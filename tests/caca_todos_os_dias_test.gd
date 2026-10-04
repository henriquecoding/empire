# tests/caca_todos_os_dias_test.gd — os bichos de todos os dias (Q-217, ADR 0058).
#
# O dono, a 03/10/2026: «nao aparece criatura e animal nenhum, eles devem spawnar logo ao
# lado do meu imperio dos dois lados e depois de forma mais organica e aleatoriamente pelo
# mundo»; «a noite os bichos nao nascem, so ficam os que ja estavam»; e «as criaturas e
# animais para cacar e farmar dinheiro devem aparecer todos os dias, varias vezes ao dia».
extends GdUnitTestSuite


func _bichos(ids: Array) -> Array[WildlifeData]:
	var saida: Array[WildlifeData] = []
	for id: String in ids:
		saida.append(Registry.entry(&"wildlife", StringName(id)) as WildlifeData)
	return saida


func _luz() -> float:
	var relogio := Registry.entry(&"economy", &"clock") as ClockData
	var luz := 0.0
	for fase in HuntWatch.LUZ:
		luz += relogio.phase_durations[fase]
	return luz


func _sorteios(u: float) -> PackedFloat32Array:
	var saida := PackedFloat32Array()
	saida.resize(WildBurrows.SORTEIOS)
	saida.fill(u)
	return saida


## Cada bicho com toca volta varias vezes por dia de luz; o coelho, o de 1 moeda, mais.
func test_cada_bicho_volta_varias_vezes_ao_dia() -> void:
	var luz := _luz()
	for recurso in Registry.entries(&"wildlife"):
		var dados := recurso as WildlifeData
		if dados.burrows_per_region <= 0 and dados.per_segment_max <= 0:
			continue
		assert_float(dados.respawn_s).override_failure_message(String(dados.id)).is_greater(0.0)
		(
			assert_float(luz / dados.respawn_s)
			. override_failure_message(String(dados.id))
			. is_greater_equal(1.0)
		)
	var coelho := Registry.entry(&"wildlife", &"rabbit") as WildlifeData
	assert_float(luz / coelho.respawn_s).is_greater_equal(3.0)


## A toca usa o ritmo do bicho dela; sem ritmo, o periodo de sempre.
func test_a_toca_da_ao_ritmo_do_bicho() -> void:
	var tocas := Burrows.new()
	tocas.place([10.0, 500.0] as Array[float], [0.0, 0.0] as Array[float])
	tocas.game = PackedStringArray(["rabbit", "deer"])
	var fora: Array[float] = []
	assert_array(tocas.grow(0.1, 100.0, fora, {&"rabbit": 5.0})).is_equal([10.0, 500.0])
	assert_float(tocas.waits[0]).is_equal_approx(4.9, 0.001)
	assert_float(tocas.waits[1]).is_equal_approx(99.9, 0.001)


## As tocas de um segmento gerado ficam dentro dele, longe do assunto, sem se tocar.
func test_as_tocas_de_um_segmento_ficam_no_chao_dele() -> void:
	var bichos := _bichos(["rabbit", "pheasant", "fox", "deer", "boar"])
	var sujeito := 1000.0 + 320.0
	for u in [0.0, 0.33, 0.5, 0.71, 0.999]:
		var tocas := WildBurrows.draw(1000.0, 640.0, sujeito, &"forest", bichos, _sorteios(u), true)
		assert_int(tocas.size()).is_greater(0)
		var xs: Array[float] = []
		for t in tocas:
			var x: float = t[WildBurrows.X]
			assert_float(x).is_between(1000.0, 1640.0)
			assert_float(absf(x - sujeito)).is_greater_equal(WildBurrows.SUJEITO_PX)
			for outro in xs:
				assert_float(absf(x - outro)).is_greater_equal(WildBurrows.FOLGA_PX)
			xs.append(x)


## Cada bicho sai do sitio que o segmento tem e que lhe faz sentido (Q-150), e nunca mais
## tocas do que o per_segment_max dele.
func test_cada_bicho_no_seu_sitio_e_no_seu_maximo() -> void:
	var bichos := _bichos(["rabbit", "pheasant", "fox", "deer", "boar"])
	for tipo: StringName in WildBurrows.SITIOS:
		var tocas := WildBurrows.draw(0.0, 640.0, 320.0, tipo, bichos, _sorteios(0.999), false)
		var conta := {}
		for t in tocas:
			var dados := (
				Registry.entry(&"wildlife", StringName(t[WildBurrows.BICHO])) as WildlifeData
			)
			var sitio := StringName(t[WildBurrows.SITIO])
			assert_bool(dados.sources.has(sitio)).is_true()
			assert_bool(WildBurrows.SITIOS[tipo].has(sitio)).is_true()
			conta[dados.id] = int(conta.get(dados.id, 0)) + 1
			assert_int(int(conta[dados.id])).is_less_equal(dados.per_segment_max)


