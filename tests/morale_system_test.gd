# tests/morale_system_test.gd — moral, fuga, e o raio do rei (§07, F1-12).
#
# "Rei em campo → nenhuma tropa foge dentro de um raio de 260 px. A defesa
# aguenta — e o rei pode morrer. E a decisao tactica de maior risco do jogo."
#
# O FLEE da tabela da §52 era, ate ao F1-12, um estado que nada alcancava. O que
# se prova aqui e que ele e alcancavel, que os numeros sao os da curva, e que o
# raio do rei e mesmo um raio — protege quem esta perto e mais ninguem.
extends GdUnitTestSuite

const MEU_IMPERIO := 7
const NUCLEO := 0.0
const SEM_BRECHA := false
const COM_BRECHA := true


func _curva() -> EconomyCurve:
	return Registry.entry(&"economy", &"curve") as EconomyCurve


func _tabela() -> Dictionary:
	var mapa := {}
	for r in Registry.entries(&"units"):
		mapa[r.get(&"id")] = r
	return mapa


func _moral() -> MoraleSystem:
	return MoraleSystem.new(_curva(), _tabela())


func _tropa(unidades: UnitSystem, estado: GameState, id: StringName, x: float) -> int:
	return unidades.spawn(estado, Registry.entry(&"units", id), MEU_IMPERIO, x)


## No meio dos dois limiares da curva: acima do que faz fugir por vida, abaixo
## do que faz fugir quando o muro cai.
func _entre_os_dois_limiares(unidades: UnitSystem, i: int) -> void:
	var curva := _curva()
	_vida(unidades, i, (curva.flee_health + curva.breach_flee_health) * 0.5)


## Poe a vida NESTA fraccao do maximo, tao perto quanto a vida inteira deixa.
## Nenhum numero de vida aparece nos testes: sai sempre de um limiar da curva.
func _vida(unidades: UnitSystem, i: int, fraccao: float) -> void:
	unidades.healths[i] = maxi(1, int(roundf(unidades.max_healths[i] * fraccao)))


## Abaixo de um limiar, e com folga: metade dele.
func _abaixo_de(unidades: UnitSystem, i: int, limiar: float) -> void:
	_vida(unidades, i, limiar * 0.5)


func test_abaixo_do_limiar_de_vida_foge_para_o_nucleo() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var quem := _tropa(unidades, estado, &"archer", 900.0)
	var i := unidades.index_of(quem)
	_abaixo_de(unidades, i, _curva().flee_health)

	var eventos := _moral().tick(unidades, UnitSystem.NENHUM, NUCLEO, SEM_BRECHA)

	assert_int(unidades.states[i]).is_equal(UnitFsm.State.FLEE)
	assert_float(unidades.target_xs[i]).is_equal(NUCLEO)
	assert_int(eventos.size()).is_equal(1)
	assert_str(String(eventos[0][MoraleSystem.PORQUE])).is_equal(String(MoraleSystem.POR_VIDA))


func test_de_boa_saude_ninguem_foge() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var quem := _tropa(unidades, estado, &"archer", 900.0)

	assert_array(_moral().tick(unidades, UnitSystem.NENHUM, NUCLEO, SEM_BRECHA)).is_empty()
	assert_int(unidades.states[unidades.index_of(quem)]).is_not_equal(UnitFsm.State.FLEE)


func test_com_o_rei_perto_ninguem_foge() -> void:
	# A regra que da peso a por o rei na linha (§07).
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var rei := _tropa(unidades, estado, &"monarch", 900.0)
	var quem := _tropa(unidades, estado, &"archer", 900.0)
	var i := unidades.index_of(quem)
	_abaixo_de(unidades, i, _curva().flee_health)

	assert_array(_moral().tick(unidades, rei, NUCLEO, SEM_BRECHA)).is_empty()
	assert_int(unidades.states[i]).is_not_equal(UnitFsm.State.FLEE)


func test_fora_do_raio_o_rei_nao_protege() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var rei := _tropa(unidades, estado, &"monarch", 0.0)
	var raio := _curva().king_presence_radius
	var quem := _tropa(unidades, estado, &"archer", raio * 2.0)
	var i := unidades.index_of(quem)
	_abaixo_de(unidades, i, _curva().flee_health)

	_moral().tick(unidades, rei, NUCLEO, SEM_BRECHA)

	assert_int(unidades.states[i]).is_equal(UnitFsm.State.FLEE)
	assert_int(raio).is_greater(0)


func test_o_rei_a_chegar_faz_voltar_quem_fugia() -> void:
	# "A defesa aguenta — e o rei pode morrer." Se o raio so impedisse entrar em
	# FLEE, levar o monarca ate la nao salvava ninguem que ja tivesse partido.
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var rei := _tropa(unidades, estado, &"monarch", 0.0)
	var quem := _tropa(unidades, estado, &"archer", 900.0)
	var i := unidades.index_of(quem)
	var r := unidades.index_of(rei)
	_abaixo_de(unidades, i, _curva().flee_health)
	var moral := _moral()
	moral.tick(unidades, rei, NUCLEO, SEM_BRECHA)
	assert_int(unidades.states[i]).is_equal(UnitFsm.State.FLEE)

	unidades.xs[r] = unidades.xs[i]
	var eventos := moral.tick(unidades, rei, NUCLEO, SEM_BRECHA)

	assert_int(unidades.states[i]).is_equal(UnitFsm.State.WORK)
	assert_int(eventos[0][MoraleSystem.CHAVE]).is_equal(MoraleSystem.EV_VOLTOU)


