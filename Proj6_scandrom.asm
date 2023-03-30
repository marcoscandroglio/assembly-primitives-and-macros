TITLE Proj6_scandrom     (Proj6_scandrom.asm)

; Author: Marco Scandroglio
; Last Modified:
; OSU email address: scandrom@oregonstate.edu
; Course number/section:   CS271 Section 408
; Project Number: 06                Due Date: 12/04/2022
; Description: This is a program that prompts the user for integer input
;				Each input string is converted character by character
;				to determine if they are valid integers and stored in an array.
;				The sum and average of the values in the array are calculated.
;				The array of inputs as well as the sum and average are converted
;				back into strings and displayed with the use of macros.


INCLUDE Irvine32.inc


;-----------------------------------------------------------------
; Name: mGetString
;
; Macro to prompt user for input and store it in a variable
; precondition: inputString initialized
; postcondition: input string stored in inputString
; receives: address of prompt string and address of inputString
; returns: string value in inputString
;-----------------------------------------------------------------

mGetString MACRO prompt, output

    PUSH    EDX
    PUSH    ECX
    PUSH    EAX


    mDisplayString prompt

    MOV     EDX, output
    MOV     ECX, 80                 

    CALL    ReadString

    MOV     charCount, EAX          ; number of characters entered / number of bytes read 
    ; move to readVal and pass on stack

    POP     EAX
    POP     ECX
    POP     EDX

ENDM


;-----------------------------------------------------------------
; Name: mDisplayString
;
; Procedure to display a string in the terminal using WriteVal
; precondition: initialized string value
; postcondition: string displayed in terminal
; receives: address of string to display
; returns: string displayed in terminal
;-----------------------------------------------------------------

mDisplayString MACRO string

    PUSH    EDX
  
    MOV     EDX, string
    CALL    WriteString

    POP     EDX

ENDM

; Constants
NUMBER_OF_INPUTS = 10

.data

; prompts and identifying strings
introPrompt1	BYTE "PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures Written by: Marco Scandroglio",0
introPrompt2	BYTE "Please provide 10 signed decimal integers.",0
introPrompt3	BYTE "Each number needs to be small enough to fit inside a 32 bit register.",13,10
				BYTE "After you have finished inputting the raw numbers I will display a",13,10  
				BYTE "list of the integers, their sum, and their average value.",0

extraCredit1	BYTE "**EC1: Number each line of user input and display a running subtotal of the user's valid numbers.",0
  
inputPrompt     BYTE "Please enter a signed number: ",0
inputPrompt2	BYTE "Please try again: ",0
errorMessage	BYTE "ERROR: You did not enter a signed number or your number was too big.",0

numbersMessage	BYTE "You entered the following numbers:",0
sumMessage		BYTE "The sum of these numbers is: ",0
averageMessage	BYTE "The truncated average is: ",0

goodbyeMessage	BYTE "Thank you for using my program!",13,10,0

currSumMessage	BYTE "	The current sum is: ",0
lineNumFormat	BYTE ". ",0

; formatting strings
commaSpace		BYTE ", ",0		    ; **EC: 1

; boolean values
negativeFlag	DWORD 0

; variables to hold user inputs and calculations
inputString     BYTE  80 DUP (?)
outputString	BYTE 12 DUP(?)
charCount       DWORD ?
inputInteger	SDWORD ?
userNumArray	SDWORD 10 DUP(?)
sumOfInputs		SDWORD ?
averageOfInputs	SDWORD ?
currentSum		SDWORD ?		    ; **EC: 1
lineCount		SDWORD 0		    ; **EC: 1


.code
main PROC

; display introduction and instructions
	mDisplayString	OFFSET introPrompt1
	CALL	Crlf
	CALL	Crlf

	mDisplayString	OFFSET introPrompt2
	CALL	Crlf
	mDisplayString	OFFSET introPrompt3
	CALL	Crlf
	CALL	Crlf

; display extra credit prompt
	mDisplayString	OFFSET extraCredit1
	CALL	Crlf
	CALL	Crlf

