section .data
    prompt db "Digite a senha: ", 0
    prompt_len equ $ - prompt
    correta db "abc123", 0xa    ; a senha certa, com quebra de linha
    correta_len equ $ - correta ; 7 bytes: abc123 + Enter
    msg_certo db "Senha correta!", 0xa
    msg_certo_len equ $ - msg_certo
    msg_errado db "Senha incorreta.", 0xa
    msg_errado_len equ $ - msg_errado

section .bss
    buffer resb 20              ; espaço reservado pra guardar o que o usuário digitar

section .text
    global _start

_start:
    ; mostra o prompt
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt
    mov rdx, prompt_len
    syscall

    ; lê o que o usuário digitar
    mov rax, 0          ; syscall "read"
    mov rdi, 0          ; ler da entrada padrão (teclado)
    mov rsi, buffer     ; guardar no buffer
    mov rdx, 20         ; no máximo 20 bytes
    syscall

    ; compara byte por byte (7 bytes: 6 caracteres + Enter)
    mov rcx, correta_len
    mov rsi, buffer
    mov rdi, correta
    repe cmpsb          ; compara enquanto forem iguais
    jne senha_errada

senha_certa:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_certo
    mov rdx, msg_certo_len
    syscall
    jmp fim

senha_errada:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_errado
    mov rdx, msg_errado_len
    syscall

fim:
    mov rax, 60
    mov rdi, 0
    syscall
