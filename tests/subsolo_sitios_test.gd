# tests/subsolo_sitios_test.gd — o subsolo no jogo: os poroes do imperio, a sala secreta
# do castelo e as masmorras, gerados na primeira descida (o pedido do dono de 02/10/2026;
# §11, §17, §21; Q-186, ADR 0046). O desenho puro esta no subsolo_delimitado_test.
extends GdUnitTestSuite

const PASSO := 1.0 / 30.0
const SEMENTE := 20261002
const OUTRA := 20261003
const SEGUNDOS := 30.0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _rei() -> int:
	return SimLoop.units.index_of(SimLoop.king_id)


func _sitio(chave: String) -> int:
	var sitios := SimLoop.field.under
	for i in sitios.count():
		if sitios.key_of(i) == chave:
			return i
	return -1


func _descer_em(x: float) -> void:
	SimLoop.units.xs[_rei()] = x
	assert_bool(Verbs.assume(SimLoop.units, SimLoop.king_id, SimLoop.passages)).is_true()


# ─── No jogo: a regiao, a sala secreta e as masmorras ────────────────────────


func test_o_imperio_tem_dois_poroes_e_uma_sala_secreta_por_gerar() -> void:
	var sitios := SimLoop.field.under
	var poroes := 0
	var alcapoes := 0
	for i in sitios.count():
		assert_bool(sitios.generated(i)).is_false()
		match sitios.kind_of(i):
			UndergroundSites.CELLAR:
				poroes += 1
				assert_bool(Passages.near(sitios.mouth_of(i), SimLoop.passages)).is_true()
			UndergroundSites.HATCH:
				alcapoes += 1
	assert_int(poroes).is_equal(SimLoop.passages.size())
	assert_int(alcapoes).is_equal(1)
	var nucleo := Registry.entry(&"buildings", BuildSlot.NUCLEO) as BuildingData
	var alcapao := sitios.hatches()[0]
	assert_float(absf(alcapao - SimLoop.core_x)).is_less(nucleo.width_px * 0.5)
	assert_float(absf(alcapao - SimLoop.core_x)).is_greater(Band.PASSAGE_PX)


func test_descer_gera_o_porao_com_o_poco_e_a_camara_dentro_dos_muros() -> void:
	_descer_em(SimLoop.passages[0])
	var i := SimLoop.field.under.site_at(SimLoop.passages[0])
	assert_int(i).is_not_equal(-1)
	var limites := SimLoop.field.under.span(i)
	var lado := signf(SimLoop.passages[0] - SimLoop.core_x)
	var dentro := 0
	for obra in SimLoop.builds.slots:
		if obra.band == Band.Kind.UNDERGROUND and signf(obra.x - SimLoop.core_x) == lado:
			assert_float(obra.x).is_between(limites.x, limites.y)
			dentro += 1
	for k in SimLoop.secrets.ids.size():
		var x := SimLoop.secrets.xs[k]
		if (
			SimLoop.secrets.bands[k] == int(Band.Kind.UNDERGROUND)
			and signf(x - SimLoop.core_x) == lado
		):
			assert_float(x).is_between(limites.x, limites.y)
			dentro += 1
	assert_int(dentro).is_greater_equal(2)  # o poco de minerio e a camara da Semente Real
	var muros: Array = Greybox.MUROS_X
	assert_float(limites.x).is_greater(SimLoop.core_x + float(muros[0]))
	assert_float(limites.y).is_less(SimLoop.core_x + float(muros[1]))


func test_o_rei_la_em_baixo_para_na_parede_do_porao() -> void:
	_descer_em(SimLoop.passages[0])
	var limites := SimLoop.field.under.span(SimLoop.field.under.site_at(SimLoop.passages[0]))
	for _t in int(SEGUNDOS / PASSO):
		SimLoop.units.set_target_x(SimLoop.king_id, SimLoop.core_x)
		SimLoop.step(PASSO)
	assert_float(SimLoop.units.xs[_rei()]).is_equal_approx(limites.y, 0.01)


