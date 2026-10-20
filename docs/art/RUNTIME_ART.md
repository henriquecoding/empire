# Arte em runtime — o que o jogo desenha com os originais

<!-- gerado por tools/inventario_arte.py — nao editar a mao -->

Lido do manifesto de `art/export/enramados/`, dos CSV e das funcoes que ligam dados a arte. Fonte, export, chamada em runtime, accoes e aprovacao sao colunas separadas: existir uma textura nao conclui nada. O `ASSET_REGISTER.csv` continua a ser o plano de producao e nao e alterado por isto (tem 2 linhas `IN_GAME`, que nao contam estas exportacoes).

Accoes do contrato (`src/actors/actor_action.gd`): `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work`. Uma accao sem tag no manifesto mostra o repouso (fugir mostra a caminhada, se existir).

## Exportacoes dos originais

| Export | Fonte | Frames | Tags (accoes) | Chamada em runtime | Quem a usa | Aprovacao |
|---|---|---:|---|---|---|---|
| `cook.png` | `art/source/originals/concept.aseprite` | 1 | — | — | — | `near_complete_reference` |
| `far_keep.png` | `art/source/originals/concept.aseprite` | 1 | — | — | — | `author_base_needs_refinement` |
| `gate.png` | `art/source/originals/concept.aseprite` | 1 | — | — | — | `author_base_needs_refinement` |
| `knight.png` | `art/source/originals/troop.aseprite` | 6 | `idle` | — | — | `near_complete_reference` |
| `monarch.png` | `art/source/originals/concept.aseprite` | 1 | — | — | — | `redesign_required` |
| `oak.png` | `art/source/originals/concept.aseprite` | 1 | — | — | — | `author_base_needs_refinement` |
| `storehouse.png` | `art/source/originals/concept.aseprite` | 1 | — | `src/world/building_skins.gd` | obra pen | `author_base_needs_refinement` |
| `training_house.png` | `art/source/originals/concept.aseprite` | 1 | — | — | — | `author_base_needs_refinement` |
| `tree_castle.png` | `art/source/originals/concept.aseprite` | 1 | — | — | — | `author_base_needs_refinement` |
| `vagrant.png` | `art/source/originals/troop.aseprite` | 6 | `idle` | — | — | `derived_temporary` |
| `workshop.png` | `art/source/originals/concept.aseprite` | 1 | — | — | — | `author_base_needs_refinement` |

## Unidades

| Unidade | Fase | No marco | Arte | Accoes desenhadas | Accoes em falta |
|---|---:|---|---|---|---|
| `vagrant` | 1 | sim | `royal_citizen` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `archer` | 1 |  | `royal_bowman` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `spearman` | 1 |  | `royal_spearman` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `dragonfly` | 2 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `root_berserker` | 2 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `mercenary` | 6 |  | `royal_knight` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `monarch` | 1 | sim | `royal_king` — emprestado | `attack`, `attack_left`, `attack_right`, `die`, `die_left`, `die_right`, `flee`, `hit`, `hit_left`, `hit_right`, `idle`, `idle_left`, `idle_right`, `rise`, `rise_left`, `rise_right`, `walk`, `walk_left`, `walk_right` | `work` |
| `squire` | 1 | sim | `royal_squire` — emprestado | `attack`, `block`, `block_hold`, `block_hold_left`, `block_hold_right`, `block_left`, `block_right`, `die`, `die_left`, `die_right`, `flee`, `hit`, `hit_left`, `hit_right`, `idle`, `idle_left`, `idle_right`, `rise`, `rise_left`, `rise_right`, `walk`, `walk_left`, `walk_right` | `work` |
| `builder` | 1 | sim | `royal_smith` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `smith` | 2 |  | `royal_smith` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `cook` | 2 | sim | `royal_cook` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `diplomat` | 6 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `bard` | 6 |  | `royal_bard` — emprestado | `die`, `die_left`, `die_right`, `flee`, `hit`, `hit_left`, `hit_right`, `idle`, `idle_left`, `idle_right`, `play`, `play_left`, `play_right`, `rise`, `rise_left`, `rise_right`, `walk`, `walk_left`, `walk_right`, `work` | `attack` |
| `climber` | 6 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `buried_knight` | 6 |  | `royal_shadow` — emprestado | `die`, `die_left`, `die_right`, `flee`, `heal`, `heal_left`, `heal_right`, `hit`, `hit_left`, `hit_right`, `idle`, `idle_left`, `idle_right`, `rise`, `rise_left`, `rise_right`, `sit`, `sit_left`, `sit_right`, `stand`, `stand_left`, `stand_right`, `walk`, `walk_left`, `walk_right` | `attack`, `work` |
| `sealed_knight` | 6 |  | `royal_knight` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `archer_hero` | 1 |  | `royal_archer` — emprestado | `attack`, `die`, `die_left`, `die_right`, `flee`, `hit`, `hit_left`, `hit_right`, `idle`, `idle_left`, `idle_right`, `rise`, `rise_left`, `rise_right`, `shoot`, `shoot_left`, `shoot_right`, `walk`, `walk_left`, `walk_right` | `work` |
| `bard_hero` | 6 |  | `royal_bard` — emprestado | `die`, `die_left`, `die_right`, `flee`, `hit`, `hit_left`, `hit_right`, `idle`, `idle_left`, `idle_right`, `play`, `play_left`, `play_right`, `rise`, `rise_left`, `rise_right`, `walk`, `walk_left`, `walk_right`, `work` | `attack` |
| `diplomat_hero` | 6 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `canopy_archer` | 2 |  | `royal_bowman` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `barge` | 7 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `counterweight_ram` | 7 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `sower` | 7 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `war_smith` | 7 |  | `royal_smith` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `digger` | 7 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `ice_warden` | 7 |  | `royal_spearman` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `reed_stalker` | 7 |  | `royal_bowman` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `nia` | 1 |  | `royal_nia` — emprestado | `attack`, `attack_left`, `attack_right`, `die`, `die_left`, `die_right`, `flee`, `hit`, `hit_left`, `hit_right`, `idle`, `idle_left`, `idle_right`, `rise`, `rise_left`, `rise_right`, `walk`, `walk_left`, `walk_right` | `work` |
| `archer_emperor` | 1 |  | `royal_archer` — emprestado | `attack`, `die`, `die_left`, `die_right`, `flee`, `hit`, `hit_left`, `hit_right`, `idle`, `idle_left`, `idle_right`, `rise`, `rise_left`, `rise_right`, `shoot`, `shoot_left`, `shoot_right`, `walk`, `walk_left`, `walk_right` | `work` |
| `bard_banner` | 1 |  | `royal_bard` — emprestado | `die`, `die_left`, `die_right`, `flee`, `hit`, `hit_left`, `hit_right`, `idle`, `idle_left`, `idle_right`, `play`, `play_left`, `play_right`, `rise`, `rise_left`, `rise_right`, `walk`, `walk_left`, `walk_right`, `work` | `attack` |
| `quiver_squire` | 1 |  | `royal_quiver` — emprestado | `deliver`, `deliver_left`, `deliver_right`, `die`, `die_left`, `die_right`, `flee`, `hit`, `hit_left`, `hit_right`, `idle`, `idle_left`, `idle_right`, `receive`, `receive_left`, `receive_right`, `rise`, `rise_left`, `rise_right`, `walk`, `walk_left`, `walk_right`, `work` | `attack` |

