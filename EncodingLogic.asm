dosseg
.MODEL SMALL
.STACK 100H


.DATA
    prompt db 'Enter a string (A-Z, a-z, or 0-9): $'
    ; Display this message before user input

    valid db 0DH, 0AH, 'Valid input!$'
    ; Message displayed when user input is valid. Carriage Return (CR) → 0DH (13 in decimal) Line Feed (LF) → 0AH (10 in decimal)

    invalid db 0DH, 0AH, 'Invalid input! Please try again.$'
    ; Message displayed when user input is invalid.

    buffer db 22
    ; Maximum length of the input (20 characters + ENTER + NULL terminator).

    sizee db ?
    ; Stores the actual size of the input (excluding ENTER)

    string db 21 dup(?)
    ; Buffer for storing user input (up to 21 characters)

    space db ' $'
    ; A space printed between Morse code outputs like .- ...

    characters DB 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890'
    ; Lookup table containing valid input characters (A-Z and 0-9)
	;Instead of assigning a separate memory location for each character, we store all characters contiguously in memory

    ;morseTable stores pointers (memory addresses of morse1, morse2, etc and morse1, morse2 actually stores the morsecode values.
    morseTable DW morse0, morse1, morse2, morse3, morse4, morse5, morse6, morse7, morse8, morse9
               DW morse10, morse11, morse12, morse13, morse14, morse15, morse16, morse17, morse18, morse19
               DW morse20, morse21, morse22, morse23, morse24, morse25, morse26, morse27, morse28, morse29
               DW morse30, morse31, morse32, morse33, morse34, morse35
    ; We first define Morse codes in DB because Morse sequences fit within 1 byte
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
    MOV AX, @DATA
    MOV DS, AX
    ; Load the data segment into the DS register to allow access to defined variables.

INPUT_LOOP:
    LEA DX, prompt
    MOV AH, 09H
    INT 21H
    ; Displays the input prompt to the user.

    MOV DX, OFFSET buffer
    MOV AH, 0AH
    INT 21H
    ; Reads the user's input string into the `buffer`. `sizee` will store the length of input.

    MOV CL, sizee
    MOV CH, 0 ;CH is set to 0 to clear the high byte of CX so it only holds sizee value
    CMP CL, 0
    JE INVALID_INPUT
    ; If the input length is zero, jump to the invalid input message.

    MOV SI, OFFSET string ;SI holds the starting address of string in memory
    ADD SI, CX ;SI moves to the end of the string for placing the $ sign for termination
    MOV AL, '$' ; stores $ sign in al
    MOV [SI], AL ;places the $ (null terminator) at the end of teh string memory address
    ; Appends the null terminator ('$') to the end of the input string.

    MOV SI, OFFSET string
    ; we need to reset it back to the beginning for further processing like printing (similar to bringing the pointer back to original position)

CHECK_LOOP:
    MOV AL, [SI]
    CMP AL, '$'
    JE VALID_INPUT
    ; Check for the null terminator ('$'). If found, input is valid.

    CMP AL, 'a'  
    JB CHECK_DIGIT
    CMP AL, 'z'
    JA CHECK_DIGIT
    SUB AL, 32
    ; Convert lowercase letters (a-z) to uppercase.

CHECK_DIGIT:
    CMP AL, '0' ; Check if character is a digit (0-9)
    JB INVALID_INPUT
    CMP AL, '9'
    JBE CONTINUE
	
    CMP AL, 'A' ; Check if character is uppercase letter (A-Z)
    JB INVALID_INPUT
    CMP AL, 'Z'
    JBE CONTINUE
	
    JMP INVALID_INPUT
    ; Checks if the character is valid (A-Z or 0-9). If not, jump to invalid input

CONTINUE:
    INC SI
    LOOP CHECK_LOOP
    ; Move to the next character and repeat for the entire string

VALID_INPUT:
    LEA DX, valid
    MOV AH, 09H
    INT 21H
    ; Display "Valid input!" message.

    MOV SI, OFFSET string
    ; Reset SI to the start of the input string.

CONVERT_TO_MORSE:
    MOV AL, [SI]
    CMP AL, '$'
    JE EXIT_PROGRAM
    ; if $ is found, end the program

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

PRINT_MORSE: ;PRINT THE MORSE EQUIVALENT
    MOV DX, DI ;Load morse code string address into DX which we prev stored in DI
    MOV AH, 09H
    INT 21H

    LEA DX, space ;for printing space between morse code display (declared in .data)
    MOV AH, 09H
    INT 21H
   

    INC SI ;move to next character in string
    JMP CONVERT_TO_MORSE ;repeat the entire process for next character
    

INVALID_INPUT: ;used to display invalid input message being referred from input loop
    LEA DX, invalid
    MOV AH, 09H
    INT 21H
    JMP INPUT_LOOP
    ; Display "Invalid input!" message and restart the input loop.

EXIT_PROGRAM: ;for exit mode
    MOV AH, 4CH
    INT 21H

MAIN ENDP
END MAIN
