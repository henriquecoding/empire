# Esquema da base de dados de conteúdo

_Gerado por tools/content_report.py a partir de data/source/ — nao editar a mao._

Uma secção por tabela de `data/source/_tables.csv`: cada coluna do CSV, o tipo da propriedade no `Resource`, e o grupo. Colunas `_` são documentação e não aparecem aqui. Os campos do grupo **v5.2** foram acrescentados à §44 pela base de dados — ver docs/content/CONTENT_DATABASE.md.

## `clock.csv` → `data/economy/clock.tres`

Script `src/sim/data/clock_data.gd` · layout `rows` · 1 linha(s) · §69: o primeiro CSV, que prova o circuito CSV → .tres → jogo

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | nome do ficheiro | — | o recurso não tem campo id |
| `dawn` | elemento de `phase_durations` (PackedFloat32Array) |  |  |
| `morning` | elemento de `phase_durations` (PackedFloat32Array) |  |  |
| `noon` | elemento de `phase_durations` (PackedFloat32Array) |  |  |
| `afternoon` | elemento de `phase_durations` (PackedFloat32Array) |  |  |
| `dusk` | elemento de `phase_durations` (PackedFloat32Array) |  |  |
| `night` | elemento de `phase_durations` (PackedFloat32Array) |  |  |
| `tick_hz` | int |  |  |
| `day_seconds` | float |  |  |
| `day_seconds_min` | float |  |  |
| `day_seconds_max` | float |  |  |
| `phase_tint_hue` | PackedFloat32Array | v6 · a cor de cada fase (§80, ADR 0011) |  |
| `phase_tint_sat` | PackedFloat32Array | v6 · a cor de cada fase (§80, ADR 0011) |  |
| `phase_tint_val` | PackedFloat32Array | v6 · a cor de cada fase (§80, ADR 0011) |  |
| `night_value_floor` | float | v6 · a cor de cada fase (§80, ADR 0011) |  |

## `units.csv` → `data/units/{id}.tres`

Script `src/sim/data/unit_data.gd` · layout `rows` · 22 linha(s) · §07 §08 §09 §44

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | StringName |  | &"archer" — chave do Registry |
| `display_key` | String |  | chave de traducao, nao texto |
| `people` | StringName |  |  |
| `max_health` | int | Combate |  |
| `damage` | int | Combate |  |
| `attack_interval` | float | Combate | segundos |
| `accuracy_open` | float | Combate | 1.0 dentro de torre |
| `range_px` | int | Combate |  |
| `targets_bands` | Array[int] | Combate | que faixas consegue atingir |
| `recruit_cost` | int | Economia |  |
| `upkeep_per_day` | float | Economia |  |
| `drops_on_death` | Array[StringName] | Economia |  |
| `band` | Band.Kind | Mundo |  |
| `move_speed` | float | Mundo | px/s |
| `scale_tier` | int | Mundo | 1, 2 ou 3 — §22 |
| `can_change_band` | bool | Mundo |  |
| `layer_slots` | Array[StringName] | Arte |  |
| `shadow_width` | int | Arte | largura da elipse de contacto |
| `tags` | Array[StringName] | v5.2 |  |
| `job_affinity` | Dictionary | v5.2 |  |
| `coin_capacity` | int | v5.2 |  |
| `trained_at` | StringName | v5.2 |  |
| `train_days` | int | v5.2 |  |
| `ability` | StringName | v5.2 |  |
| `ability_params` | Dictionary | v5.2 |  |
| `weapon_kind` | StringName | v5.2 |  |
| `head_pool` | Array[StringName] | v5.2 |  |

## `creatures.csv` → `data/creatures/{id}.tres`

Script `src/sim/data/creature_data.gd` · layout `rows` · 7 linha(s) · §07 §44 §51

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | StringName |  |  |
| `display_key` | String |  |  |
| `mass_cost` | int | Podridao | §30: RotSystem compara com a massa |
| `min_day` | int | Podridao | §51: so e escolhida a partir deste dia |
| `max_health` | int | Combate |  |
| `damage` | int | Combate |  |
| `attack_interval` | float | Combate |  |
| `range_px` | int | Combate |  |
| `accuracy` | float | Combate |  |
| `target_priority` | StringName | Combate |  |
| `targets_bands` | Array[int] | Combate |  |
| `band` | Band.Kind | Mundo |  |
| `move_speed` | float | Mundo | px/s |
| `can_change_band` | bool | Mundo |  |
| `scale_tier` | int | Mundo |  |
| `layer_slots` | Array[StringName] | Arte |  |
| `shadow_width` | int | Arte |  |
| `drops_on_death` | Array[StringName] | v5.2 |  |
| `coin_drop` | int | v5.2 | §25: "uma moeda no chao onde morreu um Rastejante" |
| `tags` | Array[StringName] | v5.2 |  |
| `from_debt` | int | v6 · o Zelador (§75) |  |
| `can_be_killed` | bool | v6 · o Zelador (§75) |  |
| `pushable` | bool | v6 · o Zelador (§75) |  |
| `steals_named` | bool | v6 · o Zelador (§75) |  |

