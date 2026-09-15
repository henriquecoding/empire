# World Production Bible — como se produz um segmento

> O dossiê decide o **modelo** do mundo: três faixas (§11), segmentos autorados de 640 px montados por *seed*
> (§21, §54), paisagem contínua por região e a lição do Chef RPG — marco, limiar, bordo, percurso (§21). Este
> documento é o **manual de produção**: medidas, zonas, metadados e o caminho de uma cena da planta ao `IN_GAME`.
>
> Registo: [`SEGMENT_REGISTER.csv`](SEGMENT_REGISTER.csv) · Greybox: [`GREYBOX_RULES.md`](GREYBOX_RULES.md) ·
> Dados: `data/source/segments.csv` (o que o gerador lê).

## 1 · Medidas

| Medida | Valor | Estado | De onde |
|---|---|---|---|
| Largura de segmento | **640 px** — fixa, sem mínimo nem máximo | constante `SEGMENT_WIDTH` | §21, §47 |
| Segmentos por região | **8** (5120 px = 4 ecrãs) | fatia vertical | §21 |
| Largura de região | 4 a 6 ecrãs | ⚠ incompatível com "8 segmentos" acima de 4 ecrãs — Q-030 | §21 |
| Linha do solo | `GROUND_LINE` = 517 **provisório** — decide-se no greybox da Fase 0 | em aberto | §11, §47, §67 |
| Faixa aérea | 0–200 px · superfície até à linha do solo · corte de solo 203 px | proposta do §11 | §11, §47 |
| Planos de imagem | céu 0–300 · distância 300–420 · plano médio 420–517 · jogo 517–720 · primeiro plano 640–720 | proposta do §11 | §11 |
| Grelha de tile | 32 px | fixa | §22 |

### Travessia — o número que a greybox tem de medir

A pé, a 26 px/s (§21, §44): **um segmento demora 24,6 s; uma região de 8 segmentos, 197 s** — mais de metade
de um dia de 360 s. Com o cavalo de tração (1,7×, §12), 116 s. O §21 diz que uma região se deve atravessar em
40–60 s de ponta a ponta, o que a 26 px/s dá 1040–1560 px — **um ecrã, não quatro** (Q-018). A leitura mais
provável é "40–60 s **por ecrã**" (1280 px / 26 px/s = 49 s, dentro do intervalo), e é a que este documento usa
até decidires. Consequência de design, que é boa: atravessar a região inteira a pé custa o dia inteiro — é
exatamente o que dá valor à primeira montaria ("deliberadamente frustrante depois do dia 6", §12).

## 2 · Densidade e espaço negativo

Números de partida do §21, para o playtest desmentir:

| Regra | Valor |
|---|---|
| Em zona construída | um edifício a cada **200–260 px** de linha do solo |
| Entre grupos | pelo menos **240 px** de terreno livre |
| Por segmento | **um assunto**, **2 a 3 edifícios**, nunca dois *props* iguais |
| *Props* | 6 a 10 por segmento (proposta), **4 variantes** cada, a mesma variante nunca a menos de 400 px |
| Vazios acima de 400 px | só de propósito, e só antes de um marco ou de um limiar |
| Céu | ≥ 30% da altura do ecrã acima do telhado mais alto, sem nada contornado (§11) |
| Faixa aérea | nada contornado lá dentro, exceto voadoras e a copa da árvore colossal (§11) |

## 3 · As zonas de um segmento

