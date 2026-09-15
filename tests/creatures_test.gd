# tests/creatures_test.gd — a tabela de invocacao e as faixas (F1-09, §07, §51).
#
# O "Porque" do ticket e uma frase: "a noite 4 tem de obrigar a torre alta. E a
# primeira vez que o jogador muda de plano por causa dela." Isso e duas coisas,
# e as duas se provam aqui: que a noite 4 traz mesmo o Alado, e que sem uma
# torre alta ninguem lhe chega.
#
# A terceira e a factura da passagem: o §25 poe a descoberta do subsolo ao
# minuto 10:00 e a conta ao 12:00 — "um Rastejante entra pela passagem que
# abriste. Toda a decisao tem custo."
extends GdUnitTestSuite

const MEU_IMPERIO := 7
const NUCLEO := 0.0
const PASSO := 1.0 / 30.0
const DIREITA := 1
const LARGURA := 4000.0


func _curva() -> EconomyCurve:
	return Registry.entry(&"economy", &"curve") as EconomyCurve


func _perfil() -> RotProfile:
	return Registry.entry(&"rot", &"default") as RotProfile


func _tabela(tabela: StringName) -> Dictionary:
	var mapa := {}
	for r in Registry.entries(tabela):
		mapa[r.get(&"id")] = r
	return mapa


func _mancha() -> RotSystem:
	var lista: Array[CreatureData] = []
	for r in Registry.entries(&"creatures"):
		lista.append(r as CreatureData)
	return RotSystem.new(_perfil(), lista)


func _escolha() -> TargetPicker:
	var postos := JobBoard.new(_curva(), _tabela(&"jobs"), _tabela(&"units"))
	return TargetPicker.new(
		_tabela(&"units"), _tabela(&"creatures"), ContactQueue.new(_curva()), postos
	)


func _bicho(criaturas: CreatureSystem, estado: GameState, id: StringName, x: float) -> int:
	return criaturas.spawn(estado, Registry.entry(&"creatures", id), x, NUCLEO)


# ─── A tabela de invocacao (§51) ─────────────────────────────────────────────


func test_cada_criatura_so_entra_a_partir_do_dia_dela() -> void:
	var rot := _mancha()
	for id in ["crawler", "winged", "brute", "burrower", "slime_ram", "devourer"]:
		var dados := Registry.entry(&"creatures", StringName(id)) as CreatureData
		rot.spawn(dados.min_day - 1, DIREITA, LARGURA)
		var vespera := String(rot.pick())
		rot.spawn(dados.min_day, DIREITA, LARGURA)
		var porque := "%s aparece na vespera do dia %d dela" % [id, dados.min_day]
		assert_str(vespera).override_failure_message(porque).is_not_equal(id)


func test_a_noite_4_traz_o_alado() -> void:
	# O "Porque" do ticket. A massa do dia 4 e 40 + 18x4 = 112 (§74); o Alado
	# custa 14 e o Bruto so entra no dia 7 — a mais cara que cabe e ele.
	var alado := Registry.entry(&"creatures", &"winged") as CreatureData
	var rot := _mancha()

	rot.spawn(alado.min_day, DIREITA, LARGURA)

	assert_str(String(rot.pick())).is_equal("winged")
	assert_int(alado.min_day).is_equal(4)


func test_o_alado_nasce_no_ar_e_o_cavador_debaixo_do_chao() -> void:
	# A faixa vem do CreatureData e nao de onde a mancha esta: ela anda no chao e
	# invoca coisas que voam (§11, §51).
	var estado := GameState.new()
	var criaturas := CreatureSystem.new()
	var alado := _bicho(criaturas, estado, &"winged", 500.0)
	var cavador := _bicho(criaturas, estado, &"burrower", 500.0)

	assert_int(criaturas.bands[criaturas.index_of(alado)]).is_equal(int(Band.Kind.AERIAL))
	assert_int(criaturas.bands[criaturas.index_of(cavador)]).is_equal(int(Band.Kind.UNDERGROUND))


# ─── A noite 4 obriga a torre alta ───────────────────────────────────────────


func test_do_chao_ninguem_chega_ao_alado() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var criaturas := CreatureSystem.new()
	var arqueiro := unidades.spawn(estado, Registry.entry(&"units", &"archer"), MEU_IMPERIO, 500.0)
	_bicho(criaturas, estado, &"winged", 520.0)
	var escolha := _escolha()

	escolha.choose(unidades, criaturas, null)

	assert_int(escolha.target_of(arqueiro)).is_equal(TargetPicker.NENHUM)


func test_o_alado_chega_a_quem_esta_no_chao() -> void:
	# Ele atinge a superficie (targets_bands) e nao e atingido de volta: e essa
	# assimetria que obriga a mudar de plano, e nao o dano dele.
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var criaturas := CreatureSystem.new()
	var arqueiro := unidades.spawn(estado, Registry.entry(&"units", &"archer"), MEU_IMPERIO, 500.0)
	var alado := _bicho(criaturas, estado, &"winged", 510.0)
	var escolha := _escolha()

	escolha.choose(unidades, criaturas, null)

	assert_int(criaturas.target_ids[criaturas.index_of(alado)]).is_equal(arqueiro)


