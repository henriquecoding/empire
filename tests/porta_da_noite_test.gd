# tests/porta_da_noite_test.gd — a noite nasce a porta, e nao dentro das muralhas (ADR 0071).
#
# A mancha atravessa o campo (§51) e invoca onde esta. Com a mistura da estreia ha mais
# invocacoes baratas numa noite funda, e a sonda viu-a ainda com massa quando passava por
# cima da Bastiao: os Rastejantes nasciam a volta do nucleo, dentro dos muros, e o castelo
# da defesa do decimo dia caia (dez_dias_test). A noite vem de fora do reino (ADR 0070):
# quem ela invoca depois de passar a muralha mais exterior do lado dela nasce a porta
# dessa muralha, do lado de fora. A massa gasta-se igual; so o sitio muda.
extends GdUnitTestSuite

const NUCLEO := 1920.0
const BORDA_LESTE := 3840.0
const BORDA_OESTE := 0.0
const LESTE := 1
const OESTE := -1


func _muro(x: float) -> BuildSlot:
	var vaga := WallSite.slot(x)
	vaga.level = 1
	vaga.state = BuildSlot.State.DONE
	vaga.health = vaga.max_health()
	return vaga


func _obras(muros: Array[float]) -> BuildSystem:
	var obras := BuildSystem.new()
	for x in muros:
		obras.post(_muro(x))
	return obras


func test_sem_muralha_nasce_onde_a_mancha_esta() -> void:
	var obras := _obras([])
	var x := RotPick.door(2000.0, LESTE, BORDA_LESTE, NUCLEO, obras, Band.Kind.SURFACE)
	assert_float(x).is_equal(2000.0)


func test_antes_da_muralha_nasce_onde_a_mancha_esta() -> void:
	var obras := _obras([2520.0])
	var x := RotPick.door(3000.0, LESTE, BORDA_LESTE, NUCLEO, obras, Band.Kind.SURFACE)
	assert_float(x).is_equal(3000.0)


func test_depois_de_passar_a_muralha_nasce_a_porta_do_lado_de_fora() -> void:
	var obras := _obras([2520.0, 2200.0])
	var muro := obras.barrier(BORDA_LESTE, NUCLEO, Band.Kind.SURFACE)
	var face := muro.x + muro.width * 0.5
	var x := RotPick.door(1950.0, LESTE, BORDA_LESTE, NUCLEO, obras, Band.Kind.SURFACE)
	assert_float(muro.x).is_equal(2520.0)  # a mais exterior, e nao a de dentro
	assert_float(x).is_equal(face)


func test_do_outro_lado_e_o_espelho() -> void:
	var obras := _obras([1320.0])
	var muro := obras.barrier(BORDA_OESTE, NUCLEO, Band.Kind.SURFACE)
	var x := RotPick.door(1800.0, OESTE, BORDA_OESTE, NUCLEO, obras, Band.Kind.SURFACE)
	assert_float(x).is_equal(muro.x - muro.width * 0.5)
	x = RotPick.door(900.0, OESTE, BORDA_OESTE, NUCLEO, obras, Band.Kind.SURFACE)
	assert_float(x).is_equal(900.0)


func test_uma_muralha_caida_ja_nao_e_porta() -> void:
	var obras := _obras([2520.0])
	obras.slots[0].health = 0
	obras.slots[0].state = BuildSlot.State.RUIN
	var x := RotPick.door(2000.0, LESTE, BORDA_LESTE, NUCLEO, obras, Band.Kind.SURFACE)
	assert_float(x).is_equal(2000.0)


func test_o_subsolo_nao_tem_muralhas_da_superficie() -> void:
	var obras := _obras([2520.0])
	var x := RotPick.door(2000.0, LESTE, BORDA_LESTE, NUCLEO, obras, Band.Kind.UNDERGROUND)
	assert_float(x).is_equal(2000.0)
