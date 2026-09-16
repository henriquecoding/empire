# src/ui/hud.gd — o painel do greybox, e NAO o HUD do §24.
#
# O §24 e explicito: um unico elemento de HUD permanente — o relogio da divida —
# e tudo o resto e o mundo a dizer-te as coisas. Isto e outra coisa: e o
# instrumento que permite jogar e MEDIR um greybox antes de existir arte que
# diga o que a barra diz (§67, GB-03). Desaparece quando a arte chegar.
#
# Le e nao escreve. Nenhuma linha daqui toca no estado: o que o painel mostra
# errado e um defeito da simulacao, nunca do painel (§45).
class_name Hud
extends Label

const FASES := ["ALVORADA", "MANHA", "MEIO-DIA", "TARDE", "CREPUSCULO", "NOITE"]
const PERCENTAGEM := 100.0
const TECLAS := (
	"A/D andar · ESPACO largar moeda (manter: em continuo) · E passagem"
	+ " · BOTAO DIREITO marcar · TAB estado · ESC pausa"
)


func _process(_delta: float) -> void:
	if SimLoop.state == null:
		text = ""
		return
	text = "%s\n%s\n%s" % [_relogio(), _campo(), TECLAS]


func _relogio() -> String:
	var relogio := ClockService.clock
	var fase := int(relogio.current_phase())
	return (
		"Dia %d · %s %d%%%s"
		% [relogio.day, FASES[fase], int(relogio.phase_progress() * PERCENTAGEM), _paragem()]
	)


## §10: "se cair, cai a partida". E a unica coisa que este painel diz que nao e
## uma contagem — porque e a unica que acaba o jogo.
func _paragem() -> String:
	if SimLoop.builds.fallen(BuildSlot.NUCLEO):
		return "   [O CASTELO-ARVORE CAIU — A PARTIDA ACABOU]"
	return "" if SimLoop.running() else "   [EM PAUSA]"


func _campo() -> String:
	return (
		"saco %d · tropas %d/%d · nucleo %d · moedas no chao %d · criaturas %d · %s"
		% [
			_saco(),
			_meus(),
			SimLoop.units.count(),
			_nucleo(),
			SimLoop.coins.count(),
			SimLoop.creatures.count(),
			_podridao(),
		]
	)


func _nucleo() -> int:
	for vaga in SimLoop.builds.slots:
		if vaga.kind == BuildSlot.NUCLEO:
			return vaga.health
	return 0


func _saco() -> int:
	var i := SimLoop.units.index_of(SimLoop.king_id)
	return SimLoop.units.carried_coins[i] if i != UnitSystem.NENHUM else 0


func _meus() -> int:
	var n := 0
	for i in SimLoop.units.count():
		if SimLoop.units.owners[i] != RecruitSystem.SEM_DONO and SimLoop.units.alive(i):
			n += 1
	return n


func _podridao() -> String:
	var rot := SimLoop.night.rot
	if not rot.active():
		return "Podridao recuada"
	return "Podridao a %d px, massa %d" % [int(rot.position_x()), int(rot.mass())]