## Obras

| Obra | Fase | No marco | Arte | Estados |
|---|---:|---|---|---|
| `core` | 1 | sim | `royal_tree_castle` | 1 frame; estados por codigo |
| `training_house` | 1 | sim | `royal_training` | 1 frame; estados por codigo |
| `forge` | 2 |  | `royal_forge` | 1 frame; estados por codigo |
| `kitchen` | 2 | sim | `royal_kitchen` | 1 frame; estados por codigo |
| `embassy` | 6 |  | pintada (`PaintedArt`): `manor` — partilhada com `heir_house` | 1 imagem; estados por codigo |
| `heir_house` | 1 | sim | pintada (`PaintedArt`): `manor` — partilhada com `embassy` | 1 imagem; estados por codigo |
| `root_sanctuary` | 6 |  | pintada (`PaintedArt`): `altar` — partilhada com `consecrated_altar` | 1 imagem; estados por codigo |
| `mount_stable` | 1 |  | pintada (`PaintedArt`): `stable` — partilhada com `cow_stable` | 1 imagem; estados por codigo |
| `farm` | 1 | sim | pintada (`PaintedArt`): `farm` | 1 imagem; estados por codigo |
| `fishery` | 1 | sim | pintada (`PaintedArt`): `fishery` | 1 imagem; estados por codigo |
| `henhouse` | 1 | sim | pintada (`PaintedArt`): `henhouse` | 1 imagem; estados por codigo |
| `cow_stable` | 6 |  | pintada (`PaintedArt`): `stable` — partilhada com `mount_stable` | 1 imagem; estados por codigo |
| `lumber_camp` | 6 |  | pintada (`PaintedArt`): `lumber` — partilhada com `sawmill` | 1 imagem; estados por codigo |
| `ore_pit` | 1 | sim | pintada (`PaintedArt`): `mine` | 1 imagem; estados por codigo |
| `granary` | 2 | sim | `royal_granary` — partilhada com `saltery` | 1 frame; estados por codigo |
| `saltery` | 6 |  | `royal_granary` — partilhada com `granary` | 1 frame; estados por codigo |
| `pen` | 6 |  | `storehouse` | 1 frame; estados por codigo |
| `sawmill` | 6 |  | pintada (`PaintedArt`): `lumber` — partilhada com `lumber_camp` | 1 imagem; estados por codigo |
| `smelter` | 6 |  | pintada (`PaintedArt`): `furnace` | 1 imagem; estados por codigo |
| `archer_tower` | 1 | sim | pintada (`PaintedArt`): `archer_tower` | 1 imagem; estados por codigo |
| `high_tower` | 1 | sim | pintada (`PaintedArt`): `high_tower` | 1 imagem; estados por codigo |
| `fire_barrel` | 1 |  | pintada (`PaintedArt`): `barrel` | 1 imagem; estados por codigo |
| `root_moat` | 6 |  | pintada (`PaintedArt`): `spikes` | 1 imagem; estados por codigo |
| `lighthouse` | 6 |  | procedural (`HearthArt`) | por codigo |
| `consecrated_altar` | 6 |  | pintada (`PaintedArt`): `altar` — partilhada com `root_sanctuary` | 1 imagem; estados por codigo |
| `passage_seal` | 1 | sim | pintada (`PaintedArt`): `seal` | 1 imagem; estados por codigo |
| `campfire` | 1 |  | procedural (`HearthArt`) | por codigo |
| `tender_ward` | 1 |  | pintada (`PaintedArt`): `bell` | 1 imagem; estados por codigo |
| `bow_rack` | 1 |  | pintada (`PaintedArt`): `bow_rack` | 1 imagem; estados por codigo |
| `citizen_house` | 1 |  | pintada (`PaintedArt`): `cottage` | 1 imagem; estados por codigo |
| `enramados_house` | 1 |  | pintada (`NativeSprites`): `native_enramados_house` | 1 imagem; estados por codigo |
| `enramados_work` | 1 |  | pintada (`NativeSprites`): `native_enramados_work` | 1 imagem; estados por codigo |
| `enramados_defense` | 1 |  | pintada (`NativeSprites`): `native_enramados_defense` | 1 imagem; estados por codigo |
| `portuarios_house` | 1 |  | pintada (`NativeSprites`): `native_portuarios_house` | 1 imagem; estados por codigo |
| `portuarios_work` | 1 |  | pintada (`NativeSprites`): `native_portuarios_work` | 1 imagem; estados por codigo |
| `portuarios_defense` | 1 |  | pintada (`NativeSprites`): `native_portuarios_defense` | 1 imagem; estados por codigo |
| `fenda_house` | 1 |  | pintada (`NativeSprites`): `native_fenda_house` | 1 imagem; estados por codigo |
| `fenda_work` | 1 |  | pintada (`NativeSprites`): `native_fenda_work` | 1 imagem; estados por codigo |
| `fenda_defense` | 1 |  | pintada (`NativeSprites`): `native_fenda_defense` | 1 imagem; estados por codigo |
| `horta_house` | 1 |  | pintada (`NativeSprites`): `native_horta_house` | 1 imagem; estados por codigo |
| `horta_work` | 1 |  | pintada (`NativeSprites`): `native_horta_work` | 1 imagem; estados por codigo |
| `horta_defense` | 1 |  | pintada (`NativeSprites`): `native_horta_defense` | 1 imagem; estados por codigo |
| `fornalha_house` | 1 |  | pintada (`NativeSprites`): `native_fornalha_house` | 1 imagem; estados por codigo |
| `fornalha_work` | 1 |  | pintada (`NativeSprites`): `native_fornalha_work` | 1 imagem; estados por codigo |
| `fornalha_defense` | 1 |  | pintada (`NativeSprites`): `native_fornalha_defense` | 1 imagem; estados por codigo |
| `sobraiz_house` | 1 |  | pintada (`NativeSprites`): `native_sobraiz_house` | 1 imagem; estados por codigo |
| `sobraiz_work` | 1 |  | pintada (`NativeSprites`): `native_sobraiz_work` | 1 imagem; estados por codigo |
| `sobraiz_defense` | 1 |  | pintada (`NativeSprites`): `native_sobraiz_defense` | 1 imagem; estados por codigo |
| `geada_house` | 1 |  | pintada (`NativeSprites`): `native_geada_house` | 1 imagem; estados por codigo |
| `geada_work` | 1 |  | pintada (`NativeSprites`): `native_geada_work` | 1 imagem; estados por codigo |
| `geada_defense` | 1 |  | pintada (`NativeSprites`): `native_geada_defense` | 1 imagem; estados por codigo |
| `bruma_house` | 1 |  | pintada (`NativeSprites`): `native_bruma_house` | 1 imagem; estados por codigo |
| `bruma_work` | 1 |  | pintada (`NativeSprites`): `native_bruma_work` | 1 imagem; estados por codigo |
| `bruma_defense` | 1 |  | pintada (`NativeSprites`): `native_bruma_defense` | 1 imagem; estados por codigo |
| `mercenary_house` | 1 |  | pintada (`NativeSprites`): `native_mercenary_house` | 1 imagem; estados por codigo |
| `mercenary_work` | 1 |  | pintada (`NativeSprites`): `native_mercenary_work` | 1 imagem; estados por codigo |
| `mercenary_defense` | 1 |  | pintada (`NativeSprites`): `native_mercenary_defense` | 1 imagem; estados por codigo |
| `hammer_rack` | 1 |  | pintada (`PaintedArt`): `hammer_rack` | 1 imagem; estados por codigo |
| `companion_post` | 1 |  | pela forma `ESTANDARTE`: `training_house` | 1 imagem; estados por codigo |
| `cellar_excavation` | 1 |  | pintada, pela forma `ABOBADA`: `manor` | 1 imagem; estados por codigo |
| `emissary_stand` | 1 |  | pela forma `ESTANDARTE`: `training_house` | 1 imagem; estados por codigo |

