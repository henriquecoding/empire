# src/sim/data/rot_profile.gd — A Podridao como dados, nao como codigo (§44).
# Gerado a partir de data/source/rot.csv. Grupo "v5.2": campos acrescentados.
class_name RotProfile
extends Resource

@export var speed_base: float = 14.0  # px/s
@export var speed_per_day: float = 0.9
@export var mass_base: float = 60.0
@export var mass_per_day: float = 26.0
@export var mass_per_fortress: float = 40.0
@export var summon_interval: Vector2 = Vector2(4.0, 7.0)
@export var consecrated_slowdown: float = 0.40  # -40% em terreno consagrado
@export var trail_move_penalty: float = 0.20
@export var two_sided_from_day: int = 12
@export var sacrifice_mass_per_coin: float = 0.5

@export_group("v5.2")
## "Mais por animal ou tropa" (§51) — valores propostos, ver _proposed no CSV.
@export var sacrifice_mass_per_animal: float = 0.0
@export var sacrifice_mass_per_troop: float = 0.0
## Largura inicial da mancha, em px (RotState.width, §51).
@export var width_start: float = 0.0
## Regra de escolha da criatura (§51): &"most_expensive_affordable".
@export var pick_rule: StringName = &"most_expensive_affordable"

@export_group("v6 · a massa escreve-se de dia")
## §74: M = mass_base + mass_per_day*dia + mass_per_fortress*fortalezas
##         + mass_per_amargueiro*arvores + mass_per_named_amargueiro*nomeadas
##         + refusal_mass * min(recusas nas ultimas refusal_window_days, 5)
## A base e o termo do dia descem de proposito: o que a noite tem de duro deixa
## de vir do calendario e passa a vir de como jogaste. O CSV traz 40, 18 e 30.
@export var mass_per_amargueiro: float = 0.0
@export var mass_per_named_amargueiro: float = 0.0
## Uma noite de pe antes de a serra pegar (§74, regra 2; D-03).
@export var amargueiro_nights_standing: int = 0
## Onde o corpo cria raiz. Dentro das muralhas nao cria — e o incentivo a
## arrastar os mortos para dentro (§74).
@export var amargueiro_roots_outside_walls: bool = true
@export var amargueiro_roots_underground: bool = true
## A base do tronco, em px: onde uma moeda cai NELE e onde tem de estar quem o
## corta — a meia largura do §55, como em qualquer obra. Proposta (Q-094).
@export var amargueiro_base_px: float = 0.0

@export_group("v6 · a candeia")
## Raio da luz: base + por_dia*dia, com teto (§74).
@export var lantern_radius_base: float = 0.0
@export var lantern_radius_per_day: float = 0.0
@export var lantern_radius_max: float = 0.0
## O Lume, roxo (ADR 0034): a unica luz do campo que nao e tua, e a unica que
## aquece a Podridao. Sao TRES paragens e nunca um gradiente (§80): nucleo, meio
## e bordo, e depois dissolve para o ambiente com um dither de lantern_dither_px.
@export var lantern_tint: String = ""
@export var lantern_tint_mid: String = ""
@export var lantern_tint_edge: String = ""
## O ambar (§22): o fogo que e TEU — fogueiras, farol, archote. As mesmas tres
## paragens, noutra cor: de longe sabe-se de quem e cada luz.
@export var fire_tint: String = ""
@export var fire_tint_mid: String = ""
@export var fire_tint_edge: String = ""
@export var lantern_dither_px: float = 0.0

@export_group("v6 · a oferta")
## A mancha chega a esta distancia da muralha mais exterior e fala (§75).
@export var offer_trigger_px: float = 0.0
## Janela depois do crepusculo, em segundos: entre x e y (§75).
@export var offer_window_after_dusk: Vector2 = Vector2.ZERO
## A frase fica este tempo no mundo; passado isso, o prato afunda-se (§75).
@export var offer_seconds: float = 0.0
## O prato de oferenda, "do tamanho de um slot de construcao" (§75). Proposta:
## o canteiro (Q-098). So conta o que cai dentro dele.
@export var offer_plate_px: float = 0.0
## Uma por noite, mesmo com duas manchas a partir do dia 12 (§75, D-05).
@export var offers_per_night: int = 1
## Recusar custa refusal_mass por cada recusa das ultimas refusal_window_days,
## ate refusal_cap. Volta a zero assim que aceitares uma vez (§75, D-04).
@export var refusal_mass: float = 0.0
@export var refusal_window_days: int = 0
@export var refusal_cap: float = 0.0

