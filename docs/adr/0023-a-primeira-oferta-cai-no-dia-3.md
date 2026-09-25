# ADR 0023 — A primeira oferta cai no dia 3: o §83 manda sobre o "Dia 2+" da §75

- Estado: aceite
- Data: 2026-09-25
- Secção do dossiê: §75, §83, §25

## Contexto
A tabela das doze ofertas da §75 dá a *"Nada. Só quero ver."* o "Dia 2+", e o `offers.csv` trazia `min_day 2`.
O §83 escreve a mesma oferta ao minuto **17:00, crepúsculo do dia 3** — "a candeia chega mais perto do que
ontem e uma frase acende-se junto a ela" —, e faz dela a primeira de todas: *"a oferta mais barata do jogo, de
propósito, e a única sem consequência má. Ensina o gesto por uma moeda."*

Medido no segmento de abertura com a muralha de dentro de pé (`tests/abertura_test.gd`): a mancha chega aos
300 px da muralha aos 57,5 s da noite 2, dentro da janela de 20 a 60 s, e fala. Com `min_day 2` a primeira
oferta cai ao minuto ~11, entre a noite 2 do §25 (*"um Rastejante entra pela passagem que abriste"*) e o
reconhecimento do Amargueiro ao 13:10 — antes de o jogador saber que as árvores têm nome. O §83 foi desenhado
na ordem inversa, e a ordem é o argumento dele. Registado na Q-089.

## Decisão
**O §83 manda.** `offers.csv` passa a `min_day 3` para `just_looking`, e a linha da tabela da §75 passa a dizer
"Dia 3+". As outras onze ofertas não mudam.

## Alternativas consideradas
Deixar os dados e aceitar a primeira oferta ao minuto 11: a sequência do §83 — perda (12:40), reconhecimento
(13:10), escolha (14:30), e só depois a voz (17:00) — deixa de acontecer por essa ordem. Rejeitado.
Atrasar a janela da oferta ou mexer na velocidade da mancha: mudava todas as noites para acertar uma. Rejeitado.

## Consequências
A primeira oferta cai ao dia 3, e o XIII-10 fecha. O `check_dossie_vs_csv` confere o "Dia 3+" contra o
`min_day`, por isso o dossiê e os dados não podem voltar a divergir sem um dos portões chumbar.
Reverter é voltar a pôr `2` nos dois sítios.
