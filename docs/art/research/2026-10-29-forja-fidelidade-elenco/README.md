# Auditoria de fidelidade de 29/10 — aplicada (FORJA-15)

O texto do dono está em [`AUDITORIA.md`](AUDITORIA.md) (o relatório «Objetos e expressões precisam preservar o
conceito»), com as evidências em [`evidencias/`](evidencias/) e os scripts de diagnóstico em
[`scripts-auditoria/`](scripts-auditoria/). O pedido: *«Implemente essas correções e faça merge na main»*. A decisão
está na [ADR 0101](../../../adr/0101-a-forja-fecha-a-entrega-pela-cadeia-e-pelo-conceito.md); o ticket é o
[FORJA-15](../../../backlog/FORJA-15.md).

O código auditado era exatamente o da `main` em `d0afd25` (os onze módulos de `codigo-conferido.json` batiam pelo
SHA-256). Os scripts `scripts-auditoria/` descrevem o comportamento de antes: com esta Forja, o
`reproduzir_casos.py` diz que o código mudou e deixa de afirmar o defeito.

## O que entrou

| Achado | Antes | Agora | Onde |
| --- | --- | --- | --- |
| Caso A — o frasco | `shared_prop_constraints` sem leitor; 99×3 passava; 13×20 igual = «mesmo frasco» | esquema e par validados; família `flask`; forma contra um molde nativo (`forja.prop_model/1`); `forja par` com a pega | `props.py`, `prop_shape.py`, `equipment.py`, `cmd_lote.py` |
| Caso B — a personalidade | caixa de rosto genérica; pinos tirados da adaptação contavam como preservação | ficha facial por personagem com marcos e relações; o estado 2 só conta sinais da autoridade; os pinos do candidato são proteção local | `face.py`, `review_state.py`, `fidelity.py`, contratos do elenco |
| Caso C — os dentes | a perda ficava no JSON de uma etapa | a perda vai para a cadeia, com votos, margem e confiança; crítica numa região obrigatória | `loss.py`, `lineage.py`, `limits.py` |
| Caso D — a etapa limpa | `erased_cells=0` na base nativa; `usable_sprite` verdadeiro | a cadeia leva as perdas até haver resolução; o `forge` diz `raster_valid` e `label: study`; o fecho único é o do `forja fidelity` | `lineage.py`, `pipeline.py`, `review_state.py` |
| Guia genérico | sobrancelha «ruído», boca assimétrica proibida, Horta vegetal | marcados como superados; o conceito prevalece | `EXPRESSION_GUIDE.md` |
| Lote | estados por ficheiro solto | `forja lote`: 15 entradas, estados separados, quem não mudou | `cmd_lote.py` |

## Os testes de regressão (§9 da auditoria)

Cada teste muda a imagem ou a evidência e confere que o resultado muda.

| Caso | Teste |
| --- | --- |
| T01 objeto, mesmo envelope | `test_fidelidade_elenco.ObjectShapeTest.test_t01_…` |
| T02 restrição partilhada | `SharedConstraintTest.test_t02_…` (o 99×3 da auditoria, dado inválido, par inexistente ou divergente) |
| T03 variação permitida | `test_t03_…` (âmbar no molde verde; espelho só declarado) |
| T04 pega e oclusão | `test_t04_…` (mão a flutuar falha; mão sobre o vidro: linhas tapadas fora da conta, muito tapado inconclusivo) |
| T05 olhar | `FaceSheetTest.test_t05_…` |
| T06 boca | `FaceSheetTest.test_t06_…` |
| T07 dentes | `test_fidelidade_cadeia.InheritedLossTest.test_t07_…` (a fonte real da mercenária) |
| T08 reexportação | `test_t08_reexporting_…` e `test_t08_a_proven_repair_…` |
| T09 recuperação exata | `ExactAndLocalTest.test_t09_…` |
| T10 pinos do candidato | `FaceSheetTest.test_t10_…` |
| T11 edição local | `ExactAndLocalTest.test_t11_…` |
| T12 fechamento | `ClosureTest.test_t12_…` |
| T13 elenco completo | `ClosureTest.test_t13_…` |

A [prova](prova_fidelidade_elenco.py) refaz os casos com as imagens do pacote e escreve [`prova.json`](prova.json)
(16 verificações), no `make forja`: a mercenária (pureza 0,970, quatro dentes críticos, reexportação bloqueada), os
dois frascos v3 (o mesmo envelope 13×20 e `pending`: não prova o molde), as mutações do frasco e do rosto, e por
personagem a ficha facial, a restrição partilhada e o hash do recorte do conceito, que é o gabarito.

## O que fica para o dono

- **Q-304** — o molde nativo do frasco e a medida partilhada: os 13×20 da v3 não são o padrão.
- **Q-305** — as caixas reservadas e as cores dos marcos faciais no layout nativo de cada personagem, e a confirmação
  das relações anotadas no par dos alquimistas (olhar e lado do sorriso).
- **Q-306** — os limiares provisórios (IoU 0,85, 1 px por linha, 60 % visível, grade duvidosa abaixo de 0,75).

Não houve nova geração, abertura no Aseprite, teste no motor nem revisão artística. Os 15 sprites v3 continuam
estudos: as fichas faciais estão `pending_annotation` e nenhum fecho passa sem elas.
