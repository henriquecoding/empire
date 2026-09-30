# tests/classe_assumida_no_jogo_test.gd — trocar de classe pelo SimLoop (§08, §24;
# Q-150, Q-162, Q-178).
#
# O Roster prova-se sozinho no assumir_classe_test; aqui prova-se o jogo inteiro: o
# Verbo 2 do rei ao pe de um arqueiro teu faz dele o Arqueiro, na escala 3, e e ele que
# anda; o rei fica, e so ele vai ate a trela (Q-150); a moeda da classe nao paga obra
# (§08: "so o rei gere"); a roda e so do rei; e o save guarda quem se conduz.
extends GdUnitTestSuite

const SEMENTE := 20260930
const PASSO := 1.0 / 30.0
const LADO := 30.0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _rei() -> int:
	return SimLoop.units.index_of(SimLoop.king_id)


## Um arqueiro teu ao lado do rei, e o Verbo 2.
func _assumir_arqueiro() -> int:
	var arqueiro := Registry.entry(&"units", &"archer") as UnitData
	var x := SimLoop.units.xs[_rei()] + LADO
	var novo := SimLoop.units.spawn(SimLoop.state, arqueiro, Greybox.MEU_IMPERIO, x)
	SimLoop.intents.queue(IntentQueue.Kind.ASSUME)
	SimLoop.step(PASSO)
	return novo


func test_o_verbo_2_ao_pe_de_um_arqueiro_teu_assume_o_arqueiro() -> void:
	var guia := GameplayGuide.context(Glyphs.Device.KEYBOARD)
	var novo := _assumir_arqueiro()
	assert_str(guia).is_not_empty()
	assert_int(Assume.driven()).is_equal(novo)
	var i := SimLoop.units.index_of(novo)
	assert_str(String(SimLoop.units.data_ids[i])).is_equal("archer_hero")
	var corpo := Registry.entry(&"units", SimLoop.units.data_ids[i]) as UnitData
	var tropa := Registry.entry(&"units", &"archer") as UnitData
	assert_int(corpo.scale_tier).is_greater(tropa.scale_tier)


## Quem o jogador conduz nao recebe posto nem vai a caca: e ele que o jogador leva.
func test_quem_se_conduz_nao_recebe_posto() -> void:
	var novo := _assumir_arqueiro()
	for _t in 60:
		SimLoop.step(PASSO)
	var i := SimLoop.units.index_of(novo)
	assert_int(SimLoop.units.job_ids[i]).is_equal(UnitSystem.NENHUM)


## O rei so se afasta `king_leash_px` alem das bordas da regiao; a classe vai ate a
## borda do mundo (Q-150).
func test_o_rei_tem_trela_e_a_classe_nao() -> void:
	var trela := SimFactory.curve().king_leash_px
	var rei := Assume.limits(SimLoop.king_id)
	assert_float(rei.y).is_equal_approx(SimLoop.world_width + trela, 0.5)
	assert_float(rei.x).is_equal_approx(-trela, 0.5)
	var novo := _assumir_arqueiro()
	var classe := Assume.limits(novo)
	assert_float(classe.y).is_greater(rei.y)
	assert_float(classe.x).is_less(rei.x)


## So o rei gere (§08): a moeda largada pela classe cai, e nao paga a obra onde cai.
func test_a_moeda_da_classe_nao_paga_obra() -> void:
	var novo := _assumir_arqueiro()
	var i := SimLoop.units.index_of(novo)
	SimLoop.units.carried_coins[i] = 3
	var args := {&"x": SimLoop.units.xs[i], &"band": Band.Kind.SURFACE, &"amount": 1}
	args[&"source"] = Verbs.JOGADOR
	SimLoop.intents.queue(IntentQueue.Kind.DROP_COIN, args)
	SimLoop.step(PASSO)
	assert_int(SimLoop.units.carried_coins[i]).is_equal(2)
	var c := SimLoop.coins.count() - 1
	assert_int(SimLoop.coins.from_king[c]).is_equal(0)
	assert_int(SimLoop.coins.targets[c]).is_equal(CoinTarget.NENHUM)


## A roda e o corpo do rei (§24): com a classe assumida, o impulso nao se usa.
func test_com_a_classe_o_impulso_nao_se_usa() -> void:
	_assumir_arqueiro()
	SimLoop.units.carried_coins[_rei()] = 30
	var antes := SimLoop.units.carried_coins[_rei()]
	SimLoop.intents.queue(IntentQueue.Kind.IMPULSE, {&"id": &"forced_harvest"})
	SimLoop.step(PASSO)
	assert_int(SimLoop.units.carried_coins[_rei()]).is_equal(antes)


## O Verbo 2 do Arqueiro ao pe do rei volta ao rei; e o rei largado volta ao nucleo.
func test_volta_se_ao_rei_e_o_rei_largado_vai_para_casa() -> void:
	SimLoop.units.xs[_rei()] = SimLoop.core_x + 600.0
	var novo := _assumir_arqueiro()
	for _t in 3:
		SimLoop.step(PASSO)
	assert_float(SimLoop.units.target_xs[_rei()]).is_equal_approx(SimLoop.core_x, 0.5)
	var i := SimLoop.units.index_of(novo)
	SimLoop.units.xs[i] = SimLoop.units.xs[_rei()] + LADO
	SimLoop.intents.queue(IntentQueue.Kind.ASSUME)
	SimLoop.step(PASSO)
	assert_int(Assume.driven()).is_equal(SimLoop.king_id)


## O save guarda quem se conduz, e o armazenamento da classe.
func test_o_save_guarda_quem_se_conduz() -> void:
	var novo := _assumir_arqueiro()
	var aljava := Assume.storage(SimLoop.units, novo, SimLoop.field)
	aljava.put(Storage.ARCHOTE, 1)
	var mundo := SimLoop.world()
	SimLoop.units.pilot = UnitSystem.NENHUM
	SimLoop.field.roster.storages.clear()
	SimLoop.load_world(mundo)
	assert_int(Assume.driven()).is_equal(novo)
	var outra := Assume.storage(SimLoop.units, novo, SimLoop.field)
	assert_int(outra.count(Storage.ARCHOTE)).is_equal(1)
