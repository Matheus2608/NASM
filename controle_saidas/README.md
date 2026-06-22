# Flags de Controle de Saídas e Arquivos do NASM

Demonstração prática das quatro opções do NASM para personalização de nomes de arquivos gerados, retenção de arquivos e redirecionamento de logs de erro, usando código de 32 bits (`elf32`).

> Versão testada: **NASM 2.16.01** em Linux x86-64 / Windows (PowerShell)

---

## Estrutura dos arquivos

| Arquivo | Flag demonstrada | Mecanismo de atuação |
|----------|----------|----------|
| `flag_o.asm` | `-o <arquivo>` | Define um nome customizado para o arquivo de saída. |
| `flag_Z.asm` | `-Z <arquivo>` | Salva os erros de compilação direto em um arquivo TXT. |
| `flag_s.asm` | `-s` | Redireciona erros (`stderr`) para a saída padrão (`stdout`). |
| `flag_keep_all.asm` | `--keep-all` | Retém arquivos intermediários ou de saída na montagem. |

---

# 1. `-o` — Definir o nome do arquivo de saída

**Arquivo:** `flag_o.asm`

Por padrão, o NASM pega o nome original do arquivo fonte e apenas altera a extensão (ex.: compilar `arquivo.asm` gera `arquivo.o`). A flag `-o` quebra essa regra e permite que você defina o nome exato do arquivo gerado.

O arquivo contém um programa de soma limpo e funcional. A compilação não gerará erros.

## Comandos

```bash
# Sem flag: o NASM gera o arquivo com o nome padrão (flag_o.o)
nasm -f elf32 flag_o.asm

# Com -o: o NASM gera o arquivo com o nome escolhido
nasm -f elf32 flag_o.asm -o meu_programa.o
```

## Output esperado

```bash
# Após rodar o comando sem a flag:
ls
-> flag_o.o

# Após rodar o comando com a flag:
ls
-> meu_programa.o
```

### Por que isso importa?

Essencial quando se trabalha com Makefiles ou scripts de automação, onde os arquivos objeto precisam seguir uma nomenclatura rigorosa para serem linkados corretamente com outros módulos ou bibliotecas em C/C++.

---

# 2. `-Z` — Redirecionamento de erros pelo NASM

**Arquivo:** `flag_Z.asm`

Quando um código possui erros de sintaxe, o NASM imprime os avisos diretamente no terminal, sujando a tela. A flag `-Z` instrui o montador a agir silenciosamente, salvando todos esses alertas dentro de um arquivo de texto.

O arquivo contém comandos inválidos (`move` e `movv` ao invés de `mov`) inseridos propositalmente no início de `_start` para forçar o NASM a gerar falhas fatais de parser.

## Comandos

```bash
# Sem flag: o erro estoura diretamente na tela do terminal
nasm -f elf32 flag_Z.asm

# Com -Z: a tela fica limpa e o erro vai direto para o TXT
nasm -f elf32 flag_Z.asm -Z log_erros.txt
```

## Output esperado

```bash
# Sem flag:
flag_Z.asm:45: error: parser: instruction expected
flag_Z.asm:46: error: parser: instruction expected

# Com -Z:
(nenhuma saída no terminal — a compilação é silenciosa)

# Lendo o arquivo gerado:
cat log_erros.txt

flag_Z.asm:45: error: parser: instruction expected
flag_Z.asm:46: error: parser: instruction expected
```

### Por que isso importa?

Muito útil ao compilar projetos gigantes onde os logs de erro passariam do limite de rolagem da tela do terminal, permitindo que o desenvolvedor leia os problemas com calma posteriormente.

---

# 3. `-s` — Redirecionamento de erros para stdout

**Arquivo:** `flag_s.asm`

Diferente da `-Z` (que cria o arquivo de log por conta própria), a flag `-s` faz com que os erros saiam pelo canal normal do terminal (`stdout`) em vez do canal de erros (`stderr`). Isso permite que você manipule a saída usando ferramentas do sistema operacional.

O arquivo também contém comandos inválidos idênticos aos de `flag_Z.asm`. Usaremos o operador `>` do terminal (que só lê o canal `stdout`) para provar o redirecionamento.

## Comandos

```bash
# Sem flag: o terminal NÃO consegue capturar o erro com o '>'
nasm -f elf32 flag_s.asm > erro_capturado.txt

# Com -s: o terminal enxerga o erro como texto normal e o captura com o '>'
nasm -f elf32 flag_s.asm -s > erro_capturado.txt
```

## Output esperado

```bash
# Sem flag:
flag_s.asm:45: error: parser: instruction expected
flag_s.asm:46: error: parser: instruction expected

# O erro "vaza" para a tela e o arquivo fica vazio.

# Com -s:
(nenhuma saída no terminal)

# O conteúdo será gravado em erro_capturado.txt
```

### Por que isso importa?

Indispensável para pipelines modernos e scripts de CI/CD onde você deseja filtrar os erros usando pipes (`|`) para processar as mensagens.

---

# 4. `--keep-all` — Retenção de arquivos intermediários

**Arquivo:** `flag_keep_all.asm`

Ocasionalmente, o processo de montagem pode gerar arquivos temporários (ou o próprio NASM pode apagar o arquivo `.o` de saída se abortar a compilação no meio devido a um erro grave). Esta flag inibe exclusões e força a retenção de tudo que for gerado na pasta.

O arquivo contém o código de soma perfeito e sem erros, apenas para provar que a flag não interfere no fluxo de uma compilação bem-sucedida.

## Comandos

```bash
# Compilação padrão forçando a manutenção de todos os arquivos gerados
nasm -f elf32 flag_keep_all.asm --keep-all
```

## Output esperado

```bash
# Compilação silenciosa (exit code 0):
(nenhuma saída)

# Listando a pasta:
ls

-> flag_keep_all.o
```

### Por que isso importa?

É uma ferramenta avançada de depuração (debugging). Se um projeto envolver expansões de macros super complexas (usando a flag `-E`, por exemplo), o `--keep-all` garante que você possa inspecionar os arquivos subprodutos sem que o NASM os exclua automaticamente.

---

# Resumo das flags de saída

| Flag | Função Principal |
|--------|--------|
| `-o` | Muda o nome do arquivo compilado. |
| `-Z` | Salva avisos/erros em um arquivo `.txt` pelo próprio NASM. |
| `-s` | Redireciona erros para `stdout`, permitindo captura por scripts. |
| `--keep-all` | Inibe a exclusão automática de arquivos temporários ou intermediários. |

---

## Conclusão

As flags de controle de saída do NASM oferecem mecanismos importantes para automação, depuração e integração com ferramentas externas. Enquanto `-o` personaliza nomes de arquivos, `-Z` e `-s` facilitam o tratamento de erros, e `--keep-all` auxilia na inspeção detalhada do processo de montagem em cenários avançados de desenvolvimento.