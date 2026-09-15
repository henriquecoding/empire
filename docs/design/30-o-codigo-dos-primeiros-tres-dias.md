# 30 — Arranque · novo · O código dos primeiros três dias

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Isto não é pseudocódigo. É o esqueleto real do projeto, escrito para caber nas regras do §28: tipado, curto, sem nós na simulação. Cria estes quatro ficheiros e tens o motor do jogo — literalmente a Camada 1 do §00.

### 1 · src/core/event_bus.gd — autoload

```gdscript
## Único ponto de acoplamento do projeto. Sistemas emitem, cenas ouvem.
## Nada em src/sim/ conhece este ficheiro — os sistemas devolvem, não emitem.
extends Node

# Ciclo
signal phase_changed(from: int, to: int)
signal day_started(day: int)

# Economia
signal coin_dropped(world_pos: Vector2, amount: int)
signal coin_collected(unit_id: int, amount: int)
signal treasury_changed(total: int, delta: int)

# Podridão
signal rot_spawned(side: int, mass: float)
signal rot_moved(x: float, mass: float)
signal creature_requested(kind: StringName, at: Vector2)
signal rot_retreated()

# Unidades
signal unit_spawned(id: int, kind: StringName, at: Vector2)
signal unit_died(id: int, at: Vector2, dropped: StringName)
signal unit_band_changed(id: int, band: int)

# Construção
signal structure_built(kind: StringName, at: Vector2, level: int)
signal structure_destroyed(kind: StringName, at: Vector2)
```

### 2 · src/sim/game_clock.gd — puro, testável, sem Node

```gdscript
class_name GameClock extends RefCounted

enum Phase { DAWN, MORNING, NOON, AFTERNOON, DUSK, NIGHT }

var day: int = 1
var elapsed: float = 0.0

var _durations: PackedFloat32Array
var _day_length: float

func _init(cfg: ClockData) -> void:
    _durations = cfg.phase_durations          # [15,85,40,85,30,105]
    _day_length = 0.0
    for d in _durations:
        _day_length += d

## Devolve as transições ocorridas neste tick. Quem chama emite os sinais.
func tick(delta: float) -> Array[Dictionary]:
    var events: Array[Dictionary] = []
    var before := current_phase()
    elapsed += delta
    while elapsed >= _day_length:
        elapsed -= _day_length
        day += 1
        events.append({&"type": &"day", &"day": day})
    var after := current_phase()
    if after != before:
        events.append({&"type": &"phase", &"from": before, &"to": after})
    return events

func current_phase() -> Phase:
    var acc := 0.0
    for i in _durations.size():
        acc += _durations[i]
        if elapsed < acc:
            return i as Phase
    return Phase.NIGHT

func phase_progress() -> float:
    var acc := 0.0
    for i in _durations.size():
        if elapsed < acc + _durations[i]:
            return (elapsed - acc) / _durations[i]
        acc += _durations[i]
    return 1.0

func seconds_until(p: Phase) -> float:
    var start := 0.0
    for i in int(p):
        start += _durations[i]
    var diff := start - elapsed
    return diff if diff >= 0.0 else diff + _day_length
```

### 3 · src/sim/rot_system.gd — o coração do jogo

```gdscript
class_name RotSystem extends RefCounted

var active: bool = false
var x: float = 0.0
var mass: float = 0.0

var _dir: int = -1
var _speed: float = 0.0
var _next_summon: float = 0.0
var _rng: RandomNumberGenerator
var _table: Array[CreatureData]

func _init(rng: RandomNumberGenerator, table: Array[CreatureData]) -> void:
    _rng = rng
    _table = table

func spawn(day: int, side: int, map_width: float, forts: int) -> void:
    active = true
    _dir = -side
    x = map_width if side > 0 else 0.0
    _speed = 14.0 + 0.9 * day
    mass = 60.0 + 26.0 * day + 40.0 * forts
    _next_summon = _rng.randf_range(4.0, 7.0)

## Avança e devolve os pedidos de invocação. Não instancia nada.
func tick(delta: float, on_consecrated: bool) -> Array[Dictionary]:
    if not active:
        return []
    var v := _speed * (0.6 if on_consecrated else 1.0)
    x += v * delta * _dir

    var out: Array[Dictionary] = []
    _next_summon -= delta
    if _next_summon <= 0.0:
        var pick := _affordable()
        if pick != null:
            mass -= pick.mass_cost
            out.append({&"kind": pick.id, &"at": Vector2(x, Band.GROUND_LINE)})
        _next_summon = _rng.randf_range(4.0, 7.0)
    return out

func feed(amount: float) -> void:
    mass = maxf(0.0, mass - amount)

func retreat() -> void:
    active = false
    mass = 0.0

func _affordable() -> CreatureData:
    var pool: Array[CreatureData] = []
    for c in _table:
        if c.mass_cost <= mass:
            pool.append(c)
    if pool.is_empty():
        return null
    return pool[_rng.randi_range(0, pool.size() - 1)]
```

### 4 · src/actors/unit_system.gd — 300 unidades sem _process

```gdscript
## Um nó para todas as tropas. As unidades são linhas em arrays paralelos,
## não nós com script. É o que permite 300 unidades a 60 fps.
class_name UnitSystem extends Node2D

const SLICES := 6                          # 1/6 das unidades decide por tick

var ids: PackedInt32Array = []
var pos: PackedVector2Array = []
var hp: PackedInt32Array = []
var state: PackedByteArray = []            # 0 IDLE 1 GOTO 2 WORK 3 FIGHT 4 FLEE
var band: PackedByteArray = []             # 0 AERIAL 1 SURFACE 2 UNDERGROUND
var kind: Array[StringName] = []
var sprites: Array[Node2D] = []

var _slice: int = 0

func _physics_process(delta: float) -> void:
    _slice = (_slice + 1) % SLICES
    var n := ids.size()
    for i in n:
        # decisão fatiada: cada unidade repensa a cada 6 ticks (0,2 s a 30 Hz)
        if i % SLICES == _slice:
            _decide(i)
        _advance(i, delta)
        sprites[i].position = pos[i]

func _decide(i: int) -> void:
    pass   # consulta o JobBoard; ver §29, prompt 4

func _advance(i: int, delta: float) -> void:
    pass   # movimento 1.5D: sign(alvo.x - pos[i].x) + separação
```

> **Porque é que este esqueleto vale mais do que parece**
>
> Repara no padrão que atravessa os quatro ficheiros: os sistemas puros devolvem pedidos; só a camada de nós age. RotSystem.tick() devolve "invoca um Rastejante em x=1200" — não instancia nada. Isto dá-te três coisas de uma vez: testes que correm em milissegundos sem abrir o Godot, um save que é só o estado dos sistemas, e um multijogador em que só os pedidos precisam de ser replicados. As três decisões mais caras do projeto ficam resolvidas por uma convenção de estilo.
