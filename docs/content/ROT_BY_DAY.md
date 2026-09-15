# A Podridão, dia a dia

_Gerado por tools/content_report.py a partir de data/source/ — nao editar a mao._

O dossiê não tem ondas: A Podridão é uma entidade com massa (§05, §51), e a §70 acabou com o `waves/`. Esta tabela é o que o `waves.csv` do relatório mestre pedia, derivada dos dados em vez de escrita à mão — muda o `rot.csv` ou o `creatures.csv` e volta a correr a ferramenta.

- Velocidade `v = 14 + 0.9 × dia` px/s
- Massa (§74, termo a termo) `M = 40 + 18 × dia + 30 × fortalezas + 22 × amargueiros + 45 × amargueiros nomeados + 8 × min(recusas nas últimas 5 noites, 5)`, recusas com teto de 40
- O que a tabela mostra é o **piso**: só os dois primeiros termos. A base e o termo do dia desceram de propósito na §74 — o que a noite tem de duro deixa de vir do calendário e passa a vir de como jogaste. Duas árvores deixadas de pé (+44) valem mais do que um dia inteiro (+18).
- O Zelador (§75) não entra nesta conta: não é invocado por massa, nasce da Dívida da Candeia ≥ 6
- Invoca a cada 4–7 s enquanto está ativa: crepúsculo + noite = 135 s → **19 a 33 invocações** no máximo
- Escolha (§51): a criatura **mais cara que cabe** na massa e cujo dia mínimo já passou
- Lado duplo a partir do dia 12

| dia | velocidade px/s | massa (0 fort.) | massa (2 fort.) | criatura mais cara disponível | invocações até esgotar (0 fort.) | lados |
|---|---|---|---|---|---|---|
| 1 | 14.9 | 58 | 118 | crawler (8) | 7 | 1 |
| 2 | 15.8 | 76 | 136 | crawler (8) | 9 | 1 |
| 3 | 16.7 | 94 | 154 | crawler (8) | 11 | 1 |
| 4 | 17.6 | 112 | 172 | winged (14) | 8 | 1 |
| 5 | 18.5 | 130 | 190 | winged (14) | 9 | 1 |
| 6 | 19.4 | 148 | 208 | winged (14) | 11 | 1 |
| 7 | 20.3 | 166 | 226 | brute (22) | 8 | 1 |
| 8 | 21.2 | 184 | 244 | brute (22) | 9 | 1 |
| 9 | 22.1 | 202 | 262 | brute (22) | 9 | 1 |
| 10 | 23.0 | 220 | 280 | burrower (30) | 8 | 1 |
| 11 | 23.9 | 238 | 298 | burrower (30) | 8 | 1 |
| 12 | 24.8 | 256 | 316 | burrower (30) | 9 | 2 |
| 13 | 25.7 | 274 | 334 | burrower (30) | 9 | 2 |
| 14 | 26.6 | 292 | 352 | slime_ram (48) | 6 | 2 |
| 15 | 27.5 | 310 | 370 | slime_ram (48) | 7 | 2 |
| 16 | 28.4 | 328 | 388 | slime_ram (48) | 8 | 2 |
| 17 | 29.3 | 346 | 406 | slime_ram (48) | 8 | 2 |
| 18 | 30.2 | 364 | 424 | slime_ram (48) | 8 | 2 |
| 19 | 31.1 | 382 | 442 | slime_ram (48) | 9 | 2 |
| 20 | 32.0 | 400 | 460 | devourer (120) | 5 | 2 |
| 21 | 32.9 | 418 | 478 | devourer (120) | 5 | 2 |
| 22 | 33.8 | 436 | 496 | devourer (120) | 5 | 2 |
| 23 | 34.7 | 454 | 514 | devourer (120) | 6 | 2 |
| 24 | 35.6 | 472 | 532 | devourer (120) | 6 | 2 |
| 25 | 36.5 | 490 | 550 | devourer (120) | 5 | 2 |
| 26 | 37.4 | 508 | 568 | devourer (120) | 5 | 2 |
| 27 | 38.3 | 526 | 586 | devourer (120) | 6 | 2 |
| 28 | 39.2 | 544 | 604 | devourer (120) | 6 | 2 |
| 29 | 40.1 | 562 | 622 | devourer (120) | 6 | 2 |
| 30 | 41.0 | 580 | 640 | devourer (120) | 6 | 2 |

**Leitura:** a coluna "invocações até esgotar" é o que a massa paga; o tempo ativo limita-a a 19–33. Quando a primeira passa a segunda, sobra massa ao amanhecer — a noite deixa de ser limitada pela massa e passa a ser limitada pelo relógio. Ver Q-017 em docs/QUESTIONS.md.
