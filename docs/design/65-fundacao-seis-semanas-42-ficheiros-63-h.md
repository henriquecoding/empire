# 65 — Fase 0 · Fundação — seis semanas, 42 ficheiros, ≈ 63 h

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Revisto na v5.1: esta lista tratava só dos ficheiros de jogo. Os do repositório — que vêm antes — estão na §68, e o conteúdo de cada um na §69; os caminhos marcados §70 foram corrigidos. Critério de saída do §33: um sprite anda nas três faixas e o CI está verde. Nada mais. A tentação é fazer combate na Fase 0; resistir a essa tentação é o que faz a Fase 1 correr bem.

| Ficheiro | O que faz | Depende de | h |
| --- | --- | --- | --- |
| Infraestrutura — 6, mais os 19 da §68 |  |  |  |
| project.godot | As definições do §19, copiadas tal e qual | — | 1 |
| .gitattributes | Git LFS para art/source/ desde o primeiro commit | — | 0,5 |
| .github/workflows/ci.yml | gdUnit4 em headless, os cinco portões do §64 | — | 3 |
| AGENTS.md + CLAUDE.md | O contrato do §69. Aponta para docs/design/, gerado por tools/split_dossie.py | §69 | 1,5 |
| tools/csv_to_tres.gd | Gera .tres a partir de data/source/*.csv | §44 | 4 |
| tools/lint_sim.gd | Portões G1, G2, G4 | — | 2 |
| Núcleo — 6 |  |  |  |
| src/sim/band.gd §70 | O enum e as constantes de plano (§47). Na simulação, não em core/ | §70 | 0,5 |
| src/core/event_bus.gd | Os 61 sinais declarados, fila e flush | §46 | 3 |
| src/core/rng_service.gd | Os seis fluxos, snapshot e restore | §42 | 2 |
| src/sim/game_clock.gd §70 | Seis fases, passo fixo, fronteiras. Puro, RefCounted | §48 | 3 |
| src/core/clock_service.gd §70 | O autoload de trinta linhas que faz o relógio andar e emite os sinais | §70 | 0,5 |
| src/core/registry.gd | Carrega .tres por StringName | §44 | 2 |
| src/core/save_service.gd | Escrita atómica, versão, rotação de três slots | §62 | 4 |
| Estado e mundo mínimo — 5 |  |  |  |
| src/sim/state/game_state.gd | A estrutura do §45, ainda quase vazia | §45 | 2 |
| src/sim/state/unit_rec.gd | Uma tropa como linha de dados | §45 | 1 |
| src/sim/data/clock_data.gd §69 | O Resource que o GameClock do §30 recebe e que a v5 não criava | §44 | 0,5 |
| src/sim/data/unit_data.gd | O Resource completo do §44 | §44 | 1,5 |
| src/world/band_layers.gd | As três faixas, camadas de física, a matriz do §53 | §53 | 3 |
| src/world/camera_rig.gd | Uma câmara, limites, movimento em pixel inteiro | §59 | 3 |
| Apresentação mínima — 4 |  |  |  |
| src/world/parallax_stack.gd | Seis camadas com floor(), ainda com placeholders | §59 | 3 |
| src/actors/unit_view.gd | Os cinco slots empilhados, mais a sombra | §58 | 4 |
| shaders/palette_lut.gdshader | O shader que faz quatro trabalhos | §60 | 4 |
| scenes/boot.tscn §70 | A cena principal: Registry, idioma e save antes de o mundo existir | §70 | 1 |
| scenes/game.tscn | A cena raiz do jogo, com a pilha do §59 montada | §59 | 3 |
| Testes — 2 |  |  |  |
| tests/architecture_test.gd | G1, G3, G4 | §64 | 2 |
| tests/clock_test.gd | Passo fixo, fronteiras de fase, 360 s por dia | §48 | 1,5 |


> **Os dois spikes de duas horas que pertencem à Fase 0**
>
> (1) PointLight2D com normal map e filtro Nearest, para veres com os teus olhos o que ele faz aos pixels antes de construíres a pilha de luz em cima. (2) A escada de escalas: 1280×720 em ecrãs de 1080p e no Steam Deck, com fractional e com integer, lado a lado. Ambas são decisões que custam semanas se forem descobertas na Fase 5, e duas horas agora.

## Critério de saída, verificável

- **Funcional** — Um sprite move-se em X na superfície, desce por uma passagem para o subsolo e sobe para a faixa aérea. As três faixas têm colisão separada e provada por teste.
- **Determinismo** — test_seed_reproduz passa com uma simulação vazia mas com relógio a correr.
- **CI** — Verde nos cinco portões, em menos de 90 segundos.
- **Orçamento** — ≈ 63 h com a §68 incluída (54 h só de jogo) de trabalho, somando a coluna acima. A um ritmo de dez horas por semana, cabe no mês — e sobra folga para os dois spikes.
- **Arte** — Sombras de contacto e CanvasModulate por plano a funcionar — o degrau 1 da pilha de iluminação (§22). Três horas, e melhora toda a arte futura.
