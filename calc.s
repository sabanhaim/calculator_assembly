 section .data
     stackSize: equ 5
     linkSize: equ 5
     stackCell: equ 4

section .bss
     myStack: resd stackSize
     tmpInput: resb 82
     returnNumber: resb 82
     commandCounter: resb 4

section   .rodata
     LC0:
          DB   "calc : ",0
     emptyError:
          db "Error: Insufficient Number of Arguments on Stack.", 10, 0
     overflowError:
          db "Error: Operand Stack Overflow", 10, 0
     illegalInputError:
          db "Error: Illegal Input",10,0
     numberOfCommands:
          db "The Number Of Commands You Used : %d",10, 0

 section .text
     align 16
     global main
     extern printf
     extern fprintf
     extern malloc
     extern free
     extern fgets
     extern stderr
     extern stdin
     extern stdout

     %macro numberForging 0
          mov dword eax, 1 ;counts number of links
          mov dword edi, [esi] ;edi will be used to travel around links
          %%linkCounterLoop2:  
               cmp dword [edi+1], 0
               je %%nextStage2
               inc eax
               mov dword edi, [edi+1]
               %%breaker2:
               jmp %%linkCounterLoop2
               %%nextStage2:
               shl eax, 1   ;double the number in ax
               push eax
               mov dword ecx, returnNumber  ;EDI will point and move backwards in the return value array
               add dword ecx, eax          ;each number in the link is consist of 8 bits (2 bytes) in BCD. so we need to double it to get it back to string.  ecx will point tp the end of the array
               inc ecx
               mov byte al, [edi]    ;check whether the last link's (first 2 digits) left digit is 0.
               and al, 0xF0
               cmp al, 0
               jne %%OK2
               dec ecx
               %%OK2:
               mov byte [ecx], 0
               dec ecx
               mov byte [ecx], 10
               dec ecx
               mov dword edi, [esi] ;edi will be used to travel around links (now points to the first link)
               %%numberForgingProcess2:
               cmp dword [edi+1], 0   ;if you are in the last link you need to test again if the last number' left digit is 0 (the first number to be printed)
               je %%lastTestAndPrint2
               mov byte al, [edi]    ;will contain the right digit
               mov byte ah, [edi]    ;will contain the left digit
               and al, 0x0F
               and ah, 0xF0
               shr ah, 4
               add byte al, 48
               add byte ah, 48
               mov byte [ecx], al
               dec ecx
               mov byte [ecx], ah
               dec ecx
               mov dword edi, [edi+1]
               jmp %%numberForgingProcess2
               %%lastTestAndPrint2:
               mov byte al, [edi]    ;will contain the right digit
               mov byte ah, [edi]    ;will contain the left digit
               and al, 0x0F
               add byte al, 48
               and ah, 0xF0
               mov byte [ecx], al
               cmp byte ah, 0
               je %%printer2
               shr ah, 4
               add byte ah, 48
               dec ecx
               mov byte [ecx], ah
               %%printer2:
                    push dword edx
                    mov edx, 0
                    cmp dword [esp+4], 2
                    je %%continueIt2
                    %%numOfZeros2:
                    cmp byte [ecx], 48
                    jne %%continueIt2
                    inc edx
                    inc ecx
                    jmp %%numOfZeros2
                         %%continueIt2:
                         pushad
                         mov dword eax, returnNumber
                         add dword eax, edx
                         push eax
                         push dword [stderr]
                         call fprintf
                         add dword esp, 8
                         popad
                         pop edx
                         pop eax
                    
     %endmacro

     %macro addressCleaner 0
          mov dword ecx, returnNumber
          %%addressCleaner:
          cmp byte [ecx], 0
          je %%endOfClean
          mov byte [ecx], 0
          inc ecx
          jmp %%addressCleaner
          %%endOfClean:
     %endmacro

     %macro addressCleanerInput 0
          pushad
          mov dword ecx, tmpInput
          %%addressCleaner:
          cmp byte [ecx], 0
          je %%endOfClean
          mov byte [ecx], 0
          inc ecx
          jmp %%addressCleaner
          %%endOfClean:
          popad
     %endmacro

     %macro debugger 0
          pushad
          numberForging
          popad
          pushad
          addressCleaner
          popad
     %endmacro

     %macro linksFreeing_linksAllocating 0 ;to use with + and &
               push eax             ;pushing the byte
               push ebp
               mov ebp, esp
               %%freeLinks:
                    cmp dword [ebp+8], 0
                    je %%skipFirst
                    pusha
                    push dword [ebp+8]
                    call free 
                    add esp, 4
                    popad
                    %%skipFirst:
                    cmp dword [ebp+12], 0
                    je %%skipSecond
                    pusha
                    push dword [ebp+12]
                    call free 
                    add esp, 4
                    popad
                    %%skipSecond:
               pushad
               push dword linkSize
               call malloc   ;returns a pointer to the unintialized data at EAX
               add dword esp, 4
               mov byte dl, [ebp+4]  ;moving the byte to enter to dl
               mov byte [eax], dl       ;placing the byte in the right place
               mov dword [eax+1], 0     ; positioning the null terminator in case there is no other links
               mov dword edx, [ebp+16]  ;getting the prvious links position to place the current address
               mov dword [edx], eax     ;placing it in the right place
               inc eax                  ; moving to the next link's address place in current link
               mov dword [ebp+16], eax   ;place the address in the empty space
               popad
               pop ebp
               add dword esp, 12
     %endmacro

     %macro allocatingOnly 0
          pushad
          push dword linkSize
          call malloc   ;returns a pointer to the unintialized data at EAX
          add dword esp, 4
          mov byte dl, [ebp+4]  ;moving the byte to enter to dl
          mov byte [eax], dl       ;placing the byte in the right place
          mov dword [eax+1], 0     ; positioning the null terminator in case there is no other links
          mov dword edx, [ebp+8]  ;getting the prvious links position to place the current address
          mov dword [edx], eax     ;placing it in the right place
          inc eax                  ; moving to the next link's address place in current link
          mov dword [ebp+8], eax   ;place the address in the empty space
          popad
          pop ebp
          add dword esp, 4
     %endmacro

     %macro errorPrinter 1 ;arg is the message to print
          pushad
          push dword %1
          push dword [stderr]
          call fprintf
          add dword esp, 8
          popad
          jmp new_line_receptor
     %endmacro

     %macro minimumArgs 0   ;checks if there is a minimum number of args to perform a 1 result commands
          cmp byte dl, 2
          jb emptyStack
     %endmacro

     %macro endPoint 0
          pop ebx
          pop eax
          ;inc dh
          inc dword [commandCounter]
          dec dl
          jmp new_line_receptor
     %endmacro

     %macro startingPoint 0
          push eax
          push ebx
          mov ecx, [esi]   ; upper number
          sub esi, stackCell   
          mov edi, [esi]   ;lower number
          mov ebx, esi   ; where to put the new num (the sum)
          push ebx       ;first "previous" link 
     %endmacro


