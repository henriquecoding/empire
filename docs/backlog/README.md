# Backlog — Fases 0 e 1

> Os tickets do §34 do dossiê, um ficheiro cada, no formato do §34, com os caminhos da §70 e os ficheiros reais de
> `docs/design/`. A v5.2 acrescentou seis que a §65 e a §66 pediam e o §34 não tinha (F0-11 a F0-15 e F1-17), e nove
> de arte, *greybox*, nomes e dados, que correm em paralelo aos sábados (§22, opção C).

**Como se usa:** abre o ticket, lê as secções da linha *Spec*, e dá-o ao agente tal e qual — uma tarefa por sessão.
Quando acabar, muda o **Estado** no próprio ficheiro e nesta tabela, no mesmo *commit*.

## Fase 0 — Fundação

| Ticket | Tarefa | Depende | Estado |
|---|---|---|---|
| [F0-00](F0-00.md) | Repositório do dia zero: as ondas 1 e 2 da §68 | — | feito |
| [F0-01](F0-01.md) | Criar o projeto Godot 4.6 com as definições do §19 | F0-00 | feito |
| [F0-02](F0-02.md) | Git LFS para *.aseprite e art/**/*.png | F0-00 | parcial — configurado; a arte que há (art/source/originals, art/export/enramados) está fora do LFS de propósito (.gitattributes), e git lfs ls-files não mostra nada |
| [F0-03](F0-03.md) | AGENTS.md e os primeiros ADRs | F0-00 | feito |
| [F0-04](F0-04.md) | Instalar o gdUnit4 e o workflow de CI | F0-00 | feito |
| [F0-05](F0-05.md) | Band: enum, planos e a matriz de colisão | F0-01 | feito |
| [F0-06](F0-06.md) | GameClock e o ClockData (prompt 1 da §29) | F0-01 | feito |
| [F0-07](F0-07.md) | EventBus com os sinais do §46 | F0-01 | feito |
| [F0-08](F0-08.md) | Câmara com lookahead e limites de região | F0-05 | feito |
| [F0-09](F0-09.md) | Spike: decidir a escala e fechar a ADR 0001 | F0-01 | por fazer |
| [F0-10](F0-10.md) | Cena de teste: um sprite anda nas três faixas | F0-05, F0-08 | feito |
| [F0-11](F0-11.md) | Registry e boot.tscn | F0-01 | feito |
| [F0-12](F0-12.md) | RngService: os seis fluxos, snapshot e restore | F0-11 | feito |
| [F0-13](F0-13.md) | SaveService: escrita atómica e três slots | F0-11 | feito |
| [F0-14](F0-14.md) | UnitView com cinco slots e o shader da paleta | F0-10 | feito |
| [F0-15](F0-15.md) | Spike: importar arte do Aseprite e fechar a ADR 0010 | F0-02 | por fazer |

## Fase 1 — Núcleo jogável

| Ticket | Tarefa | Depende | Estado |
|---|---|---|---|
| [F1-01](F1-01.md) | Moeda física: largar, arco, queda, apanhar, saco | F0-07 | feito |
| [F1-02](F1-02.md) | UnitData e as seis unidades do §07 | F0-03 | feito |
| [F1-03](F1-03.md) | UnitSystem com arrays paralelos e time-slicing | F1-02 | feito |
| [F1-04](F1-04.md) | Recrutar um vagabundo por uma moeda; ele segue-te | F1-01, F1-03 | feito |
| [F1-05](F1-05.md) | JobBoard (prompt 4 da §29) | F1-03 | feito |
| [F1-06](F1-06.md) | Muro: cinco níveis, dois caminhos, slots de contacto | F1-05 | feito |
| [F1-07](F1-07.md) | Arqueiro: alcance, precisão 0,34 em campo e 1,0 em torre | F1-06 | feito |
| [F1-08](F1-08.md) | RotSystem (prompt 2 da §29) | F0-06 | feito |
| [F1-09](F1-09.md) | Criaturas: Rastejante, Alado, Bruto e a tabela de invocação | F1-08 | feito |
| [F1-10](F1-10.md) | Economy (prompt 3 da §29) e a curve.tres | F1-01 | feito |
| [F1-11](F1-11.md) | Plantação, pesqueiro e galinheiro com os valores do §06 | F1-10 | feito |
| [F1-12](F1-12.md) | Moral e fuga com o raio do rei | F1-05 | feito |
| [F1-13](F1-13.md) | CanvasModulate por faixa, animado pelo GameClock | F0-06 | feito |
| [F1-14](F1-14.md) | Save e load do estado de src/sim/ com save_version | F1-10 | feito |
| [F1-15](F1-15.md) | Cenário de combate noturno para afinação | F1-09 | feito |
| [F1-16](F1-16.md) | Afinar até sobreviver dez dias ser possível e não trivial | tudo | feito |
| [F1-17](F1-17.md) | Arte da mancha: a Podridão e a candeia | F1-08, ART-02 | feito |

