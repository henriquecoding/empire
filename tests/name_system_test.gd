# tests/name_system_test.gd — XIII-05: ninguem tem nome ate merecer um (§76).
#
# O teto, o luto e os feitos vem de economy.csv e titles.csv. Nenhum numero de
# balanceamento esta aqui.
extends GdUnitTestSuite

const DONO := 7


func _curva() -> EconomyCurve:
	return Registry.entry(&"economy", &"curve") as EconomyCurve


func _titulo(id: StringName) -> TitleData:
	return Registry.entry(&"lore/titles", id) as TitleData


func _tropa(u: UnitSystem, e: GameState) -> int:
	return u.spawn(e, Registry.entry(&"units", &"archer") as UnitData, DONO, 100.0)


## Uma morte de criatura como o CombatSystem a devolve.
func _morte(quem: int, tipo: StringName) -> Dictionary:
	return {
		CombatSystem.CHAVE: CombatSystem.EV_MORTE,
		CombatSystem.CRIATURA: true,
		CombatSystem.POR: quem,
		CombatSystem.TIPO: tipo,
	}


func _matar(n: NameSystem, u: UnitSystem, quem: int, quantas: int, tipo := &"crawler") -> void:
	var eventos: Array[Dictionary] = []
	for _k in quantas:
		eventos.append(_morte(quem, tipo))
	n.observe(eventos, u, SimFactory.rot())


func test_ninguem_tem_nome_sem_feito() -> void:
	var n := SimFactory.names()
	var u := UnitSystem.new()
	var e := GameState.new()
	_tropa(u, e)
	assert_array(n.at_dawn(e, u, null)).is_empty()
	assert_int(n.named_count()).is_equal(0)


func test_o_contador_ganha_se_na_alvorada() -> void:
	var n := SimFactory.names()
	var u := UnitSystem.new()
	var e := GameState.new()
	var quem := _tropa(u, e)
	var precisa := int(_titulo(&"the_counter").condition_value)
	_matar(n, u, quem, precisa - 1)
	assert_array(n.at_dawn(e, u, null)).is_empty()
	_matar(n, u, quem, 1)
	var ev := n.at_dawn(e, u, null)
	assert_int(ev[0][NameSystem.CHAVE]).is_equal(NameSystem.EV_NOMEADO)
	assert_str(String(n.title_of(quem))).is_equal("the_counter")
	assert_int(n.ordinal_of(quem)).is_equal(1)


func test_partir_o_cerco_e_o_ultimo_golpe_num_ariete() -> void:
	var n := SimFactory.names()
	var u := UnitSystem.new()
	var e := GameState.new()
	var quem := _tropa(u, e)
	_matar(n, u, quem, 1, &"slime_ram")
	n.at_dawn(e, u, null)
	assert_str(String(n.title_of(quem))).is_equal("the_one_who_broke_stone")


func test_o_que_ficou_ganha_vida_maxima() -> void:
	var n := SimFactory.names()
	var u := UnitSystem.new()
	var e := GameState.new()
	var quem := _tropa(u, e)
	var i := u.index_of(quem)
	var antes := u.max_healths[i]
	n.feats[quem] = {&"nights_in_siege_post": _titulo(&"the_one_who_stayed").condition_value}
	n.at_dawn(e, u, null)
	assert_str(String(n.title_of(quem))).is_equal("the_one_who_stayed")
	assert_int(u.max_healths[i]).is_equal(antes + int(_titulo(&"the_one_who_stayed").grant_value))


func test_falou_com_ela_quem_esteve_dentro_da_mancha_e_saiu_vivo() -> void:
	var n := SimFactory.names()
	var u := UnitSystem.new()
	var e := GameState.new()
	var quem := _tropa(u, e)
	var rot := SimFactory.rot()
	rot.spawn(3, 1, 100.0)  # nasce em x = 100, em cima dela
	n.observe([], u, rot)
	n.at_dawn(e, u, null)
	assert_str(String(n.title_of(quem))).is_equal("she_who_spoke_with_her")


func test_nove_no_maximo_e_o_decimo_fica_a_espera() -> void:
	var n := SimFactory.names()
	var u := UnitSystem.new()
	var e := GameState.new()
	var cap := _curva().named_cap
	var ids: Array[int] = []
	for _k in cap + 1:
		ids.append(_tropa(u, e))
	# Os nove titulos estao todos ocupados por outros: o decimo nao tem vaga.
	for k in cap:
		n.titles_of[ids[k]] = StringName("t%d" % k)
	n.feats[ids[cap]] = {&"kills": 99.0}
	var ev := n.at_dawn(e, u, null)
	assert_int(ev[0][NameSystem.CHAVE]).is_equal(NameSystem.EV_A_ESPERA)
	assert_array(Array(n.waiting)).is_equal([ids[cap]])
	assert_int(n.named_count()).is_equal(cap)


func test_morto_o_dono_o_titulo_fica_de_luto_e_volta_com_ordinal() -> void:
	var n := SimFactory.names()
	var u := UnitSystem.new()
	var e := GameState.new()
	var primeiro := _tropa(u, e)
	var segundo := _tropa(u, e)
	n.feats[primeiro] = {&"kills": 99.0}
	n.at_dawn(e, u, null)
	n.feats[segundo] = {&"kills": 99.0}
	u.states[u.index_of(primeiro)] = UnitFsm.State.DEAD
	var caidos := n.bury(e, u)
	assert_bool(caidos.has(primeiro)).is_true()
	assert_int(n.named_count()).is_equal(0)
	for d in _curva().title_mourning_days:
		e.day = 1 + d
		n.at_dawn(e, u, null)
		assert_str(String(n.title_of(segundo))).is_equal("")  # de luto
	e.day = 1 + _curva().title_mourning_days
	n.at_dawn(e, u, null)
	assert_str(String(n.title_of(segundo))).is_equal("the_counter")
	assert_int(n.ordinal_of(segundo)).is_equal(2)  # "O Segundo"


func test_os_nomes_sobrevivem_ao_save() -> void:
	var n := SimFactory.names()
	var u := UnitSystem.new()
	var e := GameState.new()
	var quem := _tropa(u, e)
	n.feats[quem] = {&"kills": 99.0}
	n.at_dawn(e, u, null)
	var copia := SimFactory.names()
	copia.from_dict(n.to_dict())
	assert_str(String(copia.title_of(quem))).is_equal("the_counter")
	assert_int(copia.ordinal_of(quem)).is_equal(1)
