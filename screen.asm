DOSSEG
.MODEL SMALL
.STACK 100H
.DATA
TIME_AUX DB 0 						;VARIABLE USED WHEN CHECKING IF TIME HAS CHANGED
LOADING_TIMER DB 0					;VARIABLE USED WHEN CHECKING IF LOADING TIME HAS CHANGED

BAR_X DW 64H 						;X POS (COL) OF THE BAR (64H = 100D)
BAR_Y DW 64H 						;Y POS (ROW) OF THE BAR (64H = 100D)
BAR_SIZE DW 04H 					;SIZE OF THE BAR (4 x 4) PIXELS

NEXT_LINE DB 00H					;CURRENT CURSOR LINE POSITION
CURSOR_COL_POS DB 04H				;TO TRACK THE CURSOR COL POS FOR DISPLAYING MORSE CHARS WITH SPACE
CURSOR_ROW_POS DB 06H				;TO DISPLAY THE MORSE CODE ON NEW LINE IF IT EXCEEDS WINDOW SIZE
COUNT_CHARS DB 00H					;COUNTING CHARACTERS ON A LINE

PROJ_NAME_ONE DB 'IDDY UMPTY CONVERTER$'
PROJ_NAME_TWO DB '(MORSE ENCODER)$'
TEXT_MORSE_TITLE DB 'MORSE CODE:$' 						;TITLE OF THE DISPLAYIN MORSE CODE SCREEN
TEXT_EXIT_CONVERTOR DB 'EXIT CONVERTOR - E KEY','$'		;TEXT with THE EXIT CONVERTOR MESSAGE
TEXT_REGENERATE DB 'START AGAIN - R KEY','$' 			;TEXT WITH THE RE-GENERATE MORSE CODE (WITH DIFF INPUT STRING) MESSAGE

DISPLAY_PERCENTAGE DB '0','0','0','%','$' 	;TEXT WITH PERCENTAGE to hold 3 digits
LOADING_PERCENTAGE DW 0 					;CURRENT LOADING PERCENTAGE

;VARIABLES TO SEPERATE DIGITS FROM LOADING_PERCENTAGE
QUOTIENT DB 0 
REMAINDER DB 0

KEY_PRESS_MSG DB 'PRESS ANY KEY TO CONTINUE...$'			;Display this before moving to the new screen
INPUT_SIZE_PROMPT DB 'INPUT TOO LONG! MAX 100 CHARACTERS$'  ;Display this if input size exceeds
PROMPT DB 'Enter a string (A-Z, a-z, or 0-9): $'			; Display this message before user input
;VALID DB 0DH, 0AH, 'Valid input!$'							; IF user input is valid. Carriage Return (CR) → 0DH (13 in decimal) Line Feed (LF) → 0AH (10 in decimal)
INVALID DB 'Invalid input! Please try again.$'				; Message displayed when user input is invalid.

BUFFER DB 102 DUP('$')		; Maximum length of the input (100 CHARACTERS + ENTER + NULL terminator).
INPUT_SIZE DB 0				; Stores the actual size of the input (excluding ENTER)

SPACE DB ' $'				;A SPACE printed between Morse code outputs like .- ...

VALID DB 0 					;BOOLEAN VARIABLE TO VALIDATE THE INPUT STRING (0 -> INVALID, 1 -> VALID)
EXITING_CONVERTOR DB 0 		;BOOLEAN VARIABLE OF THE EXIT CONVERTOR STATUS (0 -> RE-GENERATE, 1 -> EXIT)