func test_outra_jogatina_outro_porao_e_a_mesma_semente_o_mesmo() -> void:
	_descer_em(SimLoop.passages[1])
	var i := SimLoop.field.under.site_at(SimLoop.passages[1])
	var primeiro := SimLoop.field.under.rooms(i).duplicate(true)
	var alcapao := SimLoop.field.under.hatches()[0]
	SimLoop.stop()
	SimLoop.start(SEMENTE)
	Greybox.build()
	_descer_em(SimLoop.passages[1])
	var mesmo := SimLoop.field.under.rooms(SimLoop.field.under.site_at(SimLoop.passages[1]))
	assert_bool(mesmo == primeiro).is_true()
	SimLoop.stop()
	SimLoop.start(OUTRA)
	Greybox.build()
	_descer_em(SimLoop.passages[1])
	var outro := SimLoop.field.under.rooms(SimLoop.field.under.site_at(SimLoop.passages[1]))
	var diferente := outro != primeiro or SimLoop.field.under.hatches()[0] != alcapao
	assert_bool(diferente).is_true()


func test_o_bau_proprio_abre_vazio_sem_recompensa_ao_descer() -> void:
	var alcapao := SimLoop.field.under.hatches()[0]
	SimLoop.units.xs[_rei()] = alcapao
	var para := Verbs.destination(SimLoop.units, SimLoop.king_id, SimLoop.passages)
	assert_int(para).is_equal(int(Band.Kind.UNDERGROUND))
	var antes := SimLoop.coins.count()
	_descer_em(alcapao)
	var i := _sitio(UnderWatch.HATCH_KEY)
	assert_bool(SimLoop.field.under.generated(i)).is_true()
	var caidas := SimLoop.coins.count() - antes
	assert_int(caidas).is_equal(0)
	assert_int(SimLoop.treasury.amount(UnderWatch.HATCH_KEY)).is_equal(0)
	var limites := SimLoop.field.under.span(i)
	var nucleo := Registry.entry(&"buildings", BuildSlot.NUCLEO) as BuildingData
	assert_float(limites.x).is_greater_equal(SimLoop.core_x - nucleo.width_px * 0.5)
	assert_float(limites.y).is_less_equal(SimLoop.core_x + nucleo.width_px * 0.5)
	SimLoop.units.bands[_rei()] = int(Band.Kind.SURFACE)
	_descer_em(alcapao)
	assert_int(SimLoop.coins.count() - antes).is_equal(caidas)


func test_o_porao_gerado_volta_igual_do_save() -> void:
	_descer_em(SimLoop.passages[0])
	var i := SimLoop.field.under.site_at(SimLoop.passages[0])
	var chave := SimLoop.field.under.key_of(i)
	var salas := SimLoop.field.under.rooms(i).duplicate(true)
	var mundo := SimLoop.world()
	var estado := SimLoop.state
	SimLoop.resume(estado, RngService.snapshot())
	Greybox.region()
	SimLoop.load_world(mundo)
	var j := _sitio(chave)
	assert_bool(SimLoop.field.under.generated(j)).is_true()
	assert_bool(SimLoop.field.under.rooms(j) == salas).is_true()


func test_a_masmorra_fica_no_seu_segmento() -> void:
	var limites := Frontier.walk_limits()
	var rei := _rei()
	SimLoop.units.xs[rei] = limites.y
	SimLoop.units.clear_target(SimLoop.king_id)
	SimLoop.step(PASSO)
	var bocas := SimLoop.field.wilds.dungeons(SimLoop.world_width)
	if bocas.is_empty():
		return
	SimLoop.units.xs[rei] = bocas[0]
	SimLoop.units.bands[rei] = int(Band.Kind.SURFACE)
	_descer_em(bocas[0])
	var i := SimLoop.field.under.site_at(bocas[0])
	assert_int(i).is_not_equal(-1)
	assert_str(String(SimLoop.field.under.kind_of(i))).is_equal(String(UndergroundSites.DUNGEON))
	var span := SimLoop.field.under.span(i)
	var onde := SimLoop.field.wilds.find(bocas[0], SimLoop.world_width)
	var x0 := SimLoop.field.wilds.x_of(onde.x, onde.y, SimLoop.world_width)
	assert_float(span.x).is_greater_equal(x0)
	assert_float(span.y).is_less_equal(x0 + SimLoop.field.wilds.width)
