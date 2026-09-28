# ADR 0033 — O recrutamento é o do Kingdom: New Lands

- Estado: aceite
- Data: 2026-09-28
- Secção do dossiê: §25, §02

## Contexto
O §25 escrevia o minuto 0:20 em duas frases — *"O vagabundo segue-te. Largas uma moeda perto dele."* — e o jogo
fazia disso uma fila de toda a gente sem posto atrás do rei. O dono (Q-063): *"deve ser similar ao feito no Kingdom:
New Lands, veja vídeos ou pesquise em wikis"*. Na wiki do Kingdom: o vagabundo corre para a moeda que se deixa cair
perto dele, apanha-a, e o recrutado vai para a vila e espera lá, sem fazer nada, até ter trabalho; de noite corre
para a vila. No barco, a tripulação vai com o monarca.

## Decisão
**Quem é recrutado não segue o rei: vai para o núcleo e espera lá, à volta do centro, até um posto o levar.** O
escudeiro (`follows_king`) continua atrás do rei. De noite manda o Muster (Q-128), como antes. Na travessia, quem
espera sem posto no núcleo (na faixa do rei) embarca com ele. `Retinue`, `RecruitSystem.follow()`.

## Consequências
O rei anda sozinho de dia: levar gente para fora das muralhas passa a ser dar-lhe um posto lá. Um teto para a
comitiva, como o do barco do New Lands, está na Q-154.
