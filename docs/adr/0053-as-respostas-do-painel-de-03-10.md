# ADR 0053 — As respostas do painel de 02 e 03/10/2026

- **Estado:** aceite, em curso (03/10/2026)
- **Contexto:** o dono respondeu no painel às Q-183 a Q-206 — as questões abertas pelas ADR 0044 a 0052 (as três
  escolhas, o combate direto, o subsolo delimitado, o toque, a noite, as moedas, o CORRER e os monarcas). Cinco foram
  adiadas (Q-081, Q-112, Q-147, Q-191, Q-194). O `AGENTS.md` manda aplicar o que foi decidido pela opção mais simples e
  reversível; o que é mecânica nova grande passa a ticket, com as palavras do dono como contrato (D).

## Decisão — aplicado neste lote (QP-02)

- **Q-185 — o golpe de perto atinge tudo o que alcança.** Quem não dispara (`MeleeSweep.melee`: sem aljava e sem a tag
  `ranged`) fere todas as criaturas da faixa dele, do lado do golpe, até ao alcance da arma — a tropa de IA e o
  monarca que se conduz. A criatura pequena que sobrevive recua `melee_knockback_px` (12 px) para longe de quem bateu,
  até ao `scale_tier` `melee_knockback_max_tier` (2: Rastejante, Alado, Cavador); as grandes ficam onde estão. A
  distância, um alvo por flecha; a perfuração do Arqueiro evoluído continua a dela. O empurrão é da simulação, depois
  do dano, e reproduz-se com a semente. A apresentação (ADR 0045, Q-185 de 02/10) não muda.
- **Q-190 — a lareira do núcleo afasta, e custa.** Ao crepúsculo come `hearth_night_cost` (5) da bolsa do monarca que
  reina; paga, arde até à alvorada, alumia e faz recuar, a `hearth_radius_px` (240) do núcleo, quem tem até
  `hearth_repel_mass` (8, um Rastejante), e abranda os outros a `hearth_rot_slow` (0,25). Sem as 5, fica apagada nessa
  noite: não alumia nem afasta (`Hearth`, `DarkWatch.wards`, `LightField`).
- **Q-192 — a moeda com o dobro do tamanho.** A moeda, a pilha, o saco e a coroa no chão passam a pixeis de 4
  (`CoinArt.CHAO`): a moeda de 18 para 36 px, a coroa de 30 para 60. A física fica como estava; o preço do HUD
  (`PriceTag`) continua nos pixeis de 2.
- **Q-193 — correr só premido, com fôlego.** No toque, o CORRER corre só enquanto um dedo o segura, como o Shift; a
  alavanca até ao fim já não corre. A pé, quem se conduz corre `king_run_stamina_s` (8 s) com o fôlego cheio; esgotado,
  fica cansado e anda até o recuperar todo em `king_run_refill_s` (10 s). O monarca evoluído corre
  `king_run_evolved_mult` (1,5×) mais tempo. Montado, o cavalo galopa como antes (`Stamina`, `MonarchWatch.runs`). O
  CORRER do toque apaga-se enquanto se está cansado.
- **Q-188 — no telemóvel, o mundo enche o ecrã.** Com o toque, o canvas alarga-se até 1,25× o 16:9 (ADR 0001): um 20:9
  enche-se todo; com teclado ou comando, o 16:9 de sempre (`WideTouch`).
- **Q-200 — o escudeiro dá 6 flechas por moeda.** `arrows_per_coin:6` no `ability_params` do `quiver_squire`; a banca
  do arco continua a dar 12 às tropas. Os outros números da aljava ficam aprovados.
- **Q-198, Q-199, Q-201 — os números aprovados.** Saem do `_proposed`: os números de bancada da Nia e do Imperador
  Arqueiro (vida, dano, intervalo, alcance, passo; a aljava e o sangramento), e os preços e limites do Bardo. O
  sangramento continua só do Imperador Arqueiro.
- **Fechadas sem código:** Q-183 (*«já há um novo sistema definido»* — a ADR 0052 substituiu as três classes), Q-184
  (*«por mim está bem como fez»*), Q-187 (o princípio: no telemóvel tudo o que há no computador, adaptado — fica como
  regra do UN-28), Q-189 (*«agora está como queria»*).

## Decisão — passa a tickets

- **Q-196, Q-197, Q-202 — o herdeiro é a chave da troca (UN-32).** O herdeiro é neutro até estar pronto; custa a
  manutenção mais alta do jogo e, por pagar, desaparece e paga-se de novo; pronto, o jogador vai onde ele treinou e
  escolhe um dos imperadores desbloqueados, e o ciclo do herdeiro recomeça. Começa com os bónus reduzidos e
  recupera-os em 5 noites. Em solo nunca há duas coroas soberanas. Muda o UN-07 (feito com a proposta antiga) e o
  UN-17 (a troca deixa de ser presencial entre dois imperadores vivos).
- **Q-195, Q-197, Q-206 — o roster (UN-16).** Os imperadores encontrados desbloqueiam-se para a campanha e para o
  recomeço do zero; o que cai sem reinar e não é levado ao Santuário pelo ritual sai da campanha, e volta só num
  recomeço do zero.
- **Q-205 — o quarto imperador (UN-33).** Grande, de armadura completa, obscuro e de passado triste; sentado no chão
  recupera vida e faz crescer vegetação; a escudeira dança para o alegrar e dá força a ele e às tropas; evoluída,
  abranda os inimigos, que ficam a admirá-la. As outras linhas da Q-205 ficam como propostas.
- **Q-200 — o escudeiro evoluído dispara (UN-34).** Na evolução, o escudeiro do Arqueiro também ataca com flechas.
- **Q-186 — o baú da sala secreta (QP-03).** O imperador guarda lá o excedente; quem invade pode roubá-lo; o do
  jogador começa vazio, e os outros impérios da campanha têm sempre alguma coisa.
- **Q-203, Q-204 — aprovadas.** As propostas do Diplomata universal (UN-18 a UN-21) e dos dois multiplayer (UN-29 a
  UN-31) deixam de ser P.

## Consequências

- Os números novos — `king_run_*`, `melee_knockback_*`, `hearth_*` — estão no `_proposed`: a regra é do dono, o
  número é proposta de bancada, e afina-se no CSV sem tocar em código.
- Nada muda no save: o fôlego e a lareira acesa são da noite e do passo, e o save grava-se de dia (§62).
- O painel só passa estas respostas a «aplicada» depois de merge e publicação.

## Como desfazer

- Q-185: `melee_knockback_px` a 0 tira o empurrão; `MeleeSweep.hits` a devolver `[alvo]` tira o varrimento.
- Q-190: `hearth_night_cost` a 0 acende sempre; `hearth_repel_mass` e `hearth_rot_slow` a 0 tiram o efeito.
- Q-192: `CoinArt.CHAO` a 2.0.
- Q-193: `king_run_stamina_s` a 0 tira o limite; o `TouchPad.running` volta a interruptor no `lift`.
- Q-188: `WideTouch.LIMITE` a 1.0.
