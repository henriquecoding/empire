# FORJA-15 — auditoria de fidelidade de 29/10: a entrega fecha pela cadeia e pelo conceito

Estado parcial — P0-01, P0-02, P0-03, P1-01, P1-02 e P2-01 aplicados na Forja com os testes T01–T13 e a prova do
          elenco; o molde do frasco, as caixas nativas dos marcos e a revisão dos 15 sprites ficam para o dono (Q-304–Q-306)

## Pedido

O dono, a 29/10/2026, com a [auditoria de fidelidade](../art/research/2026-10-29-forja-fidelidade-elenco/AUDITORIA.md)
dos 15 sprites v3 do elenco (base `d0afd25`): *«Implemente essas correções e faça merge na main»*.

## Spec e autoridade

[Auditoria e aplicação](../art/research/2026-10-29-forja-fidelidade-elenco/README.md),
[ADR 0101](../adr/0101-a-forja-fecha-a-entrega-pela-cadeia-e-pelo-conceito.md), [FORJA-13](FORJA-13.md) e
[ADR 0099](../adr/0099-a-forja-conserva-o-elenco-escolhido.md) (o elenco), [ADR 0093](../adr/0093-a-forja-protege-o-mestre-aprovado.md),
[ADR 0094](../adr/0094-a-forja-mede-o-que-perde-e-prende-a-autoridade.md), [Guia da Forja](../art/FORJA.md),
AGENTS.md (regras 1, 8 e 9).

## Entrega

| Melhoria | O que entrou | Evidência |
| --- | --- | --- |
| P0-01 fecho único e perdas | `lineage.py` (`forja.lineage/1`, `forja.loss_resolutions/1`); `forge --lineage --native-root`; `patch --lineage`; `delivery.raster_valid` / `release_ready` / `label` (sai `usable_sprite`); `fidelity --resolutions`; `provenance.lineage` | T07, T08, T12 em `test_fidelidade_cadeia` |
| P0-02 objeto partilhado e pega | `props.py` (esquema, par no elenco, `forja.prop_model/1`, veredito do par); `prop_shape.py` (forma contra o molde); família `flask`; `forja par` | T01–T04, o 99×3 e os frascos v3 em `test_fidelidade_elenco` |
| P0-03 conferência facial | `face.py` (`forja.face_sheet/1`: intenção, marcos, relações); sinais da autoridade separados dos pinos do candidato; a ficha no pedido fiel; fichas nos 15 contratos (o par dos alquimistas anotado no conceito) | T05, T06, T10 |
| P1-01 recuperação sensível | votos alternativos, margem e confiança por célula apagada (`loss.votes`); `redraw_region` e `inherited_loss` (`limits.inherited`) | T07, T09, traço mais fino que a célula |
| P1-02 componentes e lote | `forja lote` (uma entrada por personagem, estados separados, `--previous`); rótulo `study` / `release` / `blocked` | T11, T13 |
| P2-01 guia e benchmark | `EXPRESSION_GUIDE.md` com a precedência e três trechos superados; `prova_fidelidade_elenco.py` no `make forja` | `prova.json` (16 verificações) |

## Por fazer

1. Desenhar o molde nativo do frasco a partir do conceito e fechar `native_shared_dimensions` (Q-304); com ele, o
   `forja par` dos alquimistas sai de `pending`.
2. Reservar as caixas e as cores dos marcos faciais no layout nativo de cada personagem e confirmar as relações
   anotadas no par dos alquimistas (Q-305).
3. A ordem da auditoria: provar o método na dupla dos alquimistas (frasco, pega e rosto; conceito, fonte, recuperação
   e PNG a 1× e ampliado) e só depois rever os 15, com o `forja lote` a manter as 15 entradas.
4. Calibrar os limiares com exemplos aceites e rejeitados do dono (Q-306); o benchmark tem zero exemplos bons.

## Limite

Sem nova geração, sem chamada paga, sem revisão artística nem aprovação; os 15 sprites v3 continuam estudos. Sem
escrita em `art/`, `audio/`, `src/`, `scenes/` ou `data/`; sem dependências novas. A exportação Aseprite não leva o
rótulo de estudo (fica no JSON).

## Verificação

`make forja` (a suíte, as provas anteriores sem deriva e a prova do elenco);
`python3 -m unittest tools.forja.tests.test_fidelidade_elenco tools.forja.tests.test_fidelidade_cadeia`; CI do PR.
