# FORJA-17 — auditar sprites, continuidade e exportação de animações

Estado feito — correções e auditoria implementadas; testes/provas locais aprovados, CI exigida antes do merge.

Henrique, 30/10/2026, pediu auditoria e refinamento da criação de sprites e animações.
Autoridade: AGENTS.md, OWNER_RULES.md, guias de produção/pixel art/Aseprite, Animation Bible,
ADRs 0094–0102. Não altera arte aprovada, escala, paleta, cadência ou mecânicas.

Reproduzir falhas antes de corrigir: duração/ranges inválidos, tags truncadas, prévias com repetição/direção
incorretas, rasters que só diferem no RGB invisível, correção temporal entre ações, cabeça colada sobre
silhueta diferente e pranchas que ignoram origem/redução/consulta. Validar CLI, metadados e pixels.

Entregar correções, auditoria com fontes primárias e testes/provas repetíveis. Aprovação artística continua
pendente; um export válido não confirma mãos, expressão, biomecânica ou integração no jogo.
