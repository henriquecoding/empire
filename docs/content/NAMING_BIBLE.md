# Bíblia de nomes

> O dossiê deixa os nomes em aberto de propósito: *"Empire"* é codinome, os povos são marcadores de posição, e o
> que tem de ficar fixo já é a **lógica** de cada povo (§04). A decisão é tua, com prazo: **antes da Fase 4**, porque
> a página de Steam abre no mês 11 (§36, §67). Esta bíblia arruma o que já está decidido, propõe o que falta, e diz
> como se verifica um nome antes de o escolher.
>
> A tabela completa de nomes — id, chave, PT-PT, EN — é gerada em [`NAMES.md`](NAMES.md) a partir de
> `data/i18n/strings.csv`. A terminologia para tradutores está em `docs/localization/GLOSSARY.csv`.

## 1 · O nome do jogo

### Os critérios (§36)

1. Pesquisável no Steam sem competir com trinta jogos.
2. Funciona foneticamente em inglês **e** em português.
3. Livre como domínio `.com` e numa pesquisa de marcas da UE.
4. Diz alguma coisa sobre **povos** ou sobre **a noite que avança** — os dois ganchos reais do jogo.

### Candidatos — com uma primeira triagem feita a 11/09/2026

A triagem é só uma pesquisa web por colisões óbvias. **Não é verificação de marca nem de domínio** — isso é o
passo 2 da secção 1.3, e deve ser confirmado por quem trata de marcas antes de gastar dinheiro em logótipo.

