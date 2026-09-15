# ADR 0014 — A Podridão faz propostas, e a dívida mede-se em luz

- Estado: aceite
- Data: 2026-09-14
- Secção do dossiê: §14, §15, §24, §26, §75, §79

## Contexto
A §05 tinha uma caixa "alimentar" sem interface nenhuma. A §14 tinha um só sorvedouro emocional — a dívida dos
mercenários, que é ansiedade com relógio à vista. E a noite não tinha decisões: tinha combate.

## Decisão
Uma vez por noite, entre os 20 e os 60 s depois do crepúsculo, a mancha chega a 300 px da muralha mais exterior e
faz uma proposta: uma frase de oito palavras no mundo, na tipografia entalhada da §24, e um prato de barro no chão
à borda da mancha. Aceitar é pôr o preço dentro do prato com o Verbo 1. Recusar é não fazer nada, e custa +8 de
massa por recusa das últimas cinco noites, com teto em +40 — que volta a zero assim que se aceitar uma vez.
São doze ofertas (`offers.csv`), sorteadas entre as elegíveis pelo fluxo de aleatoriedade da §42, com a coluna
`requires` a obedecer a uma gramática de duas formas e mais nenhuma: `<chave><op><numero>` e `<chave>=<id>`,
vírgulas em AND, sem parênteses, sem "ou" e sem negação.
Aceitar sobe a Dívida da Candeia: um contador de 0 a 20, escondido, que nunca desce. O mostrador é a luz — halo aos
3, o Zelador aos 6, ambiente âmbar aos 9, segunda chama aos 12.

## Alternativas consideradas
Mostrar a Dívida como número, barra ou ícone: assim que o jogador vê "Dívida: 7" começa a otimizar um número em vez
de decidir. Rejeitado — é o mesmo mecanismo que faz o Lenhador da série não dar por nada durante anos.
Contar qualquer moeda que caia perto da mancha: perder uma tropa nomeada por um clique mal dado numa noite
atarefada seria a coisa mais injusta do jogo. Só conta o que cai no prato.
Deixar a penalização da recusa crescer para sempre: um jogador que decida nunca negociar ficava com um jogo
impossível. O teto torna a recusa um imposto fixo e conhecido, e o teste D-04 guarda-o.

## Consequências
`offers.csv` (12 linhas) e cinco campos novos em `rot.csv`. Custa 1 280 palavras traduzíveis (§75), o que muda a
frase da §27 de "quase não precisa de idiomas" para "precisa de mil e trezentas palavras". A Dívida ≥ 12 fecha o
epílogo União (§79) e abre a décima segunda oferta, a única que acaba o ciclo em vez de subir a dívida.
A Dívida fica escondida mesmo no modo de acessibilidade (Q-045): a redundância são o brilho e os estandartes da
§82, porque um número não é acessibilidade, é *spoiler*.
Reverter fecha os dois epílogos outra vez e deixa a §05 com a caixa "alimentar" vazia.
