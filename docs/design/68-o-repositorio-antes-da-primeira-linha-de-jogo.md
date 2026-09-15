# 68 — Dia zero · novo · O repositório antes da primeira linha de jogo

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Os primeiros ficheiros de um projeto não são os que fazem o jogo andar — são os que ficam caros de acrescentar depois. A §65 tratava do jogo e estava certa naquilo que fazia. Faltava-lhe a camada por baixo: dezanove ficheiros, quase todos de menos de trinta linhas, que decidem se o próximo ano é legível ou não.

## As três famílias, e porque é que são estas

**Decisões que congelam** — Entram em todos os ficheiros escritos a seguir: a faixa, o RNG, a escala, o relógio. Não se acrescentam no mês seis — reescrevem-se. São as invariantes do §40 tornadas ficheiro.

CI, lint, formatador, checklist de revisão. O teu modelo é a IA escreve, tu revês: o que decide se ele sobrevive não é a qualidade dos prompts, é o custo de rever. Portões mantêm esse custo constante.

AGENTS.md, docs/design/, ADRs. Regra sem exceção: o que não existe, o agente inventa — e inventa diferente em cada sessão. Um caminho citado no contrato e ausente do disco é pior do que não ter contrato.

> **O achado desta revisão — as referências penduradas**
>
> O CLAUDE.md do §28 manda o agente ler docs/design/, escrever em docs/QUESTIONS.md e docs/ASSETS_TODO.md, seguir tarefas em docs/backlog/<id>.md e obedecer a docs/adr/0007-save-security.md. Nenhum destes caminhos é criado por nenhuma das 23 linhas da §65 nem por nenhuma das dez tarefas F0 da §34, e o dossiê — a fonte de docs/design/ — é este ficheiro HTML.
>
> O que acontece na prática, à terceira sessão: o agente não encontra docs/design/05-loop.md, escreve a sua própria versão do loop a partir do que consegue inferir do código, e a partir daí a spec vive em dois sítios que divergem em silêncio. Custo de fechar isto: quarenta minutos e um script (§69). Custo de não o fechar: descobri-lo no mês quatro, com o código já escrito em cima da versão errada.

## O manifesto do dia zero, por ondas

Pela ordem em que se criam. A coluna da direita diz o que a v5 já tinha: falta é ficheiro novo, §70 é caminho em conflito resolvido na secção seguinte.

