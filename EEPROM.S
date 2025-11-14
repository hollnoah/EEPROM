;NAME Noah Holloway
;COURSE 3371
;SEMESTER 5
;Program: EEPROM
;Git URL
    
;Devices
;Configuration
    
    ; PIC16F883 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = XT		; Oscillator Selection bits (XT oscillator: Crystal/resonator on RA6/OSC2/CLKOUT and RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = ON            ; RE3/MCLR pin function select bit (RE3/MCLR pin function is MCLR)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
 
  
;Include Statements
  #include <xc.inc>
 ; #include <pic16f883.inc>
;Register/Variable Setup
  ;SOMEVALUE EQU 0x5f ;assign value to a variable
  
    SAVEW	    EQU	0x20
    SAVESTAT	    EQU 0x21
    STATE	    EQU 0x22
    RECSTAT	    EQU 0x23
    PRESSEDKEY	    EQU 0x24
    TIME	    EQU 0x25
    WRITEPTR	    EQU 0x26
    TEMP1	    EQU 0x27
    TEMP2	    EQU 0x28
    TEMP	    EQU 0x29


   
 ;Start of Program
 ;Reset vector address
 PSECT resetVect,class=CODE,delta=2 ;-Wl,-presetVect=00h
 GOTO Start
 
 PSECT isrVect,class=CODE,delta=2 ;-Wl,-pisrVect=04h
 ;GOTO INTERRUPT

 ;Setup Code that runs once at power up and at reset
 PSECT code,class=CODE,delta=2 ;-Wl,-pcode=08h
 
 ;-Wl,-presetVect=00h -Wl,-pisrVect=04h -Wl,-pcode=08h
 
Start:
 
;BANK 3
    BSF STATUS,5    ;GO TO BANK 3
    BSF STATUS,6    ;GO TO BANK 3
    
    CLRF ANSELH	    ;DIGITAL I/O
    CLRF ANSEL
    
    MOVLW 0x0F	    ;UPPER NIBBLE IS OUTPUTS (ROWS)
    MOVWF TRISB	    ;LOWER NIBBLE IS INPUTS (COLUMNS)
    
    MOVLW 0x80
    MOVWF OPTION_REG	;DISABLE PULL UPS
    
;BANK 2
    BSF STATUS,6    ;GO TO BANK 2
    BCF STATUS,5    ;GO TO BANK 2
    
    CLRF CM2CON1    ;SET ALL BITS TO 0
    
;BANK 1
    BSF STATUS,5    ;GO TO BANK 1
    BCF STATUS,6    ;GO TO BANK 1
    
    CLRF IOCB	    ;CLEARS INTERRUPTION CHANGE 
    CLRF PSTRCON
    CLRF TRISC	    ;CONFIGURES PORTC AS OUTPUTS
    MOVLW 0xFF
    MOVWF TRISA	    ;CONFIGURES PORTA AS INPUTS
    MOVLW 0x00
    MOVWF ADCON1    ;LEFT JUSTIFIED, VSS & VDD
    CLRF CCP1CON   
    
;BANK 0
    BCF STATUS,5    ;GO TO BANK 0
    BCF STATUS,6    ;GO TO BANK 0
    
    CLRF PORTC	    ;PUTS PORT C INTO A KNOWN STATE
    CLRF PORTA	    ;PUTS PORT A INTO A KNOWN STATE
    CLRF STATE	    ;START BLANK
    CLRF CCPR1L     ;START WITH 0 DUTY
    
    ;INTERRUPT STUFF----------------------------------------------------------------------------------------------
    
    BSF STATUS,5   ;BANK 1
    BCF STATUS,6
    
    BCF PIE1, 1	    ;ENABLES TIMER2 TO MATCH PR2 INTERRUPT
    ;BSF PIE1, 5	    ;ENABLES EUSART RECIEVE INTERRUPT BIT
    
    MOVLW 0xFF
    MOVWF PR2	    ;LOADING FF FOR MAX COUNT
    
    BCF STATUS,5
    BCF STATUS,6   ;BANK 0
    
    MOVLW 0xFF
    MOVWF T2CON	    ;TMR 2 ON, 1:16 PRE, 1:5 POST
    
    ;MOVLW 0x41
    ;MOVWF ADCON0    ;FOSC8, AN0, A/D NOT IN PROGRESS, A/D ENABLED
    
    CLRF PIR1
    ;BCF PIE1,6	    ;DISABLE AD INTERRUPT
    
    MOVLW 0x00
    ;MOVLW 0xC0
    MOVWF INTCON    ;ENABLE GLOBAL & PERIPHERAL INTERRUPTS
    
    ;BANK 0
    BCF STATUS,5
    BCF STATUS,6
        
    MOVLW 0x00	    ;STARTS EEPROM ADDRESS FOR FIRST KEY
    MOVWF WRITEPTR  ;INITIALIZE WRITE POINTER
    
    ;END INTERRUPT STUFF-----------------------------------------------------------------------------------------
    
    GOTO MAINLOOP
   
MAINLOOP: 
    BANKSEL PORTA
    
    BTFSC PORTA,0
    GOTO STARTBUTTON
    
    BTFSC PORTA,1
    GOTO STOPBUTTON
    
    BTFSC PORTA,2
    GOTO PLAYBUTTON
    
    MOVLW 0x4D	    ;INDICATING THAT WE'RE IN MAIN
    MOVWF PORTC
    
    GOTO MAINLOOP
    
STARTBUTTON:
    BANKSEL PORTC
    MOVLW 0x53	    ;DISPLAY S
    MOVWF PORTC
    CLRF WRITEPTR   ;CLEAR ADRESS REGISTER TO ADDRESS 0
      
RECORD_LOOP:
    BANKSEL PORTA
    BTFSC PORTA,1	;POLLS STOP BUTTON
    GOTO RECORD_DONE
    
    ;GOTO KEYPAD
    
    BANKSEL WRITEPTR
    ;INCF WRITEPTR,F	;INCRAMENTS WRITEPTR TO RECORD THAT ONE KEY WAS STORED
    MOVF WRITEPTR,W
    XORLW 10
    BTFSC STATUS,2	;SKIPS IF 0 FLAG NOT SET
    GOTO RECORD_DONE
    
    GOTO KEYPAD

    
RECORD_DONE:
    GOTO MAINLOOP
    
STOPBUTTON:
    CLRF PORTC
    
    GOTO MAINLOOP
    
PLAYBUTTON:
    MOVLW 0x50	    ;DISPLAYS P
    MOVWF PORTC
    CALL DELAY
    ;CALL READ
    CALL PLAYBACK
    
    GOTO MAINLOOP
    
KEYPAD:
    ;BANK 0
    BCF STATUS,5
    BCF STATUS,6 
    
    ;ACTIVATE ROW 4 (MSB ROW)
    MOVLW 0x10
    MOVWF PORTB
    
    ;CHECKING D/ R4,C4(MSB COLUMN)
    MOVLW 0x44
    BTFSC PORTB, 0 ;REFERENCE KEYPAD DATASHEET. LETTER D IS IN COLUMN 1, AND RB0 REPRESENTS COLUMN 1, RB0 IS 0 WITHIN PORTB 
    GOTO Display
    
    ;CHECKING #/ R4,C3
    MOVLW 0x23
    BTFSC PORTB, 1
    GOTO Display 
    
    ;CHEKING 0/ R4,C2
    MOVLW 0x30
    BTFSC PORTB, 2
    GOTO Display
    
    ;CHEKING */ R4,C1(LSB COLUMN)
    MOVLW 0x2A
    BTFSC PORTB, 3
    GOTO Display
    
    
    ;ACTIVATE ROW 3
    MOVLW 0x20
    MOVWF PORTB
    
    ;CHEKING C/ R3,C4
    MOVLW 0x43
    BTFSC PORTB, 0
    GOTO Display
    
    ;CHECKING 9/ R3,C3
    MOVLW 0x39
    BTFSC PORTB, 1
    GOTO Display
    
    ;CHECKING 8/ R3,C2
    MOVLW 0x38
    BTFSC PORTB, 2
    GOTO Display
    
    ;CHECKING 7/ R3,C1
    MOVLW 0x37
    BTFSC PORTB, 3
    GOTO Display
    
    
    ;ACTIVATE ROW 2
    MOVLW 0x40
    MOVWF PORTB
    
    ;CHECKING B/ R2,C4
    MOVLW 0x42
    BTFSC PORTB, 0
    GOTO Display
    
    ;CHECKING 6/ R2,C3
    MOVLW 0x36
    BTFSC PORTB, 1
    GOTO Display
    
    ;CHECKING 5/ R2,C2
    MOVLW 0x35
    BTFSC PORTB, 2
    GOTO Display
    
    ;CHECKING 4/ R2,C1
    MOVLW 0x34
    BTFSC PORTB, 3
    GOTO Display
    
    
    ;ACTIVATE ROW 1
    MOVLW 0x80
    MOVWF PORTB
    
    ;CHECKING A/ R1,C4
    MOVLW 0x41
    BTFSC PORTB, 0
    GOTO Display
    
    ;CHECKING 3/ R1,C3
    MOVLW 0x33
    BTFSC PORTB, 1
    GOTO Display
    
    ;CHECKING 2/ R1,C2
    MOVLW 0x32
    BTFSC PORTB, 2
    GOTO Display
    
    ;CHECKING 1/ R1,C1
    MOVLW 0x31
    BTFSC PORTB, 3
    GOTO Display
    
    GOTO KEYPAD
    
Display:
   MOVWF PRESSEDKEY	;STORE KEYPAD VALUE IN PRESSEDKEY
   MOVWF PORTC		;ALSO DISPLAY SAID KEYPAD VALUE ON DOT MATRIX	    

   CALL WRITE
  
   NOP
   GOTO RECORD_LOOP
   
WRITE:
    BANKSEL WRITEPTR
    MOVF WRITEPTR,W ;LOAD EEPROM ADDRESS FROM POINTER (WHERE TO WRITE)
    BANKSEL EEADR
    MOVWF EEADR
    
    BANKSEL PRESSEDKEY
    MOVF PRESSEDKEY,W	;MOVES KEYPAD VALUE OUT OF PRESSEDKEY AND INTO W
    BANKSEL EEDATA
    MOVWF EEDATA    ;WHAT TO WRITE (SAID KEYPAD VALUE)
    
    BANKSEL EECON1
    BCF EECON1,7    ;POINTS TO DATA MEMORY
    BSF EECON1,2    ;ENABLES WRITE CYCLE
    
    MOVLW 0x55	    ;FINISH PROGRAMMING SEQUENCE
    MOVWF EECON2
    MOVLW 0xAA
    MOVWF EECON2
    BSF EECON1,1    ;STARTS WRITE CYCLE
    
WAIT_EE_WRITE:
    BANKSEL PIR2
    BTFSC PIR2,4    ;EE WRITE OPERATION INTERRUPT FLAG BIT
    GOTO FINISH_EE_WRITE
    GOTO WAIT_EE_WRITE
   
FINISH_EE_WRITE:
    BANKSEL PIR2
    BCF PIR2,4	    ;CLEAR EEIF
    BANKSEL EECON1
    BCF EECON1,2    ;WREN = 0
    
    BANKSEL WRITEPTR
    INCF WRITEPTR,F	;INCRAMENT FOR NEXT WRITE
    
    RETURN
    
//    ;RENABLE INTERRUPTS
//    BANKSEL PIE2
//    MOVLW 0x10
//    MOVWF PIE2
//    
//    MOVLW 0xC0
//    MOVWF INTCON
//    
//    RETURN

    
READ: 
    ;LOAD ADDRESS TO READ
    ;COPY WRITEPTR TO TEMP, THEN DECRAMENT TEMP AND USE TEMP AS EEADR
    BANKSEL WRITEPTR
    MOVF WRITEPTR,W	;LOAD WRITEPTR VALUE INTO W
    BANKSEL TEMP
    MOVWF TEMP		;MOVE WRITEPTR VALUE OUT OF W AND INTO TEMP
    DECF TEMP,F		;DECRAMENT TEMP BY 1
    
    MOVF TEMP,W
    BANKSEL EEADR
    MOVWF EEADR
    
    BANKSEL EECON1
    BCF EECON1,7    ;EEPGD, POINT TO DATA MEMORY
    BSF EECON1,0    ;RD, EE READ
    
    BANKSEL EEDATA
    MOVF EEDATA,W   ;W=EEDATA
    
    BANKSEL PORTC
    MOVWF PORTC
    
    RETURN
    
READ_EE:
    BANKSEL EECON1
    BCF EECON1,7
    BSF EECON1,0
    
    BANKSEL EEDATA
    MOVF EEDATA,W
    
    BANKSEL PORTC
    MOVWF PORTC
    
    RETURN

PLAYBACK:
    ; use TEMP (your general-purpose counter) for 0..9
    BANKSEL TEMP
    CLRF TEMP          ; TEMP = 0

PB_LOOP:
    ; move TEMP into EEADR (explicitly select EEADR's bank first)
    BANKSEL TEMP
    MOVF TEMP,W
    BANKSEL EEADR
    MOVWF EEADR

    ; now read EEPROM at EEADR and display
    CALL READ_EE

    ; delay so user can see it
    CALL DELAY

    ; increment TEMP (counter). Make sure TEMP's bank is selected
    BANKSEL TEMP
    INCF TEMP,F

    ; compare TEMP to 10 (we'll do MOVF TEMP,W then XORLW 10)
    MOVF TEMP,W
    XORLW 10
    BTFSS STATUS,2   ; Z = 1 if TEMP == 10 -> skip next GOTO
    GOTO PB_LOOP

    RETURN

//PLAYBACK:		;DISPLAY ADDRESSES 0-9
//    BANKSEL EEADR
//    CLRF EEADR      ; start at address 0
//
//PB_LOOP:
//    CALL READ_EE    ; read and display current address
//
//    ; delay so user can see it on the dot matrix
//    CALL DELAY
//
//    INCF EEADR, F   ; next address
//    MOVF EEADR, W
//    XORLW 10
//    BTFSS STATUS,2 ; stop when EEADR == 10
//    GOTO PB_LOOP
//
//    RETURN

  ;PLAYBACK:  
//    BANKSEL EEADR	;GOOD
//    MOVLW 0x00	    
//    MOVWF EEADR
//    CALL READ_EE
//    
//    ;BANKSEL EEADR	;BAD, DISPLAYS A
//    MOVLW 0x01
//    MOVWF EEADR
//    CALL READ_EE
//    
//    ;BANKSEL EEADR	;BAD, DISPLAYS 2
//    MOVLW 0x02
//    MOVWF EEADR
//    CALL READ_EE
//    
//    ;BANKSEL EEADR	;BAD, DISPLAYS A
//    MOVLW 0x03
//    MOVWF EEADR
//    CALL READ_EE
//    
//    ;BANKSEL EEADR	;BAD, DISPLAYS *
//    MOVLW 0x04
//    MOVWF EEADR
//    CALL READ_EE
//    
//    ;BANKSEL EEADR	;BAD, DISPLAYS 8
//    MOVLW 0x05
//    MOVWF EEADR
//    CALL READ_EE
//    
//    ;BANKSEL EEADR	;BAD, DISPLAYS 9
//    MOVLW 0x06
//    MOVWF EEADR
//    CALL READ_EE
//    
//    ;BANKSEL EEADR	;BAD, DISPLAYS 2
//    MOVLW 0x07
//    MOVWF EEADR
//    CALL READ_EE
//    
//    ;BANKSEL EEADR	;BAD, DISPLAYS 9
//    MOVLW 0x08
//    MOVWF EEADR
//    CALL READ_EE
//    
//    ;BANKSEL EEADR	;BAD, DISPLAYS #
//    MOVLW 0x09
//    MOVWF EEADR
//    CALL READ_EE
//    
//    NOP
//    RETURN

DELAY:
    BANKSEL TEMP2
    MOVLW 0xFF
    MOVWF TEMP2

SD_LOOP1:
    MOVLW 0xFF
    MOVWF TIME
    
SD_LOOP2:
    DECFSZ TIME,F
    GOTO SD_LOOP2
    DECFSZ TEMP2,F
    GOTO SD_LOOP1
    
    RETURN

//INTERRUPT:
//    ;SAVE STATUS
//    MOVWF SAVEW
//    MOVF STATUS,W
//    MOVWF SAVESTAT
//    
//    BTFSS PIR1,1    ;MAKES SEURE TIMER2 INT FLAG IS SET
//    GOTO ISREXIT
//    
//    ;BCF PIR1,1
//    
//    DECFSZ TIME
//    GOTO ISREXIT
//    
//    MOVLW 16	    ;15 LOOPS SHOULD BE 1 SECOND
//    MOVWF TIME
//    
//    MOVF STATE,W
//    XORLW 0x01
//    MOVWF STATE
//    
//    BTFSC STATE,0
//    GOTO DISPLAY_S
//    CLRF PORTC	    ;DISPLAYS BLANK ON DOT MATRIX
//    GOTO ISREXIT
//    
// DISPLAY_S:   
//    MOVLW 0x53	    ;HEX VALUE FOR LETTER "S"
//    MOVWF PORTC
//    
//ISREXIT:
//    ;RESTORE STATUS AND RETURN
//    MOVF SAVESTAT,W
//    MOVWF STATUS
//    MOVF SAVEW,W
//    BCF PIR1,1	    ;MIGHT FAIL, MIGHT INTERRUPT AGAIN BEFORE ITS TIME
//
//    RETFIE 
//   
END
    
   
    
    
 
    
