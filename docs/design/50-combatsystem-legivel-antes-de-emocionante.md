# 50 — Combate · CombatSystem — legível antes de emocionante

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

As quatro regras do §07 são de design. Estas são as de implementação, e a mais importante é a ordem de resolução: sem uma ordem fixa, a mesma noite dá resultados diferentes e a promessa da seed morre.

## Ordem de resolução, por tick

1. Atualizar slots de contactoCada muro tem N slots (2 no nível 1 até 7 no Bastião). Slots libertados são preenchidos pelo atacante mais próximo da fila, com 0,4 s de transição visível. A fila tem posições estáveis entre 30 e 120 px — atribuídas, não emergentes.

## Decrementar cooldowns

Por unit.id crescente. Sempre.

## Escolher alvos

Prioridade: alvo marcado pelo Arqueiro > alvo atual se ainda vivo e em alcance > mais próximo em faixa atingível. Nunca reescolher se o alvo atual serve — é o que evita o desperdício de flechas que o Kingdom tem.

## Resolver ataques

Um roll do fluxo combat contra accuracy_open, ou acerto garantido dentro de torre. Emite attack_launched com hit já decidido — a apresentação nunca decide se acertou.

## Aplicar dano e mortes

Recolhe as mortes numa lista e só as aplica no fim do passo. Uma unidade que morre neste tick ainda não desaparece a meio da iteração — é o que evita "morreu e ainda atacou".

## Largar

Toda a morte larga: arma, moedas transportadas, ou corpo. Nada desaparece em silêncio.

> **Precisão é posição, e isso tem uma consequência técnica**
>
> accuracy_open = 0.34 em campo aberto e 1.0 dentro de torre não é um multiplicador de dano — é um roll. Isso significa que a variância de uma noite é real, e que a tabela de tempo-até-matar do §07 são médias. O teste de design test_arqueiros_nao_param_ariete tem de assertar sobre o valor esperado, não sobre uma corrida única, ou vai falhar de forma intermitente e vais acabar por o desligar.

## Ocupação de linha

```gdscript
# Uma regra de dados, não de física. Sem colisão entre aliados.
func _assign_queue_positions(wall: WallRec, attackers: Array) -> void:
    var free := attackers.filter(func(a): return a.slot == -1)
    free.sort_custom(func(a, b): return a.id < b.id)
    for i in free.size():
        # posições estáveis: não vibram, não empurram
        free[i].queue_x = wall.x + sign(free[i].x - wall.x) * (30 + i * 18)
```
