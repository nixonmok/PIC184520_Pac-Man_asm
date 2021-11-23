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
	Bean1Left
	Bean2Left
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
	setf Bean1Left
	movlw b'00100100'
	movwf Bean2Left

    movlw b'10000000'
    movwf PACMANY
    movlw b'00001001'
    movwf PACMANX ;initialize pacman position

MOVE:    ;if(player.posx == finishptx && player.posy == finishpty)
    ;endgame
    movlw 0
	CPFSEQ Bean1Left
	GOTO GAME
	CPFSEQ Bean2Left
	GOTO GAME
	GOTO GAMEOVER

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

    
	CALL Bean
	GOTO MOVE 
	
;bean subroutine start
;-------------------------------------------

Bean:
	btfss Bean1Left, 0 ;check bean1
	GOTO Bean1No	
	movlw b'00010100'
	CPFSEQ PACMANX
	GOTO continue1;Not Same
	btfss PACMANY,0
	GOTO continue1;Not Same	
Bean1No: ;XY = 1, bean = eaten
	BCF Bean1Left, 0

continue1:
	btfss Bean1Left, 1 ;check bean1
	GOTO Bean2No	
	movlw b'00010100'
	CPFSEQ PACMANX
	GOTO continue2;Not Same
	btfss PACMANY,1
	GOTO continue2;Not Same	
Bean2No:
	BCF Bean1Left, 1

continue2:
	btfss Bean1Left, 2 ;check bean1
	GOTO Bean3No	
	movlw b'00010100'
	CPFSEQ PACMANX
	GOTO continue3;Not Same
	btfss PACMANY,2
	GOTO continue3;Not Same	
Bean3No:
	BCF Bean1Left, 2

continue3:
	btfss Bean1Left, 3 ;check bean1
	GOTO Bean4No	
	movlw b'00010100'
	CPFSEQ PACMANX
	GOTO continue4;Not Same
	btfss PACMANY,3
	GOTO continue4;Not Same	
Bean4No:
	BCF Bean1Left, 3

	
continue4:

	btfss Bean1Left, 4 ;check bean1
	GOTO Bean5No	
	movlw b'00010100'
	CPFSEQ PACMANX
	GOTO continue5;Not Same
	btfss PACMANY,4
	GOTO continue5;Not Same	
Bean5No:
	BCF Bean1Left, 4

continue5:
	btfss Bean1Left, 5 ;check bean1
	GOTO Bean6No	
	movlw b'00010100'
	CPFSEQ PACMANX
	GOTO continue6;Not Same
	btfss PACMANY,5
	GOTO continue6;Not Same	
Bean6No:
	BCF Bean1Left, 5

continue6:
	btfss Bean1Left, 6 ;check bean1
	GOTO Bean7No	
	movlw b'00010100'
	CPFSEQ PACMANX
	GOTO continue7;Not Same
	btfss PACMANY,6
	GOTO continue7;Not Same	
Bean7No:
	BCF Bean1Left, 6

continue7:
	btfss Bean1Left, 7 ;check bean1
	GOTO Bean8No	
	movlw b'00010100'
	CPFSEQ PACMANX
	GOTO continue8;Not Same
	btfss PACMANY,7
	GOTO continue8;Not Same	
Bean8No:
	BCF Bean1Left, 7	

continue8:
	btfss Bean2Left, 2 ;check bean
	GOTO Bean9No	
	movlw b'00010010'
	CPFSEQ PACMANX
	GOTO continue9;Not Same
	btfss PACMANY,2
	GOTO continue9;Not Same	
Bean9No:
	BCF Bean2Left, 2

continue9:
	btfss Bean2Left, 5 ;check bean
	GOTO Bean10No	
	movlw b'00010010'
	CPFSEQ PACMANX
	GOTO finish;Not Same
	btfss PACMANY,5
	GOTO finish;Not Same
Bean10No:
	BCF Bean2Left, 5	
finish:
	movlw b'00010100'
	movwf PORTD
	movff Bean1Left, PORTC
	CALL Delay2
	
	movlw b'00010010'
	movwf PORTD
	movff Bean2Left, PORTC
	CALL Delay2
	return

;-------------------------------------------





GAMEOVER: 
	CALL GameOverScreen 
	GOTO GAMEOVER ;end game


Delay: 
    movlw 0x1
    movwf DELAY_U
    LOP_1: movlw 0xFF
    movwf DELAY_H
    LOP_2: movlw 0xFF
    movwf DELAY_L
    LOP_3: decf DELAY_L, F
    bnz LOP_3
    decf DELAY_H, F
    bnz LOP_2
    decf DELAY_U, F
    bnz LOP_3
    return

Delay2: 
    movlw 0x1
    movwf DELAY_U
    LOP_11: movlw 0xF
    movwf DELAY_H
    LOP_22: movlw 0xF
    movwf DELAY_L
    LOP_33: decf DELAY_L, F
    bnz LOP_33
    decf DELAY_H, F
    bnz LOP_22
    decf DELAY_U, F
    bnz LOP_33
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
GameOverScreen:
	movlw B'11111110'
	movwf PORTC
	movlw B'00010000'
	movwf PORTD
	CALL Delay2

	movlw B'10000010'
	movwf PORTC
	movlw B'00010001'
	movwf PORTD
	CALL Delay2
	
	
	movlw B'10000010'
	movwf PORTC
	movlw B'00010010'
	movwf PORTD
	CALL Delay2

	movlw B'10000010'
	movwf PORTC
	movlw B'00010011'
	movwf PORTD
	CALL Delay2

	movlw B'10010010'
	movwf PORTC
	movlw B'00010100'
	movwf PORTD
	CALL Delay2
	
	movlw B'11110010'
	movwf PORTC
	movlw B'00010101'
	movwf PORTD
	CALL Delay2

	movlw B'00010010'
	movwf PORTC
	movlw B'00010110'
	movwf PORTD
	CALL Delay2

	movlw B'00000000'
	movwf PORTC
	movlw B'00010111'
	movwf PORTD
	CALL Delay2

	movlw B'11111110'
	movwf PORTC
	movlw B'00001000'
	movwf PORTD
	CALL Delay2

	movlw B'10000010'
	movwf PORTC
	movlw B'00001001'
	movwf PORTD
	CALL Delay2

	movlw B'10000010'
	movwf PORTC
	movlw B'00001010'
	movwf PORTD
	CALL Delay2

	movlw B'10000010'
	movwf PORTC
	movlw B'00001011'
	movwf PORTD
	CALL Delay2

	movlw B'10010010'
	movwf PORTC
	movlw B'00001100'
	movwf PORTD
	CALL Delay2

	movlw B'11110010'
	movwf PORTC
	movlw B'00001101'
	movwf PORTD
	CALL Delay2

	movlw B'00010010'
	movwf PORTC
	movlw B'00001110'
	movwf PORTD
	CALL Delay2

	movlw B'00000000'
	movwf PORTC
	movlw B'00001111'
	movwf PORTD
	CALL Delay2
	;Game Over Screen End
	return

	ORG 0x2500
moveY_TABLE:
    DB B'10000000', B'01000000', B'00100000',B'00010000', B'00001000', B'00000100',B'00000010', B'00000001' ;lowest to largest


	ORG 0x2600
moveX_TABLE:
    DB B'00010000',B'00010001',B'00010010',B'00010011',B'00010100',B'00010101',B'00010110',B'00010111',B'00001000',B'00001001',B'00001010',B'00001011',B'00001100',B'00001101',B'00001110',B'00001111'

	END
