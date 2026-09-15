# 22 — Arte · Pipeline de pixel art e a paleta mestra

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Esta secção foi reescrita à volta das três referências que deste. A especificação continua a derivar de como desenhas (§01) e a paleta continua a ser a tua — mas agora há três coisas que não havia: a lei da escala dupla, a pilha de iluminação, e a fonte arquitetónica de cada povo. O plano de produção foi refeito em consequência, e o cenário encolheu.

## As três alavancas — o que cada referência ensina, e qual delas é tua

Medi as cinco capturas (§01) e fui ver como cada jogo é feito. A conclusão útil é que os três resolvem "cenário bonito" com alavancas diferentes, e que só uma delas é diretamente tua.

**Milki Delivery — forma e calma** — Câmara lateral, como a tua. Desenhado à mão na Unity por três pessoas, num jogo de 2–4 h. Poucas formas, grandes, com ar à volta: 30% do ecrã sem nada contornado, e uma rampa contínua de detalhe do topo para a base (2,9×, medido). É a alavanca que te falta — e é de composição, não de técnica.

582–640 px de tela efetiva, menos de metade da tua. A beleza não está nos pixels: está no deferred lighting, nos bump maps pintados peça a peça, no SSAO simulado, nos LUTs e nas camadas de névoa e raios ao amanhecer. Seis anos e oito pessoas. A alavanca é aproveitável; o orçamento não.

799×450 de tela efetiva. Feito por um designer de arquitetura que desenha cada local com princípios de desenho urbano — marco, limiar, bordo, percurso (§21). É a alavanca mais barata das três: não custa horas de pintura, custa uma hora de planta antes de desenhar.

> **A ordem por que te servem**
>
> Arquitetura primeiro (é grátis), composição a seguir (é a lei da escala dupla e a regra do céu), luz por último (é onde está o retorno maior por hora, mas só depois de haver o que iluminar). Fazer luz sobre uma cena mal composta é pôr um filtro caro num problema barato.

## O veredito sobre a resolução — e porque é que ela fica onde está

A tentação, depois dos números do §01, é baixar para 640×360 e ficar em pé de igualdade com o Eastward. Não. A tua arte de personagem está desenhada a 1:1 nesta grelha, perde 6,3% dos pixels a reduzir, e é o teu ativo mais valioso e o mais difícil de refazer. A regra de ouro do §01 mantém-se: é a grelha de autoria que manda.

O que muda não é a resolução — é a densidade de desenho dentro dela. E o cálculo é direto:

| Elemento | Na referência | Na tua grelha | Consequência |
| --- | --- | --- | --- |
| Contorno de silhueta | 1 px | 2 px | Peso aparente igual ao das referências. Podes obtê-lo por shader de dilatação, sem redesenhar nada (ver a pilha de iluminação, abaixo). |
| Contorno interno e detalhe de personagem | 1 px | 1 px | A exceção deliberada. As figuras ficam ao dobro da resolução do mundo e destacam-se sem ajuda de UI. |
| Erva, telha, junta de pedra, caixilho | 1 px | 2 px | Metade das decisões de pixel por metro quadrado de cenário. |
| Cluster mínimo em cenário | 1×1 | 2×2 | Nada de pixels soltos no mundo. Pixels soltos = ruído a esta densidade. |
| Detalhe nas camadas distantes | 2 px | 4 px | Montanha e copa distante são massa, não textura. |
| Grelha de tile | 16 px | 32 px | Já é o teu valor. Confirma-se: 32 na tua grelha = 16 na delas. |


> **Como se verifica que a lei está a ser cumprida**
>
> Não é a olho. A métrica é cores distintas numa janela de 16×16 px, medida na imagem final. Nas referências, em cena aberta, ela sobe do topo para a base assim: ~13–18 no céu, ~21–26 no plano médio, ~30–53 no primeiro plano. Se o teu topo de ecrã medir 40, tens ruído a fingir de paisagem. O guião de medição está feito e corre sobre qualquer captura tua — mede-te a ti como os mediu a eles.

