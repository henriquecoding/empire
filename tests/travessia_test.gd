# tests/travessia_test.gd — a lei da travessia do §21, medida em vez de suposta.
#
# O §21 nao deixa a largura de uma regiao ao gosto de ninguem: "nao fixes isto
# pela largura da tela onde desenhaste — DERIVA-O DO TEMPO DE TRAVESSIA: a pe
# (§12) uma regiao deve levar 40-60 s a atravessar de ponta a ponta".
#
# E uma lei sobre duas coisas ao mesmo tempo — a largura da regiao e a velocidade
# de quem anda — e por isso nao havia onde a escrever: o `data_test` olha para
# uma tabela de cada vez e a `greybox` monta a regiao sem perguntar a que
# velocidade se atravessa. Este ficheiro e essa pergunta, e chumba dos dois
# lados: alargar a regiao sem mexer no passo chumba aqui, e abrandar o passo sem
# encolher a regiao tambem.
#
# O valor que ela apanhou no dia em que nasceu: 3840 px a 26 px/s sao 148 s —
# dois minutos e meio a andar em linha reta, com um dia inteiro a durar 360 s
# (clock.csv). Ver docs/adr/0021-a-lei-da-travessia.md.
extends GdUnitTestSuite

const SEGMENTO := "enramados_start_base_01"

## §21, a lei. Sao os numeros do dossie e vivem aqui pela mesma razao que a
## tabela de tempo-ate-matar vive no design_data_test: um teste de design
## escreve o que o dossie decidiu, para que os dados tenham contra o que chumbar.
const TRAVESSIA_MIN_S := 40.0
const TRAVESSIA_MAX_S := 60.0

## Quem o greybox poe em campo no dia 1 (GB-01). Andam todos com o monarca —
## §25 minuto 0:20, "o vagabundo segue-te" — e por isso andam ao passo dele.
const EM_CAMPO := ["vagrant", "archer", "spearman", "squire"]


func _unit(id: String) -> UnitData:
	return load("res://data/units/%s.tres" % id)


func _mount(id: String) -> MountData:
	return load("res://data/mounts/%s.tres" % id)


## A regiao que o greybox monta, em px: a largura do segmento (§21, §47) pelos
## ecras que o Greybox junta. Nao esta escrita aqui — e lida de onde vive.
func _regiao_px() -> float:
	var segmento: SegmentData = load("res://data/segments/%s.tres" % SEGMENTO)
	return float(segmento.width_px) * Greybox.ECRAS


func _travessia_s(velocidade: float) -> float:
	return _regiao_px() / velocidade


func test_a_regiao_atravessa_se_em_40_a_60_segundos_a_pe() -> void:
	var pe := _unit("monarch").move_speed
	var segundos := _travessia_s(pe)
	var msg := (
		"§21: a regiao (%d px) leva %.1f s a %.0f px/s — a lei diz 40-60 s"
		% [int(_regiao_px()), segundos, pe]
	)
	assert_float(segundos).override_failure_message(msg).is_between(
		TRAVESSIA_MIN_S, TRAVESSIA_MAX_S
	)


## §12: "a velocidade a pe e deliberadamente frustrante depois do dia 6 — e o
## que da valor a primeira montaria". So vale como dadiva se a montaria descer
## abaixo do chao da lei; o cavalo de tracao e a primeira que se compra (§12).
func test_a_montaria_e_uma_dadiva_e_nao_uma_correcao() -> void:
	var montado := _unit("monarch").move_speed * _mount("draft_horse").speed_multiplier
	var msg := (
		"§12: montado a regiao leva %.1f s — tem de ficar abaixo dos %.0f s da lei"
		% [_travessia_s(montado), TRAVESSIA_MIN_S]
	)
	assert_float(_travessia_s(montado)).override_failure_message(msg).is_less(TRAVESSIA_MIN_S)


## Quem te segue tem de te alcancar. O `follow()` do RecruitSystem poe cada um
## num lugar atras do rei (§25, §50); com um passo mais lento do que o dele
## nenhum desses lugares chega a ser ocupado, e a comitiva vira um rasto.
func test_quem_segue_o_rei_anda_ao_passo_dele() -> void:
	var rei := _unit("monarch").move_speed
	for id in EM_CAMPO:
		var msg := (
			"%s anda a %.0f px/s e o rei a %.0f — nunca o alcanca" % [id, _unit(id).move_speed, rei]
		)
		assert_float(_unit(id).move_speed).override_failure_message(msg).is_greater_equal(rei)
