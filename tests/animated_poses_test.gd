# tests/animated_poses_test.gd — o que os bichos e as criaturas animados fazem no ecra (ADR 0083).
#
# O que se ve sai do que a simulacao ja diz: a caca corre, anda e come pelo passo da Herd;
# as criaturas fogem, investem e levantam-se pelas colunas; o cavalo anda e galopa com quem
# o monta; as galinhas passeiam a frente do galinheiro.
extends GdUnitTestSuite

const F := Silhouette.Form


func test_a_caca_corre_a_fugir_anda_a_pastar_e_come_nas_pontas() -> void:
	var coelho := Registry.entry(&"wildlife", &"rabbit") as WildlifeData
	var manada := Herd.new()
	manada.arrive(100.0)
	var fuga := coelho.move_speed
	assert_str(String(HuntPoses.action_of(coelho, fuga, manada, 100.0, 1.0))).is_equal("run")
	var pasto := coelho.graze_speed
	assert_str(String(HuntPoses.action_of(coelho, pasto, manada, 100.0, 1.0))).is_equal("walk")
	assert_str(String(HuntPoses.action_of(coelho, 0.0, manada, 100.0, 1.0))).is_equal("feed")


func test_o_javali_ferido_ameaca_quando_bate_e_o_atordoado_fica_parado() -> void:
	var javali := Registry.entry(&"wildlife", &"boar") as WildlifeData
	var manada := Herd.new()
	manada.arrive(100.0)
	manada.provoked[100.0] = true
	manada.cooldowns[100.0] = javali.attack_interval
	var ameaca := AnimatedArt.seconds(&"animal_boar", &"special")
	assert_str(String(HuntPoses.action_of(javali, 0.0, manada, 100.0, ameaca))).is_equal("special")
	manada.cooldowns[100.0] = 0.0
	var corre := javali.move_speed
	assert_str(String(HuntPoses.action_of(javali, corre, manada, 100.0, ameaca))).is_equal("run")
	manada.stunned[100.0] = 1.0
	assert_str(String(HuntPoses.action_of(javali, corre, manada, 100.0, ameaca))).is_equal("idle")


func test_as_galinhas_passeiam_a_frente_do_galinheiro_e_voltam() -> void:
	var largura := 96.0
	var meio := largura * FarmAnimals.PASSEIO * 0.5
	var volta := FarmAnimals.cycle_seconds(&"animal_hen", largura)
	assert_float(volta).is_greater(0.0)
	var inicio := FarmAnimals.stroll(&"animal_hen", 500.0, largura, 0.0)
	assert_float(inicio.x).is_equal_approx(500.0 - meio, 0.01)
	assert_float(inicio.y).is_equal(1.0)
	var t := 0.0
	while t < volta:
		var passo := FarmAnimals.stroll(&"animal_hen", 500.0, largura, t)
		assert_float(passo.x).is_between(500.0 - meio - 0.01, 500.0 + meio + 0.01)  # Vector3 e float32
		t += 0.25
	var outra_volta := FarmAnimals.stroll(&"animal_hen", 500.0, largura, volta)
	assert_float(outra_volta.x).is_equal_approx(inicio.x, 0.01)


func test_quem_rouba_ou_recua_foge_e_quem_luta_esta() -> void:
	var bichos := CreatureSystem.new()
	var estado := GameState.new()
	var ariete := Registry.entry(&"creatures", &"slime_ram") as CreatureData
	bichos.spawn(estado, ariete, 100.0, 1.0)
	assert_str(String(AnimatedBeasts.loop_of(F.ARIETE, bichos, 0, false))).is_equal("idle")
	assert_str(String(AnimatedBeasts.loop_of(F.ARIETE, bichos, 0, true))).is_equal("walk")
	bichos.recoils[0] = 0.5
	assert_str(String(AnimatedBeasts.loop_of(F.ARIETE, bichos, 0, true))).is_equal("flee")
	# engajado, nao anda (CreatureSystem.tick_movement): o recuo a meio nao o faz correr
	bichos.target_slots[0] = 7
	assert_str(String(AnimatedBeasts.loop_of(F.ARIETE, bichos, 0, false))).is_equal("idle")
	var alado := Registry.entry(&"creatures", &"winged") as CreatureData
	bichos.spawn(estado, alado, 200.0, 1.0)
	bichos.loot_slots[1] = 3
	assert_str(String(AnimatedBeasts.loop_of(F.ASA, bichos, 1, true))).is_equal("flee")
	assert_str(String(AnimatedBeasts.loop_of(F.ASA, bichos, 1, false))).is_equal("idle")


