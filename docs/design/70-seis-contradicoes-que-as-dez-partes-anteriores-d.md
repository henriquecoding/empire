# 70 — Correções · novo · Seis contradições que as dez partes anteriores deixaram abertas

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Um documento de setenta secções escrito em camadas contradiz-se em sítios pequenos. Nenhuma destas é grave enquanto ninguém escreve código — todas se tornam duas implementações do mesmo conceito assim que alguém escreve. Aqui ficam resolvidas, com a razão e não só com a escolha.

| Onde diverge | A contradição | Decisão |
| --- | --- | --- |
| O relógio §30 · §41 · §48 · §65 | A §30 escreve src/sim/game_clock.gd, puro, extends RefCounted. A §41 e a §65 põem src/core/game_clock.gd na lista de autoloads. Um autoload é um Node. | São dois ficheiros. src/sim/game_clock.gd é o relógio: puro, dono do estado, testável em milissegundos. src/core/clock_service.gd é um autoload de trinta linhas que chama tick(delta) no _physics_process e traduz o que ele devolve em sinais do EventBus. Zero lógica. |
| A faixa §34 · §47 · §65 | A §47 e a §65 põem Band em src/core/; a tarefa F0-05 da §34 põe-no em src/world/. Mas o UnitData (§19) declara band: Band.Kind e o RotSystem (§30) lê constantes de Band — ambos dentro de src/sim/. | src/sim/band.gd. Em core/ ou em world/, a simulação importaria de uma camada acima e o portão G1 chumbava no primeiro dia. As camadas de física ficam onde já estavam: src/world/band_layers.gd. |
| A linha do solo §30 · §47 | O código do §30 usa Band.GROUND_Y; o §47 define GROUND_LINE. Dois nomes para o mesmo número — exatamente o que a regra do vocabulário do §28 existe para evitar. | GROUND_LINE, corrigido na §30. O valor (517) continua em aberto até ao greybox, como diz a §67 — o nome é que não pode continuar a ser dois. |
| A câmara §34 · §41 · §65 | camera_rig.gd na §65, camera.gd na tarefa F0-08, CameraRig na árvore da §41. | src/world/camera_rig.gd, classe CameraRig. É rig e não câmara porque leva limites, lookahead e arredondamento a píxel inteiro — não é o nó do Godot. |
| O arranque §41 · §65 | scenes/boot.tscn está na árvore da §41 e não está em nenhuma das 23 linhas da §65, que faz de game.tscn a cena raiz. | boot.tscn é a cena principal do project.godot. Carrega o Registry, o idioma e o save, decide que game.tscn instanciar, e só depois entrega. Uma hora na Fase 0; poupa a reescrita do arranque quando o save entrar na Fase 1. |
| A árvore de data/ §19 · §41 | A §19 tem waves/; a §41 não tem, e acrescenta source/, crafts/, mounts/, segments/ e rot/. | A árvore da §41 é a canónica. Não há waves/: A Podridão substituiu as ondas (§05) e a §19 é anterior a essa decisão. |


> **A regra que decide as próximas — porque vão aparecer mais**
>
> Um tipo ou uma constante que a simulação lê vive na simulação. Um Node que a simulação nunca vê vive em core/ ou acima. Esta única frase resolve as seis linhas acima e todas as que vierem, porque é a invariante I1 (§40) traduzida em pergunta operacional: quem precisa disto mais abaixo na pilha?
>
> O corolário prático: quando hesitares entre core/ e sim/, escreve o teste primeiro. Se o teste tem de abrir o Godot para correr, puseste a coisa no sítio errado.

## A tabela canónica — cola isto no AGENTS.md

| Caminho | Classe | Camada | Pode importar de |
| --- | --- | --- | --- |
| src/sim/band.gd | Band | simulação | nada |
| src/sim/game_clock.gd | GameClock | simulação | ClockData |
| src/sim/data/*.gd | *Data | simulação | Resource, Band |
| src/sim/state/*.gd | GameState, UnitRec… | simulação | sim/ |
| src/sim/systems/*.gd | EconomySystem… | simulação | sim/ |
| src/core/clock_service.gd | ClockService (autoload) | núcleo | sim/ |
| src/core/event_bus.gd | EventBus (autoload) | núcleo | nada |
| src/core/rng_service.gd | RngService (autoload) | núcleo | nada |
| src/core/registry.gd src/core/save_service.gd | Registry, SaveService (autoloads) | núcleo | sim/ |
| src/world/band_layers.gd | BandLayers | apresentação | core/, sim/ |
| src/world/camera_rig.gd | CameraRig | apresentação | core/, sim/ |
| src/actors/*.gd | UnitView, KingView… | apresentação | core/, sim/ |
| scenes/boot.tscn | — (cena principal) | cenas | tudo |


> **O teste que torna esta tabela executável**
>
> O tests/architecture_test.gd já defende o G1 (nada em src/sim/ toca em nós). Acrescenta-lhe vinte linhas que percorrem src/sim/**/*.gd à procura de preload, load ou class_name de camadas acima, e a tabela deixa de depender de alguém a ler esta secção. É o mesmo princípio do max-file-lines da §69: uma regra que não chumba no CI não é uma regra, é uma preferência.
