# src/ui/inspector.gd — o estado de cada sistema, a pedido (TAB).
#
# Nao e a roda do rei do §24. A roda tem seis segmentos — construir, recrutar,
# oficios, impulso, expedicao, sucessao — e quatro deles nao tem sistema nenhum
# por tras ainda (§09, §13, §15). Uma roda com quatro segmentos que nao fazem
# nada e pior do que nao haver roda: ensina um gesto que depois muda.
#
# O que a tecla faz enquanto isso e o que um greybox precisa: mostrar o que os
# sistemas estao a pensar, para se poder testar cada mecanica sem ler o registo
# (§67, GB-03). Ver docs/QUESTIONS.md, Q-067.
class_name Inspector
extends Label

const NENHUM := "—"


func _ready() -> void:
	hide()


func _unhandled_input(evento: InputEvent) -> void:
	if not evento.is_action(&"king_wheel") or evento.is_echo():
		return
	# No comando a roda e manter e largar (§24, Q-148): o painel abre com o Y e fecha
	# com ele, para que o apontado se veja em cada gesto. No teclado continua a
	# alternar com o Tab (Q-067).
	if evento is InputEventJoypadButton:
		visible = evento.is_pressed()
	elif evento.is_pressed():
		visible = not visible
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not visible or SimLoop.state == null:
		return
	text = (
		"\n"
		. join(
			[
				"— ESTADO (TAB fecha) —",
				(
					"semente %d · tick %d · ids %d"
					% [SimLoop.state.seed, SimLoop.state.tick, SimLoop.state.next_id]
				),
				"nucleo em x=%d · regiao 0..%d" % [int(SimLoop.core_x), int(SimLoop.world_width)],
				"",
				"TROPAS  " + _tropas(),
				"OBRAS   " + _obras(),
				"POSTOS  " + _postos(),
				"NOITE   " + _noite(),
				"",
				"IMPULSOS (TAB + numero, ou Y + stick e largar; um por dia)",
				_impulsos(),
			]
		)
	)


func _tropas() -> String:
	var por_estado := {}
	for i in SimLoop.units.count():
		var nome := String(UnitFsm.name_of(SimLoop.units.states[i] as UnitFsm.State))
		por_estado[nome] = por_estado.get(nome, 0) + 1
	var partes := PackedStringArray()
	for nome in [&"GOTO", &"WORK", &"FIGHT", &"FLEE", &"DEAD"]:
		partes.append("%s %d" % [nome, por_estado.get(String(nome), 0)])
	return " · ".join(partes)


func _impulsos() -> String:
	var coroa := SimLoop.field.crown
	var linhas := PackedStringArray()
	var n := 0
	for id in coroa.ids():
		n += 1
		var impulso := Registry.entry(&"crown/impulses", id) as ImpulseData
		var estado := "" if coroa.available(id) else " (por ligar)"
		var marca := "> " if n - 1 == InputRouter.pointed else ""
		var perfil := RulesFactory.impulse_cost_mult(SimLoop.state.greed)
		var preco := coroa.price(id, SimLoop.state.day, perfil)  # o de hoje (Q-014)
		var linha := "%s%d %s · %d%s" % [marca, n, tr(impulso.display_key), preco, estado]
		linhas.append(linha)
	if coroa.used_day == SimLoop.state.day:
		linhas.append("hoje ja se usou um")
	return "\n".join(linhas)


func _obras() -> String:
	var de_pe := 0
	var em_obra := 0
	for vaga in SimLoop.builds.slots:
		if vaga.standing():
			de_pe += 1
		elif vaga.state != BuildSlot.State.EMPTY:
			em_obra += 1
	return "%d de pe · %d em obra · %d sitios" % [de_pe, em_obra, SimLoop.builds.count()]


func _postos() -> String:
	var vagas := SimLoop.jobs.slots.size()
	if vagas == 0:
		return NENHUM
	return "%d vagas · %d por preencher" % [vagas, SimLoop.jobs.free_slots()]


func _noite() -> String:
	var rot := SimLoop.night.rot
	if not rot.active():
		return "a mancha recuou; nasce ao crepusculo"
	return (
		"x=%d · massa %.0f · velocidade %.1f px/s · invoca %s"
		% [int(rot.position_x()), rot.mass(), rot.speed(), _proxima(rot)]
	)


func _proxima(rot: RotSystem) -> String:
	var escolhida := rot.pick()
	return String(escolhida) if escolhida != RotSystem.SEM_CRIATURA else NENHUM
