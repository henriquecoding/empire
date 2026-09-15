# src/sim/data/amargueiro_data.gd — os tres destinos de um Amargueiro (§74).
# v6: uma tropa que morre fora das muralhas e nao e recolhida antes da alvorada
# cria raiz. Cortar, consagrar ou deixar — sempre com o Verbo 1 (§05).
# Gerado a partir de data/source/amargueiros.csv.
class_name AmargueiroData
extends Resource

@export var id: StringName
@export var display_key: String

@export_group("Preco")
@export var cost_coins: int = 0
@export var cost_seeds: int = 0
## Segundos de lenhador presente, como o construtor do §55.
@export var work_seconds: float = 0.0
## Regra 2 da §74: so se corta depois de aguentar uma noite inteira.
@export var nights_standing_required: int = 0
## 1 = ja na primeira alvorada; 2 = so a partir da segunda.
@export var from_dawn: int = 1

@export_group("Rendimento")
## Regra 3 da §74: rende o que a pessoa era — escalas 1, 2 e 3 (§22).
@export var yield_by_tier: Array[int] = [0, 0, 0]
@export var yield_named: int = 0
## Regra 1: o Lenho Amargo nao e moeda. Vazio quando o destino nao rende nada.
@export var yield_kind: StringName = &""

@export_group("Efeito na noite")
## Massa que este destino tira (negativo) ou poe (positivo) por noite (§74).
@export var mass_delta: float = 0.0
@export var mass_delta_named: float = 0.0
## true = o efeito repete-se todas as noites, para sempre.
@export var permanent: bool = false
## &"marker" quando o Amargueiro vira Marco de pedra consagrado.
@export var becomes: StringName = &""
## Raio, em px, onde nao nascem raizes novas (§74).
@export var protect_radius_px: int = 0
## Abrandamento da Podridao dentro do raio — a regra do terreno consagrado (§05).
@export var slowdown: float = 0.0

@export_group("Custo humano")
## So se a tropa tinha nome (§76): toda a gente estava a ver.
@export var morale_cost: int = 0
@export var morale_days: int = 0
