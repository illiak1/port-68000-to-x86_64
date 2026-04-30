; -----------------------------------------------------------------------
; Port 68000 to x86_64
; -----------------------------------------------------------------------

section .data
    prompt        db "Enter number: ", 0    ; Define prompt string, null-terminated
    result_msg    db "The sum is: ", 0      ; Result label
    final_msg     db "Final sum is: ", 0    ; Final accumulated sum label
    error_msg     db "Invalid input!", 10, 0 ; Error message for non-numeric input
    overflow_msg  db "Overflow detected!", 10, 0 ; Message for arithmetic overflow
    newline       db 10, 0                  ; Define newline character, null-terminated

section .bss
    input_buffer  resb 64                   ; Buffer for integer conversion
    char_buf      resb 1                    ; Buffer for reading single character

section .text
    global _start                           ; Export _start as entry point
    global asm_register_adder               ; Export addition logic

_start:
    xor r12, r12          ; Running total (accumulated sum)
    mov rcx, 3            ; Loop counter (run 3 times)

.loop:
    ; Save counter because syscalls/calls might clobber rcx/r11
    push rcx

.get_first:
    mov rdi, prompt       ; Load prompt string address
    call print_string     ; Print prompt
    call read_int         ; Read integer input
    test rdx, rdx         ; Check status in RDX (0 = OK)
    jnz .input_error1     ; Handle error or overflow
    mov r13, rax          ; Temporarily store first number in r13

.get_second:
    mov rdi, prompt       ; Load prompt string address
    call print_string     ; Print prompt
    call read_int         ; Read second integer
    test rdx, rdx         ; Check status in RDX
    jnz .input_error2     ; Handle error or overflow

    ; --- register passing ---
    mov rdi, r13          ; First number to RDI
    mov rsi, rax          ; Second number to RSI
    call asm_register_adder
    jo .overflow          ; Check if the addition overflowed

    add r12, rax          ; Add current sum to running total (r12)
    jo .overflow          ; Check if running total overflowed

    ; --- print result ---
    mov rdi, result_msg   ; Load result message
    call print_string

    mov rdi, rax          ; Move current sum to rdi for printing
    call print_int

    mov rdi, newline      ; Print newline
    call print_string

    pop rcx               ; Restore loop counter
    dec rcx               ; Decrement loop counter
    jnz .loop             ; Repeat until zero

    ; --- final sum ---
    mov rdi, final_msg    ; Load final result label
    call print_string

    mov rdi, r12          ; Move final running total to rdi
    call print_int

    mov rdi, newline      ; Print newline
    call print_string

    mov rax, 60           ; syscall: exit
    xor rdi, rdi          ; exit code 0
    syscall

.input_error1:
    mov rdi, error_msg    ; Show error message
    call print_string
    jmp .get_first        ; Retry first number

.input_error2:
    mov rdi, error_msg    ; Show error message
    call print_string
    jmp .get_second       ; Retry second number

.overflow:
    mov rdi, overflow_msg ; Show overflow message
    call print_string
    mov rax, 60           ; Exit with error code
    mov rdi, 1
    syscall

; -----------------------------------------------------------------------
; Addition Function (Register Passing)
; -----------------------------------------------------------------------
asm_register_adder:
    mov rax, rdi          ; Move first arg to RAX
    add rax, rsi          ; Add second arg
    ret                   ; Return (caller checks JO)

; -----------------------------------------------------------------------
; Read Integer (with validation + overflow)
; RAX = value, RDX = status (0 ok, 1 error, 2 overflow)
; -----------------------------------------------------------------------
read_int:
    xor rbx, rbx          ; Clear accumulator
    xor rcx, rcx          ; Character counter to detect empty input

.read:
    mov rax, 0            ; sys_read
    mov rdi, 0            ; stdin
    mov rsi, char_buf     ; buffer
    mov rdx, 1            ; read 1 byte
    syscall

    mov al, [char_buf]    ; Load character
    cmp al, 10            ; Check for newline (Enter key)
    je .done

    cmp al, '0'           ; Validate ASCII lower bound
    jb .err
    cmp al, '9'           ; Validate ASCII upper bound
    ja .err

    sub al, '0'           ; Convert ASCII to digit
    movzx r8, al          ; Zero-extend digit to 64-bit

    mov rax, rbx          ; Move current total to RAX for multiplication
    imul rax, 10          ; Multiply current value by 10
    jo .ovf               ; Check for multiplication overflow

    add rax, r8           ; Add the new digit
    jo .ovf               ; Check for addition overflow

    mov rbx, rax          ; Move result back to accumulator
    inc rcx               ; Increment character count
    jmp .read

.done:
    test rcx, rcx         ; Did we read any digits at all?
    jz .err               ; If 0 digits, treat as error

    mov rax, rbx          ; Return value in RAX
    xor rdx, rdx          ; Status: 0 (OK)
    ret

.err:
    mov rdx, 1            ; Status: 1 (Invalid Input)
    ret

.ovf:
    mov rdx, 2            ; Status: 2 (Overflow)
    ret

; -----------------------------------------------------------------------
; Print Integer Function
; -----------------------------------------------------------------------
print_int:
    mov rax, rdi          ; Number to convert
    mov r8, 10            ; Divisor
    mov rsi, input_buffer + 63 ; Start at end of buffer
    mov byte [rsi], 0     ; Null terminator

.conv:
    dec rsi
    xor rdx, rdx          ; Clear RDX for division
    div r8                ; RAX / 10, Remainder in RDX
    add dl, '0'           ; Convert remainder to ASCII
    mov [rsi], dl         ; Store character
    test rax, rax         ; Any digits left?
    jnz .conv

    mov rdi, 1            ; stdout
    mov rax, 1            ; sys_write
    mov rdx, input_buffer + 63
    sub rdx, rsi          ; Calculate string length
    syscall
    ret

; -----------------------------------------------------------------------
; Print String Function
; -----------------------------------------------------------------------
print_string:
    mov rsi, rdi          ; Copy string pointer to RSI
    xor rdx, rdx          ; Clear length counter

.len:
    cmp byte [rsi + rdx], 0 ; Check for null terminator
    je .print
    inc rdx               ; Increment length
    jmp .len

.print:
    mov rax, 1            ; sys_write
    mov rdi, 1            ; stdout
    syscall               ; RSI and RDX already set
    ret