| Zona | Regra de produção | Dossiê |
|---|---|---|
| **Construção** | Os *slots* são **autorados na cena**, não calculados; posições arriscadas de propósito (à maneira do Thronefall). Largura do *slot* = largura do edifício + 16 px de soleira | §21, §55 |
| **Combate** | À frente de cada *slot* de muralha, **160 px de chão livre**: a fila de atacantes espera a 30–120 px do muro, com 18 px entre posições | §07, §50 |
| **Entrada de caverna** | 0–2 cavidades e 0–1 passagem por segmento; um `ruin` traz sempre uma passagem. Uma cavidade tem de caber um monarca (58 px) de pé — mínimo 120 px de altura, 200 px para ter composição | §11, §21 |
| **Passagem entre faixas** | Só por `PassageRec` (grafo de 20–60 nós, §53). Cada região precisa de pelo menos **duas** ligações superfície↔subsolo, para A Podridão poder desviar e o jogador flanquear | §05, §53 |
| **Spawn** | **Não há spawn por segmento.** A Podridão é a única fonte de criaturas e invoca dentro da mancha (§51). O `spawn_table` do relatório não se aplica | §51 |
| **Marco** | Um por região, visível a três segmentos de distância, no plano médio ou a furar a faixa aérea | §21 |
| **Limiar** | Fronteira entre povos: portão, ponte, falha, muralha em ruínas — **nunca um *fade***. Segmento `threshold` dedicado | §21 |
| **Bordo** | A região termina em alguma coisa: falésia, mar, muralha, desfiladeiro. Segmento `edge` | §21 |
| **Percurso** | A linha do solo **é a rua**; os edifícios dão para ela, com 12–20 px de soleira (degrau, caixote, lanterna) | §21 |
| **Seguro / risco** | Dentro das muralhas é seguro de noite; fora, de dia, é caça e expansão; acampamentos e segmentos caóticos são risco declarado | §05, §14, §17 |

## 4 · Metadados de segmento

O relatório pede catorze metadados. Cada um tem **um** sítio — nunca dois:

| Metadado | Onde vive | Nota |
|---|---|---|
| `segment_id` | `segments.csv` → `SegmentData.id` | `<povo>_<tipo>_<nn>` |
| `biome` | `peoples.csv` → `biome` do povo | o segmento herda |
| `width` | `SegmentData.width_px` | sempre 640 |
| `difficulty` | registo (produção) | 0 perto do núcleo · 3 fortaleza; guia de afinação, o jogo não o lê |
| `entry_rules` / `exit_rules` | `SegmentData.rules` | fichas `center`, `at_region_end`, `not_adjacent=<tipo>`, `requires_prev=<tipo>`, `spacing=4..7`, `first_run_only` |
| `possible_build_slots` | `SegmentData.build_slots` (contagem) + a cena (posições) | o teste de dados confere a contagem |
| `cave_slots` | `SegmentData.cavity_slots` + `passages` | |
| `resource_slots` | `SegmentData.resource` | `forest`, `water`, `rock` |
| `landmark` | `SegmentData.subject` (assunto) · `PeopleData.landmark` (marco da região) | assunto ≠ marco |
| `spawn_table` | — | não se aplica (§51) |
| `parallax_set` | `BiomeData.parallax_preset` | **por região, nunca por segmento** (§21, regra 1) |
| `lighting_profile` | `BiomeData.atmosphere_preset` | só cavidades e interiores têm luz própria |
| `music_profile` | `BiomeData.music_profile` | fortaleza, acampamento e abertura podem ter um *stinger* (AUDIO_CUE_SHEET) |

## 5 · Da planta ao `IN_GAME`

1. **Planta** (1 h, papel). Aplica as quatro ferramentas do Chef RPG: onde está o assunto, por onde se entra e
   sai, onde o olho pousa, o que é rua. Escreve o assunto numa linha.
2. **Greybox** (20 min). Formas lisas, personagens reais — ver GREYBOX_RULES. Estado `greybox` no registo.
3. **Jogar** (5 min + checklist). Responde às treze perguntas do GREYBOX_RULES. Falhou uma, volta a 2.
4. **Esperar pelos pares.** Só depois de **6 a 8 segmentos** se jogarem bem juntos é que algum se pinta (§21).
5. **Pintar** por esta ordem: terreno → edifícios → *props* → primeiro plano. Lei da escala dupla (§01).
6. **Rever** contra a checklist do ASSET_BIBLE (§7).
7. **Registar**: `paint_status = done`, `playtested` com a data.

Pintar um segmento com a composição errada custa meio dia e não conserta nada (§21). A greybox existe para isso
nunca acontecer.

## 6 · O kit de um povo

Um povo são **5 a 8 cenas de segmento** (§04). O kit mínimo, que a fatia vertical produz para os Enramados:

| Tipo | Quantas | Porquê |
|---|---|---|
| `start_base` (+ `opening` na 1.ª partida) | 1 (+1) | o núcleo; a abertura é a cena mais afinada do jogo (§25) |
| `empty` | 3 | "nunca menos de 3 por região" (§21) |
| recurso (`forest` / `water` / `rock`) | 1–2 | define a especialidade económica |
| `ruin` | 1 | a passagem para o corte de solo |
| `fortress` | 1 | numa extremidade |
| `edge` | 1 | o bordo |
| `threshold` | 0–1 | entre povos, a partir da Fase 7 |
| `mercenary_camp` · `chaotic` | 0 | Fase 6 · a partir da 2.ª região |

