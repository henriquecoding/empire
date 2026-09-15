# 52 — IA · JobSystem e UnitSystem — previsível vence inteligente

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Duas camadas, como o §20 define. A de cima corre uma vez por fase e é global; a de baixo é uma máquina de estados de cinco casos por unidade. Nada de behavior trees para tropas comuns.

## Camada A — atribuição de trabalho

```gdscript
func assign(s: GameState) -> void:
    var openings := _collect_openings(s)      # postos publicam vagas com prioridade
    openings.sort_custom(func(a, b): return a.priority > b.priority)
    var free := s.units.filter(func(u): return u.job_id == -1 and u.state != UnitFsm.State.DEAD)
    for o in openings:
        var best := -1
        var best_score := -INF
        for i in free.size():
            var u: UnitRec = free[i]
            var score := _fit(u, o) * _proximity(u, o) * o.urgency
            if score > best_score:
                best_score = score; best = i
        if best >= 0:
            free[best].job_id = o.id
            free.remove_at(best)
```

> **Porque é que isto basta**
>
> É o algoritmo do Kingdom, e a previsibilidade é a funcionalidade. Num jogo de controlo indireto, o jogador precisa de conseguir antecipar para onde vão as suas tropas. Uma IA que otimiza melhor mas surpreende é pior. Se um agente propuser behavior trees para tropas comuns, rejeita — só chefes e criaturas da Podridão as justificam.

## Camada B — a máquina de estados

| Estado | Entra quando | Sai quando | Custo por tick |
| --- | --- | --- | --- |
| GOTO | Tem trabalho e está longe | Chega ao posto | Movimento em X |
| WORK | Está no posto | Fase muda, ameaça em alcance, posto destruído | Nada — só animação |
| FIGHT | Inimigo em alcance e a unidade tem dano | Alvo morre ou sai de alcance | Resolução de combate |
| FLEE | Vida < 25% e classe permite, ou lealdade quebrada | Chega ao núcleo, ou morre | Movimento em X |
| DEAD | Vida ≤ 0 | Ressuscitada até ao amanhecer, ou removida | Nada |


Fatiamento: só 1/6 das unidades reavalia por tick (u.id % 6 == s.tick % 6). Uma unidade decide cinco vezes por segundo, o que é impercetível e corta a IA para um sexto do custo. O movimento e o combate continuam a correr todos os ticks — é só a decisão que é fatiada.

## O rei inimigo

Utilidade ponderada, cinco ações, uma vez por dia por império. O código está no §20 e não se repete aqui. A parte que interessa aqui é o contrato: KingAISystem lê um KingdomState e devolve um StringName. Não executa a ação — emite king_action_chosen e os sistemas respetivos reagem. É o que permite testá-la sem simular nada.
