# ADR 0047 — O toque é o quarto dispositivo

- Estado: aceite
- Data: 2026-10-02
- Secção do dossiê: §24, §26, §61
- Complementa: ADR 0024, ADR 0040, ADR 0045

## Contexto
O §24 escreve o mapa de comando para teclado, rato e comando, e diz-se *comando primeiro*. O jogo publica-se no
browser (ADR 0024, 0025), e quem lá chegava num telemóvel lia na casca que não havia controlos por toque — o relatório
Kingdom deixou isso como P3 (`docs/recovery/ANALISE-KINGDOM-2026-09-29.md`). O dono, a 02/10/2026: *«implemente a
jogabilidade por dispositivos mobile, no navegador também, com touchscreen e todo o necessário, isso deve ser bem feito
e elaborado»*.

O que a pesquisa trouxe, e o que se mediu no Godot 4.7.2 antes de escrever código:

- **O Kingdom no telemóvel** (Classic, New Lands, Two Crowns) joga-se só com gestos: arrastar para andar, arrastar até
  ao fim para correr, tocar ou deslizar para baixo para largar a moeda, um ✕ no canto para o menu. Funciona porque o
  Kingdom tem um verbo. O Empire tem sete gestos de jogo, e dois deles são contínuos (largar em contínuo, atacar à
  cadência da arma, ADR 0045).
- **O motor**: cada toque chega, por esta ordem, como um `InputEventMouseButton` emulado (`device == -1`,
  `DEVICE_ID_EMULATION`) e como um `InputEventScreenTouch`. Um `Control` com `MOUSE_FILTER_STOP` debaixo do dedo consome
  os dois; fora dele, os dois chegam ao `_unhandled_input`. Um `InputEventAction` metido por `Input.parse_input_event`
  só muda o estado da acção no frame seguinte. Na Web, o motor chama `preventDefault()` nos eventos de toque.
- **O `attack` tem o botão esquerdo do rato** (ADR 0045). Com o rato emulado, cada toque no ecrã era um ataque.
- **Os browsers**: no iPhone não há Fullscreen API para um canvas nem `screen.orientation.lock`; no Android o Chrome só
  tranca a orientação em ecrã inteiro, e só a partir de um gesto. O Safari ignora `user-scalable=no`; o que trava o
  zoom e o menu de toque longo é o CSS (`touch-action`, `-webkit-touch-callout`).
- **Ergonomia**: o polegar mora nos cantos de baixo; um alvo de toque não deve ficar abaixo dos 44 pt (Apple) ou 48 dp
  (Material); a alavanca flutuante — que nasce onde o polegar pousa — erra menos do que uma fixa.

## Decisão
**O toque é o quarto dispositivo do §26 (`Glyphs.Device.TOUCH`), e produz as mesmas acções do InputMap que o teclado e o
comando. O `InputRouter` e o `CombatInput` continuam a ser os únicos que fazem delas intenções (§61).**

- **À esquerda, a alavanca**: flutuante e só horizontal. Nasce onde o polegar pousa e o sítio onde pousou é o centro;
  arrastar até ao fim corre (`king_run`) — o *«drag all the way»* do Kingdom. Se o dedo passa da borda, a base vai atrás
  dele, e voltar para o outro lado custa só o caminho de volta.
- **À direita, os botões**, num arco à volta do polegar: MOEDA, o maior (tocar larga uma; manter larga em contínuo, ao
  `coin_drop_repeat_s`); ATAQUE (manter repete à cadência da arma); INTERAGIR (o Verbo 2), que brilha quando o guia diz
  que ali há alguma coisa a fazer com ele; a habilidade da classe; e IMPULSOS, a roda do rei: manter, arrastar para o
  segmento e largar — o gesto do stick do §24, com os segmentos desenhados à volta do dedo.
- **A pausa** num botão no canto de cima à direita, por baixo do painel de combate.
- **O resto do ecrã é mundo**: arrastar espreita (a câmara livre do §24, que volta sozinha em 2 s quando o dedo sai
  — desde o UX-03, só com a alavanca fixa: ver a adenda);
  tocar aponta a habilidade de quem mira — o Arqueiro marca, o Bardo encanta —, como o botão direito do rato.
- **Um rato emulado do toque não é um rato.** O ataque, a câmara na margem e os glifos ignoram-no. Os menus (pausa,
  escolha de classe, viagem) continuam a recebê-lo: é por ele que se tocam, e não se desliga a emulação.
