# tools/captura.gd — uma fotografia da cena de jogo (GB-01, §67).
#
# Fora do jogo: `tools/` esta no exclude_filter do export e nunca sai daqui.
# Corre com um ecra virtual e grava um PNG, para que se possa ver o greybox — e
# ver que a noite e castanha (ADR 0011) — sem uma maquina com ecra.
#
#   xvfb-run -a godot --path . tools/captura.tscn -- --segundos 40 --saida x.png
#
# Corre como CENA e nao com `-s`: o modo de script nao carrega autoloads, e sem
# eles nao ha SimLoop nenhum para fotografar.
#
# Ao lado do PNG fica a ficha (.json): o que o planejamento de 26/09 (§8) pede
# para que duas imagens se possam comparar — commit, motor, renderer que CORREU,
# resolucao, escala, semente, dia e fase, onde estava o rei, e se o estado foi
# natural ou preparado a mao. Um ecra virtual sem Vulkan cai para OpenGL: o
# renderer escrito no project.godot nao e prova de nada, o da ficha e.
extends Node

const JOGO := "res://scenes/game.tscn"
const SAIDA := "build/empire.png"
const SEGUNDOS := 3.0
const PASSO := 1.0 / 30.0
const ESTICAR := {"canvas_items": 1, "viewport": 2}
const ESCALA := {"fractional": 0, "integer": 1}
const FILTRO := {"nearest": 0, "linear": 1}
const FAIXAS := {"surface": Band.Kind.SURFACE, "underground": Band.Kind.UNDERGROUND}

var _restam: int = 0
var _saida: String = SAIDA
var _preparacao: PackedStringArray = PackedStringArray()
## Obras preparadas "a trabalhar": o progresso sobe um pouco a cada frame, que e
## o que o SiteMarks le como trabalho. Sem construtor presente o tick nao mexe
## nelas, e a fotografia de uma obra em curso mostrava sempre uma obra parada.
var _a_trabalhar: Array[BuildSlot] = []


func _ready() -> void:
	var args := _argumentos()
	_saida = String(args.get("saida", SAIDA))
	_restam = int(float(args.get("segundos", SEGUNDOS)) * Engine.get_frames_per_second())
	if _restam <= 0:
		_restam = int(SEGUNDOS * Engine.physics_ticks_per_second)
	_ecra(args)
	add_child(load(JOGO).instantiate())
	if not OS.get_cmdline_user_args().has(Game.NOVO):
		_preparacao.append("retomado do save")
	# Avancar a simulacao a mao, e nao esperar pelo relogio: fotografar a noite
	# custava 340 segundos de espera por causa das seis fases do §48.
	_avancar(float(args.get("avancar", 0.0)))
	_pousar_o_rei(args)
	_preparar_obras(String(args.get("obras", "")))


## `--obras "training_house=paying,farm#1=ruin"` poe obras num ponto do SiteStage
## (planejamento 26/09, lote 3 e §7: "estados preparados rotulados"). `#n` e a
## n-esima obra desse tipo, pela ordem do Greybox. Preparado, e a ficha di-lo.
func _preparar_obras(pedido: String) -> void:
	for par in pedido.split(",", false):
		var partes := par.split("=")
		var alvo := partes[0].split("#")
		var vaga := _obra(StringName(alvo[0]), int(alvo[1]) if alvo.size() > 1 else 0)
		if vaga == null or partes.size() < 2:
			push_error("captura: obra %s nao existe nesta regiao" % par)
			continue
		_preparar(vaga, partes[1])
		_preparacao.append("obra %s em x=%d: %s" % [partes[0], int(vaga.x), partes[1]])


func _obra(tipo: StringName, n: int) -> BuildSlot:
	for vaga in SimLoop.builds.slots:
		if vaga.kind == tipo:
			if n == 0:
				return vaga
			n -= 1
	return null


func _preparar(vaga: BuildSlot, etapa: String) -> void:
	var de_pe := etapa in ["operating", "damaged", "mending", "ruin"]
	vaga.level = 1 if de_pe else 0
	vaga.state = BuildSlot.State.EMPTY
	vaga.paid = 0
	vaga.progress = 0.0
	vaga.mending = false
	vaga.health = vaga.max_health()
	match etapa:
		"paying":
			vaga.paid = maxi(1, vaga.next_cost() / 2)
		"waiting", "working":
			vaga.state = BuildSlot.State.SCAFFOLD
			vaga.progress = vaga.works[0] * (0.3 if etapa == "waiting" else 0.6)
		"operating":
			vaga.state = BuildSlot.State.DONE
		"damaged", "mending":
			vaga.state = BuildSlot.State.DAMAGED
			vaga.health = int(vaga.max_health() * (0.4 if etapa == "damaged" else 0.6))
			vaga.mending = etapa == "mending"
		"ruin":
			vaga.state = BuildSlot.State.RUIN
			vaga.health = 0
			vaga.paid = maxi(1, vaga.repair_cost() / 2)
	if etapa in ["working", "mending"]:
		_a_trabalhar.append(vaga)


