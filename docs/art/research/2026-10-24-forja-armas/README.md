# Forja — armas, equipamento e consistência visual (24–25/10/2026)

O dono enviou o relatório «Forja: armas, equipamentos e consistência visual» (pesquisa de 24–25/10, revista a 25/10)
e pediu, a 25/10: *«Aplique os relatórios»*. O relatório chegou em Markdown e em HTML: o texto é o mesmo; o HTML trazia
duas figuras, guardadas aqui como PNG. Tarefa: [FORJA-03](../../../backlog/FORJA-03.md). Decisão:
[ADR 0091](../../../adr/0091-a-forja-julga-o-equipamento.md). Guia atualizado: [FORJA.md](../../FORJA.md).

| Ficheiro | O que é |
| --- | --- |
| [RELATORIO.md](RELATORIO.md) | O relatório, como chegou (Markdown) |
| [entrega-examinada.png](entrega-examinada.png) | Figura 1 do HTML: o rei, o arqueiro e o escudeiro da entrega examinada, a 6× |
| [prova-controlada.png](prova-controlada.png) | Figura 2 do HTML: as quatro fixtures da espada que passam no lint |
| [prova_arqueiro.py](prova_arqueiro.py) | A prova reproduzível deste incremento; grava [prova.json](prova.json) e falha se um resultado mudar |
| [fixtures.png](fixtures.png) | As fixtures da espada e do arco, com o lint raster e o veredito de geometria |
| [arqueiro/](arqueiro/) | O arqueiro recuperado, o manifesto, a observação marcada, os vereditos antes e depois e o reparo da corda |

**Em resumo:** aplicou-se o primeiro incremento que o relatório recomenda (§10), sobre um único caso, o arqueiro em
pose estática: vereditos separados (P0-1), manifesto de equipamento com observação e veredito em registos distintos
(P0-2), verificações de geometria com fixtures negativas e controlos positivos (P0-3), reparo com máscara qualquer,
regiões protegidas e método de composição declarado (P0-4), linhas finas e vazios protegidos do contorno global
(P0-5), e duas correções do pedido (P0-6: o zero explícito da força da imagem inicial e as contradições de câmara).
A corda do arqueiro sai da entrega com 2 px de largura em 22 linhas e a 1,55 px da reta entre as pontas; refeita na
grade, fica com 1 px, reta e ligada às duas pontas, com os pixels fora da máscara e das regiões protegidas idênticos.
**Nada disto aprova arte**: a corda refeita é uma proposta, a aprovação artística fica pendente e nada foi escrito
em `art/`. Nenhuma geração, nenhuma chamada paga, nenhuma dependência nova.

## Fatos, inferências e escolhas

| Tipo | Neste trabalho |
| --- | --- |
| Medição | As quatro fixtures da espada e as cinco do arco passam no lint `royal_80` com 0 erros (o relatório reproduzido). O arqueiro recuperado tem 37 cores opacas e 74 px de altura útil, como a tabela §3.1 do relatório. A corda da entrega: 2 px em 22 linhas, desvio máximo de 1,55 px |
| Observação marcada | As regiões do arqueiro (corda, madeira, empunhadura, mão, antebraço) e as duas âncoras das pontas foram marcadas por caixa e cores pelo agente desta sessão, conferidas a 14×; a empunhadura tem incerteza média (os castanhos entre os dedos foram lidos como a empunhadura). Não é um detector: é uma marcação, e a observação diz quem a fez e como |
| Inferência registada | No reparo, 1 pixel da corda antiga estava por cima da braçadeira; ao sair, herdou a cor dos vizinhos (`inferred` no relatório do reparo), porque o que estava por baixo não se vê |
| Escolha nossa | A corda nova segue a reta entre as âncoras, um pixel por linha, na cor dominante da corda antiga; onde a reta cruzaria a braçadeira, reaproveita o pixel da própria corda. A família `bow_simple` liga os dois braços do arco pela empunhadura |
| Lacuna | Os PNG originais da entrega (rei, arqueiro, escudeiro), as fontes e os prompts não estão no repositório; o pacote com o script e os JSON do relatório também não veio. O arqueiro foi recuperado da figura 1 (cada célula 6×6 de uma só cor dentro do sprite). O rei e o escudeiro ficam para os incrementos seguintes |

