# Arte em runtime — o que o jogo desenha com os originais

<!-- gerado por tools/inventario_arte.py — nao editar a mao -->

Lido do manifesto de `art/export/enramados/`, dos CSV e das funcoes que ligam dados a arte. Fonte, export, chamada em runtime, accoes e aprovacao sao colunas separadas: existir uma textura nao conclui nada. O `ASSET_REGISTER.csv` continua a ser o plano de producao e nao e alterado por isto (tem 2 linhas `IN_GAME`, que nao contam estas exportacoes).

Accoes do contrato (`src/actors/actor_action.gd`): `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work`. Uma accao sem tag no manifesto mostra o repouso (fugir mostra a caminhada, se existir).

## Exportacoes dos originais

| Export | Fonte | Frames | Tags (accoes) | Chamada em runtime | Quem a usa | Aprovacao |
|---|---|---:|---|---|---|---|
| `cook.png` | `art/source/originals/concept.aseprite` | 1 | — | `src/actors/unit_art_batch.gd` | unidade cook | `near_complete_reference` |
| `far_keep.png` | `art/source/originals/concept.aseprite` | 1 | — | `src/world/enramados_layer.gd` | — | `author_base_needs_refinement` |
| `gate.png` | `art/source/originals/concept.aseprite` | 1 | — | — | — | `author_base_needs_refinement` |
| `knight.png` | `art/source/originals/troop.aseprite` | 6 | `idle` | `src/actors/unit_art_batch.gd` | unidade buried_knight, unidade mercenary, unidade sealed_knight, unidade squire | `near_complete_reference` |
| `monarch.png` | `art/source/originals/concept.aseprite` | 1 | — | `src/actors/unit_art_batch.gd` | unidade monarch | `redesign_required` |
| `oak.png` | `art/source/originals/concept.aseprite` | 1 | — | `src/world/enramados_layer.gd` | — | `author_base_needs_refinement` |
| `storehouse.png` | `art/source/originals/concept.aseprite` | 1 | — | `src/world/building_skins.gd` | obra granary, obra pen, obra saltery | `author_base_needs_refinement` |
| `training_house.png` | `art/source/originals/concept.aseprite` | 1 | — | `src/world/building_skins.gd` | obra training_house | `author_base_needs_refinement` |
| `tree_castle.png` | `art/source/originals/concept.aseprite` | 1 | — | `src/world/building_skins.gd` | obra core | `author_base_needs_refinement` |
| `vagrant.png` | `art/source/originals/troop.aseprite` | 6 | `idle` | `src/actors/unit_art_batch.gd` | unidade archer, unidade builder, unidade canopy_archer, unidade spearman, unidade vagrant | `derived_temporary` |
| `workshop.png` | `art/source/originals/concept.aseprite` | 1 | — | `src/world/building_skins.gd` | obra forge, obra kitchen | `author_base_needs_refinement` |

## Unidades

| Unidade | Fase | No marco | Arte | Accoes desenhadas | Accoes em falta |
|---|---:|---|---|---|---|
| `vagrant` | 1 | sim | `vagrant` | `idle` | `attack`, `die`, `flee`, `hit`, `walk`, `work` |
| `archer` | 1 | sim | `vagrant` — emprestado | `idle` | `attack`, `die`, `flee`, `hit`, `walk`, `work` |
| `spearman` | 1 | sim | `vagrant` — emprestado | `idle` | `attack`, `die`, `flee`, `hit`, `walk`, `work` |
| `dragonfly` | 2 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `root_berserker` | 2 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `mercenary` | 6 |  | `knight` — emprestado | `idle` | `attack`, `die`, `flee`, `hit`, `walk`, `work` |
| `monarch` | 1 | sim | `monarch` | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `squire` | 1 | sim | `knight` — emprestado | `idle` | `attack`, `die`, `flee`, `hit`, `walk`, `work` |
| `builder` | 1 | sim | `vagrant` — emprestado | `idle` | `attack`, `die`, `flee`, `hit`, `walk`, `work` |
| `smith` | 2 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `cook` | 2 | sim | `cook` | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `diplomat` | 6 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `bard` | 6 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `climber` | 6 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `buried_knight` | 6 |  | `knight` — emprestado | `idle` | `attack`, `die`, `flee`, `hit`, `walk`, `work` |
| `sealed_knight` | 6 |  | `knight` — emprestado | `idle` | `attack`, `die`, `flee`, `hit`, `walk`, `work` |
| `canopy_archer` | 2 |  | `vagrant` — emprestado | `idle` | `attack`, `die`, `flee`, `hit`, `walk`, `work` |
| `barge` | 7 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `counterweight_ram` | 7 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `sower` | 7 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `war_smith` | 7 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |
| `digger` | 7 |  | procedural (`ActorArt`) | — | `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work` |

