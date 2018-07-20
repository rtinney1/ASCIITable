;Project 2 COMP 2201
;Programmer: Randi Tinney
;Updated:    20 Mar 17
;
;Creates a table that scrolls through 0 - 255 showing the HEX, DEC, and ASCII character of each number
;Controls:
;	UP arrow key scrolls up
;	DOWN arrow key scrolls down
;	SHIFT+UP increases height of table
;	SHIFT+DOWN decreases height of table
;	CTRL+UP moves table up
;	CTRL+DOWN moves table down
;	CTRL+LEFT moves table left
;	CTRL+RIGHT moves table right
;	ALT changes color of table
;	ENTER changes border shape
;	ESC exits program

MyStack SEGMENT STACK
	DW 256 DUP(?)
MyStack ENDS

MyData SEGMENT
	topLeftCorner DW 1336    ;Coords x = 28, y = 8, changeable
	topRightCorner DW 1368   ;Coords x = 44, y = 8, changeable
	botLeftCorner DW 2776    ;Coords x = 28, y = 16, changeable
	botRightCorner DW 2808   ;Coords x = 44, y = 16, changeable
	
	screen DB 4000 DUP(?)    ;Allocates memory for what the screen looked like before table was inserted
	
	topLeftShape EQU 1       ;Gives position in dbleTableShape and sngleTableShape of exact shape
	botLeftShape EQU 2
	topRightShape EQU 3   
	botRightShape EQU 4
	midShape EQU 5
	sideShape EQU 6
	
	;order for shapes: blank, topLeft, botLeft, topRight, botRight, mid, side
	dbleTableShape DB 0, 201, 200, 187, 188, 205, 186
	sngleTableShape DB 0, 218, 192, 191, 217, 196, 179
	
	currShape DB 7 DUP(?)
	
	hexColHead DB "HEX", 0
	decColHead DB "DEC", 0
	asciiColHead DB "ASCII", 0
	
	hexColStart DW 1500       ;column
	decColStart DW 1508       ;starting
	asciiColStart DW 1516     ;locations
	
	startInt DW 'A'           ;int to start the table with 
	heightOfTable DW 7        ;tells the current height of the table
	widthOfTable EQU 15
	
	altFlag DB 0              ;0 = alt not pressed, 1 = alt pressed
	shiftFlag DB 0            ;0 = stretch up, 1 = stretch down
	currColor DB 01001111b    ;allows colors to cycle, starts out with white on red
	randNumSeed DB ?          ;seed for the random number
MyData ENDS

MyCode SEGMENT
	ASSUME CS:MyCode, DS: MyData
	
mainProc PROC
	MOV AX, MyData
	MOV DS, AX
	MOV AX, 0B800h
	MOV ES, AX                
	
	CALL remScreen
	
	
	MOV AH, 02h                 ;Get clock tick
	INT 1Ah
		
	MOV randNumSeed, DH         ;gets the current clock tick in seconds for random number generator
	
	MOV CX, 6
	LEA SI, dbleTableShape
	LEA DI, currShape
getCurrShape:
	MOV AX, [SI]
	MOV [DI], AX
	INC SI
	INC DI
	LOOP getCurrShape                       ;currShape now stores the same codes for the double lines
	
	CALL drawTable                          ;starting table is drawn
	
	CALL programLoop                        ;main program loop where it continues to check for user input
	;CALL testCtrl
	
	MOV AH, 4Ch                             ;end program with these two lines
	INT 21h
	
mainProc ENDP
;==========END mainProc==============

;==========START remScreen===========
remScreen PROC
;Stores the current DOSBox into the screen variable
;On exit, all registers perserved

	PUSH CX SI DI AX

	MOV CX, 4000         ;Storing bytes so need to loop 4000 times
	LEA SI, screen       ;Gets location for start of screen
	MOV DI, 0
	
remLoop:
	MOV AX, ES:[DI]      ;Moves what was on screen into AX
	MOV [SI], AX         ;Moves AX into the
	INC DI
	INC SI
	LOOP remLoop
	
	POP AX DI SI CX
	
	RET
remScreen ENDP
;==========END remScreen=============

