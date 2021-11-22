LIST P=18F4520
#include <P18F4520.INC>
CONFIG OSC = XT
CONFIG WDT = OFF
CONFIG LVP = OFF
CBLOCK 0x000
DELAY_U
DELAY_H
DELAY_L
DELAY_U1
DELAY_H1
DELAY_L1
PACMANX 
PACMANY
GHOSTX
GHOSTY
GhostMovingCountDown
ToggleBit
COUNTERY
COUNTERX
WALL
StageVal
ENDC

ORG 0x0000 
goto main

ORG 0x0008 ;for interupt
btfss INTCON, INT0IF ;button 0 pause interupt
RETFIE
GOTO pause



ORG 0x0100

main: 
movlw 0x0F
movwf ADCON1 ;all digital
clrf TRISC
clrf TRISD ;CD = output
Setf TRISB ;B = input
movlw 0x00
movwf COUNTERY
movlw 0x0F
movwf COUNTERX

BCF INTCON,INT0IF
BSF INTCON,INT0IE
BCF INTCON2, INTEDG0 ;interupt setup for pause


	movlw b'00001010'
	movwf GHOSTX
	movlw b'10000000'
	movwf GHOSTY
	movlw 0x01
	movwf GhostMovingCountDown
	clrf ToggleBit
	
    movlw b'10000000'
    movwf PACMANY ;initialize pacman position (y-axis)
    movlw b'00001111'
    movwf PACMANX ;initialize pacman position (x-axis)
	;initial position of both game is same
	
StageSelection:
	CALL StageSelectScreen ;select stage
	btfss PORTB, 3
	GOTO MOVE1
	btfss PORTB, 7
	GOTO MOVE2
	CALL Delay
	GOTO StageSelection


MOVE1:   
	;if(player.posx == finishptx && player.posy == finishpty)
    ;endgame
     
    
	movlw 0x01
	movwf StageVal ;save stageval (for crash detection lookup table)
	
    movlw b'00000001' 
    CPFSEQ PACMANY ;check if player at finish point 1
    GOTO CheckGhost1 ;not at finish point, continue game
    movlw B'00010000'
    CPFSEQ PACMANX ;check if player at finish point 2
    GOTO CheckGhost1 ;not at finish point, continue game
	GOTO GAMEOVER
CheckGhost1:    
    movf GHOSTY, W
    CPFSEQ PACMANY
    bra GAME1 ; Pac man Y = Ghost Y?
    movf GHOSTX, W
    CPFSEQ PACMANX
    bra GAME1 ; Pac man X = Ghost X?
    
    GOTO GAMEOVER ;winning, game end

;main game
GAME1:
	BSF INTCON, GIE ;global enable ON
	
	CALL Maze1
	movff GHOSTY, PORTC
	movff GHOSTX, PORTD
	CALL Delay3
    movff PACMANY, PORTC
    movff PACMANX, PORTD
	CALL Delay2
	CALL PacManMoveSet
	CALL GhostMoving
    GOTO MOVE1 
;game1 end

MOVE2:
	
	
	;if(player.posx == finishptx && player.posy == finishpty)
    ;endgame
	movlw 0x02
	movwf StageVal ;save stageval (for crash detection lookup table)
    
    movlw b'00000001'
    CPFSEQ PACMANY ;check if player at finish point 1
    GOTO checkghost2 ;not at finish point, continue game
    movlw B'00010000'
    CPFSEQ PACMANX ;check if player at finish point 2
    GOTO checkghost2 ;not at finish point, continue game
    GOTO GAMEOVER
checkghost2:
    movf GHOSTY,w
    CPFSEQ PACMANY
    GOTO GAME2 ; Pac man Y = Ghost Y?
    movf GHOSTX,w
    CPFSEQ PACMANX
    GOTO GAME2 ; Pac man X = Ghost X?    
    GOTO GAMEOVER ;losing, game end
GAME2:
	BSF INTCON, GIE;global enable ON
	
	CALL maze2
	
	movff GHOSTY, PORTC
	movff GHOSTX, PORTD
	CALL Delay3
	movff PACMANY, PORTC
    movff PACMANX, PORTD
	CALL Delay2
	CALL PacManMoveSet
	CALL GhostMoving
    GOTO MOVE2
	
