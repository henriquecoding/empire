# ADR 0009 — Correções aos ficheiros do dia zero, encontradas ao correr o Godot 4.6

- Estado: aceite
- Data: 2026-09-11
- Secção do dossiê: §47, §68, §69

## Contexto
Os ficheiros "prontos a copiar" da §69 e o `band.gd` da §47 foram copiados tal e qual e corridos em Godot
4.6-stable, gdUnit4 6.2.1 e gdtoolkit 4.x. Sete coisas não passavam.

## Decisão
| # | Onde | O que falhava | Correção |
|---|---|---|---|
| C-01 | `src/sim/band.gd` (§47) | `const A := 1, B := 2` é erro de *parse* no 4.6 — e derrubava o `UnitData` | uma constante por linha |
| C-02 | `.gdlintrc` (§69) | as expressões de nomes rejeitavam `_init`, `_process`, `_durations` — o próprio `GameClock` do §30 chumbava | `_?` no início das duas expressões |
| C-03 | `run_tests.sh`, `ci.yml` (§69) | o gdUnit4 6.x sai com o código 103 em `--headless` | `--ignoreHeadlessMode` (a suite não usa *InputEvents*) |
| C-04 | `ci.yml` (§69) | o *export* precisa dos *templates*, que ninguém instalava | *cache* + transferência só dos *templates* de Linux; o passo agora também **arranca** o executável |
| C-05 | `.gitattributes` (§69) | `addons/** … text` forçava os PNG dos *addons* a texto (normalização de fins de linha corrompe binários) | `!filter !diff !merge text=auto` |
| C-06 | `.gitattributes` + `ci.yml` | o CI faz *checkout* sem LFS: os PNG de `art/` chegavam como ponteiros | `art/export/_placeholder/**` fora do LFS |
| C-07 | `data/source/`, `docs/` (§41) | o Godot importa qualquer CSV como tradução — cada coluna vira um idioma | `.gdignore` nas duas pastas |

E uma escolha que não é correção: `binary_format/embed_pck=false` no `export_presets.cfg` — com o `.pck` embebido o
executável não arrancava no teste; com o `.pck` ao lado arranca, e é também o formato habitual das builds da Steam.

## Alternativas consideradas
Manter os ficheiros da §69 intactos e documentar os erros: o primeiro *push* ficava vermelho, contra a regra 1 do
dia zero (§68).

## Consequências
Todas as alterações estão marcadas com `v5.2` nos próprios ficheiros. O dossiê v5.2 regista-as.
