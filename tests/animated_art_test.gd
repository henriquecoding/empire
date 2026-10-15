# tests/animated_art_test.gd — os animais e as criaturas animados do dono no jogo (ADR 0083).
#
# O dono, a 15/10/2026: «Implemente isso no meu jogo», com os dois pacotes de 14/10. O que
# entra no export tem quem o desenhe, cada quadro assenta nos pes, o tempo escolhe o quadro
# certo, a escala e inteira e as proporcoes do pacote entre os bichos ficam.
extends GdUnitTestSuite

const F := Silhouette.Form
## O porte de cada criatura fica a menos disto do do Bestiary (Q-219): a escala e inteira.
const FOLGA_PORTE := 0.2


func _manifesto() -> Dictionary:
	var texto := FileAccess.get_file_as_string(AnimatedArt.ROOT + "manifest.json")
	return JSON.parse_string(texto)


func _desenhados() -> Array:
	var ids: Array = (
		AnimatedArt.CREATURES.values() + AnimatedArt.WILDLIFE.values() + AnimatedArt.MOUNTS.values()
	)
	for bichos: Array in AnimatedArt.FARM.values():
		ids += bichos
	return ids


func _altura(id: StringName, escala: int) -> float:
	return AnimatedArt.body(id).size.y * float(escala)


func test_o_que_entra_no_export_tem_quem_o_desenhe() -> void:
	var exportados: Array = _manifesto().assets.keys()
	exportados.sort()
	var desenhados := {}
	for id: StringName in _desenhados():
		desenhados[String(id)] = true
	var nomes: Array = desenhados.keys()
	nomes.sort()
	assert_array(exportados).is_equal(nomes)
	for id: StringName in _desenhados():
		assert_bool(AnimatedArt.has(id)).override_failure_message(String(id)).is_true()
		assert_bool(OriginalArt.new().entry(id).is_empty()).is_false()


func test_cada_quadro_esta_na_folha_e_assenta_nos_pes() -> void:
	var arte := OriginalArt.new()
	for id: StringName in _manifesto().assets.keys().map(func(k: String) -> StringName: return k):
		var item := AnimatedArt.entry(id)
		var folha := arte.texture(id).get_image()
		var tela := Rect2i(Vector2i.ZERO, folha.get_size())
		var lifts: Array = item.get("lifts", [])
		for k in item.frame_origins.size():
			var canto := Vector2i(item.frame_origins[k][0], item.frame_origins[k][1])
			var quadro := Rect2i(canto, Vector2i(item.size[0], item.size[1]))
			assert_bool(tela.encloses(quadro)).is_true()
			var usado := folha.get_region(quadro).get_used_rect()
			var nome := "%s #%d" % [id, k]
			assert_bool(usado.has_area()).override_failure_message(nome).is_true()
			var sobe := int(lifts[k]) if k < lifts.size() else 0
			var pes := int(item.foot[1])
			assert_bool(usado.end.y in [pes, pes - sobe]).override_failure_message(nome).is_true()


func test_o_tempo_escolhe_o_quadro_e_o_que_nao_se_repete_fica_no_fim() -> void:
	var id := &"beast_crawler"
	var item := AnimatedArt.entry(id)
	var morre: Dictionary = item.tags.die
	assert_int(AnimatedArt.frame(id, &"die", 0.0)).is_equal(int(morre.from_frame))
	assert_int(AnimatedArt.frame(id, &"die", 60.0)).is_equal(int(morre.to_frame))
	var anda: Dictionary = item.tags.walk
	var volta := AnimatedArt.seconds(id, &"walk")
	assert_int(AnimatedArt.frame(id, &"walk", volta)).is_equal(int(anda.from_frame))
	# a fuga do Rastejante e a caminhada 1,4x mais depressa (o alias do pacote)
	assert_float(AnimatedArt.seconds(id, &"flee")).is_equal_approx(volta / 1.4, 0.001)
	assert_int(AnimatedArt.frame(id, &"flee", 0.1)).is_equal(AnimatedArt.frame(id, &"walk", 0.14))
	# sem a accao, o repouso; o Alado voa quando lhe pedem que ande
	assert_int(AnimatedArt.frame(id, &"nada", 0.0)).is_equal(AnimatedArt.frame(id, &"idle", 0.0))
	assert_bool(AnimatedArt.has_action(&"beast_winged", &"walk")).is_true()
	# os animais respondem pela categoria: a comer, cada especie com o nome dela
	assert_bool(AnimatedArt.has_action(&"animal_boar", &"feed")).is_true()
	assert_float(AnimatedArt.seconds(&"animal_boar", &"feed")).is_equal(
		AnimatedArt.seconds(&"animal_boar", &"root")
	)


