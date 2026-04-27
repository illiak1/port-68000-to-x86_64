; -----------------------------------------------------------------------
; Port 68000 to x86_64
; -----------------------------------------------------------------------

section .data
    prompt  db "Enter number: ", 0   ; Define prompt string, null-terminated
    newline db 10, 0                 ; Define newline character, null-terminated

section .text
    global _start                     ; Export _start as entry point

_start:
    mov rcx, 3                        ; Loop counter (run 3 times)

.loop_start:
    mov rdi, prompt                  ; Load prompt string address
    call print_string                ; Print prompt

    mov rdi, newline                 ; Load newline string address
    call print_string                ; Print newline

    dec rcx                          ; Decrement loop counter
    jnz .loop_start                  ; Repeat until zero

    mov rax, 60                      ; syscall: exit
    mov rdi, 0                       ; exit code 0
    syscall

; -----------------------------------------------------------------------
; Print String Function
; -----------------------------------------------------------------------
print_string:
    mov rsi, rdi                     ; Copy string pointer to RSI
    xor rdx, rdx                     ; Clear length counter

.len_loop:
    cmp byte [rsi + rdx], 0         ; Check for null terminator
    je .do_print                     ; If found, print string
    inc rdx                          ; Increase length
    jmp .len_loop                    ; Continue scanning

.do_print:
    mov rax, 1                      ; sys_write
    mov rdi, 1                      ; stdout
    syscall
    ret
