# src/world/boot.gd — a cena principal (ADR 0005).
#
# Carrega o Registry, fixa o idioma, semeia, e so depois entrega. No dia zero
# nao ha game.tscn para entregar: o que esta em baixo e o placeholder da §68
# (onda 2), que o F0-10 substitui pela versao da §70.
#
# O que NAO acontece aqui: decisoes de jogo. Se aparecer uma regra neste
# ficheiro, ela pertence a um sistema de src/sim/.
extends Node2D

const FASES := ["DAWN", "MORNING", "NOON", "AFTERNOON", "DUSK", "NIGHT"]
## Nao e balanceamento: e a escala de uma percentagem no ecra (§47).
const PERCENTAGEM := 100.0

@onready var _estado: Label = $DayZero


func _ready() -> void:
	Registry.load_all()
	_fixar_idioma()

	EventBus.day_started.connect(_no_dia)
	EventBus.phase_changed.connect(_na_fase)

	SimLoop.start(_semente_de_arranque())
	_mostrar()
	# Uma linha no arranque, e uma so. E o recibo do export: o CI corre o
	# binario com --quit-after e fica com isto no registo, em vez de "nao
	# rebentou", que nao diz se chegou a carregar alguma coisa.
	print(_estado.text.replace("\n", " · "))


## §27: o jogo tem dois idiomas e o texto vive todo em data/i18n/strings.csv.
## Respeita o do sistema quando e um dos dois; senao, PT-PT.
func _fixar_idioma() -> void:
	var sistema := OS.get_locale_language()
	TranslationServer.set_locale("en" if sistema == "en" else "pt_PT")


func _semente_de_arranque() -> int:
	return Time.get_unix_time_from_system() as int


func _no_dia(_dia: int) -> void:
	_mostrar()


func _na_fase(_de: int, _para: int) -> void:
	_mostrar()


func _mostrar() -> void:
	var relogio := ClockService.clock
	_estado.text = (
		"Empire · dia %d · %s %d%%\n%s"
		% [
			relogio.day,
			FASES[int(relogio.current_phase())],
			int(relogio.phase_progress() * PERCENTAGEM),
			_resumo(),
		]
	)


func _resumo() -> String:
	return (
		"semente %d · %d recursos em %d tabelas · %s"
		% [
			RngService.world_seed(),
			Registry.total(),
			Registry.tables().size(),
			TranslationServer.get_locale(),
		]
	)