func test_quem_chega_ao_nucleo_volta_ao_trabalho() -> void:
	# §52: o FLEE "sai quando chega ao nucleo, ou morre".
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var quem := _tropa(unidades, estado, &"archer", 900.0)
	var i := unidades.index_of(quem)
	_abaixo_de(unidades, i, _curva().flee_health)
	var moral := _moral()
	moral.tick(unidades, UnitSystem.NENHUM, NUCLEO, SEM_BRECHA)

	unidades.xs[i] = NUCLEO
	moral.tick(unidades, UnitSystem.NENHUM, NUCLEO, SEM_BRECHA)

	assert_int(unidades.states[i]).is_equal(UnitFsm.State.WORK)


func test_um_muro_a_cair_poe_a_fugir_quem_e_fraco_e_barato() -> void:
	# §07: "muro cai → tropas com vida < 30% e custo <= 4 fogem para o nucleo".
	# O arqueiro custa 3 e entra; o mercenario custa 18 e nao.
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var curva := _curva()
	var barato := _tropa(unidades, estado, &"spearman", 900.0)
	var caro := _tropa(unidades, estado, &"mercenary", 900.0)
	var a := unidades.index_of(barato)
	var b := unidades.index_of(caro)
	_entre_os_dois_limiares(unidades, a)
	_entre_os_dois_limiares(unidades, b)

	_moral().tick(unidades, UnitSystem.NENHUM, NUCLEO, COM_BRECHA)

	assert_int(unidades.recruit_costs[a]).is_less_equal(curva.breach_flee_max_cost)
	assert_int(unidades.recruit_costs[b]).is_greater(curva.breach_flee_max_cost)
	assert_int(unidades.states[a]).is_equal(UnitFsm.State.FLEE)
	assert_int(unidades.states[b]).is_not_equal(UnitFsm.State.FLEE)


func test_sem_brecha_o_limiar_dos_30_por_cento_nao_conta() -> void:
	# Ferido abaixo do limiar da brecha mas acima do limiar de vida: sem muro
	# caido, aguenta. O lanceiro tem 26 de vida e cabe-lhe um valor entre os
	# dois; num arqueiro de 14 nao cabe nenhum, e isso nao e um defeito do jogo.
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var quem := _tropa(unidades, estado, &"spearman", 900.0)
	var i := unidades.index_of(quem)
	_entre_os_dois_limiares(unidades, i)
	var curva := _curva()
	var racio := float(unidades.healths[i]) / unidades.max_healths[i]

	assert_float(racio).is_greater(curva.flee_health)
	assert_float(racio).is_less(curva.breach_flee_health)
	assert_array(_moral().tick(unidades, UnitSystem.NENHUM, NUCLEO, SEM_BRECHA)).is_empty()


func test_quem_nao_recua_nao_recua_nem_com_o_muro_caido() -> void:
	# §07, o Berserker de Raiz: "avanca sempre. Nao recua nem com o muro caido."
	# E uma tag em units.csv e nao um caso especial em codigo.
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var quem := _tropa(unidades, estado, &"root_berserker", 900.0)
	var i := unidades.index_of(quem)
	_abaixo_de(unidades, i, _curva().flee_health)

	_moral().tick(unidades, UnitSystem.NENHUM, NUCLEO, COM_BRECHA)

	assert_bool(_moral().can_flee(unidades, i)).is_false()
	assert_int(unidades.states[i]).is_not_equal(UnitFsm.State.FLEE)


func test_um_vagabundo_por_recrutar_nao_entra_nesta_conta() -> void:
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var dados := Registry.entry(&"units", &"vagrant") as UnitData
	var quem := unidades.spawn(estado, dados, RecruitSystem.SEM_DONO, 900.0)
	var i := unidades.index_of(quem)
	_abaixo_de(unidades, i, _curva().flee_health)

	assert_array(_moral().tick(unidades, UnitSystem.NENHUM, NUCLEO, SEM_BRECHA)).is_empty()


func test_quem_foge_anda_e_quem_luta_nao() -> void:
	# A tabela da §52 da a FLEE "movimento em X" e a FIGHT "nada". Sem isto, uma
	# tropa em fuga ficava parada a ser morta no sitio de onde queria sair.
	var estado := GameState.new()
	var unidades := UnitSystem.new()
	var quem := _tropa(unidades, estado, &"archer", 900.0)
	var i := unidades.index_of(quem)
	_abaixo_de(unidades, i, _curva().flee_health)
	_moral().tick(unidades, UnitSystem.NENHUM, NUCLEO, SEM_BRECHA)

	unidades.tick_movement(1.0)

	assert_float(unidades.xs[i]).is_less(900.0)
