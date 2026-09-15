# 59 — Render · A pilha, de trás para a frente

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Os deltas de saturação, valor e matiz estão no §22 e não se repetem aqui. Isto é a ordem, os nós e a regra do pixel inteiro.

| Z | Nó | motion_scale | CanvasModulate | Notas |
| --- | --- | --- | --- | --- |
| −60 | SkyLayer | 1/32 | Céu | Bandas + dither. Sol e lua posicionados pelo GameClock. |
| −50 | MountainLayer | 1/8 | Distância | Massa lisa, zero textura, zero contorno |
| −40 | HillLayer | 1/4 | Distância | Detalhe mínimo 4 px |
| −30 | MidLayer | 1/2 | Plano médio | A faixa que faltava (§11) |
| −20 | HazeBands | — | — | 2–3 bandas aditivas, 6–14% de opacidade |
| −10 | TerrainLayer | 1 | Jogo | TileMapLayer · superfície e corte de solo |
| 0 | ShadowLayer | 1 | Jogo | Elipses de contacto, multiplicativas |
| 10 | EntityLayer | 1 | Jogo | Ordenado por band, depois por x |
| 20 | FxLayer | 1 | — | Mancha da Podridão, projéteis, partículas |
| 30 | ForeLayer | 3/2 | Primeiro plano | Escuro, silhueta, sobrepõe-se às tropas |
| 40 | GodRays | — | — | Só entre nascer e pôr do sol |
| 100 | DebtHud | — | — | O único HUD permanente, e só com dívida |


```gdscript
# src/world/parallax_stack.gd — a invariante I8, num sítio só
func _process(_d: float) -> void:
    var cam := camera.global_position.x
    for l in layers:
        l.node.position.x = floor(cam * (1.0 - l.motion_scale))   # floor, sempre
```

> **Multi-mesh para a vegetação**
>
> Erva, flores, pedrinhas e detritos são milhares de instâncias e não têm lógica nenhuma. MultiMeshInstance2D: uma draw call para tudo. Se um agente propuser Sprite2D por tufo de erva, rejeita — é a diferença entre 60 e 900 draw calls.
