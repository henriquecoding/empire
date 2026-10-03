# ADR 0055 — Cada frame paga só o que se vê; e a moeda menor, por cima de quem a larga

- Estado: aceite
- Data: 2026-10-03
- Secção do dossiê: §02, §11, §22, §24, §63, §80
- Actualiza: ADR 0050 e Q-192 (o tamanho da moeda), ADR 0048 (o que o shader do cenário recebe), ADR 0049 (como o
  bestiário se pinta)

## Contexto
O dono, a 03/10/2026: *«diminua o tamanho da moeda em 30% e trabalhe densamente para melhorar o desempenho do jogo, por
algum motivo está muito lento»*, e depois: *«há algum bug que a moeda não está sendo dropada nem está dando para
utilizar»*.

**Medido**, com o motor fixado (4.7.2), a semente 7, um monarca e a câmara no núcleo; CPU sem ecrã (`--headless`) e
renderização com `xvfb` (OpenGL em software, que é um GPU fraco: conta o que o motor manda desenhar). O que pesava:

- **O mundo inteiro, a cada frame.** As terras geradas (Q-173) fazem do mundo 53 000 px, e o ecrã mostra 1 280. O
  `FaunaView` andava e desenhava 732 bichos de cenário por frame; o `BuildView` desenhava as obras todas; o `SoilCover`
  era um nó só com o chão do mundo inteiro — 220 das 356 draw calls de um frame de dia, e 14 000 primitivas; o campo e
  a linha de árvores (`WildsLayer`), outras 8 000. Um canvas do Godot só se recorta inteiro.
- **A luz, por rectângulo.** `Lighting.body` percorria as luzes todas duas vezes por cada rectângulo de cada corpo, e
  um sprite pede-a dezenas de vezes no mesmo x. O shader do cenário recebia todas as luzes, mesmo de dia (força zero) e
  mesmo longe do ecrã, e cada pixel de cada plano percorria-as.
- **As criaturas, traço a traço.** O bestiário (ADR 0049) rasteriza cada criatura em cada frame — elipses linha a
  linha, linhas passo a passo, duas contas de px de mundo por rectângulo: 0,3 ms por criatura. Numa noite de 27, 674
  draw calls.
- **O bando, todos contra todos.** O `Flock` assumia «meia dúzia de pássaros»; com o mundo contínuo junta 107, e o
  bando estava a 13 000 px do ecrã a custar 1 ms por frame.
- **A moeda não se via.** Largada aos pés do rei, era desenhada no canvas da faixa, e as tropas (o rei, o escudeiro, o
  companheiro) são um canvas filho, desenhado por cima: o saco esvaziava e não se via moeda nenhuma — e, numa obra, a
  moeda paga desaparecia sem se ver cair. A simulação estava certa (a moeda sai do saco, cai e paga: verificado com a
  tecla real e numa obra); era o ecrã.

## Decisão
**Cada frame paga só o que está perto do ecrã, e o que não muda calcula-se uma vez.** A moeda desenha-se por cima de
quem anda, e é 30 % menor.

- **A moeda**: `CoinArt.MOEDA` = 2,8 px (70 % do `CHAO`): a moeda de 36 para 25,2 px, a pilha e o saco na mesma
  proporção; a coroa fica no `CHAO`. A moeda (e a que sobe ao ser levada) vai num canvas `BandView.Moedas` depois do
  das tropas; a sombra fica no chão, por baixo delas.
- **Recortar ao ecrã** (`PresentationBounds.of`/`sees`, o mesmo que as tropas e as criaturas já usavam): os bichos de
  cenário desenham-se só no ecrã e andam só até `FaunaView.ANDAM` (640 px) para lá dele — o resto espera a câmara; as
  obras desenham-se com `BuildView.ALEM` (320 px) de folga; as moedas, no ecrã. Sem ecrã (um teste), vê-se tudo.
