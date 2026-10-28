# FORJA-07 — medir o que a amostragem perde e prender cada pedido à autoridade da pose

Estado feito — as cinco etapas de código do plano da auditoria de 27/10 (revisão 2), com testes e a prova reproduzível;
          o piloto artístico do Rei e a base nativa fiel dos três personagens (desenho) por fazer

## Pedido

O dono, a 27/10/2026, com o relatório *Forja: por que os sprites perderam o conceito* (revisão 2) e o pacote
`Forja-Auditoria-Fidelidade-Evidencias-2026-10-27`: *«Quero que implemente isso»*.

## Spec e autoridade

[A auditoria](../art/research/2026-10-27-forja-auditoria-fidelidade/AUDITORIA.md),
[o plano de implementação](../art/research/2026-10-27-forja-auditoria-fidelidade/PLANO-DE-IMPLEMENTACAO.md),
[Guia da Forja](../art/FORJA.md), [ADR 0088](../adr/0088-a-forja-de-pixel-art.md),
[ADR 0093](../adr/0093-a-forja-protege-o-mestre-aprovado.md), [ADR 0094](../adr/0094-a-forja-mede-o-que-perde-e-prende-a-autoridade.md),
AGENTS.md (regras 1, 8 e 9).

## Entrega

[Pesquisa, prova e contrato](../art/research/2026-10-27-forja-auditoria-fidelidade/README.md):

| Plano | O que entrou | Evidência |
| --- | --- | --- |
| §1 | `fidelity.py` (`forja.fidelity/1`) e `constraints.py`: recorte de autoridade anexado, `reference_conflict`, rejeitados recusados, guia em revisão sozinho recusado, modos `stylized`/`adapt_concept`/`edit_approved_master`/`recover_grid`, a origem de cada restrição e nenhuma preferência do compilador no modo fiel; `--fidelity --character --pose --mode --max-colors --tones` no `plan`, `auto` e `prompt` | `test_contrato_fidelidade.RequestTest` |
| §2 | `Grid.origin` e `gridcheck.report` (`snap.grid_report`): medida, estimada, declarada (conferida), reduzida (`--reduce`) ou não medida; orçamento contra a tela e zonas de escala fina; grade e cores afirmadas em separado | `test_perdas.GridOriginTest`, `RecoveryControlTest` |
| §3 | `loss.py`: `snap.loss` e o achado `erased`, célula a célula, com as células vazias incluídas; a pureza medida em todos os métodos | `SamplerLossTest`, `PipelineLossTest` |
| §4 | `signals.py` (`forja.signals/1`): pinos autorizados até ao PNG final, `layout_conflict` sem vencedor, pendentes, regiões perdidas; `forge --signals`, `verify --signals` | `test_sinais` |
| §5 | `review_state.py` e `forja fidelity`: os quatro estados, o rejeitado `blocked` na identidade com o runtime em `pass`, a prancha lado a lado | `test_contrato_fidelidade.ReviewTest` |

## Limite

Sem escrita em `art/`, `audio/`, `src/`, `scenes/` ou `data/`; sem dependências novas; sem chamada paga; sem geração;
sem aprovação artística. O §6 do plano (o piloto do Rei) é desenho e não foi feito. As regiões, os pinos e a caixa útil
ficam pendentes no contrato (Q-286, Q-288). O JSON da prova de 27/10 (FORJA-06) muda um valor (o plano do arqueiro só
com o guia em revisão passa a `ok: false`); a verificação dela continua a passar.

## Verificação

`make forja` (a prova, a suíte com os testes novos, as provas de 24/10, 25/10 e 27/10 sem deriva);
`python3 docs/art/research/2026-10-27-forja-auditoria-fidelidade/prova_auditoria.py`; portões estáticos locais; CI do
PR.
