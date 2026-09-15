# 43 — Ciclo · O tick, e o que corre em que ordem

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

30 passos de simulação por segundo, metade do render (§19). Dentro de cada passo a ordem é fixa e escrita — porque uma ordem implícita é uma ordem que muda sozinha quando um agente reorganiza um ficheiro.

| Ordem | Sistema | Frequência | Lê | Escreve |
| --- | --- | --- | --- | --- |
| 1 | GameClock.advance | Todo o tick | state.time | Fase do dia, emite fronteiras |
| 2 | RotSystem | Todo o tick | Fase, dia, terreno | Posição, massa, rasto, invoca criaturas |
| 3 | JobSystem | Uma vez por fase | Postos, tropas livres | Atribuições |
| 4 | UnitSystem — FSM | 1/6 das unidades por tick | Atribuição, ameaças | Estado, alvo, intenção de movimento |
| 5 | MovementSystem | Todo o tick | Intenção | Posição em X, faixa, separação |
| 6 | CombatSystem | Todo o tick | Slots de contacto, alcances | Vida, mortes, largadas |
| 7 | EconomySystem | Uma vez por fase | Edifícios, ofícios, rotas | Moeda, matéria, capacidade |
| 8 | BuildSystem | Todo o tick | Moedas largadas, obras | Progresso de construção |
| 9 | DebtSystem · DiplomacySystem | Uma vez por dia | Dívida, favor | Prazos, conversões |
| 10 | KingAISystem | Uma vez por dia, por império | KingdomState | Ação escolhida |
| 11 | EventBus.flush | Fim do tick | Fila de eventos | Entrega à apresentação |


> **Eventos entregam-se no fim, sempre**
>
> Sistemas enfileiram eventos; não os emitem no momento. A entrega acontece no passo 11, depois de todo o estado do tick estar consolidado. Sem esta regra, um ouvinte reage a um estado a meio de mudar — e apanhas bugs em que uma tropa morre e ainda ataca no mesmo tick. A fila também é o teu registo de depuração: grava os últimos 600 eventos e tens vinte segundos de história de qualquer bug.