- **Quando aparecem**: com o primeiro toque, e somem com a primeira tecla ou botão de comando, como os glifos do GB-15.
  Começam à vista quando o ecrã é táctil e não há comando ligado. Com a pausa, a escolha de classe, a viagem ou a
  derrota, escondem-se e largam tudo o que estava premido.
- **Opções**, num separador *Toque* da pausa: o tamanho dos controlos (80 a 140%), canhoto (espelha os lados) e
  vibração (só o Android a tem no browser). São preferências da §45, em `user://settings.cfg`.
- **No telemóvel**: a casca arranca com um toque, e esse gesto é o que destrava o som, pede o ecrã inteiro e, no
  Android, tranca a horizontal. Com o telemóvel ao alto, ou ao sair da aplicação, o jogo pausa; a casca pede para o
  virar.
- Os números da ergonomia (raios, zona morta, onde começa a corrida) são tolerâncias do gesto, como o `RODA_ZONA` do
  `InputRouter` e o *deadzone* do `project.godot` — não são balanceamento, e vivem em constantes da `TouchLayout`.

## Alternativas consideradas
- **Só gestos, como o Kingdom no telemóvel.** Com sete gestos, dois contínuos, tocar no ecrã largava moedas e atacava
  sem querer; e o Kingdom não tem ataque nem roda.
- **O `TouchScreenButton` do motor.** Precisa de texturas, e `art/` não se toca daqui (regra 9); não faz a alavanca
  flutuante nem o arrastar da roda; e não se testa sem árvore (ADR 0009).
- **Desligar `emulate_mouse_from_touch`.** Os menus, que são `Control` do motor, deixavam de responder ao toque.
- **Mudar o aspecto para `expand` no telemóvel**, para usar as barras laterais. Muda quanto mundo se vê, que a ADR 0001
  limita e ainda não fechou: fica a pergunta Q-188.

## Consequências
- A simulação não sabe que há toque, e a regra do §61 continua inteira: a mesma semente e as mesmas intenções dão a
  mesma partida, venham elas de um polegar ou de uma tecla.
- Uma acção de jogo nova no InputMap precisa de um gesto na `TouchLayout`, ou fica sem toque — o `tests/toque_test.gd`
  confere que cada acção do mapa do §24 tem um.
- No toque, o rodapé de teclas do HUD esconde-se: os botões dizem o que fazem. Os glifos (contexto, combate, diário,
  ajuda da pausa) dizem os nomes dos botões no ecrã.
- Fica de fora: remapear o toque, botões em posições livres, gestos de dois dedos, instalar como aplicação (PWA) e o
  aspecto no telemóvel (Q-188).
- Reverter é tirar o nó `Toque` da `game.tscn` e o `Device.TOUCH` dos glifos; o filtro do rato emulado fica, porque
  sem ele um toque volta a ser um ataque.

## Adenda — UX-03 (02/10/2026): a alavanca solta, o FIXAR e o ecrã inteiro
O dono jogou isto num iPhone e pediu: *«a câmera está andando demais só por eu mover o personagem, o arrastar a tela
está entrando em conflito com o andar, o arrastar a tela no mobile só funciona se a pessoa clicar num botão para fixar
o analogico de andar»*, e *«no menu é possível tirar da tela cheia»*. A alavanca só nascia num canto (42% × 60% do
ecrã): um polegar que pousava um pouco acima ou mais ao centro era um arrastar no mundo, e a câmara fugia.
- **Solta (por omissão)**: a alavanca é a metade do ecrã do lado do polegar, abaixo do HUD de cima, e nasce onde ele
  pousa; os botões e a pausa ganham-lhe. Arrastar nunca mexe a câmara; tocar no mundo continua a apontar.
- **Fixa**: o botão FIXAR, por cima da alavanca, prende-a no sítio; o centro passa a ser o da base, e pousar ao lado
  dela já anda. Só aí arrastar o resto do ecrã espreita, como na decisão acima. É a preferência `touch_fixed` (§45),
  também no separador *Toque*.
- **O ecrã inteiro** é o da página, pedido pela casca (`window.empireEcra`), e a pausa tem o botão para entrar e sair
  (`ScreenRow`, `WebScreen`). O iPhone não o dá a uma página em browser nenhum — o Chrome dele é o mesmo WebKit, que só
  põe vídeos em ecrã inteiro —, e lá a pausa e o ecrã de arranque dizem o caminho: Adicionar ao ecrã principal.