| Parâmetro | Valor | Origem |
| --- | --- | --- |
| Render alvo | 1280 × 720 | Medido: as duas cenas são 1:1 nativo a 720 px de altura |
| Região | 4–6 ecrãs × 720 | Derivado do tempo de travessia (§21) |
| Linha do solo | ≈ 500–540 | Proposto e derivado em §11 — a fixar na Fase 0 |
| Corte de solo | 180–220 px | Proposto em §11 |
| Grelha de tile | 32 px | Autora em 64×64 como já fazes; 64 = 2×2 tiles |
| Escala 1 — escudeiro | 32–36 px | Escudeiro do trono |
| Escala 2 — aldeão/tropa | 46–52 px | Empire troop de 47 px |
| Escala 3 — monarca/elite | 56–62 px | O rei |
| Casa pequena | ≈ 120 × 130 px | Ferreiro da panorâmica — indicativo, a confirmar em jogo |
| Animação | 10 fps | Idle 6 frames (como já fazes) · andar 8 · ataque 5 · morte 7 |
| Parallax | 6 camadas | céu · montanha · colina · fundo médio · jogo · primeiro plano |


> **Revisto na Parte XIII**
>
> O Bloco 4 muda de ordem e o parallax fica mais barato: ver §80. Três valores de silhueta entram na paleta e a noite passa a castanha.

## A paleta de trabalho — 112 cores, sete famílias

Extraída das duas cenas (104 + 115 cores opacas, 137 únicas combinadas, 112 acima do limiar de ruído). É a rampa atual de arte em curso, não uma paleta fechada — a caixa no fim desta secção diz quando e como se fecha. Passa o rato por cima para ver o hex; clica para copiar. O botão exporta em .gpl, que a Aseprite importa diretamente.

> **O que a distribuição revela**
>
> Repara nos números: 23 neutros, 30 de madeira e terra, 21 de estuque, só 9 de azul-petróleo e 5 de âmbar. Isto confirma a tua gramática — os materiais quentes e neutros fazem o mundo, e as cores frias e quentes saturadas são acentos, usados com parcimónia. Quando desenhares um povo novo, mantém a proporção: se a Fornalha tiver 30 cores de âmbar, deixa de ser um povo dentro do mesmo mundo e passa a ser um jogo diferente. Um povo novo troca a rampa dominante, não a estrutura da paleta.

## O que existe hoje, e o que falta

A versão anterior deste documento tratava a arte como um problema resolvido. Não é — mas também não está toda por fazer, e a distinção importa muito para o calendário. O design de personagem está praticamente fechado nas figuras que já desenhaste; o cenário é que está no início.

**Personagens — desenho resolvido** — Silhuetas, proporções, as três escalas, os rostos de boca larga, a rampa de cor sobre os corpos. Isto é a parte difícil de acertar e está acertada. O que falta é execução: separar em slots e animar.

Edifícios como objetos de jogo, terreno, corte de solo, parallax, muralhas, torres. É aqui que está mais de metade das horas que faltam, e é a razão pela qual as cenas que enviaste parecem desmontadas: não são layouts, são ensaios.

### Bloco 1 · Personagens — ≈ 32 h (16%)

| Item | Estado | O que falta | Horas |
| --- | --- | --- | --- |
| Design das figuras | Fechado | Nada. É o teu ativo mais valioso e o mais difícil de refazer. | 0 |
| Separação em slots | Parcial | Arrumar as personagens existentes em body · head · face · weapon · overlay, com nomenclatura fixa | 5 |
| Animação dos 3 corpos | Só idle de 6 frames | walk 8 · attack 5 · die 7, por escala. Rápido porque o desenho já existe. | 15 |
| Cabeças e identidade | Várias nas cenas | ~10 variantes: cabelo, barba, coroa, elmo, barrete, chapéu de construtor | 6 |
| Faces de estado | Normal | ferido · encantado · apodrecido | 3 |
| Armas e escudos | Base | 4 níveis de cada, mais a arma saqueada (§09) | 3 |


### Bloco 2 · Cenário — ≈ 70 h (40%) revisto na v4

As horas abaixo já contam com a lei da escala dupla (§01). Desenhar cenário com unidade de 2 px em vez de 1 px corta perto de 40% das decisões de pixel por peça — não é uma estimativa otimista, é aritmética de área. Os valores da v3 estão entre parênteses.

