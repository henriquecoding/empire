# src/sim/systems/light_ward.gd — o que as tuas luzes fazem a quem vem da noite.
#
# O dono (29/09/2026, ADR 0034): a Podridao foge da luz, como a Besta perante a
# lanterna apagada no fim de Over the Garden Wall — mas "dependendo do tipo de
# construcao e do nivel do inimigo, recua; se for muito forte, so abranda".
#
# Cada luz tua de pe na superficie (uma obra com `light_radius`, e o archote do
# rei) guarda um troco de chao com duas coisas: `repel_mass`, a massa da criatura
# mais cara que ela faz recuar, e `rot_slow`, quanto abranda as outras. O nivel de
# uma criatura e a massa dela (§51: e o preco que a Podridao paga por ela).
#
# Puro e estatico. Uma zona e Vector4(inicio, fim, repel_mass, rot_slow).
class_name LightWard
extends RefCounted


## As zonas das tuas luzes de pe, mais a do archote (`extra`, se tiver largura).
static func of(obras: BuildSystem, extra: Vector4 = Vector4.ZERO) -> Array[Vector4]:
	var zonas: Array[Vector4] = []
	for obra in obras.standing():
		if obra.band != Band.Kind.SURFACE:
			continue
		var raio := float(obra.effects.get(&"light_radius", 0.0))
		if raio <= 0.0:
			continue
		var repele := float(obra.effects.get(&"repel_mass", 0.0))
		var abranda := float(obra.effects.get(&"rot_slow", 0.0))
		zonas.append(Vector4(obra.x - raio, obra.x + raio, repele, abranda))
	if extra.y > extra.x:
		zonas.append(extra)
	return zonas


## O que a luz faz a uma criatura desta massa neste x: Vector2(recua, abranda).
## Recua (1) se alguma luz aguenta a massa dela; senao abranda pela maior.
static func at(x: float, massa: int, zonas: Array[Vector4]) -> Vector2:
	var abranda := 0.0
	for z in zonas:
		if x < z.x or x > z.y:
			continue
		if massa <= int(z.z):
			return Vector2(1.0, 0.0)
		abranda = maxf(abranda, z.w)
	return Vector2(0.0, clampf(abranda, 0.0, 1.0))
