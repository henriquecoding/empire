# src/sim/data/offer_data.gd — as doze ofertas da Podridao (§75).
# Uma por noite, aceite com o Verbo 1 dentro do prato de oferenda. Recusar e nao
# fazer nada. Gerado a partir de data/source/offers.csv.
class_name OfferData
extends Resource

@export var id: StringName
## A frase, por chave: nunca mais de oito palavras (§75).
@export var display_key: String

@export_group("Preco")
## &"troops_below_health", &"coins", &"treasury_all", &"troop_per_gate",
## &"gates_open", &"marker", &"named_troop", &"sealed_passage", &"architecture",
## &"playable_class", &"successor", &"everything_named" — §75.
## &"playable_class": uma classe da §08 perdida para sempre. Ver Q-053.
@export var price_kind: StringName = &""
@export var price_amount: float = 0.0

@export_group("Efeito")
## &"rot_pause", &"reveal_chapter", &"gates_unbreakable", &"mass_mult",
## &"skip_night", &"seed_royal", &"rot_detours", &"mass_mult_permanent",
## &"control_rot_tonight", &"greed_zero_days", &"rot_ends" — §75.
@export var effect_kind: StringName = &""
@export var effect_value: float = 0.0
@export var effect_days: int = 0

@export_group("Elegibilidade")
## A gramatica da §75: <chave><op><numero> ou <chave>=<id>, virgulas em AND.
## Sem parenteses, sem "ou", sem negacao. Vazio = sem condicao.
@export var requires: String = ""
@export var min_day: int = 0
## A Q-040 propoe uma vez por campanha para a oferta que salta a noite.
@export var once_per_campaign: bool = false

@export_group("Divida")
## Quanto sobe a Divida da Candeia ao aceitar. Nunca desce (§75, D-06).
@export var debt_delta: int = 0
## A decima segunda oferta fecha o ciclo em vez de subir a divida (§75, §79).
@export var ends_rot: bool = false