## `buildings.csv` → `data/buildings/{id}.tres`

Script `src/sim/data/building_data.gd` · layout `rows` · 25 linha(s) · §06 §09 §10 §44

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | StringName |  |  |
| `display_key` | String |  |  |
| `people` | StringName |  |  |
| `category` | StringName |  |  |
| `cost` | int | Economia |  |
| `material` | StringName | Economia | materia produzida: grain, fish, animal, wood, ore |
| `yield_per_day` | float | Economia |  |
| `requires_biome_feature` | StringName | Economia | water, forest, rock (§06, §21) |
| `destroyed_by_rot_trail` | bool | Economia | §49: plantacoes destruidas, o resto para |
| `job_slots` | int | Economia | postos que publica (§20) |
| `craft` | StringName | Economia | oficio que trabalha aqui |
| `max_health` | int | Construcao |  |
| `contact_slots` | int | Construcao |  |
| `build_work` | float | Construcao | segundos de construtor presente (§55) |
| `width_px` | int | Construcao |  |
| `upgrade_to` | StringName | Construcao |  |
| `unique_per_kingdom` | bool | Construcao |  |
| `effect_params` | Dictionary | Efeito | torres e defesas (§10) |
| `shadow_width` | int | Arte |  |
| `tags` | Array[StringName] | Arte |  |

## `walls.csv` → `data/walls/{id}.tres`

Script `src/sim/data/wall_data.gd` · layout `rows` · 5 linha(s) · §10 §44

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | StringName |  |  |
| `display_key` | String |  |  |
| `level` | int |  |  |
| `cost` | int |  |  |
| `max_health_b` | int |  | Caminho B — Fortificacao (§10, coluna "Vida (B)") |
| `guard_posts_a` | int |  | Caminho A — Guarnicao (§10, coluna "Postos (A)") |
| `contact_slots` | int |  | §07: so N atacantes engajam |
| `material_by_people` | Dictionary |  | people -> material (§10) |
| `pieces` | Array[StringName] |  | §22 |
| `max_health_a` | int | v5.2 | o §10 so da a vida do Caminho B |
| `guard_posts_b` | int | v5.2 |  |
| `unique_per_kingdom` | bool | v5.2 | Bastiao: "unico por imperio" |
| `requires_conquest` | StringName | v5.2 | Muralha de ferro: fornalha |
| `shadow_width` | int | v5.2 |  |

## `peoples.csv` → `data/peoples/{id}.tres`

Script `src/sim/data/people_data.gd` · layout `rows` · 6 linha(s) · §04 §22 §44

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | StringName |  |  |
| `display_key` | String |  |  |
| `terrain` | StringName |  |  |
| `biome` | StringName |  |  |
| `architecture_source` | String | Arquitetura | fonte arquitectonica real (§22) |
| `roof_silhouette` | String | Arquitetura | remate do telhado (§22) |
| `landmark` | StringName | Arquitetura | o marco da regiao (§21) |
| `segment_kit` | Array[StringName] | Arquitetura | SegmentData ids, 5-8 (§04) |
| `palette_ramp` | StringName | Arquitetura |  |
| `has_walls` | bool | Arquitetura |  |
| `wall_material` | StringName | Arquitetura |  |
| `economy_strength` | StringName | Jogo |  |
| `economy_modifiers` | Dictionary | Jogo |  |
| `defense_trait` | StringName | Jogo |  |
| `unique_unit` | StringName | Jogo |  |
| `playable_class` | StringName | Jogo |  |
| `starting_units` | Array[StringName] | Inicio |  |
| `starting_buildings` | Array[StringName] | Inicio |  |
| `song_texture` | String | v6 · a cancao e o marco (§78, §81) |  |
| `colheita_song` | String | v6 · a cancao e o marco (§78, §81) |  |
| `landmark_roots` | bool | v6 · a cancao e o marco (§78, §81) |  |

