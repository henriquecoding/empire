# tests/toque_camara_test.gd — o dedo no mundo e a camara (ADR 0047, UX-02).
#
# Arrastar no mundo e a camara livre do §24 ao toque: o dedo agarra o mundo, e quando
# sai a camara volta sozinha nos mesmos 2 s. Os eventos constroem-se (ADR 0009).
extends GdUnitTestSuite

const PASSO := 1.0 / 60.0
const VISTA := 1280.0


func _rig() -> CameraRig:
	var rig: CameraRig = auto_free(CameraRig.new())
	add_child(rig)
	rig.view_width = VISTA
	return rig


func _alvo(x: float) -> Node2D:
	var n: Node2D = auto_free(Node2D.new())
	add_child(n)
	n.global_position = Vector2(x, 0.0)
	return n


func _assentar(rig: CameraRig, segundos: float = 5.0) -> void:
	for _i in int(segundos / PASSO):
		rig.advance(PASSO)


## Agarrar o mundo: enquanto o dedo esta pousado a camara fica onde ele a pos, e so
## volta quando ele sai — nos mesmos 2 s da camara livre do §24.
func test_o_dedo_arrasta_a_camara_e_largar_devolve_a_em_dois_segundos() -> void:
	var rig := _rig()
	var alvo := _alvo(1000.0)
	rig.follow(alvo)
	_assentar(rig)
	var pousada := rig.position.x
	var dados: CameraData = Registry.entry(&"camera", &"default")
	rig.drag(150.0)
	rig.advance(PASSO)
	assert_float(rig.position.x).is_equal(pousada + 150.0)
	_assentar(rig, 1.0)
	assert_float(rig.position.x).override_failure_message("o dedo pousado nao segura").is_equal(
		pousada + 150.0
	)
	rig.let_go()
	for _i in int(dados.free_return_seconds / PASSO) + 1:
		rig.advance(PASSO)
	assert_float(rig.position.x).is_equal(pousada)


## Um dedo nao leva a camara mais longe do que um ecra: alem disso o largar demorava a
## voltar a ver-se mexer, porque a camara ja estava presa no limite da regiao.
func test_o_dedo_nao_leva_a_camara_mais_longe_do_que_um_ecra() -> void:
	var rig := _rig()
	var alvo := _alvo(5000.0)
	rig.follow(alvo)
	_assentar(rig)
	var pousada := rig.position.x
	rig.drag(9000.0)
	rig.advance(PASSO)
	assert_float(rig.position.x - pousada).is_less_equal(VISTA)


## O motor transforma o toque num rato com device -1. Esse rato nao esta "dentro da
## janela": se estivesse, o ultimo dedo pousado na alavanca deixava a camara a fugir
## para a margem esquerda.
func test_o_rato_emulado_do_toque_nao_liga_a_margem() -> void:
	var rig := _rig()
	var emulado := InputEventMouseMotion.new()
	emulado.device = InputEvent.DEVICE_ID_EMULATION
	rig._input(emulado)
	assert_bool(rig._rato_dentro).is_false()
	var rato := InputEventMouseMotion.new()
	rig._input(rato)
	assert_bool(rig._rato_dentro).is_true()
	rig._input(InputEventScreenTouch.new())
	assert_bool(rig._rato_dentro).is_false()


func test_a_camara_atende_pelo_grupo() -> void:
	var rig := _rig()
	assert_bool(rig.is_in_group(CameraRig.GRUPO)).is_true()
