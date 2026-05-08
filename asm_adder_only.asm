; ----------------------------------------------------------------------
; File: asm_adder_only.asm
; Author: Illia Karban
; Description:
;   Follows standard Linux x86_64 calling convention.
;   Implements a simple integer adder:
;
;       result = a + b
;
;   Inputs:
;       RDI - first integer (a)
;       RSI - second integer (b)
;
;   Output:
;       RAX - sum of a and b
;
;   This module is intended to be linked with C test code.
; ----------------------------------------------------------------------

global asm_register_adder

section .text
asm_register_adder:
    mov rax, rdi   ; move first argument into return register
    add rax, rsi   ; add second argument
    ret            ; return result in rax