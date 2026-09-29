# src/core/spirit_watch.gd — o que deixa memoria no animo do reino (Q-102).
#
# Ouve o catalogo da §46 — a noite ganha, quem morre, quem deserta, o povo que
# passa a vassalo ou que se perde — e escreve no Spirit, que e puro. O peso e o
# prazo de cada memoria sao da curva (spirit_weights, spirit_days). A arvore com
# nome serrada chega pelo que a NightWatch colhe (§74); o soldo em atraso, pela
# alvorada. Corre na entrega do passo 11, e por isso e determinista.
class_name SpiritWatch
extends RefCounted


static func listen() -> void:
	EventBus.night_survived.connect(_noite)
	EventBus.unit_died.connect(_morreu)
	EventBus.unit_fled.connect(_fugiu)
	EventBus.trade_route_opened.connect(_ganhou)
	EventBus.trade_route_closed.connect(_perdeu)
	EventBus.king_died.connect(_rei)


## Uma memoria pela chave dela, com o peso e o prazo da curva, no animo do jogo
## em curso.
static func remember(chave: StringName, dia: int = -1) -> void:
	if SimLoop.field == null:
		return
	var curva := SimFactory.curve()
	var hoje := dia if dia >= 0 else (ClockService.clock.day if ClockService.clock else 1)
	var peso := float(curva.spirit_weights.get(chave, 0.0))
	SimLoop.field.spirit.note(chave, peso, hoje, int(curva.spirit_days.get(chave, 0)))


## O que a serra colheu: uma arvore com nome tira animo (§74, §76).
static func felled(eventos: Array[Dictionary]) -> void:
	for e in eventos:
		if int(e.get(AmargueiroSystem.MORAL, 0)) > 0:
			remember(&"named_tree_felled")


## A alvorada: o soldo por pagar pesa, e o que passou esquece-se.
static func dawn(spirit: Spirit, dia: int, em_atraso: int) -> void:
	spirit.dawn(dia)
	if em_atraso > 0:
		remember(&"wages_owed", dia)


static func _noite(dia: int, mortes: int, _muros: int) -> void:
	remember(&"night_survived", dia)
	if mortes == 0:
		remember(&"night_clean", dia)


static func _morreu(unit_id: int, _x: float, _band: int, _drops: PackedStringArray) -> void:
	var i := SimLoop.units.index_of(unit_id)
	if i == UnitSystem.NENHUM or SimLoop.units.owners[i] == RecruitSystem.SEM_DONO:
		return
	if unit_id == SimLoop.king_id:
		return  # o rei tem memoria propria, na sucessao
	var nomeada := SimLoop.night.names.by_unit().has(unit_id)
	remember(&"named_died" if nomeada else &"troop_died")


static func _fugiu(_unit_id: int, porque: StringName) -> void:
	if porque == &"upkeep":
		remember(&"deserted")


static func _ganhou(_povo: StringName, _tributo: int) -> void:
	remember(&"vassal_won")


static func _perdeu(_povo: StringName, _porque: StringName) -> void:
	remember(&"vassal_lost")


static func _rei(_reino: int, _herdeiro: int) -> void:
	remember(&"king_died")
