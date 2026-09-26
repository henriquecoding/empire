# tests/repair_test.gd — reparar com a moeda fisica (§55, §25 "reparavel por 10
# moedas", Q-108). A obra tocada volta inteira; a ruina volta ao nivel que tinha.
#
# O custo e o trabalho sao os da escada da obra (walls.csv); nenhum esta aqui.
extends GdUnitTestSuite

const MEU := 1
const PASSO := 1.0 / 30.0
const X := 300.0

var estado: GameState
var unidades: UnitSystem
var obras: BuildSystem


func before_test() -> void:
	estado = GameState.new()
	unidades = UnitSystem.new()
	obras = BuildSystem.new()


func _muro_de_pe() -> BuildSlot:
	var vaga := obras.post(WallSite.slot(X))
	vaga.level = 1
	vaga.state = BuildSlot.State.DONE
	vaga.health = vaga.max_health()
	return vaga


func _pagar(quanto: int) -> Array[Dictionary]:
	var moedas := CoinSystem.new(Registry.entry(&"economy", &"curve") as EconomyCurve)
	for _k in quanto:
		var id := moedas.drop(estado, X, Band.Kind.SURFACE, 1, 0.0)
		moedas.settled[moedas.index_of(id)] = 1
	return obras.absorb(moedas)


func _trabalhar(segundos: float) -> void:
	for _t in int(segundos / PASSO) + 1:
		obras.tick(PASSO, unidades)


func test_uma_ruina_custa_o_degrau_que_tinha_e_volta_a_esse_nivel() -> void:
	var vaga := _muro_de_pe()
	obras.damage(vaga.id, vaga.health)
	assert_int(vaga.state).is_equal(BuildSlot.State.RUIN)
	assert_int(vaga.repair_cost()).is_equal(vaga.costs[0])
	_pagar(vaga.costs[0])
	assert_int(vaga.state).is_equal(BuildSlot.State.SCAFFOLD)
	assert_bool(vaga.mending).is_true()
	unidades.spawn(estado, Registry.entry(&"units", &"vagrant"), MEU, X)
	_trabalhar(vaga.works[0])
	assert_int(vaga.state).is_equal(BuildSlot.State.DONE)
	assert_int(vaga.level).is_equal(1)
	assert_int(vaga.health).is_equal(vaga.max_health())
	assert_bool(vaga.mending).is_false()


func test_uma_obra_tocada_paga_o_que_perdeu_e_fica_de_pe_enquanto_se_repara() -> void:
	var vaga := _muro_de_pe()
	var metade := vaga.max_health() / 2
	obras.damage(vaga.id, metade)
	var custo := vaga.repair_cost()
	assert_int(custo).is_equal(ceili(vaga.costs[0] * float(metade) / vaga.max_health()))
	assert_int(custo).is_greater(0)
	_pagar(custo)
	assert_int(vaga.state).is_equal(BuildSlot.State.DAMAGED)
	assert_bool(vaga.standing()).is_true()
	assert_bool(vaga.mending).is_true()
	unidades.spawn(estado, Registry.entry(&"units", &"vagrant"), MEU, X)
	_trabalhar(vaga.works[0])
	assert_int(vaga.state).is_equal(BuildSlot.State.DONE)
	assert_int(vaga.health).is_equal(vaga.max_health())
	assert_bool(vaga.mending).is_false()


func test_sem_moeda_ninguem_repara_e_sem_ninguem_a_moeda_nao_repara() -> void:
	var vaga := _muro_de_pe()
	obras.damage(vaga.id, 1)
	var vida := vaga.health
	unidades.spawn(estado, Registry.entry(&"units", &"vagrant"), MEU, X)
	_trabalhar(vaga.works[0])
	assert_int(vaga.health).is_equal(vida)
	unidades.remove(unidades.ids[0])
	_pagar(vaga.repair_cost())
	_trabalhar(vaga.works[0])
	assert_int(vaga.health).is_equal(vida)
	assert_bool(vaga.mending).is_true()


func test_cair_a_meio_da_reparacao_perde_o_pago_e_volta_a_pedir_o_degrau() -> void:
	var vaga := _muro_de_pe()
	obras.damage(vaga.id, 1)
	_pagar(vaga.repair_cost())
	obras.damage(vaga.id, vaga.health)
	assert_int(vaga.state).is_equal(BuildSlot.State.RUIN)
	assert_bool(vaga.mending).is_false()
	assert_int(vaga.repair_cost()).is_equal(vaga.costs[0])


func test_o_nucleo_nao_se_repara_com_moeda_e_a_reparacao_vai_no_save() -> void:
	var nucleo := obras.post(WallSite.slot(X))
	nucleo.costs = PackedInt32Array([0])
	nucleo.level = 1
	nucleo.state = BuildSlot.State.DAMAGED
	assert_int(nucleo.repair_cost()).is_equal(BuildSlot.NENHUM)
	var vaga := _muro_de_pe()
	obras.damage(vaga.id, 1)
	_pagar(vaga.repair_cost())
	var copia := BuildSlot.new()
	copia.from_dict(vaga.to_dict())
	assert_bool(copia.mending).is_true()


func test_o_quadro_publica_a_reparacao_paga_e_um_trabalhador_vai_la() -> void:
	var vaga := _muro_de_pe()
	obras.damage(vaga.id, 1)
	var jobs := SimFactory.job_board()
	var obreiro := unidades.spawn(estado, Registry.entry(&"units", &"vagrant"), MEU, X + 200.0)
	jobs.publish(obras)
	var antes := jobs.slots.size()
	_pagar(vaga.repair_cost())
	jobs.refresh(obras, unidades, GameClock.Phase.MORNING)
	assert_int(jobs.slots.size()).is_equal(antes + 1)
	var i := unidades.index_of(obreiro)
	assert_int(unidades.job_ids[i]).is_not_equal(JobBoard.NENHUM)
	assert_str(String(jobs.slot_of(unidades.job_ids[i]).job_id)).is_equal("repair")
	assert_float(unidades.target_xs[i]).is_equal(X)


func test_uma_escada_de_trabalho_curta_nao_parte_a_reparacao() -> void:
	var vaga := _muro_de_pe()
	vaga.level = vaga.costs.size()
	vaga.works = PackedFloat32Array([vaga.works[0]])
	vaga.health = vaga.max_health()
	obras.damage(vaga.id, 1)
	_pagar(vaga.repair_cost())
	unidades.spawn(estado, Registry.entry(&"units", &"vagrant"), MEU, X)
	_trabalhar(vaga.works[0])
	assert_int(vaga.state).is_equal(BuildSlot.State.DONE)