| Item | Estado | O que falta | Horas |
| --- | --- | --- | --- |
| Edifícios do povo | Desenhados nas cenas, não separados | 13 edifícios como objetos autónomos, com estados de construção e destruição: núcleo, casa de treino, forja, cozinha, celeiro, salga, curral, serração, poço, plantação, pesqueiro, galinheiro, estábulo | 32 (52) |
| Terreno | 4 tilesets em curso | Superfície, corte de solo, cavidade e transições, arrumados em TileSet do Godot | 10 (16) |
| Torres e defesas | — | 6 estruturas (§10) | 9 (15) |
| Parallax | Fundo achatado | 6 camadas separadas, com os deltas de saturação, valor e densidade especificados adiante nesta secção | 12 (14) |
| Muralhas | — | 5 níveis × segmento, remate e portão = 15 peças | 7 (12) |


### Bloco 4 · Luz e atmosfera — ≈ 18 h novo na v4

| Item | Estado | O que falta | Horas |
| --- | --- | --- | --- |
| Sombras de contacto | — | Um sprite de elipse por escala e por classe de objeto, mais o nó que o coloca | 1 |
| CanvasModulate por plano | — | Cinco planos ligados ao GameClock | 2 |
| LUT de hora do dia | — | Rampas para amanhecer, meio-dia, crepúsculo e noite; é o mesmo shader do palette swap | 4 |
| Névoa entre camadas | — | 3 bandas, dois presets (aberto e fechado) | 3 |
| Luz quente pontual | — | Forja, forno, lanternas, farol | 3 |
| Raios de amanhecer | — | Quads aditivos com deriva lenta | 2 |
| Contorno por dilatação | — | Engrossar a silhueta de cenário para 2 px sem redesenhar | 3 |


### Bloco 3 · Criaturas, efeitos e interface — ≈ 56 h (32%)

| Item | Estado | O que falta | Horas |
| --- | --- | --- | --- |
| Criaturas da Podridão | Só o companheiro (Healing Frog) | 6 criaturas × idle, walk, attack, die (§07). Design por fazer — mas o vocabulário visual já existe. | 30 |
| UI diegética | Placas nas cenas | 6 ícones entalhados da roda do rei, placas de loja, fonte de 12 px (§26) | 14 |
| Efeitos | — | Mancha da Podridão, dissolução, dither de revelação, moeda, impacto, buff, marca | 12 |


> **O conflito de calendário que isto revela**
>
> ≈ 176 horas para a fatia vertical depois da revisão: 32 de personagens, 70 de cenário, 18 de luz, 56 de criaturas, efeitos e interface. Ao ritmo do §28 — sábado é o dia de arte, ~6 h por semana — são 29 semanas, sete meses. A Fase 2 do roadmap dá-lhe três. O conflito é menor do que na v3, mas continua a existir.
>
> E repara no que a lei da escala dupla realmente fez. Poupou 39 horas de cenário, das quais 18 foram devolvidas à luz. O ganho líquido de calendário é modesto — três semanas. O ganho de resultado não é: essas 18 horas de iluminação valem, em imagem, muito mais do que as 39 horas de pintura fina que substituem. A troca certa não era pintar mais depressa; era pintar menos e iluminar melhor.
>
> A arte é o teu caminho crítico. O código não é: a IA escreve-o e tu revê-lo. Nenhum agente desenha o teu ferreiro de bigode — mas a boa notícia é que esse já está desenhado. O que falta é o mundo à volta dele.

### As três saídas, e a que recomendo

**A · Mais dias de arte** — Dois dias por semana em vez de um: 12 h → 17 semanas. Ainda passa dos três meses, e rouba o tempo de rever o que a IA escreve.

Só o que aparece no ciclo de 10 dias: 7 edifícios em vez de 13, 3 criaturas em vez de 6. Cai para ≈ 105 h com as horas revistas. Os outros entram na Fase 6.

Começar o cenário da Fase 2 durante a Fase 1. Arte e código são dias diferentes da semana e não se bloqueiam: oito meses de arte cabem, se começarem no mês 2 em vez do mês 5.

