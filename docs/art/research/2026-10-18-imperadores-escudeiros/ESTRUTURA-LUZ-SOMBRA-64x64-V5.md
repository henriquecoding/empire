> ARQUIVO DE ESTUDO. A rodada visual foi rejeitada em 18/10/2026. Este texto preserva pesquisa/propostas; não declara arte aprovada. Leia primeiro o README desta pasta.

# Empire — estrutura de pixel art, luz e sombra · V5

**Henrique Passos · 18 de outubro de 2026**

**Resultado desta etapa:** estudo de construção e direção de remodelação. A referência artística do rei e do escudeiro continua a ser a versão apreciada por Henrique; a da dançarina também. Os pequenos desenhos nativos deste pacote servem para investigar limites, volumes e continuidade. **São estudos técnicos, não substitutos acabados desses conceitos nem animações finais.**

## 1. O problema a resolver

As pranchas anteriores tinham mais resolução de desenho do que os personagens do jogo permitem. Uma apresentação com bordas serrilhadas pode parecer pixel art e, mesmo assim, esconder olhos, dentes, reflexos e flores que não cabem no sprite. A unidade de revisão passa a ser o **corpo inteiro na sua grelha real**, acompanhado do recorte exato da cabeça. A ampliação vem depois.

O detalhe apreciado no rei não será removido indiscriminadamente. É preciso escolher onde o gastar: silhueta, barriga, expressão, roupa e materiais recebem prioridade; textura decorativa e microdetalhes recebem o espaço que sobrar. Simplificar por falta de espaço exige redesenhar as formas. Reduzir uma ilustração pronta por filtro não resolve essa decisão.

A nova imagem de composição de Sombra e floração explora massas e cores das flores. Ainda apresenta detalhe acima da escala nativa e não certifica o limite 64/96. A prova de dimensão está nos PNGs individuais e nos painéis técnicos.

## 2. Contrato da grelha

| Elemento | Quadro de estudo | Cabeça completa, incluindo chapéu/cabelo | Decisão |
| --- | --- | --- | --- |
| Rei | 96×96 | 26×26 | Exceção para o corpo grande; preservar a direção apreciada |
| Escudeiro | 64×64 | 18×20 | Elmo, olhos e boca repartem este espaço |
| Arqueiro | 64×64 | 21×24 | Perfil estreito, capuz/coroa, nariz e queixo distintos |
| Intendente | 64×64 | 22×23 | Face larga e bigode como massa permanente |
| Nia | 64×64 | 23×25 | Preservar identidade, cabelo e arma |
| Bardo | 64×64 | 25×25 | Chapéu e atuação de canto têm orçamento explícito |
| Imperador de armadura | 96×96 | Elmo fechado integrado ao corpo | O medo vem da silhueta e do vazio do visor |
| Dançarina | 64×64 | 22×23 | Conservar o conceito e a leveza |
| Campo florido | 192×32 por camada | Não se aplica | Efeito separado do quadro do personagem |

Essas medidas descrevem **os estudos entregues**, não uma aprovação das proporções finais. A área de pele onde os olhos e a boca realmente cabem é menor que a cabeça completa. Por exemplo, os 21×24 do arqueiro incluem a coroa e o capuz; não há um retrato facial de 64×64 escondido dentro do personagem.

O pixel de autoria tem o mesmo tamanho para todos. O imperador ocupa mais células e mais espaço no mundo; não recebe pixels menores para acomodar ornamentos. Os painéis ampliam em múltiplos inteiros, sem interpolação. O sombreado em cinzento é diagnóstico; não altera a fonte colorida.

O uso de 96×96 nos dois corpos grandes é uma escolha desta estrutura, compatível com a tolerância indicada por Henrique. Se a produção exigir todos em 64×64, será necessário outro desenho de proporção, não apenas encolher esses dois PNGs.

## 3. Pesquisa aplicada: o que se aproveita e o que é decisão de Empire

Foram consultadas fontes dos próprios artistas. A direção da luz, as dimensões e a paleta abaixo são decisões de projeto; não são leis universais de pixel art.

