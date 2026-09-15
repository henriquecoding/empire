# tests/creature_system_test.gd — as criaturas invocadas, em colunas (§51, §52).
#
# O molde e o do tests/unit_system_test.gd: o que aqui se prova nao e a criatura,
# e a coluna — que o indice de uma criatura e a mesma criatura em todas, e que
# remover do meio nao perde nem baralha ninguem.
extends GdUnitTestSuite

const RUMO := 0.0


func _dados(id: StringName) -> CreatureData:
	return Registry.entry(&"creatures", id) as CreatureData


func _campo() -> Array:
	return [GameState.new(), CreatureSystem.new()]


func test_nascer_copia_os_campos_quentes_do_creature_data() -> void:
	var campo := _campo()
	var estado: GameState = campo[0]
	var bicho: CreatureSystem = campo[1]
	var dados := _dados(&"crawler")

	var id := bicho.spawn(estado, dados, 500.0, RUMO)
	var i := bicho.index_of(id)

	assert_int(bicho.count()).is_equal(1)
	assert_int(bicho.healths[i]).is_equal(dados.max_health)
	assert_float(bicho.speeds[i]).is_equal(dados.move_speed)
	assert_int(bicho.bands[i]).is_equal(int(dados.band))
	assert_int(bicho.coin_drops[i]).is_equal(dados.coin_drop)
	assert_bool(bicho.alive(i)).is_true()
	# O rumo e o lugar para onde anda comecam iguais, e so o segundo muda depois.
	assert_float(bicho.goal_xs[i]).is_equal(RUMO)
	assert_float(bicho.target_xs[i]).is_equal(RUMO)


func test_os_ids_vem_do_contador_do_game_state() -> void:
	# §45: o contador de ids e unico e monotonico, e e o mesmo para tropas,
	# moedas e criaturas — dois ids iguais em colecoes diferentes seriam um
	# defeito que so aparece no save.
	var campo := _campo()
	var estado: GameState = campo[0]
	var bicho: CreatureSystem = campo[1]

	var a := bicho.spawn(estado, _dados(&"crawler"), 0.0, RUMO)
	var b := bicho.spawn(estado, _dados(&"winged"), 0.0, RUMO)

	assert_int(b).is_equal(a + 1)


func test_andar_aproxima_do_rumo_e_para_la() -> void:
	var campo := _campo()
	var estado: GameState = campo[0]
	var bicho: CreatureSystem = campo[1]
	var dados := _dados(&"crawler")
	var id := bicho.spawn(estado, dados, 100.0, 0.0)
	var i := bicho.index_of(id)

	for _t in 100:
		bicho.tick_movement(0.1)

	assert_float(bicho.xs[i]).is_equal(0.0)


func test_quem_esta_engajado_nao_anda() -> void:
	# §50: escolher alvo e resolver o ataque sao passos distintos, e uma criatura
	# que ja bate em alguem nao continua a caminhar para o nucleo por baixo dele.
	var campo := _campo()
	var estado: GameState = campo[0]
	var bicho: CreatureSystem = campo[1]
	var id := bicho.spawn(estado, _dados(&"crawler"), 100.0, 0.0)
	var i := bicho.index_of(id)
	bicho.target_ids[i] = 42

	bicho.tick_movement(1.0)

	assert_bool(bicho.engaged(i)).is_true()
	assert_float(bicho.xs[i]).is_equal(100.0)

	bicho.target_ids[i] = CreatureSystem.NENHUM
	bicho.target_slots[i] = 3
	bicho.tick_movement(1.0)

	assert_bool(bicho.engaged(i)).is_true()
	assert_float(bicho.xs[i]).is_equal(100.0)


func test_morrer_e_perder_vida_ate_zero() -> void:
	var campo := _campo()
	var estado: GameState = campo[0]
	var bicho: CreatureSystem = campo[1]
	var dados := _dados(&"crawler")
	var id := bicho.spawn(estado, dados, 0.0, RUMO)
	var i := bicho.index_of(id)

	bicho.damage(id, dados.max_health * 2)

	assert_int(bicho.healths[i]).is_equal(0)
	assert_bool(bicho.alive(i)).is_false()


func test_remover_do_meio_nao_perde_nem_baralha_ninguem() -> void:
	var campo := _campo()
	var estado: GameState = campo[0]
	var bicho: CreatureSystem = campo[1]
	var ids: Array[int] = []
	for k in 5:
		ids.append(bicho.spawn(estado, _dados(&"crawler"), float(k) * 10.0, RUMO))

	assert_bool(bicho.remove(ids[2])).is_true()

	assert_int(bicho.count()).is_equal(4)
	assert_int(bicho.index_of(ids[2])).is_equal(CreatureSystem.NENHUM)
	for k in [0, 1, 3, 4]:
		var i := bicho.index_of(ids[k])
		assert_int(i).is_not_equal(CreatureSystem.NENHUM)
		assert_float(bicho.xs[i]).is_equal(float(k) * 10.0)


func test_dissolver_leva_tudo_e_devolve_quem_levou() -> void:
	# §51: ao amanhecer a mancha recua e "as criaturas vivas dissolvem-se".
	var campo := _campo()
	var estado: GameState = campo[0]
	var bicho: CreatureSystem = campo[1]
	for k in 3:
		bicho.spawn(estado, _dados(&"crawler"), float(k), RUMO)

	var levadas := bicho.dissolve()

	assert_int(levadas.size()).is_equal(3)
	assert_int(bicho.count()).is_equal(0)


func test_o_save_das_colunas_so_leva_tipos_base() -> void:
	var campo := _campo()
	var estado: GameState = campo[0]
	var bicho: CreatureSystem = campo[1]
	bicho.spawn(estado, _dados(&"brute"), 12.0, RUMO)

	for valor in bicho.to_dict().values():
		assert_int(typeof(valor)).is_not_equal(TYPE_OBJECT)