GAMEOVER:
BCF INTCON, GIE ;global enable OFF (pause is not allowed)
CALL GameOverScreen 
btfss PORTB, 3
GOTO main
btfss PORTB, 7
GOTO main
GOTO GAMEOVER ;end game

;main program end
;--------------------------------------------------------------------------

;pause interupt
;--------------------------------------------------------------------------
pause:
	ORG 300H
	CALL PauseScreen
	btfsc PORTB, 2
	bra pause
	BCF INTCON, INT0IF
	
	RETFIE
;--------------------------------------------------------------------------



;--------------------------------------------------------------------------	
;subroutine

;--------------------------------------------------------------------------	
;Ghost moving

GhostMoving:
	
 
	btfsc GHOSTY,7
	BTG ToggleBit,0
	btfsc GHOSTY,0
	BTG ToggleBit,0
	btfsc ToggleBit,0 ;ToggleBit test:
	bra GoUp		;=1 -> go up
	bra GoDown		;=0 -> go down
GoUp:
	RRNCF GHOSTY, 1
	return
GoDown:
	RLNCF GHOSTY, 1
	return

;Ghost moving end
;--------------------------------------------------------------------------	

;--------------------------------------------------------------------------
;pacman control

PacManMoveSet:
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
    btfss PORTB, 0x04 ;button P5
    CALL moveleft
NOMOVELEFT:
;moveright?	
	movlw 0x0F
	CPFSEQ COUNTERX	;if X == most right(counter==most right), do nothing
	GOTO MOVERIGHTYES
	GOTO NOMOVERIGHT
MOVERIGHTYES:
	btfss PORTB, 0x06 ;button P7
    CALL moveright
    
NOMOVERIGHT:
	return
;pac man control end
;--------------------------------------------------------------------------




