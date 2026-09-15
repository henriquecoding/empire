# 49 — Economia · EconomySystem — três circuitos, uma passagem por fase

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

O §06 define produção, conversão e comércio. Aqui está o contrato: quando corre, o que toca, e a regra que impede a matéria-prima de virar um inventário.

- **Corre** — Uma vez por transição de fase, no passo 7 do tick. Nunca por frame.
- **Lê** — state.buildings, state.player.crafts, rotas de comércio abertas, EconomyCurve.
- **Escreve** — Matéria dentro de cada edifício, moeda no chão, capacidades ativas, rendimento das rotas.
- **Nunca escreve** — Um inventário do jogador. Não existe inventário. A matéria vive no edifício que a produziu, e é isso que mantém os dois verbos intactos.

## O algoritmo, por fase

```gdscript
func on_phase(s: GameState, phase: int) -> void:
    # 1 — produção: cada edifício acumula a sua matéria
    for b in s.buildings:                       # ordenado por id (I2/§42)
        if b.destroyed or b.on_rot_trail: continue
        var d := Registry.building(b.data_id)
        b.stock += d.yield_per_phase
    # 2 — conversão: ofícios consomem matéria e produzem moeda OU capacidade
    for c in s.player.active_crafts:
        var src := _find_building(s, c.source_id)
        if src == null or src.stock < c.cost: continue
        src.stock -= c.cost
        EventBus.queue(&"material_consumed", [src.id, c.kind, c.cost])
        if c.mode == CraftData.Mode.COIN:
            _drop_coins(s, src.x, c.coin_yield)
        else:
            _grant_capacity(s, c.capacity_kind, c.magnitude)
    # 3 — comércio: uma vez por dia, no DAWN
    if phase == GameClock.Phase.DAWN:
        for r in s.player.routes:
            _drop_coins(s, s.player.core_x, r.income)
```

| Caso difícil | Resolução |
| --- | --- |
| Edifício no rasto da Podridão | Não produz nesse dia. Plantações são destruídas; as restantes só param. A distinção está no BuildingData, não em if por tipo. |
| Ofício sem matéria suficiente | Não faz nada e não avisa. A falta de trânsito de carroças é o aviso — é o HUD diegético do §24. |
| Duas conversões a competir pela mesma matéria | Ordem por craft.id. Determinista, e o jogador aprende a ordem. |
| Moeda largada quando o chão está cheio | Empilha na mesma coordenada com contagem, até 99. Acima disso, funde num saco. |
| Rota de comércio de povo arrasado | Fechada em fortress_conquered se o modo foi saque. É a razão económica para não arrasares. |

