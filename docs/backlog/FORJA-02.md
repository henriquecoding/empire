# FORJA-02 — reparar a Forja pela auditoria de 23/10 e fechar uma fatia vertical

Estado feito — F01–F09 reparados com testes, fatia vertical royal_64/royal_80 sem rede, piloto pago definido e por executar (sem chaves; teto por aprovar pelo dono)

## Pedido

O dono, a 23/10/2026, com a [auditoria](../art/research/2026-10-23-pixellab/AUDITORIA-FORJA-CLAUDE.md), o
[relatório mestre](../art/research/2026-10-23-pixellab/RELATORIO-MESTRE.md) e o
[pedido de continuidade](../art/research/2026-10-23-pixellab/PROMPT-PARA-CLAUDE.md): continuar a Forja do PR #117
sem ferramenta paralela; reproduzir F01–F09, corrigir primeiro os pedidos (F01/F02/F03/F09), depois a preservação da
arte (F04/F05/F06/F08) e a avaliação (F07); qualificar alegações; fechar uma fatia vertical com `royal_64` e
`royal_80`; executar o piloto só com teto de custo e referências definidos, e registar a dependência se não houver
inferência.

## Spec e autoridade

[Guia da Forja](../art/FORJA.md), [ADR 0088](../adr/0088-a-forja-de-pixel-art.md),
[ADR 0089](../adr/0089-a-forja-pede-uma-vez-e-mede.md), guia de personagens, decisões de 19/10, REFERENCE_AUTHORITY,
Asset e Animation Bibles, AGENTS.md (regras 1, 8 e 9).

## Entrega

- Pedidos: um POST pago sai uma vez; jobs duráveis com prazo, cancelamento, retomada e teto; plano por gerador
  validado sem rede (PixelLab nativo 64/80 com `init_image` e `color_image`; Gemini em proporção e resolução suportadas
  com margens; gpt-image com imagens por papel); o prompt só promete o que vai anexado; o que chega é medido.
- Arte: edição sem colisão de cor e com eco exato; limpeza por política com caixas protegidas; pranchas que mantêm
  saltos, agachamentos e raízes; direções das tags no Godot.
- Avaliação: `contract_valid`, `motion_checks`, `needs_regeneration` e `artistic_approval` separados; repetições
  declaradas; alegações da documentação qualificadas.
- [Reparos, antes e depois, fatia vertical e piloto](../art/research/2026-10-23-forja-reparos/README.md).

## Limite

Sem escrita em `art/`, `audio/`, `src/`, `scenes/` ou `data/`; sem dependências novas; os quadros V15 só são lidos.
Nenhuma chamada paga (sem chaves); nenhum asset novo; nenhuma aprovação artística. O `.aseprite` não foi aberto no
aplicativo.

## Verificação

`make forja` (prova 11/11 e 136 testes, com o Godot 4.7.2 fixado a carregar o `SpriteFrames` dos quadros reais);
as sondas da auditoria antes e depois; `fatia_vertical.py`; portões estáticos locais; CI do PR.