## Em paralelo — arte, *greybox*, nomes e dados

| Ticket | Tarefa | Depende | Estado |
|---|---|---|---|
| [ART-01](ART-01.md) | A primeira personagem real em cinco slots | F0-14, F0-15 | por fazer |
| [ART-02](ART-02.md) | A paleta mestra e o LUT | F0-01 | por fazer |
| [ART-03](ART-03.md) | As seis camadas de parallax com teto de valores | ART-02, F0-08 | por fazer |
| [ART-04](ART-04.md) | Rostos e expressões: o catálogo do §60 | ART-01 | por fazer |
| [GB-01](GB-01.md) | Greybox do segmento zero | F0-10 | parcial — falta a cara fixa do vagabundo (ART-01, Q-104) |
| [GB-02](GB-02.md) | Greybox dos seis biomas | GB-01 | feito |
| [GB-03](GB-03.md) | Regras de densidade medidas no greybox | GB-02 | feito |
| [GB-04](GB-04.md) | O passo do §21: a região atravessa-se em 40–60 s | GB-01 | feito |
| [GB-05](GB-05.md) | O preço daquilo em cima de que estás | GB-01 | feito |
| [GB-06](GB-06.md) | Largar em contínuo, que o §24 já mandava | F1-01 | feito |
| [GB-07](GB-07.md) | O rei não fica preso em combate | F1-03 | feito |
| [GB-08](GB-08.md) | O golpe que se vê | F1-07 | feito |
| [GB-09](GB-09.md) | A sombra de contacto da moeda | F1-01 | feito |
| [GB-10](GB-10.md) | O render interpola, e o rei deixa de andar aos solavancos | F0-06 | feito |
| [GB-11](GB-11.md) | O gatilho direito, num comando | F1-07 | feito |
| [GB-12](GB-12.md) | A câmara livre pelo rato na margem | F0-08 | feito |
| [GB-13](GB-13.md) | Pausa e opções: desligar o tremor e os clarões | GB-08 | feito |
| [GB-14](GB-14.md) | O sinal da passagem, onde o Verbo 2 pega | GB-05 | feito |
| [GB-15](GB-15.md) | Os glifos do comando que se está a usar | GB-06 | feito |
| [GB-16](GB-16.md) | A derrota diz a verdade, e dá um jogo novo | GB-13 | feito |
| [GB-17](GB-17.md) | O amanhecer que se vê chegar | F1-13 | feito |
| [GB-18](GB-18.md) | O sol e a lua dizem a hora | F1-13 | feito |
| [GB-19](GB-19.md) | O pequeno bounce da moeda | GB-09 | feito |
| [GB-20](GB-20.md) | A cara de quem está ferido | F0-14 | feito |
| [GB-21](GB-21.md) | As tropas saem dos postos atrás da luz | GB-17 | feito |
| [GB-22](GB-22.md) | As legendas de som | GB-13 | feito |
| [GB-23](GB-23.md) | A silhueta fantasma a piscar | GB-05 | feito |
| [GB-24](GB-24.md) | A duração do dia, ao ritmo de quem joga | GB-13 | feito |
| [GB-25](GB-25.md) | O controlo de contraste | GB-13 | feito |
| [GB-26](GB-26.md) | Os modos para daltonismo | GB-25 | feito |
| [GB-27](GB-27.md) | O painel fala por chave | GB-15 | feito |
| [GB-28](GB-28.md) | O idioma escolhe-se na pausa | GB-27 | feito |
| [NB-01](NB-01.md) | Bíblia de nomes e a escolha do nome do jogo | — | por fazer |
| [CD-01](CD-01.md) | A base de dados de conteúdo, uma tabela por sessão | F0-03 | feito |
| [PUB-01](PUB-01.md) | O jogo passa a jogar-se no browser | F0-04 | feito |
| [PUB-02](PUB-02.md) | O site passa a ser a página do jogo | PUB-01 | feito |
| [PUB-04](PUB-04.md) | O site mostra o jogo de hoje | PUB-02 | feito |

