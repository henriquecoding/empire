# Empire — contrato do agente

Vale para qualquer agente. O CLAUDE.md tem tres linhas a apontar para aqui.
Se leres um unico ficheiro deste repositorio, e este.

## O que e
Kingdom-builder 2D em pixel art. Godot 4.7.2 (o pin de .godot-version), GDScript. Mundo 1.5D com tres
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
src/core/rules_factory.gd   RulesFactory  o que as respostas do painel trouxeram: precos, estatuas, estrago (ADR 0027)
src/core/pace.gd            Pace          a roda abranda o tempo saltando passos (Q-034)
src/core/dark_watch.gd      DarkWatch     o escuro da noite, o archote e quem vem de la (Q-029)
src/core/event_relay.gd     EventRelay    traduz o que os sistemas devolvem para a §46
src/core/intent_queue.gd    IntentQueue   a fila de intencoes do §61
src/core/night_watch.gd     NightWatch    o ciclo da noite: nascer, invocar, recuar, e o que fica (§74)
src/core/verbs.gd           Verbs         o Verbo 2 e o gatilho direito (§24, §61)
src/core/defeat.gd          Defeat        quando a partida acabou: o nucleo ou o rei (§10, §16, Q-118)
src/core/save_point.gd      SavePoint     gravar ao pausar e ao fechar, de dia (§62, Q-119)
src/core/fresh_start.gd     FreshStart    recomecar do zero: os saves e o legado, tudo ou nada (Q-164)
src/core/legacy_store.gd    LegacyStore   o legado como transacao: gravar, confirmar, gastar (§16, §62, Q-139)
src/core/field_work.gd      FieldWork     a caca e as casas de oficio, no tick (§09, §25)
src/core/camps.gd           Camps         o vagabundo novo de cada alvorada, nos acampamentos (Q-110, Q-122)
src/core/frontier.gd        Frontier      o mundo continuo no tick: gerar ao andar, encontros e limites (Q-173)
src/core/wild_hunt.gd       WildHunt      a caca das terras geradas e o ritmo de cada bicho (Q-217, ADR 0058)
src/core/woods.gd           Woods         a densidade do bosque, a mesma para o cenario e para as arvores (ADR 0070)
src/core/forest_watch.gd    ForestWatch   plantar a floresta: primeiro o que o mapa precisa, depois as arvores (ADR 0070)
src/core/forest_work.gd     ForestWork    abater, limpar o chao das obras e o que a floresta da a quem esta perto (ADR 0070)
src/core/under_watch.gd     UnderWatch    onde ha subsolo, de que e feito, e a primeira descida (§11, §17, Q-186)
src/core/gleaning.gd        Gleaning      a moeda caida e de quem passa: vagabundo ou tropa (Q-107, Q-111)
src/core/king_claims.gd     KingClaims    o que a moeda do rei paga antes de cair no chao (§02, §55)
src/core/monarch_watch.gd   MonarchWatch  o monarca no jogo: o perfil, a escolha, o companheiro pago e a coroacao (ADR 0052)
src/core/royal_song.gd      RoyalSong     a ordem paga da Nia ao Bardo dela: encantar, incentivar, promover (ADR 0052, Q-199)
src/core/foundation_watch.gd FoundationWatch a fundacao: o pioneiro, a carroca, a bancada e o alvo da moeda no marco (ADR 0059)
src/core/caravan_watch.gd   CaravanWatch  a carroca e o grupo seguem o monarca ate fundar, e alcancam (ADR 0066, 0070)
src/core/foundation_choice.gd FoundationChoice onde e quando se funda: parado, e so o chao da sede livre (ADR 0066, 0070)
src/core/realm_frame.gd     RealmFrame    as bordas do reino: a noite e o Lume nascem em relacao a sede, onde quer que se funde (ADR 0070)
src/core/lume.gd            Lume          apagar o Lume: o fim do ciclo pela luz (§75, Q-156)
src/core/offer_toll.gd      OfferToll     o que uma oferta leva do mundo, e o que da (§75, Q-099)
src/core/realm.gd           Realm         o reino que fica, a marcha e os vassalos (§13, ADR 0035)
src/core/save_migrations.gd SaveMigrations uma migracao do save por versao (§62, ADR 0007, Q-091)
src/core/save_migrations_v8.gd SaveMigrationsV8 o castelo dos saves de antes e a Fortaleza (ADR 0059)
src/core/save_migrations_v12.gd SaveMigrationsV12 o save de antes da floresta planta-a ao carregar (ADR 0070)
src/core/spirit_watch.gd    SpiritWatch   o que o reino lembra: ouve a §46 e escreve no animo (Q-102)
src/sim/state/game_state.gd GameState     o estado autoritativo (§45)
src/sim/systems/contact_queue.gd ContactQueue os slots de contacto e a fila (§50)
src/sim/systems/posts.gd    Posts         o que um posto acrescenta a quem o ocupa (§07)
src/sim/systems/morale_system.gd MoraleSystem moral, fuga e o raio do rei (§07)
src/sim/systems/passages.gd Passages    quem muda de faixa, e onde; a escora fecha (§11, §53, Q-132)
src/sim/systems/underground_sites.gd UndergroundSites o subsolo e um sitio, e acaba: as salas e as paredes (§11, Q-186)
src/sim/systems/retinue.gd  Retinue       quem espera no nucleo e quem segue o rei (§25, Q-063)
src/sim/systems/monarchy.gd Monarchy      quem reina, o perfil, a linhagem e o companheiro de cada monarca (ADR 0052)
src/sim/systems/realm_ladder.gd RealmLadder o estagio da sede e o que cada estagio abre (ADR 0059)
src/sim/systems/realm_seat.gd RealmSeat  a carroca da chegada, o alvo da moeda no nucleo e a sede herdada (ADR 0059)
src/sim/systems/bleeding.gd Bleeding      a ferida da flecha do Imperador Arqueiro (ADR 0052, Q-201)
src/sim/systems/discoveries.gd Discoveries o que so se sabe fazer depois de achar a estatua (§17, Q-016)
src/sim/systems/torchlight.gd Torchlight  o archote do rei, que vai no armazenamento, e o escuro (Q-029)
src/sim/systems/hearth.gd   Hearth        a lareira do nucleo: paga ao crepusculo, afasta ate a alvorada (Q-190)
src/sim/systems/stamina.gd  Stamina       o folego de quem corre a pe; parado volta depressa (Q-193, Q-208)
src/sim/systems/melee_sweep.gd MeleeSweep o golpe de perto fere tudo o que alcanca e empurra os pequenos (Q-185)
src/sim/systems/burrows.gd  Burrows       as tocas de onde sai a caca, ao ritmo de cada bicho (Q-106, Q-120, Q-217)
src/sim/systems/wild_burrows.gd WildBurrows as tocas de um segmento gerado: sitios, bichos e chao (Q-217, ADR 0058)
src/sim/systems/woodland.gd Woodland      as arvores do mundo, uma a uma: especie, sitio e estado (ADR 0070)
src/sim/systems/forest_plan.gd ForestPlan onde nascem as arvores, depois do que o mapa precisa (ADR 0070)
src/sim/systems/influence.gd Influence    as regras de vizinhanca: origem, destino, alcance e acumulacao (ADR 0070)
src/sim/systems/site_validator.gd SiteValidator o chao valido da fundacao e a flora que ela limpa (ADR 0066)
src/sim/systems/fire_zones.gd FireZones   fogueiras e barris abrandam a Podridao (§05, Q-029)
src/sim/systems/light_ward.gd LightWard   as tuas luzes fazem recuar ou abrandar a noite (ADR 0034)
src/sim/systems/class_system.gd ClassSystem a classe do rei: a aura e a evolucao (§08)
src/sim/systems/squire.gd   Squire        o escudeiro: escudo, espada e investidura (§08, Q-114)
src/sim/systems/storage.gd  Storage       o armazenamento de cada personagem jogavel (§08, §58, Q-153)
src/sim/systems/coin_target.gd CoinTarget a quem serve uma moeda largada (§02, §55, Q-115)
src/sim/systems/staffing.gd Staffing      quem esteve no posto na fase que acabou (§06, §52, Q-121)
src/sim/systems/upkeep_system.gd UpkeepSystem a manutencao do exercito, a alvorada (§06, Q-124)
src/sim/systems/muster.gd   Muster        a formacao da noite de quem nao tem posto (§05, Q-128)
src/sim/systems/thieves.gd  Thieves       o Alado rouba galinhas e leva-as a alvorada (§06, §07, Q-129)
src/sim/systems/succession.gd Succession  o herdeiro: treino na casa e a coroa a alvorada (§15, §16, Q-133)
src/sim/systems/march.gd    March         quem vai na marcha, e quando volta (§13, ADR 0035)
src/sim/systems/world_plan.gd WorldPlan   quem mora onde no mundo continuo, e as misturas (§21, Q-173)
src/sim/systems/wild_segments.gd WildSegments os segmentos gerados ao andar e gravados (§21, Q-173)
src/sim/systems/trail_pick.gd TrailPick   o tipo de cada segmento de trilho, pelos pesos (§21, Q-173)
src/sim/systems/vassal_system.gd VassalSystem os povos que pagam tributo, e os que caem (§13, Q-103)
src/sim/systems/spirit.gd   Spirit        o animo do reino: memorias com peso e prazo (Q-102)
src/sim/systems/title_perks.gd TitlePerks as bonificacoes dos titulos no combate (§76, Q-102)
src/sim/systems/legacy.gd   Legacy        o que fica quando se perde ou se atravessa (§16, Q-134, Q-135)
src/sim/systems/campaign_memory.gd CampaignMemory o que a campanha lembra ao atravessar (§16, §79, Q-143)
src/sim/state/slot_variant.gd SlotVariant a variante A/B de uma melhoria: torre e canteiro (§10, Q-136)
src/sim/systems/repair_work.gd RepairWork reparar com a moeda fisica (§55, Q-108)
src/sim/systems/training_system.gd TrainingSystem a Casa de Treino: trabalhador -> oficio (§09, §10)
src/sim/systems/crown_system.gd CrownSystem os impulsos reais (§15, §57)
src/sim/systems/conversion_system.gd ConversionSystem o circuito 2: moeda agora ou capacidade (§06, §49)
src/sim/systems/dawn_cascade.gd DawnCascade a frente da luz que solta os postos (§24, GB-21)
src/sim/systems/secret_sites.gd SecretSites onde estao os segredos, e quem os acha (§17)
src/sim/systems/epilogue.gd Epilogue      qual dos tres finais, por precedencia (§79, ADR 0018)
src/sim/state/columns.gd    Columns       gravar e repor um sistema de colunas (§62)
src/sim/systems/amargueiro_system.gd AmargueiroSystem o que a noite deixa no campo (§74)
src/sim/systems/amargueiro_roots.gd AmargueiroRoots quem se levanta na alvorada, e onde (§74)
src/sim/state/amargueiro_save.gd AmargueiroSave as arvores em tipos base (§84)
src/sim/systems/offer_system.gd OfferSystem  a Oferta: uma por noite, no prato (§75)
src/sim/systems/offer_rules.gd OfferRules    a gramatica da coluna requires (§75)
src/sim/systems/offer_price.gd OfferPrice    se o preco caiu no prato (§75)
src/sim/systems/debt_ledger.gd DebtLedger    a Divida da Candeia e as recusas (§75)
src/sim/systems/tender.gd   Tender        o Zelador (§75)
src/sim/systems/ward.gd     Ward          o Sino de Vigia, que afasta o Zelador (§75, Q-100)
src/sim/systems/title_system.gd TitleSystem  quem tem nome, o teto, o luto e o ordinal (§76)
src/sim/systems/feat_ledger.gd FeatLedger    os feitos registados (§76)
src/sim/systems/harvest_system.gd HarvestSystem a Colheita: soltar ou ficar (§78)
src/core/offer_watch.gd     OfferWatch    a voz da Podridao: falar, cobrar, dar (§75)
src/core/sim_save.gd        SimSave       que coleccoes da §45 entram no save
src/core/preferences.gd     Preferences   o tremor e os claroes, em user://settings.cfg (§26, §45)
src/world/boot.gd           (script)      o que a boot.tscn corre (ADR 0005)
src/world/game.gd           Game          o que a game.tscn corre (ADR 0005)
src/world/greybox.gd        Greybox       monta a regiao enquanto nao ha segmentos (GB-01)
src/world/band_view.gd      BandView      desenha UMA faixa, e leva a luz dela
src/world/terrain_backdrop.gd TerrainBackdrop o cenario da faixa, so quando a luz muda
src/world/terrain_art.gd    TerrainArt    o cenario de cada faixa (§11, §22)
src/world/prop_art.gd       PropArt       a arvore e a casa, o que o cenario repete
src/world/actor_art.gd      ActorArt      o que uma tropa E, por dentro da caixa (§22, §24)
src/world/creature_art.gd   CreatureArt   o que um bicho E, por dentro da caixa (§22, §25)
src/world/rot_view.gd       RotView       a mancha, o rasto e o Lume (§74, §80, ADR 0034)
src/world/amargueiro_view.gd AmargueiroView a arvore com a cara na casca, e o Marco (§74)
src/world/offer_view.gd     OfferView     o prato, a frase e o Zelador (§75)
src/world/title_view.gd     TitleView     a fita de quem tem nome (§76)
src/world/build_view.gd     BuildView     as obras, desenhadas pela forma delas (§25, §55)
src/world/structure_art.gd  StructureArt  o que cada obra E, por dentro do contorno (§25, §55)
src/world/building_skins.gd BuildingSkins as obras com sprite, em todos os pontos do SiteStage (ADR 0051)
src/world/painted_art.gd    PaintedArt    as obras sem arte do dono, pintadas uma vez numa textura (ADR 0051)
src/world/pixel_painter.gd  PixelPainter  o pincel das obras: tracos escritos como dados, numa Image (ADR 0051)
src/world/sprites_walls.gd  WallSprites   o muro nos cinco niveis do §10, a escora e o fosso (ADR 0051)
src/world/sprites_towers.gd TowerSprites  a torre, a torre alta, o sino e o barril (ADR 0051)
src/world/sprites_farmstead.gd FarmSprites o canteiro, o galinheiro, o pesqueiro, o estabulo e a lenha (ADR 0051)
src/world/sprites_houses.gd HouseSprites  o solar, a casa terrea, a mina, a fundicao, o altar e a banca (ADR 0051)
src/world/sprites_native.gd NativeSprites as casas dos povos, com a cor e o telhado de cada um (§21, ADR 0051)
src/world/sprites_seat.gd   SeatSprites   a sede em cada estagio e a carroca da chegada (ADR 0059)
src/world/silhouette.gd     Silhouette    o que cada coisa E, em forma (§22, Q-079)
src/world/campfires.gd      Campfires     os sitios de fogueira da regiao (Q-029)
src/world/wards.gd          Wards         os sitios dos sinos de vigia e do farol (Q-100, Q-156)
src/world/bow_racks.gd      BowRacks      o sitio da banca do arco, posta por ultimo (Q-165)
src/world/outline.gd        Outline       o contorno de cada forma, em centesimos da caixa
src/world/gauge.gd          Gauge         os instrumentos do greybox: vida, saco e armazenamento (GB-03, Q-153)
src/world/site_stage.gd     SiteStage     em que ponto esta uma obra, para a obra o mostrar
src/world/site_marks.gd     SiteMarks     moedas pagas, andaime, fissuras e reparo, por forma
src/actors/actor_action.gd  ActorAction   que tag da arte mostra o que a unidade faz
src/world/price_tag.gd      PriceTag      o preco do que esta debaixo do rei (§24, §55, GB-05)
src/world/impact_view.gd    ImpactView    o golpe que se ve: flash e particula (§24, GB-08)
src/world/strike_pose.gd    StrikePose    o golpe em tres tempos: preparar, bater, voltar (§24, Q-185)
src/world/combat_fx.gd      CombatFx      o que um corpo mostra de um golpe: pose, empurrao, hitstop, flash (Q-084)
src/world/battle_view.gd    BattleView    as flechas no ar e o que fica de uma morte (§07, §50, Q-185)
src/world/creature_view.gd  CreatureView  os bichos da noite, desenhados: pose, bestiario ou contorno (§07, §51, §80)
src/world/bestiary.gd       Bestiary      as sete criaturas: forma, porte, cor e olhos (§07, §22, ADR 0049)
src/world/beast_pen.gd      BeastPen      o pincel do bestiario: pixeis de criatura, espelho e pose (ADR 0049)
src/world/beasts_small.gd   BeastsSmall   o Rastejante, o Alado e o Cavador, em pixeis (ADR 0049)
src/world/beasts_large.gd   BeastsLarge   o Bruto e o Ariete de lodo, em pixeis (ADR 0049)
src/world/beasts_giant.gd   BeastsGiant   o Devorador e o Zelador, em pixeis (ADR 0049)
src/world/last_seen.gd      LastSeen      o ultimo desenho de cada criatura, para a morte e a flecha (§07, §50)
src/world/volley.gd         Volley        as flechas que se veem voar, e as que se cravam (§07, §50)
src/world/death_burst.gd    DeathBurst    uma morte que se ve: branco, espalmar e pedacos (§07)
src/world/screen_shake.gd   ScreenShake   o tremor de ecra por trauma, 4 px no maximo (§24, §26)
src/actors/fallen_art.gd    FallenArt     os corpos que a alvorada leva, com raizes (Q-096)
src/world/shadow.gd         Shadow        a sombra de contacto (§22, §24, GB-09)
src/world/smoothing.gd      Smoothing     o render interpola entre dois ticks (§40 I5, GB-10)
src/world/passage_cue.gd    PassageCue    onde o Verbo 2 pega, dito no sitio (§11, §25, GB-14)
src/world/dawn_sweep.gd     DawnSweep     o amanhecer que se ve chegar (§24, GB-17)
src/world/sky_view.gd       SkyView       o ceu, e o sol e a lua que dizem a hora e a noite funda (§24, GB-18)
src/world/coin_bounce.gd    CoinBounce    a moeda sai da mao, gira, ressalta e e levada, so no ecra (§24, ADR 0050)
src/world/coin_art.gd       CoinArt       a moeda, a pilha e o saco em pixeis, e o brilho no chao (§02, ADR 0050)
src/world/accessibility_filter.gd AccessibilityFilter contraste e daltonismo, por cima do mundo (§26)
src/world/lighting.gd       Lighting      quanta luz chega a cada coisa (§22, §74, §80)
src/world/glow.gd           Glow          uma luz: centro, raio, as tres paragens e a forca (§80, ADR 0048)
src/world/flicker.gd        Flicker       o fogo que cintila e o Lume que respira (ADR 0048)
src/world/light_field.gd    LightField    as luzes do mundo neste frame, por faixa, e a lareira (ADR 0034, 0048)
src/world/scenery_light.gd  SceneryLight  a luz do cenario plano a plano, no shader world_light (§80, ADR 0048)
src/world/flame_art.gd      FlameArt      a chama em pixeis, que nao leva luz (§80, ADR 0048)
src/world/hearth_art.gd     HearthArt     a fogueira e o farol: pedra, lenha, torre e braseiro (§05, §10, ADR 0048)
src/world/world_palette.gd  WorldPalette  as cores e a geometria do greybox
src/world/band_light.gd     BandLight     a luz de cada faixa por fase (§80, ADR 0011)
src/world/world_light.gd    WorldLight    as tres paragens da luz e o raio da candeia
src/world/wall_site.gd      WallSite      o sitio de muro: a escada do §10 e o Lenho (§74)
src/world/seat_site.gd      SeatSite      a sede: o nucleo como escada de estagios, da Clareira a Fortaleza (ADR 0059)
src/world/cavities.gd       Cavities      o poco das cavidades e as escoras das passagens (§11, Q-130)
src/world/site_view.gd      SiteView      a camara, a estatua e a placa do capitulo (§17, §83)
src/world/biome_greybox.gd  BiomeGreybox  a greybox de cada bioma, em formas lisas (GB-02)
src/world/wilds.gd          Wilds         o que cresce e vive numa regiao, pela semente (Q-150)
src/world/wilds_layer.gd    WildsLayer    um plano gerado: campo, horizonte ou nuvens
src/world/wild_ground.gd    WildGround    o chao das terras geradas, sem degraus (Q-173)
src/world/wild_tunnel.gd    WildTunnel    a terra por baixo das terras e a camara das masmorras (Q-173, Q-186)
src/world/under_art.gd      UnderArt      os sitios do subsolo, escavados na terra (§11, Q-186)
src/world/under_props.gd    UnderProps    o que ha em cada sala do subsolo, pelo tipo dela (Q-186)
src/world/wild_subjects.gd  WildSubjects  o assunto de cada segmento de trilho (§21, Q-173)
src/world/wild_lands.gd     WildLands     o limiar e a terra de outro povo (§21, Q-173)
src/world/wild_edge.gd      WildEdge      a borda do mundo: mar, falesia, desfiladeiro, muralha (Q-173)
src/world/shape_art.gd      ShapeArt      formas lisas escritas como dados, e o interprete (Q-173)
src/world/frontier_view.gd  FrontierView  a camara segue o mundo ja gerado (Q-173)
src/world/soil_cover.gd     SoilCover     a terra por cima do subsolo, que se vai so por cima do sitio onde o rei desce (§11, Q-181, Q-186)
src/world/soil_reveal.gd    SoilReveal    quanto do subsolo se ve, e a matriz do dither_reveal (§11, §60, Q-181)
src/world/lowland.gd        Lowland       a paisagem por cima do subsolo: os trocos e as plantas (§11, Q-181)
src/world/lowland_layout.gd LowlandLayout os caminhos e os lagos dessa paisagem (§11, Q-181)
src/world/lowland_art.gd    LowlandArt    essa paisagem, em pixeis (§11, §22, Q-181)
src/world/passage_art.gd    PassageArt    a boca da passagem, e o poco quando o subsolo se ve (§11, Q-181)
src/world/flora_art.gd      FloraArt      o que cresce, em pixeis
src/world/tree_art.gd       TreeArt       as arvores em pixeis: silhueta por especie, copa por estacao, vento (ADR 0070)
src/world/forest_view.gd    ForestView    a floresta no plano de accao, a quem serve e o chao que ficou vazio (ADR 0070)
src/world/fauna.gd          Fauna         os bichos de cenario e o que fazem (nenhum e caca)
src/world/flock.gd          Flock         um bando de passaros, pelas regras de Reynolds
src/world/fauna_art.gd      FaunaArt      o que um bicho de cenario E, em pixeis
src/world/fauna_view.gd     FaunaView     os bichos de cenario, a mexer
src/world/band_layers.gd    BandLayers    camadas e mascaras de fisica
src/world/camera_rig.gd     CameraRig     camara unica
src/world/synth_sfx.gd      SynthSfx      os sons provisorios, sintetizados aos bocados (ADR 0054, Q-209)
src/world/synth_take.gd     SynthTake     um som do SynthSfx a fazer-se, amostra a amostra (ADR 0055)
src/world/sfx_cues.gd       SfxCues       as pistas que ja tocam, iguais a folha de pistas de docs/audio/
src/world/sfx_director.gd   SfxDirector   ouve o EventBus e toca as pistas; a moeda na obra sobe de tom
src/ui/input_router.gd      InputRouter   entrada -> intencoes; nunca muda estado (§61)
src/ui/hud.gd               Hud           o painel do greybox, e nao o HUD do §24
src/ui/game_hud.gd          GameHud       o painel de quem joga (§24)
src/ui/inspector.gd         Inspector     o estado de cada sistema, a pedido (Q-067)
src/ui/pause_menu.gd        PauseMenu     a pausa e o fim da partida (§24, §16)
src/ui/guide_sites.gd       GuideSites    o que o guia diz nos sitios: a passagem, o herdeiro, a fortaleza e as terras (Q-138, Q-166, Q-173)
src/ui/seat_guide.gd        SeatGuide     o que o painel diz no marco da sede: fundar, melhorar, o que abre (ADR 0059)
src/ui/forest_guide.gd      ForestGuide   o que o painel diz ao pe de uma arvore: preco, tronco e a quem serve (ADR 0070)
src/ui/foundation_guide.gd  FoundationGuide o que fundar aqui leva e deixa, no painel antes de fundar (ADR 0070)
src/ui/glyphs.gd            Glyphs        os botoes do dispositivo activo (§26, GB-15); o toque e o quarto (ADR 0047)
src/ui/touch_controls.gd    TouchControls jogar com os dedos: os dedos viram accoes do InputMap (ADR 0047)
src/ui/touch_layout.gd      TouchLayout   onde esta cada controlo de toque, e o canhoto (ADR 0047)
src/ui/touch_pad.gd         TouchPad      quem e cada dedo, o que ele quer premido, e o CORRER premido (ADR 0047, UX-04, Q-193)
src/ui/touch_stick.gd       TouchStick    a alavanca, solta ou fixa: andar; correr e so o CORRER premido (ADR 0047, UX-03, Q-193)
src/ui/wide_touch.gd        WideTouch     no toque, o mundo enche o ecra ate 1,25x o 16:9 (Q-188)
src/ui/touch_view.gd        TouchView     o que cada botao de toque diz agora (ADR 0047)
src/ui/touch_art.gd         TouchArt      os controlos de toque, desenhados em formas lisas (ADR 0047)
src/ui/web_screen.gd        WebScreen     o ecra inteiro do browser, pedido a casca (UX-03)
src/ui/screen_row.gd        ScreenRow     o ecra inteiro na pausa: entrar, sair, ou como no iPhone (UX-03)
src/ui/captions.gd          Captions      as legendas de som (§26, GB-22)
src/ui/hud_text.gd          HudText       o texto do painel, por chave (§27, GB-27)
src/ui/options_panel.gd     OptionsPanel  as opcoes da pausa, e o idioma (§26, §27)
src/ui/fresh_start_panel.gd FreshStartPanel o "Recomecar do zero" da pausa, e a pergunta (Q-164)
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
src/core/offer_watch.gd     OfferWatch             nucleo        core/, sim/
src/core/verbs.gd           Verbs                  nucleo        core/, sim/
src/core/field_work.gd      FieldWork              nucleo        core/, sim/
src/core/intent_queue.gd    IntentQueue            nucleo        nada
src/core/event_bus.gd       EventBus               nucleo        nada
src/core/rng_service.gd     RngService             nucleo        nada
src/core/registry.gd        Registry               nucleo        sim/
src/core/save_service.gd    SaveService            nucleo        sim/
src/core/legacy_store.gd    LegacyStore            nucleo        core/, sim/
src/core/preferences.gd     Preferences            nucleo        nada
src/world/*.gd              BandLayers, CameraRig  apresentacao  core/, sim/
src/actors/*.gd             UnitView, KingView...  apresentacao  core/, sim/
src/ui/*.gd                 InputRouter, Hud...    apresentacao  core/, sim/
scenes/boot.tscn            (cena principal)       cenas         tudo
tools/*.gd, tools/*.py      ferramentas            fora do jogo  tudo; nunca exportado
tools/vistoria.gd           Vistoria/Autopilot     fora do jogo  uma partida longa, vigiada
ferramentas/*.mjs, src/*.js camada de uso do dossie fora do jogo  docs/; nunca exportado
tools/web/**                o site (ADR 0024, 0025)  fora do jogo  le data/, docs/ e o project.godot; nunca exportado

## Ciclo de trabalho
1. Le docs/backlog/<id>.md e as seccoes de docs/design/ que ele cita.
2. Escreve ou atualiza o teste em tests/. Confirma que falha.
3. Implementa o minimo que o faz passar.
4. Corre ./run_tests.sh — e `make vistoria` se mexeste no tick ou no mundo.
5. So com tudo verde, propoe o diff, com a checklist do PR preenchida.
6. A `main` e o ramo por omissao, e e la que o trabalho feito vive. Regra do
   dono: tudo o que estiver feito — suite e portoes verdes — entra na `main`
   no fim da sessao, por PR, e nao fica num ramo de trabalho a espera. Antes
   de abrir o PR, junta a `main` ao ramo e volta a correr tudo. Um PR em
   rascunho nao esta feito: nao se junta sem o dono dizer.

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
