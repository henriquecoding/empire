# 19 — Engenharia · Arquitetura Godot 4.6

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

> **Esta secção é o esboço; a especificação está na §39**
>
> O que se segue são as decisões de arquitetura e as definições de projeto. O modelo de dados completo, o catálogo de eventos, a ordem do tick e os critérios de aceitação por fase estão nas §39 a §67, e é contra essas que o código se escreve e se revê.

O Godot 4.6 saiu em janeiro de 2026. Nada nele muda a arquitetura abaixo — mas três coisas mudam a velocidade a que trabalhas com IA: docks móveis, previews de recursos em tempo real no Quick Open, e variáveis @export criadas por arrastar um recurso para o editor de scripts. Há também suporte para profilers de tracing (Tracy, Perfetto, Instruments), que é o que vais usar quando tiveres 300 unidades no ecrã.

## Configurações de projeto — copiar tal e qual

| Definição | Valor | Porquê |
| --- | --- | --- |
| Display › Window › Viewport | 1280 × 720 | Medido na tua arte (§01). Não reduzir. |
| Stretch › Mode | canvas_items | Câmara suave sem tremer os pixels |
| Stretch › Scale Mode | fractional, com opção integer | Ver a decisão da escada de escalas, abaixo |
| Stretch › Aspect | keep | Barras finas em vez de deformação |
| Textures › Default Filter | Nearest | Pixels nítidos |
| 2D › Snap Transforms to Pixel | Off | Deixa o subpixel à câmara; ligar isto causa jitter nas tropas |
| Physics Ticks per Second | 30 | Metade do render. Suficiente para IA de tropas e poupa CPU com 300 unidades |
| Rendering › Renderer | Mobile | Melhor para 2D e para export web; Forward+ é desperdício aqui |


## O problema da escada de escalas — e a decisão

1280×720 é a resolução certa para a tua arte, mas tem um custo: 1080p não é múltiplo inteiro de 720p (é 1,5×), e 1080p é o ecrã mais comum do mundo.

| Ecrã | Fator | Resultado |
| --- | --- | --- |
| 1280 × 720 | 1,0× | Perfeito |
| Steam Deck 1280 × 800 | 1,0× | Perfeito, com barras de 40 px |
| 1920 × 1080 | 1,5× | Pixels desiguais — uns com 1 px, outros com 2 |
| 2560 × 1440 | 2,0× | Perfeito |
| 3840 × 2160 | 3,0× | Perfeito |


> **Recomendação — decide isto na Fase 0**
>
> Escala fracionária com filtro suave por omissão; nas Opções, um interruptor "pixels nítidos" que passa a escala inteira com barras; e a largura visível limitada a um máximo (por exemplo 1,25× do rácio 16:9) para que ecrãs ultralargos não ganhem vantagem em ver A Podridão chegar mais cedo. A câmara e o enquadramento dependem desta decisão — tomá-la depois custa uma reescrita.

## Estrutura de pastas

```gdscript
res://
├─ CLAUDE.md              # contrato do agente (§28)
├─ docs/
│  ├─ design/            # este dossiê, dividido por sistema
│  └─ adr/               # decisões arquitetónicas, uma por ficheiro
├─ data/                 # TUDO o que é balanceamento (.tres)
│  ├─ peoples/           # enramados.tres, portuarios.tres...
│  ├─ units/             # enramados_arqueiro.tres, fenda_ariete.tres...
│  ├─ buildings/  biomes/  classes/  waves/  economy/
├─ src/
│  ├─ core/              # autoloads: EventBus, GameClock, SaveService, RNG
│  ├─ sim/               # simulação PURA, sem nós: economia, moral, podridão
│  ├─ actors/            # Unit, Builder, King, Mount, Creature
│  ├─ world/             # WorldGen, Chunk, Band, Camera
│  ├─ ui/  net/
├─ scenes/
├─ art/
│  ├─ source/            # .aseprite (Git LFS)
│  └─ export/            # .png + .json gerados (NÃO versionar)
├─ audio/  shaders/
└─ tests/                # gdUnit4
```

