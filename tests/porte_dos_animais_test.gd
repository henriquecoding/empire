# tests/porte_dos_animais_test.gd — o porte de cada animal, como o dono o disse (Q-264).
#
# O dono, a 15/10/2026: «o coelho, o pavao e as galinhas sao mesmo pequenos, o javali e o
# carneiro sao de um tamanho adequado para as tropas, eles tem que ser de um tamanho que
# faca sentido para ser montaria das tropas, o veado tambem e do tamanho do carneiro, ja a
# vaca, o bufalo e o cervo sao animais de grande porte que podem ser montados pelos
# imperadores, eles tem que ser de uma proporcao que isso faca sentido». E depois: os
# pequenos «devem ser um pouco menor que as tropas»; o javali, o carneiro e o veado «devem
# ter um tamanho um pouco maior que as tropas para elas poderem montar eles». Mede-se o
# que se desenha — a arte do pacote a escala dela — contra as tropas e os monarcas que ha.
extends GdUnitTestSuite

const P := AnimatedArt.Porte
const DONO := {
	&"animal_rabbit": AnimatedArt.Porte.PEQUENO,
	&"animal_peacock": AnimatedArt.Porte.PEQUENO,
	&"animal_hen": AnimatedArt.Porte.PEQUENO,
	&"animal_rooster": AnimatedArt.Porte.PEQUENO,
	&"animal_boar": AnimatedArt.Porte.TROPA,
	&"animal_ram": AnimatedArt.Porte.TROPA,
	&"animal_deer": AnimatedArt.Porte.TROPA,
	&"animal_cow": AnimatedArt.Porte.IMPERADOR,
	&"animal_buffalo": AnimatedArt.Porte.IMPERADOR,
	&"animal_white_stag": AnimatedArt.Porte.IMPERADOR,
}
## «Um pouco menor que as tropas»: entre 3/4 e 9/10 da tropa do meio.
const PEQUENO_DE := 0.75
const PEQUENO_ATE := 0.9
## «Um pouco maior que as tropas»: acima da tropa do meio, ate 1,3 vezes ela.
const TROPA_ATE := 1.3
## Uma montaria de imperador passa um pouco o monarca mais alto, e nunca metade mais.
const IMPERADOR_DE := 1.1
const IMPERADOR_ATE := 1.5
## A escala vai em quartos de pixel.
const QUARTOS := 4.0
## O veado e do tamanho do carneiro: menos disto entre os dois.
const PARECIDOS := 0.15


func _animais() -> Array:
	var ids: Array = AnimatedArt.WILDLIFE.values() + AnimatedArt.MOUNTS.values()
	for bichos: Array in AnimatedArt.FARM.values():
		ids += bichos
	return ids


func _do_porte(porte: int) -> Array:
	return _animais().filter(func(id: StringName) -> bool: return AnimatedArt.PORTE[id] == porte)


func _alto(id: StringName) -> float:
	return AnimatedArt.body(id).size.y * AnimatedArt.scale_of(id)


func _largo(id: StringName) -> float:
	return AnimatedArt.body(id).size.x * AnimatedArt.scale_of(id)


## Os pixeis do corpo no primeiro quadro de repouso, a escala dele: o tamanho a olho,
## que nao se deixa enganar pelas orelhas do coelho nem pela crista do pavao.
func _massa(id: StringName) -> float:
	var item := AnimatedArt.entry(id)
	var imagem := (load(AnimatedArt.ROOT + item.texture) as Texture2D).get_image()
	var origem: Array = item.frame_origins[int(item.tags.idle.from_frame)]
	var tamanho: Array = item.size
	var cheios := 0
	for y in int(tamanho[1]):
		for x in int(tamanho[0]):
			if imagem.get_pixel(int(origem[0]) + x, int(origem[1]) + y).a > 0.0:
				cheios += 1
	var escala := AnimatedArt.scale_of(id)
	return float(cheios) * escala * escala


## A altura de cada perfil de arte das unidades: o dos monarcas (`monarcas`) ou o das
## tropas, cada perfil uma vez (o Arqueiro jogavel veste o perfil do Imperador Arqueiro).
func _alturas(monarcas: bool) -> Array[float]:
	var deles := {}
	for monarca: MonarchData in Registry.entries(&"monarchs"):
		deles[RenewalArt.UNITS[monarca.unit]] = true
	var perfis := {}
	for perfil: StringName in RenewalArt.UNITS.values():
		if deles.has(perfil) == monarcas:
			perfis[perfil] = true
	var arte := OriginalArt.new()
	var alturas: Array[float] = []
	for perfil: StringName in perfis.keys():
		alturas.append(arte.body_box(perfil, Vector2.ZERO).size.y)
	alturas.sort()
	return alturas


## A tropa do meio: a mediana das alturas das tropas.
func _tropa() -> float:
	var alturas := _alturas(false)
	return alturas[alturas.size() / 2]


func _maior(ids: Array, medida: Callable) -> float:
	var maior := -INF
	for id: StringName in ids:
		maior = maxf(maior, medida.call(id))
	return maior


func _menor(ids: Array, medida: Callable) -> float:
	var menor := INF
	for id: StringName in ids:
		menor = minf(menor, medida.call(id))
	return menor


