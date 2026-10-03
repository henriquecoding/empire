extends GdUnitTestSuite

var obras: BuildSystem
var sede: BuildSlot
var estado: GameState


func before_test() -> void:
	RulesFactory.install_realm_gates()
	obras = BuildSystem.new()
	estado = GameState.new()
	sede = obras.post(SeatSite.slot(0.0))
	sede.raise_to(RealmLadder.FUNDADO)


func test_camp_tem_ferramentas_primeiro_canteiro_e_so_o_proximo_muro_de_cada_lado() -> void:
	var perto := _site(&"farm", 200.0)
	var longe := _site(&"farm", 400.0)
	var oeste := _wall(-700.0)
	var leste := _wall(700.0)
	var fora := _wall(1400.0)
	assert_bool(RealmGrowth.visible(obras, _site(&"hammer_rack", -500.0))).is_true()
	assert_bool(RealmGrowth.visible(obras, perto)).is_true()
	assert_bool(RealmGrowth.visible(obras, longe)).is_false()
	assert_bool(RealmGrowth.next_wall(obras, oeste)).is_true()
	assert_bool(RealmGrowth.next_wall(obras, leste)).is_true()
	assert_bool(RealmGrowth.next_wall(obras, fora)).is_false()
	leste.raise_to(1)
	assert_bool(RealmGrowth.visible(obras, longe)).is_true()
	assert_bool(RealmGrowth.next_wall(obras, fora)).is_true()


func test_povoado_pede_area_defendida_do_lado_certo_com_edificio_inteiro() -> void:
	sede.raise_to(2)
	var treino := _site(&"training_house", 500.0)
	var muro := _wall(-700.0)
	muro.raise_to(1)
	assert_int(RealmGrowth.refusal(obras, treino)).is_equal(RealmGrowth.Need.WALL)
	assert_bool(obras.can_climb(treino, estado, null)).is_false()
	muro.x = treino.x + treino.width * 0.5 - 1.0
	assert_bool(RealmGrowth.protected(obras, treino)).is_false()
	muro.x += 2.0
	assert_bool(RealmGrowth.protected(obras, treino)).is_true()
	assert_bool(obras.can_climb(treino, estado, null)).is_true()


func test_defesa_em_obra_ruina_torre_ou_povo_vizinho_nao_reivindica_territorio() -> void:
	sede.raise_to(2)
	var treino := _site(&"training_house", 500.0)
	var torre := _site(&"archer_tower", 800.0)
	torre.raise_to(1)
	var muro := _wall(700.0)
	muro.state = BuildSlot.State.BUILDING
	assert_bool(RealmGrowth.protected(obras, treino)).is_false()
	muro.raise_to(1)
	muro.territory = 1
	assert_bool(RealmGrowth.protected(obras, treino)).is_false()
	muro.territory = 0
	muro.state = BuildSlot.State.RUIN
	assert_bool(RealmGrowth.protected(obras, treino)).is_false()


func test_torre_avanca_apenas_ate_a_proxima_frente_com_muro_de_pe() -> void:
	sede.raise_to(2)
	var dentro := _site(&"archer_tower", 900.0)
	var fora := _site(&"archer_tower", 1500.0)
	var muro := _wall(700.0)
	_wall(1400.0)
	assert_bool(RealmGrowth.allows(obras, dentro)).is_false()
	muro.raise_to(1)
	assert_bool(RealmGrowth.allows(obras, dentro)).is_true()
	assert_int(RealmGrowth.refusal(obras, fora)).is_equal(RealmGrowth.Need.FRONTIER)


func test_vila_combina_estagio_palicada_e_producao_de_apoio() -> void:
	sede.raise_to(2)
	var cozinha := _site(&"kitchen", 500.0)
	var muro := _wall(700.0)
	muro.raise_to(2)
	assert_bool(RealmGrowth.visible(obras, cozinha)).is_false()
	sede.raise_to(3)
	assert_int(RealmGrowth.refusal(obras, cozinha)).is_equal(RealmGrowth.Need.SUPPLY)
	var fonte := _site(&"henhouse", 300.0)
	fonte.raise_to(1)
	assert_bool(RealmGrowth.supplied(obras, [&"henhouse"])).is_true()
	assert_bool(RealmGrowth.visible(obras, cozinha)).is_true()
	muro.raise_to(1)
	assert_bool(RealmGrowth.visible(obras, cozinha)).is_false()


func test_catalogo_novo_sem_regra_fica_fechado_mas_obras_herdadas_continuam_visiveis() -> void:
	sede.raise_to(5)
	var nova := obras.post(BuildSlot.new())
	nova.kind = &"unlisted_building"
	assert_int(RealmGrowth.refusal(obras, nova)).is_equal(RealmGrowth.Need.UNLISTED)
	assert_bool(RealmLadder.allows(obras, nova)).is_false()
	assert_bool(RealmGrowth.visible(obras, nova)).is_false()
	nova.paid = 1
	assert_bool(RealmGrowth.visible(obras, nova)).is_true()
	nova.paid = 0
	nova.state = BuildSlot.State.RUIN
	assert_bool(RealmGrowth.visible(obras, nova)).is_true()
	nova.level = 1
	assert_bool(RealmGrowth.allows(obras, nova)).is_true()


func test_construcao_conquistada_preserva_autonomia_e_moeda_antiga_nao_paga_convite_novo() -> void:
	var vaga := _site(&"training_house", 500.0)
	var moedas := CoinSystem.new(SimFactory.curve())
	var id := moedas.drop(estado, vaga.x, Band.Kind.SURFACE, 1, 0.0)
	CoinTarget.aim(moedas, id, obras, true, estado)
	moedas.settled[moedas.index_of(id)] = 1
	vaga.territory = 1
	assert_bool(RealmGrowth.visible(obras, vaga)).is_true()
	assert_bool(RealmLadder.allows(obras, vaga)).is_true()
	assert_bool(CoinTarget.pays(moedas, moedas.index_of(id), vaga)).is_false()


func _site(kind: StringName, x: float) -> BuildSlot:
	return obras.post(Greybox.slot_of(Registry.entry(&"buildings", kind) as BuildingData, x))


func _wall(x: float) -> BuildSlot:
	return obras.post(WallSite.slot(x))
