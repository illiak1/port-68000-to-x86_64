; -----------------------------------------------------------------------
; Project: Port 68000 to x86_64
; Author: Illia Karban
; Date: April 2026
; Description: This project ports functionality from Motorola 68000
;              assembly to x86_64 architecture, including user input,
;              numeric validation, summation logic, and error handling
;              for invalid input and arithmetic overflow.
; -----------------------------------------------------------------------

; --- MACROS ---

; Macro: PRINT_STR
; Argument: Pointer to a null-terminated string
; Loads string address into RDI and calls print_string
%macro PRINT_STR 1
    mov rdi, %1        ; load string address into RDI (1st arg)
    call print_string  ; call print helper
%endmacro

; Macro: EXIT
; Argument: Error code/Exit status
; Logic: Invokes sys_exit (RAX 60) with the provided status
%macro EXIT 1
    mov rax, 60        ; syscall number for exit
    mov rdi, %1        ; exit status code
    syscall            ; invoke kernel
%endmacro

section .data                  ; initialized data

    prompt       db "Enter number: ", 0              ; user input prompt
    result       db "The sum is: ", 0                ; current sum label
    final_result db "Final sum is: ", 0              ; final sum label
    error_msg    db "Invalid input! Please enter a positive integer.", 10, 0 ; invalid input msg
    overflow_msg db "Error: Input exceeds 64-bit limits!", 10, 0             ; input overflow msg
    math_err_msg db "Error: Arithmetic overflow detected!", 10, 0            ; math overflow msg
    newline      db 10, 0                            ; newline (LF)

section .bss             ; Uninitialized data (reserved space)
    input_buffer resb 64 ; 64-byte space to build strings for printing
    char_buf     resb 1  ; 1-byte space for reading individual chars from stdin


section .text            ; The .text section contains executable code (instructions)
    ; This is the program entry point (where execution begins)  
    global _start        ; Make the label _start visible to the linker
    
    global asm_register_adder ; Export the asm_register_adder function so it can be called
                              ; from other modules or linked code (not just locally)

_start:
    xor r12, r12         ; Clear R12 to 0 (Used as the Accumulator/Running Sum)
    mov r15, 3           ; Set loop counter to 3 (Run the program 3 times)

game_loop:
; Main loop: runs 3 iterations
; Each iteration reads two integers, computes sum, accumulates result

.get_input_1:
    xor rax, rax         ; reset syscall return register before read
    PRINT_STR prompt     ; Ask for first number
    call read_int        ; Convert user typing to integer
    test rdx, rdx        ; Check error code in RDX
    jnz .handle_in_err_1 ; If error (RDX != 0), jump to handler
    mov r13, rax         ; Save valid input in R13 (Temporary storage)

.get_input_2:
    PRINT_STR prompt     ; Ask for second number
    call read_int
    test rdx, rdx        ; Check for conversion errors
    jnz .handle_in_err_2
    
    ; --- REGISTER PASSING (Calling Convention) ---
    mov rdi, r13         ; First operand for adder
    mov rsi, rax         ; Second operand for adder
    call asm_register_adder
    jo .math_overflow    ; Check Overflow Flag if sum exceeds 64-bit capacity
    
    ; Update total running sum
    add r12, rax         ; Add the result of the subroutine to R12
    jo .math_overflow 

    push rax             ; Save result before printing (preserve value)
    PRINT_STR result
    pop rdi              ; Restore sum into RDI for printing
    call print_int       ; Print the decimal value
    PRINT_STR newline

    dec r15              ; Loop counter - 1
    jnz game_loop        ; If R15 is not 0, repeat the loop

    ; --- STACK PASSING ---
    PRINT_STR final_result
    push r12             ; Pass the final total via the Stack
    call stack_printer   ; Subroutine will look into the stack to find R12
    add rsp, 8           ; Clean up the stack (pop the parameter off)

    EXIT 0               ; Exit program successfully

; Error Handling Redirection
.handle_in_err_1:
    call handle_error_print
    jmp .get_input_1     ; Retry the first input

.handle_in_err_2:
    call handle_error_print
    jmp .get_input_2     ; Retry the second input

.math_overflow:
    PRINT_STR math_err_msg
    EXIT 1               ; Terminate with error code 1

; --- Subroutines ---

; Logic: Simple addition to demonstrate register-based argument passing
asm_register_adder:
    mov rax, rdi         ; Load first arg
    add rax, rsi         ; Add second arg
    ret