;==========START drawScreen==========
drawScreen PROC
;On entry, calls on screen to redraw screen how it was
;On exit, all registers preserved

	PUSH AX CX SI DI
	
	MOV CX, 4000
	LEA SI, screen      ;Uses SI to get location of screen
	MOV DI, 0
	
redrawLoop:
	MOV AX, [SI]        ;Move data at location of screen into AX
	MOV ES:[DI], AX 
	INC DI
	INC SI
	LOOP redrawLoop
	
	POP DI SI CX AX
	
	RET
drawScreen ENDP
;==========END drawScreen============

;==========START drawTable===========
drawTable PROC
;On entry, uses currShape, topLeftCorner, topRightCorner, botLeftCorner, botRightCorner, 
;	currColor, and heightOfTable. These variables can change throughout the program 
;Calls on: drawScreen, fillTable
;On exit, table is created, all registers preserved

	PUSH DI SI CX AX
	
	CALL drawScreen
	
	LEA SI, currShape               ;Stores location of currShape in SI to get the shape of the table outlines
	MOV DI, topLeftCorner           ;Get current position for top left corner of table
	MOV AH, currColor               ;get current color 
	MOV AL, [SI + topLeftShape]     ;Adds the constant value for the topLeftShape to SI to get the correct shape from currShape
	MOV ES:[DI], AX                 ;Places the top left corner onto the screen
	MOV AL, [SI + midShape]         ;Adds the constant value for the midShape to SI to get the correct shape from currShape
	ADD DI, 2
	MOV ES:[DI], AX                 ;Places one middle piece onto the screen
	
	MOV CX, widthOfTable            ;Creates a counter based on the width of the table
topMiddleLoop:
	MOV ES:[DI], AX                 ;Places middle piece onto the screen   
	ADD DI, 2
	LOOP topMiddleLoop
	
	MOV DI, topRightCorner          ;Get current position for top right corner of table
	MOV AL, [SI + topRightShape]    ;Adds the constant value for the topRightShape to SI to get the correct shape from currShape
	MOV ES:[DI], AX                 ;Places the top right corner onto the screen
;TOP LINE IS DONE BY THIS SPOT
	
	MOV DI, topLeftCorner           ;Gets current position for top left corner of table
	ADD DI, 160                     ;moves down a row to begin drawing left side of table
	MOV AL, [SI + sideShape]        ;Adds the constant value for the sdeShape to SI to get the correct shape from currShape

	MOV CX, heightOfTable           ;Creates counter for current height of table
	INC CX                          
tableSideLeft:
	MOV ES:[DI], AX                 ;Places side onto screen
	ADD DI, 160                     ;Moving down the right hand side
	LOOP tableSideLeft
	
	MOV DI, topRightCorner          ;Gets current position for top right corner of table
	ADD DI, 160                     ;moves down a row to begin frawing right side of table
		
	MOV CX, heightOfTable           ;Creates coutner for current height of table
	INC CX
tableSideRight:
	MOV ES:[DI], AX                 ;Places side onto screen
	ADD DI, 160                     ;Moving down the right hand side
	LOOP tableSideRight
;SIDES ARE DONE BY THIS SPOT
	
	MOV DI, botLeftCorner           ;Gets current position for bottom left corner of table
	MOV AL, [SI + botLeftShape]     ;Adds the constant value for the botLeftShape to SI to get the correct shape from currShape
	MOV ES:[DI], AX                 ;Places bottom left corner onto screen
	MOV AL, [SI + midShape]         ;Adds the constant value for the midShape to SI to get the correct shape from currShape
	ADD DI, 2
	
	MOV CX, widthOfTable            ;Creates a counter from the width of table
botMiddleLoop:
	MOV ES:[DI], AX
	ADD DI, 2
	LOOP botMiddleLoop
;BOT LINE IS DONE BY THIS SPOT
	
	MOV DI, botRightCorner          ;Gets current position for bottom right corner of table
	MOV AL, [SI + botRightShape]    ;Adds the constant value for the botRightShape to SI to get the correct shape from currShape
	MOV ES:[DI], AX                 ;Places bottom right corner onto screen
	
	CALL fillTable
	
	POP AX CX SI DI
	
	RET