| Tema estudado | Síntese da fonte | Aplicação proposta |
| --- | --- | --- |
| Construção por grupos | Saint11 organiza a imagem em grupos contíguos de cor [R01] | Dar função a cada mancha; pontos isolados só para detalhes que precisem deles |
| Luz e volume | Saint11 distingue sombra de volume, sombra projetada e reflexo, e trabalha da forma simples para o detalhe [R02] | Resolver primeiro cabeça, torso, placas e braços; depois acessórios |
| Direção da luz | SLYNYRD parte de uma fonte definida e de massas de luz/sombra [R03] | Fixar luz superior esquerda nos estudos diurnos |
| Cor | Saint11 discute valor, saturação, temperatura e relações entre cores como guias flexíveis [R04] | Controlar contraste e saturação antes de adicionar tons |
| Rampas | SLYNYRD mostra relações de matiz, valor e saturação entre degraus [R05] | Compartilhar rampas e evitar tons quase duplicados |
| Materiais | O estudo de texturas de SLYNYRD relaciona padrões e leitura de superfície [R06] | Metal, pano e couro precisam de distribuição de luz diferente |
| Vegetação | SLYNYRD abstrai a planta em massas e repete vocabulários de folhas [R07] | Poucas famílias de tufos, com intervalos e alturas distintas |
| Escala | Estudos pequenos de fazenda trabalham planos e textura sob limites concretos [R08] | Julgar cada detalhe à escala real |
| Acabamento de cavaleiros | SLYNYRD organiza anatomia e volumes antes da superfície; distingue imagem estática de animação [R09] | Preservar articulações e reduzir adornos que não se sustentem entre quadros |
| Limpeza e sombreado | Derek Yu trata contraste, volume e problemas de sombreado que acompanha o contorno [R10] | Conferir se a sombra explica forma ou apenas contorna a figura |
| Antialias manual | Saint11 discute utilidade, excesso e banding [R11] | Suavização interna pode ser intencional; halos dependentes do fundo não entram no export |
| Dimensão antes do detalhe | SLYNYRD define o tamanho e simplifica o corpo antes do equipamento [R12] | Fazer o desenho funcionar dentro do quadro antes das expressões |

O tutorial de personagens de R12 usa outra vista de jogo. Aproveita-se a ordem de construção, sem mudar a vista lateral de Empire. As plantas e os desenhos didáticos das fontes também não são modelos para copiar como personagens ou assets do projeto.

## 4. Luz e sombra: estrutura de trabalho

### 4.1 Uma luz principal antes das manchas

A luz de estudo vem de cima e da esquerda da imagem. O topo do elmo, a testa exposta, o alto do ombro e a manga voltada à fonte devem concordar. A mudança para outra orientação ou para a noite exige uma revisão própria.

É preciso separar quatro funções:

| Função | Pergunta de construção | Exemplo em Empire |
| --- | --- | --- |
| Sombra de volume | Que plano do próprio objeto vira para longe da luz? | Lado inferior da barriga; face lateral da placa |
| Sombra projetada | Que peça bloqueia a luz sobre outra? | Aba sobre os olhos; ombreira sobre o braço |
| Contato/oclusão | Onde dois volumes se encontram e a separação fica mais escura? | Luva no joelho; bota no solo; dobra sob o cinto |
| Reflexo seletivo | Que superfície recebe um acento concentrado? | Aresta do aço e pequena face da fivela |

Essas funções não exigem quatro cores adicionais. Uma mesma cor escura pode cumprir papéis diferentes, desde que a forma da mancha explique o encontro dos volumes. Nem todo fenómeno de iluminação cabe numa cabeça pequena.

A ordem proposta é: **cores locais → planos claros/escuros → sombras entre peças → traços essenciais → limpeza**. A sombra não deve ser uma faixa da mesma espessura ao redor de toda a face. O contorno serve à separação; a iluminação serve ao volume.

### 4.2 Rampas do estudo

A paleta compartilhada tem **38 cores opacas e uma entrada transparente**. Cada corpo utiliza entre 9 e 22 cores opacas. Trabalhar com duas ou três cores por material é o orçamento inicial destes estudos, não uma definição universal de pixel art.

