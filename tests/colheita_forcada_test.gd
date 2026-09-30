# tests/colheita_forcada_test.gd — a conta de retorno da Colheita Forcada (§15), com
# as condicoes reais (Q-145, o dono a 29/09/2026: "siga por esse caminho").
#
# A conta antiga (economia_jogada_test) omitia a ganancia e pagava o preco base de
# sempre. Com as condicoes reais — a ganancia do perfil equilibrado leva a parte
# dela do ganho e da perda, o preco e o do dia (ADR 0028: cresce com a producao) e
# o impulso so pesa nas fases que faltam —, o ganho e o preco crescem ao mesmo
# ritmo, e o retorno e o mesmo em qualquer dia. Medido no greybox de tres fontes,
# a 4 moedas ficava abaixo do preco (0,83); o dono aprovou a descida para 3 (Q-158,
# 30/09/2026), e passa a compensar.
extends GdUnitTestSuite

const SEMENTE := 20260926
const DIAS := 30
const FOLGA := 0.02

var _eco: EconomySystem


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()
	_eco = SimLoop.economy
	for obra in SimLoop.builds.slots:
		if obra.kind in [&"farm", &"henhouse", &"fishery"]:
			obra.level = 1
			obra.state = BuildSlot.State.DONE
			obra.health = obra.max_health()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


## O que a Colheita Forcada devolve por moeda paga, no dia `d`, usada numa fracao
## `fracao` do dia (1 a alvorada, metade ao meio-dia).
func _retorno(d: int, fracao: float) -> float:
	var impulso := Registry.entry(&"crown/impulses", &"forced_harvest") as ImpulseData
	var perfil := Registry.entry(&"economy/profiles", &"balanced") as EconomyProfile
	var canteiros := 0.0
	for obra in SimLoop.builds.standing():
		if obra.kind == &"farm":
			canteiros += obra.yield_per_day
	var ganho := _eco.built_income(SimLoop.builds, d) * (impulso.benefit_value - 1.0) * fracao
	var perda := canteiros * pow(SimFactory.curve().income_growth, d)
	var preco := SimLoop.field.crown.price(&"forced_harvest", d)
	return (ganho - perda) * (1.0 - perfil.greed / 100.0) / preco


## O preco cresce com a producao (ADR 0028), e o ganho tambem: o retorno por moeda
## nao depende do dia — so do arredondamento do preco.
func test_o_retorno_e_o_mesmo_em_qualquer_dia() -> void:
	var referencia := _retorno(DIAS, 1.0)
	print("Colheita Forcada, retorno por moeda paga (a alvorada): %.2f" % referencia)
	for d in range(DIAS - 10, DIAS + 1):
		assert_float(_retorno(d, 1.0)).is_equal_approx(referencia, referencia * FOLGA + 0.05)
	assert_float(_retorno(DIAS, 0.5)).is_less(referencia)


## O §15 quer que um impulso possa valer a pena; P-M pedia que a Colheita Forcada
## compensasse nalgum dia. Com as condicoes reais, no greybox de tres fontes, a 4
## moedas nao compensava nunca; a 3 (Q-158) devolve mais do que custa.
func test_a_colheita_forcada_compensa_nalgum_dia() -> void:
	var compensa := false
	for d in range(1, DIAS + 1):
		compensa = compensa or _retorno(d, 1.0) > 1.0
	assert_bool(compensa).is_true()