func test_a_criatura_tem_escala_inteira_e_o_porte_do_bestiario() -> void:
	for forma: F in AnimatedArt.CREATURES.keys():
		var escala := AnimatedBeasts.scale_of(forma)
		var porte := Bestiary.box(forma, 0.0, int(Band.Kind.SURFACE)).size.y
		var alto := _altura(AnimatedBeasts.id_of(forma), escala)
		var nome := String(AnimatedBeasts.id_of(forma))
		assert_int(escala).override_failure_message(nome).is_greater_equal(1)
		assert_float(absf(alto - porte) / porte).override_failure_message(nome).is_less(FOLGA_PORTE)


func test_o_rastejante_continua_o_mais_baixo_e_a_consumidora_a_maior() -> void:
	var alturas := {}
	for forma: F in AnimatedArt.CREATURES.keys():
		alturas[forma] = _altura(AnimatedBeasts.id_of(forma), AnimatedBeasts.scale_of(forma))
	for forma: F in alturas.keys():
		assert_float(alturas[forma]).is_greater_equal(alturas[F.RASTEJO])
		assert_float(alturas[forma]).is_less_equal(alturas[F.COLOSSO])


func test_os_animais_guardam_as_proporcoes_do_pacote() -> void:
	for id: StringName in AnimatedArt.WILDLIFE.keys():
		var dados := Registry.entry(&"wildlife", id) as WildlifeData
		assert_int(dados.sprite_scale).override_failure_message(String(id)).is_equal(
			AnimatedArt.ANIMAL_SCALE
		)
	var e := AnimatedArt.ANIMAL_SCALE
	var crescente := [
		&"animal_rabbit", &"animal_fox", &"animal_boar", &"animal_deer", &"animal_white_stag"
	]
	for k in range(1, crescente.size()):
		assert_float(_altura(crescente[k], e)).is_greater(_altura(crescente[k - 1], e))
	var q := AnimatedArt.FARM_SCALE
	assert_float(_altura(&"animal_hen", q)).is_less(_altura(&"animal_rooster", q))
	assert_float(_altura(&"animal_rooster", q)).is_less(_altura(&"animal_cow", q))
	assert_float(_altura(&"animal_cow", e)).is_less(_altura(&"animal_draft_horse", e))


## As galinhas e as vacas ficam a escala da obra onde vivem: nenhuma passa de metade da
## altura do sprite dela (a 2x, a galinha ficava da altura do galinheiro).
func test_os_bichos_da_quinta_ficam_a_escala_da_obra_deles() -> void:
	for obra: StringName in AnimatedArt.FARM.keys():
		var sprite: StringName = PaintedArt.OBRAS[obra]
		var alto_da_obra := float(FarmSprites.TAMANHOS[sprite].y)
		for id: StringName in AnimatedArt.FARM[obra]:
			var nome := "%s em %s" % [id, obra]
			var alto := _altura(id, AnimatedArt.FARM_SCALE)
			assert_float(alto).override_failure_message(nome).is_less_equal(alto_da_obra * 0.5)


func test_as_criaturas_brilham_no_escuro_e_o_branco_tem_a_forma_delas() -> void:
	for id: StringName in AnimatedArt.CREATURES.values():
		var item := AnimatedArt.entry(id)
		var corpo := (load(AnimatedArt.ROOT + item.texture) as Texture2D).get_image()
		var branco := (load(AnimatedArt.ROOT + item.mask_texture) as Texture2D).get_image()
		var olhos := (load(AnimatedArt.ROOT + item.eyes_texture) as Texture2D).get_image()
		assert_vector(branco.get_size()).is_equal(corpo.get_size())
		assert_vector(olhos.get_size()).is_equal(corpo.get_size())
		var quadro := Rect2i(Vector2i.ZERO, Vector2i(item.size[0], item.size[1]))
		(
			assert_bool(olhos.get_region(quadro).is_invisible())
			. override_failure_message(String(id))
			. is_false()
		)
		var usado := corpo.get_region(quadro).get_used_rect()
		assert_bool(usado == branco.get_region(quadro).get_used_rect()).is_true()
	for id: StringName in AnimatedArt.WILDLIFE.values():
		assert_bool(AnimatedArt.entry(id).has("eyes_texture")).is_false()


## O manifesto nao e um recurso do Godot: sem ele no include_filter, o jogo exportado (Linux,
## Windows e Web) voltava a arte de antes sem dar erro nenhum.
func test_o_manifesto_vai_em_todos_os_exports() -> void:
	var presets := ConfigFile.new()
	assert_int(presets.load("res://export_presets.cfg")).is_equal(OK)
	var vistos := 0
	for seccao in presets.get_sections():
		if not presets.has_section_key(seccao, "include_filter"):
			continue
		vistos += 1
		var filtro := String(presets.get_value(seccao, "include_filter"))
		assert_str(filtro).override_failure_message(seccao).contains("art/export/animated/*.json")
	assert_int(vistos).is_greater(0)