drawTable ENDP
;==========END drawTable=============

;==========START fillTable===========
fillTable PROC
;On entry, startInt will tell what values will be filled in the table
;Calls on: fillInCodes, drawHeader
;On exit, fills the table created in drawTable, all registers preserved

	PUSH SI DI CX AX BX
	
	CALL fillBlanks         
	
	MOV SI, hexColStart      ;Gets current location for the hex column
	LEA DI, hexColHead       ;Gets memory location for HEX header      
	
	CALL drawHeader
                                 ;HEX HEADER DRAWN BY THIS POINT
	
	MOV SI, decColStart      ;Gets current location for the dec column
	LEA DI, decColHead       ;Gets memory location for DEC header
	
	CALL drawHeader
                                 ;DEC HEADER DRAWN BY THIS POINT
	
	MOV SI, asciiColStart    ;Gets current location for the ascii column
	LEA DI, asciiColHead     ;Gets memory location for ASCII header
	
	CALL drawHeader
                                 ;ASCII HEADER DRAWN BY THIS POINT
                                 
;ALL HEADERS DRAWN BY THE POINT
	
	MOV BL, 16               ;Moving 16 into BL to pass into fillInCodes for integer to hex conversion
	MOV SI, hexColStart      ;Gets current location for hex column
	ADD SI, 164              ;Moves down a row and over to start output
	MOV CX, heightOfTable    ;Moving heightOfTable into CX for next three PROC CALLS

	CALL fillInCodes
                                 ;HEX COLUMN FILLED IN BY THIS POINT
	
	MOV BL, 10               ;Moving 10 into BL to pass into fillInCodes for interger to base 10 conversion
	MOV SI, decColStart      ;Gets current location for dec column
	ADD SI, 164              ;Moves down a row and over to start output
	
	CALL fillInCodes
                                 ;DEC COLUMN FILLED IN BY THIS POINT
	
	MOV SI, asciiColStart    ;Gets current location for ascii column
	ADD SI, 164              ;Moves down a row and over to start ouput
	
	CALL fillInASCII
				;ASCII COLUMN FILLED IN BY THIS POINT
	
	POP BX AX CX DI SI
	
	RET
	
fillTable ENDP
;==========END fillTable=============

;==========START fillBlanks==========
;On entry, passes topLeftCorner, currColor, widthOfTable, and heightOfTable to get current location of table
;On exit, fills in the table with a blank color to erase the previous table
;	All registers preserved
fillBlanks PROC
	PUSH BX AX CX SI
	
	MOV SI, topLeftCorner        ;Gets current locaation of top left corner of table
	ADD SI, 162                  ;Moves down a row and over a column so it is inside the table and won't bother the border
	MOV AH, currColor	     ;Get current color
	MOV AL, 0                    ;Ensure no characters are outputted to the screen

	MOV CX, heightOfTable        ;Create a counter from the height of the table
	INC CX
	
drawBlankOuterLoop:
	PUSH SI                      ;Stores the beginning of the inner table so we can reset from current position and add 160
	MOV BX, widthOfTable         ;Creates a counter from the widthOfTable
drawBlankInnerLoop:
	MOV ES:[SI], AX              ;Output blank spot into table
	ADD SI, 2
	DEC BX
	CMP BX, 0                    ;Check coutner
	JNE drawBlankInnerLoop
	
	POP SI                       ;Move back to beginning of row 
	ADD SI, 160                  ;Move down a row
	LOOP drawBlankOuterLoop
	
	POP SI CX AX BX
	RET
fillBlanks ENDP
;==========END fillBlanks============

;==========START fillInCodes=========
fillInCodes PROC
;On entry, uses startInt to convert unsigned integer to Hex
;	CX is passed for the loop, BL contains the number of the base to convert to,
;	SI is passed to know where to output the number on the screen
;On exit, fills in HEX or DEC column depending on the value in BL, all registers preserved
	
	PUSH AX SI CX DX DI
	
	MOV AX, startInt                 ;Erase everything in AX
	;MOV AL, startInt          ;Move starting integer into AL for division
	MOV DH, currColor         ;Going to output DX to screen so put current color into DH

