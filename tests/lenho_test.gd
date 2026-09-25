# tests/lenho_test.gd — XIII-03: para que serve o Lenho Amargo (§74, §10).
#
# A muralha de ferro pede a Fornalha, e um Lenho dispensa-a, por segmento. O
# bastiao, unico por imperio, custa 3 Lenhos alem das moedas. Os numeros vem de
# walls.csv e economy.csv; o sitio de muro monta-se como o greybox o monta.
extends GdUnitTestSuite


func _curva() -> EconomyCurve:
	return Registry.entry(&"economy", &"curve") as EconomyCurve


func _nivel(n: int) -> WallData:
	return SimFactory.walls_by_level()[n - 1]


func _muro(obras: BuildSystem, x: float, nivel: int) -> BuildSlot:
	var vaga := WallSite.slot(x)
	vaga.level = nivel
	vaga.state = BuildSlot.State.DONE if nivel > 0 else BuildSlot.State.EMPTY
	return obras.post(vaga)


func _pagar(obras: BuildSystem, vaga: BuildSlot, estado: GameState) -> Array[Dictionary]:
	var moedas := CoinSystem.new(_curva())
	var e := GameState.new()
	for _k in vaga.next_cost():
		moedas.settled[moedas.index_of(moedas.drop(e, vaga.x, vaga.band, 1, 0.0))] = 1
	return obras.absorb(moedas, estado)


func test_a_muralha_de_ferro_pede_a_fornalha_ou_um_lenho() -> void:
	var obras := BuildSystem.new()
	var vaga := _muro(obras, 100.0, 3)
	var estado := GameState.new()
	assert_str(String(_nivel(4).requires_conquest)).is_equal("fornalha")
	assert_bool(obras.can_climb(vaga, estado)).is_false()
	assert_array(_pagar(obras, vaga, estado)).is_empty()  # as moedas ficam no chao
	estado.bitter_wood = 1
	assert_bool(obras.can_climb(vaga, estado)).is_true()
	_pagar(obras, vaga, estado)
	assert_int(vaga.state).is_equal(BuildSlot.State.SCAFFOLD)
	assert_int(estado.bitter_wood).is_equal(0)


func test_com_a_fornalha_conquistada_o_lenho_nao_se_gasta() -> void:
	var obras := BuildSystem.new()
	var vaga := _muro(obras, 100.0, 3)
	var estado := GameState.new()
	estado.conquests = PackedStringArray(["fornalha"])
	estado.bitter_wood = 2
	_pagar(obras, vaga, estado)
	assert_int(vaga.state).is_equal(BuildSlot.State.SCAFFOLD)
	assert_int(estado.bitter_wood).is_equal(2)


func test_o_bastiao_custa_tres_lenhos_alem_das_moedas() -> void:
	var obras := BuildSystem.new()
	var vaga := _muro(obras, 100.0, 4)
	var estado := GameState.new()
	estado.conquests = PackedStringArray(["fornalha"])
	var custo := _curva().bitter_wood_bastion_cost
	estado.bitter_wood = custo - 1
	assert_bool(obras.can_climb(vaga, estado)).is_false()
	estado.bitter_wood = custo
	_pagar(obras, vaga, estado)
	assert_int(vaga.state).is_equal(BuildSlot.State.SCAFFOLD)
	assert_int(estado.bitter_wood).is_equal(0)


func test_o_bastiao_e_unico_por_imperio() -> void:
	var obras := BuildSystem.new()
	var um := _muro(obras, 100.0, 5)
	var outro := _muro(obras, 900.0, 4)
	var estado := GameState.new()
	estado.bitter_wood = 99
	assert_bool(um.next_unique()).is_false()  # ja no topo
	assert_bool(outro.next_unique()).is_true()
	assert_bool(obras.can_climb(outro, estado)).is_false()


func test_os_niveis_de_baixo_so_pedem_moedas() -> void:
	var obras := BuildSystem.new()
	var vaga := _muro(obras, 100.0, 0)
	var estado := GameState.new()
	for n in 3:
		vaga.level = n
		assert_int(vaga.woods_for_next(estado.conquests)).is_equal(0)
		assert_bool(obras.can_climb(vaga, estado)).is_true()


func test_sem_estado_contam_so_as_moedas() -> void:
	var obras := BuildSystem.new()
	var vaga := _muro(obras, 100.0, 3)
	assert_bool(obras.can_climb(vaga, null)).is_true()
