# src/core/camps.gd — o vagabundo novo de cada alvorada (Q-122).
#
# "Os vagabundos nao sao meus trabalhadores; como no Kingdom, devo procura-los
# pelo mundo em acampamentos" (Q-110). Um por alvorada, num acampamento fora das
# muralhas de fora, alternando o lado, ate ao teto de vivos por recrutar. Tirado do
# FieldWork, que chegou as 250 linhas do §28.
class_name Camps
extends RefCounted


static func dawn(
	camps: PackedFloat32Array, dia: int, unidades: UnitSystem, estado: GameState
) -> void:
	if camps.is_empty():
		return
	var curva := SimFactory.curve()
	var vagabundo := Registry.entry(&"units", &"vagrant") as UnitData
	var livres := 0
	for i in unidades.count():
		if unidades.owners[i] == RecruitSystem.SEM_DONO and unidades.alive(i):
			livres += 1 if unidades.data_ids[i] == vagabundo.id else 0
	for k in mini(curva.vagrants_per_dawn, maxi(0, curva.vagrant_camp_cap - livres)):
		var x := camps[(dia + k) % camps.size()]
		var novo := unidades.spawn(estado, vagabundo, RecruitSystem.SEM_DONO, x)
		EventBus.queue(&"unit_spawned", [novo, vagabundo.id, x, int(Band.Kind.SURFACE)])