## `classes.csv` → `data/classes/{id}.tres`

Script `src/sim/data/class_data.gd` · layout `rows` · 7 linha(s) · §08 §44

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | StringName |  |  |
| `display_key` | String |  |  |
| `archetype` | StringName |  |  |
| `base_unit` | StringName |  | UnitData que se assume com o Verbo 2 (§08) |
| `verb` | StringName |  | acao propria da classe (§24: arqueiro marca alvo) |
| `fights` | bool |  |  |
| `unlock` | StringName | Desbloqueio |  |
| `unlock_seed_cost` | int | Desbloqueio |  |
| `phase_count` | int | Fases |  |
| `evolve_seed_cost` | int | Fases | §08: 1 Semente Real para a Fase 2 |
| `evolve_condition` | StringName | Fases |  |
| `evolve_condition_value` | int | Fases |  |
| `phase1_ability` | StringName | Fases |  |
| `phase1_params` | Dictionary | Fases |  |
| `phase2_ability` | StringName | Fases |  |
| `phase2_params` | Dictionary | Fases |  |

## `crafts.csv` → `data/crafts/{id}.tres`

Script `src/sim/data/craft_data.gd` · layout `rows` · 5 linha(s) · §06 circuito 2 · §44 · §49

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | StringName |  |  |
| `display_key` | String |  |  |
| `material` | StringName |  | materia consumida |
| `house` | StringName |  | edificio-alvo (BuildingData id) |
| `cost` | int |  | §49: materia consumida por conversao |
| `coin_multiplier` | float |  | §06: "+50% do valor de venda" |
| `capacity_craft` | StringName |  | oficio que da a capacidade |
| `capacity_kind` | StringName |  |  |
| `magnitude` | float |  |  |
| `duration` | float |  | segundos; 0 = permanente |

## `jobs.csv` → `data/jobs/{id}.tres`

Script `src/sim/data/job_data.gd` · layout `rows` · 14 linha(s) · §20 §29 §52 — o jobs.csv do relatório mestre

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | StringName |  |  |
| `display_key` | String |  |  |
| `priority` | float |  |  |
| `dawn` | elemento de `urgency_by_phase` (PackedFloat32Array) |  |  |
| `morning` | elemento de `urgency_by_phase` (PackedFloat32Array) |  |  |
| `noon` | elemento de `urgency_by_phase` (PackedFloat32Array) |  |  |
| `afternoon` | elemento de `urgency_by_phase` (PackedFloat32Array) |  |  |
| `dusk` | elemento de `urgency_by_phase` (PackedFloat32Array) |  |  |
| `night` | elemento de `urgency_by_phase` (PackedFloat32Array) |  |  |
| `band` | Band.Kind |  |  |
| `building_category` | StringName |  |  |

## `biomes.csv` → `data/biomes/{id}.tres`

Script `src/sim/data/biome_data.gd` · layout `rows` · 6 linha(s) · §11 §21 §44

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | StringName |  |  |
| `display_key` | String |  |  |
| `people` | StringName |  |  |
| `creature_table` | Array[StringName] |  | CreatureData ids |
| `resources` | Array[StringName] |  | water, forest, rock, fertile... |
| `atmosphere_preset` | StringName |  | open \| closed (§11) |
| `parallax_preset` | StringName |  | ParallaxLayerData.preset |
| `region_screens` | Vector2i |  | §21 |
| `music_profile` | StringName |  |  |
| `wildlife` | Array[StringName] |  | WildlifeData ids |

## `segments.csv` → `data/segments/{id}.tres`

Script `src/sim/data/segment_data.gd` · layout `rows` · 9 linha(s) · §21 §44 §54

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | StringName |  |  |
| `kind` | StringName |  |  |
| `people` | StringName |  |  |
| `weight` | int |  | §21; 0 = colocado por regra, nunca sorteado |
| `scene` | String |  |  |
| `width_px` | int |  |  |
| `build_slots` | int |  | autorados na cena (§55); aqui so a contagem |
| `cavity_slots` | int |  | 0-2 (§21) |
| `passages` | int |  | 0-1 (§21) |
| `resource` | StringName |  |  |
| `rules` | Array[StringName] |  | restricoes de adjacencia (§21) |
| `min_per_region` | int |  |  |
| `max_per_region` | int |  |  |
| `min_region_index` | int |  | caotico: so a partir da 2.a regiao |
| `subject` | StringName |  | o assunto do segmento (§21, regra 2) |
| `fixed` | bool |  | cena fixa (abertura, §25) |