B + C em conjunto resolvem-no com folga. E há uma quarta alavanca que só existe porque o design de personagem está fechado: as personagens podem entrar no jogo já. Não precisas de esperar pelo cenário para teres figuras animadas a andar num ecrã de blocos de cor — o que significa que a Fase 1 pode ter, desde cedo, uma coisa que se parece com um jogo.

## A ordem por que se acaba a arte

Não é a ordem em que apetece desenhar. É a ordem que desbloqueia mais coisas por hora gasta — e começa pelas personagens precisamente porque estão prontas.

1. Sombras de contacto e CanvasModulateTrês horas, antes de tudo o resto. É a única coisa neste documento que melhora toda a arte que já existe e toda a que ainda não existe, sem tocar num ficheiro Aseprite. Faz isto no primeiro sábado.

## Separar as personagens em slots e animá-las

Vinte horas que servem dezenas de personagens através do sistema de slots (§22). É a maior alavanca do pipeline inteiro, e é a única categoria onde partes de um desenho acabado.

## Uma cena-cartaz, acabada a 100%

Um único ecrã de 1280 × 720, completo: céu, parallax, terreno, corte de solo com uma cavidade, quatro edifícios, seis personagens, luz de crepúsculo. Não é para o jogo — é para descobrires quanto tempo demora uma cena acabada, e para teres a primeira coisa bonita para o devlog (§36). Com as personagens já prontas, é sobretudo um exercício de cenário, que é exatamente onde precisas de praticar.

## Terreno e parallax

Tudo o resto assenta em cima. Um erro aqui repete-se em todos os ecrãs do jogo.

## Os sete edifícios do ciclo de 10 dias

Núcleo, casa de treino, plantação, galinheiro, forja, cozinha, celeiro. Os outros seis esperam pela Fase 6.

## Muralhas, os cinco níveis

São a progressão mais visível do jogo e aparecem em todas as capturas de ecrã.

## Três criaturas: Rastejante, Alado, Bruto

Chegam para os primeiros dez dias. O Aríete e a Consumidora são conteúdo da Fase 6.

## Efeitos, e só depois o resto

A mancha da Podridão e a dissolução valem mais em impacto do que qualquer edifício extra.

> **A regra do greybox — e é a que te poupa mais horas**
>
> Nada de cenário se pinta antes de ter sido jogado como forma lisa. Um edifício em pixel art custa quatro horas; um retângulo de cor lisa com o tamanho certo custa dois minutos e responde exatamente à mesma pergunta — cabe no ecrã? lê-se à distância? o jogador percebe o que é? A regra não se aplica às personagens, porque essas já estão desenhadas: mete-as no greybox desde o primeiro dia e deixa que sejam elas a dar-te a escala de tudo o resto.

> **Quando se fecha a paleta**
>
> As 112 cores acima são a rampa das duas cenas em curso — um ponto de partida, não uma paleta fechada. Fecha-a no fim da fatia vertical, quando um povo inteiro estiver pintado: aí sim tens uma amostra representativa, e sobretudo tens cenário pintado, que é o que falta à amostra atual. O ritual é simples — junta tudo o que pintaste, corre a extração outra vez, funde cores a menos de 4% de distância umas das outras, e a partir daí a paleta é lei. Uma cor nova passa a exigir a mesma justificação que um material novo.

## A pilha de iluminação — o Eastward em Godot, por ordem de retorno

A Pixpil monta cada cena em 3D dentro do motor, pinta um bump map à mão para cada peça, simula SSAO e passa tudo por LUTs e camadas de névoa. Tem oito pessoas e seis anos. Tu tens sábados. Mas a pilha decompõe-se, e os primeiros três degraus custam quase nada e dão a maior parte do efeito.

