# tests/wilds_test.gd — o que cresce e o que vive numa regiao: a semente manda.
extends GdUnitTestSuite

const SEMENTE := 20260915
const OUTRA := 20260916
const REGIAO := 3840.0
const BIOMAS := [
	&"ancient_forest", &"coast", &"canyon", &"floodplain", &"volcanic", &"subterranean"
]


func before_test() -> void:
	RngService.configure(SEMENTE)


func after_test() -> void:
	RngService.configure(SEMENTE)


func _campo(regiao: int, bioma: StringName = &"ancient_forest") -> PackedFloat32Array:
	var camadas := Wilds.table(Wilds.CAMPO, bioma)
	return Wilds.plants(camadas, 0.0, REGIAO, regiao, Wilds.SAL.campo, Wilds.woods())


func _tipos(lista: PackedFloat32Array, passo: int) -> Dictionary:
	var out := {}
	for i in range(0, lista.size(), passo):
		out[int(lista[i])] = true
	return out


func test_a_mesma_semente_e_a_mesma_regiao_dao_o_mesmo_campo() -> void:
	var primeiro := _campo(0)
	assert_int(primeiro.size()).is_greater(0)
	assert_array(_campo(0)).is_equal(primeiro)
	RngService.configure(OUTRA)
	assert_array(_campo(0)).is_not_equal(primeiro)


func test_cada_regiao_e_terra_nova() -> void:
	# Atravessar (Q-135) e chegar a um troco do mundo que ainda nao se viu.
	assert_array(_campo(1)).is_not_equal(_campo(0))
	assert_array(_campo(2)).is_not_equal(_campo(1))


func test_cada_bioma_tem_tabelas_e_da_plantas_diferentes() -> void:
	var vistos := {}
	for bioma in BIOMAS:
		assert_bool(Wilds.CAMPO.has(bioma)).is_true()
		assert_bool(Wilds.HORIZONTE.has(bioma)).is_true()
		assert_bool(Wilds.FAUNA.has(bioma)).is_true()
		vistos[_tipos(_campo(0, bioma), Wilds.PLANTA).keys().hash()] = true
	assert_int(vistos.size()).is_greater(3)
	assert_array(Wilds.table(Wilds.CAMPO, &"nao_existe")).is_equal(Wilds.CAMPO[&"ancient_forest"])


func test_nenhuma_planta_sai_da_regiao_e_ficam_ordenadas_de_tras_para_a_frente() -> void:
	var campo := _campo(0)
	var fundo := 1.0
	for i in range(0, campo.size(), Wilds.PLANTA):
		assert_float(campo[i + 1]).is_between(0.0, REGIAO)
		assert_float(campo[i + 2]).is_less_equal(fundo)
		fundo = campo[i + 2]


func test_a_grelha_da_um_espacamento_minimo_por_camada() -> void:
	# Grelha com tremor: duas do mesmo tipo nunca ficam mais perto do que o
	# passo sem o tremor (e o que tira o carimbo de um campo aleatorio).
	var camadas := Wilds.table(Wilds.CAMPO, &"floodplain")
	var passo: float = camadas[0][1]
	var tipo: int = camadas[0][0]
	var xs: Array[float] = []
	var campo := Wilds.plants([camadas[0]], 0.0, REGIAO, 0, Wilds.SAL.campo, Wilds.woods())
	for i in range(0, campo.size(), Wilds.PLANTA):
		assert_int(int(campo[i])).is_equal(tipo)
		xs.append(campo[i + 1])
	xs.sort()
	for i in range(1, xs.size()):
		assert_float(xs[i] - xs[i - 1]).is_greater_equal(floorf(passo * (1.0 - Wilds.TREMOR.largo)))


func test_o_bosque_tem_clareiras() -> void:
	# A densidade vem de ruido continuo: ha sitios cerrados e sitios vazios.
	var ruido := Wilds.woods()
	var menor := 1.0
	var maior := 0.0
	for x in range(0, int(REGIAO) * 4, 16):
		var d := Wilds.density(ruido, float(x))
		menor = minf(menor, d)
		maior = maxf(maior, d)
	assert_float(maior - menor).is_greater(0.5)


func test_os_pardais_pousam_nos_arbustos_e_ninguem_e_caca() -> void:
	var campo := _campo(0)
	var arbustos := {}
	for i in range(0, campo.size(), Wilds.PLANTA):
		if int(campo[i]) == Wilds.Plant.BUSH:
			arbustos[campo[i + 1]] = true
	var tabela := Wilds.table(Wilds.FAUNA, &"ancient_forest")
	var bichos := Wilds.animals(tabela, 0.0, REGIAO, 0, campo)
	var pardais := 0
	for i in range(0, bichos.size(), Wilds.BICHO):
		if int(bichos[i]) == Wilds.Animal.SONGBIRD:
			pardais += 1
			assert_bool(arbustos.has(bichos[i + 1])).is_true()
	assert_int(pardais).is_greater(0)
	for nome in Wilds.Animal.keys():
		assert_bool(nome in ["RABBIT", "DEER", "BOAR"]).is_false()


func test_o_enxame_muda_de_noite_para_noite_e_e_sempre_o_mesmo() -> void:
	var vistos := {}
	for dia in range(1, 30):
		var e := Wilds.swarm(dia)
		assert_float(e).is_between(Wilds.ENXAME.de, Wilds.ENXAME.ate)
		assert_float(Wilds.swarm(dia)).is_equal(e)
		vistos[snappedf(e, 0.1)] = true
	assert_int(vistos.size()).is_greater(2)
