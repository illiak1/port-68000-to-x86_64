; -----------------------------------------------------------------------
; Port 68000 to x86_64
; -----------------------------------------------------------------------
section .data
    prompt  db "Enter number: ", 0   ; Define prompt string, null-terminated
    newline db 10, 0                 ; Define newline character, null-terminated

section .text
    global _start                     ; Export _start as entry point

_start:
    mov rdi, prompt                   ; Load address of prompt into RDI (first argument)
    call print_string                 ; Call print_string routine to print prompt

    mov rdi, newline                  ; Load address of newline into RDI
    call print_string                 ; Call print_string routine to print newline

    mov rax, 60                       ; Syscall number for exit (sys_exit)
    mov rdi, 0                        ; Exit code 0
    syscall                           ; Invoke syscall to exit program

; --- Minimal print routine ---
print_string:
    mov rsi, rdi                      ; Copy string pointer from RDI to RSI
    xor rdx, rdx                      ; Clear RDX to use as string length counter
.len_loop:
    cmp byte [rsi+rdx], 0             ; Compare current byte to null terminator
    je .do_print                       ; If null terminator, jump to printing
    inc rdx                            ; Otherwise, increment counter
    jmp .len_loop                      ; Repeat loop for next byte
.do_print:
    mov rax, 1                         ; Syscall number for write (sys_write)
    mov rdi, 1                         ; File descriptor 1 (stdout)
    syscall                            ; Invoke syscall to write string
    ret                                ; Return from print_string routine