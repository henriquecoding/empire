# tools/contabilidade.gd — por onde andou cada moeda, dia a dia (CONT-05). Fora do
# jogo: `tools/` esta no exclude_filter do export.
#
# A auditoria de 27/09 (§6.6): "fome economica percebida pode decorrer de dinheiro
# inacessivel ou mal distribuido, mesmo quando existe riqueza total suficiente".
# A vistoria dizia quantas moedas havia no chao; isto diz de onde vieram, quem as
# apanhou e em que se gastaram — pelos sinais da §46, sem ler estado nenhum, e por
# isso sem poder mudar a partida que mede.
#
# Largar nao e gastar: a moeda largada pelo rei numa obra ou num recruta muda de
# mao, e o `coin_spent` so diz os sorvedouros que a §46 ja nomeia (treino,
# herdeiro, soldo, impulso, conversao).
class_name Contabilidade
extends RefCounted

const LINHA := "  %3d | %-40s | %-24s | %s"

## dia -> {"largou": {origem: n}, "apanhou": {rei|outros: n}, "gastou": {porque: n}}
static var dias: Dictionary = {}


static func ligar() -> void:
	dias = {}
	EventBus.coin_dropped.connect(_largou)
	EventBus.coin_collected.connect(_apanhou)
	EventBus.coin_spent.connect(_gastou)


static func _dia() -> Dictionary:
	var dia := SimLoop.state.day if SimLoop.state != null else 0
	if not dias.has(dia):
		dias[dia] = {"largou": {}, "apanhou": {}, "gastou": {}}
	return dias[dia]


static func _somar(grupo: String, chave: String, quanto: int) -> void:
	var g: Dictionary = _dia()[grupo]
	g[chave] = int(g.get(chave, 0)) + quanto


static func _largou(_x: float, _faixa: int, quanto: int, origem: StringName) -> void:
	_somar("largou", String(origem), quanto)


static func _apanhou(unit_id: int, quanto: int) -> void:
	_somar("apanhou", "rei" if unit_id == SimLoop.king_id else "outros", quanto)


static func _gastou(quanto: int, porque: StringName) -> void:
	_somar("gastou", String(porque), quanto)


## Uma linha por dia: o que caiu por origem, quem apanhou, e os sorvedouros.
static func imprimir() -> void:
	print("\n  contas — dia | largadas por origem | apanhadas | gastas")
	var ordem := dias.keys()
	ordem.sort()
	for dia in ordem:
		var d: Dictionary = dias[dia]
		print(LINHA % [dia, _texto(d["largou"]), _texto(d["apanhou"]), _texto(d["gastou"])])


static func _texto(g: Dictionary) -> String:
	if g.is_empty():
		return "-"
	var partes := PackedStringArray()
	var chaves := g.keys()
	chaves.sort()
	for k in chaves:
		partes.append("%s %d" % [k, g[k]])
	return ", ".join(partes)
