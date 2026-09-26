# tests/conversion_test.gd — o circuito 2 do §06, pelo algoritmo do §49: cada
# casa de conversao consome materia do produtor e da moeda agora OU capacidade
# depois. Nunca as duas.
#
# Os numeros sao os de crafts.csv e buildings.csv; nenhum esta aqui.
extends GdUnitTestSuite

const MEU := 1
const FASES := 6

var estado: GameState
var unidades: UnitSystem
var obras: BuildSystem
var conversao: ConversionSystem
var economia: EconomySystem
var canteiro: BuildSlot
var celeiro: BuildSlot


func before_test() -> void:
	estado = GameState.new()
	unidades = UnitSystem.new()
	obras = BuildSystem.new()
	conversao = SimFactory.conversion()
	economia = SimFactory.economy()
	economia.conversion = conversao
	canteiro = _de_pe(&"farm", 100.0)
	celeiro = _de_pe(&"granary", 900.0)


func _de_pe(kind: StringName, x: float) -> BuildSlot:
	var dados := Registry.entry(&"buildings", kind) as BuildingData
	var vaga := BuildSlot.new()
	vaga.kind = kind
	vaga.x = x
	vaga.width = float(dados.width_px)
	vaga.costs = PackedInt32Array([dados.cost])
	vaga.works = PackedFloat32Array([dados.build_work])
	vaga.healths = PackedInt32Array([dados.max_health])
	vaga.yield_per_day = dados.yield_per_day
	obras.post(vaga)
	vaga.level = 1
	vaga.state = BuildSlot.State.DONE
	vaga.health = vaga.max_health()
	return vaga


func _grao() -> CraftData:
	return Registry.entry(&"crafts", &"grain_granary") as CraftData


func _um_dia() -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	for f in FASES:
		eventos.append_array(economia.on_phase(obras, f, []))
	return eventos


func _moedas_em(eventos: Array[Dictionary], x: float) -> int:
	var n := 0
	for e in eventos:
		if (
			e[EconomySystem.CHAVE] == EconomySystem.EV_MOEDA
			and is_equal_approx(e[EconomySystem.ONDE], x)
		):
			n += e[EconomySystem.QUANTO]
	return n


func test_sem_celeiro_o_canteiro_larga_a_moeda_dele() -> void:
	obras.damage(celeiro.id, celeiro.health)
	var dia := _um_dia()
	assert_int(_moedas_em(dia, canteiro.x)).is_equal(int(canteiro.yield_per_day))


func test_com_celeiro_o_grao_vende_se_la_com_o_bonus() -> void:
	var dia := _um_dia()
	assert_int(_moedas_em(dia, canteiro.x)).is_equal(0)
	var esperado := int(floorf(canteiro.yield_per_day * _grao().coin_multiplier))
	assert_int(_moedas_em(dia, celeiro.x)).is_equal(esperado)


func test_uma_moeda_no_celeiro_com_cozinheiro_passa_a_capacidade() -> void:
	var moedas := CoinSystem.new(Registry.entry(&"economy", &"curve") as EconomyCurve)
	var id := moedas.drop(estado, celeiro.x, Band.Kind.SURFACE, 1, 0.0)
	moedas.settled[moedas.index_of(id)] = 1
	assert_bool(conversao.absorb(moedas, obras, unidades)).is_false()
	assert_int(moedas.count()).is_equal(1)
	unidades.spawn(estado, Registry.entry(&"units", &"cook"), MEU, 0.0)
	assert_bool(conversao.absorb(moedas, obras, unidades)).is_true()
	assert_int(moedas.count()).is_equal(0)
	assert_int(conversao.mode_of(celeiro)).is_equal(CraftData.Mode.CAPACITY)
	var dia := _um_dia_com(unidades)
	assert_int(_moedas_em(dia, celeiro.x)).is_equal(0)
	assert_float(conversao.capacity(_grao().capacity_kind)).is_equal(_grao().magnitude)


func test_sem_cozinheiro_vivo_a_capacidade_volta_a_moeda() -> void:
	conversao.modes[celeiro.id] = CraftData.Mode.CAPACITY
	var dia := _um_dia_com(unidades)
	assert_int(_moedas_em(dia, celeiro.x)).is_greater(0)
	assert_float(conversao.capacity(_grao().capacity_kind)).is_equal(0.0)


func test_a_capacidade_de_vida_sobe_e_desce_o_teto_das_tuas_tropas() -> void:
	var tropa := unidades.spawn(estado, Registry.entry(&"units", &"archer"), MEU, 0.0)
	var i := unidades.index_of(tropa)
	var base := unidades.max_healths[i]
	conversao.apply(unidades, {&"troop_health": 0.1})
	assert_int(unidades.max_healths[i]).is_equal(roundi(base * 1.1))
	assert_int(unidades.healths[i]).is_equal(roundi(base * 1.1))
	conversao.apply(unidades, {})
	assert_int(unidades.max_healths[i]).is_equal(base)
	assert_int(unidades.healths[i]).is_equal(base)


func test_o_modo_vai_no_save() -> void:
	conversao.modes[celeiro.id] = CraftData.Mode.CAPACITY
	var copia := SimFactory.conversion()
	copia.from_dict(conversao.to_dict())
	assert_int(copia.mode_of(celeiro)).is_equal(CraftData.Mode.CAPACITY)


func _um_dia_com(quem: UnitSystem) -> Array[Dictionary]:
	conversao.bind(quem)
	return _um_dia()
