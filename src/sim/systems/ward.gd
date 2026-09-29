# src/sim/systems/ward.gd — o Sino de Vigia, que afasta o Zelador (§75; Q-100).
#
# O §75 diz que o Zelador "pode ser afastado, nao morto", e nao diz com que. O dono
# (29/09/2026): "pode ser um tipo de construcao que emita algo que impeca que ele
# avance, e esse recurso vai diminuindo conforme o poder da podridao se torna mais
# forte ao decorrer dos dias; o jogador deve gerir formas para preservar isso e
# manter ativo, ou tentar reativar se aquilo for desativado ou destruido."
#
# O sino tem carga. Com carga, o Zelador nao entra no raio dele pelo lado de fora
# — e se ja la estiver, e empurrado para fora. Cada alvorada a carga desce, e desce
# mais quanto mais forte a noite (`ward_decay_base` + `ward_decay_per_day` x dia).
# Carrega-se com moedas largadas nele (Verbo 1), ate ao teto; destruido, repara-se
# como qualquer obra (Q-108). Acabado de levantar, nasce cheio.
#
# Puro e estatico: os numeros sao o effect_params do sino (buildings.csv).
class_name Ward
extends RefCounted

const SINO := &"tender_ward"


## Se esta obra e um sino de pe que ainda aceita moedas.
static func wants(vaga: BuildSlot) -> bool:
	return vaga.kind == SINO and vaga.standing() and vaga.charge < cap(vaga)


static func cap(vaga: BuildSlot) -> float:
	return float(vaga.effects.get(&"ward_charge_max", 0.0))


## Se o sino esta a guardar: de pe e com carga.
static func active(vaga: BuildSlot) -> bool:
	return vaga.kind == SINO and vaga.standing() and vaga.charge > 0.0


## As moedas `apanhadas` (ja em cima do sino) carregam-no. Devolve quantas levou.
static func absorb(moedas: CoinSystem, vaga: BuildSlot, apanhadas: PackedInt32Array) -> int:
	var levou := 0
	var por_moeda := float(vaga.effects.get(&"ward_per_coin", 0.0))
	for coin_id in apanhadas:
		if vaga.charge >= cap(vaga) or por_moeda <= 0.0:
			break
		levou += moedas.amounts[moedas.index_of(coin_id)]
		vaga.charge = minf(
			cap(vaga), vaga.charge + por_moeda * moedas.amounts[moedas.index_of(coin_id)]
		)
		moedas.remove(coin_id)
	return levou


## A alvorada do dia `dia`: cada sino perde carga, mais quanto mais tarde.
static func dawn(obras: BuildSystem, dia: int) -> void:
	for vaga in obras.slots:
		if vaga.kind != SINO:
			continue
		var perde := float(vaga.effects.get(&"ward_decay_base", 0.0))
		perde += float(vaga.effects.get(&"ward_decay_per_day", 0.0)) * dia
		vaga.charge = maxf(0.0, vaga.charge - perde)


## Onde o Zelador pode estar, vindo de `x` para `alvo`: nunca dentro do raio de
## um sino activo do lado dele. Se ja la estiver, sai pelo lado de fora.
static func hold(obras: BuildSystem, x: float, alvo: float, nucleo: float) -> float:
	var lado := signf(x - nucleo)
	for vaga in obras.slots:
		if not active(vaga) or signf(vaga.x - nucleo) != lado:
			continue
		var limite := vaga.x + lado * float(vaga.effects.get(&"ward_radius", 0.0))
		if absf(alvo - nucleo) < absf(limite - nucleo):
			alvo = limite
	return alvo
