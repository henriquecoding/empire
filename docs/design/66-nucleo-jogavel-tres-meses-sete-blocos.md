# 66 — Fase 1 · Núcleo jogável — três meses, sete blocos

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Critério de saída: sobreviver 10 dias é possível e não é trivial. Cenário em blocos de cor lisa; personagens já animadas por cima. Ao sábado, arranca o cenário da Fase 2 em paralelo.

| Bloco | Ficheiros | Critério de aceitação |
| --- | --- | --- |
| Economia mínima | sim/systems/economy_system.gd · build_system.gd · data/building_data.gd · state/building_rec.gd · coin_rec.gd | Largar uma moeda num slot constrói. Uma plantação produz. O dia de asfixia cai entre 9 e 14 no teste de design. |
| Tropas e trabalho | sim/systems/unit_system.gd · job_system.gd · movement_system.gd · ai/unit_fsm.gd | Recrutar um vagabundo com uma moeda; ele vai sozinho para o posto certo e volta ao amanhecer. 300 unidades dentro do orçamento do §63. |
| Combate | sim/systems/combat_system.gd · state/wall_rec.gd · data/wall_data.gd · creature_data.gd | Slots de contacto, fila estável, precisão por posição. As quatro tabelas de tempo-até-matar batem certo com o §07, em valor esperado. |
| A Podridão | sim/systems/rot_system.gd · state/rot_state.gd · data/rot_profile.gd | Nasce no crepúsculo, avança, invoca dentro do orçamento de massa, deixa rasto, recua ao amanhecer. Vê-se chegar do outro lado do ecrã. |
| Uma noite completa | scenes/tests/night_test.tscn · tests/sim_harness.gd | Corre em headless com delta fixo, dez dias em menos de dez segundos. É o instrumento que vai balancear o jogo inteiro. |
| Mundo mínimo | sim/worldgen/world_gen.gd · segment_data.gd · 8 cenas de segmento em greybox | Uma região gerada por seed, com paisagem contínua e segmentos montados. A mesma seed dá o mesmo mundo. |
| Save | migração 1→1, integração com DAWN | Gravar a meio da noite 9 e retomar continua a mesma noite, com a mesma sequência aleatória. |


## Os primeiros doze commits, por ordem de dependência

1. Esqueleto, CI e os cinco portõesAntes de qualquer jogo. Um repositório com CI verde e nenhum código é melhor ponto de partida do que um protótipo sem testes.

## Band, camadas de física e a matriz

A invariante I3. Se entrar depois, reescreves.

## EventBus com os 61 sinais

Declarados todos de uma vez, mesmo os que só serão usados na Fase 6. Um catálogo incompleto convida a inventar.

## RngService e test_seed_reproduz

O teste passa trivialmente agora e vai proteger-te durante dois anos.

## GameClock e o teste do ciclo

360 segundos, seis fases, fronteiras a emitir.

## csv_to_tres e os primeiros CSV

Unidades e criaturas. A partir daqui, balancear é editar uma folha.

## GameState, UnitRec, SaveService

Gravar e carregar um estado vazio. Fazer isto cedo é o que torna o save trivial para sempre.

## MovementSystem e UnitView

Um sprite anda. É o critério de saída da Fase 0 e a primeira coisa que se parece com um jogo.

## Moeda física e BuildSystem

O Verbo 1. A partir daqui há decisões a tomar no ecrã.

## JobSystem e a FSM

As tropas passam a ir sozinhas para onde fazem falta. O jogo começa a jogar-se.

## CombatSystem e SimHarness

Os dois juntos, sempre: combate sem instrumento de simulação é balanceamento às cegas.

## RotSystem e a primeira noite

O momento em que este projeto deixa de ser um clone do Kingdom.
