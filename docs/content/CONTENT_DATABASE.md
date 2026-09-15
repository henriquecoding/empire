# Base de dados de conteúdo

> **Regra:** alterar balanceamento nunca exige editar GDScript. Os números escrevem-se **uma vez**, num CSV de
> `data/source/`; tudo o resto — `.tres`, relatórios, testes — sai dele. (Dossiê §41, §44; invariante I4, §40.)

Este documento é o dicionário da base de dados: o que existe, como se lê, como se muda e o que trava os erros.
O esquema coluna a coluna está em [`SCHEMA.md`](SCHEMA.md), que é gerado; a lista de valores propostos está em
[`PROPOSALS.md`](PROPOSALS.md); a Podridão dia a dia está em [`ROT_BY_DAY.md`](ROT_BY_DAY.md).

## 1 · O circuito

```text
data/source/<tabela>.csv          ← editas aqui (folha de cálculo ou editor de texto)
        │  godot --headless --path . -s tools/csv_to_tres.gd
        ▼
data/<pasta>/<id>.tres            ← gerado e versionado (ADR 0004); nunca se edita à mão
        │  Registry (F0, §41) carrega por StringName
        ▼
src/sim/ — a simulação lê o Resource, nunca um número escrito no código
```

| Comando | O que faz |
|---|---|
| `godot --headless --path . -s tools/csv_to_tres.gd` | Gera todos os `.tres` e apaga os que já não têm linha no CSV |
| `godot --headless --path . -s tools/csv_to_tres.gd -- --check` | Não escreve nada: falha se algum `.tres` divergir do CSV (corre no CI) |
| `python3 tools/check_dossie_vs_csv.py` | Confere 193 números das tabelas do dossiê contra os CSV (corre no CI) |
| `python3 tools/content_report.py` | Regenera `SCHEMA.md`, `PROPOSALS.md` e `ROT_BY_DAY.md` (`--check` no CI) |
| `./run_tests.sh` | Inclui `tests/data_test.gd` (integridade) e `tests/design_data_test.gd` (portão G5) |

O registo das tabelas é `data/source/_tables.csv`: para cada tabela, o script do `Resource`, o caminho de saída
(`{id}` = uma linha por ficheiro) e o *layout* (`rows` = uma linha por recurso; `kv` = chave/valor, um recurso só).

## 2 · Convenções do CSV

| Coisa | Como se escreve | Exemplo |
|---|---|---|
| Codificação | UTF-8, vírgula como separador, cabeçalho na 1.ª linha | — |
| Identificador | `id` em inglês, `snake_case`, único na tabela | `root_berserker` |
| Chave de texto | `display_key` em `UPPER_SNAKE`; o texto vive em `data/i18n/strings.csv` | `UNIT_ROOT_BERSERKER` |
| Lista | valores separados por `\|` | `weapon\|coins\|corpse` |
| Vector2 / Vector2i | `x\|y` | `4\|7` |
| Dicionário | `chave:valor\|chave:valor` — números viram `float`, o resto `StringName` | `hunt:1.0\|wall:1.0` |
| Enum | pelo nome | `SURFACE`, `AERIAL\|SURFACE` |
| Booleano | `true` / `false` | — |
| Célula vazia | fica o valor por omissão do `Resource` | — |
| Colunas `_` | documentação; a ferramenta ignora-as | `_src`, `_proposed`, `_notes`, `_phase`, `_group` |
| Coluna desconhecida | **a ferramenta falha** — um erro de escrita nunca passa em silêncio | — |

### As colunas de documentação

| Coluna | Para quê |
|---|---|
| `_src` | De onde vêm os números desta linha — secção e tabela do dossiê |
| `_proposed` | Campos cujo valor **não está no dossiê** e foi proposto (decisão de 11/09/2026: propor e marcar). Lista separada por `\|` |
| `_notes` | A justificação das propostas, e tudo o que um revisor precisa de saber |
| `_phase` | Fase do roadmap (§33) em que a linha passa a ser necessária — 0/1/2 é a fatia vertical |