; Logic: Demonstrates manual stack frame navigation
stack_printer:
    push rbp             ; Save the caller's base pointer (old stack frame)
    mov rbp, rsp         ; Establish a new stack frame (RBP = current stack top)

    ; Stack layout at this point:
    ; [RBP]     = saved old RBP
    ; [RBP+8]   = return address (where to go after RET)
    ; [RBP+16]  = argument passed via stack (our value)

    mov rdi, [rbp+16]    ; Load the argument (the pushed value) into RDI
                         ; RDI is used as the first argument for print_int

    call print_int       ; Print the integer value

    PRINT_STR newline    ; Print a newline after the number

    pop rbp              ; Restore the original base pointer (previous stack frame)
    ret                  ; Return to caller (jump to saved return address)

; Logic: Reads input from stdin and converts ASCII to integer
; Returns: RAX (value), RDX (0=Success, 1=Invalid Char, 2=Overflow)
read_int:
    xor rbx, rbx         ; RBX = current integer value (running total)
    xor r14, r14         ; Using R14 as digit counter
.read_char:
    mov rax, 0           ; System Call: sys_read
    mov rdi, 0           ; File Descriptor: stdin
    mov rsi, char_buf    ; Pointer to buffer
    mov rdx, 1           ; Number of bytes to read
    syscall

    mov al, [char_buf]   ; Move the read character into AL
    cmp al, 10           ; Check for Newline (ASCII 10)
    je .done             ; If newline, we finished reading the number

    cmp al, '0'          ; Check if character is below '0'
    jb .err
    cmp al, '9'          ; Check if character is above '9'
    ja .err
    
    sub al, '0'          ; Convert ASCII character to its numeric value
    movzx r8, al         ; Move value to 64-bit register R8
    mov rax, rbx         ; Load current total into RAX for multiplication
    imul rax, 10         ; Shift existing number left (e.g., 5 -> 50)
    jo .ovf              ; Jump if multiplication overflowed 64 bits
    add rax, r8          ; Add the new digit
    jo .ovf              ; Jump if addition overflowed 64 bits
    mov rbx, rax         ; Update running total in RBX
    inc r14              ; Increment our safe counter
    jmp .read_char       ; Loop to get next character

.done:
    test r14, r14        ; Was any digit actually processed?
    jz .err              ; If 0 digits, treat as error (Invalid input)
    mov rax, rbx         ; Return value
    xor rdx, rdx         ; Success code 0
    ret

.ovf: 
    mov r10, 2           ; Set error code 2 for Overflow
    jmp .flush
.err: 
    mov r10, 1           ; Set error code 1 for Invalid Character
.flush:
    ; Logic: Clear remaining stdin after error
    ; Prevent leftover chars from affecting next input
    cmp byte [char_buf], 10 ; check if newline already reached
    je .exit_err            ; if yes, stop flushing

    mov rax, 0              ; sys_read syscall
    mov rdi, 0              ; stdin (fd = 0)
    mov rsi, char_buf       ; buffer address
    mov rdx, 1              ; read 1 byte
    syscall                 ; read next char

    jmp .flush              ; loop until newline found

.exit_err:
    mov rdx, r10            ; return error code in RDX
    ret                     ; return to caller

; Logic: Simple null-terminated string printer using sys_write
print_string:
    mov rsi, rdi         ; RSI needs the pointer to the string
    xor rdx, rdx         ; RDX will serve as the length counter
.len_loop:
    cmp byte [rsi+rdx], 0 ; Check for the null terminator
    je .do_print
    inc rdx              ; Increment length
    jmp .len_loop
.do_print:
    mov rax, 1           ; System Call: sys_write
    mov rdi, 1           ; File Descriptor: stdout
    syscall              ; RSI and RDX are already set by logic above
    ret

; Logic: Converts an integer to an ASCII string and prints it
print_int:
    mov rax, rdi         ; Number to be converted
    mov r8, 10           ; Base 10 divisor
    mov rsi, input_buffer + 63 ; Start at the end of the buffer
    mov byte [rsi], 0    ; Place null terminator at the end
.conv:
    dec rsi              ; Move buffer pointer one step left
    xor rdx, rdx         ; Clear RDX for division
    div r8               ; RAX = Quotient, RDX = Remainder (the digit)
    add dl, '0'          ; Convert digit to ASCII
    mov [rsi], dl        ; Store ASCII character in buffer
    test rax, rax        ; Check if there are more digits to process
    jnz .conv            ; Loop if RAX > 0
    
    ; Setup sys_write to print the resulting string in the buffer
    mov rdi, 1           ; stdout
    mov rax, 1           ; sys_write
    mov rdx, input_buffer + 63
    sub rdx, rsi         ; Calculate length (End - Current Start)
                         ; RSI is already pointing to the start of the string
    syscall
    ret

; Logic: Interprets RDX error code and prints relevant message
handle_error_print:
    cmp rdx, 2           ; Check if the error code is 2 (Overflow)
    je .o                ; Jump to overflow printer
    PRINT_STR error_msg  ; Default: print general invalid input message
    ret
.o: 
    PRINT_STR overflow_msg ; Print specific overflow message
    ret
