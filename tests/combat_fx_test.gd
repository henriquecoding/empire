# tests/combat_fx_test.gd — o que um corpo mostra de um golpe (§24, Q-084, Q-185).
#
# O que importa provar e o contrato com a simulacao: o empurrao e so do ecra e
# acaba SEMPRE na posicao dela; o hitstop e de quem bate e de quem leva, e nao
# do jogo; o flash dura os 80 ms do §24 e desliga-se nas opcoes (§26).
extends GdUnitTestSuite

const FICHEIRO := "user://combat_fx_test.cfg"
const S := StrikePose.Style


func before_test() -> void:
	CombatFx.reset()


func after_test() -> void:
	CombatFx.reset()
	Preferences.set_shared(null)
	for f in [FICHEIRO, FICHEIRO + ".tmp"]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))


func test_sem_golpe_o_corpo_esta_onde_a_simulacao_o_pos() -> void:
	var pose := CombatFx.body(7, S.MELEE, StrikePose.NUNCA, 1.0)
	assert_vector(pose).is_equal(Vector4(0.0, 1.0, 1.0, 0.0))


## O hitstop de quem leva: treme um pixel no sitio, e so depois e empurrado.
func test_durante_o_hitstop_quem_leva_treme_no_sitio() -> void:
	CombatFx.struck(7, 1.0, 1.0)
	CombatFx.advance(0.01)
	assert_float(absf(CombatFx.recoil(7))).is_equal(CombatFx.TREME.px)


## §24: 3 px de knockback, do lado do golpe — e a mola devolve-o ao sitio da
## simulacao (§45): nenhum empurrao fica.
func test_o_empurrao_e_do_lado_do_golpe_e_acaba_onde_estava() -> void:
	CombatFx.struck(7, -1.0, 1.0)
	CombatFx.advance(CombatFx.TREME.s + 0.001)
	assert_float(CombatFx.recoil(7)).is_less(-CombatFx.RECUO_PX * 0.9)
	CombatFx.advance(0.5)
	assert_float(absf(CombatFx.recoil(7))).is_less(0.05)


func test_um_golpe_pesado_empurra_mais_e_treme_mais_tempo() -> void:
	var pesado := StrikePose.strength(S.HEAVY)
	CombatFx.struck(2, 1.0, pesado)
	CombatFx.advance(CombatFx.TREME.s * 1.5)
	assert_float(absf(CombatFx.recoil(2))).is_equal(CombatFx.TREME.px)
	CombatFx.advance(CombatFx.TREME.s * (pesado - 1.5) + 0.001)
	assert_float(CombatFx.recoil(2)).is_greater(CombatFx.RECUO_PX)


func test_o_flash_dura_os_80_ms_do_24() -> void:
	CombatFx.struck(7, 1.0, 1.0)
	assert_float(CombatFx.flash(7)).is_equal(1.0)
	CombatFx.advance(CombatFx.FLASH_S)
	assert_float(CombatFx.flash(7)).is_equal(0.0)


## §26: "obrigatorio para fotossensibilidade". O empurrao fica: nao e um clarao.
func test_sem_claroes_nao_ha_flash_mas_ha_empurrao() -> void:
	var minhas := Preferences.new(FICHEIRO)
	minhas.set_enabled(Preferences.FLASHES, false)
	Preferences.set_shared(minhas)
	CombatFx.struck(7, 1.0, 1.0)
	assert_float(CombatFx.flash(7)).is_equal(0.0)
	CombatFx.advance(CombatFx.TREME.s + 0.001)
	assert_float(CombatFx.recoil(7)).is_greater(0.0)


## A lanca leva STRIKE_S a esticar: a pancada sente-se quando ela chega.
func test_quem_leva_espera_que_a_arma_chegue() -> void:
	CombatFx.struck(7, 1.0, 1.0, StrikePose.STRIKE_S)
	assert_float(CombatFx.flash(7)).is_equal(0.0)
	assert_float(CombatFx.recoil(7)).is_equal(0.0)
	CombatFx.advance(StrikePose.STRIKE_S)
	assert_float(CombatFx.flash(7)).is_greater(0.0)


## O hitstop de quem bate: fica no frame do impacto, e so depois recupera.
func test_quem_bate_fica_no_frame_do_impacto() -> void:
	CombatFx.attacked(3, S.HEAVY)
	CombatFx.advance(StrikePose.STRIKE_S + StrikePose.hold(S.HEAVY) * 0.5)
	var parado := CombatFx.since_attack(3)
	assert_int(StrikePose.phase(parado, StrikePose.NUNCA)).is_equal(StrikePose.Phase.STRIKE)
	CombatFx.advance(StrikePose.hold(S.HEAVY))
	var depois := CombatFx.since_attack(3)
	assert_int(StrikePose.phase(depois, StrikePose.NUNCA)).is_equal(StrikePose.Phase.RECOVER)


## Um muro nao tem `attack_launched`: o ataque le-se no cooldown que sobe.
func test_um_cooldown_que_sobe_e_um_ataque_que_saiu() -> void:
	CombatFx.observe(5, 0.5, S.HEAVY)
	CombatFx.advance(0.1)
	CombatFx.observe(5, 0.4, S.HEAVY)
	assert_float(CombatFx.since_attack(5)).is_equal(StrikePose.NUNCA)
	CombatFx.observe(5, 2.0, S.HEAVY)
	assert_float(CombatFx.since_attack(5)).is_equal(0.0)


func test_quem_cai_cai_para_o_lado_do_golpe_e_fica_deitado() -> void:
	CombatFx.struck(9, -1.0, 1.0)
	CombatFx.fell(9, CombatFx.side(9))
	CombatFx.advance(CombatFx.QUEDA_S)
	assert_float(CombatFx.fall(9)).is_equal_approx(-PI * 0.5, 0.01)
	CombatFx.advance(5.0)
	assert_float(CombatFx.fall(9)).is_equal_approx(-PI * 0.5, 0.01)
	CombatFx.forget(9)
	assert_float(CombatFx.fall(9)).is_equal(0.0)


## Uma noite de trezentas pancadas nao fica na memoria.
func test_o_que_passou_sai_da_memoria() -> void:
	CombatFx.struck(9, -1.0, 1.0)
	CombatFx.attacked(9, S.MELEE)
	LastSeen.remember(9, Rect2(0, 0, 8, 8), 0, Color.WHITE)
	for k in 4:
		CombatFx.advance(CombatFx.ESQUECE_S)
	assert_float(CombatFx.side(9)).is_equal(1.0)
	assert_float(CombatFx.since_attack(9)).is_equal(StrikePose.NUNCA)
	assert_bool(LastSeen.seen(9).is_empty()).is_true()
