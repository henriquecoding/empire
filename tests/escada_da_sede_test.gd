# tests/escada_da_sede_test.gd — a escada da sede, sozinha (ADR 0059).
#
# O RealmLadder diz o que cada estagio abre; o RealmSeat guarda a carroca e o alvo da
# moeda no nucleo; o BuildSlot da sede sobe com a largura e a vida de cada estagio.
extends GdUnitTestSuite

const X := 1000.0


func before_test() -> void:
	RulesFactory.install_realm_gates()


func _obras_com_sede(nivel: int) -> BuildSystem:
	var obras := BuildSystem.new()
	var sede := obras.post(SeatSite.slot(X))
	sede.raise_to(nivel)
	return obras


func _obra(kind: StringName) -> BuildSlot:
	var dados := Registry.entry(&"buildings", kind) as BuildingData
	return Greybox.slot_of(dados, X + 500.0)


func test_a_escada_vem_dos_dados_da_clareira_a_fortaleza() -> void:
	var estagios := RulesFactory.realm_stages()
	assert_int(estagios.size()).is_equal(6)
	assert_str(String(estagios[0].id)).is_equal("clearing")
	assert_str(String(estagios[5].id)).is_equal("fortress")
	var sede := SeatSite.slot(X)
	assert_int(sede.costs.size()).is_equal(5)
	assert_int(sede.costs[0]).is_equal(estagios[1].cost)
	assert_int(sede.level).is_equal(RealmLadder.CLAREIRA)
	assert_bool(sede.standing()).is_false()
	assert_bool(sede.holds()).is_false()


## O castelo de antes e a Fortaleza: a vida, a largura e os slots de contacto do nucleo.
func test_a_fortaleza_e_o_castelo_de_antes() -> void:
	var castelo := Registry.entry(&"buildings", BuildSlot.NUCLEO) as BuildingData
	var sede := SeatSite.slot(X)
	sede.raise_to(sede.costs.size())
	assert_int(sede.max_health()).is_equal(castelo.max_health)
	assert_float(sede.width).is_equal(float(castelo.width_px))
	assert_int(sede.contact_slots()).is_equal(castelo.contact_slots)


func test_sem_nucleo_nada_se_fecha() -> void:
	var obras := BuildSystem.new()
	assert_int(RealmLadder.stage(obras)).is_equal(RealmLadder.NENHUM)
	assert_bool(RealmLadder.allows(obras, _obra(&"forge"))).is_true()
	assert_bool(RealmLadder.founded(obras)).is_true()


func test_na_clareira_so_a_propria_sede_se_paga() -> void:
	var obras := _obras_com_sede(RealmLadder.CLAREIRA)
	assert_bool(RealmLadder.founded(obras)).is_false()
	assert_bool(RealmLadder.allows(obras, RealmLadder.seat(obras))).is_true()
	assert_bool(RealmLadder.allows(obras, _obra(&"farm"))).is_false()


func test_cada_estagio_abre_o_que_a_coluna_unlocks_diz() -> void:
	var acampamento := _obras_com_sede(1)
	assert_bool(RealmLadder.allows(acampamento, _obra(&"farm"))).is_true()
	assert_bool(RealmLadder.allows(acampamento, _obra(&"bow_rack"))).is_true()
	assert_bool(RealmLadder.allows(acampamento, _obra(&"training_house"))).is_false()
	var povoado := _obras_com_sede(2)
	assert_bool(RealmLadder.allows(povoado, _obra(&"training_house"))).is_true()
	assert_bool(RealmLadder.allows(povoado, _obra(&"high_tower"))).is_true()
	assert_bool(RealmLadder.allows(povoado, _obra(&"kitchen"))).is_false()


## Uma obra que nenhum estagio lista abre com a fundacao: as casas dos povos, o sino.
func test_o_que_nenhum_estagio_lista_abre_com_a_fundacao() -> void:
	assert_int(RealmLadder.required(_obra(&"tender_ward"))).is_equal(RealmLadder.FUNDADO)
	assert_int(RealmLadder.required(_obra(&"enramados_house"))).is_equal(RealmLadder.FUNDADO)


## O muro abre por nivel: o degrau seguinte e o que se pergunta.
func test_o_muro_abre_degrau_a_degrau() -> void:
	var obras := _obras_com_sede(1)
	var muro := WallSite.slot(X + 680.0)
	assert_bool(RealmLadder.allows(obras, muro)).is_true()
	muro.raise_to(1)
	assert_bool(RealmLadder.allows(obras, muro)).is_false()
	RealmLadder.seat(obras).raise_to(2)
	assert_bool(RealmLadder.allows(obras, muro)).is_true()


## A largura do marco, onde a moeda da sede cai, nao cresce com a sede: a volta do
## castelo continua a haver gente por recrutar.
func test_o_marco_tem_a_largura_da_clareira_em_todos_os_estagios() -> void:
	var sede := SeatSite.slot(X)
	var marco := sede.catch_half()
	sede.raise_to(sede.costs.size())
	assert_float(sede.catch_half()).is_equal(marco)
	assert_float(sede.width * BuildSlot.METADE).is_greater(marco)


func test_subir_de_estagio_nao_cura() -> void:
	var sede := SeatSite.slot(X)
	sede.raise_to(1)
	sede.health = sede.max_health() / 2
	var antes := sede.max_health()
	sede.level = 2
	var vida := sede.raised_health(antes)
	assert_int(vida).is_equal(ceili(float(sede.max_health()) / 2.0))


func test_a_carroca_da_o_que_cabe_no_saco_e_guarda_o_resto() -> void:
	var sede := RealmSeat.new()
	sede.place_cart(X, 8)
	assert_int(sede.take_cart(X + 100.0, 24.0, 33)).is_equal(0)
	assert_int(sede.take_cart(X + 10.0, 24.0, 5)).is_equal(5)
	assert_int(sede.cart_coins).is_equal(3)
	assert_int(sede.take_cart(X, 24.0, 33)).is_equal(3)
	assert_int(sede.take_cart(X, 24.0, 33)).is_equal(0)


func test_o_alvo_do_monarca_so_existe_quando_ele_pode_evoluir() -> void:
	var sede := RealmSeat.new()
	assert_bool(sede.toggle_aim(false)).is_false()
	assert_bool(sede.toggle_aim(true)).is_true()
	assert_bool(sede.aims_monarch(true)).is_true()
	assert_bool(sede.aims_monarch(false)).is_false()
	assert_bool(sede.toggle_aim(true)).is_false()


func test_a_sede_vai_e_volta_do_save() -> void:
	var sede := RealmSeat.new()
	sede.place_cart(X, 8)
	sede.take_cart(X, 24.0, 3)
	sede.monarch_aim = true
	var outra := RealmSeat.new()
	outra.from_dict(sede.to_dict())
	assert_int(outra.cart_coins).is_equal(5)
	assert_float(outra.cart_x).is_equal(X)
	assert_bool(outra.monarch_aim).is_true()
	assert_bool(outra.inherited).is_false()
