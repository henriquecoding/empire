# tests/diario_na_ruina_test.gd — o XIII-08 comeca a ler-se: o diario 1 esta
# numa ruina dentro das tuas muralhas desde o dia 1 (§79), e acha-se como um
# segredo do §17 — entrando la com o rei.
extends GdUnitTestSuite

const DIARIO := &"journal_01"
const X := 500.0
const LARGURA := 64.0
const LONGE := 400.0
const MEU := 1


func _rei(estado: GameState, u: UnitSystem, x: float) -> int:
	return u.spawn(estado, Registry.entry(&"units", &"monarch") as UnitData, MEU, x)


func test_o_rei_na_ruina_acha_o_diario() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var rei := _rei(estado, u, X)
	var s := SecretSites.new()
	s.post_journal(DIARIO, X, LARGURA)
	var achados := s.tick(u, rei, estado)
	assert_int(achados.size()).is_equal(1)
	assert_str(String(achados[0][SecretSites.ID])).is_equal(String(DIARIO))
	assert_int(int(achados[0][SecretSites.SEMENTES])).is_equal(0)
	assert_bool(estado.found.has(String(DIARIO))).is_true()
	assert_int(estado.royal_seeds).is_equal(0)


func test_o_diario_acha_se_uma_vez() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var rei := _rei(estado, u, X)
	var s := SecretSites.new()
	s.post_journal(DIARIO, X, LARGURA)
	s.tick(u, rei, estado)
	assert_int(s.tick(u, rei, estado).size()).is_equal(0)
	assert_int(Array(estado.found).count(String(DIARIO))).is_equal(1)


func test_longe_da_ruina_nao_se_acha() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var rei := _rei(estado, u, X + LONGE)
	var s := SecretSites.new()
	s.post_journal(DIARIO, X, LARGURA)
	assert_int(s.tick(u, rei, estado).size()).is_equal(0)


func test_o_greybox_poe_o_diario_da_ruina_dentro_das_muralhas() -> void:
	SimLoop.start(1)
	Greybox.region()
	var s := SimLoop.secrets
	var k := s.ids.find(DIARIO)
	assert_int(k).is_not_equal(-1)
	var de_dentro := Greybox.MUROS_X.filter(func(m: float) -> bool: return absf(m) < LONGE * 2)
	var perto: float = de_dentro.map(func(m: float) -> float: return absf(m)).min()
	assert_float(absf(s.xs[k] - SimLoop.core_x)).is_less(perto)
	assert_int(s.bands[k]).is_equal(int(Band.Kind.SURFACE))
	SimLoop.stop()


func test_so_os_diarios_de_ruina_vao_para_a_ruina() -> void:
	SimLoop.start(1)
	Greybox.region()
	for id in SimLoop.secrets.ids:
		var d := (
			Registry.entry(&"lore/journals", id)
			if Registry.has_entry(&"lore/journals", id)
			else null
		)
		if d != null:
			assert_str(String((d as JournalData).where_kind)).is_equal("ruin")
	SimLoop.stop()


# ─── O que se le ─────────────────────────────────────────────────────────────


func test_o_painel_le_o_titulo_e_o_corpo_do_diario() -> void:
	var dados := Registry.entry(&"lore/journals", DIARIO) as JournalData
	var texto := JournalPanel.text_of(DIARIO)
	assert_str(texto[JournalPanel.TITULO]).is_equal(TranslationServer.translate(dados.title_key))
	assert_str(texto[JournalPanel.CORPO]).is_equal(TranslationServer.translate(dados.body_key))
	assert_str(texto[JournalPanel.CORPO]).is_not_empty()


func test_um_segredo_que_nao_e_diario_nao_abre_o_painel() -> void:
	assert_bool(JournalPanel.text_of(&"root_chamber").is_empty()).is_true()
