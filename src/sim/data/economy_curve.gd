# src/sim/data/economy_curve.gd — §06, §44, §47. Gerado de data/source/economy.csv
# (formato chave/valor). Concentra todos os numeros de balanceamento que o
# dossie escreve em prosa ou dentro de codigo de exemplo (§20, §29, §50).
# Os valores por omissao sao neutros de proposito: os numeros vivem so no CSV (I4),
# e tests/data_test.gd chumba se uma propriedade nao tiver linha em economy.csv.
class_name EconomyCurve
extends Resource

@export_group("Curva e asfixia — §06")
@export var income_growth: float = 0.0
@export var trade_growth: float = 0.0
@export var night_cost_base: float = 0.0
@export var night_cost_growth: float = 0.0
@export var suffocation_target: Vector2i = Vector2i()
@export var curve_income_flat: float = 0.0
@export var curve_income_per_source: float = 0.0

@export_group("Manutencao — §06")
@export var upkeep_free_troops: int = 0
@export var upkeep_tier1_limit: int = 0
@export var upkeep_tier1_rate: float = 0.0
@export var upkeep_tier2_rate: float = 0.0

@export_group("Comercio, caca, saque — §06, §13, §25, §49")
@export var trade_route_income: float = 0.0
@export var trade_network_bonus: float = 0.0
@export var trade_cart_cost: int = 0
@export var hunt_yield: Vector2i = Vector2i()
@export var loot_yield: Vector2i = Vector2i()
@export var start_coins: int = 0
@export var coin_stack_max: int = 0

@export_group("Moeda fisica — §02, §61, F1-01")
## A fisica do arco. O dossie diz que a moeda e fisica e nao diz com que fisica —
## os tres estao em _proposed e a pergunta e a Q-061. O coin_pickup_px ja existia
## acima, no grupo dele.
@export var coin_gravity_px_s2: float = 0.0
@export var coin_drop_speed_px_s: float = 0.0
@export var coin_drop_spread_px_s: float = 0.0
## De quanto em quanto tempo sai uma moeda com a tecla premida. O §24 tem
## "Largar em continuo — Espaco (manter)" no mapa de comando e nao lhe da ritmo:
## a proposta esta ancorada na fatia de decisao do §52. Ver Q-083.
@export var coin_drop_repeat_s: float = 0.0

@export_group("Recrutamento — §25 minuto 0:20, F1-04")
## O §25 descreve o minuto 0:20 em duas frases — "largas uma moeda perto dele" e
## "o vagabundo segue-te" — e nao da um numero a nenhuma das duas. Os tres estao
## em _proposed e a pergunta e a Q-063. Os dois de baixo estao ancorados na fila
## do §50 de proposito: a que distancia uma pessoa espera por outra ja tem
## resposta neste jogo, e ter duas seria ter duas.
@export var recruit_notice_px: float = 0.0
@export var follow_distance_px: float = 0.0
@export var follow_spacing_px: float = 0.0

@export_group("Favor e diplomacia — §06, §14, §56")
@export var favor_decay_per_day: float = 0.0
@export var diplomat_p_dissolve: float = 0.0
@export var diplomat_p_contract: float = 0.0
@export var diplomat_p_capture: float = 0.0
@export var diplomat_favor_step: int = 0
@export var diplomat_favor_shift: float = 0.0
@export var assimilate_every_days: int = 0
@export var assimilate_favor: int = 0

@export_group("Mercenarios e divida — §05, §14, §56")
@export var mercenary_afternoon_markup: float = 0.0
@export var debt_base: int = 0
@export var debt_per_mercenary: int = 0
@export var debt_due_days: int = 0
@export var debt_late_multiplier: float = 1.0
@export var debt_partial_reset_days: int = 0
@export var debt_desert_until_late_day: int = 0
@export var debt_diplomat_dies_late_day: int = 0
@export var debt_camp_marches_late_day: int = 0

