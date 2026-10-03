# tests/toque_combate_test.gd — um toque no ecra nao e um golpe (ADR 0047, ADR 0045).
extends GdUnitTestSuite

const STEP := 1.0 / 60.0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261001)
	Greybox.build()
	SimLoop.step(STEP)


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


## ADR 0047: o motor converte cada toque num clique esquerdo com device -1, e o attack
## tem o botao esquerdo. Sem o filtro, cada toque no ecra do telemovel era um golpe.
func test_um_toque_no_ecra_nao_e_um_ataque() -> void:
	MonarchWatch.begin(&"monarch")
	var who := SimLoop.king_id
	HeroWatch.tick(0.0)
	var entrada: CombatInput = auto_free(CombatInput.new())
	add_child(entrada)
	SimLoop.intents.clear()
	entrada._unhandled_input(_clique_esquerdo(InputEvent.DEVICE_ID_EMULATION))
	assert_int(SimLoop.intents.pending()).is_equal(0)
	entrada._unhandled_input(_clique_esquerdo(InputEvent.DEVICE_ID_MOUSE))
	assert_int(SimLoop.intents.pending()).is_equal(1)
	assert_int(int(SimLoop.intents.take()[0][1][&"who"])).is_equal(who)


## Um clique esquerdo de `dispositivo`. O rato a serio e o DEVICE_ID_MOUSE do motor (4.7):
## e por esse que o InputMap reconhece o attack, e o clique do toque e o DEVICE_ID_EMULATION.
func _clique_esquerdo(dispositivo: int) -> InputEventMouseButton:
	var clique := InputEventMouseButton.new()
	clique.button_index = MOUSE_BUTTON_LEFT
	clique.pressed = true
	clique.device = dispositivo
	return clique
