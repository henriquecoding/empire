# tests/montaria_test.gd — o cavalo de tracao e os alforges (§12; Q-169, o dono a
# 30/09/2026).
#
# "O personagem que o jogador controla corre a 1,8x, o cavalo deve correr a 2,1x. O
# jogador pode armazenar ate 20 moedas na montaria ou outros itens." O cavalo compra-se
# no estabulo; quem o jogador conduz monta-o ao passar la; os alforges alargam o saco e
# o armazenamento de quem monta, e guardam o que passou do saco quando ele desmonta.
extends GdUnitTestSuite

const MEU := 1
const A_PE := 1.8

var _estado := GameState.new()
var _u := UnitSystem.new()
var _obras := BuildSystem.new()


func before_test() -> void:
	_estado = GameState.new()
	_u = UnitSystem.new()
	_obras = BuildSystem.new()


func _cavalo() -> MountData:
	return Registry.entry(&"mounts", &"draft_horse") as MountData


func _montaria() -> Mount:
	var alforges := Registry.entry(&"classes/storages", &"saddlebags") as StorageData
	return Mount.new(_cavalo(), alforges)


func _estabulo(x: float, de_pe: bool) -> BuildSlot:
	var dados := Registry.entry(&"buildings", Stables.ESTABULO) as BuildingData
	var vaga := _obras.post(Greybox.slot_of(dados, x))
	if de_pe:
		vaga.level = 1
		vaga.state = BuildSlot.State.DONE
		vaga.health = vaga.max_health()
	return vaga


func _rei(x: float) -> int:
	return _u.spawn(_estado, Registry.entry(&"units", &"monarch") as UnitData, MEU, x)


## A pe corre-se ao king_run_mult; montado, anda-se a 1,7 e corre-se a 2,1.
func test_a_pe_e_montado_o_passo_e_o_do_dono() -> void:
	var m := _montaria()
	var rei := _rei(0.0)
	assert_float(m.pace(rei, false, A_PE)).is_equal(1.0)
	assert_float(m.pace(rei, true, A_PE)).is_equal(A_PE)
	m.owned = _cavalo().id
	m.mount(_u, rei)
	assert_float(m.pace(rei, false, A_PE)).is_equal(_cavalo().speed_multiplier)
	assert_float(m.pace(rei, true, A_PE)).is_equal(_cavalo().run_multiplier)
	assert_float(_cavalo().run_multiplier).is_equal(2.1)
	assert_float(m.pace(rei + 1, true, A_PE)).is_equal(A_PE)  # quem nao monta, corre a pe


## So um estabulo de pe vende o cavalo, e as moedas largadas nele pagam-no.
func test_o_estabulo_de_pe_vende_o_cavalo() -> void:
	var m := _montaria()
	var por_fazer := _estabulo(0.0, false)
	assert_int(m.owed(por_fazer)).is_equal(0)
	var vaga := _estabulo(1000.0, true)
	assert_int(m.owed(vaga)).is_equal(_cavalo().cost)
	var moedas := CoinSystem.new(Registry.entry(&"economy", &"curve") as EconomyCurve)
	for k in _cavalo().cost - 1:
		moedas.drop(_estado, vaga.x, Band.Kind.SURFACE, 1, 0.0)
	for c in moedas.count():
		moedas.settled[c] = 1
	assert_int(m.absorb(moedas, _obras)).is_equal(_cavalo().cost - 1)
	assert_str(String(m.owned)).is_empty()
	assert_int(m.owed(vaga)).is_equal(1)
	var ultima := moedas.drop(_estado, vaga.x, Band.Kind.SURFACE, 1, 0.0)
	moedas.settled[moedas.index_of(ultima)] = 1
	assert_int(m.absorb(moedas, _obras)).is_equal(1)
	assert_str(String(m.owned)).is_equal(String(_cavalo().id))
	assert_int(m.owed(vaga)).is_equal(0)


## Quem se conduz monta ao passar no estabulo: o saco cresce os alforges, e o que
## passou do saco fica neles quando desmonta — e volta quando monta outra vez.
func test_os_alforges_guardam_o_que_passa_do_saco() -> void:
	var m := _montaria()
	var vaga := _estabulo(500.0, true)
	var rei := _rei(0.0)
	var r := _u.index_of(rei)
	var saco := _u.coin_capacities[r]
	m.owned = _cavalo().id
	assert_bool(m.tick(_u, rei, _obras)).is_false()  # longe do estabulo
	_u.xs[r] = vaga.x
	assert_bool(m.tick(_u, rei, _obras)).is_true()
	assert_int(m.rider).is_equal(rei)
	assert_int(_u.coin_capacities[r]).is_equal(saco + _cavalo().saddlebag_coins)
	assert_int(_cavalo().saddlebag_coins).is_equal(20)
	_u.carried_coins[r] = saco + 7
	m.dismount(_u)
	assert_int(m.coins).is_equal(7)
	assert_int(_u.carried_coins[r]).is_equal(saco)
	assert_int(_u.coin_capacities[r]).is_equal(saco)
	m.mount(_u, rei)
	assert_int(_u.carried_coins[r]).is_equal(saco + 7)
	assert_int(m.coins).is_equal(0)