| Material | Sombra | Base | Luz | Luminância relativa dos três tons |
| --- | --- | --- | --- | --- |
| Pele clara | `#9b6350` | `#dca578` | `#f6d1a0` | 16,5% → 43,5% → 67,7% |
| Pele de Nia | `#603f42` | `#97644d` | `#c18b62` | 6,4% → 16,2% → 30,7% |
| Aço do escudeiro | `#465164` | `#77879a` | `#b8bfbe` | 8,1% → 23,6% → 51,2% |
| Azul profundo | `#303a52` | `#465875` | `#6d7d92` | 4,3% → 9,6% → 20,0% |
| Armadura escura | `#303a52` | `#465164` | `#6d7d92` | 4,3% → 8,1% → 20,0% |
| Vinho | `#652d3f` | `#9b4651` | `#cf6964` | 5,0% → 11,9% → 24,3% |
| Verde | `#294c4a` | `#53705a` | `#88a26c` | 6,1% → 14,2% → 32,2% |
| Marfim | `#a79b7b` | `#d7cfac` | `#f7edce` | 33,1% → 62,1% → 84,8% |
| Ouro | `#8b613c` | `#c39a4f` | `#edc66b` | 14,4% → 35,3% → 59,5% |

Os números são luminância relativa calculada em RGB linear a partir dos hexadecimais; não são percentagens de área, valores HSV ou garantias de leitura. A distribuição das manchas importa tanto quanto a distância entre cores.

A rampa escura permite que o imperador tenha massa ameaçadora sem preencher tudo de preto. O aço claro do escudeiro separa o equipamento leve da armadura pesada. Marfim e flores claras podem chamar mais atenção: por isso devem ocupar áreas controladas junto do imperador.

### 4.3 Como distinguir materiais com poucos pixels

| Material | Organização da luz | Refinamento a evitar |
| --- | --- | --- |
| Pele | Testa, maçã do rosto e perfil do nariz como planos contínuos | Mancha vermelha no nariz; brilho branco em cada curva |
| Pano | Mancha ampla na dobra principal e sombra na sobreposição | Contornar cada dobra com três linhas paralelas |
| Couro | Base relativamente estável, acento curto na curva de maior exposição | Tornar botas e correias tão brilhantes como metal |
| Metal | Facetas e acentos de aresta coerentes com a luz | Pontos de brilho distribuídos aleatoriamente |
| Cabelo/bigode | Silhueta agrupada, separação de mechas essenciais | Desenhar fio a fio ou apagar cabelo para abrir a boca |
| Folhas | Base escura conectada e grupos superiores iluminados | Um brilho por folha ou textura uniforme de pontos |
| Pétalas | Poucas massas claras sobre a folhagem | Cada pétala receber um gradiente independente |

O nariz usa a mesma base de pele da testa e da bochecha. Um plano iluminado pode usar a luz dessa rampa; uma área oculta pode usar a sombra. Não existe uma segunda cor local rosa/vermelha exclusiva do nariz.

## 5. Expressões desenhadas dentro da anatomia

O recorte ampliado deve ser **o mesmo dado** colocado no corpo. Não se desenha uma cabeça mais detalhada para a prancha. É necessário reservar espaço entre sobrancelha, pálpebra, nariz, boca e queixo; sobrepor traços por falta de espaço não cria expressão.

O estudo limita-se a alterações faciais sobre uma pose corporal fixa. A atuação completa ainda requer inclinação de cabeça, ombros, braços e apoio, em poses próprias da ação. A máscara fixa usada aqui é uma proteção para estudar continuidade, não uma proibição de deformar bochechas ou cabelo na futura animação.

