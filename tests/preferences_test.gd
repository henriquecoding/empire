# tests/preferences_test.gd — o tremor e os claroes desligam-se (§24, §26; GB-13).
#
# O §24 escreve "screen shake ... com opcao de desligar (§26)" e o §26 poe
# "desligar screen shake e flashes" na lista do que se faz, com uma palavra:
# "obrigatorio para fotossensibilidade". A §45 diz onde vive: "preferencia de
# sessao, nao estado de jogo. Vai para user://settings.cfg".
#
# Cada teste le e escreve o SEU ficheiro, e nunca o do jogo: as preferencias de
# quem corre a suite nao sao do teste.
extends GdUnitTestSuite

const FICHEIRO := "user://preferences_test.cfg"


func after_test() -> void:
	for f in [FICHEIRO, FICHEIRO + ".tmp"]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))


func _escrever(conteudo: Variant, objectos: bool) -> void:
	var f := FileAccess.open(FICHEIRO, FileAccess.WRITE)
	f.store_var(conteudo, objectos)
	f.close()


## Sem ficheiro, tudo ligado: o §24 desenha o jogo com eles, e quem precisa de os
## desligar desliga — o contrario obrigava toda a gente a ir as opcoes.
func test_sem_ficheiro_esta_tudo_ligado() -> void:
	var p := Preferences.new(FICHEIRO)
	assert_bool(p.enabled(Preferences.SCREEN_SHAKE)).is_true()
	assert_bool(p.enabled(Preferences.FLASHES)).is_true()


## A duracao do dia e um numero, e nao um interruptor: zero e "a do clock.csv".
func test_a_duracao_do_dia_grava_se_como_numero() -> void:
	var p := Preferences.new(FICHEIRO)
	assert_float(p.number(Preferences.DAY_SECONDS)).is_equal(0.0)
	assert_bool(p.set_number(Preferences.DAY_SECONDS, 300.0)).is_true()
	assert_float(Preferences.new(FICHEIRO).number(Preferences.DAY_SECONDS)).is_equal(300.0)
	assert_bool(p.set_number(Preferences.SCREEN_SHAKE, 1.0)).is_false()
	assert_bool(p.set_enabled(Preferences.DAY_SECONDS, true)).is_false()


## As legendas de som vem desligadas: sao para quem precisa delas (GB-22).
func test_as_legendas_vem_desligadas() -> void:
	assert_bool(Preferences.new(FICHEIRO).enabled(Preferences.CAPTIONS)).is_false()


func test_o_que_se_desliga_fica_desligado_depois_de_fechar_o_jogo() -> void:
	assert_bool(Preferences.new(FICHEIRO).set_enabled(Preferences.SCREEN_SHAKE, false)).is_true()
	var outra_sessao := Preferences.new(FICHEIRO)
	assert_bool(outra_sessao.enabled(Preferences.SCREEN_SHAKE)).is_false()
	assert_bool(outra_sessao.enabled(Preferences.FLASHES)).is_true()


## A regra da ADR 0007, aplicada tambem aqui: o ficheiro le-se com objectos
## desligados. Um settings.cfg com um objecto la dentro nao e lido — e o jogo
## continua, com os valores por omissao, em vez de correr o que vinha nele.
func test_um_ficheiro_com_objectos_nao_se_le() -> void:
	_escrever({"screen_shake": RefCounted.new(), "flashes": false}, true)
	var p := Preferences.new(FICHEIRO)
	assert_bool(p.enabled(Preferences.SCREEN_SHAKE)).is_true()
	assert_bool(p.enabled(Preferences.FLASHES)).is_true()


## Campo a campo, como o save: um tipo errado ou uma chave desconhecida ignoram-se
## e o resto le-se (degrada em vez de recusar, ADR 0007).
func test_um_campo_estragado_nao_leva_os_outros() -> void:
	_escrever({"screen_shake": "nao", "flashes": false, "outra_coisa": true}, false)
	var p := Preferences.new(FICHEIRO)
	assert_bool(p.enabled(Preferences.SCREEN_SHAKE)).is_true()
	assert_bool(p.enabled(Preferences.FLASHES)).is_false()


func test_um_ficheiro_que_nao_e_um_dicionario_e_o_mesmo_que_nenhum() -> void:
	_escrever(42, false)
	assert_bool(Preferences.new(FICHEIRO).enabled(Preferences.FLASHES)).is_true()


## So se desligam as que o §26 lista. Uma chave inventada nao se grava: o
## ficheiro e a lista do dossie, e nao um saco onde cabe tudo.
func test_uma_preferencia_que_nao_existe_nao_se_grava() -> void:
	assert_bool(Preferences.new(FICHEIRO).set_enabled(&"modo_turbo", false)).is_false()
	assert_bool(FileAccess.file_exists(FICHEIRO)).is_false()


## O caminho e o da §45, e nao outro — e e o das partilhadas.
func test_o_ficheiro_e_o_da_seccao_45() -> void:
	assert_str(Preferences.FICHEIRO).is_equal("user://settings.cfg")
	assert_str(Preferences.shared().path).is_equal(Preferences.FICHEIRO)
