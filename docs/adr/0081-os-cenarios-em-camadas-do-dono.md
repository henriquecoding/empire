# ADR 0081 — Os cenários em camadas do dono entram no jogo

- Estado: aceite
- Data: 2026-10-08
- Secção do dossiê: §11 (o mundo em duas camadas), §21 (segmentos, limiar e borda), §22 (profundidade), §80 (a luz)
- Complementa: ADR 0038 (o mundo contínuo), ADR 0039 (em baixo é só paisagem), ADR 0075 (a direção visual), ADR 0078
  (o contrato dos planos)
- Tarefa: [CV-02](../backlog/CV-02.md)

## Contexto

O dono, a 08/10/2026: *«Quero que acesse meu google drive para ter acesso aos arquivos .zip que são o que você precisa
para implementar o design que quero no meu jogo»*, com o catálogo e o guia da entrega. A pasta do Drive tem três lotes:
os **8 reinos** (Enramados, Bruma, Horta, Portuários, Fenda, Caldeira/Fornalha, Geada, SobRaiz), as **13 transições**
entre eles e **3 propostas especiais** (Reino Fluvial, Porto Central, Lago com Ponte e Cais). Cada cena é um ZIP com
as camadas alinhadas em `18_aligned`, a composição, as rotas candidatas e um visualizador; o `catalogo.json` de cada
lote leva o SHA-256 de cada ZIP.

As cenas foram feitas para a geometria do jogo: chão em y 517 (`Band.GROUND_LINE`), pés do subsolo em 618,5
(`WorldPalette.ground_of`), segmentos de 640 px, ecrã de 1280 × 720. O guia é explícito no que não traz: movimento,
colisões, passagens, economia e construção ficam com o jogo; só céu, nuvens e o que está longe pode ter parallax; as
fachadas de casas e castelos só aparecem quando o estado do mundo as permite.

Tal como na ADR 0075, este pedido autoriza a edição de `art/` para esta tarefa, sobrepondo-se à regra 9 do
`AGENTS.md`; as fontes ficam no Drive do dono e o que entra no repositório é o export verificado.

## Decisão

**O cenário de cada povo é o reino pintado dele, e a fronteira entre dois povos é a transição pintada desse par.
O que se constrói, onde há passagem e onde há água continua a ser a simulação a dizer.**

1. **Export (`tools/export_scenery.py`).** Lê os três lotes sem os extrair, confere cada ZIP com o `catalogo.json` e
   escreve em `art/export/scenery/<cena>/` só as camadas que o jogo desenha, recortadas ao alfa. Quando a camada foi
   pintada em blocos repetidos (os céus vêm em 8 × 4), guarda-se no bloco nativo: as mesmas cores, sem reamostrar.
   O `manifest.json` diz, por camada, o retângulo no quadro, o bloco e o SHA-256 do PNG; `--check` confere o export
   contra ele sem os ZIPs (portão `inventario-arte`). Os 21 cenários ocupam 10 MB.
   - Reinos: céu, nuvens, longe, meio, perto, encosta (`under`), terraço de baixo (`terrain`), água e folhagem da frente.
   - Transições: encosta, terraço, água, folhagem e o marco do limiar, recortado da camada de adereços onde o autor o
     pôs (`07_props/threshold_landmark.png`, localizado pixel a pixel).
   - Ficam nos pacotes: edifícios e fundação (a sede e as obras são da simulação), escadas e atividades de baixo (não
     são passagens registadas), atores de referência e as três propostas especiais (Q-259).
2. **Que cena em cada sítio (`SceneryMap`, puro e testado).** A região de casa e cada segmento gerado são um troço com
   o bioma dele; num trilho, o da terra de onde se vem. A terra muda no limiar (§21: *«a fronteira entre povos nunca é
   um fade»*). Onde há transição pintada com o de-onde-se-vem à esquerda, ela fica centrada nessa fronteira (640 px
   para cada lado) e os reinos encostam-se a ela; onde não há, os dois reinos encontram-se na fronteira com uma junta
   esbatida de 48 px. As transições nunca se espelham (o guia: *«never mirror the entire scene»*), por isso a oeste
   de casa, onde os pares estão ao contrário, não há transição pintada (Q-260).
