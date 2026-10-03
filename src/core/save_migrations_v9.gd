class_name SaveMigrationsV9
extends RefCounted


## A distribuicao antiga deixava tocas dentro da Clareira. Reautora so os habitats;
## dinheiro recolhido, bolsas dos cacadores, pessoas e construcoes ficam intactos.
static func apply(save: Dictionary) -> void:
	var world: Variant = save.get(&"world", {})
	if not world is Dictionary:
		return
	var hunt: Variant = world.get(&"hunting", {})
	if not hunt is Dictionary or hunt.is_empty():
		return
	hunt[&"burrows"] = {}
	hunt[&"rabbits"] = []
	hunt[&"wounds"] = {}
	hunt[&"herd"] = {}
	hunt[&"intro_x"] = HuntingSystem.SEM_INTRO
