# src/ui/game_hud.gd — o painel de quem joga (§24).
#
# Nao e o Inspector: aquele mostra o estado de cada sistema, a pedido, e serve
# para depurar (Q-067). Isto e o contrario — quatro coisas, sempre no mesmo
# sitio, para quem esta a jogar e nao quer ler nada: que horas sao, o que se
# tem, o que falta fazer, e o que acabou de acontecer.
#
# Nao decide nada e nao toca no estado: le o SimLoop e ouve os sinais do §46. Os
# avisos sao todos sinais do catalogo — um HUD que inventasse um evento seu era
# um sitio onde a regra 7 do AGENTS.md deixava de valer.
class_name GameHud
extends Control

## As seis fases do §05, pela ordem do relogio.
const FASES := ["ALVORADA", "MANHÃ", "MEIO-DIA", "TARDE", "CREPÚSCULO", "NOITE"]

const INK := Color(0.08, 0.07, 0.06)
const PAPER := Color(0.12, 0.10, 0.10, 0.88)
const PAPER_LIGHT := Color(0.20, 0.16, 0.13, 0.94)
const GOLD := Color(0.95, 0.67, 0.27)
const MINT := Color(0.53, 0.79, 0.57)
const TEXT := Color(0.96, 0.92, 0.81)
const MUTED := Color(0.73, 0.67, 0.56)
const JADE := Color(0.33, 0.53, 0.45)
const RODAPE_LINHA := Color(0.32, 0.26, 0.20)
const VEU_COR := Color(0.02, 0.02, 0.03, 0.62)

## O ecra de base (§67). A composicao e fixa: o greybox joga-se a 1280x720, e um
## painel que se reorganiza sozinho e uma decisao de arte que ainda nao existe.
const ECRA := {"largura": 1280.0, "altura": 720.0}

## Cada rotulo: canto, tamanho da caixa e corpo da letra.
const TITULO := {"x": 36.0, "y": 27.0, "w": 230.0, "h": 32.0, "letra": 24}
const RELOGIO := {"x": 378.0, "y": 27.0, "w": 510.0, "h": 28.0, "letra": 19}
const RECURSOS := {"x": 378.0, "y": 54.0, "w": 510.0, "h": 24.0, "letra": 14}
const OBJECTIVO := {"x": 944.0, "y": 28.0, "w": 290.0, "h": 44.0, "letra": 14}
const DICA := {"x": 40.0, "y": 0.0, "acima": 44.0, "w": 1120.0, "h": 26.0, "letra": 13}
const AVISO := {"x": 400.0, "y": 112.0, "w": 480.0, "h": 30.0, "letra": 16}
const VEU := {"x": 400.0, "y": 280.0, "w": 480.0, "h": 120.0, "letra": 28}

## Os tres paineis do topo, a barra da fase e o rodape das teclas.
const PAINEL_ESQ := {"x": 20.0, "y": 16.0, "w": 292.0, "h": 72.0}
const PAINEL_MEIO := {"x": 348.0, "y": 16.0, "w": 570.0, "h": 72.0}
const PAINEL_DIR := {"recuo": 332.0, "y": 16.0, "w": 312.0, "h": 72.0}
const BARRA := {"x": 360.0, "y": 83.0, "w": 546.0, "h": 3.0}
const RODAPE := {"x": 20.0, "acima": 48.0, "margem": 40.0, "h": 30.0}
const AVISO_CAIXA := {"x": 390.0, "y": 108.0, "w": 500.0, "h": 38.0}
const VEU_CAIXA := {"x": 350.0, "y": 252.0, "w": 580.0, "h": 190.0}

const TRACO := {"painel": 2.0, "rodape": 1.0, "contorno": 3}

## As duas faixas que este painel ocupa: a de cima acaba onde o painel acaba, e
## a de baixo e o rodape das teclas.
const FAIXA_TOPO := 88.0

