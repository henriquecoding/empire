# v6 → v6 + respostas do painel — o que mudou no dossiê

_28 e 29 de setembro de 2026. Companheiro de `dossie-v6-correcoes.md`. A regra da §72: **o dossiê só muda por
correção, por decisão que vira ADR, ou por número que um playtest desmentiu.** Tudo o que segue é do segundo tipo —
as respostas do dono no painel (ADR 0026, ADR 0027; de P21 em diante, as de 29/09, ADR 0036) — e cada linha diz de que
pergunta vem._

| # | Secção | O que estava | O que passou a estar | Pergunta |
|---|---|---|---|---|
| P01 | §05 | "fogueiras, barris de fogo e terreno consagrado abrandam-na" | a mesma frase, e a fogueira de 3 moedas onde se compra o archote | Q-029 |
| P02 | §06 | "Cada nível custa `base × 1,8^n`" | "aproximadamente", e os preços da tabela do §10 mandam | Q-002 |
| P03 | §06 | Pesqueiro — risco "imune ao rasto" | e "o peixe estraga: sem Salga perde 1 por dia" | Q-012 |
| P04 | §07 | Aríete de lodo com 90 de vida; tempo até matar 32,2 / 96,6 / 16,5 / 7,2 / 9,0 s | 104 de vida; 36,4 / ≈109,2 / 19,8 / 8,1 / 10,0 s | Q-001, Q-038 |
| P05 | §07 | a linha do arqueiro em campo sem nota | "≈" e a frase que diz que a conta é com 1/3 e os dados com 0,34 | Q-003 |
| P06 | §07 | "um muro, seis arqueiros" | "um muro, uma torre de arqueiros, seis arqueiros"; um posto é um lugar; a variante sem torre perde o muro no dia 8 | Q-073 |
| P07 | §07 | "A classe Arqueiro marca um alvo" | e qualquer classe com o verbo `mark_target` | Q-086 |
| P08 | §14 | "Um diplomata n2 com 60 de Favor tem 45/45/10" | "Um diplomata com 60 de Favor tem 45/50/5" | Q-004 |
| P09 | §15 | Fastuoso: "+1 tropa de elite grátis a cada 3 dias" | "(o Berserker de Raiz) a cada 5 dias" | Q-015 |
| P10 | §15 | os impulsos sem preço em moedas | um parágrafo com o sistema de preço | Q-014 |
| P11 | §17 | a estátua "ensina uma mecânica" | e o que ensina só existe depois de achada; as três estátuas | Q-016 |
| P12 | §21 | "40–60 s... o que a 26 px/s dá 1000–1560 px por ecrã" | uma estimativa que cada região adapta, medida no greybox; 80 px/s; oito segmentos na fatia vertical | Q-018, Q-030, Q-082 |
| P13 | §24 | "Marcar alvo — Só classe Arqueiro" | "e as de jogo parecido" | Q-086 |
| P14 | §25, §34, §83 | "O vagabundo segue-te." | o vagabundo corre para a moeda e, recrutado, vai para a vila — como no Kingdom: New Lands | Q-063 |
| P15 | §27 | "Um jogo com cem palavras localiza-se por 200 €" | "precisa de mil e trezentas palavras", como a §75 mandava | Q-049 |
| P16 | §74 | a massa sem primeiras noites | a rampa das primeiras noites, com os três Rastejantes da noite 1 | Q-017, Q-068 |
| P17 | §77 | o Forno Aceso cria raiz "dentro das tuas muralhas inclusive"; "só um o diz"; D-10 = 1 | a lei respeita as muralhas; nenhuma ficha o contraria; D-10 = 0 | Q-039 |
| P18 | §80 | "as tuas fogueiras têm de ser mais fracas do que a candeia" | e o farol também, com paragens a metade da força | Q-078 |
| P19 | §85 | "gera os 154 recursos a partir das 17 tabelas" | a contagem é da ferramenta (`validation.json`), e não da frase | Q-050 |
| P20 | §73, §74, §80, §83 | a candeia no meio da mancha, âmbar: "a coisa que te vem matar é a única que traz luz" | o Lume: roxo, fica na base de onde ela nasce, alimenta-se do que ela consome; as tuas luzes (âmbar) fazem recuar ou abrandar conforme a obra e a massa da criatura | ADR 0034 (o dono a 29/09/2026), Q-156 |
| P21 | §22 | Escala 3 — monarca/elite, O rei | Escala 3 — personagem jogável/elite; Escala 4 — o rei, 64–70 px; o vagabundo tem tamanho de tropa | Q-097 |
| P22 | §74 | Escala 1 e vagabundo: 1 Lenho; Escala 3, elite ou monarca: 3 | Escala 1 (o escudeiro): 1; tropa ou vagabundo: 2; escala 3 ou mais: 3 | Q-097 |
| P23 | §09 | +8% defesa das muralhas | +2% por construtor, até +10% (dano aguentado); só o construtor repara | Q-109, Q-108 |
| P24 | §74 | a massa: rampa das primeiras noites e depois a fórmula | e depois da noite 10 a fórmula cresce 6% por noite (mais difícil exponencialmente) | Q-151 |
| P25 | §75 | Fica com a candeia por uma noite; uma classe jogável para sempre; manda-la a um império rival | Fica com o Lume por uma noite; a evolução da classe, para sempre nesta campanha; a mancha é tua e vai-se | Q-099, ADR 0034 |
| P26 | §75 | O que enterraste: abrir uma passagem subterrânea selada | abrir uma passagem que escoraste (Q-132) | Q-099 |
| P27 | §77 | a candeia fica por baixo de ti | o Lume fica por baixo de ti | Q-099, ADR 0034 |
| P28 | §74 | tabela ao dia 20: 400/466/576/645, −31% a +11% contra a v5.2 | 716/782/892/961 com o crescimento da Q-151; as árvores não crescem | Q-151 |
| P29 | §79 | 4+ povos soltos / ficados | 5+ de oito (Q-152), vassalos contam como ficados (Q-103) | Q-152, Q-103 |
| P30 | §77 | nove fichas cinco a cinco dão 126 mundos | as regiões ordenadas pela semente (Minecraft); 61 combinações de fichas | Q-105 |
| P31 | §58 | Cinco Sprite2D: body, head, face, weapon/shield, overlay | Seis: entra o storage (o armazenamento do personagem jogável, a camada Equipments) entre o body e o head | Q-153 |

`docs/design/` foi gerado outra vez com `tools/split_dossie.py`, como sempre.