3. **Fundo (`SceneryPlane`, em parallax).** Céu 0,03125 · nuvens 0,07 · longe 0,125 · meio 0,25 · perto 0,5 — os
   fatores das transições, que coincidem com o `parallax_layers.csv` nos planos que ele tem (Q-254). Por cima da terra
   de cada povo pinta-se o reino dele; a fronteira projeta-se em cada plano e um reino dá lugar ao outro numa faixa de
   480 px (o `background_mix_interval` das transições). O mosaico ancora o meio do reino atrás do meio da região, onde
   a sede nasce. O céu, que é um gradiente, repete-se com um quadro sim e outro não virado e sem o texel de cada ponta
   (nos céus pintados a coluna da ponta é mais clara): nas terras longe de casa não se vê a junta.
4. **Chão (`SceneryStrip`, no mundo).** Até y 517, a beira de erva, o caminho e o marco da transição (nó `Chao` da
   cena do cenário, fora de qualquer `Parallax2D`). Abaixo de 517, a encosta, o terraço de baixo, a água e a folhagem
   da frente são a terra do `SoilCover`: levam o dither dele e dissolvem-se quando o rei desce (ADR 0039). Um limiar
   coberto por uma transição pintada leva só a bandeira do povo (vassalo ou não) e não o marco procedural.
5. **A luz é a de sempre.** Cada plano leva o material do `SceneryLight` da sua profundidade; a noite, as fogueiras e o
   archote caem na arte pintada como caíam nos polígonos.
6. **Memória.** Cada nó pinta só a janela à volta da câmara e guarda as texturas que mostra; as que ninguém mostra
   saem da memória. Um reino inteiro ocupa entre 5 e 8 MB de vídeo; uma transição, pouco mais de 1 MB.
7. **Recurso.** Se faltar o manifesto ou um bioma não tiver reino pintado, `SceneryArt.painted()` é falso e o jogo
   desenha o cenário procedural inteiro, como antes. Não se misturam os dois.

## Alternativas consideradas

- **Trocar o fundo pela posição da câmara** (os dois reinos a misturar-se no ecrã todo perto da fronteira): a primeira
  captura mostrou uma dupla exposição — o carvalho ancestral meio transparente sobre o lago da Horta. Rejeitada a favor
  da faixa projetada da fronteira.
- **Usar os fundos das transições.** Cada transição tem céu, longe, meio e perto de 1280 px, pintados para a câmara
  parada na fronteira. Em parallax, a primeira passada da câmara mostra-lhes a borda; ficam nos pacotes (Q-261).
- **As camadas `18_aligned` inteiras como textura única.** O guia diz que as prévias não são a textura final; e 12
  camadas de 2560 × 720 por reino seriam 88 MB de vídeo por reino.
- **Espelhar as transições para o lado oeste.** O guia proíbe-o: inverte a direção da luz.

## Consequências

- O mundo inteiro, da borda à borda, tem a arte do dono; o `Lowland`, o `WildGround` (chão), o panorama do vale, o
  bosque de carvalhos e as plantas do campo e do horizonte ficam como recurso, sem se desenharem.
- As árvores do plano "perto" são cenário, a 0,5: não se abatem. A floresta funcional continua a ser a da ADR 0070.
- O carvalho ancestral dos Enramados (e a árvore da SobRaiz) faz parte do plano "perto" do reino e repete-se a cada
  5120 px de caminho (Q-261).
- Os pássaros pousam onde pousavam (a `Fauna` tira os arbustos das tabelas), agora sem o mato procedural por baixo.
- A água que o território conta para o pesqueiro continua sem margem pintada (Q-257); o Lago com Ponte e Cais é o
  candidato natural, por decidir (Q-259).
- Reverter: apagar `art/export/scenery/` (ou o manifesto) devolve o cenário procedural sem tocar em código.