| Personagem | Calma | Foco | Medo | Golpe | Ferido | Vitória |
| --- | --- | --- | --- | --- | --- | --- |
| Rei | Pálpebra baixa e sorriso seguro | Sobrancelha comprime; sorriso fecha | Tenta sustentar a compostura; dentes tensos | Olho contrai, boca lateral comprime | Peso na pálpebra e canto da boca | Grin largo, bochecha sobe |
| Escudeiro | Atenção insegura sob o elmo | Olhar estreito atrás do escudo | Abertura curta de olho e boca | Olho fecha; mandíbula trava | Pálpebra cai, queixo recolhe | Alegria breve de quem conseguiu |
| Arqueiro | Olhar enviesado e meio sorriso | Linha da pálpebra firme; maxilar contido | Olho abre; boca pequena interrompe a confiança | Contração oblíqua e dentes agrupados | Meio olhar e canto da boca baixo | Sorriso de canto, satisfação controlada |
| Intendente | Sobrancelha pesada e desconfiança | Testa comprime; bigode continua inteiro | Olho ganha área sob a boina | Bochecha comprime sob o bigode | Cansaço nos olhos, lábio pouco exposto | Olho amacia, sorriso aparece nas bordas |
| Nia | Confiança frontal | Concentração e tensão de prontidão | Reação alerta | Careta curta e forte | Olhar pesado sem perder identidade | Alegria expansiva |
| Bardo | Boca pronta para cantar | Vogal estreita e atenção musical | Canto interrompe; olho abre | Som/careta vertical | Boca fecha; energia cai | Boca de canto ampla |
| Dançarina | Pálpebra suave e sorriso curto | Atenção serena | Sobressalto contido | Contração breve | Expressão abatida e delicada | Prazer no gesto, sem copiar o riso do bardo |

O imperador de elmo fechado comunica através da inclinação da cabeça, da linha dos ombros, das mãos e do peso. Acrescentar olhos desenhados sobre o visor mudaria o conceito apreciado.

**Regra do intendente:** o desenho do bigode fica acima da zona da boca. A careta é construída nos espaços existentes; não limpa a área ocupada pelos pelos. O pacote verifica a permanência desse bigode nos seis estados. A produção dos demais personagens com barba/costeletas deve receber verificação equivalente.

## 6. Refinamento de cada conceito

| Personagem | Preservar | Aprofundar na remodelação |
| --- | --- | --- |
| Rei | Barriga coberta, coroa, cabelo/costeletas, vinho/marfim/azul, humor apreciado | Barriga como volume único; capa apoiada nos ombros; sorriso com assimetria própria; pernas a receber o peso |
| Escudeiro | Elmo, escudo, escala pequena e atuação apreciada | Face exposta legível; braço realmente sustenta o escudo; joelhos e ombros respondem ao esforço |
| Arqueiro | Função, acessórios e família cromática | Perfil comprido sem excesso de nariz; olhos deliberados; braço de mira e puxada têm função diferente; aljava não recorta o rosto |
| Intendente | Corpo compacto, boina, bigode, mão de pagamento e carga | Contrapeso da aljava; sobrancelhas legíveis; nariz amplo na mesma pele; mão e moedas como grupos claros |
| Nia | Identidade, cabelo, arma e confiança | Quadril e ombros em oposição; pernas sustentam prontidão; arma acompanha a intenção |
| Bardo | Chapéu, instrumento, presença musical | Peito participa do canto; dedos simplificados; instrumento tem peso e não atravessa o braço |
| Imperador | Conceito sombrio, visor vazio, coroa estreita, armadura e vinho | Ombros desiguais; cabeça afundada; placas articuladas; grande contraste ao sentar entre flores |
| Dançarina | Todo o conceito apreciado | Curva do gesto, mãos legíveis, apoio de uma perna e continuidade do lenço |

As versões nativas de construção não autorizam voltar a desenhar o rei ou a dançarina como personagens genéricos. O refinamento estético deve regressar às referências apreciadas em cada comparação.

## 7. Flores: leitura das sete referências de Henrique

As referências não compartilham uma grelha de pixel art. O seu valor é a composição botânica e a organização das massas.

| Referência recebida | O que estudar | Tradução para o campo pequeno |
| --- | --- | --- |
| 044546 — vegetação vermelha/laranja | Grupos com perfis diferentes | Não repetir o mesmo tufo em toda a faixa |
| 044743 — folhagem e campo florido de Gigantic | Camadas densas, dominante cromática e alturas | Conectar a base verde; separar grupos florais |
| 044809 — flores, capim e pedras | Relação de folhas largas e flores abertas | Criar famílias de folhas e flores de poucos pixels |
| 044822 — margaridas e vegetação | Contraste claro sobre massa verde | Concentrar pétalas claras em alguns focos |
| 044857 — estudos botânicos detalhados | Diversidade de crescimento | Selecionar poucas estruturas, sem copiar cada folha |
| 044923 — aquarelas de flores silvestres | Ritmo de alturas e espaços vazios | Alternar tufos baixos, médios e hastes altas |
| 044928 — processo de glicínias | Volumes grandes antes do detalhe | Resolver massas claras/escuras antes de pétalas |