## `economy.csv` → `data/economy/curve.tres`

Script `src/sim/data/economy_curve.gd` · layout `kv` · 94 linha(s) · §06 §47 — chave/valor; um só recurso

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `income_growth` | float | Curva e asfixia — §06 |  |
| `trade_growth` | float | Curva e asfixia — §06 |  |
| `night_cost_base` | float | Curva e asfixia — §06 |  |
| `night_cost_growth` | float | Curva e asfixia — §06 |  |
| `suffocation_target` | Vector2i | Curva e asfixia — §06 |  |
| `curve_income_flat` | float | Curva e asfixia — §06 |  |
| `curve_income_per_source` | float | Curva e asfixia — §06 |  |
| `upkeep_free_troops` | int | Manutencao — §06 |  |
| `upkeep_tier1_limit` | int | Manutencao — §06 |  |
| `upkeep_tier1_rate` | float | Manutencao — §06 |  |
| `upkeep_tier2_rate` | float | Manutencao — §06 |  |
| `trade_route_income` | float | Comercio, caca, saque — §06, §13, §25, §49 |  |
| `trade_network_bonus` | float | Comercio, caca, saque — §06, §13, §25, §49 |  |
| `trade_cart_cost` | int | Comercio, caca, saque — §06, §13, §25, §49 |  |
| `hunt_yield` | Vector2i | Comercio, caca, saque — §06, §13, §25, §49 |  |
| `loot_yield` | Vector2i | Comercio, caca, saque — §06, §13, §25, §49 |  |
| `start_coins` | int | Comercio, caca, saque — §06, §13, §25, §49 |  |
| `coin_stack_max` | int | Comercio, caca, saque — §06, §13, §25, §49 |  |
| `favor_decay_per_day` | float | Favor e diplomacia — §06, §14, §56 |  |
| `diplomat_p_dissolve` | float | Favor e diplomacia — §06, §14, §56 |  |
| `diplomat_p_contract` | float | Favor e diplomacia — §06, §14, §56 |  |
| `diplomat_p_capture` | float | Favor e diplomacia — §06, §14, §56 |  |
| `diplomat_favor_step` | int | Favor e diplomacia — §06, §14, §56 |  |
| `diplomat_favor_shift` | float | Favor e diplomacia — §06, §14, §56 |  |
| `assimilate_every_days` | int | Favor e diplomacia — §06, §14, §56 |  |
| `assimilate_favor` | int | Favor e diplomacia — §06, §14, §56 |  |
| `mercenary_afternoon_markup` | float | Mercenarios e divida — §05, §14, §56 |  |
| `debt_base` | int | Mercenarios e divida — §05, §14, §56 |  |
| `debt_per_mercenary` | int | Mercenarios e divida — §05, §14, §56 |  |
| `debt_due_days` | int | Mercenarios e divida — §05, §14, §56 |  |
| `debt_late_multiplier` | float | Mercenarios e divida — §05, §14, §56 |  |
| `debt_partial_reset_days` | int | Mercenarios e divida — §05, §14, §56 |  |
| `debt_desert_until_late_day` | int | Mercenarios e divida — §05, §14, §56 |  |
| `debt_diplomat_dies_late_day` | int | Mercenarios e divida — §05, §14, §56 |  |
| `debt_camp_marches_late_day` | int | Mercenarios e divida — §05, §14, §56 |  |
| `impulses_per_day` | int | Coroa, morte e decay — §15, §16 |  |
| `heir_training_days` | int | Coroa, morte e decay — §15, §16 |  |
| `heir_training_days_diplomat` | int | Coroa, morte e decay — §15, §16 |  |
| `heir_cost_per_day` | int | Coroa, morte e decay — §15, §16 |  |
| `heir_boost_inheritance` | float | Coroa, morte e decay — §15, §16 |  |
| `interregnum_days` | int | Coroa, morte e decay — §15, §16 |  |
| `interregnum_greed` | int | Coroa, morte e decay — §15, §16 |  |
| `decay_structures_kept` | float | Coroa, morte e decay — §15, §16 |  |
| `resurrection_seed_cost` | int | Coroa, morte e decay — §15, §16 |  |
| `resurrection_coin_cost` | int | Coroa, morte e decay — §15, §16 |  |
| `resurrection_phase_loss` | int | Coroa, morte e decay — §15, §16 |  |
| `craft_evolve_days_home` | int | Oficios e conquista — §09, §13 |  |
| `craft_evolve_days_combat` | int | Oficios e conquista — §09, §13 |  |
| `fortress_seeds` | Vector2i | Oficios e conquista — §09, §13 |  |
| `fortress_cavities_revealed` | Vector2i | Oficios e conquista — §09, §13 |  |
| `tower_accuracy` | float | Combate e moral — §07, §47, §50, §52 |  |
| `slot_replace_time` | float | Combate e moral — §07, §47, §50, §52 |  |
| `queue_min_px` | int | Combate e moral — §07, §47, §50, §52 |  |
| `queue_max_px` | int | Combate e moral — §07, §47, §50, §52 |  |
| `queue_spacing_px` | int | Combate e moral — §07, §47, §50, §52 |  |
| `king_presence_radius` | int | Combate e moral — §07, §47, §50, §52 |  |
| `breach_flee_health` | float | Combate e moral — §07, §47, §50, §52 |  |
| `breach_flee_max_cost` | int | Combate e moral — §07, §47, §50, §52 |  |
| `flee_health` | float | Combate e moral — §07, §47, §50, §52 |  |
| `job_proximity_px` | float | Trabalho — §29 |  |
| `job_hysteresis` | float | Trabalho — §29 |  |
| `ai_w_fortify_wall` | float | IA do rei inimigo — §10, §20 |  |
| `ai_w_fortify_threat` | float | IA do rei inimigo — §10, §20 |  |
| `ai_w_attack` | float | IA do rei inimigo — §10, §20 |  |
| `ai_w_recruit` | float | IA do rei inimigo — §10, §20 |  |
| `ai_w_expand` | float | IA do rei inimigo — §10, §20 |  |
| `ai_w_diplomat` | float | IA do rei inimigo — §10, §20 |  |
| `ai_tyrant_greed` | float | IA do rei inimigo — §10, §20 |  |
| `ai_tyrant_fortify_mult` | float | IA do rei inimigo — §10, §20 |  |
| `ai_tyrant_recruit_mult` | float | IA do rei inimigo — §10, §20 |  |
| `ai_target_training_house_from_day` | int | IA do rei inimigo — §10, §20 |  |
| `named_cap` | int | v6 · nomes, Colheita e Lenho |  |
| `title_mourning_days` | int | v6 · nomes, Colheita e Lenho |  |
| `colheita_base_days` | int | v6 · nomes, Colheita e Lenho |  |
| `colheita_per_people` | int | v6 · nomes, Colheita e Lenho |  |
| `colheita_assimilation_factor` | float | v6 · nomes, Colheita e Lenho |  |
| `colheita_production_mult` | float | v6 · nomes, Colheita e Lenho |  |
| `release_favor` | int | v6 · nomes, Colheita e Lenho |  |
| `release_route_income` | float | v6 · nomes, Colheita e Lenho |  |
| `release_unit_price_mult` | float | v6 · nomes, Colheita e Lenho |  |
| `keep_production_bonus` | float | v6 · nomes, Colheita e Lenho |  |
| `keep_landmark_mass` | float | v6 · nomes, Colheita e Lenho |  |
| `ally_attack_favor` | int | v6 · nomes, Colheita e Lenho |  |
| `bitter_wood_sell_price` | int | v6 · nomes, Colheita e Lenho |  |
| `bitter_wood_wall_level` | int | v6 · nomes, Colheita e Lenho |  |
| `bitter_wood_bastion_cost` | int | v6 · nomes, Colheita e Lenho |  |
| `coin_pickup_px` | float | v6 · nomes, Colheita e Lenho |  |
| `coin_gravity_px_s2` | float | Moeda fisica — §02, §61, F1-01 |  |
| `coin_drop_speed_px_s` | float | Moeda fisica — §02, §61, F1-01 |  |
| `coin_drop_spread_px_s` | float | Moeda fisica — §02, §61, F1-01 |  |
| `coin_drop_repeat_s` | float | Moeda fisica — §02, §61, F1-01 |  |
| `recruit_notice_px` | float | Recrutamento — §25 minuto 0:20, F1-04 |  |
| `follow_distance_px` | float | Recrutamento — §25 minuto 0:20, F1-04 |  |
| `follow_spacing_px` | float | Recrutamento — §25 minuto 0:20, F1-04 |  |

