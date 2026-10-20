# ADR 0086 — As composições do dono, separadas em planos, pintam o mundo

- Estado: aceite
- Data: 2026-10-17
- Secção do dossiê: §11 (o mundo em duas camadas), §21 (segmentos, limiar e borda), §22 (profundidade), §80 (a luz)
- Complementa: ADR 0081 (os cenários em camadas), ADR 0084 (a produção nativa), ADR 0077 (a água que o território
  conta), ADR 0039 (a terra por cima do subsolo)
- Tarefa: [CV-04](../backlog/CV-04.md)

## Contexto

O dono, a 17/10/2026: *«Quero que implemente esses dois arquivos .zip que te enviei, o do google drive é essencial
que aplique»*. Os dois ZIPs:

- `EMPIRE-Agua-Composicoes-Aprovadas-2026-10-15.zip` (anexo) — o porto, o lago e o rio, aprovados a 15/10 («Estão
  perfeitos, é mesmo como quero»), com as guias de 1280 × 720 e o pedido de encaixe.
- `EMPIRE-Cenarios-24-2026-10-16.zip` (Drive) — 24 composições novas: 16 dos oito reinos (base e uma variante cada),
  6 variações das três águas e 2 transições, com as três aprovadas e o mesmo contrato (chão em y 517, nível de baixo em
  618,5, segmentos de 640 px).

A ADR 0084 (16/10) reconstruiu estas vistas com imagens geradas de novo e reduzidas a blocos de 4 px. As capturas do
jogo mostravam por isso outro desenho, mais grosso, e não as pinturas que o dono escolheu. Os dois pacotes dizem o que
falta: separar paisagem, planos, terreno, água e construções, pôr o chão nas coordenadas do jogo, deixar fora o que é
da simulação (edifícios, barcos, trabalhadores, escadas) e manter as silhuetas, a luz e o detalhe aprovados.

Como na ADR 0075 e na ADR 0081, este pedido autoriza a edição de `art/` para esta tarefa, sobrepondo-se à regra 9.

## Decisão

**O que se vê de cada povo é a pintura do dono, separada em planos a partir dos próprios pixeis dela; a hora e a
estação escolhem a variante; o porto, o lago e o rio ficam na água que o território já conta.**

1. **Separar sem repintar (`tools/owner_scenery/`).** Cada pintura é dividida pela profundidade (Depth Anything V2) e
   pelo céu (SegFormer ADE20k), ao nível de superpíxeis (SLIC): os contornos seguem a pintura e não o modelo. O chão de
   cima e o de baixo de cada pintura são medidos à mão (`views.json`) e postos em 517 e 618,5. O que a simulação
   desenha sai: edifícios, barcos, pessoas, o rei, escadas e as portas de baixo; o cais e as pontes ficam, como
   paisagem. O que estava por trás enche-se em dois passos: o LaMa diz que forma e que cor vão lá, e cada célula de
   8 × 8 desse palpite é trocada pela célula da própria pintura que mais se lhe parece e que casa com as vizinhas — o
   traço que fica é o do dono, e não o borrão de um inpainting. Onde a casa é maior do que o que a rodeia (a do lago, a
   azenha do rio), cobre-se antes com uma faixa da própria pintura ao lado dela — a margem e o lago, as árvores por
   baixo do aqueduto —, repetida e virada a cada cópia para as juntas casarem. Os astros pintados saem do céu: o `SkyView` desenha o
   sol e a lua do jogo, e haveria dois. Nada se reamostra para um bloco maior: o export é a pintura em meia resolução,
   na grelha de 2 px do jogo, com alfa binário.
2. **Os planos.** Céu (opaco, sem nuvens nem astros — o `SkyView` desenha o sol e a lua do jogo; por trás do que o
   tapava continua o degradê da própria pintura, linha a linha), nuvens (0,07), longe
   (0,125) e meio (0,25) num laço escolhido onde as duas pontas casam e que leva os marcos do reino (o vulcão, o
   castelo, a vila do horizonte), cada um com um período próprio. O longe é opaco até ao chão e repete-se duas vezes por
   laço: uma como pintada, outra sem a vila do horizonte, para a vila não se ver três vezes no mesmo ecrã; nessa, o
   contorno do plano passa onde a vila estava de crista a crista, e não pelo fundo da caixa dela. O meio é uma
   parede de árvores onde a pintura o tem quase de ponta a ponta (os Enramados), e só o contorno do que lá está onde é
   esparso (uma árvore, uma cerca). O perto (0,5) leva a árvore ou o rochedo do primeiro plano e mostra-se uma vez por
   2560 px, com o meio da composição atrás da sede e as pontas fechadas. O chão (`under`, `terrain`) é o caminho, a cerca
   e a terra de baixo, em 1280. Um sítio de água é um quadro só, de 1280, sem laço.
