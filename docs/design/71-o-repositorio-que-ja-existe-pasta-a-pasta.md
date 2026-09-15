# 71 — Índice · novo · O repositório que já existe, pasta a pasta

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Inventário histórico — os números desta secção são os de 11/09/2026. A tabela abaixo fica como registo do que a v5.2 tinha, e não se atualiza: 23 tabelas, 120 recursos, 23 testes, 75 ficheiros de especificação, 550 propostas. O estado de hoje está medido em docs/recovery/validation.json, contado em docs/recovery/RETOMADA.md, e mostrado no painel ★ Estado desta página, que o volta a contar a cada construção. Onde os dois discordarem, manda o medido.

As ondas 1 e 2 da §68, e tudo o que o relatório do que faltava pedia, estão num repositório que abre no Godot 4.6: 23 testes (dois saltados, com a razão escrita), o export de Linux a arrancar, e os números deste dossiê em 23 tabelas de onde saem 120 recursos .tres. O que o dossiê não dava foi proposto e marcado — 550 valores, 265 deles na fatia vertical. Nada foi decidido em silêncio.

## Pasta a pasta

| Pasta | O que tem | Vem de | Estado |
| --- | --- | --- | --- |
| Raiz | AGENTS.md + CLAUDE.md, README.md, .gitignore, .gitattributes, .editorconfig, .gdlintrc, .godot-version, LICENSE, NOTICE.md, LEGAL.md, project.godot, export_presets.cfg, run_tests.sh | §68, ondas 1 e 2 · §69 | Existe e corre |
| .github/ | workflows/ci.yml — os cinco portões do §64, mais dois passos da v5.2: dados em sincronia com o dossiê, e docs/design/ igual ao gerado · PULL_REQUEST_TEMPLATE.md | §64 · §69 | Existe; corre no GitHub quando houver remoto |
| data/source/ → data/**/*.tres | 23 tabelas e o registo _tables.csv; 120 .tres gerados e versionados. As colunas _src e _proposed dizem de onde vem cada número e o que ainda é proposta | §44 · §06 a §17 | Existe; csv_to_tres --check sem diferenças |
| data/i18n/strings.csv | 207 chaves de texto, PT-PT e EN, com contexto e limite de caracteres | §27 | Existe |
| src/sim/ | band.gd e 23 recursos de definição — as doze classes da §44 e mais onze que as tabelas pediram (relógio, postos de trabalho, ganância, impulsos, segredos, diários, fauna, companheiros…) | §44 · §47 · §70 | Existe; o resto da simulação são os tickets F0 e F1 |
| scenes/boot.tscn | A cena principal do dia zero: céu, corte de solo, um placeholder de escala 2 com sombra de contacto em cima da GROUND_LINE | §59 · §70 | Existe — placeholder, não jogo |
| tools/ | csv_to_tres.gd, csv_codec.gd, lint_sim.gd, lint_rules.gd, split_dossie.py, check_dossie_vs_csv.py, content_report.py, export_aseprite.sh | §41 · §64 · §69 | Existe; o último por testar com o Aseprite |
| tests/ | Arquitetura (G1, G2, G4, a faixa canónica, 250 linhas), dados (tabelas completas, referências, chaves de texto) e design (tempo até matar do §07, Podridão, manutenção, asfixia entre 9 e 14, rotas, ganância, muralhas) | §31 · §64 | 23 testes; G3 espera pelo F0-07, o aríete pela Q-001 |
| docs/design/ | Este dossiê partido por secção, 75 ficheiros | §69 | Gerado; o CI falha se divergir |
| docs/adr/ | 0000 a 0010 — escala, faixas, dados, versionamento, arranque, relógio, save, convenções da base de dados, correções do dia zero, importação da arte | §28 · §69 | 0001 e 0010 são propostas; as outras, aceites |
| docs/backlog/ | 42 tickets: F0-00 a F0-15 e F1-01 a F1-17 no formato do §34, com os caminhos da §70 e os ficheiros reais de docs/design/; mais nove tickets de arte, greybox, nomes e dados | §34 · §65 · §66 | Existe |
| docs/content/ | Dicionário e esquema da base de dados, as 550 propostas, a Podridão dia a dia, os nomes, e a bíblia de nomes com a triagem dos candidatos ao nome do jogo | §17 · §36 · §44 | Existe; o nome do jogo continua por escolher |
| docs/art/ | Asset Bible, registo de 251 assets, bíblia de animação, guia de expressões, 34 efeitos | §01 · §22 · §58 · §60 | Existe |
| docs/world/ | Bíblia de produção de mundo, regras de greybox, registo de 43 segmentos | §21 · §54 | Existe |
| docs/ux/ · docs/audio/ · docs/localization/ | Fluxos e 25 ecrãs · bíblia de áudio e 56 pistas · glossário de 57 termos e guia de estilo | §23 · §24 · §25 · §27 | Existe |
| docs/qa/ | Plano e formulário de playtest, plano mestre de QA, regressão, desempenho, acessibilidade | §26 · §32 · §63 | Existe |
| docs/legal/ · docs/release/ · docs/marketing/ | Registo de terceiros, checklists de lançamento, assets da loja | §35 · §36 | Existe |
| docs/ | QUESTIONS.md (Q-001 a Q-036), ASSETS_TODO.md, dossie-v5.2-correcoes.md | §28 · §68 | Existe |


## Como se verificou

- **Motor** — Godot 4.6-stable em headless: o projeto importa sem erros
- **Testes** — gdUnit4 6.2.1 — 23 testes, 21 a passar e 2 saltados com a razão escrita
- **Dados** — csv_to_tres --check sem diferenças; check_dossie_vs_csv.py confere 127 números deste dossiê contra as tabelas, e não há divergências
- **Portões** — lint_sim.gd (G1, G2, G4) limpo; gdformat e gdlint limpos
- **Export** — Linux, com os templates 4.6; o executável arranca em headless
- **A curva** — O modelo do §06 reproduzido num teste: asfixia no dia 11 no perfil equilibrado, duas rotas empurram-na quatro dias, tudo no máximo leva-a ao dia 28 — como o simulador do §06 diz

## A pré-produção está fechada?

O relatório do que faltava dá doze critérios. Agrupados, o estado honesto é este:

| Critério | Estado |
| --- | --- |
| O dossiê é a fonte de verdade | Sim — gerado para docs/design/ e conferido pelo CI |
| As decisões da Fase 0 estão registadas | Em parte — a escala é ADR proposta até ao spike; a GROUND_LINE, a fonte e a câmara continuam na §67 |
| Existe a base de dados de conteúdo | Sim, com 550 propostas por aprovar |
| Existem a Asset Bible, o registo de assets, a bíblia de animação e a de nomes | Sim — o nome do jogo não |
| Existem todos os ficheiros do dia zero | As ondas 1 e 2, completas; as ondas 3 e 4 são os tickets F0 |
| O CI está verde | Localmente, com a mesma sequência de passos; no GitHub, quando houver remoto |
| O projeto exporta | Sim — Linux |
| Uma personagem funciona dentro do jogo | Não — F0-10 e ART-01 |
| A greybox funciona | Não — GB-01 a GB-03 |


> **O que falta já não é documentação**
>
> As duas linhas por fazer não se resolvem a escrever. O próximo marco é o do relatório: abrir o Empire, controlar uma personagem real numa greybox, atravessar as três faixas, construir algo com uma moeda, sobreviver à primeira noite e reproduzir o resultado pela mesma seed. Os tickets estão por ordem em docs/backlog/. Começa pelo F0-00.