| # | Degrau | Como se faz em Godot | Custo | O que compra |
| --- | --- | --- | --- | --- |
| 1 | Sombra de contacto | Um sprite elíptico desenhado à mão sob tudo o que toca o chão. CanvasItem em modo multiplicativo, 45–55% de opacidade, castanho-escuro quente — nunca preto. Escala com a largura do objeto, não com a altura. | 1 h | O maior salto isolado do documento. É o que separa "objetos pousados numa imagem" de "objetos que estão ali". As tuas cenas flutuam sobre branco; isto resolve-o antes de pintares um único edifício. |
| 2 | CanvasModulate por faixa | Um por plano de imagem (§11), animado pelo GameClock. O corte de solo fica permanentemente escuro; só as cavidades descobertas recebem luz. | 2 h | Ciclo dia/noite quase de graça, e profundidade estática por diferença de exposição entre planos. |
| 3 | Gradação por LUT | Uma rampa 1D por hora do dia; todos os sprites amostram através dela. É o mesmo shader de palette swap que já tens listado para variantes de povo, estados e encantamento do bardo — um shader a fazer quatro trabalhos. | 4 h | Amanhecer, meio-dia, crepúsculo e noite coerentes em todo o jogo, sem repintar nada e sem sair da paleta. É a técnica do Eastward, e é a que melhor se aplica ao teu caso. |
| 4 | Camadas de névoa | Duas ou três bandas horizontais aditivas entre camadas de parallax, com opacidade de 6–14% e deriva muito lenta. | 3 h | É o que produz, em imagem, a rampa de saturação e valor medida na §11. Barato e desproporcionalmente eficaz em cena aberta. |
| 5 | Luz quente pontual | PointLight2D sem sombra na forja, no forno, nas lanternas e nos faróis. Sombras dinâmicas só nas três luzes mais próximas da câmara (§19). | 3 h | Dá vida à noite e justifica a rampa de âmbar da paleta, que hoje tem só 5 cores e quase não se usa. |
| 6 | Raios de amanhecer | Quads aditivos inclinados, opacidade ≤10%, deriva lenta, só entre as horas de nascer e pôr do sol. | 2 h | A assinatura visual do Eastward, e o que faz o teu sino da manhã (§23) valer uma captura de ecrã. |
| 7 | Contorno por dilatação | Já está na tua lista. Aqui ganha uma função nova: engrossar a silhueta de 1 para 2 px sem redesenhar a arte (§01). Aplica-se por material — cenário sim, faixas distantes não. | 3 h | Resolve a lei da escala dupla no contorno sem te custar uma única hora de Aseprite. |
| 8 | Normal maps + luz presa à paleta | O PointLight2D não respeita o filtro Nearest em normal maps — a armadilha já documentada abaixo. A solução conhecida é codificar o índice de paleta num canal e o brilho da normal noutro, e descodificar através de uma textura de gradiente, para a cor iluminada cair sempre numa cor da paleta. | 12 h+ | É o efeito Eastward a sério. Só para objetos-herói — núcleo, castelo, muralhas, forja. Nunca para 300 unidades. E só depois de 1 a 7 estarem feitos. |


> **Se só fizeres uma coisa**
>
> Faz o degrau 1. Uma hora de sombras de contacto muda mais as tuas capturas de ecrã do que cinquenta horas de edifícios novos — e resolve exatamente o sintoma que a §01 descreve: figuras acabadas espalhadas sobre um fundo por resolver. Elas não estão só sobre um fundo por resolver; estão a flutuar. Uma elipse castanha por baixo põe-nas no chão.

## A profundidade, camada a camada

As seis camadas de parallax já estavam na tabela de parâmetros. O que faltava era dizer o que muda de uma para a outra — e agora os deltas são medidos nas tuas referências (§11), não inventados.

| Camada | motion_scale | Saturação | Valor | Matiz | Detalhe mín. | Contorno | Cores/16px |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 · Céu | 1/32 | −35% | +20% | +20° → céu | bandas lisas | não | 13–18 |
| 2 · Montanha | 1/8 | −28% | +16% | +14° | 8 px | não | 15–20 |
| 3 · Colina | 1/4 | −20% | +11% | +9° | 4 px | não | 18–23 |
| 4 · Fundo médio | 1/2 | −10% | +5% | +4° | 4 px | não | 21–26 |
| 5 · Jogo | 1 | referência | referência | 0° | 2 px | sim, 2 px | 30–40 |
| 6 · Primeiro plano | 3/2 | +5% | −30% | −5° (quente) | silhueta | sim, 2 px | ≤20 |


