# FORJA-05 — auditoria da Forja de 26/10: o que rebentava, o que se calava e o que chegava errado ao gerador

Estado feito — dez falhas (A01–A10) reproduzidas sem rede e reparadas com testes; observações abertas O1–O7
          na pesquisa; piloto pago por executar (sem chaves)

## Pedido

O dono, a 26/10/2026: *«Quero que faça uma auditoria na forja e veja o que pode melhorar e refinar»*.

## Spec e autoridade

[Guia da Forja](../art/FORJA.md), [ADR 0088](../adr/0088-a-forja-de-pixel-art.md),
[ADR 0089](../adr/0089-a-forja-pede-uma-vez-e-mede.md), [ADR 0091](../adr/0091-a-forja-julga-o-equipamento.md),
[ADR 0092](../adr/0092-a-forja-ve-a-cor-no-espaco.md), a [auditoria de 23/10](../art/research/2026-10-23-pixellab/AUDITORIA-FORJA-CLAUDE.md),
AGENTS.md (regras 1, 8 e 9).

## Entrega

[Auditoria, antes e depois](../art/research/2026-10-26-forja-auditoria/README.md), com as sondas reproduzíveis:

| Achado | O que entrou | Evidência |
| --- | --- | --- |
| A01 ampliação exata fora de fase (regressão do #124) | `gridcheck.exact_grid`: período e fase pelas fronteiras (máximo divisor comum); células parciais nas pontas | `test_gridcheck.ExactScaleTest` |
| A02 imagem sem figura | `sheet` com `found: 0` e o pedido ao gerador; o `empty` do lint com o mesmo pedido | `test_auditoria.EmptyAndStopTest` |
| A03 `auto` que para depois de forjar | o resultado diz a última tentativa forjada e `stopped`; o teto antes do job; um erro da Forja guarda a imagem paga e para | `EmptyAndStopTest` |
| A04 custo retomado | `forja jobs --resume` soma no `budget.json`; falha definitiva conta como custo desconhecido | `test_auditoria.BudgetResumeTest` |
| A05 e A10 o prompt corretivo | `hint` inglês com a medida para a grade e o tamanho; "at most 62" no elenco V15 | `test_auditoria.CorrectiveTest` |
| A06, A07 e A09 a superfície | listas no MCP para os repetíveis; máscara sem alfa pelo claro; JSON e código 2 para um ficheiro que não é imagem | `test_auditoria.SurfaceTest` |
| A08 a fronteira da célula | `cells.py`: cada mancha vai para a célula onde está a maior parte dela; o que fica dividido corta-se pela linha; `cell_crossing` e aviso no lint | `test_auditoria.CellCrossingTest` |

Refinamentos: a amostragem de uma célula por pixel sem voto, o recorte vazio a 1×1, a pertença à paleta sem
refazer o conjunto, `placement.common_canvas`.

## Limite

Sem escrita em `art/`, `audio/`, `src/`, `scenes/` ou `data/`; sem dependências novas; sem chamada paga; sem
aprovação artística. Os registos das pesquisas anteriores não foram reescritos (O2).

## Verificação

`make forja` (a prova 11/11 e a suíte, 265 testes); `python3 docs/art/research/2026-10-26-forja-auditoria/sondas.py`
(antes e depois no mesmo cenário); as sondas F01–F09 de 23/10 e as provas do arqueiro de 24/10 e 25/10; portões
estáticos locais; CI do PR.