@export_group("Coroa, morte e decay — §15, §16")
@export var impulses_per_day: int = 0
@export var heir_training_days: int = 0
@export var heir_training_days_diplomat: int = 0
@export var heir_cost_per_day: int = 0
@export var heir_boost_inheritance: float = 0.0
@export var interregnum_days: int = 0
@export var interregnum_greed: int = 0
@export var decay_structures_kept: float = 0.0
@export var resurrection_seed_cost: int = 0
@export var resurrection_coin_cost: int = 0
@export var resurrection_phase_loss: int = 0

@export_group("Oficios e conquista — §09, §13")
@export var craft_evolve_days_home: int = 0
@export var craft_evolve_days_combat: int = 0
@export var fortress_seeds: Vector2i = Vector2i()
@export var fortress_cavities_revealed: Vector2i = Vector2i()

@export_group("Combate e moral — §07, §47, §50, §52")
@export var tower_accuracy: float = 0.0
@export var slot_replace_time: float = 0.0
@export var queue_min_px: int = 0
@export var queue_max_px: int = 0
@export var queue_spacing_px: int = 0
@export var king_presence_radius: int = 0
@export var breach_flee_health: float = 0.0
@export var breach_flee_max_cost: int = 0
@export var flee_health: float = 0.0

@export_group("Trabalho — §29")
@export var job_proximity_px: float = 0.0
@export var job_hysteresis: float = 0.0

@export_group("IA do rei inimigo — §10, §20")
@export var ai_w_fortify_wall: float = 0.0
@export var ai_w_fortify_threat: float = 0.0
@export var ai_w_attack: float = 0.0
@export var ai_w_recruit: float = 0.0
@export var ai_w_expand: float = 0.0
@export var ai_w_diplomat: float = 0.0
@export var ai_tyrant_greed: float = 0.0
@export var ai_tyrant_fortify_mult: float = 1.0
@export var ai_tyrant_recruit_mult: float = 1.0
@export var ai_target_training_house_from_day: int = 0

@export_group("v6 · nomes, Colheita e Lenho")
## Nove nomes ao mesmo tempo, e nem mais um (§76, D-07). A escassez e o que
## faz o nome valer; a Q-041 propoe mante-lo fixo.
@export var named_cap: int = 0
## Morto o dono, o titulo fica de luto e volta com ordinal (§76, D-08).
@export var title_mourning_days: int = 0
## Seis capitulos por campanha, dos dez; um e sempre o Cerco (§77, D-11, Q-043).
@export var chapters_per_campaign: int = 0
## C = colheita_base_days + colheita_per_people * povos ja detidos (§78).
@export var colheita_base_days: int = 0
@export var colheita_per_people: int = 0
## Por assimilacao, metade, arredondada para cima (§78).
@export var colheita_assimilation_factor: float = 0.0
## Produzem a 140% enquanto dura, e cantam (§78, §81).
@export var colheita_production_mult: float = 0.0
## Soltar: Favor, rota permanente e a tropa unica a 1,5x (§78).
@export var release_favor: int = 0
@export var release_route_income: float = 0.0
@export var release_unit_price_mult: float = 0.0
## Ficar: producao permanente e o marco que cria raiz (§78).
@export var keep_production_bonus: float = 0.0
@export var keep_landmark_mass: float = 0.0
## Atacar um aliado custa Favor e quebra as outras aliancas (§78).
@export var ally_attack_favor: int = 0
## O Lenho Amargo nao tem preco (§74, regra 1; D-02). Fica em zero de proposito
## e o teste chumba se alguem lhe der valor.
@export var bitter_wood_sell_price: int = 0
## Muralha de nivel 4 por Lenho, sem conquistar a Fornalha; o bastiao custa 3.
@export var bitter_wood_wall_level: int = 0
@export var bitter_wood_bastion_cost: int = 0
## Raio de apanha da moeda, em px (F1-01, proposta).
@export var coin_pickup_px: float = 0.0