convertLoopOuter:
	PUSH SI AX                ;Store starting position of output and the current integer for easy access
	MOV DI, 0                 ;Resets DI to use as counter for how many integers have been outputted

convertLoopInner:
	DIV BL                    ;Convert the integer in AL by whatever base was passed in BL
	CMP AH, 10                ;Compare the remainder of teh division to 10 to know if we need to change it to a letter or not
	JGE letter
	ADD AH, '0'               ;Converts the number to an ASCII code for output
	JMP bottomOfLoop
letter:
	ADD AH, 55                ;Add 55 to the remainder which would be 10-15 to get the correct letter to output (65 is ASCII for A)
bottomOfLoop:
	MOV DL, AH
	MOV ES:[SI], DX           ;Put the conversion onto th screen
	SUB SI, 2                 ;Move left to allow for another output
	INC DI                    ;Increase DI by 1 to see if we need to put a 0 infront of a letter for HEX
	MOV AH, 0                 ;Get rid of the remainder because it is no longer necessary and could screw up future divisions
	CMP AL, 0                 ;Check to see if the conversion is finished
	JG convertLoopInner
	
	CMP BL, 16                ;See if we converted to HEX
	JNE notHex
	CMP DI, 1                 ;See if we need to output a 0 infront of a HEX number
	JNE notHex
	ADD AL, '0'               ;Add '0' to AL because AL already contains a 0 so we need to convert it to ASCII
	MOV DL, AL
	MOV ES:[SI], DX           ;Output 0 to screen 

notHex:
	POP AX SI                 ;restores AX and SI so we can restart and move to next integer
	INC AX
	AND AX, 0FFh		  ;Make sure never get >255
continueAsIs:
	ADD SI, 160               ;Move to next row
	LOOP convertLoopOuter     ;Continues to fill in the column based on the CX counter passed into the PROC
	
	POP DI DX CX SI AX
	
	RET
fillInCodes ENDP
;==========END fillInCodes============

;==========START fillInASCII==========
fillInASCII PROC
;On entry, uses startInt to know which ASCII character to display,
;	CX is passed for the loop, SI is passed to know where to output
;On exit, fills in ASCII column, all registers preserved
	
	PUSH SI CX DX
	
	MOV DH, currColor          ;Gets current color for output
	MOV DL, BYTE PTR startInt  ;Gets starting integer

asciiLoop:
	MOV ES:[SI], DX            ;Outputs current character onto screen
	ADD SI, 160                ;Move down a row
	INC DL                     ;Move to next character
	LOOP asciiLOOP
	
	POP DX CX SI
	
	RET
fillInASCII ENDP
;==========END fillInASCII===========

;==========START drawHeader===========
drawHeader PROC
;On entry, passes DI for memory location of header and SI for draw location
;On exit, all registers preserved

	PUSH DX DI SI
	
	MOV DH, currColor        ;gets current color for output
	
headerLoop:
	MOV DL, DS:[DI]          ;move part of header into DL
	MOV ES:[SI], DX	         ;outputs current letter onto screen
	INC DI                   ;Moves to next letter in header
	ADD SI, 2             
	CMP [DI], BYTE PTR 0     ;Check to see if DI is at the end of the header
	JNE headerLoop
	
	POP SI DI DX

	RET
drawHeader ENDP
;==========END drawHeader============

;==========START programLoop=========
programLoop PROC
;On entry, creates an infinite loop to check for user input
;	calls on various procs for corresponding user input
;On exit, ESC was pressed, program will then end, all registers preserved

	PUSH AX BX CX
	
topOfLoop:
	MOV AH, 12h                     
	INT 16h                  ;Check for shifts pressed
	TEST AL, 8               ;Alt key pressed?
	JNZ changing             ;need to change color
	TEST AL, 4               ;Ctrl key pressed?
	JNZ ctrlDown             ;Figure out which arrow key was pressed too
	TEST AL, 2               ;Shift key pressed?
	JNZ shiftDown            ;Need to expand table
 	TEST AL, 1               ;Other shift key pressed?
	JNZ shiftDown            ;Need to expand table
	JMP getKey               ;No shifts pressed, go geck for another key

