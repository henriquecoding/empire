extends GdUnitTestSuite

## O relatorio de 06/10/2026 (A01, T02, T03, T10, T19, T44, T45): fundar longe da agua nao
## leva o pesqueiro do segmento de partida; a previsao e a confirmacao dizem o mesmo.

const PESQUEIRO := &"fishery"
const MINA := &"ore_pit"


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261006)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _vagas(kind: StringName) -> Array[BuildSlot]:
	var saida: Array[BuildSlot] = []
	for vaga in SimLoop.builds.slots:
		if vaga.kind == kind:
			saida.append(vaga)
	return saida


## O primeiro sitio valido a pelo menos `longe` px da origem, de um lado ou do outro.
func _sitio(longe: float) -> float:
	var o := SimLoop.arrival.origin
	for passo in 40:
		for lado in [-1.0, 1.0]:
			var x: float = o + lado * (longe + 24.0 * passo)
			if FoundationChoice.valid(x) and not FoundationChoice.priority_at(x):
				return x
	return NAN


func _fundar(x: float) -> bool:
	var u := SimLoop.units
	u.xs[u.index_of(SimLoop.king_id)] = x
	u.clear_target(SimLoop.king_id)
	SimLoop.step(1.0)
	return FoundationChoice.claim(x)


func test_a_regiao_autora_a_agua_e_o_pesqueiro_fica_ao_pe_dela() -> void:
	assert_array(SimLoop.field.waters).has_size(1)
	assert_float(SimLoop.field.waters[0]).is_equal(SimLoop.core_x + Greybox.AGUAS_X[0])
	var pesqueiro := _vagas(PESQUEIRO)
	assert_array(pesqueiro).has_size(1)
	assert_str(String(pesqueiro[0].terrain_bar)).is_empty()
	for mina in _vagas(MINA):
		assert_str(String(mina.terrain_bar)).is_empty()


func test_fundar_perto_conserva_o_pesqueiro() -> void:
	assert_bool(_fundar(SimLoop.arrival.origin - 83.0)).is_true()
	var pesqueiro := _vagas(PESQUEIRO)[0]
	assert_str(String(pesqueiro.terrain_bar)).is_empty()
	assert_int(RealmGrowth.refusal(SimLoop.builds, pesqueiro)).is_not_equal(
		RealmGrowth.Need.TERRAIN
	)


func test_fundar_longe_da_agua_fecha_o_pesqueiro_e_nao_o_cobra() -> void:
	var x := _sitio(1400.0)
	assert_bool(is_finite(x)).is_true()
	var agua := SimLoop.field.waters.duplicate()
	assert_bool(_fundar(x)).is_true()  # T03: um sitio pobre funda-se na mesma
	assert_array(SimLoop.field.waters).is_equal(agua)  # a agua nao vem com a sede
	var pesqueiro := _vagas(PESQUEIRO)[0]
	assert_str(String(pesqueiro.terrain_bar)).is_equal("TERRAIN_NO_WATER")
	assert_bool(RealmGrowth.barred(pesqueiro)).is_true()
	assert_int(RealmGrowth.refusal(SimLoop.builds, pesqueiro)).is_equal(RealmGrowth.Need.TERRAIN)
	assert_bool(RealmGrowth.visible(SimLoop.builds, pesqueiro, SimLoop.state)).is_false()
	var madeira := SimLoop.night.amargueiros
	assert_bool(SimLoop.builds.can_climb(pesqueiro, SimLoop.state, madeira)).is_false()  # T19
	for mina in _vagas(MINA):  # T06: longe das passagens, o porao nao chega la
		assert_str(String(mina.terrain_bar)).is_equal("TERRAIN_NO_ROCK")


