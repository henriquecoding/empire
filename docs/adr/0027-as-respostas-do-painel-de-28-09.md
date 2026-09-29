# ADR 0027 — As respostas do painel de 28/09/2026 entram no repositório

- Estado: aceite
- Data: 2026-09-28
- Secção do dossiê: várias (§05, §06, §07, §10, §14, §15, §17, §21, §24, §25, §27, §74, §77, §80, §85)
- Complementa: ADR 0026

## Contexto
O dono respondeu a 73 perguntas no painel (`/painel/`, ADR 0026): 49 aprovações de proposta, 23 respostas próprias
e uma adiada (Q-081). A ADR 0026 manda um agente aplicá-las no `QUESTIONS.md` e no código, e marcá-las `aplicada`.
Várias mexem no texto do dossiê — e a §72 diz que o dossiê só muda por correção, por decisão que vira ADR, ou por
número que um playtest desmentiu.

## Decisão
**Cada resposta aplica-se inteira: dados, código, testes e o texto do dossiê que ela contradiz.** As decisões
grandes têm ADR própria (0028 a 0033). As edições ao dossiê estão listadas em `docs/dossie-painel-correcoes.md`.
No `QUESTIONS.md` as 72 passam para a secção *"Decididas pelo dono no painel"*, cada uma a abrir com a decisão e o
que mudou; o que ficou por decidir virou pergunta nova (Q-151 a Q-155). Um valor aprovado sai do `_proposed`.

## Alternativas consideradas
Aplicar só no `QUESTIONS.md` e deixar o código para depois: o painel diria «aplicada» a uma coisa que o jogo não faz.
Rejeitado. Mover as perguntas para «Resolvidas»: o painel deixava de as mostrar e o dono não via o que se fez.

## Consequências
O painel mostra as 72 como aplicadas. Onde duas respostas se contrariam (Q-018 e Q-082) aplicou-se a mais recente e
mais específica, e a outra leitura está na Q-155 para o dono confirmar.