; initializing address of array and loop counter
	MOV		EDI, OFFSET userNumArray
	MOV		ECX, NUMBER_OF_INPUTS

; loop for prompting user for input and storing to array
_arrayFillLoop:

	INC		lineCount				; **EC: 1

	PUSH	OFFSET lineNumFormat	; [EBP + 44] **EC: 1
	PUSH	OFFSET outputString		; [EBP + 40] **EC: 1
	PUSH	OFFSET lineCount		; [EBP + 36] **EC: 1
	PUSH	OFFSET inputPrompt2		; [EBP + 32]
	PUSH	OFFSET inputInteger		; [EBP + 28]
	PUSH	OFFSET charCount		; [EBP + 24]
	PUSH	OFFSET errorMessage		; [EBP + 20]
	PUSH	OFFSET negativeFlag		; [EBP + 16]
	PUSH	OFFSET inputString		; [EBP + 12]
	PUSH	OFFSET inputPrompt		; [EBP + 8]
	CALL	ReadVal

	MOV		EAX, inputInteger
	MOV		[EDI], EAX
	ADD		EDI, TYPE userNumArray

; **EC1 running subtotal
	ADD		currentSum, EAX
	mDisplayString  OFFSET currSumMessage

	PUSH	OFFSET outputString
	PUSH	currentSum
	CALL	WriteVal
	CALL	Crlf

	LOOP    _arrayFillLoop
	CALL	Crlf

; number display identifier
	mDisplayString  OFFSET numbersMessage
	CALL	Crlf

; initializing address of array and loop counter
	MOV		ESI, OFFSET userNumArray    ;Address of first element of myArr into ESI
	MOV		ECX, NUMBER_OF_INPUTS

; loop using WriteVal to convert each integer in array to string and display them
_displayIntegers:
	MOV		EAX, [ESI] 
	PUSH	OFFSET outputString
	PUSH	EAX
	CALL	WriteVal

	CMP		ECX, 1
	JE		_noComma

	mDisplayString OFFSET commaSpace

_noComma:
	ADD		ESI, TYPE userNumArray

	LOOP	_displayIntegers
	CALL	Crlf
	CALL	Crlf


; calculate and store sum
	PUSH	NUMBER_OF_INPUTS
	push	OFFSET sumOfInputs
	push	OFFSET userNumArray
	call	CalculateSum

; sum display identifier
	mDisplayString  OFFSET sumMessage

; display sum
	PUSH	OFFSET outputString
	PUSH	sumOfInputs
	CALL	WriteVal

; calculate and store average
	PUSH	NUMBER_OF_INPUTS
	push	OFFSET averageOfInputs
	push	sumOfInputs
	call	CalculateAverage
	CALL	Crlf

; average display identifier
	mDisplayString  OFFSET averageMessage

; display average
	PUSH	OFFSET outputString
	PUSH	averageOfInputs
	CALL	WriteVal
	CALL	Crlf
	CALL	Crlf

; display goodbye message
	mDisplayString  OFFSET goodbyeMessage


	Invoke ExitProcess,0	        ; exit to operating system
main ENDP


;-----------------------------------------------------------------
; Name: ReadVal
;
; Procedure to receive user input, convert the input from string
; to signed integer, and evaluate the validity of the value
; with respect to actually being an integer and fitting 
; into a 32 bit register
; precondition: ReadVal called in main with appropriate stack values
; postcondition: converted value saved in inputInteger and boolean
; value in negativeFlag
; receives: string from user in 
; returns: strings for prompts and initialized variables to store output
;-----------------------------------------------------------------

ReadVal PROC

	PUSH	EBP 
	MOV		EBP, ESP

	PUSH	EAX
	PUSH	EBX
	PUSH	ECX
	PUSH	EDI
	PUSH	ESI

_getInput:

; **EC: 1
	MOV		EAX, [EBP + 36]
	PUSH	[EBP + 40]
	PUSH	[EAX]
	CALL	WriteVal
	mDisplayString	[EBP + 44]

	mGetString  [EBP + 8], [EBP + 12]
	JMP		_setValues

