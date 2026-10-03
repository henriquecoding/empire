# ADR 0054 — O refinamento de 03/10/2026: espaço entre obras, fôlego e som

- **Estado:** aceite, reversível (03/10/2026)
- **Contexto:** o dono pediu *«Quero que refine bastante a gameplay, pesquise intensamente para isso na web, as
  construções devem ter um pequeno espaço também, estão muito juntas uma da outras»*. Mediu-se a região: das 29 obras
  da superfície, nove pares ficavam a 16 px ou menos um do outro, e dois colados (a 0 px: o canteiro de fora contra a
  estacaria de dentro, a cozinha contra o castelo-árvore). A pesquisa (Kingdom Two Crowns, Thronefall, guias de *game
  feel*, queixas de jogadores no Steam) apontou três lacunas que este jogo tem e que se fecham sem mudar uma decisão
  do dono: as obras coladas, o fôlego que só recupera a andar, e o silêncio — o jogo não toca um único som.

## Decisão

- **Q-207 — chão livre entre obras.** A disposição do Greybox foi refeita de dentro para fora com 24 px livres entre
  duas obras vizinhas da mesma faixa (e entre as estátuas enterradas e as obras). A ordem de tudo é a mesma; o que
  estava dentro de um muro continua dentro dele. Os muros passam de ±600/±1300 para ±680/±1408, as passagens de ±950
  para ±1040, a bifurcação de 1800 para 1904, e o resto acompanha (`Greybox`, `Campfires`, `Wards`, `BowRacks`,
  `Stables`, `Cavities`, `secrets.csv`). O `tests/obras_com_folga_test.gd` conta a folga, para que nenhuma obra nova
  volte a colar. As tocas da caça (`HuntWatch.SITIOS`) também saem de cima das obras: a leste não sobra chão, e os
  coelhos de lá passam para o pé do castelo-árvore (como o do §25); a árvore e o lago ficam a oeste.
- **Q-208 — parado, o fôlego volta depressa.** Andar recupera-o em `king_run_refill_s` (10 s), como estava; parado,
  em `king_run_rest_refill_s` (4 s, proposto). É a montaria do Kingdom a pastar, e responde à queixa mais comum ao
  fôlego do Kingdom: atravessar a própria base cansado. A decisão da Q-193 (só corre premido, cansa, o evoluído aguenta
  mais) não muda.
- **Q-209 — os sons provisórios.** O `AGENTS.md` não deixa tocar em `audio/`, e as gravações não existem. Como o
  `PaintedArt` fez para a arte (ADR 0051), o `SynthSfx` sintetiza em código, de senos e ruído, as 22 pistas da folha de
  pistas que têm sinal na §46 — as moedas, o sino da alvorada, o aviso do crepúsculo, a noite, os golpes, as mortes, as
  obras, o muro a romper, a coroa. O `SfxDirector` ouve o `EventBus` e toca-as com o volume, a variação de tom, o máximo
  de vozes e a distância à câmara da folha (`SfxCues`, conferido pelo `tests/som_test.gd`). A moeda que entra numa
  obra sobe de tom a cada moeda, até a obra ficar paga (a última é a do `build_started`). Uma pista pedida antes de
  estar feita passa à frente no aquecimento e toca quando fica pronta, se ainda for a tempo (o sino da 1.ª alvorada). Os sons fazem-se aos bocados por frame (a web não tem fios),
  as moedas primeiro. Liga-se e desliga-se nas opções (`Preferences.SOUND`, ligado). Sem dependências novas: é o
  `AudioStreamWAV` do motor. Quando uma gravação chegar a `audio/`, toma o lugar da pista sintetizada.

## Fica para o dono (abertas no `QUESTIONS.md`)

- **Q-210** — reparar sem micro-gestão: o que foi tocado de noite e não caiu repara-se sozinho de madrugada.
- **Q-211** — o alcance da torre à vista quando o monarca está ao pé dela.
- **Q-212** — o "bem alimentado": quem enche o fôlego parado corre mais tempo na corrida seguinte.

## Consequências

- O mapa de casa estica-se 80 a 100 px por lado até ao muro de fora; o fim da região (±1920) não muda.
- O CI não ouve: os testes conferem a folha, as receitas (duração, pico, fim em silêncio, sem sorteio), o tom da moeda,
  a distância e o máximo de vozes, e que o sino toca pelo sinal.
- Os números novos (`king_run_rest_refill_s`) ficam no `_proposed` até o dono os aprovar no painel.
