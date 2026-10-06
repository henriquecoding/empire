# HUD móvel — pesquisa, aplicação e prova

Revisão de 06/10/2026. Base: `1a0587a`, captura móvel fornecida pelo dono e código efetivamente
usado por `scenes/game.tscn`. Implementação: [UX-05](../backlog/UX-05.md) e
[ADR 0074](../adr/0074-hud-mobile.md).

## Diagnóstico da captura

O principal problema é a hierarquia. O logótipo, o relógio, sete estatísticas, o objetivo,
o contexto, dois botões de combate e seis botões de toque competiam simultaneamente com o
mundo. A duplicação de ataque/habilidade não acrescentava uma ação ao jogador móvel.
O objetivo usava um retângulo de desenho diferente da posição do texto, deixando uma caixa
vazia à direita. A redução do canvas também reduzia as letras mais pequenas. A posição fixa
do aviso e das legendas não tinha em conta a altura real do contexto.

O refinamento deve libertar o centro, preservar as ações e tornar os dados disponíveis no
momento certo. Uma HUD vazia não é automaticamente melhor: perder o custo de uma ação, as
flechas ou a consequência de fundar seria uma regressão.

## Referências primárias e o que se transfere

| Fonte | Observação fundamentada | Aplicação em Empire |
| --- | --- | --- |
| [Kingdom Two Crowns — site oficial](https://kingdomthegame.com/kingdom-two-crowns/) | A apresentação oficial centra o jogo em microestratégia minimalista e pixel art. | Inferência de design: preservar a leitura do mundo e reduzir a informação permanente. Empire tem mais ações; não se assume que possa copiar a mesma quantidade de controlos. |
| [Dead Cells — ficha oficial de Playdigious](https://play.google.com/store/apps/details?hl=en_US&id=com.playdigious.deadcells.mobile) | A edição móvel anuncia interface adaptada e personalização de posição/tamanho dos botões. | Organizar por alcance dos polegares e conservar as opções de tamanho e mão já existentes. Um editor livre de posições fica fora desta revisão. |
| [The Lost Crown Mobile — entrevista da Ubisoft](https://news.ubisoft.com/en-us/article/7HvHq2SIDTcXg6ap0v4QgD/prince-of-persia-the-lost-crown-mobile-accessibility-spotlight) | A equipa descreve ajustes de tamanho, posição e opacidade dos controlos, predefinições e assistência opcional para adaptar ações complexas ao toque. | Reduzir a competição visual entre controlos e jogo. Não introduzir automatismos de combate sem uma decisão própria. |
| [Apple — Game controls](https://developer.apple.com/design/human-interface-guidelines/game-controls) e [WWDC24 — Design advanced games for Apple platforms](https://developer.apple.com/videos/play/wwdc2024/10085/) | O desenho deve considerar entradas, alcance e adaptação ao dispositivo. A orientação de toque usa pontos, incluindo a referência de 44 × 44 pt. | Manter uma área de acerto maior que o círculo visível e avaliar o resultado no ecrã final. Um ponto iOS não é automaticamente um píxel do canvas Godot. |
| [Xbox Accessibility Guideline 101 — Text display](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/101) | Legibilidade depende de dimensão efetivamente desenhada, espaçamento, forma e contexto de leitura, incluindo ecrãs pequenos. | Compensar a redução da HUD e impedir a segunda redução da fonte; distinguir texto principal e secundário. O mínimo técnico do projeto não é uma certificação de acessibilidade. |
| [XAG 102 — Contrast](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/102) | A informação precisa de contraste suficiente com o fundo, que num jogo varia continuamente. | Cartões escuros com opacidade alta, texto claro e uma borda discreta; os botões mantêm fundo legível sobre vegetação. |
| [XAG 107 — Input](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/107) | Diferentes capacidades e dispositivos beneficiam de opções de entrada e alternativas a gestos exigentes. | Preservar as opções existentes e a consistência entre dispositivos. A revisão não altera a decisão explícita Q-193 de manter CORRER premido. |
| [Godot — Size and anchors](https://docs.godotengine.org/en/stable/tutorials/ui/size_and_anchors.html) | A geometria de Control deve responder ao espaço disponível e às dimensões mínimas. | Separar cálculo de retângulos, dados e desenho; medir a altura real dos rótulos em vez de adivinhar o número de linhas. |

Estas fontes orientam a solução; não provam que uma disposição seja confortável em todas
as mãos. Não foram copiadas imagens, fontes comerciais ou elementos gráficos destes jogos.

## Hierarquia aplicada

| Prioridade | Informação | Comportamento |
| --- | --- | --- |
| Imediata | Moedas e capacidade | Cartão compacto no canto superior esquerdo, sem zeros artificiais. |
| Imediata | Dia e fase | Relógio legível e progresso discreto; a estação fica na segunda linha. |
| Combate móvel | Flechas | Substituem temporariamente a estação na segunda linha quando o corpo conduzido usa aljava. |
| Orientação | Objetivo | Cartão à direita; em ecrãs estreitos passa para o contexto quando este está livre. |
| Local | Ação, custo e consequência | Painel contextual que cresce com o texto; nenhuma consequência cortada por uma altura fixa. |
| Transitória | Recolhas, recusas e pistas sonoras | Avisos abaixo do contexto; legendas abaixo do último painel visível. |
| Consulta | Tropas, soldo, sede, nobres, ânimo, archotes e sementes | «Estado do reino» na pausa, sem avanço da simulação; Voltar devolve o foco ao botão de origem. |

A camada de controlos mantém as ações conhecidas. Moeda e ataque ocupam a fila inferior;
interação e habilidade ficam acima; corrida e impulsos ficam do lado interior. A pausa tem
o seu espaço no cabeçalho. O espelho para canhotos mantém a pausa no mesmo canto.
O nome do ataque acompanha o corpo controlado e os aros mantêm o estado de recarga.

## Legibilidade e comportamento responsivo

O desenho usa os mesmos retângulos que o posicionamento dos rótulos. O objetivo deixa de
ter uma moldura afastada do texto. O cartão cresce quando uma tradução precisa de mais
linhas; o contexto desce com ele. A largura máxima impede que uma frase curta produza
uma caixa exagerada num monitor largo.

A fonte da HUD é uma cópia da fonte já disponível no motor, com sobreamostragem explícita
para a escala compensada da interface. Corrige as letras desfocadas verificadas na primeira
captura a 844 × 390. A renderização da pixel art não muda. Os rótulos dos botões deixam de
usar palavras inteiras em maiúsculas; o destaque da interação passa a aro estável.

O estado da sede distingue ausência de fundação de destruição. A ajuda do toque passa a
explicar a corrida mantida, corrigindo o texto antigo que ainda descrevia um interruptor.
São correções de informação e apresentação; o motor de combate e os gestos permanecem iguais.

## Provas reproduzíveis

`tests/hud_layout_test.gd` cobre os cartões em larguras de 568 a 1600, o contexto variável,
o espaço da pausa e a área dos controlos. `tests/hud_readout_test.gd` cobre dados PT/EN,
sede por fundar/destruída, alternância toque/teclado, pausa e foco, janela estreita,
objetivo longo, aljava e separação das legendas. As suites existentes de toque verificam
também acerto, duas mãos, escalas, FIXAR e corrida.

`tools/captura_hud.tscn` instancia a cena real, escolhe um monarca e guarda PNG e JSON com
dimensões e linhas visíveis. Exemplo, com um servidor gráfico disponível:

```sh
godot --path . --audio-driver Dummy --resolution 844x390 \
  --rendering-method gl_compatibility tools/captura_hud.tscn -- \
  --novo --semente 20261006 --touch true --output build/hud/mobile.png
```

Parâmetros adicionais: `--locale en`, `--left true`, `--monarch archer_emperor`,
`--captions true` e `--overview true`. Os ficheiros produzidos são provas locais em `build/`.
A revisão visual inclui 844 × 390, 667 × 375 com mão esquerda e inglês, desktop 1280 × 720,
monarca arqueiro, pistas sonoras e o estado do reino na pausa.

Os portões obrigatórios são `make portoes` e `./run_tests.sh`; o CI mantém ainda exportação
Linux/Windows/Web, arranque web, idiomas, teclado, toque e silhueta noturna. A medição de
contraste por paleta e os testes de retângulos não substituem uma sessão num iPhone real.
Ficam para essa sessão o conforto prolongado, a legibilidade exterior, os recortes do ecrã
e a interação com as barras do Safari. Não se declara essa validação física como realizada.

## UX-06 — a HUD conta pontos, e não píxeis (06/10/2026)

A captura do dono num iPhone mostrou a HUD de UX-05 a um terço do tamanho desenhado. A causa
era uma conta só: a escala da interface dividia pelos píxeis da janela, e o browser do
telemóvel dá três píxeis por ponto (`devicePixelRatio`). Num iPhone deitado a janela tem
2532 × 1170 píxeis, a escala dava 1,0 e cada unidade de 1280 × 720 ficava com 0,54 pontos:
a letra de 14 lia-se a 7,6 pontos e os botões tinham 41 pontos de diâmetro.

`HudLayout.zoom()` passa a dividir pela densidade do ecrã (`DisplayServer.screen_get_scale()`)
e a pedir, no toque, 1,15 pontos por unidade. Todos os painéis usam esta mesma conta: a
faixa, o contexto, a dica, os avisos, as legendas, a pausa, a escolha do monarca, o painel
de combate e os botões de toque (estes até ao teto da `TouchLayout`). O rótulo de cada botão
encolhe pelo raio dele, para caber dentro do círculo. As letras escritas no mundo (o nome das
provisões, o alcance de uma torre) crescem com `WorldText`, até 1,6 ×.

Uma captura a 844 × 390 com densidade 1 é o que o iPhone passa a mostrar a 2532 × 1170 com
densidade 3; `tests/hud_layout_test.gd` prova a igualdade das duas contas. Num desktop a
densidade é 1 e nada muda; num Mac com ecrã Retina a janela grande continua a 1,0.

Revisão antes do merge (06/10/2026). Com a escala nova, dois efeitos ficaram à vista e estão
corrigidos. O tamanho dos controlos escolhido nas opções voltava a não contar no telemóvel:
a densidade empurrava qualquer escolha para o máximo. Agora a densidade cresce os botões até
`TouchLayout.TETO` e a escolha multiplica isso, até `TouchLayout.MAXIMO`. O contexto, os
avisos e as legendas desciam por cima dos botões; no toque, um texto que fosse descer por
cima de um controlo estreita para o x livre entre os controlos dos dois lados que lhe chegam
à altura (`HudLayout.fit_label()`), mas nunca abaixo de `HudLayout.MIN_BAND`: um painel de
uma letra por linha é pior do que tapar o topo de um botão. Um painel que passaria o fundo do
ecrã sobe até caber. Nos tamanhos normais, em 640 × 360, 667 × 375 canhoto, 844 × 390 e
1024 × 768, nada tapa os botões; só com o tamanho máximo dos controlos num ecrã estreito o
texto volta a ficar largo.