## Fase 2 — Fatia vertical

| Ticket | Tarefa | Depende | Estado |
|---|---|---|---|
| [F2-01](F2-01.md) | A classe do Monarca: a aura e a evolução | F1-12, XIII-03 | parcial |

## Auditoria de gameplay de 26/09 — o que o relatório mandou fazer

> `docs/recovery/AUDITORIA-GAMEPLAY-2026-09-26.md`. As decisões estão nas Q-115 em diante.

| Ticket | Tarefa | Depende | Estado |
|---|---|---|---|
| [AUD-01](AUD-01.md) | Integridade da simulação: a moeda, o muro, a torre, o rei e o save | — | feito |
| [AUD-02](AUD-02.md) | A economia verdadeira: o que o CI afina é o que o jogo corre | AUD-01 | feito — a produção cresce, paga nobres e pede o trabalhador; a manutenção e o vagabundo da alvorada na partida; o D8 passa para o AUD-04 (o Cavador do dia 10, Q-101) |
| [AUD-03](AUD-03.md) | A noite legível e com gestos | AUD-01 | feito — o lado dito à tarde, o ritmo, o sacrifício de moedas, a formação da noite e as legendas; som gravado continua a ser da pasta audio/ |
| [AUD-04](AUD-04.md) | As faixas: o subsolo como expedição e o Alado com alvo | AUD-01 | feito — o poço nas cavidades, a escora das passagens, o Cavador chamado pelo poço e o Alado que rouba galinhas |
| [AUD-05](AUD-05.md) | Uma campanha mínima: sucessão, fim de região e decay | AUD-02, AUD-03 | feito — o herdeiro, o decay, a travessia com o epílogo e as variantes da torre e do canteiro |

## Auditoria de gameplay de 27/09 — a continuidade

> `docs/recovery/AUDITORIA-GAMEPLAY-2026-09-27.md`. As decisões e as perguntas abertas estão nas Q-137 a Q-147.

