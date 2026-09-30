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
# mao, e o `coin_spent` so diz os sorvedouros que a §46 ja nomeia (recrutar,
# treino, herdeiro, soldo, impulso, conversao). A obra nao tem sinal de moeda: o
# que ela absorveu le-se no fim de cada dia, pelo que as obras ja custaram — os
# degraus levantados e o pago do degrau a meio — e entra como "obras".
#
# A ultima coluna e a gente que a moeda armou (K1 do relatorio Kingdom): quem saiu
# de uma casa de oficio (`unit_promoted`) e os decretos da roda
# (`royal_impulse_used`). E por ela que se ve o piloto passar dos tres arqueiros.
class_name Contabilidade
extends RefCounted

const LINHA := "  %3d | %-40s | %-24s | %-32s | %s"

## dia -> {"largou": {origem: n}, "apanhou": {rei|outros: n}, "gastou": {porque: n},
## "gente": {oficio ou decreto: n}}
static var dias: Dictionary = {}
## dia -> o que as obras tinham custado quando o dia comecou.
static var _obras_no_inicio: Dictionary = {}


static func ligar() -> void:
	dias = {}
	_obras_no_inicio = {}
	EventBus.coin_dropped.connect(_largou)
	EventBus.coin_collected.connect(_apanhou)
	EventBus.coin_spent.connect(_gastou)
	EventBus.unit_promoted.connect(_formou)
	EventBus.royal_impulse_used.connect(_decretou)


static func _dia() -> Dictionary:
	var dia := SimLoop.state.day if SimLoop.state != null else 0
	if not dias.has(dia):
		dias[dia] = {"largou": {}, "apanhou": {}, "gastou": {}, "gente": {}}
		_obras_no_inicio[dia] = _nas_obras()
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


static func _formou(_quem: int, _de: StringName, para: StringName) -> void:
	_somar("gente", String(para), 1)


static func _decretou(impulso: StringName) -> void:
	_somar("gente", String(impulso), 1)


## Uma linha por dia: o que caiu por origem, quem apanhou, os sorvedouros e a gente.
static func imprimir() -> void:
	print("\n  contas — dia | largadas por origem | apanhadas | gastas | gente armada")
	var ordem := dias.keys()
	ordem.sort()
	for k in ordem.size():
		var dia: int = ordem[k]
		var d: Dictionary = dias[dia]
		var fim: int = _obras_no_inicio[ordem[k + 1]] if k + 1 < ordem.size() else _nas_obras()
		# Uma obra que cai perde degraus: isso e perda, nao gasto negativo.
		var obras := maxi(0, fim - int(_obras_no_inicio[dia]))
		if obras > 0:
			d["gastou"]["obras"] = obras
		var colunas := [dia]
		for g in [d["largou"], d["apanhou"], d["gastou"], d["gente"]]:
			colunas.append(_texto(g))
		print(LINHA % colunas)


## As moedas que as obras de pe ja absorveram: os degraus e o pago do seguinte.
static func _nas_obras() -> int:
	var total := 0
	for obra in SimLoop.builds.slots:
		total += Legacy.invested(obra) + obra.paid
	return total


static func _texto(g: Dictionary) -> String:
	if g.is_empty():
		return "-"
	var partes := PackedStringArray()
	var chaves := g.keys()
	chaves.sort()
	for k in chaves:
		partes.append("%s %d" % [k, g[k]])
	return ", ".join(partes)