3. **As variantes.** `OwnerScenery.weights` dá o peso de cada pintura agora: a da hora (o luar, a névoa da alvorada, as
   brasas) entra na segunda metade da fase de antes e sai na primeira da de depois; a da estação (a colheita, o
   outono, a geada) muda durante a alvorada do primeiro dia. As pintadas para uma hora já trazem a luz dela: desenham-se
   num nó com o material `SceneryLight.PINTADA`, sem o ambiente da fase por cima, e as luzes do mundo somam-se — menos o
   ambiente da noite, que lhes cai com o peso dela (`SceneryLight.night_weight`: entra na segunda metade do crepúsculo e
   sai na primeira da alvorada, como uma variante da noite), porque a noite é castanha (§80, ADR 0011). Sem ele, o luar
   pintado chumbava o `make silhueta` à meia-noite: 3,9% contados, onde o limite é 0,5% (o que o portão conta: Q-270).
4. **Os sítios (`OwnerSites`, `SceneryMap.with_sites`).** A proposta da Q-259, com as três vistas aprovadas: o lago na
   água dos Enramados (a de casa e a dos segmentos de água), o porto na dos Portuários e o rio na da Bruma. O quadro de
   1280 px fica com a água pintada no x da fonte; se não cabe inteiro no troco, não se pinta e a água continua a do
   `ResourceWater`. Onde há sítio, o `ResourceWater` não desenha por cima.
5. **As transições.** Enramados → Bruma substitui o chão da Mata Encharcada e traz a estela como marco; Fenda → Geada é
   um par que não tinha transição. O fundo continua a ser a mistura dos dois reinos (Q-261).
6. **O resto é o de sempre.** `SceneryArt` lê o manifesto antigo, a produção nativa e por fim este (`OwnerScenery.patch`):
   `SceneryMap`, `SceneryPlane`, `SceneryStrip`, o `SoilCover` e a luz não mudam de contrato. A produção nativa fica na
   galeria (`tools/native_scenery_review.tscn`); os planos de campanha dela deixam de ir nos exports.
7. **Verificação.** `tools/export_owner_scenery.py` confere cada PNG de origem contra o ZIP de onde veio (SHA-256) e
   `--check` confere o export contra o manifesto, no portão `inventario-arte`. O CI abre os três PCK e exige as texturas
   do dono.

## Dependências

Nenhuma no jogo nem no CI: o export e o `--check` só precisam do Pillow, já fixado. A separação corre fora do CI, uma
vez por entrega, com PyTorch (CPU), Transformers, OpenCV contrib, scikit-image, SciPy, ONNX Runtime e três modelos
abertos (Depth Anything V2 Large, SegFormer-B5 ADE20k, LaMa em ONNX), listados em `tools/owner_scenery/requirements.txt`.
Os modelos não entram no repositório.

## Alternativas consideradas

- **A pintura inteira como uma camada só, a 1:1.** Mantinha cada pixel, mas o fundo andava com o chão e não havia
  profundidade; e o que a simulação constrói ficava pintado no Dia 1.
- **Pedir a um gerador de imagens as camadas separadas** (o caminho da ADR 0084). Muda o desenho: foi o que o dono
  aprovou que se perdeu.
- **Inpainting só com LaMa, ou só com cópias da pintura (shift-map).** O primeiro borra os pixeis; o segundo mantém o
  traço mas, em buracos grandes, repete riscas e pedaços de telhado. O enchimento guiado usa os dois.

## Consequências

- Os oito reinos, três sítios de água e duas transições usam as pinturas do dono; cada vista ocupa cerca de 0,7 MB no
  repositório e 3 a 4 MB de vídeo, carregados só quando o troco está perto.
- O que foi preenchido por trás do que saiu é uma estimativa: onde a pintura não diz o que estava atrás de uma casa, o
  enchimento é verosímil e não autoral (Q-267).
- O nível de baixo da pintura é paisagem, como na ADR 0039: as passagens continuam a ser as da simulação.
- Reverter: apagar `art/export/scenery_owner/manifest.json` devolve os planos da ADR 0084 sem tocar em código.
