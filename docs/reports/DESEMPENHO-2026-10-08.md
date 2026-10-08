# Empire — auditoria de desempenho

Data: 08/10/2026. Ticket: RG-18 (parcial). Base: `main` em `0433c13` (CV-02).
Pedido do dono: «o desempenho do jogo parece estar muito pesado e mal elaborado».

## Método

A regra do §63 e da `docs/qa/PERFORMANCE_MATRIX.md`: medir primeiro, mudar depois, e
só o que se mediu. Nada aqui é estimado.

- **Bancada** (`tools/desempenho.gd`, `make desempenho`): a cena de jogo inteira, o
  piloto da vistoria a jogar, semente `20260916`. Mede o custo de um tick (o avanço a
  mão de N segundos de jogo, sem desenhar) e o frame (média, p95, p99).
- **Perfilador** (`tools/perfilador.gd`, `make perfil`): faz de editor — liga-se ao
  debugger remoto do motor e lê o perfilador `servers` (o separador *Profiler* do
  editor), com o tempo próprio e total de cada função de GDScript por frame.
- **Ambiente**: Godot 4.7.2, CPU de servidor, Xvfb com janela real e o render `dummy`
  — mede só o CPU do jogo. Sem janela (`--headless`) a vista é infinita e nada fica
  fora do ecrã; com o rasterizador por software (llvmpipe) o frame é o do rasterizador.
- **Antes e depois**: uma *worktree* da `main` ao lado do ramo, a mesma bancada nas
  duas. O estado final de cada medição (dia, fase, tropas, moedas) é igual nas duas:
  as correções não mudaram o que o jogo faz.

Os números são de uma CPU de servidor. Num telemóvel, e sobretudo na web (GDScript em
WebAssembly, sem *threads*), cada um multiplica-se várias vezes — é aí que «pesado» se
sente, e é por isso que o que se poupa por frame conta.

## O que se encontrou

| # | Achado | Custo medido (antes) | Onde |
|---|---|---|---|
| A1 | O `absorb` perguntava `can_climb` — escada, território e muralha, que percorrem as obras todas — a **cada obra, a cada tick**, e só depois via se havia moeda em cima | ~0,9 ms por tick; metade do tick | `BuildSystem.absorb` |
| A2 | O desenho das obras fazia a mesma conta (`RealmGrowth.visible`) às obras **fora do ecrã** antes de as recortar | ~0,4 ms por frame | `BuildView.draw_on`, `TowerPreview.draw` |
| A3 | Os 801 bichos de cenário eram percorridos **duas vezes por frame** — para mexer nos ~150 perto do ecrã e para desenhar 25 | 0,8–1,2 ms por frame | `Fauna.tick`, `FaunaView._draw` |
| A4 | Os controlos de toque redesenhavam-se **todos os frames**, e cada botão voltava a medir o texto em vários tamanhos | ~0,8 ms por frame no toque | `TouchControls`, `TouchArt.label` |
| A5 | `Registry.ids()`/`entries()` reordenavam a tabela a **cada chamada** (várias por tick, via `SimFactory.by_id` e `RulesFactory.realm_stages`) | ~0,1 ms por tick | `Registry` |
| A6 | `Assume.driven()` (que percorre o plantel) pedido duas vezes por tropa, por faixa, por frame | cresce com o exército | `UnitArtBatch.draw_on` |

Medido e **deixado como está**, de propósito:

- O bando de Reynolds (~0,4 ms por frame com 115 pássaros) já procura vizinhos por ordem
  de x (03/10/2026). O resto teria de mudar o comportamento do bando.
- A síntese dos sons provisórios (~0,6 ms por frame) só dura o aquecimento: 17 s de som,
  ~16 s de jogo a 60 fps, espalhados para não travar o arranque (ADR 0054).
- O resto do tick ficou uma cauda plana: ~40 sistemas a 0,05–0,15 ms cada.

## O que se corrigiu

Nenhuma correção muda o que se vê ou o que se simula. Cada uma tem um teste que prova
que o atalho dá a mesma resposta que o caminho comprido (`desempenho_auditoria_test`,
`build_system_test`, `registry_test`).