## Lacunas de arte do marco dos Enramados

O que o marco usa e ainda nao tem arte propria, accoes desenhadas ou aprovacao. "No marco" e o que o `Greybox` monta e quem se forma nas obras que ele monta.

**Unidades**

- `vagrant`: `royal_citizen` — emprestado; faltam `attack`, `die`, `hit`, `work`
- `monarch`: `royal_king` — emprestado; faltam `work`
- `squire`: `royal_squire` — emprestado; faltam `work`
- `builder`: `royal_smith` — emprestado; faltam `attack`, `die`, `hit`, `work`
- `cook`: `royal_cook` — emprestado; faltam `attack`, `die`, `hit`, `work`

**Obras**

- `core`: `royal_tree_castle`; 1 frame; estados por codigo
- `training_house`: `royal_training`; 1 frame; estados por codigo
- `kitchen`: `royal_kitchen`; 1 frame; estados por codigo
- `heir_house`: pintada (`PaintedArt`): `manor` — partilhada com `embassy`; 1 imagem; estados por codigo
- `farm`: pintada (`PaintedArt`): `farm`; 1 imagem; estados por codigo
- `fishery`: pintada (`PaintedArt`): `fishery`; 1 imagem; estados por codigo
- `henhouse`: pintada (`PaintedArt`): `henhouse`; 1 imagem; estados por codigo
- `ore_pit`: pintada (`PaintedArt`): `mine`; 1 imagem; estados por codigo
- `granary`: `royal_granary` — partilhada com `saltery`; 1 frame; estados por codigo
- `archer_tower`: pintada (`PaintedArt`): `archer_tower`; 1 imagem; estados por codigo
- `high_tower`: pintada (`PaintedArt`): `high_tower`; 1 imagem; estados por codigo
- `passage_seal`: pintada (`PaintedArt`): `seal`; 1 imagem; estados por codigo
- muralha (`walls.csv`, 5 niveis): pintada (`WallSprites`): `wall_1`, `wall_2`, `wall_3`, `wall_4`, `wall_5`; 1 imagem por nivel, estados por codigo

