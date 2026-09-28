# src/sim/systems/fire_zones.gd — onde a Podridao abranda por causa do fogo (§05).
#
# "Fogueiras, barris de fogo e terreno consagrado abrandam-na" (§05). O terreno
# consagrado sao os Marcos (§74, `consecrated_slowdown`); isto e o resto: cada
# obra de pe com `rot_slow` no effect_params abranda-a nesse tanto enquanto ela
# estiver por cima — o barril de fogo do §10 e a fogueira da Q-029, que tem o
# abrandamento do barril. O raio e o `radius` da obra, ou meia largura.
#
# Puro e estatico.
class_name FireZones
extends RefCounted

const METADE := 0.5


## As zonas de fogo de pe: (inicio, fim, fraccao que tiram a velocidade).
static func of(obras: BuildSystem) -> Array[Vector3]:
	var zonas: Array[Vector3] = []
	for obra in obras.standing():
		var abranda := float(obra.effects.get(&"rot_slow", 0.0))
		if abranda <= 0.0:
			continue
		var raio := float(obra.effects.get(&"radius", obra.width * METADE))
		zonas.append(Vector3(obra.x - raio, obra.x + raio, abranda))
	return zonas


## Quanto tirar a velocidade da mancha neste x: a maior das zonas por baixo dela.
static func slow(x: float, zonas: Array[Vector3]) -> float:
	var maior := 0.0
	for z in zonas:
		if x >= z.x and x <= z.y:
			maior = maxf(maior, z.z)
	return clampf(maior, 0.0, 1.0)