| Candidato | O que diz | EN / PT | Triagem | Veredito |
|---|---|---|---|---|
| **Sixfold** | Os seis povos e as seis partes da lore (§17) — o fim da União é "voltar a ser um" | "siks-fould" nas duas | Nenhum videojogo encontrado; existe uma web-série e um jogo de tabuleiro online com o nome ([TV Tropes](https://tvtropes.org/pmwiki/pmwiki.php/WebOriginal/Sixfold), [LG-Docs](https://docs.littlegolem.net/games/sixfold/)) | **Forte** — verificar marca e `.com` |
| **Rotwatch** | Olhar para o horizonte e ver A Podridão chegar — o gancho do §05 | bom em EN; "rot" lê-se bem em PT | Nenhum videojogo encontrado; o nome está usado como *handle* e em rotwatch.net ([rotwatch.net](https://rotwatch.net/), [X @RotWatch](https://x.com/rotwatch?lang=en)) | Possível — `.net` já ocupado |
| Rotfall | A Podridão que cai à noite | bom nas duas | Vizinhança lotada no Steam: *Ratfall*, *Rotfront*, e o *Rotwood* da Klei ([Ratfall](https://store.steampowered.com/app/4400890/Ratfall/), [Rotfront](https://store.steampowered.com/app/4502770/Rotfront/), [Rotwood](https://en.wikipedia.org/wiki/Rotwood)) | Arriscado — confunde-se |
| Six Roots | Seis povos, a árvore, os Sob-Raiz | bom nas duas | Colide em tema e nome com *Root*, jogo de estratégia de fações do bosque ([Root no Steam](https://store.steampowered.com/app/965580/Root/)) | Evitar |
| ~~Rootbound~~ | — | — | Já existe no Steam, de ex-programadores de Gothic/Elex ([Steam](https://store.steampowered.com/app/3453490/Rootbound/)) | **Excluído** |
| ~~Dawnbell~~ | O sino da manhã (§23) | — | Já existe *Dawn Bell*, aventura de terror 2D no Steam ([GameWith](https://x.com/gamewith_review/status/2026966086931927192)) | **Excluído** |
| ~~Canopy Kings~~ | Os Enramados | — | Série da Prime Video ([Prime Video](https://www.primevideo.com/detail/0K8WU3QDPXR3STJJEE3CHP3T4Y)) | **Excluído** |
| Duskward | Rumo ao crepúsculo; a mancha que avança | bom em EN; estranho em PT | Não pesquisado | Por triar |
| The Six Hearths | Seis povos, seis lares | bom em EN; "hearth" é difícil em PT | Não pesquisado | Por triar |

### Verificação antes de decidir

1. **Steam, itch.io, IGDB** — pesquisa exata e variantes com um carácter trocado.
2. **Marca** — EUIPO eSearch (classes 9 e 41) e INPI Portugal. Isto é informação geral, não aconselhamento
   jurídico: antes de registar ou investir num nome, confirma com um profissional de propriedade intelectual.
3. **Domínio** — `.com` livre; `.pt` como extra.
4. **Redes** — o mesmo *handle* livre onde o devlog vive (§36).
5. **O teste da capsule** — o nome legível a 120 × 45 numa grelha com vinte concorrentes (§36).
6. **O teste da pronúncia** — três pessoas que não falam português dizem-no em voz alta; três que não falam inglês
   também.

Até à decisão: **nenhum logótipo**, e o codinome `Empire` só aparece em ficheiros de trabalho (`UI_TELEMETRY_PROMPT`
tem-no marcado para substituir).

## 2 · Os povos

Os nomes em português são os do dossiê e continuam provisórios (§04). Proponho que fiquem **como nomes próprios
também em inglês** até à decisão — como "Hobbits" não se traduz —, com a alternativa inglesa ao lado.

| id | PT (provisório) | Alternativa EN (proposta) | O que o nome diz | Gentílico |
|---|---|---|---|---|
| `enramados` | Enramados | Boughfolk | cobertos de ramos: vivem nas árvores | um enramado, uma enramada |
| `portuarios` | Portuários | Harborfolk | o porto enorme | um portuário |
| `fenda` | Fenda | Riftfolk | o desfiladeiro | um fendeiro *(proposta)* |
| `horta` | Horta | Growers | a várzea e os legumes | um hortelão |
| `fornalha` | Fornalha | Forgekin | o vulcão e as fundições | um fornalheiro *(proposta)* |
| `sobraiz` | Sob-Raiz | Underroot | debaixo das raízes | um sob-raiz |

**A regra do §04 continua a mandar:** um povo novo só existe com as cinco colunas preenchidas — terreno →
arquitetura → economia → defesa → tropa única. O nome vem depois.

## 3 · Regiões, reis e títulos

Nada disto está no dossiê; são propostas para a fase de cada povo.

- **Regiões** tomam o nome do **marco** (§21): *A Árvore-Mãe* (Enramados), *O Farol* (Portuários), *A Porta
  Talhada* (Fenda), *O Silo Grande* (Horta), *A Chaminé* (Fornalha), *O Poço* (Sob-Raiz).
- **Reis e herdeiros** são gerados, não escritos: nome próprio de uma lista por povo + **epíteto do perfil de
  ganância** (§15) — *Baltasar, o Austero*; *Leonor, a Fastuosa*; *Dom Nabo II, o Tirano* (Horta). O epíteto é
  informação tática lida de relance, e cumpre a regra de o HUD não ter números.
- **Listas de nomes por povo** (a escrever): Enramados — nomes de árvores e ofícios da madeira; Portuários — nomes
  de marés e de barcos; Fenda — pedras; Horta — legumes e festas agrícolas; Fornalha — metais; Sob-Raiz — fungos e
  palavras da terra. Quinze por povo chegam para a fatia vertical.
- **Títulos:** Rei / Rainha · Herdeiro / Herdeira · Regente (durante o interregno, §16).

## 4 · Terminologia fixa

Estes termos não se traduzem de maneira diferente de sessão para sessão — nem pelo código, nem pelo texto. A lista
completa, com contexto, género e plural, está no `GLOSSARY.csv`.

| PT-PT | EN | id no código | Nunca |
|---|---|---|---|
| A Podridão | The Rot | `rot` | Blight · Decay · Corruption · a sombra · onda/wave (§28, §70) |
| Faixa (aérea · superfície · subsolo) | Band (aerial · surface · underground) | `Band.Kind` | camada, layer |
| Moeda | Coin | `coin` | ouro, dinheiro |
| Semente Real | Royal Seed | `royal_seed` | "semente" sozinha (confunde com a *seed* do mundo) |
| Semente do mundo | World seed | `seed` | Semente Real |
| Favor | Favor | `favor` | — |
| Matéria | Material | `material` | recurso, item, inventário (**não há inventário**, §49) |
| Ofício | Craft | `craft` / `UnitData` do ofício | profissão, job |
| Posto (de trabalho) | Job post | `JobData` | tarefa |
| Impulso real | Royal impulse | `ImpulseData` | poder, *boost* no texto visível |
| Ganância | Greed | `greed` | corrupção |
| Roda do rei | King's wheel | `king_wheel` | menu |
| Verbo 1 — largar moeda · Verbo 2 — assumir | drop · assume | `verb_drop` · `verb_assume` | um terceiro verbo (§05) |

## 5 · Convenções de código

| Coisa | Regra | Exemplo |
|---|---|---|
| Identificadores de conteúdo | inglês, `snake_case`, únicos na tabela | `root_berserker`, `granary` |
| Povos | o `id` de `peoples.csv`, sem acentos | `sobraiz` |
| Chaves de texto | `UPPER_SNAKE` com prefixo por tipo | `UNIT_` `CREATURE_` `BUILDING_` `WALL_` `PEOPLE_` `CLASS_` `CRAFT_` `JOB_` `BIOME_` `MOUNT_` `IMPULSE_` `GREED_` `SECRET_` `JOURNAL_` `WILDLIFE_` `COMPANION_` `CHAOS_` `UI_` `OPT_` `CAPTION_` `EPILOGUE_` `CURRENCY_` |
| Chaves com número | a chave inteira com marcador, nunca concatenação | `DAY_N` → `Dia %d` (§27) |
| Classes | `PascalCase`; recursos de definição terminam em `Data`, `Profile` ou `Curve` (§44) | `UnitData`, `RotProfile` |
| Sinais | só os 61 da §46 | `unit_died`, nunca `unit_dead` |
| Ficheiros de código | `snake_case.gd`, ≤ 250 linhas (§28) | `rot_system.gd` |
| Arte | ASSET_BIBLE §3 | `enramados_villager_weapon_bow_l1.png` |
| Segmentos | `<povo>_<tipo>_<nn>` | `enramados_ruin_01` |

**Os tipos de segmento passam a inglês.** O §21 escreveu-os em português (`base_inicial`, `vazio`…), mas o
vocabulário do §28 manda o código em inglês — e a §21 é de design, não fixa nomes (§39):

| §21 (PT) | Dados (EN) |
|---|---|
| `base_inicial` | `start_base` |
| `segmento_00_abertura` | `opening` (cena `enramados_opening_00`) |
| `vazio` | `empty` |
| `bosque` · `agua` · `rocha` | `forest` · `water` · `rock` |
| `ruina` | `ruin` |
| `acampamento_mercenario` | `mercenary_camp` |
| `fortaleza` | `fortress` |
| `caotico` | `chaotic` |
| — (limiar e bordo da lição do Chef RPG) | `threshold` · `edge` |

**Os exemplos em português de nomes de ficheiro também:** `enramados_arqueiro.tres` (§19) passa a
`data/units/archer.tres` com `people = neutral` (o arquétipo é de todos; o corpo é do povo), e
`enramados_ferreiro_body.aseprite` (§22) passa a `enramados_villager.aseprite` com a camada `head_mustache_bald`.

**Um aviso sobre "craft":** o vocabulário do §28 diz *Craft → ofício*, e a §44 chama `CraftData` à receita de
conversão do circuito 2. As duas leituras batem certo se se disser assim: **o ofício é quem trabalha; a
`CraftData` é o que ele faz com uma matéria.** O cozinheiro (`cook`, uma unidade) usa a receita
`grain_granary` (uma `CraftData`).

## 6 · Palavras proibidas no texto do jogo

- **`Empire`** como nome final (é codinome, §36).
- **Nomes de marcas alheias** — *Kingdom*, *Two Crowns*, *Thronefall*, *Root* — em qualquer texto do jogo ou da loja
  que não seja uma comparação explícita e factual numa entrevista.
- **Números de vida, dano ou recursos** no mundo (§07, §24): o texto nunca diz "32 HP".
- **"Menu"** para a roda do rei, **"inventário"** para matéria, **"onda"** para A Podridão.
- **Brasileirismos no PT-PT** — tela, time, usuário, planejar, você, ônibus; ver o STYLE_GUIDE.