## Os alforges levam itens: os archotes de quem monta passam a caber la tambem.
func test_os_alforges_levam_os_archotes() -> void:
	var m := _montaria()
	var cinto := Storage.new(Registry.entry(&"classes/storages", &"royal_belt") as StorageData)
	var teto := cinto.cap(Storage.ARCHOTE)
	m.link(cinto)
	assert_int(cinto.cap(Storage.ARCHOTE)).is_equal(teto + m.bags.cap(Storage.ARCHOTE))
	assert_int(cinto.put(Storage.ARCHOTE, teto + 1)).is_equal(teto + 1)
	assert_int(m.bags.count(Storage.ARCHOTE)).is_equal(1)
	assert_int(cinto.take(Storage.ARCHOTE, teto + 1)).is_equal(teto + 1)
	m.link(null)
	assert_int(cinto.cap(Storage.ARCHOTE)).is_equal(teto)


## O cavalo e da superficie: quem desce desmonta; quem cai deixa-o voltar ao estabulo.
func test_quem_desce_ou_cai_desmonta() -> void:
	var m := _montaria()
	var rei := _rei(0.0)
	var r := _u.index_of(rei)
	var saco := _u.coin_capacities[r]
	m.owned = _cavalo().id
	m.mount(_u, rei)
	_u.bands[r] = int(Band.Kind.UNDERGROUND)
	assert_bool(m.tick(_u, rei, _obras)).is_true()
	assert_int(m.rider).is_equal(Mount.NENHUM)
	_u.bands[r] = int(Band.Kind.SURFACE)
	m.mount(_u, rei)
	_u.healths[r] = 0
	_u.states[r] = UnitFsm.State.DEAD
	assert_bool(m.tick(_u, rei, _obras)).is_true()
	assert_int(m.rider).is_equal(Mount.NENHUM)
	assert_int(_u.coin_capacities[r]).is_equal(saco)


func test_o_save_guarda_o_cavalo() -> void:
	var m := _montaria()
	m.owned = _cavalo().id
	m.coins = 9
	m.bags.put(Storage.ARCHOTE, 2)
	var outra := _montaria()
	outra.from_dict(m.to_dict())
	assert_str(String(outra.owned)).is_equal(String(_cavalo().id))
	assert_int(outra.coins).is_equal(9)
	assert_int(outra.bags.count(Storage.ARCHOTE)).is_equal(2)


## Na regiao: o estabulo existe, a superficie, e nasce por ultimo (§45).
func test_o_estabulo_esta_na_regiao() -> void:
	SimLoop.autosave_enabled = false
	SimLoop.start(20260930)
	Greybox.build()
	var ultima: BuildSlot = SimLoop.builds.slots[-1]
	assert_str(String(ultima.kind)).is_equal(String(Stables.ESTABULO))
	assert_int(int(ultima.band)).is_equal(int(Band.Kind.SURFACE))
	assert_float(ultima.x - SimLoop.core_x).is_equal(Stables.ESTABULOS_X[0])
	SimLoop.stop()
	SimLoop.autosave_enabled = true


## No jogo, so com gestos: o rei larga as moedas no estabulo de pe, compra o cavalo e
## monta-o ali mesmo; o saco dele cresce os alforges.
func test_no_jogo_o_rei_compra_e_monta_o_cavalo() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20260930)
	Greybox.build()
	var casa: BuildSlot = SimLoop.builds.slots[-1]
	casa.level = 1
	casa.state = BuildSlot.State.DONE
	casa.health = casa.max_health()
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	var saco := SimLoop.units.coin_capacities[rei]
	SimLoop.units.carried_coins[rei] = _cavalo().cost
	SimLoop.units.xs[rei] = casa.x
	for _t in 2400:
		if SimLoop.field.mount.rider != Mount.NENHUM:
			break
		SimLoop.units.set_target_x(SimLoop.king_id, casa.x)
		if SimLoop.units.carried_coins[rei] > 0:
			var moeda := {
				&"x": SimLoop.units.xs[rei],
				&"band": Band.Kind.SURFACE,
				&"amount": InputRouter.UMA,
				&"source": Verbs.JOGADOR
			}
			SimLoop.intents.queue(IntentQueue.Kind.DROP_COIN, moeda)
		SimLoop.step(1.0 / 30.0)
	assert_str(String(SimLoop.field.mount.owned)).is_equal(String(_cavalo().id))
	assert_int(SimLoop.field.mount.rider).is_equal(SimLoop.king_id)
	rei = SimLoop.units.index_of(SimLoop.king_id)
	assert_int(SimLoop.units.coin_capacities[rei]).is_equal(saco + _cavalo().saddlebag_coins)
	SimLoop.stop()
	SimLoop.autosave_enabled = true
