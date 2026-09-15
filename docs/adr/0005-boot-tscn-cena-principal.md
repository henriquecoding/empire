# ADR 0005 — `boot.tscn` é a cena principal; `game.tscn` é instanciada por ela

- Estado: aceite
- Data: 2026-09-11
- Secção do dossiê: §41, §65, §70

## Contexto
A §41 tinha `boot.tscn` na árvore; a §65 fazia de `game.tscn` a cena raiz. Com o save a entrar na Fase 1, o
arranque tinha de ser reescrito.

## Decisão
`boot.tscn` carrega o `Registry`, o idioma e o save, decide que `game.tscn` instanciar, e só depois entrega. No dia
zero é um *placeholder* com um *sprite* e uma sombra, para o *export* ter o que mostrar (§68, onda 2).

## Alternativas consideradas
`game.tscn` como raiz: obriga a meter carregamento de save e idioma dentro da cena de jogo.

## Consequências
O ticket F0-10 substitui o *placeholder* pela versão da §70.
