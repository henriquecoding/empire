# tests/secret_sites_test.gd — a camara atras da passagem da a Semente Real (§17, §25).
extends GdUnitTestSuite

const CAMARA := 300.0
const LARGA := 64.0


func _camara() -> SecretData:
	return Registry.entry(&"lore/secrets", &"root_chamber") as SecretData


func _rei(u: UnitSystem, e: GameState, x: float, faixa: Band.Kind) -> int:
	var id := u.spawn(e, Registry.entry(&"units", &"monarch") as UnitData, 1, x)
	u.bands[u.index_of(id)] = faixa
	return id


func test_o_rei_na_camara_acha_a_semente_uma_vez_so() -> void:
	var s := SecretSites.new()
	s.post(_camara(), CAMARA, LARGA)
	var u := UnitSystem.new()
	var e := GameState.new()
	var rei := _rei(u, e, CAMARA, _camara().band)
	var achados := s.tick(u, rei, e)
	assert_int(achados.size()).is_equal(1)
	assert_int(e.royal_seeds).is_equal(_camara().reward_seeds)
	assert_array(Array(e.found)).is_equal(["root_chamber"])
	assert_array(s.tick(u, rei, e)).is_empty()
	assert_int(e.royal_seeds).is_equal(_camara().reward_seeds)


func test_na_outra_faixa_ou_fora_da_camara_nao_se_acha() -> void:
	var s := SecretSites.new()
	s.post(_camara(), CAMARA, LARGA)
	var u := UnitSystem.new()
	var e := GameState.new()
	var em_cima := _rei(u, e, CAMARA, Band.Kind.SURFACE)
	assert_array(s.tick(u, em_cima, e)).is_empty()
	u.bands[u.index_of(em_cima)] = _camara().band
	u.xs[u.index_of(em_cima)] = CAMARA + LARGA
	assert_array(s.tick(u, em_cima, e)).is_empty()
	assert_int(e.royal_seeds).is_equal(0)


func test_sem_rei_ninguem_acha_nada() -> void:
	var s := SecretSites.new()
	s.post(_camara(), CAMARA, LARGA)
	assert_array(s.tick(UnitSystem.new(), UnitSystem.NENHUM, GameState.new())).is_empty()
	s.chapters.append(900.0)
	s.clear()
	assert_int(s.count()).is_equal(0)
	assert_int(s.chapters.size()).is_equal(0)