_pleaseTryAgain:
	
; **EC: 1
	MOV		EAX, [EBP + 36]
	MOV		EBX, 1
	ADD		[EAX], EBX
	PUSH	[EBP + 40]
	PUSH	[EAX]
	CALL	WriteVal

	mDisplayString	[EBP + 44]

	mGetString  [EBP + 32], [EBP + 12]

_setValues:

	PUSH	EAX
	MOV		EAX, [EBP + 24]
	MOV		ECX, [EAX]				; set counter to length of input
	MOV		EDI, [EBP + 28]			; location of variable to store converted value
	MOV		EBX, 0					; clear variable for storing current integer
	MOV		[EDI], EBX
	POP		EAX

_clearNegative:

	PUSH	EBX
	PUSH	EAX
	MOV		EBX, 0
	MOV		EAX, [EBP + 16]
	MOV		[EAX], EBX
	POP		EAX
	POP		EBX

	MOV		ESI, [EBP + 12]			; place value of user input into ESI so LODSB can use it

; convert the ASCII value obtained from mGetString to numeric value using string primitives

	LODSB							; uses ESI
	CMP		AL, 45					; checks if first character is "-"
	JE		_setNegative
	CMP		AL, 43					; checks if first character is "+"
	JE		_positive
	JMP		_validate				; jumps to validation code if no sign characters

_setNegative:

	PUSH	EBX
	PUSH	EAX
	MOV		EBX, 1
	MOV		EAX, [EBP + 16]
	MOV		[EAX], EBX
	POP		EAX
	POP		EBX
	DEC		ECX
	JMP		_increment

_positive:

	PUSH	EBX
	PUSH	EAX
	MOV		EBX, 0
	MOV		EAX, [EBP + 16]
	MOV		[EAX], EBX
	POP		EAX
	POP		EBX
	DEC		ECX
	JMP		_increment


; code block that increments through the current input and validates it
_increment:

	MOV		EAX, 0
	CLD
	LODSB		; increment to next character

_validate:

	CMP		AL, 48  ; checks if character is "0"
	JB		_invalidInput
	CMP		AL, 57  ; checks if character is "9"
	JA		_invalidInput

	MOV		EBX, [EBP + 16]
	MOV		EBX, [EBX]
	CMP		EBX, 1
	JE		_negativeAccumulator
	JMP		_accumulator

; if overflow occurs during multiplication this cleans up the stack
_mulStackCleanup:

	POP		EDX
	POP		EBX
	POP		EAX

_invalidInput:

	mDisplayString [EBP + 20]  ; error message
	CALL	Crlf
	JMP		_pleaseTryAgain

; converting string into integer
_accumulator:

	PUSH	EAX
	PUSH	EBX
	PUSH	EDX

	MOV		EAX, [EDI]
	MOV		EBX, 10
	IMUL	EAX, EBX
	JO		_mulStackCleanup

	MOV		[EDI], EAX

	POP		EDX
	POP		EBX
	POP		EAX

	SUB		AL, 48         ; to convert to integer value
	MOV		EBX, [EDI]

	ADD		EBX, EAX
	JO		_invalidInput
	ADD		[EDI], AL      ; store value in a memory variable



	DEC		ECX
	CMP		ECX, 0
	JA		_increment
	JE		_endReadVal


_negativeAccumulator:

	PUSH	EAX
	PUSH	EBX
	PUSH	EDX

	MOV		EAX, [EDI]
	MOV		EBX, 10
	IMUL	EAX, EBX
	JO		_mulStackCleanup

	MOV		[EDI], EAX

	POP		EDX
	POP		EBX
	POP		EAX

	SUB		AL, 48			; to convert to integer value

	MOVSX	EDX, AL			; sign extend and negate
	NEG		EDX
	
	MOV		EBX, [EDI]
	ADD		EBX, EDX
	JO		_invalidInput

	ADD		[EDI], EDX      ; store value in a memory variable
	
	MOV		EBX, [EDI]
	CMP		EBX, 0
	JLE		_continue

	NEG		EBX
	MOV		[EDI], EBX

