# tests/lua_do_pico_test.gd — a lua diz a noite funda na vespera (Q-126; relatorio
# Kingdom de 29/09, K8 pequeno).
#
# A noite funda vem de peak_every em peak_every noites e sabe-se de vespera, mas o
# jogo so a dizia a tarde, e so do lado. No Kingdom a Lua de Sangue esta no ceu. Aqui
# a lua do SkyView, que ja diz a hora, nasce cheia na vespera e vermelha na noite
# funda: informacao que deixa responder, sem painel.
extends GdUnitTestSuite

const SEMENTE := 20260929
const CALENDARIO := 60


func before_test() -> void:
	SimLoop.autosave_enabled = false
	SimLoop.start(SEMENTE)


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


## A primeira noite funda do calendario da mancha.
func _funda() -> int:
	for dia in range(1, CALENDARIO):
		if SimLoop.night.rot.deep(dia):
			return dia
	return -1


func test_ha_noites_fundas_no_calendario() -> void:
	assert_int(_funda()).is_greater(1)


func test_numa_noite_qualquer_a_lua_e_a_de_sempre() -> void:
	var comum := _funda() - 2
	assert_bool(SimLoop.night.rot.deep(comum) or SimLoop.night.rot.deep(comum + 1)).is_false()
	var lua := SkyView.moon(SimLoop.night.rot, comum)
	assert_float(lua[SkyView.RAIO]).is_equal(SkyView.LUA_RAIO)
	assert_that(lua[SkyView.COR]).is_equal(SkyView.LUA)


func test_na_vespera_a_lua_nasce_cheia() -> void:
	var lua := SkyView.moon(SimLoop.night.rot, _funda() - 1)
	assert_float(lua[SkyView.RAIO]).is_greater(SkyView.LUA_RAIO)
	assert_that(lua[SkyView.COR]).is_equal(SkyView.LUA)


func test_na_noite_funda_a_lua_vem_vermelha() -> void:
	var lua := SkyView.moon(SimLoop.night.rot, _funda())
	var cor: Color = lua[SkyView.COR]
	assert_float(lua[SkyView.RAIO]).is_greater(SkyView.LUA_RAIO)
	assert_float(cor.r).is_greater(cor.g)
	assert_float(cor.r).is_greater(cor.b)
	assert_that(cor).is_not_equal(SkyView.LUA)


## Sem mancha (um cenario sem simulacao, como o greybox dos biomas) a lua nao muda.
func test_sem_mancha_a_lua_e_a_de_sempre() -> void:
	var lua := SkyView.moon(null, _funda())
	assert_float(lua[SkyView.RAIO]).is_equal(SkyView.LUA_RAIO)
	assert_that(lua[SkyView.COR]).is_equal(SkyView.LUA)