changing:
	CALL changeColor
	MOV altFlag, 1           ;Change altFlag to show that alt key was just pressed
	JMP topOfLoop
	
getKey:
	MOV AH, 11h
	INT 16h		         ;check to see if a key was pressed
	MOV altFlag, 0		 ;Change altFlah to show that alt key was not pressed
	JZ restartLoop           ;jumps to top of loop if no key was pressed

	MOV AH, 10h
	INT 16h                  ;reads key from buffer
	
	;MOV startInt, AL        ;Leaving this in to easily check
	;MOV BL, 16		 ;what the ASCII codes for each 
	;MOV SI, 180		 ;key stroke for all the 
	;CALL fillInCodes        ;buttons
	
	CMP AL, 1Bh              ;ESC?
	JE escHit
	
	CMP AX, 48E0h            ;UP arrow key?
	JNE checkForDOWN           
	
	CALL scrollTable
	JMP restartLoop

checkForDOWN:
	CMP AX, 50E0h            ;DOWN arrow key?
	JNE checkEnter             
	
	CALL scrollTable
	JMP restartLoop
	
checkEnter:
	CMP AX, 1C0Dh		 ;ENTER key?
	JNE restartLoop
	
	CALL changeBorder
	JMP restartLoop
	
shiftDown:
	CALL stretchTable
	JMP restartLoop

ctrlDown:
	CALL moveTable
	
restartLoop:
	JMP topOfLoop
	
escHit:
	POP CX BX AX
	RET
	
programLoop ENDP
;==========END programLoop=========

;==========START scrollTable=========
scrollTable PROC
;On entry, passes AX, either UP or DOWN was
;	pressed. Will change startInt accordingly.
;Calls drawTable
;On exit, redraws table for scroll, all registers preserved
	 
	INC startInt
	CMP AX, 48E0h		;UP arrow key?
	JNE leaveScrollProc
	SUB startInt, 2

leaveScrollProc:
	AND startInt, 0FFh
	CALL drawTable
	
	RET
scrollTable ENDP
;==========END scrollTable===========

;==========START stretchTable========
stretchTable PROC
;On entry, passes BX, either UP or DOWN + SHIFT was pressed. Checks shiftFlag to know how to stretch table
;	Will change heightOfTable, corners, and heading starts accordingly.
;	calls drawTable
;On exit, redraws table for stretch
	
	MOV AH, 11h
	INT 16h		          ;double check to see if a key was pressed
	JNZ getKeyPress
	JMP leaveStretchProc

getKeyPress:
	MOV AH, 10h 
	INT 16h                   ;check which key was pressed
	
	CMP AX, 48E0h             ;UP arrow key?
	JE incTop
	CMP AX, 50E0h             ;DOWN arrow key?
	JE decreaseHeight
	JMP leaveStretchProc
	
incTop:
	CMP shiftFlag, 0          ;If 0, move top, if not, move bottom
	JNE incBottom
	CMP topLeftCorner, 158    ;Compare table corner to top row
	JLE incBottom
doubleCheckIncrease:
	CMP topLeftCorner, 158    ;Need this just to makes sure we cannot increase the table
	JG  increaseTop
	JMP leaveStretchProc
increaseTop:
	SUB topLeftCorner, 160    ;Need to sub 160 from all these values
	SUB topRightCorner, 160   ;to move everything up a row to increase height 
	SUB hexColStart, 160
	SUB decColStart, 160
	SUB asciiColStart, 160
	INC heightOfTable         ;Increase the height of the table for redrawing purposes
	MOV shiftFlag, 1          ;Move bottom next time
	JMP redrawStr
incBottom:
	CMP botLeftCorner, 3840   ;Compare table corner to bottom row
	JGE doubleCheckIncrease   
	ADD botLeftCorner, 160    ;Add 160 to these two values to stretch the bottom
	ADD botRightCorner, 160   ;of the table
	INC heightOfTable         ;increase the height of the table for redrawing purposes
	MOV shiftFlag, 0          ;Move top next time
	JMP redrawStr
	
