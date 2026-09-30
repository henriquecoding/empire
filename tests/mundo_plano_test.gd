# tests/mundo_plano_test.gd — quem mora onde no mundo continuo (o pedido do dono de
# 30/09/2026; §21; ADR 0038).
#
# "Entre as regioes devem haver caminhos e trilhas para fazerem transicoes suaves."
# O plano poe os povos da campanha ao longo do mundo, alternando de lado a partir da
# regiao de casa; cada terra tem um trilho antes e um limiar a entrada (§21: "a
# fronteira entre povos nunca e um fade"), e acaba na fortaleza (§21: "uma nas
# extremidades"). Depois do ultimo povo de cada lado, um trilho e a borda.
extends GdUnitTestSuite

const TERRA := 4
const TRILHO := 5
const POVOS := 7
const Z := WorldPlan.Zone


func _fixo(_lado: int, _j: int) -> int:
	return TRILHO


func _plano(povos: int = POVOS) -> WorldPlan:
	return WorldPlan.draw(povos, TERRA, _fixo)


## Os povos das terras de um lado, de dentro para fora.
func _povos_das_terras(plano: WorldPlan, lado: int) -> Array[int]:
	var saida: Array[int] = []
	for k in plano.size(lado):
		if plano.zone(lado, k) == Z.THRESHOLD:
			saida.append(plano.people(lado, k))
	return saida


func test_os_povos_alternam_de_lado_pela_ordem_do_plano() -> void:
	var plano := _plano()
	assert_array(_povos_das_terras(plano, WorldPlan.LESTE)).is_equal([1, 3, 5, 7])
	assert_array(_povos_das_terras(plano, WorldPlan.OESTE)).is_equal([2, 4, 6])


func test_cada_terra_tem_trilho_limiar_e_a_fortaleza_na_ponta() -> void:
	var plano := _plano(1)
	var esperado: Array[int] = []
	for _k in TRILHO:
		esperado.append(Z.TRAIL)
	esperado.append(Z.THRESHOLD)
	for _k in TERRA - 1:
		esperado.append(Z.LAND)
	esperado.append(Z.FORTRESS)
	for _k in TRILHO:
		esperado.append(Z.TRAIL)
	esperado.append(Z.EDGE)
	var leste: Array[int] = []
	for k in plano.size(WorldPlan.LESTE):
		leste.append(plano.zone(WorldPlan.LESTE, k))
	assert_array(leste).is_equal(esperado)


func test_sem_outros_povos_ha_um_trilho_e_a_borda() -> void:
	var plano := _plano(0)
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		assert_int(plano.size(lado)).is_equal(TRILHO + 1)
		assert_int(plano.zone(lado, TRILHO)).is_equal(Z.EDGE)
		assert_int(plano.people(lado, TRILHO)).is_equal(WorldPlan.CASA)


## A transicao suave: ao longo de um trilho a paisagem passa do povo de onde se vem
## para o povo para onde se vai, e o ultimo trilho de cada lado fica no ultimo povo.
func test_o_trilho_passa_de_um_povo_para_o_seguinte() -> void:
	var plano := _plano()
	var antes := -1.0
	for k in TRILHO:
		var entre := plano.between(WorldPlan.LESTE, k)
		assert_int(int(entre.x)).is_equal(WorldPlan.CASA)
		assert_int(int(entre.y)).is_equal(1)
		assert_float(entre.z).is_greater(antes)
		assert_float(entre.z).is_between(0.0, 1.0)
		antes = entre.z
	var segundo := plano.between(WorldPlan.LESTE, TRILHO + TERRA + 1)
	assert_int(int(segundo.x)).is_equal(1)
	assert_int(int(segundo.y)).is_equal(3)
	var ultimo := plano.between(WorldPlan.LESTE, plano.size(WorldPlan.LESTE) - 2)
	assert_int(int(ultimo.x)).is_equal(7)
	assert_int(int(ultimo.y)).is_equal(7)
	assert_float(plano.between(WorldPlan.LESTE, TRILHO).z).is_equal(1.0)


