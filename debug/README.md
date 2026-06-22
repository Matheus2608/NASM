# Flags de depuração `-g` e `-F`

Testes feitos com NASM 2.16.01, GNU GDB 15.1 e Linux x86-64.

- `flag_g.asm`: compara um objeto sem debug com outro contendo DWARF.
- `flag_F.asm`: compara os formatos DWARF e STABS.

Segundo o `nasm -h`:

```text
-g            generate debugging information
-F format     select a debugging format (output format dependent)
-gformat      same as -g -F format
```

`-g` gera os metadados de depuração. `-F` escolhe o formato desses dados.
Em `elf64`, DWARF é o formato moderno e padrão; STABS é legado.

## Flag `-g`

O `flag_g.asm` incrementa um contador três vezes, imprime uma mensagem e
termina com status `3`. Monte o mesmo fonte com e sem debug:

```bash
cd debug
nasm -f elf64 flag_g.asm -o flag_g_sem_debug.o
nasm -f elf64 -g flag_g.asm -o flag_g_com_debug.o
```

Compare as seções e os tamanhos:

```bash
readelf -SW flag_g_sem_debug.o | grep '\.debug'
readelf -SW flag_g_com_debug.o | grep '\.debug'
stat -c '%n %s bytes' flag_g_sem_debug.o flag_g_com_debug.o
```

Resultado observado:

```text
# Sem -g: nenhuma seção .debug

# Com -g:
.debug_aranges
.debug_info
.debug_abbrev
.debug_line

flag_g_sem_debug.o 1088 bytes
flag_g_com_debug.o 2432 bytes
```

`.debug_info` descreve o código e `.debug_line` associa endereços de máquina
ao arquivo e às linhas do Assembly. O objeto com `-g` é maior por causa desses
metadados, não porque executa mais instruções.

```bash
readelf --debug-dump=decodedline flag_g_com_debug.o
```

Trecho:

```text
CU: flag_g.asm:
flag_g.asm    31    0
flag_g.asm    34    0x5
flag_g.asm    35    0xc
```

O comportamento continua igual:

```bash
ld -o flag_g_com_debug flag_g_com_debug.o
./flag_g_com_debug
echo $?
```

```text
Contador incrementado 3 vezes.
3
```

## Flag `-F`

O `flag_F.asm` soma cinco elementos de um vetor, chama uma rotina de conversão
decimal, imprime a soma e termina com status `15`. Ele possui laço, função,
variáveis e rótulos úteis para um depurador.

Gere o mesmo programa nos dois formatos:

```bash
nasm -f elf64 -g -F dwarf flag_F.asm -o flag_F_dwarf.o
nasm -f elf64 -g -F stabs flag_F.asm -o flag_F_stabs.o
ld -o flag_F_dwarf flag_F_dwarf.o
ld -o flag_F_stabs flag_F_stabs.o
```

As duas versões executam a mesma lógica:

```bash
./flag_F_dwarf; echo "status=$?"
./flag_F_stabs; echo "status=$?"
```

```text
Soma do vetor: 15
status=15
Soma do vetor: 15
status=15
```

Compare a estrutura dos objetos:

```bash
readelf -SW flag_F_dwarf.o | grep '\.debug'
readelf -SW flag_F_stabs.o | grep '\.stab'
stat -c '%n %s bytes' flag_F_dwarf.o flag_F_stabs.o
```

Resultado resumido:

```text
DWARF: .debug_info, .debug_line, .debug_abbrev
STABS: .stab, .stabstr, .rela.stab

flag_F_dwarf.o 2704 bytes
flag_F_stabs.o 2816 bytes
```

STABS não ficou menor. O critério mais importante é a compatibilidade com as
ferramentas, e não apenas o tamanho.

Os dois formatos registraram as linhas usando estruturas diferentes:

```bash
readelf --debug-dump=decodedline flag_F_dwarf.o
objdump --stabs flag_F_stabs.o
```

```text
# DWARF
flag_F.asm    59    0x53
flag_F.asm    62    0x55
flag_F.asm    63    0x58

# STABS
SLINE  0  59  0000000000000053
SLINE  0  62  0000000000000055
SLINE  0  63  0000000000000058
```

No GDB, execute `info line somar_vetor` e `list somar_vetor`. Com DWARF, o
resultado foi:

```text
Line 59 of "flag_F.asm" starts at address ... <somar_vetor>
```

Com STABS:

```text
No line number information available for address ... <somar_vetor>
```

O `objdump` confirma que os registros STABS existem, mas o GDB 15.1 testado
não os usou para mostrar linhas nesse executável ELF64. Isso demonstra por que
DWARF deve ser preferido em projetos novos.

## Formas equivalentes

Como DWARF é o padrão de `elf64`, estes comandos geram o mesmo tipo de debug:

```bash
nasm -f elf64 -g flag_F.asm -o programa.o
nasm -f elf64 -g -F dwarf flag_F.asm -o programa.o
nasm -f elf64 -gdwarf flag_F.asm -o programa.o
```

No NASM 2.16.01, `-F dwarf` e `-F stabs` sozinhos também habilitaram o debug e
produziram objetos idênticos aos feitos com `-g -F`. Mesmo assim, escrever
`-g -F formato` é mais claro: uma opção pede o debug e a outra escolhe seu
formato.

Em resumo: use `-g` para depurar, prefira `-F dwarf` e deixe `-F stabs` para
estudo ou compatibilidade com ferramentas antigas.

```bash
rm -f flag_g_*.o flag_g_com_debug
rm -f flag_F_*.o flag_F_dwarf flag_F_stabs
```
