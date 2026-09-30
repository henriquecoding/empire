# src/world/boot.gd — a cena principal (ADR 0005).
#
# Carrega o Registry, fixa o idioma, e so depois entrega. Ate agora nao havia
# game.tscn para entregar e o que estava aqui era o placeholder da §68; o F0-10
# fecha isso, e este ficheiro volta a ser o que a ADR 0005 diz que ele e: o
# arranque, e mais nada.
#
# O que NAO acontece aqui: decisoes de jogo. Se aparecer uma regra neste
# ficheiro, ela pertence a um sistema de src/sim/.
extends Node2D

const JOGO := "res://scenes/game.tscn"

@onready var _estado: Label = $DayZero


func _ready() -> void:
	Registry.load_all()
	_fixar_idioma()
	_mostrar()
	# Uma linha no arranque, e uma so. E o recibo do export: o CI corre o
	# binario com --quit-after e fica com isto no registo, em vez de "nao
	# rebentou", que nao diz se chegou a carregar alguma coisa.
	print(_estado.text.replace("\n", " · ") + " · " + disk_line())
	# A troca e adiada um frame de proposito: trocar de cena dentro do _ready()
	# da arvore que esta a nascer e o caminho mais curto para um no a meio de
	# entrar e ja fora dela.
	call_deferred(&"_entregar")


## §27: o jogo tem dois idiomas e o texto vive todo em data/i18n/strings.csv.
## O escolhido na pausa manda (GB-28); sem escolha, o do sistema quando e um dos
## dois, e senao PT-PT.
func _fixar_idioma() -> void:
	TranslationServer.set_locale(language(Preferences.shared().text(Preferences.LANGUAGE)))


static func language(escolhido: String) -> String:
	if escolhido in Preferences.LANGUAGES:
		return escolhido
	return "en" if OS.get_locale_language() == "en" else "pt_PT"


## O estado do disco no recibo: o save mais recente e se ha legado a espera. E o que
## o teste de fumo le para saber se um recomeco do zero persistiu no browser (Q-164):
## o recibo da cena de jogo sai igual num jogo retomado, num herdado e num limpo.
static func disk_line() -> String:
	var slot := SaveService.latest_slot()
	var save := "save: nenhum"
	if slot >= 0:
		save = "save: dia %d" % int(SaveService.summaries()[slot].get(&"day", 0))
	return "%s · legado: %s" % [save, "nao" if LegacyStore.pending().is_empty() else "sim"]


func _entregar() -> void:
	get_tree().change_scene_to_file(JOGO)


func _mostrar() -> void:
	_estado.text = (
		"Empire · semente por semear · %d recursos em %d tabelas · %s"
		% [Registry.total(), Registry.tables().size(), TranslationServer.get_locale()]
	)
