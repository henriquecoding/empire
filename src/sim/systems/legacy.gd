# src/sim/systems/legacy.gd — o que fica quando se perde (§16; Q-088, Q-134).
#
# O §16: "Decay em vez de reset. Segue o Two Crowns, nao o Kingdom original. Ao
# cair, o jogador mantem: Sementes Reais, classes desbloqueadas, mapas revelados,
# segredos encontrados, e 40% das estruturas do imperio principal." Ate aqui o
# botao da derrota recomecava do zero (Q-088).
#
# O legado e um dicionario em tipos base — vai para um ficheiro e volta — com o
# que o jogo novo herda: as Sementes, os segredos achados, as conquistas, o plano
# da campanha, a fase da classe do rei, e as obras que ficam. Ficam as mais caras:
# a fraccao `decay_structures_kept` das obras de pe (arredondada), por moedas
# investidas e, no empate, por id. Levantam-se no mesmo sitio, no mesmo degrau,
# caminho e variante — o segmento e o mesmo, e os ids dos sitios tambem (§21, §45).
# A variante e a classe faltavam: uma torre B voltava A, e a evolucao paga com a
# Semente sumia com a Semente gasta (auditoria de 27/09, N1 e N2; Q-133, Q-136).
#
# Puro: recebe o estado e as obras.
class_name Legacy
extends RefCounted

const SEMENTES := &"royal_seeds"
const ACHADOS := &"found"
const CONQUISTAS := &"conquests"
const PLANO := &"chapters"
const OBRAS := &"slots"
const ID := &"id"
const NIVEL := &"level"
const CAMINHO := &"path"
const VARIANTE := &"variant"
## A fase da classe do rei. Atravessa com a campanha; num jogo novo — a derrota,
## ou a campanha seguinte — a classe continua desbloqueada, mas a evolucao volta
## a ganhar-se a jogar (Q-140, o dono a 29/09/2026).
const CLASSE := &"class_phase"
## A travessia (P-K, Q-135): a regiao seguinte, quem vai com o rei e o saco dele.
const REGIAO := &"region"
const COMITIVA := &"party"
const SACO := &"purse"


## O que o jogo novo herda desta partida.
static func of(estado: GameState, obras: BuildSystem, fracao: float) -> Dictionary:
	var ficam := []
	for obra in kept(obras, fracao):
		ficam.append(
			{ID: obra.id, NIVEL: obra.level, CAMINHO: int(obra.path), VARIANTE: obra.variant}
		)
	return {
		SEMENTES: estado.royal_seeds,
		ACHADOS: estado.found,
		CONQUISTAS: estado.conquests,
		PLANO: estado.chapters.to_dict(),
		REGIAO: estado.region,  # o decay recomeca a regiao onde se perdeu (§16)
		OBRAS: ficam,
	}


## O que atravessa com o rei (P-K, Q-135): nenhuma obra — a regiao seguinte e
## outra —, mas quem e teu e esta perto dele (`alcance`) ou espera sem posto no
## nucleo (Q-063), o saco, e a regiao a seguir. Depois da ultima, a campanha
## acabou: o plano sorteia-se de novo.
static func crossing(
	estado: GameState,
	unidades: UnitSystem,
	dados: Dictionary,
	rei: int,
	alcance: float,
	classes: ClassSystem = null
) -> Dictionary:
	var d := of(estado, BuildSystem.new(), 0.0)
	d[CLASSE] = classes.phase if classes != null else ClassSystem.PRIMEIRA
	var r := unidades.index_of(rei)
	var comitiva := PackedStringArray()
	for i in unidades.count():
		var perfil: UnitData = dados.get(unidades.data_ids[i])
		if i == r or perfil == null or perfil.tags.has(&"follows_king") or not unidades.alive(i):
			continue
		if unidades.owners[i] != unidades.owners[r]:
			continue
		if unidades.bands[i] != unidades.bands[r]:
			continue  # so na faixa do rei (N2)
		# Quem esta perto vai; e quem espera no nucleo sem posto embarca com ele,
		# como a tripulacao do barco do Kingdom: New Lands — ja nao anda atras
		# dele (Q-063). Quem tem posto fica, e e o decay da regiao (§16).
		var perto := absf(unidades.xs[i] - unidades.xs[r]) <= alcance
		if perto or unidades.job_ids[i] == UnitSystem.NENHUM:
			comitiva.append(String(unidades.data_ids[i]))
	d[COMITIVA] = comitiva
	d[SACO] = unidades.carried_coins[r]
	d[REGIAO] = estado.region + 1
	if estado.region + 1 >= estado.chapters.regions.size():
		end_campaign(d)
	return d