1. **A1** — o `absorb` procura primeiro a moeda pousada; só a obra que a tem pergunta se
   sobe.
2. **A2** — o recorte do ecrã vem antes do `RealmGrowth.visible`; a pré-visão da torre
   pergunta a distância ao rei antes da muralha.
3. **A3** — `FaunaGrid`: os bichos que não são do bando moram no troço de 256 px onde
   estão; quem pergunta por um intervalo de x só olha para os troços que o tocam, e a
   resposta vem pela mesma ordem (a ordem de desenho não muda).
4. **A4** — `TouchView.plan()` diz o que os controlos mostram; o `TouchControls` só
   redesenha quando o plano muda. O corpo de letra que cabe em cada botão
   (`TouchArt.fit`) mede-se uma vez por texto, raio e tamanho pedido.
5. **A5** — o `Registry` guarda os ids ordenados e os recursos por essa ordem, e devolve
   cópias: quem recebe não estraga o índice.
6. **A6** — `Assume.driven()` pede-se uma vez por desenho.

## Antes e depois

Janela 1280×720 (toque: 2532×1170, a do iPhone deitado), render `dummy`, semente
`20260916`, 600 frames medidos depois de 60 de aquecimento.

| Momento | Tick antes | Tick depois | Frame antes | Frame depois |
|---|---|---|---|---|
| Dia 1, arranque | — | — | 6,94 ms | 5,63 ms |
| Noite 1 | 1,80 ms | 1,24 ms (−31%) | 8,44 ms | 7,90 ms |
| Dia 2, manhã | 1,82 ms | 1,35 ms (−26%) | 7,63 ms | 7,02 ms |
| Noite 2 | 1,77 ms | 1,33 ms (−25%) | 8,34 ms | 7,00 ms |
| Toque, arranque | — | — | 8,21 ms | 6,63 ms |
| Toque, noite 2 | 1,80 ms | 1,40 ms (−22%) | 8,45 ms | 8,11 ms |

A variação entre corridas iguais é de ~0,5 ms no frame; o tick é estável.

## O que fica por fazer (RG-18, Q-262)

- **Draw calls.** O orçamento do §63 é ≤ 120; medido com render real, ~100–180 de dia e
  **~160–280 à noite**. Atribuídos escondendo uma camada de cada vez: o subsolo
  (`RootCellars`, ~60), o chão (`PathAndSoil`, ~37), a faixa da superfície do
  `BandView` (~78, das quais as obras ~20 e as tropas ~13) e o HUD (~20). São formas
  vetoriais que não se juntam num lote. O caminho que o projeto já tem para isto é o
  do `PaintedArt` (ADR 0051): pintar uma vez numa textura o que não muda a cada frame.
  Não se fez aqui porque muda como as camadas se compõem e pede o olho do dono.
- **Enchimento no telemóvel.** O cenário pintado (CV-02) tem cerca de oito planos de
  ecrã inteiro com o shader `world_light`; com o `canvas_items` o telemóvel pinta-os à
  resolução nativa (3 Mpx num iPhone deitado). No rasterizador por software, o
  cenário é ~20 dos ~36 ms do frame a 720p, e o frame passa de ~40 para ~100 ms a
  2532×1170. Uma
  resolução interna mais baixa no toque é uma decisão da ADR 0001, não deste diff.
- **Sedes grandes e o painel**, como o RG-18 pede: medir com `make desempenho` depois
  de levantar a Fortaleza.

## Como voltar a medir

```bash
xvfb-run -a make desempenho AVANCAR=630                 # o frame e o tick na noite 2
xvfb-run -a make desempenho AVANCAR=630 EXTRA="--toque 1"
xvfb-run -a make perfil AVANCAR=630                     # build/perfil.txt
```

O perfilador do motor às vezes atribui a uma função um tempo maior do que o frame
inteiro (aconteceu com `SynthTake.sample` e com `Lighting.body`). Uma linha assim
confere-se contra a bancada, que mede pelo relógio.
