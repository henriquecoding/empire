# src/sim/systems/amargueiro_roots.gd — quem se levanta na alvorada, e onde (§74).
#
# As cinco linhas de "Onde o Amargueiro pode nascer, e onde nao", e a regra 3,
# "rende o que a pessoa era". Separadas do AmargueiroSystem porque sao a parte
# da secao que mais se vai discutir — dentro e fora, subsolo, Marco — e uma
# regra discutida quer-se num sitio onde se le sozinha.
#
# Puro, e sem estado: le as colunas das tropas e as obras, e responde.
class_name AmargueiroRoots
extends RefCounted

## §74, regra 3: "Escala 1 e vagabundo: 1 Lenho". O vagabundo tem escala 2 no
## units.csv (a da figura, §22) e rende como a carne mais barata que e.
const VAGABUNDO := &"vagrant"
const CORPO := &"corpse"
const PRIMEIRA_ESCALA := 1

var _perfil: RotProfile
var _tropas: Dictionary
var _escalas: int


func _init(perfil: RotProfile, tropas: Dictionary, escalas: int) -> void:
	_perfil = perfil
	_tropas = tropas
	_escalas = escalas


## Os mortos que sao teus e deixam corpo, por id crescente (§42): a ordem das
## colunas nao e estavel, e as arvores tem de nascer sempre pela mesma ordem.
func dead(unidades: UnitSystem) -> PackedInt32Array:
	var ids := PackedInt32Array()
	for i in unidades.count():
		if unidades.alive(i) or unidades.owners[i] == RecruitSystem.SEM_DONO:
			continue
		var dados: UnitData = _tropas.get(unidades.data_ids[i])
		if dados == null or dados.drops_on_death.has(CORPO):
			ids.append(unidades.ids[i])
	ids.sort()
	return ids


## "Na faixa aerea — nao ha corpos; as voadoras caem" (§74).
static func body_band(faixa: int) -> int:
	return int(Band.Kind.SURFACE) if faixa == int(Band.Kind.AERIAL) else faixa


## A escala do §22, de 1 a quantas o corte tiver. O vagabundo e a excecao.
func tier(data_id: StringName) -> int:
	if data_id == VAGABUNDO:
		return PRIMEIRA_ESCALA
	var dados: UnitData = _tropas.get(data_id)
	var escala := dados.scale_tier if dados != null else PRIMEIRA_ESCALA
	return clampi(escala, PRIMEIRA_ESCALA, _escalas)


## Se um corpo aqui cria raiz. `mundo` leva o x do nucleo e a largura da regiao;
## `consagrado` sao os intervalos dos Marcos, que protegem o raio deles.
##
## Dentro das muralhas e haver, do lado do corpo, um muro de pe cuja face de fora
## esta mais longe do nucleo do que ele — o mesmo muro que trava uma criatura. A
## face e a meia largura do §55: quem morre no posto do muro morreu EM CIMA dele,
## e os postos repartem-se pela largura toda (JobBoard). No subsolo nao ha muro
## que o impeca: cresce para baixo (§74).
func roots(
	x: float, faixa: int, obras: BuildSystem, mundo: Vector2, consagrado: Array[Vector2]
) -> bool:
	for m in consagrado:
		if x >= m.x and x <= m.y:
			return false
	if faixa == int(Band.Kind.UNDERGROUND):
		return _perfil.amargueiro_roots_underground
	return not _dentro(x, obras, mundo.x) and _perfil.amargueiro_roots_outside_walls


func _dentro(x: float, obras: BuildSystem, nucleo: float) -> bool:
	var lado := signf(x - nucleo)
	for vaga in obras.slots:
		if not vaga.blocks or not vaga.holds() or vaga.band != Band.Kind.SURFACE:
			continue
		if signf(vaga.x - nucleo) != lado and lado != 0.0:
			continue
		if absf(vaga.x - nucleo) + vaga.width * BuildSystem.METADE >= absf(x - nucleo):
			return true
	return false
