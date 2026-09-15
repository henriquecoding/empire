# 29 — Prompts · novo · A biblioteca de prompts, por sistema

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Pediste a melhor forma de a IA construir isto. A resposta não é um prompt gigante — é uma forma fixa de pedir, repetida trinta vezes. Um pedido vago produz 400 linhas plausíveis e erradas; um pedido com contrato produz 120 linhas revisíveis.

## O molde. Usa-o sempre.

```gdscript
CONTEXTO   Empire, Godot 4.6, GDScript. Le CLAUDE.md e docs/design/<ficheiro>.md.
TAREFA     <uma frase, um verbo>
FICHEIROS  Cria/altera SO: <lista explicita de caminhos>
CONTRATO   Assinaturas publicas exatas:
             func nome(arg: Tipo) -> Tipo   # o que faz, numa linha
DADOS      Le de: data/<caminho>.tres — campos: <lista>
TESTES     Escreve primeiro tests/<nome>_test.gd cobrindo: <3-6 casos, com numeros>
LIMITES    Nao toques em <lista>. Maximo 250 linhas. Sem dependencias novas.
SAIDA      Diff. Depois, uma frase sobre o que ficou por fazer.
```

## Cinco prompts reais, prontos a colar

### 1 · O relógio do jogo — a primeira coisa que constróis

```gdscript
TAREFA Implementar o GameClock: ciclo de 360 s com seis fases.
FICHEIROS src/core/game_clock.gd, tests/game_clock_test.gd
CONTRATO
  enum Phase { DAWN, MORNING, NOON, AFTERNOON, DUSK, NIGHT }
  signal phase_changed(from: Phase, to: Phase)
  signal day_started(day: int)
  func tick(delta: float) -> void
  func current_phase() -> Phase
  func phase_progress() -> float      # 0.0-1.0 dentro da fase atual
  func seconds_until(p: Phase) -> float
DADOS data/economy/clock.tres — duracoes: 15/85/40/85/30/105, day_length 360.0
TESTES
  - tick(360.0) num so passo avanca exatamente 1 dia e emite day_started(2)
  - aos 75 s a fase e MORNING e phase_progress ~= 0.706   # (75-15)/85
  - aos 15.0 s exatos ja e MORNING, nao DAWN (fronteira fechada a esquerda)
  - seconds_until(NIGHT) aos 0 s == 255.0
  - alterar day_length no .tres para 180 mantem as proporcoes
LIMITES Sem Node. E um RefCounted. Nao usa get_process_delta_time.
```

Repara no quarto teste: 15+85+40+85+30 = 255. Dar o número calculado ao agente é o que impede uma implementação que passa nos testes por acidente.

### 2 · A Podridão — o sistema que te distingue

```gdscript
TAREFA Implementar RotSystem: entidade com posicao, massa e invocacao.
FICHEIROS src/sim/rot_system.gd, tests/rot_system_test.gd
CONTRATO
  func spawn(day: int, side: int, map_width: float) -> void
  func tick(delta: float, consecrated: Array[Vector2]) -> Array[SpawnRequest]
  func mass() -> float
  func feed(amount: float) -> void
  func position_x() -> float
  func retreat() -> void
REGRAS
  velocidade = 14.0 + 0.9 * dia, px/s
  massa      = 40.0 + 18.0 * dia + 30.0 * fortalezas_conquistadas
             + 22.0 * amargueiros + 45.0 * amargueiros_nomeados
             + 8.0 * min(recusas_nos_ultimos_5_dias, 5)          # §74, §75
  invoca a cada 4-7 s (RNG com seed), gastando o custo de massa da criatura
  sobre terreno consagrado: velocidade * 0.6
  feed(x) reduz massa em x, minimo 0
DADOS data/rot/default.tres, data/creatures/<id>.tres   # a §70 acabou com waves/
TESTES
  - dia 1: velocidade == 14.9
  - dia 10 com 2 fortalezas, campo limpo: massa == 280.0
  - tick nao devolve SpawnRequest se massa < custo da criatura mais barata
  - 30 s sobre consagrado percorre 60% da distancia de 30 s em terreno normal
  - feed(1000) poe massa a 0, nunca negativa
  - com a mesma seed, duas corridas produzem a mesma sequencia de invocacoes
LIMITES Sem Node. Devolve pedidos; nao instancia nada.
```

### 3 · Economia — onde vive o balanceamento

