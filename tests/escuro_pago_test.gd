# tests/escuro_pago_test.gd — o escuro paga-se, e a noite 1 e a do §25 (ADR 0071, Q-241).
#
# O escuro da Q-029 («se o jogador explora a noite sem item e muito perigoso, pois podem
# aparecer inimigos de qualquer lugar») trazia ate seis Rastejantes por noite, de graca e
# a 90 px do rei, desde a primeira noite. A sonda (tools/noites.gd) viu o rei la fora na
# noite 1 com nove criaturas em vez das tres do §25, e a partida acabar nessa noite. A
# ADR 0071 poe-no na regra da §05 — a Podridao e a unica fonte de criaturas e paga-as da
# massa — e da as primeiras noites para se aprender o escuro antes de ele morder.
extends GdUnitTestSuite

const SEMENTE := 20260915
const PASSO := 1.0 / 30.0
const DIREITA := 1
## Massa que nunca acaba numa noite: o que se mede e o escuro, e nao o orcamento.
const SEM_FUNDO := 1000.0
## Onde o rei passa a noite 1 no ultimo teste: no escuro, como quem explora.
const LA_FORA := 600.0


func _perfil() -> RotProfile:
	return SimFactory.rot_profile()


func _bicho(id: StringName) -> CreatureData:
	return Registry.entry(&"creatures", id) as CreatureData


func _jogo() -> void:
	SimLoop.autosave_enabled = false
	SimLoop.start(SEMENTE)
	Greybox.build()


func _fim() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


## Um x no escuro, do lado direito do nucleo: fora dele, das muralhas e das luzes.
func _escuro() -> float:
	var meia := RealmLadder.seat(SimLoop.builds).width * BuildSystem.METADE
	var x := SimLoop.core_x + meia + _perfil().dark_ambush_px
	while not Torchlight.in_dark(x, SimLoop.builds, SimLoop.core_x, meia):
		x += 32.0
	return x


## O rei no escuro, sem archote, uma noite inteira do `dia` com `massa` na mancha.
## Devolve quantos o escuro trouxe.
func _noite_no_escuro(dia: int, massa: float) -> int:
	var noite := SimLoop.night
	SimLoop.state.day = dia
	noite.rot.spawn(dia, DIREITA, SimLoop.world_width)
	noite.rot.state.mass = massa
	noite.dark.torch.torches = 0
	var r := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.xs[r] = _escuro()
	var antes := SimLoop.creatures.count()
	var noite_s := (Registry.entry(&"economy", &"clock") as ClockData).phase_durations[
		GameClock.Phase.NIGHT
	]
	for _i in int(noite_s / PASSO):
		noite.dark.tick(
			PASSO,
			GameClock.Phase.NIGHT,
			SimLoop.state,
			SimLoop.creatures,
			SimLoop.builds,
			SimLoop.core_x
		)
	return SimLoop.creatures.count() - antes


func test_nas_primeiras_noites_o_escuro_nao_traz_ninguem() -> void:
	_jogo()
	assert_int(_noite_no_escuro(1, SEM_FUNDO)).is_equal(0)
	_fim()


func test_depois_o_escuro_traz_e_a_podridao_paga() -> void:
	_jogo()
	var custo := _bicho(_perfil().dark_creature).mass_cost
	var vieram := _noite_no_escuro(_perfil().dark_from_night, SEM_FUNDO)
	assert_int(vieram).is_equal(_perfil().dark_ambush_max)
	assert_float(SimLoop.night.rot.mass()).is_equal(SEM_FUNDO - vieram * custo)
	_fim()


func test_sem_massa_o_escuro_chama_e_ninguem_vem() -> void:
	_jogo()
	assert_int(_noite_no_escuro(_perfil().dark_from_night, 0.0)).is_equal(0)
	_fim()


func test_quem_vem_do_escuro_nasce_longe_do_corpo_do_rei() -> void:
	# A emboscada nascia a 90 px, menos do que o corpo de um Rastejante (Q-219): colada.
	var crawler := _bicho(&"crawler")
	assert_float(_perfil().dark_ambush_px).is_greater(float(crawler.shadow_width) * 2.0)


# ─── O jogo inteiro: a noite 1 do §25, esteja o rei onde estiver ─────────────


func test_a_noite_1_sao_tres_rastejantes_mesmo_com_o_rei_no_escuro() -> void:
	# A queixa do dono, medida pela sonda: o rei la fora na noite 1 via nove.
	_jogo()
	LastCartWatch.claim(&"road")  # o relogio comeca no estandarte (ADR 0065)
	var vistos := {}
	var guarda := int(2.0 * ClockService.clock.day_seconds() / PASSO)
	while ClockService.clock.day < 2 and guarda > 0:
		guarda -= 1
		var rot := SimLoop.night.rot
		if rot.active():  # do lado de onde ela NAO vem: so o escuro lhe chega
			var lado := -signf(rot.position_x() - SimLoop.core_x)
			SimLoop.units.set_target_x(SimLoop.king_id, SimLoop.core_x + lado * LA_FORA)
		SimLoop.step(PASSO)
		for id in SimLoop.creatures.ids:
			vistos[id] = true
	var tres := int(_perfil().opening_mass) / _bicho(&"crawler").mass_cost
	assert_int(vistos.size()).is_between(1, tres)  # a noite veio, e so com os do §25
	_fim()
