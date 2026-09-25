# tests/nome_test.gd — o XIII-05: ninguem tem nome ate merecer um (§76).
#
# Nove nomes no maximo; o titulo ganha-se na alvorada por feito registado; e o
# luto de tres dias devolve-o com ordinal. O teto e o luto vem de economy.csv, os
# feitos e as condicoes de titles.csv. Nenhum numero de balanceamento esta aqui.
extends GdUnitTestSuite

const MEU := 7
const X := 1000.0


func _curva() -> EconomyCurve:
	return Registry.entry(&"economy", &"curve") as EconomyCurve


func _titulo(id: StringName) -> TitleData:
	return Registry.entry(&"lore/titles", id) as TitleData


func _nomes() -> TitleSystem:
	return SimFactory.titles()


func _tropa(u: UnitSystem, estado: GameState, tropa := &"archer") -> int:
	return u.spawn(estado, Registry.entry(&"units", tropa), MEU, X)


## O que o combate devolve quando esta tropa abate aquela criatura (§50).
func _abate(quem: int, criatura: int, que: StringName) -> Array[Dictionary]:
	return [
		{
			CombatSystem.CHAVE: CombatSystem.EV_DANO,
			CombatSystem.DE: quem,
			CombatSystem.PARA: criatura,
			CombatSystem.CRIATURA: true,
		},
		{
			CombatSystem.CHAVE: CombatSystem.EV_MORTE,
			CombatSystem.DE: criatura,
			CombatSystem.CRIATURA: true,
			CombatSystem.QUEM: que,
		},
	]


func _alvorada(nomes: TitleSystem, dia: int, u: UnitSystem) -> Array[Dictionary]:
	return nomes.at_dawn(dia, u, SimFactory.job_board())


# ─── Como se ganha ───────────────────────────────────────────────────────────


func test_o_contador_ganha_se_na_alvorada_a_seguir_ao_decimo_rastejante() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var arqueiro := _tropa(u, estado)
	var nomes := _nomes()
	var precisa := int(_titulo(&"the_counter").condition_value)
	for k in precisa - 1:
		nomes.observe(_abate(arqueiro, 1000 + k, &"crawler"))
	nomes.observe(_abate(arqueiro, 5000, &"brute"))  # nao e Rastejante
	_alvorada(nomes, 2, u)
	assert_str(nomes.title_of(arqueiro)).is_empty()
	nomes.observe(_abate(arqueiro, 2000, &"crawler"))
	assert_str(nomes.title_of(arqueiro)).is_empty()  # so na alvorada
	var eventos := _alvorada(nomes, 3, u)
	assert_str(nomes.title_of(arqueiro)).is_equal("the_counter")
	assert_int(eventos[0][TitleSystem.CHAVE]).is_equal(TitleSystem.EV_NOMEADO)
	assert_int(nomes.ordinal_of(&"the_counter")).is_equal(1)


func test_o_que_partiu_a_pedra_e_o_golpe_final_num_ariete() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var lanceiro := _tropa(u, estado, &"spearman")
	var outro := _tropa(u, estado)
	var nomes := _nomes()
	# O outro bate primeiro; o golpe final e do lanceiro.
	nomes.observe(_abate(outro, 77, &"slime_ram").slice(0, 1))
	nomes.observe(_abate(lanceiro, 77, &"slime_ram"))
	_alvorada(nomes, 2, u)
	assert_str(nomes.title_of(lanceiro)).is_equal("the_one_who_broke_stone")
	assert_str(nomes.title_of(outro)).is_empty()


func test_o_que_ficou_sao_cinco_noites_vivo_em_posto_de_cerco() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var arqueiro := _tropa(u, estado)
	var postos := SimFactory.job_board()
	postos.post(JobSlot.new(&"wall", X, Band.Kind.SURFACE))
	u.job_ids[u.index_of(arqueiro)] = 0
	var nomes := _nomes()
	var noites := int(_titulo(&"the_one_who_stayed").condition_value)
	for dia in range(2, 2 + noites - 1):
		nomes.at_dawn(dia, u, postos)
	assert_str(nomes.title_of(arqueiro)).is_empty()
	nomes.at_dawn(2 + noites, u, postos)
	assert_str(nomes.title_of(arqueiro)).is_equal("the_one_who_stayed")


func test_a_que_falou_com_ela_esteve_dentro_da_mancha_e_saiu_viva() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var dentro := _tropa(u, estado)
	var morta := _tropa(u, estado)
	var nomes := _nomes()
	nomes.stain(u, X - 10.0, X + 10.0)
	u.states[u.index_of(morta)] = UnitFsm.State.DEAD
	_alvorada(nomes, 2, u)
	assert_str(nomes.title_of(dentro)).is_equal("she_who_spoke_with_her")
	assert_str(nomes.title_of(morta)).is_empty()


