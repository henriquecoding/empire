# tests/lume_test.gd — o Lume roxo e as tuas luzes (ADR 0034).
#
# O dono (29/09/2026): a Podridao foge da luz, como a Besta perante a lanterna
# apagada; "dependendo do tipo de construcao e do nivel do inimigo recua, mas se
# for muito forte so abranda". O Lume fica na base de onde ela nasce, arde em
# roxo, e tudo o que ela consome o alimenta.
extends GdUnitTestSuite

const PASSO := 1.0 / 30.0


func _perfil() -> RotProfile:
	return SimFactory.rot_profile()


func _obra(tipo: StringName, x: float) -> BuildSlot:
	var dados := Registry.entry(&"buildings", tipo) as BuildingData
	var vaga := Greybox.slot_of(dados, x)
	vaga.level = 1
	vaga.state = BuildSlot.State.DONE
	vaga.health = vaga.max_health()
	return vaga


func _bicho(bichos: CreatureSystem, tipo: StringName, x: float, rumo: float) -> int:
	var dados := Registry.entry(&"creatures", tipo) as CreatureData
	return bichos.spawn(GameState.new(), dados, x, rumo)


# ─── Quem recua e quem so abranda ───────────────────────────────────────────


func test_a_fogueira_faz_recuar_o_rastejante_e_so_abranda_o_bruto() -> void:
	var obras := BuildSystem.new()
	obras.post(_obra(&"campfire", 500.0))
	var zonas := LightWard.of(obras)
	assert_int(zonas.size()).is_equal(1)
	assert_float(LightWard.at(500.0, 8, zonas).x).is_equal(1.0)
	var bruto := LightWard.at(500.0, 22, zonas)
	assert_float(bruto.x).is_equal(0.0)
	assert_float(bruto.y).is_equal(0.25)


func test_o_farol_aguenta_mais_do_que_a_fogueira() -> void:
	var obras := BuildSystem.new()
	obras.post(_obra(&"lighthouse", 2000.0))
	var zonas := LightWard.of(obras)
	assert_float(LightWard.at(2000.0, 22, zonas).x).is_equal(1.0)  # o bruto recua
	var ariete := LightWard.at(2000.0, 48, zonas)  # o Ariete de lodo so abranda
	assert_float(ariete.x).is_equal(0.0)
	assert_float(ariete.y).is_greater(0.0)


func test_fora_da_luz_nada_acontece() -> void:
	var obras := BuildSystem.new()
	obras.post(_obra(&"campfire", 500.0))
	assert_object(LightWard.at(5000.0, 8, LightWard.of(obras))).is_equal(Vector2.ZERO)


func test_o_archote_faz_recuar_os_rastejantes() -> void:
	var p := _perfil()
	var zona := Vector4(0.0, 2.0 * p.torch_radius_px, float(p.torch_repel_mass), 0.0)
	var zonas := LightWard.of(BuildSystem.new(), zona)
	assert_float(LightWard.at(p.torch_radius_px, 8, zonas).x).is_equal(1.0)
	assert_float(LightWard.at(p.torch_radius_px, 22, zonas).x).is_equal(0.0)


# ─── No movimento ───────────────────────────────────────────────────────────


func test_quem_entra_numa_luz_que_o_aguenta_recua() -> void:
	var bichos := CreatureSystem.new()
	var id := _bicho(bichos, &"crawler", 600.0, 0.0)
	var zonas: Array[Vector4] = [Vector4(400.0, 600.0, 8.0, 0.0)]
	bichos.set_lights(zonas, 1.0)
	bichos.tick_movement(PASSO)
	var i := bichos.index_of(id)
	assert_float(bichos.xs[i]).is_greater(600.0)  # anda para tras, para longe do nucleo
	assert_float(bichos.recoils[i]).is_greater(0.0)


func test_quem_e_forte_de_mais_so_abranda() -> void:
	var livre := CreatureSystem.new()
	var a := _bicho(livre, &"brute", 600.0, 0.0)
	livre.tick_movement(1.0)
	var andou := 600.0 - livre.xs[livre.index_of(a)]
	var bichos := CreatureSystem.new()
	var b := _bicho(bichos, &"brute", 600.0, 0.0)
	var zonas: Array[Vector4] = [Vector4(0.0, 1000.0, 8.0, 0.25)]
	bichos.set_lights(zonas, 1.0)
	bichos.tick_movement(1.0)
	assert_float(600.0 - bichos.xs[bichos.index_of(b)]).is_equal_approx(andou * 0.75, 0.001)


# ─── O Lume come o que ela consome ──────────────────────────────────────────


func test_o_que_ela_consome_alimenta_o_lume() -> void:
	var divida := DebtLedger.new(_perfil())
	divida.feed_lume(8.0)
	divida.feed_lume(-3.0)  # nao se tira combustivel ao Lume
	assert_float(divida.lume_fuel).is_equal(8.0)
	assert_float(divida.lume_mass()).is_equal_approx(8.0 * _perfil().lume_mass_per_fuel, 0.001)
	var outra := DebtLedger.new(_perfil())
	outra.from_dict(divida.to_dict())
	assert_float(outra.lume_fuel).is_equal(8.0)


func test_o_lume_arde_na_base_e_nao_em_cima_da_mancha() -> void:
	var rot := SimFactory.rot()
	rot.spawn(3, 1, 4000.0)
	var base := WorldLight.nest_x(rot)
	for _i in 60:
		rot.tick(PASSO * 10.0, [])
	assert_float(WorldLight.nest_x(rot)).is_equal(base)
	assert_float(rot.position_x()).is_less(base)


func test_o_lume_e_roxo_e_o_teu_fogo_e_ambar() -> void:
	var lume := WorldLight.stops(_perfil())[WorldLight.PARAGENS - 1]
	var fogo := WorldLight.fire_stops(_perfil())[WorldLight.PARAGENS - 1]
	assert_float(lume.b).is_greater(lume.g)  # violeta: mais azul do que verde
	assert_float(fogo.r).is_greater(fogo.b)  # ambar: mais vermelho do que azul


func test_o_archote_aceso_arde_mesmo_fora_do_escuro() -> void:
	# Senao o rei guardava os 60 s de um archote entre saidas, voltando a luz.
	var archote := Torchlight.new(_perfil())
	archote.buy(1)
	archote.tick(PASSO, true, true)
	assert_bool(archote.lit()).is_true()
	var antes := archote.burning
	archote.tick(1.0, true, false)
	assert_float(archote.burning).is_equal_approx(antes - 1.0, 0.001)
