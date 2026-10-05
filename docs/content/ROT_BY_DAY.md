# A Podridão, dia a dia

_Gerado por tools/content_report.py a partir de data/source/ — nao editar a mao._

O dossiê não tem ondas: A Podridão é uma entidade com massa (§05, §51), e a §70 acabou com o `waves/`. Esta tabela é o que o `waves.csv` do relatório mestre pedia, derivada dos dados em vez de escrita à mão — muda o `rot.csv` ou o `creatures.csv` e volta a correr a ferramenta.

- Velocidade `v = 14 + 0.9 × dia` px/s
- Massa (§74, termo a termo) `M = 40 + 18 × dia + 30 × fortalezas + 22 × amargueiros + 45 × amargueiros nomeados + 8 × min(recusas nas últimas 5 noites, 5)`, recusas com teto de 40
- O que a tabela mostra é o **piso**: só os dois primeiros termos. A base e o termo do dia desceram de propósito na §74 — o que a noite tem de duro deixa de vir do calendário e passa a vir de como jogaste. Duas árvores deixadas de pé (+44) valem mais do que um dia inteiro (+18).
- O Zelador (§75) não entra nesta conta: não é invocado por massa, nasce da Dívida da Candeia ≥ 6
- Invoca a cada 4–7 s enquanto está ativa: crepúsculo + noite = 135 s → **19 a 33 invocações** no máximo
- As primeiras noites (Q-017, Q-068): a noite 1 tem massa 24 — os três Rastejantes do §25 — e o calendário sobe em linha recta até à fórmula de cima, que manda por inteiro a partir da noite 5
- Depois (Q-151): mais difícil exponencialmente — a fórmula multiplica-se por 1.06 a cada noite depois da noite 10
- Escolha (§51): a criatura **mais cara que cabe** na massa e cujo dia mínimo já passou
- Estreia (ADR 0071, Q-240): na n-ésima noite em que pode vir, uma espécie vem no máximo 1 × n vezes — o primeiro Alado é um. A da noite 1 não estreia, e o que sobra da massa paga as mais baratas
- O que escreveste de dia (árvores, recusas, o Lume) pesa com a rampa: nada na noite 1, metade na noite 3, inteiro a partir da noite 5 (ADR 0071, Q-239)
- Lado duplo a partir do dia 12
- Ritmo (Q-126): de 6 em 6 noites uma **funda** (massa × 1.3), e a seguinte **calma** (× 0.6). O lado de cada noite diz-se à tarde (Q-125)

| dia | velocidade px/s | massa (0 fort.) | massa (2 fort.) | criatura mais cara disponível | invocações até esgotar (0 fort.) | o que a massa paga (0 fort.) | lados |
|---|---|---|---|---|---|---|---|
| 1 | 14.9 | 24 | 84 | crawler (8) | 3 | crawler 3 | 1 |
| 2 | 15.8 | 37 | 97 | crawler (8) | 4 | crawler 4 | 1 |
| 3 | 16.7 | 59 | 119 | crawler (8) | 7 | crawler 7 | 1 |
| 4 | 17.6 | 90 | 150 | winged (14) | 10 | winged 1 · crawler 9 | 1 |
| 5 | 18.5 | 130 | 190 | winged (14) | 14 | winged 2 · crawler 12 | 1 |
| 6 (funda) | 19.4 | 192.4 | 270.4 | winged (14) | 21 | winged 3 · crawler 18 | 1 |
| 7 (calma) | 20.3 | 99.6 | 135.6 | brute (22) | 7 | brute 1 · winged 4 · crawler 2 | 1 |
| 8 | 21.2 | 184 | 244 | brute (22) | 15 | brute 2 · winged 5 · crawler 8 | 1 |
| 9 | 22.1 | 202 | 262 | brute (22) | 15 | brute 3 · winged 6 · crawler 6 | 1 |
| 10 | 23.0 | 220 | 280 | burrower (30) | 12 | burrower 1 · brute 4 · winged 7 | 1 |
| 11 | 23.9 | 252.3 | 312.3 | burrower (30) | 13 | burrower 2 · brute 5 · winged 5 · crawler 1 | 1 |
| 12 (funda) | 24.8 | 373.9 | 451.9 | burrower (30) | 21 | burrower 3 · brute 6 · winged 9 · crawler 3 | 2 |
| 13 (calma) | 25.7 | 195.8 | 231.8 | burrower (30) | 8 | burrower 4 · brute 3 · crawler 1 | 2 |
| 14 | 26.6 | 368.6 | 428.6 | slime_ram (48) | 14 | slime_ram 1 · burrower 5 · brute 7 · winged 1 | 2 |
| 15 | 27.5 | 414.8 | 474.8 | slime_ram (48) | 14 | slime_ram 2 · burrower 6 · brute 6 | 2 |
| 16 | 28.4 | 465.3 | 525.3 | slime_ram (48) | 15 | slime_ram 3 · burrower 7 · brute 5 | 2 |
| 17 | 29.3 | 520.3 | 580.3 | slime_ram (48) | 16 | slime_ram 4 · burrower 8 · brute 4 | 2 |
| 18 (funda) | 30.2 | 754.2 | 832.2 | slime_ram (48) | 25 | slime_ram 5 · burrower 9 · brute 11 | 2 |
| 19 (calma) | 31.1 | 387.2 | 423.2 | slime_ram (48) | 10 | slime_ram 6 · burrower 3 · crawler 1 | 2 |
| 20 | 32.0 | 716.3 | 776.3 | devourer (120) | 17 | devourer 1 · slime_ram 7 · burrower 8 · winged 1 | 2 |
| 21 | 32.9 | 793.5 | 853.5 | devourer (120) | 16 | devourer 2 · slime_ram 8 · burrower 5 · winged 1 | 2 |
| 22 | 33.8 | 877.3 | 937.3 | devourer (120) | 15 | devourer 3 · slime_ram 9 · burrower 2 · brute 1 | 2 |
| 23 | 34.7 | 968.3 | 1028.3 | devourer (120) | 15 | devourer 4 · slime_ram 10 · crawler 1 | 2 |
| 24 (funda) | 35.6 | 1387.3 | 1465.3 | devourer (120) | 25 | devourer 5 · slime_ram 11 · burrower 8 · winged 1 | 2 |
| 25 (calma) | 36.5 | 704.6 | 740.6 | devourer (120) | 8 | devourer 5 · slime_ram 2 · crawler 1 | 2 |
| 26 | 37.4 | 1290.5 | 1350.5 | devourer (120) | 17 | devourer 7 · slime_ram 9 · winged 1 | 2 |
| 27 | 38.3 | 1416.4 | 1476.4 | devourer (120) | 18 | devourer 8 · slime_ram 9 · brute 1 | 2 |
| 28 | 39.2 | 1552.8 | 1612.8 | devourer (120) | 20 | devourer 9 · slime_ram 9 · burrower 1 · crawler 1 | 2 |
| 29 | 40.1 | 1700.4 | 1760.4 | devourer (120) | 21 | devourer 10 · slime_ram 10 · winged 1 | 2 |
| 30 (funda) | 41.0 | 2418.2 | 2496.2 | devourer (120) | 38 | devourer 11 · slime_ram 17 · burrower 9 · crawler 1 | 2 |

**Leitura:** a coluna "invocações até esgotar" é o que a massa paga; o tempo ativo limita-a a 19–33. Quando a primeira passa a segunda, sobra massa ao amanhecer — a noite deixa de ser limitada pela massa e passa a ser limitada pelo relógio. Ver Q-017 em docs/QUESTIONS.md.
