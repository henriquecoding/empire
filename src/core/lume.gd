# src/core/lume.gd — apagar o Lume (§74, §75, §79; Q-156, aprovada a 29/09/2026).
#
# "Apagar o Lume e o fim do ciclo de um imperio — uma expedicao a base dela, de
# dia, com o farol de pe e a Divida baixa (Uniao, §75); aceitar a decima segunda
# oferta e o outro fim (quem acende a lanterna passa a ser tu). Ate la, a base nao
# se ataca."
#
# O Lume arde nas duas bordas de onde a mancha nasce (ADR 0034). O gesto e o Verbo
# 2 ao pe dele: so de dia, so com um farol teu de pe, e so com a Divida da Candeia
# no limiar da Uniao (`union_debt_max`). Apagado, a Podridao nao volta a nascer e
# o epilogo e a Uniao; o jogo ouve o segment_entered com o tipo `lume` e acaba o
# ciclo como a travessia da ultima regiao acaba a campanha.
class_name Lume
extends RefCounted

const TIPO := &"lume"
const FAROL := &"lighthouse"


## Se o rei esta ao pe do Lume numa das bordas.
static func at_base(x: float) -> bool:
	var bordas := RealmFrame.edges()  # as bordas do reino (ADR 0070)
	return absf(x - bordas.x) <= Band.PASSAGE_PX or absf(x - bordas.y) <= Band.PASSAGE_PX


## Porque e que nao se apaga agora, ou &"" se se apaga (o guia di-lo).
static func refusal(unidades: UnitSystem, king_id: int) -> StringName:
	var i := unidades.index_of(king_id)
	if i == UnitSystem.NENHUM or not unidades.alive(i) or SimLoop.night == null:
		return &"LUME_NOT_HERE"
	if unidades.bands[i] != int(Band.Kind.SURFACE) or not at_base(unidades.xs[i]):
		return &"LUME_NOT_HERE"
	if ClockService.clock.current_phase() >= GameClock.Phase.DUSK:
		return &"LUME_NEEDS_DAY"
	if not _farol_de_pe():
		return &"LUME_NEEDS_LIGHTHOUSE"
	var divida := SimLoop.night.voice.debt
	if divida.ended or divida.debt > SimFactory.rot_profile().union_debt_max:
		return &"LUME_NEEDS_LOW_DEBT"
	return &""


## O Verbo 2 ao pe do Lume. Verdadeiro se o apagou.
static func extinguish(unidades: UnitSystem, king_id: int) -> bool:
	if not refusal(unidades, king_id).is_empty():
		return false
	var divida := SimLoop.night.voice.debt
	divida.lume_out = true
	divida.ended = true
	SimLoop.state.crossed = true
	EventBus.queue(&"segment_entered", [&"", TIPO])
	return true


static func _farol_de_pe() -> bool:
	for obra in SimLoop.builds.standing():
		if obra.kind == FAROL:
			return true
	return false
