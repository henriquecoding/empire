# FORJA-06 — recuperar antes de proteger: autoridade das referências, edição presa ao mestre e encerramento

Estado feito — as seis etapas do §7 da solução de 27/10, com testes, a prova reproduzível e a pesquisa complementar;
          a recuperação dos rostos do Rei, do Arqueiro e do Escudeiro (desenho) por fazer

## Pedido

O dono, a 27/10/2026, com o pacote `Solucao-Forja-Fidelidade-2026-10-27`: *«Implemente isso, e também pesquise
profundamente na web mais coisas que possam complementar isso»*.

## Spec e autoridade

[A solução de 27/10](../art/research/2026-10-27-forja-fidelidade/SOLUCAO.md), [Guia da Forja](../art/FORJA.md),
[ADR 0088](../adr/0088-a-forja-de-pixel-art.md), [ADR 0091](../adr/0091-a-forja-julga-o-equipamento.md),
[ADR 0092](../adr/0092-a-forja-ve-a-cor-no-espaco.md), [ADR 0093](../adr/0093-a-forja-protege-o-mestre-aprovado.md),
AGENTS.md (regras 1, 8 e 9).

## Entrega

[Pesquisa, prova e fontes](../art/research/2026-10-27-forja-fidelidade/README.md):

| § | O que entrou | Evidência |
| --- | --- | --- |
| 7.1 | `refs.py` e `forja refs`: o registo `forja.refs/1` pelo hash dos pixels; o prompt nomeia o estado (só o mestre registado é APPROVED); a rejeitada não entra; `authority.stage` no plano; `--refs` e `--concept` no `plan`/`auto`; `--reference-state`, `--refs` e `--reference-file` no `prompt` | `test_fidelidade.AuthorityTest` |
| 7.2 | `expectation.py`: o `auto`, o `forge` e o `sheet` manuais com a mesma conta; tamanho errado invalida; nativo só com o tamanho certo | `ExpectationTest` |
| 7.3 | `cmd_local.py`: `forja inpaint --refs` recusa o rejeitado e o conceito antes do pedido; `stopped: size_mismatch` com o job; `forja verify`, só a ler | `LocalEditTest`, `ClosureTest` |
| 7.4 | `repair.straighten` com a cor declarada em toda a linha final; `repair.fill`; `forja line --core --core-box --color --mode`; sem cor, `inconclusive` | `test_corda_cores.StringCoreTest` |
| 7.5 | `materials.material_state`: `pending` com pixels presos fora da rampa ou fronteiras perdidas | `MaterialTest` |
| 7.6 | `verdicts.closure`: as quatro condições do §9; só o registo do dono, desta imagem, aprova | `ClosureTest` |
| — | `banding.py` (Pixel Fixer, TU Delft 2025) no `forja cores`, como suspeita | `BandingTest` |

## Limite

Sem escrita em `art/`, `audio/`, `src/`, `scenes/` ou `data/`; sem dependências novas; sem chamada paga; sem aprovação
artística. A recuperação dos rostos (§2) é desenho e não foi feita. Os JSON de detalhe das provas de 24/10 e 25/10
ganharam campos novos sem mudar valores.

## Verificação

`make forja` (a prova, a suíte com os testes novos, as provas de 24/10, 25/10 e 27/10 sem deriva);
`python3 docs/art/research/2026-10-27-forja-fidelidade/prova_fidelidade.py` (28 verificações); portões estáticos
locais; CI do PR.