**Exportacoes**

- Sem chamada em runtime: `cook`, `far_keep`, `gate`, `knight`, `monarch`, `oak`, `training_house`, `tree_castle`, `vagrant`, `workshop`.
- Estados de aprovacao presentes: `author_base_needs_refinement`, `derived_temporary`, `near_complete_reference`, `redesign_required`. Nenhuma exportacao esta aprovada.


## Assets gratuitos temporarios

Proxies para gameplay, autorizados pelo dono (ADR 0042). Fontes preservadas em `art/source/temporary/`; licencas, autores e alteracoes em `art/export/temporary/CREDITS.txt`. Nao sao arte definitiva nem aprovacao dos originais.

| Perfil | Frame exportado | Escala inteira | Tags |
|---|---|---:|---|
| `temp_archer` | 117x80 | 1 | `idle`, `walk`, `attack`, `hit`, `die` |
| `temp_archer_hero` | 132x90 | 2 | `idle`, `walk`, `attack`, `hit`, `die` |
| `temp_brute` | 142x90 | 2 | `idle`, `walk`, `attack`, `hit`, `die` |
| `temp_burrower` | 98x59 | 1 | `idle`, `walk`, `attack`, `hit`, `die` |
| `temp_cave` | 32x32 | 2 | — |
| `temp_crate` | 36x36 | 2 | — |
| `temp_crawler` | 88x46 | 1 | `idle`, `walk`, `attack`, `hit`, `die` |
| `temp_fence` | 36x36 | 2 | — |
| `temp_flag` | 36x36 | 2 | — |
| `temp_forest_back` | 544x320 | 2 | — |
| `temp_forest_middle` | 544x320 | 2 | — |
| `temp_lever` | 36x36 | 2 | — |
| `temp_mushroom` | 36x36 | 2 | — |
| `temp_plant` | 36x36 | 2 | — |
| `temp_sign` | 36x36 | 2 | — |
| `temp_soil` | 32x32 | 2 | — |
| `temp_spearman` | 93x57 | 3 | `idle`, `walk`, `attack`, `die` |
| `temp_stone` | 36x36 | 2 | — |
| `temp_winged` | 56x41 | 1 | `idle`, `walk`, `attack`, `hit`, `die` |
| `temp_wood` | 36x36 | 2 | — |

Atores: OriginalArt/UnitArtBatch. Criaturas: Bestiary/CreatureView (ADR 0049; os sprites temporarios de criatura ficam no export, fora de uso). Cenario e props: TemporaryScenery/EnramadosLayer/RootCellars/BuildView.


## Renovacao visual — direcao confirmada em 05/10/2026

Fontes integrais: `art/source/renewal/`. Export deterministico: `tools/export_renewal.py`. Referencias, aprovacoes e limites: `docs/art/ART_DIRECTION_2026-10-05.md` (ADR 0075).