main:
     push ebp                                   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     mov ebp, esp
     add esp, 4
     mov dword [commandCounter], 0
     cmp dword [ebp+8], 1   ;comparing argc
     je noDe
     check1:
          mov dword ecx, [ebp+12]   ;getting argv
          mov dword ecx, [ecx+4]        ; getting -d
          check2:
          cmp byte [ecx], '-'
          jne noDe
          check3:
          cmp byte [ecx+1], 'd'
          jne noDe
          check4:
          cmp byte [ecx+2], 0
          jne noDe
          push dword 1
          jmp star
     noDe:
          push dword 0
     star:
     mov esp, ebp
     pop ebp                                        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     push ebp
     mov ebp, esp
     mov dl, byte 0   ;counts number of cells ocupied in the stack
     mov dh, byte 0   ;counts the number of commands that succeed
     mov dword esi, myStack  ;points to the last position in the stack
     sub esi, stackCell
     new_line_receptor:
          pushad
          push LC0
          call printf
          add dword esp, 4
          popad
          pushad
          push dword [stdin]
          push dword 80
          push dword tmpInput
          call fgets
          add dword esp, 12
          popad
          mov dword ebx, tmpInput   ;EBX points to the input
          jumper:
               cmp byte [ebx], 0x0a
               je new_line_receptor
               cmp byte [ebx], 'p'
               je poper
               cmp byte [ebx], 'q'
               je quit
               cmp byte [ebx], 'd'
               je duplicate
               cmp byte [ebx], '+'
               je plus
               cmp byte [ebx], '&'
               je bitwiseAnd
     input_check:
          cmp byte [ebx], 0x0a
          je stack_fullness_check
          cmp byte [ebx], 0x30
          jb illegalInput 
          cmp byte [ebx], 0x39
          ja illegalInput 
          inc ebx
          jmp input_check

     stack_fullness_check:
          cmp byte dl, stackSize
          je stackoverflow     ;"stack is full" check
          inc dl                ;updates number of taken slots in the stack
     mov dword ebx, tmpInput   ;EBX points to the input


     check5:
     cmp dword [ebp], 1
     jne goOn
     debug1:
          pushad
          push dword tmpInput
          push dword [stderr]
          call fprintf
          add dword esp, 8
          popad


     goOn:
     add dword ebx, 80         ;EBX points to the end of the input +1 : useful for the linkMaker
     mov dword edi, 81         ; counts the number of byte left to check in the input
     add esi, stackCell              ;move to the next free cell in the stack
     mov dword ecx, esi             ; making a new linked list of the given number (in BCD formation)
     jmp numberInput
     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;POP;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     poper:
          cmp byte [ebx+1],10
               jne illegalInput
          cmp byte  dl, 0
          je emptyStack

          pushad
          mov dword eax, 0 ;counts number of links
          mov dword edi, [esi] ;edi will be used to travel around links
          mov dword edx, 0
          zeroCounter:
               cmp dword edi, 0
               je matcher
               inc eax
               cmp byte [edi], 0
               jne gogo
               inc edx
               gogo:
               mov dword edi, [edi+1]
               jmp zeroCounter
               matcher:
                    cmp dword eax, edx
                    jne regular
                    mov dword ecx, returnNumber
                    mov byte [ecx], 48
                    mov byte [ecx+1], 10
                    mov byte [ecx+2], 0
                    pushad
                    push ecx
                    call printf
                    add dword esp, 4
                    popad
                    popad
                    mov dword edi, [esi]   ;for freeing use
                    mov dword [esi], 0 ;empties the last cell in stack 
                    sub esi, stackCell    ;points to the previous cell (now last cell)
                    dec dl
                    inc dword [commandCounter]
                    jmp addressCleaner_linkFree


          regular:
          popad
          mov dword eax, 1 ;counts number of links
          mov dword edi, [esi] ;edi will be used to travel around links
          linkCounterLoop:  
               cmp dword [edi+1], 0
               je nextStage
               inc eax
               mov dword edi, [edi+1]
               breaker:
               jmp linkCounterLoop
          nextStage:
               shl eax, 1   ;double the number in ax
               add eax, 2   ; for \n and 0
               push eax
               