## ADR 0062: o primeiro segmento garante uma fonte de caca, nao todas as especies.
func test_o_primeiro_segmento_tem_sempre_caca() -> void:
	var bichos := _bichos(["rabbit", "pheasant", "fox"])
	(
		assert_array(WildBurrows.draw(0.0, 640.0, 320.0, &"empty", bichos, _sorteios(0.0), false))
		. is_empty()
	)
	var garantidas := WildBurrows.draw(0.0, 640.0, 320.0, &"empty", bichos, _sorteios(0.0), true)
	assert_int(garantidas.size()).is_equal(1)
	assert_str(String(garantidas[0][WildBurrows.BICHO])).is_equal("rabbit")
	(
		assert_array(
			WildBurrows.draw(0.0, 640.0, 320.0, &"settlement", bichos, _sorteios(0.9), true)
		)
		. is_empty()
	)


func test_o_limite_de_densidade_nao_elimina_a_fonte_pequena_garantida() -> void:
	var bichos := _bichos(["rabbit", "pheasant", "fox"])
	var u := _sorteios(0.999)
	u[0] = 0.0  # o coelho depende da garantia, os outros tentam ocupar o trecho
	u[WildBurrows.MAX_BICHOS + 1] = 0.999
	u[WildBurrows.MAX_BICHOS + WildBurrows.POR_TOCA + 1] = 0.0
	u[WildBurrows.MAX_BICHOS + WildBurrows.POR_TOCA * 2 + 1] = 0.001
	var tocas := WildBurrows.draw(0.0, 640.0, 320.0, &"empty", bichos, u, true)
	var rabbit := false
	for toca in tocas:
		rabbit = rabbit or toca[WildBurrows.BICHO] == &"rabbit"
	assert_bool(rabbit).is_true()
	assert_int(tocas.size()).is_less_equal(2)


## O mesmo segmento da as mesmas tocas: o mundo e o mesmo venha o rei quando vier.
func test_o_mesmo_sorteio_da_as_mesmas_tocas() -> void:
	var bichos := _bichos(["rabbit", "pheasant", "fox", "deer", "boar"])
	var u := RngService.scatter(hash([1, 2, 3]), WildBurrows.SORTEIOS)
	var a := WildBurrows.draw(-640.0, 640.0, -300.0, &"forest", bichos, u, false)
	var b := WildBurrows.draw(-640.0, 640.0, -300.0, &"forest", bichos, u, false)
	assert_str(str(a)).is_equal(str(b))


## Os cacadores de casa nao vao atras de um bicho das terras: cacam dentro da regiao.
func test_os_cacadores_cacam_em_casa() -> void:
	var h := HuntingSystem.new(SimFactory.by_id(&"units"), Registry.entry(&"wildlife", &"rabbit"))
	h.burrows.place([5000.0] as Array[float], [0.0] as Array[float])
	h.home = Vector2(0.0, 3840.0)
	h.open_day(2)
	h.grow(0.0, true, 1.0)
	var unidades := UnitSystem.new()
	var arqueiro := unidades.spawn(GameState.new(), Registry.entry(&"units", &"archer"), 1, 3700.0)
	unidades.clear_target(arqueiro)
	h.plan(unidades, true)
	var i := unidades.index_of(arqueiro)
	assert_int(unidades.has_targets[i]).is_equal(0)
	h.home = Vector2(-INF, INF)
	h.plan(unidades, true)
	assert_int(unidades.has_targets[i]).is_equal(1)


## De dia a toca vazia volta a dar o bicho dela varias vezes; de noite nao nasce nada.
func test_de_dia_volta_de_noite_nao_nasce() -> void:
	var h := HuntingSystem.new(SimFactory.by_id(&"units"), Registry.entry(&"wildlife", &"rabbit"))
	h.wildlife = SimFactory.by_id(&"wildlife")
	h.burrows.place([100.0] as Array[float], [0.0] as Array[float])
	var ritmos := WildHunt.rhythms(0.0)
	var vezes := 0
	var t := 0.0
	while t < _luz():
		h.grow(1.0, true, 0.0, Callable(), ritmos)
		if not h.rabbits.is_empty():
			vezes += 1
			h.hurt(100.0, 99, 0)
		t += 1.0
	assert_int(vezes).is_greater_equal(3)
	for _k in 600:
		h.grow(1.0, false, 0.0, Callable(), ritmos)
	assert_array(h.rabbits).is_empty()
