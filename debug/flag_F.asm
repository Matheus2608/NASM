; arquivo: flag_F.asm
; FLAG DEMONSTRADA: -F
;
; -g habilita as informações de depuração.
; -F escolhe o formato delas: dwarf (moderno) ou stabs (legado).
;
;   nasm -f elf64 -g -F dwarf flag_F.asm -o flag_F_dwarf.o
;   nasm -f elf64 -g -F stabs flag_F.asm -o flag_F_stabs.o
;
; O programa soma os valores do vetor, converte a soma para dois algarismos,
; imprime "Soma do vetor: 15" e encerra com status 15.

bits 64
default rel

section .data
    valores db 2, 4, 1, 3, 5
    quantidade equ $ - valores

    mensagem db "Soma do vetor: "
    tamanho_mensagem equ $ - mensagem

    resultado db "00", 10
    tamanho_resultado equ $ - resultado

section .text
    global _start

_start:
    lea rsi, [valores]
    mov ecx, quantidade
    call somar_vetor
    mov r12d, eax

    call converter_decimal

    ; write(1, mensagem, tamanho_mensagem)
    mov eax, 1
    mov edi, 1
    lea rsi, [mensagem]
    mov edx, tamanho_mensagem
    syscall

    ; write(1, resultado, tamanho_resultado)
    mov eax, 1
    mov edi, 1
    lea rsi, [resultado]
    mov edx, tamanho_resultado
    syscall

    ; exit(soma)
    mov eax, 60
    mov edi, r12d
    syscall

; Entrada: RSI aponta para o vetor e ECX contém a quantidade de elementos.
; Saída: EAX contém a soma.
somar_vetor:
    xor edx, edx

.proximo:
    movzx eax, byte [rsi]
    add edx, eax
    inc rsi
    loop .proximo

    mov eax, edx
    ret

; Entrada: EAX contém um valor entre 0 e 99.
; Saída: escreve os dois algarismos ASCII em "resultado".
converter_decimal:
    xor edx, edx
    mov ecx, 10
    div ecx

    add al, '0'
    add dl, '0'
    mov [resultado], al
    mov [resultado + 1], dl
    ret