```gdscript
TAREFA Implementar Economy: rendimento, sorvedouros e a curva de asfixia.
FICHEIROS src/sim/economy.gd, tests/economy_test.gd
CONTRATO
  func daily_income(sources: Array[SourceData], day: int) -> float
  func trade_income(routes: int, day: int) -> float   # efeito de rede a partir da 2.a
  func upkeep(troop_count: int) -> float
  func greed_cut(gross: float, greed: int) -> float
  func net_income(...) -> float
  func night_cost(day: int) -> float
  func suffocation_day(profile: EconomyProfile) -> int
REGRAS
  upkeep: 0 ate 8 tropas; 0.5/dia entre 9 e 20; 1.5/dia acima de 20
  night_cost(d) = 6.1 * pow(1.22, d - 1)
  income cresce a pow(1.12, d-1) sobre a base; upkeep e constante,
  por isso o liquido cresce mais depressa que 1.12 — ver §06
  trade_income = rotas * 4.5 * pow(1.08, d-1) * (1 + 0.10 * max(0, rotas-1))
TESTES
  - upkeep(8) == 0.0 ; upkeep(14) == 3.0 ; upkeep(25) == 13.5
  - greed_cut(100, 28) == 28.0
  - suffocation_day do perfil "equilibrado" cai entre 9 e 14  <- TESTE DE DESIGN
  - cada rota de comercio ADIA a asfixia em ~2 dias (retorno decrescente)
  - trade_income(0, d) == 0.0 para todo o d
  - greed 80 antecipa a asfixia em pelo menos 3 dias face a greed 20
LIMITES Puro. Determinista. Sem RNG.
```

> **O terceiro teste é o mais importante do projeto**
>
> suffocation_day entre 9 e 14 não é um teste de código — é um teste de design que corre no CI. Se alguém (tu ou a IA) mexer num número de balanceamento que quebre a curva, o build falha. É a única forma que conheço de manter uma economia afinada durante dois anos de alterações. Escreve testes destes para tudo o que tem um intervalo-alvo: duração da noite 1, custo de subir a primeira muralha, tempo médio até à primeira montaria.

### 4 · Atribuição de trabalho — o algoritmo do Kingdom

```gdscript
TAREFA Implementar JobBoard: atribuir tropas a postos, uma vez por fase.
FICHEIROS src/sim/job_board.gd, tests/job_board_test.gd
CONTRATO
  func post(job: JobSlot) -> void
  func assign(units: Array[UnitState], phase: int) -> Dictionary  # unit_id -> job_id
REGRAS
  score = adequacao(unidade, posto) * proximidade * urgencia(fase)
  proximidade = 1.0 / (1.0 + distancia_x / 400.0)
  a NOITE, postos de muro e torre tem urgencia 3.0; plantacao tem 0.0
  atribuicao e estavel: uma unidade so muda de posto se o score novo
  superar o atual em mais de 15% (histerese, evita tremeliques)
TESTES
  - de noite, nenhum arqueiro fica atribuido a plantacao
  - com 2 postos de muro e 5 arqueiros, exatamente 2 sao atribuidos
  - correr assign() duas vezes seguidas com o mesmo estado nao muda nada
  - uma unidade a 800 px perde para uma a 100 px com adequacao igual
LIMITES Sem Node. Sem alocacoes dentro do ciclo principal.
```

### 5 · Uma cena — o único caso em que o MCP compensa

```gdscript
TAREFA Montar a cena de teste de combate noturno.
USA o servidor MCP do Godot. Guarda em disco no fim.
CENA scenes/tests/night_fight.tscn
  Node2D "NightFight"
   +- Camera2D            (position 640,360; zoom 1,1)
   +- CanvasModulate      (color #1B2A4A)
   +- TileMapLayer "Ground"
   +- Node2D "Wall"       (position 640, Band.GROUND_LINE) -> scenes/buildings/wall.tscn
   +- Node2D "Spawns"     6 Marker2D em x = 1100..1400, y = Band.GROUND_LINE
   +- Node2D "Units"      (vazio; preenchido em runtime)
   +- Label "Debug"       (canto sup. esq., 12 px, mostra dia/fase/massa)
DEPOIS Corre a cena e cola as 20 primeiras linhas da consola.
LIMITES Nao alteres nenhuma cena existente.
```

## Quatro erros que vão custar-te semanas

**Pedir "o sistema de combate"** — Demasiado grande. Divide sempre em: dados → resolução → apresentação → integração. Quatro sessões, quatro diffs pequenos.

Se o agente diz "os testes passariam", não passaram. Corre a suite. É a diferença entre revisão e fé.

Se não deres o valor, ele escolhe um plausível e enterra-o num script — exatamente onde não deve estar. Dá sempre o número, ou diz onde o ir buscar.

Ao fim de uma hora o contexto está poluído e a qualidade cai. Uma tarefa, uma sessão, um merge. Fecha e recomeça.
