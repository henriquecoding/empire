# tests/obras_com_folga_test.gd — as obras da regiao nao se tocam (Q-207).
#
# O dono, a 03/10/2026: "as construcoes devem ter um pequeno espaco tambem, estao muito
# juntas uma das outras". Havia nove pares a 16 px ou menos, e dois colados. A regra
# passou a ser geometria do Greybox: entre duas obras vizinhas da mesma faixa ha sempre
# FOLGA px de chao livre, a contar das larguras do buildings.csv.
extends GdUnitTestSuite

## O chao livre entre duas obras: geometria, como as posicoes do Greybox (Q-207).
const FOLGA := 24.0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	SimLoop.start(20261003)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _obras(faixa: Band.Kind) -> Array[BuildSlot]:
	var lista: Array[BuildSlot] = []
	for vaga in SimLoop.builds.slots:
		if vaga.band == faixa and vaga.kind != AmargueiroSystem.CORTE:
			lista.append(vaga)
	lista.sort_custom(func(a: BuildSlot, b: BuildSlot) -> bool: return a.x < b.x)
	return lista


func test_duas_obras_vizinhas_tem_folga_entre_elas() -> void:
	var obras := _obras(Band.Kind.SURFACE)
	assert_int(obras.size()).is_greater(20)
	for k in range(1, obras.size()):
		var a := obras[k - 1]
		var b := obras[k]
		var folga := (b.x - b.width * 0.5) - (a.x + a.width * 0.5)
		var par := "%s e %s" % [a.kind, b.kind]
		assert_float(folga).override_failure_message(par).is_greater_equal(FOLGA)


func test_as_obras_do_subsolo_tambem_nao_se_tocam() -> void:
	var obras := _obras(Band.Kind.UNDERGROUND)
	for k in range(1, obras.size()):
		var folga := (
			(obras[k].x - obras[k].width * 0.5) - (obras[k - 1].x + obras[k - 1].width * 0.5)
		)
		assert_float(folga).is_greater_equal(FOLGA)


## As estatuas enterradas (Q-016) tambem tem o seu chao: nao ficam por baixo de uma obra.
func test_as_estatuas_nao_ficam_por_baixo_de_uma_obra() -> void:
	var s := SimLoop.secrets
	for k in s.count():
		if not Registry.has_entry(&"lore/secrets", s.ids[k]):
			continue  # o diario da ruina (§79) nao e uma estatua
		if not (Registry.entry(&"lore/secrets", s.ids[k]) as SecretData).place_px:
			continue
		for vaga in _obras(Band.Kind.SURFACE):
			var longe := absf(vaga.x - s.xs[k]) - (vaga.width + s.widths[k]) * 0.5
			assert_float(longe).override_failure_message(String(vaga.kind)).is_greater(0.0)
