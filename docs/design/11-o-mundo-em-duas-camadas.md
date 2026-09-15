# 11 — Estrutura · O mundo em duas camadas

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

A ideia é tua: "a tela é dividida ao meio, em baixo é só paisagem, mas ao aceder a uma passagem secreta encontras níveis, porões, dungeons". Há duas formas de a construir, e a escolha entre elas é a decisão arquitetónica mais cara do projeto. Recomendo a segunda, e não por causa da arte — por causa do custo.

**A · Câmara que se divide ao descer** — Dois viewports, transição, dois enquadramentos a gerir. Mais código, mais bugs de câmara, e o jogador perde a superfície de vista exatamente quando precisa dela para saber se está a ser atacado.

Uma câmara só. A faixa de baixo faz parte do enquadramento normal e está sempre lá, mesmo quando é só terra maciça. Menos código, zero bugs de transição, e o jogador vê os dois planos ao mesmo tempo — que é o que torna a segunda camada uma tática e não um ecrã separado.

O resto desta secção assume a opção B.

**Uma câmara só** — Sem split screen, sem transição. A faixa inferior faz parte do enquadramento normal, como na tua arte.

A maior parte do corte é terra — paisagem pura, sem jogo. É o que dá peso e escala ao mundo. Quanta terra e quanta cavidade é uma decisão de ritmo, e afina-se por playtest (§21).

Onde há caverna, dungeon ou porão, a terra é recortada e o espaço passa a jogável. Ligado à superfície por passagens, escadas ou raízes.

Uma cavidade não descoberta desenha-se como terra normal. Ao encontrar a entrada, a terra dissolve-se com o shader de dither e revela o interior.

O topo do ecrã. As copas de árvore e as torres altas chegam lá; as voadoras vivem aí e só são atacáveis por arqueiros e torre alta (§07).

Personagens jogáveis, ofícios enviados e criaturas subterrâneas. As tropas de defesa nunca descem.

> **Revisto na Parte XIII**
>
> O diagnóstico desta secção — "falta um plano no meio" — é resolvido com um teto de valores por camada na §80. As faixas de jogo não mudam.

## A faixa que falta — e que é a razão de as tuas cenas parecerem planas

As três faixas acima são a divisão de jogo: quem passa onde, o que colide com o quê. Está certa e mantém-se. Mas a divisão de jogo não é a divisão de imagem, e é aí que está o buraco. Medi as capturas que enviaste, faixa a faixa, do topo do ecrã para a base:

| Faixa (topo → base) | 1 | 2 | 3 | 4 | 5 | 6 | Leitura |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Milki — estrada · densidade | 18,2 | 21,0 | 23,7 | 23,1 | 30,0 | 53,4 | Rampa contínua. O primeiro plano tem 2,9× o detalhe do topo. |
| Milki — estrada · saturação | 0,363 | 0,518 | 0,513 | 0,586 | 0,519 | 0,585 | Topo com −38% de saturação face à base. |
| Milki — estrada · valor | 0,726 | 0,593 | 0,489 | 0,481 | 0,606 | 0,625 | Topo +16% mais claro. É névoa, não é céu. |
| Eastward — aldeia · densidade | 12,9 | 24,4 | 26,4 | 41,6 | 23,8 | 36,6 | Mesma rampa: −33% de saturação e +23% de valor no topo. |
| Milki — floresta · saturação | 0,785 | 0,706 | 0,668 | 0,642 | 0,556 | 0,561 | A regra inverte-se em cena fechada — ver a nota abaixo. |


Densidade = número médio de cores distintas numa janela de 16×16 px na grelha do próprio jogo. Saturação e valor são médias HSV por faixa.

> **O diagnóstico**
>
> Nas referências, a profundidade não é feita com camadas de parallax a mexer — é feita com três rampas simultâneas: o detalhe adensa, a saturação sobe e o valor escurece, tudo de forma contínua do topo para a base. Não há degraus. Não há "fundo" e "frente": há um gradiente.
>
> A tua §22 descreve o teu fundo atual como "achatado". É exatamente isso: tens duas superfícies — céu e chão — separadas por uma linha. As referências têm cinco ou seis planos entre elas. Não é falta de resolução nem de talento: é falta de um plano no meio.

### O horizonte não é a linha do solo

É esta a confusão que produz cenas planas, e é fácil de desfazer. A linha do solo é onde as tropas pisam — a constante de jogo. O horizonte é onde as camadas distantes se encontram, e tem de ficar bastante mais alto, para haver espaço entre os dois. Esse espaço é o plano médio: colinas, linha de árvores, aldeia longínqua, a silhueta do império vizinho.

| Plano de imagem | y proposto | Altura | O que vive lá | Densidade alvo |
| --- | --- | --- | --- | --- |
| Céu | 0 – 300 | 300 px | Gradiente em bandas, nuvens, sol/lua, voadoras. Nada com contorno. | ⅓ do plano de jogo |
| Distância | 300 – 420 | 120 px | Montanha ou massa de copa. Silhueta lisa, sem textura nenhuma. | ⅓ |
| Plano médio o que falta | 420 – 517 | ≈ 100 px | Colinas, linha de árvores, telhados distantes, o mar. É a faixa que dá escala ao mundo. | ½ |
| Plano de jogo | 517 – 720 | 203 px | Tudo o que colide. Edifícios, tropas, muralhas, corte de solo. | referência |
| Primeiro plano | ≈ 640 – 720 | 80 px | Erva alta, ramos, pedras. Escuro, sem detalhe, só silhueta. Sobrepõe-se às tropas. | ⅓, mas contraste máximo |


> **A regra do céu**
>
> Acima do telhado mais alto tem de haver pelo menos 30% da altura do ecrã sem nada com contorno. Só céu e camadas distantes. É a única coisa que o Milki Delivery faz e tu não fazes, e é o que transforma "objetos sobre um fundo" numa paisagem.
>
> Repara que isto não te obriga a mudar as faixas: a tua faixa aérea já são 200 px = 28% do ecrã. O que muda é a regra de composição — nada de silhueta contornada entra na faixa aérea, exceto as voadoras e a copa da árvore colossal do castelo, e é justamente por isso que ela vai ler-se como monumental.

> **A exceção medida: cenas fechadas invertem a regra**
>
> A captura de floresta do Milki mede ao contrário: saturação maior no topo (0,785) do que na base (0,561), e o topo mais escuro (valor 0,311 contra 0,431). Faz sentido — numa floresta fechada não há atmosfera entre o observador e o fundo, e a profundidade passa a ser feita só com valor: o fundo escurece, a frente ilumina-se.
>
> Isto dá-te uma gramática por bioma sem inventar nada: biomas abertos (Horta, Portuários, Fenda) fazem profundidade com saturação e névoa clara; biomas fechados (Enramados, Sob-Raiz, e o interior do corte de solo) fazem-na com escuridão no fundo. O mesmo motor de camadas, dois presets.

> **A decisão arquitetónica mais importante do projeto**
>
> Cada entidade precisa de um campo faixa: enum {AEREA, SUPERFICIE, SUBSOLO} desde a primeira linha de código, e as colisões usam collision layers separadas por faixa. O corte de terra é um TileMapLayer com máscara de revelação. Se isto entrar no dia 200 em vez do dia 1, reescreves o jogo. Agora é barato, porque não há segunda câmara — há composição.