| Ficheiro | Porque é dia zero | Estado na v5 | h |
| --- | --- | --- | --- |
| Onda 1 — antes de qualquer código. O que suja todos os commits futuros se faltar no primeiro. |  |  |  |
| .gitignore | Sem ele, o .godot/ entra no commit inicial e todos os diffs seguintes trazem milhares de linhas de cache — e tu deixas de os ler | falta | 0,25 |
| .gitattributes | LFS para *.aseprite e art/**/*.png, eol=lf em tudo, addons/ fora do LFS | ✓ §65 | 0,5 |
| README.md | Como correr, testar e exportar. Escreve-se em três minutos e é o que lês daqui a seis meses, ou outra pessoa lê no dia em que entrar | falta | 0,5 |
| LICENSE + NOTICE.md | Código teu; arte com todos os direitos reservados; e as licenças de terceiros listadas (gdUnit4, GodotSteam, LimboAI, tipos de letra). Antes do primeiro GIF público, não depois | falta | 0,25 |
| .editorconfig | Tabulações no .gd, espaços no resto. Elimina a classe inteira de diffs que são só espaço em branco | falta | 0,1 |
| AGENTS.md + CLAUDE.md | Um contrato só, lido por qualquer agente. O CLAUDE.md passa a três linhas a apontar para ele | falta | 0,5 |
| docs/design/** | A spec que o agente lê a cada sessão. Gerada deste dossiê por tools/split_dossie.py, uma secção por ficheiro | falta | 1,5 |
| docs/adr/0000-template.md | Mais os sete primeiros ADRs. O 0007 já é citado como regra absoluta no contrato | parcial | 1 |
| docs/QUESTIONS.md docs/ASSETS_TODO.md docs/backlog/ | Os três destinos que o contrato manda usar. Vazios, com um cabeçalho a dizer o que lá vai — é o suficiente para o agente acertar | falta | 0,25 |
| Onda 2 — os portões. Antes da primeira linha de lógica, porque é o que te deixa aceitar código que não leste. |  |  |  |
| project.godot | As definições do §19, copiadas tal e qual | ✓ §65 | 1 |
| .godot-version | Uma linha: 4.6-stable. Fixa a versão no CI e na tua máquina — um patch do motor a meio da Fase 3 não pode mudar um resultado de teste | falta | 0,1 |
| addons/gdUnit4/ | Vendorizado no repo, versão fixa, fora do LFS | parcial | 0,5 |
| .github/workflows/ci.yml | Os cinco portões do §64 — mais o passo --import, sem o qual a suite falha sempre em checkout frio e tu perdes meia manhã a perceber porquê | parcial | 3 |
| .gdlintrc | max-file-lines: 250. Transforma a regra mais valiosa do §28 num portão de CI em vez de uma boa intenção | falta | 0,5 |
| .github/PULL_REQUEST_TEMPLATE.md | Nove caixas. É o ficheiro de dez linhas com mais alavancagem do repositório, porque o teu modelo inteiro é revisão | falta | 0,25 |
| run_tests.sh | Um comando, usado por ti e pelo agente. Um sítio para mudar quando o gdUnit4 mudar de caminho | falta | 0,25 |
| export_presets.cfg | E um export a correr no dia 1, com um sprite no ecrã. A primeira falha de export deve custar uma tarde no mês 1, não uma semana no mês 20 | falta | 1 |
| tools/csv_to_tres.gd tools/lint_sim.gd | Gerador de dados e portões G1/G2/G4 | ✓ §65 | 6 |
| data/source/clock.csv data/source/units.csv | A ferramenta existia sem input. Duas linhas de CSV bastam para provar o circuito CSV → .tres → jogo no dia 1 | falta | 1 |
| Onda 3 — os contratos congelados. Tipos e serviços que todo o código posterior assume. |  |  |  |
| src/sim/band.gd | Enum, planos e GROUND_LINE. Na simulação, não em core/ — ver §70, é o conflito que chumbava o portão G1 no primeiro dia | §70 | 0,5 |
| src/core/event_bus.gd | Os 61 sinais do §46, fila e flush | ✓ §65 | 3 |
| src/core/rng_service.gd | Os seis fluxos, snapshot e restore | ✓ §65 | 2 |
| src/sim/game_clock.gd src/core/clock_service.gd | O relógio puro e o autoload de trinta linhas que o faz andar. São dois ficheiros, não um — §70 | §70 | 3,5 |
| src/sim/data/clock_data.gd | O Resource que o construtor do GameClock recebe no §30. Sem ele, o código de arranque do dossiê não compila | falta | 0,5 |
| src/core/registry.gd src/core/save_service.gd | Carregamento por StringName; escrita atómica com rotação de três slots | ✓ §65 | 6 |
| src/sim/state/game_state.gd src/sim/state/unit_rec.gd src/sim/data/unit_data.gd | A estrutura do §45 e o Resource do §44, ainda quase vazios | ✓ §65 | 4,5 |
| Onda 4 — o primeiro píxel. Só agora, e só o suficiente para o critério de saída. |  |  |  |
| scenes/boot.tscn | A cena principal do project.godot: carrega Registry, idioma e save, e só depois instancia game.tscn. Está na árvore do §41 e faltava na lista | falta | 1 |
| scenes/game.tscn | A cena raiz do jogo, com a pilha do §59 montada | ✓ §65 | 3 |
| src/world/band_layers.gd src/world/camera_rig.gd src/world/parallax_stack.gd | Faixas e matriz de colisão do §53, câmara, seis camadas de parallax | ✓ §65 | 9 |
| src/actors/unit_view.gd shaders/palette_lut.gdshader | Cinco slots empilhados; o shader que faz quatro trabalhos | ✓ §65 | 8 |
| art/source/.gdignore | Ficheiro vazio. Impede o Godot de tentar importar .aseprite e de reimportar tudo a cada checkout de LFS | falta | 0,1 |
| tests/architecture_test.gd tests/clock_test.gd scenes/tests/bands.tscn | G1, G3, G4, o relógio, e a cena que prova o critério de saída | ✓ §65 | 4,5 |


> **As duas regras do dia zero**
>
> 1 · Nenhum commit de lógica antes de um push verde. O primeiro commit de código do projeto é um teste trivial que passa no CI. Tudo o que vem depois herda um portão que funciona, e nunca tens de reconstruir a confiança no CI no meio de uma fase.
>
> 2 · O que o contrato cita, existe. Antes de escreveres AGENTS.md, cria os ficheiros que ele nomeia — mesmo vazios, mesmo com uma linha só a dizer para que servem. Um caminho citado e ausente é um convite a que o agente decida por ti.

## O que isto acrescenta ao orçamento

- **Trabalho novo** — ≈ 9 h, das quais 4 h são o split do dossiê e o primeiro export — as duas que mais tempo poupam a jusante
- **Fase 0 revista** — ≈ 63 h, contra as ≈ 54 h da §65
- **Calendário honesto** — A dez horas por semana são seis semanas, não quatro. A §65 já estava otimista antes desta secção; é melhor saberes agora do que na quinta semana
- **Critério de saída** — Não muda. Continua a ser um sprite anda nas três faixas e o CI está verde — mais e o repositório exporta um executável