## 7 · Montagem da região (§54)

Três passagens, **nesta ordem, sempre** — trocar a ordem muda todos os mundos de todas as *seeds* e obriga a subir
`WORLDGEN_VERSION` (§54, §62):

1. **Paisagem** — camadas 1–4 geradas uma vez para a região inteira pelo fluxo `world`.
2. **Segmentos** — oito de 640 px sorteados por peso, com as restrições de adjacência.
3. **Costura** — erva, pedras e ramos colocados depois, ignorando as juntas.

## 8 · A cena-cartaz

Uma por povo, **fora do gerador**, acabada a 100%: céu, parallax, terreno, corte de solo com uma cavidade, quatro
edifícios, seis personagens, luz de crepúsculo (§21, §22). Serve de padrão de qualidade para os segmentos daquele
povo, de material para a Steam, e de medida de quanto tempo demora uma cena acabada. A dos Enramados é
critério de saída da Fase 1 (§33).

## Parte XIII — os dez capítulos

> Fonte: §77 e a ADR 0016. Os dados estão em `data/source/chapters.csv`; os segmentos em
> [`SEGMENT_REGISTER.csv`](SEGMENT_REGISTER.csv), com o prefixo `chapter_`.

### As seis regras, do lado da produção

1. **Uma lei, uma frase.** Se precisar de duas, são dois capítulos ou não é nenhum. A frase vive em
   `strings.csv` como `CHAPTER_LAW_<ID>`.
2. **Um habitante.** Fala, cumpre a lei, e comporta-se como se ela fosse óbvia. `CHAPTER_WHO_<ID>`.
3. **Uma canção.** 20 a 40 s, sem letra traduzível. A do capítulo, não a do bioma.
4. **Um diário, ou uma Semente Anciã.** A coluna `reward_kind` decide; seis dos dez levam diário.
5. **Contorna-se sempre, e o desvio tem preço escrito.** `detour_seconds`: 25 s numa bifurcação ou à beira da
   estrada, 40 s numa travessia ou numa fortaleza. **O gerador tem de garantir o caminho alternativo** — é o
   teste D-09, e é a única regra desta lista que o código pode quebrar sem ninguém dar por isso.
6. **A lei não entra em casa.** Exatamente um capítulo a quebra — O Forno Aceso — e o teste D-10 chumba se
   aparecer um segundo.

### Quantos, e onde

O gerador coloca **seis por campanha, no máximo um por região**, sob a semente do mundo (§54) com o fluxo da §42.
O Cerco Que Não Acaba sai sempre. Nove fichas sorteadas cinco a cinco dão 126 mundos, e os quatro que não saíram
ficam para a partida seguinte.

A atribuição de diários segue-os: o 12 está sempre no Cerco; os outros cinco vão para o capítulo que preferem ou,
se esse não saiu, para o seguinte que tenha saído, por ordem de ato. **Uma partida vê sempre os doze** — é o teste
D-12, e corre sobre mil sementes.

### A raiz, e o erro a não cometer

Cada lei sai de uma coisa que existiu ou existe, guardada em `folk_root`: alminhas e nichos de estrada; romaria e
andor; encomendação das almas; mouras encantadas; ferrarias sempre acesas; pregão de feira; cidades soterradas;
pontes de seis materiais. Duas ficaram por confirmar (Q-054).

**A regra é a 2: o habitante nunca justifica a lei.** No momento em que alguém explicar ao jogador que "isto é uma
tradição portuguesa", o capítulo passou de mundo a museu — e é assim que o folclore vira turismo. Uma linha de
diálogo que comece por "aqui é costume" corta-se (risco R-18).

### O orçamento, e o que se corta

10,6 h por capítulo: 5 de arte, 3 de código e desenho, 2 de canção e meia de escrita. Dez são 106 h e cabem na
Fase 5. **Quatro é o mínimo viável** — com quatro aparecem quatro por campanha e ninguém nota, porque só seis
apareciam de qualquer maneira (risco R-13, Q-043).
