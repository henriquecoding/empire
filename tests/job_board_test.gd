# tests/job_board_test.gd — os quatro testes do prompt 4 da §29, e o que a
# histerese obriga a acrescentar.
#
# O algoritmo e o do Kingdom e a previsibilidade e a funcionalidade (§52): o que
# se prova aqui nao e que a atribuicao seja boa, e que seja a MESMA duas vezes.
extends GdUnitTestSuite

const MEU_IMPERIO := 7
const NOITE := int(GameClock.Phase.NIGHT)
const MEIO_DIA := int(GameClock.Phase.NOON)


func _curva() -> EconomyCurve:
	return Registry.entry(&"economy", &"curve") as EconomyCurve


func _postos() -> Dictionary:
	var mapa := {}
	for r in Registry.entries(&"jobs"):
		var j := r as JobData
		mapa[j.id] = j
	return mapa


func _dados() -> Dictionary:
	var mapa := {}
	for r in Registry.entries(&"units"):
		var u := r as UnitData
		mapa[u.id] = u
	return mapa


func _quadro() -> JobBoard:
	return JobBoard.new(_curva(), _postos(), _dados())


func _arqueiros(unidades: UnitSystem, estado: GameState, xs: Array) -> Array[int]:
	var dados := Registry.entry(&"units", &"archer") as UnitData
	var saida: Array[int] = []
	for x in xs:
		saida.append(unidades.spawn(estado, dados, MEU_IMPERIO, float(x)))
	return saida


# ─── Os quatro do prompt ─────────────────────────────────────────────────────


func test_de_noite_nenhum_arqueiro_fica_na_plantacao() -> void:
	# A plantacao tem urgencia 0,0 a noite (jobs.csv) e urgencia zero e score
	# zero: ninguem la fica, e nao por um `if` sobre a fase.
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	_arqueiros(unidades, estado, [0.0, 50.0])
	var quadro := _quadro()
	quadro.post(JobSlot.new(&"farm", 10.0, Band.Kind.SURFACE))

	var atribuido := quadro.assign(unidades, NOITE)

	assert_dict(atribuido).is_empty()


func test_dois_postos_de_muro_e_cinco_arqueiros_dao_duas_atribuicoes() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	_arqueiros(unidades, estado, [0.0, 20.0, 40.0, 60.0, 80.0])
	var quadro := _quadro()
	quadro.post(JobSlot.new(&"wall", 0.0, Band.Kind.SURFACE))
	quadro.post(JobSlot.new(&"wall", 100.0, Band.Kind.SURFACE))

	var atribuido := quadro.assign(unidades, NOITE)

	assert_int(atribuido.size()).is_equal(2)
	assert_int(quadro.free_slots()).is_equal(0)


func test_correr_duas_vezes_seguidas_nao_muda_nada() -> void:
	# A histerese existe para isto: sem ela a atribuicao treme de fase em fase e
	# as tropas andam de um lado para o outro sem trabalhar.
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	_arqueiros(unidades, estado, [0.0, 20.0, 40.0, 60.0, 80.0])
	var quadro := _quadro()
	for x in [0.0, 100.0, 200.0]:
		quadro.post(JobSlot.new(&"wall", x, Band.Kind.SURFACE))

	var primeira := quadro.assign(unidades, NOITE)
	var segunda := quadro.assign(unidades, NOITE)

	assert_dict(segunda).is_equal(primeira)


func test_a_800_px_perde_para_quem_esta_a_100_px() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var ids := _arqueiros(unidades, estado, [100.0, 800.0])
	var quadro := _quadro()
	quadro.post(JobSlot.new(&"wall", 0.0, Band.Kind.SURFACE))

	var atribuido := quadro.assign(unidades, NOITE)

	assert_bool(atribuido.has(ids[0])).is_true()
	assert_bool(atribuido.has(ids[1])).is_false()


# ─── O que o contrato acrescenta ─────────────────────────────────────────────


func test_a_tropa_vai_ao_posto_certo() -> void:
	# "A tropa vai ao posto certo e volta a alvorada" e o Feito do F1-05: quem e
	# atribuido fica com o alvo em x no posto, e o passo 5 leva-o la.
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var ids := _arqueiros(unidades, estado, [0.0])
	var quadro := _quadro()
	quadro.post(JobSlot.new(&"wall", 300.0, Band.Kind.SURFACE))

	quadro.assign(unidades, NOITE)
	var i := unidades.index_of(ids[0])

	assert_float(unidades.target_xs[i]).is_equal(300.0)
	assert_int(unidades.has_targets[i]).is_equal(1)


func test_a_alvorada_larga_os_postos_de_noite() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var ids := _arqueiros(unidades, estado, [0.0])
	var quadro := _quadro()
	quadro.post(JobSlot.new(&"wall", 300.0, Band.Kind.SURFACE))
	quadro.assign(unidades, NOITE)

	# De dia o muro cai para urgencia 0,5 e a caca sobe: sem posto de caca, o
	# muro continua a ser o melhor que ha, e por isso ele fica. O que muda e a
	# plantacao — e e o que o teste de cima ja prova. Aqui so se confirma que
	# uma fase nova nao deixa ninguem com um posto que deixou de existir.
	quadro.clear()
	var atribuido := quadro.assign(unidades, MEIO_DIA)

	assert_dict(atribuido).is_empty()
	assert_int(unidades.job_ids[unidades.index_of(ids[0])]).is_equal(UnitSystem.NENHUM)


func test_o_vagabundo_por_recrutar_nao_trabalha() -> void:
	# Quem nao e de ninguem anda atras de moedas (F1-04), nao de postos.
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var dados := Registry.entry(&"units", &"vagrant") as UnitData
	unidades.spawn(estado, dados, RecruitSystem.SEM_DONO, 0.0)
	var quadro := _quadro()
	quadro.post(JobSlot.new(&"farm", 0.0, Band.Kind.SURFACE))

	assert_dict(quadro.assign(unidades, MEIO_DIA)).is_empty()


func test_sem_adequacao_ao_posto_ninguem_e_atribuido() -> void:
	# O vagabundo tem farm 1,0 e nao tem wall nenhum (units.csv): adequacao zero
	# e score zero, e o §52 nao poe gente onde ela nao serve.
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var dados := Registry.entry(&"units", &"vagrant") as UnitData
	unidades.spawn(estado, dados, MEU_IMPERIO, 0.0)
	var quadro := _quadro()
	quadro.post(JobSlot.new(&"wall", 0.0, Band.Kind.SURFACE))

	assert_dict(quadro.assign(unidades, NOITE)).is_empty()
