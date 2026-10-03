# tests/caca_viva_regras_test.gd — a caca viva com as regras que ja havia (ADR 0057):
# a aljava paga (Q-200), os saves de antes e a morte pelo combate.
extends GdUnitTestSuite

var units: UnitSystem
var state: GameState


func before_test() -> void:
	units = UnitSystem.new()
	state = GameState.new()


func _caca(tocas: Array[float], bichos: PackedStringArray) -> HuntingSystem:
	var h := HuntingSystem.new(SimFactory.by_id(&"units"), Registry.entry(&"wildlife", &"rabbit"))
	h.wildlife = SimFactory.by_id(&"wildlife")
	var esperas: Array[float] = []
	esperas.resize(tocas.size())
	esperas.fill(0.0)
	h.burrows.place(tocas, esperas, PackedStringArray(), bichos)
	h.open_day(2)
	h.grow(0.0, true, 1.0)
	return h


## O imperador arqueiro que ninguem conduz gasta flechas da aljava dele ao cacar; sem
## flechas, nao caca (Q-200).
func test_o_arqueiro_imperial_sem_condutor_gasta_flechas() -> void:
	var h := _caca([100.0], PackedStringArray(["rabbit"]))
	var perfis := SimFactory.by_id(&"units")
	var arqueiro := units.spawn(state, Registry.entry(&"units", &"archer_emperor"), 1, 150.0)
	var i := units.index_of(arqueiro)
	var dados := perfis[&"archer_emperor"] as UnitData
	assert_array(RoyalHunt.idle(h, units, perfis, UnitSystem.NENHUM, true)).is_empty()
	var aljava := Supply.new()
	aljava.spent[arqueiro] = dados.ammo
	assert_array(RoyalHunt.idle(h, units, perfis, UnitSystem.NENHUM, true, aljava)).is_empty()
	aljava.spent[arqueiro] = 0
	assert_int(RoyalHunt.idle(h, units, perfis, UnitSystem.NENHUM, true, aljava).size()).is_equal(1)
	assert_int(int(aljava.spent[arqueiro])).is_equal(1)
	assert_float(units.cooldowns[i]).is_greater(0.0)


## Uma toca a mais entra viva, com o sitio, o bicho e a espera dela.
func test_uma_toca_acrescenta_se_viva() -> void:
	var tocas := Burrows.new()
	assert_bool(tocas.checked).is_false()
	tocas.add(40.0, 3.0, "tree", "boar")
	assert_int(tocas.living()).is_equal(1)
	assert_str(String(tocas.game_at(40.0))).is_equal("boar")
	assert_float(tocas.waits[0]).is_equal(3.0)
	tocas.place([1.0] as Array[float], [0.0] as Array[float])
	assert_bool(tocas.checked).is_true()


## Um save de antes da ADR 0057 so tinha coelhos e veados: ao carregar, as tocas que
## faltam entram nos sitios livres, e as que la estavam ficam como estavam. Desde a Q-218
## os sitios sao oito: quatro coelhos e o veado nos cinco primeiros.
func test_um_save_antigo_ganha_as_tocas_novas() -> void:
	SimLoop.autosave_enabled = false
	SimLoop.start(20261003)
	Greybox.build()
	var hunt := SimLoop.hunting
	var antigas: Array[float] = []
	var fontes := PackedStringArray()
	var bichos := PackedStringArray()
	var esperas: Array[float] = []
	for k in 5:
		antigas.append(SimLoop.core_x + float(HuntWatch.SITIOS[k][0]))
		fontes.append(String(HuntWatch.SITIOS[k][1]))
		bichos.append("rabbit" if k < 4 else "deer")
		esperas.append(0.0)
	hunt.burrows = Burrows.new()
	hunt.burrows.from_dict(
		{&"xs": antigas, &"alive": PackedByteArray([1, 1, 1, 1, 1]), &"kinds": fontes}
	)
	hunt.burrows.game = bichos
	HuntWatch.prepare(hunt, 2, SimLoop.core_x, SimLoop.world_width)
	assert_bool(hunt.burrows.checked).is_true()
	for id in ["pheasant", "fox", "boar"]:
		assert_bool(hunt.burrows.game.has(id)).override_failure_message(id).is_true()
	assert_int(Array(hunt.burrows.game).count("rabbit")).is_equal(4)
	assert_array(hunt.burrows.xs.slice(0, 5)).is_equal(antigas)
	SimLoop.stop()
	SimLoop.autosave_enabled = true


## A morte de quem o javali matou passa pelo combate: quem nao tem arma a largar morre
## com o anuncio, como qualquer outra (Q-168).
func test_quem_o_javali_mata_morre_pelo_combate() -> void:
	SimLoop.autosave_enabled = false
	SimLoop.start(20261003)
	Greybox.build()
	var hunt := SimLoop.hunting
	var x := SimLoop.core_x + 300.0
	hunt.rabbits.append(x)
	hunt.burrows.add(x, 99.0, "tree", "boar")
	hunt.herd.arrive(x)
	hunt.herd.provoked[x] = true
	var id := SimLoop.units.spawn(SimLoop.state, Registry.entry(&"units", &"cook"), 1, x + 4.0)
	var i := SimLoop.units.index_of(id)
	SimLoop.units.healths[i] = 1
	var mortes: Array[int] = []
	var ouvir := func(quem: int, _x: float, _faixa: int, _larga: PackedStringArray) -> void:
		mortes.append(quem)
	EventBus.unit_died.connect(ouvir)
	for k in 3:
		SimLoop.step(0.1)
	EventBus.unit_died.disconnect(ouvir)
	assert_bool(SimLoop.units.alive(i)).is_false()
	assert_array(mortes).contains([id])
	SimLoop.stop()
	SimLoop.autosave_enabled = true
