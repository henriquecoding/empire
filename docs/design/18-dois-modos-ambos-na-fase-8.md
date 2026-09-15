# 18 — Multijogador · Dois modos, ambos na Fase 8

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

**Cooperativo — duas coroas** — Dois jogadores, um império, classes diferentes. Um pode estar em expedição enquanto o outro defende. Ecrã dividido local e online.

Começam nas extremidades opostas do mapa e conquistam em direção um ao outro. Vence quem tomar o império adversário ou sobreviver mais dias após a Podridão dupla.

| Opção | Viabilidade | Nota |
| --- | --- | --- |
| Ecrã dividido local | Alta | Dois SubViewport. Faz-se em duas semanas. Começa por aqui. |
| Online via Steam Sockets | Média | GodotSteam traz NAT traversal e relays. É a opção testada em produção para jogos Steam. |
| Online via ENet puro | Média-baixa | Irrelevante para 2 jogadores, mas exige port forwarding ou relay próprio. |
| Autoridade | — | Host-autoritativo. O MultiplayerSynchronizer só replica primitivos; centenas de unidades exigem serialização manual em PackedByteArray. |


> **Aviso do próprio criador do Kingdom**
>
> Depois do Kingdom, van den Berg tentou o Garbage Country, um MMO com mundos colaborativos persistentes, e abandonou-o: problemas técnicos com o SpatialOS e questões de jogabilidade por resolver. Salvou um simulador de plantas e fez o Cloud Gardens em dois anos. Ele próprio nota que "mundos persistentes e complexidade de multijogador provaram ser difíceis de prototipar rapidamente". Faz o jogo single-player completo primeiro. Se o multijogador falhar, tens um jogo. Se o fizeres a meio, não tens nada.