**Aceitar uma proposta:** apaga o nome do campo em `_proposed`. **Mudar uma proposta:** edita o valor e deixa a
marca até o playtest a confirmar. O `PROPOSALS.md` ordena-as por fase e separa balanceamento de apresentação —
começa pela primeira tabela dele.

## 3 · As tabelas

| CSV | Resource | Saída | Linhas | Dossiê | No relatório mestre |
|---|---|---|---|---|---|
| `clock` | `ClockData` | `data/economy/clock.tres` | 1 | §05, §69 | `clock.csv` — o primeiro a provar o circuito |
| `units` | `UnitData` | `data/units/` | 22 | §07, §08, §09, §04 | `units.csv` |
| `creatures` | `CreatureData` | `data/creatures/` | 7 | §07, §51, §75 | `creatures.csv` |
| `buildings` | `BuildingData` | `data/buildings/` | 25 | §06, §09, §10, §15, §16 | `buildings.csv` |
| `walls` | `WallData` | `data/walls/` | 5 | §10 | `walls.csv` |
| `peoples` | `PeopleData` | `data/peoples/` | 6 | §04, §21, §22 | `peoples.csv` |
| `classes` | `ClassData` | `data/classes/` | 7 | §08 | `classes.csv` |
| `crafts` | `CraftData` | `data/crafts/` | 5 | §06 (circuito 2), §49 | — (estava na §44, não no relatório) |
| `jobs` | `JobData` | `data/jobs/` | 14 | §20, §29, §52 | `jobs.csv` — ver 4.1 |
| `biomes` | `BiomeData` | `data/biomes/` | 6 | §11, §21 | `biomes.csv` |
| `segments` | `SegmentData` | `data/segments/` | 9 | §21, §25, §54 | — (§44); o registo de produção é `docs/world/SEGMENT_REGISTER.csv` |
| `economy` | `EconomyCurve` | `data/economy/curve.tres` | 71 chaves | §05–§16, §20, §29, §47, §50 | `economy.csv` — todos os números em prosa |
| `economy_profiles` | `EconomyProfile` | `data/economy/profiles/` | 5 | §06, §29, §31 | novo — perfis dos testes de design |
| `rot` | `RotProfile` | `data/rot/` | 1 | §05, §44, §51 | substitui `waves.csv` — ver 4.1 |
| `mounts` | `MountData` | `data/mounts/` | 6 | §12 | `mounts.csv` |
| `impulses` | `ImpulseData` | `data/crown/impulses/` | 6 | §15, §57 | novo |
| `greed_profiles` | `GreedProfile` | `data/crown/greed/` | 4 | §15, §20 | novo |
| `secrets` | `SecretData` | `data/lore/secrets/` | 4 | §17 | novo |
| `journals` | `JournalData` | `data/lore/journals/` | 12 | §17 | novo |
| `wildlife` | `WildlifeData` | `data/wildlife/` | 3 | §06, §25 | novo |
| `companions` | `CompanionData` | `data/companions/` | 3 | §08 | novo |
| `chaos_modifiers` | `ChaosModifierData` | `data/biomes/chaos/` | 4 | §17, §21 | novo |
| `parallax_layers` | `ParallaxLayerData` | `data/biomes/parallax/` | 12 | §11, §22, §59 | novo |

### As quatro da Parte XIII (ADR 0012)

| CSV | Resource | Saída | Linhas | Dossiê | ADR |
|---|---|---|---|---|---|
| `amargueiros` | `AmargueiroData` | `data/rot/amargueiros/` | 3 | §74 | 0013 |
| `offers` | `OfferData` | `data/rot/offers/` | 12 | §75 | 0014 |
| `titles` | `TitleData` | `data/lore/titles/` | 9 | §76 | 0015 |
| `chapters` | `ChapterData` | `data/world/chapters/` | 10 | §77 | 0016 |

