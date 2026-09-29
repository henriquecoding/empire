# tests/escora_abre_test.gd — a escora fecha e abre (Q-132, Q-138, o dono a
# 29/09/2026): "se for o subsolo de uma construcao, o jogador pode fechar ou abrir;
# mas ha subsolos cuja entrada e sempre aberta".
extends GdUnitTestSuite

const X := 950.0


func _obras_com_escora() -> BuildSystem:
	var obras := BuildSystem.new()
	var dados := Registry.entry(&"buildings", Passages.ESCORA) as BuildingData
	var escora := obras.post(Greybox.slot_of(dados, X))
	escora.level = 1
	escora.state = BuildSlot.State.DONE
	escora.health = escora.max_health()
	return obras


func test_a_escora_de_pe_fecha_e_desmontada_abre() -> void:
	var obras := _obras_com_escora()
	var passagens := PackedFloat32Array([X])
	assert_int(Passages.open(passagens, obras).size()).is_equal(0)
	assert_bool(Passages.unseal(obras, X, int(Band.Kind.SURFACE))).is_true()
	assert_int(Passages.open(passagens, obras).size()).is_equal(1)
	assert_int(obras.slots[0].state).is_equal(BuildSlot.State.EMPTY)
	assert_int(obras.slots[0].next_cost()).is_greater(0)


func test_uma_boca_sem_escora_e_natural_e_esta_sempre_aberta() -> void:
	var obras := BuildSystem.new()
	var passagens := PackedFloat32Array([X])
	assert_bool(Passages.unseal(obras, X, int(Band.Kind.SURFACE))).is_false()
	assert_int(Passages.open(passagens, obras).size()).is_equal(1)


func test_longe_da_escora_nada_abre() -> void:
	var obras := _obras_com_escora()
	assert_bool(Passages.unseal(obras, X + 500.0, int(Band.Kind.SURFACE))).is_false()
