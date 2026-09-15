# 20 — IA · Como as tropas e os reis decidem

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

O Kingdom prova que previsível vence inteligente quando o jogador não tem controlo direto. A arquitetura abaixo é deliberadamente simples na base e sofisticada só onde é preciso.

**Camada A — Atribuição de trabalho (global)** — Um sistema central, uma vez por fase do dia. Os postos (muro, plantação, torre, cozinha) publicam vagas com prioridade; as tropas disponíveis são atribuídas por score = adequação × proximidade × urgência. É o algoritmo do Kingdom, e é o que garante previsibilidade.

Uma máquina de estados pequena: IR_PARA, TRABALHAR, COMBATER, FUGIR, MORTO. Sem behavior trees para tropas comuns. Behavior tree só para chefes e criaturas da Podridão — aí LimboAI ou Beehave justificam-se.

## Movimento em mundo 1.5D

Não precisas de A* nem de NavigationServer2D na superfície: o mundo é uma linha. O movimento é sign(alvo.x - self.x) mais steering de separação. Complexidade real só existe em três casos:

- Mudança de faixa — grafo minúsculo de passagens e pontes. Dijkstra sobre 20–60 nós. Trivial.
- Voadoras — movimento livre em X e Y dentro da faixa aérea, com flocking leve.
- Subterrâneo — aí sim há túneis ramificados: usa NavigationRegion2D só nesta faixa.

## Utilidade para as escolhas do rei inimigo

Os impérios inimigos não são scripts. Cada um avalia, uma vez por dia, um conjunto pequeno de ações com pontuação de utilidade ponderada pela sua ganância e pela idade do rei. Cinco ações, cinco fórmulas, comportamento que parece intencional — e cabe em 150 linhas.

```gdscript
# src/sim/ai/enemy_king_ai.gd
func choose_action(s: KingdomState) -> StringName:
    var greed := s.greed / 100.0
    var scores := {
        &"fortify":  s.wall_deficit * 1.4 + s.threat * 0.8,
        &"attack":   s.army_surplus * 1.2 - s.king_age_risk,
        &"recruit":  (1.0 - s.army_ratio) * 1.1,
        &"expand":   s.income_deficit * 0.9 * (1.0 - greed),
        &"diplomat": s.favor_ratio * 1.3,
    }
    # tiranos poupam no muro e gastam em elites
    if greed > 0.65:
        scores[&"fortify"] *= 0.45
        scores[&"recruit"] *= 1.35
    return _weighted_argmax(scores, s.rng)
```

> **Porque é que isto é suficiente**
>
> Cinco números por dia por império geram comportamento que os jogadores descrevem como "ele percebeu que eu estava fraco". Não percebeu — subtraiu king_age_risk. A IA de estratégia legível é quase sempre utilidade ponderada, não planeamento, e a diferença de custo entre as duas é de semanas.
