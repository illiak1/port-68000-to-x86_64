; -----------------------------------------------------------------------
; Port 68000 to x86_64 
; -----------------------------------------------------------------------

section .data
    prompt       db "Enter number: ", 0   ; Define prompt string, null-terminated
    result_msg   db "The sum is: ", 0     ; New: Result label
    newline      db 10, 0                 ; Define newline character, null-terminated

section .bss
    input_buffer resb 64                  ; Buffer for integer conversion

section .text
    global _start                         ; Export _start as entry point
    global asm_register_adder             ; Export addition logic

_start:
    mov rcx, 3                            ; Loop counter (run 3 times)
    xor r12, r12                          ; Running total (accumulated sum)

.loop_start:
    ; Save counter because syscalls/calls might clobber rcx/r11
    push rcx

    mov rdi, prompt                       ; Load prompt string address
    call print_string                     ; Print prompt

    ; --- Expansion: Simple Addition Logic ---
    ; In this version, we'll hardcode or simulate addition 
    ; before moving to full user input in Version 3.
    mov rdi, 10                           ; First number
    mov rsi, 5                            ; Second number
    call asm_register_adder               ; rax = rdi + rsi
    add r12, rax                          ; Add to running total

    mov rdi, result_msg
    call print_string
    
    mov rdi, rax                          ; Move sum to rdi for printing
    call print_int

    mov rdi, newline                      ; Load newline string address
    call print_string                     ; Print newline

    pop rcx                               ; Restore loop counter
    dec rcx                               ; Decrement loop counter
    jnz .loop_start                       ; Repeat until zero

    mov rax, 60                           ; syscall: exit
    mov rdi, 0                            ; exit code 0
    syscall

; -----------------------------------------------------------------------
; Addition Function (Register Passing)
; -----------------------------------------------------------------------
asm_register_adder:
    mov rax, rdi
    add rax, rsi
    ret

; -----------------------------------------------------------------------
; Print Integer Function
; -----------------------------------------------------------------------
print_int:
    mov rax, rdi
    mov r8, 10
    mov rsi, input_buffer + 63
    mov byte [rsi], 0
.conv:
    dec rsi
    xor rdx, rdx
    div r8
    add dl, '0'
    mov [rsi], dl
    test rax, rax
    jnz .conv
    mov rdi, 1
    mov rax, 1
    mov rdx, input_buffer + 63
    sub rdx, rsi
    syscall
    ret

; -----------------------------------------------------------------------
; Print String Function
; -----------------------------------------------------------------------
print_string:
    mov rsi, rdi                      ; Copy string pointer to RSI
    xor rdx, rdx                      ; Clear length counter

.len_loop:
    cmp byte [rsi + rdx], 0           ; Check for null terminator
    je .do_print                      ; If found, print string
    inc rdx                           ; Increase length
    jmp .len_loop                     ; Continue scanning

.do_print:
    mov rax, 1                        ; sys_write
    mov rdi, 1                        ; stdout
    syscall
    ret