;--------------------------------------------------------------------------
;move up function
    
	;y-AXIS movement:{
moveup:
	movlw 0x01
	CPFSEQ StageVal
	GOTO up2
	CALL EncountingWallY
	GOTO up1
	up2:
	CALL EncountingWallY2
	up1:
    MOVLW low moveY_TABLE ; TBLPTRL = 00
    MOVWF TBLPTRL
    MOVLW high moveY_TABLE; TBLPTRH = 25
    MOVWF TBLPTRH
    MOVLW upper moveY_TABLE ;upper no need care
    MOVWF TBLPTRU ;set up look up pointer

    INCF COUNTERY
    MOVF COUNTERY, W
    ADDWF TBLPTRL, F
    TBLRD* ;increase pointer first then read, TABLAT = next pac man location
    ;checking crash
	MOVF TABLAT, 0
	IORWF WALL, 0
	CPFSEQ WALL
	GOTO continueup ;no crash
	GOTO upcrashed ;crashed
continueup:	
    MOVFF TABLAT, PACMANY ;Y + 1
	return
upcrashed:
	DECF COUNTERY ;recover counterY (to original)
    return
;move up function end
;--------------------------------------------------------------------------    
    
    
    
;--------------------------------------------------------------------------
;move down function 
movedown:
	movlw 0x01
	CPFSEQ StageVal
	GOTO down2
	CALL EncountingWallY
	GOTO down1
	down2:
	CALL EncountingWallY2
	down1:
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
	;checking crash
	MOVF TABLAT, 0
	IORWF WALL, 0
	CPFSEQ WALL
	GOTO continuedown ;no crash
	GOTO downcrashed ;crashed
continuedown:	
    MOVFF TABLAT, PACMANY ;Y - 1
	return
downcrashed:
	INCF COUNTERY ;recover counterY (to original)
    return

EncountingWallY:
	MOVLW low mazeY_TABLE
    MOVWF TBLPTRL
    MOVLW high mazeY_TABLE
    MOVWF TBLPTRH
    MOVLW upper mazeY_TABLE
    MOVWF TBLPTRU ;set up look up pointer
	
	MOVF COUNTERX,W ;move counterX to WREG
	ADDWF TBLPTRL, F 
	TBLRD*
	MOVFF TABLAT, WALL ;move to WALL (variable)
	return

EncountingWallY2:
	MOVLW low mazeY_TABLE2
    MOVWF TBLPTRL
    MOVLW high mazeY_TABLE2
    MOVWF TBLPTRH
    MOVLW upper mazeY_TABLE2
    MOVWF TBLPTRU ;set up look up pointer
	
	MOVF COUNTERX,W ;move counterX to WREG
	ADDWF TBLPTRL, F 
	TBLRD*
	MOVFF TABLAT, WALL ;move to WALL (variable)
	return
;move down function end
;--------------------------------------------------------------------------	

	
	
;--------------------------------------------------------------------------
;moveright function
moveright:
	movlw 0x01
	CPFSEQ StageVal
	GOTO right2
	CALL EncountingWallRight
	GOTO right1
	right2:  
	CALL EncountingWallRight2
	right1:
    MOVLW low moveX_TABLE
    MOVWF TBLPTRL
    MOVLW high moveX_TABLE
    MOVWF TBLPTRH
    MOVLW upper moveX_TABLE
    MOVWF TBLPTRU ;set up look up pointer
	
	MOVF PACMANY, 0 ;move Y location to WREG
	IORWF WALL, 0 ; PACMANY or WALL
	CPFSEQ WALL ;if after location after AND == before, do nothing
	GOTO continueright
    GOTO rightcrashed
continueright:
    INCF COUNTERX
    MOVF COUNTERX, W
    ADDWF TBLPTRL, F
    TBLRD* ;increase pointer first then read
    MOVFF TABLAT, PACMANX ;X+1
rightcrashed:
    return
EncountingWallRight:
	MOVLW low mazeY_TABLE
    MOVWF TBLPTRL
    MOVLW high mazeY_TABLE
    MOVWF TBLPTRH
    MOVLW upper mazeY_TABLE
    MOVWF TBLPTRU ;set up look up pointer
	
	MOVF COUNTERX,W ;move counterX to WREG
	ADDWF TBLPTRL, F 
	INCF TBLPTRL, F ;pointer + COUNTERX - 1 (left Wall)
	TBLRD*
	MOVFF TABLAT, WALL ;move to WALL (variable)
	return

EncountingWallRight2:
	MOVLW low mazeY_TABLE2
    MOVWF TBLPTRL
    MOVLW high mazeY_TABLE2
    MOVWF TBLPTRH
    MOVLW upper mazeY_TABLE2
    MOVWF TBLPTRU ;set up look up pointer
	
	MOVF COUNTERX,W ;move counterX to WREG
	ADDWF TBLPTRL, F 
	INCF TBLPTRL, F ;pointer + COUNTERX - 1 (left Wall)
	TBLRD*
	MOVFF TABLAT, WALL ;move to WALL (variable)
	return
	
;move right end
;--------------------------------------------------------------------------


;--------------------------------------------------------------------------
;move left function
moveleft:
	
	movlw 0x01
	CPFSEQ StageVal
	GOTO left2
	CALL EncountingWallLeft
	GOTO left1
	left2: 
	CALL EncountingWallLeft2
	left1: ;Check if it is crash with left's wall, save the location to wall
    MOVLW low moveX_TABLE
    MOVWF TBLPTRL
    MOVLW high moveX_TABLE
    MOVWF TBLPTRH
    MOVLW upper moveX_TABLE
    MOVWF TBLPTRU ;set up look up pointer
	
	MOVF PACMANY, 0 ;move Y location to WREG
	IORWF WALL, 0 ; PACMANY or WALL
	CPFSEQ WALL ;if after location after AND == before, do nothing
	GOTO continueleft
    GOTO leftcrashed
continueleft:
	DECF COUNTERX
    MOVF COUNTERX, W
    ADDWF TBLPTRL, F
    TBLRD* ;increase pointer first then read	
    MOVFF TABLAT, PACMANX ;Else, X-1
leftcrashed:
	return

;Detecting Wall object {
EncountingWallLeft:
	MOVLW low mazeY_TABLE
    MOVWF TBLPTRL
    MOVLW high mazeY_TABLE
    MOVWF TBLPTRH
    MOVLW upper mazeY_TABLE
    MOVWF TBLPTRU ;set up look up pointer
	
	MOVF COUNTERX,W ;move counterX to WREG
	ADDWF TBLPTRL, F 
	DECF TBLPTRL, F ;pointer + COUNTERX - 1 (left Wall)
	TBLRD*
	MOVFF TABLAT, WALL ;move to WALL (variable)
	return

EncountingWallLeft2:
	MOVLW low mazeY_TABLE2
    MOVWF TBLPTRL
    MOVLW high mazeY_TABLE2
    MOVWF TBLPTRH
    MOVLW upper mazeY_TABLE2
    MOVWF TBLPTRU ;set up look up pointer
	
	MOVF COUNTERX,W ;move counterX to WREG
	ADDWF TBLPTRL, F 
	DECF TBLPTRL, F ;pointer + COUNTERX - 1 (left Wall)
	TBLRD*
	MOVFF TABLAT, WALL ;move to WALL (variable)
	return
;}

;move left function end
;--------------------------------------------------------------------------

;--------------------------------------------------------------------------
;Display scrren function
Maze1:
	;maze1:
movlw B'10000000'
	movwf PORTC
	movlw B'00010000'
	movwf PORTD
	CALL Delay

movlw B'10111110'
	movwf PORTC
	movlw B'00010001'
	movwf PORTD
	CALL Delay
	
	
movlw B'10111110'
	movwf PORTC
	movlw B'00010010'
	movwf PORTD
	CALL Delay

movlw B'10111100'
	movwf PORTC
	movlw B'00010011'
	movwf PORTD
	CALL Delay

movlw B'00000001'
	movwf PORTC
	movlw B'00010100'
	movwf PORTD
	CALL Delay
	
movlw B'01101101'
	movwf PORTC
	movlw B'00010101'
	movwf PORTD
CALL Delay

movlw B'01101101'
	movwf PORTC
	movlw B'00010110'
	movwf PORTD
	CALL Delay

movlw B'01101101'
	movwf PORTC
	movlw B'00010111'
	movwf PORTD
	CALL Delay

movlw B'01101101'
	movwf PORTC
	movlw B'00001000'
	movwf PORTD
	CALL Delay

movlw B'01101101'
	movwf PORTC
	movlw B'00001001'
	movwf PORTD
	CALL Delay

movlw B'00000000'
	movwf PORTC
	movlw B'00001010'
	movwf PORTD
	CALL Delay

movlw B'11111010'
	movwf PORTC
	movlw B'00001011'
	movwf PORTD
	CALL Delay

movlw B'11111010'
	movwf PORTC
	movlw B'00001100'
	movwf PORTD
	CALL Delay

movlw B'10000010'
	movwf PORTC
	movlw B'00001101'
	movwf PORTD
	CALL Delay

movlw B'10111110'
	movwf PORTC
	movlw B'00001110'
	movwf PORTD
	CALL Delay

movlw B'00000000'
	movwf PORTC
	movlw B'00001111'
	movwf PORTD
	CALL Delay
	;maze end
	return

maze2:
	;maze2:
movlw B'11111100'
	movwf PORTC
	movlw B'00010000'
	movwf PORTD
	CALL Delay

movlw B'00000001'
	movwf PORTC
	movlw B'00010001'
	movwf PORTD
	CALL Delay
	
	
movlw B'01111101'
	movwf PORTC
	movlw B'00010010'
	movwf PORTD
	CALL Delay

movlw B'01111101'
	movwf PORTC
	movlw B'00010011'
	movwf PORTD
	CALL Delay

movlw B'00000001'
	movwf PORTC
	movlw B'00010100'
	movwf PORTD
	CALL Delay
	
movlw B'01111101'
	movwf PORTC
	movlw B'00010101'
	movwf PORTD
CALL Delay

movlw B'01111101'
	movwf PORTC
	movlw B'00010110'
	movwf PORTD
	CALL Delay

movlw B'00000001'
	movwf PORTC
	movlw B'00010111'
	movwf PORTD
	CALL Delay

movlw B'01111011'
	movwf PORTC
	movlw B'00001000'
	movwf PORTD
	CALL Delay

movlw B'01111011'
	movwf PORTC
	movlw B'00001001'
	movwf PORTD
	CALL Delay

movlw B'00000000'
	movwf PORTC
	movlw B'00001010'
	movwf PORTD
	CALL Delay

movlw B'01111110'
	movwf PORTC
	movlw B'00001011'
	movwf PORTD
	CALL Delay

movlw B'01111110'
	movwf PORTC
	movlw B'00001100'
	movwf PORTD
	CALL Delay

movlw B'00000000'
	movwf PORTC
	movlw B'00001101'
	movwf PORTD
	CALL Delay

movlw B'10110111'
	movwf PORTC
	movlw B'00001110'
	movwf PORTD
	CALL Delay

movlw B'00000000'
	movwf PORTC
	movlw B'00001111'
	movwf PORTD
	CALL Delay
	;maze2 end
	return


GameOverScreen:
	movlw B'11111110'
	movwf PORTC
	movlw B'00010000'
	movwf PORTD
	CALL Delay

movlw B'10000010'
	movwf PORTC
	movlw B'00010001'
	movwf PORTD
	CALL Delay
	
	
movlw B'10000010'
	movwf PORTC
	movlw B'00010010'
	movwf PORTD
	CALL Delay

movlw B'10000010'
	movwf PORTC
	movlw B'00010011'
	movwf PORTD
	CALL Delay

movlw B'10010010'
	movwf PORTC
	movlw B'00010100'
	movwf PORTD
	CALL Delay
	
movlw B'11110010'
	movwf PORTC
	movlw B'00010101'
	movwf PORTD
CALL Delay

movlw B'00010010'
	movwf PORTC
	movlw B'00010110'
	movwf PORTD
	CALL Delay

movlw B'00000000'
	movwf PORTC
	movlw B'00010111'
	movwf PORTD
	CALL Delay

movlw B'11111110'
	movwf PORTC
	movlw B'00001000'
	movwf PORTD
	CALL Delay

movlw B'10000010'
	movwf PORTC
	movlw B'00001001'
	movwf PORTD
	CALL Delay

movlw B'10000010'
	movwf PORTC
	movlw B'00001010'
	movwf PORTD
	CALL Delay

movlw B'10000010'
	movwf PORTC
	movlw B'00001011'
	movwf PORTD
	CALL Delay

movlw B'10010010'
	movwf PORTC
	movlw B'00001100'
	movwf PORTD
	CALL Delay

movlw B'11110010'
	movwf PORTC
	movlw B'00001101'
	movwf PORTD
	CALL Delay

movlw B'00010010'
	movwf PORTC
	movlw B'00001110'
	movwf PORTD
	CALL Delay

movlw B'00000000'
	movwf PORTC
	movlw B'00001111'
	movwf PORTD
	CALL Delay
	;Game Over Screen End
	return


PauseScreen:
	movlw B'01111110'
	movwf PORTC
	movlw B'00010000'
	movwf PORTD
	CALL Delay

movlw B'00001010'
	movwf PORTC
	movlw B'00010001'
	movwf PORTD
	CALL Delay
	
	
movlw B'00001110'
	movwf PORTC
	movlw B'00010010'
	movwf PORTD
	CALL Delay

movlw B'01111100'
	movwf PORTC
	movlw B'00010011'
	movwf PORTD
	CALL Delay

movlw B'00010010'
	movwf PORTC
	movlw B'00010100'
	movwf PORTD
	CALL Delay
	
movlw B'01111100'
	movwf PORTC
	movlw B'00010101'
	movwf PORTD
CALL Delay

movlw B'01111110'
	movwf PORTC
	movlw B'00010110'
	movwf PORTD
	CALL Delay

movlw B'01000000'
	movwf PORTC
	movlw B'00010111'
	movwf PORTD
	CALL Delay

movlw B'01111110'
	movwf PORTC
	movlw B'00001000'
	movwf PORTD
	CALL Delay

movlw B'01001110'
	movwf PORTC
	movlw B'00001001'
	movwf PORTD
	CALL Delay

movlw B'01001010'
	movwf PORTC
	movlw B'00001010'
	movwf PORTD
	CALL Delay

movlw B'01111010'
	movwf PORTC
	movlw B'00001011'
	movwf PORTD
	CALL Delay

movlw B'01111110'
	movwf PORTC
	movlw B'00001100'
	movwf PORTD
	CALL Delay

movlw B'01001010'
	movwf PORTC
	movlw B'00001101'
	movwf PORTD
	CALL Delay

movlw B'01001010'
	movwf PORTC
	movlw B'00001110'
	movwf PORTD
	CALL Delay

movlw B'00000000'
	movwf PORTC
	movlw B'00001111'
	movwf PORTD
	CALL Delay
	;Stage Select Screen end
	return

StageSelectScreen:
	movlw B'01111100'
	movwf PORTC
	movlw B'00010000'
	movwf PORTD
	CALL Delay

movlw B'01000000'
	movwf PORTC
	movlw B'00010001'
	movwf PORTD
	CALL Delay
	
	
movlw B'01000000'
	movwf PORTC
	movlw B'00010010'
	movwf PORTD
	CALL Delay

movlw B'01111100'
	movwf PORTC
	movlw B'00010011'
	movwf PORTD
	CALL Delay

movlw B'01010100'
	movwf PORTC
	movlw B'00010100'
	movwf PORTD
	CALL Delay
	
movlw B'01010100'
	movwf PORTC
	movlw B'00010101'
	movwf PORTD
CALL Delay

movlw B'00011100'
	movwf PORTC
	movlw B'00010110'
	movwf PORTD
	CALL Delay

movlw B'01100000'
	movwf PORTC
	movlw B'00010111'
	movwf PORTD
	CALL Delay

movlw B'01100000'
	movwf PORTC
	movlw B'00001000'
	movwf PORTD
	CALL Delay

movlw B'00011100'
	movwf PORTC
	movlw B'00001001'
	movwf PORTD
	CALL Delay

movlw B'01111100'
	movwf PORTC
	movlw B'00001010'
	movwf PORTD
	CALL Delay

movlw B'01010100'
	movwf PORTC
	movlw B'00001011'
	movwf PORTD
	CALL Delay

movlw B'01010100'
	movwf PORTC
	movlw B'00001100'
	movwf PORTD
	CALL Delay

movlw B'01111100'
	movwf PORTC
	movlw B'00001101'
	movwf PORTD
	CALL Delay

movlw B'01000000'
	movwf PORTC
	movlw B'00001110'
	movwf PORTD
	CALL Delay

movlw B'01000000'
	movwf PORTC
	movlw B'00001111'
	movwf PORTD
	CALL Delay
	;Pause Screen end
	return
;Display Screen end
;--------------------------------------------------------------------------


;--------------------------------------------------------------------------	
;Delay function
Delay: 
    movlw 0x01
    movwf DELAY_U
    LOP_1: movlw 0x1F
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
Delay2: 
    movlw 0x01
    movwf DELAY_U
    LOP_11: movlw 0xFF
    movwf DELAY_H
    LOP_22: movlw 0x40
    movwf DELAY_L
    LOP_33: decf DELAY_L, F
    bnz LOP_33
    decf DELAY_H, F
    bnz LOP_22
    decf DELAY_U, F
    bnz LOP_33
    return
Delay3: 
    movlw 0x01
    movwf DELAY_U
    LOP_111: movlw 0xF
    movwf DELAY_H
    LOP_222: movlw 0x40
    movwf DELAY_L
    LOP_333: decf DELAY_L, F
    bnz LOP_333
    decf DELAY_H, F
    bnz LOP_222
    decf DELAY_U, F
    bnz LOP_333
    return
;Delay function end
;--------------------------------------------------------------------------


ORG 0x2500 ;lookup table for pacman vertical movement
moveY_TABLE:
    DB B'10000000', B'01000000', B'00100000',B'00010000', B'00001000', B'00000100',B'00000010', B'00000001' ;lowest to largest


ORG 0x2600 ;lookup table for pacman horizontal movement
moveX_TABLE:
    DB B'00010000',B'00010001',B'00010010',B'00010011',B'00010100',B'00010101',B'00010110',B'00010111',B'00001000',B'00001001',B'00001010',B'00001011',B'00001100',B'00001101',B'00001110',B'00001111'

ORG 0x2700 ;for level 1 crash detection
mazeY_TABLE:
	DB B'10000000',B'10111110',B'10111110',B'10111100',B'00000001',B'01101101',B'01101101',B'01101101',B'01101101',B'01101101',B'00000000',B'11111010',B'11111010',B'10000010',B'10111110',B'00000000'

ORG 0x2400 ;for level 2 crash detection
mazeY_TABLE2:
	DB B'11111100',B'00000001',B'01111101',B'01111101',B'00000001',B'01111101',B'01111101',B'00000001',B'01111011',B'01111011',B'00000000',B'01111110',B'01111110',B'00000000',B'10110111',B'00000000'
	
END
