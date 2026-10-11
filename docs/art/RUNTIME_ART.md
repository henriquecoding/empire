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
| `monarch` | 1 | sim | `royal_king` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `squire` | 1 | sim | `royal_squire` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `builder` | 1 | sim | `royal_smith` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `smith` | 2 |  | `royal_smith` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `cook` | 2 | sim | `royal_cook` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `diplomat` | 6 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `bard` | 6 |  | `royal_bard` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `climber` | 6 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `buried_knight` | 6 |  | `royal_knight` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `sealed_knight` | 6 |  | `royal_knight` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `archer_hero` | 1 |  | `royal_archer` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `bard_hero` | 6 |  | `royal_bard` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `diplomat_hero` | 6 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `canopy_archer` | 2 |  | `royal_bowman` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `barge` | 7 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `counterweight_ram` | 7 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `sower` | 7 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `war_smith` | 7 |  | `royal_smith` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `digger` | 7 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `ice_warden` | 7 |  | `royal_spearman` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `reed_stalker` | 7 |  | `royal_bowman` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `nia` | 1 |  | `royal_nia` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `archer_emperor` | 1 |  | `royal_archer` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `bard_banner` | 1 |  | `royal_bard` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |
| `quiver_squire` | 1 |  | `royal_quiver` — emprestado | `flee`, `idle`, `walk` | `attack`, `die`, `hit`, `work` |

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
- `monarch`: `royal_king` — emprestado; faltam `attack`, `die`, `hit`, `work`
- `squire`: `royal_squire` — emprestado; faltam `attack`, `die`, `hit`, `work`
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