## Quanto tempo um aviso fica no ecra, e a percentagem em que tudo se le.
const AVISO_S := 2.0
const CEM := 100.0
const SEM_NUCLEO := -1.0

var _titulo: Label
var _relogio: Label
var _recursos: Label
var _objectivo: Label
var _dica: Label
var _aviso: Label
var _veu: Label
var _topo: Control
var _rodape: Control
var _moldura_aviso: Control
var _aviso_ate := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_titulo = _label("EMPIRE", TITULO, GOLD)
	_relogio = _label("", RELOGIO, TEXT)
	_recursos = _label("", RECURSOS, MUTED)
	_objectivo = _label("", OBJECTIVO, MINT)
	_dica = _label("", DICA, MUTED)
	_aviso = _label("", AVISO, GOLD)
	_veu = _label("", VEU, TEXT)
	_topo = _faixa()
	_rodape = _faixa()
	_moldura_aviso = _faixa()
	_moldura_aviso.position = _caixa(AVISO_CAIXA).position
	_moldura_aviso.size = _caixa(AVISO_CAIXA).size
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_veu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dica.text = (
		"A/D mover · ESPAÇO largar (manter: em contínuo)"
		+ " · E passagem · direito alvo · TAB estado · ESC pausa"
	)
	_veu.visible = false
	EventBus.coin_collected.connect(_no_apanhar)
	EventBus.build_completed.connect(_na_obra)
	EventBus.target_marked.connect(_no_alvo)
	EventBus.passage_used.connect(_na_passagem)
	EventBus.wall_breached.connect(_no_rompimento)
	EventBus.game_paused.connect(_na_pausa)


func _process(delta: float) -> void:
	if SimLoop.state == null or ClockService.clock == null:
		return
	_atualizar()
	_aviso_ate = maxf(0.0, _aviso_ate - delta)
	_aviso.visible = _aviso_ate > 0.0
	_moldura_aviso.visible = _aviso.visible
	_veu.visible = not SimLoop.running()
	if _veu.visible:
		_veu.text = "JOGO EM PAUSA\n\nESC para continuar"
	queue_redraw()


func _draw() -> void:
	var largura := maxf(size.x, ECRA.largura)
	var altura := maxf(size.y, ECRA.altura)
	_painel(_caixa(PAINEL_ESQ), PAPER_LIGHT, GOLD)
	_painel(_caixa(PAINEL_MEIO), PAPER, JADE)
	var direito := Rect2(largura - PAINEL_DIR.recuo, PAINEL_DIR.y, PAINEL_DIR.w, PAINEL_DIR.h)
	_painel(direito, PAPER, MINT)
	draw_rect(Rect2(BARRA.x, BARRA.y, BARRA.w, BARRA.h), INK)
	if ClockService.clock != null:
		var feito := BARRA.w * ClockService.clock.phase_progress()
		draw_rect(Rect2(BARRA.x, BARRA.y, feito, BARRA.h), GOLD)
	var rodape := altura - RODAPE.acima
	draw_rect(Rect2(RODAPE.x, rodape, largura - RODAPE.margem, RODAPE.h), PAPER)
	var fim := Vector2(largura - RODAPE.x, rodape)
	draw_line(Vector2(RODAPE.x, rodape), fim, RODAPE_LINHA, TRACO.rodape)
	if _aviso.visible:
		_painel(_caixa(AVISO_CAIXA), PAPER_LIGHT, GOLD)
	if not _veu.visible:
		return
	draw_rect(Rect2(0.0, 0.0, largura, altura), VEU_COR)
	_painel(_caixa(VEU_CAIXA), PAPER_LIGHT, GOLD)


