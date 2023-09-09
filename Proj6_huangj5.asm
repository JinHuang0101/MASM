TITLE Project 6     (Proj6_huangj5.asm)

; Author: Jin Huang
; Last Modified:060521
; OSU email address: huangj5@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: 6                Due Date: 060621
; Description: This program prompts user to input 10 signed integers and displays the integers in a list.
;              Then it calcualtes and displays the sum and average of the integers. 
;              This program takes numeric input in string, validates if each byte of the input string
;              represents a legit digit or negative/positive sign. If not, users are prompted to re-enter.
;              Then this program stores the strings in a memory location and displays them.
;              Next this program converts each string of digits to its coresponding numeric
;              value, stores it in an array, and calculates the sum and average of the 10 signed integers.
;              Afterwards, this program converts the numeric value of sum and average into their
;              coresponding strings of digit, and displays them on the console.
;              This program uses two macros for string processing: mGetString gets user input of 
;              a string of digits and mDisplayString displays the string on the console.
		
; Implementation note: Parameters are passed on the system stack.

INCLUDE Irvine32.inc

; --mDisplayString--
; displays string stored in a specific memory location
; preconditions: none
; receives: 
;       address = address of return input 
; registers used: edx
; returns: string output on console
mDisplayString MACRO address
	push edx
	mov edx, address
	call WriteString
	pop edx
ENDM

; --mGetString--
; displays a prompt to get user input and stores it in a memory location
; receives: 
;       promptAddress = address of prompt string
;       inputString = user input string 
;       countString = LENGTHOF input string
; preconditions: none
; returns: none
; registers used: edx, ecx
mGetString  MACRO   promptAddress, inputString, countString    
    push    edx         
    push    ecx
 
    mov     edx, promptAddress                  ; display prompt
    call    WriteString                         ; get string input
    mov     edx, inputString                    
    mov     ecx, countString
    call    ReadString

    pop     ecx
    pop     edx
ENDM


.data
IntroTitle			BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures ",0
IntroAuthor			BYTE	"Written by: Jin Huang",0
IntroRequirement	BYTE	"Please provide 10 signed decimal integers.",13,10
					BYTE	"Each number needs to be small enough to fit inside a 32 bit register."
					BYTE	"After you have finished inputting the raw numbers I will display a list of "
					BYTE	"the integers, their sum, and their average value. ",0
prompt1             BYTE    "Please enter a signed number: ",0
prompt2             BYTE    "Please try again: ", 0
error               BYTE    "ERROR: You did not enter a signed number or your number was too big.",0 
displayTitle        BYTE    "You entered the following numbers:", 0
commaSpace          BYTE    ", ", 0
sumTitle            BYTE    "The sum of these numbers is: ", 0
averageTitle        BYTE    "The rounded average is: ", 0
goodbyeTitle        BYTE    "Thanks for playing!",0
negativeSign        BYTE    "-",0

array               SDWORD   10 DUP(?)
inputCounter        DWORD    0

.code
main PROC

; program introduction
push	OFFSET	IntroTitle
push	OFFSET	IntroAuthor
push	OFFSET	IntroRequirement
call	introduction

; get user input string in a loop
mov     ecx,   LENGTHOF array                   ; loop counter
_inputLoop:
    push    inputCounter                        ; track the number saved in array               
    push    OFFSET      array 
    push    LENGTHOF    array 
    push    OFFSET      prompt1 
    push    OFFSET      prompt2 
    push    OFFSET      error 
    call    getUserInput
    inc     inputCounter                        ; update array address to write more numbers
    LOOP    _inputLoop

; display list
push    OFFSET      negativeSign
push    OFFSET      array 
push    LENGTHOF    array
push    OFFSET      displayTitle 
push    OFFSET      commaSpace 
call    displayList 

; calcualte sum and average
push    OFFSET      negativeSign
push    OFFSET      array                            
push    LENGTHOF    array                          
push    OFFSET      sumTitle                    
push    OFFSET      averageTitle                    
call    calculateSumAve           

; display the title of goodbye message
push    OFFSET      goodbyeTitle
call goodbye  

exit
main ENDP

;   -- Introduction --
; Procedure to introduce the program
; preconditions: strings of introTitle, introAuthor and introRequirement exist 
; postconditions: ebp, edx registers changed
; receives: 
;       [ebp+20] = address of introTitle
;       [ebp+16] = address of introAuthor
;       [ebp+12] = introRequirement 
; returns: none
introduction PROC   USES    edx
    push    ebp
    mov     ebp, esp

    mov     edx, [ebp+20]                   ;introTitle
    mDisplayString  edx
    call    CrLf
    mov     edx, [ebp+16]                   ;introAuthor
    mDisplayString  edx
    call    CrLf
    call    CrLf
    mov     edx, [ebp+12]                   ;introRequirement
    mDisplayString  edx
    call    CrLf
    call    CrLf
    
    pop     ebp
    ret     8
