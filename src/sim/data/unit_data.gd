# src/sim/data/unit_data.gd — §44. Gerado a partir de data/source/units.csv.
# Os campos do grupo "v5.2" foram acrescentados pela base de dados de conteudo
# (docs/content/CONTENT_DATABASE.md); todos os outros sao os da §44, sem mudancas.
class_name UnitData
extends Resource

@export var id: StringName  # &"archer" — chave do Registry
@export var display_key: String  # chave de traducao, nao texto
@export var people: StringName = &"neutral"

@export_group("Combate")
@export var max_health: int = 10
@export var damage: int = 0
@export var attack_interval: float = 1.2  # segundos
@export var accuracy_open: float = 0.34  # 1.0 dentro de torre
@export var range_px: int = 28
@export var targets_bands: Array[int] = [1]  # que faixas consegue atingir

@export_group("Economia")
@export var recruit_cost: int = 1
@export var upkeep_per_day: float = 0.0
@export var drops_on_death: Array[StringName] = []

@export_group("Mundo")
@export var band: Band.Kind = Band.Kind.SURFACE
@export var move_speed: float = 26.0  # px/s
@export var scale_tier: int = 2  # 1, 2 ou 3 — §22
@export var can_change_band: bool = false

@export_group("Arte")
@export var sprite_frames: SpriteFrames
@export var layer_slots: Array[StringName] = [&"body", &"face", &"weapon"]
@export var shadow_width: int = 18  # largura da elipse de contacto

@export_group("v5.2")
## Papeis e comportamentos lidos pela FSM e pelo JobSystem (ex.: &"holds_line").
@export var tags: Array[StringName] = []
## Adequacao a cada posto (JobData.id -> 0..1). E o termo `adequacao` do §20.
@export var job_affinity: Dictionary = {}
## Moedas que transporta; largadas na morte (§07, regra 4).
@export var coin_capacity: int = 0
## Onde se treina e quantos dias demora (§09, §10). Vazio = recrutamento direto.
@export var trained_at: StringName = &""
@export var train_days: int = 0
## Habilidade unica (tropas de povo, classes) e os seus numeros.
@export var ability: StringName = &""
@export var ability_params: Dictionary = {}
## Familia de arma para o slot `weapon` e cabecas possiveis para o slot `head` (§58).
@export var weapon_kind: StringName = &""
@export var head_pool: Array[StringName] = []
