# v6 → v6 + Parte XIII — o que mudou, linha a linha

_14 de setembro de 2026. Companheiro de `dossie-v5.2-correcoes.md`, que lista as 105 correções de português e
as 27 edições de conteúdo da v5.2. Este lista só o que esta ronda mudou._

A regra da §72 continua a valer: **o dossiê só muda por correção, por decisão que vira ADR, ou por número que um
playtest desmentiu.** Tudo o que segue é do primeiro tipo, exceto onde a linha disser a ADR.

---

## Parte 1 — As oito edições ao dossiê

| # | Secção | O que estava | O que passou a estar | Porquê |
|---|---|---|---|---|
| V01 | §05 | `M = 60 + 26 × dia + 40 × fortalezas_conquistadas` | A mesma linha riscada, seguida da fórmula da §74 com os cinco termos | A §05 trazia uma caixa a dizer "revisto na §74" mas a linha continuava a afirmar os números antigos. Quem lesse a §05 e não a §74 implementava a fórmula errada, e o `rot.csv` já traz 40/18/30. |
| V02 | §29, *prompt* 2 | `massa = 60.0 + 26.0 * dia + 40.0 * fortalezas` | A fórmula da §74, com os termos dos Amargueiros e das recusas | É um bloco "pronto a copiar": quem o colasse implementava a v5.2. |
| V03 | §29, *prompt* 2 | `DADOS data/waves/rot.tres, data/waves/creatures_<bioma>.tres` | `DADOS data/rot/default.tres, data/creatures/<id>.tres` | A §70 acabou com `waves/`. Os caminhos citados não existiam no disco. |
| V04 | §29, *prompt* 2 | `- dia 10 com 2 fortalezas: massa == 400.0` | `- dia 10 com 2 fortalezas, campo limpo: massa == 280.0` | Consequência de V02: `40 + 18 × 10 + 30 × 2 = 280`. O teste `test_podridao_do_29` foi atualizado no mesmo passo. |
| V05 | §80 | *"A §05 **manda** «Azul profundo» na noite."* | *"A §05 **mandava** «Azul profundo» na noite."* | A tabela da §05 já foi corrigida pela ADR 0011. A frase no presente afirmava um estado que deixou de existir. |
| V06 | §71 | *"conserva o estado **registrado** pelo Claude"* | *"conserva o estado **registado** pelo Claude"* | `registrado` é PT-BR. O dossiê é PT-PT/AO90 (v5.2, correção J-xx). |
| V07 | §75 | *"Controlas a mancha esta noite e **mandas-la** a um império rival"* | *"… e **manda-la** a um império rival"* | Verbo na 2.ª pessoa do singular perde o `-s` antes de `o/a`: `mandas + a` → `manda-la`. |
| V08 | §76 e §83 | *"na alvorada seguinte **pára** um passo à frente"* (2 ocorrências) | *"… **para** um passo à frente"* | O AO90 eliminou o acento diferencial em `pára`. É a regra que a v5.2 aplicou 69 vezes. |

E a nota de abertura do dossiê passou a citar números medidos em vez de escritos à mão, com a ligação para
`docs/recovery/RETOMADA.md` — que era uma **referência pendurada**: o ficheiro não existia. Passou a existir.

---

## Parte 2 — Os defeitos encontrados ao implementar o anexo §85