## `economy_profiles.csv` → `data/economy/profiles/{id}.tres`

Script `src/sim/data/economy_profile.gd` · layout `rows` · 5 linha(s) · §06 §31 — perfis dos testes de design

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | StringName |  |  |
| `sources` | int |  |  |
| `routes` | int |  |  |
| `troops` | int |  |  |
| `greed` | int |  |  |
| `expect_suffocation` | Vector2i |  |  |

## `rot.csv` → `data/rot/{id}.tres`

Script `src/sim/data/rot_profile.gd` · layout `rows` · 1 linha(s) · §05 §44 §51 — substitui o waves.csv (§70)

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | nome do ficheiro | — | o recurso não tem campo id |
| `speed_base` | float |  | px/s |
| `speed_per_day` | float |  |  |
| `mass_base` | float |  |  |
| `mass_per_day` | float |  |  |
| `mass_per_fortress` | float |  |  |
| `summon_interval` | Vector2 |  |  |
| `consecrated_slowdown` | float |  | -40% em terreno consagrado |
| `trail_move_penalty` | float |  |  |
| `two_sided_from_day` | int |  |  |
| `sacrifice_mass_per_coin` | float |  |  |
| `sacrifice_mass_per_animal` | float | v5.2 |  |
| `sacrifice_mass_per_troop` | float | v5.2 |  |
| `width_start` | float | v5.2 |  |
| `pick_rule` | StringName | v5.2 |  |
| `mass_per_amargueiro` | float | v6 · a massa escreve-se de dia |  |
| `mass_per_named_amargueiro` | float | v6 · a massa escreve-se de dia |  |
| `amargueiro_nights_standing` | int | v6 · a massa escreve-se de dia |  |
| `amargueiro_roots_outside_walls` | bool | v6 · a massa escreve-se de dia |  |
| `amargueiro_roots_underground` | bool | v6 · a massa escreve-se de dia |  |
| `amargueiro_base_px` | float | v6 · a massa escreve-se de dia |  |
| `lantern_radius_base` | float | v6 · a candeia |  |
| `lantern_radius_per_day` | float | v6 · a candeia |  |
| `lantern_radius_max` | float | v6 · a candeia |  |
| `lantern_tint` | String | v6 · a candeia |  |
| `lantern_tint_mid` | String | v6 · a candeia |  |
| `lantern_tint_edge` | String | v6 · a candeia |  |
| `lantern_dither_px` | float | v6 · a candeia |  |
| `offer_trigger_px` | float | v6 · a oferta |  |
| `offer_window_after_dusk` | Vector2 | v6 · a oferta |  |
| `offer_seconds` | float | v6 · a oferta |  |
| `offer_plate_px` | float | v6 · a oferta |  |
| `offers_per_night` | int | v6 · a oferta |  |
| `refusal_mass` | float | v6 · a oferta |  |
| `refusal_window_days` | int | v6 · a oferta |  |
| `refusal_cap` | float | v6 · a oferta |  |
| `debt_max` | int | v6 · a Divida da Candeia |  |
| `debt_tiers` | Array[int] | v6 · a Divida da Candeia |  |
| `tender_from_debt` | int | v6 · a Divida da Candeia |  |
| `ambient_light_from_debt` | int | v6 · a Divida da Candeia |  |
| `second_flame_from_debt` | int | v6 · a Divida da Candeia |  |
| `union_debt_max` | int | v6 · os epilogos |  |
| `union_peoples_released` | int | v6 · os epilogos |  |
| `dominion_debt_min` | int | v6 · os epilogos |  |
| `dominion_peoples_kept` | int | v6 · os epilogos |  |