| Ticket | Tarefa | Depende | Estado |
|---|---|---|---|
| [CONT-01](CONT-01.md) | Transição durável: o legado como transação | — | feito — LegacyStore: temporário, leitura de volta e rename; os slots só se apagam depois; o primeiro save do jogo novo gasta o legado (Q-139) |
| [CONT-02](CONT-02.md) | Memória da campanha: o que atravessa e o que fica | CONT-01; Q-143 | parcial — a variante, a fase da classe, a dívida, os povos e o treino do herdeiro atravessam; a comitiva só da faixa do rei (Q-140, Q-143); falta separar a dívida local e a identidade da comitiva |
| [CONT-03](CONT-03.md) | Snapshot do trabalho: o Staffing no save | — | feito — o Staffing grava a fase, quem serve e quem serviu; retomar fecha a fase igual (Q-141) |
| [CONT-04](CONT-04.md) | Transições sem prisão: sucessão e escoras | Q-137, Q-138 | parcial — uma condição de sucessão (casa de pé) e a escora fecha por cima; a topologia do subsolo e o treino sem casa ficam na Q-137/Q-138 |
| [CONT-05](CONT-05.md) | Medição fiel da partida | —; repetir depois de CONT-01 a 04 | parcial — a vistoria pára com o Defeat e diz a causa, conta as moedas por origem e por sorvedouro, e compara duas políticas (Q-142); o piloto já compra o arco na banca e decreta a Chamada às Armas, e a vistoria conta a gente armada (Q-165); falta um piloto que invista em renda e chegue à travessia: medido a 29/09, das seis moedas ele nunca tem saco à tarde e o rei cai ao dia 4 sem levantar a banca |
| [CONT-06](CONT-06.md) | Manutenção com custo marginal | CONT-05; Q-144 | por fazer |
| [CONT-07](CONT-07.md) | Duas economias de conversão válidas | CONT-05, CONT-06; Q-145 | por fazer |
| [CONT-08](CONT-08.md) | Abertura e controlo completos | CONT-04 | parcial — o impulso escolhe-se no comando pelo gesto do §24 (manter Y, apontar, largar; Q-148); falta o destinatário da moeda antes de largar, a razão do que não pode e o retorno da expedição |
| [CONT-09](CONT-09.md) | Sinais de ação e ameaça | — | por fazer |
| [CONT-10](CONT-10.md) | Duas regiões autoradas | CONT-01, CONT-02, CONT-05 | por fazer |
| [CONT-11](CONT-11.md) | Um povo, uma escolha completa | CONT-02, CONT-10 | por fazer |
| [CONT-12](CONT-12.md) | Evidências e estado derivados | contínuo | parcial — o validation.json acertado a 27/09; repetir a cada entrega |

## Parte XIII — a candeia, a Oferta, o Nome, a Colheita e os Capítulos

> Onze tickets novos, pela ordem de custo da §82. O caminho mínimo que dá a transformação inteira é
> XIII-01 + XIII-02 + XIII-03 + XIII-04 + XIII-10 + XIII-11: 52 horas, e é aí que está quase todo o efeito.

| Ticket | Tarefa | Depende | Horas | Estado |
|---|---|---|---|---|
| [XIII-01](XIII-01.md) | §80 · O preto na paleta e a noite castanha | ART-02 | 4 (2 código + 2 arte) | feito |
| [XIII-02](XIII-02.md) | §74 · O termo dos Amargueiros na massa | F1-08 | 1 | feito |
| [XIII-03](XIII-03.md) | §74 · O Amargueiro e a candeia, completos | XIII-02, F1-06, ART-04 | 13 (10 + 3 arte) | feito |
| [XIII-04](XIII-04.md) | §75 · A Oferta e a Dívida da Candeia | XIII-03 | 20 (12 + 4 arte + 2 som + 2 escrita) | feito — 4 das 12 ofertas com preço e efeito ligados (Q-099) |
| [XIII-05](XIII-05.md) | §76 · O Nome | F1-12 | 11 (7 + 2 arte + 1 som + 1 escrita) | feito — 5 dos 9 feitos com o que observar (Q-102) |
| [XIII-06](XIII-06.md) | §78 · A Colheita | F1-16 | 11 (8 + 3 arte) | parcial — falta a conquista que a começa e o gesto da decisão (Q-103) |
| [XIII-07](XIII-07.md) | §77 · Os dez capítulos | GB-02, XIII-06 | 106 (30 + 50 arte + 20 som + 6 escrita) | parcial — a colocação e os diários feitos (D-09, D-11, D-12); as leis, a arte e as canções por fazer |
| [XIII-08](XIII-08.md) | §79 · Os doze diários e os três epílogos | XIII-04, XIII-07 | 13 (3 + 10 escrita) | parcial — a atribuição, o D-12, o D-13 e o diário 1 legível; os outros onze esperam pelas fortalezas e pelos capítulos |
| [XIII-09](XIII-09.md) | §81 · Som: o cante, os motivos e a encomendação | XIII-05, XIII-06 | 44 (6 + 38 som) | por fazer |
| [XIII-10](XIII-10.md) | §83 · Os primeiros vinte minutos | GB-01, XIII-03 | 8 (3 + 4 arte + 1 escrita) | feito |
| [XIII-11](XIII-11.md) | §84 · Os catorze testes de design e as seis linhas de risco | XIII-02 | 6 | feito |

