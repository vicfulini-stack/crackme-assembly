# crackme-assembly

Um crackme escrito à mão em Assembly x86-64 (NASM, Linux) e depois analisado com GDB, como exercício de estudo de engenharia reversa.

O programa pede uma senha e valida byte a byte. Para testar se eu tinha entendido o que escrevi, fiz o caminho inverso: fingi não conhecer a senha e usei apenas o GDB para rastrear o fluxo, achar a comparação e ler o valor correto direto da memória.

> **Aviso:** projeto de estudo, feito para rodar em ambiente próprio. O "alvo" é um programa que eu mesmo escrevi.

## O que eu pratiquei

- Registradores, memória e seções (`.data`, `.bss`, `.text`)
- Syscalls Linux em x86-64: `read` (0), `write` (1) e `exit` (60)
- Comparação de memória com `repe cmpsb` e desvio condicional com `jne`
- Depuração com GDB (breakpoints, execução passo a passo, inspeção de registradores e memória)
- Raciocínio de quem analisa um binário desconhecido

## Como funciona o programa

1. Exibe `Digite a senha:` com a syscall `write`.
2. Lê até 20 bytes da entrada padrão com a syscall `read`, guardando em um buffer reservado em `.bss`.
3. Compara os 7 bytes da entrada (6 caracteres + Enter) com a senha guardada em `.data`, usando `repe cmpsb`.
4. Se forem iguais, imprime `Senha correta!`. Caso contrário, `Senha incorreta.`
5. Encerra com a syscall `exit`.

Trecho central da validação:

```nasm
mov rcx, correta_len
mov rsi, buffer
mov rdi, correta
repe cmpsb          ; compara enquanto forem iguais
jne senha_errada
```

O código completo está em [`crackme.asm`](crackme.asm).

![Código-fonte do crackme](docs/codigo.png)

## Como compilar e rodar

Requisitos: NASM, `ld` (binutils) e GDB. Testado no WSL (Ubuntu).

```bash
sudo apt install nasm binutils gdb

nasm -f elf64 -g -F dwarf crackme.asm -o crackme.o
ld crackme.o -o crackme

./crackme
```

As flags `-g -F dwarf` incluem símbolos de depuração, que deixam o GDB mostrar as linhas do código-fonte.

## Como analisei no GDB

Usei o GDB com a extensão [GEF](https://github.com/hugsy/gef), que mostra registradores e instruções em um painel só (é opcional; os comandos abaixo funcionam no GDB puro).

```bash
gdb ./crackme
```

```gdb
(gdb) disassemble _start        # localizar o repe cmpsb
(gdb) break *<endereço do repe cmpsb>
(gdb) run                       # digitar qualquer senha errada
(gdb) info registers rsi rdi rcx
(gdb) x/s $rsi                  # o que eu digitei
(gdb) x/s $rdi                  # o valor com que o programa compara
```

O raciocínio:

- `rsi` aponta para o buffer com a entrada digitada.
- `rdi` aponta para a senha correta guardada em `.data`.
- `rcx` carrega o número de bytes a comparar (7).

Parando o programa exatamente antes do `repe cmpsb`, o conteúdo de `rdi` já revela o que o programa espera receber. Na captura abaixo, o GDB está parado nessa instrução: `rsi` mostra a entrada que digitei e `rdi` aponta para o início da seção de dados, onde está a senha correta.

![GDB parado no repe cmpsb](docs/gdb-cmpsb.png)

<details>
<summary>Spoiler: a senha</summary>

A senha é `abc123`.

</details>

## O que aprendi

- A senha fica em texto puro na seção `.data`, então qualquer pessoa que consiga ler a memória do programa (ou o próprio binário) chega nela. Guardar segredos assim em um programa distribuído é um erro clássico.
- Entender onde a comparação acontece é o ponto central de quem analisa um binário, porque é nela que o fluxo se divide entre "acesso liberado" e "acesso negado".

## Limitações conhecidas

- A comparação usa tamanho fixo (7 bytes): só os primeiros 7 bytes da entrada são verificados, o que importa quando a entrada vem por pipe e não pelo teclado.
- A senha está no código-fonte e no binário, sem nenhuma ofuscação.

## Próximos passos

- [ ] Verificar se a senha aparece com o comando `strings crackme`
- [ ] Alterar o `jne` do binário (patch) para pular a validação e entender o impacto
- [ ] Reescrever a validação sem deixar a senha em texto puro (por exemplo, comparando um hash ou valor transformado)
- [ ] Comparar o resultado com uma análise estática em outra ferramenta (Ghidra ou radare2)

## Licença

Uso livre para fins educacionais.