@export_group("v6 · a Divida da Candeia")
## 0 a 20, escondida, nunca desce (§75, D-06). O mostrador e a luz.
@export var debt_max: int = 20
## Limiares em que a luz muda: halo, Zelador, ambiente ambar, segunda chama.
@export var debt_tiers: Array[int] = []
## A partir daqui aparece o Zelador, que nao ataca e leva um nomeado (§75).
@export var tender_from_debt: int = 0
## A partir daqui deixa de haver escuro a noite e as fogueiras perdem o bonus.
@export var ambient_light_from_debt: int = 0
## A partir daqui a candeia tem duas chamas e o epilogo Uniao fecha (§75, §79).
@export var second_flame_from_debt: int = 0

@export_group("v6 · os epilogos")
## A precedencia da §79, avaliada de cima para baixo (D-13).
@export var union_debt_max: int = 0
@export var union_peoples_released: int = 0
@export var dominion_debt_min: int = 0
@export var dominion_peoples_kept: int = 0

@export_group("Auditoria de gameplay — AUD-03")
## O ritmo da noite (Q-126): de `peak_every` em `peak_every` noites, uma funda
## (massa × peak_mass_mult), e a seguinte calma (× calm_mass_mult). Zero desliga.
@export var peak_every: int = 0
@export var peak_mass_mult: float = 0.0
@export var calm_mass_mult: float = 0.0

@export_group("Auditoria de gameplay — AUD-04")
## O poco de minerio "atrai Cavadores" (§06): com um de pe, o Cavador vem este
## numero de noites mais cedo (Q-131).
@export var mine_lure_days: int = 0

@export_group("As primeiras noites — Q-017, Q-068")
## A noite 1 do §25: "tres Rastejantes". A massa que os paga, e nao a do
## calendario da §74 (58, sete). O dono confirmou os tres (Q-068).
@export var opening_mass: float = 0.0
## Ate esta noite a massa do calendario sobe em linha recta da noite 1 ate a §74,
## e dela em diante e a §74 tal e qual: "comeca leve e vai intensificando" (Q-017).
@export var ramp_nights: int = 0

@export_group("A noite saltada — Q-040")
## A fraccao da massa de uma noite saltada que vem na seguinte: "saltar o jogo
## gera consequencias; nada pode ser feito de qualquer jeito" (o dono, Q-040).
@export var skipped_mass_carry: float = 0.0

@export_group("O escuro e o archote — Q-029")
## O archote: quanto custa numa fogueira, quantos se levam, quanto arde.
@export var torch_cost: int = 1
@export var torch_max: int = 0
@export var torch_burn_s: float = 0.0
## A luz dele, a volta do rei.
@export var torch_radius_px: float = 0.0
## No escuro e sem archote: de quanto em quanto nasce alguem, a que distancia,
## quantos no maximo por noite, e o que nasce.
@export var dark_ambush_s: float = 0.0
@export var dark_ambush_px: float = 0.0
@export var dark_ambush_max: int = 0
@export var dark_creature: StringName = &""
## A massa da criatura mais cara que o archote aceso faz recuar (ADR 0034).
@export var torch_repel_mass: int = 0

@export_group("O Lume e as tuas luzes — ADR 0034")
## Quanto tempo recua quem entra numa luz tua que a aguenta.
@export var light_recoil_s: float = 0.0
## O que a noite seguinte ganha por cada unidade do que o Lume comeu (sacrificios,
## galinhas roubadas): "tudo aquilo que a Podridao consome alimenta-a".
@export var lume_mass_per_fuel: float = 0.0


## A parte do calendario da massa (§74: base + dia), com as primeiras noites em
## rampa (Q-017, Q-068). Sem rampa escrita nos dados, e a §74 tal e qual.
func calendar_mass(dia: int) -> float:
	var cheia := mass_base + mass_per_day * dia
	if ramp_nights <= 1 or opening_mass <= 0.0 or dia >= ramp_nights:
		return cheia
	var t := float(maxi(dia, 1) - 1) / float(ramp_nights - 1)
	return opening_mass + (cheia - opening_mass) * t