| Perfil | Tamanho do frame | Frames | Accoes |
|---|---|---:|---|
| `royal_archer` | 192 x 192 | 4 | idle, walk, flee |
| `royal_bard` | 192 x 192 | 4 | idle, walk, flee |
| `royal_bowman` | 192 x 192 | 4 | idle, walk, flee |
| `royal_brute` | 192 x 192 | 4 | idle, walk, flee |
| `royal_burrower` | 192 x 192 | 4 | idle, walk, flee |
| `royal_bush` | 80 x 50 | 1 | idle |
| `royal_cart` | 166 x 134 | 1 | idle |
| `royal_citizen` | 192 x 192 | 4 | idle, walk, flee |
| `royal_cook` | 192 x 192 | 4 | idle, walk, flee |
| `royal_crawler` | 192 x 192 | 4 | idle, walk, flee |
| `royal_devourer` | 192 x 192 | 4 | idle, walk, flee |
| `royal_encampment` | 186 x 100 | 1 | idle |
| `royal_forge` | 216 x 168 | 1 | idle |
| `royal_granary` | 180 x 152 | 1 | idle |
| `royal_hall` | 240 x 192 | 1 | idle |
| `royal_hamlet` | 254 x 132 | 1 | idle |
| `royal_keep` | 308 x 272 | 1 | idle |
| `royal_king` | 192 x 192 | 4 | idle, walk, flee |
| `royal_kitchen` | 194 x 184 | 1 | idle |
| `royal_knight` | 192 x 192 | 4 | idle, walk, flee |
| `royal_meadow` | 60 x 28 | 1 | idle |
| `royal_nia` | 192 x 192 | 4 | idle, walk, flee |
| `royal_oak` | 326 x 316 | 1 | idle |
| `royal_pine` | 152 x 196 | 1 | idle |
| `royal_quiver` | 192 x 192 | 4 | idle, walk, flee |
| `royal_ram` | 192 x 192 | 4 | idle, walk, flee |
| `royal_smith` | 192 x 192 | 4 | idle, walk, flee |
| `royal_spearman` | 192 x 192 | 4 | idle, walk, flee |
| `royal_squire` | 192 x 192 | 4 | idle, walk, flee |
| `royal_tender` | 192 x 192 | 4 | idle, walk, flee |
| `royal_training` | 220 x 172 | 1 | idle |
| `royal_tree_castle` | 522 x 348 | 1 | idle |
| `royal_tree_coast_pine` | 202 x 184 | 1 | idle |
| `royal_tree_coast_pine_bare` | 202 x 184 | 1 | idle |
| `royal_tree_oak` | 200 x 184 | 1 | idle |
| `royal_tree_oak_bare` | 196 x 184 | 1 | idle |
| `royal_tree_roots` | 190 x 184 | 1 | idle |
| `royal_tree_roots_bare` | 190 x 184 | 1 | idle |
| `royal_tree_willow` | 196 x 184 | 1 | idle |
| `royal_tree_willow_bare` | 192 x 184 | 1 | idle |
| `royal_village` | 288 x 190 | 1 | idle |
| `royal_walled` | 352 x 220 | 1 | idle |
| `royal_winged` | 192 x 192 | 4 | idle, walk, flee |

Os ataques, golpes recebidos e quedas usam poses do combate. Caminhadas com quatro frames; nao se declaram ciclos de ataque completos. Edificios conservam estados de pagamento, construcao, reparacao e ruina. Todas as especies da Podridao usam sprites desta familia e olhos emissivos.


## Elenco V15 — pedido de integração de 19/10/2026

Fonte editável: `art/source/royals_v15/`. Importação fiel: `tools/export_royals.py`.
Os seis membros das duplas iniciais são usados no seletor e no mundo. O Cavaleiro Enterrado usa a aparência do Sombra; a Bailarina e a sequência de floração estão disponíveis na galeria dentro do jogo. Não há quarto par de gameplay definido (CV-05).

| Perfil | Tela | Entradas (incluindo espelhos) | Ações |
|---|---|---:|---|
| `royal_archer` | 80 × 80 | 112 | idle, walk, hit, die, rise, shoot |
| `royal_bard` | 64 × 64 | 96 | idle, walk, hit, die, rise, play |
| `royal_dancer` | 64 × 64 | 96 | idle, walk, hit, die, rise, dance |
| `royal_king` | 80 × 80 | 96 | idle, walk, hit, die, rise, attack |
| `royal_nia` | 64 × 64 | 96 | idle, walk, hit, die, rise, attack |
| `royal_quiver` | 64 × 64 | 114 | idle, walk, hit, die, rise, deliver, receive |
| `royal_shadow` | 80 × 80 | 112 | idle, walk, hit, die, rise, sit, heal, stand |
| `royal_squire` | 64 × 64 | 100 | idle, walk, hit, die, rise, block, block_hold |

Pivôs por direção, tempos variáveis e marcadores preservados. Os marcadores não aplicam dano, cura, moedas ou projéteis; a simulação mantém essa autoridade.


## Cenarios em camadas — entrega de 08/10/2026

Os ZIPs do dono, lidos por `tools/export_scenery.py` (hashes de cada pacote conferidos com o `catalogo.json`); o export e as mesmas camadas recortadas ao alfa, sem reamostrar. Mapa e regras: ADR 0081. Chamada em runtime: `SceneryArt`, `SceneryPlane` (fundo, em parallax) e `SceneryStrip` (chao e terra, no mundo).