@export_group("Auditoria de gameplay — AUD-02")
## O que rende uma obra com posto sem ninguem la, nas fases em que o posto e
## urgente (Q-121). O galinheiro, sem posto, rende sozinho.
@export var unstaffed_yield: float = 0.0
## A populacao por recrutar nao acaba: um vagabundo por alvorada num acampamento
## da regiao, ate haver este numero deles vivos (Q-122).
@export var vagrants_per_dawn: int = 0
@export var vagrant_camp_cap: int = 0
## O perfil de ganancia do teu rei no inicio (§15, Q-123).
@export var start_greed_profile: StringName = &""

@export_group("Auditoria de gameplay — AUD-04")
## O que um Alado leva de um galinheiro, em materia, se chegar vivo a alvorada
## (Q-129): a producao do dia seguinte, e nunca mais do que um dia dela.
@export var chicken_theft_matter: float = 0.0

@export_group("Auditoria de gameplay — AUD-05")
## A bifurcacao abre a travessia para a regiao seguinte a partir deste dia (Q-135).
@export var crossing_day: int = 0
## Quem e teu e esta a esta distancia do rei quando ele atravessa vai com ele.
@export var crossing_party_px: float = 0.0

@export_group("Andar — correr")
## Quanto mais depressa o rei anda com a tecla de correr premida (Q-149).
@export var king_run_mult: float = 0.0
## Quantos segundos se corre a pe com o folego cheio; 0 corre sem limite (Q-193).
@export var king_run_stamina_s: float = 0.0
## Quantos segundos a andar enchem o folego do zero (Q-193).
@export var king_run_refill_s: float = 0.0
## Quanto mais folego tem o monarca evoluido (Q-193).
@export var king_run_evolved_mult: float = 1.0
## Quanto o rei se afasta das bordas da regiao de casa; as classes vao alem (Q-150).
@export var king_leash_px: float = 0.0

@export_group("Coroa — o preco dos impulsos (Q-014)")
## Repetir o mesmo decreto dentro de impulse_repeat_days dias multiplica o preco
## por isto, por cada vez que ele saiu: o reino cansa-se da mesma ordem.
@export var impulse_repeat_mult: float = 1.0
@export var impulse_repeat_days: int = 0

## Q-144: dias de soldo que as tropas aguentam por pagar antes de desertarem, e
## dias em que quem desertou nao volta a ser recrutado.
@export var wage_grace_days: float = 1.0
@export var deserter_rest_days: int = 2

## A marcha e os vassalos (§13; Q-103, Q-146, Q-154).
@export var march_party_caps: Dictionary = {}
@export var march_min_party: int = 0
@export var march_nights: int = 1
## O cerco (§13; Q-166): a firmeza da fortaleza do primeiro povo, quanto mais tem
## cada povo adiante no plano, quanto lhe tira cada um que marcha, e a chance de
## cada um nao voltar.
@export var march_fortress_base: int = 0
@export var march_fortress_per_region: int = 0
@export var march_siege_per_unit: int = 0
@export var march_loss_chance: float = 0.0
## O mundo continuo (Q-173; ADR 0038): quanto mede cada trilho entre terras, a terra de
## cada outro povo, quanto o clima junta o bosque e de quantos em quantos segmentos,
## e o monte de moedas de uma masmorra.
@export var world_trail_segments: Vector2i = Vector2i()
@export var world_land_segments: int = 0
@export var wild_cluster: float = 0.0
@export var wild_cluster_segments: int = 0
@export var dungeon_coins: Vector2i = Vector2i()
@export var vassal_tribute: Vector2i = Vector2i()
@export var vassal_seeds: Vector2i = Vector2i()
@export var vassal_strength: float = 0.0
@export var vassal_erosion_per_mass: float = 0.0
@export var vassals_can_fall: bool = true

## O animo do reino (Q-102): limiares, pesos e prazos das memorias, e o que mexe.
@export var spirit_levels: PackedFloat32Array = PackedFloat32Array([35.0, 50.0, 65.0])
@export var spirit_weights: Dictionary = {}
@export var spirit_days: Dictionary = {}
@export var spirit_flee_mult: Vector2 = Vector2.ONE
@export var spirit_yield: float = 0.0
@export var spirit_vagrants: int = 0
