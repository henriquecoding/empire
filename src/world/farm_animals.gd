# src/world/farm_animals.gd — as galinhas a porta do galinheiro e as vacas do estabulo (§06,
# ADR 0083).
#
# O §06 da ao galinheiro as galinhas ca fora — sao elas que o Alado vem roubar (§07) — e ao
# estabulo de vacas as vacas vivas. Sao cenario que se mexe, como a Fauna: nada do que
# fazem toca na simulacao nem no save, e o que a obra rende continua a ser o BuildSystem.
# Cada bicho passeia a frente da obra dele: anda de uma ponta a outra, come, descansa e
# volta; o galo canta e a galinha bate as asas na outra ponta. Puro no tempo, sem sorteio:
# a fase de cada um sai do x da obra e da ordem dele nela.
class_name FarmAnimals
extends RefCounted

## O passeio vai um pouco alem da largura da obra.
const PASSEIO := 1.2
## Uma passada por ciclo de caminhada, em fraccoes do corpo: e o que deixa as patas no chao.
const PASSADA := 0.35
const REPOUSO_S := 2.5
## Dois bichos da mesma obra andam meia volta desencontrados: um descansa numa ponta
## enquanto o outro descansa na outra.
const DESFASE := 0.5
## A accao propria de quem a tem no passeio (o canto do galo, as asas da galinha).
const PROPRIA := [&"animal_rooster", &"animal_hen"]
const SOMBRA := 0.25
## As tres primeiras partes do passeio vao para a direita; as outras tres voltam.
const IDA := 3


static func draw_on(canvas: CanvasItem, luz: Lighting, tempo: float) -> void:
	if SimLoop.builds == null:
		return
	var vista := PresentationBounds.of(canvas)
	var escala := AnimatedArt.FARM_SCALE
	for vaga in SimLoop.builds.standing():
		var bichos: Array = AnimatedArt.FARM.get(vaga.kind, [])
		if bichos.is_empty() or not PresentationBounds.sees(vista, vaga.x, vaga.width * PASSEIO):
			continue
		for k in bichos.size():
			var perfil: StringName = bichos[k]
			if not AnimatedArt.has(perfil):
				continue
			var fase := tempo + float(k) * DESFASE * cycle_seconds(perfil, vaga.width) + vaga.x
			var passo := stroll(perfil, vaga.x, vaga.width, fase)
			var meia := AnimatedArt.body(perfil).size.x * float(escala) * SOMBRA
			Shadow.drop(canvas, passo.x, int(Band.Kind.SURFACE), meia, 0.0, 0.0)
			var pose := AnimatedArt.posed(Vector2(passo.x, Band.GROUND_LINE), passo.y, escala)
			AnimatedArt.lit(canvas, perfil, int(passo.z), pose, luz, passo.x)


## Onde esta o bicho, para que lado olha e que quadro mostra, ao fim de `t` segundos do
## passeio a frente de uma obra em `centro` com `largura` px: (x, frente, quadro).
static func stroll(perfil: StringName, centro: float, largura: float, t: float) -> Vector3:
	var fases := _phases(perfil, largura)
	var meio := largura * PASSEIO * WorldPalette.MEIA
	var c := fposmod(t, cycle_seconds(perfil, largura))
	for k in fases.size():
		var dura: float = fases[k][1]
		if c < dura or k == fases.size() - 1:
			var ida := k < IDA
			var frente := 1.0 if ida else -1.0
			var parte := clampf(c / dura, 0.0, 1.0) if dura > 0.0 else 1.0
			var x := centro + (meio if ida else -meio)
			if fases[k][0] == &"walk":
				x = centro + lerpf(-meio, meio, parte) * frente
			return Vector3(x, frente, AnimatedArt.frame(perfil, fases[k][0], c))
		c -= dura
	return Vector3(centro, 1.0, 0.0)


## Quanto leva uma volta inteira do passeio, em segundos.
static func cycle_seconds(perfil: StringName, largura: float) -> float:
	var total := 0.0
	for fase: Array in _phases(perfil, largura):
		total += float(fase[1])
	return total


## As seis partes do passeio, [accao, segundos]: ir, comer, descansar, voltar, a accao
## propria (ou comer outra vez), descansar.
static func _phases(perfil: StringName, largura: float) -> Array:
	var passada := AnimatedArt.body(perfil).size.x * float(AnimatedArt.FARM_SCALE) * PASSADA
	var ciclo := AnimatedArt.seconds(perfil, &"walk")
	var anda := largura * PASSEIO / maxf(1.0, passada / maxf(ciclo, 0.01))
	var come := AnimatedArt.seconds(perfil, &"feed")
	var outra := &"special" if perfil in PROPRIA else &"feed"
	return [
		[&"walk", anda],
		[&"feed", come],
		[&"idle", REPOUSO_S],
		[&"walk", anda],
		[outra, AnimatedArt.seconds(perfil, outra)],
		[&"idle", REPOUSO_S],
	]