func test_cada_animal_tem_o_porte_que_o_dono_lhe_deu() -> void:
	for id: StringName in DONO.keys():
		assert_int(AnimatedArt.PORTE.get(id, -1)).override_failure_message(String(id)).is_equal(
			DONO[id]
		)
	for id: StringName in _animais():
		assert_bool(AnimatedArt.PORTE.has(id)).override_failure_message(String(id)).is_true()


## Cada animal com porte tem escala, em quartos e nunca abaixo de 1; a caca do
## wildlife.csv desenha-se a mesma.
func test_cada_animal_tem_escala_em_quartos_e_a_caca_segue_a() -> void:
	for id: StringName in AnimatedArt.PORTE.keys():
		var escala := AnimatedArt.scale_of(id)
		assert_bool(AnimatedArt.ESCALA.has(id)).override_failure_message(String(id)).is_true()
		assert_float(escala).override_failure_message(String(id)).is_greater_equal(1.0)
		var quartos := escala * QUARTOS
		assert_float(quartos).override_failure_message(String(id)).is_equal(roundf(quartos))
	for bicho: StringName in AnimatedArt.WILDLIFE.keys():
		var dados := Registry.entry(&"wildlife", bicho) as WildlifeData
		var perfil: StringName = AnimatedArt.WILDLIFE[bicho]
		assert_float(dados.sprite_scale).override_failure_message(String(bicho)).is_equal(
			AnimatedArt.scale_of(perfil)
		)


## Os pequenos ficam um pouco abaixo da tropa do meio, e sao mais leves do que qualquer
## montaria das tropas.
func test_os_pequenos_sao_um_pouco_menores_do_que_as_tropas() -> void:
	var tropa := _tropa()
	var montarias := _do_porte(P.TROPA)
	assert_array(montarias).is_not_empty()
	for id: StringName in _do_porte(P.PEQUENO):
		var nome := String(id)
		assert_float(_alto(id)).override_failure_message(nome).is_between(
			tropa * PEQUENO_DE, tropa * PEQUENO_ATE
		)
		assert_float(_massa(id)).override_failure_message(nome).is_less(_menor(montarias, _massa))


## O javali, o carneiro e o veado ficam um pouco acima da tropa do meio, para ela os
## montar; e o veado e do tamanho do carneiro.
func test_as_montarias_das_tropas_sao_um_pouco_maiores_do_que_elas() -> void:
	var tropa := _tropa()
	for id: StringName in _do_porte(P.TROPA):
		var nome := String(id)
		assert_float(_alto(id)).override_failure_message(nome).is_greater(tropa)
		assert_float(_alto(id)).override_failure_message(nome).is_less_equal(tropa * TROPA_ATE)
	if AnimatedArt.has(&"animal_ram"):  # o carneiro so entra com lugar no jogo (Q-263)
		var veado := _alto(&"animal_deer")
		var carneiro := _alto(&"animal_ram")
		assert_float(absf(veado - carneiro)).is_less_equal(carneiro * PARECIDOS)


## Uma montaria de imperador passa um pouco o monarca mais alto e e mais comprida do que
## ele; e mais alta e mais pesada do que qualquer montaria das tropas.
func test_as_montarias_dos_imperadores_levam_um_imperador() -> void:
	var monarca: float = _alturas(true).back()
	var tropas := _do_porte(P.TROPA)
	for id: StringName in _do_porte(P.IMPERADOR):
		var nome := String(id)
		assert_float(_alto(id)).override_failure_message(nome).is_between(
			monarca * IMPERADOR_DE, monarca * IMPERADOR_ATE
		)
		assert_float(_largo(id)).override_failure_message(nome).is_greater_equal(monarca)
		assert_float(_alto(id)).override_failure_message(nome).is_greater(_maior(tropas, _alto))
		assert_float(_massa(id)).override_failure_message(nome).is_greater(_maior(tropas, _massa))


## So o monarca monta (Mount): o que ele monta e do porte dos imperadores.
func test_o_imperador_so_monta_montarias_de_imperador() -> void:
	for id: StringName in AnimatedArt.MOUNTS.values():
		assert_int(AnimatedArt.PORTE[id]).override_failure_message(String(id)).is_equal(P.IMPERADOR)


## As galinhas e as vacas cabem na altura da obra onde vivem.
func test_os_bichos_da_quinta_cabem_na_obra_deles() -> void:
	for obra: StringName in AnimatedArt.FARM.keys():
		var alto_da_obra := float(FarmSprites.TAMANHOS[PaintedArt.OBRAS[obra]].y)
		for id: StringName in AnimatedArt.FARM[obra]:
			var nome := "%s em %s" % [id, obra]
			assert_float(_alto(id)).override_failure_message(nome).is_less(alto_da_obra)


## Os portes nao se misturam, e o pacote guarda a ordem de quem vive junto.
func test_os_animais_guardam_a_ordem_entre_eles() -> void:
	var pequenos := _do_porte(P.PEQUENO)
	var tropas := _do_porte(P.TROPA)
	var imperadores := _do_porte(P.IMPERADOR)
	assert_float(_maior(pequenos, _alto)).is_less(_menor(tropas, _alto))
	assert_float(_maior(tropas, _alto)).is_less(_menor(imperadores, _alto))
	assert_float(_alto(&"animal_hen")).is_less(_alto(&"animal_rooster"))
	assert_float(_massa(&"animal_rabbit")).is_less(_massa(&"animal_fox"))
	assert_float(_alto(&"animal_cow")).is_less(_alto(&"animal_draft_horse"))
