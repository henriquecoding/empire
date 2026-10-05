# src/core/save_migrations_v12.gd — o save de antes da floresta (ADR 0070).
#
# Nao havia arvores no mundo da simulacao. O save antigo fica marcado como de antes dela:
# a floresta planta-se no primeiro passo depois de carregar, sem nunca cobrir o que ja
# se ergueu nem a clareira da sede, e sem tocar nas moedas, nas pessoas ou nas obras.
class_name SaveMigrationsV12
extends RefCounted


static func apply(save: Dictionary) -> void:
	var world: Variant = save.get(&"world", {})
	if not world is Dictionary or world.is_empty() or world.has(&"woodland"):
		return
	world[&"woodland"] = {&"generated": false, &"legacy": true}
