# tests/caca_das_terras_test.gd — a caca das terras geradas, com o jogo inteiro (Q-217,
# ADR 0058).
#
# O dono, a 03/10/2026: «eles devem spawnar logo ao lado do meu imperio dos dois lados e
# depois de forma mais organica e aleatoriamente pelo mundo». Ao andar, cada segmento de
# trilho traz as suas tocas, com o bicho ja la fora, e o save guarda-as.
extends GdUnitTestSuite

const PASSO := 1.0 / 30.0
const SEMENTE := 20261003


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _comecar() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()
	SimLoop.step(PASSO)


func _por_o_rei(x: float) -> void:
	var i := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.xs[i] = x
	SimLoop.units.clear_target(SimLoop.king_id)
	SimLoop.step(PASSO)


func _tocas_fora(lado: int) -> Array[float]:
	var saida: Array[float] = []
	for x in SimLoop.hunting.burrows.xs:
		if (lado < 0 and x < 0.0) or (lado > 0 and x > SimLoop.world_width):
			saida.append(x)
	return saida


## Ao andar, as terras geradas trazem tocas, com o bicho ja la fora: dos dois lados, logo
## no primeiro segmento, e depois espalhadas pelo mundo.
func test_as_terras_geradas_tem_bichos_dos_dois_lados() -> void:
	_comecar()
	var terras := SimLoop.field.wilds
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		assert_array(_tocas_fora(lado)).is_empty()
		var beira := 0.0 if lado == WorldPlan.OESTE else SimLoop.world_width
		_por_o_rei(beira)
		assert_int(terras.count(lado)).is_greater(0)
		var tocas := _tocas_fora(lado)
		assert_int(tocas.size()).override_failure_message(str(lado)).is_greater(0)
		var primeiro := terras.x_of(lado, 0, SimLoop.world_width)
		var no_primeiro := tocas.filter(
			func(x: float) -> bool: return x >= primeiro and x <= primeiro + terras.width
		)
		assert_int(no_primeiro.size()).is_greater(0)
		for x in no_primeiro:
			assert_bool(SimLoop.hunting.rabbits.has(x)).is_true()
	var limites := Frontier.walk_limits()
	_por_o_rei(limites.y)
	_por_o_rei(limites.x)
	var segmentos_com_caca := {}
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		for x in _tocas_fora(lado):
			segmentos_com_caca[terras.find(x, SimLoop.world_width)] = true
	assert_int(segmentos_com_caca.size()).is_greater(2)


## O save guarda as tocas das terras; um save de antes delas ganha-as ao carregar.
func test_as_tocas_das_terras_vao_no_save() -> void:
	_comecar()
	_por_o_rei(0.0)
	_por_o_rei(SimLoop.world_width)
	var antes := SimLoop.hunting.burrows.xs.duplicate()
	var mundo: Dictionary = SimLoop.world()
	var velho: Dictionary = mundo.duplicate(true)
	var caca: Dictionary = velho[&"hunting"]
	var tocas: Dictionary = caca[&"burrows"]
	var em_casa: Array[float] = []
	for x: float in tocas[&"xs"]:
		if x >= 0.0 and x <= SimLoop.world_width:
			em_casa.append(x)
	tocas[&"xs"] = em_casa
	for chave in [&"alive", &"waits", &"kinds", &"game"]:
		var lista: Variant = tocas[chave]
		lista.resize(em_casa.size())
		tocas[chave] = lista
	for novo in [mundo, velho]:
		var estado := GameState.from_dict(SimLoop.state.to_dict())
		var fluxos := RngService.snapshot()
		SimLoop.stop()
		SimLoop.resume(estado, fluxos)
		Greybox.region()
		SimLoop.load_world(novo)
		var depois := SimLoop.hunting.burrows.xs.duplicate()
		depois.sort()
		var esperado := antes.duplicate()
		esperado.sort()
		assert_array(depois).is_equal(esperado)
