# src/sim/data/rules_curve.gd — as regras das respostas do painel de 30/09/2026 (ADR
# 0041). Gerado de data/source/rules.csv, chave/valor como o economy.csv: a EconomyCurve
# chegou as 250 linhas do §28, e isto e o que entrou depois dela.
class_name RulesCurve
extends Resource

@export_group("Coroa no chao — Q-167")
## Quao perto uma criatura tem de chegar da coroa para a levar, a vida com que o rei se
## levanta, e quanto a coroa alimenta o Lume se a mancha a cobre.
@export var crown_grab_px: float = 0.0
@export var crown_rise_health: float = 0.0
@export var crown_lume_feed: int = 0

@export_group("Alicerces — Q-171")
## A fracao do investido que custa reerguer uma obra que o decay nao guardou.
@export var decay_rebuild_frac: float = 0.0

@export_group("Acampamentos e casas de cidadaos — Q-170, Q-177")
## A que distancia de um acampamento um Amargueiro abatido o acaba; quantos cidadaos
## espera uma casa de cidadaos, e quanto custa cada um; quantos mercenarios da um
## acampamento das trilhas antes de ficar vazio.
@export var camp_tree_px: float = 0.0
@export var citizen_cap: int = 0
@export var citizen_price: int = 0
@export var mercenary_camp_hires: int = 0

@export_group("Abastecimento do exercito — Q-163")
## Quantas flechas se repoem por moeda na alvorada, e a obra que as faz.
@export var arrows_per_coin: int = 0
@export var ammo_depot: StringName = &""
