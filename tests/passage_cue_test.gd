# tests/passage_cue_test.gd — onde o Verbo 2 pega, dito no sitio (§11, §24, §25; GB-14).
#
# O §25 poe a passagem ao minuto 10:00 — "e o momento em que o jogo deixa de ser
# Kingdom" — e o §32 mede-a: se a mediana de underground_discovered passar dos
# 20 minutos, "a passagem esta mal sinalizada". A Q-066 ja dizia que o problema,
# se o houvesse, seria esse. O E pegava a 24 px de uma risca de 8 px, e nada no
# ecra dizia que ali o E fazia alguma coisa.
extends GdUnitTestSuite

const PASSAGEM := 1000.0


func _mundo(dados_id: StringName, x: float, faixa: Band.Kind) -> Array:
	var unidades := UnitSystem.new()
	var estado := GameState.new()
	var rei := unidades.spawn(estado, Registry.entry(&"units", dados_id), 0, x)
	unidades.bands[unidades.index_of(rei)] = int(faixa)
	return [unidades, rei]


func _passagens() -> PackedFloat32Array:
	return PackedFloat32Array([PASSAGEM])


func test_na_superficie_a_passagem_desce() -> void:
	var m := _mundo(&"monarch", PASSAGEM, Band.Kind.SURFACE)
	var destino := Verbs.destination(m[0], m[1], _passagens())
	assert_int(destino).is_equal(Band.Kind.UNDERGROUND)


func test_no_subsolo_a_passagem_sobe() -> void:
	var m := _mundo(&"monarch", PASSAGEM, Band.Kind.UNDERGROUND)
	assert_int(Verbs.destination(m[0], m[1], _passagens())).is_equal(Band.Kind.SURFACE)


## A tolerancia e a do Band, e e a mesma para o gesto e para o sinal: se o ves,
## o E pega; um passo para la dela, nem um nem outro.
func test_fora_do_alcance_nao_ha_destino() -> void:
	var dentro := _mundo(&"monarch", PASSAGEM + Band.PASSAGE_PX, Band.Kind.SURFACE)
	var fora := _mundo(&"monarch", PASSAGEM + Band.PASSAGE_PX + 1.0, Band.Kind.SURFACE)
	assert_int(Verbs.destination(dentro[0], dentro[1], _passagens())).is_not_equal(Verbs.NENHUMA)
	assert_int(Verbs.destination(fora[0], fora[1], _passagens())).is_equal(Verbs.NENHUMA)


## So muda de faixa quem pode (o can_change_band do §44). Um vagabundo em cima
## da passagem nao tem destino nenhum, e por isso tambem nao tem sinal.
func test_quem_nao_muda_de_faixa_nao_tem_destino() -> void:
	var m := _mundo(&"vagrant", PASSAGEM, Band.Kind.SURFACE)
	assert_int(Verbs.destination(m[0], m[1], _passagens())).is_equal(Verbs.NENHUMA)


## O gesto e o sinal sao a mesma conta: o assume() muda para o destino que o
## sinal mostra, e nao para outro.
func test_o_verbo_2_vai_para_onde_o_sinal_aponta() -> void:
	var m := _mundo(&"monarch", PASSAGEM, Band.Kind.SURFACE)
	var destino := Verbs.destination(m[0], m[1], _passagens())
	assert_bool(Verbs.assume(m[0], m[1], _passagens())).is_true()
	var unidades: UnitSystem = m[0]
	assert_int(unidades.bands[unidades.index_of(m[1])]).is_equal(destino)


## A seta aponta para onde se vai: para baixo quando se desce, para cima quando
## se sobe. E a unica coisa que ela diz, e tem de a dizer sem palavra (§24).
func test_a_seta_aponta_para_o_destino() -> void:
	var desce := PassageCue.arrow(Vector2(0.0, 100.0), Band.Kind.SURFACE, Band.Kind.UNDERGROUND)
	var sobe := PassageCue.arrow(Vector2(0.0, 100.0), Band.Kind.UNDERGROUND, Band.Kind.SURFACE)
	assert_float(_bico(desce).y).is_greater(_base_y(desce))
	assert_float(_bico(sobe).y).is_less(_base_y(sobe))


func _bico(seta: PackedVector2Array) -> Vector2:
	return seta[PassageCue.BICO]


func _base_y(seta: PackedVector2Array) -> float:
	var soma := 0.0
	for i in seta.size():
		if i != PassageCue.BICO:
			soma += seta[i].y
	return soma / (seta.size() - 1)
