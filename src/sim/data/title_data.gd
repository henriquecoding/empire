# src/sim/data/title_data.gd — os nove feitos que dao nome a uma tropa (§76).
# Ninguem tem nome ate merecer um: o titulo ganha-se por feito registado, na
# alvorada, e nunca por escolha do jogador. Gerado de data/source/titles.csv.
class_name TitleData
extends Resource

@export var id: StringName
## O titulo — "O Que Ficou", "A Que Ficou na Porta" (§76).
@export var display_key: String
## O feito, para o registo de eventos e para a encomendacao (§81).
@export var feat_key: String

@export_group("Condicao")
## &"nights_in_siege_post", &"sole_gate_survivor", &"killed_ram",
## &"kills", &"corpses_dragged", &"survived_inside_stain", &"days_without_food",
## &"resurrected", &"same_weapon_days" — sinais que o §50 e o §52 ja emitem.
@export var condition_kind: StringName = &""
@export var condition_value: float = 0.0

@export_group("O que da")
## &"max_health", &"never_flees", &"damage_vs_siege", &"attack_rate",
## &"drag_speed", &"no_panic_in_lantern", &"food_use", &"charm_immune",
## &"weapon_level" — §76.
@export var grant_kind: StringName = &""
@export var grant_value: float = 0.0

@export_group("Apresentacao")
## Uma fita no slot overlay que ja existe (§58). Uma cor por tipo de feito.
@export var ribbon_color: String = ""
## O titulo e unico enquanto o dono estiver vivo; morto, fica de luto (§76).
@export var unique_while_alive: bool = true
