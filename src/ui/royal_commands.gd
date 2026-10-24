class_name RoyalCommands
extends RefCounted

enum Family { BUILD, RECRUIT, CRAFT, BOOST, TRAVEL, HEIR }

const FAMILIES := [&"build", &"recruit", &"craft", &"crown", &"expedition", &"heir"]
const NAMES := [
	&"WHEEL_BUILD", &"WHEEL_RECRUIT", &"WHEEL_CRAFT", &"WHEEL_BOOST", &"WHEEL_TRAVEL", &"WHEEL_HEIR"
]
const HELP := [
	&"WHEEL_BUILD_HELP",
	&"WHEEL_RECRUIT_HELP",
	&"WHEEL_CRAFT_HELP",
	&"",
	&"WHEEL_TRAVEL_HELP",
	&"WHEEL_HEIR_HELP"
]


static func describe(index: int, device: Glyphs.Device) -> String:
	var context := GuideHints.context(device)
	var key := String(context.key)
	var matches := false
	match index:
		0:
			matches = key.begins_with("CONTEXT_BUILD") or key.begins_with("CONTEXT_SEAT")
		1:
			matches = key == "CONTEXT_RECRUIT"
		2:
			matches = key.begins_with("CONTEXT_TRAIN") or key.begins_with("CONTEXT_CONVERT")
		Family.HEIR:
			matches = key.begins_with("CONTEXT_HEIR")
	return context.text if matches else TranslationServer.translate(HELP[index])


## Construir/recrutar/oficios continuam a ser locais e pagos pela moeda no mundo.
## A roda revela o contexto; nunca cria obras nem debita a bolsa ao abrir um setor.
static func choose(index: int, node: Node, device: Glyphs.Device) -> void:
	if index < 0 or index >= FAMILIES.size() or not Assume.king():
		return
	if index == 0 and SiteSheet.asks():
		node.get_tree().call_group(&"site_sheet", &"open")
	elif index == Family.TRAVEL and TravelWatch.at_gate():
		node.get_tree().call_group(&"travel_menu", &"open")
	elif index == Family.HEIR and ImperialSuccession.at_house():
		node.get_tree().call_group(&"jogo", &"choose_successor")
	else:
		node.get_tree().call_group(&"painel", &"say", describe(index, device))


static func boost(index: int, node: Node) -> void:
	var ids := SimLoop.field.crown.ids()
	if index < 0 or index >= ids.size() or not Assume.king():
		return
	var refusal := InputRouter.impulse_refusal(ids[index])
	if refusal.is_empty():
		SimLoop.intents.queue(IntentQueue.Kind.IMPULSE, {&"id": ids[index]})
	else:
		node.get_tree().call_group(&"painel", &"say", refusal)