## `mounts.csv` → `data/mounts/{id}.tres`

Script `src/sim/data/mount_data.gd` · layout `rows` · 6 linha(s) · §12 §44

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | StringName |  |  |
| `display_key` | String |  |  |
| `speed_multiplier` | float |  |  |
| `coin_capacity_multiplier` | float |  |  |
| `band` | Band.Kind |  |  |
| `can_change_band` | bool |  |  |
| `flies` | bool |  | libelula: ignora a faixa de superficie |
| `climbs_walls` | bool |  | lagarto: acesso vertical sem passagem |
| `ignores_rot_trail` | bool |  | alce da Podridao |
| `knocks_down_stakes` | bool |  | javali |
| `obtain` | StringName |  |  |
| `obtain_ref` | StringName |  | bioma, povo ou classe de origem |
| `cost` | int |  |  |
| `heal_days` | int |  | §12: ferida recupera no estabulo em 2 dias |

## `impulses.csv` → `data/crown/impulses/{id}.tres`

Script `src/sim/data/impulse_data.gd` · layout `rows` · 6 linha(s) · §15 §57

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | StringName |  |  |
| `display_key` | String |  |  |
| `icon` | StringName |  |  |
| `coin_cost` | int |  |  |
| `benefit` | StringName |  |  |
| `benefit_value` | float |  |  |
| `drawback` | StringName |  |  |
| `drawback_value` | float |  |  |
| `drawback_days` | int |  |  |