introduction ENDP

; --getUserInput--
; Procedure to get user input to fill an array with signed integers
; preconditions: strings of prompt1, prompt2 and error exist
; postconditions: esi, eax changed
; receives: 
;       [ebp+36] = value of inputCounter
;       [ebp+32] = address of array
;       [ebp+24] = address of prompt1
;       [ebp+20] = address of prompt2
;       [ebp+16] = address of error
;       error, prompt2, prompt1, array, inputCounter are global variables
; returns: array with signed integers 
getUserInput PROC USES eax esi 
push ebp
mov ebp, esp

; initialize registers  
mov     eax, [ebp+36]                       ; inputCounter
imul    eax, 4                              ; size of DWORD 
mov     esi, [ebp + 32]                     ; array 
add     esi, eax                            ; update array address

; get user input
mov     eax, [ebp + 24]                     ; prompt1 
push    eax
push    [ebp + 20]                          ; prompt2 
push    [ebp + 16]                          ; error 
call readVal                                ; call subproc readVal

pop [esi]                                   ; store value in array

pop ebp
ret 20
getUserInput ENDP

; --readVal--
; Procedure to read user input of signed integer.
; Calls mGetString macro to get user input
; Calls subproc validateInput to verify if each byte of the input is legit
; preconditions: prompt1 string exist
; postconditions: eax, ebx changed
; receives: 
;       [ebp+16] = address of prompt1
;       [ebp+8] = address of error
; returns: converted value stored in a memory address
readVal PROC USES eax ebx
    LOCAL inputNum[15]:BYTE, isValid:DWORD
    push esi
    push ecx

    mov     eax, [ebp+16]                               ; prompt1 string 
    lea     ebx, inputNum                               ; save inputNum to ebx

_readLoop:                                              ; load, validate each byte of the input string
    mGetString eax, ebx, LENGTHOF inputNum
    mov     ebx, [ebp+8]                                ; error string
    push    ebx
    lea     eax, isValid                                ; validity flag
    push    eax
    lea     eax, inputNum
    push    eax
    push    LENGTHOF inputNum 
    call validateInput                                  ; call subproc to validate input 
    pop edx
    mov     [ebp + 16], edx                             ; store converted value at this address
    mov     eax, isValid 
    cmp     eax, 1                                      ; check validity 
    mov     eax, [ebp + 12]
    lea     ebx, inputNum
    jne _readLoop                                
    pop ecx
    pop esi
ret 8
readVal ENDP

; --validateInput--
; Procedure to validate if the input string represents a signed integer.
; Calls subproc calculateNum to convert the input string to its numeric value 
; preconditions: string of error message exists. inputNum is BYTE.
; postconditions: esi, ecx, eax, edx changed
; receives:
;       [ebp+20] = error
;       [ebp+16] = value of isValid
;       [ebp+12] = address of inputNum
;       [ebp+8] = LENGTHOF inputNum 
;       inputNum and isValid are local variables
; returns: none
validateInput PROC USES esi ecx eax edx
    LOCAL oversizedFlag:DWORD

    mov esi, [ebp+12]                       ; address of inputNum(local)                             
    mov ecx, [ebp+8]                        ; LENGTHOF inputNum(local)
    cld

; loads input string and check if the digits
; represent number from 0 to 9 or sign (+ or -)
_loadString:
    lodsb
    cmp al, 0                                   ;null string     
    je StrToInt                              

    cmp al, 48                                  ;48d is "0"
    jl  _checkPosSign
    jge  _continueCheck

_checkPosSign:
    cmp al, 43                                  ;43d is positive sign
    jne _checkNegSign
    loop _loadString

_checkNegSign:
    cmp al, 45                                  ; 45d is negative sign
    jne invalid
    loop _loadString

_continueCheck:
    cmp al, 57                                  ; 57d is "9"
    jg invalid 
    loop _loadString

invalid:
    mov edx, [ebp+20]                           ;error message string
    mDisplayString edx
    call Crlf

; initialize isValid to 0
    mov edx, [ebp+16]                           ; isValid flag
    mov eax, 0
    mov [edx], eax
    jmp finalValue