func _atualizar() -> void:
	var relogio := ClockService.clock
	var fase := int(relogio.current_phase())
	var conhecida := fase >= 0 and fase < FASES.size()
	var nome: String = FASES[fase] if conhecida else FASES[FASES.size() - 1]
	var por_cento := int(relogio.phase_progress() * CEM)
	_relogio.text = "DIA %02d · %s · %02d%%" % [SimLoop.state.day, nome, por_cento]
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	var saco := SimLoop.units.carried_coins[rei] if rei >= 0 else 0
	var cabem := SimLoop.units.coin_capacities[rei] if rei >= 0 else 0
	var texto := "SACO %02d/%02d   ·   TROPAS %02d   ·   NÚCLEO %03d%%"
	_recursos.text = texto % [saco, cabem, _meus(), _vida_nucleo()]
	if SimLoop.night.rot.active():
		_objectivo.text = "A PODRIDÃO AVANÇA\nprotege as muralhas"
	else:
		_objectivo.text = "RECOLHE MOEDAS\nprepara a fronteira"
	_dica.position = Vector2(DICA.x, size.y - DICA.acima)
	_topo.size = Vector2(size.x, FAIXA_TOPO)
	_rodape.position = Vector2(0.0, size.y - RODAPE.acima)
	_rodape.size = Vector2(size.x, RODAPE.h)


## A vida do nucleo em percentagem (§10: "se cair, cai a partida"). Sem nucleo
## nenhum de pe a conta nao existe, e o que se mostra e zero.
func _vida_nucleo() -> int:
	var melhor := SEM_NUCLEO
	for vaga in SimLoop.builds.slots:
		if vaga.kind != BuildSlot.NUCLEO:
			continue
		melhor = maxf(melhor, float(vaga.health) / maxf(1.0, float(vaga.max_health())))
	return clampi(int(round(melhor * CEM)), 0, int(CEM))


func _meus() -> int:
	var total := 0
	for i in SimLoop.units.count():
		if SimLoop.units.alive(i) and SimLoop.units.owners[i] != RecruitSystem.SEM_DONO:
			total += 1
	return total


func _label(conteudo: String, caixa: Dictionary, cor: Color) -> Label:
	var label := Label.new()
	label.text = conteudo
	label.position = Vector2(caixa.x, caixa.y)
	label.size = Vector2(caixa.w, caixa.h)
	label.add_theme_font_size_override("font_size", caixa.letra)
	label.add_theme_color_override("font_color", cor)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", TRACO.contorno)
	add_child(label)
	return label


## Uma faixa do ecra que este painel ocupa. Nao se ve nada nela — quem a le e
## quem MEDE a imagem: a regra das duas frias do §80 conta pixeis do MUNDO, e
## medi-la por cima de um painel de texto media o painel (GB-03, tools/captura).
func _faixa() -> Control:
	var faixa := Control.new()
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	faixa.add_to_group(&"instrumentos")
	add_child(faixa)
	return faixa


## Uma tabela de canto e tamanho, em rectangulo.
static func _caixa(medida: Dictionary) -> Rect2:
	return Rect2(medida.x, medida.y, medida.w, medida.h)


func _painel(caixa: Rect2, fundo: Color, risco: Color) -> void:
	draw_rect(caixa, fundo)
	draw_line(caixa.position, caixa.position + Vector2(caixa.size.x, 0.0), risco, TRACO.painel)
	draw_line(caixa.position, caixa.position + Vector2(0.0, caixa.size.y), risco, TRACO.painel)


func _dizer(mensagem: String) -> void:
	_aviso.text = mensagem
	_aviso_ate = AVISO_S
	_aviso.visible = true


func _no_apanhar(_unit_id: int, amount: int) -> void:
	_dizer("+%d moeda" % amount)


func _na_obra(_building_id: int) -> void:
	_dizer("OBRA CONCLUÍDA")


func _no_alvo(_target_id: int, _by_id: int) -> void:
	_dizer("ALVO MARCADO")


func _na_passagem(_unit_id: int, _from_band: int, _to_band: int) -> void:
	_dizer("PASSAGEM USADA")


func _no_rompimento(_wall_id: int) -> void:
	_dizer("MURALHA ROMPIDA")


func _na_pausa(pausado: bool) -> void:
	_dizer("JOGO PAUSADO" if pausado else "JOGO RETOMADO")
