# tools/noites.gd — a tabela das noites: quem vem, de onde, e o que custa. Fora do
# jogo: `tools/` esta no exclude_filter do export.
#
# A vistoria diz se a partida anda sem se partir; o night_test mede o cenario
# fechado do §07. Nenhum dos dois diz o que quem joga VE numa noite do jogo
# inteiro: quantas criaturas, de que especie, e por que porta entraram — a mancha,
# o escuro a volta do rei ou o bicho que a Podridao levantou. Foi essa a queixa do
# dono (05/10/2026): «na primeira noite esta aparecendo diversos inimigos e
# inimigos muito fortes». Isto e o instrumento para a medir, e para ver a correccao.
#
#     godot --headless --path . scenes/tests/noites.tscn -- --dias 12 --politica fora
#
# Politicas do rei de noite: `casa` (o piloto da vistoria, na borda do nucleo do lado
# da mancha), `cauteloso` (o mesmo piloto, do outro lado do nucleo), `fora` (a 400 px
# do nucleo, do lado da mancha, como quem defende a estacaria ou explora) e `longe` (a
# 1400 px, nas terras). De dia e sempre o piloto.
extends Node

const PASSO := 1.0 / 30.0
const SEMENTE := 20260916
const FORA_PX := 400.0
const LONGE_PX := 1400.0
## A emboscada do escuro nasce a dark_ambush_px do rei; o resto da tolerancia e
## o passo de movimento de um tick.
const FOLGA_PX := 4.0
## A distancia a que quem joga comeca a bater: o corpo do Rastejante (Q-219).
const GOLPE_PX := 90.0
## Quem bate a mais do que isto luta de longe (o arqueiro tem 200, o lanceiro 28).
const PERTO_PX := 60.0
const LINHA := "  %3d | %-14s | %5s | %-6s | %3d | %-26s | %-9s | %-12s | %4d | %6d | %4d"
const CABECA := (
	"  dia | defesa         | massa | ritmo  | arv | da mancha                  | do escuro "
	+ "| caca / povo  | pico | rei -hp | mortos"
)

var _politica := "casa"
var _por_noite: Dictionary = {}
var _vistos: Dictionary = {}
var _vivas_max := 0
var _meus_ao_crepusculo := 0
var _fase := -1


func _ready() -> void:
	var dias := int(_argumento("dias", "10"))
	_politica = _argumento("politica", "casa")
	Autopilot.cauteloso = _politica == "cauteloso"  # o rei do lado onde ela nao esta
	SimLoop.autosave_enabled = false
	SimLoop.start(int(_argumento("semente", str(SEMENTE))))
	Greybox.build()
	EventBus.unit_damaged.connect(_ferido)
	EventBus.rot_spawned.connect(_nasceu_a_mancha)
	print(
		(
			"\nnoites — %d dias, politica %s, semente %s"
			% [dias, _politica, _argumento("semente", str(SEMENTE))]
		)
	)
	var passos := int(float(dias) * ClockService.clock.day_seconds() / PASSO)
	for _i in passos:
		if Defeat.happened():
			var causa := "o rei caiu" if Defeat.king_fell() else "a sede caiu"
			print("  a partida acabou ao dia %d: %s" % [SimLoop.state.day, causa])
			break
		Autopilot.step(SimLoop)
		_noite_do_rei()
		SimLoop.step(PASSO)
		_contar()
	_imprimir()
	get_tree().quit()


## De noite o rei fica onde a politica manda; de dia, o piloto.
func _noite_do_rei() -> void:
	if _politica in ["casa", "cauteloso"] or not SimLoop.night.rot.active():
		return
	var lado := signf(SimLoop.night.rot.position_x() - SimLoop.core_x)
	var longe := FORA_PX if _politica == "fora" else LONGE_PX
	SimLoop.units.set_target_x(SimLoop.king_id, SimLoop.core_x + lado * longe)
	_golpear()


## Quem joga bate no que lhe chega perto: o gatilho do golpe (ADR 0045), como o
## InputRouter o enfileira. Sem isto o rei ficava parado a levar, e media-se mal.
func _golpear() -> void:
	var r := SimLoop.units.index_of(SimLoop.king_id)
	var bichos := SimLoop.creatures
	for i in bichos.count():
		var d := bichos.xs[i] - SimLoop.units.xs[r]
		if bichos.alive(i) and not bichos.allies.has(bichos.ids[i]) and absf(d) <= GOLPE_PX:
			var gesto := {&"who": SimLoop.king_id, &"direction": signf(d)}
			SimLoop.intents.queue(IntentQueue.Kind.ATTACK, gesto)
			return


func _contar() -> void:
	var agora := int(ClockService.clock.current_phase())
	if agora != _fase:
		if agora == GameClock.Phase.DUSK:
			_meus_ao_crepusculo = _meus()
			_linha()[&"arvores"] = (
				SimLoop.night.amargueiros.anonymous() + SimLoop.night.amargueiros.named()
			)
			_linha()[&"defesa"] = _defesa()
			_vivas_max = 0
		if agora == GameClock.Phase.DAWN and _por_noite.has(SimLoop.state.day - 1):
			var n: Dictionary = _por_noite[SimLoop.state.day - 1]
			n[&"perdas"] = maxi(0, _meus_ao_crepusculo - _meus())
		_fase = agora
	var bichos := SimLoop.creatures
	var vivas := 0
	for i in bichos.count():
		if not bichos.alive(i) or bichos.allies.has(bichos.ids[i]):
			continue
		vivas += 1
		if _vistos.has(bichos.ids[i]):
			continue
		_vistos[bichos.ids[i]] = true
		_nasceu(bichos.data_ids[i], bichos.xs[i])
	_vivas_max = maxi(_vivas_max, vivas)
	if SimLoop.night.rot.active():
		_linha()[&"pico"] = maxi(int(_linha().get(&"pico", 0)), _vivas_max)


