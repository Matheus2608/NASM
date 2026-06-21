# Flags de Otimização (-O) do NASM

Demonstração prática das flags de otimização de saltos do NASM usando código de 32 bits (`elf32`).

> Versão testada: **NASM 2.15.05** em Linux x86-64

---

## Estrutura dos arquivos

| Arquivo     | Descrição                                                              |
|-------------|-------------------------------------------------------------------------|
| `soma.asm`  | Idêntico ao `soma.asm` da raiz — programa base sem funções do Paul Carter |![alt text](image.png)

Diferente das flags de warning, **as flags `-O` não exigem nenhuma mudança no código-fonte**. O efeito delas é inteiramente sobre como o NASM decide o tamanho de codificação de instruções de salto (`jmp`/`jcc`) no `.o` final. Por isso há um único `.asm`; o que muda são os comandos de montagem.

Texto oficial do `nasm -h`:

```bash
nasm -h | grep -A4 "Oflags"
```

```
-Oflags...    optimize opcodes, immediates and branch offsets
   -O0        no optimization
   -O1        minimal optimization
   -Ox        multipass optimization (default)
   -Ov        display the number of passes executed at the end
```

---

## Comandos usados

```bash
nasm -f elf32 soma.asm -O0 -o soma_O0.o
nasm -f elf32 soma.asm -O1 -o soma_O1.o
nasm -f elf32 soma.asm -Ox -o soma_Ox.o
nasm -f elf32 soma.asm -Ov -o soma_v.o      # combinar com qualquer -O acima
```

## Tamanho da seção `.text` gerada

```bash
objdump -h soma_O0.o | grep .text
objdump -h soma_O1.o | grep .text
objdump -h soma_Ox.o | grep .text
```

| Flag             | `.text` (bytes) | Tamanho do `.o` |
|------------------|-----------------|------------------|
| `-O0`            | 387             | 1760 bytes       |
| `-O1`            | **399**         | 1760 bytes       |
| `-Ox` (default)  | **384**         | 1744 bytes       |

> Confirmado: montar **sem nenhuma flag `-O`** produz um `.o` byte-a-byte idêntico ao de `-Ox` — ou seja, `-Ox` é mesmo o default do NASM, como documentado.

### O resultado contraintuitivo

Seria de esperar que mais "otimização" (`-O1`) gerasse código igual ou menor que nenhuma otimização (`-O0`). **Não é o que acontece neste programa**: `-O1` gera 12 bytes *mais* que `-O0`. Comparando o disassembly (`objdump -d -M intel`) lado a lado:

```bash
objdump -d -M intel soma_O0.o | grep -E "jbe|je|jne|jmp"
objdump -d -M intel soma_O1.o | grep -E "jbe|je|jne|jmp"
```

```
                          -O0                          -O1
jbe menor_que_10    76 1b        (2 bytes, rel8)   0f 86 1b 00 00 00  (6 bytes, rel32)
je  so_unidade      74 16        (2 bytes, rel8)   0f 84 16 00 00 00  (6 bytes, rel32)
jne flush_stdin     75 e1        (2 bytes, rel8)   0f 85 dd ff ff ff  (6 bytes, rel32)
jmp imprimir        e9 0e000000  (5 bytes, rel32)  e9 0e000000        (5 bytes, rel32)
```

- Com **`-O0`**, o NASM resolve esses três `jcc` condicionais já na forma curta (`rel8`, 2 bytes), porque o alvo está próximo o bastante e é conhecido ao final da montagem em passe único.
- Com **`-O1`** ("otimização mínima"), o NASM força a forma longa (`rel32`, 6 bytes) para os mesmos `jcc`, sem tentar reduzir — é o comportamento mais conservador/seguro, não o mais compacto.
- Só com **`-Ox`** (multipass) o NASM faz passes extras de *relaxation*: ele tenta repetidamente a forma curta para **todo** salto cujo destino permita, incluindo o `jmp imprimir` (que vira `eb 0e`, 2 bytes, em vez de `e9 0e000000`, 5 bytes) — por isso é o único caso onde o `jmp` incondicional também encolhe.

**Conclusão para a apresentação:** o nome "otimização mínima" (`-O1`) não significa "um pouco menor que o normal" — significa que o NASM faz o mínimo de esforço/passes para garantir que o código monte corretamente, e isso pode resultar em código maior que simplesmente não otimizar nada (`-O0`). Só `-Ox` (o default) de fato minimiza o tamanho.

---

## `-Ov` — número de passes

```bash
nasm -f elf32 soma.asm -O0 -Ov -o /dev/null
nasm -f elf32 soma.asm -O1 -Ov -o /dev/null
nasm -f elf32 soma.asm -Ox -Ov -o /dev/null
```

Saída (idêntica nos três casos, para este programa):

```
soma.asm: info: assembly required 1+1+2 passes
```

`-Ov` não muda o código gerado — só imprime, ao final, quantos passes o montador precisou executar. Aqui o número de passes não variou entre `-O0`/`-O1`/`-Ox` (o programa é pequeno e não tem referências circulares complicadas), mas o **resultado de cada passe** (tamanho final escolhido para cada salto) é diferente, como mostrado acima.

---

## Como reproduzir

```bash
for o in O0 O1 Ox; do
    nasm -f elf32 soma.asm -$o -o soma_$o.o
    echo "-$o: .text = $(objdump -h soma_$o.o | awk '/\.text/{print $3}') (hex)"
done
objdump -d -M intel soma_O0.o > dis_O0.txt
objdump -d -M intel soma_O1.o > dis_O1.txt
objdump -d -M intel soma_Ox.o > dis_Ox.txt
diff dis_O0.txt dis_Ox.txt   # mostra o jmp encolhendo de e9 (5B) para eb (2B)
diff dis_O0.txt dis_O1.txt   # mostra os jcc crescendo de rel8 para rel32
```
