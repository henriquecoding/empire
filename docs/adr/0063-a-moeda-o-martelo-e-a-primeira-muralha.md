# ADR 0063 — A moeda, o martelo e a primeira muralha

- **Estado:** aceite no âmbito dos pedidos do dono de 04/10/2026.
- **Data:** 2026-10-04
- **Tarefa:** `docs/backlog/RG-21.md`.
- **Substitui:** Q-064 quanto às mãos que constroem muralhas.
- **Completa-se com:** ADR 0064, que decide onde ficam as bancas, quando aparecem
  (ao acender a lareira da fundação) e como a cidade cresce dentro das muralhas.

## Problema e pedido

O vagabundo procurava a moeda ao passo normal e qualquer aliado podia construir
uma muralha. O dono pediu corrida pela moeda, contratação ao apanhá-la, formação
do construtor na banca do reino e só então pagamento e construção da muralha,
com etapas cada vez mais caras, como no Kingdom.

## Decisão

1. O raio continua o `recruit_notice_px` existente, incluindo o seu limite. Moeda
   pousada, na mesma faixa, livre de obra e que caiba no saco é alvo. Empate pelo
   id; duas pessoas não duplicam a moeda.
2. A corrida aplica `recruit_run_mult` ao movimento sem alterar a velocidade base.
   O multiplicador 2 é proposta reversível no CSV, registada na Q-230. A escolha
   continua fatiada; perder a moeda cancela o alvo no tick seguinte. Contratação
   termina a corrida. Um movimento neutro sem alvo de moeda não é cancelado.
3. A banca do martelo existe desde a fundação, dentro do primeiro recinto
   (ADR 0064). Não dá pessoas gratuitas: transforma um recrutado existente.
4. Só um construtor vivo da mesma faixa e do dono permite destinar moeda a uma
   muralha. O posto só aceita construtores e o progresso exige presença física.
   Rei, companhia, arqueiro e trabalhador sem martelo não constroem muralhas.
   Perder o construtor pausa o andaime; outro pode retomá-lo.
5. A escada continua a de `walls.csv`: Estacaria, Paliçada, Pedra, Ferro e Bastião,
   uma etapa por pagamento, com custos existentes crescentes. Sede, conquistas,
   Lenho, caminhos e unicidade conservam os requisitos. O guia nomeia o próximo
   degrau, pede construtor quando falta e pede muralha antes do canteiro.

## Save e validação

Não há nova coluna autoritativa nem versão de save. A corrida não entra no save:
é derivada do alvo de cada tick. Ao retomar, um treino em curso segue a banca na
posição atual da autoria, sem repetir nem perder o treino.

Testes vermelhos reproduziram a corrida ausente, a muralha sem construtor e o
treino preso na posição antiga. A validação inclui raio, moeda reservada, disputa,
cancelamento, fluxo com gestos e dinheiro inicial, obra sem rei, morte do
construtor, save e as cinco etapas.

Os preços das muralhas, população inicial, materiais e arte original permanecem.
Não há nova dependência. Esta decisão implementa o pedido para Empire; não afirma
que seus valores sejam os preços de uma edição de Kingdom.
