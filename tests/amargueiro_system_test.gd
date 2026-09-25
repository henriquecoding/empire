# tests/amargueiro_system_test.gd — o XIII-03, primeira metade: uma tropa que
# morre fora das muralhas e nao e recolhida cria raiz na alvorada, e cada arvore
# de pe e massa na noite seguinte (§74).
#
# Os numeros vem de data/: a massa e a noite de pe de rot.csv, a escala de
# units.csv. A geometria da regiao de teste esta em tests/support/bosque.gd.
extends GdUnitTestSuite

const B := preload("res://tests/support/bosque.gd")

# ─── Onde nasce, e onde nao ──────────────────────────────────────────────────


func test_morto_fora_das_muralhas_cria_raiz_na_alvorada() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var o := BuildSystem.new()
	B.muro(o, B.MURO)
	var morto := B.morto(u, estado, &"archer", B.FORA)
	var bosque := SimFactory.amargueiros()
	B.alvorada(bosque, 3, u, o)
	assert_int(bosque.count()).is_equal(1)
	assert_float(bosque.xs[0]).is_equal(B.FORA)
	assert_int(bosque.tiers[0]).is_equal(2)
	assert_int(bosque.days[0]).is_equal(3)
	assert_int(u.index_of(morto)).is_equal(UnitSystem.NENHUM)  # o corpo levantou-se


func test_morto_dentro_das_muralhas_desaparece_e_nao_cria() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var o := BuildSystem.new()
	B.muro(o, B.MURO)
	var morto := B.morto(u, estado, &"archer", B.DENTRO)
	var no_muro := B.morto(u, estado, &"archer", B.MURO)  # caiu em cima do muro
	# O posto do muro reparte-se pela largura dele (JobBoard): quem la morre, fora
	# do centro mas em cima da pedra, morreu dentro.
	var no_posto := B.morto(u, estado, &"archer", B.MURO + o.slots[0].width * 0.4)
	var bosque := SimFactory.amargueiros()
	B.alvorada(bosque, 3, u, o)
	assert_int(bosque.count()).is_equal(0)
	assert_int(u.index_of(morto)).is_equal(UnitSystem.NENHUM)  # perda normal
	assert_int(u.index_of(no_muro)).is_equal(UnitSystem.NENHUM)
	assert_int(u.index_of(no_posto)).is_equal(UnitSystem.NENHUM)


func test_sem_muro_de_pe_tudo_e_fora() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	B.morto(u, estado, &"archer", B.DENTRO)
	var bosque := SimFactory.amargueiros()
	B.alvorada(bosque, 3, u, BuildSystem.new())
	assert_int(bosque.count()).is_equal(1)


func test_no_subsolo_cria_raiz_mesmo_debaixo_do_muro() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var o := BuildSystem.new()
	B.muro(o, B.MURO)
	B.morto(u, estado, &"digger", B.DENTRO)
	u.bands[0] = int(Band.Kind.UNDERGROUND)
	var bosque := SimFactory.amargueiros()
	B.alvorada(bosque, 3, u, o)
	assert_int(bosque.count()).is_equal(1)
	assert_int(bosque.bands[0]).is_equal(int(Band.Kind.UNDERGROUND))


func test_na_faixa_aerea_nao_ha_corpos_as_voadoras_caem() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	B.morto(u, estado, &"dragonfly", B.FORA)
	var bosque := SimFactory.amargueiros()
	B.alvorada(bosque, 3, u, BuildSystem.new())
	assert_int(bosque.count()).is_equal(1)
	assert_int(bosque.bands[0]).is_equal(int(Band.Kind.SURFACE))


func test_quem_esta_vivo_ou_nao_e_teu_nao_cria_raiz() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var vivo := u.spawn(estado, Registry.entry(&"units", &"archer"), B.MEU_IMPERIO, B.FORA)
	var alheio := B.morto(u, estado, &"vagrant", B.FORA)
	u.owners[u.index_of(alheio)] = RecruitSystem.SEM_DONO
	var bosque := SimFactory.amargueiros()
	B.alvorada(bosque, 3, u, BuildSystem.new())
	assert_int(bosque.count()).is_equal(0)
	assert_int(u.index_of(vivo)).is_not_equal(UnitSystem.NENHUM)


# ─── Regra 3: rende o que a pessoa era ───────────────────────────────────────


func test_a_escala_e_a_da_pessoa_e_o_vagabundo_e_escala_1() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	B.morto(u, estado, &"vagrant", B.FORA)
	B.morto(u, estado, &"archer", B.FORA + 100.0)
	B.morto(u, estado, &"root_berserker", B.FORA + 200.0)
	var bosque := SimFactory.amargueiros()
	B.alvorada(bosque, 3, u, BuildSystem.new())
	assert_array(Array(bosque.tiers)).is_equal([1, 2, 3])


# ─── A massa: +22, ou +45 com nome ───────────────────────────────────────────


func test_as_arvores_de_pe_sao_o_termo_da_massa() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var nomeado := B.morto(u, estado, &"archer", B.FORA)
	B.morto(u, estado, &"archer", B.FORA + 100.0)
	B.morto(u, estado, &"archer", B.FORA + 200.0)
	var bosque := SimFactory.amargueiros()
	bosque.at_dawn(3, u, BuildSystem.new(), B.NUCLEO, B.LARGURA, {nomeado: B.TITULO})
	assert_int(bosque.anonymous()).is_equal(2)
	assert_int(bosque.named()).is_equal(1)
	assert_str(bosque.titles[0]).is_equal(B.TITULO)


# ─── As regras, perguntadas a direito ────────────────────────────────────────


func test_as_regras_de_onde_nasce_perguntadas_sem_alvorada() -> void:
	var tropas := SimFactory.by_id(&"units")
	var regras := AmargueiroRoots.new(B.perfil(), tropas, 3)
	var o := BuildSystem.new()
	B.muro(o, B.MURO)
	var mundo := Vector2(B.NUCLEO, B.LARGURA)
	var nada: Array[Vector2] = []
	assert_bool(regras.roots(B.FORA, int(Band.Kind.SURFACE), o, mundo, nada)).is_true()
	assert_bool(regras.roots(B.DENTRO, int(Band.Kind.SURFACE), o, mundo, nada)).is_false()
	assert_bool(regras.roots(B.DENTRO, int(Band.Kind.UNDERGROUND), o, mundo, nada)).is_true()
	var marco: Array[Vector2] = [Vector2(B.FORA - 1.0, B.FORA + 1.0)]
	assert_bool(regras.roots(B.FORA, int(Band.Kind.SURFACE), o, mundo, marco)).is_false()
	assert_int(regras.tier(&"vagrant")).is_equal(1)
	assert_int(regras.tier(&"monarch")).is_equal(3)
	assert_int(regras.tier(&"squire")).is_equal(1)
	assert_int(AmargueiroRoots.body_band(int(Band.Kind.AERIAL))).is_equal(int(Band.Kind.SURFACE))
