# tests/impact_view_test.gd — o golpe que se ve (GB-07, §24).
#
# O desenho nao se testa; o que se testa e o que ele desenha DURANTE. O §24 dá
# ao impacto oitenta milissegundos, e um flash que fique no ecrã é pior do que
# nenhum: numa noite de trezentas pancadas, a lista de golpes tem de encolher
# sozinha ou o ecrã fica branco e o `_draw` cresce sem fim.
extends GdUnitTestSuite

const ESQUERDA := -1.0
const DIREITA := 1.0


func _vista() -> ImpactView:
	return auto_free(ImpactView.new())


func test_um_golpe_dura_os_80_ms_do_24() -> void:
	var vista := _vista()
	vista.hit(1, DIREITA)
	assert_int(vista.count()).is_equal(1)

	vista.advance(ImpactView.FLASH_S * 0.5)
	assert_int(vista.count()).is_equal(1)

	vista.advance(ImpactView.FLASH_S * 0.5)
	assert_int(vista.count()).is_equal(0)


## Uma noite nao acumula: o que passou dos 80 ms sai, e sai mesmo com golpes
## novos a entrar no mesmo passo.
func test_os_golpes_velhos_saem_e_os_novos_ficam() -> void:
	var vista := _vista()
	for id in [1, 2, 3]:
		vista.hit(id, DIREITA)
	vista.advance(ImpactView.FLASH_S * 0.9)
	vista.hit(4, ESQUERDA)

	vista.advance(ImpactView.FLASH_S * 0.2)

	assert_int(vista.count()).is_equal(1)


func test_uma_lista_vazia_nao_se_queixa() -> void:
	var vista := _vista()
	vista.advance(1.0)
	assert_int(vista.count()).is_equal(0)


## O sentido e do atacante para quem levou: e o que diz de onde veio a pancada.
func test_a_particula_sai_para_o_lado_para_onde_o_golpe_foi() -> void:
	assert_float(ImpactView.aim(0.0, 40.0)).is_equal(DIREITA)
	assert_float(ImpactView.aim(40.0, 0.0)).is_equal(ESQUERDA)


## Dois corpos no mesmo x davam sentido zero, e uma particula com sentido zero
## fica dentro do corpo — que e o unico sitio onde ela nao se ve.
func test_dois_corpos_no_mesmo_sitio_nao_dao_sentido_zero() -> void:
	assert_float(ImpactView.aim(120.0, 120.0)).is_equal(DIREITA)


## A ponta que um teste de unidade nao apanha: o nome e a aridade do sinal da
## §46. Um `attack_launched` com outra assinatura liga sem se queixar e nunca
## chama ninguem, e o defeito so aparece numa noite a olhar para o ecra.
func test_o_sinal_do_46_chega_mesmo_a_vista() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20260916)
	Greybox.build()
	var vista := _vista()
	add_child(vista)

	var quem := SimLoop.units.ids[0]
	var levou := SimLoop.units.ids[1]
	EventBus.queue(&"attack_launched", [quem, levou, true])
	EventBus.queue(&"attack_launched", [quem, levou, false])
	EventBus.flush()

	# Duas pancadas enfileiradas, uma so acertou: o §07 da ao arqueiro em campo
	# aberto 0,34 de precisao, e piscar as falhas mentia sobre quantas acertam.
	assert_int(vista.count()).is_equal(1)

	remove_child(vista)
	SimLoop.stop()
	SimLoop.autosave_enabled = true


## Ha DOIS espacos de id: um corpo vem do contador do §45 e um sitio de obra vem
## do indice do BuildSystem. Sem separar, uma dentada no muro numero 3 piscava a
## tropa numero 3 do outro lado do mapa, e ninguem percebia porque.
func test_uma_dentada_no_muro_nao_pisca_a_tropa_com_o_mesmo_numero() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20260916)
	Greybox.build()
	var vista := _vista()
	add_child(vista)

	var muro := SimLoop.builds.slots[1]
	EventBus.queue(&"building_damaged", [muro.id, 0.5])
	EventBus.flush()

	assert_int(vista.count()).is_equal(1)
	assert_bool(vista.last()[ImpactView.OBRA]).is_true()
	assert_int(vista.last()[ImpactView.ALVO]).is_equal(muro.id)

	# E um corpo continua a entrar como corpo, com o mesmo numero.
	vista.hit(muro.id, 1.0)
	assert_bool(vista.last()[ImpactView.OBRA]).is_false()

	remove_child(vista)
	SimLoop.stop()
	SimLoop.autosave_enabled = true
