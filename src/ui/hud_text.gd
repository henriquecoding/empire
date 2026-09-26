# src/ui/hud_text.gd — o texto do painel de quem joga, por chave (§27; GB-27).
#
# O §27 da duas regras de engenharia "agora": um strings.csv so, e "nunca
# componhas frases por concatenacao — usa sempre a chave inteira com
# placeholder; em japones a ordem inverte-se". O GameHud tinha doze frases
# escritas a mao em portugues, e uma troca de idioma deixava-as la.
#
# Puro: recebe os numeros e devolve a frase. O GameHud le o SimLoop e escreve;
# isto so sabe como se diz.
class_name HudText
extends RefCounted

## O aviso de cada sinal da §46 que o painel diz em voz alta, sem numero.
const AVISOS := {
	&"build_completed": &"TOAST_BUILT",
	&"target_marked": &"TOAST_MARKED",
	&"passage_used": &"TOAST_PASSAGE",
	&"wall_breached": &"TOAST_BREACH",
	&"unit_promoted": &"TOAST_PROMOTED",
}
## Os algarismos com zeros a esquerda, como o painel sempre os mostrou.
const DOIS := "%02d"
const TRES := "%03d"
const CEM := 100.0
const PREFIXO_FASE := "PHASE_"


## O nome da fase, em maiusculas. A chave sai do enum do relogio (PHASE_DAWN...),
## e por isso nao ha uma lista de fases escrita duas vezes.
static func phase(fase: int) -> String:
	var nomes := GameClock.Phase.keys()
	var nome: String = nomes[clampi(fase, 0, nomes.size() - 1)]
	return TranslationServer.translate(PREFIXO_FASE + nome).to_upper()


static func clock(dia: int, fase: int, progresso: float) -> String:
	var valores := {"day": DOIS % dia, "phase": phase(fase), "pct": DOIS % int(progresso * CEM)}
	return TranslationServer.translate(&"HUD_CLOCK").format(valores)


static func resources(saco: int, cabem: int, tropas: int, nucleo: int) -> String:
	var valores := {"bag": DOIS % saco, "cap": DOIS % cabem, "troops": DOIS % tropas}
	valores["core"] = TRES % nucleo
	return TranslationServer.translate(&"HUD_RESOURCES").format(valores)


static func goal(noite: bool) -> String:
	return TranslationServer.translate(&"HUD_GOAL_NIGHT" if noite else &"HUD_GOAL_DAY")


static func coins(quantas: int) -> String:
	return TranslationServer.translate(&"TOAST_COIN").format({"n": quantas})
