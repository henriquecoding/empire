# src/world/site_stage.gd — em que ponto esta uma obra, para a obra o mostrar.
#
# O lote 3 do planejamento visual de 26/09: vazio, pagamento, espera, trabalho,
# operacao, dano, reparo e ruina distinguiveis pela propria obra, sem depender
# so do texto. O BuildSlot tem seis estados (§55) e mais dois factos que o ecra
# nao mostrava — quanto do degrau ja esta pago e se a obra esta a ser reparada.
# Isto le-os e diz o que desenhar; nao muda nada no slot.
#
# "A operar" e o que a simulacao ja trata como tal: uma obra de pe (DONE ou
# DAMAGED) produz, treina e converte (EconomySystem, TrainingSystem e
# ConversionSystem pedem `standing()`). Uma obra tocada continua a operar — e
# por isso o reparo desenha-se POR CIMA da operacao, e nao em vez dela.
class_name SiteStage
extends RefCounted

enum Stage { AVAILABLE, PAYING, WAITING, WORKING, OPERATING, DAMAGED, MENDING, RUIN }


## O ponto em que a obra esta. `a_trabalhar` e o que o render viu: o progresso
## ou a vida da obra subiram ha pouco (quem la esta a trabalha-la).
static func of(vaga: BuildSlot, a_trabalhar: bool) -> Stage:
	match vaga.state:
		BuildSlot.State.EMPTY:
			return Stage.PAYING if vaga.paid > 0 else Stage.AVAILABLE
		BuildSlot.State.SCAFFOLD, BuildSlot.State.BUILDING:
			return Stage.WORKING if a_trabalhar else Stage.WAITING
		BuildSlot.State.DAMAGED:
			return Stage.MENDING if vaga.mending else Stage.DAMAGED
		BuildSlot.State.RUIN:
			return Stage.RUIN
	return Stage.OPERATING


## Quanto custa o que a proxima moeda paga: o degrau seguinte de uma obra vazia
## ou de pe, a reparacao de uma tocada ou caida, ou NENHUM se nada se paga agora
## (uma obra a meio nao aceita moeda — BuildSystem.absorb).
static func cost_now(vaga: BuildSlot) -> int:
	if vaga.mending:
		return BuildSlot.NENHUM
	match vaga.state:
		BuildSlot.State.EMPTY, BuildSlot.State.DONE:
			return vaga.next_cost()
		BuildSlot.State.DAMAGED, BuildSlot.State.RUIN:
			return vaga.repair_cost()
	return BuildSlot.NENHUM


## Quanto da obra esta erguido, de 0 a 1. Em obra e o progresso do degrau (o de
## uma ruina a levantar-se e o do nivel que tinha); de pe e a vida.
static func built(vaga: BuildSlot) -> float:
	if vaga.state in [BuildSlot.State.SCAFFOLD, BuildSlot.State.BUILDING]:
		var degrau := mini(vaga.level, vaga.works.size()) - 1 if vaga.mending else vaga.level
		if degrau < 0 or degrau >= vaga.works.size() or vaga.works[degrau] <= 0.0:
			return 0.0
		return clampf(vaga.progress / vaga.works[degrau], 0.0, 1.0)
	if vaga.standing():
		return clampf(float(vaga.health) / maxf(1.0, float(vaga.max_health())), 0.0, 1.0)
	return 0.0


## Se a obra esta de pe e a fazer o que faz (produzir, treinar, converter).
static func operating(stage: Stage) -> bool:
	return stage in [Stage.OPERATING, Stage.DAMAGED, Stage.MENDING]
