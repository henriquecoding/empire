# tests/gleaning_test.gd — quem pisa uma moeda apanha-a (Q-107, Q-111).
#
# "E como em Kingdom: se o jogador nao pega, o vagabundo pode pegar e tornar-se
# tropa, ou a tropa pode pegar e armazenar, ate uma quantidade limitada." O que a
# tropa apanha vai para o livro do rei e chega-lhe quando ele passa.
extends GdUnitTestSuite

const MEU := 1
const X := 400.0

var estado: GameState
var unidades: UnitSystem
var moedas: CoinSystem
var caca: HuntingSystem


func before_test() -> void:
	estado = GameState.new()
	unidades = UnitSystem.new()
	moedas = CoinSystem.new(Registry.entry(&"economy", &"curve") as EconomyCurve)
	caca = HuntingSystem.new(SimFactory.by_id(&"units"), Registry.entry(&"wildlife", &"rabbit"))


func _pousar(x: float, n: int, do_rei := false) -> void:
	for _k in n:
		var id := moedas.drop(estado, x, Band.Kind.SURFACE, 1, 0.0)
		var i := moedas.index_of(id)
		moedas.settled[i] = 1
		moedas.from_king[i] = 1 if do_rei else 0


func test_a_tua_tropa_apanha_o_que_caiu_ate_a_capacidade() -> void:
	var dados := Registry.entry(&"units", &"vagrant") as UnitData
	var quem := unidades.spawn(estado, dados, MEU, X)
	_pousar(X, dados.coin_capacity + 3)
	Gleaning.sweep(unidades, moedas, UnitSystem.NENHUM, caca.bagged)
	var i := unidades.index_of(quem)
	assert_int(unidades.carried_coins[i]).is_equal(dados.coin_capacity)
	assert_int(int(caca.bagged[quem])).is_equal(dados.coin_capacity)
	assert_int(moedas.count()).is_equal(3)


func test_nao_apanha_o_que_o_rei_largou_nem_o_que_esta_longe() -> void:
	var quem := unidades.spawn(estado, Registry.entry(&"units", &"vagrant"), MEU, X)
	_pousar(X, 2, true)
	_pousar(X + 500.0, 2)
	Gleaning.sweep(unidades, moedas, UnitSystem.NENHUM, caca.bagged)
	assert_int(unidades.carried_coins[unidades.index_of(quem)]).is_equal(0)
	assert_int(moedas.count()).is_equal(4)


func test_quem_nao_e_de_ninguem_nao_varre() -> void:
	var livre := unidades.spawn(estado, Registry.entry(&"units", &"vagrant"), 0, X)
	_pousar(X, 1)
	Gleaning.sweep(unidades, moedas, UnitSystem.NENHUM, caca.bagged)
	assert_int(unidades.carried_coins[unidades.index_of(livre)]).is_equal(0)


func test_o_que_a_tropa_guardou_chega_ao_rei_quando_ele_passa() -> void:
	var quem := unidades.spawn(estado, Registry.entry(&"units", &"vagrant"), MEU, X)
	var rei := unidades.spawn(estado, Registry.entry(&"units", &"monarch"), MEU, X + 2000.0)
	_pousar(X, 3)
	Gleaning.sweep(unidades, moedas, rei, caca.bagged)
	assert_int(caca.deliver(unidades, rei, 120.0)).is_equal(0)
	unidades.xs[unidades.index_of(rei)] = X + 50.0
	assert_int(caca.deliver(unidades, rei, 120.0)).is_equal(3)
	assert_int(unidades.carried_coins[unidades.index_of(quem)]).is_equal(0)


## Q-111: as tropas mais basicas guardam 5; as de combate um pouco mais.
func test_as_basicas_guardam_cinco_e_as_de_combate_mais() -> void:
	for id in [&"vagrant", &"builder", &"cook"]:
		assert_int((Registry.entry(&"units", id) as UnitData).coin_capacity).is_equal(5)
	for id in [&"spearman", &"archer"]:
		assert_int((Registry.entry(&"units", id) as UnitData).coin_capacity).is_greater(5)