## `greed_profiles.csv` → `data/crown/greed/{id}.tres`

Script `src/sim/data/greed_profile.gd` · layout `rows` · 4 linha(s) · §15 §20

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | StringName |  |  |
| `display_key` | String |  |  |
| `greed_range` | Vector2i |  |  |
| `elite_morale_mod` | float | No teu imperio |  |
| `free_elite_every_days` | int | No teu imperio |  |
| `impulse_cost_mult` | float | No teu imperio |  |
| `enemy_wall_bias` | float | Num rei inimigo |  |
| `enemy_elite_bias` | float | Num rei inimigo |  |
| `enemy_attack_unit` | StringName | Num rei inimigo |  |
| `enemy_attack_timing` | StringName | Num rei inimigo |  |

## `secrets.csv` → `data/lore/secrets/{id}.tres`

Script `src/sim/data/secret_data.gd` · layout `rows` · 4 linha(s) · §17

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | StringName |  |  |
| `display_key` | String |  |  |
| `band` | Band.Kind |  |  |
| `location` | StringName |  | behind_passage, under_vegetation, fortress, chaotic_biome |
| `reward_seeds` | int |  |  |
| `reward` | StringName |  | lore_fragment, teach_mechanic, journal, unlock |
| `teaches` | StringName |  | mecanica ensinada (estatuas) |

## `journals.csv` → `data/lore/journals/{id}.tres`

Script `src/sim/data/journal_data.gd` · layout `rows` · 12 linha(s) · §17

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | StringName |  |  |
| `act` | int |  |  |
| `order` | int |  |  |
| `title_key` | String |  |  |
| `body_key` | String |  |  |
| `where_kind` | StringName | v6 · onde esta e o que e (§79) |  |
| `where_id` | StringName | v6 · onde esta e o que e (§79) |  |
| `object_key` | String | v6 · onde esta e o que e (§79) |  |
| `reveals_key` | String | v6 · onde esta e o que e (§79) |  |

## `wildlife.csv` → `data/wildlife/{id}.tres`

Script `src/sim/data/wildlife_data.gd` · layout `rows` · 3 linha(s) · §06 §25

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | StringName |  |  |
| `display_key` | String |  |  |
| `max_health` | int |  |  |
| `move_speed` | float |  |  |
| `coin_yield` | int |  |  |
| `flees` | bool |  |  |
| `damage` | int |  |  |
| `biomes` | Array[StringName] |  |  |
| `per_segment_max` | int |  |  |
| `shadow_width` | int |  |  |

## `companions.csv` → `data/companions/{id}.tres`

Script `src/sim/data/companion_data.gd` · layout `rows` · 3 linha(s) · §08

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | StringName |  |  |
| `display_key` | String |  |  |
| `rule` | StringName |  | a regra que altera |
| `rule_params` | Dictionary |  |  |
| `heal_per_day` | float |  | §08: a cura tambem vem do companheiro |
| `growth_stages` | int |  |  |
| `food` | Array[StringName] |  |  |

## `chaos_modifiers.csv` → `data/biomes/chaos/{id}.tres`

Script `src/sim/data/chaos_modifier_data.gd` · layout `rows` · 4 linha(s) · §17 §21

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | StringName |  |  |
| `display_key` | String |  |  |
| `damage_mult` | float |  |  |
| `health_loss_per_day` | float |  |  |
| `mercenary_price_mult` | float |  |  |
| `debt_interest_mult` | float |  |  |
| `swaps_bands` | bool |  |  |
| `no_light` | bool |  |  |
| `only_class` | StringName |  | quem se orienta sem luz |

## `parallax_layers.csv` → `data/biomes/parallax/{id}.tres`

