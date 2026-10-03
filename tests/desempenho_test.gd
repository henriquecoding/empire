# tests/desempenho_test.gd — o que cada frame deixou de pagar, sem mudar o que se ve.
#
# O dono, a 03/10/2026: "por algum motivo esta muito lento". Medido: cada frame
# desenhava e animava o mundo inteiro (732 bichos de cenario, as obras todas, o chao
# das terras geradas num no so com 220 draw calls), rasterizava cada criatura traco a
# traco, e cada rectangulo de um corpo percorria as luzes todas duas vezes. Aqui
# prova-se que o atalho da a mesma resposta que o caminho comprido, e que a moeda
# largada se ve por cima de quem a largou.
extends GdUnitTestSuite

const PASSO := 1.0 / 30.0
const CHAO := 517.0
const RAIO := 96.0


func _noite(luzes: Array[Glow]) -> Lighting:
	var luz := Lighting.new()
	var dados := Registry.entry(&"economy", &"clock") as ClockData
	luz.set_phase(dados, GameClock.Phase.NIGHT, 0.5)
	luz.set_glows(luzes, CHAO)
	return luz


func _fogo(x: float) -> Glow:
	var cores := WorldLight.fire_stops(SimFactory.rot_profile())
	return Glow.new(Vector2(x, CHAO), int(Band.Kind.SURFACE), RAIO, 0.5, cores, Flicker.Kind.FIRE)


func test_a_moeda_desenha_se_por_cima_de_quem_anda() -> void:
	var faixa: BandView = auto_free(BandView.new())
	faixa.visible = false  # so a arvore conta aqui; desenhar pedia a partida inteira
	faixa.set_process(false)
	add_child(faixa)
	var tropas := faixa.get_children().filter(func(n: Node) -> bool: return n is UnitCanvas)
	var moedas := faixa.get_children().filter(func(n: Node) -> bool: return n is BandView.Moedas)
	assert_int(tropas.size()).is_equal(1)
	assert_int(moedas.size()).is_equal(1)
	assert_int((moedas[0] as Node).get_index()).is_greater((tropas[0] as Node).get_index())
	assert_bool((moedas[0] as CanvasItem).show_behind_parent).is_false()


func test_o_que_esta_fora_do_ecra_nao_se_ve_e_sem_ecra_ve_se_tudo() -> void:
	var vista := Rect2(0.0, 0.0, 1280.0, 720.0)
	assert_bool(PresentationBounds.sees(vista, 640.0)).is_true()
	assert_bool(PresentationBounds.sees(vista, -10.0)).is_false()
	assert_bool(PresentationBounds.sees(vista, -10.0, 20.0)).is_true()  # o pe fora, a obra dentro
	assert_bool(PresentationBounds.sees(vista, 1300.0, 10.0)).is_false()
	var solto: Node2D = auto_free(Node2D.new())
	assert_bool(PresentationBounds.of(solto) == PresentationBounds.TUDO).is_true()
	assert_bool(PresentationBounds.sees(PresentationBounds.TUDO, 1e8)).is_true()


func test_a_luz_de_um_corpo_e_a_mesma_lembrada_ou_nao() -> void:
	var luz := _noite([_fogo(100.0), _fogo(400.0)])
	var cor := Color("c98f22")
	for x: float in [100.0, 100.0, 180.0, 400.0, 100.0, 2000.0]:
		var fresca := _noite([_fogo(100.0), _fogo(400.0)])
		assert_bool(luz.body(cor, x).is_equal_approx(fresca.body(cor, x))).is_true()
	# Cada coisa que a luz tem muda o que se lembrava: as luzes, o ambiente, o escuro.
	var lembrada := luz.body(cor, 100.0)
	luz.set_glows([] as Array[Glow], CHAO)
	assert_bool(luz.body(cor, 100.0).is_equal_approx(lembrada)).is_false()
	luz.set_glows([_fogo(100.0)] as Array[Glow], CHAO)
	lembrada = luz.body(cor, 100.0)
	luz.ambient = Color.WHITE
	var clara := _noite([_fogo(100.0)])
	clara.ambient = Color.WHITE
	assert_bool(luz.body(cor, 100.0).is_equal_approx(clara.body(cor, 100.0))).is_true()
	assert_bool(luz.body(cor, 100.0).is_equal_approx(lembrada)).is_false()
	luz.dark = 0.0
	clara.dark = 0.0
	assert_bool(luz.body(cor, 100.0).is_equal_approx(clara.body(cor, 100.0))).is_true()