## A campanha acabou (a ultima regiao, ou o Lume apagado, Q-156): o jogo novo
## comeca outra, com o plano sorteado de novo e a classe sem a evolucao (Q-140).
static func end_campaign(d: Dictionary) -> void:
	d[REGIAO] = 0
	d.erase(PLANO)
	d.erase(CLASSE)


## As obras que ficam, das mais caras para as mais baratas.
static func kept(obras: BuildSystem, fracao: float) -> Array[BuildSlot]:
	var de_pe: Array[BuildSlot] = []
	for obra in obras.standing():
		if obra.kind != BuildSlot.NUCLEO and obra.kind != AmargueiroSystem.CORTE and obra.level > 0:
			de_pe.append(obra)
	de_pe.sort_custom(
		func(a: BuildSlot, b: BuildSlot) -> bool:
			var ca := invested(a)
			var cb := invested(b)
			return ca > cb or (ca == cb and a.id < b.id)
	)
	return de_pe.slice(0, roundi(de_pe.size() * clampf(fracao, 0.0, 1.0)))


## As moedas que custaram os degraus que a obra ja tem.
static func invested(obra: BuildSlot) -> int:
	var total := 0
	for k in mini(obra.level, obra.costs.size()):
		total += obra.costs[k]
	return total


## Um jogo novo, ja montado, recebe o legado: o estado, a classe e as obras que
## ficam, de pe e inteiras. Um sitio que o mundo novo nao tem ignora-se, e um
## legado sem variante ou sem classe (de antes do CONT-02) fica com as de raiz (§62).
static func apply(
	d: Dictionary, estado: GameState, obras: BuildSystem, classes: ClassSystem = null
) -> void:
	if classes != null:
		classes.phase = maxi(classes.phase, int(d.get(CLASSE, ClassSystem.PRIMEIRA)))
	estado.royal_seeds = int(d.get(SEMENTES, estado.royal_seeds))
	estado.found = PackedStringArray(d.get(ACHADOS, estado.found))
	estado.conquests = PackedStringArray(d.get(CONQUISTAS, estado.conquests))
	var plano: Dictionary = d.get(PLANO, {})
	if not plano.is_empty():
		estado.chapters.from_dict(plano)
	estado.region = int(d.get(REGIAO, estado.region))
	for guardada: Dictionary in d.get(OBRAS, []):
		var i := obras.index_of(int(guardada.get(ID, BuildSlot.NENHUM)))
		if i == BuildSlot.NENHUM:
			continue
		var obra := obras.slots[i]
		obra.path = int(guardada.get(CAMINHO, int(obra.path))) as BuildSlot.Path
		obra.level = mini(int(guardada.get(NIVEL, 1)), obra.costs.size())
		obra.variant = int(guardada.get(VARIANTE, obra.variant))
		obra.state = BuildSlot.State.DONE
		obra.progress = 0.0
		obra.paid = 0
		obra.health = obra.max_health()


## A comitiva e o saco da travessia chegam com o rei ao nucleo da regiao nova.
static func arrive(
	d: Dictionary, estado: GameState, unidades: UnitSystem, dados: Dictionary, rei: int, x: float
) -> Array[int]:
	var chegaram: Array[int] = []
	var r := unidades.index_of(rei)
	if r == UnitSystem.NENHUM:
		return chegaram
	unidades.carried_coins[r] += int(d.get(SACO, 0))
	for id in PackedStringArray(d.get(COMITIVA, PackedStringArray())):
		var perfil: UnitData = dados.get(StringName(id))
		if perfil != null:
			chegaram.append(unidades.spawn(estado, perfil, unidades.owners[r], x))
	return chegaram
