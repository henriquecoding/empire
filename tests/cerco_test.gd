# tests/cerco_test.gd — o cerco da marcha (§13; Q-166; relatorio Kingdom de 29/09, K6).
#
# A marcha ganhava sempre que levava tres ou mais (ADR 0035). O §13 tem tres tempos —
# reconhecimento, marcha e cerco — e so existia o do meio. Agora cada povo do plano
# tem uma fortaleza com firmeza; cada marcha tira-lhe firmeza pelos que foram, e essa
# firmeza nao volta, como o portal do Kingdom, que nao regenera vida. Quem marcha
# pode nao voltar: as baixas saem do fluxo combat, e a mesma semente da as mesmas.
# A bifurcacao diz quanto falta — conquistar passa a ser "mais uma marcha e cai".
extends GdUnitTestSuite

const STEP := 1.0 / 30.0
const SEMENTE := 20260929
const LONGE := 1000.0
const LIMITE := 12

var _conquistas: Array = []


func after_test() -> void:
	if EventBus.fortress_conquered.is_connected(_conquistou):
		EventBus.fortress_conquered.disconnect(_conquistou)
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _curva() -> EconomyCurve:
	return SimFactory.curve()


func _cheia(regiao: int) -> int:
	return March.fortress(regiao, _curva().march_fortress_base, _curva().march_fortress_per_region)


func _firmeza(m: March, regiao: int) -> int:
	return m.firmness(regiao, _curva().march_fortress_base, _curva().march_fortress_per_region)


## Cada povo mais adiante no plano tem uma fortaleza mais firme; o primeiro tem a base.
func test_a_fortaleza_cresce_pelo_plano() -> void:
	assert_int(_cheia(1)).is_equal(_curva().march_fortress_base)
	assert_int(_cheia(2)).is_equal(
		_curva().march_fortress_base + _curva().march_fortress_per_region
	)
	assert_int(_cheia(3)).is_greater(_cheia(2))


## O dano de uma marcha fica: a seguinte comeca onde a outra parou, o save guarda-o, e
## a firmeza nunca desce abaixo de zero.
func test_a_firmeza_tirada_nao_volta() -> void:
	var m := March.new()
	var dano := 3
	m.siege(2, dano)
	assert_int(_firmeza(m, 2)).is_equal(_cheia(2) - dano)
	assert_int(_firmeza(m, 1)).is_equal(_cheia(1))
	var copia := March.new()
	copia.from_dict(m.to_dict())
	assert_int(_firmeza(copia, 2)).is_equal(_cheia(2) - dano)
	copia.siege(2, _cheia(2))
	assert_int(_firmeza(copia, 2)).is_equal(0)


## Um save de antes do cerco abre com todas as fortalezas inteiras.
func test_um_save_de_antes_do_cerco_abre_com_as_fortalezas_inteiras() -> void:
	var m := March.new()
	m.from_dict({&"party": [], &"target": March.NENHUM, &"returns": 0})
	assert_int(_firmeza(m, 1)).is_equal(_cheia(1))
	assert_bool(m.sieges.is_empty()).is_true()


## Quem tira no sorteio menos do que a chance fica no campo; os outros voltam, pela
## ordem em que foram. Sem chance nenhuma voltam todos, como na ADR 0035.
func test_quem_tira_abaixo_da_chance_nao_volta() -> void:
	var foram: Array[Dictionary] = [{&"ids": 1}, {&"ids": 2}, {&"ids": 3}]
	var voltam := March.survivors(foram, PackedFloat32Array([0.9, 0.1, 0.5]), 0.2)
	assert_array(voltam.map(func(linha: Dictionary) -> int: return linha[&"ids"])).is_equal([1, 3])
	var todos := March.survivors(foram, PackedFloat32Array([0.0, 0.0, 0.0]), 0.0)
	assert_int(todos.size()).is_equal(foram.size())


## Quem fica no campo nao volta as colunas. Com a marcha acabada ja nao esta fora, e
## quem tinha nome e chorado pelos titulos, como qualquer morto.
func test_quem_fica_no_campo_e_chorado() -> void:
	var unidades := UnitSystem.new()
	var nomes := SimFactory.titles()
	var a := unidades.spawn(GameState.new(), Registry.entry(&"units", &"archer"), 1, 10.0)
	nomes.holders[&"the_one_who_stayed"] = a
	var m := March.new()
	nomes.away = m.away
	m.start(unidades, PackedInt32Array([a]), 1, 11, 1)
	var voltam := March.survivors(m.finish(), PackedFloat32Array([0.0]), _curva().march_loss_chance)
	assert_array(voltam).is_empty()
	nomes.at_dawn(12, unidades, SimFactory.job_board())
	assert_bool(nomes.holders.has(&"the_one_who_stayed")).is_false()
	assert_bool(nomes.mourning.has(&"the_one_who_stayed")).is_true()


