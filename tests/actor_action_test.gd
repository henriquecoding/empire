# tests/actor_action_test.gd — o contrato de accoes da arte (planejamento 26/09, lote 4).
#
# A apresentacao le o que a simulacao decidiu e escolhe a tag; nao decide nada.
# O que se prova aqui: a prioridade das reaccoes, a cadeia de recurso quando a
# arte ainda nao tem a tag, e que uma accao de uma vez fica no ultimo frame.
extends GdUnitTestSuite

const S := UnitFsm.State
const K := ActorAction.Kind
const IDLE_MS := [100, 100, 100, 100, 150, 100]


func test_a_morte_passa_a_frente_de_tudo() -> void:
	assert_int(ActorAction.of(S.DEAD, true, true)).is_equal(K.DIE)


func test_o_dano_imediato_passa_a_frente_do_medo_e_da_accao() -> void:
	assert_int(ActorAction.of(S.FLEE, true, true)).is_equal(K.HIT)
	assert_int(ActorAction.of(S.FIGHT, false, true)).is_equal(K.HIT)


func test_o_medo_passa_a_frente_do_combate_e_do_andar() -> void:
	assert_int(ActorAction.of(S.FLEE, true, false)).is_equal(K.FLEE)


func test_quem_combate_ataca_mesmo_parado() -> void:
	assert_int(ActorAction.of(S.FIGHT, false, false)).is_equal(K.ATTACK)


func test_andar_passa_a_frente_do_trabalho_e_o_trabalho_do_repouso() -> void:
	assert_int(ActorAction.of(S.WORK, true, false)).is_equal(K.WALK)
	assert_int(ActorAction.of(S.GOTO, true, false)).is_equal(K.WALK)
	assert_int(ActorAction.of(S.WORK, false, false)).is_equal(K.WORK)
	assert_int(ActorAction.of(S.GOTO, false, false)).is_equal(K.IDLE)


func test_sem_a_tag_na_arte_mostra_se_o_repouso_e_nunca_outra_accao() -> void:
	var art := OriginalArt.new()
	# A tropa original so tem `idle` exportado: o resto cai para ele.
	for kind in [K.WALK, K.WORK, K.ATTACK, K.HIT, K.FLEE, K.DIE]:
		assert_int(ActorAction.shown(art, &"knight", kind)).is_equal(K.IDLE)
	assert_bool(art.has_action(&"knight", &"idle")).is_true()
	assert_bool(art.has_action(&"knight", &"walk")).is_false()
	# O rei tem um frame e nenhuma tag: continua a desenhar-se.
	assert_int(ActorAction.shown(art, &"monarch", K.WALK)).is_equal(K.IDLE)
	assert_int(art.frame_at(&"monarch", 3.0, &"walk")).is_equal(0)


func test_fugir_sem_arte_propria_usa_a_caminhada() -> void:
	assert_int(ActorAction.FALLBACK[K.FLEE]).is_equal(K.WALK)
	assert_bool(ActorAction.loops(K.WALK)).is_true()
	assert_bool(ActorAction.loops(K.DIE)).is_false()
	assert_bool(ActorAction.loops(K.HIT)).is_false()


func test_cada_accao_tem_uma_tag_propria() -> void:
	var nomes := {}
	for kind in K.values():
		nomes[ActorAction.TAGS[kind]] = true
	assert_int(nomes.size()).is_equal(K.size())


func test_uma_tag_percorre_so_os_seus_frames() -> void:
	var ms := [100, 100, 100, 100, 150, 100, 80, 80, 80, 80]
	# Uma caminhada hipotetica nos frames 6..9: 320 ms por volta.
	assert_int(OriginalArt.frame_in(ms, 6, 9, 0.0, true)).is_equal(6)
	assert_int(OriginalArt.frame_in(ms, 6, 9, 250.0, true)).is_equal(9)
	assert_int(OriginalArt.frame_in(ms, 6, 9, 330.0, true)).is_equal(6)


func test_uma_accao_de_uma_vez_fica_no_ultimo_frame() -> void:
	assert_int(OriginalArt.frame_in(IDLE_MS, 0, 5, 649.0, false)).is_equal(5)
	assert_int(OriginalArt.frame_in(IDLE_MS, 0, 5, 5000.0, false)).is_equal(5)
	assert_int(OriginalArt.frame_in(IDLE_MS, 0, 5, 5200.0, true)).is_equal(0)


func test_o_idle_original_continua_igual_pela_tag() -> void:
	var art := OriginalArt.new()
	assert_int(art.frame_at(&"knight", 0.549, &"idle")).is_equal(4)
	assert_int(art.frame_at(&"knight", 0.550, &"idle")).is_equal(5)
