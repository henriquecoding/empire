# v6 → v6 + respostas do painel — o que mudou no dossiê

_28 de setembro de 2026. Companheiro de `dossie-v6-correcoes.md`. A regra da §72: **o dossiê só muda por correção,
por decisão que vira ADR, ou por número que um playtest desmentiu.** Tudo o que segue é do segundo tipo — as
respostas do dono no painel (ADR 0026, ADR 0027) — e cada linha diz de que pergunta vem._

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

`docs/design/` foi gerado outra vez com `tools/split_dossie.py`, como sempre.
