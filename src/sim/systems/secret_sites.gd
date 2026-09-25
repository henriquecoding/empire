# src/sim/systems/secret_sites.gd — onde estao os segredos, e quem os acha (§17).
#
# Os sitios sao AUTORADOS, como os de obra (§21): e o segmento que decide onde
# fica a camara atras da passagem. O que muda em jogo — ja foi achado — vive no
# GameState (`found`), e por isso isto nao vai no save: volta a ser montado.
#
# §25, minuto 11:00: "na camara subterranea: Semente Real". Acha-se entrando la
# com o rei — recompensa por curiosidade, nao por combate.
class_name SecretSites
extends RefCounted

const ID := &"id"
const SEMENTES := &"seeds"
const X := &"x"

var ids: Array[StringName] = []
var xs: PackedFloat32Array = PackedFloat32Array()
var bands: PackedByteArray = PackedByteArray()
var widths: PackedFloat32Array = PackedFloat32Array()
var seeds: PackedInt32Array = PackedInt32Array()
## Onde ha um capitulo escondido (§77, §83): a bifurcacao do segmento. E o que a
## oferta "Nada. So quero ver." revela; sem nenhum, ela nao tem o que mostrar.
var chapters: PackedFloat32Array = PackedFloat32Array()


func count() -> int:
	return ids.size()


func clear() -> void:
	ids = []
	xs = PackedFloat32Array()
	bands = PackedByteArray()
	widths = PackedFloat32Array()
	seeds = PackedInt32Array()
	chapters = PackedFloat32Array()


## Um diario num sitio (§79): acha-se como um segredo, e nao da Semente. O id e
## o do diario, e e esse que fica em `found` — e o que o painel le.
func post_journal(diario: StringName, x: float, largura: float) -> void:
	ids.append(diario)
	xs.append(x)
	bands.append(int(Band.Kind.SURFACE))
	widths.append(largura)
	seeds.append(0)


## Poe um segredo no mundo. `largura` e a da camara: e dentro dela que se acha.
func post(dados: SecretData, x: float, largura: float) -> void:
	ids.append(dados.id)
	xs.append(x)
	bands.append(int(dados.band))
	widths.append(largura)
	seeds.append(dados.reward_seeds)


## Todos os ticks. O rei dentro de uma camara por achar acha-a: fica em `found`,
## e a Semente Real entra no imperio. Devolve o que se achou, para anunciar.
func tick(unidades: UnitSystem, king_id: int, estado: GameState) -> Array[Dictionary]:
	var achados: Array[Dictionary] = []
	var rei := unidades.index_of(king_id)
	if rei == UnitSystem.NENHUM or not unidades.alive(rei):
		return achados
	for k in ids.size():
		if String(ids[k]) in estado.found or unidades.bands[rei] != bands[k]:
			continue
		if absf(unidades.xs[rei] - xs[k]) > widths[k] * BuildSystem.METADE:
			continue
		estado.found.append(String(ids[k]))
		estado.royal_seeds += seeds[k]
		achados.append({ID: ids[k], SEMENTES: seeds[k], X: xs[k]})
	return achados
