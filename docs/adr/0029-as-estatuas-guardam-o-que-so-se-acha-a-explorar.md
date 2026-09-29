# ADR 0029 — As estátuas enterradas guardam o que só se acha a explorar

- Estado: aceite
- Data: 2026-09-28
- Secção do dossiê: §17, §25

## Contexto
O §17 dá às estátuas enterradas *"ensina uma mecânica ao ser ativada"* e só escreve uma (a do Ferreiro). A Q-016
propunha uma por mecânica dos primeiros minutos. O dono: *"aprofunde bem, acho muito interessante ter mecânicas e/ou
habilidades que só são descobertas e podem ser usadas se o jogador encontrou explorando."*

## Decisão
**Cada estátua guarda uma coisa, e essa coisa não existe no teu jogo até a achares com o rei.** A coluna `teaches`
do `secrets.csv` diz o quê (o id de uma obra ou o nome de um gesto); `Discoveries.known()` é a pergunta. Três hoje:
- **O Ferreiro** (a do §25, perto do castelo): a Forja.
- **A Oferenda** (fora da muralha de fora, a leste): o sacrifício de moedas à Podridão (Q-127).
- **O Mineiro** (fora da muralha de fora, a oeste): a escora que fecha a passagem (Q-132).
Nada do núcleo do jogo fica atrás de uma estátua. O que se acha é do império e vai com o legado (o `found`).

## Alternativas consideradas
Estátuas que só *mostram* uma mecânica que já existe: é o que o §17 dizia, e o dono pediu mais. Estátuas com
habilidades novas: pedia desenhar sistemas que o dossiê não tem; ficam para quando os houver.

## Consequências
A Forja, a escora e o sacrifício deixam de estar disponíveis desde o início. Os testes que os usam acham a estátua
primeiro. Uma estátua nova é uma linha no `secrets.csv` e um gesto que pergunte ao `Discoveries`.
