# tests/som_test.gd — os sons provisorios (ADR 0054, Q-209).
#
# O jogo nao tinha som nenhum. As pistas que o SynthSfx sabe fazer sao as da folha de
# pistas (docs/audio/AUDIO_CUE_SHEET.csv), com o mesmo evento, volume, variacao de tom e
# maximo de vozes; e quem as toca ouve os sinais da §46, sem a simulacao saber.
extends GdUnitTestSuite

const FOLHA := "res://docs/audio/AUDIO_CUE_SHEET.csv"
## As preferencias do teste: nunca as de quem corre a suite (user://settings.cfg).
const FICHEIRO := "user://som_test.cfg"
const DT := 1.0 / 60.0


func before_test() -> void:
	Preferences.set_shared(Preferences.new(FICHEIRO))


func after_test() -> void:
	Preferences.set_shared(null)
	for f in [FICHEIRO, FICHEIRO + ".tmp"]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	if SimLoop.running():
		SimLoop.stop()
	SimLoop.autosave_enabled = true


func _folha() -> Dictionary:
	var linhas := {}
	var f := FileAccess.open(FOLHA, FileAccess.READ)
	var cabeca := f.get_csv_line()
	while not f.eof_reached():
		var linha := f.get_csv_line()
		if linha.size() == cabeca.size():
			var d := {}
			for k in cabeca.size():
				d[cabeca[k]] = linha[k]
			linhas[StringName(linha[0])] = d
	return linhas


func _diretor() -> SfxDirector:
	while not SynthSfx.warm():
		pass
	var d: SfxDirector = auto_free(SfxDirector.new())
	add_child(d)
	return d


func test_cada_pista_e_a_da_folha() -> void:
	var folha := _folha()
	for cue: StringName in SfxCues.CUES:
		assert_bool(folha.has(cue)).override_failure_message(String(cue)).is_true()
		var linha: Dictionary = folha[cue]
		var pista := SfxCues.of(cue)
		assert_str(linha.event).contains(String(pista[SfxCues.EVENTO]))
		assert_float(float(linha.volume_db)).is_equal(pista[SfxCues.VOLUME])
		assert_float(float(linha.pitch_variation)).is_equal(pista[SfxCues.TOM])
		assert_int(int(linha.max_instances)).is_equal(pista[SfxCues.MAXIMO])
		var alcance := 0.0 if linha.distance_px == "—" else float(linha.distance_px)
		assert_float(alcance).is_equal(pista[SfxCues.DISTANCIA])


func test_cada_pista_tem_som_e_cada_som_tem_pista() -> void:
	for cue: StringName in SfxCues.CUES:
		assert_bool(SynthSfx.has(cue)).override_failure_message(String(cue)).is_true()
	for cue: StringName in SynthSfx.RECEITAS:
		assert_bool(SfxCues.CUES.has(cue)).override_failure_message(String(cue)).is_true()


## Cada som dura o que a receita diz, ouve-se, e nunca satura.
func test_os_sons_tem_a_duracao_e_o_pico_certos() -> void:
	for cue: StringName in SynthSfx.RECEITAS:
		var receita: Dictionary = SynthSfx.RECEITAS[cue]
		var a := SynthSfx.samples(receita)
		assert_int(a.size()).is_equal(int(float(receita.dur) * SynthSfx.TAXA))
		var pico := 0.0
		for v in a:
			pico = maxf(pico, absf(v))
		assert_float(pico).is_equal_approx(SynthSfx.PICO, 0.001)
		assert_float(absf(a[a.size() - 1])).is_less(0.01)  # acaba em silencio, sem estalo
		var wav := SynthSfx.stream(cue)
		assert_int(wav.data.size()).is_equal(a.size() * 2)


## Sem sorteio: o mesmo som duas vezes e o mesmo som (§42).
func test_o_som_e_sempre_o_mesmo() -> void:
	var receita: Dictionary = SynthSfx.RECEITAS[&"sfx_coin_drop"]
	var uma := SynthSfx.samples(receita)
	var outra := SynthSfx.samples(receita)
	assert_bool(uma == outra).is_true()


## O Kingdom: cada moeda que entra numa obra toca mais aguda, ate a obra ficar paga.
func test_a_moeda_na_obra_sobe_de_tom() -> void:
	var antes := SfxDirector.pay_pitch(0, 6)
	for pago in range(1, 7):
		var agora := SfxDirector.pay_pitch(pago, 6)
		assert_float(agora).is_greater(antes)
		antes = agora
	assert_float(SfxDirector.pay_pitch(6, 6)).is_equal(1.0 + SfxDirector.SUBIDA)
	assert_float(SfxDirector.pay_pitch(9, 6)).is_equal(1.0 + SfxDirector.SUBIDA)


