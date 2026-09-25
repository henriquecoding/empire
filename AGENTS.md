# Empire — contrato do agente

Vale para qualquer agente. O CLAUDE.md tem tres linhas a apontar para aqui.
Se leres um unico ficheiro deste repositorio, e este.

## O que e
Kingdom-builder 2D em pixel art. Godot 4.6, GDScript. Mundo 1.5D com tres
faixas verticais: AERIAL, SURFACE, UNDERGROUND.

## Onde esta a verdade
- Design e especificacao: docs/design/ — um ficheiro por seccao, gerado do
  dossie por tools/split_dossie.py. NAO editar a mao.
- Decisoes tomadas, e porque: docs/adr/
- A tarefa desta sessao: docs/backlog/<id>.md
- Duvida que a spec nao cobre: escreve-a em docs/QUESTIONS.md. Nao decidas tu.
- Asset em falta: placeholder de cor lisa em art/export/_placeholder/ e uma
  linha em docs/ASSETS_TODO.md.
- Numeros de balanceamento: data/source/*.csv (v5.2). Dicionario e regras em
  docs/content/CONTENT_DATABASE.md; esquema em docs/content/SCHEMA.md.
  Nunca edites um .tres a mao: edita o CSV e corre
  godot --headless --path . -s tools/csv_to_tres.gd
- Nomes, ids e termos: docs/content/NAMING_BIBLE.md e
  docs/localization/GLOSSARY.csv. Texto visivel: so por chave, em
  data/i18n/strings.csv.
- Producao (arte, mundo, UX, audio, QA): docs/art/, docs/world/, docs/ux/,
  docs/audio/, docs/qa/. Nomes de ficheiro de arte: docs/art/ASSET_BIBLE.md.

## Regras absolutas
1. Maximo 250 linhas por script. O gdlint chumba — nao e um conselho.
2. src/sim/ nao importa de nenhuma camada acima e nao usa Node, Node2D nem
   qualquer classe de cena. E logica pura. Posicao entra como parametro.
3. Balanceamento vive em data/**/*.tres, gerado de data/source/*.csv.
   Nunca escrevas um numero de balanceamento dentro de um script.
4. Toda a funcao publica de src/sim/ tem teste em tests/. O teste vem primeiro.
5. Tipos sempre anotados: func f(x: int) -> void. Sem excecoes.
6. Aleatoriedade so pelo RngService, com fluxo nomeado. Nunca randi, randf
   nem randomize fora de src/core/rng_service.gd.
7. Sinais: so os que existem no catalogo (docs/design/46-*.md).
8. Sem dependencias novas sem uma ADR em docs/adr/.
8b. Nenhum autoload le outro autoload no _ready(). A ordem em que correm e a
    ordem de declaracao no project.godot — implicita, e por isso proibida
    (ADR 0020). Carrega a pedido, na primeira utilizacao.
9. Nao toques em art/ nem em audio/.
10. Colunas "_" nos CSV sao documentacao. Um campo listado em _proposed e uma
    proposta por aprovar: se a tarefa depender dele, diz-o em docs/QUESTIONS.md
    em vez de o tratar como decidido.

## Vocabulario — codigo em ingles, dossie em portugues
Band -> faixa (AERIAL|SURFACE|UNDERGROUND) · Rot -> A Podridao ·
People -> povo (Enramados, Portuarios, Fenda, Horta, Fornalha, SobRaiz) ·
Craft -> oficio (builder, smith, cook, diplomat, bard) · Boost -> impulso ·
Greed -> ganancia (0-100) · RoyalSeed -> Semente Real · Favor -> favor

## Caminhos canonicos — se dois documentos divergirem, esta tabela manda
src/sim/band.gd             Band          enum, planos de imagem, GROUND_LINE
src/sim/game_clock.gd       GameClock     relogio puro (RefCounted)
src/core/clock_service.gd   ClockService  autoload; traduz o relogio em sinais
src/core/sim_loop.gd        SimLoop       autoload; os onze passos do §43 (ADR 0020)
src/core/event_bus.gd       EventBus      autoload; os 61 sinais da §46
src/core/rng_service.gd     RngService    autoload; os seis fluxos (§42)
src/core/registry.gd        Registry      autoload; os .tres por StringName
src/core/save_service.gd    SaveService   autoload; store_var/get_var(false)
src/core/sim_factory.gd     SimFactory    monta os sistemas puros a partir do Registry
src/core/event_relay.gd     EventRelay    traduz o que os sistemas devolvem para a §46
src/core/intent_queue.gd    IntentQueue   a fila de intencoes do §61
src/core/night_watch.gd     NightWatch    o ciclo da noite: nascer, invocar, recuar
src/core/verbs.gd           Verbs         o Verbo 2 e o gatilho direito (§24, §61)
src/sim/state/game_state.gd GameState     o estado autoritativo (§45)
src/sim/systems/contact_queue.gd ContactQueue os slots de contacto e a fila (§50)
src/sim/systems/posts.gd    Posts         o que um posto acrescenta a quem o ocupa (§07)
src/sim/systems/morale_system.gd MoraleSystem moral, fuga e o raio do rei (§07)
src/sim/systems/passages.gd Passages    quem muda de faixa, e onde (§11, §53)
src/sim/systems/amargueiro_system.gd AmargueiroSystem quem fica no campo cria raiz (§74)
src/sim/systems/offer_system.gd OfferSystem a Oferta: uma por noite, no prato (§75)
src/sim/systems/debt_ledger.gd DebtLedger  a Divida da Candeia, que nunca desce (§75)
src/core/offer_desk.gd      OfferDesk     quando a mancha fala, o preco e o efeito (§75)
src/sim/state/columns.gd    Columns       gravar e repor um sistema de colunas (§62)
src/core/sim_save.gd        SimSave       que coleccoes da §45 entram no save
src/world/boot.gd           (script)      o que a boot.tscn corre (ADR 0005)
src/world/game.gd           Game          o que a game.tscn corre (ADR 0005)
src/world/greybox.gd        Greybox       monta a regiao enquanto nao ha segmentos (GB-01)
src/world/band_view.gd      BandView      desenha UMA faixa, e leva a luz dela
src/world/terrain_backdrop.gd TerrainBackdrop o cenario da faixa, so quando a luz muda
src/world/terrain_art.gd    TerrainArt    o cenario de cada faixa (§11, §22)
src/world/prop_art.gd       PropArt       a arvore e a casa, o que o cenario repete
src/world/actor_art.gd      ActorArt      o que uma tropa E, por dentro da caixa (§22, §24)
src/world/creature_art.gd   CreatureArt   o que um bicho E, por dentro da caixa (§22, §25)
src/world/rot_view.gd       RotView       a mancha, o rasto e a candeia (§74, §80)
src/world/amargueiro_view.gd AmargueiroView a arvore com a cara na casca, e o Marco (§74)
src/world/offer_view.gd     OfferView     o prato e a frase da Oferta (§75)
src/world/build_view.gd     BuildView     as obras, desenhadas pela forma delas (§25, §55)
src/world/structure_art.gd  StructureArt  o que cada obra E, por dentro do contorno (§25, §55)
src/world/silhouette.gd     Silhouette    o que cada coisa E, em forma (§22, Q-079)
src/world/outline.gd        Outline       o contorno de cada forma, em centesimos da caixa
src/world/gauge.gd          Gauge         os instrumentos do greybox: vida, saco, pago (GB-03)
src/world/price_tag.gd      PriceTag      o preco do que esta debaixo do rei (§24, §55, GB-05)
src/world/impact_view.gd    ImpactView    o golpe que se ve: flash e particula (§24, GB-08)
src/world/shadow.gd         Shadow        a sombra de contacto (§22, §24, GB-09)
src/world/lighting.gd       Lighting      quanta luz chega a cada coisa (§22, §74, §80)
src/world/world_palette.gd  WorldPalette  as cores e a geometria do greybox
src/world/band_light.gd     BandLight     a luz de cada faixa por fase (§80, ADR 0011)
src/world/world_light.gd    WorldLight    as tres paragens da luz e o raio da candeia
src/world/band_layers.gd    BandLayers    camadas e mascaras de fisica
src/world/camera_rig.gd     CameraRig     camara unica
src/ui/input_router.gd      InputRouter   entrada -> intencoes; nunca muda estado (§61)
src/ui/hud.gd               Hud           o painel do greybox, e nao o HUD do §24
src/ui/game_hud.gd          GameHud       o painel de quem joga (§24)
src/ui/inspector.gd         Inspector     o estado de cada sistema, a pedido (Q-067)
scenes/boot.tscn                          cena principal do project.godot
scenes/game.tscn                          a cena de jogo, instanciada pela boot

## Quem pode importar quem (a tabela da §70, completa — v5.2)
Caminho                     Classe                 Camada        Pode importar de
src/sim/band.gd             Band                   simulacao     nada
src/sim/game_clock.gd       GameClock              simulacao     ClockData
src/sim/data/*.gd           *Data, *Profile, *Curve simulacao    Resource, Band
src/sim/state/*.gd          GameState, UnitRec...  simulacao     sim/
src/sim/systems/*.gd        EconomySystem...       simulacao     sim/
src/core/clock_service.gd   ClockService           nucleo        sim/
src/core/sim_loop.gd        SimLoop                nucleo        core/, sim/
src/core/sim_factory.gd     SimFactory             nucleo        core/, sim/
src/core/event_relay.gd     EventRelay             nucleo        core/, sim/
src/core/night_watch.gd     NightWatch             nucleo        core/, sim/
src/core/verbs.gd           Verbs                  nucleo        core/, sim/
src/core/offer_desk.gd      OfferDesk              nucleo        core/, sim/
src/core/intent_queue.gd    IntentQueue            nucleo        nada
src/core/event_bus.gd       EventBus               nucleo        nada
src/core/rng_service.gd     RngService             nucleo        nada
src/core/registry.gd        Registry               nucleo        sim/
src/core/save_service.gd    SaveService            nucleo        sim/
src/world/*.gd              BandLayers, CameraRig  apresentacao  core/, sim/
src/actors/*.gd             UnitView, KingView...  apresentacao  core/, sim/
src/ui/*.gd                 InputRouter, Hud...    apresentacao  core/, sim/
scenes/boot.tscn            (cena principal)       cenas         tudo
tools/*.gd, tools/*.py      ferramentas            fora do jogo  tudo; nunca exportado
tools/vistoria.gd           Vistoria/Autopilot     fora do jogo  uma partida longa, vigiada
ferramentas/*.mjs, src/*.js camada de uso do dossie fora do jogo  docs/; nunca exportado

## Ciclo de trabalho
1. Le docs/backlog/<id>.md e as seccoes de docs/design/ que ele cita.
2. Escreve ou atualiza o teste em tests/. Confirma que falha.
3. Implementa o minimo que o faz passar.
4. Corre ./run_tests.sh — e `make vistoria` se mexeste no tick ou no mundo.
5. So com tudo verde, propoe o diff, com a checklist do PR preenchida.

## O que nao fazer
- Nao inventes mecanicas. Se a spec nao cobre o caso, escreve a pergunta em
  docs/QUESTIONS.md e implementa a opcao mais simples e mais reversivel.
- Nao refatores fora do ambito da tarefa.
- Nao escrevas comentarios que repetem o codigo.
- Nao uses load() nem ResourceLoader.load em ficheiros de save (sao a mesma
  funcao): FileAccess.get_var(false). Ver docs/adr/0007-save-security.md (v5.2)
- Nao mudes um numero em data/ para fazer um teste de design passar. Um teste
  de design a falhar e informacao, nao um obstaculo.
- Nao apagues nem comentes um teste saltado. Um teste saltado leva a razao e o
  nome do sistema que falta; e a lista do que falta (ADR 0019).
- Nao escrevas a mao um numero que a ferramenta conta. O dossie, o README e o
  painel de estado leem docs/recovery/validation.json e os CSV; um numero
  escrito a mao diverge no primeiro dia e ninguem da por isso.