E seis tabelas alargadas em vez de duplicadas: `rot` (25 campos novos — a massa termo a termo, a candeia, a
Oferta, a Dívida e os limiares dos epílogos), `journals` (ato, origem, objeto físico, o que revela), `peoples`
(canção, canção de Colheita, marco), `creatures` (o Zelador e os campos que o descrevem), `clock` (os *tints*
das seis fases e o chão de valor da noite) e `economy` (16 chaves da Colheita, dos títulos e do Lenho Amargo).

**Total: 27 tabelas, 202 recursos.**

E fora de `data/source/`: **`data/i18n/strings.csv`** — 271 chaves de texto (PT-PT e EN), importadas pelo Godot
como tradução. É o `strings.csv` único da §27; a terminologia está em `docs/localization/GLOSSARY.csv`. As 64
chaves novas da Parte XIII são as doze frases de oferta, os nove títulos e feitos, os dez capítulos com lei e
habitante, os três destinos do Amargueiro e o Zelador — cerca de 400 palavras traduzíveis, mais as 900 dos doze
diários (§75).

## 4 · Onde o relatório mestre e o dossiê divergiam, e quem ganhou

O dossiê é a fonte de verdade (relatório §23) e manda nos nomes (§39). Por isso:

### 4.1 Tabelas

- **`waves.csv` não existe.** A §70 decidiu: *"Não há `waves/`: A Podridão substituiu as ondas."* Tudo o que o
  relatório pedia para ondas (massa base, crescimento, intervalo, reservatório de criaturas, lado) já está em
  `rot.csv` + `creatures.csv` (`min_day`) + `biomes.csv` (`creature_table`). A vista por dia que o relatório queria
  é o `ROT_BY_DAY.md`, gerado — nunca escrito à mão.
- **`jobs.csv` são os postos de trabalho** do §20 e do prompt 4 do §29 (muro, torre, plantação…), com a urgência
  por fase. Os **ofícios** (construtor, ferreiro…) são unidades em `units.csv`, treinadas num edifício; e as
  **conversões** do circuito 2 são o `crafts.csv` que a §44 já previa.
- **Nove tabelas novas**, porque o dossiê tinha listas com números em prosa sem sítio onde viver:
  impulsos (§57 pede-os como `Resource`), perfis de ganância, perfis de economia (os testes de design do §31
  precisam deles), segredos, diários, fauna, companheiros, biomas caóticos e camadas de parallax.

### 4.2 Campos

Os nomes da §44 ficam. Os campos do relatório entraram com o nome do dossiê:

| Relatório | Dossiê / CSV | Nota |
|---|---|---|
| `hp` | `max_health` | |
| `range` | `range_px` | |
| `accuracy` | `accuracy_open` | a torre é global: `economy.tower_accuracy` |
| `cost` (unidade) | `recruit_cost` | |
| `upkeep` | `upkeep_per_day` + regra global em `economy.csv` | a manutenção do §06 é por contagem de tropas, não por unidade |
| `speed` | `move_speed` | |
| `mass_cost`, `first_possible_day` | `mass_cost`, `min_day` | |
| `sprite_id`, `animation_set` | `sprite_frames`, `layer_slots`, `weapon_kind`, `head_pool` | a arte é por slots (§58), não por sprite inteiro |
| `role`, `job_affinity`, `tags` | `tags`, `job_affinity` | acrescentados na v5.2 |
| `death_behavior` | `drops_on_death` | |
| `flee_threshold` | `economy.breach_flee_health`, `economy.flee_health` | é regra global, não por unidade — ver Q-005 |
| `production_rate` | `yield_per_day` | o §49 lê `yield_per_phase`: o sistema divide pelo número de fases |

**Não entraram, de propósito:** `armor` e `morale` (o modelo de combate do §07 não tem armadura nem moral por
unidade — acrescentá-los quebrava a tabela de tempo-até-matar); `spawn_weight` (a §51 escolhe a criatura
*mais cara que cabe*, não por peso); `display_name` (a §44 proíbe texto nos `.tres` — é `display_key`).

