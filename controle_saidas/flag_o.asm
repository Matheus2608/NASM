; file: flag_o.asm
; FLAG DEMONSTRADA: -o <arquivo>
;
; A flag '-o' instrui o montador (NASM) a nomear o arquivo final gerado com
; um nome customizado escolhido pelo usuário. Por padrão, se essa flag não
; for usada, o NASM apenas pega o nome original e troca a extensão (ex: de
; .asm para .o).
;
; Modificação em relação a soma.asm:
;   O código abaixo é um programa 
;   que apenas inicia e encerra com sucesso (sys_exit).
;
; Como testar — compare as duas execuções:
;   nasm -f elf32 flag_o.asm
;     -> use o comando 'ls' e veja que o NASM gerou o arquivo padrão: flag_o.o
;
;   nasm -f elf32 flag_o.asm -o meu_programa_compilado.o
;     -> use o comando 'ls' e veja que o arquivo customizado apareceu: 
;        meu_programa_compilado.o

section .data
    prompt1 db "Enter a number (0-9): "
    len_p1  equ $ - prompt1
    prompt2 db "Enter another number (0-9): "
    len_p2  equ $ - prompt2
    outmsg1 db "You entered "
    len_o1  equ $ - outmsg1
    outmsg2 db " and "
    len_o2  equ $ - outmsg2
    outmsg3 db ", the sum of these is "
    len_o3  equ $ - outmsg3
    newline db 10

section .bss
    input1 resb 1
    input2 resb 1
    res_ten resb 1    ; Dezena do resultado
    res_unit resb 1   ; Unidade do resultado
    temp    resb 1    ; Para limpar o buffer

section .text
    global _start

_start:
    ; --- LER PRIMEIRO NÚMERO ---
    ; Exibir Prompt 1
    mov eax, 4
    mov ebx, 1
    mov ecx, prompt1
    mov edx, len_p1
    int 0x80

    ; Ler entrada
    mov eax, 3
    mov ebx, 0
    mov ecx, input1
    mov edx, 1
    int 0x80
    call flush_stdin

    ; --- LER SEGUNDO NÚMERO ---
    ; Exibir Prompt 2
    mov eax, 4
    mov ebx, 1
    mov ecx, prompt2
    mov edx, len_p2
    int 0x80

    ; Ler entrada
    mov eax, 3
    mov ebx, 0
    mov ecx, input2
    mov edx, 1
    int 0x80
    call flush_stdin

    ; --- LÓGICA DA SOMA ---
    mov al, [input1]
    sub al, '0'
    mov bl, [input2]
    sub bl, '0'
    add al, bl          

    cmp al, 9
    jbe menor_que_10
    
    ; Caso a soma seja > 9 (ex: 13)
    mov ah, 0
    mov bl, 10
    div bl              ; AL = quociente (1), AH = resto (3)
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
    ; --- EXIBIÇÃO DO RESULTADO ---
    ; "You entered "
    mov eax, 4
    mov ebx, 1
    mov ecx, outmsg1
    mov edx, len_o1
    int 0x80

    ; Primeiro número
    mov eax, 4
    mov ebx, 1
    mov ecx, input1
    mov edx, 1
    int 0x80

    ; " and "
    mov eax, 4
    mov ebx, 1
    mov ecx, outmsg2
    mov edx, len_o2
    int 0x80

    ; Segundo número
    mov eax, 4
    mov ebx, 1
    mov ecx, input2
    mov edx, 1
    int 0x80

    ; ", the sum of these is "
    mov eax, 4
    mov ebx, 1
    mov ecx, outmsg3
    mov edx, len_o3
    int 0x80

    ; Imprime dezena se existir
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

    ; Pular linha
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    ; Sair do programa
    mov eax, 1
    xor ebx, ebx
    int 0x80

; --- FUNÇÃO PARA LIMPAR O BUFFER DO TECLADO ---
flush_stdin:
    .loop:
        mov eax, 3
        mov ebx, 0
        mov ecx, temp
        mov edx, 1
        int 0x80
        cmp byte [temp], 10 ; Verifica se é o Enter (ASCII 10)
        jne .loop
    ret