### 7.1 Construção proposta

O campo deixa de ser uma faixa uniforme de pontos coloridos. A composição principal reúne grupos de tamanhos diferentes, ligados por uma base mais baixa. Os vazios são desenhados junto com as plantas. As hastes não devem alinhar todas as flores na mesma altura.

O estudo nativo usa folhas largas agrupadas, hastes conectadas à base e 22 posições florais distribuídas em alturas distintas. Há três variações cromáticas: **marfim/lavanda**, **rosa/marfim** e **marfim/amarelo**. Marfim/lavanda é a proposta principal; os outros painéis ajudam a comparar o efeito da cor sem alterar a escala.

A imagem de composição amplia a intenção de abundância e mostra cinco massas principais. O estudo nativo é mais contido e ainda necessita de refinamento artístico para alcançar esse acabamento dentro do orçamento real.

### 7.2 Cor e profundidade

O verde sustenta o campo e ocupa a maior massa conectada. Uma família de flores domina, outra aparece em segundo plano e a terceira funciona como acento. O colorido vem da relação entre grupos, não da alternância aleatória de todos os matizes.

A folhagem de trás pode subir ao lado do corpo. A da frente fica baixa perto das botas e do contato da capa. Evitar contorno preto em cada folha: a sombra compartilhada da base pode separar o tufo. Cores muito claras próximas do elmo ou das mãos precisam ser revistas para não competir com a leitura do personagem.

### 7.3 Apoio e surgimento

A habilidade deverá seguir esta ordem de atuação:

1. O imperador prepara a descida e desloca o peso.
2. Joelhos e quadril articulam; a armadura continua rígida em cada peça.
3. Quadril/capa encontram o chão; mãos assentam nos joelhos.
4. Brotos surgem na zona de contato.
5. Hastes crescem em grupos com pequenas diferenças de tempo.
6. Flores abrem e o conjunto assenta.

Esta lista descreve a produção futura. O pacote contém **duas poses do imperador e três estágios estáticos de crescimento**, não a interpolação nem o ciclo completo. Na composição nativa, imperador, dançarina e efeito partilham a linha de chão; o campo tem camadas próprias, sem obrigar o corpo a abandonar o quadro 96×96.

## 8. Método da remodelação

| Passo | Trabalho concreto | Condição para avançar |
| --- | --- | --- |
| 1. Comparação | Colocar o corpo ao lado das referências apreciadas, na mesma unidade de pixel | Identidade e família visual reconhecíveis a 1× |
| 2. Silhueta e peso | Resolver cabeça, torso, apoio e acessório principal em poucas massas | Pose legível preenchida de uma só cor |
| 3. Valores | Distinguir planos principais antes da textura | Rosto, braços, roupa e equipamento continuam separados em cinzento |
| 4. Materiais | Aplicar rampas e sombras entre peças | Luz concorda entre rosto, corpo e acessórios |
| 5. Expressão | Atuar sobre a cabeça real e conferir no corpo | Personalidade legível sem aumentar a resolução |
| 6. Acabamento | Limpar escadas, grupos e detalhes essenciais | Cada acento tem função; não há textura para mascarar forma |
| 7. Poses extremas | Desenhar preparação, contato, esforço e recuperação | Apoio e identidade sobrevivem à mudança de pose |
| 8. Ciclos | Produzir animações com os tempos do projeto | Revisão em movimento, recortes limpos e eventos sincronizados |

Não convém multiplicar dezenas de quadros a partir de um rosto ainda mal resolvido. O pedido anterior de animações completas continua ligado à definição dos conceitos.

## 9. O que foi verificado no pacote

Foram produzidos **43 PNGs corporais de estados**, 42 recortes de cabeça, oito corpos de referência, uma pose sentada, oito diagnósticos de cor base, três pares de camadas florais, três composições e três estágios de crescimento, além dos quatro painéis.

A verificação confere: dimensões 64/96; modo indexado; transparência sem meios-tons; espaço dentro do quadro; igualdade entre o recorte de cabeça e os pixels usados no corpo; silhueta estável nas trocas faciais deste ensaio; seis imagens faciais distintas por personagem; e permanência dos pixels do bigode do intendente.