func test_um_muro_nao_trava_quem_voa() -> void:
	# A muralha e da superficie. Um Alado passa-lhe por cima, e e por isso que a
	# resposta a ele e uma torre e nao mais um nivel de muro (§10).
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var criaturas := CreatureSystem.new()
	var obras := BuildSystem.new()
	var muro := BuildSlot.new()
	muro.x = 400.0
	muro.blocks = true
	muro.width = 64.0
	muro.kind = &"stakes"
	muro.healths = PackedInt32Array([40])
	muro.contacts = PackedInt32Array([2])
	obras.post(muro)
	muro.level = 1
	muro.state = BuildSlot.State.DONE
	muro.health = muro.max_health()
	var alado := _bicho(criaturas, estado, &"winged", 500.0)
	var escolha := _escolha()

	escolha.choose(unidades, criaturas, obras)

	assert_int(criaturas.target_slots[criaturas.index_of(alado)]).is_equal(CreatureSystem.NENHUM)


# ─── A factura da passagem (§25, minuto 12:00) ───────────────────────────────


func test_o_cavador_sobe_pela_passagem_que_abriste() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var criaturas := CreatureSystem.new()
	var passagem := 500.0
	var cavador := _bicho(criaturas, estado, &"burrower", passagem)
	var c := criaturas.index_of(cavador)
	var escolha := _escolha()

	var eventos := escolha.choose(unidades, criaturas, null, PackedFloat32Array([passagem]))

	assert_int(criaturas.bands[c]).is_equal(int(Band.Kind.SURFACE))
	assert_array(eventos).is_not_empty()


func test_sem_passagem_ele_fica_em_baixo() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var criaturas := CreatureSystem.new()
	var cavador := _bicho(criaturas, estado, &"burrower", 500.0)
	var c := criaturas.index_of(cavador)

	_escolha().choose(unidades, criaturas, null, PackedFloat32Array([2000.0]))

	assert_int(criaturas.bands[c]).is_equal(int(Band.Kind.UNDERGROUND))


func test_quem_nao_muda_de_faixa_nao_sobe() -> void:
	# O Rastejante nasce na superficie e o can_change_band dele e falso: se um
	# dia alguem o puser em baixo, ele nao sai de la por uma passagem.
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var criaturas := CreatureSystem.new()
	var passagem := 500.0
	var bicho := _bicho(criaturas, estado, &"crawler", passagem)
	var c := criaturas.index_of(bicho)
	criaturas.bands[c] = int(Band.Kind.UNDERGROUND)

	_escolha().choose(unidades, criaturas, null, PackedFloat32Array([passagem]))

	assert_int(criaturas.bands[c]).is_equal(int(Band.Kind.UNDERGROUND))
	(
		assert_bool((Registry.entry(&"creatures", &"crawler") as CreatureData).can_change_band)
		. is_false()
	)


# ─── Quem alcanca que faixa, do lado das criaturas (§07, §11) ────────────────


func test_o_cavador_no_subsolo_nao_chega_a_quem_esta_no_chao() -> void:
	# O espelho do Posts.reaches() do F1-07, que faltava deste lado. O §07 diz
	# que o Cavador "PASSA pela faixa subterranea" — passa, nao ataca de la. Sem
	# esta regra ele batia em quem estivesse em cima sem nunca subir, e a
	# passagem do §25 nao custava nada a ninguem.
	var cavador := Registry.entry(&"creatures", &"burrower") as CreatureData

	assert_bool(cavador.can_change_band).is_true()
	(
		assert_bool(Passages.reaches(cavador, int(Band.Kind.UNDERGROUND), int(Band.Kind.SURFACE)))
		. is_false()
	)


func test_depois_de_subir_chega() -> void:
	var cavador := Registry.entry(&"creatures", &"burrower") as CreatureData

	assert_bool(Passages.reaches(cavador, int(Band.Kind.SURFACE), int(Band.Kind.SURFACE))).is_true()


func test_o_alado_bate_no_chao_sem_descer_porque_nao_pode_descer() -> void:
	# A outra metade da mesma regra, e e ela que faz do Alado uma ameaca: o
	# can_change_band dele e falso, e por isso o ar e o sitio dele para sempre.
	# O §07 escreve-o na Libelula: "ignora a camada de solo; so atacavel por
	# arqueiros e torres altas". A resposta a ele e um posto, e e a torre alta.
	var alado := Registry.entry(&"creatures", &"winged") as CreatureData

	assert_bool(alado.can_change_band).is_false()
	assert_bool(Passages.reaches(alado, int(Band.Kind.AERIAL), int(Band.Kind.SURFACE))).is_true()


func test_uma_faixa_fora_do_targets_bands_nao_se_alcanca_de_lado_nenhum() -> void:
	var rastejante := Registry.entry(&"creatures", &"crawler") as CreatureData

	(
		assert_bool(Passages.reaches(rastejante, int(Band.Kind.SURFACE), int(Band.Kind.AERIAL)))
		. is_false()
	)
