# 48 — Relógio · GameClock — a fase do dia é um estado, não um temporizador

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Seis fases, 360 segundos, durações do §05. Tudo o resto no jogo pergunta ao relógio; o relógio não pergunta a ninguém.

| Fase | Duração | Início | Emite à entrada | Estado das tropas |
| --- | --- | --- | --- | --- |
| DAWN | 15 s | 0 | dawn_broke, phase_changed | Saem dos postos, em cascata |
| MORNING | 85 s | 15 | phase_changed | Trabalho livre |
| NOON | 40 s | 100 | phase_changed | Trabalho livre · fortalezas detetam |
| AFTERNOON | 85 s | 140 | phase_changed | Trabalho livre · mercenários +25% |
| DUSK | 30 s | 225 | dusk_fell, rot_spawned | Recolha aos postos |
| NIGHT | 105 s | 255 | night_started | Posto de cerco |


```gdscript
# src/core/game_clock.gd — o único sítio onde o tempo avança
enum Phase { DAWN, MORNING, NOON, AFTERNOON, DUSK, NIGHT }
const DURATIONS := [15.0, 85.0, 40.0, 85.0, 30.0, 105.0]
const STEP := 1.0 / 30.0

func advance(s: GameState) -> void:
    s.tick += 1
    s.phase_elapsed += STEP
    if s.phase_elapsed < DURATIONS[s.phase]:
        return
    var old := s.phase
    s.phase_elapsed = 0.0
    s.phase = (s.phase + 1) % 6
    if s.phase == Phase.DAWN:
        s.day += 1
        EventBus.queue(&"day_started", [s.day])
        EventBus.queue(&"night_survived", [s.day - 1, _deaths, _walls_lost])
    EventBus.queue(&"phase_changed", [old, s.phase])
```

> **A regra da fase, não do segundo**
>
> Nenhum sistema pergunta "que segundo é". Perguntam s.phase. Se um dia decidires que a tarde deve ter 95 segundos, mudas um número num .tres e nada mais no jogo se apercebe. Sistemas que dependem de segundos absolutos são o que torna um ciclo de dia impossível de afinar.
