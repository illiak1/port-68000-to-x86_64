; -----------------------------------------------------------------------
; Project: Port 68000 to x86_64
; Date: April 2026
; Description: This project ports functionality from Motorola 68000
;              assembly to x86_64 architecture, including user input,
;              numeric validation, summation logic, and error handling
;              for invalid input and arithmetic overflow.
; -----------------------------------------------------------------------

section .data                  ; initialized data

    prompt       db "Enter number: ", 0              ; user input prompt
    result       db "The sum is: ", 0                ; current sum label
    final_result db "Final sum is: ", 0              ; final sum label
    error_msg    db "Invalid input! Please enter a positive integer.", 10, 0 ; invalid input msg
    overflow_msg db "Error: Input exceeds 64-bit limits!", 10, 0             ; input overflow msg
    math_err_msg db "Error: Arithmetic overflow detected!", 10, 0            ; math overflow msg
    newline      db 10, 0                            ; newline (LF)

section .bss
    input_buffer resb 64     ; buffer for number-to-string conversion
    char_buf     resb 1      ; buffer for single character input

section .text
    global _start
    global asm_register_adder

_start:
    xor r12, r12             ; running sum = 0
    mov r15, 3               ; loop counter = 3

game_loop:
.get_input_1:
    mov rdi, prompt          ; print prompt
    call print_string
    call read_int            ; read integer
    test rdx, rdx            ; check error
    jnz .handle_in_err_1
    mov r13, rax             ; store first number

.get_input_2:
    mov rdi, prompt          ; print prompt again
    call print_string
    call read_int
    test rdx, rdx
    jnz .handle_in_err_2

    mov rdi, r13             ; first argument
    mov rsi, rax             ; second argument
    call asm_register_adder
    jo .math_overflow        ; check overflow

    add r12, rax             ; update total sum
    jo .math_overflow

    push rax                 ; save current result
    mov rdi, result          ; print "The sum is: "
    call print_string
    pop rdi                  ; restore result
    call print_int           ; print number
    mov rdi, newline         ; print newline
    call print_string

    dec r15                  ; decrement loop counter
    jnz game_loop            ; repeat if not zero

    mov rdi, final_result    ; print final label
    call print_string
    push r12                 ; pass final sum via stack
    call stack_printer
    add rsp, 8               ; clean stack

    mov rax, 60              ; sys_exit
    mov rdi, 0               ; exit code 0
    syscall

.handle_in_err_1:
    call handle_error_print  ; print error
    jmp .get_input_1         ; retry input 1

.handle_in_err_2:
    call handle_error_print
    jmp .get_input_2         ; retry input 2

.math_overflow:
    mov rdi, math_err_msg    ; print overflow message
    call print_string
    mov rax, 60              ; sys_exit
    mov rdi, 1               ; exit with error
    syscall

; --- Subroutines ---

asm_register_adder:
    mov rax, rdi             ; load first operand
    add rax, rsi             ; add second operand
    ret

stack_printer:
    push rbp                 ; save base pointer
    mov rbp, rsp             ; new stack frame

    mov rdi, [rbp+16]        ; get argument from stack
    call print_int           ; print it

    mov rdi, newline         ; print newline
    call print_string

    pop rbp                  ; restore base pointer
    ret

read_int:
    xor rbx, rbx             ; result = 0
    xor rcx, rcx             ; digit counter = 0
.read_char:
    mov rax, 0               ; sys_read
    mov rdi, 0               ; stdin
    mov rsi, char_buf        ; buffer
    mov rdx, 1               ; read 1 byte
    syscall

    mov al, [char_buf]       ; load char
    cmp al, 10               ; newline?
    je .done

    cmp al, '0'              ; below '0'?
    jb .err
    cmp al, '9'              ; above '9'?
    ja .err

    sub al, '0'              ; ASCII -> digit
    movzx r8, al
    mov rax, rbx
    imul rax, 10             ; multiply by 10
    jo .ovf
    add rax, r8              ; add digit
    jo .ovf
    mov rbx, rax             ; update result
    inc rcx                  ; increment digit count
    jmp .read_char

.done:
    test rcx, rcx            ; no digits entered?
    jz .err
    mov rax, rbx             ; return value
    xor rdx, rdx             ; success (0)
    ret

.ovf:
    mov r10, 2               ; overflow error code
    jmp .flush
.err:
    mov r10, 1               ; invalid input error
.flush:
    cmp byte [char_buf], 10  ; newline reached?
    je .exit_err
    mov rax, 0
    mov rdi, 0
    mov rsi, char_buf
    mov rdx, 1
    syscall
    jmp .flush
.exit_err:
    mov rdx, r10             ; return error code
    ret

print_string:
    mov rsi, rdi             ; string pointer
    xor rdx, rdx             ; length = 0
.len_loop:
    cmp byte [rsi+rdx], 0    ; null terminator?
    je .do_print
    inc rdx                  ; increment length
    jmp .len_loop
.do_print:
    mov rax, 1               ; sys_write
    mov rdi, 1               ; stdout
    syscall
    ret

print_int:
    mov rax, rdi             ; number
    mov r8, 10               ; base 10
    mov rsi, input_buffer+63 ; end of buffer
    mov byte [rsi], 0        ; null terminator
.conv:
    dec rsi                  ; move left
    xor rdx, rdx
    div r8                   ; divide by 10
    add dl, '0'              ; to ASCII
    mov [rsi], dl
    test rax, rax
    jnz .conv

    mov rdi, 1               ; stdout
    mov rax, 1               ; sys_write
    mov rdx, input_buffer+63
    sub rdx, rsi             ; length
    syscall
    ret

handle_error_print:
    cmp rdx, 2               ; overflow?
    je .o
    mov rdi, error_msg       ; print invalid input
    call print_string
    ret
.o:
    mov rdi, overflow_msg    ; print overflow msg
    call print_string
    ret