Script `src/sim/data/parallax_layer_data.gd` · layout `rows` · 12 linha(s) · §11 §22 §59

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | StringName |  |  |
| `preset` | StringName |  | open \| closed |
| `layer` | int |  | 1 ceu .. 6 primeiro plano |
| `node_name` | StringName |  |  |
| `z_index` | int |  |  |
| `motion_scale` | float |  | fracoes binarias exatas (§22) |
| `saturation_delta` | float |  |  |
| `value_delta` | float |  |  |
| `hue_shift_deg` | float |  |  |
| `min_detail_px` | int |  |  |
| `outline_px` | int |  |  |
| `colors_per_16px` | Vector2i |  |  |

## `amargueiros.csv` → `data/rot/amargueiros/{id}.tres`

Script `src/sim/data/amargueiro_data.gd` · layout `rows` · 3 linha(s) · §74 — os três destinos de um Amargueiro

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | StringName |  |  |
| `display_key` | String |  |  |
| `cost_coins` | int | Preco |  |
| `cost_seeds` | int | Preco |  |
| `work_seconds` | float | Preco |  |
| `nights_standing_required` | int | Preco |  |
| `from_dawn` | int | Preco |  |
| `yield_by_tier` | Array[int] | Rendimento |  |
| `yield_named` | int | Rendimento |  |
| `yield_kind` | StringName | Rendimento |  |
| `mass_delta` | float | Efeito na noite |  |
| `mass_delta_named` | float | Efeito na noite |  |
| `permanent` | bool | Efeito na noite |  |
| `becomes` | StringName | Efeito na noite |  |
| `protect_radius_px` | int | Efeito na noite |  |
| `slowdown` | float | Efeito na noite |  |
| `morale_cost` | int | Custo humano |  |
| `morale_days` | int | Custo humano |  |

## `offers.csv` → `data/rot/offers/{id}.tres`

Script `src/sim/data/offer_data.gd` · layout `rows` · 12 linha(s) · §75 — as doze ofertas, com a gramática de requires

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | StringName |  |  |
| `display_key` | String |  |  |
| `price_kind` | StringName | Preco |  |
| `price_amount` | float | Preco |  |
| `effect_kind` | StringName | Efeito |  |
| `effect_value` | float | Efeito |  |
| `effect_days` | int | Efeito |  |
| `requires` | String | Elegibilidade |  |
| `min_day` | int | Elegibilidade |  |
| `once_per_campaign` | bool | Elegibilidade |  |
| `debt_delta` | int | Divida |  |
| `ends_rot` | bool | Divida |  |

## `titles.csv` → `data/lore/titles/{id}.tres`

Script `src/sim/data/title_data.gd` · layout `rows` · 9 linha(s) · §76 — os nove feitos que dão nome

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | StringName |  |  |
| `display_key` | String |  |  |
| `feat_key` | String |  |  |
| `condition_kind` | StringName | Condicao |  |
| `condition_value` | float | Condicao |  |
| `grant_kind` | StringName | O que da |  |
| `grant_value` | float | O que da |  |
| `ribbon_color` | String | Apresentacao |  |
| `unique_while_alive` | bool | Apresentacao |  |

## `chapters.csv` → `data/world/chapters/{id}.tres`

Script `src/sim/data/chapter_data.gd` · layout `rows` · 10 linha(s) · §77 — os dez Capítulos

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | StringName |  |  |
| `display_key` | String |  |  |
| `law_key` | String |  |  |
| `inhabitant_key` | String |  |  |
| `song_key` | String |  |  |
| `biome` | StringName | Colocacao |  |
| `placement` | StringName | Colocacao |  |
| `detour_seconds` | float | Colocacao |  |
| `guaranteed` | bool | Colocacao |  |
| `reward_kind` | StringName | Recompensa |  |
| `reward_id` | StringName | Recompensa |  |
| `law_enters_walls` | bool | Regras |  |
| `visits_tracked` | bool | Regras |  |
| `folk_root` | String | Regras |  |

## `camera.csv` → `data/camera/{id}.tres`

Script `src/sim/data/camera_data.gd` · layout `rows` · 1 linha(s) · §19 §24 §59 — a camara como dados; um so numero vem do dossie (Q-057)

| coluna | tipo | grupo | nota do script |
|---|---|---|---|
| `id` | nome do ficheiro | — | o recurso não tem campo id |
| `lookahead_px` | float |  |  |
| `lookahead_seconds` | float |  |  |
| `follow_seconds` | float |  |  |
| `free_speed_px_s` | float |  |  |
| `free_return_seconds` | float |  |  |

