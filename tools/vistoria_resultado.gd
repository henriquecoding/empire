class_name VistoriaResultado
extends RefCounted


static func write(requested: int, steps: int, step_seconds: float, findings: Array[String]) -> bool:
	var clock := ClockService.clock
	var elapsed := (clock.day - 1) * clock.day_seconds() + clock.elapsed
	var args := OS.get_cmdline_user_args()
	var i := args.find("--min-dias")
	var minimum := float(args[i + 1]) if i >= 0 and i + 1 < args.size() else 0.0
	var covered := elapsed + step_seconds >= minimum * clock.day_seconds()
	var result := {
		"dias_pedidos": requested,
		"dias_completos": int(elapsed / clock.day_seconds()),
		"dia_final": clock.day,
		"segundos_calendario": elapsed,
		"segundos_executados": steps * step_seconds,
		"ticks_executados": steps,
		"cobertura_minima_dias": minimum,
		"cobertura_minima_cumprida": covered,
		"pedido_completo": elapsed + step_seconds >= requested * clock.day_seconds(),
		"derrota": Defeat.happened(),
		"achados": findings,
		"cenario": "piloto_partida_nova",
		"commit": OS.get_environment("GITHUB_SHA"),
		"godot": Engine.get_version_info().string,
	}
	var path := "build/vistoria.json"
	DirAccess.make_dir_recursive_absolute("res://build")
	var file := FileAccess.open("res://" + path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(result, "\t") + "\n")
	file.close()
	print(
		(
			"vistoria: cobertura real %.2f de %d dias pedidos; minimo %.2f — %s"
			% [
				elapsed / clock.day_seconds(),
				requested,
				minimum,
				"cumprido" if covered else "insuficiente"
			]
		)
	)
	return covered