| # | Onde | O defeito | O que se fez |
|---|---|---|---|
| D01 | `tools/content_report.py` | **Ciclo infinito.** O Zelador (§75) entrou no `creatures.csv` com `mass_cost = 0`; o laço que conta invocações subtrai o custo da criatura mais cara que cabe e nunca terminava. A ferramenta deixou de responder. | O Zelador sai do sorvedouro: nasce da Dívida, não da massa. O relatório passa a dizê-lo. |
| D02 | `tools/content_report.py` | O `ROT_BY_DAY.md` anunciava a fórmula de três termos | Passa a mostrar os seis termos da §74 e a dizer que a tabela é **o piso** — o resto joga-se. |
| D03 | §77 vs `chapters.csv` | A caixa das raízes lista **oito** raízes para **dez** capítulos, e eu tinha atribuído "cantiga de contar" onde a §77 diz "encomendação das almas" | As oito passam a ser as da §77, na ordem dela. As duas que faltam ficam marcadas em `_proposed` e abrem a **Q-054**. |
| D04 | §75 vs `offers.csv` | A décima oferta tem *"Uma classe jogável, para sempre"* na coluna **Preço**. Lido como recompensa, seria a única linha com duas recompensas e preço nenhum | Fica como preço — perder uma classe da §08 — em `price_kind = playable_class`, marcado, e abre a **Q-053**. |
| D05 | §77, regra 5 | O desvio está escrito para bifurcação (25 s) e travessia (40 s), e três das cinco colocações não são nenhuma das duas | Propostas marcadas nas dez linhas; abre a **Q-055**. |
| D06 | `ferramentas/verificar-dossie.mjs` | O portão exigia ≥ 880 referências §NN ligadas. **Nenhuma construção alguma vez o atingiu** — nem a de 13/09 (857) nem a de hoje (858) | Piso recalibrado para 820, com a medição e a razão escritas ao lado. Um portão que chumba sempre é um portão que se aprende a ignorar. |
| D07 | `ferramentas/verificar-novo.mjs` | O caminho do ficheiro estava fixo em `saida/dossie-empire-v6.html` | Passa a aceitar o caminho como argumento, com o mesmo valor por omissão. |
| D08 | `ferramentas/construir.mjs` | O cabeçalho diz "cinco inserções" e o contador imprimia quatro | O bloco de dados e o de comportamento contam como dois, que é o que são. |
| D09 | `ferramentas/extrair-dados.mjs` e os painéis | Os números "42 tickets · 52 perguntas · 12 ADRs · 17 tabelas · 46 testes · 85 secções" estavam escritos à mão no JavaScript, e o extrator lia um registo de validação fixo | O extrator lê o registo **mais recente** de `docs/recovery/`; os painéis passam a derivar todos estes números. Era o painel de estado a mentir sobre o estado. |
| D10 | `docs/i18n/strings.csv` | 35 chaves de conteúdo novo sem tradução — o teste `test_todas_as_chaves_de_texto_existem` chumbava 36 vezes | 64 chaves novas, PT-PT e EN: as doze ofertas, os nove títulos e feitos, os dez capítulos com lei e habitante, os três destinos e o Zelador. Fecha a **Q-049**. |

---

## Parte 3 — O que entrou de novo

- **Dados** — `amargueiros.csv` (3), `offers.csv` (12), `titles.csv` (9), `chapters.csv` (10); `rot.csv` com 25
  campos novos; colunas novas em `journals.csv`, `peoples.csv`, `creatures.csv`, `clock.csv` e 16 linhas em
  `economy.csv`. **27 tabelas, 202 recursos.**
- **Resources** — `AmargueiroData`, `OfferData`, `TitleData`, `ChapterData`; seis alargados.
- **Testes** — os catorze da §84, em `tests/parte_xiii_rot_test.gd` e `tests/parte_xiii_mundo_test.gd`:
  20 casos, 16 a correr e 4 saltados com a razão e o sistema que falta escritos. **43 casos no total, zero falhas.**
- **Portões** — o `check_dossie_vs_csv.py` passa de 127 para **193** números conferidos: a massa termo a termo,
  os três destinos, a candeia, as doze ofertas, os limiares da Dívida, os nove feitos e os *tints* das seis fases.
- **ADRs** — 0011 (noite castanha) a 0019 (os catorze testes). Nove novas.
- **Perguntas** — Q-037 a Q-055 em `docs/QUESTIONS.md`. A Q-037 fecha com a ADR 0011.
- **Backlog** — 53 tickets, incluindo os onze da Parte XIII pela ordem de custo da §82.
- **Bíblias** — arte, animação, áudio, mundo, *greybox*, UX, localização e QA, mais o
  `docs/qa/RISK_REGISTER.csv` com os doze riscos da §37 e os seis novos da §84.

