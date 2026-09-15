# src/sim/data/economy_profile.gd — os perfis padrao do teste de design (§06, §31).
# Gerado de data/source/economy_profiles.csv. Sao as quatro alavancas do simulador
# da §06: fontes de producao, rotas, tropas mantidas e ganancia.
class_name EconomyProfile
extends Resource

@export var id: StringName
@export var sources: int = 0
@export var routes: int = 0
@export var troops: int = 0
@export var greed: int = 0
## Intervalo esperado do dia de asfixia; (0, 0) = sem alvo proprio.
@export var expect_suffocation: Vector2i = Vector2i()