## O arqueiro

| | Antes (entrega) | Depois (corda refeita) |
| --- | --- | --- |
| `raster_contract` | pass | pass |
| `equipment_geometry` | **fail** — corda com 2 px em 22 linhas e a 1,55 px da reta | pass |
| `functional_pose` | pass — mão encostada à empunhadura | pass |
| `identity_consistency` | not_evaluated | not_evaluated |
| `temporal_consistency` | not_applicable (uma pose) | not_applicable |
| `artistic_approval` | pending | pending |
| `runtime_integration` | not_tested | not_tested |

- Antes: [vereditos](arqueiro/antes/arqueiro-recuperado_equip.json) e [regiões e âncoras](arqueiro/antes/arqueiro-recuperado_equip.png).
- Reparo: [antes e depois a 1× e a 8×](arqueiro/depois/arqueiro-recuperado_line_compare.png),
  [zona do reparo e âncoras](arqueiro/depois/arqueiro-recuperado_line_mask.png),
  [relatório](arqueiro/depois/arqueiro-recuperado_line.json): 56 pixels de corda (51 mantidos, 5 desenhados),
  26 tirados para o vazio, 1 inferido; 32 pixels mudados, todos na zona; fora dela e nas regiões protegidas, idênticos.
- Depois: [vereditos](arqueiro/depois/arqueiro-recuperado_line_equip.json) com a
  [observação reaplicada](arqueiro/depois/arqueiro-recuperado_line.observation.json) (os mesmos seletores, sobre a
  imagem nova; uma observação vale só para a imagem cujo hash traz).

A curva da madeira não se mediu (é intencional); a outra mão no cinto lê-se como repouso e não como puxada; a aljava
ficou fora desta prova. Custo: zero chamadas pagas; uma marcação manual e um reparo determinístico.

## As sondas do contorno

O contorno global da Forja engrossa uma corda de 1 px para 3 px e fecha um vazio de 2 px entre duas linhas — o
segundo teste do relatório (§5.2), reproduzido em [prova.json](prova.json). Com a zona declarada sem contorno
(`--bare`), a corda e o vazio ficam como estavam. Nos três resultados da entrega este ramo não correu (o relatório
viu-o no registo `finish`), por isso a sonda é prevenção e não a causa da corda larga, que já vinha da fonte.

## O que ficou por fazer (e porquê)

- **Espada do rei e escudo do escudeiro** (relatório §10, a seguir ao arqueiro): precisam das fontes da entrega ou
  de uma recuperação como a do arqueiro, e o escudo precisa da ficha do verso (pergunta aberta sobre o tipo de pega).
- **P1 (operações PixelLab, poses no tempo, rampas por material) e P2 (biblioteca)**: o relatório pede que só
  avancem depois de esta prova mostrar melhoria sem regressão de identidade; a identidade ainda não tem verificação.
- **Inventário compilado no prompt a partir do manifesto** (P0-6, parte): o assunto ainda é texto livre; as
  contradições de câmara e direção já bloqueiam o plano.
- As decisões que são do dono estão em [QUESTIONS.md](../../../QUESTIONS.md) (Q-272 a Q-276).

## Reproduzir

```bash
python3 docs/art/research/2026-10-24-forja-armas/prova_arqueiro.py
python3 -m tools.forja equip docs/art/research/2026-10-24-forja-armas/arqueiro/arqueiro-recuperado.png \
  --manifest docs/art/research/2026-10-24-forja-armas/arqueiro/manifesto.json \
  --observation docs/art/research/2026-10-24-forja-armas/arqueiro/observacao.json --kind royal_80 -o build/forja/arqueiro
make forja
```
