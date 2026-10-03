# src/core/save_migrations_v8.gd — o passo da versao 7 para a 8: a fundacao do reino
# (ADR 0059; o dono a 03/10/2026: *«aplique esse relatorio»*).
#
# "Saves atuais nao devem virar acampamentos" (plano do reino §27.1). Um save de antes
# trazia o nucleo como castelo, de pe no nivel 1 da escada antiga, que so tinha esse
# degrau. Na escada nova o castelo e a Fortaleza: a mesma vida, a mesma largura e os
# mesmos slots de contacto. O nucleo passa para esse estagio com a vida que tinha, e a
# sede fica marcada como herdada — os degraus de baixo nao foram pagos, e nao se finge
# que foram. Nada mais se inventa: nem o pioneiro, nem a carroca, nem a banca de graca.
class_name SaveMigrationsV8
extends RefCounted

const NUCLEO := &"core"
## O castelo de antes: o estagio de realm_stages.csv com a vida e a largura dele.
const CASTELO := 5


static func apply(d: Dictionary) -> void:
	var mundo := _dict(d, &"world")
	if mundo.is_empty():
		return
	var obras: Variant = mundo.get(&"builds", [])
	if obras is Array:
		for obra: Variant in obras:
			if obra is Dictionary and obra.get(&"kind", &"") == NUCLEO:
				_castelo(obra)
	if not mundo.has(&"seat"):
		mundo[&"seat"] = {&"inherited": true}
	d[&"world"] = mundo


## O nucleo de pe passa a Fortaleza. O que caiu fica caido: a derrota nao se desfaz.
static func _castelo(obra: Dictionary) -> void:
	if int(obra.get(&"level", 0)) >= 1:
		obra[&"level"] = CASTELO


static func _dict(d: Dictionary, chave: StringName) -> Dictionary:
	var valor: Variant = d.get(chave, {})
	return valor if valor is Dictionary else {}
