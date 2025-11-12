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
    STATE    EQU 0x22
    RECSTAT	    EQU 0x23
    SERVOPOS	    EQU 0x24
    TIME	    EQU 0x25
    ADDEDBITS	    EQU 0x26
	    MAILOUT EQU 0x27
 ANOTHERTIME	EQU 0x28
	TEMP EQU 0x29


   
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
    
    BCF STATUS,5
    BCF STATUS,6
        
    
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
    
    GOTO MAINLOOP
    
STARTBUTTON:
    MOVLW 0x53
    MOVWF PORTC
    CALL KEYPAD
    
    GOTO MAINLOOP
    
STOPBUTTON:
    CLRF PORTC
    
    GOTO MAINLOOP
    
PLAYBUTTON:
    MOVLW 0x50
    MOVWF PORTC
    
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
   MOVWF PORTC
   GOTO MAINLOOP	    ;??
   

    
//    CALL WRITE
//    CALL READ
//    GOTO MAINLOOP
//    
//WRITE:
//    BANKSEL EEADR
//    MOVLW 0x55	    ;WHERE TO WRITE
//    MOVWF EEADR
//    
//    MOVLW 0x38
//    MOVWF EEDATA    ;WHAT TO WRITE
//    
//    BANKSEL EECON1
//    BCF EECON1,7    ;POINTS TO DATA MEMORY
//    BSF EECON1,2    ;ENABLES WRITE CYCLE
//    
//    ;BANK 3
//    BSF STATUS,5
//    BSF STATUS,6
//    
//    MOVLW 0x55	    ;FINISH PROGRAMMING SEQUENCE
//    MOVWF EECON2
//    MOVLW 0xAA
//    MOVWF EECON2
//    
//    BSF EECON1,1    ;STARTS WRITE CYCLE
//    
//    BANKSEL PIR2
//    BTFSS PIR2,4    ;EE WRITE OPERATION INTERRUPT FLAG BIT
//    GOTO $-1
//    
    ;RENABLE INTERRUPTS
//    BANKSEL PIE2
//    MOVLW 0x10
//    MOVWF PIE2
//    
//    MOVLW 0xC0
//    MOVWF INTCON
    
    ;RETURN
    
;READ: 
    ;FIGURE OUT READ CODE
//    BANKSEL EEADR
//    MOVLW 0x55
//    MOVWF EEADR
//    
//    BANKSEL EECON1
//    BCF EECON1,7    ;EEPGD, POINT TO DATA MEMORY
//    BSF EECON1,0    ;RD, EE READ
//    
//    BANKSEL EEDATA
//    MOVF EEDATA,W   ;W=EEDATA
//    
//    ;BANK 0
//    BCF STATUS,5
//    BCF STATUS,6
//    
//    MOVWF PORTC
//    
//    RETURN
    
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
    
   
    
    
 
    