## Ordem sugerida

**Código, dias de semana:** F0-00 → F0-02 → F0-05 → F0-07 → F0-06 → F0-11 → F0-13 → F0-12 → F0-08 → F0-14 → F0-10,
com os dois *spikes* (F0-09, F0-15) numa tarde cada. Depois a Fase 1 pela ordem dos doze *commits* da §66:
F1-02 → F1-03 → F1-01 → F1-04 → F1-05 → F1-06 → F1-07 → F1-08 → F1-09 → F1-15 → F1-10 → F1-11 → F1-12 → F1-13 → F1-14 → F1-17 → F1-16.

**Arte, aos sábados (§28):** ART-02 → ART-01 → GB-01 → ART-03 → GB-02 → GB-03 → ART-04. O NB-01 começa já e fecha antes
da Fase 4; o CD-01 faz-se antes do F1-02 e do F1-09, uma tabela por sessão.

**Parte XIII:** XIII-11 e XIII-02 primeiro (os testes e o termo da massa, que são 7 h e guardam tudo o resto),
depois XIII-01 antes de se desenhar cenário. XIII-03 → XIII-04 → XIII-10 fecham o caminho mínimo de 52 h.
As XIII-05, XIII-07 e XIII-09 podem cair inteiras sem que as outras deixem de funcionar (§82).

**O marco que fecha a pré-produção** (relatório mestre, §32; dossiê, §71): abrir o Empire, controlar uma personagem real
numa *greybox*, atravessar as três faixas, construir algo com uma moeda, sobreviver à primeira noite e reproduzir o
resultado pela mesma *seed*. São o F0-10, o ART-01, o GB-01, o F1-01, o F1-06, o F1-08 e o F0-11.

## Interface — correções pedidas pelo dono

| Ticket | Tarefa | Depende | Estado |
|---|---|---|---|
| [UX-01](UX-01.md) | Reformular a pausa e corrigir o corte visual | GB-13 | feito |
| [UX-02](UX-02.md) | Jogar com os dedos: os controlos por toque | UX-01 | feito |
| [UX-03](UX-03.md) | A alavanca solta, o FIXAR e o ecrã inteiro | UX-02 | feito |
| [UX-04](UX-04.md) | O CORRER no toque e as obras com sprite | UX-03 | feito |

## Monarcas, companhias e controlo imperial — ADR 0052

> O plano de 02/10/2026 (`docs/recovery/PLANO-MONARCAS-2026-10-02.md`): começar como um de três monarcas, só
> imperadores controláveis, flechas imperiais pagas. Nove fases; cada uma entra por PR próprio.

