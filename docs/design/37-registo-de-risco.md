# 37 — Risco · novo · Registo de risco

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Ordenado por dano esperado, não por probabilidade. Relê isto no fim de cada fase — leva quatro minutos e é a coisa mais barata que podes fazer pelo projeto.

| Risco | Prob. | Impacto | Sinal de alarme | Mitigação |
| --- | --- | --- | --- | --- |
| A Camada 1 não é divertida | Média | Fatal | Não queres jogar o dia 11 no mês 7 | Portão da Fase 2 (§33). Dois meses de afinação de números antes de avançar. |
| Abandono por exaustão | Alta | Fatal | Duas semanas sem commit; o devlog para | Ritmo semanal do §28. Sexta é para jogar, sábado para arte. Fases curtas com fim visível. |
| O cenário não acompanha o código | Alta | Grande | Fim da Fase 1 sem a cena-cartaz acabada | Cenário da Fase 2 começa na Fase 1; greybox obrigatório para cenário; fatia estreita de 7 edifícios (§22) |
| Escopo cresce em vez de encolher | Alta | Grande | Uma tarefa nova por semana no backlog sem nenhuma sair | O campo Fora em cada ticket (§34). Nada entra na Fase 6 sem sair outra coisa. |
| Dívida técnica gerada por IA | Média | Grande | Ficheiros acima de 250 linhas; testes a serem ignorados | As sete regras + o teste que verifica src/sim/ (§31) |
| Wishlists insuficientes no mês 14 | Média | Grande | < 5 000 depois do Next Fest | Diagnóstico de posicionamento antes de mais código: trailer, capsule, tags |
| Desempenho com 300 unidades | Baixa | Médio | Quedas de fps na noite do dia 20 | Arquitetura de arrays desde a F1-03. Profiler de tracing do 4.6. |
| Reprovar Steam Deck Verified | Média | Médio | Fonte desenhada abaixo de 12 px | Decidir o tamanho da fonte na Fase 0 (§26) |
| Corrupção de saves num update | Baixa | Grande | Um relato basta para envenenar as análises | save_version desde a v1, escrita atómica, 3 slots (§19) |
| Multijogador consome a Fase 8 e falha | Média | Baixo | Mais de 6 semanas em sincronização | Já está depois do lançamento. Corta e não perdes nada. |
| Nome colide com marca registada | Média | Médio | Descobres no mês 26 | Resolver antes da Fase 4 (§36) |
| Um clone sai primeiro | Baixa | Baixo | — | Irrelevante. A tua arte e os seis povos não se clonam em seis meses. |


> **Revisto na Parte XIII**
>
> Seis linhas novas — os riscos que a Parte XIII traz, com sinal de alarme e mitigação — estão na §84.

> **Os dois riscos fatais são o mesmo risco**
>
> Repara que os dois de cima têm impacto fatal, e ambos se resolvem com a mesma coisa: chegar ao mês 7 com um jogo que te apetece jogar. Se isso acontecer, a exaustão passa a ser gerível porque estás a jogar o teu próprio jogo às sextas. Se não acontecer, os outros dez riscos não interessam. Todo o plano existe ao serviço da Fase 2.
