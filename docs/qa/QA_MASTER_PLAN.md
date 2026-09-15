# Plano mestre de QA

> O §31 e o §64 definem a estrutura automática: **três níveis** (unitário em `src/sim/`, de cena, de design) e
> **cinco portões de CI** (G1–G5), mais o `test_seed_reproduz`. Este plano junta-lhe o que a máquina não vê — o
> teste manual —, diz o que corre em cada fase e o que faz um *bug* passar de aborrecido a bloqueante.
>
> Relacionados: [`REGRESSION_CHECKLIST.md`](REGRESSION_CHECKLIST.md) · [`PERFORMANCE_MATRIX.md`](PERFORMANCE_MATRIX.md)
> · [`ACCESSIBILITY_MATRIX.md`](ACCESSIBILITY_MATRIX.md) · [`PLAYTEST_PLAN.md`](PLAYTEST_PLAN.md)

## 1 · Automático

| Área | Onde | Estado no dia zero | Entra com |
|---|---|---|---|
| **G1** — `src/sim/` não toca em nós | `tests/architecture_test.gd` + `tools/lint_rules.gd` | ✅ corre | — |
| **G2** — RNG só pelo `RngService` | CI (grep) + `architecture_test.gd` | ✅ corre | — |
| **G3** — sinais só do catálogo da §46 | `architecture_test.gd` | ⏸ saltado com razão | F0-07 (EventBus) |
| **G4** — sem literais de balanceamento | `architecture_test.gd` | ✅ corre | — |
| **G5** — testes de design | `tests/design_data_test.gd` (sobre o modelo de referência) | ✅ corre; 1 saltado (Q-001) | F1-10 passa a usar o `Economy` real |
| Dados — CSV ↔ `.tres` | CI · `csv_to_tres.gd --check` | ✅ corre | — |
| Dados — dossiê ↔ CSV | CI · `check_dossie_vs_csv.py` (127 valores) | ✅ corre | — |
| Dados — integridade e texto | `tests/data_test.gd` | ✅ corre | — |
| Unitário — cada sistema de `src/sim/` | `tests/<sistema>_test.gd`, teste primeiro (§28) | — | cada ticket F0/F1 |
| Determinismo | `tests/determinism_test.gd` — `test_seed_reproduz` (§64) | — | F0 (RngService) |
| Economia | `economy_test.gd` — os 6 testes do prompt 3 (§29) | modelo de referência já os cobre | F1-10 |
| Combate | TTK em valor esperado, nunca numa corrida só (§50) | tabela do §07 já coberta nos dados | F1-07 |
| Save | escrita atómica, 3 *slots*, `save_version`, nunca `load()` (§62, ADR 0007) | — | F0 (SaveService), F1-14 |
| Migração | uma `_migrate_N_to_N1` por alteração ao `GameState`, no mesmo *commit* (§62) | — | F1-14 |
| Worldgen | mesma *seed* → mesmo mundo; mudar a ordem sobe `WORLDGEN_VERSION` (§54) | — | F1 (mundo mínimo) |
| Orçamentos | teste de desempenho contra o §63 (PERFORMANCE_MATRIX) | — | F1-03 |
| Eventos | `test_eventos_no_catalogo` (G3) | — | F0-07 |
| Contratos | a tabela canónica da §70 (`test_band_vive_na_simulacao` e seguintes) | ✅ parcial | cada ficheiro canónico |
| Formato e tamanho | CI · `gdformat --check`, `gdlint` (máx. 250 linhas) | ✅ corre | — |
| *Export* | CI · Linux exporta **e arranca** 30 *frames* sem erro | ✅ corre | — |

Tempo do CI: **< 90 s** nos cinco portões (§65); a suite inteira tem limite de 8 min (§31) — se passar, estás a
testar cenas onde devias testar lógica.

## 2 · Manual

Cada linha tem dono e momento. As que dependem de *hardware* estão na PERFORMANCE_MATRIX; as de acessibilidade na
ACCESSIBILITY_MATRIX.

| Área | O que se faz | Quando |
|---|---|---|
| Comando | jogar um dia inteiro só com comando; todos os ecrãs navegáveis | fim de cada fase a partir da 1 |
| Teclado | idem, só teclado | idem |
| Steam Deck | critérios Verified do §26 (ACCESSIBILITY_MATRIX §2) | Fase 5 e antes da demo |
| Resoluções | 720p, 800p (Deck), 1080p, 1440p, 4K, ultralargo — `fractional` e `integer` | Fase 0 (spike) e antes da demo |
| Alt-tab | sair e voltar a meio da noite; o jogo pausa e o áudio não salta | antes da demo |
| Ecrã inteiro ↔ janela | alternar 10 vezes; nada se desalinha | antes da demo |
| Áudio | 24 vozes com 300 unidades; o sino ouve-se sempre | Fase 4 |
| Save/load | gravar na noite 9 e retomar a mesma noite com a mesma sequência aleatória (§66) | Fase 1 e cada *release* |
| Opções | cada opção aplica-se e persiste depois de reiniciar | Fase 4 |
| Localização | captura de cada ecrã em cada idioma; nada cortado | antes da página de Steam |
| Acessibilidade | ACCESSIBILITY_MATRIX inteira | Fase 5 |
| Desempenho | PERFORMANCE_MATRIX inteira | fim de cada fase a partir da 1 |
| Remapeamento | remapear os dois verbos e jogar | Fase 5 |
| Primeira execução | apagar `user://` e arrancar: idioma, consentimento, título | antes da demo |
| Corrupção simulada | truncar um save a meio; o jogo usa o *slot* anterior e diz-o | Fase 1 (F1-14) e cada *release* |
| *Update* de versão | abrir um save da versão anterior; a migração corre | cada *release* depois da demo |

## 3 · Gravidade

| Nível | Definição | Exemplo | Regra |
|---|---|---|---|
| **S1 — bloqueante** | perde progresso, *crash*, ou quebra uma invariante do §40 | save corrompido; `randf()` solto; `extends Node` em `src/sim/` | não há *merge* nem *release* |
| **S2 — grave** | o jogo fica errado ou injusto | a noite 1 perde-se; TTK diverge do §07 | corrige-se antes de acabar a fase |
| **S3 — incómodo** | funciona, mas lê-se mal ou cansa | a mancha não se vê ao crepúsculo em protanopia | entra no backlog com fase |
| **S4 — cosmético** | ninguém fora da equipa repararia | um frame fora do pivot | quando se tocar no asset |

**Um teste de design a falhar não é um *bug* de código** — é informação de balanceamento (AGENTS.md: *"não mudes
um número em `data/` para fazer um teste de design passar"*). Vai para o `QUESTIONS.md`, não para um *hotfix*.

## 4 · Critérios por fase

| Fase | Entra quando | Sai quando (§33, §65, §66) |
|---|---|---|
| Dia zero | — | CI verde nos portões que já existem; o projeto abre, testa e exporta ✅ |
| 0 | CI verde | um sprite anda nas três faixas; `test_seed_reproduz` passa; CI < 90 s |
| 1 | Fase 0 fechada | sobreviver 10 dias é possível e não é trivial; cena-cartaz acabada; save retoma a noite 9 |
| 2 | Fase 1 fechada | **R2: querem jogar o dia 11** (PLAYTEST_PLAN) |
| 4–5 | Fase 3 fechada | RELEASE_CHECKLIST "antes da demo" completa; PERFORMANCE_MATRIX verde no Deck |