| Cena | Tipo | Bioma ou fronteira | Quadro | Camadas |
|---|---|---|---|---|
| `ancient_forest` (Enramados) | kingdom | `ancient_forest` | 2560 x 720 | sky, clouds, far, mid, near, under, terrain, foreground |
| `arriba_estratos` (Arriba dos Estratos) | transition | `coast → canyon` | 1280 x 720 | under, terrain, water, foreground, landmark |
| `boca_fenda` (Boca da Fenda) | transition | `floodplain → canyon` | 1280 x 720 | under, terrain, water, foreground, landmark |
| `canyon` (Fenda) | kingdom | `canyon` | 2560 x 720 | sky, clouds, far, mid, near, under, terrain, foreground |
| `cicatriz_basalto` (Cicatriz de Basalto) | transition | `canyon → volcanic` | 1280 x 720 | under, terrain, foreground, landmark |
| `cinzas_vivas` (Bosque das Cinzas Vivas) | transition | `ancient_forest → volcanic` | 1280 x 720 | under, terrain, foreground, landmark |
| `coast` (Portuarios) | kingdom | `coast` | 2560 x 720 | sky, clouds, far, mid, near, under, terrain, water, foreground |
| `floodplain` (Horta) | kingdom | `floodplain` | 2560 x 720 | sky, clouds, far, mid, near, under, terrain, water, foreground |
| `galeria_exposta` (Galeria Exposta) | transition | `canyon → subterranean` | 1280 x 720 | under, terrain, foreground, landmark |
| `glacier` (Geada) | kingdom | `glacier` | 2560 x 720 | sky, clouds, far, mid, near, under, terrain, water, foreground |
| `limiar_raizes` (Limiar das Raízes) | transition | `ancient_forest → subterranean` | 1280 x 720 | under, terrain, foreground, landmark |
| `limite_bosques` (Limite dos Bosques) | transition | `ancient_forest → glacier` | 1280 x 720 | under, terrain, water, foreground, landmark |
| `marisma_estuario` (Marisma do Estuário) | transition | `marsh → floodplain` | 1280 x 720 | under, terrain, water, foreground, landmark |
| `marisma_horta_coast` (Marisma do Estuário — Horta → Portuários) | transition | `floodplain → coast` | 1280 x 720 | under, terrain, water, foreground, landmark |
| `marsh` (Bruma) | kingdom | `marsh` | 2560 x 720 | sky, clouds, far, mid, near, under, terrain, water, foreground |
| `mata_encharcada` (Mata Encharcada) | transition | `ancient_forest → marsh` | 1280 x 720 | under, terrain, water, foreground, landmark |
| `mata_mare` (Mata da Maré) | transition | `ancient_forest → coast` | 1280 x 720 | under, terrain, water, foreground, landmark |
| `neve_negra` (Linha da Neve Negra) | transition | `volcanic → glacier` | 1280 x 720 | under, terrain, water, foreground, landmark |
| `orla_campos` (Orla dos Campos) | transition | `ancient_forest → floodplain` | 1280 x 720 | under, terrain, water, foreground, landmark |
| `subterranean` (SobRaiz) | kingdom | `subterranean` | 2560 x 720 | sky, clouds, far, mid, near, under, terrain, foreground |
| `volcanic` (Caldeira) | kingdom | `volcanic` | 2560 x 720 | sky, clouds, far, mid, near, under, terrain, foreground |

Propostas por colocar no mundo, fora do export: Reino-Fluvial (`reino_fluvial`), Porto-Central (`porto_central`), Lago-Ponte-Cais (`lago_ponte`) (Q-259). Edificios, escadas, atividades de baixo e atores de referencia ficam nos pacotes: o que se constroi e onde ha passagem decide-o a simulacao.


## Producao nativa — 16/10/2026 (ADR 0084)

Os planos naturais abaixo substituem os planos homonimos da entrega anterior pela chamada NativeSceneryCatalog.patch_legacy em SceneryArt. O terreno da campanha continua associado aos sitios e passagens da simulacao. A galeria tools/native_scenery_review.tscn monta as camadas funcionais e as construcoes fora do parallax.

| Familia | Uso | Camadas nativas | Fonte editavel |
|---|---|---|---|
| Enramados (enramados) | campanha: planos naturais; prefab completo | far, mid, near, under, terrain, crossings, structures, props, foreground, water_back, water, sky, clouds | art/export/scenery_native/enramados/layers.ora |
| Bruma (bruma) | campanha: planos naturais; prefab completo | far, mid, near, under, terrain, crossings, structures, props, foreground, water_back, water, sky, clouds | art/export/scenery_native/bruma/layers.ora |
| Horta (horta) | campanha: planos naturais; prefab completo | far, mid, near, under, terrain, crossings, structures, props, foreground, water_back, water, sky, clouds | art/export/scenery_native/horta/layers.ora |
| Portuários (portuarios) | campanha: planos naturais; prefab completo | far, mid, near, under, terrain, crossings, structures, props, foreground, water_back, water, sky, clouds | art/export/scenery_native/portuarios/layers.ora |
| Fenda (fenda) | campanha: planos naturais; prefab completo | far, mid, near, under, terrain, crossings, structures, props, foreground, water_back, water, sky, clouds | art/export/scenery_native/fenda/layers.ora |
| Fornalha (fornalha) | campanha: planos naturais; prefab completo | far, mid, near, under, terrain, crossings, structures, props, foreground, water_back, water, sky, clouds | art/export/scenery_native/fornalha/layers.ora |
| Geada (geada) | campanha: planos naturais; prefab completo | far, mid, near, under, terrain, crossings, structures, props, foreground, water_back, water, sky, clouds | art/export/scenery_native/geada/layers.ora |
| SobRaiz (sobraiz) | campanha: planos naturais; prefab completo | far, mid, near, under, terrain, crossings, structures, props, foreground, water_back, water, sky, clouds | art/export/scenery_native/sobraiz/layers.ora |
| Porto Central (porto) | prefab completo; colocacao de campanha por decidir | far, mid, near, under, terrain, crossings, structures, props, foreground, water_back, water, sky, clouds | art/export/scenery_native/porto/layers.ora |
| Lago das Ruínas (lago) | prefab completo; colocacao de campanha por decidir | far, mid, near, under, terrain, crossings, structures, props, foreground, water_back, water, sky, clouds | art/export/scenery_native/lago/layers.ora |
| Rio das Azenhas (rio) | prefab completo; colocacao de campanha por decidir | far, mid, near, under, terrain, crossings, structures, props, foreground, water_back, water, sky, clouds | art/export/scenery_native/rio/layers.ora |
| Enramados → Bruma (enramados_bruma) | prefab completo; colocacao de campanha por decidir | far, mid, near, under, terrain, crossings, structures, props, foreground, water_back, water, sky, clouds | art/export/scenery_native/enramados_bruma/layers.ora |
| Fenda → Geada (fenda_geada) | prefab completo; colocacao de campanha por decidir | far, mid, near, under, terrain, crossings, structures, props, foreground, water_back, water, sky, clouds | art/export/scenery_native/fenda_geada/layers.ora |

