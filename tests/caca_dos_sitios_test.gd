# tests/caca_dos_sitios_test.gd — a caca sai de onde faz sentido (Q-150).
#
# O dono (30/09/2026): "as cacas devem aparecer de onde faca sentido, de arbustos, de
# arvores, de lagos, de rochas, de buracos". Cada toca e um sitio e o bicho dele.
extends GdUnitTestSuite

var units: UnitSystem
var state: GameState


func before_test() -> void:
	units = UnitSystem.new()
	state = GameState.new()


## Q-150: cada toca da o bicho do sitio dela — o coelho do arbusto, do buraco e da
## rocha, o veado da arvore e do lago — e o veado leva dois tiros e vale tres.
func test_cada_sitio_da_o_bicho_que_la_faz_sentido() -> void:
	var h := HuntingSystem.new(SimFactory.by_id(&"units"), Registry.entry(&"wildlife", &"rabbit"))
	h.wildlife = SimFactory.by_id(&"wildlife")
	var tocas: Array[float] = [10.0, 400.0]
	var esperas: Array[float] = [0.0, 0.0]
	h.burrows.place(
		tocas, esperas, PackedStringArray(["bush", "tree"]), PackedStringArray(["rabbit", "deer"])
	)
	h.open_day(2)
	h.grow(0.0, true, 1.0)
	assert_str(String(h.burrows.game_at(400.0))).is_equal("deer")
	var id := units.spawn(state, Registry.entry(&"units", &"archer"), 1, 390.0)
	var i := units.index_of(id)
	assert_array(h.resolve(units, true, false)).is_empty()  # o primeiro tiro so fere
	assert_bool(h.rabbits.has(400.0)).is_true()
	units.cooldowns[i] = 0.0
	var caca := h.resolve(units, true, false)
	assert_int(caca.size()).is_equal(1)
	assert_int(caca[0][&"amount"]).is_equal(
		(Registry.entry(&"wildlife", &"deer") as WildlifeData).coin_yield
	)
	assert_bool(h.rabbits.has(400.0)).is_false()


## Os sitios da regiao de casa: o primeiro e o coelho do 1:10, e cada toca fica num
## sitio de que o bicho dela sai (wildlife.csv, `sources`).
func test_as_tocas_da_regiao_sao_dos_sitios_de_cada_bicho() -> void:
	SimLoop.autosave_enabled = false
	SimLoop.start(20260930)
	Greybox.build()
	HuntWatch.place(SimLoop.hunting, SimLoop.core_x, SimLoop.world_width)
	var tocas := SimLoop.hunting.burrows
	assert_str(String(tocas.game[0])).is_equal("rabbit")
	for k in tocas.xs.size():
		var bicho := Registry.entry(&"wildlife", StringName(tocas.game[k])) as WildlifeData
		assert_bool(bicho.sources.has(StringName(tocas.kinds[k]))).is_true()
	assert_bool(tocas.game.has("deer")).is_true()
	SimLoop.stop()
	SimLoop.autosave_enabled = true


## Um save de antes da Q-150 nao traz o sitio nem o bicho: arbustos com coelhos.
func test_um_save_de_antes_tem_arbustos_com_coelhos() -> void:
	var tocas := Burrows.new()
	tocas.from_dict({&"xs": [1.0, 2.0], &"alive": PackedByteArray([1, 1])})
	assert_array(Array(tocas.kinds)).is_equal(["bush", "bush"])
	assert_array(Array(tocas.game)).is_equal(["rabbit", "rabbit"])