## De onde veio: da mancha (nasce no x dela), do escuro (a dark_ambush_px do rei)
## ou de outro sitio — o bicho apanhado que se levanta, um guardiao, um povoado.
func _nasceu(especie: StringName, x: float) -> void:
	var rot := SimLoop.night.rot
	var outra := SimLoop.night.other_rot
	var porta := &"outra"
	if rot.active() and absf(x - rot.position_x()) <= FOLGA_PX:
		porta = &"mancha"
	elif outra.active() and absf(x - outra.position_x()) <= FOLGA_PX:
		porta = &"mancha"
	else:
		var r := SimLoop.units.index_of(SimLoop.king_id)
		var px := SimFactory.rot_profile().dark_ambush_px
		if r != UnitSystem.NENHUM and absf(absf(x - SimLoop.units.xs[r]) - px) <= FOLGA_PX:
			porta = &"escuro"
	if porta == &"outra":
		porta = &"povoado" if _de_um_povoado(x) else &"caca"
	var n := _linha()
	var grupo: Dictionary = n.get(porta, {})
	grupo[especie] = int(grupo.get(especie, 0)) + 1
	n[porta] = grupo


## A noite de um povoado das terras nasce a NIGHT_OFFSET dele (SettlementWatch).
func _de_um_povoado(x: float) -> bool:
	for registo: Dictionary in SimLoop.field.settlements.records.values():
		if absf(absf(x - float(registo[&"x"])) - SettlementWatch.NIGHT_OFFSET) <= FOLGA_PX:
			return true
	return false


func _ferido(unit_id: int, quanto: int, _de: int) -> void:
	if unit_id == SimLoop.king_id and SimLoop.night != null and SimLoop.night.rot.active():
		_linha()[&"rei"] = int(_linha().get(&"rei", 0)) + quanto


## A massa da noite. Com duas manchas a segunda anuncia a metade da primeira (RiftWatch).
func _nasceu_a_mancha(_x: float, _largura: float, massa: float, _lado: int) -> void:
	_linha()[&"massa"] = maxf(float(_linha().get(&"massa", 0.0)), massa)


func _linha() -> Dictionary:
	var dia := SimLoop.state.day
	if int(ClockService.clock.current_phase()) == GameClock.Phase.DAWN:
		dia -= 1
	if not _por_noite.has(dia):
		_por_noite[dia] = {}
	return _por_noite[dia]


## O que defende ao crepusculo: quem luta de longe e de perto (sem o rei), os muros de
## pe e o estagio da sede (ADR 0059).
func _defesa() -> String:
	var longe := 0
	var perto := 0
	var perfis := SimFactory.by_id(&"units")
	for i in SimLoop.units.count():
		var dados: UnitData = perfis.get(SimLoop.units.data_ids[i])
		var meu := SimLoop.units.owners[i] != RecruitSystem.SEM_DONO
		if not meu or not SimLoop.units.alive(i) or dados == null or dados.damage <= 0:
			continue
		if SimLoop.units.ids[i] == SimLoop.king_id:
			continue
		if dados.range_px > PERTO_PX:
			longe += 1
		else:
			perto += 1
	var muros := 0
	for obra in SimLoop.builds.standing():
		muros += 1 if obra.blocks and obra.kind != BuildSlot.NUCLEO else 0
	var sede := RealmLadder.seat(SimLoop.builds)
	return "%da %dl %dm s%d" % [longe, perto, muros, sede.level if sede != null else 0]


func _meus() -> int:
	var n := 0
	for i in SimLoop.units.count():
		if SimLoop.units.owners[i] != RecruitSystem.SEM_DONO and SimLoop.units.alive(i):
			n += 1
	return n


func _imprimir() -> void:
	print(CABECA)
	var dias := _por_noite.keys()
	dias.sort()
	for dia: int in dias:
		var n: Dictionary = _por_noite[dia]
		if not n.has(&"massa"):
			continue
		var ritmo := SimLoop.night.rot.rhythm(dia)
		print(
			(
				LINHA
				% [
					dia,
					String(n.get(&"defesa", "-")),
					str(roundi(float(n[&"massa"]))),
					"x%.1f" % ritmo,
					int(n.get(&"arvores", 0)),
					_texto(n.get(&"mancha", {})),
					_texto(n.get(&"escuro", {})),
					_texto(n.get(&"caca", {})) + " / " + _texto(n.get(&"povoado", {})),
					int(n.get(&"pico", 0)),
					int(n.get(&"rei", 0)),
					int(n.get(&"perdas", 0)),
				]
			)
		)


static func _texto(g: Dictionary) -> String:
	if g.is_empty():
		return "-"
	var partes := PackedStringArray()
	var chaves := g.keys()
	chaves.sort()
	for k in chaves:
		partes.append("%s %d" % [String(k).substr(0, 5), g[k]])
	return " ".join(partes)


func _argumento(nome: String, por_omissao: String) -> String:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--" + nome)
	return args[i + 1] if i >= 0 and i + 1 < args.size() else por_omissao
