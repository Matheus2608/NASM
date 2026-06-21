# Flags de Avisos (Warnings) do NASM

Demonstração prática das quatro flags de controle de avisos do NASM usando código de 32 bits (`elf32`).

> Versão testada: **NASM 2.16.01** em Linux x86-64

---

## Estrutura dos arquivos

| Arquivo               | Flag demonstrada      | Mecanismo de aviso                                    |
|-----------------------|-----------------------|-------------------------------------------------------|
| `flag_wall.asm`       | `-w+all`              | `float-denorm` — constante denormal (OFF por padrão)  |
| `flag_wnoall.asm`     | `-w-all`              | `zeroing` (ON) + `float-denorm` (OFF)                 |
| `flag_werror.asm`     | `-w+error`            | `zeroing` — `resb` em seção inicializada (ON por padrão) |
| `flag_label_orphan.asm` | `-w-label-orphan`   | `label-orphan` — rótulo sem `:` (ON por padrão)       |

---

## 1. `-w+all` — Habilitar todos os avisos

**Arquivo:** `flag_wall.asm`

O NASM mantém algumas classes de aviso **desligadas por padrão** porque são raras em código normal. A flag `-w+all` ativa tudo, incluindo essas classes silenciosas.

O arquivo contém `tiny_val dd __float32__(1.0e-40)`: uma constante de ponto flutuante de 32 bits cujo valor (`1e-40`) é menor que o menor número normalizado (`~1.175e-38`), tornando-a **denormal**. O aviso `float-denorm` está OFF por padrão — só aparece com `-w+all`.

### Comandos

```bash
# Sem flag: compilação silenciosa (float-denorm está off por padrão)
nasm -f elf32 flag_wall.asm -o flag_wall.o

# Com -w+all: aviso float-denorm é exibido
nasm -f elf32 flag_wall.asm -w+all -o flag_wall.o
```

### Output esperado

```
# Sem flag:
(nenhuma saída — arquivo .o gerado normalmente)

# Com -w+all:
flag_wall.asm:32: warning: denormal floating-point constant [-w+float-denorm]
```

**Por que isso importa:** constantes denormais causam penalidade de performance em hardware (operações em software em vez de hardware) e geralmente indicam um erro de digitação na magnitude do valor.

---

## 2. `-w-all` — Silenciar todos os avisos

**Arquivo:** `flag_wnoall.asm`

O oposto de `-w+all`. Útil ao compilar código legado onde os avisos são conhecidos, inofensivos e apenas poluem a saída do terminal.

O arquivo tem dois gatilhos intencionais:
- `pad resb 1` dentro de `.data` → aviso `zeroing` (**ON** por padrão)
- `tiny_val dd __float32__(1.0e-40)` → aviso `float-denorm` (**OFF** por padrão)

### Comandos

```bash
# Sem flag: apenas zeroing aparece (float-denorm ainda está off)
nasm -f elf32 flag_wnoall.asm -o flag_wnoall.o

# Com -w+all: zeroing + float-denorm (tudo ativado)
nasm -f elf32 flag_wnoall.asm -w+all -o flag_wnoall.o

# Com -w-all: silêncio total — .o é gerado sem nenhuma mensagem
nasm -f elf32 flag_wnoall.asm -w-all -o flag_wnoall.o
```

### Output esperado

```
# Sem flag:
flag_wnoall.asm:31: warning: uninitialized space declared in non-BSS section `.data': zeroing [-w+zeroing]

# Com -w+all:
flag_wnoall.asm:31: warning: uninitialized space declared in non-BSS section `.data': zeroing [-w+zeroing]
flag_wnoall.asm:32: warning: denormal floating-point constant [-w+float-denorm]

# Com -w-all:
(nenhuma saída — arquivo .o gerado normalmente)
```

**Por que isso importa:** `-w-all` não impede a compilação — o `.o` é sempre gerado. Ela apenas remove o ruído visual. Use com cautela: você pode estar ignorando avisos que apontam para bugs reais.