- **Talhões**: o `SoilCover` e o `WildsLayer` desenham em nós de 1 024 px (`LowlandArt.parts`, `FloraArt.chunks`), e
  o motor deixa de fora os que estão longe. A terra tem uma parte por nó, pela ordem em que se pinta — o chão, os
  caminhos e os lagos, as plantas —, e só se redesenha o talhão que mudou quando nasce um segmento.
- **A luz**: `Lighting.body` lembra a luz do último x (`ambient`, `dark` e `glows` esquecem-na ao mudar); o
  `SceneryLight` só manda ao shader as luzes com força e perto do ecrã (`ALCANCE`, 1,5 raios), e o shader, sem nenhuma,
  é só o ambiente.
- **O bestiário**: o `BeastPen` grava os traços de uma pose (`record`) e pinta-os numa transformação só (`replay`); o
  `Bestiary` guarda cada pose pela forma e pelos sinais em 1/16 da amplitude (`PASSOS`) — um sinal de k pixeis anda de
  k/16 em k/16, abaixo de meio px de mundo —, até `POSES_MAX`.
- **O bando**: os vizinhos procuram-se por ordem de x (o `sort()` do motor), cada par uma vez; longe da vista o bando
  anda aos saltos de `Flock.LONGE_S` (0,2 s).
- **O painel**: os textos do `GameHud` e o guia do `ContextPanel` refazem-se dez vezes por segundo (`TEXTO_S`); a barra
  da fase continua a cada frame.

**Depois**, nas mesmas condições (média por frame):

| | antes | depois |
|---|---|---|
| CPU, dia 1 | 14,7 ms | 6,9 ms |
| CPU, noite com 27 criaturas | 25,2 ms | 10,7 ms |
| Renderização em software, dia | 87,5 ms · 360 draw calls · 30 195 primitivas | 56,5 ms · 155 · 11 923 |
| Renderização em software, noite | 112,3 ms · 674 draw calls · 45 390 primitivas | 82,3 ms · 178 · 20 082 |

As fotografias de dia, de noite e do bestiário, antes e depois, diferem só no que já difere entre duas corridas da
mesma versão (a cintilação das luzes e a fase de repouso das tropas, que correm pelo relógio do ecrã).

## Alternativas consideradas
- **Mudar o renderer para Compatibility.** É o que o browser já usa, e num GPU integrado costuma ser mais leve em 2D;
  mas muda o pipeline de cor e é uma escolha de motor, do dono. Fica por medir num PC real.
- **Pintar o cenário em texturas (bake).** Tirava quase todas as primitivas, mas é uma reescrita das camadas, e os
  talhões chegam para o motor recortar.
- **Limitar o bando a meia dúzia de pássaros.** O bando é de quem o mundo gera (`Wilds.animals`); mudar quantos é
  conteúdo, não desempenho.
- **Desenhar as moedas por cima no mesmo canvas da faixa.** A faixa desenha-se antes dos filhos, e as tropas são um
  filho: só outro canvas, depois delas, as põe por cima.

## Consequências
- Quem desenhar o mundo a cada frame pergunta ao `PresentationBounds` o que se vê; um desenho estático e largo vai em
  talhões. Um bicho longe da câmara não anda: é cenário, e ninguém o vê parado.
- Uma criatura nova desenha-se como antes (traços em constantes); a pose guarda-se sozinha. Mudar os traços de uma forma
  em jogo pede `Bestiary._poses.clear()`.
- `tests/desempenho_test.gd` prova que cada atalho dá a resposta do caminho comprido: a luz lembrada e a fresca, o bando
  por ordem de x e o de todos contra todos, os talhões sem perder planta nem caminho, a pose gravada, e a moeda por cima
  das tropas.
- Desfazer: a moeda volta a 36 px com `CoinArt.MOEDA` = `CHAO`; o recorte, com `PresentationBounds.of` a devolver
  `TUDO`; o resto é independente e desfaz-se ficheiro a ficheiro.
