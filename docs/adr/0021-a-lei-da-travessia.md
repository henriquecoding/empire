# ADR 0021 — A lei da travessia manda na velocidade, e não ao contrário

- Estado: aceite
- Data: 2026-09-16
- Secção do dossiê: §12, §19, §21, §44

## Contexto
O §21 escreve a largura de uma região com uma ordem explícita: *"não fixes isto pela largura da tela onde
desenhaste — **deriva-o do tempo de travessia**: a pé (§12) uma região deve levar **40–60 s** a atravessar de ponta
a ponta"*. É a única lei do dossiê que liga a geometria do mundo ao tempo de quem lá anda.

O greybox monta a região que o §21 descreve — seis ecrãs de 640 px (§47 `SEGMENT_WIDTH`), **3840 px** — e toda a
`units.csv` andava a **26 px/s**. São **148 segundos** de ponta a ponta, com um dia inteiro a durar 360 s
(`clock.csv`): quase metade de um dia a andar em linha reta, só de ida. A lei pedia 40–60 s e o jogo entregava 148.

Os 26 px/s nunca foram uma decisão sobre nenhuma tropa em particular: são o **valor por omissão do campo**
(§19 e §44 escrevem os dois `@export var move_speed: float = 26.0`), e ele ficou copiado em 17 das 22 linhas da
`units.csv`. O `_src` da linha `vagrant` dizia-o com todas as letras — "§19/§44 move_speed 26". Nenhuma tabela do
dossiê dá velocidade a uma tropa; a tabela do §07 que o `tools/check_dossie_vs_csv.py` confere dá velocidade às
**criaturas**, e só a elas.

A segunda metade do §21 — *"o que a 26 px/s dá 1000–1560 px por ecrã"* — é aritmética da leitura contrária (40–60 s
por **ecrã**, e não por região) e não se aguenta com o resto da secção: uma região de 1040–1560 px não são
"4 a 6 ecrãs" de 640 px nem "oito segmentos por região". Ver a Q-082.

## Decisão
**A velocidade a pé deriva da lei da travessia, e não do valor por omissão do campo.** Uma pessoa a pé anda a
**80 px/s** — 3840 px em 48 s, o meio do intervalo do §21. O resto da coluna `move_speed` da `units.csv` sobe pelo
mesmo factor (80/26), para que as relações autoradas sobrevivam intactas: a libélula continua a ser 1,9× uma
pessoa (152), o aríete de contrapeso continua a ser 0,62× (49).

A `creatures.csv` **não se toca**. As velocidades das criaturas estão na tabela do §07, são conferidas contra o
dossiê pelo `make dossie-numeros`, e são o relógio da noite — mexer-lhes mudava quando a mancha chega ao muro, que
é o que os testes de design do §66 e do §78 medem.

## Alternativas consideradas
**Encolher a região até 26 px/s dar 40–60 s.** Dava 1040–1560 px, e o §21 fixa o segmento em 640 px (§47) e a
região em 4 a 6 deles. A região passaria a ter dois segmentos e meio: contradiz a secção que a lei vem de lá
dentro. Rejeitada.

**Mexer só no monarca.** Resolvia a queixa do jogador e partia a comitiva: o `follow()` do §25 põe cada recruta num
lugar atrás do rei, e com um passo três vezes mais lento nenhum desses lugares chega a ser ocupado — a comitiva
virava um rasto que só se juntava com o rei parado. Rejeitada por ser meia correcção.

**Aplicar um multiplicador na apresentação** (câmara com zoom, mundo desenhado a metade). Mudava o que se vê e não
o que se simula: a moeda continuaria a cair a 12 px de raio de apanha num mundo que parece o dobro, e a distância a
que um vagabundo repara numa moeda (120 px) deixaria de significar o que significa no ecrã. Rejeitada por separar a
simulação da imagem, que é o contrário do §45.

## Consequências
A região atravessa-se em 48 s a pé, e o cavalo de tracção do §12 (×1,7) leva-a a 28 s — a montaria passa a ser a
dádiva que o §12 descreve em vez da correcção de um defeito. As tropas passam a chegar ao posto dentro da fase em
que lhes é dado (o crepúsculo dura 30 s, e 26 px/s não atravessavam sequer um ecrã nesse tempo).

As pessoas passam a andar mais depressa do que as criaturas (68–152 px/s contra 14–44). Não mexe no §07: o combate
resolve-se em postos, o lanceiro tem `no_pursuit`, o arqueiro dispara a 200 px e nenhuma tropa persegue nada — o
`combat_system` não escreve um único `set_target_x`. O que muda é reposicionar, fugir e seguir, e os três melhoram.

**O que a `make vistoria` passou a mostrar, e não é um defeito do jogo.** O piloto de mentira da vistoria
(`tools/autopilot.gd`, que o cabeçalho dele abre a dizer que *"NÃO joga bem de propósito"*) perde o
castelo-árvore ao **dia 2** onde antes perdia ao **dia 3**. A razão mede-se e é a mudança a funcionar: o piloto
recruta três pessoas, não constrói nada que publique posto nenhum, e vai-se embora — a 600 px de casa às duas
noites, antes e depois. A diferença é que a 26 px/s a comitiva **não o alcançava** e ficava a meio caminho, por
acaso em cima do castelo; a 80 px/s ela chega mesmo ao lugar que o `follow()` do §25 lhe dá, atrás do rei, e o
castelo fica sem ninguém. Os três que o seguem seguem-no porque **não têm posto** — o `RecruitSystem.follow()`
só pega em quem está desempregado —, e quem não tem posto é assim porque o piloto não levantou uma torre.

A primeira medição desta ADR dizia mais do que isto: dizia que a noite 1 passava a custar 596 de vida ao
castelo e duas das três tropas. Isso era outra coisa, e está corrigido — era o monarca a ficar **preso em
FIGHT** (Q-085), a tanque com um bicho ao lado em vez de recuar. Com o §24 a valer (*"Mover — Sempre"*), a
noite 1 volta a fechar com o castelo aos 1000 e as três tropas de pé, e o que sobra é a noite 2.

Nenhum teste de design mudou de resultado: os 406 casos da suíte dão o mesmo — 397 a passar e os 9 saltados de
sempre —, o F1-16 continua a fechar as duas metades, e a varredura de nove defesas por dez dias do §66 não mexe.
A vistoria ganhou por isso uma coluna nova — a distância do rei ao núcleo —, porque sem ela uma noite perdida
por má jogada e uma noite perdida por defeito do *tick* leem-se iguais na tabela.

Passa a ser proibido alargar a região ou abrandar o passo sem que `tests/travessia_test.gd` o veja: a lei do §21
está lá escrita e chumba dos dois lados. Reverter isto obriga a reescrever esse teste e devolve 148 s de travessia.
