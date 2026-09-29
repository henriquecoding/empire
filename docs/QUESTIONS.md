# Perguntas em aberto

> O destino que o `AGENTS.md` manda usar quando a especificação não cobre um caso: **"escreve a pergunta aqui; não
> decidas tu."** Esta primeira leva saiu de transformar a prosa do dossiê em dados, testes e ficheiros que correm —
> é exatamente o tipo de contradição que *"uma tabela esconde e um gráfico apanha em cinco segundos"* (§06).
>
> Formato: o que diverge, onde, a proposta, o que bloqueia e quem decide. **Abertas** esperam por ti; **resolvidas
> na v5.2** estão aplicadas e documentadas, e podes revertê-las.

## Abertas — abertas pelas respostas do painel (29/09/2026)

### Q-157 · A noite fica exponencialmente mais difícil — a partir de que noite?
- **Onde:** Q-151, §74, §66; `mass_growth` e `growth_from_night` em `rot.csv`.
- **O que pediste:** *«mais brando até a noite 5, depois conforme os dias passam se torna mais difícil
  exponencialmente»*.
- **O que foi feito:** as primeiras cinco noites continuam brandas; da 6 à 10 a massa sobe pela fórmula da §74
  (+18 por noite); a partir da 11 multiplica-se por 1,06 a cada noite — à noite 20 pesa 1,8 vezes, à 30 pesa 3,2.
- **Porque não começa na 6:** medido, com o crescimento logo a seguir à noite 5, qualquer ritmo a partir de 2% por
  noite derruba no dia 10 a defesa que o §66 manda aguentar dez noites — e o §66 é o portão da Fase 1.
- **Proposta:** fica assim, a crescer a partir da noite 11. As alternativas são começar na 6 com um ritmo mais
  baixo e mexer no §66, ou mudar a defesa de referência do §66.
- **Decide:** tu.

### Q-158 · A Colheita Forçada devolve menos do que custa
- **Onde:** Q-145, §15 (os impulsos), ADR 0028 (o preço cresce com a produção); `impulses.csv`,
  `tests/colheita_forcada_test.gd`.
- **O que é:** um impulso do rei: paga-se, e nesse dia a produção rende 1,8 vezes — mas no dia seguinte as
  plantações param.
- **O que se mediu:** com as condições reais — a ganância leva a parte dela, o preço é o do dia e o impulso só
  pesa nas fases que faltam —, no *greybox* de três fontes (canteiro, galinheiro, pesqueiro) cada moeda paga
  devolve **0,83**, em qualquer dia, porque o ganho e o preço crescem ao mesmo ritmo. Nunca compensa. O teste que
  pede que compense nalgum dia está saltado com esta pergunta.
- **Proposta:** baixar o preço base de 4 para 3 (devolve perto de 1,1 com três fontes, e mais com mais fontes). As
  alternativas são subir o que ela rende (`benefit_value`), ou deixá-la como impulso de aflição: moedas já, com
  perda.
- **Decide:** tu.

### Q-159 · A marcha no lugar da travessia (ADR 0035) — confirma
- **Onde:** Q-135 (aprovada: o Verbo 2 na bifurcação acaba a região, e o rei leva a comitiva), Q-146 (*«o rei
  nunca sai para longe do reino, quem vai para longe do reino é as classes jogáveis»*), Q-103, Q-154; ADR 0035,
  `Realm`, `March`, `VassalSystem`.
- **O que foi feito:** as duas respostas não cabiam juntas, e ficou a mais recente e a mais específica: o rei fica.
  O Verbo 2 na bifurcação, de dia e a partir do dia 11, manda uma **marcha** — quem é teu e está perto do rei, até
  ao teto do barco do New Lands (3 construtores, 4 de longo alcance, 3 de corpo a corpo), com pelo menos 3 —
  conquistar o povo seguinte da campanha. Saem nessa noite (o reino fica desguarnecido, §13) e voltam na alvorada;
  o povo passa a vassalo (Q-103), com o tributo e as Sementes. Com todos os povos vassalos, a campanha acaba, e o
  epílogo da §79 conta os vassalos como povos que ficaram.
- **O que muda com isto:** as regiões seguintes já não se jogam com o rei lá dentro — conquistam-se de longe. Hoje a
  marcha ganha sempre que leva três ou mais: o preço é a noite sem eles. As classes jogáveis a ir para longe (a tua
  frase) esperam por trocar de classe (§08), que ainda não existe: por agora vai quem é teu.
- **Proposta:** fica assim. Se a conquista deve poder falhar (e quantos voltam), é a parte a decidir a seguir.
- **Decide:** tu.

### Q-160 · O prato das ofertas: de que largura? (a Q-098, em palavras simples)
- **Onde:** §75; `offer_plate_px` em `rot.csv`.
- **O que é o prato:** quando a Podridão te faz uma oferta, à noite, põe no chão um alguidar de barro — o «prato».
  Aceitas largando lá dentro o que ela pede; se não largares nada até o tempo acabar, é uma recusa.
- **A dúvida:** o dossiê diz que o prato tem *«o tamanho de um slot de construção»*, mas os sítios de construção têm
  larguras diferentes. A largura decide quão perto do prato o rei tem de estar para a moeda contar. Hoje são
  **96 px**: a largura de um canteiro, o sítio de construção mais comum.
- **Proposta:** ficam os 96 px, e o *playtest* diz se é preciso alargar.
- **Decide:** tu, ou o *playtest*.

### Q-161 · A árvore velha do início conta para a noite? (a Q-104, em palavras simples)
- **Onde:** §83 (o minuto 0:00), §74, §25 (*«a noite 1 é ganha de certeza»*); `AmargueiroSystem.Fate.OLD`.
- **O que é:** quando o jogo começa, já há uma árvore amarga (um Amargueiro) de pé, perto da estacaria da esquerda.
  Os Amargueiros de pé tornam cada noite mais forte: +22 de massa cada um.
- **A dúvida:** se esta árvore contasse, a primeira noite — que o §25 diz que tem de ser ganha de certeza — ficava
  mais forte do que o dossiê manda. Por isso está como **paisagem de antes de ti**: não conta para a noite, não se
  corta e não se consagra.
- **Proposta:** fica como paisagem. A alternativa é contar desde o início e poder cortar-se, como as outras — e a
  primeira noite fica mais difícil.
- **Decide:** tu.

### Q-162 · O arqueiro, o bardo e o diplomata jogáveis têm corpo de tropa
- **Onde:** Q-097 (*«os personagens jogáveis são maiores que tropas e o rei é maior que os personagens
  jogáveis»*), §08 (trocar de classe é o Verbo 2 sobre uma tropa da classe), §22, `units.csv`.
- **O que está:** o Trepador e os dois cavaleiros só existem como personagens jogáveis, e ficaram na escala 3. O
  arqueiro, o bardo e o diplomata são ao mesmo tempo tropa (ou ofício) e o corpo da classe jogável — e ficaram na
  escala 2, a de tropa.
- **Proposta:** cada uma destas três classes ganha um corpo jogável próprio, na escala 3, que é o que assumes com o
  Verbo 2; a tropa do mesmo nome fica na 2. Custa três corpos de arte a mais por povo. A alternativa é aceitar a
  excepção: estas três jogam-se do tamanho de tropa.
- **Decide:** tu.

### Q-163 · O que cada armazenamento leva além do archote
- **Onde:** Q-153, §08, `storages.csv`, `docs/art/ASSET_BIBLE.md`.
- **O que está:** cada personagem jogável tem o seu armazenamento, desenhado na camada `Equipments`, e hoje todos
  levam só archotes — de 1 a 4. As moedas vão no saco do corpo. O archote é o único item que o jogo já tem para
  levar.
- **Proposta:** cada tipo ganha o item da classe quando o sistema dela existir: a aljava, flechas de marca (hoje o
  arqueiro marca sem limite); o alforge do bardo, as canções que encantam; o cinto de escalada, a corda para subir
  sem escada; os alforges, a ração do cavalo; a pasta, os tratados do §14. Os tetos ficam em `storages.csv`, como
  os archotes.
- **Decide:** tu.

## Abertas — balanceamento e design

### Q-006 · Quem atinge a faixa aérea? — **fechada pelo F1-07**
- **Onde:** §07 (Libélula: "só atacável por arqueiros e torres altas"; Alado: "obriga a torre alta") e §10.
- **O que divergia:** se os arqueiros atingem a faixa aérea, o Alado não obriga a nada.
- **Decisão — a proposta, tal como estava escrita:** o `targets_bands` diz o que a unidade **pode** apontar; a
  faixa dela própria chega sempre; qualquer outra só com um posto que lhe dê altura — o `hits_aerial` do
  `effect_params`, que hoje só a `high_tower` tem. Está em `src/sim/systems/posts.gd` e tem três testes.
- **É uma mudança de comportamento:** antes disto um arqueiro no chão abatia o Alado.

## Abertas — abertas ao implementar o anexo §85

### Q-062 · Os portões mediam com um motor e o CI media com outro
- **Onde:** `ferramentas/verificar-dossie.mjs` e `ferramentas/verificar-novo.mjs`, em cada `goto`.
- **O que acontecia:** os dois abriam a página com `waitUntil: "load"` e uma espera fixa de 900 ms. O evento
  `load` **não** garante que as fontes da rede já foram aplicadas: com `display=swap` a página desenha-se com a
  de recurso e troca quando o ficheiro chega. Numa máquina fria isso acontece *a meio da medição*.
- **Como apareceu:** a corrida **#16** chumbou com duas falhas — «320px · "dia 11" fora do desenho» e
  «carregar num item leva à #s40 (desvio −4376px)» — que passavam em todo o lado.
- **O que a investigação encontrou, e é o mais importante:** neste ambiente as fontes **nunca** carregam. O
  Chromium do Playwright recusa o certificado do proxy (`net::ERR_CERT_AUTHORITY_INVALID`) e
  `document.fonts.size` é **0**. Ou seja: todas as corridas locais destes portões mediram uma página com
  tipos de letra de recurso, diferente da que o *runner* mede. Com o certificado ignorado à força, a medição
  local passou a dar **118 intactas · 5 a deslizar** — exactamente os números do *runner*, contra as 120 · 3
  de antes. Um portão de disposição cuja resposta depende de a rede ter chegado não é um portão.
- **A barreira entrou, e NÃO chegou.** Pôs-se `await página.evaluate(() => document.fonts.ready)` a seguir a
  cada `goto`, nos dois ficheiros. A corrida **#17** chumbou nas mesmas duas. A hipótese das fontes explicava
  a diferença de medição — e explica — mas **não** é a causa destas duas falhas. A barreira fica porque medir
  depois de as fontes assentarem é certo de qualquer maneira; não fica como correcção.
