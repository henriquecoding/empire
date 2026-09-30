# tests/fauna_test.gd — os bichos de cenario: fogem do rei e voltam a casa.
extends GdUnitTestSuite

const SEMENTE := 20260915
const PASSO := 1.0 / 30.0
const REGIAO := 3840.0


func before_test() -> void:
	RngService.configure(SEMENTE)


func after_test() -> void:
	RngService.configure(SEMENTE)


func _um(tipo: int, x: float, v: float = 0.3) -> Fauna:
	var f := Fauna.new()
	f.populate(PackedFloat32Array([tipo, x, v]), REGIAO)
	return f


func _correr(f: Fauna, segundos: float, rei_x: float, rei_aqui: bool = true) -> void:
	for _i in int(segundos / PASSO):
		f.tick(PASSO, rei_x, rei_aqui)


func test_o_pardal_foge_do_rei_e_volta_ao_arbusto_quando_ele_se_vai() -> void:
	var f := _um(Wilds.Animal.SONGBIRD, 1000.0)
	var p := f.bichos[0]
	var casa := p.home
	_correr(f, 1.0, 960.0)
	assert_int(p.state).is_equal(Fauna.State.FLEE)
	assert_float(p.y).is_less(casa.y)
	assert_float(p.x).is_greater(casa.x)
	_correr(f, 30.0, -5000.0)
	assert_int(p.state).is_equal(Fauna.State.IDLE)
	assert_vector(Vector2(p.x, p.y)).is_equal(casa)


func test_o_pardal_nao_volta_enquanto_o_rei_la_esta() -> void:
	var f := _um(Wilds.Animal.SONGBIRD, 1000.0)
	_correr(f, 20.0, 1000.0)
	assert_int(f.bichos[0].state).is_not_equal(Fauna.State.IDLE)


func test_o_rei_debaixo_de_terra_nao_assusta_ninguem() -> void:
	var f := _um(Wilds.Animal.CROW, 1000.0)
	_correr(f, 1.0, 1000.0, false)
	assert_int(f.bichos[0].state).is_not_equal(Fauna.State.FLEE)


func test_o_corvo_espantado_levanta_voo_e_pousa_longe() -> void:
	var f := _um(Wilds.Animal.CROW, 1000.0, 0.1)
	var c := f.bichos[0]
	_correr(f, 0.5, 990.0)
	assert_float(c.y).is_less(float(Band.GROUND_LINE))
	_correr(f, 20.0, -5000.0)
	assert_float(c.y).is_equal(float(Band.GROUND_LINE))
	assert_float(absf(c.x - 990.0)).is_greater(Fauna.ESPANTO[Wilds.Animal.CROW][0])


func test_quem_paira_fica_perto_de_casa() -> void:
	var f := _um(Wilds.Animal.BUTTERFLY, 500.0)
	for _i in 300:
		f.tick(PASSO, 0.0, false)
		var b := f.bichos[0]
		assert_float(absf(b.x - b.home.x)).is_less_equal(
			Fauna.OITO[Wilds.Animal.BUTTERFLY][0] + 0.01
		)


func test_o_bando_voa_no_ceu() -> void:
	var lista := PackedFloat32Array()
	for i in 6:
		lista.append_array(PackedFloat32Array([Wilds.Animal.BIRD, 600.0 + i * 20.0, i / 6.0]))
	var f := Fauna.new()
	f.populate(lista, REGIAO)
	assert_int(f.bando.size()).is_equal(6)
	_correr(f, 10.0, 0.0, false)
	for b in f.bichos:
		assert_float(b.y).is_less(float(Band.HORIZON))


func test_de_dia_nao_ha_pirilampos_e_de_noite_nao_ha_pardais() -> void:
	assert_float(Fauna.presence(Wilds.Animal.FIREFLY, 0.0)).is_equal(0.0)
	assert_float(Fauna.presence(Wilds.Animal.FIREFLY, 1.0)).is_equal(1.0)
	assert_float(Fauna.presence(Wilds.Animal.SONGBIRD, 1.0)).is_equal(0.0)
	assert_float(Fauna.presence(Wilds.Animal.BAT, 0.0)).is_equal(1.0)


func test_ha_um_perfil_por_bicho() -> void:
	var n := Wilds.Animal.size()
	assert_int(Fauna.MODO.size()).is_equal(n)
	assert_int(Fauna.TURNO.size()).is_equal(n)
	assert_int(Fauna.ALTURA.size()).is_equal(n)
	assert_int(Fauna.FAIXA.size()).is_equal(n)
	assert_int(FaunaArt.SPRITES.size()).is_equal(n)
	assert_int(FaunaArt.CORES.size()).is_equal(n)
	for tipo in Wilds.Plant.values():
		assert_bool(FloraArt.SPRITES.has(tipo)).is_true()


func test_a_faixa_de_cada_bicho_e_a_da_luz_que_o_ilumina() -> void:
	assert_int(Fauna.FAIXA[Wilds.Animal.BAT]).is_equal(Band.Kind.UNDERGROUND)
	assert_int(Fauna.FAIXA[Wilds.Animal.BIRD]).is_equal(Band.Kind.AERIAL)
	assert_int(Fauna.FAIXA[Wilds.Animal.SONGBIRD]).is_equal(Band.Kind.SURFACE)


## Q-173: o corvo das terras a oeste da regiao anda por la, dentro dos limites dados — e
## nao e puxado para a regiao, nem passa da beira.
func test_o_corvo_das_terras_anda_entre_os_limites() -> void:
	var f := Fauna.new()
	var limites := Vector2(-2000.0, REGIAO)
	f.populate(PackedFloat32Array([Wilds.Animal.CROW, -1990.0, 0.3]), REGIAO, limites)
	var menor := INF
	var maior := -INF
	for _i in int(60.0 / PASSO):
		f.tick(PASSO, 0.0, false)
		menor = minf(menor, f.bichos[0].x)
		maior = maxf(maior, f.bichos[0].x)
	assert_float(menor).is_greater_equal(limites.x)
	assert_float(maior).is_less(limites.x + Fauna.PE.roda * 2.0)
