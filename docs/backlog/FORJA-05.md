# FORJA-05 — auditoria da Forja de 26/10: o que rebentava, o que se calava e o que chegava errado ao gerador

Estado feito — A01–A12 e as observações O1–O6 reparadas com testes; o piloto pago (O7) por executar, com os
          dez planos revalidados sem rede (sem chaves nem teto aprovado)

## Pedido

O dono, a 26/10/2026: *«Quero que faça uma auditoria na forja e veja o que pode melhorar e refinar»*; e, a
27/10, depois do PR: *«Quero que corrija e aplique o que descobriu»* — as observações O1–O7 que o relatório
deixava abertas.

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

Aplicado a 27/10 ([relatório](../art/research/2026-10-26-forja-auditoria/README.md#aplicado-a-2710)):

| Item | O que entrou | Evidência |
| --- | --- | --- |
| O1 a forense de 26/10 | a `forense.py` com a medida da Forja; as 60 imagens públicas medidas outra vez: o tileset é 4× no que se vê (o "2×" era cor escondida debaixo do alfa 0), 7 de 16 em vez de 8, e 9 capturas 2× recortadas em pixel ímpar; errata no dossiê | `verificar.py` da pesquisa |
| O2 os artefactos do arqueiro | refrescados; o `make forja` corre as provas de 24/10 e 25/10 e chumba um JSON que mude sem commit | `make forja` |
| O3 `--same-height` | cada figura na sua própria grade, sem LANCZOS: um agachar já não cresce | `test_auditoria_aplicada.OpenItemsTest` |
| O4 sem grade | recusa logo com `no_grid` (`limits.py`): 225 s → 8,5 s a 1920×1920, com a frase certa | `OpenItemsTest` |
| O5 frases por causa | o lado cortado é `margin`, não contorno; o `clipped` cala a altura e a margem | `OpenItemsTest`, `CorrectiveTest` |
| O6 uma amostragem | `gridcheck.measure` e o `snap` reaproveitam-na | `OpenItemsTest` |
| A11 a máscara e a grade | a grade de cada recorte mede-se antes da máscara | `OpenItemsTest` |
| A12 o `downscale` | voto `mode`: a cor exata mais frequente, nunca a média | `OpenItemsTest` |

Refinamentos: a amostragem de uma célula por pixel sem voto, o recorte vazio a 1×1, a pertença à paleta sem
refazer o conjunto, `placement.common_canvas`.

## Limite

Sem escrita em `art/`, `audio/`, `src/`, `scenes/` ou `data/`; sem dependências novas; sem chamada paga; sem
aprovação artística. Dos registos das pesquisas anteriores, só se refrescaram os JSON do arqueiro de 24/10 (O2) e a
forense de 26/10 (O1, com errata); o resto fica como foi visto.

## Verificação

`make forja` (a prova 11/11, a suíte com 270 testes e as provas do arqueiro sem deriva); `python3 docs/art/research/2026-10-26-forja-auditoria/sondas.py`
(antes e depois no mesmo cenário); as sondas F01–F09 de 23/10 e as provas do arqueiro de 24/10 e 25/10; portões
estáticos locais; CI do PR.
