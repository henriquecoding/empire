# tests/amargueiro_noite_test.gd — o Amargueiro ligado a noite (§74, XIII-03):
# nasce na alvorada, pesa no crepusculo seguinte, e o Marco abranda a mancha.
#
# Corre pela NightWatch, que e o passo 2 do §43, e nao pelo sistema a solta: e
# a ligacao que se prova aqui — o sistema tem os seus testes.
extends GdUnitTestSuite

const B := preload("res://tests/support/bosque.gd")
const Model := preload("res://tests/support/reference_model.gd")

const SEMENTE := 20260925
const DIA := 5


func _mundo() -> Vector2:
	return Vector2(B.NUCLEO, B.LARGURA)


func _virar(noite: NightWatch, fase: GameClock.Phase, estado: GameState) -> void:
	noite.tick(B.PASSO, int(fase), true, estado, CreatureSystem.new(), _mundo())


func before_test() -> void:
	RngService.configure(SEMENTE)


func test_tres_mortos_la_fora_sao_a_linha_das_tres_arvores_da_74() -> void:
	var u := UnitSystem.new()
	var o := BuildSystem.new()
	var noite := B.noite(u, o)
	var estado := GameState.new()
	estado.day = DIA
	for k in 3:
		B.morto(u, estado, &"archer", B.FORA + 100.0 * k)
	_virar(noite, GameClock.Phase.DAWN, estado)
	assert_int(noite.amargueiros.anonymous()).is_equal(3)
	assert_int(u.count()).is_equal(0)  # os corpos levantaram-se

	_virar(noite, GameClock.Phase.DUSK, estado)
	assert_float(noite.rot.mass()).is_equal(Model.rot_mass(DIA, 0, B.perfil(), 3, 0))


func test_o_marco_e_terreno_consagrado_para_a_mancha() -> void:
	var livre := _distancia_percorrida(false)
	var travada := _distancia_percorrida(true)
	assert_float(travada).is_less(livre)


## Quanto a mancha anda numa noite curta, com ou sem um Marco no caminho todo.
func _distancia_percorrida(com_marco: bool) -> float:
	RngService.configure(SEMENTE)
	var u := UnitSystem.new()
	var o := BuildSystem.new()
	var noite := B.noite(u, o)
	var estado := GameState.new()
	estado.day = DIA
	# Um Marco em cada borda: o lado por onde ela nasce e sorteado (§51).
	for x in [50.0, B.LARGURA - 50.0] if com_marco else []:
		var i := noite.amargueiros.plant(x, int(Band.Kind.SURFACE), 2, 1, "")
		noite.amargueiros.consecrate(i, o)
	_virar(noite, GameClock.Phase.DUSK, estado)
	var partida := noite.rot.position_x()
	for _t in 60:
		noite.tick(
			B.PASSO, int(GameClock.Phase.NIGHT), false, estado, CreatureSystem.new(), _mundo()
		)
	return absf(noite.rot.position_x() - partida)


func test_a_arvore_tem_a_altura_da_pessoa_e_no_subsolo_pende_do_tecto() -> void:
	var bosque := SimFactory.amargueiros()
	var baixa := bosque.plant(B.FORA, int(Band.Kind.SURFACE), 1, 1, "")
	var alta := bosque.plant(B.FORA, int(Band.Kind.SURFACE), 3, 1, "")
	var funda := bosque.plant(B.FORA, int(Band.Kind.UNDERGROUND), 2, 1, "")
	assert_float(AmargueiroView.box(bosque, alta).size.y).is_greater(
		AmargueiroView.box(bosque, baixa).size.y
	)
	var chao := WorldPalette.ground_of(int(Band.Kind.SURFACE))
	assert_float(AmargueiroView.box(bosque, baixa).end.y).is_equal(chao)
	assert_float(AmargueiroView.box(bosque, funda).position.y).is_equal(float(Band.GROUND_LINE))


func test_um_nomeado_morto_la_fora_e_uma_arvore_nomeada_e_o_titulo_vai_de_luto() -> void:
	var u := UnitSystem.new()
	var o := BuildSystem.new()
	var noite := B.noite(u, o)
	var estado := GameState.new()
	estado.day = DIA
	var morto := B.morto(u, estado, &"archer", B.FORA)
	noite.names.from_dict({&"titles_holder": {"the_counter": morto}})
	_virar(noite, GameClock.Phase.DAWN, estado)
	assert_int(noite.amargueiros.named()).is_equal(1)
	assert_str(noite.amargueiros.titles[0]).is_equal("the_counter")
	assert_int(noite.names.count()).is_equal(0)
	assert_bool(noite.names.mourning.has("the_counter")).is_true()
	_virar(noite, GameClock.Phase.DUSK, estado)
	assert_float(noite.rot.mass()).is_equal(Model.rot_mass(DIA, 0, B.perfil(), 0, 1))


func test_o_marco_de_um_povo_que_ficou_pesa_como_uma_arvore() -> void:
	var noite := B.noite(UnitSystem.new(), BuildSystem.new())
	var estado := GameState.new()
	estado.day = DIA
	noite.harvest.conquer(&"portuarios", false)
	for _d in noite.harvest.days_left:
		_virar(noite, GameClock.Phase.DAWN, estado)
	noite.harvest.decide(HarvestSystem.Choice.KEEP)
	_virar(noite, GameClock.Phase.DUSK, estado)
	assert_float(noite.rot.mass()).is_equal(Model.rot_mass(DIA, 0, B.perfil(), 1, 0))
