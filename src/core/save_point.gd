# src/core/save_point.gd — gravar quando quem joga para, e nao so na alvorada (§62).
#
# O autosave era so na alvorada, e fechar o jogo a meio do dia deitava fora ate
# seis minutos de partida (auditoria de 26/09, D11; Game Accessibility
# Guidelines, "save anytime"). Grava-se tambem ao pausar e ao fechar a janela.
#
# So de dia. A noite tem estado que o save nao leva — o intervalo da invocacao
# armado, a oferta a meio, o que a noite ja levou (NightTally) — e retomar a meio
# dela era retomar outra noite. De noite fica o save da alvorada, como antes.
class_name SavePoint
extends RefCounted


## Se a partida se pode gravar agora: ha partida, nao acabou, e e de dia.
static func allowed() -> bool:
	if SimLoop.state == null or SimLoop.king_id == UnitSystem.NENHUM or Defeat.happened():
		return false
	return int(ClockService.clock.current_phase()) < int(GameClock.Phase.DUSK)


## Grava no slot mais antigo e devolve qual, ou -1 se agora nao se grava.
static func now() -> int:
	if not allowed():
		return -1
	return SaveService.autosave(SimLoop.state, RngService.snapshot(), SimLoop.world())