; convert string to numeric value 
; and checks if the value is too large
StrToInt:
    mov edx, [ebp+8]                                    ; LENGTHOF inputNum
    cmp ecx, edx                                
    je invalid
    lea eax, oversizedFlag                              ; local 
    mov edx, 0
    mov [eax], edx                                      ; initialize oversizedFlag to 0
    push [ebp+12]                                       ; address of inputNum
    push [ebp+8]                                        ; LENGTHOF inputNum
    lea edx, oversizedFlag
    push edx                                            ; oversizedFlag
    call calculateNum                                   ; call subproc to convert string to numeric value
    mov edx, oversizedFlag
    cmp edx, 1
    je invalid
    mov edx, [ebp+16]                                   ; isValid
    mov eax, 1                                          ; set isValid to true
    mov [edx], eax

finalValue:
    pop edx                                             ; value returned from calculateNum
    mov [ebp + 20], edx                                 ; store the value at this address

ret 12
validateInput ENDP

; --calculateNum--
; Procedure to convert input string to its numeric value
; Preconditions:inputNum is BYTE.
; Postconditions: esi, ecx, eax, ebx, edx changed
; Receives:
;   [ebp+16] = address of inputNum
;   [ebp+12] = LENGTHOF inputNum
;   [ebp+8] = oversizedFlag
;   inputNum and oversizedFlag are local variables 
; Returns: none
calculateNum PROC USES esi ecx eax ebx edx
    LOCAL value:SDWORD, isNeg:DWORD

; initialize registers
    mov eax, isNeg                                      ; local variable
    xor eax, eax
    mov isNeg, eax

    mov esi, [ebp+16]                                   ; address of inputNum
    mov ecx, [ebp+12]                                   ; LENGTHOF inputNum
    lea eax, value                                      ; local variable 
    xor ebx, ebx
    mov [eax], ebx
    xor eax, eax
    xor edx, eax
    cld

; loads in string 
_insertDigits:
    lodsb
    cmp al, 43                                          ; if positive sign
    je  _stripPosSign                                   ; strip positive sign
    cmp al, 45                                          ; if negative sign
    je _stripNegSign                                    ; strip negative sign
    jmp _continueInsert

_stripPosSign:
    mov eax, 0
    mov al, [esi]
    add esi, 1                                          ; skip the sign bit
    jmp _continueInsert

_stripNegSign:
    mov eax, 0
    mov al, [esi]
    add esi, 1
    inc isNeg                                           ; mark this number is negative
    jmp _continueInsert

_continueInsert:
    cmp eax, 0
    je _endInsert
    sub eax, 48
    mov ebx, eax
    mov eax, value
    mov edx, 10                                         ; multipley by 10
    imul edx

; check for signed overflow
    jo _tooLarge                                         ; check after multiply
    add eax, ebx                                        ; add the digit to the converted value
    jo _tooLarge                                         ; check after adding
    mov value, eax                                      ; store temp value to local variable
    mov eax, 0                                          ; reset eax
    loop _insertDigits

_endInsert:
    mov eax, isNeg                                     ; check negative flag
    cmp eax, 1
    je _negFinish                                       
    mov eax, value
    mov [ebp + 16], eax                                 ; save int value 
    jmp _finish

; finishing up for negative number
_negFinish:                                 
    mov eax, 0                                                  ; negate the positive value
    mov ebx, value
    sub eax, ebx
    mov [ebp+16], eax                                           ; save int value on stack
    jmp _finish

; update oversizedFlag 
_tooLarge:
    mov ebx, [ebp+8]                                            ; oversizedFlag 
    mov eax, 1                                                  ; set oversizedFlag to true
    mov [ebx], eax
    mov eax, 0
    mov [ebp + 16], eax

_finish:
    ret 8
calculateNum ENDP

;--displayList--
; Procedure to display an array of numbers 
; calls mDisplayString macro
; calls subproc writeVal 
; preconditions: the array is type SDWORD. string of negativeSign, displayTitle, commaSpace exist. LENGTHOF array exist.
; postconditions: esi, ebx, ecx, edx changed
; receives:
;       [ebp+40] = negativeSign
;       [ebp+36] = address of array
;       [ebp+32] = LENGTHOF array
;       [ebp+28] = address of displayTitle
;       [ebp+24] = commaSpace
; returns: displays numbers on console
displayList PROC USES esi ebx ecx edx
    push ebp
    mov ebp, esp

    call Crlf
    mov edx, [ebp+28]                                           ; address of displayTitle
    mDisplayString edx
    call Crlf

; initialize registers
    mov esi, [ebp+36]                                           ; address of array
    mov ecx, [ebp+32]                                           ; LENGTHOF array
    mov ebx, 1                                                  ; set the counter to 1
                                                                
