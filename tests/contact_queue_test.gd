# tests/contact_queue_test.gd — os slots de contacto e a fila do §50.
#
# Duas regras, e as duas sao de legibilidade antes de serem de equilibrio:
#
#   §07 · "so N atacantes engajam"
#   §50 · "a fila tem posicoes estaveis entre 30 e 120 px — ATRIBUIDAS, nao
#          emergentes. Uma regra de dados, nao de fisica."
#
# O que se prova aqui nao e que a fila seja justa: e que ela e a MESMA duas
# vezes, e que ninguem a meio dela bate no muro.
extends GdUnitTestSuite

const NUCLEO := 0.0
const MEIO := 0.5


func _curva() -> EconomyCurve:
	return Registry.entry(&"economy", &"curve") as EconomyCurve


func _muro(obras: BuildSystem, nivel: StringName, x: float) -> BuildSlot:
	var vaga := BuildSlot.new()
	vaga.x = x
	vaga.blocks = true
	vaga.kind = nivel
	for w in SimFactory.walls_by_level():
		vaga.costs.append(w.cost)
		vaga.works.append(float(w.cost))
		vaga.healths.append(w.max_health_b)
		vaga.healths_a.append(w.max_health_a)
		vaga.posts_a.append(w.guard_posts_a)
		vaga.posts_b.append(w.guard_posts_b)
		vaga.contacts.append(w.contact_slots)
		vaga.width = maxf(vaga.width, float(w.shadow_width))
	obras.post(vaga)
	vaga.path = BuildSlot.Path.FORTIFICACAO
	vaga.level = _nivel_de(nivel)
	vaga.state = BuildSlot.State.DONE
	vaga.health = vaga.max_health()
	return vaga


func _nivel_de(id: StringName) -> int:
	return (Registry.entry(&"walls", id) as WallData).level


func _bichos(criaturas: CreatureSystem, estado: GameState, xs: Array) -> PackedInt32Array:
	var dados := Registry.entry(&"creatures", &"crawler") as CreatureData
	var ids := PackedInt32Array()
	for x in xs:
		ids.append(criaturas.spawn(estado, dados, float(x), NUCLEO))
	ids.sort()
	return ids


func test_so_engajam_os_slots_que_o_nivel_tem() -> void:
	# §10: a estacaria tem 2 slots de contacto e o bastiao tem 7. Cinco bichos
	# contra uma estacaria dao dois a bater e tres a ver.
	var estado := GameState.new()
	var criaturas := CreatureSystem.new()
	var obras := BuildSystem.new()
	var muro := _muro(obras, &"stakes", 500.0)
	var ids := _bichos(criaturas, estado, [560, 580, 600, 620, 640])
	var fila := ContactQueue.new(_curva())

	fila.assign(muro, criaturas, ids)

	var engajados := 0
	for quem in ids:
		if fila.holds(muro, quem):
			engajados += 1
	assert_int(engajados).is_equal(muro.contact_slots())
	assert_int(engajados).is_equal((Registry.entry(&"walls", &"stakes") as WallData).contact_slots)


func test_o_bastiao_engaja_mais_do_que_a_estacaria() -> void:
	var estado := GameState.new()
	var criaturas := CreatureSystem.new()
	var obras := BuildSystem.new()
	var bastiao := _muro(obras, &"bastion", 500.0)
	var ids := _bichos(criaturas, estado, [520, 540, 560, 580, 600, 620, 640, 660, 680])
	var fila := ContactQueue.new(_curva())

	fila.assign(bastiao, criaturas, ids)

	var engajados := 0
	for quem in ids:
		if fila.holds(bastiao, quem):
			engajados += 1
	assert_int(engajados).is_equal(bastiao.contact_slots())
	assert_int(engajados).is_greater(_muro(BuildSystem.new(), &"stakes", 0.0).contact_slots())


func test_os_slots_vao_para_os_mais_proximos() -> void:
	var estado := GameState.new()
	var criaturas := CreatureSystem.new()
	var obras := BuildSystem.new()
	var muro := _muro(obras, &"stakes", 500.0)
	var ids := _bichos(criaturas, estado, [900, 520, 800, 540])
	var fila := ContactQueue.new(_curva())

	fila.assign(muro, criaturas, ids)

	for quem in ids:
		var c := criaturas.index_of(quem)
		var perto := absf(criaturas.xs[c] - muro.x) < 100.0
		assert_bool(fila.holds(muro, quem)).is_equal(perto)


