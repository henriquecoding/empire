# 61 — Entrada · Dois verbos, e como chegam à simulação

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Limite dos exemplos: o encaminhamento antigo de ASSUME não autoriza assumir tropas nem trocar livremente entre imperadores. A ação contextual valida o contrato de herdeiro da §15; ataque, habilidade e corrida têm entradas separadas com paridade de toque (§24).

O mapa completo de comandos está no §24. Aqui só interessa o contrato: a entrada nunca muda estado diretamente.

```gdscript
# scenes/game.tscn → src/ui/input_router.gd
func _unhandled_input(e: InputEvent) -> void:
    if e.is_action_pressed(&"verb_drop"):
        # NÃO mexe no estado. Enfileira uma intenção.
        Sim.queue_intent(Intent.DROP_COIN, {&"x": _player_x(), &"band": _player_band()})
    elif e.is_action_pressed(&"verb_assume"):
        Sim.queue_intent(Intent.ASSUME, {&"target": _nearest_assumable()})
```

As intenções são consumidas no início do tick seguinte, na ordem em que chegaram. É o que faz o jogo determinista apesar de haver um humano: dada a mesma seed e a mesma sequência de intenções, a partida repete-se exatamente. E é isso que torna possível gravar uma repetição em 40 bytes por segundo.