## Obras

| Obra | Fase | No marco | Arte | Estados |
|---|---:|---|---|---|
| `core` | 1 | sim | `tree_castle` | 1 frame; estados por codigo |
| `training_house` | 1 | sim | `training_house` | 1 frame; estados por codigo |
| `forge` | 2 |  | `workshop` — partilhada com `kitchen` | 1 frame; estados por codigo |
| `kitchen` | 2 | sim | `workshop` — partilhada com `forge` | 1 frame; estados por codigo |
| `embassy` | 6 |  | procedural (`Silhouette`/`StructureArt`) | por codigo |
| `heir_house` | 6 |  | procedural (`Silhouette`/`StructureArt`) | por codigo |
| `root_sanctuary` | 6 |  | procedural (`Silhouette`/`StructureArt`) | por codigo |
| `mount_stable` | 6 |  | procedural (`Silhouette`/`StructureArt`) | por codigo |
| `farm` | 1 | sim | procedural (`SettlementArt`) | por codigo |
| `fishery` | 1 | sim | procedural (`SettlementArt`) | por codigo |
| `henhouse` | 1 | sim | procedural (`SettlementArt`) | por codigo |
| `cow_stable` | 6 |  | procedural (`Silhouette`/`StructureArt`) | por codigo |
| `lumber_camp` | 6 |  | procedural (`Silhouette`/`StructureArt`) | por codigo |
| `ore_pit` | 6 |  | procedural (`Silhouette`/`StructureArt`) | por codigo |
| `granary` | 2 | sim | `storehouse` — partilhada com `pen`, `saltery` | 1 frame; estados por codigo |
| `saltery` | 6 |  | `storehouse` — partilhada com `granary`, `pen` | 1 frame; estados por codigo |
| `pen` | 6 |  | `storehouse` — partilhada com `granary`, `saltery` | 1 frame; estados por codigo |
| `sawmill` | 6 |  | procedural (`Silhouette`/`StructureArt`) | por codigo |
| `smelter` | 6 |  | procedural (`Silhouette`/`StructureArt`) | por codigo |
| `archer_tower` | 1 | sim | procedural (`Silhouette`/`StructureArt`) | por codigo |
| `high_tower` | 1 | sim | procedural (`Silhouette`/`StructureArt`) | por codigo |
| `fire_barrel` | 1 |  | procedural (`Silhouette`/`StructureArt`) | por codigo |
| `root_moat` | 6 |  | procedural (`Silhouette`/`StructureArt`) | por codigo |
| `lighthouse` | 6 |  | procedural (`Silhouette`/`StructureArt`) | por codigo |
| `consecrated_altar` | 6 |  | procedural (`Silhouette`/`StructureArt`) | por codigo |

## Lacunas de arte do marco dos Enramados

O que o marco usa e ainda nao tem arte propria, accoes desenhadas ou aprovacao. "No marco" e o que o `Greybox` monta e quem se forma nas obras que ele monta.

**Unidades**

- `vagrant`: `vagrant`; faltam `attack`, `die`, `flee`, `hit`, `walk`, `work`
- `archer`: `vagrant` — emprestado; faltam `attack`, `die`, `flee`, `hit`, `walk`, `work`
- `spearman`: `vagrant` — emprestado; faltam `attack`, `die`, `flee`, `hit`, `walk`, `work`
- `monarch`: `monarch`; faltam `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work`
- `squire`: `knight` — emprestado; faltam `attack`, `die`, `flee`, `hit`, `walk`, `work`
- `builder`: `vagrant` — emprestado; faltam `attack`, `die`, `flee`, `hit`, `walk`, `work`
- `cook`: `cook`; faltam `attack`, `die`, `flee`, `hit`, `idle`, `walk`, `work`

**Obras**

- `core`: `tree_castle`; 1 frame; estados por codigo
- `training_house`: `training_house`; 1 frame; estados por codigo
- `kitchen`: `workshop` — partilhada com `forge`; 1 frame; estados por codigo
- `farm`: procedural (`SettlementArt`); por codigo
- `fishery`: procedural (`SettlementArt`); por codigo
- `henhouse`: procedural (`SettlementArt`); por codigo
- `granary`: `storehouse` — partilhada com `pen`, `saltery`; 1 frame; estados por codigo
- `archer_tower`: procedural (`Silhouette`/`StructureArt`); por codigo
- `high_tower`: procedural (`Silhouette`/`StructureArt`); por codigo
- muralha (`walls.csv`, 5 niveis): procedural (`Silhouette`/`StructureArt`); por codigo

**Exportacoes**

- Sem chamada em runtime: `gate`.
- Estados de aprovacao presentes: `author_base_needs_refinement`, `derived_temporary`, `near_complete_reference`, `redesign_required`. Nenhuma exportacao esta aprovada.