## No jogo: cada marcha com o minimo de gente tira a sua parte, a fortaleza fica de pe
## com o que sobra, e cai na marcha em que a conta chega a zero — nem antes nem depois.
func test_no_jogo_a_fortaleza_cai_quando_a_conta_chega_a_zero() -> void:
	_comecar()
	var reino := SimLoop.field.realm
	var alvo := reino.next_target(SimLoop.state)
	var golpe := _curva().march_min_party * _curva().march_siege_per_unit
	var precisa := ceili(float(_cheia(alvo)) / float(golpe))
	var dia := _curva().crossing_day
	var marchas := 0
	while reino.next_target(SimLoop.state) == alvo and marchas < LIMITE:
		_marchar(dia)
		marchas += 1
		dia += 1
		if marchas < precisa:
			assert_int(_firmeza(reino.march, alvo)).is_equal(_cheia(alvo) - marchas * golpe)
			assert_bool(reino.vassals.has(Realm._povo(_regiao(alvo)))).is_false()
	assert_int(marchas).is_equal(precisa)
	assert_bool(reino.vassals.has(Realm._povo(_regiao(alvo)))).is_true()
	assert_array(_conquistas).is_equal([[alvo, Realm._povo(_regiao(alvo))]])
	# Conquistada, a conta limpa-se: se a mancha comer o vassalo (Q-103), a fortaleza
	# volta inteira e reconquista-se do principio.
	assert_bool(reino.march.sieges.has(alvo)).is_false()
	assert_int(_firmeza(reino.march, alvo)).is_equal(_cheia(alvo))


## As baixas saem do fluxo combat: a mesma semente, a mesma marcha, os mesmos que
## voltam — e nunca mais do que os que foram.
func test_as_baixas_sao_as_mesmas_com_a_mesma_semente() -> void:
	_comecar()
	var primeira := _marchar(_curva().crossing_day)
	SimLoop.stop()
	_comecar()
	var segunda := _marchar(_curva().crossing_day)
	assert_array(segunda).is_equal(primeira)
	assert_int(primeira.size()).is_less_equal(_curva().march_min_party)


## O reconhecimento (§13): na bifurcacao, de dia, o guia diz a firmeza que sobra da
## fortaleza seguinte e o quanto os que la estao lhe tirariam.
func test_a_bifurcacao_diz_quanto_falta_a_fortaleza() -> void:
	TranslationServer.set_locale("pt_PT")
	_comecar()
	var reino := SimLoop.field.realm
	var alvo := reino.next_target(SimLoop.state)
	_no_dia(_curva().crossing_day)
	_na_bifurcacao()
	_trazer(_curva().march_min_party)
	var texto := GameplayGuide.context(Glyphs.Device.KEYBOARD)
	assert_str(texto).contains("%d/%d" % [_cheia(alvo), _cheia(alvo)])
	var golpe := _curva().march_min_party * _curva().march_siege_per_unit
	assert_str(texto).contains(str(golpe))


func _comecar() -> void:
	_conquistas = []
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()
	SimLoop.step(STEP)
	if not EventBus.fortress_conquered.is_connected(_conquistou):
		EventBus.fortress_conquered.connect(_conquistou)


## Uma marcha so com os que se trazem: o rei na bifurcacao, onde mais ninguem esta, e
## a volta longe dele, para a marcha seguinte ser outra vez so dos novos. Devolve os
## ids de quem voltou.
func _marchar(dia: int) -> Array[int]:
	var reino := SimLoop.field.realm
	_na_bifurcacao()
	var foram := _trazer(_curva().march_min_party)
	assert_bool(reino.send(SimLoop.units, SimLoop.king_id, SimLoop.state, dia)).is_true()
	var volta := Vector2(SimLoop.core_x, SimLoop.secrets.chapters[0] + LONGE)
	reino.dawn(dia + 1, SimLoop.units, SimLoop.state, SimLoop.king_id, volta)
	EventBus.flush()
	var voltaram: Array[int] = []
	for id in foram:
		if SimLoop.units.index_of(id) != UnitSystem.NENHUM:
			voltaram.append(id)
	return voltaram


func _trazer(quantos: int) -> Array[int]:
	var r := SimLoop.units.index_of(SimLoop.king_id)
	var arqueiro := Registry.entry(&"units", &"archer") as UnitData
	var ids: Array[int] = []
	for _k in quantos:
		var x: float = SimLoop.units.xs[r]
		ids.append(SimLoop.units.spawn(SimLoop.state, arqueiro, SimLoop.units.owners[r], x))
	return ids


func _na_bifurcacao() -> void:
	var r := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.xs[r] = SimLoop.secrets.chapters[0]
	SimLoop.units.set_target_x(SimLoop.king_id, SimLoop.secrets.chapters[0])


func _no_dia(dia: int) -> void:
	ClockService.seek(dia, 0.0)
	SimLoop.state.day = dia
	SimLoop.step(STEP)


func _regiao(k: int) -> String:
	return SimLoop.state.chapters.regions[k]


func _conquistou(regiao: int, povo: StringName) -> void:
	_conquistas.append([regiao, povo])
