# ADR 0061 — A caça longe do reino

- **Estado:** aceite, reversível (03/10/2026)
- **Contexto:** o dono jogou o dia 1 e escreveu, com uma captura do Empire e outra do Kingdom: *«As criaturas estão com
  o respawn colado com o reino, está tudo muito em cima, deve ser algo melhor elaborado como é em Kingdom. Algo similar
  a isso era o que eu queria»*. Na captura, o rei está à porta do castelo com coelhos, faisão e raposa à volta, na
  estrada. A causa: quatro das oito tocas de casa (três arbustos e uma rocha, Q-218) ficavam a 60–180 px do castelo,
  no único chão largo que as obras da região deixam (Q-207), e cada uma volta a dar o seu bicho a cada 60–75 s de luz
  (Q-217). No Kingdom a praça do acampamento não tem caça: os coelhos saem da erva alta das planícies para lá das
  muralhas e os veados vivem nas florestas (ADR 0058, a pesquisa).

## Decisão

1. **Nenhuma toca dentro da primeira muralha.** As tocas de casa ficam só nos arrabaldes, no chão livre entre as obras
   de fora: o buraco do coelho entre o galinheiro e a torre de oeste (−830 px, e é o coelho do 1:10 do §25), a árvore
   do veado entre o farol e o sino de vigia (−1692), o buraco da raposa na beira de oeste (−1860) e a árvore do javali
   entre o celeiro e o sino de vigia (+1656). Saem os três arbustos e a rocha da porta do castelo.
2. **O resto da caça vive nas terras** (Q-217), para lá das muralhas dos dois lados, como já vivia: o primeiro segmento
   de cada lado tem sempre pelo menos uma toca de cada bicho que lá cabe, o faisão incluído.
3. **Números (propostas, `_proposed`):** o coelho passa de 4 para 1 toca por região, e o faisão de 1 para 0 (sem o
   arbusto da porta, não tem sítio em casa).
4. **Saves antigos:** ao carregar, as tocas de casa que já não são sítio (as da porta) perdem-se com os bichos delas,
   e as que faltam entram nos sítios livres (`HuntWatch.reconcile`).

## O que não muda

O ritmo de cada bicho (`respawn_s`), a caça das terras, a manada, a noite e os imperadores que caçam (ADR 0057, 0058).
O coelho do 1:10 continua a ser a primeira toca de casa; agora sai dos arrabaldes de oeste, do lado onde se começa.

## Consequências

- Mais fácil: o reino lê-se como reino e a caça como coisa de fora; ir caçar é sair para os arrabaldes e para as
  terras, como no Kingdom.
- Mais difícil: no início há menos caça a dois passos do castelo; os caçadores andam mais. Se a caça de casa deve ter
  mais tocas nos arrabaldes, é a Q-228.
- Reverter: repor as quatro linhas de `HuntWatch.SITIOS` e os `burrows_per_region` do coelho (4) e do faisão (1).