## O que se ve numa ponta de um segmento: de onde se vem, para onde se vai e quanto.
## Uma ponta que e toda de um povo le-se so como esse povo.
func _ponta(plano: WorldPlan, lado: int, k: int, fora: bool) -> Vector3:
	var entre := plano.between(lado, k)
	var pontas := plano.mix_ends(lado, k)
	var t := pontas.y if fora else pontas.x
	if is_zero_approx(t):
		return Vector3(entre.x, entre.x, 1.0)
	if is_equal_approx(t, 1.0):
		return Vector3(entre.y, entre.y, 1.0)
	return Vector3(entre.x, entre.y, t)


## Sem degraus (o dono: "parece que foi programado para pular de um ponto a outro"):
## cada segmento acaba com a paisagem com que o seguinte comeca, e ao longo de um
## trilho a mistura so cresce.
func test_a_paisagem_nao_da_saltos_de_um_segmento_para_o_seguinte() -> void:
	var plano := _plano()
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		var casa := Vector3(WorldPlan.CASA, WorldPlan.CASA, 1.0)
		assert_that(_ponta(plano, lado, 0, false)).is_equal(casa)
		for k in range(1, plano.size(lado)):
			assert_that(_ponta(plano, lado, k, false)).is_equal(_ponta(plano, lado, k - 1, true))
			var pontas := plano.mix_ends(lado, k)
			if plano.zone(lado, k) == Z.TRAIL:
				assert_float(pontas.y).is_greater(pontas.x)
			else:
				assert_that(pontas).is_equal(Vector2.ONE)


## A estrada da regiao e a da terra de cada povo estreitam-se em trilho ao sair e
## alargam-se ao chegar ao limiar seguinte; o ultimo trilho vai estreito ate a borda.
func test_o_caminho_estreita_e_alarga_sem_saltos() -> void:
	var plano := _plano(1)
	var lado := WorldPlan.LESTE
	var borda := plano.size(lado) - 1
	assert_that(plano.trail_ends(lado, 0)).is_equal(Vector2(0.0, 1.0))
	assert_that(plano.trail_ends(lado, 1)).is_equal(Vector2.ONE)
	assert_that(plano.trail_ends(lado, TRILHO - 1)).is_equal(Vector2(1.0, 0.0))
	assert_that(plano.trail_ends(lado, TRILHO)).is_equal(Vector2.ZERO)
	assert_that(plano.trail_ends(lado, TRILHO + TERRA + 1)).is_equal(Vector2(0.0, 1.0))
	assert_that(plano.trail_ends(lado, borda - 1)).is_equal(Vector2.ONE)
	assert_that(plano.trail_ends(lado, borda)).is_equal(Vector2.ONE)
	for k in range(1, plano.size(lado)):
		assert_float(plano.trail_ends(lado, k).x).is_equal(plano.trail_ends(lado, k - 1).y)


## O comprimento de cada trilho e o que quem chama sorteia para aquele sitio: o
## j-esimo trilho de um lado, e nao o j-esimo pedido.
func test_cada_trilho_tem_o_comprimento_do_seu_sitio() -> void:
	var pedidos: Array = []
	var trilho := func(lado: int, j: int) -> int:
		pedidos.append([lado, j])
		return 3 + j + (1 if lado == WorldPlan.OESTE else 0)
	var plano := WorldPlan.draw(3, TERRA, trilho)
	var leste := plano.size(WorldPlan.LESTE)
	# Leste: trilho 0 (3), terra do 1, trilho 1 (4), terra do 3, trilho 2 (5), borda.
	assert_int(leste).is_equal(3 + 1 + TERRA + 4 + 1 + TERRA + 5 + 1)
	assert_int(plano.zone(WorldPlan.LESTE, 3)).is_equal(Z.THRESHOLD)
	assert_bool(pedidos.has([WorldPlan.OESTE, 1])).is_true()


func test_o_plano_vai_no_save() -> void:
	var plano := _plano()
	var copia := WorldPlan.new()
	copia.from_dict(plano.to_dict())
	for lado in [WorldPlan.OESTE, WorldPlan.LESTE]:
		assert_int(copia.size(lado)).is_equal(plano.size(lado))
		for k in plano.size(lado):
			assert_int(copia.zone(lado, k)).is_equal(plano.zone(lado, k))
			assert_int(copia.people(lado, k)).is_equal(plano.people(lado, k))
	var vazio := WorldPlan.new()
	vazio.from_dict({&"east": "lixo"})
	assert_int(vazio.size(WorldPlan.LESTE)).is_equal(0)
