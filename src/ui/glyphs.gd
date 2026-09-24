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
class_name Glyphs
extends RefCounted

enum Device { KEYBOARD, XBOX, PLAYSTATION }

## O que se diz de cada gesto, pela ordem do rodape.
const ACCOES := [
	&"HINT_MOVE", &"HINT_DROP", &"HINT_ASSUME", &"HINT_MARK", &"HINT_WHEEL", &"HINT_PAUSE"
]

## O botao de cada gesto, por dispositivo, na ordem de ACCOES. Um StringName e
## uma chave a traduzir; uma String e o nome tal e qual.
const BOTOES := {
	Device.KEYBOARD: ["A/D", &"KEY_SPACE", "E", &"KEY_MOUSE_RIGHT", "TAB", "ESC"],
	Device.XBOX: ["D-PAD", "A", "X", "RT", "Y", "START"],
	Device.PLAYSTATION: ["D-PAD", &"PAD_CROSS", &"PAD_SQUARE", "R2", &"PAD_TRIANGLE", "OPTIONS"],
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
	if evento is InputEventKey or evento is InputEventMouseButton:
		return Device.KEYBOARD
	if evento is InputEventJoypadButton:
		return pad_of(nome)
	if evento is InputEventJoypadMotion and absf(evento.axis_value) >= DERIVA:
		return pad_of(nome)
	return anterior


static func pad_of(nome: String) -> Device:
	var baixo := nome.to_lower()
	for marca: String in PLAYSTATION:
		if marca in baixo:
			return Device.PLAYSTATION
	return Device.XBOX


## O rodape inteiro: "BOTAO gesto · BOTAO gesto · ...".
static func hint(dispositivo: Device) -> String:
	var partes := PackedStringArray()
	var botoes: Array = BOTOES[dispositivo]
	for i in ACCOES.size():
		partes.append("%s %s" % [_nome(botoes[i]), TranslationServer.translate(ACCOES[i])])
	return SEPARADOR.join(partes)


static func _nome(botao: Variant) -> String:
	if botao is StringName:
		return String(TranslationServer.translate(botao))
	return String(botao)