decreaseHeight:
	CMP heightOfTable, 4      ;Makes sure size of table >= 4
	JLE leaveStretchProc
	CMP shiftFlag, 0          ;If 0, move top, if not, move bottom
	JNE decBottom
	ADD topLeftCorner, 160    ;Add 160 to all these values to move the top of table down
	ADD topRightCorner, 160   ;a row
	ADD hexColStart, 160
	ADD decColStart, 160
	ADD asciiColStart, 160
	DEC heightOfTable         ;decrease the height of the table for redrawing purposes
	MOV shiftFlag, 1          ;Move bottom next time
	JMP redrawStr
decBottom:
	SUB botLeftCorner, 160    ;Sub 160 to these two values to shift bottom line
	SUB botRightCorner, 160   ;up one row
	DEC heightOfTable         ;decrease the height of the table for redrawing purposes
	MOV shiftFlag, 0          ;Move top next time

redrawStr:
	CALL drawTable
leaveStretchProc:
	
	RET
stretchTable ENDP
;==========END stretchTable==========

;==========START moveTable============
moveTable PROC
;On entry, checks to see whether UP, DOWN, LEFT, or RIGHT was pressed. 
;	Will change all four corners and colStart s accordingly.
;	calls drawTable
;On exit, redraws table for move

	PUSH BX AX
	
	MOV AH, 11h
	INT 16h		          ;check to see if a key was pressed
	JNZ contInMoveTable
	JMP leaveMoveProc
	
contInMoveTable:
	MOV AH, 10h
	INT 16h                   ;Check to see which key was presed
	
	CMP AX, 8DE0h             ;UP arrow key?
	JE moveUpDown
	CMP AX, 91E0h             ;DOWN arrow key?
	JE moveUpDown

moveLeftRight:
	MOV BX, 2                 ;Puts 2 into BX so we can easily move either left or right across the screen
	CMP AX, 73E0h             ;LEFT arrow key?
	JE moveLeft
	CMP AX, 74E0h             ;RIGHT arrow key?
	JE moveRight
	JMP leaveMoveProc
	
moveRight:
	PUSH DX
	CALL boundsCheck          
	CMP DX, 1                 ;Return from boundsCheck means we can't move
	POP DX
	JNE continue
	JMP leaveMoveProc
continue:
	ADD botRightCorner, BX    ;Essentially adds 2 to all these values to shift
	ADD botLeftCorner, BX     ;the table
	ADD topRightCorner, BX
	ADD topLeftCorner, BX
	ADD hexColStart, BX
	ADD decColStart, BX
	ADD asciiColStart, BX
	JMP redrawMv
	
moveLeft:
	CALL boundsCheck
	CMP DX, 1		  ;Return from boundsCheck means we can't move
	JE leaveMoveProc
	SUB topRightCorner, BX    ;Essentially subs 2 to all these values to shift
	SUB topLeftCorner, BX     ;the table
	SUB botRightCorner, BX
	SUB botLeftCorner, BX
	SUB hexColStart, BX
	SUB decColStart, BX
	SUB asciiColStart, BX
	JMP redrawMv

moveUpDown:
	MOV BX, 160               ;Puts 160 into BX to easily shift table up and down the screen
	CMP AX, 91E0h             ;DOWN arrow key?
	JNE moveUp

moveDown:
	CMP botLeftCorner, 3840   ;Compares table corner to bottom row to make sure we can move down
	JGE leaveMoveProc
	ADD botRightCorner, BX    ;Essentially adds 160 to all these values to
	ADD botLeftCorner, BX	  ;move the table down the screen
	ADD topRightCorner, BX
	ADD topLeftCorner, BX
	ADD hexColStart, BX
	ADD decColStart, BX
	ADD asciiColStart, BX
	JMP redrawMv
	
moveUp:
	CMP topLeftCorner, 158    ;Compares table corner to top row to make sure we can move up
	JLE leaveMoveProc
	SUB topRightCorner, BX    ;Essentially subs 160 to all these values to
	SUB topLeftCorner, BX     ;move the table up the screen
	SUB botRightCorner, BX
	SUB botLeftCorner, BX
	SUB hexColStart, BX
	SUB decColStart, BX
	SUB asciiColStart, BX
	
