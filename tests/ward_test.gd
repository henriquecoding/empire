# tests/ward_test.gd — o Sino de Vigia afasta o Zelador (§75; Q-100, o dono a
# 29/09/2026): "uma construcao que emita algo que impeca que ele avance, e esse
# recurso vai diminuindo conforme o poder da podridao se torna mais forte".
extends GdUnitTestSuite

const NUCLEO := 2000.0
const SINO_X := 3200.0

var estado: GameState
var obras: BuildSystem
var sino: BuildSlot
var moedas: CoinSystem


func before_test() -> void:
	estado = GameState.new()
	obras = BuildSystem.new()
	moedas = CoinSystem.new(SimFactory.curve())
	var dados := Registry.entry(&"buildings", Ward.SINO) as BuildingData
	sino = obras.post(Greybox.slot_of(dados, SINO_X))


func _levantar() -> void:
	sino.state = BuildSlot.State.SCAFFOLD
	obras.tick(sino.works[0] + 1.0, _com_quem_trabalha())


func _com_quem_trabalha() -> UnitSystem:
	var u := UnitSystem.new()
	u.spawn(estado, Registry.entry(&"units", &"vagrant"), 1, SINO_X)
	return u


func _raio() -> float:
	return float(sino.effects[&"ward_radius"])


func test_acabado_de_levantar_nasce_cheio() -> void:
	_levantar()
	assert_int(sino.state).is_equal(BuildSlot.State.DONE)
	assert_float(sino.charge).is_equal(Ward.cap(sino))
	assert_bool(Ward.active(sino)).is_true()


func test_com_carga_o_zelador_nao_entra_e_e_empurrado_para_fora() -> void:
	_levantar()
	var fora := SINO_X + _raio() + 100.0
	assert_float(Ward.hold(obras, fora, fora - 150.0, NUCLEO)).is_equal(SINO_X + _raio())
	assert_float(Ward.hold(obras, fora, fora - 50.0, NUCLEO)).is_equal(fora - 50.0)
	sino.charge = 0.0
	assert_float(Ward.hold(obras, fora, fora - 150.0, NUCLEO)).is_equal(fora - 150.0)


func test_o_zelador_para_a_porta_do_sino() -> void:
	_levantar()
	var zelador := SimFactory.tender()
	zelador.dusk(SINO_X + 1500.0)
	for _t in 3000:
		zelador.tick(1.0 / 30.0, NUCLEO + 300.0, NUCLEO, 240.0, obras)
	assert_float(zelador.x).is_equal_approx(SINO_X + _raio(), 0.01)


func test_a_carga_desce_mais_quanto_mais_tarde() -> void:
	_levantar()
	var cheio := sino.charge
	Ward.dawn(obras, 2)
	var cedo := cheio - sino.charge
	sino.charge = cheio
	Ward.dawn(obras, 20)
	assert_float(cheio - sino.charge).is_greater(cedo)


func test_moedas_largadas_carregam_ate_ao_teto() -> void:
	_levantar()
	sino.charge = 0.0
	for _k in 20:
		var id := moedas.drop(estado, SINO_X, Band.Kind.SURFACE, 1, 0.0)
		moedas.settled[moedas.index_of(id)] = 1
	obras.absorb(moedas)
	assert_float(sino.charge).is_equal(Ward.cap(sino))
	assert_int(moedas.count()).is_greater(0)


func test_a_carga_vai_no_save() -> void:
	sino.charge = 3.5
	var copia := BuildSlot.new()
	copia.from_dict(sino.to_dict())
	assert_float(copia.charge).is_equal(3.5)