| Ticket | Tarefa | Depende | Estado |
|---|---|---|---|
| [UN-00](UN-00.md) | Consolidar as regras dos monarcas e a ADR | — | feito |
| [UN-01](UN-01.md) | Esquema de monarcas e companheiros | UN-00 | feito |
| [UN-02](UN-02.md) | Autoridade por reino e por pessoa | UN-01 | feito |
| [UN-03](UN-03.md) | Vínculo de companhia | UN-02 | feito |
| [UN-04](UN-04.md) | Seleção imperial e autoria inicial | UN-01, UN-02, UN-03 | feito |
| [UN-05](UN-05.md) | Retirar o controlo de tropas | UN-02 | feito |
| [UN-06](UN-06.md) | Migração das campanhas antigas | UN-03, UN-04, UN-05 | feito |
| [UN-07](UN-07.md) | Generalizar a morte e a sucessão | UN-02, UN-03 | feito — o herdeiro segue o perfil de quem reinava, a proposta da Q-202 por aprovar |
| [UN-08](UN-08.md) | Despacho do combate e da habilidade | UN-04, UN-05 | feito |
| [UN-09](UN-09.md) | A Imperatriz Nia e os números de bancada | UN-08 | feito |
| [UN-10](UN-10.md) | O Bardo real pago | UN-03, UN-09 | feito |
| [UN-11](UN-11.md) | Conversão e hostilidade | UN-10 | feito |
| [UN-12](UN-12.md) | Promoção e evolução de Nia | UN-10, UN-11 | feito — os tetos de encantados e de convertidos são propostas da Q-199 por aprovar |
| [UN-13](UN-13.md) | O Imperador Arqueiro e a aljava | UN-08 | feito |
| [UN-14](UN-14.md) | O escudeiro que fornece flechas | UN-03, UN-13 | feito |
| [UN-15](UN-15.md) | O sangramento | UN-13 | feito |
| [UN-16](UN-16.md) | Encontros e roster imperial | UN-05, UN-06, UN-07 | por fazer |
| [UN-17](UN-17.md) | Troca imperial transacional | UN-16 | por fazer |
| [UN-18](UN-18.md) | Diplomata universal sob IA | UN-05 | por fazer |
| [UN-19](UN-19.md) | Tesouro local e defesa na ausência | UN-02, UN-07 | por fazer |
| [UN-20](UN-20.md) | Incursões com Diplomata | UN-18, UN-19 | por fazer |
| [UN-21](UN-21.md) | Captura, resgate e dívida | UN-20 | por fazer |
| [UN-22](UN-22.md) | Alvo de unidade e de obra, e conquista | UN-11, UN-20 | por fazer |
| [UN-23](UN-23.md) | Governo inimigo e assimilação | UN-07, UN-18, UN-22 | por fazer |
| [UN-24](UN-24.md) | Viagem da comitiva, montarias e sítios | UN-03, UN-17, UN-20 | por fazer |
| [UN-25](UN-25.md) | Ofícios, evolução e produção animal | UN-19, UN-20, UN-21, UN-22 | por fazer |
| [UN-26](UN-26.md) | Pontes, torres e um evento de bioma | UN-22, UN-24, UN-25 | por fazer |
| [UN-27](UN-27.md) | Lore e apresentação dos encontros | UN-09, UN-10, UN-11, UN-12, UN-13, UN-14, UN-15, UN-16, UN-17, UN-23, UN-24 | por fazer |
| [UN-28](UN-28.md) | O primeiro ciclo e a acessibilidade | UN-04, UN-10, UN-14, UN-17, UN-18 | por fazer |
| [UN-29](UN-29.md) | Coop local | UN-17, UN-18, UN-19, UN-20, UN-21, UN-22, UN-23 | por fazer |
| [UN-30](UN-30.md) | Dois reinos e a vitória | UN-22, UN-23, UN-29 | por fazer |
| [UN-31](UN-31.md) | Spike e integração de rede | UN-29, UN-30 | por fazer |
| [UN-32](UN-32.md) | O herdeiro neutro, caro, e a chave da troca | UN-07, UN-16 | por fazer |
| [UN-33](UN-33.md) | O quarto imperador e a escudeira que dança | UN-16 | por fazer |
| [UN-34](UN-34.md) | O escudeiro evoluído dispara flechas | UN-14 | por fazer |

## Respostas aprovadas no painel

| Ticket | Tarefa | Depende | Estado |
|---|---|---|---|
| [QP-01](QP-01.md) | Onze respostas restantes do painel | UX-01 | feito |
| [QP-02](QP-02.md) | As respostas do painel de 02 e 03/10/2026 | UX-04 | feito |
| [QP-03](QP-03.md) | O baú da sala secreta | QP-02 | por fazer |
| [QP-04](QP-04.md) | O refinamento da jogabilidade de 03/10/2026 | QP-02 | feito |
