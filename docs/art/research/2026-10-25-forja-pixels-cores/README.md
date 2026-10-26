# Forja — pixels coerentes, cores e continuidade visual (25–26/10/2026)

O dono enviou, a 26/10, três ficheiros da pesquisa de 25/10 — o relatório «Forja — pixels coerentes, cores e
continuidade visual», o dossiê dos 200 vídeos do canal da PixelLab e o pacote para o Claude (script de provas,
evidências, catálogo e fichamentos) — e pediu: *«Trabalhe densamente analisando e aplicando esses arquivos ao meu
jogo, faça por etapas, não tenha pressa, faça bem feito»*. Tarefa: [FORJA-04](../../../backlog/FORJA-04.md). Decisão:
[ADR 0092](../../../adr/0092-a-forja-ve-a-cor-no-espaco.md). Guia atualizado: [FORJA.md](../../FORJA.md#a-cor-no-espaço-o-que-o-lint-raster-não-via).

| Ficheiro | O que é |
| --- | --- |
| [RELATORIO.md](RELATORIO.md) | O relatório, como chegou (24 secções; a §22 é a instrução para o Claude) |
| [DOSSIE-PIXELLAB-200-VIDEOS.md](DOSSIE-PIXELLAB-200-VIDEOS.md) | A cobertura dos 200 itens públicos e os 40 fichamentos |
| [pacote/](pacote/) | O pacote, byte a byte: o script `provas-pixels-cores.py`, as evidências (`resultados.json`, `scatter.png`, `cluster.png`), o catálogo dos vídeos e o `MANIFESTO-SHA256.json` (os 12 ficheiros conferem a partir do git) |
| [prova_cores.py](prova_cores.py) | A prova reproduzível deste trabalho; grava [prova.json](prova.json) e falha se um resultado mudar |
| [elenco/](elenco/) | O rei, o arqueiro e o escudeiro recuperados da figura de 24/10 e o diagnóstico de cor de cada um |
| [arqueiro/](arqueiro/) | A observação de cores, o plano, o candidato, as diferenças, as zonas, os vereditos e a composição com a corda refeita |

**Em resumo:** as nove falhas que o relatório reproduziu no snapshot `4471cde` reproduziam-se ainda na `main` de
26/10 (`74f71a1`, depois do FORJA-03). Os cinco incrementos que o relatório pede (§19) entraram por esta ordem, cada um
com testes: o diagnóstico da cor no espaço (componentes N4/N8, fragmentos com estado, métricas por região e um eixo
novo, `color_coherence`), a proteção que vale até ao PNG final, o orçamento de cores que já não se cala ao lado de uma
paleta e as rampas por material, a temporalidade que diagnostica antes de corrigir e só corrige onde se declarou que
nada se mexe, e a separação entre área, conectividade e bloco. O script do pacote, **sem alteração**, corre agora contra
o código novo: o que o relatório pede que mude mudou, e o que deve ficar igual (a validade raster das duas fixtures e a
área de uma mancha) ficou. A prova pequena é a do arqueiro (§22): 44 pixels
agrupados no pano verde, nas calças e nas linhas, com o rosto, os braços, o arco e a corda presos — zero mudanças nos
1054 pixels presos, zero fora da zona, o alfa igual. **Nada disto aprova arte**: o candidato é uma proposta, nada foi
escrito em `art/`, não houve geração nem chamada paga, nem dependência nova.

## O que se conferiu antes de mexer

| Conferência | Resultado |
| --- | --- |
| Integridade do pacote | Os 12 hashes do `MANIFESTO-SHA256.json` conferem; o relatório e o dossiê do pacote são byte a byte os dois Markdown enviados à parte |
| As provas do pacote na `main` de 26/10 | Todas as nove reproduzem (o FORJA-03 não tocou nesses caminhos): ver a coluna `4471cde` da tabela abaixo, igual à da `main` antes deste trabalho |
| Os três personagens | Recuperados da [figura de 24/10](../2026-10-24-forja-armas/entrega-examinada.png) (células 6×6 de uma só cor, origem posta no pivô do contrato): as **nove medidas** do pacote (pixels opacos, cores, componentes N4/N8, singletons N4/N8/interiores, órfãos de alfa) são iguais nos três; o arqueiro é o mesmo do FORJA-03 pixel a pixel |
| O lint nos três | 0 erros e um aviso de gradiente em cada — o que o relatório diz na §6 |

## As provas do pacote, antes e depois

O script do pacote corre sem alteração; a coluna `agora` é a mesma corrida contra `tools/forja` desta entrega
([prova.json](prova.json), secção `package_proofs`).

| Prova (relatório §7) | `4471cde` | agora | O que mudou |
| --- | --- | --- | --- |
| 16 pontos espalhados × o mesmo histograma num bloco: lint | 0 erros, 0 avisos nos dois | 0 erros, 0 avisos nos dois | De propósito: as duas cumprem o contrato raster |
| … e o diagnóstico de cor | não medido | `needs_review` × `pass` | `clusters.py`: 16 fragmentos a rever × nenhum; S8 = 0,0066 × 0 |
| `colors=2` com uma paleta de três | 3 cores no fim | 2 | `quantize.apply`: subconjunto da paleta, com o preto do contorno obrigatório |
| Pixel 105 protegido até ao fim | saía 100 | 105 | `guard.py`: a garantia mede-se no PNG final; com paleta incompatível fica exato e o conflito é um erro |
| `min_cluster(2)` numa diagonal de oito | apagava 8 | 0 | 8 vizinhos por omissão; 4 só por escolha (cenário) |
| Tira 1×4 e quadrado 2×2 (área) | nenhum é «mancha pequena» | igual, de propósito | A área continua área; `footprint` diz que a tira não tem bloco 2×2 (1 × 0) |
| Olho aberto–fechado–aberto | reabria o olho | 0 mudanças | `temporal.py`: sem região estática declarada nada muda; o piscar fica `inconclusive` (ou `expected`, se declarado) |
| Faixa de baixo contraste a andar uma coluna | 24 pixels congelados | 0 | A vizinhança deslocada é movimento, mesmo dentro de uma região estática |
| Dither Bayer2 com força 0 | 128 de 256 brancos | 0 | A força é a amplitude da matriz: 0 é sem dither |

## O elenco: onde está a fragmentação

Sem regiões anotadas, a figura é a única região conhecida e todo o fragmento sem papel declarado fica `review` —
suspeita com evidência, nunca defeito confirmado (relatório §11). Os números são candidatos, não contagens de erros.

| Personagem | Tela | Opacos | Cores | Singletons N8 | S8 | Componentes N8 / 100 px (F) | A rever | Inconclusivos | Candidatos |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| Rei | 80×80 | 2783 | 27 | 97 | 0,0349 | 8,48 | 128 | 23 | [imagem](elenco/rei/rei_cores_candidatos.png) |
| Arqueiro | 80×80 | 2323 | 37 | 144 | 0,0620 | 13,82 | 185 | 44 | [imagem](elenco/arqueiro/arqueiro_cores_candidatos.png) |
| Escudeiro | 64×64 | 1845 | 46 | 94 | 0,0509 | 11,71 | 119 | 26 | [imagem](elenco/escudeiro/escudeiro_cores_candidatos.png) |

«A rever» conta fragmentos (componentes de 1–3 px), «inconclusivos» os ligados só pela diagonal (traço a analisar,
nunca a apagar). O rei e o escudeiro ficam só com o diagnóstico: o relatório pede que o elenco se expanda depois de o
arqueiro mostrar melhoria sem regressão, e isso é do dono julgar.

## O arqueiro (a prova pequena da §22)

**Observação** ([observacao-cores.json](arqueiro/observacao-cores.json)): 19 regiões marcadas por caixa e cores sobre o
PNG a 1×, conferidas num mapa de caracteres e a 12× — capuz e túnica (`cloth_green`), rosto, olho (`eye`), boca
(`mouth`), aljava, os dois braços, correia e cinto, fivela (`buckle`), calças, botas, as linhas, a zona inteira do
arco e as cinco regiões do arco, da mão e do antebraço que o FORJA-03 já tinha marcado. Quem marcou foi o agente desta
sessão; a observação diz-o e prende-se ao hash da imagem.

**Plano** ([plano-cores.json](arqueiro/plano-cores.json)): presos o rosto, o olho, a boca, os dois braços, a zona do
arco, a mão, o antebraço, a madeira, a empunhadura e a corda; o capuz e a túnica com a rampa dos três verdes que o
gerador já usava, as calças com dois tons, as linhas com o preto do contrato. Nenhum teto global de cores (Q-273),
dither desligado, paleta mestra intacta.

| | Antes | Depois |
| --- | --- | --- |
| Pixels mudados | — | 44 (7 na túnica, 5 nas calças, 31 linhas de `#0B0B0B` para `#000000`, 1 fragmento fundido) |
| Presos mudados, E(P) | — | **0 de 1054** |
| Fora da zona editável | — | **0** |
| Alfa | — | idêntico |
| Fronteiras entre materiais perdidas, C(R) | — | nenhuma |
| Cores opacas | 37 | 34 |
| Componentes N8 | 321 | 277 |
| Singletons N8 (S8) | 144 (0,0620) | 116 (0,0499) |
| Fragmentos a rever fora do que está preso (U) | 80 | 50 |
| Lint `royal_80` | 0 erros, 1 aviso (gradiente) | 0 erros, 1 aviso (gradiente) |

Por região: a túnica passa de 6 cores e 8 singletons a 3 e 3 (S8 0,0299 → 0,0112); as calças de 3 cores e 5
singletons a 2 e 2; as linhas de 79 componentes a 45. O capuz já estava coerente (S8 0,0045) e não mudou. A rampa
verde ficou com três tons — reduzir a dois, como a Asset Bible pede por material, é decisão de arte (Q-278).

- [Antes, depois e as diferenças a magenta, a 1× e a 8×](arqueiro/cores/arqueiro_cores_compare.png);
  [zonas presa e editável](arqueiro/cores/arqueiro_cores_zonas.png);
  [candidatos antes](arqueiro/cores/arqueiro_cores_candidatos_antes.png) e
  [depois](arqueiro/cores/arqueiro_cores_candidatos_depois.png); [relatório](arqueiro/cores/arqueiro_cores.json).
- **Equipamento:** os vereditos do FORJA-03 ficam iguais antes e depois das cores (o contrato raster passa, a geometria
  falha pela corda larga, a pose passa): a corda é de outro reparo ([antes](arqueiro/equip/antes/arqueiro_equip.json),
  [depois](arqueiro/equip/depois/arqueiro_cores_equip.json)).
- **Com a corda refeita do FORJA-03** ([corda-e-cores/](arqueiro/corda-e-cores/)): o mesmo plano, com a observação
  reaplicada, muda **os mesmos 44 pixels**, que não tocam nenhum dos da corda; a geometria passa.
  [Entrega, corda refeita e corda + cores lado a lado](arqueiro/comparacao.png).

### O que ficou por resolver (as falhas que a prova mostra)

- **A fragmentação está no detalhe, não no pano.** Depois do agrupamento, os 50 fragmentos a rever estão na aljava
  (17), nas botas (12), na correia e no cinto (10), na túnica (4), em pixels sem região (4), nas calças (2) e no capuz
  (1). As regiões mais fragmentadas são presas ou equipamento: a empunhadura (S8 0,48), a mão da frente (0,23), a
  correia (0,18), a aljava (0,11 depois) e a madeira do arco (0,13). Agrupar cor não resolve ali; é desenho de mão e
  de equipamento — reparo localizado ou nova geração com referência aprovada (relatório §17.3).
- **Sete fragmentos ficaram de propósito**, com a razão escrita: três encostam a um pixel preso (a fronteira com o
  rosto e com a manga), quatro estão cercados sobretudo pelo contorno ou por outra região — «escolher a olho», com a
  alternativa escrita.
- **52 pixels `#0B0B0B` continuam nas zonas presas** (o traço do rosto, a pupila, a mão): o plano lista-os como
  conflito em vez de os mudar. Levar o quase-preto interior ao preto no próprio acabamento é a Q-279.
- A cor da pele no rosto e na mão tem microvariação (`#FE9505`, `#F19312` junto de `#EAA55A`); ficou presa por pedido do
  relatório. O que não se mede — planos de luz, banding, rampas, curvas — está escrito em `not_measured`.

## Fatos, inferências e escolhas

| Tipo | Neste trabalho |
| --- | --- |
| Medição | As nove medidas dos três personagens iguais às do pacote; as provas do pacote antes e depois; as métricas do arqueiro por região; E(P) = 0 |
| Observação marcada | As regiões do arqueiro foram marcadas pelo agente desta sessão (caixa e cores, mapa de caracteres e 12×); a aljava e a correia têm incerteza média; não é um detector |
| Inferência registada | O `#0B0B0B` é o preto quantizado do traço (o `outline.normalize` só trata a borda e o docstring dele já o diz); a Asset Bible pede preto puro também no detalhe interno |
| Escolha nossa | Fragmento = componente N8 de 1–3 px (o ponto de partida do relatório §11.3, por calibrar); fundir só com maioria estrita da vizinhança e sem encostar ao que está preso; a distância à silhueta com teto de 32 |
| Lacuna | O conjunto de calibração de 48 imagens e 8 sequências (§18) não existe; as anotações não foram revistas por um humano; a leitura a 1× e no jogo é do dono |

## Os vídeos e a documentação

O dossiê cobre os 200 itens públicos do canal (180 legendas obtidas, 20 muito breves, 20 sem transcrição) e 40
fichamentos; não é transcrição integral nem visão de todos os quadros, e diz-o. Do que ele e o relatório trazem, entrou
na Forja: a paleta e a limpeza estrutural como etapas distintas (F01, F34), partículas pequenas como intenção (F07,
o gelo), a máscara a governar a imagem achatada (F08), estabilizar só o que está declarado parado (F09, a fogueira), a
boca que pode ser expressão (F16, F21) e o `drift_threshold` do PixelLab, que compara com o primeiro quadro e não é o
`--deflicker` da Forja (P10). O resto — referências por papel, versão do modelo por direção, mapas e emendas — fica
no relatório para os incrementos seguintes.

## Reproduzir

```bash
python3 docs/art/research/2026-10-25-forja-pixels-cores/prova_cores.py
python3 docs/art/research/2026-10-25-forja-pixels-cores/pacote/provas-pixels-cores.py --forja-dir tools/forja --out build/forja/provas
python3 -m tools.forja cores docs/art/research/2026-10-25-forja-pixels-cores/elenco/arqueiro/arqueiro.png \
  --observation docs/art/research/2026-10-25-forja-pixels-cores/arqueiro/observacao-cores.json \
  --plan docs/art/research/2026-10-25-forja-pixels-cores/arqueiro/plano-cores.json --kind royal_80 -o build/forja/cores
make forja
```