## `--esticar`, `--escala` e `--filtro` trocam o modo de ecra so nesta
## fotografia, para comparar as alternativas da ADR 0001 com a mesma cena.
func _ecra(args: Dictionary) -> void:
	var raiz := get_tree().root
	if ESTICAR.has(args.get("esticar")):
		raiz.content_scale_mode = ESTICAR[args["esticar"]]
	if ESCALA.has(args.get("escala")):
		raiz.content_scale_stretch = ESCALA[args["escala"]]
	if FILTRO.has(args.get("filtro")):
		raiz.canvas_item_default_texture_filter = FILTRO[args["filtro"]]


## `--rei <x>` poe o monarca num sitio antes da fotografia, em px de mundo a
## contar do nucleo; `--faixa underground` poe-no no subsolo. Existe porque
## metade do que ha para ver so aparece com ele ao pe da coisa — o preco de uma
## obra (PriceTag) e o alcance de uma passagem. E um estado PREPARADO, e a ficha
## di-lo: ninguem andou ate la.
func _pousar_o_rei(args: Dictionary) -> void:
	if not args.has("rei") or SimLoop.state == null:
		return
	var i := SimLoop.units.index_of(SimLoop.king_id)
	if i == UnitSystem.NENHUM:
		return
	var x := clampf(SimLoop.core_x + float(args["rei"]), 0.0, SimLoop.world_width)
	SimLoop.units.xs[i] = x
	_preparacao.append("rei posto em x=%d" % int(x))
	if FAIXAS.has(args.get("faixa")):
		SimLoop.units.bands[i] = FAIXAS[args["faixa"]]
		_preparacao.append("rei posto na faixa %s" % args["faixa"])
	SimLoop.units.clear_target(SimLoop.king_id)
	# A camara segue com atraso e antecipa na direccao do salto; uma fotografia
	# de um sitio tem de estar ENQUADRADA nele, e por isso assenta ja.
	Smoothing.reset()
	var jogo := get_child(0)
	var monarca := jogo.get_node(^"Monarca") as Node2D
	monarca.position = Vector2(x, WorldPalette.ground_of(int(SimLoop.units.bands[i])))
	(jogo.get_node(^"CameraRig") as CameraRig).follow(monarca)


func _process(delta: float) -> void:
	for vaga in _a_trabalhar:
		vaga.progress = minf(vaga.progress + delta * 0.01, vaga.works[0] * 0.99)
	_restam -= 1
	if _restam > 0:
		return
	set_process(false)
	await RenderingServer.frame_post_draw
	var imagem := get_viewport().get_texture().get_image()
	print("captura: %s (erro %d)" % [_saida, imagem.save_png(_saida)])
	_ficha(imagem)
	get_tree().quit()


