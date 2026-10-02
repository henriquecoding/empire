# src/ui/glyphs.gd — os botoes da mao que esta a jogar (§24, §26; GB-15).
#
# O §26 poe na lista do Steam Deck Verified: "os glifos no ecra correspondem ao
# dispositivo ativo — implementar: trocar atlas de icones por Input.get_joy_name".
# Nao ha atlas nenhum (art/ nao e deste ticket, AGENTS.md regra 9), e a fonte por
# omissao do motor nao tem ✕ ▢ △ nem setas — medido, e no browser nao ha fonte de
# sistema que os traga. Por isso sao NOMES, ate o atlas existir: A, X, Y, RT num
# comando Xbox ou num Steam Deck; cruz, quadrado, triangulo, R2 num PlayStation.
#
# Os botoes sao os do mapa de comando do §24, pela ordem dele. As palavras do que
# cada um faz sao chaves de data/i18n/strings.csv; os nomes de botao que nao
# mudam de lingua (A, RT, TAB) ficam aqui, como o §24 os escreve.
#
# O toque e o quarto dispositivo (ADR 0047): os nomes dele sao os dos botoes que se
# desenham no ecra, e o rodape de teclas esconde-se, porque os botoes dizem o que fazem.
class_name Glyphs
extends RefCounted

enum Device { KEYBOARD, XBOX, PLAYSTATION, TOUCH }

## O que se diz de cada gesto, pela ordem do rodape.
const ACCOES := [
	&"HINT_MOVE",
	&"HINT_DROP",
	&"HINT_ASSUME",
	&"HINT_MARK",
	&"HINT_WHEEL",
	&"HINT_PAUSE",
	&"HINT_ATTACK"
]

## O botao de cada gesto, por dispositivo, na ordem de ACCOES. Um StringName e
## uma chave a traduzir; uma String e o nome tal e qual.
const BOTOES := {
	Device.KEYBOARD: ["A/D", &"KEY_SPACE", "E", &"KEY_SKILL", "TAB", "ESC", &"KEY_ATTACK"],
	Device.XBOX: ["D-PAD", "A", "X", "RT", "Y", "START", "RB"],
	Device.PLAYSTATION:
	["D-PAD", &"PAD_CROSS", &"PAD_SQUARE", "R2", &"PAD_TRIANGLE", "OPTIONS", "R1"],
	Device.TOUCH:
	[
		&"TOUCH_STICK",
		&"TOUCH_DROP",
		&"TOUCH_ASSUME",
		&"TOUCH_SKILL",
		&"TOUCH_WHEEL",
		&"TOUCH_PAUSE",
		&"TOUCH_ATTACK",
	],
}

## Os nomes que o motor da a um comando PlayStation. O resto — o Steam Deck, o
## comando virtual do Steam, um Xbox, um comando sem nome — e A/B/X/Y, que e o
## que o §24 escreve primeiro.
const PLAYSTATION := ["playstation", "dualsense", "dualshock", "sony", "ps3", "ps4", "ps5"]

## Um stick abaixo disto esta a derivar, e nao na mao de ninguem.
const DERIVA := 0.5
const SEPARADOR := "  ·  "


## O dispositivo depois deste evento. `nome` e o Input.get_joy_name() do comando
## que o mandou — vem de fora para que isto se possa testar sem um comando.
static func device_of(evento: InputEvent, anterior: Device, nome: String) -> Device:
	if evento is InputEventScreenTouch or evento is InputEventScreenDrag:
		return Device.TOUCH
	if emulated(evento):
		return anterior
	if evento is InputEventKey or evento is InputEventMouseButton:
		return Device.KEYBOARD
	if evento is InputEventJoypadButton:
		return pad_of(nome)
	if evento is InputEventJoypadMotion and absf(evento.axis_value) >= DERIVA:
		return pad_of(nome)
	return anterior


## O motor transforma cada toque num clique de rato com device -1, e manda-o ANTES do
## toque (medido no 4.7.2; ADR 0047). Esse clique e o que faz os menus responderem ao
## dedo; para o jogo nao e um rato: nao ataca, nao mexe a camara, nao troca os glifos.
static func emulated(evento: InputEvent) -> bool:
	return evento is InputEventMouse and evento.device == InputEvent.DEVICE_ID_EMULATION


## A mao com que se comeca: um comando ligado, um ecra tactil, ou o teclado. Um Steam
## Deck nao tem teclado, e um telemovel tambem nao.
static func initial() -> Device:
	var comandos := Input.get_connected_joypads()
	if not comandos.is_empty():
		return pad_of(Input.get_joy_name(comandos[0]))
	return Device.TOUCH if DisplayServer.is_touchscreen_available() else Device.KEYBOARD


static func pad_of(nome: String) -> Device:
	var baixo := nome.to_lower()
	for marca: String in PLAYSTATION:
		if marca in baixo:
			return Device.PLAYSTATION
	return Device.XBOX


## O rodape inteiro: "BOTAO gesto · BOTAO gesto · ...". Sem `marca` o gatilho
## direito nao aparece: so uma classe de arco marca alvos (Q-086).
static func hint(
	dispositivo: Device, marca: bool = true, ability: StringName = &"HINT_MARK"
) -> String:
	if dispositivo == Device.TOUCH:
		return ""
	var partes := PackedStringArray()
	var botoes: Array = BOTOES[dispositivo]
	for i in ACCOES.size():
		if ACCOES[i] == &"HINT_MARK" and not marca:
			continue
		var key: StringName = ability if ACCOES[i] == &"HINT_MARK" else ACCOES[i]
		partes.append("%s %s" % [_nome(botoes[i]), TranslationServer.translate(key)])
	return SEPARADOR.join(partes)


static func _nome(botao: Variant) -> String:
	if botao is StringName:
		return String(TranslationServer.translate(botao))
	return String(botao)