;123456790
;20002222222
               sub esp ,4         ;the address to the memory allocation 
               push ebp
               mov ebp, esp
               pushad
               push dword eax          ;creating new array double the size of the linked list (for chars)
               call malloc   ;returns a pointer to the unintialized data at EAX
               mov dword [ebp+4], eax     ;placing it in the right place
               add dword esp, 4
               popad
               pop ebp
               pop ecx         ;saves the address in ecx

               pop eax
               sub eax, 1

               push ecx       ;for later use

               add dword ecx, eax          ;each number in the link is consist of 8 bits (2 bytes) in BCD. so we need to double it to get it back to string.  ecx will point tp the end of the array
               mov byte al, [edi]    ;check whether the last link's (first 2 digits) left digit is 0.
               and al, 0xF0
               cmp al, 0
               jne OK
               dec ecx
               OK:
               mov byte [ecx], 0
               dec ecx
               mov byte [ecx], 10
               dec ecx
               mov dword edi, [esi] ;edi will be used to travel around links (now points to the first link)
          numberForgingProcess:
               cmp dword [edi+1], 0   ;if you are in the last link you need to test again if the last number' left digit is 0 (the first number to be printed)
               je lastTestAndPrint
               mov byte al, [edi]    ;will contain the right digit
               mov byte ah, [edi]    ;will contain the left digit
               and al, 0x0F
               and ah, 0xF0
               shr ah, 4
               add byte al, 48
               add byte ah, 48
               check12:
               mov byte [ecx], al
               dec ecx
               mov byte [ecx], ah
               dec ecx
               mov dword edi, [edi+1]
               jmp numberForgingProcess
          lastTestAndPrint:
               mov byte al, [edi]    ;will contain the right digit
               mov byte ah, [edi]    ;will contain the left digit
               and al, 0x0F
               add byte al, 48
               and ah, 0xF0
               mov byte [ecx], al
               cmp byte ah, 0
               je printer
               shr ah, 4
               add byte ah, 48
               dec ecx
               mov byte [ecx], ah
               printer:
                    push dword edx
                    numOfZeros:
                    cmp byte [ecx], 48
                    jne continueIt
                    inc ecx
                    jmp numOfZeros
                         continueIt:
                         pushad
                         push ecx
                         breakit:
                         call printf
                         add dword esp, 4
                         popad
                         pop edx

                         pop ecx
                         pusha
                         push ecx
                         call free 
                         add esp, 4
                         popad

                         mov dword edi, [esi]   ;for freeing use
                         mov dword [esi], 0 ;empties the last cell in stack 
                         sub esi, stackCell    ;points to the previous cell (now last cell)
                         dlcheck:
                         dec dl
                         inc dword [commandCounter]
                         addressCleaner_linkFree:
                              freeLinks:
                                   cmp dword edi, 0     ;if its not null
                                   je freeEnd
                                   mov dword ecx, edi
                                   mov dword edi, [ecx+1]
                                   pusha
                                   push ecx
                                   call free 
                                   add esp, 4
                                   popad
                                   jmp freeLinks
                              freeEnd:
                              addressCleaner
                              jmp new_line_receptor
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;POPEND;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DUPLICATE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     duplicate:
          cmp byte [ebx+1],10
          jne illegalInput
          cmp byte dl, stackSize
          je stackoverflow
          cmp byte dl, 0
          je emptyStack
          mov dword edi, [esi]  ;edi will contain the address of the first link of the number to be copied
          add esi, stackCell    ;now esi points to where it should be duplicated to.
          push edx      ;in the end of the process, we need to pop it back
          push ebx      ;in the end of the process, we need to pop it back
          mov dword ecx, esi ; moving the address of the first place to point to link.
          duplicator:
               push ecx
               mainLoop:
                    mov byte dl, [edi]   ;get the numerical BCD value
                    mov dword ebx, [edi+1]   ;get the next link in the original linked list address
                         push edx             ;pushing the byte
                         push ebp
                         mov ebp, esp
                         allocatingOnly
                         afterAllo:
                    cmp dword ebx, 0
                    je ending
                    mov dword edi, ebx
                    jmp mainLoop
                    ending:
                    add dword esp, 4
                    pop ebx
                    pop edx                  ;get back the right EDX value back to the register
                    inc dl
                    checkDe1:
                    cmp dword [ebp], 1
                    jne neverMind
                    
                    debugger
                    neverMind:
                    inc dword [commandCounter]
                    jmp new_line_receptor         ;REPEAT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DUPLICATEEND;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;NUMBER;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     numberInput:
          gettingRidOfZeros:
               dec ebx
               dec edi
               cmp byte [ebx], 0    ; getting all of the last 0's out
               je gettingRidOfZeros
               dec ebx             ;getting rid of the '\n'
               dec edi
          push ecx         ;pushing the previous link's "next link" address for the first time
          mainThing:
          mov byte al, [ebx]   ;get the first char from the end (first digit)
          sub byte al, 48     ; get numerical value
          and al, 0x0F        ;leave only the right digit (in case there was something else)
          dec edi             ;update amount of bytes left to check
          cmp dword edi, 0   ;counts 80 to go
          je allocator        ;if there are no byte left, it means the number that was give is odd
          dec ebx             
          mov byte ah, [ebx]
          sub byte ah, 48
          shl ah, 4
          add byte al, ah
          dec ebx              ;moves on to the next digit
          dec edi
          cmp dword edi, 0   ;counts 80 to go
          allocator:
               push eax             ;pushing the byte
               push ebp
               mov ebp, esp
               allocatingOnly
          cmp edi, 0
          jne mainThing
          fullStop:
               add dword esp, 4    ;taking out the previous link's "next link" address from the stack  
               mov dword ebx, tmpInput
               mov dword edi, 81
               cleaner:
                    mov byte [ebx], 0
                    dec edi
                    inc ebx
                    cmp dword edi, 0
                    jne cleaner
               jmp new_line_receptor         ;REPEAT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;NUMBEREND;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;PLUS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     plus:
          cmp byte [ebx+1],10
          jne illegalInput
          minimumArgs
          startingPoint
          mov byte al, 0
          mov byte ah, 0
          add byte al, ah   ;to make the carry flag = 0
          mainPlusLoop:
               push ecx            ;to release the memory
               push edi            ;to release the memory
               pushfd
               cmp dword edi, ecx  ;if both are equal it means they are both 0
               je complete
               mov byte al, 0
               cmp dword ecx, 0
               je noNeedEcx
               mov byte al, [ecx]   ;get upper number's byte
               mov dword ecx, [ecx+1]  ;get the next link of the number 
               noNeedEcx:
               cmp dword edi, 0
               je noNeedEdi
               add byte ah, [edi]  ;get lower number's byte + carry (that should already be in ah, i.e. ah=1/0)
               daa
               mov dword edi, [edi+1]
               noNeedEdi:
               popfd
               adc byte al, ah
               daa
               mov byte ah, 0
               adc byte ah, 0  ; to see if there is carry
               plusAllocator:
                    linksFreeing_linksAllocating
                    jmp mainPlusLoop
          complete:
               popfd
               add dword esp, 8    ;ecx,edi
               cmp byte ah, 1
               jne justFinish
               push ebp
               mov ebp, esp
               pushad
               push dword linkSize
               call malloc   ;returns a pointer to the unintialized data at EAX
               add dword esp, 4
               mov byte [eax], 0x00000001       ;placing the byte in the right place
               mov dword [eax+1], 0     ; positioning the null terminator in case there is no other links
               mov dword edx, [ebp+4]  ;getting the prvious links position to place the current address
               mov dword [edx], eax     ;placing it in the right place
               popad
               pop ebp
               justFinish:
               add dword esp, 4
               checkDe2:
               cmp dword [ebp], 1
               jne neverMind2
               debugger
               neverMind2:
               endPoint
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;PLUSEND;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;QUIT;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     quit:
          cmp byte [ebx+1],10
          jne illegalInput
          cmp dl, 0
          je finishAndQuit
          cmp dword [esi], 0
          mov dword edi, [esi]
          theActualFree:
               cmp dword edi, 0     ;if its not null
               je freeEnder
               mov dword ecx, edi
               mov dword edi, [ecx+1]
               pusha
               push ecx
               call free 
               add esp, 4
               popad
               jmp theActualFree
          freeEnder:
               dec dl
               sub esi, stackCell
               jmp quit
          finishAndQuit:
               pushad
               push dword [commandCounter]
               push dword numberOfCommands
               push dword [stdout]
               call fprintf
               add dword esp, 12
               popad
               pop ebp
               ;sub esp, 4
               mov dword eax, 1
               mov dword ebx, 0
               mov dword ecx, 0
               mov dword edx, 0
               int 0x80
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;QUITEND;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;BITWISEAND;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     bitwiseAnd:
          cmp byte [ebx+1],10
          jne illegalInput
          minimumArgs
          startingPoint
          bitwiser:
               push ecx            ;to release the memory
               push edi            ;to release the memory
               checkEcx:
               mov byte al, [ecx]   ;first one
               mov dword ecx, [ecx+1]  ;get the next link of the number 
               checkEdi:
               mov byte ah, [edi] ;second one
               mov dword edi, [edi+1]  ;get the next link of the number
               checkEdiAfter:
               and byte al, ah   ;"and" them
               cmp dword ecx, 0    ;check if we are in the final link of this number (upper)
               je bitwisersEnd
               cmp dword edi, 0    ;check if we are in the final link of this number (lower)
               je bitwisersEnd
               preformer:
                    linksFreeing_linksAllocating
                    jmp bitwiser

               bitwisersEnd:
                    cmp dword [esp+8], esi
                    je forCase1
                    cmp byte al, 0
                    je freedom
                    forCase1:
                         push eax             ;pushing the byte
                         push ebp
                         mov ebp, esp
                         pushad
                         push dword linkSize
                         call malloc   ;returns a pointer to the unintialized data at EAX
                         add dword esp, 4
                         mov byte dl, [ebp+4]  ;moving the byte to enter to dl
                         mov byte [eax], dl       ;placing the byte in the right place
                         mov dword [eax+1], 0     ; positioning the null terminator in case there is no other links
                         mov dword edx, [ebp+16]  ;getting the prvious links position to place the current address
                         mov dword [edx], eax     ;placing it in the right place
                         inc eax                  ; moving to the next link's address place in current link
                         mov dword [ebp+16], eax   ;place the address in the empty space
                         popad
                         pop ebp
                         add dword esp, 4
                    freedom:
                    push ebp
                    mov ebp, esp
                    cmp dword [ebp+8], 0
                    je skipFirst1
                    mov dword ecx, [ebp+8]
                    mov dword ecx, [ecx+1]
                    pusha
                    push dword [ebp+8]
                    call free 
                    add esp, 4
                    popad
                    mov dword [ebp+8], ecx
                    skipFirst1:
                    cmp dword [ebp+4], 0
                    je skipSecond1
                    mov dword edi, [ebp+4]
                    mov dword edi, [edi+1]
                    pusha
                    push dword [ebp+4]
                    call free 
                    add esp, 4
                    popad
                    mov dword [ebp+4], edi
                    skipSecond1:
                    pop ebp
                    cmp dword ecx, edi
                    jne freedom
               finalize:
                    add dword esp, 12    ;ecx,edi, prevlink
                    checkDe3:
                    cmp dword [ebp], 1
                    jne goOn3
                    debugger

                    goOn3:
                    endPoint
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;BITWISEANDEND;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     emptyStack:
          addressCleanerInput
          errorPrinter emptyError

     stackoverflow:
          addressCleanerInput
          errorPrinter overflowError
          
     illegalInput:
          addressCleanerInput
          errorPrinter illegalInputError