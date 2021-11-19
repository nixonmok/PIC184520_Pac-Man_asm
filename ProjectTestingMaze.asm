LIST P=18F4520 ;directive to define processor
#include <P18F4520.INC> ;CPU specific variable definitions
;Configuration bits definitions
CONFIG OSC = XT
CONFIG WDT = OFF
CONFIG LVP = OFF

CBLOCK 0x000
DELAY_U
DELAY_H
DELAY_L
ENDC

ORG 0x0000
goto main

ORG 0x0100
main: movlw 0x0F
movwf ADCON1
clrf TRISC
clrf TRISD
Clrf TRISA ;ACD = output
Setf TRISB ;B = input

MAZE:
	;Matrix 1 and 3 LED
	movlw 0x10
	movwf PORTD
	movlw B'11111110'
	movwf PORTC
	Call Delay
	
	movlw 0x11
	movwf PORTD
	movlw B'10000000'
	movwf PORTC
	Call Delay
	
	movlw 0x12
	movwf PORTD
	movlw B'10110000'
	movwf PORTC
	
	Call Delay
	
	movlw 0x13
	movwf PORTD
	movlw B'10111111'
	movwf PORTC
		;column4
	Call Delay
	
	movlw 0x14
	movwf PORTD
	movlw B'10111111'
	movwf PORTC
		;column5
	Call Delay
	
	movlw 0x15
	movwf PORTD
	movlw B'10110000'
	movwf PORTC
		;column6
	Call Delay
	
	movlw 0x16
	movwf PORTD
	movlw B'10110111'
	movwf PORTC
		;column7
	Call Delay
	
	movlw 0x17
	movwf PORTD
	movlw B'10110111'
	movwf PORTC
	;column8
	Call Delay
	
	;Matrix 2 and 4 LED
	
	movlw 0x08
	movwf PORTD
	movlw B'10000000'
	movwf PORTC
		;column1
	Call Delay
	
	movlw 0x09
	movwf PORTD
	movlw B'10111111'
	movwf PORTC
		;column2
	Call Delay
	
	movlw 0x0A
	movwf PORTD
	movlw B'10111111'
	movwf PORTC
		;column3
	Call Delay
	
	movlw 0x0B
	movwf PORTD
	movlw B'10000000'
	movwf PORTC
		;column4
	Call Delay
	
	movlw 0x0C
	movwf PORTD
	movlw B'10111111'
	movwf PORTC
		;column5
	Call Delay
	
	movlw 0x0D
	movwf PORTD
	movlw B'10111111'
	movwf PORTC
		;column6
	Call Delay
	
	movlw 0x0E
	movwf PORTD
	movlw B'10000000'
	movwf PORTC
		;column7
	Call Delay
	
	movlw 0x0F
	movwf PORTD
	movlw B'11111110'
	movwf PORTC
		;column8
	Call Delay
	
	GOTO MAZE
	
	
	
Delay: movlw 0x03
movwf DELAY_U
LOP_1: movlw 0x01
movwf DELAY_H
LOP_2: movlw 0x01
movwf DELAY_L
LOP_3: decf DELAY_L, F
bnz LOP_3
decf DELAY_H, F
bnz LOP_2
decf DELAY_U, F
bnz LOP_3
return

	END