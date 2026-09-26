# tests/captions_test.gd — as legendas de som (§26; GB-22).
#
# O §26 poe "legendas para pistas sonoras — 8 pistas (sino, crepusculo, muro a
# cair...)" na lista do que se faz: "substitui o audio para surdos". As oito
# chaves CAPTION_* estavam no strings.csv desde o dia zero e nada as mostrava.
extends GdUnitTestSuite

const FOLHA := "res://docs/audio/AUDIO_CUE_SHEET.csv"


func _legendas(ligadas: bool = true) -> Captions:
	var c: Captions = auto_free(Captions.new())
	add_child(c)
	c.enabled = ligadas
	return c


## Desligadas por omissao, desde antes do primeiro frame: o sino da alvorada do
## dia 1 chega no primeiro tick, e apanhava-as ligadas.
func test_nascem_com_a_preferencia_e_nao_ligadas() -> void:
	var c: Captions = auto_free(Captions.new())
	add_child(c)
	assert_bool(c.enabled).is_equal(Preferences.on(Preferences.CAPTIONS))


## A folha de pistas da bibliografia de audio diz que evento dispara cada
## legenda. O codigo diz o mesmo — para as pistas cujo sinal ja se emite. Se um
## dos dois mudar sozinho, isto chumba.
func test_o_mapa_e_o_da_folha_de_pistas() -> void:
	var folha := {}
	var f := FileAccess.open(FOLHA, FileAccess.READ)
	var cabeca := f.get_csv_line()
	var ev := cabeca.find("event")
	var chave := cabeca.find("caption_key")
	while not f.eof_reached():
		var linha := f.get_csv_line()
		if linha.size() > chave and linha[chave].begins_with("CAPTION_"):
			folha[linha[chave]] = linha[ev]
	for sinal: StringName in Captions.PISTAS:
		var k: StringName = Captions.PISTAS[sinal]
		assert_str(folha.get(String(k), "")).override_failure_message(String(k)).is_equal(sinal)
	assert_str(folha.get("CAPTION_KING_HIT", "")).starts_with("unit_damaged")
	assert_str(folha.get("CAPTION_ROT_NEAR", "")).is_equal("rot_moved")


func test_uma_pista_mostra_a_legenda_e_ela_passa() -> void:
	var c := _legendas()
	c.say(&"CAPTION_DAWN_BELL")
	assert_str(c.text).contains(tr(&"CAPTION_DAWN_BELL"))
	c.advance(Captions.DURA_S + 0.1)
	assert_str(c.text).is_empty()


## Desligadas, nao se ve nada: e uma opcao, e quem ouve pode nao a querer.
func test_desligadas_nao_mostram_nada() -> void:
	var c := _legendas(false)
	c.say(&"CAPTION_NIGHT")
	assert_str(c.text).is_empty()


## A mesma pista duas vezes e uma linha, com o tempo refeito — o max_instances 1
## da folha. Um rei atingido dez vezes nao enche o ecra de dez linhas.
func test_a_mesma_pista_nao_se_repete() -> void:
	var c := _legendas()
	c.say(&"CAPTION_KING_HIT")
	c.say(&"CAPTION_KING_HIT")
	assert_int(c.text.split("\n").size()).is_equal(1)


func test_nunca_mais_de_tres_linhas() -> void:
	var c := _legendas()
	for k in [
		&"CAPTION_DAWN_BELL", &"CAPTION_NIGHT", &"CAPTION_KING_HIT", &"CAPTION_WALL_BREACHED"
	]:
		c.say(k)
	assert_int(c.text.split("\n").size()).is_equal(Captions.LINHAS)


## "Uma vez quando a mancha entra na largura visivel" (folha de pistas).
func test_a_mancha_entra_no_ecra() -> void:
	var ecra := Vector2(1000.0, 2280.0)
	assert_bool(Captions.in_view(3000.0, 400.0, ecra)).is_false()
	assert_bool(Captions.in_view(2400.0, 400.0, ecra)).is_true()
	assert_bool(Captions.in_view(900.0, 400.0, ecra)).is_true()


## AUD-03: a mancha alimentada (Q-127) e quem se vai embora sem soldo (Q-124).
## Quem foge com medo nao tem legenda: ve-se a correr.
func test_o_sacrificio_e_quem_se_vai_embora_tem_legenda() -> void:
	var c := _legendas()
	EventBus.rot_fed.emit(8.0, &"coins")
	assert_str(c.text).contains(tr(&"CAPTION_ROT_FED"))
	EventBus.unit_fled.emit(1, &"morale")
	assert_str(c.text).not_contains(tr(&"CAPTION_UNIT_LEFT"))
	EventBus.unit_fled.emit(1, &"upkeep")
	assert_str(c.text).contains(tr(&"CAPTION_UNIT_LEFT"))
