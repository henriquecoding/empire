# src/sim/systems/walls.gd — onde acaba o "dentro das muralhas" (§74, §75).
#
# Duas regras leem a mesma fronteira: onde um morto cria raiz (§74) e a que
# distancia a mancha fala (§75). Uma so conta, num sitio so.
class_name Walls
extends RefCounted


## Do bordo de fora do muro de pe mais afastado de um lado do nucleo ao do
## outro. Um lado sem muro de pe nao tem dentro, e quem cai em cima do muro caiu
## dentro (Q-086).
static func inside(obras: BuildSystem, core_x: float) -> Vector2:
	var dentro := Vector2(core_x, core_x)
	for vaga in obras.standing():
		if not vaga.blocks or not vaga.two_paths() or vaga.band != Band.Kind.SURFACE:
			continue
		dentro.x = minf(dentro.x, vaga.x - vaga.width * BuildSystem.METADE)
		dentro.y = maxf(dentro.y, vaga.x + vaga.width * BuildSystem.METADE)
	return dentro
