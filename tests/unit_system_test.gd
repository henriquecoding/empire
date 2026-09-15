# tests/unit_system_test.gd — as colunas, o fatiamento, e o orcamento do §63.
#
# O "Feito" deste ticket e um numero: 300 unidades dentro do orcamento por
# passagem. E por isso que ha aqui uma medicao a serio e nao so asserções de
# comportamento — e por isso que ela diz em que maquina correu.
extends GdUnitTestSuite

const TROPAS := 300
const PASSO := 1.0 / 30.0

## §63: "UnitSystem (FSM) | 0,8 ms | Marcador dedicado". O orcamento e do Steam
## Deck; esta medicao corre onde correr, e por isso o teste guarda uma margem
## larga e o numero exato fica escrito no registo, para ser comparado la.
const ORCAMENTO_FSM_US := 800
const ORCAMENTO_MOVIMENTO_US := 1000


func _estado() -> GameState:
	var e := GameState.new()
	e.seed = 20260915
	return e


func _vagabundo() -> UnitData:
	return Registry.entry(&"units", &"vagrant")


func _povoar(sistema: UnitSystem, estado: GameState, quantos: int) -> void:
	var dados := _vagabundo()
	for i in quantos:
		var unit_id := sistema.spawn(estado, dados, 0, float(i))
		sistema.set_target_x(unit_id, float(i) + 1000.0)


# ─── As colunas ──────────────────────────────────────────────────────────────


func test_uma_unidade_nasce_com_os_campos_do_tres() -> void:
	var sistema := UnitSystem.new()
	var estado := _estado()
	var dados := _vagabundo()

	var unit_id := sistema.spawn(estado, dados, 0, 42.0)
	var i := sistema.index_of(unit_id)

	assert_int(sistema.count()).is_equal(1)
	assert_int(sistema.healths[i]).is_equal(dados.max_health)
	assert_float(sistema.speeds[i]).is_equal_approx(dados.move_speed, 0.0001)
	assert_int(sistema.bands[i]).is_equal(int(dados.band))
	assert_str(sistema.data_ids[i]).is_equal(dados.id)
	assert_float(sistema.xs[i]).is_equal_approx(42.0, 0.0001)


func test_os_ids_vem_do_contador_do_game_state() -> void:
	# §45: "next_id — contador unico e monotonico". Ids reciclados sao a raiz de
	# metade dos defeitos de alvo errado num jogo com mortes.
	var sistema := UnitSystem.new()
	var estado := _estado()
	var a := sistema.spawn(estado, _vagabundo(), 0, 0.0)
	var b := sistema.spawn(estado, _vagabundo(), 0, 0.0)

	assert_int(b).is_greater(a)
	sistema.remove(a)
	var c := sistema.spawn(estado, _vagabundo(), 0, 0.0)
	assert_int(c).is_greater(b)


func test_remover_do_meio_nao_perde_nem_baralha_ninguem() -> void:
	var sistema := UnitSystem.new()
	var estado := _estado()
	var criados: Array[int] = []
	for i in 10:
		criados.append(sistema.spawn(estado, _vagabundo(), 0, float(i) * 10.0))

	sistema.remove(criados[3])

	assert_int(sistema.count()).is_equal(9)
	assert_int(sistema.index_of(criados[3])).is_equal(UnitSystem.NENHUM)
	# Os outros nove continuam todos encontraveis, e com o x que tinham.
	for i in 10:
		if i == 3:
			continue
		var j := sistema.index_of(criados[i])
		assert_int(j).is_not_equal(UnitSystem.NENHUM)
		assert_float(sistema.xs[j]).is_equal_approx(float(i) * 10.0, 0.0001)


func test_remover_um_id_que_nao_existe_nao_faz_nada() -> void:
	var sistema := UnitSystem.new()
	assert_bool(sistema.remove(999)).is_false()


func test_o_save_das_colunas_so_leva_tipos_base() -> void:
	var sistema := UnitSystem.new()
	var estado := _estado()
	_povoar(sistema, estado, 5)

	for chave in sistema.to_dict():
		var valor: Variant = sistema.to_dict()[chave]
		var porque := "%s e Object" % chave
		assert_int(typeof(valor)).override_failure_message(porque).is_not_equal(TYPE_OBJECT)

	# E passa mesmo pelo canal da ADR 0007, ida e volta.
	var caminho := "user://test_unit_columns.save"
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	f.store_var(sistema.to_dict(), false)
	f.close()
	f = FileAccess.open(caminho, FileAccess.READ)
	var lido: Variant = f.get_var(false)
	f.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(caminho))
	assert_int(typeof(lido)).is_equal(TYPE_DICTIONARY)
	assert_int((lido as Dictionary)[&"ids"].size()).is_equal(5)