---

## Parte 4 — A segunda passagem: o que a auditoria encontrou

Depois de tudo o acima estar feito, varreu-se o repositório à procura de números escritos à mão, caminhos citados
que não existem, e estados de ticket que afirmavam mais do que era verdade.

| # | Onde | O defeito | O que se fez |
|---|---|---|---|
| D11 | `data/i18n/strings.csv` | **Os doze diários da §79 estavam por escrever** — doze linhas a dizer `(por escrever)`. Era o maior buraco de conteúdo que restava, e o §79 dava a ficha de cada um: ato, onde, o objeto físico e o que deixa perceber | Os doze escritos, PT-PT e EN, todos entre 60 e 90 palavras como a §79 manda — 836 palavras. O 9 é o do dossiê, palavra por palavra; os outros onze são primeira versão e medem-se contra ele. Zero *placeholders* em 271 chaves. |
| D12 | `docs/backlog/tickets.json` | Três tickets diziam **«feito»** e não estavam: o F0-06 (o `game_clock.gd` não existe), o F0-02 (não há arte para o LFS mostrar) e o F0-04 (o CI nunca correu num *runner* remoto) | Passam a **«parcial»**, cada um com a data e o que falta. Um backlog que se engana sobre o que está feito é pior do que não ter backlog. |
| D13 | `docs/adr/0019` | Citava `tests/design/`, que não existe — os testes vivem em `tests/parte_xiii_rot_test.gd` e `tests/parte_xiii_mundo_test.gd` | Corrigido, com a razão de serem dois: o portão das 250 linhas do §28 vale também para os testes. |
| D14 | `ferramentas/extrair-dados.mjs` | O caminho de entrada tinha de ser a pasta que **contém** `Empire/`. Num *runner* de CI a pasta de trabalho chama-se outra coisa, e o comando escrito no LEIA-ME não servia lá | Aceita a raiz do repositório, a pasta que a contém, ou nada (usa a sua). Falha com mensagem quando não é nenhuma das três. |
| D15 | `ferramentas/verificar-*.mjs` | O caminho do Chromium estava fixo nesta máquina. Num *runner*, o `launch` rebentava com um erro que não dizia porquê | Só se passa `executablePath` quando o ficheiro existe; caso contrário resolve o Playwright. |
| D16 | `.github/workflows/ci.yml` | Os dois portões do dossiê não corriam no CI — existiam e só se corriam à mão | Job novo `dossie`: instala o Playwright, deriva o inventário, constrói e corre os dois portões. |
| D17 | `ferramentas/LEIA-ME.md` | «42 tickets, 52 perguntas, 12 ADRs, 17 tabelas», «912 documentos», «quatro inserções», e um comando de reconstrução que apontava para uma cópia do dossiê dentro de `ferramentas/` | Os números saem; o comando passa a apontar para `../docs/dossie.html`, que é a única cópia. |
| D18 | `docs/content/CONTENT_DATABASE.md` | A lista de tabelas tinha 23 e o conferidor «127 números» | 27 tabelas, com as quatro da Parte XIII numa secção própria e as seis alargadas nomeadas; 193 números. |
| D19 | §71 do dossiê | A secção é um inventário histórico e dizia-o, mas os números dela liam-se como atuais — e uma linha dizia «Existe» de uma pasta que não existia | A nota passa a datar os números (11/09/2026), a listá-los, e a mandar o leitor para o registo medido. Onde os dois discordarem, manda o medido. |

> **A regra que saiu disto, e que entrou no `AGENTS.md`**
>
> *Não escrevas à mão um número que a ferramenta conta.* O dossiê, o README e o painel de estado passam a ler
> `docs/recovery/validation.json` e os CSV. Um número escrito à mão diverge no primeiro dia e ninguém dá por isso,
> porque nada reprova — foi assim que um painel de estado chegou a afirmar 17 tabelas num repositório com 27.