### 4.3 Campos acrescentados à §44

Todos no grupo `@export_group("v5.2")` de cada script, para se verem de relance. Em `UnitData`: `tags`,
`job_affinity`, `coin_capacity`, `trained_at`, `train_days`, `ability`, `ability_params`, `weapon_kind`,
`head_pool`. Em `RotProfile`: sacrifício por animal e por tropa, `width_start`, `pick_rule`. Em `ClockData`:
`day_seconds_min` e `day_seconds_max` (o *slider* de 240–540 s da §26). As restantes classes são novas e o seu
esquema é o de `SCHEMA.md`.

## 5 · Valores por omissão — porque é que quase todos são zero

Os três `Resource` que o dossiê escreve por extenso (`UnitData`, `RotProfile`, `ClockData`) mantêm os valores
por omissão da §44/§69, tal e qual. Todos os outros têm omissões **neutras** (0, `1.0` nos multiplicadores, vazio):
assim o `.tres` gerado mostra todos os números, o *diff* de balanceamento é legível, e um número nunca vive no
código por engano. O `tests/data_test.gd` chumba se uma propriedade da `EconomyCurve` não tiver linha no CSV.
ADR 0008.

## 6 · O que trava os erros

| Portão | Onde | Apanha |
|---|---|---|
| Sincronia CSV ↔ `.tres` | CI · `csv_to_tres.gd --check` | `.tres` editado à mão, ferramenta esquecida, ficheiro órfão |
| Coluna desconhecida | a própria ferramenta | erro de escrita num cabeçalho (`max_healt`) |
| Dossiê ↔ CSV | CI · `check_dossie_vs_csv.py` | um número do §05, §06, §07, §09, §10, §12 ou §15 mudado só de um lado |
| Integridade | `tests/data_test.gd` | referência partida (`trained_at` a um edifício que não existe), chave de texto em falta, `_proposed` a citar coluna inexistente, segmentos do mesmo tipo com pesos diferentes |
| Design (G5) | `tests/design_data_test.gd` | dia de asfixia fora de 9–14, tabela de tempo-até-matar do §07, fórmulas da Podridão e da manutenção do §29, custos das muralhas, payback do §06 |
| Relatórios | CI · `content_report.py --check` | `PROPOSALS.md` ou `SCHEMA.md` desatualizados |

Um teste de design está **saltado com razão escrita**: `test_arqueiros_nao_param_ariete` — com os números do §07
dá 94,7 s, menos do que a noite de 105 s. É a Q-001 em `docs/QUESTIONS.md`; o teste volta quando decidires.

## 7 · Como se acrescenta

- **Uma linha:** acrescenta-a ao CSV, com `_src` e `_phase`; corre a ferramenta; se tiver `display_key`, acrescenta
  a chave a `data/i18n/strings.csv`.
- **Um campo:** `@export` no script do `Resource` (no grupo `v5.2` ou num grupo novo, com a secção do dossiê num
  comentário), coluna no CSV, ferramenta. Se o campo mudar um contrato da §44, sobe a versão do dossiê.
- **Uma tabela:** script em `src/sim/data/`, CSV em `data/source/`, linha em `_tables.csv` com uma pasta de saída
  **só dela** (a poda apaga `.tres` sem linha na pasta da tabela). Depois `content_report.py`.

## 8 · Duas armadilhas do Godot, já resolvidas

1. **O Godot importa qualquer `.csv` do projeto como tradução** — cada coluna viraria um idioma. Por isso
   `data/source/.gdignore` e `docs/.gdignore` existem. A ferramenta e os testes leem os CSV na mesma: o `.gdignore`
   só afeta o importador.
2. **O `ResourceSaver` omite propriedades iguais ao valor por omissão.** É por isso que o `--check` compara
   recursos carregados, não texto — e é outra razão para as omissões neutras da secção 5.
