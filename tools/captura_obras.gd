# tools/captura_obras.gd — obras postas num ponto do SiteStage para a fotografia.
#
# Fora do jogo, como o tools/captura.gd que o usa. E o "estado preparado
# rotulado" do planejamento de 26/09 (lote 3, §7): a ficha da captura diz que
# obra foi posta em que ponto, e por isso a fotografia nao passa por natural.
extends RefCounted

## Quanto uma obra "a trabalhar" sobe por segundo, em segundos de trabalho, e ate
## onde: sem construtor presente o tick nao mexe nela, e o SiteMarks so ve
## trabalho quando o progresso sobe.
const RITMO := 0.01
const ATE := 0.99
const ESPERA := 0.3
const OBRA := 0.6
const TOCADA := 0.4
const EM_REPARO := 0.6

var _a_trabalhar: Array[BuildSlot] = []


## `--obras "training_house=paying,farm#1=ruin"` poe obras num ponto do SiteStage
## (planejamento 26/09, lote 3 e §7: "estados preparados rotulados"). `#n` e a
## n-esima obra desse tipo, pela ordem do Greybox. Preparado, e a ficha di-lo.
func prepare(pedido: String) -> PackedStringArray:
	var feito := PackedStringArray()
	for par in pedido.split(",", false):
		var partes := par.split("=")
		var alvo := partes[0].split("#")
		var vaga := _obra(StringName(alvo[0]), int(alvo[1]) if alvo.size() > 1 else 0)
		if vaga == null or partes.size() < 2:
			push_error("captura: obra %s nao existe nesta regiao" % par)
			continue
		_preparar(vaga, partes[1])
		feito.append("obra %s em x=%d: %s" % [partes[0], int(vaga.x), partes[1]])
	return feito


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
			vaga.progress = vaga.works[0] * (ESPERA if etapa == "waiting" else OBRA)
		"operating":
			vaga.state = BuildSlot.State.DONE
		"damaged", "mending":
			vaga.state = BuildSlot.State.DAMAGED
			vaga.health = int(vaga.max_health() * (TOCADA if etapa == "damaged" else EM_REPARO))
			vaga.mending = etapa == "mending"
		"ruin":
			vaga.state = BuildSlot.State.RUIN
			vaga.health = 0
			vaga.paid = maxi(1, vaga.repair_cost() / 2)
	if etapa in ["working", "mending"]:
		_a_trabalhar.append(vaga)


## Um frame: as obras "a trabalhar" sobem um pouco.
func advance(delta: float) -> void:
	for vaga in _a_trabalhar:
		vaga.progress = minf(vaga.progress + delta * RITMO, vaga.works[0] * ATE)
