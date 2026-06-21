; file: flag_wnoall.asm
; FLAG DEMONSTRADA: -w-all
;
; Silencia TODOS os avisos do NASM. Útil para código legado com muitos
; warnings inofensivos que poluem a saída do terminal.
; Modificação em relação a soma.asm:
;   - Adicionada 'unused_var db 0' (mesma causa de aviso do flag_wall.asm).
;
; Como compilar — compare as duas execuções:
;   nasm -f elf32 flag_wnoall.asm -w+all    <- mostra o aviso
;   nasm -f elf32 flag_wnoall.asm -w-all    <- silêncio total, só erros fatais
;
; Com -w-all o arquivo .o é gerado sem nenhuma mensagem, mesmo com unused_var.

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
    unused_var db 0   ; <-- mesma variável não utilizada; com -w-all não gera aviso

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
