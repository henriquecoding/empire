# tools/prova_save.gd — corre o jogo, deixa a alvorada gravar, e volta a abrir.
#
# Fora do jogo: `tools/` esta no exclude_filter do export. O que isto prova nao
# e o save — a suite ja o prova — e o ARRANQUE: que a boot entrega uma partida
# retomada e nao uma partida nova (ADR 0005, F1-14).
extends Node

const JOGO := "res://scenes/game.tscn"
const PASSO := 1.0 / 30.0
const DIAS := 3.0


func _ready() -> void:
	add_child(load(JOGO).instantiate())
	var dia_s: float = (Registry.entry(&"economy", &"clock") as ClockData).day_seconds
	for _i in int(dia_s * DIAS / PASSO):
		if not SimLoop.running():
			break
		SimLoop.step(PASSO)
	print(
		(
			"prova: dia %d · slot mais recente %d · tropas %d"
			% [SimLoop.state.day, SaveService.latest_slot(), SimLoop.units.count()]
		)
	)
	get_tree().quit()