## Longe da camara baixa, e alem da distancia da folha ja nao toca; o sino ouve-se sempre.
func test_a_distancia_baixa_o_volume_e_cala() -> void:
	var moeda := SfxCues.of(&"sfx_coin_drop")
	assert_float(SfxDirector.volume_at(moeda, 100.0, 100.0)).is_equal(moeda[SfxCues.VOLUME])
	var meio := SfxDirector.volume_at(moeda, 420.0, 100.0)
	assert_float(meio).is_less(moeda[SfxCues.VOLUME])
	assert_bool(is_nan(SfxDirector.volume_at(moeda, 1000.0, 100.0))).is_true()
	var sino := SfxCues.of(&"stg_dawn_bell")
	assert_float(SfxDirector.volume_at(sino, 9000.0, 0.0)).is_equal(0.0)


func test_o_sino_da_alvorada_toca_pelo_sinal() -> void:
	var d := _diretor()
	EventBus.dawn_broke.emit(2)
	assert_str(String(d.last_cue)).is_equal("stg_dawn_bell")
	EventBus.dusk_fell.emit(2)
	assert_str(String(d.last_cue)).is_equal("stg_dusk_warning")


## Desligado na pausa, nao toca nada.
func test_com_o_som_desligado_nao_toca() -> void:
	var d := _diretor()
	Preferences.shared().set_enabled(Preferences.SOUND, false)
	assert_bool(d.play(&"stg_dawn_bell")).is_false()
	assert_str(String(d.last_cue)).is_equal("")


## Nunca mais vozes iguais do que a folha deixa: o sino e um so.
func test_o_maximo_de_vozes_iguais() -> void:
	var d := _diretor()
	assert_bool(d.play(&"stg_dawn_bell")).is_true()
	assert_bool(d.play(&"stg_dawn_bell")).is_false()


## O aquecimento faz os sons aos bocados, e no fim estao todos feitos.
func test_o_aquecimento_faz_tudo_aos_bocados() -> void:
	var voltas := 0
	while not SynthSfx.warm():
		voltas += 1
	for cue: StringName in SynthSfx.RECEITAS:
		assert_bool(SynthSfx.ready(cue)).is_true()
	assert_bool(SynthSfx.warm()).is_true()


## O sino da primeira alvorada sai no primeiro tick, antes de o aquecimento la chegar:
## nao se perde, passa a frente e toca assim que esta feito.
func test_a_pista_pedida_a_frio_toca_quando_fica_feita() -> void:
	SynthSfx.forget()
	var d: SfxDirector = auto_free(SfxDirector.new())
	add_child(d)
	EventBus.dawn_broke.emit(1)
	assert_str(String(d.last_cue)).is_equal("")
	var voltas := 0
	while d.last_cue == &"" and voltas < SynthSfx.RECEITAS.size() * SynthSfx.TAXA:
		d._process(0.0)
		voltas += 1
	assert_str(String(d.last_cue)).is_equal("stg_dawn_bell")
	# Faz-se e passa-se a 16 bits aos bocados: duas voltas por bocado, e nenhuma outra
	# pista antes dela.
	var sino := int(SynthSfx.duration(&"stg_dawn_bell") * SynthSfx.TAXA)
	assert_int(voltas).is_less_equal(2 * ceili(float(sino) / SynthSfx.POR_FRAME) + 1)


## A moeda pedida a frio que so fica feita depois de passar o que duraria ja nao toca.
func test_a_pista_que_ja_nao_vai_a_tempo_nao_toca() -> void:
	SynthSfx.forget()
	var d: SfxDirector = auto_free(SfxDirector.new())
	add_child(d)
	d.play(&"sfx_coin_drop", NAN)
	while not SynthSfx.ready(&"sfx_coin_drop"):
		d._process(SynthSfx.duration(&"sfx_coin_drop"))
	d._process(0.0)
	assert_str(String(d.last_cue)).is_equal("")


## A ultima moeda de uma obra: o absorb tira-lhe o custo e o pago volta a zero, mas a
## obra arranca (build_started) e a moeda ouve-se, a mais aguda.
func test_a_moeda_que_paga_a_obra_tambem_toca() -> void:
	SimLoop.autosave_enabled = false
	SimLoop.start(20261003)
	Greybox.build()
	var d := _diretor()
	var vaga: BuildSlot = SimLoop.builds.slots[0]
	d._process(DT)
	EventBus.build_started.emit(vaga.id, vaga.kind)
	assert_str(String(d.last_cue)).is_equal(String(SfxDirector.MOEDA))
