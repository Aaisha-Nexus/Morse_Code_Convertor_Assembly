
.MODEL SMALL
.STACK 100H

.DATA
    prompt      DB 'Enter a string (A-Z, a-z, or 0-9): $'
    valid       DB 13, 10, 'Morse code: $'
    invalid     DB 13, 10, 'Invalid input! Please try again.$'
    buffer      DB 22
    sizee       DB ?
    string      DB 21 DUP(?)
    space       DB ' $'

    characters  DB 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890'

    morseTable  DW morse0, morse1, morse2, morse3, morse4, morse5, morse6, morse7, morse8, morse9
                DW morse10, morse11, morse12, morse13, morse14, morse15, morse16, morse17, morse18, morse19
                DW morse20, morse21, morse22, morse23, morse24, morse25, morse26, morse27, morse28, morse29
                DW morse30, morse31, morse32, morse33, morse34, morse35

    morse0      DB ".- $"      
    morse1      DB "-... $"
    morse2      DB "-.-. $"
    morse3      DB "-.. $"
    morse4      DB ". $"
    morse5      DB "..-. $"
    morse6      DB "--. $"
    morse7      DB ".... $"
    morse8      DB ".. $"
    morse9      DB ".--- $"
    morse10     DB "-.- $"
    morse11     DB ".-.. $"
    morse12     DB "-- $"
    morse13     DB "-. $"
    morse14     DB "--- $"
    morse15     DB ".--. $"
    morse16     DB "--.- $"
    morse17     DB ".-. $"
    morse18     DB "... $"
    morse19     DB "- $"
    morse20     DB "..- $"
    morse21     DB "...- $"
    morse22     DB ".-- $"
    morse23     DB "-..- $"
    morse24     DB "-.-- $"
    morse25     DB "--.. $"
    morse26     DB ".---- $"
    morse27     DB "..--- $"
    morse28     DB "...-- $"
    morse29     DB "....- $"
    morse30     DB "..... $"
    morse31     DB "-.... $"
    morse32     DB "--... $"
    morse33     DB "---.. $"
    morse34     DB "----. $"
    morse35     DB "----- $"

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

INPUT_LOOP:
    LEA DX, prompt
    MOV AH, 09H
    INT 21H

    MOV DX, OFFSET buffer
    MOV AH, 0AH
    INT 21H

    MOV CL, sizee
    MOV CH, 0
    CMP CX, 0
    JE INVALID_INPUT

    MOV SI, OFFSET string
    ADD SI, CX
    MOV AL, '$'
    MOV [SI], AL
    MOV SI, OFFSET string

VALIDATION_LOOP:
    MOV AL, [SI]
    CMP AL, '$'
    JE VALID_INPUT

    CMP AL, 'a'
    JB CHECK_DIGIT
    CMP AL, 'z'
    JA CHECK_DIGIT
    SUB AL, 32

CHECK_DIGIT:
    CMP AL, '0'
    JB INVALID_INPUT
    CMP AL, '9'
    JBE CONTINUE_CHAR

    CMP AL, 'A'
    JB INVALID_INPUT
    CMP AL, 'Z'
    JBE CONTINUE_CHAR

    JMP INVALID_INPUT

CONTINUE_CHAR:
    INC SI
    LOOP VALIDATION_LOOP

VALID_INPUT:
    LEA DX, valid
    MOV AH, 09H
    INT 21H

    MOV SI, OFFSET string

CONVERT_LOOP:
    MOV AL, [SI]
    CMP AL, '$'
    JE EXIT_PROGRAM

    CMP AL, 'a'
    JB FIND_INDEX
    CMP AL, 'z'
    JA FIND_INDEX
    SUB AL, 32

FIND_INDEX:
    MOV DI, OFFSET characters
    MOV CX, 36
    MOV BL, 0

FIND_CHAR:
    CMP AL, [DI]
    JE FOUND
    INC DI
    INC BL
    LOOP FIND_CHAR
    JMP INVALID_INPUT

FOUND:
    MOV DI, OFFSET morseTable
    SHL BX, 1
    ADD DI, BX
    MOV DI, [DI]

; --- NEW MORSE PRINTING + SOUND LOGIC ---
PRINT_MORSE:
NEXT_MORSE_CHAR:
    MOV AL, [DI]  ;gets next dash in morse string
    CMP AL, '$'   ; has morse string end?
    JE AFTER_MORSE  ;if yes go back to main loop

    ; Print dot or dash
    MOV DL, AL
    MOV AH, 02H
    INT 21H

    ; Play beep and delay based on symbol
    CMP AL, '.'
    JE DOT_SOUND
    CMP AL, '-'
    JE DASH_SOUND

    JMP CONTINUE_MORSE

DOT_SOUND:
    MOV AH, 0Eh ;function to print with sound
    MOV AL, 07h ;ascii code for beep beep
    INT 10h     ;so we can hear the beep
    CALL SHORT_DOT_DELAY   ;go to the short dot delay and return
    JMP CONTINUE_MORSE  ;cont with the next element

DASH_SOUND:
    MOV AH, 0Eh
    MOV AL, 07h
    INT 10h
    CALL LONG_DASH_DELAY
    JMP CONTINUE_MORSE

CONTINUE_MORSE:   ;works within the same element morse
    INC DI    ;i++
    JMP NEXT_MORSE_CHAR ;go to above, see next char with the updated index (DI) are we done with the character or not?
    
;After printing the Morse for one letter, print a space on the screen, then go check the next character in the input and start converting it too

AFTER_MORSE: ;runs after one more character is printed
    LEA DX, space ;loading the address of space (initialized above) 
    MOV AH, 09H   ;printing space
    INT 21H

    INC SI   ;move to the next character
    JMP CONVERT_LOOP  ;now go back and convert the next letter to Morse.

INVALID_INPUT:
    LEA DX, invalid ;for invalid input
    MOV AH, 09H
    INT 21H
    JMP INPUT_LOOP

SHORT_DOT_DELAY:
    MOV CX, 50 ;the time for one beep
DOT_LOOP:
    NOP  ;halt, pause, stop until 50 (cx)
    LOOP DOT_LOOP  ;decreasing cx until its 0
    RET

LONG_DASH_DELAY:
    MOV CX, 150
DASH_LOOP:
    NOP
    LOOP DASH_LOOP
    RET

EXIT_PROGRAM:
    MOV AH, 4CH
    INT 21H

MAIN ENDP
END MAIN