func test_o_cenario_so_recebe_as_luzes_que_se_veem() -> void:
	var ecra := Rect2(0.0, 0.0, 1280.0, 720.0)
	var noite := _noite([_fogo(200.0), _fogo(5000.0), _fogo(-RAIO)])
	var u := SceneryLight.uniforms(noite, Transform2D.IDENTITY, ecra)
	assert_int(u[&"luzes"]).is_equal(2)  # a de 5000 esta longe; a da beira ainda alumia
	assert_float((u[&"onde"] as PackedVector4Array)[0].x).is_equal_approx(200.0, 0.001)
	assert_int((u[&"onde"] as PackedVector4Array).size()).is_equal(SceneryLight.MAX_LUZES)
	var dia := Lighting.new()
	var dados := Registry.entry(&"economy", &"clock") as ClockData
	dia.set_phase(dados, GameClock.Phase.NOON, 0.5)
	dia.set_glows([_fogo(200.0)] as Array[Glow], CHAO)
	assert_int(SceneryLight.uniforms(dia, Transform2D.IDENTITY, ecra)[&"luzes"]).is_equal(0)


## O bando por ordem de x e o mesmo bando que todos contra todos (o Flock antigo).
func test_o_bando_por_ordem_de_x_e_o_de_todos_contra_todos() -> void:
	var novo := Flock.new()
	var velho := Flock.new()
	for i in 40:
		var x := float(i % 8) * 14.0 + floorf(i / 8.0) * 300.0
		var onde := Vector2(x, 150.0 + float(i % 5) * 9.0)
		novo.add(onde, Vector2(40.0, 0.0))
		velho.add(onde, Vector2(40.0, 0.0))
	for _i in 120:
		novo.step(PASSO, Vector2(900.0, 120.0))
		_todos_contra_todos(velho, PASSO, Vector2(900.0, 120.0))
	for i in novo.size():
		assert_float(novo.positions[i].distance_to(velho.positions[i])).is_less(0.01)


func test_longe_do_ecra_os_bichos_esperam_e_o_bando_voa() -> void:
	var f := Fauna.new()
	var lista := PackedFloat32Array([Wilds.Animal.BUTTERFLY, 100.0, 0.3])
	lista.append_array([Wilds.Animal.BUTTERFLY, 9000.0, 0.3])
	lista.append_array([Wilds.Animal.BIRD, 9000.0, 0.5])
	f.populate(lista, 3840.0)
	f.vista = Rect2(0.0, 0.0, 1280.0, 720.0)
	var antes := [f.bichos[0].x, f.bichos[1].x, f.bichos[2].x]
	for _i in 30:
		f.tick(PASSO, 0.0, false)
	assert_float(f.bichos[0].x).is_not_equal(antes[0])  # no ecra, anda
	assert_float(f.bichos[1].x).is_equal(antes[1])  # longe, espera
	assert_float(f.bichos[2].x).is_not_equal(antes[2])  # o bando voa sempre


func test_os_talhoes_das_plantas_tem_as_plantas_todas_pela_ordem() -> void:
	var plantas := PackedFloat32Array()
	for i in 50:
		plantas.append_array([i % 4, float(i) * 97.0 - 1500.0, float(i % 3) / 3.0, 0.5])
	var talhoes := FloraArt.chunks(plantas, 1024.0)
	var juntas := PackedFloat32Array()
	var inicios: Array = talhoes.keys()
	inicios.sort()
	for de: float in inicios:
		var dele: PackedFloat32Array = talhoes[de]
		for i in range(0, dele.size(), Wilds.PLANTA):
			assert_float(dele[i + 1]).is_between(de, de + 1024.0)
		juntas.append_array(dele)
	assert_array(juntas).is_equal(plantas)  # x crescente: a ordem de juntar e a de origem


