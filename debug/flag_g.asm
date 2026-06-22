; arquivo: flag_g.asm
; FLAG DEMONSTRADA: -g
;
; A flag -g faz o NASM incluir informações de depuração no arquivo objeto.
; Em ELF64, o formato de depuração padrão é DWARF. Essas informações permitem
; que ferramentas como GDB e readelf relacionem instruções de máquina com este
; arquivo-fonte e com suas linhas.
;
; Montagem sem informações de depuração:
;   nasm -f elf64 flag_g.asm -o flag_g_sem_debug.o
;
; Montagem com informações de depuração:
;   nasm -f elf64 -g -F dwarf flag_g.asm -o flag_g_com_debug.o
;
; O programa incrementa a variável "contador" três vezes, mostra uma mensagem
; e encerra com status 3. A lógica e a saída são iguais com ou sem -g; o que
; muda são os metadados adicionados ao arquivo objeto.

bits 64
default rel

section .data
    contador dq 0
    mensagem db "Contador incrementado 3 vezes.", 10
    tamanho_mensagem equ $ - mensagem

section .text
    global _start

_start:
    mov ecx, 3

incrementar:
    inc qword [contador]
    loop incrementar

fim_do_loop:
    ; write(1, mensagem, tamanho_mensagem)
    mov eax, 1
    mov edi, 1
    lea rsi, [mensagem]
    mov edx, tamanho_mensagem
    syscall

    ; exit(contador)
    mov eax, 60
    mov edi, dword [contador]
    syscall