; display a list of numbers
_printNumList:
    push [ebp+40]                                               ; negativeSign
    push [esi]                                                  ; array content
    call writeVal                                               ; call subproc writeVal                                               
    add esi, 4
    cmp ebx, [ebp+32]                                         
    jge endOfList
    mov edx, [ebp+24]                                           ; commaSpace ", "
    mDisplayString edx
    inc ebx
    loop _printNumList

    endOfList:                                                  ; no commaSpace
        call Crlf 

    pop ebp
    ret 20                                              
displayList ENDP

; --writeVal--
; Procedure to output an integer as a string
; calls subproc IntToStr 
; preconditions: the array is type SDWORD. string of negativeSign exist.
; postconditions: eax, ebx changed
; receives:
;       [ebp+12] = negativeSign
;       [ebp+8] = [esi]
;       esi = [ebp+36] address of array
; returns: displays strings on console
writeVal PROC USES eax ebx
    LOCAL numberString[200]:BYTE            

    lea eax, numberString                           ; local variable
    push eax
    mov ebx, [ebp+8]                                ; the int number to display
    test ebx, ebx                                   ; check sign flag
    js _displayNegative
    push [ebp+8]
    call IntToStr                                   ; call subprocedure to convert integer to string                 
    lea eax, numberString
    mDisplayString eax          
    ret 8                                       

_displayNegative:
    neg ebx                                         ; convert to positive integer
    mov [ebp+8],ebx
    push [ebp+8]
    call IntToStr                                   ; call subproc IntToStr 
    lea eax, numberString
    push eax
    mov eax, [ebp+12]                               ; negativeSign                            
    mDisplayString eax                              ; print negative sign
    pop eax
    mDisplayString eax                              ; print the value
    
    ret 8                                           
writeVal ENDP

; --IntToStr--
; Procedure to convert an integer to a string
; Preconditions: the array is type SDWORD.
; Postconditions: eax, ebx, ecx changed
; Receives:
;       [ebp+8] = [esi]
;       esi = [ebp+36] address of array
; Returns: none
IntToStr PROC USES eax ebx ecx
    LOCAL character:DWORD

; divide integer by 10
    mov eax, [ebp+8]                                    ; the int number to display
    mov ebx, 10
    mov ecx, 0
    cld

; calculate digit, push the digits in reverse
divideLoop:                                             ; divide by 10
    cdq
    idiv ebx
    push edx                                
    inc ecx                                
    cmp eax, 0
    jne divideLoop
    mov edi, [ebp+12]                                   ; save to string array

; save the character in the array
_saveCharToArray:
    pop character
    mov al, BYTE PTR character                          ; cast BYTE type
    add al, 48
    stosb
    loop _saveCharToArray
    mov al, 0
    stosb

    ret 8                               
IntToStr ENDP

; --calculateSumAve--
; Procedure to display the sum and average of an array of signed integers
; preconditions: string of sumTitle, negativeSign, averageTitle and array, LENGTHOF array exsit
; postconditions: esi, eax, ebx, ecx, edx 
; receives: 
;       [ebp+32] = sumTitle 
;       [ebp+44] = negativeSign
;       [ebp+40] = address of array
;       [ebp+36] = LENGTHOF array
;       [ebp+28] = averageTitle
; returns: none
calculateSumAve PROC USES esi edx ecx eax ebx
    push ebp
    mov ebp, esp

    mov edx, [ebp + 32]                             ; sumTitle 
    mDisplayString edx
    mov esi, [ebp + 40]                             ; address of array 
    mov ecx, [ebp + 36]                             ; LENGTHOF array 
    xor eax, eax                                    ; clear flags

calculateSum:
    add eax, [esi]                                  ; move array content to eax
    add esi, 4
    loop calculateSum

; display sum
    push [ebp+44]                                   ; push negative sign
    push eax                                        ; save the number stored in eax
    call writeVal
    call Crlf
    jmp _calculateAVG

_calculateAVG:
    mov edx, [ebp+28]                               ; averageTitle 
    mDisplayString edx
    cdq
    mov ebx, [ebp+36]                               ; LENGTHOF array 
    idiv ebx                                        ; signed division

; display average
    push [ebp+44]                                   ; push negative sign
    push eax                                        ; save the AVG stored in eax
    call writeVal 
    call CrLf
    jmp _finish
    
_finish:
    pop ebp
    ret 20
calculateSumAve ENDP

; --goodbye--
; Procedure to display the goodbye title
; preconditions: goodbye title string to display exist
; postconditions: ebp, edx changed.
; receives: 
;       [ebp+12] = goodbyeTitle
; returns: displays goodbye message on console
goodbye PROC    USES    edx
    push    ebp
    mov     ebp, esp
    call    CrLf
    mov     edx, [ebp+12]                            ; the goodbye title
    mDisplayString  edx

    pop       ebp
    ret       8
goodbye ENDP

END main
