# Flags de Modificação da Estrutura Interna do NASM

Demonstração prática das flags que alteram a tabela de símbolos, o fluxo de pré-processamento e a assinatura binária do arquivo objeto gerado.

## Estrutura dos arquivos

| Arquivo | Descrição |
|---------|-----------|
| `soma.asm` | Código-fonte em Assembly puramente focado em chamadas de sistema (syscalls) Linux para 32 bits, com tratamento de dezenas e limpeza de buffer. |

Diferente das flags de formato (`-f`), estas flags operam modificando as tabelas internas do código na memória ou ignorando etapas de processamento, sem a necessidade de reescrever o arquivo `.asm` original.

**Texto oficial do `nasm -h`:**

```
--prefix str   prepend the given string to the names of all extern, common and global symbols
--lprefix str  prepend the given string to local symbols
-a             don't preprocess (assemble only)
--reproducible attempt to produce run-to-run identical output
```

## Comandos usados

```bash
nasm -f elf32 fix.asm --prefix _ -o fix_prefix.o
nasm -f elf32 fix.asm --lprefix interno_ -o fix_lprefix.o
nasm -f elf32 fix.asm -a -o fix_direto.o
nasm -f elf32 fix.asm --reproducible -o fix_rep.o
```

## 1. Modificação de Símbolos (`--prefix` e `--lprefix`)

O NASM permite renomear silenciosamente os símbolos (rótulos e variáveis) do programa durante a montagem para evitar colisões com outros arquivos ou atender a padrões de ligadores (linkers) em C. Podemos inspecionar essas mudanças com o comando `nm`.

### O resultado da tabela de símbolos

Ao executarmos o arquivo prefixado, temos o seguinte comportamento:

**Comando:** `nm fix_prefix.o`

```
00000000 T __start
00000160 t flush_stdin
0000009e t imprimir
00000000 b input1
```

Ao executarmos o arquivo prefixado, temos o seguinte comportamento:

**Comando:** `nm fix_lprefix.o`

```
00000000 T _start
00000160 t interno_flush_stdin
00000160 t interno_flush_stdin.loop
0000009e t interno_imprimir
00000000 b interno_input1
```


### Análise do `--prefix`

Como documentado, a flag `--prefix` atua exclusivamente sobre símbolos globais, comuns ou externos. Como o nosso `fix.asm` define apenas `global _start`, o NASM anexou o `_` unicamente a ele, transformando-o em `__start`. Variáveis locais como `input1` ou rótulos como `imprimir` permaneceram intocados.

### Análise do `--lprefix`

Atua de forma inversa. A flag `--lprefix interno_` não toca no global `_start`, mas reescreve toda a estrutura interna do programa. Rótulos nativos se transformam em `interno_imprimir`, `interno_flush_stdin`, etc. É o controle ideal para compilar bibliotecas sem poluir o escopo global.

## 2. Bypass do Pré-processador (`-a`)

O NASM funciona em duas etapas principais: Pré-processamento (onde resolve macros e diretivas) e a Montagem (onde converte mnemônicos em código de máquina). A opção `-a` desliga a primeira etapa.

### O erro esperado e justificado

**Comando:** `nasm -f elf32 fix.asm -a -o fix_direto.o`

```
fix.asm:2: error: parser: instruction expected
fix.asm:15: error: label `section' inconsistently redefined
fix.asm:2: info: label `section' originally defined here
fix.asm:15: error: parser: instruction expected
```

### Por que isso acontece?

Palavras estruturais como `section` não são instruções do processador, são diretivas entendidas pelo Standard Macro Package do pré-processador do NASM. Ao usarmos `-a`, deixamos o NASM "cego" para diretivas.

Ele passa a interpretar a palavra `section` como um simples rótulo de memória (label), e quando lê a palavra seguinte (`.data` ou `.bss`), acusa erro por não reconhecê-la como uma instrução válida (como `mov` ou `add`). Isso prova a dependência crítica da linguagem para com a etapa de pré-processamento.

## 3. Compilação Determinística (`--reproducible`)

Normalmente, compiladores inserem metadados (como timestamps de data e hora) no cabeçalho do arquivo gerado, fazendo com que duas compilações do mesmo código tenham hashes criptográficos diferentes.

A opção `--reproducible` atua removendo qualquer dado variável ou carimbo de tempo da montagem.

### Comportamento

Se executarmos o comando 10 vezes no mesmo código, os 10 arquivos `.o` gerados terão rigorosamente a mesma integridade binária. Isso é fundamental para engenharia reversa, análise de malware e auditorias de software que exigem builds reproduzíveis e determinísticas.