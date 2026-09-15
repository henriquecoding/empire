# src/world/game.gd — a cena de jogo (F0-10, ADR 0005).
#
# A ADR 0005 escreve o contrato: a boot.tscn carrega o Registry, o idioma e o
# save, decide que game.tscn instanciar, e so depois entrega. Isto e o que ela
# entrega, e ate agora nao existia — "nao ha cena de jogo" era a primeira linha
# do docs/POR_FAZER.md.
#
# O que este ficheiro faz e curto de proposito: semeia, manda o Greybox montar a
# regiao, aponta a camara ao monarca e liga o tremor de ecra do §24. Nenhuma
# regra de jogo passa por aqui; se aparecer uma, pertence a um sistema de
# src/sim/ (a mesma nota que a boot.gd ja tinha).
class_name Game
extends Node2D

## §24: "so para o muro a cair e o Ariete a acertar. Nunca para golpes normais.
## Amplitude max. 4 px, e com opcao de desligar (§26)."
const TREMOR_PX := 4.0
const TREMOR_S := 0.25
const MEIO := 0.5
## `godot --path . -- --novo` comeca uma partida do zero mesmo havendo save.
const NOVO := "--novo"

var _tremor: float = 0.0

@onready var _camara: CameraRig = $CameraRig
@onready var _mundo: Node2D = $Mundo
@onready var _monarca: Node2D = $Monarca


func _ready() -> void:
	Registry.load_all()
	if not _retomar():
		SimLoop.start(_semente())
		Greybox.build()
	_camara.set_region(0.0, SimLoop.world_width)
	# Poe o marcador onde o monarca esta ANTES de o entregar a camara: o follow()
	# assenta a camara na posicao do alvo, e um alvo ainda na origem punha o
	# primeiro segundo de cada partida a viajar da borda do mapa ate ao castelo.
	_seguir()
	_camara.follow(_monarca)
	EventBus.wall_breached.connect(_no_rompimento)
	EventBus.building_destroyed.connect(_no_desabamento)
	print(_recibo())


func _process(delta: float) -> void:
	_seguir()
	if _tremor <= 0.0:
		return
	_tremor = maxf(0.0, _tremor - delta)
	var forca := TREMOR_PX * (_tremor / TREMOR_S)
	_mundo.position = Vector2(RngService.float_range(RngService.VISUAL, -forca, forca), 0.0)


## A semente da partida. O §42 manda mostra-la no ecra e deixar copiar — o
## Inspector fa-lo — e e o melhor instrumento de depuracao que ha de graca.
func _semente() -> int:
	return Time.get_unix_time_from_system() as int


## Retoma o autosave mais recente, se houver (ADR 0005: a boot carrega o save e
## so depois entrega). Devolve falso quando nao ha nada para retomar.
##
## Duas razoes para comecar de novo mesmo havendo save: `--novo` na linha de
## comandos, que e o que um teste de greybox precisa para repetir uma noite; e um
## nucleo em ruina, porque retomar uma partida ja perdida nao e retomar nada.
func _retomar() -> bool:
	var slot := SaveService.latest_slot()
	if slot < 0 or OS.get_cmdline_user_args().has(NOVO):
		return false
	var estado := SaveService.restore(slot)
	if estado == null:
		return false
	SimLoop.resume(estado, SaveService.restore_rng(slot))
	Greybox.region()
	SimLoop.load_world(SaveService.restore_world(slot))
	if SimLoop.builds.fallen(BuildSlot.NUCLEO) or SimLoop.units.count() == 0:
		return false
	return true


## A camara segue um Node2D (§59) e o monarca e uma LINHA DE COLUNAS, nao um no
## (§52). O no "Monarca" e a ponte: um no vazio que copia o x da coluna, uma vez
## por frame, e mais nada.
func _seguir() -> void:
	var i := SimLoop.units.index_of(SimLoop.king_id)
	if i == UnitSystem.NENHUM:
		return
	var faixa := int(SimLoop.units.bands[i])
	_monarca.position = Vector2(SimLoop.units.xs[i], WorldPalette.ground_of(faixa))


func _no_rompimento(_wall_id: int) -> void:
	_tremor = TREMOR_S


## §10, numa frase: "se cair, cai a partida". O §46 nao tem sinal de derrota e
## inventar um era quebrar a regra 7 do AGENTS.md — o que ha e o mundo, e o
## mundo diz-o: o nucleo em ruina. O relogio para e a entrada deixa de responder.
func _no_desabamento(building_id: int, _x: float) -> void:
	var i := SimLoop.builds.index_of(building_id)
	if i == UnitSystem.NENHUM or SimLoop.builds.slots[i].kind != BuildSlot.NUCLEO:
		return
	_tremor = TREMOR_S
	SimLoop.set_paused(true)
	$Entrada.set_process_unhandled_input(false)


## Uma linha no arranque, e uma so. E o recibo do export: o CI corre o binario
## com --quit-after e fica com isto no registo, em vez de "nao rebentou".
func _recibo() -> String:
	return (
		"Empire · semente %d · regiao %d px · %d sitios de obra · %d em campo"
		% [
			RngService.world_seed(),
			int(SimLoop.world_width),
			SimLoop.builds.count(),
			SimLoop.units.count(),
		]
	)