**Esses resultados não medem beleza, personalidade, iluminação correta, fluidez ou fidelidade ao conceito apreciado.** A revisão visual continua necessária. O estudo é estático e não foi integrado nem validado em movimento no Godot.

### Conteúdo e edição

- `EMPIRE-ELENCO-NATIVO-V5.png`: estudo de corpos e proporções, ampliação 4×.
- `EMPIRE-LUZ-SOMBRA-V5.png`: cor base, planos iluminados e leitura em valores.
- `EMPIRE-EXPRESSOES-NATIVAS-V5.png`: cabeças a 6× e amostras a 1×.
- `EMPIRE-CAMPO-FLORIDO-NATIVO-V5.png`: apoio no chão e comparação das três paletas.
- `sprites/`, `expressions/`, `flowers/`, `diagnostics/`: PNGs em tamanho nativo.
- `source/build_native_studies.py`: coordenadas inteiras e paleta editáveis.
- `source/palette.json`, `manifest.json`, `validation.json`: dados exportados e resultados.

O construtor requer Python 3.9+ e Pillow 10.1+. Executar `python3 source/build_native_studies.py` na pasta extraída reconstrói os estudos. A paleta é definida no código; o JSON é um registo exportado. Os desenhos foram construídos por coordenadas inteiras para esta prova, sem reduzir ou quantizar as referências recebidas. Não há ficheiro Aseprite nem animações completas neste ZIP.

A imagem adicional de composição foi produzida com a ferramenta nativa de imagens, como estudo visual de acabamento. O prompt integral e as funções de cada referência estão em `source/PROMPT-COMPOSICAO-V5.txt`. Essa imagem não pertence à validação de dimensões dos PNGs nativos.

## 10. Fontes consultadas

Acesso em 18/10/2026. As aplicações a Empire, os limites numéricos e as escolhas de personalidade são decisões deste estudo.

- **R01 — Saint11, Basic Pixel Art.** [Grupos de pixels e construção](https://saint11.art/pixel_art_articles/article2/).
- **R02 — Saint11, Basic Shading.** [Volume, sombras entre objetos e ordem de acabamento](https://saint11.art/pixel_art_articles/article4/).
- **R03 — SLYNYRD, Pixelblog 6: Light and Shadow.** [Fonte de luz e organização tonal](https://www.slynyrd.com/blog/2018/6/15/pixelblog-6-light-and-shadow).
- **R04 — Saint11, Basic Color Theory.** [Valor, saturação, temperatura e esquemas](https://saint11.art/pixel_art_articles/article6/).
- **R05 — SLYNYRD, Pixelblog 1: Color Palettes.** [Rampas cromáticas](https://www.slynyrd.com/blog/2018/1/10/pixelblog-1-color-palettes).
- **R06 — SLYNYRD, Pixelblog 2: Texture.** [Organização de texturas](https://www.slynyrd.com/blog/2018/2/15/pixelblog-2-texture).
- **R07 — SLYNYRD, Pixelblog 15: Plant Life.** [Abstração e massas vegetais](https://www.slynyrd.com/blog/2019/3/7/pixelblog-15-plant-life).
- **R08 — SLYNYRD, Pixelblog 34: On the Farm.** [Planos e detalhe em elementos pequenos](https://www.slynyrd.com/blog/2021/10/24/pixelblog-34-on-the-farm).
- **R09 — SLYNYRD, Pixelblog 57: Knights, Monsters & Castles.** [Anatomia, volumes e custo do detalhe](https://www.slynyrd.com/blog/2025/7/28/pixelblog-57-knights-monsters-amp-castles).
- **R10 — Derek Yu, Pixel Art Tutorial, parte 2.** [Contraste e sombreado](https://derekyu.com/makegames/pixelart2.html).
- **R11 — Saint11, Anti-Alias and Banding.** [Suavização manual e banding](https://saint11.art/pixel_art_articles/article5/).
- **R12 — SLYNYRD, Pixelblog 22: Top Down Character Sprites.** [Escala e corpo antes do equipamento](https://www.slynyrd.com/blog/2019/10/21/pixelblog-22-top-down-character-sprites).