## A ficha da fotografia, ao lado dela. O `check_silhueta.py` do §80 precisa de
## duas coisas que um PNG nao sabe dizer: em que fase do dia foi tirada, e ONDE
## estava a mancha — porque a regra das duas excepcoes diz "violeta e A Podridao
## e so A Podridao", e um teste que nao saiba onde ela esta ou chumba a mancha
## ou nao chumba nada. O resto e a proveniencia (planejamento 26/09, §8).
func _ficha(imagem: Image) -> void:
	var relogio := ClockService.clock
	var ecra := get_viewport().get_visible_rect().size
	var ficha := {
		"largura": ecra.x,
		"altura": ecra.y,
		"dia": SimLoop.state.day if SimLoop.state != null else 0,
		"fase": int(relogio.current_phase()),
		"progresso_fase": snappedf(relogio.phase_progress(), 0.001),
		"mancha": _mancha(),
		"instrumentos": _instrumentos(),
		"semente": RngService.world_seed(),
		"rei": _rei(),
		"camara_x": _camara_x(),
		"estado": "preparado" if not _preparacao.is_empty() else "natural",
		"preparacao": _preparacao,
		"imagem": [imagem.get_width(), imagem.get_height()],
	}
	ficha.merge(_motor())
	var f := FileAccess.open(_saida.get_basename() + ".json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(ficha, "\t", true))
		f.close()


## Com que motor, que renderer e que ecra — o que CORREU, e nao o declarado.
func _motor() -> Dictionary:
	var raiz := get_tree().root
	var git := []
	OS.execute("git", ["rev-parse", "HEAD"], git)
	var sujo := []
	OS.execute("git", ["status", "--porcelain", "--untracked-files=no"], sujo)
	return {
		"commit": String(git[0]).strip_edges() if not git.is_empty() else "",
		"sujo": not sujo.is_empty() and not String(sujo[0]).strip_edges().is_empty(),
		"motor": Engine.get_version_info().string,
		"renderer": RenderingServer.get_current_rendering_method(),
		"driver": RenderingServer.get_current_rendering_driver_name(),
		"adaptador": RenderingServer.get_video_adapter_name(),
		"janela": [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
		"base":
		[
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height"),
		],
		"esticar": ESTICAR.find_key(raiz.content_scale_mode),
		"escala": ESCALA.find_key(raiz.content_scale_stretch),
		"filtro": FILTRO.find_key(raiz.canvas_item_default_texture_filter),
		"fator": snappedf(raiz.get_final_transform().get_scale().x, 0.001),
		"comando":
		" ".join(OS.get_cmdline_args() + PackedStringArray(["--"]) + OS.get_cmdline_user_args()),
		"tirada": Time.get_datetime_string_from_system(true) + "Z",
	}


func _rei() -> Dictionary:
	var i := SimLoop.units.index_of(SimLoop.king_id) if SimLoop.state != null else -1
	if i == UnitSystem.NENHUM or i < 0:
		return {}
	var faixa := int(SimLoop.units.bands[i])
	return {
		"x": snappedf(SimLoop.units.xs[i], 0.1),
		"do_nucleo": snappedf(SimLoop.units.xs[i] - SimLoop.core_x, 0.1),
		"faixa": String(Band.Kind.find_key(faixa)).to_lower(),
	}


## O x do mundo que esta no meio do ecra. E o que diz "vista oeste, centro ou
## leste" sem ter de confiar em onde se pediu a camara.
func _camara_x() -> float:
	var t := get_viewport().get_canvas_transform()
	return snappedf((t.affine_inverse() * (get_viewport().get_visible_rect().size * 0.5)).x, 0.1)


## Onde a mancha e o rasto dela estao NO ECRA, em rectangulos. A camara so anda
## em x, mas quem converte e a transformacao do canvas: repetir a conta aqui era
## ter dois sitios a decidir onde uma coisa aparece.
func _mancha() -> Array:
	var rot := SimLoop.night.rot if SimLoop.state != null else null
	if rot == null or not rot.active():
		return []
	var t := get_viewport().get_canvas_transform()
	var largura := maxf(rot.state.width, WorldPalette.DEGRAU)
	var meia := largura * WorldPalette.MEIA
	var chao := WorldPalette.ground_of(int(Band.Kind.SURFACE))
	var massa := Rect2(rot.position_x() - meia, float(Band.HORIZON), largura, chao - Band.HORIZON)
	var de := minf(rot.state.trail_from, rot.state.trail_to)
	var ate := maxf(rot.state.trail_from, rot.state.trail_to)
	var rasto := Rect2(de, chao - WorldPalette.RASTO, ate - de, WorldPalette.RASTO)
	return [_no_ecra(t, massa), _no_ecra(t, rasto)]


## Onde estao os INSTRUMENTOS do greybox no ecra (§67, GB-03). Quem mede a
## imagem tem de os saltar: sao texto branco, e uma regra sobre a luz do mundo
## medida por cima de um painel de texto media o painel.
func _instrumentos() -> Array:
	var fora: Array = []
	for camada in get_tree().get_nodes_in_group(&"instrumentos"):
		var control := camada as Control
		if control != null and control.visible:
			var r := control.get_global_rect()
			fora.append([r.position.x, r.position.y, r.size.x, r.size.y])
	return fora


func _no_ecra(t: Transform2D, caixa: Rect2) -> Array:
	var canto := t * caixa.position
	var fim := t * caixa.end
	return [canto.x, canto.y, fim.x - canto.x, fim.y - canto.y]


## Corre `segundos` de simulacao ao passo fixo, sem render. E o mesmo step() que
## os testes usam, e por isso a fotografia mostra um estado que a suite tambem
## consegue reproduzir.
##
## Para quando a partida para. O step() e publico e nao olha ao _running — quem
## o chama a mao tem de olhar, senao continua a andar com um jogo ja acabado e a
## fotografia mostra um mundo que nunca existiu.
func _avancar(segundos: float) -> void:
	for _i in int(segundos / PASSO):
		if not SimLoop.running():
			return
		SimLoop.step(PASSO)


func _argumentos() -> Dictionary:
	var saida := {}
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size() - 1:
		# Um `--novo` e so bandeira: nao pode engolir o `--saida` que vem a seguir.
		if args[i].begins_with("--") and not args[i + 1].begins_with("--"):
			saida[args[i].substr(2)] = args[i + 1]
			i += 1
		i += 1
	return saida
