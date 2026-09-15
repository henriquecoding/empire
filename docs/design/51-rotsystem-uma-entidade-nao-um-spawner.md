# 51 — Podridão · RotSystem — uma entidade, não um spawner

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

A §05 insiste que A Podridão é um sistema de primeira classe. Tecnicamente isso quer dizer: tem posição contínua, um orçamento de massa, e é a única fonte de criaturas no jogo.

```gdscript
# src/sim/state/rot_state.gd
class_name RotState extends RefCounted
var active: bool = false
var x: float                      # centro da mancha
var width: float
var mass: float                   # orçamento de invocação
var side: int                     # -1 esquerda, +1 direita, 0 = ambos (dia 12+)
var next_summon_at: float
var trail_from: float
var trail_to: float
```

| Momento | O que acontece | Fórmula |
| --- | --- | --- |
| DUSK | Nasce na borda mais distante do lado ameaçado | mass = 60 + 26·dia + 40·fortalezas |
| Todo o tick | Avança em direção ao império | v = (14 + 0,9·dia) · (1 − abrandamentos) px/s |
| A cada 4–7 s | Gasta massa a invocar da tabela do bioma | Escolhe a criatura mais cara que cabe e cujo dia mínimo já passou |
| Ao avançar | Deixa rasto: plantações destruídas, animais mortos, −20% de movimento | Persiste até ao DAWN seguinte |
| DAWN | Recua. Não morre — nunca é morta em campo aberto | active = false, criaturas vivas dissolvem-se |


> **A escolha de criatura, e porque é assim**
>
> "A mais cara que cabe" produz naturalmente a curva certa: nos primeiros dias há massa só para Rastejantes; ao dia 14 aparece o Aríete de lodo (48 de massa) e a noite muda de carácter sem uma única linha de scripting por dia. Se em vez disso escolhesses ao acaso entre as disponíveis, terias noites 14 sem Aríete nenhum e o jogador nunca aprenderia a lição que o §07 quer ensinar.

## As quatro interações do jogador

**Ver** — A mancha é visível no crepúsculo. O rot_moved alimenta o stem de tensão do áudio proporcionalmente à distância — o jogador ouve-a antes de a ver.

Fogueiras, barris e terreno consagrado emitem rot_slowed. Cada segundo de atraso é uma invocação a menos, e isso é literal: o orçamento gasta-se por tempo, não por distância.

Se o caminho de superfície estiver selado, a mancha usa a faixa subterrânea ou aérea. É uma tática avançada, e a implementação é um grafo de três nós — não vale mais do que isso.

rot_fed remove massa: 0,5 por moeda, mais por animal ou tropa. Transforma economia em segurança, e é a mecânica mais sinistra do jogo.
