# 54 — Mundo · WorldGen — determinista, e por camadas separadas

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

O §21 resolve o conflito entre geração e composição com uma regra: o parallax nunca é por segmento. Aqui está a consequência técnica — a geração corre em duas passagens independentes.

1. Passagem 1 — a paisagemAs camadas 1 a 4 (céu, montanha, colina, fundo médio) são geradas uma vez para a região inteira a partir do fluxo world. Produzem texturas contínuas com repeat_size igual à largura da região. Nenhum segmento sabe que elas existem.

## Passagem 2 — os segmentos

Oito segmentos de 640 px sorteados por peso, com as restrições de adjacência do §21. Cada um instancia uma cena autorada, com os seus slots de construção e 0–2 cavidades. Só isto colide, só isto é jogável.

## Passagem 3 — costura

Terreno e primeiro plano atravessam as juntas: erva, pedras e ramos são colocados depois da montagem, ignorando fronteiras de segmento. É o que apaga a grelha aos olhos do jogador.

```gdscript
func generate(seed: int, biome: BiomeData) -> WorldState:
    var rng := RngService.stream(&"world")
    var w := WorldState.new()
    w.width = _region_width(biome)             # derivado do tempo de travessia, §21
    w.parallax = _make_landscape(rng, biome, w.width)   # passagem 1
    w.segments = _pick_segments(rng, biome, w.width / 640)
    _apply_adjacency_rules(w.segments)          # fortalezas nunca adjacentes, etc.
    _place_core(w)                              # base_inicial ao centro
    _carve_cavities(rng, w)
    _scatter_decoration(rng, w)                 # passagem 3, ignora juntas
    return w
```

> **A ordem é parte do contrato**
>
> Trocar duas chamadas nesta função muda todos os mundos gerados por todas as seeds anteriores. Não é um refactor inocente: é quebrar todos os saves e todas as seeds partilhadas. Se a ordem tiver mesmo de mudar, sobe WORLDGEN_VERSION e trata como migração (§62).