## O Ariete so tem a obra por alvo quando ja lhe chega, e ai para: investe no ultimo corpo
## antes da muralha que tem a frente, e anda no resto do caminho.
func test_o_ariete_investe_no_ultimo_corpo_antes_da_muralha() -> void:
	var obras := BuildSystem.new()
	var muro := WallSite.slot(1000.0)
	muro.level = 1
	muro.state = BuildSlot.State.DONE
	muro.health = muro.max_health()
	obras.post(muro)
	var bichos := CreatureSystem.new()
	var ariete := Registry.entry(&"creatures", &"slime_ram") as CreatureData
	var corpo := float(ariete.shadow_width)
	var face := muro.x + muro.width * 0.5
	bichos.spawn(GameState.new(), ariete, face + corpo * 3.0, 0.0)
	assert_bool(AnimatedBeasts.charging(bichos, 0, obras, corpo)).is_false()
	bichos.xs[0] = face + corpo * 0.5
	assert_bool(AnimatedBeasts.charging(bichos, 0, obras, corpo)).is_true()
	var investe := AnimatedBeasts.loop_of(F.ARIETE, bichos, 0, true, true)
	assert_str(String(investe)).is_equal("charge")
	bichos.goal_xs[0] = face + corpo * 5.0  # a muralha ficou para tras
	assert_bool(AnimatedBeasts.charging(bichos, 0, obras, corpo)).is_false()


## Parado mas acossado nao come: o javali ferido entre golpes e o coelho encurralado no fim
## do terreno dele ficam de pe.
func test_quem_esta_acossado_nao_come() -> void:
	var coelho := Registry.entry(&"wildlife", &"rabbit") as WildlifeData
	var manada := Herd.new()
	manada.arrive(100.0)
	manada.xs[100.0] = 100.0 + coelho.flee_px
	assert_str(String(HuntPoses.action_of(coelho, 0.0, manada, 100.0, 1.0))).is_equal("idle")
	manada.xs[100.0] = 100.0 + coelho.roam_px
	assert_str(String(HuntPoses.action_of(coelho, 0.0, manada, 100.0, 1.0))).is_equal("feed")
	var javali := Registry.entry(&"wildlife", &"boar") as WildlifeData
	manada.arrive(500.0)
	manada.provoked[500.0] = true
	assert_str(String(HuntPoses.action_of(javali, 0.0, manada, 500.0, 0.5))).is_equal("idle")


func test_quem_aparece_a_meio_da_noite_levanta_se_e_quem_ja_la_estava_nao() -> void:
	var bichos := CreatureSystem.new()
	var estado := GameState.new()
	var rastejante := Registry.entry(&"creatures", &"crawler") as CreatureData
	bichos.spawn(estado, rastejante, 100.0, 1.0)
	CombatFx.reset()
	var vista := AnimatedBeasts.new()
	vista.observe(bichos, 10.0)
	var nunca := StrikePose.NUNCA
	var repouso := AnimatedArt.frame(&"beast_crawler", &"idle", 10.0)
	assert_int(vista.frame_of(F.RASTEJO, bichos, 0, false, nunca, 0.0)).is_equal(repouso)
	bichos.spawn(estado, rastejante, 200.0, 1.0)
	vista.observe(bichos, 11.0)
	var nasce := AnimatedArt.frame(&"beast_crawler", &"spawn", 0.0)
	assert_int(vista.frame_of(F.RASTEJO, bichos, 1, false, nunca, 0.0)).is_equal(nasce)


## Um jogo novo recarrega a cena e o relogio do ecra volta a zero, mas o que e estatico
## fica: um tempo que anda para tras e um comeco, e nao uma accao parada no futuro.
func test_o_relogio_do_ecra_que_volta_a_zero_recomeca_a_accao() -> void:
	var relogio := AnimClock.new()
	relogio.play(1.0, &"feed", 500.0)
	assert_float(relogio.play(1.0, &"feed", 503.0)).is_equal(3.0)
	assert_float(relogio.play(1.0, &"feed", 2.0)).is_equal(0.0)
	assert_float(relogio.play(1.0, &"feed", 4.0)).is_equal(2.0)


## Montado, o cavalo anda ao passo do cavalo e so galopa com o correr premido.
func test_o_cavalo_montado_anda_e_so_galopa_a_correr() -> void:
	var perfil := &"animal_draft_horse"
	MountView.frame_of(perfil, true, false, 100.0, 10.0)
	var anda := MountView.frame_of(perfil, true, false, 104.0, 10.05)
	var tag: Dictionary = AnimatedArt.entry(perfil).tags
	assert_int(anda).is_between(int(tag.walk.from_frame), int(tag.walk.to_frame))
	var galopa := MountView.frame_of(perfil, true, true, 108.0, 10.1)
	assert_int(galopa).is_between(int(tag.run.from_frame), int(tag.run.to_frame))
	var parado := MountView.frame_of(perfil, true, false, 108.0, 11.0)
	assert_int(parado).is_between(int(tag.idle.from_frame), int(tag.idle.to_frame))
