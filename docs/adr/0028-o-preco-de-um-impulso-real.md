# ADR 0028 — O preço de um impulso real é um sistema, e não um número

- Estado: aceite
- Data: 2026-09-28
- Secção do dossiê: §15, §57

## Contexto
A Q-014 perguntava quanto custa um impulso (o §15 só diz que o tirano paga metade). O `impulses.csv` tinha 12 moedas
em todos. O dono respondeu: *"pense e trabalhe bem para elaborar isso, deve ser um sistema bem completo que faça
sentido."* Um preço fixo fica caro no dia 1 e de graça no dia 20, e seis preços iguais para seis coisas diferentes
fazem do melhor impulso o único que se usa.

## Decisão
**O preço de um impulso = base × `income_growth`^(dia−1) × perfil de ganância × `impulse_repeat_mult`^(repetições
nos últimos `impulse_repeat_days` dias), arredondado e nunca de graça.**
- A base é a medida do que o impulso vale: Colheita Forçada e Chamada às Armas 4, Rota Protegida 5, Feira Livre e
  Vigília 6, Perdão Real 10 (a conta de cada uma está na nota do `impulses.csv`).
- Cresce ao ritmo da produção do §06, e por isso custa sempre o mesmo em dias de trabalho.
- O perfil é o da gama onde a ganância do rei cai (`greed_profiles.csv`): o tirano paga metade (§15).
- O mesmo decreto repetido dentro de 3 dias custa ×1,5 por vez: o reino cansa-se da mesma ordem.
Continua a ser um por dia, pago do saco do rei. Vive no `CrownSystem.price()`, vai no save, e o Inspector mostra o
preço do dia.

## Alternativas consideradas
Preço em fração do rendimento do dia medido: exacto mas instável (uma obra caída mudava o preço a meio do dia).
Custo em moedas e dívida: mistura dois sistemas que o §15 separa. Rejeitadas.

## Consequências
As bases e os dois números da repetição estão em `_proposed` para o playtest. A indisponibilidade de três impulsos
(Q-110, Q-113) não muda.
