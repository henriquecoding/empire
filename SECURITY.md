# Segurança

## Como reportar

Usa **Security → Report a vulnerability** neste repositório (GitHub Private
Vulnerability Reporting). Não abras uma issue pública para uma falha
explorável: uma issue pública é uma instrução de exploração com endereço.

Respondo em **5 dias úteis**. Se a falha for real, o remendo entra com um teste
que a reproduz — uma correção sem teste é uma falha adiada.

## O que conta como falha aqui

O Empire é um jogo de um jogador, sem servidor e sem conta. A superfície é
pequena e está quase toda em três sítios:

### 1 · Os saves — o único vetor sério, e está resolvido

Um `.tres` arbitrário pode conter um script embutido. Carregar um ficheiro de
save com `load()` ou `ResourceLoader.load()` é **execução remota de código
disfarçada de save**, e é a falha clássica de jogos em Godot: basta um save
"partilhado" num fórum.

A regra do projeto, em [ADR 0007](docs/adr/0007-save-security.md) e no §62:

- grava com `FileAccess.store_var(dados, false)` — o `false` desliga a
  serialização de objetos;
- lê com `FileAccess.get_var(false)`;
- **nunca** `load()` nem `ResourceLoader.load()` num caminho de save;
- valida os tipos base campo a campo, e ignora campos desconhecidos em vez de
  rebentar.

Um PR que quebre isto é tratado como falha de segurança, não como defeito de
estilo. Há teste a guardá-la (`test_d14_o_save_dos_sistemas_novos_so_contem_tipos_base`).

### 2 · Credenciais de assinatura

`export_presets.cfg` **é** versionado; palavras-passe de keystore e credenciais
de assinatura **não**. Vivem em variáveis de ambiente e em segredos do GitHub.
O `.gitignore` recusa `*.keystore`, `*.p12`, `*.pem` e `.env`.

Se alguma vez commitares uma, não basta apagá-la no commit seguinte: revoga-a
primeiro, e só depois limpa a história.

### 3 · A cadeia de construção

O CI não tem permissão de escrita (`permissions: contents: read` no topo do
workflow) e não corre código de PRs de forks com segredos. As dependências
externas são três e estão fixadas: o motor em `.godot-version`, o gdtoolkit em
`tools/requirements.txt`, e as actions pelo dependabot.

## O que não conta

- Um número de balanceamento que te deixa ganhar depressa. É design — vai para
  uma issue de defeito, ou para um playtest.
- Trapaça em jogo de um jogador. Não há nada a proteger de ti próprio.
- A semente do §42 ser visível e copiável. É de propósito: é instrumento de
  depuração e o melhor hábito de comunidade que o projeto tem de graça.

## Versões suportadas

O projeto está em pré-produção e não tem versão lançada. Enquanto assim for,
só o ramo principal recebe correções.