_continue:

	DEC		ECX
	CMP		ECX, 0
	JA		_increment


_endReadVal:

	POP		ESI
	POP		EDI
	POP		ECX
	POP		EBX
	POP		EAX
	POP		EBP
	RET		28

ReadVal ENDP


;-----------------------------------------------------------------
; Name: WriteVal
;
; Procedure to convert a signed integer into a string and display it
; precondition: SDWORD input passed on the stack as a parameter
; postcondition: string representation of SDWORD displayed in terminal
; receives: an empty string and a signed integer value
; returns: none
;-----------------------------------------------------------------

WriteVal PROC

; invokes mDisplayString macro
	PUSH	EBP
	MOV		EBP, ESP

	PUSH	EAX
	PUSH	EBX
	PUSH	ECX
	PUSH	EDI
	PUSH	EDX

	MOV		EDI, [EBP + 12]			; address of output variable
	MOV		EAX, [EBP + 8]			; SDWORD input

_checkSign:

	CMP		EAX, 0
	JL		_negate
	JMP		_pushNullBit
	CLD


_negate:

	PUSH	EAX
	MOV		AL, 45
	STOSB	
	mDisplayString	[EBP + 12]

	DEC		EDI					; Move back to beginning of string (address)
		
	POP		EAX
	NEG		EAX					; convert to positive int

_pushNullBit:

	PUSH	0

_toASCII:

	MOV		EDX, 0
	MOV		EBX, 10
	DIV		EBX
		
	MOV		ECX, EDX
	ADD		ECX, 48
	PUSH	ECX
	CMP		EAX, 0
	JE		_display
	JMP		_toASCII

_display:

	POP		EAX

	STOSB
	mDisplayString	[EBP + 12]
	DEC		EDI				; Move back to display again

	CMP		EAX, 0
	JE		_endWriteVal
	JMP		_display

_endWriteVal:

	DEC		EDI				; Move back to reset for next use 
	
	POP		EDX
	POP		EDI
	POP		ECX
	POP		EBX
	POP		EAX
	POP		EBP
	RET		8

WriteVal ENDP


;-----------------------------------------------------------------
; Name: CalculateSum
;
; Procedure to calculate the sum of all the valid inputs
; precondition: userNumArray is populated with values
; postcondition: value in sumOfInputs
; receives: address of userNumArray and number of elements in array
; returns: value in sumOfInputs
;-----------------------------------------------------------------

CalculateSum PROC

	PUSH	EBP
	MOV		EBP, ESP

	PUSH	ESI
	PUSH	EAX
	PUSH	EBX
	PUSH	ECX

	MOV		ESI, [EBP + 8]			; input array
	MOV		ECX, [EBP + 16]			; number of elements

	MOV		EAX, 0

_sumLoop:

	ADD		EAX, [ESI]
	ADD		ESI, 4
	LOOP	_sumLoop

	MOV		EBX, [EBP + 12]
	MOV		[EBX], EAX

	POP		ECX
	POP		EBX
	POP		EAX
	POP		ESI
	POP		EBP
	RET		8

CalculateSum ENDP


;-----------------------------------------------------------------
; Name: CalculateAverage
;
; Procedure to calculate the truncated average of the valid inputs
; precondition: sumOfInputs has a value
; postcondition: value in averageOfInputs
; receives: sumOfInputs and number of elements in array
; returns: value in averageOfInputs
;-----------------------------------------------------------------

CalculateAverage PROC

	PUSH	EBP
	MOV		EBP, ESP
	PUSH	ECX
	PUSH	EAX
	PUSH	EBX

	MOV		ECX, [EBP + 16]			; number of elements
	MOV		EAX, [EBP + 8]			; sum			
	
_divide:

	MOV		EBX, [EBP + 16]			; number of elements
	MOV		EDX, 0
	CDQ
	IDIV	EBX

	MOV		EBX, [EBP + 12]					
	MOV		[EBX], EAX

	POP		EBX
	POP		EAX
	POP		ECX
	POP		EBP
	RET		12

CalculateAverage ENDP

END main
