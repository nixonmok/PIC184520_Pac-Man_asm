LIST P=18F4520
#include <P18F4520.INC>
CONFIG OSC = XT
CONFIG WDT = OFF
CONFIG LVP = OFF
CBLOCK 0x000
DELAY_U
DELAY_H
DELAY_L
PACMANX 
PACMANY
COUNTERY
COUNTERX
ENDC

ORG 0x0000
goto main

ORG 0x0100

main: 
movlw 0x0F
movwf ADCON1
clrf TRISC
clrf TRISD ;CD = output
Setf TRISB ;B = input
movlw 0x00
movwf COUNTERY
movlw 0x09
movwf COUNTERX


    movlw b'10000000'
    movwf PACMANY
    movlw b'00001001'
    movwf PACMANX ;initialize pacman position

MOVE:    ;if(player.posx == finishptx && player.posy == finishpty)
    ;endgame
    movlw b'00000001'
    CPFSEQ PACMANY ;check if player at finish point 1
    GOTO GAME ;not at finish point, continue game
    movlw B'00010000'
    CPFSEQ PACMANX ;check if player at finish point 2
    GOTO GAME ;not at finish point, continue game
    GOTO GAMEOVER ;winning, game end

GAME:

    movff PACMANY, PORTC
    movff PACMANX, PORTD
	CALL Delay
;moveup?
    movlw 0x07
    CPFSEQ COUNTERY ;compare WREG(7) with COUNTERY, if ==, skip moveup action
    GOTO MOVEUPYES ;case: COUNTERY != 7
    GOTO NOMOVEUP    ;if pointer = 7, even pressed, no moveup
MOVEUPYES:
    btfss PORTB, 0x01 ;button P2
    CALL moveup ;move up
    NOMOVEUP: 
;movedown?
    MOVF COUNTERY
    BZ NOMOVEDOWN ;if pointer = 0, even pressed, no movedown
    btfss PORTB, 0x05 ;button P6
    CALL movedown
NOMOVEDOWN:
;moveleft?	
	MOVF COUNTERX
	BZ NOMOVELEFT ;Status = 0 (which means Counter=0, do nothing)
    btfss PORTB, 0x04
    CALL moveleft
NOMOVELEFT:
;moveright?	
	movlw 0x0F
	CPFSEQ COUNTERX	;if X == most right(counter==most right), do nothing
	GOTO MOVERIGHTYES
	GOTO NOMOVERIGHT
MOVERIGHTYES:
    btfss PORTB, 0x06
    CALL moveright
NOMOVERIGHT:

    GOTO MOVE 

GAMEOVER: 
clrf PORTC
clrf PORTD 
GOTO GAMEOVER ;end game


Delay: 
    movlw 0x10
    movwf DELAY_U
    LOP_1: movlw 0xF
    movwf DELAY_H
    LOP_2: movlw 0xF
    movwf DELAY_L
    LOP_3: decf DELAY_L, F
    bnz LOP_3
    decf DELAY_H, F
    bnz LOP_2
    decf DELAY_U, F
    bnz LOP_3
    return
    ;y-AXIS movement:{
moveup:

    MOVLW low moveY_TABLE ; TBLPTRL = 00
    MOVWF TBLPTRL
    MOVLW high moveY_TABLE; TBLPTRH = 25
    MOVWF TBLPTRH
    MOVLW upper moveY_TABLE ;upper no need care
    MOVWF TBLPTRU ;set up look up pointer

    INCF COUNTERY
    MOVF COUNTERY, W
    ADDWF TBLPTRL, F
    TBLRD* ;increase pointer first then read
    MOVFF TABLAT, PACMANY ;Y+1


    return

movedown:
    MOVLW low moveY_TABLE
    MOVWF TBLPTRL
    MOVLW high moveY_TABLE
    MOVWF TBLPTRH
    MOVLW upper moveY_TABLE
    MOVWF TBLPTRU ;set up look up pointer

    DECF COUNTERY
    MOVF COUNTERY, W
    ADDWF TBLPTRL, F
    TBLRD* ;read table and decrease pointer (next will minus fewer)
    MOVFF TABLAT, PACMANY ;Y - 1


    return
;Y-axis movement }
moveright:
    MOVLW low moveX_TABLE
    MOVWF TBLPTRL
    MOVLW high moveX_TABLE
    MOVWF TBLPTRH
    MOVLW upper moveX_TABLE
    MOVWF TBLPTRU ;set up look up pointer

    INCF COUNTERX
    MOVF COUNTERX, W
    ADDWF TBLPTRL, F
    TBLRD* ;increase pointer first then read
    MOVFF TABLAT, PACMANX ;X+1
    return

moveleft:
    MOVLW low moveX_TABLE
    MOVWF TBLPTRL
    MOVLW high moveX_TABLE
    MOVWF TBLPTRH
    MOVLW upper moveX_TABLE
    MOVWF TBLPTRU ;set up look up pointer

    DECF COUNTERX
    MOVF COUNTERX, W
    ADDWF TBLPTRL, F
    TBLRD* ;increase pointer first then read
    MOVFF TABLAT, PACMANX ;X-1
    return

ORG 0x2500
moveY_TABLE:
    DB B'10000000', B'01000000', B'00100000',B'00010000', B'00001000', B'00000100',B'00000010', B'00000001' ;lowest to largest


ORG 0x2600
moveX_TABLE:
    DB B'00010000',B'00010001',B'00010010',B'00010011',B'00010100',B'00010101',B'00010110',B'00010111',B'00001000',B'00001001',B'00001010',B'00001011',B'00001100',B'00001101',B'00001110',B'00001111'
END