# 46 — Eventos · O catálogo completo

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Sessenta e um sinais. É a lista fechada: um sistema que precise de comunicar uma coisa que não está aqui precisa primeiro de uma entrada nova na §46. É esta restrição que impede a IA de inventar meia dúzia de sinais quase iguais em ficheiros diferentes.

| Sinal | Carga | Emitido por | Quem ouve |
| --- | --- | --- | --- |
| Relógio — 7 |  |  |  |
| day_started | day: int | GameClock | Economia, Podridão, IA, autosave |
| phase_changed | from, to: Phase | GameClock | Trabalho, luz, áudio, tropas |
| dawn_broke | day: int | GameClock | Sino, varrimento de luz, contagem de perdas |
| dusk_fell | day: int | GameClock | Aviso sonoro, nascimento da Podridão |
| night_started | day: int | GameClock | Recolha aos postos, música |
| night_survived | day, deaths, walls_lost | GameClock | Telemetria, conquistas, diário |
| game_paused | paused: bool | UI | Todos os sistemas |
| Economia — 11 |  |  |  |
| coin_dropped | x, band, amount, source | Jogador, unidade, morte | Construção, apanha, áudio |
| coin_collected | unit_id, amount | MovementSystem | HUD do saco, áudio |
| coin_spent | amount, purpose | Build, recrutamento | Telemetria |
| material_produced | building_id, kind, amount | EconomySystem | Carroças, ofícios |
| material_consumed | building_id, kind, amount | CraftSystem | Visual da carroça |
| craft_chosen | craft_id, mode | Jogador | Economia, capacidade |
| capacity_granted | kind, magnitude, duration | CraftSystem | Tropas, overlay visual |
| trade_route_opened | people_id, income | DiplomacySystem | Economia, HUD |
| trade_route_closed | people_id, reason | Conquista, Podridão | Economia |
| seed_royal_gained | amount, source | Fortaleza, segredo | Metaprogresso, save |
| favor_changed | delta, total | Diplomacia, bardo | HUD, mercenários |
| Unidades e combate — 14 |  |  |  |
| unit_spawned | unit_id, data_id, x, band | UnitSystem | Apresentação, telemetria |
| unit_promoted | unit_id, from, to | JobSystem | Slots de arte, áudio |
| unit_state_changed | unit_id, from, to | UnitFsm | Animação |
| unit_damaged | unit_id, amount, from_id | CombatSystem | Flash, camada face, knockback |
| unit_died | unit_id, x, band, drops | CombatSystem | Corpo, largadas, áudio, telemetria |
| unit_revived | unit_id | ClassSystem | Apresentação |
| unit_fled | unit_id, reason | UnitFsm | Moral |
| attack_launched | from_id, to_id, hit: bool | CombatSystem | Projétil, impacto, áudio |
| target_marked | target_id, by_id | Classe Arqueiro | Prioridade de alvo, contorno |
| contact_slot_taken | wall_id, slot, unit_id | CombatSystem | Posicionamento |
| contact_slot_freed | wall_id, slot | CombatSystem | Substituição em 0,4 s |
| weapon_dropped | x, band, tier | CombatSystem | Ferreiro n2 |
| mercenary_hired | unit_id, price, debt | DiplomacySystem | Dívida, HUD |
| loyalty_changed | unit_id, value | Bardo, dívida | Camada face, IA |
| A Podridão — 8 |  |  |  |
| rot_spawned | x, width, mass, side | RotSystem | Mancha, música, aviso |
| rot_moved | x, width | RotSystem | Mancha, stem de tensão |
| rot_summoned | creature_id, x, mass_spent | RotSystem | Apresentação |
| rot_slowed | factor, cause | RotSystem | Feedback visual |
| rot_fed | mass_removed, offering | Jogador | Mancha, áudio |
| rot_trail_left | from_x, to_x | RotSystem | Terreno, plantações, movimento |
| rot_retreated | day | RotSystem | Dissolução, luz |
| creature_died | creature_id, x, band | CombatSystem | Largadas, telemetria |
| Mundo e construção — 12 |  |  |  |
| region_generated | seed, segments | WorldGen | Apresentação, parallax |
| segment_entered | segment_id, type | CameraRig | Áudio, telemetria |
| build_started | slot_id, building_id | BuildSystem | Andaime, construtor |
| build_progressed | slot_id, ratio | BuildSystem | Estado do sprite |
| build_completed | building_id | BuildSystem | Economia, áudio |
| building_damaged | building_id, ratio | CombatSystem | Estado do sprite |
| building_destroyed | building_id, x | CombatSystem | Ruína, economia |
| wall_upgraded | wall_id, level | BuildSystem | Material, silhueta, slots |
| wall_breached | wall_id | CombatSystem | Tremor de ecrã, música, IA |
| cavity_revealed | cavity_id | Jogador | Shader de dither, luz |
| passage_used | unit_id, from_band, to_band | MovementSystem | Apresentação |
| secret_found | secret_id | Mundo | Diário, Semente Real |
| Coroa e impérios — 9 |  |  |  |
| king_action_chosen | kingdom_id, action | KingAISystem | Apresentação, telemetria |
| greed_changed | kingdom_id, value | CrownSystem | Nobres na varanda, economia |
| royal_impulse_used | impulse_id | Jogador | Efeito, roda do rei |
| king_died | kingdom_id, heir_id | CombatSystem | Sucessão, derrota |
| succession_started | heir_id | SuccessionSystem | UI, luz |
| fortress_conquered | fortress_id, people_id | ConquestSystem | Kit novo, Semente Real |
| people_assimilated | people_id | DiplomacySystem | Rota, arquitetura |
| debt_incurred | amount, due_day | DebtSystem | Contador de 6 dias |
| debt_defaulted | amount | DebtSystem | Mercenários viram inimigos |


> **Como o EventBus é escrito**
>
> Um único autoload com sinais declarados, não um dicionário de strings. Sinais declarados dão-te verificação estática, autocompletar, e um erro em vez de silêncio quando alguém escreve unit_dead em vez de unit_died. A fila do §43 é interna: queue(sig, args) durante o tick, flush() no fim.