func test_o_titulo_da_mais_vida_maxima() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var arqueiro := _tropa(u, estado)
	var antes := u.max_healths[u.index_of(arqueiro)]
	var nomes := _nomes()
	var postos := SimFactory.job_board()
	postos.post(JobSlot.new(&"wall", X, Band.Kind.SURFACE))
	u.job_ids[u.index_of(arqueiro)] = 0
	for dia in range(2, 2 + int(_titulo(&"the_one_who_stayed").condition_value)):
		nomes.at_dawn(dia, u, postos)
	var ganho := int(_titulo(&"the_one_who_stayed").grant_value)
	assert_int(u.max_healths[u.index_of(arqueiro)]).is_equal(antes + ganho)


# ─── As quatro regras ────────────────────────────────────────────────────────


func test_nove_no_maximo_e_o_decimo_fica_a_espera_ate_abrir_vaga() -> void:
	# Nove titulos, cada um unico enquanto o dono vive: com os nove dados, a
	# decima que cumpre um feito para um passo a frente e espera (§76).
	var estado := GameState.new()
	var u := UnitSystem.new()
	var teto := _curva().named_cap
	var donos := {}
	var ids: Array[String] = []
	for t: TitleData in Registry.entries(&"lore/titles"):
		ids.append(String(t.id))
	ids.sort()
	var tropas: Array[int] = []
	for k in teto + 1:
		tropas.append(_tropa(u, estado))
	for k in teto:
		donos[ids[k]] = tropas[k]
	var nomes := _nomes()
	nomes.from_dict({&"titles_holder": donos})
	var decima := tropas[teto]
	nomes.stain(u, X - 10.0, X + 10.0)
	var eventos := _alvorada(nomes, 2, u)
	assert_int(nomes.count()).is_equal(teto)
	assert_str(nomes.title_of(decima)).is_empty()
	assert_bool(nomes.waiting.has(decima)).is_true()
	var esperas := 0
	for e in eventos:
		if e[TitleSystem.CHAVE] == TitleSystem.EV_ESPERA:
			esperas += 1
	assert_int(esperas).is_equal(1)
	# Morre a dona do titulo dela: abre vaga, mas so depois do luto.
	u.remove(donos["she_who_spoke_with_her"])
	var luto := _curva().title_mourning_days
	for dia in range(3, 3 + luto):
		_alvorada(nomes, dia, u)
		assert_str(nomes.title_of(decima)).is_empty()
		assert_int(nomes.count()).is_equal(teto - 1)
	_alvorada(nomes, 3 + luto, u)
	assert_str(nomes.title_of(decima)).is_equal("she_who_spoke_with_her")
	assert_int(nomes.count()).is_equal(teto)
	assert_bool(nomes.waiting.has(decima)).is_false()


func test_morto_o_dono_o_titulo_fica_de_luto_e_volta_com_ordinal() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var primeira := _tropa(u, estado)
	var segunda := _tropa(u, estado)
	var nomes := _nomes()
	nomes.stain(u, X - 10.0, X + 10.0)
	u.remove(segunda)  # so a primeira esteve la
	_alvorada(nomes, 2, u)
	assert_str(nomes.title_of(primeira)).is_equal("she_who_spoke_with_her")
	segunda = _tropa(u, estado)
	u.remove(primeira)
	var luto := _curva().title_mourning_days
	for dia in range(3, 3 + luto):
		nomes.stain(u, X - 10.0, X + 10.0)
		_alvorada(nomes, dia, u)
		assert_str(nomes.title_of(segunda)).is_empty()
	nomes.stain(u, X - 10.0, X + 10.0)
	_alvorada(nomes, 3 + luto, u)
	assert_str(nomes.title_of(segunda)).is_equal("she_who_spoke_with_her")
	assert_int(nomes.ordinal_of(&"she_who_spoke_with_her")).is_equal(2)


func test_o_monarca_e_os_vagabundos_por_recrutar_nao_ganham_nome() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var rei := _tropa(u, estado, &"monarch")
	var vagabundo := u.spawn(estado, Registry.entry(&"units", &"vagrant"), 0, X)
	var nomes := _nomes()
	nomes.stain(u, X - 10.0, X + 10.0)
	_alvorada(nomes, 2, u)
	assert_str(nomes.title_of(rei)).is_empty()
	assert_str(nomes.title_of(vagabundo)).is_empty()


func test_o_save_tem_os_nomes_da_84() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var a := _tropa(u, estado)
	var nomes := _nomes()
	nomes.stain(u, X - 10.0, X + 10.0)
	_alvorada(nomes, 2, u)
	var d := nomes.to_dict()
	for campo in [&"titles_holder", &"titles_ordinal", &"titles_mourning"]:
		assert_bool(d.has(campo)).is_true()
	var lido := _nomes()
	lido.from_dict(d)
	assert_str(lido.title_of(a)).is_equal("she_who_spoke_with_her")
	assert_int(lido.ordinal_of(&"she_who_spoke_with_her")).is_equal(1)
	assert_dict(lido.by_unit()).is_equal(nomes.by_unit())