Catalogo: 13 familias, 24 cenas. Módulos de 64 px, PNGs recortados ao alfa, export nearest de 2/4 px, paleta limitada sem dithering. Validacao executada: docs/art/scenery_native_validation.json; guia: docs/art/NATIVE_SCENERY.md.


## As composicoes do dono — 15 e 16/10/2026 (ADR 0086)

As pinturas dos dois ZIPs, separadas em planos por `tools/owner_scenery/` e exportadas por `tools/export_owner_scenery.py` (cada origem conferida contra o ZIP). Substituem os planos e o chao dos reinos pela chamada OwnerScenery.patch em SceneryArt; as variantes trocam-se pela hora e pela estacao (OwnerScenery.weights) e os sitios ficam na agua do territorio (OwnerSites).

| Vista | Uso | Origem | Camadas |
|---|---|---|---|
| `bruma_base` | reino `marsh` | `01_reinos/03-bruma_base.png` | sky, clouds, far, mid, near, under, terrain |
| `bruma_nevoa` | variante de `marsh` (dawn) | `01_reinos/04-bruma_nevoa.png` | sky, clouds, far, mid, near, under, terrain |
| `enramados_base` | reino `ancient_forest` | `01_reinos/01-enramados_base.png` | sky, clouds, far, mid, near, under, terrain |
| `enramados_bruma` | transicao `mata_encharcada` (ancient_forest → marsh) | `03_transicoes/23-enramados_bruma.png` | sky, clouds, far, mid, near, under, terrain, landmark |
| `enramados_lua` | variante de `ancient_forest` (night) | `01_reinos/02-enramados_lua.png` | sky, clouds, far, mid, near, under, terrain |
| `fenda_base` | reino `canyon` | `01_reinos/09-fenda_base.png` | sky, clouds, far, mid, near, under, terrain |
| `fenda_geada` | transicao `fenda_geada` (canyon → glacier) | `03_transicoes/24-fenda_geada.png` | sky, clouds, far, mid, near, under, terrain, landmark |
| `fenda_luar` | variante de `canyon` (night) | `01_reinos/10-fenda_luar.png` | sky, clouds, far, mid, near, under, terrain |
| `fornalha_base` | reino `volcanic` | `01_reinos/11-fornalha_base.png` | sky, clouds, far, mid, near, under, terrain |
| `fornalha_brasas` | variante de `volcanic` (dusk, night) | `01_reinos/12-fornalha_brasas.png` | sky, clouds, far, mid, near, under, terrain |
| `geada_aurora` | variante de `glacier` (night) | `01_reinos/14-geada_aurora.png` | sky, clouds, far, mid, near, under, terrain |
| `geada_base` | reino `glacier` | `01_reinos/13-geada_base.png` | sky, clouds, far, mid, near, under, terrain |
| `horta_base` | reino `floodplain` | `01_reinos/05-horta_base.png` | sky, clouds, far, mid, near, under, terrain |
| `horta_colheita` | variante de `floodplain` (autumn) | `01_reinos/06-horta_colheita.png` | sky, clouds, far, mid, near, under, terrain |
| `lago_base` | sitio de agua de `ancient_forest` | `04_referencias_aprovadas/lago-aprovado-2026-10-15.png` | sky, clouds, far, mid, near, under, terrain |
| `lago_geada` | variante do sitio de `ancient_forest` (winter) | `02_agua/20-lago_geada.png` | sky, clouds, far, mid, near, under, terrain |
| `lago_outono` | variante do sitio de `ancient_forest` (autumn) | `02_agua/19-lago_outono.png` | sky, clouds, far, mid, near, under, terrain |
| `porto_base` | sitio de agua de `coast` | `04_referencias_aprovadas/porto-aprovado-2026-10-15.png` | sky, clouds, far, mid, near, under, terrain |
| `porto_crepusculo` | variante do sitio de `coast` (dusk) | `02_agua/17-porto_crepusculo.png` | sky, clouds, far, mid, near, under, terrain |
| `porto_noite` | variante do sitio de `coast` (night) | `02_agua/18-porto_noite.png` | sky, clouds, far, mid, near, under, terrain |
| `portuarios_base` | reino `coast` | `01_reinos/07-portuarios_base.png` | sky, clouds, far, mid, near, under, terrain |
| `portuarios_mare_baixa` | variante de `coast` (afternoon) | `01_reinos/08-portuarios_mare_baixa.png` | sky, clouds, far, mid, near, under, terrain |
| `rio_base` | sitio de agua de `marsh` | `04_referencias_aprovadas/rio-aprovado-2026-10-15.png` | sky, clouds, far, mid, near, under, terrain |
| `rio_chuva` | variante do sitio de `marsh` (spring) | `02_agua/21-rio_chuva.png` | sky, clouds, far, mid, near, under, terrain |
| `rio_luar` | variante do sitio de `marsh` (night) | `02_agua/22-rio_luar.png` | sky, clouds, far, mid, near, under, terrain |
| `sobraiz_base` | reino `subterranean` | `01_reinos/15-sobraiz_base.png` | sky, clouds, far, mid, near, under, terrain |
| `sobraiz_umida` | variante de `subterranean` (dusk) | `01_reinos/16-sobraiz_umida.png` | sky, clouds, far, mid, near, under, terrain |


