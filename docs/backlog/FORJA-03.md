# FORJA-03 — a Forja julga armas e equipamento: o primeiro incremento do relatório de 24–25/10

Estado parcial — P0 aplicado e provado no arqueiro (vereditos separados, manifesto e observação, geometria, reparo
          com máscara e método, contorno que respeita linhas finas, pedido sem contradições); espada do rei, escudo
          do escudeiro, P1 e P2 por fazer

## Pedido

O dono, a 25/10/2026, com o relatório «Forja: armas, equipamentos e consistência visual» em Markdown e HTML
([arquivado](../art/research/2026-10-24-forja-armas/README.md)): *«Aplique os relatórios»*. O relatório pede
(§10 e §12) um primeiro incremento pequeno — P0-1 a P0-4 sobre um único caso, a corda e a empunhadura do arqueiro —,
a proteção de cordas e vazios contra o contorno global, a correção do `init_strength or 300` e a validação do pedido
contra a câmara; e só depois a espada do rei, o escudo do escudeiro, as animações e as operações PixelLab.

## Spec e autoridade

[Relatório](../art/research/2026-10-24-forja-armas/RELATORIO.md), [guia da Forja](../art/FORJA.md),
[ADR 0088](../adr/0088-a-forja-de-pixel-art.md), [ADR 0089](../adr/0089-a-forja-pede-uma-vez-e-mede.md),
[ADR 0091](../adr/0091-a-forja-julga-o-equipamento.md), CHARACTER_PRODUCTION_GUIDE, REFERENCE_AUTHORITY,
ASSET_BIBLE §2 (slots e espelho), ANIMATION_BIBLE (sockets e tags), `data/source/storages.csv` (`holds|worn` em
`_proposed`), AGENTS.md (regras 1, 8, 9 e 10).

## Entrega

| Ticket do relatório | O que entrou | Evidência |
| --- | --- | --- |
| P0-1 vereditos | `verdicts.py`: sete eixos, sem média; `not_evaluated` nunca passa; a revisão automática traz-os | `test_equipment.VerdictsTest`, `test_request` |
| P0-2 manifesto | `equipment.py`: intenção (`forja.equipment/1`), observação presa ao hash da imagem (`forja.observation/1`), famílias espada, arco, escudo e armazenamento; campos de jogo recusados | `test_equipment.ObservationTest` |
| P0-3 geometria | `geometry.py`, `forja equip`: partes, lâmina, corda, guarda, contactos; fixtures do relatório e controlos positivos | `test_equipment`, [fixtures.png](../art/research/2026-10-24-forja-armas/fixtures.png) |
| P0-4 reparo | `masks.py`, `compose.py`, `inpaint.py` (máscara, `--method add|replace|remove`, `--protect`), `repair.py` e `forja line` | `test_repair`, a corda do arqueiro |
| P0-5 linhas finas | `outline.add(keep=…)`, `--bare` no `forge`, isenção no lint | as duas sondas em `test_repair` e em `prova.json` |
| P0-6 pedido (parte) | zero explícito na força da imagem inicial; contradições de câmara e direção bloqueiam o plano e aparecem no `prompt` | `test_request.RequestTest` |

O arqueiro: recuperado da figura do relatório, a corda falha (2 px em 22 linhas, 1,55 px fora da reta) e, refeita na
grade, passa; fora da zona do reparo e nas regiões protegidas os pixels ficam idênticos. A aprovação artística
continua pendente.

## Por fazer

- Espada do rei e escudo do escudeiro (relatório §6.3, §6.5): as fontes da entrega não estão no repositório; o
  escudo precisa da ficha do verso e do tipo de pega (Q-274).
- P0-6, resto: o inventário do manifesto compilado no prompt; o prompt expandido guardado e conferido quando um
  adaptador o devolver.
- P1-1 adaptador de inpainting do PixelLab (comparar `inpaint-v3` e Pro Flash no mesmo caso, com chave e teto);
  P1-2 identidade e contactos por quadro; P1-3 rampas por material; P2 biblioteca de referências aceitas.
- `identity_consistency` e `temporal_consistency` continuam `not_evaluated` em tudo o que tem equipamento.

## Limite

Sem escrita em `art/`, `audio/`, `src/`, `scenes/` ou `data/`; sem dependências novas; sem geração nem chamada paga;
sem aprovação artística; nenhuma mecânica, capacidade ou estado de jogo inventado. A corda refeita é uma proposta
dentro da pasta de pesquisa.

## Verificação

`make forja` (a prova e a suite da Forja, com as fixtures e a prova do arqueiro);
`python3 docs/art/research/2026-10-24-forja-armas/prova_arqueiro.py`; portões estáticos locais; CI do PR.