> **A regra do pixel inteiro**
>
> Nada de parallax se move em meio pixel. Cada camada calcula a posição e arredonda para baixo antes de a aplicar (floor()), e a câmara move-se em pixels inteiros de mundo. As frações acima são todas binárias exatas (1/32, 1/8, 1/4, 1/2, 3/2) precisamente para o arredondamento ser estável. Camadas que andam menos de 1 px por frame tremem: se acontecer, duplica a largura da textura em vez de baixar a velocidade.
>
> Em cena fechada — Enramados, Sob-Raiz, interior de cavidade — inverte a coluna do valor: o fundo escurece em vez de clarear, e a saturação quase não muda. É o segundo preset medido na §11.

## Cada povo precisa de uma fonte arquitetónica, não de uma paleta

Esta é a lição mais barata e a mais subestimada. O Eastward mistura arquitetura japonesa Showa e Taishō com Hong Kong e Xangai; o Chef RPG cruza arquitetura asiática e ocidental com cyberpunk, e o autor descreve o tema como o choque entre tradição e tecnologia. Nenhum dos dois inventou um estilo — os dois foram buscar um. É o que faz um kit parecer uma cultura em vez de um conjunto de casas.

A tua §04 define os seis povos por terreno, economia, defesa e tropa. Falta a coluna que decide como eles se desenham. Estas são propostas — o que importa é que cada uma seja um sítio real que possas ir ver, e que a fonte fique escrita no PeopleData.tres ao lado da rampa de paleta.

| Povo | Fonte proposta | O que se rouba de lá | Remate do telhado |
| --- | --- | --- | --- |
| Enramados | Igrejas de madeira norueguesas (stavkirke) + casas nas árvores dos Korowai + carpintaria japonesa sem pregos | Estrutura de madeira à vista, telhados sobrepostos em camadas, varandas em consola, escadas exteriores | Empilhado, escamado, pontiagudo — silhueta serrada |
| Portuários | Porto palafítico da Carrasqueira, no Sado — a 30 km de ti — e os naust nórdicos | Estacaria irregular de madeira sobre água, passadiços estreitos, telheiros de guarda-barcos, redes | Baixo, largo, de duas águas, quase a tocar a água |
| Fenda | Petra, os celeiros dogon da falésia de Bandiagara, e as aldeias de xisto da Serra da Lousã | Fachada esculpida na rocha, sem telhado; degraus talhados; pontes suspensas entre paredes | Não há — a silhueta é o negativo do desfiladeiro |
| Horta | Lezíria do Tejo e celeiros de estrutura de madeira ingleses | Volumes grandes e simples, colmo, silos cilíndricos, estufas envidraçadas, muros baixos | Enorme e liso, com uma única inclinação. Contrasta com tudo o resto |
| Fornalha | Ferrarias bascas (ferrerías) e construção em basalto islandês | Pedra escura, chaminés altas, muros de escória vitrificada, aberturas que brilham de noite | Chato e pesado, atravessado por chaminés — a silhueta é vertical |
| Sob-Raiz | Derinkuyu, na Capadócia, e Coober Pedy | Câmaras escavadas ligadas por poços, nichos, nada de fachada — só aberturas na terra | Não há telhado. O povo lê-se pelo corte, não pelo alçado |


> **O teste, e é o mesmo de sempre**
>
> Tapa tudo abaixo da linha do solo. Se ainda distingues os seis povos, os kits estão certos. É por isso que a fonte arquitetónica importa mais do que a paleta: a paleta muda com a hora do dia e com o LUT; a silhueta do telhado não muda nunca.

## A gramática visual — escreve-a e não a quebres

