# 56 — Dívida · DiplomacySystem e DebtSystem

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

| Sistema | Corre | Regra |
| --- | --- | --- |
| Favor | Uma vez por dia, no DAWN | Decai 10% se não for usado. É a única moeda que perde valor — e é o que impede acumular favor durante vinte dias. |
| Mercenários | Ao contratar | Preço sobe 25% na AFTERNOON. Contratar sem favor cria dívida com prazo de 6 dias. |
| Dívida | Uma vez por dia | É o único elemento de HUD permanente do jogo (§24), e só existe quando há dívida. |
| Incumprimento | No prazo | debt_defaulted: os mercenários mudam de owner na mesma linha de código. Não são substituídos por inimigos — tornam-se inimigos, com o equipamento que lhes deste. |


> **Uma nota sobre a lealdade**
>
> loyalty é um campo de UnitRec, não uma classe de unidade separada. Um mercenário e um aldeão diferem num float. É o que permite que o bardo encante inimigos e que a dívida vire aliados — a fronteira entre os exércitos é permeável porque, nos dados, mal existe.