- **O que os números dizem agora:** o desvio mudou de **−4376 px** (#16) para **−4688 px** (#17). Não é uma
  diferença fixa de disposição: **varia entre corridas**. E as duas verificações que chumbam são as duas que
  medem depois de uma espera FIXA — `waitForTimeout(900)` a seguir ao clique, e a remedição a 320px. As
  vizinhas que esperam por uma condição («saltar para #s40 numa parte fechada: abriu=true, desvio 0px»)
  passam sempre, no mesmo ficheiro e na mesma corrida.
- **A causa, finalmente medida: era a VERSÃO DO MOTOR.** Os portões escolhiam o Chromium pela ordem errada —
  primeiro um caminho fixo (`chromium-1194`), e só se esse faltasse é que perguntavam ao Playwright. Nesta
  máquina o caminho fixo existe, no *runner* não: eu media com o **1194** e o CI media com o **1243**, em
  silêncio, durante três corridas. E a diferença não é cosmética. O salto do item da bandeja é **animado**, e
  no 1243 a animação demora quase o dobro:

  | motor | o salto assenta aos | o portão lia aos | resultado |
  |---|---|---|---|
  | 1194 (esta máquina) | **814 ms** | 900 ms fixos | passava, por 86 ms |
  | 1243 (o *runner*) | **1613 ms** | 900 ms fixos | lia a meio da animação |

- **Reproduzida.** Com o portão **antigo** e o motor do *runner*, a falha sai igual nesta máquina:
  `FALHA carregar num item leva à #s40 (desvio −4331px)` — e numa segunda corrida **−4639 px**. Varia aqui
  como varia lá (−4376, −4688), porque ler a meio de uma animação dá o sítio por onde a página ia passar. A
  série medida de 100 em 100 ms mostra-o inteiro:
  `113ms:−52409 · 213ms:−45372 · 313ms:−33967 · 413ms:−20681 · 514ms:−9275 · 614ms:−2236 · 714ms:0`.
  Os números do *runner* caem exactamente dentro desta curva.
- **Corrigido:** (1) pergunta-se ao Playwright PRIMEIRO qual é o Chromium, nos dois ficheiros — o caminho fixo
  passa a recurso e não a preferência, e esta máquina passa a medir com o motor do CI; (2) a verificação do
  item da bandeja espera até ESTABILIZAR — lê de 100 em 100 ms e só decide quando duas leituras seguidas
  coincidem, com tecto de 6 s e um piso de 400 ms (antes disso, duas leituras iguais são a página *parada* e
  não a página *assente*). O que se afirma não mudou; mudou quando se lê.
- **A segunda falha (o gráfico a 320px) era consequência da primeira — e eu tinha escrito aqui que não era.**
  A medição que me levou a isso foi feita nesta máquina: quando o gráfico se mede, a página já parou
  (`scrollY 38913 → 38913`). Só que esse «já parou» é do **1194**, onde a animação acaba aos 814 ms; no
  *runner*, onde acaba aos 1712 ms, o salto ainda ia a meio enquanto as verificações do simulador corriam, e o
  gráfico media-se sobre uma página em movimento. Corrigida a espera, a corrida **#19** passou as duas, e mais
  um número mudou de sítio com elas: os blocos de código a deslizar a 1280px passaram de **4** para **5**, que
  é o que esta máquina sempre mediu. Refutar uma hipótese com uma medição feita no ambiente errado é o mesmo
  erro das fontes, outra vez — e por isso fica escrito.
- **O que se fez em vez de adivinhar:** os portões passam a dizer com que números chumbam. Cada `FALHA` leva
  agora o detalhe — qual das quatro condições falhou e as caixas de cada rótulo — e cada corrida abre a
  declarar **que página mediu**: `motor: 153.0.8010.12 (…)` e `tipos de letra: 38 faces · loaded 10`. Uma
  destas duas linhas teria poupado as três corridas.
- **Fechada pela corrida #19:** os cinco *jobs* verdes, e as duas linhas que chumbavam a dizer
  `carregar num item leva à #s40 (desvio 0px, assente aos 1712ms)` e
  `320px · viewBox 246 · «dia 11» dentro do desenho`. Os 1712 ms do *runner* contra a espera fixa de 900 ms
  são a medida do que estava errado.
- **O que fica por decidir:** se o dossiê deve depender de uma CDN para a sua própria verificação. Continua a
  valer, e agora com mais provas: sem a CDN são **120 intactas · 3 a deslizar**, com ela **118 · 5**; uma face
  pode falhar sozinha (`IBM Plex Mono 500` deu `error` numa das medições) e só ela muda a contagem dos blocos
  de código; e os caracteres de desenho de caixa caem sempre para o tipo monoespaçado *da máquina*, que o
  *runner* tem e esta não. Embutir as fontes no ficheiro construído tornava o portão igual em qualquer máquina
  e sem rede. **Decide:** tu.

## Abertas — abertas ao encher o tick e a montar a cena de jogo

### Q-076 · O jogo não se podia perder: nada mordia o castelo-árvore — **fechada pelo F1-16**
- **Onde:** o §10 escreve a regra mais curta do dossiê — *"se o castelo-árvore cair, cai a partida"* — e ela
  estava implementada dos dois lados: o `BuildSystem.fallen()` sabia responder e o `src/world/game.gd` parava
  o relógio. O que não existia era o caminho pelo meio: **nada lhe tirava vida**.
- **A causa, e era de uma linha:** só o `WallData` tinha `contact_slots` (`walls.csv`, 2 a 7 pelos cinco
  degraus do §10). O `BuildingData` não tinha essa coluna, e por isso o `BuildSlot.contacts` de tudo o que não
  é muro ficava vazio e o `contact_slots()` devolvia **zero**. A `ContactQueue` do §50 reparte *N* atacantes
  por *N* slots; com zero slots não atribuía nenhum, o `target_slots` ficava em `NENHUM`, o `engaged()` dava
  falso, e o `CombatSystem._criaturas_batem()` saltava a criatura. **Só o muro podia ser atacado** — e era por
  isso que só o muro caía.
- **Decisão — a proposta, tal como estava escrita:** `contact_slots` passa a ser coluna do `buildings.csv`,
  como a que o `walls.csv` já tinha. Não inventa mecânica nenhuma, usa a fila do §50 que já existe, e uma obra
  com a coluna a zero comporta-se exactamente como antes — que é o caso de **todas** menos uma.
- **O número, e porque é que ele não decide nada:** o núcleo leva **7**, que é o topo da escada do §10 — o
  Bastião, a outra obra *única por império*; o núcleo é a maior do mapa (480 px) e a última. O dossiê não dá
  este número, e por isso ele está marcado em `_proposed` e a escolha é revertível. **E a varredura mostra que
  ela não muda o critério do §66**: com 2, 3, 4, 5 ou 7, as mesmas defesas aguentam e as mesmas caem. A única
  linha que se mexe é a muralha de ferro nos dois flancos, que a 2 slots aguenta com **5%** de núcleo — o fio
  da navalha que a escolha de 7 evita.
- **O que isto passou a medir** (`godot --headless --path . scenes/tests/dez_dias.tscn`, nove defesas, dez
  dias cada, com um Bastião só — o §10 escreve-o *"único por império"*):

  | esq | dir | torre | alta | arq | aguentou | núcleo |
  |---|---|---|---|---|---|---|
  | 1 | 1 | não | não | 6 | caiu no dia **3** | 0,00 |
  | 4 | 4 | sim | sim | 12 | caiu no dia 10 | 0,00 |
  | 5 | 4 | sim | não | 12 | caiu no dia 9 | 0,00 |
  | 5 | 4 | não | sim | 12 | caiu no dia 9 | 0,00 |
  | 5 | 4 | sim | sim | 6 | caiu no dia 9 | 0,00 |
  | 5 | 4 | sim | sim | 12 | **aguentou** | **1,00** |

  A primeira linha é a receita do §07 tal e qual. A última é a defesa do décimo dia, e é a única que aguenta:
  o §66 tem as duas metades que pede.
- **Onde:** `data/source/buildings.csv`, `src/sim/data/building_data.gd`, `src/world/greybox.gd`,
  `tests/support/closed_region.gd`. Os testes são o `tests/dez_dias_test.gd`, e nenhum deles está saltado.

### Q-077 · O Alado atravessa a muralha, pousa no castelo e não faz nada
- **Onde:** o §07 dá ao Alado a linha *"Dia 4 — obriga a torre alta"*, e o §10 vende a torre alta por 30
  moedas para *"atingir a camada aérea"*. Medido no cenário dos dez dias, os dias 4, 5 e 6 — que são os dele —
  **não custam nada a ninguém**.
- **A causa:** para uma criatura AÉREA nenhuma obra de superfície é barreira. O `BuildSystem.barrier()` filtra
  por faixa (`vaga.band != faixa`), e por isso o Alado nunca encontra muro nem núcleo no caminho: só olha para
  tropas, dentro dos seus 24 px de alcance. Atravessa a muralha, atravessa a região, pousa no castelo — e o
  castelo perde **0%**. Medido numa noite posta de propósito sem muro nenhum: os Alados do dia 5 chegam a
  **0 px** do núcleo.
- **O que a torre alta vale hoje, então:** os **dois postos** que publica, com precisão 1,0 — e não a altura.
  A varredura dos dez dias mostra-o: tirar a torre alta à defesa que aguenta faz cair a partida no dia 9, e
  faz cair pela mesma razão que tirar a torre de arqueiros faria. Não é a faixa aérea que ela está a defender.
- **Proposta:** ou a `barrier()` deixa de filtrar por faixa para quem voa — e aí um Alado bate no que estiver
  por baixo —, ou o `targets_bands` do §44 passa a valer também para obras, e a faixa da obra entra na conta
  como já entra a da tropa. A segunda usa uma coluna que já existe e não inventa regra nenhuma; a primeira é
  menos escrita e mais surpresa.
- **Bloqueia:** a linha *"obriga a torre alta"* do §07, e com ela metade do valor da torre de 30 moedas. Não
  bloqueia o F1-16: o critério do §66 mede-se e passa sem ela, e passaria com mais margem contra.
- **Não é a Q-075, e as duas encostam:** a Q-075 deu regra ao alcance vertical de uma criatura sobre as
  **tropas** — e para o Alado a resposta é que ele bate no chão de onde está, porque não pode mudar de
  faixa. Esta é sobre as **obras**, e o caminho é outro: quem filtra por faixa é o `BuildSystem.barrier()`,
  e ele não sabe nada de `targets_bands`.
- **Decide:** tu. É a segunda metade da Q-076, tal como ela estava escrita antes de o F1-16 a fechar, e é
  do F1-09 — o ticket do Alado e do Cavador.
- **Fechada (AUD-04, 26/09):** nem uma nem outra — o Alado passa a roubar galinhas, e a torre alta a proteger
  uma coisa concreta. Ver a Q-129.

### Q-081 · A derrota é de quem tem a cena aberta, e isso é deliberado
- **Onde:** §10 (*"se o castelo-árvore cair, cai a partida"*), §45 (o estado autoritativo),
  `src/world/game.gd`, `tools/vistoria.gd`.
- **O que a `make vistoria` mostrou:** quem pára a partida é a `game.gd` — um **nó** —, e por isso a regra só
  vale com a cena aberta. Uma ferramenta que chame `SimLoop.step()` a mão continua a correr dias sobre um
  castelo-árvore em ruína, e foi o que a vistoria fez: **sete dias**.
- **A correcção óbvia está errada, e experimentei-a.** Pôr o `step()` a parar sozinho quando o núcleo cai
  chumbou **três** instrumentos do próprio repositório, e pela mesma razão: eles existem para MEDIR uma
  derrota. O §66 varre nove defesas por dez dias e a coluna que interessa é *"em que dia caiu"*; o
  `jogo_noite_test` quer ver o amanhecer a seguir a uma noite que o *greybox* perde (Q-068). Um `step()` que
  pára tira-lhes o que eles vieram contar. **Quem joga tem cena; quem mede, não** — e a linha fica onde está.
- **O que mudou:** nada na simulação. A vistoria passou a perguntar pelo `builds.fallen()` e a dizer em que
  dia o castelo caiu, que era o que faltava — o instrumento é que estava a medir uma partida acabada.
- **O que continua por decidir:** o §46 **não tem sinal de derrota** e inventar um quebrava a regra 7 do
  `AGENTS.md`. O §16 (ressurreição até ao amanhecer) e o §15 (sucessão) não existem, e por isso a derrota é um
  fim seco: o relógio pára e é preciso reabrir o jogo.
- **Decide:** tu. A pergunta é se a derrota ganha sinal próprio na §46 quando o §15 e o §16 chegarem — e é aí
  que um `step()` que pára deixa de tirar nada a ninguém, porque passa a haver o que ouvir.

### Q-088 · A derrota do §16 é «decay em vez de reset», e o *greybox* não tem decay
- **Onde:** §16 (*"Ao cair, o jogador mantém: Sementes Reais, classes desbloqueadas, mapas revelados, segredos
  encontrados, e 40% das estruturas do império principal... o decay resolve isso melhor do que qualquer sistema
  de save"*), §10, `src/world/game.gd`, `src/ui/pause_menu.gd`.
- **O que foi feito (GB-16):** com o castelo-árvore caído, o ecrã diz *"A coroa caiu"* e oferece *"Novo jogo"*,
  que recomeça do zero **sem** retomar o autosave. É a leitura mais simples do §16 que existe hoje: nada do
  que o decay guarda existe ainda (não há Sementes, classes, mapas nem segredos), e guardar 40% das obras é uma
  mecânica que o §16 descreve e ninguém implementou.
- **O que se encontrou, e não se mudou:** **fechar e reabrir** o jogo depois de uma derrota retoma o autosave
  mais recente — o da alvorada anterior, com o castelo de pé —, porque o `_retomar()` só recusa um save cujo
  núcleo já caiu. Isso é exactamente *"um save que se recarrega"*, que o §16 recusa. Não se mexeu: o fluxo é o
  da ADR 0005 e da Q-081, e fechá-lo é decidir o que um save guarda depois de uma derrota.
- **Decide:** tu, quando houver decay. As duas perguntas: o que o *"Novo jogo"* herda da partida perdida, e se
  um autosave anterior à derrota continua a poder ser retomado.
- **Fechada (AUD-05, 26/09):** herda o legado do §16 e os autosaves da partida perdida apagam-se. Ver a Q-134.

### Q-112 · A decisão do circuito 2: como se "aponta um ofício a um edifício"
- **Onde:** §06 (*"a decisão de conversão faz-se apontando um ofício a um edifício, que é o Verbo 1 com outro
  alvo"*), §49 (o algoritmo), `crafts.csv`, `buildings.csv` (celeiro, salga, curral).
- **O que foi feito (reversível, `ConversionSystem`):** o algoritmo do §49 à letra — com a casa de pé, a matéria
  dos produtores dela é consumida (`cost` por conversão) e dá moeda ×`coin_multiplier` **ou** a capacidade.
  O gesto: **uma moeda largada na casa troca o modo**; para capacidade só se tiveres o ofício vivo (o
  cozinheiro, para o grão), e sem ele a casa volta a vender. A capacidade corre enquanto houver o ofício e um
  produtor da matéria de pé ("duration 0 = recalculada a cada fase"). Ligadas: `troop_health` e `troop_speed`
  (vida máxima e passo das tuas tropas, a partir do perfil). As outras três (`combat_dish`,
  `wall_and_tower_cost`, `weapon_level`) aparecem no painel mas ainda não têm efeito.
- **O greybox:** a segunda Casa de Treino (a `training_house` é única por império) passa a **cozinha**, e há um
  **celeiro fora do muro de fora** — pôr a render é mandar o cozinheiro ao sítio arriscado (§21). A arte é a
  autoral recuperada: `storehouse` para as casas de conversão, `workshop` para a cozinha e a forja.
- **Em aberto:** as carroças do §06 (a matéria não se transporta hoje: a casa consome à distância); se trocar
  de modo deve custar a moeda; e onde fica o celeiro num segmento autorado.
- **Decide:** tu.

## Decididas pelo dono no painel (29/09/2026)

> As 66 respostas que o dono guardou no painel (`/painel/`, ADR 0026) e que um agente aplicou a 29/09/2026 (ADR 0036).
> As 32 que estavam abertas vêm para aqui; as 34 das duas auditorias (Q-115 a Q-149) ficam onde estavam, com a
> decisão do dono por cima. Cada entrada abre com a decisão e o que se mudou, e mantém por baixo o que estava
> escrito, para se ver de onde veio. São reversíveis como as outras. Onde uma resposta deixou uma parte por decidir,
> ou pediu uma pergunta mais clara, a parte está nas Q-157 a Q-163. A Q-081, a Q-112 e a Q-147 foram adiadas no
> painel e continuam onde estavam.

### Q-087 · O rato na margem não tem largura no dossiê
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «tamanho do ecra» — a margem do rato deixa de ser um
  número de píxeis e passa a ser uma fracção da largura do ecrã: `edge_pan_frac` 0,0125 no `camera.csv` (16 px a
  1280, 24 px a 1920), lida pelo `CameraRig.edge()`. `tests/camera_rig_test.gd`.
- **Onde:** §24 (*"Câmara livre — Stick direito — Q · Z **ou rato na margem**"*), `data/source/camera.csv`,
  `src/world/camera_rig.gd`.
- **O que foi feito (GB-12):** o rato a menos de `edge_pan_px` da borda do ecrã empurra a câmara livre, que
  volta sozinha nos 2 s do §24. Com o rato fora da janela, ou a janela sem foco, não empurra — sem isso um rato
  que saía pela borda deixava lá a última posição, e a câmara ia-se embora sozinha.
- **O número que não está no dossiê:** a largura da margem. Fica `edge_pan_px = 16` px de ecrã, marcado em
  `_proposed` ao lado dos outros quatro da Q-057: 1/80 dos 1280, a faixa que se acerta sem olhar em ecrã
  inteiro e que o rato atravessa sem parar a caminho do botão direito. Zero desliga.
- **Decide:** o primeiro *playtest*. Em janela a margem é mais difícil de acertar; se for preciso, isto sobe —
  e o risco oposto é o rato a caminho de marcar um bicho perto da borda levar a câmara com ele.

### Q-089 · A cascata do amanhecer é simulação, e o dossiê não diz a ordem
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Sim, a dispersão é em cascata e gradual, não se
  demora tanto, mas deve ser feita de forma suave» — fica a leitura da GB-21, que era esta: cada tropa sai do posto
  quando a frente de luz da alvorada lhe chega (900 px/s, `dawn_sweep_px_s`), e nove tropas saem entre 1,97 s e 2,33
  s — em cascata, curta, e sem saltos, porque a frente é contínua.
- **Onde:** §24 (*"Amanhecer — sino + varrimento de luz da esquerda para a direita a 900 px/s + as tropas a
  saírem dos postos em cascata, não todas ao mesmo tempo"*), §43 (passo 3), `src/sim/systems/job_board.gd`.
- **O que foi feito (GB-17):** o varrimento, que é apresentação: uma frente de luz da cor da alvorada do
  `clock.csv` atravessa a região a 900 px/s.
- **O que ficou de fora:** a cascata. O `jobs.assign()` do passo 3 dá o alvo do dia a toda a gente no mesmo
  tick; o fatiamento da §52 espalha as **decisões** por seis ticks (0,2 s), mas o alvo já está escrito e toda a
  gente arranca junta. Uma cascata muda **quando** cada tropa recebe o alvo — é simulação, tem de ser
  determinista, e entra no save.
- **A leitura mais natural, e não decidida:** a mesma linha do §24 põe as duas coisas lado a lado, e por isso a
  cascata pode seguir a frente de luz — uma tropa sai do posto quando a luz lhe chega, `x / 900` s depois do
  `dawn_broke`. É um número que o dossiê já tem, e liga o que se vê ao que acontece.
- **Implementado depois, e reversível (GB-21):** foi esta a leitura. Na alvorada, quem tem posto e está à
  direita da frente espera por ela; a frente é o relógio vezes `dawn_sweep_px_s` (clock.csv, 900, do §24) e
  não guarda estado. Medido: nove tropas que arrancavam todas aos 0,03 s passam a sair de 1,97 s a 2,33 s.
  Nenhum teste de design mudou de resultado e a vistoria dá a mesma tabela. Para desligar: `dawn_sweep_px_s`
  a zero, que desliga também a luz.
- **Decide:** tu, se a ordem é esta — a da luz — ou outra.

### Q-090 · O `settings.cfg` da §45 grava-se como o save, e não como `ConfigFile`
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** fica como está: o caminho da §45 com o formato da
  ADR 0007, e o G6 a guardá-lo.
- **Onde:** §45 (*"Câmara — preferência de sessão, não estado de jogo. Vai para `user://settings.cfg`"*), §26,
  ADR 0007, `src/core/preferences.gd`, `tools/lint_rules.gd`.
- **O que diverge:** a §45 dá o caminho e não o formato, e a extensão `.cfg` sugere o `ConfigFile` do motor. O
  `ConfigFile` desserializa `Object(...)` e `Resource(...)` — a mesma porta que a ADR 0007 fecha no save: um
  ficheiro de preferências partilhado *"para desligar o tremor"* podia trazer um *script*.
- **O que foi decidido, e é reversível (GB-13):** o caminho é o da §45 e o formato é o da ADR 0007 — um
  dicionário de tipos base com `store_var(_, false)`, lido com `get_var(false)` e validado campo a campo; uma
  chave desconhecida ou um tipo errado ignoram-se. O portão G6 passa a guardar os dois ficheiros, e proíbe
  também o `ConfigFile` neles.
- **O custo:** o ficheiro deixa de se poder editar à mão num editor de texto. Se isso for querido, a ADR 0007
  já lista a alternativa segura — JSON — e a troca fica num ficheiro só.
- **Decide:** tu.

### Q-091 · A duração do dia entrou no save sem `save_version` novo
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Como está escrito gere todo esse sistema para que
  seja bem feito e faça sentido.» — o save passa a ter migrações a sério (`SaveMigrations`,
  `src/core/save_migrations.gd`): uma por versão, corridas por ordem ao ler (`SaveService`), sobre dicionários de
  tipos base (nunca instanciam objectos, ADR 0007), cada uma a escrever o que a versão acrescentou com o valor que dá
  o jogo antigo. Um save de uma versão futura não se toca (§62). A v2 leva a duração do dia (GB-24), as tocas da caça
  (Q-106), o reino e os vassalos (Q-103), a escolha da sucessão (Q-146), o escudeiro (Q-114), quem desertou (Q-144) e
  os archotes no cinto do rei (Q-153). `tests/save_migrations_test.gd`.
- **Onde:** §26 (*"slider de duração do dia (240–540 s)"*), §62 e ADR 0007 (*"save_version desde a 1, com uma
  migração por alteração, no mesmo commit"*), `src/sim/state/game_state.gd`, `src/core/save_service.gd`.
- **O que foi feito (GB-24):** o `GameState` ganhou `day_seconds`, e o `from_dict` já é *"campos em falta ficam
  no valor por omissão"*. Zero quer dizer *"a do clock.csv"* — e é exactamente o que um save de antes disto
  tinha, porque o slider não existia. Por isso um save antigo carrega igual, sem migração nenhuma.
- **O que diverge:** a ADR 0007 pede uma migração por alteração, e isto é uma alteração sem migração nem versão
  nova. Nenhuma das colecções acrescentadas desde o F1-14 subiu a versão, e o `SaveService` não tem ainda
  código de migração nenhum — mas a regra está escrita.
- **Decide:** tu. Subir para 2 com uma migração que só escreve o zero, ou escrever na ADR que um campo novo
  cujo omissão é o comportamento antigo não precisa de versão.

### Q-092 · As legendas de som vêm desligadas, e o jogo ainda não tem som
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** ficam desligadas por omissão e ligam-se na pausa;
  3 s por legenda, até três de uma vez.
- **Onde:** §26 (*"Legendas para pistas sonoras... Fazer. Substitui o áudio para surdos."*),
  `docs/audio/AUDIO_CUE_SHEET.csv`, `src/ui/captions.gd`, `src/core/preferences.gd`.
- **O que foi decidido (GB-22):** desligadas por omissão, e ligam-se na pausa. É o costume de uma opção de
  acessibilidade, e a matriz de QA (A8) testa-as *"com OPT_CAPTIONS ligado"*.
- **O que isso custa hoje:** não há som nenhum gravado (73 pistas escritas, zero gravadas), e por isso, com as
  legendas desligadas, o sino da alvorada e o aviso do crepúsculo não chegam a ninguém de maneira nenhuma. Até
  haver som, ligá-las por omissão seria defensável.
- **O número que não está no dossiê:** 3 s por legenda, e até três de uma vez. É o tempo de ler uma linha
  curta.
- **Decide:** tu.

### Q-093 · O §26 pede contraste e daltonismo, e não diz com que gama nem com que algoritmo
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** ficam o contraste de 75% a 150%, o daltonismo por
  correcção (Machado 2009 e Fidaner 2005) e o limiar de 90% do A4/A15.
- **Onde:** §26 (*"Controlos de contraste — um shader de saturação/contraste global"*; *"Modos para daltonismo —
  a paleta é quente/fria, boa base. Testa a Podridão contra o terreno em protanopia"*), `docs/qa/ACCESSIBILITY_MATRIX.md`
  (A3, A4, A15), `src/world/accessibility_filter.gd`, `shaders/accessibility.gdshader`.
- **O que foi decidido, e é reversível (GB-25, GB-26):**
  - **contraste de 75% a 150%**, em passos de 5%. Abaixo de 75% a noite castanha da §80 fecha-se num tom só;
    acima de 150% o meio-dia queima. Um slider só: a saturação que o §26 junta ao contraste fica por fazer;
  - **daltonismo por correcção**, e não por simulação: a simulação é a de Machado, Oliveira e Fernandes (2009),
    com severidade total, e a correcção é a de Fidaner, Lin e Ozguven (2005), que leva o que o olho perde para os
    canais que ele ainda separa. As matrizes são publicadas e estão no `AccessibilityFilter`;
  - **o limiar do teste A4/A15**: com o modo ligado, quem tem a deficiência tem de manter 90% da separação
    mancha–chão que um olho sem ela vê. Medido: 116% em protanopia, 117% em deuteranopia, 95% em tritanopia.
- **Decide:** tu, com um *playtest* com jogadores daltónicos, que é o único que responde a isto.

### Q-094 · A base do Amargueiro não tem largura
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Isso será definido pela arte, quando estiver pronta»
  — os 32 px ficam como marcador, em `_proposed`, até a arte do Amargueiro dar a largura do tronco (ART-01).
- **Onde:** §74 (*"largar moedas na base"*), §55 (a moeda cai *numa* obra quando cai dentro da meia largura
  dela), `data/source/rot.csv`.
- **O que falta:** o corte é um slot de destino no BuildSystem, e um slot precisa de largura — é ela que diz
  se uma moeda caiu na árvore ou ao lado, e quem está lá a serrar. O dossiê não a escreve.
- **O que foi feito, e é reversível:** `amargueiro_base_px = 32`, marcado em `_proposed` — a largura do barril
  de fogo, a obra mais estreita de `buildings.csv`. Um tronco é mais estreito do que uma casa e mais largo do
  que uma pessoa.
- **Decide:** o playtest — se largar seis moedas numa árvore obrigar a acertar, sobe.

### Q-095 · Consagrar pede uma Semente Real, e a Semente Real ainda não se larga
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Gere todo esse sistema.» — a Semente Real passa a
  ter o ciclo inteiro. **Ganha-se** na câmara atrás da passagem (`root_chamber`), ao conquistar um povo pela marcha
  (Q-103, `vassal_seeds` 1 a 3) e na oferta que a dá (Q-099, `seed_royal`), sempre com o `seed_royal_gained` da §46.
  **Gasta-se** a consagrar um Amargueiro (§74) e a evoluir a classe (§08). **Vê-se** no painel (`SEMENTES n`,
  `HUD_SEEDS`) e **fica** no legado da derrota e na travessia (§16).
- **Onde:** §74 (*"Consagrar — largar 1 Semente Real na base"*), §15, §57 (CrownSystem), §61 (Verbo 1).
- **O que falta:** o Verbo 1 hoje larga moedas e só moedas. A Semente Real existe como número nos dados
  (`class_data.gd`, `economy_curve.gd`) e como sinal no catálogo (`seed_royal_gained`), mas não há inventário
  de sementes nem gesto para largar uma.
- **O que foi feito:** o destino está inteiro no `AmargueiroSystem.consecrate()` — vira Marco, sai da massa,
  protege 120 px de raízes novas, e a mancha abranda 40% sobre ele (testado pela `NightWatch`). O que não
  existe é quem o chame. Liga-se no dia em que a semente for uma coisa que sai da mão.
- **Bloqueia:** o "Feito" do XIII-03 fica parcial por isto. **Decide:** o calendário — é o CrownSystem da
  Fase 2, e não uma decisão de design.
- **Ligado depois (junção com o ramo `dossie-implementation-ymfkjl`):** a Semente passa a existir e a sair
  da mão. `GameState.royal_seeds`; a primeira vem da câmara atrás da passagem (`root_chamber` em
  `secrets.csv`, o minuto 11:00 do §25), que o rei acha ao entrar (`SecretSites`). E o gesto é o Verbo 1:
  largar em cima de uma árvore de pé com uma Semente no império chama o `consecrate()` e a moeda volta ao
  saco — *a moeda que largas é que decide*, e aqui decide a Semente. Sem Semente, cai a moeda. O inventário
  do CrownSystem (§57) continua a ser da Fase 2; isto é o mínimo que fecha o destino.

### Q-096 · "Não é recolhida antes da alvorada" — não há gesto para recolher
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Se cria raízes nas tropas caídas e elas somem
  suavemente a seguir» — os corpos que a alvorada leva desvanecem em 1,6 s (`FADE_SECONDS`), com raízes a crescer por
  baixo deles (`UnitArtBatch._fade`). Não há gesto de recolher: a alvorada recolhe-os.
- **Onde:** §74 (*"uma tropa que morre fora das muralhas e não é recolhida antes da alvorada cria raiz"*;
  *"reutiliza inteiro o gesto que a §16 já tem para o Santuário das Raízes"*), §16.
- **O que falta:** o gesto de arrastar um corpo para dentro é do Santuário das Raízes (§16), e o Santuário
  ainda não existe. Hoje um corpo fica onde caiu.
- **O que foi feito:** a regra de onde cria raiz está inteira — dentro das muralhas não cria, no subsolo cria,
  a voadora cai para a superfície, o Marco protege o raio dele. "Dentro" é haver, do lado do corpo, um muro de
  pé cuja face de fora está mais longe do núcleo do que ele (`AmargueiroRoots`): quem morre no posto do muro
  morreu em cima dele, e não fora. Recolher entra com o §16, e só muda o x do corpo antes da alvorada.
- **Decide:** o calendário.

### Q-097 · O vagabundo tem escala 2 no units.csv e a §74 dá-lhe escala 1
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Os vagabundos tem o tamanho de tropas pois eles
  podem ser convertidos em tropas, os personagens jogáveis são maiores que tropas e o rei é maior que os personagens
  jogáveis...» — três degraus: tropa e vagabundo na escala 2, personagem jogável na 3 (o Trepador sobe de 2 para 3;
  os cavaleiros já lá estavam), o rei na 4 (64–70 px). A tabela da §22 e a regra 3 da §74 dizem-no, e o vagabundo
  deixa de ser excepção no Lenho que rende (2, como uma tropa). O arqueiro, o bardo e o diplomata jogáveis ainda
  partilham o corpo da tropa do mesmo nome: a Q-162 pergunta como se separam.
- **Onde:** §74, regra 3 (*"Escala 1 e vagabundo: 1 Lenho. Escala 2, tropa: 2"*), §22, `units.csv`
  (`vagrant,…,scale_tier 2`).
- **O que diverge:** a escala do §22 é a da figura, e um vagabundo tem o tamanho de qualquer tropa. A regra 3
  lê-se como "a carne barata rende pouco", e por isso junta o vagabundo à escala 1.
- **O que foi feito, e é reversível:** o vagabundo rende como escala 1 por exceção explícita
  (`AmargueiroRoots.VAGABUNDO`); todas as outras tropas rendem pela `scale_tier`. Uma linha a apagar, se a
  leitura for outra.
- **Decide:** tu.

### Q-098 · O prato tem "o tamanho de um slot de construção" — de qual?
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Não entendi isso, como assim o prato tem o tamanho
  de um slot de construção, não sei não o que é o prato......» — a pergunta estava mal escrita. Está reescrita em
  palavras simples na **Q-160**; até lá o prato fica com os 96 px.
- **Onde:** §75 (*"um alguidar de barro, do tamanho de um slot de construção"*), `data/source/rot.csv`.
- **O que foi feito, e é reversível:** `offer_plate_px = 96`, marcado em `_proposed` — o canteiro, o slot mais
  comum do greybox. Só conta o que cai dentro dele (a primeira das quatro regras da §75).
- **Decide:** o playtest.

### Q-099 · Das doze ofertas, só quatro têm hoje onde pegar
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Recentemente eu ditei as mudanças da candeeira,
  consultar isso e corrigir» — as ofertas passam a falar do Lume da ADR 0034 («Fica com o Lume por uma noite»; na
  §77, «o Lume fica por baixo de ti»), e oito das doze têm agora onde pegar. A moeda do rei no prato é o sim
  (`OfferPrice`); o `OfferToll` leva o resto do mundo: o treino do herdeiro volta a zero (`successor`), um Marco
  consagrado volta a ser árvore dela (`marker`), a primeira escora de pé cai e a passagem abre (`sealed_passage`), a
  evolução da classe fica presa nesta campanha (`playable_class`, `ClassSystem.locked`). E dá o que só existe fora da
  mancha: Sementes Reais (`seed_royal`), dias de ganância a zero (`greed_zero_days`) e a mancha desta noite, que é
  tua e se vai (`control_rot_tonight`). *O que enterraste* pede agora uma passagem que escoraste (`sealed>=1`). A
  pesquisa que a Q-101 pediu está em `docs/recovery/PESQUISA-OFERTAS-2026-09-29.md`. `tests/oferta_ligada_test.gd`.
- **Onde:** §75, a tabela das doze; `src/sim/systems/offer_system.gd` (`PRECOS`, `EFEITOS`).
- **O que falta:** oito preços e cinco efeitos dependem de sistemas que ainda não existem — portões (§10 não
  os tem), tesouraria, Capítulos (§77), sucessor (§15), povos (§78), classes jogáveis (§08), passagens seladas,
  e a Semente Real como coisa que se larga (Q-095).
- **O que foi feito:** uma oferta só é candidata quando o preço dela se pode pagar com o Verbo 1 **e** o efeito
  existe. Hoje: *Nada. Só quero ver.* (dia 2+, a do §83 — a revelação fica guardada para os Capítulos), *Dá-me
  o que já não anda* (dia 3+), *Diz-me um nome* (com nomeados, XIII-05) e *Devolve-me o que é meu* (com a
  Dívida em 12). As outras oito não são sorteadas — nenhuma aparece para não fazer nada. Cada sistema que chegar acrescenta a sua linha às duas listas, e a oferta entra sozinha.
- **Q-040 e Q-053 continuam por decidir por isto:** *O que brilha* e *Fica com a candeia* não são candidatas
  enquanto não houver tesouraria nem classes. O `once_per_campaign` da Q-040 já é respeitado.
- **Decide:** o calendário.

### Q-100 · O Zelador pode ser afastado — com quê?
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «O que é isso? O inimigo mais forte?, você não me
  explicou, pode ser um tipo de construção que emita algo que impessa que ele avance, e esse recurso vai diminuindo
  conforme o poder da podridão se torna mais forte [...]» — o Zelador é a figura que a Dívida da Candeia chama a
  partir de 6: anda atrás da mancha, não ataca e não morre, e se chegar ao núcleo leva uma tropa com nome. Afasta-o
  agora o **Sino de Vigia** (`tender_ward`, 8 moedas, dois sítios a ±1560 px do núcleo; `Ward`): com carga, o Zelador
  não entra no raio dele (200 px) e, se já lá estiver, é empurrado para fora. A carga enche com moedas largadas no
  sino (uma por moeda, até 6) e desce a cada alvorada, tanto mais quanto mais avançada a campanha (1 + 0,1 × dia): é
  preciso mantê-lo, e destruído repara-se como qualquer obra. Números em `_proposed`. `tests/ward_test.gd`.
- **Onde:** §75 (*"Pode ser afastado, não morto"*), `creatures.csv` (`tender`, `pushable = true`).
- **O que falta:** o dossiê não diz o gesto. Não há empurrar no jogo.
- **O que foi feito, e é reversível:** o Zelador não é uma criatura do combate (tem `max_health 0`, e no
  CreatureSystem isso é morrer no primeiro tick); anda por conta própria, nunca à frente da mancha, e um muro
  de pé pára-o — não ataca, por isso não o rompe. Com as muralhas de pé, fica a olhar para o núcleo. Afastá-lo
  entra quando houver o gesto.
- **Decide:** tu.

### Q-101 · A recusar todas as ofertas, a defesa do décimo dia cai ao dia 9
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Faça uma pesquisa e embase todo esse sistema, a
  sempre consequencias das escolhas feitas» — a pesquisa está em `docs/recovery/PESQUISA-OFERTAS-2026-09-29.md`
  (Inscryption, Darkest Dungeon, Hades, Frostpunk, Kingdom Two Crowns, Cultist Simulator). O §66 continua a medir-se
  com a voz calada, e recusar tudo deixou de ser um teste saltado: é uma regra, e o
  `test_recusar_todas_as_ofertas_tem_consequencia` prova que a mesma defesa cai. Nenhum número mudou para calar a
  medição.
- **Onde:** §66 (*"sobreviver 10 dias é possível e não é trivial"*), §75 (*"recusar custa +8 de massa por cada
  recusa das últimas cinco noites, até cinco"*), `tests/dez_dias_test.gd`.
- **O que foi medido:** a defesa que fecha a Fase 1 — Bastião, ferro, duas torres, doze arqueiros — aguenta dez
  noites com a mancha calada (a curva da §74 com recusas a zero, que é como a tabela da §74 isola o termo, e o
  que o F1-16 afinou). Com a voz ligada, o instrumento não paga nada e recusa todas as noites: o imposto chega
  aos +40 à sexta, e o núcleo cai **ao dia 9, com 6 mortes**.
- **O que foi feito:** o teste do §66 mede o que media, e diz agora que é sem a voz; o teste novo, a recusar
  sempre, está saltado com esta razão. Nenhum número de `data/` foi mexido.
- **O que está em aberto:** se o §66 deve valer para quem recusa sempre (e então o teto de +40 ou a defesa
  mudam), ou só para quem aceita alguma coisa (e então o instrumento precisa de uma política de ofertas).
- **Medido na auditoria de 26/09 (AUD-02):** o instrumento ganhou uma política — pagar as ofertas que custam
  moedas (`Campaign.pay_coin_offers`) — e a última defesa **cai ao dia 10 igual**: no cenário fechado as ofertas
  que aparecem nunca custam moedas (*Diz-me um nome* nos dias 2, 4, 7 e 9; *Dá-me o que já não anda* nos dias 3
  e 10). E o que a derruba no dia 10 são **sete Cavadores** (massa 228): a primeira ameaça que passa por baixo do
  muro, e nada no jogo lhe responde. O `dez_dias` imprime as duas corridas. A resposta é o subsolo (AUD-04), e não
  o teto das recusas.
- **Decide:** tu.

### Q-102 · Dos nove feitos, cinco têm hoje o que observar; das nove bonificações, uma
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Gosto desse sistema de moral, faça uma densa
  pesquisa e elabore algo concreto que faça sentido ao meu jogo» — a pesquisa está em
  `docs/recovery/PESQUISA-MORAL-2026-09-29.md` (RimWorld, Stronghold, Frostpunk, Mount & Blade, Total War, Darkest
  Dungeon). O **ânimo do reino** (`Spirit`, `SpiritWatch`) é feito de memórias com peso e prazo — a noite ganha, os
  mortos, os desertores, o soldo em atraso, a árvore com nome serrada (os −1 durante 2 dias do §74), os vassalos
  ganhos e perdidos —, entre 0 e 100 à volta de 50. Três estados mexem em três coisas que já existiam: abatido
  (abaixo de 35) foge com 30% mais vida, rende −10% e não chega ninguém aos acampamentos; animado (acima de 65) foge
  com 20% menos, rende +10% e chega mais um vagabundo por alvorada. O painel mostra-o (`ÂNIMO n`). Das nove
  bonificações de título ligam-se as que já têm sistema: não foge, +10% de cadência, +2 de dano contra cerco
  (`TitlePerks`). `tests/animo_test.gd`.
- **Onde:** §76, a tabela dos nove feitos; `src/sim/systems/feat_ledger.gd`, `title_system.gd`.
- **O que falta:** *Último na porta* precisa de portões (o §10 não os tem); *Trouxe os outros*, do gesto de
  arrastar corpos (§16, Q-096); *Não comeu*, de cozinha e consumo; *Voltou*, da ressurreição (§16). Até lá
  nunca se cumprem. Das bonificações, só **+1 vida máxima** tem onde pegar: *não foge*, *+10% cadência*,
  *+2 dano contra cerco*, *arrasta ao dobro*, *não entra em pânico na candeia*, *metade da comida*,
  *imune a encantamento* e *a arma sobe um nível* mexem na moral, no combate e na economia, e ficam escritas
  em `titles.csv` à espera de quem as leia.
- **Também em aberto:** *"serrá-lo tira 1 ponto de moral ao império durante 2 dias"* (§74, §76) — o moral do
  império não existe (o do §07 é por tropa). O corte de um Amargueiro nomeado já devolve o custo no evento.
- **O que foi feito:** os cinco feitos observáveis (noites em posto de cerco, Rastejantes abatidos, o golpe
  final num Aríete, sair vivo de dentro da mancha, dias com a mesma arma) e as quatro regras inteiras.
- **Decide:** o calendário.

### Q-103 · A Colheita não tem quem a comece, nem onde se decida
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Deve ser feito todo um sistema de vassalos e
  suseranos [...] O meu reino será sempre o que eu começo, os outros que assimilei podem inclusive serem conquistados
  ou consumidos pelo meu inimigo, dependendo do modo de jogo» — ADR 0035. Um povo conquistado passa a **vassalo**
  (`VassalSystem`): continua a funcionar sem ti e paga tributo a cada alvorada (os «4–6 moedas/dia para sempre» do
  §13, entregues no núcleo) e, ao ser conquistado, dá Sementes Reais (1 a 3). O teu reino é sempre o primeiro. Os
  vassalos têm força (100), e a massa da Podridão desgasta-a (0,02 por ponto de massa); a zero, o vassalo é consumido
  — e `vassals_can_fall` é a chave do modo de jogo. Com todos os povos vassalos a campanha acaba. Números em
  `_proposed`. `tests/marcha_test.gd`.
- **Onde:** §78 (*"quando tomas ou assimilas um povo"*; *"No fim da Colheita, uma decisão. Verbo 1, no núcleo
  deles"*; *"a aldeia fica fora das tuas muralhas"*), §13, §82 (os estandartes).
- **O que falta:** a conquista (§13) ainda não existe, nem há aldeias no greybox — por isso ninguém chama
  `HarvestSystem.conquer()`. E a decisão tem duas saídas para um só gesto: largar moeda no núcleo deles diz
  *que* decides, não *o quê*. O dossiê não escreve se são dois sítios (o núcleo e o marco?), duas quantias,
  ou outra coisa. Os estandartes do §82 também não têm cor por povo em `peoples.csv`.
- **O que foi feito:** o sistema inteiro — a duração (C = 6 + 2 × povos, metade por assimilação), uma de cada
  vez com fila a 100%, os 140% em Colheita e os +80% de quem ficou, perder o povo se a aldeia cair, soltar e
  ficar, os campos da §84 — e as duas ligações que já têm onde pegar: cada alvorada é um dia de Colheita, e o
  marco de cada povo que ficou pesa +22 por noite, como um Amargueiro que não se corta.
- **Decide:** tu (o gesto) e o calendário (a conquista).

### Q-104 · O Amargueiro velho do minuto 0:00, e o dia da primeira oferta
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Não entendi nada dessa pergunta, você formula de uma
  forma que não faz sentido nenhum...» — a pergunta está reescrita em palavras simples na **Q-161**. A parte da
  primeira oferta já estava fechada pela ADR 0023; a árvore velha fica como estava (não conta) até lá.
- **Onde:** §83 (a tabela dos vinte minutos e a caixa *"o que o segmento de abertura passa a ter de conter"*),
  §25 (*"a noite 1 é ganha de certeza"*), §74, `offers.csv` (`just_looking`, `min_day 2`).
- **O Amargueiro velho:** está lá desde o primeiro frame, logo a seguir à estacaria da esquerda (−750 px do
  núcleo). O §83 não diz se pesa na massa. Pesar eram +22 na noite 1 — a que tem de ser ganha de certeza —, e
  por isso **não pesa**: é cenário de antes de ti (`Fate.OLD`), não se serra e não se consagra. Reverte-se numa
  linha (`Fate.STANDING`).
- **A primeira oferta:** a primeira da campanha é sempre *"Nada. Só quero ver."*, como o §83 manda. Mas o §83
  põe-na no crepúsculo do **dia 3** (17:00) e a tabela da §75 — e o `offers.csv` — dá-lhe **dia 2+**. Com os
  dados como estão, ela fala na noite 2. **Fechado pela ADR 0023:** o §83 manda; `min_day 3` e "Dia 3+" na
  §75, e o `abertura_test` prova que a noite 2 fica calada.
- **O que falta do segmento de abertura:** o vagabundo com `head_pool` fixo é arte (ART-01: no greybox todas as
  caras são a mesma), e a bifurcação a três ecrãs para leste precisa dos Capítulos (XIII-07). A **placa** da
  bifurcação já está no segmento (`SecretSites.chapters`, a leste) e acende-se quando a primeira oferta é
  paga; o capítulo que lá cai é o da região dos Enramados no plano do XIII-07, e a placa diz-lhe o nome.
- **Decide:** tu.

### Q-105 · Nove fichas cinco a cinco não dão 126 mundos: dão 61
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «A campanha tem um lore, mas as regiões não são
  fixas, é gerada proceduralmente como é em minecraft, tornando assim a campanha sempre única» — a ordem das regiões
  passa a sair da semente (`SimFactory.campaign_regions()`): a região de casa primeiro, as outras baralhadas pela
  semente, como um mundo do Minecraft. A §77 diz agora isso, e as 61 combinações de fichas.
- **Onde:** §77 (*"nove fichas sorteadas cinco a cinco dão 126 mundos"*; *"no máximo um por região"*), §21
  (*"uma região = um povo"*), `chapters.csv` (`biome`).
- **O que diverge:** 126 é C(9,5), e só é verdade se qualquer cinco couberem juntas. Não cabem: a romaria e a
  várzea virada são as duas da várzea, o sulco cego e a ponte são as duas do desfiladeiro, e uma campanha tem uma
  região por povo — uma várzea, um desfiladeiro. As campanhas com as duas de um bioma são 65 das 126, e ficam
  **61**. O `ChapterPlan.worlds` conta-as e o `chapter_plan_test` prova que mil sementes as dão todas.
- **Proposta:** manter as regras e corrigir o número da §77 para 61. A alternativa — deixar dois capítulos no
  mesmo bioma quando a campanha tiver duas regiões dele — muda a §21 e não a §77.
- **Também por decidir:** o *"junto a acampamento de mercenários"* do mercado e o *"fortaleza"* do Cerco não
  restringem nada hoje: qualquer região tem um e outro. Se o WorldGen (§54) vier a ter regiões sem acampamento,
  o mercado passa a precisar de uma, e o `_cabem` é o sítio.
- **Decide:** tu.

### Q-106 · A caça é um stock do dia e esgota-se em meio minuto
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Isso não deve ser feito assim, como em kingdom os
  coelhos saem de arbustos ou coisas similares, os arbustos geram aos poucos os coelhos [...] se fizer algo errado e
  perder o arbusto para de ser gerado os coelhos e consequentemente aquele tipo de receita» — a caça passa a sair de
  **tocas** (`Burrows`): quatro arbustos por região (`burrows_per_region`), cada um a soltar um coelho de cada vez —
  o seguinte só depois de o anterior sair —, ao ritmo que faz a caça do dia render o `hunt_yield`. Um Amargueiro de
  pé a menos de 48 px de um arbusto seca-o (`burrow_wither_px`), e com ele a receita. Os arbustos desenham-se
  (`HuntView`). `tests/hunting_test.gd`.
- **Onde:** §06 (circuito 1), §25 (minuto 1:10), `economy.csv` (`hunt_yield 3|9`, nota *"caça: moeda direta
  por saída"*), `src/core/hunt_watch.gd`, `src/sim/systems/hunting_system.gd`.
- **O que diverge:** o CSV dá 3–9 moedas **por saída**; o `HuntWatch` lê o mesmo intervalo como **o stock do
  dia** — sorteia quantos coelhos há ao amanhecer e põe-nos todos nas clareiras de uma vez. O dossiê não diz o
  que é uma "saída" nem quantas há por dia.
- **O que foi medido** (`tests/abertura_natural_test.gd`, semente 20260926, dia de 360 s): o vagabundo e o
  arqueiro do lado do castelo ficam teus aos 6 s, e o arqueiro mata os cinco coelhos do dia 1 **até aos 30 s**.
  O rei tem 4 moedas aos 20 s, paga o canteiro aos 27 s, e o trabalhador acaba-o aos 34 s com o rei a 590 px
  dali; a primeira colheita cai aos 225 s, no crepúsculo. Entre os 30 s e o crepúsculo a caça não rende mais
  nada: a renda chega toda de uma vez e o resto do dia não tem caça para ir buscar — o *"deslocamento parece
  vazio"* do relatório ASTRA (secção 16), medido.
- **O que foi feito (26/09, segunda fatia):** aplicada a opção **(b)**, reversível numa linha
  (`HuntWatch.WAVE_PHASES` com uma só fase volta ao stock do dia): o sorteio do dia reparte-se em três vagas —
  alvorada, meio-dia e tarde —, com o mesmo total. Com a Q-111, a abertura medida passa a ser: 4 moedas de caça
  no saco do rei aos 107 s, o canteiro de pé aos 119 s, a primeira colheita aos 255 s; e há caça por apanhar
  até ao crepúsculo.
- **Opções:** (a) manter o stock do dia; (b) repartir o sorteio pelas fases de luz — coelhos que aparecem de
  manhã, ao meio-dia e à tarde; (c) ler "saída" à letra: cada caçador tem N saídas por dia e cada uma rende
  entre 3 e 9 dividido por elas. A (b) é a que dá motivo às viagens sem mudar o total do dia.
- **Decide:** tu.

### Q-107 · A moeda do minuto 1:10 fica com o arqueiro que a caçou
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «É como em kingdom, se o jogador não pega o vagabundo
  pode pegar e se tornar tropa, ou a tropa pode pegar e armazenar, até uma quantidade limitada de 5 moedas» — a moeda
  caída que o rei não apanha é de quem passa (`Gleaning`): um vagabundo que a apanha fica recrutado, e uma tropa tua
  guarda-a no saco dela, até ao teto (5 para as mais básicas, Q-111), e entrega-a ao rei quando ele passa. A moeda
  que o próprio rei largou continua a ser dele. `tests/gleaning_test.gd`.
- **Onde:** §25 (*"Um coelho passa. Um segundo vagabundo com arco mata-o. Cai 1 moeda. — Observação. O jogador
  não fez nada."*), §02 (a moeda física), `RecruitSystem.seek_coins`, `recruit_notice_px 120`.
- **O que foi medido:** com o rei parado no castelo, o coelho da primeira clareira cai aos 70 s, a 160 px do
  rei — no ecrã, depois da correção desta mesma medição (antes caía a 760 px, fora dele, morto pelo arqueiro de
  id mais baixo que tivesse **outro** coelho ao alcance). **0,8 s depois o próprio arqueiro sem dono apanha a
  moeda**, porque quem não é de ninguém anda para a moeda pousada mais perto (§25, minuto 0:20). Fica com 1 das
  3 do preço dele, e o preço por cima dele passa a dizer 2.
- **Leitura:** é a regra da moeda física a funcionar — a economia existe fora de ti e baixa-lhe o preço —, mas
  o jogador vê a moeda cair e não a vê chegar-lhe ao saco. O aviso "+1 moeda" dizia que tinha chegado; passou a
  aparecer só quando é o rei a apanhar.
- **Opções:** (a) manter: a lição é "a caça rende", e o preço mais baixo mostra-o; (b) a moeda da demonstração
  não é apanhável por quem não tem dono até o rei passar por ela.
- **Decide:** tu.

### Q-108 · Quanto custa reparar, e quem repara
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «é COMO EM KINGDOM precisa do construtor para
  conseguir reparar os danos» — só o construtor repara (`RepairWork.REPAIRER`); uma obra nova levanta-se com quem
  estiver no sítio, como antes. `tests/repair_test.gd`.
- **Onde:** §55 (os estados `DAMAGED` e `RUIN`), §25 (*"Casa de Treino em ruínas, reparável por 10 moedas"*),
  §09 (o construtor), `jobs.csv` (o posto `repair`, que existia sem obra que o publicasse).
- **O que o dossiê dá:** só um número — a ruína da Casa de Treino repara-se por 10, que é o preço dela. Nada
  sobre a obra tocada nem sobre quem trabalha.
- **O que foi feito (reversível, `RepairWork` e `BuildSlot.repair_cost`):** a **ruína** custa o degrau em que
  estava e volta a andaime, levantando-se outra vez no mesmo nível com o `build_work` desse degrau. A **obra
  tocada** custa a parte da vida que perdeu (arredondada para cima, mínimo 1), **fica de pé enquanto se repara**
  — continua a travar — e ganha vida à razão de uma obra inteira por `build_work`. O posto `repair` é publicado
  quando a reparação está paga e vai lá um trabalhador (a urgência nocturna do `jobs.csv` é zero: repara-se de
  dia). Quem conta como presente é a regra da Q-064: todos os teus. Cair a meio perde o pago. O núcleo não se
  repara com moeda.
- **Decide:** tu — em especial se a obra tocada deve pagar em proporção ou por degrau, e se só o construtor
  repara.

### Q-109 · O "+8% defesa das muralhas" do construtor
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «O defesa é a quantidade suportada de danos pelas
  muralhas, um construtor dá +2% de defesa, podendo chegar ao máximo de até +10% conforme há mais construtores» —
  `wall_defense` 0,02 por construtor, até `wall_defense_max` 0,1, lidos como dano aguentado a mais: a muralha leva
  `dano × defesa / (1 + defesa)` a menos. A §09 diz-o. `tests/training_test.gd`.
- **Onde:** §09 (*"Construtor — dentro do império: +8% defesa das muralhas"*), `units.csv`
  (`ability_params wall_defense:0.08`).
- **O que foi feito (reversível):** lido como **menos 8% de dano** em cada muralha (só as que têm os dois
  caminhos do §10; torres e edifícios não), enquanto houver **um** construtor teu vivo — dois não somam. A
  fracção poupada guarda-se de golpe para golpe (`BuildSlot.soak`), porque um golpe de 6 com 8% arredondado
  poupava zero sempre.
- **Em aberto:** se "defesa" é dano recebido ou vida máxima, e se soma por construtor. O "+1 slot de armas no
  arsenal" não tem arsenal onde pegar.
- **Decide:** tu.

### Q-110 · Três dos seis impulsos reais têm onde pegar
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Os vagabundos não são meus trabalhadores, assim como
  kingdom eu devo procurar eles pelo mundo em acampamentos [...] meu império apenas terá algumas tropas sem funções
  que devo sabiamente atribuir [...]» — o jogo começa simples: duas tropas já tuas, sem ofício (`Greybox.JA_TEUS`), e
  os outros vagabundos estão nos acampamentos lá fora (a ±1650 px), para ires buscar. Os acampamentos repõem um por
  alvorada (Q-122, `Camps`).
- **Onde:** §15 (a tabela dos impulsos), §24 (*"Roda do rei → segmento · Tab → 1–5"*), §57, `impulses.csv`.
- **O que foi feito:** o `CrownSystem` paga do saco do rei, um por dia, e lê o `benefit` e o `drawback` como
  chaves. Ligados: **Colheita Forçada** (produção ×1,8 hoje; as plantações de grão não produzem amanhã),
  **Chamada às Armas** (os vagabundos **sem dono** viram lanceiros teus; a produção de hoje vai a zero) e
  **Vigília** (esta noite ninguém foge; ao amanhecer seguinte a vida de cada tropa tua cai a 70%, uma vez).
  **Recusados sem cobrar:** Feira Livre (precisa da ganância e de um multiplicador de custo em todos os
  preços), Rota Protegida (comércio) e Perdão Real (dívida de mercenários e favor).
- **O gesto:** Tab mantido + 1–6, pela ordem dos ids (a tabela tem seis e o §24 diz "1–5"). O painel do Tab
  lista-os, com o preço e o que está por ligar. A roda de seis segmentos da Q-067 continua por desenhar.
- **Em aberto:** se "todos os vagabundos" inclui os teus trabalhadores; se o custo da Vigília é vida actual ou
  vida máxima por um dia; e o custo de 12 moedas é proposta (`_proposed` no CSV).
- **Decide:** tu.

### Q-111 · O caçador guarda a caça e entrega-a ao rei
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Cada tropa pode armazenar uma quantidade diferente,
  tropas mais básicas 5 moedas e outras podem armazenar um pouco mais para depois poder entregar ao jogador ao
  passar» — o `coin_capacity` do `units.csv`: 5 para o vagabundo e os ofícios, 7 para o lanceiro, 8 para o
  mercenário, 11 para o arqueiro (o caçador). Quem guarda entrega ao rei quando ele passa (`HuntingSystem.bagged`).
- **Onde:** §02 (*"Capacidade de moedas — Arqueiro 11"*, herdado do Kingdom), §06 (a caça, *"moeda direta"*),
  §25 (o minuto 1:10), Q-106.
- **O que foi medido:** com a caça repartida pelo dia, a moeda caía onde o coelho morria — a 700 px do rei ou
  ao lado de um lanceiro sem dono, que a apanhava. De seis moedas de caça até ao crepúsculo, três chegavam ao
  rei.
- **O que foi feito (reversível, `HuntingSystem.bag` e `deliver`):** a caça do **teu** caçador vai para o saco
  dele (o saco de 11 do arqueiro não tinha outro uso) e passa para o saco do rei quando os dois estão a
  `recruit_notice_px` um do outro. Entrega só o que caçou — o preço que pagaste para o recrutar fica com ele. A
  caça de quem **não** é de ninguém continua a cair no chão (o 1:10 do §25, Q-107). O saco do caçador vê-se por
  cima dele (§24).
- **Decide:** tu — em particular se o caçador deve ir ter com o rei quando o saco enche, em vez de só entregar
  quando se cruzam.

### Q-113 · Como o jogador vê que um impulso não está disponível
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «o jogador recebe uma mensagem sobre o que é preciso
  para utilizar aquilo» — um impulso recusado diz porquê (`CrownSystem.refusal()`): precisa do rei, ainda não, já
  usado hoje, ou faltam moedas — no painel do jogo (`GameHud.say`).
- **Onde:** planejamento visual de 26/09 (§7: *"Impulsos — seleção, custo, indisponibilidade e consequência;
  um funcional e um indisponível; recusa sem cobrança"*), §24, §46, Q-110.
- **O que há:** a recusa sem cobrança existe (`CrownSystem.use` devolve falso e o saco fica igual), mas só o
  painel de diagnóstico do Tab (`Inspector`) diz "por ligar", com texto escrito no script. Ao carregar 1–6 num
  impulso recusado, o jogador não vê nada.
- **Porque não se fez:** mostrar a recusa pede ou um sinal que o catálogo do §46 não tem (regra 7 do
  `AGENTS.md`), ou que a interface pergunte ao `CrownSystem` antes de pôr a intenção na fila — que é uma decisão
  de desenho do HUD (a roda de seis segmentos da Q-067 continua por desenhar). Nada foi alterado.
- **Opções:** (a) a roda desenha os três recusados apagados e com cadeado, e a tecla não faz nada; (b) um aviso
  curto do HUD ao recusar, com um sinal novo no §46; (c) esconder os recusados até terem sistema.
- **Decide:** tu.

### Q-114 · A classe do Monarca: o que é "defesa", o que é "em pessoa", como se evolui — e o escudeiro
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «O escudeiro tem um escudo que protege o rei, o rei
  pode dar 5 moedas para o escudeiro [...] torna-se cavaleiro [...]» — o escudeiro (`Squire`): o Verbo 2 dá-lhe uma
  moeda de cada vez para o escudo, até 5; cada moeda aguenta um golpe fraco, e um forte (8 de dano ou mais) gasta
  duas e meia — 5 fracos ou 2 fortes. Três moedas caídas que ele apanha dão-lhe uma espada de 3 golpes (6 de dano)
  que bate primeiro, antes de o inimigo bater; depois parte-se e o ciclo recomeça. Anda à frente do rei (24 px) e só
  passa para trás sem escudo. Não entrega moedas ao rei. Na segunda fase do Monarca é armado cavaleiro: escudo até 10
  moedas, espada de 5 golpes de 10. O escudo é o saco que se lhe desenha. Números em `_proposed`.
  `tests/squire_test.gd`.
- **Onde:** §08 (*"Tanque. +10% defesa às tropas num raio. Dano fraco. Escudeiro acompanha e apanha moedas
  caídas"*; *"O boost passa a +25% e aplica-se ao império inteiro; o escudeiro cresce e torna-se tropa de
  combate"*; *"Evolução custa Semente Real (1 para a Fase 2) e uma condição de feito"*), `classes.csv`
  (`nights_defended_in_person` 5), `units.csv` (o `squire`), F2-01.
- **O que foi feito (reversível, `ClassSystem`):**
  - **Defesa** é menos dano recebido, com a fracção poupada guardada de golpe para golpe — a leitura que a
    Q-109 já deu ao construtor e às muralhas. Na fase 1 vale para as tuas tropas na faixa do rei e a 260 px
    dele; na fase 2, para todas as tuas tropas. Nunca para o próprio rei, que é quem a dá.
  - **Uma noite defendida em pessoa** é uma em que, pelo menos num tick entre o crepúsculo e a alvorada, uma
    tropa tua combateu dentro do raio do rei, na faixa dele. Conta na alvorada.
  - **O gesto de evoluir** é o Verbo 1 no núcleo, com a condição cumprida e a Semente Real: a semente gasta-se
    e a moeda volta ao saco, como ao consagrar uma árvore (§74). Sem as duas coisas, a moeda cai como sempre.
    O guia de contexto di-lo no núcleo.
- **O escudeiro (a opção mais simples e mais reversível, como manda o `AGENTS.md`):** nasce com o rei, é teu,
  e segue-o como quem não tem posto. Apanha **só moedas caídas**: cada moeda passou a lembrar-se de quem a
  largou (`CoinSystem.from_king`), e as que o rei larga com o Verbo 1 — para pagar uma obra ou recrutar — ficam
  para quem as ia receber. O que apanha, entrega ao rei quando está ao pé dele, como o caçador (Q-111). Não é
  tropa de combate (dano 0) e o painel não o conta. Os campos dele continuam em `_proposed`.
- **Em aberto:** as três leituras de cima; se "caídas" deve ser outra coisa que "não largadas pelo rei"; se
  entregar ao rei é o que o §08 quer (a alternativa é ele guardar até 5, como armadura de moedas do Kingdom);
  e **em que tropa ele cresce** na fase 2 (`squire_becomes_combatant`) — não entrou, porque o dossiê não o diz.
- **Decide:** tu.

### Q-151 · Com a torre na receita, a noite 5 ganha-se sem mortes
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Tudo bem, pode ser mais brando assim até a noite 5
  depois conforme os dias passam se torna mais difícil exponencialmente» — as primeiras cinco noites ficam brandas, e
  o calendário da massa passa a crescer 6% por noite (`mass_growth` 1,06) — mas só depois da noite 10
  (`growth_from_night`), porque a partir da 6 qualquer ritmo derrubava a defesa que o §66 manda aguentar dez noites.
  À noite 20 pesa 1,8×; à 30, 3,2×. As árvores e as fortalezas não crescem. O dia em que começa é a **Q-157**.
- **Onde:** §07 (*"ajusta até a noite ser ganha com 1–2 mortes no dia 5"*), Q-073, Q-017; `tests/noite_do_07_test.gd`.
- **O que está:** com a torre na receita (Q-073) os seis arqueiros têm lugar e a noite 5 invoca 16 e mata 16, sem
  ninguém morrer; as primeiras noites em rampa (Q-017) tornam o início ainda mais leve. As 1–2 mortes do §07 não
  aparecem, e o teste dessa metade está saltado com esta razão.
- **Opções:** (a) o §07 passa a pedir *"ganha sem perder o muro"* e as mortes deixam de ser o alvo; (b) afina-se a
  noite 5 (mais massa, ou a receita com menos arqueiros) até custar 1–2 mortes; (c) medir as mortes numa campanha de
  dez dias seguidos e não numa noite solta.
- **Decide:** tu.

### Q-152 · Os povos do gelo e do pântano: como entram na campanha
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Passa a 8 regiões, tudo está integrado no mesmo
  sistema» — a Geada e o Paul entram na campanha (`biomes.csv`, `in_campaign`), que passa a ter oito regiões; os
  finais da §79 passam a «5 de oito» (`union_peoples_released` e `dominion_peoples_kept`, 5).
  `tests/parte_xiii_mundo_test.gd`.
- **Onde:** Q-010, Q-013; §04 (*"seis povos"*), §77 (seis capítulos e os 126 mundos), §79 (União e Domínio contam
  4 de 6 povos), `peoples.csv`, `biomes.csv` (`in_campaign`).
- **O que está:** a Geada e o Paul existem nos dados com características, unidade, arquitectura e canção propostas,
  e **fora da campanha**, que continua com seis regiões. A classe de cada um é provisória (Trepador e Diplomata).
- **Por decidir:** (1) se a campanha passa a oito regiões ou se cada campanha sorteia seis dos oito povos; (2) os
  limiares da União e do Domínio com oito povos; (3) se cada um ganha uma classe própria; (4) os nomes definitivos.
- **Decide:** tu.

### Q-153 · Onde vai a camada `Equipments`
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Equipaments faz parte do armazenamento do
  personagem, cada personagem jogável a um tipo de armazenamento que deve ser desenvolvido e bem feito» — a camada
  `Equipments` é o **armazenamento** do personagem jogável: um slot próprio, `storage`, entre o `body` e o `head` (a
  §58 passa a seis), só para quem se joga. Cada classe da §08 traz o seu tipo (`storages.csv`, `Storage`): o cinto do
  rei, a aljava do arqueiro, o alforge do bardo, o cinto de escalada do trepador, a mochila do cavaleiro enterrado,
  os alforges do cavaleiro selado e a pasta de tratados do diplomata — com o que cada um leva e onde o traz no corpo.
  Os archotes do Q-029 vão no cinto do rei (o `torch_max` saiu do `rot.csv`) e gravam-se com ele; trocar de
  personagem fica com o que cabe e larga o resto. As moedas continuam no saco do corpo (§02). O `ASSET_BIBLE` tem a
  tabela. O que mais cada um leva é a **Q-163**. `tests/armazenamento_test.gd`.
- **Onde:** Q-024, §22, §58, `docs/art/ASSET_BIBLE.md`.
- **O que está:** o dono decidiu que `Equipments` não é o `head`, e ficou sem slot.
- **Opções:** (a) um slot próprio `equipment` entre o `body` e o `head` (a §58 passa a sete); (b) funde-se no
  `body` ao exportar.
- **Decide:** tu, ao separar o `Empire troop` (ART-01).

### Q-154 · A comitiva da travessia com o recrutamento do Kingdom
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «A comitiva tem um teto também, mas está mal feito
  atualmente, está delimitando o mapa, o mapa deve ser expandido muito mais horizontalmente, a comitiva não deve
  limitar as bordas» — a comitiva tem o teto do barco do New Lands (3 construtores, 4 de longo alcance, 3 de corpo a
  corpo; `march_party_caps`), e deixou de marcar as bordas: o mapa estende-se seis ecrãs de terras bravias para cada
  lado (`Greybox.BRAVIAS_ECRAS`, `SimLoop.wild_px`), onde o rei anda e a câmara vai.
- **Onde:** Q-063, Q-135, Q-143; `Legacy.crossing()`.
- **O que está:** desde a Q-063 ninguém anda atrás do rei, e por isso a travessia leva quem está perto **e** quem
  espera sem posto no núcleo (na faixa do rei), como a tripulação do barco do New Lands. O New Lands tem teto: o
  barco leva até 3 construtores, 4 arqueiros e 3 cavaleiros.
- **Por decidir:** se a comitiva tem um teto como o barco, e qual.
- **Decide:** tu.

### Q-155 · A Q-018 e a Q-082 disseram coisas diferentes sobre os 40–60 s
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Isso será definido conforme o design de cada região,
  ainda não tem um valor exato» — os 40–60 s são uma estimativa, e cada região terá o tempo que o desenho dela pedir;
  o rei continua a 80 px/s a pé.
- **Onde:** §21, Q-018 (aprovada: *"40–60 s por ecrã"*), Q-082 (*"cada região é única, esse número é uma
  estimativa"*), ADR 0021.
- **O que foi feito:** apliquei a Q-082, a mais recente e a mais específica: os 40–60 s são uma estimativa por região,
  medida no *greybox*, e a velocidade a pé fica em 80 px/s. Ler a Q-018 à letra (40–60 s **por ecrã**) punha o rei
  outra vez a 26 px/s, que foi a queixa que deu a ADR 0021.
- **Confirma:** se era isto.

### Q-156 · Como se apaga o Lume?
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** apagar o Lume é o fim do ciclo (`Lume`): o Verbo
  2 na base dela, de dia, com o farol de pé e a Dívida da Candeia até ao limiar da União (3), acaba a campanha em
  **União** (§75). Sem cada uma das três, o guia diz o que falta. Aceitar a décima segunda oferta continua a ser o
  outro fim. `tests/apagar_o_lume_test.gd`.
- **Onde:** §74, §75 (a décima segunda oferta "fecha"), ADR 0034.
- **O que foi feito:** o Lume (a candeia) ficou na base de onde a Podridão nasce, roxo, alimentado pelo que ela
  consome; as tuas luzes fazem recuar os fracos e abrandam os fortes. O dono comparou-o à *"Besta perante a lanterna
  apagada, no fim da série"* — e na série apagar a lanterna é o fim da Besta. Nada no jogo apaga o Lume ainda.
- **Proposta:** apagar o Lume é o fim do ciclo de um império — uma expedição à base dela, de dia, com o farol de pé
  e a Dívida baixa (União, §75); aceitar a décima segunda oferta é o outro fim (quem acende a lanterna passa a ser
  tu). Até lá, a base não se ataca.
- **Confirma:** se o Lume se apaga, como, e se é o fim da campanha ou só de uma região.

## Decididas pelo dono no painel (28/09/2026)

> As 72 respostas que o dono guardou no painel (`/painel/`, ADR 0026) e que um agente aplicou a 28/09/2026. Cada
> entrada abre com a decisão e o que se mudou, e mantém por baixo o que estava escrito, para se ver de onde veio.
> São reversíveis como as outras. Onde uma resposta deixou uma parte por decidir, a parte está nas Q-151 a Q-155.
> A Q-081 foi adiada no painel e continua onde estava.

### Q-001 · Os arqueiros param o Aríete de lodo?
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** a vida do Aríete de lodo passa de 90 para 104
  (`creatures.csv`, e a tabela do §07 no dossiê, com o tempo até matar refeito: 36,4 s em torre e ≈109 s em campo).
  O `test_arqueiros_nao_param_ariete` deixou de estar saltado e mede contra a noite do `clock.csv`.
- **Onde:** §07 (tabela de tempo até matar) contra §31 (`test_arqueiros_nao_param_ariete`).
- **O que diverge:** o §07 diz que um arqueiro em campo demora **96,6 s** a matar um aríete — *"mais do que uma
  noite inteira"*. A noite dura **105 s** (§05). 96,6 < 105; com a precisão dos dados (0,34) dá 94,7 s. O teste do
  §31 exige > 105 e **falha com os números do próprio dossiê**.
- **Proposta:** manter a intenção (arqueiros não param aríetes) subindo a vida do aríete de 90 para **104**
  (26 golpes: 36,4 s em torre, 107 s em campo). Alternativa: medir o teste contra o tempo que o aríete demora a
  chegar ao muro, em vez da noite.
- **Bloqueia:** o teste está saltado com esta razão; volta quando decidires. F1-09.
- **Decide:** tu.

### Q-002 · Custo das muralhas: a tabela ou a fórmula?
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** a tabela do §10 manda; o §06 passa a escrever
  «aproximadamente `base × 1,8^n`» e cita os preços da tabela.
- **Onde:** §06 (`base × 1,8^n`) contra §10 (tabela).
- **O que diverge:** a fórmula dá 6 · 10,8 · 19,4 · 35 · 63; a tabela diz 6 · 11 · 20 · **36** · **65**.
- **Proposta:** a tabela manda (é o que está nos CSV); a fórmula passa a descrição aproximada no dossiê.
- **Decide:** tu. Não bloqueia.

### Q-003 · Precisão em campo: 1/3 ou 0,34?
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** fica 0,34 nos dados; a linha do arqueiro em
  campo da tabela do §07 passa a «≈» e a frase por cima diz porquê.
- **Onde:** §07 (tabela de TTK usa 1/3) contra §19/§44/F1-07 (`accuracy_open = 0.34`).
- **O que diverge:** 2% no TTK em campo. O teste tolera 3%.
- **Proposta:** fica 0,34 nos dados; a tabela do §07 passa a dizer "≈".

### Q-004 · Diplomata n2 com 60 de Favor: 45/45/10?
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** o exemplo do §14 estava errado: com 60 de Favor
  dá 45/50/5 (dossiê corrigido).
- **Onde:** §14.
- **O que diverge:** a regra ("cada 20 de Favor move 5 pontos de Captura para Dissolução") dá **45/50/5** com 60
  de Favor. O exemplo diz 45/45/10. O efeito do nível 2 do diplomata não está escrito.
- **Proposta:** o nível 2 move 5 pontos de Contrato para Captura? Não faz sentido. Mais simples: o exemplo está
  errado e fica **45/50/5**. Ou o nível 2 tem regra própria — escreve-a.
- **Bloqueia:** F6 (diplomacia). **Decide:** tu.

### Q-005 · Fuga: 30% ou 25% de vida?
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** ficam as duas regras: 30% quando o muro cai
  (`breach_flee_health`) e 25% no resto (`flee_health`). Já era o que o código fazia.
- **Onde:** §07 (muro cai → fogem as tropas com vida < 30% e custo ≤ 4) contra §52 (FSM: FUGIR com vida < 25%).
- **Proposta:** são duas regras diferentes e ficam as duas — 30% quando o muro cai (`breach_flee_health`), 25% no
  resto (`flee_health`). Confirma.
- **Bloqueia:** F1-12.

### Q-007 · Horta: "tropas baratíssimas" quanto?
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** a Horta tem `recruit_cost_delta:-1` no
  `peoples.csv`: −1 moeda no recrutamento de todas as tropas, nunca abaixo de 1. O `RecruitSystem.price()` aplica o
  desconto do povo da região em que se joga, e o `PriceTag` e o guia mostram esse preço (testes em
  `recruit_system_test.gd`).
- **Onde:** §04. Nenhum número. **Proposta:** −1 moeda no recrutamento de todas as tropas da Horta (mínimo 1).
  Fase 7.

### Q-008 · Forja e Fundição são o mesmo edifício?
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** dois edifícios, como estava nos dados (a Forja é
  a oficina, a Fundição a casa de conversão).
- **Onde:** §09 e §22 (Forja, onde trabalha o ferreiro) contra §06 (Fundição, a casa de conversão do minério).
- **Proposta:** dois edifícios (oficina ≠ conversão), como está nos dados. Se for um só, a fatia vertical perde a
  forja sem minério.

### Q-009 · O estábulo das montarias é o estábulo das vacas?
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** dois edifícios (`cow_stable`, `mount_stable`);
  os 30 são o preço do cavalo.
- **Onde:** §06 (estábulo de vaca, 14) e §12 ("Cavalo de tração — Estábulo, 30 moedas").
- **Proposta:** dois edifícios (`cow_stable`, `mount_stable`); os 30 são o preço do cavalo.

### Q-010 · Paliçada de "gelo"?
- **Decidido pelo dono (painel, 28/09/2026 — outra resposta):** «Gosto da idéia de ter um povo do gelo com
  características únicas» — o gelo **não** sai: a paliçada de gelo passa a ser do sétimo povo, a **Geada** (nome
  provisório), que entra nos dados com características próprias propostas — o frio guarda (nada estraga na região
  deles), o chão gelado abranda a Podridão 15%, a guarda do gelo abranda quem golpeia — e o `material_by_people` das
  muralhas. Fica **fora da campanha** até à Q-152 (`biomes.csv`, `in_campaign`). ADR 0031.
- **Onde:** §10 ("Madeira reforçada / gelo"). Nenhum dos seis povos é de gelo. **Proposta:** retirar o gelo.

### Q-011 · As moedas de abate entram na curva?
- **Decidido pelo dono (painel, 28/09/2026 — outra resposta):** «Quero que os abates gerem moedas, geram mais
  conforme o inimigo for mai dificil de derrotar» — as moedas de abate passam a crescer com a massa da criatura (o
  preço que a Podridão paga por ela): uma moeda por cada 8 de massa, arredondado, nunca menos de uma — 1 · 2 · 3 · 4
  · 6 · 15. O `design_data_test` guarda a ordem.
- **Onde:** §25 (um Rastejante morto larga uma moeda) contra §06 (o modelo da curva não conta abates).
- **Proposta:** manter os abates baixos (1–6 moedas, nos dados) e incluí-los no modelo quando o `SimHarness` os medir.

### Q-012 · O peixe estraga?
- **Decidido pelo dono (painel, 28/09/2026 — outra resposta):** «Eu aprovo, pois no meu jogo há o conceito de
  podridão e fz sentido ter» — a proposta, aprovada: coluna nova `spoil_per_day` no `buildings.csv` (o pesqueiro
  perde 1 por dia); a Salga de pé acaba com o estrago (§06). O `EconomySystem` e o `built_income()` descontam-no;
  sem Salga o pesqueiro paga-se ao terceiro dia (dossiê §06 anotado).
- **Onde:** §06 (a Salga: "o peixe deixa de estragar"). Não há regra de estrago em lado nenhum.
  **Proposta:** o peixe perde 1 unidade por dia no pesqueiro se não for convertido.

### Q-013 · Que fortaleza é "do pântano"?
- **Decidido pelo dono (painel, 28/09/2026 — outra resposta):** «Quero que haja também a população do pântano» —
  entra o oitavo povo, o **Paul** (nome provisório), com bioma, unidade própria, arquitectura e canção propostas; a
  libélula-montaria passa a vir dele (`mounts.csv`). Fora da campanha até à Q-152. ADR 0031.
- **Onde:** §12 (a libélula-montaria vem da "Fortaleza do pântano"). Nenhum dos seis povos vive num pântano.
  **Proposta:** a Horta (várzea).

### Q-014 · Quanto custa um impulso real?
- **Decidido pelo dono (painel, 28/09/2026 — outra resposta):** «Quero que pense e trabalhe bem para elaborar isso,
  deve ser um sistema bem completo que faça sentido.» — o preço de um impulso passa a ser um sistema: base por
  impulso, na medida do que ele vale (4 a 10 no `impulses.csv`), a crescer com a produção (`income_growth` — custa
  sempre o mesmo em dias de trabalho), a metade para o tirano (§15, pelo perfil em que a ganância do rei cai), e
  ×1,5 por cada vez que o mesmo decreto saiu nos últimos 3 dias. `CrownSystem.price()`, no save; o Inspector mostra
  o preço do dia. ADR 0028.
- **Onde:** §15 (o tirano paga "metade" pelos impulsos — logo têm custo — mas nenhum número).
  **Proposta:** 12 moedas (≈ o rendimento líquido do dia 1). Fase 6.

### Q-015 · Qual é a "tropa de elite"?
- **Decidido pelo dono (painel, 28/09/2026 — outra resposta):** «A cada 3 dias parece ser muito rápido, talvez a
  cada 5 ou 7 dias, para ficar mais equilibrado o jogo» — o Fastuoso dá a tropa de elite (o Berserker de Raiz) de 5
  em 5 dias (`greed_profiles.csv` e dossiê §15). Se o playtest a achar generosa, passa a 7.
- **Onde:** §15 (Fastuoso: +1 tropa de elite grátis a cada 3 dias). **Proposta:** o Berserker de Raiz (escala 3).

### Q-016 · Quantas estátuas enterradas, e que mecânicas ensinam?
- **Decidido pelo dono (painel, 28/09/2026 — outra resposta):** «Gosto dessa idéia aprofunde bem ela, pois aco muito
  interessante ter mecânicas e/ou habilidades que só são descobertas e podem ser usadas se o jogador encontrou
  explorando» — cada estátua guarda **uma** coisa, que não existe no teu jogo até a achares com o rei: a do Ferreiro
  guarda a Forja, a da Oferenda o sacrifício de moedas (Q-127), a do Mineiro a escora (Q-132). As duas novas ficam
  fora das muralhas de fora. O que se acha é do império e vai com o legado. `Discoveries`, `secrets.csv` (`teaches`,
  `place_px`), `tests/estatuas_test.gd`. ADR 0029.
- **Onde:** §17 (só a do Ferreiro está escrita). **Proposta:** uma por mecânica dos primeiros 12 minutos (§25) que
  não se ensina por observação. Fase 3.

### Q-017 · Quantas criaturas tem a noite 1?
- **Decidido pelo dono (painel, 28/09/2026 — outra resposta):** «Sim, quero que comece com algo leve e que vai se
  intensificando com o passar das noites» — a noite 1 tem os três Rastejantes do §25 (`opening_mass` 24) e a massa
  do calendário sobe em linha recta até à §74, que manda por inteiro a partir da noite 5 (`ramp_nights`). Os postos
  de muro disparam com a precisão da torre (a segunda metade da proposta). Medido no §07: 3 · 4 · 7 · 11 invocações
  nas quatro primeiras noites (antes 7 · 9 · 11 · 14). ADR 0030.
- **Onde:** §25 ("Noite 1: três Rastejantes") contra §05/§51 (massa do dia 1 = 86 → **10 Rastejantes**, e o tempo
  ativo dá para 19–33 invocações — ver `docs/content/ROT_BY_DAY.md`). E a precisão dos arqueiros **num muro** (postos
  do Caminho A) não está escrita: 0,34 ou 1,0?
- **Proposta:** a abertura é uma cena autorada (§25): o segmento `opening` limita a Podridão da primeira noite a 3
  Rastejantes. Postos de muro com precisão de torre (é o que o Caminho A vende).
- **Bloqueia:** `test_noite_1_e_sempre_ganha` (§31), F1-15. **Decide:** tu, com o `SimHarness`.

### Q-018 · Quanto demora a atravessar uma região?
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** o número deixa de ser a lei da região inteira e
  mede-se no *greybox*. Encosta na Q-082 — ver lá como as duas foram juntas.
- **Onde:** §21 ("40–60 s de ponta a ponta, o que a 26 px/s dá 1000–1560 px").
- **O que diverge:** 1560 px é pouco mais de um ecrã; uma região tem 4 a 6. A pé, uma região de 8 segmentos demora
  197 s.
- **Proposta:** ler "40–60 s **por ecrã**". Mede-se na greybox (pergunta 11 do GREYBOX_RULES).

### Q-024 · A camada `Equipments` é o slot `head`?
- **Decidido pelo dono (painel, 28/09/2026 — outra resposta):** «Equipments e head não são a mesma coisa...» —
  `Equipments` deixa de estar ligado ao `head` no `ASSET_BIBLE`; onde vai fica na Q-153.
- **Onde:** os teus ficheiros têm `Body · Face · Shield · Sword · Equipments`; a §58 tem `body · head · face ·
  weapon · shield · overlay`. **Proposta:** `Equipments` → `head`. Confirma ao separar o `Empire troop` (ART-01).

### Q-025 · Godot 4.6-stable, 4.6.3 ou 4.7?
- **Decidido pelo dono (painel, 28/09/2026 — outra resposta):** «O godot já tem a versão 4.7.2 estável, faça a
  princípio nela...» — o projecto passa ao Godot **4.7.2-stable** (`.godot-version`, `project.godot`), com a suite
  inteira corrida nele antes de mudar. ADR 0032.
- **Onde:** `.godot-version` (§69). Em setembro de 2026 existem 4.6.3-stable e 4.7.2-stable; o gdUnit4 6.2.1 suporta
  4.5–4.7.1. **Proposta:** ficar no 4.6 e subir para o **4.6.3** (só correções) com uma ADR no início da Fase 0;
  4.7 só com uma razão concreta.

### Q-028 · Que arquétipo jogável traz cada povo?
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** o arquétipo de cada povo sai do `_proposed` do
  `peoples.csv`.
- **Onde:** §04 ("1 classe" por povo) e §13. **Proposta nos dados:** Enramados → arqueiro, Portuários → trepador,
  Fenda → monarca, Horta → bardo, Fornalha → cavaleiro enterrado, Sob-Raiz → cavaleiro selado. Fase 7.

### Q-029 · As "fogueiras" que abrandam A Podridão são o quê?
- **Decidido pelo dono (painel, 28/09/2026 — outra resposta):** «Além disso é possível adquirir um item que o
  jogador pode carregar com ele para ajudar a explorar, esse item tem limite de uso e se o jogador explora a noite
  sem item é muito perigoso pois podem aparecer inimigos de qualquer lugar» — a **fogueira** entra (3 moedas, o
  abrandamento do barril, luz mais fraca do que a candeia) — e fogueiras e barris passam a abrandar mesmo a mancha
  (`FireZones`). E o **archote**: compra-se numa fogueira com o Verbo 1, levam-se dois, acende-se sozinho no escuro
  e arde 60 s; de noite, fora das muralhas e da luz, sem archote, nasce um Rastejante ao lado do rei de 8 em 8 s.
  `Torchlight`, `DarkWatch`, `tests/archote_test.gd`. ADR 0030.
- **Onde:** §05 ("fogueiras, barris de fogo e terreno consagrado abrandam-na"). Só o barril e o altar têm dados.
  **Proposta:** fogueira = o *campfire* das rondas noturnas, edifício de 3 moedas com o abrandamento do barril.

### Q-030 · Uma região tem 8 segmentos ou 4 a 6 ecrãs?
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** oito segmentos na fatia vertical, dez a doze com
  ADR quando uma região pedir cinco ou seis ecrãs (dossiê §21).
- **Onde:** §21. Oito segmentos de 640 px são 4 ecrãs, não 6. **Proposta:** 8 na fatia vertical; 10–12 quando uma
  região precisar de 5–6 ecrãs, com ADR.

### Q-031 · O núcleo tem vida?
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** o núcleo tem 1000 de vida e não tem ruína
  (`max_health` sai do `_proposed`).
- **Onde:** §10 ("não é construído nem destruído"; "se cair, cai a partida"). **Proposta nos dados:** 1000 de vida,
  sem estados de ruína.

### Q-033 · A curva do §06 e os edifícios reais — **medida pelo F1-11**
- **Decidido pelo dono (painel, 28/09/2026 — outra resposta):** «Faça pelo F1-16» — pelo método do F1-16: manda o
  jogo medido (os edifícios reais), e o modelo do §06 fica como referência. O dia da asfixia da economia jogada
  continua dentro do alvo (`economia_jogada_test`), com o estrago do peixe incluído.
- **Onde:** §06 (o simulador usa "fontes" abstratas: base = 3 + 2,6 × fontes) contra os edifícios de `buildings.csv`
  (2 a 5 por dia cada).
- **Proposta:** o `EconomySystem` (F1-10) calcula o rendimento a partir dos edifícios; o teste de design compara-o
  com o modelo de referência e o dia de asfixia tem de continuar entre 9 e 14. Se não bater, afina-se `economy.csv`.
- **O que o F1-11 mediu, e não decidiu:** o `EconomySystem.built_income()` soma os edifícios reais e o
  `sources()` conta-os. A região do *greybox* tem as **7 fontes** do perfil `balanced` — quatro canteiros,
  dois galinheiros e um pesqueiro — e rende **17 moedas no dia 1**. O simulador do §06, com as mesmas 7
  fontes, dá **21,2**. O abstrato é 25% mais generoso do que o concreto, e o `producao_test` fixa a
  diferença para que ela não mude em silêncio.
- **O que fica por decidir:** qual dos dois manda. Baixar `curve_income_per_source` de 2,6 para ≈2,0 fecha a
  diferença e move o dia da asfixia; subir os `yield_per_day` fecha-a do outro lado e mexe em seis edifícios.
  É balanceamento e é do F1-16 — nenhum número de `data/` foi mexido aqui.

### Q-034 · A roda do rei pausa o jogo? E porque é que o teclado vai de 1 a 5?
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** Tab + 1–6 já era o gesto; a roda passa a
  abrandar o tempo a 50% enquanto está aberta (`wheel_time_scale` no `clock.csv`), desligável nas opções. Abranda-se
  saltando passos e não encolhendo o delta, para a semente continuar a reproduzir a partida (`Pace`,
  `tests/pace_test.gd`).
- **Onde:** §24 (impulso: "Tab → 1–5"; a roda tem 6 segmentos e há 6 impulsos) e §05 (a roda é o corpo do rei).
- **Proposta:** Tab + 1–6; a roda abranda o tempo a 50%, desligável.

### Q-035 · `treasury_changed` e os sinais do §30
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** a §46 manda; nada a mudar.
- **Onde:** o `event_bus.gd` do §30 declara `treasury_changed`, `creature_requested`, `unit_band_changed`,
  `structure_built`, `structure_destroyed` e outras cargas; **nenhum destes está no catálogo fechado da §46**.
- **Proposta:** a §46 manda (§39). O F0-07 escreve os 61 sinais da §46; o HUD do saco usa `coin_collected`.

### Q-036 · O I6 protege mesmo o save?
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** o I6 já estava corrigido no dossiê (§19, §40,
  §62) e a ADR 0007 segue-o.
- **Onde:** §19 ("Usa `ResourceLoader.load` com `CACHE_MODE_IGNORE` e valida os tipos à mão"), §40 (I6) e §62.
- **O que diverge:** o `load()` do GDScript é um atalho para o `ResourceLoader.load`, e `CACHE_MODE_IGNORE` só decide
  se o recurso vem da *cache* — um `.tres` com *script* embutido executa-o na mesma. A regra, tal como está
  escrita, proíbe a função e recomenda a mesma função. É a única falha de segurança encontrada no dossiê.
- **Proposta:** o save grava-se com `FileAccess.store_var` e lê-se com `FileAccess.get_var(false)` (sem objetos —
  o valor por omissão), só com tipos base, validados campo a campo; nunca `ResourceLoader` num save. A ADR 0007 já
  diz isto desde a v5.2; falta mudares a frase do I6 no dossiê (§19, §40, §62).
- **Bloqueia:** F0-13 (`SaveService`) — o ticket já segue a proposta. **Decide:** tu, mas não há alternativa segura
  com `ResourceLoader`.

### Q-038 · A massa desce: a Q-001 muda de resposta?
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** refez-se a conta com a massa da §74 antes de
  desmarcar: o tempo até matar não depende da massa, e a Q-001 fica com a mesma resposta.
- **Onde:** §74 (massa base de 60 para 40, termo do dia de 26 para 18) contra §07 e §31.
- **O que diverge:** a Q-001 media os arqueiros contra a noite com a massa antiga. Com 40 + 18 × dia a noite tem
  menos criaturas, e o Aríete de lodo chega mais tarde — o número que fazia o teste falhar pode ter mudado.
- **Proposta:** recalcular o teste da §31 com os números novos **antes** de o desmarcar. `docs/content/ROT_BY_DAY.md`
  já está gerado com a fórmula nova e serve de base à conta.
- **Bloqueia:** F1-09. **Decide:** tu.

### Q-039 · O Forno Aceso faz nascer um Amargueiro dentro das muralhas
- **Decidido pelo dono (painel, 28/09/2026 — outra resposta):** «Não faz muito sentido, se for outra coisa que gera
  talvez, mas uma fornalha não...» — a exceção corta-se: nenhuma lei entra em casa. O Forno Aceso só cria raiz fora
  das muralhas (`chapters.csv`, a lei em PT e EN, dossiê §77) e o D-10 passa a guardar **zero** leis dentro de casa.
- **Onde:** §77 (a lei do Forno Aceso: a brasa cria raiz ao sétimo dia, *"dentro das tuas muralhas inclusive"*)
  contra §74 (*"dentro das muralhas — não cria"*).
- **Proposta:** exceção deliberada, e a única. `chapters.csv` marca-a com `law_enters_walls`, e o teste D-10 falha
  se aparecer uma segunda. Se houver uma segunda, corta-se esta.
- **Bloqueia:** Fase 5. **Decide:** tu.

### Q-040 · "O que brilha, e nada mais" salta 105 s de jogo
- **Decidido pelo dono (painel, 28/09/2026 — outra resposta):** «Saltar o jogo gera consequências, nada pode ser
  feito de qualquer jeito, decisões tem pesos» — saltar a noite passa a ter peso além do preço: a massa que a noite
  saltada trazia vem inteira na noite seguinte (`skipped_mass_carry`, `DebtLedger.carry()`), e continua a ser uma
  vez por campanha.
- **Onde:** §75, quinta oferta.
- **Proposta:** uma vez por campanha. Saltar a noite duas vezes ensina a evitar o jogo em vez de o jogar.
  `offers.csv` traz `once_per_campaign = true` marcado em `_proposed`.
- **Bloqueia:** Fase 3. **Decide:** tu.

### Q-041 · Nove nomeados é teto fixo ou cresce com o império?
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** nove nomeados, teto fixo.
- **Onde:** §76, regra 1.
- **Proposta:** fixo. Cresce e deixa de significar nada — a escassez é o que faz o nome valer.
  `economy.csv` traz `named_cap = 9`; o teste D-07 guarda-o.
- **Bloqueia:** Fase 4. **Decide:** tu.

### Q-042 · A sexta Colheita em 16 dias é longa demais?
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** fica `6 + 2 × n` e mede-se em playtest.
- **Onde:** §78 (`C = 6 + 2 × povos detidos`).
- **Proposta:** medir em playtest. Alternativa escrita: `6 + 1,5 × n`, arredondado para cima.
  `economy.csv` traz `colheita_base_days = 6` e `colheita_per_people = 2`, ambos marcados.
- **Bloqueia:** Fase 5. **Decide:** o playtest.

### Q-043 · Seis capítulos por campanha, ou os dez sempre?
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** seis capítulos por campanha, o Cerco sempre.
- **Onde:** §77.
- **Proposta:** seis. Quatro por descobrir valem mais do que dez esgotados, e é o que dá os 126 mundos.
  O teste D-11 guarda o número e a presença d'O Cerco Que Não Acaba.
- **Bloqueia:** Fase 5. **Decide:** tu.

### Q-044 · O motivo sonoro da Podridão substitui o indicador visual?
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** coexistem, e o visual é a própria candeia.
- **Onde:** §81 contra §26.
- **Proposta:** coexistem, mas o visual é a própria candeia (§74) e não um ícone.
- **Bloqueia:** §26. **Decide:** tu.

### Q-045 · A Dívida fica escondida no modo de acessibilidade?
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** a Dívida fica escondida; a redundância é a luz e
  os estandartes.
- **Onde:** §75 contra §26 e §82.
- **Proposta:** fica. O brilho da candeia e os estandartes dos povos soltos (§82) são a redundância;
  um número não é acessibilidade, é *spoiler*.
- **Bloqueia:** §26. **Decide:** tu.

### Q-046 · O Turno entra na Fase 8 ou corta-se?
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** O Turno entra na Fase 8.
- **Onde:** §79, terceiro epílogo.
- **Proposta:** entra. É um sinalizador no save e um termo na semente, e é o mais forte dos três.
  `rot.csv` guarda os limiares dos outros dois; O Turno é o ramo *"tudo o resto"* da precedência.
- **Bloqueia:** Fase 8. **Decide:** tu.

### Q-047 · Uma noite de pé, ou mais?
- **Decidido pelo dono (painel, 28/09/2026 — outra resposta):** «Quero que seja equilibrado, não quero que meu jogo
  acabe logo tão cedo, deve ser bem cadenciado como kingdom: new lands» — a regra do Amargueiro fica em uma noite
  (não sobe com o dia, que a tornava mais dura), e a cadência do Kingdom: New Lands entra onde o jogo acabava cedo:
  as primeiras noites em rampa (Q-017) — o New Lands também alivia as primeiras noites de cada ilha — e as noites
  fundas de 6 em 6 (Q-126), que é o ritmo das Luas de Sangue. Medido: a receita mais fraca do §07 passa a cair
  ao dia 7 em vez do 3, e a defesa do décimo dia continua a aguentar os dez. ADR 0030.
- **Onde:** §74, regra 2, e o glossário das ferramentas.
- **O que está em aberto:** o Amargueiro só se corta depois de aguentar uma noite inteira. Uma noite chega para
  fechar a exploração do vagabundo (paga-se +22 uma vez por árvore), mas não se sabe se o número devia subir com
  o dia, como sobe tudo o resto da §74.
- **Proposta:** fixo em 1 (`rot.csv`, `amargueiro_nights_standing`; `amargueiros.csv`,
  `nights_standing_required`). A conta da §74 — dez vagabundos são +220 na noite seguinte — já mata o império
  ao dia 6 com uma só noite. O teste D-03 guarda a regra.
- **Bloqueia:** Fase 2. **Decide:** tu.

### Q-048 · As nove cenas de segmento autoradas
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** refaz-se só a `seg_000` na Fase 1; as outras
  oito ficam para o gerador.
- **Onde:** `source_gaps` da recuperação; §65 e §83.
- **O que falta:** as nove cenas de segmento escritas à mão não sobreviveram ao zip recuperado. A §83 exige que
  `seg_000` seja fixa e autorada, e agora com o Amargueiro velho e a candeia lá dentro desde o minuto 0:00.
- **Proposta:** refazer só a `seg_000` na Fase 1, com a lista de obrigatórios da §83, e deixar as outras oito
  para o greybox da Fase 2 — o gerador da §54 cobre-as até lá.
- **Bloqueia:** Fase 1. **Decide:** tu.

### Q-049 · O catálogo de tradução para além do título de arranque
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** as chaves já existiam no `strings.csv`; a frase
  da §27 passa a dizer «mil e trezentas palavras».
- **Onde:** `source_gaps` da recuperação; §27 e §75.
- **O que falta:** `data/i18n/strings.csv` tem os nomes de conteúdo, mas a Parte XIII acrescenta 1 280 palavras
  novas (§75): doze frases de oferta, nove títulos, dez leis de capítulo e doze diários.
- **Proposta:** as chaves entram já (`OFFER_*`, `TITLE_*`, `CHAPTER_*`, `JOURNAL_*`), com o texto PT-PT do dossiê
  e o `en` por traduzir. A §27 passa a dizer *"precisa de mil e trezentas palavras"*.
- **Bloqueia:** Fase 3. **Decide:** tu.

### Q-050 · As tabelas de dados que faltavam
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** o `_tables.csv` manda, e a §85 deixa de escrever
  números à mão: aponta para o `validation.json`, que o `check_claims.py` confere.
- **Onde:** `source_gaps` da recuperação (*"wildlife and remaining data tables"*).
- **O que diverge:** o zip recuperado trazia 17 tabelas e 154 recursos; este repositório tem 27 e 202. As dez que
  faltavam são as de fauna, segmentos, i18n e as quatro novas da Parte XIII.
- **Proposta:** o `_tables.csv` deste repositório manda, e a frase da §85 (*"os 154 recursos a partir das 17
  tabelas"*) passa a ser um número gerado e não escrito à mão.
- **Bloqueia:** nada — já aplicado. **Decide:** confirmar o número.

### Q-051 · Os sistemas de jogo e a cena de jogo
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** pela ordem de custo da §82; nada a mudar hoje.
- **Onde:** `source_gaps` da recuperação (*"game systems and scene"*).
- **O que falta:** `src/sim/` tem os dados e as regras puras; os nove sistemas da Parte XIII (Amargueiro, Oferta,
  Dívida, Títulos, Capítulos, Colheita, Diários, Epílogos, Som) não têm implementação.
- **Proposta:** entram pela ordem de custo da §82 — §80, §74, §75, §83, §84 são o caminho mínimo de 52 h. Os
  catorze testes da §84 entram com cada sistema, não depois.
- **Bloqueia:** Fases 1 a 6. **Decide:** o calendário.

### Q-052 · CI remoto e exportação
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** fica o `run_tests.sh` como contrato local;
  outros alvos de exportação quando houver máquina que os arranque.
- **Onde:** `source_gaps` da recuperação; §31 e §35.
- **O que falta:** ~~sem remoto nunca correu num runner limpo~~ — **corre.** A corrida **#19** pôs os cinco
  *jobs* verdes na mesma corrida (portões estáticos, dados e suite gdUnit4, export de Linux, camada do dossiê,
  e o `ci` que os junta), que era a condição para fechar esta pergunta. O que fica por fazer é o resto do
  enunciado: a **exportação só está testada para Linux**.
- **Proposta:** manter o `run_tests.sh` como contrato local e acrescentar os outros alvos de exportação quando
  houver máquina para os provar — exportar sem arrancar o binário não prova nada, e é o arranque que o job de
  Linux faz hoje.
- **Bloqueia:** Fase 2. **Decide:** tu — mas já não por falta de CI.

### Q-053 · O preço da décima oferta
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** é preço (`price_kind` sai do `_proposed`).
- **Onde:** §75, tabela das doze ofertas, linha *"Fica com a candeia por uma noite."*
- **O que diverge:** a coluna **Preço** diz *"Uma classe jogável, para sempre"* e a coluna **O que dá** diz
  *"Controlas a mancha esta noite e manda-la a um império rival"*. Lida como preço, a primeira só pode significar
  **perder** uma classe da §08 para sempre; lida como recompensa, seria a única linha da tabela com duas
  recompensas e preço nenhum.
- **Proposta:** é preço. `offers.csv` traz `price_kind = playable_class`, `price_amount = 1`, marcado em
  `_proposed`. A classe perdida escolhe-se largando a tropa dessa classe no prato, como todas as outras — continua
  a ser o Verbo 1. É o preço mais caro da tabela, e é por isso que só aparece ao dia 15 e vale +5 de Dívida.
- **Bloqueia:** Fase 3. **Decide:** tu.

### Q-054 · Dois capítulos ficaram sem raiz
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** as duas raízes («vozes sem corpo», «cerco sem
  fim») saem do `_proposed`.
- **Onde:** §77, caixa *"Cada lei tem uma raiz, e a raiz é verificável"*.
- **O que diverge:** a caixa lista oito raízes para dez capítulos. O Sulco Cego e O Cerco Que Não Acaba ficaram de
  fora, e a regra escrita é que **cada** capítulo sai de uma coisa que existiu.
- **Proposta:** `chapters.csv` propõe *"vozes sem corpo"* para O Sulco Cego e *"cerco sem fim"* para O Cerco,
  ambos marcados em `_proposed`. São descrições, não raízes verificáveis — falta-lhes a fonte.
- **Bloqueia:** Fase 5 (a escrita do habitante). **Decide:** tu.

### Q-055 · O desvio dos capítulos que não estão numa bifurcação nem numa travessia
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** 25 s para beira de estrada e acampamento, 40 s
  para fortaleza e travessia (`detour_seconds` sai do `_proposed`).
- **Onde:** §77, regra 5 (*"25 s numa bifurcação e 40 s numa travessia"*).
- **O que diverge:** três das cinco colocações não são nenhuma das duas — beira da estrada, fortaleza e junto a
  acampamento de mercenários.
- **Proposta:** `chapters.csv` propõe 25 s para beira de estrada e acampamento (o desvio é curto) e 40 s para
  fortaleza (o desvio é uma região inteira). Marcado em `_proposed` nas dez linhas.
- **Bloqueia:** Fase 5. **Decide:** o playtest.

### Q-056 · O §46 dá a carga de cada sinal, mas não os tipos
- **Decidido pelo dono (painel, 28/09/2026 — outra resposta):** «Aplique o que você decidiu, me parece bem» — fica a
  regra do F0-07 e os dois casos como estão implementados.
- **Onde:** `docs/design/46-o-catalogo-completo.md` contra `src/core/event_bus.gd` (F0-07).
- **O que diverge:** a coluna *Carga* tipa sete parâmetros (`day: int`, `paused: bool`, `hit: bool`,
  `from, to: Phase`) e deixa os outros **cerca de quarenta** só com nome: `amount`, `source`, `ratio`,
  `tier`, `income`, `value`, `drops`, `segments`. Um sinal declarado exige o tipo escrito.
- **Proposta:** a regra que o F0-07 aplicou, para ser uma regra e não quarenta decisões avulsas —
  id de **dados** (existe numa linha de `data/source/*.csv`) é `StringName`; id de **instância**
  (sai do `next_id` do §45) é `int`; moeda, matéria e contagens são `int`; posição, massa, largura,
  rácio e duração são `float`; `drops` é `PackedStringArray` porque o CSV já os escreve `coins|corpse`.
- **Dois casos ficam por decidir, e estão implementados pelo mais simples:**
  `rot_summoned(creature_id)` leva o id de **dados** (é o que o §30 devolve em `pick.id`) enquanto
  `creature_died(creature_id)` leva o de **instância** — o mesmo nome de parâmetro para duas coisas;
  e `region_generated(segments)` ficou `int`, a contagem, porque a §46 não diz se é a lista ou quantos.
- **Bloqueia:** nada. Os tipos mudam sem quebrar ninguém enquanto não houver emissores — **e é agora
  que é barato**. **Decide:** tu, antes do F1-08 (o primeiro emissor de `rot_summoned`).

### Q-057 · O dossiê dá um número de câmara, e a câmara precisa de cinco
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** os quatro números da câmara saem do `_proposed`
  (o `edge_pan_px` é da Q-087 e fica).
- **Onde:** `docs/design/24-controlos-hud-diegetico-e-feedback.md` contra `src/world/camera_rig.gd` (F0-08).
- **O que diverge:** a §24 escreve *"Reconhecimento; volta sozinha em 2 s"* para a câmara livre, e nomeia a
  antecipação ao dizer que a cegueira do Cavaleiro Selado a desliga. Não dá **nenhum** valor para a
  antecipação, para a suavização, nem para a velocidade da câmara livre. A §19 diz que "a câmara e o
  enquadramento dependem" da decisão de escala, que é o *spike* F0-09 e ainda não fechou.
- **Proposta:** os quatro valores entraram em `data/source/camera.csv` marcados em `_proposed`, porque a
  invariante I4 manda que o que se afina em *playtest* viva em `data/` e não num script:
  `lookahead_px` **120** (3/16 da meia-tela de 640 — deixa ver cerca de dois terços do ecrã à frente de quem
  anda), `lookahead_seconds` **0,6** (alto de propósito: uma antecipação que salta ao primeiro passo para trás
  dá enjoo), `follow_seconds` **0,18**, `free_speed_px_s` **420** (atravessa um segmento de 640 px em pouco
  mais de segundo e meio). O `free_return_seconds` é **2,0** e esse vem do dossiê.
- **Bloqueia:** nada — a câmara funciona e nenhum destes números é lido pela simulação. Mas o F0-09 pode
  mexer-lhes: se a escala mudar, a antecipação em píxeis muda com ela. **Decide:** o primeiro *playtest*,
  depois do F0-09.

### Q-058 · A célula das moedas contradiz-se dentro da própria tabela do §53
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** manda o `L_COIN`; já era assim.
- **Onde:** `docs/design/53-faixas-colisao-e-a-matriz-que-tem-de-existir-no-.md`, as linhas `L_SURFACE` e `L_COIN`.
- **O que diverge:** `L_SURFACE` diz que colide com *"Terreno, edifícios, muralhas, **moedas**"*; duas linhas
  abaixo, `L_COIN` diz que colide com *"**Nada** — é apanha por proximidade"*, e justifica-o: *"colisão de moeda
  com 300 unidades é desperdício"*. As duas não podem ser verdade.
- **Proposta:** manda o `L_COIN`, porque traz a razão escrita e a razão é de desempenho. O `BandLayers` põe
  `coin_mask` a colidir só com o terreno da faixa onde a moeda foi largada — uma moeda tem de **assentar** no
  chão (§F1-01: largar, arco, queda, apanhar) — e nenhuma máscara de corpo inclui `L_COIN`. Há teste:
  `test_ninguem_apanha_moedas_por_colisao`.
- **Bloqueia:** nada hoje. **Decide:** o F1-01, que é quem primeiro larga uma moeda a sério.

### Q-059 · O `UnitSystem` do §30 é um `Node2D`; o do §41 e do §43 é simulação
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** o `UnitSystem` é puro e vive em
  `src/sim/systems/`.
- **Onde:** o §30 escreve `src/actors/unit_system.gd` com `class_name UnitSystem extends Node2D` e sprites lá
  dentro. O §41 põe os sistemas em `src/sim/systems/`, o §43 lista `UnitSystem — FSM` como o **passo 4 da
  simulação**, e o §52 descreve-o sem uma única referência a nós.
- **Proposta:** a especificação manda, pelo precedente da **Q-035** (*"a §46 manda (§39)"*): o §19 diz de si
  próprio que é o esboço e que a especificação está nas §39–§67. O `UnitSystem` é puro e vive em
  `src/sim/systems/`; o portão **G1** chumbaria de imediato um `Node2D` ali. A camada de apresentação é o
  `UnitView` (§58, F0-14), que é outra coisa e já existe. O próprio §30 fecha com a regra que isto aplica:
  *"os sistemas puros devolvem pedidos; só a camada de nós age"*.
- **Bloqueia:** nada. **Decide:** confirmação tua, ou uma ADR se preferires o contrário.

### Q-060 · `Array[UnitRec]` no §45 contra as colunas do F1-03
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** as colunas são a verdade; o `UnitRec` não se
  cria.
- **Onde:** o §45 declara `var units: Array[UnitRec] = []` e dá o `UnitRec` como classe; o título do **F1-03**
  é *"UnitSystem com arrays paralelos"*, e o §30 explica porquê: *"as unidades são linhas em arrays paralelos,
  não nós com script. É o que permite 300 unidades a 60 fps."*
- **O que diverge:** um `UnitRec` por unidade são 300 objetos `RefCounted` — exatamente o custo por unidade que
  o §63 orça para não existir.
- **Proposta:** as colunas são a verdade, e o `UnitRec` **não é criado**. O `UnitSystem` guarda `PackedArrays`
  com um campo por coluna, e o índice `i` é a mesma unidade em todas. O save leva as colunas, que já são tipos
  base e passam pelo canal da ADR 0007 sem conversão nenhuma — há teste. O `UnitRec` do §45 continua a ser a
  descrição do que uma unidade **é**; deixa de ser a descrição de como é guardada.
- **O que isto custa, e está escrito no código:** `remove()` troca com a última em vez de deslocar tudo, e por
  isso **muda a ordem das colunas**. Nada que afete a simulação pode iterar por índice e esperar estabilidade —
  itera-se por id crescente, que é o que a §42 já manda.
- **Bloqueia:** nada. **Decide:** tu, e antes do F1-14 (o save do estado a sério).

### Q-061 · O dossiê diz que a moeda é física e não diz com que física
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** a gravidade, o impulso e a dispersão da moeda
  saem do `_proposed`.
- **Onde:** o §02 e o §61 fazem da moeda física o **Verbo 1** — *"tudo o que o jogador faz passa por ela"* — e
  o `economy.csv` traz **um** número para ela: `coin_pickup_px = 12`, já marcado em `_proposed` pelo F1-01.
  Um arco precisa de mais três, e nenhum está escrito em lado nenhum.
- **Proposta:** entraram em `data/source/economy.csv` marcados em `_proposed`, pela mesma regra do I4 que levou
  lá os da câmara (Q-057): `coin_gravity_px_s2` **700**, `coin_drop_speed_px_s` **180**,
  `coin_drop_spread_px_s` **40**. Dão um ápice de 23 px em contínuo — cerca de **20 px medidos a 30 Hz**, que é
  o que se vê — meio segundo de voo, e ±20 px de espalhamento, mais do que o raio de apanha de 12, para que
  duas moedas largadas juntas não se apanhem como uma só. Há teste a medir o ápice contra a fórmula, com a
  tolerância escrita como erro de discretização (`v0 · dt`) e não como um número a gosto.
- **Onde é que a moeda corre no tick:** o §43 tem onze passos e **nenhum é a moeda**. Corre no passo **5**, com
  o movimento, porque é movimento — e porque o passo 8 (BuildSystem) lê *"moedas largadas"* e portanto precisa
  delas já pousadas. Está escrito no `SimLoop` e no `CoinSystem`.
- **Bloqueia:** nada. **Decide:** o primeiro playtest — e o F1-06, que é quem constrói com a moeda a sério.

### Q-063 · O §25 descreve o minuto 0:20 em duas frases e não dá um número a nenhuma
- **Decidido pelo dono (painel, 28/09/2026 — outra resposta):** «Deve ser similar ao feito no jogo kingdom: new
  lands, veja vídeos ou pesquise em wikis para entender como foi feito» — como no Kingdom: New Lands (pesquisado na
  wiki do jogo): o vagabundo corre para a moeda que cai perto dele, apanha-a, e o recrutado **não segue o rei** —
  vai para a vila (o núcleo) e espera lá por trabalho; à noite recolhe como antes (Q-128). Só o escudeiro anda atrás
  do rei. Na travessia, quem espera sem posto embarca com ele, como a tripulação do barco do New Lands. `Retinue`,
  dossiê §25. ADR 0033.
- **Onde:** o §25 e o §83 dizem *"Largas uma moeda perto dele"* e *"O vagabundo segue-te"*, e o F1-04 tem de
  as pôr a funcionar. "Perto" não tem número, e "segue" não tem distância.
- **Proposta:** entraram em `data/source/economy.csv` marcados em `_proposed`, pela mesma regra que levou lá os
  da câmara (Q-057) e os da moeda (Q-061): `recruit_notice_px` **120**, `follow_distance_px` **30**,
  `follow_spacing_px` **18**. Os dois últimos estão ancorados na fila do §50 — `queue_min_px` 30 e
  `queue_spacing_px` 18 — **de propósito**: "a que distância uma pessoa espera por outra" já tem resposta neste
  jogo, e ter duas seria ter duas. Não se reutilizaram as chaves do §50 porque aquelas são de quem espera vez
  num muro; o dia em que uma mudar, a outra não tem de mudar com ela. O 120 é o limite exterior dessa mesma
  fila, que é a distância a que o jogo já diz que alguém pertence a um sítio.
- **Onde é que isto corre no tick:** procurar a moeda e andar atrás do rei **escrevem alvo**, e por isso são o
  passo **4** (*"estado, alvo, intenção de movimento"*). Apanhar e ser recrutado são consequência de ter
  **chegado**, e por isso são o passo **5**, a seguir ao movimento. O §43 não tem passo para a apanha, tal como
  não tinha para o arco (Q-061); está escrito no `SimLoop`, que é onde a ordem vive (ADR 0020).
- **O que a medição obrigou a mudar, e é a parte que interessa:** procurar moeda é uma varredura de unidades
  **contra** moedas, e o custo é o produto. Medido no pior caso do §63 — 300 por recrutar, 60 moedas no chão —
  a primeira versão dava **3871 µs só na procura**, e o tick completo **4372 µs** contra os **4000 µs** que o
  §63 dá à simulação **inteira**. Duas correcções, ambas indicadas pelo próprio dossiê:
  a procura passou a ser **fatiada** como a FSM (§52: *"é só a decisão que é fatiada"* — escolher para que
  moeda se anda é uma decisão), e a apanha deixou de varrer o chão todo por unidade, porque o passo 4 já
  escolheu a moeda e guarda-a no `target_ids` do §45, que estava na coluna à espera de quem o escrevesse.
  O tick ficou em **971 µs**. Se voltar a crescer, a alavanca é uma grelha por X (§53) e não o `AI_SLICE`.
- **O que fica por decidir:** (a) o §46 não tem sinal para *"deixou de ser de ninguém"* — o `unit_promoted` é
  do **JobSystem** no catálogo, e usá-lo aqui era inventar, por isso o recrutamento anuncia-se com
  `coin_spent(1, "recruit")`, que o §46 dá a *"Build, recrutamento"*; (b) um vagabundo por recrutar passa a
  ter o `set_target_x` **sobreposto** de seis em seis ticks por quem procura moeda — é o que se quer, mas é uma
  mudança de contrato para quem chamava esse método à mão. **Decide:** tu, e o primeiro playtest.

### Q-064 · O §55 dá estados à obra e não dá trabalho a nenhum deles
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** o muro herda `build_work = 2 s × custo`, e a
  regra sai do `_proposed` de todos os edifícios.
- **Onde:** a §55 escreve `EMPTY → SCAFFOLD → BUILDING(ratio) → DONE → DAMAGED(ratio) → RUIN` e diz que *"o
  progresso avança enquanto ele estiver presente"*. Não diz **quanto** avança, nem quanto tempo demora um muro.
  O `buildings.csv` tem `build_work` para os edifícios (regra proposta: 2 s × custo); o `walls.csv` não tem
  coluna nenhuma para isso.
- **Proposta, e é a mais reversível que há:** o muro herda a mesma regra proposta dos edifícios — `build_work =
  2 s × custo — lida do próprio canteiro em vez de repetida à mão (`Greybox._segundos_por_moeda()`). Uma
  estacaria de 6 moedas leva 12 s de construtor presente; um bastião de 65 leva 130.
- **E uma mão vale uma mão:** o progresso avança `delta × quantos estão em cima da obra`, **todos por igual**.
  O bónus do construtor é a habilidade do §09 (`builder_wall_bonus`, +8% de defesa) e não uma velocidade; dar-lhe
  aqui um multiplicador era inventar um número que o dossiê não escreve. Reparar uma obra `DAMAGED` com moeda
  também ficou de fora: é o posto `repair` do F1-05 mais a habilidade, e nenhum dos dois tem número.
- **Decide:** tu, e o primeiro *playtest* — é exactamente o tipo de número que o §67 diz que o greybox fecha.

### Q-065 · O §49 converte matéria em moeda por um ofício, e os ofícios são Fase 2
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** a conversão 1:1 enquanto não houver ofício; o
  circuito 2 já está no `ConversionSystem`.
- **Onde:** o §49 tem três circuitos: produzir matéria, **convertê-la** por um ofício, e comércio. O circuito 2
  precisa do `CraftData` e do cozinheiro/ferreiro do §09, que são o F1-11 e a Fase 2. Sem ele a matéria acumula
  dentro do edifício e nunca sai — o que é o mesmo que não haver economia nenhuma no jogo.
- **Proposta:** enquanto não houver ofícios, a conversão é **1:1 e imediata**: um canteiro de
  `yield_per_day` 2 larga 2 moedas por dia, repartidas pelas seis fases (Q-027, fechada: *"o CSV guarda por dia
  e o sistema divide pelas fases"*). A moeda cai **por cima do edifício que a produziu**, que é a única parte
  em que o §49 não admite alternativa: *"nunca escreve um inventário do jogador. Não existe inventário."*
- **O que isto NÃO decide:** a taxa de conversão real dos ofícios. Quando o F1-11 entrar, a matéria passa a
  parar no `stock` e o ofício é que a tira de lá — e esta linha desaparece sem que mais nada mude.
- **Decide:** o F1-11.

### Q-066 · O Verbo 2 tem quatro usos no §24 e três deles não têm sistema
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** o Verbo 2 faz a passagem, com 24 px de
  tolerância.
- **Onde:** o §24 dá ao Verbo 2 quatro contextos — *"trocar de classe, montar, entrar em passagem, subir em
  criatura"*. Classes são o §08, montarias o §12, e subir em criatura a habilidade do Trepador (§08): nenhum
  dos três existe. **Entrar em passagem** existe: a §11 dá as três faixas, o `units.csv` dá
  `can_change_band` ao monarca, e o `segments.csv` dá uma passagem por segmento.
- **Proposta:** o Verbo 2 faz **só** a passagem entre faixas, e a tolerância do gesto — a que distância da
  passagem a tecla ainda pega — é `SimFactory.PASSAGEM_PX` = **24 px**, ancorada na largura de uma tropa à
  escala 2 (§01). O dossiê não dá número nenhum a isto.
- **Decide:** tu. O §25 mede `underground_discovered` com alvo de 14 minutos (§32); se a mediana passar disso,
  o problema é a sinalização da passagem e não a tolerância.

### Q-067 · A roda do rei tem seis segmentos e quatro deles não têm sistema por trás
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** a tecla da roda abre o painel de estado até os
  quatro sistemas existirem.
- **Onde:** o §24 chama à roda *"o único menu do jogo"* e dá-lhe seis segmentos: construir · recrutar ·
  ofícios · impulso · expedição · sucessão. Construir e recrutar **já são os dois verbos** e não precisam de
  menu; ofícios (§09), impulso (§15), expedição (§13) e sucessão (§15) não têm sistema nenhum.
- **Proposta:** a acção `king_wheel` (Tab) abre, por agora, o **painel de estado do greybox** — o que cada
  sistema está a pensar, para se poder testar uma mecânica sem ler o registo (§67, GB-03). Uma roda com quatro
  segmentos que não fazem nada é pior do que não haver roda: ensina um gesto que depois muda.
- **Decide:** a Fase 2, quando os quatro sistemas existirem. Até lá a tecla está ligada a alguma coisa em vez
  de estar declarada e por ler, que era o estado anterior.

### Q-068 · O §25 diz três Rastejantes na noite 1; a massa do §74 dá sete
- **Decidido pelo dono (painel, 28/09/2026 — outra resposta):** «Está correto, 3 no dia 1» — a prosa do §25 fica: a
  noite 1 tem três Rastejantes, pela rampa das primeiras noites (ver a Q-017).
- **Onde:** a tabela do §25 escreve *"Noite 1: três Rastejantes. Os arqueiros matam-nos do muro."* A massa do
  dia 1 é `40 + 18 × 1 = 58` (§74) e o Rastejante custa 8 (`creatures.csv`), o que dá **sete** — e é o que o
  `docs/content/ROT_BY_DAY.md`, gerado dos dados, escreve na linha do dia 1.
- **Não é um defeito do código:** o `RotSystem` gasta a massa como o §51 manda e o `ROT_BY_DAY` deriva dos
  mesmos números. A divergência é entre a **prosa do §25** e a **tabela do §74**, e as duas são do dossiê.
- **Porque é que importa:** o §25 diz que *"a noite 1 é ganha de certeza — está desenhada para isso"*. Sete
  Rastejantes contra um monarca sem muro não é isso.
- **E desde o F1-16 deixou de ser hipótese: é uma medição.** Com o núcleo já atacável (Q-076) o *greybox*
  corrido sem ninguém a jogar **perde na noite 1** — os sete Rastejantes chegam ao castelo-árvore e comem-no.
  Com as duas estacarias de dentro de pé aguenta a noite 1 com **376 de 1000** e perde na **noite 2**. Com a
  abertura do §25 inteira — muro **e** toda a gente recrutada — aguenta a noite 1 com **388** e perde na
  noite 2 na mesma. Só com as quatro muralhas e as quatro torres de pé é que o núcleo fica a **100%** ao
  quarto dia. Medido em `src/world/greybox.gd`, ao passo fixo, com a semente da suite.
- **Duas leituras, e a segunda é a Q-073:** ou a noite 1 tem criaturas a mais, ou a defesa tem postos a menos
  — nove tropas recrutadas num muro que publica **um** posto de guarda deixam oito a recolher ao núcleo, e
  isso não é uma defesa, é uma fila. As duas perguntas são a mesma medição vista de dois lados.
- **Decide:** tu, e é uma das duas — ou a prosa do §25 passa a sete, ou a `mass_base` do `rot.csv` desce. O
  `AGENTS.md` proíbe mexer no número para calar o teste, e por isso nada foi mexido.

### Q-069 · "CanvasModulate por faixa" pede a única coisa que o motor não faz
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** um nó por faixa, com o seu `modulate`.
- **Onde:** o título do F1-13. O Godot aceita **um** `CanvasModulate` por canvas — é o que a documentação dele
  diz e é o que o nome quer dizer: ele modula *o canvas*. Três faixas no mesmo canvas não podem ter três.
- **Proposta:** um nó por faixa (`src/world/band_view.gd`) com o seu `modulate`. É a mesma multiplicação, e
  três nós irmãos podem tê-la diferente. A alternativa — três `CanvasLayer`, um por faixa — dava três
  `CanvasModulate` a sério, mas custava sincronizar a transformação da câmara à mão em cada um, porque um
  `CanvasLayer` não a herda. Isso é a pilha de parallax da §59 e é o ART-03; quando ela existir, este ficheiro
  passa a viver lá dentro sem que a conta mude.
- **E o segundo número que não existe:** o §80 dá `night_value_floor` 0,11 para o chão contra 0,16 do
  ambiente, e mais nada. Daí sai uma razão que vale em todas as fases; o subsolo leva-a duas vezes, porque não
  há número para ele e inventar um era escrever balanceamento em código (regra 3 do `AGENTS.md`).
- **Decide:** o ART-03, quando trouxer as seis camadas de parallax.

### Q-070 · Os dois caminhos da muralha são uma decisão, e não há onde a tomar
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** a Fortificação por omissão até à roda.
- **Onde:** o §10 escreve *"cada segmento oferece duas melhorias mutuamente exclusivas por nível. Nunca dá
  para ter as duas — **e essa é a decisão**"*. A **Guarnição** põe postos e deixa o muro frágil; a
  **Fortificação** põe vida e tira dano de saída. O `walls.csv` tem as quatro colunas para as duas.
- **O sistema está inteiro:** `BuildSlot.choose_path()` aceita a escolha até ao nível 1 — *"nunca dá para ter
  as duas"* também quer dizer que não se troca a meio — e a partir daí a vida e os postos saem do caminho
  escolhido. O que não existe é **onde carregar**: a roda do rei é a Q-067 e os dois verbos já estão tomados.
- **Proposta, por omissão:** `FORTIFICACAO`, que é a coluna que o §10 escreve como principal (é a coluna
  "Vida (B)" da tabela). Ninguém escolhe, e por isso escolhe-se a que o dossiê põe à frente.
- **Decide:** a Fase 2, com a roda. Até lá é uma linha no `greybox.gd` e muda-se num sítio.

### Q-071 · A fila do §50 mede-se do centro do muro, e um muro tem largura
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** as distâncias da fila medem-se da face do muro.
- **Onde:** o §50 dá a fila como `wall.x + sign(...) * (30 + i * 18)`. O modelo dele não tem largura de muro;
  estes têm — a estacaria tem 64 px de silhueta. Trinta píxeis medidos do **centro** punham o primeiro da fila
  **dentro** dela, e quem tem *slot* de contacto ficava a 32 px de um alvo que alcança 24.
- **Proposta:** as distâncias medem-se da **face**. Quem tem *slot* fica na face (distância zero ao que vai
  bater); quem espera fica em `face + 30 + i × 18`, com o teto de 120 na mesma. O espaçamento do §50 mantém-se
  intacto — o que muda é de onde se conta, e é a única leitura que funciona com um muro que ocupa espaço.
- **Decide:** ninguém, se o greybox não desmentir. É geometria, não equilíbrio.

### Q-072 · O §06 diz que o pesqueiro é "imune ao rasto" e os dados só sabem dizer duas coisas
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** «imune» quer dizer fora do rasto; resolve-se com
  água no segmento (GB-01).
- **Onde:** a coluna *Risco* do §06 dá três estados diferentes — a plantação é *"destruída pelo rasto"*, o
  pesqueiro é *"imune ao rasto"*, e o galinheiro não diz nada. O §49 só escreve dois: *"a plantação no rasto é
  destruída; as outras só param"*. O `buildings.csv` tem uma bandeira, `destroyed_by_rot_trail`, e uma
  bandeira representa dois estados, não três.
- **O que está implementado:** os dois do §49. O pesqueiro não é arrasado (a bandeira está a `false`) mas
  **pára** enquanto o rasto o cobrir, como o galinheiro. A terceira leitura — produzir na mesma dentro do
  rasto — não está escrita em lado nenhum dos dados.
- **Proposta:** "imune" quer provavelmente dizer *fora do rasto*, e não *dentro dele a produzir*: o pesqueiro
  está na água e o rasto é de terra. Com geometria de água no segmento (GB-01) a frase resolve-se sozinha e
  sem coluna nova. Enquanto não houver água autorada, fica como está.
- **Decide:** o GB-01, ou uma terceira coluna em `buildings.csv` se o playtest a pedir.

### Q-073 · O §07 quer seis arqueiros num muro que só tem um posto
- **Decidido pelo dono (painel, 28/09/2026 — outra resposta):** «Se só há um lugar só deve haver um, para caber mais
  deve evoluir o lugar» — é a opção (a): a receita do §07 passa a ter a torre (o lugar evoluído) e o «sem torre no
  dia 8» passa a variante, em que o muro cai. Os dois testes do §07 deixaram de estar saltados; fica saltada só a
  metade das mortes (Q-151). Dossiê §07 reescrito.
- **Onde:** o §07 fecha com a receita do microteste — *"monta um cenário fechado: um muro, **seis arqueiros**,
  uma noite de 105 s, vagas de Rastejantes crescentes. Ajusta até a noite ser ganha com **1–2 mortes no dia 5**
  e **perdida sem torre no dia 8**"*. O cenário existe (`tests/sim_harness.gd`, F1-15) e mede o contrário.
- **O que o instrumento lê**, com a estacaria de nível 1 e a semente do cenário:

  | Noite 5 | invoca | abate | mortes | ao muro | muro cai | núcleo |
  |---|---|---|---|---|---|---|
  | sem torre | 16 | 10 | **1** | 2 | **sim** | de pé |
  | com torre de arqueiros | 16 | 16 | **0** | 7 | não | de pé |

  E o dia 8 dá o mesmo desenho: sem torre o muro cai, com torre não. Sem torre o muro cai em **todas** as
  noites, a começar na 1 — e o §25 diz que a noite 1 *"é ganha de certeza"*.
- **Porque é que acontece, e não é um defeito do código:** a estacaria do §10 publica **um** posto de guarda
  (`guard_posts_b = 1`, `walls.csv`). Dos seis arqueiros, um sobe ao muro e os outros cinco ficam sem vaga, e
  quem não tem posto recolhe ao núcleo — a 500 px do muro, com 200 px de alcance. A noite inteira é decidida
  por **um** arqueiro. A torre de arqueiros dá mais dois postos, e é isso que a tabela de cima mede: *"a torre
  não dá dano — dá certeza"* (§07) está certo, e é a única coisa desta medição que está.
- **O que o F1-16 lhe acrescentou, e não fechou:** com o núcleo já atacável (Q-076) a segunda linha mudou de
  razão mas não de resposta — uma noite 8 **sozinha** continua a acabar com o castelo-árvore de pé, porque o
  muro cai tarde e o que resta da noite não chega para os 1000 de vida. Dez noites seguidas já chegam, e é
  isso que o `tests/dez_dias_test.gd` mede. A primeira linha está como estava.
- **Porque é que o F1-16 não a podia fechar, e não é falta de vontade:** a opção (b) é subir os postos de
  guarda, e no nível 1 não há onde. O §10 escreve *"o nível 1 é a base comum aos dois caminhos"*, e os postos
  do caminho A desse nível estão **na tabela do dossiê** — mexê-los é mexer no dossiê, não em `_proposed`. O
  `guard_posts_b` está proposto, mas pô-lo acima de A no nível 1 desfazia a base comum.
- **Decide:** tu, e é uma de três — (a) a receita do §07 passa a incluir a torre, e o "sem torre no dia 8"
  passa a ser a variante; (b) os postos de guarda do §10 sobem no nível 1, e aí é o dossiê que muda; (c) um
  arqueiro sem posto passa a disparar de onde está, e aí a §52 ganha uma regra que hoje não tem. O `AGENTS.md`
  proíbe mexer no número para calar o teste, e por isso nada foi mexido: os dois testes do §07 estão
  **saltados com esta razão** em `tests/noite_do_07_test.gd`.

### Q-074 · O §66 quer dez dias em dez segundos, e o tick fica no fio da navalha
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** medir antes de otimizar, e primeiro num export
  de release. O teste continua saltado com essa razão até haver o export de medição.
- **Onde:** o §66 dá ao bloco *"Uma noite completa"* o critério *"corre em headless com delta fixo, **dez dias
  em menos de dez segundos**"*. Dez dias são 3600 s de jogo a 30 Hz — **108 000 ticks** —, o que dá um
  orçamento de **92 µs por tick**.
- **O que se mede:** o cenário fechado — duas obras, sete tropas, vagas de Rastejantes — corre os dez dias em
  **≈18 s** num *runner* headless. Medido por passo: **≈22 µs** com o mundo vazio, **≈99 µs** com as sete
  tropas e as duas obras, **≈275 µs** a meio da noite 10. O `EventBus` não é o custo (desligar a história
  muda 3%); o custo é o tick, e cresce com as obras e com as tropas antes de crescer com as criaturas.
- **Não colide com o §63:** o orçamento do §63 é de **4000 µs** por tick para a simulação inteira, e a 30 Hz
  isso é tempo real com folga — o `jogo_noite_test` mede-o e passa. O que o §66 pede é outra coisa: **360× mais
  depressa do que o tempo real**, que é o que faz de um cenário um instrumento de afinação em vez de uma
  partida acelerada.
- **Proposta:** medir antes de otimizar. Este número sai de um binário de editor em *debug*, com as
  verificações de tipo do GDScript e os `assert` ligados; a mesma medição sobre um *export* de release é o
  primeiro passo, e não custa nada senão correr o CI. Se a diferença não chegar, o §66 é que escolhe: ou o
  orçamento sobe, ou o tick emagrece — e aí é trabalho de simulação, com ticket próprio.
- **O que o F1-16 voltou a medir:** noutro *runner* headless, com o mesmo binário de editor, os mesmos dez
  dias custam **9,4 s numa corrida e 11,1 s na seguinte** — o orçamento do §66 passou a estar dentro da
  variação da máquina. Não é uma melhoria do tick: é a mesma medição noutro sítio, e é exactamente a razão
  para o teste continuar saltado. Um portão que responde à carga do *runner* e não ao código chumba a quem
  não mexeu em nada.
- **Bloqueia:** o teste está saltado com esta razão em `tests/noite_do_07_test.gd`. O que **não** está saltado
  é o que o F1-15 promete: os dez dias correm, em headless e ao passo fixo, e o relógio chega ao dia 11.
- **Decide:** tu. Não bloqueou o F1-16 — a afinação lê a tabela noite a noite, e essa é rápida.

### Q-075 · Uma criatura ataca de qualquer faixa que o `targets_bands` liste, de onde quer que esteja
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** fica: quem pode mudar de faixa tem de subir para
  atacar.
- **Onde:** o F1-07 escreveu para as tropas a regra do alcance vertical (`Posts.reaches`, Q-006): a faixa
  própria alcança sempre, qualquer outra só com um posto que dê altura. Do lado das **criaturas** não havia
  regra nenhuma — o `TargetPicker._tropa_mais_proxima` olhava só para o `targets_bands` do `CreatureData`.
- **O que isso fazia:** o Cavador, que nasce na faixa subterrânea, atacava tropas da superfície **sem nunca
  subir**. O §07 diz que ele *"passa pela faixa subterrânea"* — passa, e passar é o que o torna uma ameaça,
  porque passa **por baixo do muro**. Atacar de lá não está escrito em lado nenhum, e tornava decorativo todo
  o `src/sim/systems/passages.gd` do F1-09: a passagem que o §25 manda abrir ao minuto 10:00 deixava de ter
  a factura que o mesmo §25 lhe põe ao minuto 12:00.
- **Decidido, e a decisão sai dos dados que já lá estavam:** `Passages.reaches(dados, sua_faixa, alvo)`. A
  faixa própria alcança sempre; outra faixa só se a criatura **não puder** mudar de faixa. O `can_change_band`
  do §44 separa exactamente as duas criaturas que o §07 descreve de maneiras diferentes:
  - o **Alado** (`can_change_band = false`) vive no ar e bate no chão de lá — *"ignora a camada de solo; só
    atacável por arqueiros e torres altas"* (§07). A resposta a ele é um posto que chegue lá acima, e é a
    torre alta.
  - o **Cavador** (`can_change_band = true`) tem de **subir** para bater, e sobe onde há passagem (§11, §51).
- **É uma mudança de comportamento**, e só toca no Cavador: o Rastejante, o Bruto, o Aríete e a Consumidora
  nascem e batem na superfície, e para eles a regra é a identidade.
- **Reversível, e o que a reverte:** se um dia o Cavador tiver de morder tornozelos de baixo para cima, o
  `return not dados.can_change_band` passa a `return true` e volta tudo ao que era. Nenhum número de `data/`
  foi mexido.

### Q-078 · O farol ilumina 300 px e a candeia nunca passa dos 260
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** o farol mantém os 300 px e ganha paragens
  próprias a metade da força (`light_strength` 0,5 no `effect_params`); o `WorldLight.dominates()` mede-o paragem a
  paragem e o teste da candeia deixou de estar saltado (abaixo de ≈0,54 a candeia domina). Dossiê §80 anotado.
- **Onde:** o §80 escreve a regra de composição da noite inteira — *"uma luz domina por ecrã. Se duas
  competem, o ecrã lê plano. Consequência de design, não só de arte: as tuas fogueiras têm de ser **mais
  fracas do que a candeia à mesma distância**"*. E o §10 vende o farol por 40 moedas para *"iluminar 300 px"*.
  A candeia do §74 é `150 + 4 × dia`, **com teto em 260**. O farol é a única obra do jogo com `light_radius`,
  e ganha à candeia em qualquer dia.
- **Porque é que o raio decide isto:** com as mesmas três paragens, a luz de raio maior é mais forte a
  **qualquer** distância — o núcleo e o meio dela chegam onde a outra já é bordo. Duas luzes com paragens
  diferentes era outra conversa, e o §80 não dá paragens às fogueiras: dá **uma** regra de luz ao jogo todo.
- **Não bloqueia nada hoje, e é por isso que é uma pergunta e não um defeito:** o farol é de Fase 6, não está
  no *greybox*, e tem `blocks_summon` — *"A Podridão não invoca dentro da luz"* —, portanto a candeia e ele
  talvez nunca se encontrem no mesmo ecrã de propósito. O `tests/candeia_test.gd` tem o teste **saltado** com
  esta razão, e ele volta sozinho no dia em que a pergunta fechar.
- **Proposta:** a mais reversível é dar ao farol paragens próprias e mais fracas — uma coluna nova em
  `buildings.csv`, como o `light_radius` já é — em vez de lhe cortar o raio, que é um número do dossiê. A
  alternativa é escrever no §80 que o farol é a excepção: ele é *landmark* e não fogueira, e um marco que
  domina o seu ecrã é exactamente o que um farol faz.
- **Decide:** tu. A palavra que falta ao dossiê é se "fogueira" inclui o farol.

### Q-079 · O vocabulário de formas do *greybox*: uma por categoria, até haver arte
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** o vocabulário de formas fica até ao
  ART-01/ART-02.
- **Onde:** §22 (*"a paleta muda com a hora do dia e com o LUT; a silhueta do telhado não muda nunca"*, e os
  seis kits de arquitetura), §80 §5 (a tabela do teste de silhueta), §25 (*"a silhueta é o convite"*), e
  `src/world/silhouette.gd`.
- **O que o dossiê não diz:** o dossiê decide que a **silhueta é a identidade** de uma obra, e decide de onde
  ela virá — do **kit de arquitetura do povo** (§22: stavkirke para os Enramados, basalto para a Fornalha, o
  negativo do desfiladeiro para a Fenda). O que ele não diz é que forma tem um canteiro **enquanto não há
  arte**, e até agora a resposta do repositório era "nenhuma": tudo era o mesmo rectângulo cinzento, e um
  canteiro, uma torre e o castelo-árvore só se distinguiam pela largura.
- **O que está escrito, e é reversível numa linha:** uma forma por **`category` de `buildings.csv`** — a
  coluna que já existe —, mais o muro (que vem de `walls.csv` e se reconhece por ter os dois caminhos do §10),
  mais uma por `tag` de `creatures.csv`, mais uma marca por `weapon_kind` de `units.csv`. Nada disto é um `if
  id == "archer_tower"`: sai todo de `data/`, e no dia em que aparecer a sexta obra de defesa ela ganha forma
  sozinha. As formas estão em `src/world/outline.gd`, em centésimos da caixa, e trocar uma é trocar uma linha
  de números.
- **As três coisas que escolhi e o dossiê não escreve** — e por isso estão aqui e não caladas:
  1. **As alturas.** O §01 fixa a escala das personagens (16 px = um degrau) e o §10 dá as **larguras** em
     `width_px`, mas nenhuma secção dá altura a um edifício. As do `Silhouette.DEGRAUS` estão em degraus —
     um canteiro dá pelo ombro, uma torre são cinco pessoas, a torre alta são oito — e a do castelo-árvore
     **não é uma escolha de escala**: sai da geometria das faixas, porque o §11 diz que a copa entra na faixa
     aérea e diz porquê.
  2. **A ruína.** O §55 dá seis estados a um sítio de obra e o dossiê descreve cinco. Uma ruína desenha-se com
     a mesma forma, rente ao chão: reconhece-se o que era, e vê-se que já não é.
  3. **A calha da barra de vida.** O §07 diz *"sem números no ecrã, nada de barras de vida flutuantes"*, e o
     `Gauge` é o contrário disso e sabe que é (GB-03, §67: o *greybox* existe para se **medir** uma noite).
     Com calha, 23 px de barra num castelo de 480 px passam a ler-se como 5% em vez de como um risco.
- **Proposta:** fica assim até ao **ART-01/ART-02**. Este vocabulário é o *fallback* neutro — um povo só, sem
  kit —, e a forma definitiva é por povo **e** por categoria, como o §22 manda. O `tests/outline_test.gd`
  guarda a única regra que tem de sobreviver à arte: **duas formas nunca desenham a mesma coisa**.
- **Decide:** tu. Não bloqueia nada, e nada na simulação muda com isto — é tudo apresentação (§45).

### Q-080 · A que luz se vê um corpo à noite
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** silhueta longe da luz, cor perto; o chapéu e os
  instrumentos não levam luz.
- **Onde:** §80 §1 (a tabela de tectos de valor, com *"inalterado"* na linha do plano de jogo), §80 §3
  (*"perto da luz vê-se cor e volume; longe vê-se silhueta"*), §22 degrau 3 (*"uma rampa 1D por hora do dia;
  todos os sprites amostram através dela"*), e `src/world/lighting.gd`.
- **O que estava errado, e mede-se:** o ambiente da fase vinha no `modulate` do nó da faixa, e um `modulate`
  multiplica **tudo** o que o nó desenha. Multiplicava três coisas que não são a mesma, e a terceira era um
  defeito a sério: **a candeia saía com luminância 26 contra um céu de 34** — a fonte de luz ficava mais escura
  do que o fundo, e o §80 diz o contrário em duas palavras, *"âmbar é luz"*. Ao lado disso, o chão era
  desenhado com `SOLO * plane()` e o `Color * float` do GDScript multiplica **quatro** componentes: o chão saía
  a 69% de opacidade sobre o cinzento por omissão do motor, e à noite dava (32,29,26) contra um céu de
  (36,34,30). Sem horizonte não há §11 nenhuma. Os dois estão corrigidos e têm teste.
- **O que não vem do dossiê, e por isso está aqui:** com o ambiente aplicado só onde ele manda, faltava
  responder *quanto* dele chega a um corpo. Escurecer a cor de cada um pelo ambiente deixava um vagabundo
  (0,93 0,85 0,61) a **luminância 31 contra um céu a 34** — a mesma mancha, e não se via. O que está escrito é
  a leitura literal do §80 §3: longe de qualquer luz o corpo é **uma silhueta**, um valor escuro só — o
  `#100D09` que o §80 §1 nomeia —, e perto da candeia é a cor dele. Mede 16 contra 34, e vê-se a **forma**,
  que é o que a §22 diz que identifica uma coisa.
- **As duas excepções que abri, e porquê:** o **chapéu** (§25, *"ele apanha-a e ganha um chapéu"*) e os
  **instrumentos** do `Gauge` não levam luz nenhuma. Um sinal de dono que se apaga à noite deixa de ser um
  sinal, e o *greybox* existe para se **medir** uma noite (§67, GB-03). Com isto, à noite vêem-se vultos
  escuros e os que têm um ponto dourado em cima são teus — que é a leitura do Kingdom.
- **Proposta:** fica assim até ao ART-02. A rampa 1D da §22 é o mecanismo certo e não existe enquanto não
  houver *sprites*; o que está escrito é a mesma decisão feita com `draw_rect`. O portão que a guarda é o
  `make silhueta`: a noite tem de abrir a gama que a paleta do §80 lhe dá, e a noite chapada de antes abria
  2,7× contra os 16,3× exigidos.
- **Decide:** tu. Nada na simulação muda — é tudo apresentação (§45).

### Q-082 · O §21 dá dois tempos de travessia e eles não são o mesmo tempo
- **Decidido pelo dono (painel, 28/09/2026 — outra resposta):** «Cada região é única, esse número é uma estimativa,
  que deve ser adaptada» — os 40–60 s passam a estimativa e não lei: cada região adapta-o, e mede-se no *greybox* (a
  Q-018, aprovada, dizia o mesmo). A velocidade a pé fica nos 80 px/s da ADR 0021, que vieram da queixa de um
  jogador; o `travessia_test` guarda a região do *greybox*. Dossiê §21 reescrito. As duas respostas puxavam para
  lados diferentes na letra — ver a Q-155.
- **Onde:** §21 (*"Região — 4 a 6 ecrãs de largura... deriva-o do tempo de travessia: a pé (§12) uma região
  deve levar 40–60 s a atravessar de ponta a ponta, o que a 26 px/s dá 1000–1560 px por ecrã"*), §47
  (`SEGMENT_WIDTH 640`), §12, §19 e §44 (`move_speed = 26.0`), `data/source/units.csv`, `src/world/greybox.gd`.
- **A contradição, numa linha:** a primeira metade da frase diz que a **região** se atravessa em 40–60 s; a
  segunda faz a conta como se fossem 40–60 s **por ecrã**. Uma região de 1040–1560 px não são "4 a 6 ecrãs"
  de 640 px, nem "oito segmentos por região" — as duas metades não podem ser verdade ao mesmo tempo.
- **O que o jogo fazia:** nem uma nem outra. A região do *greybox* tem 3840 px (seis ecrãs de 640) e toda a
  `units.csv` andava aos 26 px/s que o §19 e a §44 escrevem como **valor por omissão do campo**. São **148 s**
  de ponta a ponta, num dia que dura 360 s (`clock.csv`) — quase metade de um dia a andar em linha reta, só de
  ida. Foi por aqui que a queixa do jogador entrou: *"o personagem está a mover-se extremamente lento"*.
- **O que foi decidido, e é reversível:** manda a primeira metade — a que a própria secção escreve como
  **ordem** (*"deriva-o do tempo de travessia"*). A pé são 80 px/s, 48 s de travessia, e a coluna inteira da
  `units.csv` sobe pelo mesmo factor para não perder as relações autoradas. A `creatures.csv` não se toca: a
  velocidade das criaturas está na tabela do §07 e é conferida contra o dossiê. Ver ADR 0021.
- **O que continua por decidir:** se o que se quis dizer foi mesmo 40–60 s **por ecrã**, então o número que
  está errado não é a velocidade — é a região, e ela tem de passar de seis segmentos para dois e meio, o que
  contradiz o §21 noutro sítio. Corrigir o dossiê fecha isto num dos dois sentidos; enquanto não for
  corrigido, o `tests/travessia_test.gd` é que guarda a leitura escolhida.
- **Decide:** tu. A pergunta é qual das duas metades da frase do §21 fica no dossiê.

### Q-083 · O §24 manda largar em contínuo e não diz a que ritmo
- **Decidido pelo dono (painel, 28/09/2026 — outra resposta):** «Está correto, deve pagar em continio enquanto
  mantiver precionado e enquanto houver dinheiro» — é o que o jogo faz: enquanto a tecla está premida e há moedas no
  saco, larga ao ritmo do `coin_drop_repeat_s`.
- **Onde:** §24 (mapa de comando: *"Largar em contínuo — A/✕ (manter) — Espaço (manter) — Pagar vários
  níveis de uma vez"*), §55, `src/ui/input_router.gd`, `data/source/economy.csv`.
- **O que faltava:** a linha estava no mapa de comando do §24 desde a v2 e **ninguém a lia**. O
  `input_router.gd` dizia-o no cabeçalho — *"manter para largar em contínuo espera pelo BuildSystem a aceitar
  pagamento por nível de uma vez"* — e isso era uma leitura a mais: o §55 quer a moeda física a cair uma a uma
  (*"uma obra existe quando uma moeda cai num BuildSlot"*), e o que o §24 pede não é um pagamento de uma vez, é
  **a mesma moeda a sair sozinha**. Pagar o Bastião de 65 moedas à tecla eram 65 toques.
- **O número que não está no dossiê:** o ritmo. Fica `coin_drop_repeat_s = 0,12` — pouco mais de oito moedas
  por segundo, o degrau mais caro do §10 (o Bastião, 65) em 8 s de tecla premida. O valor vem do PR #16, que
  chegou a esta mesma linha do §24 por outro caminho e o escreveu num `const` do router com a justificação
  certa (*"depressa o bastante para encher uma obra sem martelar a tecla, devagar o bastante para se ver cada
  moeda a cair"*); ao juntar os dois ficou o **número dele** e o **sítio deste** — `economy.csv`, pela regra 3
  do AGENTS.md, ao lado da gravidade e da dispersão do arco, que são a mesma classe de número.
- **O que isto NÃO faz, e é de propósito:** não paga vários níveis de uma vez. O §55 diz que uma obra a meio
  não aceita moeda, e por isso o contínuo enche o degrau seguinte, a obra arranca, e as moedas que saírem
  depois ficam no chão à espera do degrau a seguir — que é o que o Kingdom faz.
- **Decide:** tu, e é um número de playtest. Mais depressa e a moeda deixa de se ver a cair; mais devagar e a
  muralha de ferro volta a ser um exercício de dedo.

### Q-084 · O knockback do §24 é o único terço do impacto que mexe na simulação
- **Decidido pelo dono (painel, 28/09/2026 — outra resposta):** «Por enquanto sim, mais pra frente minh aintenção é
  ter um sistema completo» — fica sem empurrão na simulação por agora; o sistema completo de impacto é trabalho
  futuro.
- **Onde:** §24 (*"Impacto — flash branco de 80 ms, **3 px de knockback**, partícula de 4 px na direção do
  golpe"*), §45, §50, §61, `src/world/impact_view.gd`.
- **O que foi feito:** dois dos três. O flash e a partícula são apresentação e vivem no `ImpactView`; o
  `building_damaged` — o sinal que uma noite do *greybox* emite às centenas e que não se via em lado nenhum —
  acende a orla da obra que está a ser comida.
- **Porque é que o terceiro ficou de fora:** empurrar um corpo 3 px muda uma **posição**, e posições são a
  simulação (§45). Um empurrão dado da camada de apresentação tira um atacante da fila de contacto do §50 sem
  que o §50 dê por isso, e um empurrão que o *save* não conhece torna a partida irreproduzível pela mesma
  semente (§61, §42) — que é a propriedade que este repositório mais protege.
- **O que falta para o fazer:** um número em `data/` (3 px é do dossiê, mas falta dizer se é por golpe, se
  acumula, e se um Bruto empurra um vagabundo tanto como o contrário), e um sítio em `src/sim/` que o aplique
  no passo 6 do §43, a seguir à resolução do combate e antes do movimento.
- **Decide:** tu. A pergunta é se o empurrão é do atacante (massa) ou do golpe (dano), porque disso depende se
  ele vive no `CombatSystem` ou numa coluna nova.

### Q-085 · O §52 diz que quem luta não anda; o §24 diz que o comando "Mover" vale sempre
- **Decidido pelo dono (painel, 28/09/2026 — aprovar a proposta):** quem uma pessoa conduz anda mesmo em FIGHT.
- **Onde:** §52 (a tabela de estados: `FIGHT | Inimigo em alcance | Alvo morre ou sai de alcance | Resolução de
  combate`), §24 (mapa de comando: *"Mover — Stick esquerdo / D-pad — A · D · ← → — **Sempre**"*), §08,
  `src/sim/systems/unit_system.gd`.
- **O que estava a acontecer:** o monarca tem `damage 3` e `range_px 30` (`units.csv`), e por isso o
  `target_picker` põe-no em FIGHT como põe qualquer tropa. Com o FIGHT a proibir movimento, uma criatura a
  30 px tirava o jogo das mãos de quem o joga **até ela morrer** — e numa noite com cinco delas à volta, isso
  era a partida inteira a ver-se a si própria.
- **A leitura que mudou:** a última coluna da tabela do §52 é o **custo por tick** de cada estado — GOTO custa
  "movimento em X", FIGHT custa "resolução de combate" — e não uma proibição. A proibição era uma
  interpretação do código, defensável para uma tropa (um lanceiro `holds_line` não deve sair da linha) e
  insustentável para o corpo que uma pessoa conduz.
- **O que foi decidido, e é reversível:** quem é conduzido por uma pessoa anda mesmo em FIGHT; quem a §52
  conduz continua a segurar a linha. Entra por parâmetro no `tick_movement()` e não por coluna, porque não é
  propriedade da unidade — é quem a está a conduzir agora, e isso vive no `SimLoop` (§45). Andar para fora do
  alcance desengata sozinho, e por isso fugir continua a custar o golpe que se deixa de dar.
- **Decide:** tu. A pergunta aberta é a da Fase 2: quando o Verbo 2 deixar assumir outros corpos (§24), o
  "conduzido" passa a ser mais do que o `king_id` — e aí talvez valha a pena ser coluna.

### Q-086 · O gatilho direito não tem cursor, e o §24 diz «só classe Arqueiro»
- **Decidido pelo dono (painel, 28/09/2026 — outra resposta):** «Vale para a classe arqueiro e para outras que podem
  ter uma gameplay similar ou parecida» — só marca alvos quem conduz uma classe com o verbo `mark_target` no
  `classes.csv` (hoje o Arqueiro; qualquer classe de jogo parecido ganha-o nos dados). O Monarca deixa de marcar, e
  o rodapé esconde o gatilho quando ele não faz nada (`ClassSystem.marks()`, dossiê §24).
- **Onde:** §24 (mapa de comando: *"Marcar alvo — Gatilho direito — Botão dir. do rato — **Só classe
  Arqueiro**"*), §50, `src/ui/input_router.gd`, `src/core/verbs.gd`.
- **O que faltava:** o rato tem cursor e o gatilho não, e o dossiê não diz para onde aponta o gatilho. O router
  lia os dois como rato — com o comando, o alvo media-se do sítio onde o cursor tivesse ficado. E o gatilho é
  analógico: medido, um puxão emitia seis eventos «premido» e marcava seis vezes.
- **O que foi decidido, e é reversível (GB-11):** um puxão marca uma vez, e com o comando o alvo mede-se a
  partir do rei — o `Verbs.mark` escolhe a criatura mais perto desse x, que é a mais perto de quem joga.
- **O que continua por decidir:** *"só classe Arqueiro"*. As classes jogáveis são do §08 e não existem; o
  monarca marca desde o F1-07 e continua a marcar. Quando o Verbo 2 assumir um arqueiro, esta linha do §24
  passa a ser uma condição que se pode escrever. E o alvo do comando pode ser outro: a criatura mais perto **na
  direcção para onde o rei olha**, ou a mais perto **que a candeia mostra** (§74: *"fora, não"*).
- **Decide:** tu, no primeiro *playtest* com comando.

## Decididas na auditoria de gameplay de 26/09 (reversíveis)

> O dono do repositório autorizou a aplicar o relatório `docs/recovery/AUDITORIA-GAMEPLAY-2026-09-26.md` inteiro
> (26/09/2026). Cada entrada diz o que ficou decidido, onde, e como se reverte. Os tickets são os AUD-01 a AUD-05.

### Q-115 · A quem serve uma moeda largada
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Para coisas como troca de modo, não é simplesmente
  largar a moeda, o jogador deve selecionar para o que quer trocar» — o modo do celeiro escolhe-se com o Verbo 2 em
  cima dele (`ConversionSystem.choose`, `Verbs.choose_mode`), e a moeda só paga. Fecha o que estava em aberto.
  `tests/conversion_test.gd`.
- **Onde:** §02 (*"tudo o que o jogador faz passa pela moeda"*), §55, §61, Q-112; auditoria D1 e D5.
- **O que estava:** a moeda pousada servia quatro leitores pela ordem do tick (obra → treino → celeiro → quem a
  foi buscar → quem a pisa) e nenhum sabia quem a largou nem para quê. A venda do celeiro trocava-lhe o modo
  sozinha, e a moeda largada ao lado de um vagabundo pagava a Casa de Treino onde ele nascera.
- **Decidido (AUD-01):** o destino resolve-se **no gesto**, pela mesma conta do painel de contexto e do
  `PriceTag` — o sítio de obra debaixo do rei, ou nenhum (`CoinTarget.slot_at`) — e vai na moeda
  (`CoinSystem.targets`). Só esse sítio a absorve (obra, reparação, treino ou celeiro); uma moeda que caiu de
  outra coisa (venda, caça, saque) apanha-se e não paga nada. O `PriceTag` deixa de mostrar o preço de quem está
  ao lado quando há uma obra a cobrar. Ninguém por recrutar nasce dentro de um sítio de obra (o `Greybox`
  mudou-os de sítio). E o rei não volta a pôr no saco a moeda que acabou de largar enquanto alguém por
  recrutar estiver ao alcance dela (`Verbs.awaited`) — largar ao lado de alguém chega a ele.
- **Em aberto:** o celeiro troca de modo a **cada** moeda que lá pousa; largar em contínuo troca-o de um lado
  para o outro. Uma alternativa é a moeda só trocar se não houver outra no ar para o mesmo sítio.
- **Reverte-se:** `CoinTarget.QUALQUER` em todas as moedas volta ao raio antigo.

### Q-116 · Um muro a subir de degrau continua a ser o muro que era
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** fica como está.
- **Onde:** §10, §55; auditoria D4.
- **O que estava:** pagar o degrau seguinte punha o muro em andaime, e um andaime não travava, não levava
  golpes, não tinha slots de contacto nem postos. Melhorar o muro à tarde abria a porta à noite.
- **Decidido (AUD-01):** `BuildSlot.upgrading()` — pago, em andaime, com o degrau de baixo de pé — e
  `BuildSlot.holds()`. Enquanto sobe, o muro trava, leva golpes (perde vida sem parar a obra), mantém os slots de
  contacto e os postos do degrau que tem, e publica também a vaga de obra. Derrubado durante a obra, cai em
  ruína e perde o degrau pago. Acabada a obra, fica com a vida inteira do degrau novo. Desenha-se o muro velho
  dentro do andaime.
- **Reverte-se:** `holds()` a devolver `standing()`.

### Q-117 · A certeza da torre é de quem está nela
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** fica como está.
- **Onde:** §07 (*"a torre não dá dano — dá certeza"*), §10; auditoria D3.
- **O que estava:** o bónus ia com o **posto** (`job_id`): 100% de precisão e +40% de alcance a 500 px da torre.
- **Decidido (AUD-01):** `Posts.present()` — o posto dá o que dá a quem está dentro da largura da obra que o
  publicou (`JobSlot.holds`). A caminho, a fugir ou atrás da luz da alvorada, dispara como em campo aberto. O
  `dez_dias` foi medido outra vez e não mudou.

### Q-118 · A morte do rei, enquanto não há sucessão
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** fica como está.
- **Onde:** §15, §16 (*"Morte do rei — se houver sucessor, ele assume no amanhecer; se não houver, interregno"*;
  *"Derrota — todos os personagens jogáveis mortos e sem sucessor"*); auditoria D6.
- **O que estava:** o rei morria como qualquer tropa e a partida continuava sem ninguém para comandar.
- **Decidido (AUD-01):** até haver herdeiro, a morte do rei é a derrota, com o mesmo ecrã que o núcleo caído
  (`Defeat.happened()`, uma regra só, lida pelo menu, pela entrada, pelo painel e pelo arranque). A sucessão do
  §15/§16 é o AUD-05.

### Q-119 · Gravar quando quem joga para
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** fica como está.
- **Onde:** §62; Game Accessibility Guidelines (*save anytime*); auditoria D11.
- **O que estava:** só o autosave da alvorada; fechar o jogo a meio do dia perdia até seis minutos.
- **Decidido (AUD-01):** grava-se também ao pausar e ao fechar a janela (ou ao deixar a aplicação), **só de
  dia** e com a partida viva (`SavePoint`). À noite fica o save da alvorada: a noite tem estado que o save não
  leva (o intervalo da invocação, a oferta a meio, o que a noite já levou). Retomar deixou de repetir a fase em
  que se gravou (D2, sem pergunta: era um defeito).

### Q-120 · O coelho do 1:10 num dia de outra duração
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «As criaturas que nascem para ser caçadas e gerar
  dinheiro nunca nascem todas ao mesmo tempo e todas de uma vez, é sempre progressivamente e de forma suave e
  estável» — é o que as tocas da Q-106 fazem: cada arbusto solta um bicho de cada vez, espaçado ao longo do dia, e o
  dia não abre com a caça toda de uma vez. `tests/abertura_natural_test.gd`.
- **Onde:** §25 (minuto 1:10), §26 (*slider* de 240–540 s); auditoria D10.
- **Decidido (AUD-01):** cai no mesmo **ponto** do dia (`HuntWatch.intro_at`), e não ao mesmo segundo.

### Q-121 · A obra com posto pede quem lá trabalhe
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** fica como está.
- **Onde:** §06 circuito 1, §52; auditoria §5.3 (P-B).
- **O que estava:** a produção somava a todas as obras de pé e o posto do canteiro não mudava nada.
- **Decidido (AUD-02):** uma obra com posto rende inteiro com alguém no posto **e dentro dela** (`Staffing`), e
  `unstaffed_yield` (0,25, `_proposed`) sem ninguém — só nas fases em que o posto é urgente (`jobs.csv`): de
  noite o canteiro não pede ninguém e não é por isso que rende menos. O galinheiro e o pesqueiro do greybox não
  têm posto e rendem sozinhos. Retomar um save não penaliza a primeira fase (não se viu quem lá esteve).

### Q-122 · De onde vem gente nova
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** fica como está, com o arranque da Q-110 (duas
  tropas tuas, o resto nos acampamentos) e o ânimo da Q-102 (animado chega mais um; abatido não chega ninguém).
- **Onde:** §02 (o Kingdom desmontado), §25; auditoria (achado do Lote 2).
- **O que estava:** a população por recrutar acabava em nove pessoas — o dossiê não tem fonte de vagabundos — e
  a manutenção (grátis até à oitava tropa) nunca chegava a morder.
- **Decidido (AUD-02):** um vagabundo por alvorada (`vagrants_per_dawn`) num dos dois acampamentos do greybox,
  fora das muralhas de fora, alternando o lado, até haver `vagrant_camp_cap` (4) vivos por recrutar. O greybox
  nasce com o teto cheio: o acampamento repõe quem recrutaste.

### Q-123 · A ganância do teu rei
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** fica como está.
- **Onde:** §15 (*"a percentagem do rendimento diário que desaparece para os nobres"*; *"sorteada de novo"* na
  sucessão), §06 (o modelo já a cobrava).
- **Decidido (AUD-02):** sorteada no início, no fluxo `world`, dentro do perfil `start_greed_profile`
  (`balanced`, 20–35); vai no save (`GameState.greed`) e leva a sua parte da produção antes de ela virar moeda.
  A caça não paga nobres (é moeda física do teu caçador). O painel mostra-a ("NOBRES 27%"). Os efeitos do perfil
  (moral de elite, elite grátis, impulsos a metade) e a Feira Livre (+15) ficam para quando houver elite e
  sucessão.

### Q-124 · A manutenção do exército, na partida
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** fica, com o soldo em atraso da Q-144 por cima: o
  que falta fica a dever-se em vez de se perdoar.
- **Onde:** §06 sorvedouro 1 (três escalões); auditoria D7 e §5.4 (P-D).
- **Decidido (AUD-02):** paga-se na alvorada, do saco do rei (`UpkeepSystem`); a fração que o dia não fecha
  passa ao seguinte. Sem moedas para a parte inteira, a dívida do dia perdoa-se e **uma** tropa vai-se embora —
  a mais barata sem posto — e volta a poder ser recrutada. O rei e o escudeiro não contam. O painel mostra o
  soldo do dia ("SOLDO 0,5/dia"). Com a produção a crescer ao `income_growth` e a ganância, **a economia do jogo
  passa a ser a do modelo**: o dia da asfixia calculado sobre as obras do greybox e a caça média cai no dia 10,
  dentro do alvo 9–14 (`economia_jogada_test`). A Colheita Forçada passa a compensar a partir do dia ~10 com as
  sete fontes; o modo capacidade do celeiro continua dominado pela venda (Q-112, em aberto).

### Q-125 · De que lado vem a noite, e quando se sabe
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** fica como está.
- **Onde:** §05, §51; Into the Breach e Thronefall (auditoria §6); auditoria §5.5 (P-F).
- **O que estava:** o lado sorteava-se no próprio crepúsculo, e a composição não se mostrava.
- **Decidido (AUD-03):** o lado sorteia-se **na passagem para a tarde**, no mesmo fluxo `rot` e com a mesma
  conta — nada do fluxo corre entre a tarde e o crepúsculo, por isso as noites de uma semente são as mesmas —, e
  vai no save (`RotSystem.announced`). Diz-se no mundo (a candeia acende-se no horizonte dessa borda) e no guia
  ("A NOITE VEM DE LESTE"). A composição continua por dizer: vê-se chegar.

### Q-126 · O ritmo da noite
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «O conceito dA candeeia foi alterado, ajuste isso» —
  o aviso da tarde passa a ser o Lume da ADR 0034: acende-se na base dela, no horizonte da borda de onde a noite vem,
  em violeta, e maior numa noite funda. O ritmo (uma funda de seis em seis, a seguinte calma) fica.
- **Onde:** §74 (a massa termo a termo); a Lua de Sangue do Kingdom e o *relax* do AI Director (auditoria §6, P-H).
- **Decidido (AUD-03):** de `peak_every` (6) em 6 noites uma **funda** (massa × 1,3), e a seguinte **calma**
  (× 0,6); sabe-se de véspera e diz-se à tarde ("NOITE FUNDA"), com uma candeia maior no horizonte. Os três
  números em `rot.csv`, em `_proposed`; a tabela `ROT_BY_DAY.md` mostra-os. A noite 10 (o Cavador) não é funda.

### Q-127 · Alimentar a Podridão com moedas
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** fica como está.
- **Onde:** §05 (*"Alimentar — deixar sacrifícios (animais, tropas fracas, ouro) reduz a massa. Sinistro,
  eficaz, e mecanicamente honesto: transformas economia em segurança"*), `rot.csv` (`sacrifice_mass_per_coin`,
  que nenhum sistema lia).
- **Decidido (AUD-03):** as moedas que **o rei** largou sem outro destino, pousadas dentro da mancha, somem nela e
  tiram-lhe `sacrifice_mass_per_coin` (0,5) de massa cada; a do prato de uma oferta aberta é da oferta; a que caiu
  de quem morreu não é sacrifício. Sai o `rot_fed` da §46 e uma legenda. O guia di-lo com o rei dentro da mancha
  e com moedas. Os animais e as tropas fracas ficam por fazer.

### Q-128 · Quem não tem posto, de noite
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** fica como está.
- **Onde:** §25 (*"o vagabundo segue-te"*), §52; auditoria §5.5 e D13 (P-C).
- **O que estava:** quem não tinha posto seguia o rei também de noite — para fora do muro, ou para o meio de um
  castelo de 480 px enquanto as criaturas mordiam a borda.
- **Decidido (AUD-03):** do crepúsculo à alvorada forma-se (`Muster`): quem luta vai para a borda do núcleo do lado
  da noite, para dentro, um a seguir ao outro; quem não luta recolhe ao núcleo; o escudeiro fica com o rei; quem
  treina continua a treinar. Medido: a vistoria passa de 3 para 8 dias, e a defesa mais fraca do `dez_dias` de
  cair ao dia 2 para cair ao 7.

### Q-129 · O Alado rouba galinhas (fecha a Q-077)
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** fica como está.
- **Onde:** §06 (galinheiro, *"galinhas roubáveis à noite"*), §07 (*"Dia 4 — obriga a torre alta"*); a Q-077
  media o Alado a pousar no castelo sem custar nada a ninguém; auditoria P-J.
- **Decidido (AUD-04):** quem voa (`flyer`) vai ao galinheiro de pé mais perto dele (`stealable_at_night`), leva
  **uma** galinha e volta para a borda de onde a noite veio (`Thieves`). Se chegar vivo à alvorada, o galinheiro
  perde `chicken_theft_matter` (1) da matéria — a produção do dia seguinte —, nunca abaixo de menos um dia de
  rendimento; abatido pelo caminho, não leva nada. Sem galinheiro de pé, segue para o núcleo como antes. A
  `barrier()` continua a filtrar por faixa: a resposta ao Alado é a torre alta entre a borda e as galinhas, e não
  um muro que ele não vê. Sai o `material_consumed` da §46 e uma legenda.

### Q-130 · As cavidades do subsolo têm um poço
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** fica como está.
- **Onde:** §11 (*"ao aceder a uma passagem secreta encontras níveis, porões"*), §06 (poço de minério, rocha,
  *"atrai Cavadores"*), `segments.csv` (`cavity_slots`, que ninguém lia); auditoria P-I.
- **Decidido (AUD-04):** uma cavidade de cada lado, atrás da passagem (`Cavities`, ±1060 px do núcleo), com um
  sítio de poço de minério **no subsolo**. A cavidade é rocha, e por isso o `requires_biome_feature = rock` do
  poço cumpre-se lá em baixo em qualquer bioma. Não tem posto (ninguém mais desce): rende sozinho, e as moedas
  dele caem no subsolo, onde só o rei as apanha — é a expedição de dia. O `ore_pit` passa à Fase 1. O perfil
  `balanced` do §06 continua a contar as sete fontes da superfície: o poço fica fora, como a caça.

### Q-131 · O poço chama o Cavador
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** fica como está.
- **Onde:** §06 (*"atrai Cavadores"*), a tag `attracted_by_mine` do Cavador; auditoria P-I (*"a própria tag é o
  custo"*).
- **Decidido (AUD-04):** com um poço de pé, o Cavador pode ser invocado `mine_lure_days` (3) noites mais cedo —
  do dia 7 em vez do 10. É o preço da renda do subsolo. Em `rot.csv`, em `_proposed`.

### Q-132 · A escora fecha a passagem
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** fica, e a parte que estava por fazer fez-se:
  abrir uma passagem escorada é o preço de *O que enterraste* (Q-099), e uma escora das tuas desmonta-se com o Verbo
  2 (Q-138).
- **Onde:** §51 (*"se o caminho de superfície estiver selado, a mancha usa a faixa subterrânea"*), §25 (minuto
  12:00, *"um Rastejante entra pela passagem que abriste"*), a oferta *O que enterraste* (`sealed_passage`);
  auditoria P-I e AUD-04 (*"o Cavador do dia 10 não tem resposta"*).
- **Decidido (AUD-04):** cada boca de passagem tem um sítio de **escora** (`passage_seal`, 10 moedas, em
  `buildings.csv` com `_proposed`). De pé, a passagem fecha **para toda a gente**: o Cavador não sobe por ela e
  o rei não desce. Um lado com todas as passagens escoradas não deixa caminho ao subsolo, e a mancha desse lado
  não gasta massa em quem vem por baixo — compra o que vem por cima (o espelho da frase do §51). É para sempre
  nesta região: fechar o subsolo de um lado é perder o poço e a câmara desse lado. Abrir uma passagem escorada
  (o preço da oferta *O que enterraste*) fica por fazer.

### Q-133 · O herdeiro
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** fica, com a Q-137 e a Q-146 por cima: o sucessor
  nasce no castelo, e com ele pronto a morte do rei pergunta se continuas com um monarca novo.
- **Onde:** §15 (*"Treino — 10 dias na Casa do Herdeiro. Custa 5 moedas/dia"*; *"a Ganância é sorteada de novo"*),
  §16 (*"se houver sucessor, ele assume no amanhecer"*), `economy.csv` (`heir_training_days`,
  `heir_cost_per_day`, que ninguém lia); auditoria D6 e AUD-05.
- **Decidido (AUD-05):** a casa do herdeiro tem sítio no *greybox* (fora do muro de fora, a oeste, do outro lado
  do celeiro) e passa à Fase 1. De pé, cada alvorada tira um dia de treino ao saco do rei (5 moedas; sem elas,
  nesse dia não treina). Com o herdeiro formado, a morte do rei **deixa de ser derrota**: o guia diz "o herdeiro
  assume ao amanhecer", e na alvorada seguinte ele nasce na casa, sem moedas, com a ganância sorteada de novo, e o
  treino recomeça do zero. Saem `king_died` e `succession_started` da §46.
- **Sem herdeiro continua a ser derrota:** o interregno do §16 (3 dias sem construir, ganância 80) pede outro
  personagem jogável que o atravesse, e na Fase 1 o monarca é o único. Os 60% de *boosts* herdados ficam para
  quando houver *boosts* que durem; a evolução da classe é do império e fica.

### Q-134 · O que fica quando se perde (fecha a Q-088)
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** fica, sem a evolução da classe (Q-140): num jogo
  novo volta-se a ganhar.
- **Onde:** §16 (*"Decay em vez de reset... mantém: Sementes Reais, classes desbloqueadas, mapas revelados,
  segredos encontrados, e 40% das estruturas do império principal"*), `economy.csv` (`decay_structures_kept`).
- **Decidido (AUD-05):** na derrota escreve-se o **legado** (`Legacy`) — as Sementes Reais, os segredos achados,
  as conquistas, o plano da campanha, a região em que se estava e as obras que ficam — e **os saves da partida
  perdida apagam-se**: perder
  não se desfaz a recarregar a alvorada de antes. Ficam as obras de pé mais caras (por moedas investidas; no
  empate, por id), `round(40% × obras de pé)`, sem o núcleo nem as ruínas. O jogo novo (o botão da derrota, ou
  abrir o jogo outra vez) monta a região e levanta-as no mesmo sítio, no mesmo degrau e caminho, inteiras. O
  ecrã da derrota diz o que fica.

### Q-135 · Uma região acaba: a travessia
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** aprovada, e mudada no mesmo painel pela Q-146: «o
  rei nunca sai para longe do reino». A travessia passa a **marcha** (ADR 0035): o Verbo 2 na bifurcação manda quem
  está perto conquistar o povo seguinte, e o rei fica. A Q-159 pede-te que confirmes a troca.
- **Onde:** §16, §21, §83 (*"a bifurcação a leste"*), §79 (os três finais, ADR 0018); Kingdom Two Crowns (a ilha
  seguinte) e Against the Storm (a região como *run* curta); auditoria P-K (*"não há objetivo depois do dia 3"*).
- **Decidido (AUD-05):** a partir da manhã do dia `crossing_day` (11 — depois das dez noites do §66), o Verbo 2
  na bifurcação, de dia, **acaba a região**: o rei leva o saco e quem é teu e está a `crossing_party_px` (120)
  dele; as obras ficam para trás (a região seguinte é outra). Os saves da região atravessada apagam-se e o jogo
  novo começa a região seguinte da campanha (`GameState.region`) com a comitiva, o saco, as Sementes, os segredos
  e o mesmo plano de capítulos. Depois da última região vem o **epílogo** (`NightWatch.epilogue()`, §79): o ecrã
  diz "Fim da campanha · União/Domínio/O Turno", e o jogo novo começa uma campanha nova com o que o §16 guarda.
  Antes do dia, a bifurcação diz em que dia abre. Sai o `segment_entered` da §46 com o tipo `crossing`.
- **O que fica por fazer:** a região seguinte é montada pelo mesmo *greybox* (o bioma dela está no plano, as
  cenas não); voltar a uma região deixada e retomá-la com *decay* (P-K) espera pelas regiões com cena.

### Q-136 · Melhorias com variante
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** fica como está.
- **Onde:** §10 (a escolha A/B da muralha: *"nunca dá para ter as duas"*); Thronefall (auditoria P-N: *"upgrades
  com variante, não mais edifícios"*).
- **Decidido (AUD-05):** a torre de arqueiros e o canteiro ganham uma **variante B** (`variant_params` em
  `buildings.csv`, sobre o `effect_params`): a torre de **cadência** perde os 40% de alcance e dispara com 75% do
  intervalo; o canteiro **resguardado** não para nem é arrasado no rasto da Podridão e rende 75%. A variante A é a
  de sempre. Escolhe-se com o Verbo 2 com o sítio vazio e sem moeda, e fica; vai no save. Os três números em
  `_proposed`.

## Da auditoria de gameplay de 27/09 — decididas (reversíveis) e abertas

> O dono do repositório pediu para aplicar o relatório `docs/recovery/AUDITORIA-GAMEPLAY-2026-09-27.md` (27/09/2026),
> auditado sobre a `main` em `568c568`. Os defeitos que não pediam decisão de design corrigiram-se (N1, N3, N4, N5,
> N7/N8, N9, e a parte do N2 que a Q-133 já decidia). O que pede decisão fica aqui aberto, com a recomendação do
> relatório — **não é regra aprovada**. Os tickets são os CONT-01 a CONT-12 (`docs/backlog/`).

### Q-137 · Herdeiro formado sem casa (N3)
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Não sei nem o que é o treino, mas o sucessor só
  nasce no castelo, e ele deve existir para poder continuar, se não houver a partida acaba» — o treino são os 10 dias
  em que o herdeiro aprende na casa dele (5 moedas por dia, Q-133). O sucessor nasce agora **no castelo**
  (`Succession.castle()`), e só há sucessão com o herdeiro formado e o castelo de pé (`Succession.possible()`); sem
  isso, a partida acaba. `tests/sucessao_test.gd`.
- **Onde:** §15, §16, Q-133; `Defeat.happened()`, `Succession.crown()`.
- **O que estava:** o `Defeat` só lia o treino; a coroação pedia também a casa de pé. Com herdeiro formado, rei
  morto e casa em ruína, o jogo não acabava e ninguém era coroado.
- **Decidido (opção mais simples):** uma só condição, `Succession.possible()` — herdeiro formado **e** casa de pé —,
  lida pelo `Defeat`, pelo guia e pela coroação. Sem casa ele não tem onde nascer, e é derrota; a casa a cair com o
  rei já morto também acaba a partida (`game.gd` pergunta ao `Defeat` a cada desabamento).
- **Fica por decidir:** se o treino sobrevive à perda da casa e, nesse caso, onde nasce o sucessor.

### Q-138 · A escora fecha por cima (N4)
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Depende do que é o subsolo, se for o subsolo de uma
  construção o jogador pode fechar ou abrir [...] mas há subsolos que a entrada/saída é sempre aberta» — uma boca com
  sítio de escora é das tuas: a escora fecha-a, e o Verbo 2 em cima da escora desmonta-a e abre-a outra vez
  (`Passages.unseal()`; fechar volta a custar). Uma boca sem sítio de escora é natural e fica sempre aberta. O guia
  diz-o (`CONTEXT_SEALED`). `tests/escora_abre_test.gd`.
- **Onde:** Q-132; `Verbs.destination()`, `Passages.open()`.
- **O que estava:** as duas escoras de pé com o rei no subsolo tiravam-lhe todas as saídas.
- **Decidido (opção mais simples):** a escora fecha a boca **por cima**: ninguém desce e o Cavador não sobe, mas quem
  está em baixo e pode mudar de faixa (hoje, só o rei) sobe por ela. O sinal e o gesto continuam a ser a mesma conta.
- **Fica por decidir:** a Q-132 diz que fechar um lado perde o poço e a câmara desse lado, mas o subsolo do *greybox*
  é um corredor contínuo — ou as cavidades passam a isolar-se por lado, ou o texto passa a descrever o corredor.

### Q-139 · O legado é uma transação (N7, N8)
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** fica como está.
- **Onde:** §16, §62, ADR 0007; `LegacyStore` (novo, `src/core/legacy_store.gd`).
- **Decidido (CONT-01):** o legado escreve-se num temporário, lê-se de volta, compara-se e renomeia-se; só então se
  apagam os slots. Se falhar, os slots ficam e o ecrã do fim di-lo (`UI_LEGACY_FAILED`) em vez de anunciar a
  travessia. O jogo novo aplica-o a um mundo novo e grava logo o primeiro save; é esse save — numerado acima da
  sequência guardada na moldura do legado — que o gasta (`LegacyStore.settle()`, no arranque). Um fecho entre dois
  passos repete o que faltava; aplicar a um mundo novo não duplica nada. Legados sem moldura leem-se na mesma.

### Q-140 · O que o legado leva: variante e classe (N1, N2 em parte)
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «A classe é desbloqueada para o jogo novo, mas a
  evolução dela não, isso deve ser novamente obtido jogando…» — o legado da derrota deixa de levar a fase da classe
  (`Legacy.of()`); a travessia continua a levá-la dentro da mesma campanha (`Legacy.crossing()`), e o fim da campanha
  apaga-a (`Legacy.end_campaign()`). `tests/legado_test.gd`.
- **Onde:** §16 (*"classes desbloqueadas"*), Q-133 (*"a evolução da classe é do império e fica"*), Q-134, Q-136.
- **Decidido:** cada obra retida leva a variante (uma torre B volta B); o legado da derrota e o da travessia levam a
  fase da classe do rei, e o jogo novo nunca a baixa. Um legado sem estes campos fica com os de raiz.

### Q-141 · O trabalho da fase vai no save (N5)
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** fica como está.
- **Onde:** Q-121 (*"a primeira fase depois de retomar não é penalizada"*); `Staffing`, `SimSave`.
- **Decidido (CONT-03):** o `Staffing` grava a fase que observa, quem já serviu nela e quem serviu na que acabou.
  Retomar e jogar de seguida fecham a fase igual. Um save anterior não tem o campo e ninguém é penalizado.

### Q-142 · A vistoria acaba quando o jogo acaba (N9)
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** fica como está.
- **Onde:** Q-081, Q-128; `tools/vistoria.gd`.
- **Decidido:** a vistoria pára com o `Defeat.happened()` — núcleo, ou rei sem sucessão possível — e diz a causa.
  Os "8 dias" da Q-128 mediam só o núcleo; um número de dias sobrevividos cita a versão e a regra de derrota.
  Medido a 27/09 sobre a `568c568` com estas correções: `make vistoria DIAS=10`, semente 20260916 — *"4 de 10 dias,
  o rei caiu sem herdeiro — sem invariantes quebradas"* (antes: núcleo no dia 7). É um piloto, não todo o jogador.
  Com a política cautelosa (`-- --cauteloso 1`: de noite o rei fica do lado do núcleo onde a mancha não está),
  a mesma semente chega ao dia 6. A contabilidade por dia (`tools/contabilidade.gd`) mostra porquê o piloto
  morre pobre: produção recolhida 1–12 moedas/dia contra a base de 17 com as sete fontes, e o grosso das moedas
  largadas é o rei a largar e a apanhar as mesmas.
- **Fica por fazer (CONT-05):** separar a estabilidade da simulação, a resistência de uma defesa pronta e um piloto
  que começa com as seis moedas, paga pela bolsa e chega à travessia com a voz ligada.

### Q-143 · O que atravessa uma região, além do que já vai (em parte decidida)
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «O herdeiro não se trata de uma nova campanha do
  zero, por isso ele herda dívidas e consequências dessa campanha, o herdeiro é uma segunda chance, não um jogo novo»
  — fecha a primeira metade do que estava aberto: a Dívida da Candeia não se separa em operacional e de campanha, e
  o herdeiro fica com tudo o que o rei deixou — a Dívida, o soldo em atraso (Q-144), a memória da morte dele no
  ânimo (Q-102) —; só a ganância se sorteia de novo (§15). A identidade da comitiva continua aberta, e passa à
  marcha (ADR 0035): quem volta volta com o mesmo tipo, sem título, ferimentos nem moedas.
- **Onde:** §16, Q-133, Q-135, §79; `Legacy.crossing()`, `NightWatch.epilogue()`.
- **O que está:** a travessia leva Sementes, segredos, conquistas, plano, saco, a fase da classe (Q-140) e os
  **tipos** de quem está perto. Zera a Dívida da Candeia, os povos soltos/retidos e o treino do herdeiro; a comitiva
  perde identidade, título, ferimentos e moedas, e a proximidade não olha à faixa. O epílogo lê só a região corrente.
- **Recomendação do relatório:** separar dívida local de memória da campanha; histórico de povos acumulado; um
  *snapshot* mínimo da comitiva; decidir se o treino do herdeiro acompanha a corte. O que se zerar diz-se no resumo.
- **Decidido (CONT-02, opção mais simples e reversível):** a travessia leva **tal e qual** a Dívida da Candeia, os
  povos soltos, retidos e perdidos, e o treino do herdeiro (`CampaignMemory`); o epílogo lê assim a campanha
  inteira. Ficam locais as recusas por dia, as ofertas usadas e a massa da Podridão. A derrota não os leva (não
  estão na lista do §16). A comitiva passa a ser só de quem está perto **e na faixa do rei**. O ecrã da travessia
  diz o que vai (`UI_CROSSING_MEMORY`). Depois da **última** região só o Turno leva a memória à campanha seguinte;
  a União e o Domínio acabam-na (§79, `CampaignMemory.carries()`).
- **Continua aberto:** separar a dívida operacional da memória da campanha (hoje a dívida levada pesa na região
  seguinte como pesava nesta); a identidade da comitiva (título, ferimentos, moedas) — hoje só vão os tipos.

### Q-144 · Inadimplência do soldo (N6, aberta)
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Elabore um planeamento completo para implementar
  isso, você está no caminho correto» — o soldo que falta fica **a dever-se** (`UpkeepSystem.owed`) e paga-se
  primeiro na alvorada seguinte. O que se deve para lá de um dia de soldo (`wage_grace_days`) faz desertar, uma a
  uma, as tropas cujo soldo o paga — a mais barata sem posto primeiro —, e cada uma leva da dívida o que custava;
  quem desertou descansa dois dias (`deserter_rest_days`) antes de voltar a aceitar moedas — já não se recontrata por
  uma moeda no dia seguinte. O ânimo lembra-se do soldo em atraso e de cada deserção (Q-102).
  `tests/upkeep_system_test.gd`.
- **Onde:** Q-124; `UpkeepSystem`, `RecruitSystem`.
- **O que está:** sem moedas, a parte inteira em falta perdoa-se e deserta a tropa mais barata sem posto — que se
  recontrata por uma moeda. Com 25 tropas, 13,5 de soldo trocam-se por uma deserção de custo 1.
- **Recomendação:** comparar dívida de soldo, desertores proporcionais ao défice e indisponibilidade temporária para
  recontratar, sem criar a espiral deserção → menos renda → mais deserção. Depende do CONT-05 para medir.

### Q-145 · O celeiro e a Colheita Forçada (aberta)
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Vejo que elaborou bem, siga por esse caminho» — a
  capacidade do celeiro passa a exigir consumo **e** presença: o cozinheiro tem posto dentro do celeiro
  (`ConversionSystem.staff`), e sem matéria consumida não há +10%. A conta de retorno da Colheita Forçada refez-se
  com as condições reais (a ganância, o preço do dia, as fases que faltam): devolve 0,83 por moeda paga, em qualquer
  dia — o que isso quer dizer está na **Q-158**. `tests/colheita_forcada_test.gd`.
- **Onde:** Q-115, Q-124; `ConversionSystem`, `economia_jogada_test.gd`.
- **O que está:** a capacidade (+10% de vida) liga-se com um cozinheiro vivo em qualquer sítio e um produtor de pé,
  mesmo sem matéria consumida; o teste da Colheita Forçada omite a ganância e o momento da ativação.
- **Por decidir:** se a capacidade exige consumo e presença; que cenário a justifica contra a venda; e refazer a
  conta de retorno do impulso com as condições reais. Não mudar o +10% antes de medir.

### Q-146 · O que encerra uma região, e para que serve o herdeiro (aberta)
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «O herdeiro é como uma segunda chance para o rei caso
  ele morra, o rei nunca sai para longe do reino, quem vai para longe do reino são as classes jogáveis, se o
  imperador morre e o herdeiro estiver pronto, o jogador pode optar por continuar [...]» — com o herdeiro pronto, a
  morte do rei pára o jogo e pergunta: continuar com um novo monarca, ou deixar cair a coroa (`PauseMenu`,
  `end_reign`). E o rei não sai do reino: a região já não acaba com ele a atravessar — a bifurcação passa a mandar
  uma **marcha** (ADR 0035, `Realm`, `March`): quem está perto do rei, até ao teto da comitiva (Q-154), vai
  conquistar o povo seguinte, e volta ao fim de uma noite; com gente bastante, o povo passa a vassalo (Q-103). O dia
  11 continua a ser o portão da marcha. A Q-159 pede a confirmação.
- **Onde:** Q-133, Q-135; `crossing_day` 11, `heir_training_days` 10.
- **O que está:** o dia 11 são ~60 minutos (40–90 com o *slider*); o herdeiro custa 70 moedas e fica formado no dia
  11 no melhor caso — e o treino não atravessa.
- **Por decidir:** manter o dia como portão de teste e experimentar uma meta de região; escolher a função do herdeiro
  (seguro de região longa, próximo monarca da campanha, ou objetivo de permanência) antes de mexer no 10.

### Q-147 · Ofertas com preço sem sistema (aberta)
- **Onde:** §75; `OfferPrice`.
- **Por decidir:** mostrar só as ofertas que se podem de facto pagar hoje, ou dizer que estão indisponíveis.

### Q-148 · O impulso no comando (CONT-08)
- **Decidido pelo dono (painel, 29/09/2026 — aprovar a proposta):** fica como está.
- **Onde:** §24 (*"Manter Y abre uma roda de seis segmentos... Selecionar é apontar o stick e largar"*), Q-067, Q-113;
  `InputRouter.wheel_segment()`.
- **O que estava:** com teclado, Tab mantido + número escolhia o impulso; no comando não havia gesto nenhum.
- **Decidido (opção mais simples):** com Y mantido o rei pára, o painel abre e o stick aponta; largar Y usa o impulso
  apontado, e largar com o stick ao centro cancela. Os
  segmentos são os impulsos, pela ordem do Inspector (o primeiro em cima, no sentido do relógio), e o Inspector
  marca o apontado. A roda de seis segmentos do §24 continua à espera dos sistemas que ela abre (Q-067).
- **Fica por fazer:** o desenho da roda (vitral, ícones) e a razão e o custo de um impulso indisponível no sítio.

### Q-149 · Correr com o Shift esquerdo
- **Decidido pelo dono (painel, 29/09/2026 — outra resposta):** «Pode ser até 1.8 vezes a velocidade normal» —
  `king_run_mult` 1,8: a correr, o rei vai de 80 a 144 px/s.
- **Onde:** pedido do dono (28/09/2026); §24 (o mapa de comando não tem correr), §07 (o raio de presença do rei),
  §21 (a região é para atravessar a pé); `king_run_mult` em `economy.csv`, `UnitSystem.piloted_pace`.
- **Decidido (opção mais simples):** com o Shift esquerdo (ou L3 no comando) premido, só o rei anda a
  `king_run_mult` (1,6×: 80 → 128 px/s; o mapa de 48 s passa a 30 s). Sem custo e sem efeito em quem o segue.
- **Por decidir:** se correr tem preço (fôlego, moedas que caem do saco, a aura do Monarca desligada a correr) e
  se quem segue o rei acompanha o passo dele. Um correr sem custo encurta o preço do deslocamento que a auditoria
  de 27/09 (§6.5) diz ser um diferencial do jogo.

### Q-150 · Um mundo mais vivo, gerado pela semente (terras bravias)
- **Onde:** pedido do dono (28/09/2026: *"fazer o mundo ser mais vivo, ter mais animais, vegetação, e que se
  expanda de forma generativa, não seja limitado"*); §11 (os planos), §21 (a região), §22 (a profundidade),
  §80 (as duas frias), Q-135 (a travessia), `biomes.csv`, `src/world/wilds.gd`.
- **Decidido (só cenário, reversível):** o campo entre o horizonte e o caminho, a linha de árvores do horizonte
  (num `Parallax2D` a 0,5, a `motion_scale` da MidLayer do `parallax_layers.csv`) e as nuvens (a 0,03125, a da
  SkyLayer) são gerados pela semente, com tabelas por bioma da campanha. A região N é o troço N de um ruído
  que não acaba, por isso cada travessia chega a terra nova. Técnicas: grelha com tremor (espaçamento mínimo,
  sem costuras) e densidade por ruído contínuo (`FastNoiseLite`, semeado pelo `RngService.noise`) para haver
  bosque e clareira. Bichos de cenário (`Fauna`): pardais que pousam nos arbustos e fogem do rei, corvos no
  caminho, borboletas, pirilampos (enxame que muda de noite para noite), um bando pelas regras de Reynolds
  (`Flock`), gaivotas na costa, morcegos na cave. Nada entra na simulação nem no save.
- **O que ficou de fora de propósito:** coelho, veado e javali são **caça** (`wildlife.csv`, `HuntingSystem`),
  e um bicho de cenário com a mesma cara era uma mentira ao jogador; por isso nenhum bicho de cenário é caça.
  A região continua a acabar (Q-135): o "sem limite" é a campanha — cada região gerada de novo — e o cenário
  em parallax, que se desenha para lá das bordas. O rei não sai da região a pé.
- **Por decidir:** (1) se o rei deve poder andar para lá da região, nas terras bravias, ou se a travessia é a
  única maneira de avançar; (2) se a caça deve nascer das mesmas manchas de bosque (Kingdom Two Crowns: os
  veados nascem junto às árvores); (3) os sprites são rectângulos desenhados em código, à espera de arte a sério
  (ASSET_REGISTER) — trocar é mudar o `FloraArt`/`FaunaArt`, não o gerador.
- **O (1) respondeu-o a Q-154 (29/09/2026):** o mapa estende-se seis ecrãs de terras bravias para cada lado
  (`Greybox.BRAVIAS_ECRAS`), e o rei anda lá; a região continua a não se atravessar a pé — conquista-se pela marcha
  (Q-159). Ficam o (2) e o (3).

## Resolvidas na v5.2 (reversíveis)

| # | O quê | Decisão | Onde |
|---|---|---|---|
| Q-019 | §30 escolhe criatura ao acaso; §51 manda "a mais cara que cabe" | **§51 manda** (`pick_rule`); o F1-08 corrige o código do §30 | `rot.csv`, ROT_BY_DAY |
| Q-020 | §42: sementes por XOR com constantes que não são hexadecimal (`0xR0T7`, `0xEC0N`); o código usa `hash(str(seed) + nome)` | o código manda; a tabela passa a dizer "derivada do nome do fluxo" | §42 |
| Q-021 | §47 manda `DAY_SECONDS` para a `EconomyCurve`; a §69 cria o `ClockData` | `ClockData` | ADR 0006 |
| Q-022 | ids em português nos exemplos (`enramados_arqueiro.tres`, `enramados_ferreiro_body`) contra a regra "código em inglês" | inglês | NAMING_BIBLE §5 |
| Q-023 | §22 "uma camada por slot" contra §58 "um ficheiro por slot" | fonte: um ficheiro por corpo com camadas; exportação: uma folha por camada com o nome da §58 | ASSET_BIBLE §2 |
| Q-026 | relatório mestre: `waves.csv`, `jobs.csv`, `GREYBOX_RULES` em `docs/design/` | `rot.csv` (§70); `jobs.csv` = postos; `docs/world/` | CONTENT_DATABASE §4 |
| Q-027 | §49 lê `yield_per_phase`; o §06 dá números por dia | o CSV guarda por dia; o sistema divide pelas fases | `building_data.gd` |
| Q-032 | sete correções aos ficheiros do dia zero (C-01 a C-07) | aplicadas | ADR 0009 |

## Resolvidas na Parte XIII (reversíveis)

| # | O quê | Decisão | Onde |
|---|---|---|---|
| Q-037 | A noite é azul profunda (§05) ou castanha (§80)? | **castanha** — 32° · 0,22 · 0,16, chão em 0,11 | ADR 0011, `clock.csv` |

