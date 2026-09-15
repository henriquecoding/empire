# 42 — Determinismo · Aleatoriedade com disciplina

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Uma seed reproduz tudo — o §21 promete isso e mostra-a ao jogador. Essa promessa custa uma regra: a aleatoriedade é dividida em fluxos independentes, e cada consumidor usa sempre o mesmo.

## Os fluxos

| Fluxo | Consome | Semeado com | Afeta a simulação? |
| --- | --- | --- | --- |
| world | Geração de região, tipos de segmento, cavidades, passagens | hash(str(seed) + "world") | Sim |
| combat | Precisão do arqueiro, ordem de desempate na fila de contacto | hash(str(seed) + "combat") | Sim |
| rot | Intervalo de invocação, escolha de criatura, largura da mancha | hash(str(seed) + "rot") | Sim |
| economy | Variação de rendimento, preços de mercenários, saque | hash(str(seed) + "economy") | Sim |
| ai | Desempate de utilidade do rei inimigo, atribuição de trabalho | hash(str(seed) + "ai") | Sim |
| visual | Variante de prop, desfasamento de animação, variação de pitch, partículas | Time.get_ticks_usec() | Nunca |


```gdscript
# src/core/rng_service.gd
extends Node

var _streams: Dictionary = {}   # StringName -> RandomNumberGenerator
var _seed: int = 0

func configure(world_seed: int) -> void:
    _seed = world_seed
    _streams.clear()
    for s in [&"world", &"combat", &"rot", &"economy", &"ai"]:
        var r := RandomNumberGenerator.new()
        r.seed = hash(str(world_seed) + str(s))
        _streams[s] = r
    var v := RandomNumberGenerator.new()
    v.randomize()                # só o fluxo visual é livre
    _streams[&"visual"] = v

func stream(name: StringName) -> RandomNumberGenerator:
    assert(_streams.has(name), "fluxo RNG desconhecido: %s" % name)
    return _streams[name]

func snapshot() -> Dictionary:   # para o save: guarda o estado, não só a seed
    var out := {}
    for k in _streams:
        if k != &"visual":
            out[k] = _streams[k].state
    return out
```

> **A parte que quase toda a gente esquece**
>
> Guardar a seed não chega. Se o jogador grava a meio da noite 9, retomar tem de continuar a sequência aleatória exatamente onde ia — logo o save guarda o estado de cada fluxo (rng.state), não a semente. Sem isto, carregar um save muda a noite que se estava a jogar, e o bug parece um fantasma.

## Regras derivadas

**Iteração ordenada** — Nunca iterar um Dictionary quando o resultado afeta a simulação. Ordem de dicionário não é garantida entre execuções. Usa arrays ordenados por id.

Posição e massa da Podridão avançam por delta fixo de 1/30 s, sempre o mesmo. Nada de get_process_delta_time() dentro de src/sim/.

O combate resolve por unit.id crescente, não por ordem de nó nem por proximidade. Empates resolvem-se pelo fluxo combat, nunca por posição de memória.

Mostrada no ecrã de pausa e copiável. É o teu melhor instrumento de depuração e um dos melhores hábitos de comunidade que podes ter de graça.
