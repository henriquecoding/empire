# tests/abertura_test.gd — GB-01 e XIII-10: o segmento de abertura e os
# primeiros vinte minutos, com a candeia la dentro (§25, §83).
extends GdUnitTestSuite

const SEMENTE := 20260925
const PASSO := 1.0 / 30.0


func _relogio() -> ClockData:
	return Registry.entry(&"economy", &"clock") as ClockData


## Corre ate a mancha falar. As muralhas ficam de pe: sem ninguem nos postos a
## pedra cai na noite 1, e isto mede a voz e nao a defesa.
func _ate_falar(max_dias: int) -> int:
	var passos := int(_relogio().day_seconds * max_dias / PASSO)
	for _i in passos:
		SimLoop.step(PASSO)
		for vaga in SimLoop.builds.slots:
			if vaga.two_paths() and vaga.level > 0:
				vaga.state = BuildSlot.State.DONE
				vaga.health = vaga.max_health()
		if SimLoop.night.offers.active():
			return SimLoop.state.day
	return 0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()
	# Sem muralha a mancha nao tem de onde chegar aos 300 px (§75), e nao fala.
	# Pedra, e nao a estacaria do §25: a estacaria cai a meio da noite 3, e isto
	# mede a oferta e nao a defesa.
	for vaga in SimLoop.builds.slots:
		if vaga.two_paths() and absf(vaga.x - SimLoop.core_x) < SimLoop.world_width * 0.25:
			vaga.level = 3
			vaga.state = BuildSlot.State.DONE
			vaga.health = vaga.max_health()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_ao_minuto_zero_ha_um_amargueiro_velho_fora_do_muro_a_esquerda() -> void:
	var arvores := SimLoop.night.trees
	assert_int(arvores.count()).is_equal(1)
	assert_int(arvores.wild[0]).is_equal(1)
	assert_float(arvores.xs[0]).is_equal(SimLoop.core_x + Greybox.AMARGUEIRO_VELHO_X)
	var de_dentro: float = Greybox.MUROS_X.filter(func(x: float) -> bool: return x < 0.0).max()
	var muro_de_dentro := SimLoop.core_x + de_dentro
	assert_float(arvores.xs[0]).is_less(muro_de_dentro)
	# Nao e um morto teu: nao pesa na primeira noite, que e ganha de certeza (§25).
	assert_int(arvores.standing(false)).is_equal(0)


func test_o_vagabundo_do_minuto_0_20_e_sempre_o_mesmo() -> void:
	var primeiro := _o_primeiro_vagabundo()
	SimLoop.stop()
	SimLoop.start(SEMENTE + 1)
	Greybox.build()
	assert_array(_o_primeiro_vagabundo()).is_equal(primeiro)


func _o_primeiro_vagabundo() -> Array:
	var u := SimLoop.units
	var x := SimLoop.core_x + Greybox.VAGABUNDOS_X[0]
	for i in u.count():
		if u.data_ids[i] == &"vagrant" and u.xs[i] == x:
			return [u.ids[i], u.xs[i]]
	return []


func test_os_segredos_da_abertura_estao_la() -> void:
	var sitios := Array(SimLoop.secrets.ids).map(func(id: StringName) -> String: return String(id))
	assert_array(sitios).contains(["buried_statue", "root_chamber"])
	# A bifurcacao a leste, onde cai o capitulo que a primeira oferta revela.
	assert_array(Array(SimLoop.secrets.chapters)).is_equal([SimLoop.core_x + Greybox.BIFURCACAO_X])


func test_a_primeira_oferta_e_so_quero_ver_e_acende_a_bifurcacao() -> void:
	var dia := _ate_falar(4)
	var ofertas := SimLoop.night.offers
	# §83, 17:00: o crepusculo do dia 3 (ADR 0023). Antes disso a voz esta calada.
	assert_int(dia).is_equal(3)
	assert_str(String(ofertas.offer_id)).is_equal("just_looking")
	assert_bool(SimLoop.state.found.has(OfferDesk.CAPITULO)).is_false()
	SimLoop.drop_coin(ofertas.dish_x, Band.Kind.SURFACE, 1, &"player")
	for _i in int(3.0 / PASSO):
		SimLoop.step(PASSO)
	assert_bool(SimLoop.state.found.has(OfferDesk.CAPITULO)).is_true()
	assert_int(ofertas.debt.debt).is_equal(1)