CHARACTERS DB 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890'
; Lookup table containing valid input CHARACTERS (A-Z and 0-9)
;Instead of assigning a separate memory location for each character, we store all CHARACTERS contiguously in memory
;morseTable stores pointers (memory addresses of morse1, morse2, etc and morse1, morse2 actually stores the morsecode values.
	
morseTable DW morse0, morse1, morse2, morse3, morse4, morse5, morse6, morse7, morse8, morse9
		DW morse10, morse11, morse12, morse13, morse14, morse15, morse16, morse17, morse18, morse19
        DW morse20, morse21, morse22, morse23, morse24, morse25, morse26, morse27, morse28, morse29
        DW morse30, morse31, morse32, morse33, morse34, morse35	
		
;We first define Morse codes in DB because Morse sequences fit within 1 byte
;We store them in DW later to maintain fixed-size storage and simplify processing
;DW helps handle longer symbols and allows faster access using 16-bit registers 

    morse0 DB ".- $"        ; Morse code for 'A'
    morse1 DB "-... $"      ; Morse code for 'B'
    morse2 DB "-.-. $"      ; Morse code for 'C'
    morse3 DB "-.. $"       ; Morse code for 'D'
    morse4 DB ". $"         ; Morse code for 'E'
    morse5 DB "..-. $"      ; Morse code for 'F'
    morse6 DB "--. $"       ; Morse code for 'G'
    morse7 DB ".... $"      ; Morse code for 'H'
    morse8 DB ".. $"        ; Morse code for 'I'
    morse9 DB ".--- $"      ; Morse code for 'J'
    morse10 DB "-.- $"      ; Morse code for 'K'
    morse11 DB ".-.. $"     ; Morse code for 'L'
    morse12 DB "-- $"       ; Morse code for 'M'
    morse13 DB "-. $"       ; Morse code for 'N'
    morse14 DB "--- $"      ; Morse code for 'O'
    morse15 DB ".--. $"     ; Morse code for 'P'
    morse16 DB "--.- $"     ; Morse code for 'Q'
    morse17 DB ".-. $"      ; Morse code for 'R'
    morse18 DB "... $"      ; Morse code for 'S'
    morse19 DB "- $"        ; Morse code for 'T'
    morse20 DB "..- $"      ; Morse code for 'U'
    morse21 DB "...- $"     ; Morse code for 'V'
    morse22 DB ".-- $"      ; Morse code for 'W'
    morse23 DB "-..- $"     ; Morse code for 'X'
    morse24 DB "-.-- $"     ; Morse code for 'Y'
    morse25 DB "--.. $"     ; Morse code for 'Z'
    morse26 DB ".---- $"    ; Morse code for '1'
    morse27 DB "..--- $"    ; Morse code for '2'
    morse28 DB "...-- $"    ; Morse code for '3'
    morse29 DB "....- $"    ; Morse code for '4'
    morse30 DB "..... $"    ; Morse code for '5'
    morse31 DB "-.... $"    ; Morse code for '6'
    morse32 DB "--... $"    ; Morse code for '7'
    morse33 DB "---.. $"    ; Morse code for '8'
    morse34 DB "----. $"    ; Morse code for '9'
    morse35 DB "----- $"    ; Morse code for '0'

.CODE
MAIN PROC
	MOV AX,@DATA
	MOV DS,AX
	
	CALL CLEAR_SCREEN
	
	CALL DRAW_WELCOME_SCREEN_UI 		;DRAW THE USER INTERFACE
	
	;we need to call "DRAW_BAR" after some time to increase it's width
	;to acheive this we need to use time. we update the bar's width,and erase the screen. WE clear the screen upon completion
	;to give the illusion of movement
	;we will need to get system time and check if 100th of second has passed
	
	CHECK_TIME:
		
		CMP EXITING_CONVERTOR,01H	;IF TRUE->EXIT PROGRAM, FALSE -> RE-GENERATE MORSE CODE
		JE START_EXIT_PROCESS
		JMP LOAD_INPUT_SCREEN
		
		MOV AH,2CH 			;GET system time FUNCTION
		INT 21H 			;Returns CH = hours (0-23),CL = minutes (0-59), DH = seconds (0-59) , and DL = 1/100 SECONDS
		
		CMP DL,TIME_AUX 	;IS THE CURRENT TIME = PREV ONE(TIME_AUX) ?
		JE CHECK_TIME 		;IF IT IS EQUAL,CHECK AGAIN
		
	LOAD_INPUT_SCREEN:
		CALL DRAW_INPUT_SCREEN_UI
		
		CMP VALID,01H			;check VALIDITY, 1 -> valid, 0 -> invalid
		JE SHOW_MORSE_CODE		;GENERATE MORSE CODE if valid
		JMP LOAD_INPUT_SCREEN	;IF INPUT IS INVALID,RE-INPUT THE STRING
		
	SHOW_MORSE_CODE:
		CALL DRAW_MORSE_CODE_SCREEN_UI	;DISPLAY THE MORSE CODE OF THE INPUT ON NEW SCREEN
		JMP CHECK_TIME					;CHECK IF USER WANTS TO RE-GENERATE OR EXIT PROGRAM
		
	START_EXIT_PROCESS:
		CALL EXIT_CONVERTOR				;EXITS THE PROGRAM
	
	MOV AH,4CH
	INT 21H
MAIN ENDP

DRAW_LOADING_BAR PROC 			;PROCEDURE TO DRAW THE INITIAL BAR AS A BOX OF 4X4 PIXELS
	
	MOV CX,BAR_X 				;SET THE INITIAL COLUMN OF THE PIXEL
	MOV DX,BAR_Y 				;SET THE INITIAL ROW OF THE PIXEL
	
	;DRAWING THE (4 x 4) BAR USING THIS PIXEL
	DRAW_BAR_HORIZONTAL:
		MOV AH,0CH 				;SET THE CONFIGURATION TO WRITING A PIXEL
		MOV AL,0FH 				;SET WHITE COLOR OF THE PIXEL
		MOV BH,00H 				;SET THE PAGE NUMBER 
		INT 10H
		
		INC CX 					; CX = CX + 1 incrementing column
		; CX - BAR_X > BAR_SIZE (T: MOVE TO THE NEXT ROW, F: INC COLUMN)
		MOV AX,CX 				;STORE THE VALUE SO THAT IT DOES NOT GETS LOST
		SUB AX,BAR_X
		CMP AX,BAR_SIZE
		JNG DRAW_BAR_HORIZONTAL ;IF AX < BAR_SIZE, "JUMP NOT GREATER" LOOPING TO DRAW HORIZONTALLY UNTIL IT = INITIAL BAR_SIZE
		
		MOV CX,BAR_X 			;IT GOES BACK TO INITIAL THE COL
		INC DX 					;incrementing THE ROW
		; dX - BAR_Y > BAR_SIZE (T: EXIT THIS PROCEDURE, F: INC ROW)
		MOV AX,DX 				;STORE THE VALUE SO THAT IT DOES NOT GETS LOST
		SUB AX,BAR_Y 
		CMP AX,BAR_SIZE 		;CHECKING TO DRAW VERTICALLY UNTIL IT = INITIAL BAR_SIZE
		JNG DRAW_BAR_HORIZONTAL
		
	RET
DRAW_LOADING_BAR ENDP

UPDATE_LOADING_PERCENTAGE PROC
	XOR AX,AX 					;CLEANING THE AX REGISTER
	MOV AX,LOADING_PERCENTAGE	;given for e.g. LOADING_PERCENTAGE = 2 points => AX,2
	
	;dividing 3-digit per by 10 to seperate each digit
	MOV BL,10
	DIV BL
	;QUOTIENT = AL, REMAINDER = AH
	MOV QUOTIENT,AL
	MOV REMAINDER,AH
	
	;now before printing to the screen, we convert the decimal value to the ascii code CHARACTER
	;we can do this by adding 48 or 30H to AL (number to ascii)
	
	ADD REMAINDER,30H
	MOV AL,REMAINDER
	MOV [DISPLAY_PERCENTAGE + 2],AL	 ;move the value of AL to the address of the 3RD index(UNITS PLACE) of this variable
	
	MOV AL,QUOTIENT
	DIV BL
	MOV QUOTIENT,AL
	MOV REMAINDER,AH
	ADD REMAINDER,30H
	MOV AL,REMAINDER
	MOV [DISPLAY_PERCENTAGE + 1],AL  ;move the value of AL to the address of the 2ND index (TENTHS PLACE) of this variable
	
	MOV AL,QUOTIENT
	DIV BL
	MOV REMAINDER,AH
	ADD REMAINDER,30H
	MOV AL,REMAINDER
	MOV [DISPLAY_PERCENTAGE],AL		;move the value of AL to the address of the 1ST index (HUNDRETHS PLACE) of this variable
	
	;DISPLAY THE PERCENTAGE
	
	MOV AH,02H 						;SET CURSOR POSITION FUNCTION
	MOV BH,00H 						;SET PAGE NUMBER
	MOV DH,0FH 						;ROW POS OF CURSOR
	MOV DL,12H 						;COL POS OF CURSOR
	INT 10H
	
	MOV AH,09H 								;WRITE STRING TO STANDARD OUTPUT
	MOV DX,OFFSET DISPLAY_PERCENTAGE		;GIVE THE ADDRESS OF THE 1ST POSITION OF STRING
	INT 21H									;PRINT THE STRING
	
	RET
UPDATE_LOADING_PERCENTAGE ENDP

DRAW_WELCOME_SCREEN_UI PROC
	
	;DISPLAY THE PROJ_NAME_ONE
	
	MOV AH,02H 						;SET CURSOR POSITION FUNCTION
	MOV BH,00H 						;SET PAGE NUMBER
	MOV DH,05H 						;ROW POS OF CURSOR
	MOV DL,0AH 						;COL POS OF CURSOR
	INT 10H
	
	MOV AH,09H 								;WRITE STRING TO STANDARD OUTPUT
	MOV DX,OFFSET PROJ_NAME_ONE				;GIVE THE ADDRESS OF THE 1ST POSITION OF STRING
	INT 21H									;PRINT THE STRING
	
	;DISPLAY THE PROJ_NAME_TWO
	
	MOV AH,02H 						;SET CURSOR POSITION FUNCTION
	MOV BH,00H 						;SET PAGE NUMBER
	MOV DH,08H 						;ROW POS OF CURSOR
	MOV DL,0CH 						;COL POS OF CURSOR
	INT 10H
	
	MOV AH,09H 								;WRITE STRING TO STANDARD OUTPUT
	MOV DX,OFFSET PROJ_NAME_TWO				;GIVE THE ADDRESS OF THE 1ST POSITION OF STRING
	INT 21H									;PRINT THE STRING
	
	TIMER:
		MOV AH,2CH 			;GET system time FUNCTION
		INT 21H 			;Returns CH = hours (0-23),CL = minutes (0-59), DH = seconds (0-59) , and DL = 1/100 SECONDS
		
		CMP DL,LOADING_TIMER 	;IS THE CURRENT TIME = PREV ONE(LOADING_TIMER) ?
		JE TIMER 				;IF IT IS EQUAL,CHECK AGAIN
		
		;IF IT IS DIFFERENT, DRAW,MOVE ETC.
		MOV LOADING_TIMER,DL 	;UPDATE LOADING_TIMER VAR TO CURRENT 1/100ths OF second
		INC BAR_X
		CALL DRAW_LOADING_BAR
		INC LOADING_PERCENTAGE
		CALL UPDATE_LOADING_PERCENTAGE ;UPDATING THE LOADING_PERCENTAGE
		CMP LOADING_PERCENTAGE,100 		;CHECK IF THE LOADING_PERCENTAGE == 100
		JE  EXIT_WELCOME_SCREEN
		JMP TIMER 		; AFTER EVERYTHING, CHECK TIME AGAIN
		
	EXIT_WELCOME_SCREEN:
	
		;DISPLAY THE PROMPT TO MOVE TO THE NEW SCREEN
		MOV AH,02H 						;SET CURSOR POSITION FUNCTION
		MOV BH,00H 						;SET PAGE NUMBER
		MOV DH,13H 						;ROW POS OF CURSOR
		MOV DL,06H 						;COL POS OF CURSOR
		INT 10H
		
		MOV AH,09H 						;WRITE STRING TO STANDARD OUTPUT
		MOV DX,OFFSET KEY_PRESS_MSG		;GIVE THE ADDRESS OF THE 1ST POSITION OF STRING
		INT 21H							;PRINT THE STRING
		
		MOV AH,00H						;WAIT FOR KEYPRESS TO MOVE TO THE NEW SCREEN
		INT 16H
		
		RET
DRAW_WELCOME_SCREEN_UI ENDP

DRAW_INPUT_SCREEN_UI PROC

	CALL CLEAR_SCREEN
	
	;DISPLAY THE PROMPT
	
	MOV AH,02H 						;SET CURSOR POSITION FUNCTION
	MOV BH,00H 						;SET PAGE NUMBER
	MOV DH,04H 						;ROW POS OF CURSOR
	MOV DL,04H 						;COL POS OF CURSOR
	INT 10H
	
	MOV AH,09H 						;WRITE STRING TO STANDARD OUTPUT
	MOV DX,OFFSET PROMPT			;GIVE THE ADDRESS OF THE 1ST POSITION OF STRING
	INT 21H							;PRINT THE STRING
	
	;MOVING THE CURSOR TO DIFFERENT LINE
	MOV AH,02H 						;SET CURSOR POSITION FUNCTION
	MOV BH,00H 						;SET PAGE NUMBER
	MOV DH,08H 						;ROW POS OF CURSOR
	MOV DL,04H 						;COL POS OF CURSOR
	INT 10H
	
	MOV NEXT_LINE,DH				;STORING THE CURRENT LINE POSITION WHERE THE CURSOR BLINKS
	
	MOV SI,OFFSET BUFFER			;STORE THE ADDRESS OF FIRST INDEX IN SOURCE INDEX REGISTER
	READ_INPUT_LOOP:
		MOV AH,00H					;Wait for Keypress and Read Character
		INT 16H
		CMP AL,0DH					;CHECK FOR ENTER KEYPRESS
		JE END_INPUT				;IF ENTER KEY IS PRESSED, DISPLAY THE INPUT
		
		MOV [SI],AL					;STORE CHARACTERS IN BUFFER
		INC INPUT_SIZE				;COUNT THE LENGTH OF STRING
		INC COUNT_CHARS
		CMP COUNT_CHARS,30
		JE MOVE_TO_NEXT_LINE
		CMP INPUT_SIZE,100
		JG	EXCEED_INPUT_SIZE		;IF INPUT SIZE EXCEEDS 100 CHARACTERS, DISPLAY INVALID INPUT MSG
		INC SI						;MOVE TO NEXT POSITION
		
		;SHOW THE INPUT TAKEN
		MOV DL,AL					;CHARACTER TO DISPLAY
		MOV AH,02H
		INT 21H
		JMP READ_INPUT_LOOP			;CONTINUE TO TAKE INPUT UNTIL ENTER KEY IS PRESSED
		
	EXCEED_INPUT_SIZE:
	
		;PROMPT THE USER THAT INPUT SIZE HAS BEEN EXCEEDED
		;DRAW THE INPUT UI AGAIN TO RETAKE INPUT
	
		CALL CLEAR_SCREEN
		
		MOV INPUT_SIZE,00H
		
		MOV AH,02H 						;SET CURSOR POSITION FUNCTION
		MOV BH,00H 						;SET PAGE NUMBER
		MOV DH,06H 						;ROW POS OF CURSOR
		MOV DL,04H 						;COL POS OF CURSOR
		INT 10H
		
		MOV AH,09H 							;WRITE STRING TO STANDARD OUTPUT
		MOV DX,OFFSET INPUT_SIZE_PROMPT		;GIVE THE ADDRESS OF THE 1ST POSITION OF STRING
		INT 21H								;PRINT THE STRING
		
		MOV AH,02H 						;SET CURSOR POSITION FUNCTION
		MOV BH,00H 						;SET PAGE NUMBER
		MOV DH,08H 						;ROW POS OF CURSOR
		MOV DL,04H 						;COL POS OF CURSOR
		INT 10H
		
		MOV AH,09H 						;WRITE STRING TO STANDARD OUTPUT
		MOV DX,OFFSET KEY_PRESS_MSG		;GIVE THE ADDRESS OF THE 1ST POSITION OF STRING
		INT 21H							;PRINT THE STRING
		
		MOV SI,OFFSET BUFFER			;Reset SI to the start of the BUFFER.
		MOV COUNT_CHARS,00H				;RESET TO COUNT CHARACTERS ON THE NEW LINE
		
		MOV AH,00H						;WAIT FOR KEYPRESS TO MOVE TO THE NEW SCREEN
		INT 16H
		
		MOV VALID,00H					;SET VALIDITY TO FALSE
		RET
	
	MOVE_TO_NEXT_LINE:
		;MOVING THE CURSOR TO DIFFERENT LINE
		INC NEXT_LINE
		MOV AH,02H 						;SET CURSOR POSITION FUNCTION
		MOV BH,00H 						;SET PAGE NUMBER
		MOV DH,NEXT_LINE 				;ROW POS OF CURSOR
		MOV DL,04H 						;COL POS OF CURSOR
		INT 10H
		
		MOV COUNT_CHARS,00H				;RESET TO COUNT CHARACTERS ON THE NEW LINE
		JMP READ_INPUT_LOOP
	
	END_INPUT:
		MOV AL,'$'
		MOV [SI],AL		;NULL-TERMINATOR APPENDED AT THE END OF THE INPUT string
		
		CALL VALIDATE_INPUT				;VALIDATE THE INPUT
		
	RET
	
DRAW_INPUT_SCREEN_UI ENDP

VALIDATE_INPUT PROC
	
	;VALIDATE THE input
	CMP INPUT_SIZE,00H				;IF INPUT_SIZE == 0 -> INVALID INPUT, ELSE VALID input
	JE INVALID_INPUT
	
	MOV SI,OFFSET BUFFER			;MOVE THE STARTING ADDRESS INTO SI for further processing
	
	CHECK_LOOP:
		MOV AL, [SI]
		CMP AL, '$'
		JE EXIT_VALIDATE_INPUT			;Check for the null terminator ('$'). If found, input is valid. WE EXIT THIS PROCEDURE

		CMP AL, 'a'  
		JB CHECK_DIGIT
		CMP AL, 'z'
		JA CHECK_DIGIT
		SUB AL, 32						;Convert lowercase letters (a-z) to uppercase.

		CHECK_DIGIT:
		
			CMP AL, ' '					; Check if character is a SPACE (' ')
			JE CONTINUE
			
			CMP AL, '0' 				; Check if character is a digit (0-9)
			JB INVALID_INPUT
			CMP AL, '9'
			JBE CONTINUE
			
			CMP AL, 'A' 				; Check if character is uppercase letter (A-Z)
			JB INVALID_INPUT
			CMP AL, 'Z'
			JBE CONTINUE
			
			JMP INVALID_INPUT			;Checks if the character is valid (A-Z or 0-9). If not, jump to invalid input

		CONTINUE:
			INC SI
			JMP CHECK_LOOP				;Move to the next character and repeat for the entire string

	
	INVALID_INPUT:					;used to display invalid input message being referred from input loop
		CALL CLEAR_SCREEN
		MOV AH,02H 						;SET CURSOR POSITION FUNCTION
		MOV BH,00H 						;SET PAGE NUMBER
		MOV DH,04H 						;ROW POS OF CURSOR
		MOV DL,04H 						;COL POS OF CURSOR
		INT 10H
		
		MOV AH,09H 						;WRITE STRING TO STANDARD OUTPUT
		MOV DX,OFFSET INVALID			;GIVE THE ADDRESS OF THE 1ST POSITION OF STRING
		INT 21H							;PRINT THE STRING
		JMP	RE_INPUT					;Display "Invalid input!" message, CLEAR THE SCREEN AND TAKE INPUT AGAIN.	
	
	RE_INPUT:
		MOV AH,02H 						;SET CURSOR POSITION FUNCTION
		MOV BH,00H 						;SET PAGE NUMBER
		MOV DH,08H 						;ROW POS OF CURSOR
		MOV DL,04H 						;COL POS OF CURSOR
		INT 10H
		
		MOV AH,09H 						;WRITE STRING TO STANDARD OUTPUT
		MOV DX,OFFSET KEY_PRESS_MSG		;GIVE THE ADDRESS OF THE 1ST POSITION OF STRING
		INT 21H							;PRINT THE STRING
		
		MOV AH,00H						;WAIT FOR KEYPRESS TO MOVE TO THE NEW SCREEN
		INT 16H
		MOV VALID,00H					;SET VALIDITY TO FALSE
		RET
		
	EXIT_VALIDATE_INPUT:
		MOV VALID,01H					;SET VALIDITY TO TRUE IF INPUT IS VALID
		RET
VALIDATE_INPUT ENDP

CONVERT_TO_MORSE_CODE PROC
	MOV SI, OFFSET BUFFER			;Reset SI to the start of the input string.
	MOV COUNT_CHARS,00H				;RESET TO COUNT CHARACTERS ON THE NEW LINE
	
	CONVERT_TO_MORSE:
		MOV AL, [SI]
		CMP AL, '$'
		JE EXIT_CONVERT_TO_MORSE	; if $ is found, end the PROCEDURE
		
		CMP AL,' '					;IF THERE IS A SPACE IN INPUT STRING,WE WON'T LOOK FOR IT IN THE LOOKUP TABLE
		JE SKIP_CHARACTER

		CMP AL, 'a'
		JB FIND_INDEX
		CMP AL, 'z'
		JA FIND_INDEX
		SUB AL, 32
		; Again converting lowercase to uppercase as string is being processed again so if any lowercase is encountered it'll be simply converted to uppercase

	FIND_INDEX:
		MOV DI, OFFSET characters ;using DI instead of SI because DI is used for looking up values in a table whereas SI is used to read from input string 
		MOV CX, 36 ;Set CX to 36 (total valid characters: A-Z + 0-9)
		MOV BL, 0 ;use to track the index of the character in the lookup table
		; In short, set DI to start of the lookup table, CX to total number of valid characters, and BL as the index

	FIND_LOOP: ;FINDING THE INDEX OF THE CHARACTER
		CMP AL, [DI] ;Compare AL (current input) with character in lookup table 
		JE FOUND_INDEX ;If it is equal then go to found_index loop
		INC DI ;Move to the next character in lookup table one by one
		INC BL ;Increment the above declared index tracker which was initially 0
	LOOP FIND_LOOP ;Keep repeating until we find the character
	 

	FOUND_INDEX: ;RETRIEVE THE MORSE CODE
		MOV DI, OFFSET morseTable ;Point DI to start of the MorseTable declared in .data segment
		SHL BX, 1 	; Each entry in morseTable is a 2-byte address because of dw  
					; Since each entry is 2 bytes, multiplying BL by 2 (SHL BX, 1)  
					; converts the index into a byte offset for correct address retreival(remember not accessing index number rather pointing to address locations like we do in pointers)
					; eg:- If BL = 2 (character 'C') then
					;   SHL BX, 1  ->  BX = 2 * 2 = 4
					;   ADD DI, BX ->  DI = morseTable + 4 (points to the address of 'C's Morse code)
					;   MOV DI, [DI] -> DI now holds the actual memory address of 'C's Morse code which later is used for printing

		ADD DI, BX ;Move to the correct Morse code index 
		MOV DI, [DI] ;retrieves the memory address where the morse code string is stored

	PRINT_MORSE: 				;PRINT THE MORSE EQUIVALENT
		MOV AH,02H 				;SET CURSOR POSITION FUNCTION
		MOV BH,00H 				;SET PAGE NUMBER
		MOV DH,CURSOR_ROW_POS 	;ROW POS OF CURSOR
		MOV DL,CURSOR_COL_POS 	;COL POS OF CURSOR
		INT 10H
		
		
		MOV DX,DI				;Load morse code string address into DX which we prev stored in DI
		MOV AH,09H
		INT 21H
		
		ADD CURSOR_COL_POS,02H	;TO DISPLAY NEW MORSE CHAR ON THE SAME LINE BUT DIFF COL POS
		
		INC CURSOR_COL_POS		;for printing space between morse code display (declared in .data)
		INC COUNT_CHARS			;COUNTING MORSE CHARS ON A SINGLE LINE
		CMP COUNT_CHARS,10		;IF MORSE CHARS = 10 -> DISPLAY NEW LINE AND DISPLAY REMAINING CHARS OVER THERE
		JE  DISPLAY_NEW_LINE

		INC SI 					;move to next character in string
		JMP CONVERT_TO_MORSE 	;repeat the entire process for next character
		
	DISPLAY_NEW_LINE:
		;MOVING THE CURSOR TO DIFFERENT LINE
		INC CURSOR_ROW_POS
		MOV COUNT_CHARS,00H				;RESET TO COUNT CHARACTERS ON THE NEW LINE
		MOV CURSOR_COL_POS,04H			;RESET THE COL POS OF THE CURSOR, WORKS LIKE CARRIAGE RETURN
		
		JMP	PRINT_MORSE
		
	SKIP_CHARACTER:
		INC SI			;SKIP THE SPACE IN THE INPUT STRING
		JMP CONVERT_TO_MORSE
		
	EXIT_CONVERT_TO_MORSE:
		RET
CONVERT_TO_MORSE_CODE ENDP

DRAW_MORSE_CODE_SCREEN_UI PROC
	CALL CLEAR_SCREEN
	
	MOV AH,02H 						;SET CURSOR POSITION FUNCTION
	MOV BH,00H 						;SET PAGE NUMBER
	MOV DH,03H 						;ROW POS OF CURSOR
	MOV DL,0DH 						;COL POS OF CURSOR
	INT 10H
		
	MOV AH,09H 						;WRITE STRING TO STANDARD OUTPUT
	MOV DX,OFFSET TEXT_MORSE_TITLE	;GIVE THE ADDRESS OF THE 1ST POSITION OF STRING
	INT 21H							;PRINT THE STRING
	
	CALL CONVERT_TO_MORSE_CODE
	
	;display the exit prompt
	MOV AH,02H 						;SET CURSOR POSITION FUNCTION
	MOV BH,00H 						;SET PAGE NUMBER
	MOV DH,12H 						;ROW POS OF CURSOR
	MOV DL,08H 						;COL POS OF CURSOR
	INT 10H
		
	MOV AH,09H 							;WRITE STRING TO STANDARD OUTPUT
	MOV DX,OFFSET TEXT_EXIT_CONVERTOR	;GIVE THE ADDRESS OF THE 1ST POSITION OF STRING
	INT 21H
	
	;display the RE-GENERATE morse code prompt
	MOV AH,02H 						;SET CURSOR POSITION FUNCTION
	MOV BH,00H 						;SET PAGE NUMBER
	MOV DH,14H 						;ROW POS OF CURSOR
	MOV DL,08H 						;COL POS OF CURSOR
	INT 10H
		
	MOV AH,09H 						;WRITE STRING TO STANDARD OUTPUT
	MOV DX,OFFSET TEXT_REGENERATE	;GIVE THE ADDRESS OF THE 1ST POSITION OF STRING
	INT 21H
	
	;WAIT FOR KEYPRESS
	MOV AH,00H
	INT 16H
	
	;CHECK WHICH KEY WAS PRESSED
	CMP AL,'E'
	JE EXIT
	CMP AL,'e'
	JE EXIT
	CMP AL,'R'
	JE RESTART
	CMP AL,'r'
	JE RESTART
	
	RESTART:
		MOV EXITING_CONVERTOR,00H
		RET
	EXIT:
		MOV EXITING_CONVERTOR,01H
		RET
		
DRAW_MORSE_CODE_SCREEN_UI ENDP


CLEAR_SCREEN PROC
;TO CLEAR THE SCREEN, WE SET THE VIDEO MODE CONFIGURATIONS AGAIN
	MOV AH,00H 			;SET THE CONFIGURATION TO VIDEO MODE
	MOV AL,0DH 			;resolution 320 x 200 graphics
	INT 10H 			;SETTING INTERRUPT FOR GRAPHICS VIDEO MODE
		
	MOV AH,0BH 			;Set THE FUNCTION
	MOV BH,00H 			;TO background/border color
	MOV BL,00H 			;SET Background/Border color TO BLACK
	INT 10H
	
	RET
CLEAR_SCREEN ENDP

EXIT_CONVERTOR PROC	;GOES BACK TO THE TEXT MODE
	
	MOV AH,00H 			;SET THE CONFIGURATION TO VIDEO MODE
	MOV AL,02H 			;resolution 80 x 25 TEXT MODE
	INT 10H 			;SETTING INTERRUPT FOR GRAPHICS VIDEO MODE
	
	MOV AH,4CH
	INT 21H
	
	RET
EXIT_CONVERTOR ENDP
END MAIN