| Regra | Especificação |
| --- | --- |
| Contorno | Preto puro. 2 px na silhueta de tudo o que é cenário e edifício; 1 px nas personagens e no detalhe interno (§01, lei da escala dupla). As camadas 1–4 de parallax não levam contorno nenhum. |
| Materiais | Estuque creme · vigas castanho-escuro · telha azul-petróleo escamada · pedra cinza-frio · madeira quente · relva verde-lima. Um material novo exige justificação escrita. |
| Sombreamento | Dois tons por material, sem gradientes, sem dithering decorativo. O dither é reservado a efeitos (revelação, dissolução) e às bandas de céu. |
| Densidade | Cluster mínimo de 2×2 px em todo o cenário; 4×4 nas camadas distantes. Pixels soltos são ruído a esta resolução. As personagens são a exceção e ficam a 1 px. |
| Assentar no chão | Tudo o que toca o solo leva sombra de contacto — elipse castanha quente, multiplicativa, 45–55%. Sem exceções, nem para caixotes. |
| Céu | Pelo menos 30% da altura do ecrã acima do telhado mais alto, sem nada contornado (§11). |
| Rostos | Bocas largas com dentes, olhos afastados. O humor está na cara — atravessa idiomas sem localização. |
| Sinalética | Ícone entalhado em madeira, nunca texto. UI diegética e localização grátis. |
| Silhueta por povo | Cada povo é reconhecível a 100% de zoom out só pela forma dos telhados. É o teste de qualidade de um kit novo, e cada povo tem uma fonte arquitetónica real escrita no seu PeopleData.tres. |


## Slots: o teu sistema modular

Os teus ficheiros já separam Body, Face, Sword, Shield, Equipments. Formaliza como cinco slots:

| Slot | Trocado por | Exemplo |
| --- | --- | --- |
| body | Povo e escala | enramado, portuário, horta · escalas 1/2/3 |
| head | Identidade | cabelo preto, barba ruiva, coroa, elmo alado, barrete de cozinheiro |
| face | Estado e lealdade | normal, ferido, encantado, apodrecido |
| weapon / shield | Ferreiro | níveis 1–4 · arma saqueada |
| overlay | Efeitos | buff do cozinheiro, marca do arqueiro, rasto da Podridão |


Cada slot é um Sprite2D filho com o mesmo AnimationPlayer. Um personagem = 5 sprites empilhados. Custo de desenho desprezável em 2D; poupança de trabalho artístico enorme — e é o que torna viável ter seis povos.

## Da Aseprite ao Godot

- Autoras em art/source/<povo>/*.aseprite, uma camada por slot, tags por animação (idle, walk, attack, die).
- Godot Aseprite Wizard importa para SpriteFrames ou AnimationPlayer respeitando tags e camadas. É o plugin mais maduro do ecossistema.
- Nomenclatura obrigatória: <povo>_<entidade>_<slot>.aseprite — ex. enramados_ferreiro_body.aseprite. A IA depende disto para gerar cenas sem ver a arte.
- art/export/ é gerado e está no .gitignore. art/source/ vai para Git LFS desde o primeiro commit — migrar depois é doloroso.

## Shaders que valem a pena

| Shader | Usa em | Custo |
| --- | --- | --- |
| Palette swap (LUT 1D) | Variantes de povo, estados, encantamento do bardo | Baixo. O maior retorno do projeto. |
| Revelação por dither | Cavidades a abrir no corte de solo | Baixo. Mecânica e efeito ao mesmo tempo. |
| Outline por dilatação | Personagem controlado, alvo marcado | Baixo |
| Dissolução | Podridão a espalhar-se, morte de unidades | Baixo |
| Ondulação de água | O lago do castelo, portos, pesqueiros | Baixo |
| Névoa volumétrica falsa | Cavidades, crepúsculo | Médio |
| Vinheta de cegueira | Cavaleiro Selado sem montaria (§24) | Baixo |


## Iluminação

Um CanvasModulate por faixa, animado pelo GameClock, dá o ciclo dia/noite quase de graça — e o corte de solo pode ficar escuro de forma permanente, com luz só nas cavidades descobertas. PointLight2D para as fogueiras que já desenhaste (forja, forno), faróis e a própria Podridão.

> **Armadilha documentada**
>
> O PointLight2D não respeita o filtro Nearest em normal maps e sombras — os teus pixels ficam suaves à volta das luzes. Se usares normal maps, testa isto na Fase 0, não na Fase 5. Sombras dinâmicas em 2D também são caras: limita-as às três luzes mais próximas da câmara e faz as restantes com sprites aditivos.