func test_quem_ja_esta_no_slot_fica() -> void:
	# A estabilidade e a funcionalidade: um slot que mudasse de dono a cada tick
	# dava a mesma multidao a tremer que as posicoes atribuidas evitam.
	var estado := GameState.new()
	var criaturas := CreatureSystem.new()
	var obras := BuildSystem.new()
	var muro := _muro(obras, &"stakes", 500.0)
	var ids := _bichos(criaturas, estado, [560, 580, 600])
	var fila := ContactQueue.new(_curva())
	fila.assign(muro, criaturas, ids)
	var antes := muro.contact.duplicate()

	# O que estava mais longe aproxima-se de tudo o resto e mesmo assim nao entra.
	criaturas.xs[criaturas.index_of(ids[2])] = muro.x + 1.0
	fila.assign(muro, criaturas, ids)

	assert_array(muro.contact).is_equal(antes)


func test_um_slot_livre_e_dado_a_quem_esta_mais_perto() -> void:
	var estado := GameState.new()
	var criaturas := CreatureSystem.new()
	var obras := BuildSystem.new()
	var muro := _muro(obras, &"stakes", 500.0)
	var ids := _bichos(criaturas, estado, [560, 580, 600])
	var fila := ContactQueue.new(_curva())
	fila.assign(muro, criaturas, ids)
	var morto := muro.contact[0]

	criaturas.damage(morto, 1000)
	var eventos := fila.assign(muro, criaturas, ids)

	assert_bool(fila.holds(muro, morto)).is_false()
	assert_bool(fila.holds(muro, ids[2])).is_true()
	var tipos: Array[int] = []
	for e in eventos:
		tipos.append(e[ContactQueue.CHAVE])
	assert_array(tipos).contains([ContactQueue.EV_LIVRE, ContactQueue.EV_OCUPADO])


func test_quem_entra_no_slot_leva_os_04_s_de_transicao() -> void:
	var estado := GameState.new()
	var criaturas := CreatureSystem.new()
	var obras := BuildSystem.new()
	var muro := _muro(obras, &"stakes", 500.0)
	var ids := _bichos(criaturas, estado, [560])
	var fila := ContactQueue.new(_curva())

	fila.assign(muro, criaturas, ids)

	assert_float(criaturas.cooldowns[criaturas.index_of(ids[0])]).is_equal_approx(
		_curva().slot_replace_time, 0.001
	)


func test_a_fila_e_a_mesma_duas_vezes() -> void:
	var estado := GameState.new()
	var criaturas := CreatureSystem.new()
	var obras := BuildSystem.new()
	var muro := _muro(obras, &"stakes", 500.0)
	var ids := _bichos(criaturas, estado, [560, 580, 600, 620, 640])
	var fila := ContactQueue.new(_curva())

	fila.assign(muro, criaturas, ids)
	var primeira := criaturas.target_xs.duplicate()
	fila.assign(muro, criaturas, ids)

	assert_array(criaturas.target_xs).is_equal(primeira)


func test_a_fila_vive_entre_o_minimo_e_o_maximo_da_curva() -> void:
	var estado := GameState.new()
	var criaturas := CreatureSystem.new()
	var obras := BuildSystem.new()
	var muro := _muro(obras, &"stakes", 500.0)
	var ids := _bichos(criaturas, estado, [560, 580, 600, 620, 640, 660, 680, 700, 720])
	var fila := ContactQueue.new(_curva())
	var curva := _curva()
	var face := muro.width * MEIO

	fila.assign(muro, criaturas, ids)

	for quem in ids:
		var c := criaturas.index_of(quem)
		var d := absf(criaturas.target_xs[c] - muro.x) - face
		if fila.holds(muro, quem):
			assert_float(d).is_equal_approx(0.0, 0.001)
			continue
		assert_float(d).is_between(curva.queue_min_px, curva.queue_max_px)


func test_um_muro_em_ruina_nao_engaja_ninguem() -> void:
	var estado := GameState.new()
	var criaturas := CreatureSystem.new()
	var obras := BuildSystem.new()
	var muro := _muro(obras, &"stakes", 500.0)
	var ids := _bichos(criaturas, estado, [560, 580])
	var fila := ContactQueue.new(_curva())
	fila.assign(muro, criaturas, ids)

	obras.damage(muro.id, muro.max_health())
	var eventos := fila.assign(muro, criaturas, ids)

	assert_int(muro.contact.size()).is_equal(0)
	assert_bool(fila.holds(muro, ids[0])).is_false()
	assert_array(eventos).is_not_empty()


func test_o_alcance_da_fila_conta_a_partir_da_face() -> void:
	var obras := BuildSystem.new()
	var muro := _muro(obras, &"stakes", 500.0)
	var fila := ContactQueue.new(_curva())

	assert_float(fila.reach(muro)).is_equal_approx(muro.width * MEIO + _curva().queue_max_px, 0.001)
