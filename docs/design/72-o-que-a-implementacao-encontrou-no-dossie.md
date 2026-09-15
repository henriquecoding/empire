# 72 — Achados · novo · O que a implementação encontrou no dossiê

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Transformar prosa em ficheiros que correm é o teste mais duro que uma especificação pode ter. Sete ficheiros do dia zero não funcionavam como estavam escritos, trinta e cinco números ou regras estavam em falta ou não batiam entre secções, e uma regra de segurança não protegia o que prometia. Ficou tudo escrito: os ficheiros corrigidos, as contradições em perguntas com proposta, e nada decidido por omissão.

## Os sete ficheiros que não corriam como estavam escritos

| # | Onde | O que falhava | Correção |
| --- | --- | --- | --- |
| C-01 | §47 · band.gd | Várias constantes numa só linha: erro de sintaxe, e o UnitData caía com ele | Uma constante por linha — corrigido na §47 |
| C-02 | §69 · .gdlintrc | Os padrões recusavam nomes privados (_init, _durations): o gdlint chumbava o próprio GameClock do §30 | _? nos dois padrões — corrigido na §69 |
| C-03 | §69 · run_tests.sh, ci.yml | O gdUnit4 6.x sai com o código 103 em --headless | --ignoreHeadlessMode — corrigido na §69 |
| C-04 | §69 · ci.yml | O export falha sempre sem os templates do motor | Um passo, com cache, que instala só os de Linux — corrigido na §69 |
| C-05 | §69 · .gitattributes | text forçado nos addons/ trata os PNG como texto e corrompe-os | !filter !diff !merge text=auto — corrigido na §69 |
| C-06 | CI | O checkout sem LFS deixa ponteiros no lugar das imagens do dia zero | Os placeholders ficam fora do LFS, em art/export/_placeholder/ — no repositório |
| C-07 | Godot | O Godot importa qualquer .csv como tradução, incluindo os de data/source/ | .gdignore em data/source/ e em docs/ — no repositório |


A ADR 0009 tem a razão de cada uma. Os ficheiros do repositório são a versão completa: o AGENTS.md, o ci.yml e o clock_data.gd de lá levam ainda o que a v5.2 acrescentou — a tabela da §70 inteira, os passos de dados e de spec, e os limites do slider da §26.

## As contradições entre secções

Trinta e seis perguntas em docs/QUESTIONS.md, cada uma com o sítio exato, a proposta e o que bloqueia. Oito ficaram resolvidas na v5.2, porque o próprio dossiê já as decidia noutro lado; as outras esperam por ti.

| # | Resolvida na v5.2 | Ficou |
| --- | --- | --- |
| Q-019 | O §30 escolhe a criatura ao acaso; a §51 manda escolher a mais cara que cabe | A §51 — o F1-08 corrige o código do §30 |
| Q-020 | A §42 semeava os fluxos com XOR de constantes que nem são hexadecimais (0xR0T7); o código logo abaixo usa hash | O código — a tabela da §42 foi corrigida |
| Q-021 | O §47 mandava DAY_SECONDS para a EconomyCurve; a §69 criou o ClockData | ClockData (ADR 0006) — corrigido no §47 |
| Q-022 | Ids em português nos exemplos (enramados_arqueiro.tres) contra a regra do código em inglês | Inglês — a bíblia de nomes, §5 |
| Q-023 | O §22 diz uma camada por slot; o §58, um ficheiro por slot | Fonte com camadas, exportação por slot — Asset Bible, §2 |
| Q-026 | O relatório pedia um waves.csv | rot.csv — A Podridão substituiu as ondas (§70) |
| Q-027 | A §49 lê rendimento por fase; o §06 dá números por dia | O CSV guarda por dia; o sistema divide pelas fases |
| Q-032 | Os sete ficheiros acima | Aplicadas — ADR 0009 |


| # | Em aberto, e bloqueia as Fases 0 e 1 | Bloqueia |
| --- | --- | --- |
| Q-001 | Os arqueiros param o Aríete de lodo? O §07 diz que não, mas 96,6 s é menos do que uma noite de 105 s | F1-09 — o teste está saltado |
| Q-005 | As tropas fogem a 30% ou a 25% de vida? | F1-12 |
| Q-006 | Quem atinge a faixa aérea? | F1-07 · F1-09 |
| Q-017 | Três Rastejantes na noite 1, como diz a §25, ou dez, como dá a massa do §05? | F1-15 |
| Q-024 | A camada Equipments dos teus ficheiros é o slot head? | ART-01 |
| Q-025 | Godot 4.6-stable, 4.6.3 ou 4.7? | Fase 0 |
| Q-033 | A curva abstrata do §06 contra os edifícios reais | F1-10 |
| Q-035 | Sinais do §30 que não estão no catálogo da §46 | F0-07 |
| Q-036 | O I6 proíbe o load() num save e recomenda o ResourceLoader.load — que é a mesma função; um .tres pode trazer script e executá-lo | F0-13 — a ADR 0007 já segue a proposta |


A Q-036 é a mais séria, e a única de segurança: a proposta é gravar o save com FileAccess.store_var e lê-lo com get_var(false), só com tipos base. Na retomada, as frases das §19, §40 e §62 foram alinhadas com a ADR 0007; o SaveService continua por implementar. As outras dezanove são de fases posteriores e estão no mesmo ficheiro, cada uma com a proposta que já está nos dados.

## O português

A v5.2 revê o texto inteiro contra a norma europeia com o Acordo Ortográfico de 1990, que já era a do resto do documento: 105 correções — 69 grafias anteriores ao Acordo, 9 formas do Brasil e 27 de gramática, pontuação e coerência. Estão todas, uma a uma e com o contexto, em docs/dossie-v5.2-correcoes.md. Os blocos de código ficaram de fora de propósito: são ASCII para poderem ser colados.

> **A regra que fecha a pré-produção**
>
> A partir daqui, o dossiê só muda por três razões: uma correção, uma decisão que vira ADR, ou um número que um playtest desmentiu. Uma pergunta nova vai para docs/QUESTIONS.md; um número muda no CSV e o CI confere-o contra este texto. Uma v6 feita de teoria nova seria a forma mais confortável de não fazer o jogo.
