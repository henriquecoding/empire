# 63 — Desempenho · Orçamentos, e como se medem

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

O alvo é 60 fps no Steam Deck com 300 unidades no ecrã. Isso dá 16,6 ms por frame, dos quais a simulação usa metade dos ticks. Os números abaixo são orçamentos, não medições — o teste de desempenho falha quando são ultrapassados.

| Item | Orçamento | Como se mede | Se estourar |
| --- | --- | --- | --- |
| Simulação, tick completo | 4,0 ms | Profiler de tracing (Tracy/Perfetto, §19) | Aumenta AI_SLICE antes de otimizar código |
| — CombatSystem | 1,5 ms | Marcador dedicado | Reduz slots de contacto, não unidades |
| — MovementSystem | 1,0 ms | Marcador dedicado | Steering só contra os 4 vizinhos mais próximos |
| — UnitSystem (FSM) | 0,8 ms | Marcador dedicado | Fatiamento para 1/8 |
| Render, draw calls | ≤ 120 | Monitor do Godot | Mais MultiMeshInstance2D |
| Nós ativos na cena | ≤ 900 | Monitor do Godot | Pooling; unidades fora do ecrã não têm nó |
| Vozes de áudio | ≤ 24 | Contador próprio | Prioridade por proximidade da câmara |
| Memória de texturas | ≤ 512 MB | Monitor do Godot | No export web, máx. 1024 px por textura |
| Tempo de arranque até jogável | ≤ 4 s | Teste de cena | Carregar .tres em segundo plano |


> **A ordem por que se otimiza**
>
> Nunca por instinto. Primeiro mede, depois muda dados (fatiamento, contagens, distâncias), e só em último caso muda código. Metade dos problemas de desempenho num jogo com 300 unidades resolvem-se com um número, não com uma reescrita — e uma reescrita feita por um agente sem medição é sempre pior do que o original.
