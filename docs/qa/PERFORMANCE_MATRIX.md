# Matriz de desempenho

> Alvo do §63: **60 fps no Steam Deck com 300 unidades no ecrã** — 16,6 ms por *frame*. Os números do §63 são
> **orçamentos, não medições**: o teste falha quando se ultrapassam. E a ordem de otimização também é do dossiê:
> **mede primeiro, muda dados depois, código só em último caso.**

## 1 · Os orçamentos

| Item | Orçamento | Como se mede | Se estourar | Fonte |
|---|---|---|---|---|
| Simulação, tick completo | **4,0 ms** | *profiler* de *tracing* (Tracy/Perfetto) | sobe `AI_SLICE` antes de otimizar código | §63 |
| — `CombatSystem` | 1,5 ms | marcador dedicado | reduz *slots* de contacto, não unidades | §63 |
| — `MovementSystem` | 1,0 ms | marcador dedicado | *steering* só contra os 4 vizinhos | §63 |
| — `UnitSystem` (FSM) | 0,8 ms | marcador dedicado | fatiamento para 1/8 | §63 |
| *Draw calls* | ≤ 120 | monitor do Godot | mais `MultiMeshInstance2D` | §63 |
| Nós ativos | ≤ 900 | monitor do Godot | *pooling*; fora do ecrã sem nó | §63 |
| Vozes de áudio | ≤ 24 | contador próprio | prioridade por proximidade | §63 |
| Memória de texturas | ≤ 512 MB | monitor do Godot | na web, máx. 1024 px por textura | §63 |
| Arranque até jogável | ≤ 4 s | teste de cena | `.tres` em segundo plano | §63 |
| Luzes com sombra | ≤ 3 (as mais próximas da câmara) | contagem | o resto são *sprites* aditivos | §19, §22 |
| Gravação | ≤ 200 ms, sem soluço visível | marcador à volta do `SaveService` | serializar fora do *frame* | proposta |
| Geração de uma região | ≤ 1 s | marcador à volta do `WorldGen.generate` | *cache* das paisagens por *seed* | proposta |
| Partículas no ecrã | ≤ 400 | contador próprio | reduz por prioridade (VFX_REGISTER) | proposta |

## 2 · As máquinas

Proposta de perfis, para fixar quando comprares ou pedires emprestado o *hardware* (o Deck está no orçamento do
§35 e não é opcional se queres Verified):

| Perfil | Exemplo | Alvo |
|---|---|---|
| PC fraco | portátil com gráfica integrada (classe Intel UHD / Radeon Vega), 8 GB | 60 fps a 720p e 1080p |
| PC médio | GTX 1060 / RX 580, 16 GB | 60 fps até 1440p |
| PC forte | RTX 3070 ou superior, 32 GB | 60 fps a 4K; é o teste de ultralargo |
| **Steam Deck** | LCD ou OLED, 1280 × 800 | **60 fps**; o mínimo Verified é 30 fps nas definições por omissão (§26) |

## 3 · Os cenários

Cada cenário é uma cena de `scenes/tests/` com *seed* fixa, para ser repetível:

| Cenário | O que carrega | Existe em |
|---|---|---|
| C1 · Noite do dia 20 | 300 unidades, Podridão com massa do dia 20, 3 luzes com sombra, fogo, névoa | F1-03 / F1-15 |
| C2 · Amanhecer | transição de luz, `CanvasModulate` nos 5 planos, raios, sino | F1-13 |
| C3 · Região nova | `WorldGen.generate` × 3 regiões | F1 (mundo mínimo) |
| C4 · Gravar e carregar | save a meio da noite 9 e retoma | F1-14 |
| C5 · Explosões | 5 barris de fogo + mancha + 60 flechas | Fase 2 |
| C6 · Menu parado | título e opções — tem de estar perto de zero de CPU | Fase 4 |

## 4 · A matriz

Uma linha por combinação que se testa; a primeira coluna é o que falta medir. Preenche `—` com o número e a data.

| Máquina | Resolução | Escala | C1 fps / ms | C1 sim ms | Draw calls | Nós | Memória | Arranque | Gravação | Região |
|---|---|---|---|---|---|---|---|---|---|---|
| Steam Deck | 1280 × 800 | 1× | — | — | — | — | — | — | — | — |
| PC fraco | 1280 × 720 | 1× | — | — | — | — | — | — | — | — |
| PC fraco | 1920 × 1080 | `fractional` 1,5× | — | — | — | — | — | — | — | — |
| PC fraco | 1920 × 1080 | `integer` + barras | — | — | — | — | — | — | — | — |
| PC médio | 2560 × 1440 | 2× | — | — | — | — | — | — | — | — |
| PC forte | 3840 × 2160 | 3× | — | — | — | — | — | — | — | — |
| PC forte | 3440 × 1440 (21:9) | 2×, largura limitada a 1,25 × 16:9 | — | — | — | — | — | — | — | — |
| Web (demo) | 1280 × 720 | 1× | — | — | — | — | — | — | — | — |

A linha `integer` vs `fractional` no 1080p é o **spike de duas horas da Fase 0** (§65): decide a ADR 0001 lado a
lado, a olhar, e fica registada aqui com as capturas.

## 5 · Registo de uma medição

```text
Data / build:     ____-__-__ / <commit>
Máquina:          ______   Resolução: ______   Escala: ______
Cenário:          C_       Seed: ______
fps (média/1% low): ___ / ___    frame time p95: ___ ms
Simulação: total ___ ms · combate ___ · movimento ___ · FSM ___
Draw calls ___ · nós ___ · vozes ___ · memória de texturas ___ MB · partículas ___
Arranque ___ s · gravação ___ ms · região ___ ms
Estourou? ______  O que se mudou (dados primeiro): ______
```
