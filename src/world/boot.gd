# src/world/boot.gd — a cena principal (ADR 0005).
#
# Carrega o Registry, fixa o idioma, semeia o RngService, e so depois entrega.
# No dia zero nao ha game.tscn para entregar: o que esta em baixo e o
# placeholder da §68 (onda 2), que existe para o export ter o que mostrar. O
# F0-10 substitui-o pela versao da §70.
#
# O que NAO acontece aqui: decisoes de jogo. Se aparecer uma regra neste
# ficheiro, ela pertence a um sistema de src/sim/.
extends Node2D

## §21/§42: o mundo sai de uma semente, e o ecra de pausa mostra-a. Enquanto
## nao ha menu que a peca, o arranque tira-a do relogio da maquina — e o fluxo
## visual e o unico que ja e livre, por isso nao ha aqui aleatoriedade nenhuma.
@onready var _estado: Label = $DayZero


func _ready() -> void:
	Registry.load_all()
	_fixar_idioma()
	RngService.configure(_semente_de_arranque())
	_estado.text = _resumo()
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


func _resumo() -> String:
	return (
		"Empire · dia zero\nsemente %d · %d recursos em %d tabelas · %s"
		% [
			RngService.world_seed(),
			Registry.total(),
			Registry.tables().size(),
			TranslationServer.get_locale(),
		]
	)