redrawMv:
	CALL drawTable
leaveMoveProc:
	
	POP AX BX
	
	RET
moveTable ENDP
;==========END moveTable=============

;==========START changeColor=========
changeColor PROC
;On entry, alt key was pressed so must change color of background
;	Uses random number generator to get a random color
;On exit, increases currColor by 1, calls clrScreen and drawTable

	PUSH AX BX 
	
	CMP altFlag, 1
	JE leaveChangeColor
	
	MOV AL, randNumSeed         ;r0
	MOV AH, 0
	MOV BL, 10                  ;for division
	DIV BL			    
	ADD AH, 5		    ;r1 := r0 % 10 + 5
	MOV AL, AH
	MOV AH, 0
	DIV BL
	ADD AH, 5           	    ;r2 := r1 % 10 + 5
	ADD currColor, AH           ;Add random number (r2) to currColor
	AND currColor, 01111111b    ;Gets rid of blinking
	
	CALL drawTable
leaveChangeColor:
	
	POP BX AX
	RET
changeColor ENDP
;==========END changeColor===========

;==========START boundsCheck=========
boundsCheck PROC
;On entry, compares table corners to screen boundaries and makes sure that the table can
;	move in whatever direction it is trying to move to. AX contains previous key press.
;On exit, changes DX, 0 if able to move, 1 if not, no other registers changed

	PUSH AX CX BX
	
	MOV BX, AX		 ;Get key press from AX
	MOV DX, 0                ;Make sure DX starts at 0 for accurate division
	MOV CX, 160              ;All left hand side is a multiple of 160 so must divide by 160
	CMP BX, 74E0h            ;RIGHT arrow key?
	JE checkGoingRight       ;Need to compare right side instead of left
	MOV AX, topLeftCorner    ;Get current topLeftCorner location
	DIV CX
	CMP DX, 0		 ;See if there is a remainder or not
	JE noMove		 ;No remainder means we are at the edge so we can't move
	MOV DX, 0		 ;Move 0 into DX to show that we can move
	JMP done
	
checkGoingRight:
	MOV AX, topRightCorner   ;Get current topRightCorner location
	DIV CX
	CMP DX, 158              ;See if there is a remainder of 158 which means you are on the right hand side
	JE noMove                ;Remainder of 158 means we are at the edge so we can't move
	MOV DX, 0                ;Move 0 into DX to show that we can move
	
	JMP done
noMove:
	MOV DX, 1                ;Move 1 into DX to show that we can't move
done:	
	POP BX CX AX
	
	RET
boundsCheck ENDP
;==========END boundsCheck===========

;==========START changeBorder========
changeBorder PROC
;On entry, checks current table shape and changes to the opposite
;	Calls clrScreen and drawTable
;On exit, change the outline of the table

	PUSH DI SI AX BX CX
	
	LEA SI, dbleTableShape      ;Gets memory location of dbleTableShape
	LEA DI, currShape           ;Gets memory location of currShape
	MOV AX, [SI]                ;Moves first value of dbleTableShape into AX
	MOV BX, [DI]                ;Moves first value of currShape into BX
	CMP AX, BX                  ;Compares the two values to see what the current shape of the outline is
	JE changeToSingleShape
	
	MOV CX, 6
	LEA SI, dbleTableShape
	LEA DI, currShape
getDbleShape:
	MOV AX, [SI]
	MOV [DI], AX
	INC SI
	INC DI
	LOOP getDbleShape            ;currShape now stores the same values as the double shape
	JMP leaveChangeProc
	
changeToSingleShape:
	MOV CX, 6
	LEA SI, sngleTableShape
	LEA DI, currShape
getSngleShape:
	MOV AX, [SI]
	MOV [DI], AX
	INC SI
	INC DI
	LOOP getSngleShape          ;currShape now stores the same values as the single shape
	
leaveChangeProc:
	CALL drawTable
	
	POP CX BX AX SI DI
	
	RET
changeBorder ENDP
;==========END changeBorder==========

MyCode ENDS
END mainProc