func test_a_terra_em_talhoes_nao_perde_nada() -> void:
	var terra := Lowland.of(null, 3840.0, 1, Wilds.BIOMA_POR_OMISSAO, PackedFloat32Array())
	var partes := LowlandArt.parts(terra, SoilCover.TALHAO)
	var plantas := 0
	var aguas := 0
	var largura := 0.0
	for chave: Vector3 in partes:
		for d: Variant in partes[chave]:
			match int(chave.x):
				LowlandArt.Parte.MATO:
					plantas += (d as PackedFloat32Array).size()
				LowlandArt.Parte.AGUA:
					aguas += 1
				LowlandArt.Parte.CHAO:
					largura += (d[1] as Vector2).y - (d[1] as Vector2).x
	var todas := 0
	for lista: PackedFloat32Array in terra[Lowland.PLANTAS]:
		todas += lista.size()
	assert_int(plantas).is_equal(todas)
	var caminhos: Array = terra[Lowland.CAMINHOS]
	assert_int(aguas).is_equal(caminhos.size() + (terra[Lowland.LAGOS] as Array).size())
	assert_float(largura).is_equal_approx(3840.0, 0.01)


func test_uma_pose_grava_se_sem_cor_e_pinta_se_com_a_do_pen() -> void:
	const S := BeastPen.Stroke
	const T := BeastPen.Tone
	var pen := BeastPen.new(null, Vector2.ZERO, Vector2(2.0, 2.0), 1.0)
	var tracos := [
		[S.RECT, T.BODY, 1, 2, 3, 4],
		[S.POLY, T.DARK, 0, 0, 4, 0, 2, 3],
		[S.GLOW, T.BONE, 5, 5],
	]
	var gravado := pen.record(tracos, Bestiary.signals(Silhouette.Form.BRUTO, 0.0, 0.0, 0.0))
	assert_int(gravado[0]).is_equal(T.BODY)
	assert_bool(gravado[1] == Rect2(1, 2, 3, 4)).is_true()
	assert_int(gravado[2]).is_equal(T.DARK + BeastPen.POLIGONO)
	assert_int(gravado[4]).is_equal(BeastPen.HALO_OLHO)
	assert_int(gravado[6]).is_equal(BeastPen.NUCLEO_OLHO)
	assert_int(gravado[8]).is_equal(BeastPen.BRILHO_OLHO)
	var parados := PackedFloat32Array()
	parados.resize(BeastPen.Sinal.size())
	assert_array(pen.record(tracos, parados)).is_equal(gravado)


## O Flock de antes da ordem de x: todos contra todos. Fica aqui como a referencia.
static func _todos_contra_todos(f: Flock, delta: float, rumo: Vector2) -> void:
	var r := Flock.REGRAS
	var novas := f.velocities.duplicate()
	for i in f.size():
		var p := f.positions[i]
		var afastar := Vector2.ZERO
		var passo := Vector2.ZERO
		var meio := Vector2.ZERO
		var vizinhos := 0
		for j in f.size():
			var d := p.distance_to(f.positions[j])
			if j == i or d > r.vizinho:
				continue
			vizinhos += 1
			passo += f.velocities[j]
			meio += f.positions[j]
			if d < r.perto and d > 0.0:
				afastar += (p - f.positions[j]) / d
		var v := f.velocities[i]
		var querer: Vector2 = (rumo - p).normalized() * r.max * r.rumo
		if vizinhos > 0:
			querer += (passo / vizinhos - v) * r.alinhar + (meio / vizinhos - p) * r.juntar
		v += (querer + afastar * r.max * r.afastar) * delta
		novas[i] = v.limit_length(r.max)
		if novas[i].length() < r.min:
			novas[i] = novas[i].normalized() * r.min
	f.velocities = novas
	for i in f.size():
		f.positions[i] += f.velocities[i] * delta