---

## 3. `-w+error` — Tolerância zero (avisos viram erros fatais)

**Arquivo:** `flag_werror.asm`

Com esta flag, qualquer aviso interrompe o montador com código de saída 1 e o arquivo `.o` **não é criado**. Ideal para CI/CD ou para forçar código sempre limpo.

O arquivo contém `pad resb 1` dentro do segmento `.data`. O NASM avisa (`zeroing`) porque espaço não-inicializado deveria estar em `.bss`, não em `.data`. Normalmente esse aviso é inofensivo e o `.o` é gerado. Com `-w+error`, ele vira erro fatal.

### Comandos

```bash
# Sem flag: aviso exibido, mas .o É gerado (exit code 0)
nasm -f elf32 flag_werror.asm -o flag_werror.o

# Com -w+error: erro fatal, .o NÃO é gerado (exit code 1)
nasm -f elf32 flag_werror.asm -w+error -o flag_werror.o
```

### Output esperado

```
# Sem flag:
flag_werror.asm:35: warning: uninitialized space declared in non-BSS section `.data': zeroing [-w+zeroing]
# (exit code 0, flag_werror.o é gerado)

# Com -w+error:
flag_werror.asm:35: error: uninitialized space declared in non-BSS section `.data': zeroing [-w+error=zeroing]
# (exit code 1, flag_werror.o NÃO é gerado)
```

**Para corrigir o aviso:** mova `pad resb 1` para a seção `.bss` — lá é onde espaço não-inicializado deve ser declarado.

---

## 4. `-w-label-orphan` — Controle cirúrgico de um aviso específico

**Arquivo:** `flag_label_orphan.asm`

As flags de aviso podem ser combinadas. Você pode ativar tudo com `-w+all` e depois desligar seletivamente apenas um aviso específico com `-w-<nome>`.

Um "rótulo órfão" é um identificador numa linha que parece um rótulo mas não tem os dois-pontos (`:`) no final. O NASM avisa porque provavelmente é um erro de digitação. O arquivo contém `verificar_carry` (linha 88) sem `:`.

### Comandos

```bash
# Com -w+all: aviso label-orphan é exibido
nasm -f elf32 flag_label_orphan.asm -w+all -o flag_label_orphan.o

# Com -w+all -w-label-orphan: apenas esse aviso é suprimido, os outros continuam
nasm -f elf32 flag_label_orphan.asm -w+all -w-label-orphan -o flag_label_orphan.o
```

### Output esperado

```
# Com -w+all:
flag_label_orphan.asm:88: warning: label alone on a line without a colon might be in error [-w+label-orphan]

# Com -w+all -w-label-orphan:
(nenhuma saída — aviso suprimido, .o gerado normalmente)
```

**Por que isso importa:** a ordem importa — a última flag ganha. `-w+all -w-label-orphan` significa "ligue tudo, depois desligue apenas label-orphan". O inverso (`-w-label-orphan -w+all`) seria inútil porque `-w+all` religaria tudo.

---

## Resumo das classes de aviso usadas

| Classe          | Padrão | Descrição                                                    |
|-----------------|--------|--------------------------------------------------------------|
| `float-denorm`  | OFF    | Constante de ponto flutuante denormal                        |
| `zeroing`       | ON     | `RESx` em seção inicializada (vira zero no `.o`)             |
| `label-orphan`  | ON     | Identificador numa linha sem `:` no final                    |

Para ver todas as classes disponíveis no seu NASM:

```bash
nasm -h
```

---

## Compilação rápida de todos os exemplos

```bash
# Gera todos os .o sem nenhum aviso (modo produção silencioso)
for f in flag_wall flag_wnoall flag_werror flag_label_orphan; do
    nasm -f elf32 ${f}.asm -w-all -o ${f}.o && echo "OK: ${f}.o"
done
```