func test_a_previsao_e_a_confirmacao_dizem_o_mesmo() -> void:
	for longe in [83.0, 1400.0]:
		before_test()
		var x: float = _sitio(longe) if longe > 100.0 else SimLoop.arrival.origin - longe
		var antes: Dictionary = TerritoryWatch.preview(x)
		assert_bool(_fundar(x)).is_true()
		var depois := TerritoryWatch.profile()
		assert_dict(antes[TerritoryProfile.NEEDS]).is_equal(depois[TerritoryProfile.NEEDS])
		assert_array(TerritoryProfile.barred(antes)).is_equal(TerritoryProfile.barred(depois))
		var assinatura := SimLoop.arrival.site_signature
		assert_int(int(assinatura[&"signature_version"])).is_equal(2)
		assert_dict(assinatura[&"territory"]).is_equal(antes[TerritoryProfile.NEEDS])
		after_test()


func test_o_save_reabre_o_mesmo_territorio_sem_duplicar() -> void:
	assert_bool(_fundar(_sitio(1400.0))).is_true()
	var fechados := TerritoryProfile.barred(TerritoryWatch.profile())
	var obras := SimLoop.builds.count()
	var agua := SimLoop.field.waters.duplicate()
	var guardado := SimLoop.world()
	for reload in 2:  # T44: carregar duas vezes nao cria fontes nem obras
		SimLoop.resume(SimLoop.state, RngService.snapshot())
		Greybox.region()
		SimLoop.load_world(guardado)
	assert_int(SimLoop.builds.count()).is_equal(obras)
	assert_array(SimLoop.field.waters).is_equal(agua)
	assert_array(TerritoryProfile.barred(TerritoryWatch.profile())).is_equal(fechados)
	assert_str(String(_vagas(PESQUEIRO)[0].terrain_bar)).is_equal("TERRAIN_NO_WATER")


func test_o_pesqueiro_de_um_save_de_antes_fica_de_pe_e_nao_abre_copias() -> void:
	assert_bool(_fundar(_sitio(1400.0))).is_true()
	var pesqueiro := _vagas(PESQUEIRO)[0]
	pesqueiro.raise_to(1)  # o save de antes ja o tinha levantado longe da agua
	var guardado := SimLoop.world()
	SimLoop.resume(SimLoop.state, RngService.snapshot())
	Greybox.region()
	SimLoop.load_world(guardado)
	pesqueiro = _vagas(PESQUEIRO)[0]
	assert_int(pesqueiro.level).is_equal(1)
	assert_str(String(pesqueiro.terrain_bar)).is_equal("TERRAIN_NO_WATER")  # T45: diz-se
	assert_bool(RealmGrowth.barred(pesqueiro)).is_false()  # e tolera-se
	assert_bool(RealmGrowth.visible(SimLoop.builds, pesqueiro, SimLoop.state)).is_true()
	assert_array(_vagas(PESQUEIRO)).has_size(1)


func test_quando_o_terreno_anda_com_a_sede_a_agua_anda_tambem() -> void:
	var agua := SimLoop.field.waters[0]
	assert_bool(LastCartWatch.claim(&"grove")).is_true()
	assert_float(SimLoop.field.waters[0]).is_equal(agua + LastCartWatch.CHOICES[&"grove"])
	assert_str(String(_vagas(PESQUEIRO)[0].terrain_bar)).is_empty()


func test_a_previsao_diz_o_que_o_sitio_permite_e_o_que_falta() -> void:
	var perto := FoundationGuide.territory(SimLoop.arrival.origin - 83.0)
	var longe := FoundationGuide.territory(_sitio(1400.0))
	var nome := TranslationServer.translate(&"BUILDING_FISHERY")
	var agua := TranslationServer.translate(&"TERRAIN_SOURCE_WATER")
	var ok := TranslationServer.translate(&"TERRAIN_SITE_OK").format({"name": nome, "source": agua})
	var nao := TranslationServer.translate(&"TERRAIN_SITE_NONE").format(
		{"name": nome, "source": agua}
	)
	assert_str(perto).contains(ok)
	assert_str(longe).contains(nao)
	assert_str(longe).not_contains(ok)
