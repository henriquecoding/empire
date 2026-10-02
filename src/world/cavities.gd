# src/world/cavities.gd — o que se faz no subsolo e na boca dele (§11, §06, §51;
# auditoria P-I).
#
# A auditoria de 26/09 achou a faixa subterranea um corredor com dois segredos:
# as `cavity_slots` do segments.csv nao eram lidas e nada se construia la em
# baixo. Isto e o segmento a autora-las, como o Greybox autora a superficie:
#
#   · uma cavidade de cada lado, atras da passagem, com um poco de minerio. A
#     cavidade E rocha, e por isso o `requires_biome_feature = rock` do poco
#     cumpre-se la em baixo em qualquer bioma (Q-130). So o rei desce — e so ele
#     o levanta, e as moedas dele caem la em baixo, onde so ele as apanha.
#   · uma escora por construir em cada boca de passagem, a superficie: de pe,
#     fecha a passagem para toda a gente (Q-132).
#
# Posicoes, e nao balanceamento: a resposta a "onde" e do segmento (§21). Os
# precos, as vidas e o trabalho vem de buildings.csv.
class_name Cavities
extends RefCounted

const MINA := &"ore_pit"
## Relativas ao nucleo: entre a passagem (+-950) e o muro de fora (+-1300), e
## fora da camara da Semente Real (-1180).
const CAVIDADES_X := [-1060.0, 1060.0]


## Depois das obras da superficie: os ids das que ja existiam nao mudam (§45).
static func author() -> void:
	var segmento := Registry.entry(&"segments", Greybox.SEGMENTO) as SegmentData
	var cabem := mini(CAVIDADES_X.size(), segmento.cavity_slots * Greybox.ECRAS)
	var mina := Registry.entry(&"buildings", MINA) as BuildingData
	for k in cabem:
		var vaga := Greybox.slot_of(mina, SimLoop.core_x + CAVIDADES_X[k])
		vaga.band = Band.Kind.UNDERGROUND
		SimLoop.builds.post(vaga)
	var escora := Registry.entry(&"buildings", Passages.ESCORA) as BuildingData
	for x in SimLoop.passages:
		SimLoop.builds.post(Greybox.slot_of(escora, x))
	var muros := PackedFloat32Array()
	for x in Greybox.MUROS_X:
		muros.append(SimLoop.core_x + x)
	UnderWatch.author_home(SimLoop.passages, muros)  # os poroes e a sala secreta (Q-186)
