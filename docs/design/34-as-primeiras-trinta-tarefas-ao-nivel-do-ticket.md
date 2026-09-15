# 34 — Backlog · novo · As primeiras trinta tarefas, ao nível do ticket

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Isto é o que abres na segunda-feira. Cada linha é uma sessão de agente, no formato do §29. As Fases 0 e 1 estão completas; a partir daí escreves tu, no mesmo molde.

### Fase 0 — Fundação · 1 mês

| # | Tarefa | Ficheiros | Feito quando |
| --- | --- | --- | --- |
| F0-00 | Repositório do dia zero: as ondas 1 e 2 da §68 | .gitignore, AGENTS.md, .gdlintrc, CI, docs/ | Push verde e docs/design/ com 75 ficheiros |
| F0-01 | Criar projeto Godot 4.6 com as definições do §19 | project.godot | Abre a 1280×720, filtro Nearest, 30 ticks |
| F0-02 | Git + LFS para *.aseprite e art/**/*.png | .gitattributes | git lfs ls-files mostra a arte |
| F0-03 | Escrever CLAUDE.md (§28) e os primeiros 3 ADRs | CLAUDE.md, docs/adr/ | ADR 0001 escala, 0002 faixas, 0003 dados |
| F0-04 | Instalar gdUnit4 + workflow de CI | .github/workflows/ | Push verde com um teste trivial |
| F0-05 | Band enum + collision layers por faixa | src/sim/band.gd §70 | Teste: aéreo não colide com subsolo |
| F0-06 | GameClock + ClockData.tres (prompt 1, §29) | src/sim/game_clock.gd | Os 5 testes do prompt passam |
| F0-07 | EventBus autoload | src/core/event_bus.gd | Sinais declarados, nenhum emissor ainda |
| F0-08 | Câmara com lookahead e limites de região | src/world/camera_rig.gd §70 | Não treme com movimento subpixel |
| F0-09 | Decidir a escala (§19) e escrever ADR 0001 | docs/adr/0001 | Testado em 1080p e no Deck |
| F0-10 | Cena de teste: um sprite anda nas 3 faixas | scenes/tests/bands.tscn | Critério de saída da Fase 0 |


### Fase 1 — Núcleo jogável · 3 meses

| # | Tarefa | Depende de | Feito quando |
| --- | --- | --- | --- |
| F1-01 | Moeda física: largar, arco, queda, apanhar, saco com capacidade | F0-07 | Largar 10 moedas a 60 fps sem picos |
| F1-02 | UnitData.tres + as 6 unidades do §07 | F0-03 | Editar dano no .tres muda o jogo sem recompilar |
| F1-03 | UnitSystem com arrays paralelos e time-slicing | F1-02 | 300 unidades a 60 fps no profiler |
| F1-04 | Recrutar vagabundo por 1 moeda; ele segue-te | F1-01, F1-03 | O minuto 0:20 do §25 funciona |
| F1-05 | JobBoard (prompt 4, §29) | F1-03 | Os 4 testes do prompt passam |
| F1-06 | Muro: 5 níveis, dois caminhos, slots de contacto | F1-05 | Tabela do §10 replicada em .tres |
| F1-07 | Arqueiro: alcance, precisão 0,34 em campo / 1,0 em torre | F1-06 | TTK medido bate com a tabela do §07 |
| F1-08 | RotSystem (prompt 2, §29) | F0-06 | Os 6 testes do prompt passam |
| F1-09 | Criaturas: Rastejante, Alado, Bruto + tabela de invocação | F1-08 | A noite 4 obriga a torre alta |
| F1-10 | Economy (prompt 3, §29) + curve.tres | F1-01 | Teste do dia da asfixia entre 9 e 14 |
| F1-11 | Plantação, pesqueiro, galinheiro com os valores do §06 | F1-10 | Payback de 2 dias medido em jogo |
| F1-12 | Moral e fuga com raio do rei (§07) | F1-05 | Com o rei em campo ninguém foge |
| F1-13 | CanvasModulate por faixa animado pelo GameClock | F0-06 | As 6 fases são distinguíveis sem HUD |
| F1-14 | Save/load do estado de src/sim/ com save_version | F1-10 | Fechar e reabrir no dia 7 preserva tudo |
| F1-15 | Cenário de combate noturno para afinação (§07) | F1-09 | Noite 5 ganha com 1–2 mortes |
| F1-16 | Afinar até sobreviver 10 dias ser possível e não trivial | tudo | Critério de saída da Fase 1 |


### O formato de tarefa — copia para docs/backlog/F1-08.md

```gdscript
# F1-08 · RotSystem

Porque   A Podridao e a mecanica que distingue o jogo. Sem ela ha um clone.
Spec     docs/design/05-loop.md, seccao "A Podridao"
Depende  F0-06 (GameClock)
Contrato [colar do prompt 2 do dossie, §29]
Feito    Os 6 testes passam + a mancha e visivel no horizonte ao crepusculo
Fora     Arte da mancha (F1-17), som (F4-03), alimentar (F6-11)
```

O campo Fora é o mais importante: é o que impede o agente — e a ti — de fazer três tarefas numa e produzir um diff que não consegues rever.
