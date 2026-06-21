; file: flag_wall.asm
; FLAG DEMONSTRADA: -w+all
;
; Habilita TODOS os avisos do NASM, incluindo os que estão DESLIGADOS por padrão.
; Modificação em relação a soma.asm:
;   - Adicionada 'tiny_val dd __float32__(1.0e-40)': constante de ponto flutuante
;     denormal (menor que o menor valor normalizado de 32 bits).
;     O aviso 'float-denorm' está OFF por padrão — só aparece com -w+all.
;
; Como compilar — compare as duas execuções:
;   nasm -f elf32 flag_wall.asm              <- sem avisos (float-denorm está off)
;   nasm -f elf32 flag_wall.asm -w+all       <- exibe o aviso float-denorm
;
; Saída esperada com -w+all:
;   flag_wall.asm:X: warning: denormal floating-point constant [-w+float-denorm]
;
; Isso demonstra que -w+all vai além do padrão: ativa classes de aviso que o NASM
; mantém silenciosas por default para não incomodar em casos comuns.

section .data
    prompt1    db "Enter a number (0-9): "
    len_p1     equ $ - prompt1
    prompt2    db "Enter another number (0-9): "
    len_p2     equ $ - prompt2
    outmsg1    db "You entered "
    len_o1     equ $ - outmsg1
    outmsg2    db " and "
    len_o2     equ $ - outmsg2
    outmsg3    db ", the sum of these is "
    len_o3     equ $ - outmsg3
    newline    db 10
    tiny_val   dd __float32__(1.0e-40) ; <-- constante denormal: só avisa com -w+all

section .bss
    input1   resb 1
    input2   resb 1
    res_ten  resb 1
    res_unit resb 1
    temp     resb 1

section .text
    global _start

_start:
    mov eax, 4
    mov ebx, 1
    mov ecx, prompt1
    mov edx, len_p1
    int 0x80

    mov eax, 3
    mov ebx, 0
    mov ecx, input1
    mov edx, 1
    int 0x80
    call flush_stdin

    mov eax, 4
    mov ebx, 1
    mov ecx, prompt2
    mov edx, len_p2
    int 0x80

    mov eax, 3
    mov ebx, 0
    mov ecx, input2
    mov edx, 1
    int 0x80
    call flush_stdin

    mov al, [input1]
    sub al, '0'
    mov bl, [input2]
    sub bl, '0'
    add al, bl

    cmp al, 9
    jbe menor_que_10

    mov ah, 0
    mov bl, 10
    div bl
    add al, '0'
    mov [res_ten], al
    add ah, '0'
    mov [res_unit], ah
    jmp imprimir

menor_que_10:
    mov byte [res_ten], 0
    add al, '0'
    mov [res_unit], al

imprimir:
    mov eax, 4
    mov ebx, 1
    mov ecx, outmsg1
    mov edx, len_o1
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, input1
    mov edx, 1
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, outmsg2
    mov edx, len_o2
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, input2
    mov edx, 1
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, outmsg3
    mov edx, len_o3
    int 0x80

    cmp byte [res_ten], 0
    je so_unidade
    mov eax, 4
    mov ebx, 1
    mov ecx, res_ten
    mov edx, 1
    int 0x80

so_unidade:
    mov eax, 4
    mov ebx, 1
    mov ecx, res_unit
    mov edx, 1
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    mov eax, 1
    xor ebx, ebx
    int 0x80

flush_stdin:
    .loop:
        mov eax, 3
        mov ebx, 0
        mov ecx, temp
        mov edx, 1
        int 0x80
        cmp byte [temp], 10
        jne .loop
    ret