## Animais e criaturas animados — entrega de 14/10/2026

Os dois ZIPs do dono, lidos por `tools/export_animated.py` (cada ficheiro conferido com as somas do proprio pacote); a folha da direita e a mesma, byte a byte, e o export junta-lhe a mascara branca e, nas criaturas, o que brilha no escuro. Regras: ADR 0083. Quadros de 64 x 64, as criaturas a escala inteira mais perto do porte do `Bestiary`; os animais a escala do porte que o dono lhes deu (os pequenos um pouco abaixo das tropas, as montarias das tropas um pouco acima, as dos imperadores acima do rei; `AnimatedArt.ESCALA`, Q-264).

| Export | Pacote | Quadros | Accoes | Quem o desenha |
|---|---|---|---|---|
| `animal_boar` | Javali (`javali`) | 42 | idle, walk, run, root, threat, lie_down | caca `boar` (`HuntView`, `HuntPoses`) |
| `animal_cow` | Vaca (`vaca`) | 42 | idle, walk, run, graze, startle, collapse | obra `cow_stable` (`FarmAnimals`) |
| `animal_deer` | Cervo castanho (`cervo_castanho`) | 42 | idle, walk, run, graze, startle, lie_down | caca `deer` (`HuntView`, `HuntPoses`) |
| `animal_draft_horse` | Cavalo (`cavalo`) | 42 | idle, walk, run, graze, rear, collapse | montaria `draft_horse` (`MountView`) |
| `animal_fox` | Raposa (`raposa`) | 40 | idle, walk, run, groom, pounce, lie_down | caca `fox` (`HuntView`, `HuntPoses`) |
| `animal_hen` | Galinha (`galinha`) | 42 | idle, walk, run, peck, flap, collapse | obra `henhouse` (`FarmAnimals`) |
| `animal_peacock` | Pavão (`pavao`) | 42 | idle, walk, run, preen, display, lie_down | caca `pheasant` (`HuntView`, `HuntPoses`) |
| `animal_rabbit` | Coelho (`coelho`) | 41 | idle, walk, run, nibble, alert, collapse | caca `rabbit` (`HuntView`, `HuntPoses`) |
| `animal_rooster` | Galo (`galo`) | 42 | idle, walk, run, peck, crow, collapse | obra `henhouse` (`FarmAnimals`) |
| `animal_white_stag` | Cervo branco (`cervo_branco`) | 42 | idle, walk, run, graze, bellow, lie_down | caca `white_stag` (`HuntView`, `HuntPoses`) |
| `beast_brute` | Bruto (`bruto`) | 32 | idle, walk, attack, hit, die, spawn, roar, flee | criatura `BRUTO` (`CreatureView`, `AnimatedBeasts`) |
| `beast_burrower` | Cavador (`cavador`) | 32 | idle, walk, attack, hit, die, spawn, dig, alert | criatura `BROCA` (`CreatureView`, `AnimatedBeasts`) |
| `beast_crawler` | Rastejante (`rastejante`) | 32 | idle, walk, attack, hit, die, spawn, pounce, alert | criatura `RASTEJO` (`CreatureView`, `AnimatedBeasts`) |
| `beast_devourer` | Consumidora (`consumidora`) | 32 | idle, walk, attack, hit, die, spawn, grab, roar | criatura `COLOSSO` (`CreatureView`, `AnimatedBeasts`) |
| `beast_slime_ram` | Aríete de raízes (`ariete`) | 32 | idle, walk, attack, hit, die, spawn, charge, alert | criatura `ARIETE` (`CreatureView`, `AnimatedBeasts`) |
| `beast_tender` | Zelador (`zelador`) | 28 | idle, walk, hit, die, spawn, tend, flee | criatura `ZELADOR` (`CreatureView`, `AnimatedBeasts`); a voz da Podridao (`OfferView`) |
| `beast_winged` | Alado de folhas (`alado`) | 32 | idle, fly, attack, hit, die, spawn, steal, flee | criatura `ASA` (`CreatureView`, `AnimatedBeasts`) |

Ficam nos pacotes, sem lugar no jogo ainda: Búfalo (`bufalo`), Carneiro (`carneiro`), Saqueador de raízes (`saqueador`) (Q-263).
