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
	print(_estado.text.replace("\n", " · "))
	# A troca e adiada um frame de proposito: trocar de cena dentro do _ready()
	# da arvore que esta a nascer e o caminho mais curto para um no a meio de
	# entrar e ja fora dela.
	call_deferred(&"_entregar")


## §27: o jogo tem dois idiomas e o texto vive todo em data/i18n/strings.csv.
## Respeita o do sistema quando e um dos dois; senao, PT-PT.
func _fixar_idioma() -> void:
	var sistema := OS.get_locale_language()
	TranslationServer.set_locale("en" if sistema == "en" else "pt_PT")


func _entregar() -> void:
	get_tree().change_scene_to_file(JOGO)


func _mostrar() -> void:
	_estado.text = (
		"Empire · semente por semear · %d recursos em %d tabelas · %s"
		% [Registry.total(), Registry.tables().size(), TranslationServer.get_locale()]
	)