> **A regra que faz a IA funcionar**
>
> src/sim/ não pode importar nada de src/actors/ nem tocar em nós. É lógica pura, testável sem abrir o Godot. Toda a economia, moral, ganância, dívida e progressão da Podridão vivem aí. É a única forma de escreveres testes rápidos e de deixares a IA mexer em regras sem partir cenas. Se um agente puser um Node2D dentro de src/sim/, o teste falha e o CI trava o commit (§31).

## Dados como Resource

```gdscript
# src/sim/data/unit_data.gd
class_name UnitData extends Resource

@export var id: StringName
@export var display_name: String
@export_group("Combate")
@export var max_health: int = 10
@export var damage: int = 0
@export var attack_interval: float = 1.2
@export var accuracy_open: float = 0.34   # 1.0 dentro de torre
@export_group("Economia")
@export var recruit_cost: int = 1
@export var upkeep_per_day: float = 0.0
@export_group("Mundo")
@export var band: Band.Kind = Band.Kind.SURFACE
@export var move_speed: float = 26.0
@export_group("Arte")
@export var sprite_frames: SpriteFrames
@export var layer_slots: Array[StringName] = [&"body", &"face", &"weapon"]
```

Cada tropa é um .tres. Balancear é editar tabelas — nunca código. Isto também significa que podes gerar todos os .tres a partir de um CSV e balancear numa folha de cálculo, que é exatamente o que a tabela do §07 é.

## Desempenho com centenas de unidades

| Problema | Solução | Ganho |
| --- | --- | --- |
| 300 nós com _process | Um UnitSystem itera arrays; unidades não têm _process | Grande |
| Vegetação e detritos (milhares) | MultiMeshInstance2D — uma draw call para tudo | Grande |
| Decisões de IA todos os frames | Time-slicing: 1/6 das unidades decide por tick | Grande |
| Instanciar/destruir tropas | Object pooling com pool por tipo | Médio |
| Colisões entre tropas | Sem colisão entre aliados; só separação por steering (§07) | Grande |
| Sprites fora do ecrã | VisibleOnScreenNotifier2D + LOD: fora do ecrã, simula mas não anima | Médio |
| Muitas PointLight2D com sombra | Sombras só nas 3 luzes mais próximas da câmara; as restantes são sprites aditivos | Grande |


## Save

Um Dictionary de tipos base validados contém o estado de src/sim/ e as posições das entidades. Grava-se com FileAccess.store_var e lê-se com FileAccess.get_var(false), conforme a ADR 0007. O esquema e a migração são explícitos; nenhum Resource é carregado a partir de um save. Regras não negociáveis:

- Escreve para ficheiro temporário e só depois renomeia. Um crash a meio da escrita não pode destruir o save.
- Campo save_version: int desde a v1, com migrações explícitas. Um jogador que perca 40 horas por causa de um update não volta.
- Três slots com rotação em user://, auto-save no amanhecer de cada dia.
- Nunca uses load() num ficheiro de save. Um .tres arbitrário pode conter script embutido — é uma execução remota de código disfarçada. Grava tipos base com FileAccess.store_var(dados, false) e lê com FileAccess.get_var(false); valida os campos. Nunca uses ResourceLoader.load num save (ADR 0007, Q-036).

## Steam, Steam Deck e web

- GodotSteam para conquistas, estatísticas, cloud saves e sockets. É o GDExtension padrão do ecossistema e a Valve documenta o Godot como motor suportado.
- Steam Deck: 1280×800 → 1× nativo com 40 px de barras. O ecrã do Deck é praticamente a tua tela de autoria. §26 tem os critérios de verificação.
- Web: requer cabeçalhos COOP/COEP para threads. Mantém um ramo não-threaded como reserva e reduz o escopo da demo web (texturas máx. 1024, uma música em simultâneo) em vez de esperar que corra igual ao PC.
