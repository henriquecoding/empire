# Asset Bible — como cada asset do Empire é produzido

> Complementa a direção de arte do dossiê (§01, §11, §21, §22, §58–§60) com o que ela não dizia: **que ficheiros
> existem, com que tela, pivot, camadas, nomes e estados.** Onde este documento e o dossiê discordarem em
> *intenção artística*, manda o dossiê; em *nome de ficheiro, pivot ou exportação*, manda este (§39: a arte fica
> com §01/§11/§22, as consequências técnicas ficam aqui).
>
> Registo completo: [`ASSET_REGISTER.csv`](ASSET_REGISTER.csv) · Animação: [`ANIMATION_BIBLE.md`](ANIMATION_BIBLE.md)
> · Rostos: [`EXPRESSION_GUIDE.md`](EXPRESSION_GUIDE.md) · Efeitos: [`VFX_REGISTER.csv`](VFX_REGISTER.csv)

## 1 · A unidade gráfica

| Regra | Valor | De onde |
|---|---|---|
| Resolução interna | **1280 × 720**. Não se reduz. | §01 (medido: 1:1 nativo, 6,3% de perda a 640×360) |
| Grelha de autoria | 1:1 — um pixel de arte é um pixel de ecrã a 720p | §01 |
| Lei da escala dupla | **Cenário e edifícios: detalhe mínimo de 2 px** (cluster 2×2). Camadas distantes: 4 px (cluster 4×4). **Personagens: 1 px** — a única exceção, de propósito | §01, §22 |
| Contorno | Preto puro `#000000`. **1 px** em personagens e detalhe interno; **2 px** na silhueta de cenário e edifícios (desenhado ou pelo *shader* `outline_dilate`); **nenhum** nas camadas de parallax 1–4 | §22 gramática |
| Sombreamento | Dois tons por material. Sem gradientes. | §01, §22 |
| *Dithering* | Só em efeitos (revelação, dissolução) e nas bandas do céu. Nunca decorativo | §22 |
| Pixels soltos no cenário | Proibidos (cluster mínimo 2×2) | §22 |
| Sombra de contacto | Tudo o que toca o chão: elipse castanho-escura quente, multiplicativa, 45–55%, **nunca preta**; escala com a **largura** | §22 degrau 1 |
| Céu livre | ≥ 30% da altura do ecrã acima do telhado mais alto, sem nada contornado | §11, §22 |
| Grelha de tile | **32 px** (autoria em 64×64 = 2×2 tiles) | §22 |
| Paleta | `art/palettes/empire_working.gpl` — as 112 cores de trabalho em 7 famílias. **Fecha no fim da fatia vertical**: extrair de novo, fundir cores a < 4%, e a partir daí é lei | §22 |
| Materiais | Estuque creme · vigas castanho-escuro · telha azul-petróleo escamada · pedra cinza-frio · madeira quente · relva verde-lima. Um material novo exige justificação escrita | §01, §22 |
| Rampas por povo | Um povo troca a **rampa dominante**, não a estrutura da paleta (se a Fornalha tiver 30 âmbares, é outro jogo) | §22 |

### Escalas de personagem e tamanhos úteis

| Escala | Quem | Altura útil | Tela padrão | Pivot | Medido em |
|---|---|---|---|---|---|
| 1 | Escudeiro, tropas pequenas, Rastejante | 32–36 px | 64 × 64 | (32, 56) | escudeiro do trono ≈ 34 px (§01) |
| 2 | Aldeões, tropas, ofícios | 46–52 px | 96 × 96 | (48, 88) | `Empire troop` 24 × 47 úteis (§01) |
| 3 | Monarca, elites, cavaleiros | 56–62 px | 128 × 128 | (64, 120) | `Knight Potato` 35 × 64 úteis (§01) |
| Colosso | Aríete de lodo, Consumidora, veículos | até 160 px | 256 × 256 | (128, 248) | — |

**Pivot = o ponto de contacto dos pés com a linha do solo, ao centro horizontal do corpo no frame 1 de `idle`.**
É o mesmo em todas as camadas, todas as animações e todos os frames de um corpo. A tela deixa 8 px por baixo
do pivot para pó e sombra, e espaço acima e aos lados para armas e ataques. *As telas padrão são uma proposta:
valida-a separando o `Empire troop` (tela atual 192 × 192) antes de a fixares — é a Etapa 4 do relatório.*

### Edifícios e cenário

| Coisa | Regra |
|---|---|
| Edifício pequeno | ≈ 120 × 130 px (o ferreiro da panorâmica, §22 — indicativo) |
| Pivot de edifício | Centro da base, na linha do solo. A soleira de 12–20 px à frente da fachada (§21) é desenhada no edifício |
| Estados de construção | `empty · scaffold · building · done · damaged · ruin` — **frames do mesmo ficheiro**, não cenas diferentes (§55) |
| Largura | Múltipla de 32 px sempre que possível (grelha de tile) |
| Assunto | Um por segmento de 640 px (§21, regra 2) |
| Variantes de *prop* | **4 no mínimo**; nunca a mesma variante a menos de 400 px; espelhar proibido em tudo o que tenha lado iluminado (§21, regra 4) |
| Remate do telhado | É onde vive 80% da identidade do povo (§21, regra 3). Teste: tapa tudo abaixo da linha do solo — tens de continuar a distinguir os seis povos |

## 2 · O sistema de slots

Os teus ficheiros já separam as camadas; o dossiê formalizou-as em cinco slots (§22) e deu-lhes ordem Z (§58).
O relatório mestre sugeria outra lista (Body, Face, Equipment, Weapon, Shield/Secondary). **Manda a §58.** Esta é
a tabela de correspondência:

| Slot (§58) | Z | Trocado por | As tuas camadas atuais | Relatório mestre |
|---|---|---|---|---|
| `shadow` | −1 | largura do sprite (`shadow_width`) | — (nova) | — |
| `body` | 0 | povo e escala | `Body` | Body |
| `head` | 1 | identidade (sorteada do fluxo `visual`) | `Equipments` *(a confirmar: Q-024)* | Equipment |
| `face` | 2 | estado e lealdade — **nunca guardado** | `Face` | Face |
| `weapon` | 3 | nível do ferreiro | `Sword`, `Arms and Weapons` | Weapon |
| `shield` | 3 | nível do ferreiro | `Shield` | Shield / Secondary |
| `overlay` | 4 | efeitos ativos | — (nova) | — |

`Knight`, `References` e `Background` são camadas de trabalho: não se exportam.

### Regras por slot

| Slot | Pivot | Frames | Palette swap | Espelhar | Exceções |
|---|---|---|---|---|---|
| `body` | o do corpo | todas as tags (§4) | sim — `palette_lut` faz povo, hora do dia, encantamento e estado (§60) | sim (`flip_h`) | Cavaleiro Selado: corpo + cavalo num só `body` |
| `head` | o do corpo | as mesmas do `body`, frame a frame | sim | sim | coroa torta do rei: nunca troca |
| `face` | o do corpo | as mesmas do `body` | sim (`apodrecido` é LUT, não desenho novo) | sim | ver EXPRESSION_GUIDE |
| `weapon` / `shield` | o do corpo | as mesmas do `body` | sim | sim — o escudo muda de braço, aceite | arma saqueada (§09): usa o nível 4 com a rampa do povo de origem |
| `overlay` | o do corpo | loop próprio de 4–6 frames | não | sim | marca do arqueiro é `outline_dilate`, não overlay |
| `shadow` | centro da base | 1 frame | não | — | voadoras: sem sombra (não tocam o chão) |

**Compatibilidade:** todas as camadas de um corpo partilham tela, pivot, tags e número de frames. Uma cabeça
desenhada para a escala 2 não entra na escala 3. Um slot vazio num frame é permitido (transparente); um slot com
menos frames do que o corpo não é.

### Um ficheiro por corpo, uma folha por camada

A §22 diz *"uma camada por slot"* dentro do ficheiro; a §58 nomeia a exportação por slot. As duas cabem juntas, e
é como já trabalhas:

- **Fonte:** um `.aseprite` por **corpo-base** (povo × escala), com uma camada por variante de slot —
  `body`, `face_normal`, `face_hurt`, `head_hood`, `weapon_bow_l1`… — e uma *tag* por animação.
- **Exportação:** uma folha PNG + JSON **por camada**, com o nome da §58 lido como
  `<povo>_<corpo>_<camada>`: `enramados_villager_weapon_bow_l1.png`.
- **Uma tropa não é um ficheiro:** o arqueiro é `enramados_villager` + `head_hood` + `weapon_bow_l1`. A combinação
  vive nos dados (`UnitData.people`, `scale_tier`, `head_pool`, `weapon_kind`), não na arte. É isto que torna
  viáveis seis povos (§22).

Corpos-base previstos por povo: `squire` (escala 1), `villager` (escala 2), `monarch` (escala 3), `elite` (escala 3,
berserker e mercenário). Corpos únicos têm ficheiro próprio: cavaleiros, criaturas, montarias, veículos, fauna,
companheiros.

## 3 · Nomes de ficheiro

Identificadores em **inglês**, `snake_case`, sem acentos; povos pelo `id` de `peoples.csv`
(`enramados`, `portuarios`, `fenda`, `horta`, `fornalha`, `sobraiz`), `neutral` para o que é de todos, `rot` para
a Podridão. Os exemplos em português da §19 e da §22 (`enramados_ferreiro_body`) passam a
`enramados_villager_*` + dados — ver NAMING_BIBLE.

| Categoria | Fonte (`art/source/…`) | Exportação (`art/export/…`) |
|---|---|---|
| Corpo de personagem | `<povo>/<povo>_<corpo>.aseprite` | `<povo>/<povo>_<corpo>_<camada>.png/.json` |
| Personagem único | `<povo\|neutral>/<povo>_<id>.aseprite` | idem |
| Criatura | `rot/rot_<id>.aseprite` | `rot/rot_<id>_<camada>.png/.json` |
| Montaria · fauna · companheiro | `neutral/mount_<id>`, `neutral/wildlife_<id>`, `neutral/companion_<id>` | idem |
| Edifício | `<povo>/buildings/<povo>_<id>.aseprite` — tags = estados | `<povo>/buildings/<povo>_<id>.png/.json` |
| Muralha | `<povo>/walls/<povo>_wall_l<n>_<peça>.aseprite` (`segment`, `cap`, `gate`) | idem |
| *Prop* | `<povo\|neutral>/props/<povo>_prop_<nome>_<vv>.aseprite` (`vv` = 01–04+) | idem |
| Terreno | `<bioma>/tiles/<bioma>_tiles_<camada>.aseprite` (`surface`, `soil`, `cavity`, `transition`) | `.png` + `TileSet` |
| Parallax | `<bioma>/parallax/<bioma>_parallax_<camada>_<peça>.aseprite` | idem |
| Céu | `<bioma>/sky/<bioma>_sky_<coisa>.aseprite` (`bands`, `sun`, `moon`, `cloud_vv`) | idem |
| Interface | `ui/ui_<nome>.aseprite`; ícones `ui/icons/ui_icon_<nome>.aseprite` | `ui/…` |
| Efeitos | `fx/fx_<nome>.aseprite` | `fx/…` |
| Sombras | `neutral/shadow_<largura>.aseprite` | `neutral/shadow_<largura>.png` |
| *Placeholder* | — | `_placeholder/<nome>.png` (cor lisa; registo em `docs/ASSETS_TODO.md`) |

Tags de animação: nomes do ANIMATION_BIBLE (`idle`, `walk`, `attack`, `die`…), em minúsculas. Nomes de camada:
`<slot>` ou `<slot>_<variante>` (`face_hurt`, `weapon_bow_l2`).

## 4 · Estados de produção

Cada linha do `ASSET_REGISTER.csv` está num destes estados. Só se avança quando o critério de saída passa.

| Estado | O que existe | Sai quando |
|---|---|---|
| `TODO` | Uma linha no registo | Há tamanho, pivot e tela decididos |
| `BLOCKOUT` | Forma lisa de cor, no tamanho certo, **já no jogo** (greybox) | Passou as perguntas do GREYBOX_RULES: cabe, lê-se, percebe-se |
| `DRAWING` | Pixel art estática, com a paleta e os materiais certos | Silhueta e remate aprovados a 100% de zoom out |
| `ANIMATION` | Todas as tags do ANIMATION_BIBLE para este asset | Frames de ação, pivot e pés conferidos na grelha |
| `REVIEW` | Revisão contra a secção 7 (checklist) | Nenhum item falha |
| `APPROVED` | Aprovado; nada muda sem nova revisão | Exportado sem avisos |
| `EXPORTED` | PNG + JSON em `art/export/`, gerados pelo *script* | Importado no Godot e visto em cena |
| `IN_GAME` | Usado por uma cena ou por dados (`sprite_frames`) | — |

`implemented` e `reviewed` no registo são `yes`/`no`, para filtrar depressa na folha de cálculo.

## 5 · Da Aseprite ao Godot

1. **Autoras** em `art/source/` (Git LFS desde o primeiro commit, §28; `art/source/.gdignore` impede o Godot de
   tentar importar `.aseprite`, §69).
2. **Exportas** com `tools/export_aseprite.sh <ficheiro.aseprite>`: uma folha por camada, com as tags no JSON.
   O *script* usa a linha de comandos da Aseprite (`--layer`, `--sheet`, `--data`, `--list-tags`). *Não foi
   testado no ambiente onde este repositório foi montado, porque lá não há Aseprite — corre-o uma vez com o
   `Empire troop` antes de confiares nele.*
3. **Importas** com o Godot Aseprite Wizard (§22, §28) para `SpriteFrames`, respeitando tags e camadas. A
   dependência precisa da ADR 0010 antes de entrar em `addons/` (regra 8 do AGENTS.md).
4. **Ligas** o `SpriteFrames` ao `UnitData.sprite_frames` (ou equivalente) no CSV — a coluna aceita um caminho
   `res://`. A cena nunca carrega arte por nome inventado.

`art/export/` é gerado e não se versiona (`.gitignore`), exceto `art/export/_placeholder/`, que fica fora do LFS
para o CI e o *export* do dia zero terem imagens reais (ADR 0009).

## 6 · Regras por categoria

| Categoria | Regra de produção | Dossiê |
|---|---|---|
| Personagens | Design fechado: **não se redesenha**. O trabalho é separar em slots e animar | §01, §22 |
| Criaturas | Vocabulário visual da Podridão (ameixa e sombra, 7 cores); leem-se como *dentro* da mancha. Idle, walk, attack, die | §07, §22 |
| Edifícios | Objetos autónomos com estados de construção/destruição; luz quente pontual nas oficinas (`warm_light` nos dados) | §22, §55 |
| Muralhas | 5 níveis × segmento, remate e portão = 15 peças por povo; material e silhueta por povo, mecânica igual | §10, §22 |
| Terreno | 4 *tilesets* por bioma — superfície, corte de solo, cavidade, transições — num `TileSet` do Godot | §22 |
| Vegetação e detritos | Milhares de instâncias sem lógica: `MultiMeshInstance2D`, nunca `Sprite2D` por tufo | §59 |
| Céu | Bandas lisas com *dither*; sol e lua posicionados pelo `GameClock`; a hora do dia é LUT, não repintura | §22, §59 |
| Parallax | Camadas 1–4 geradas **uma vez por região** a partir de peças; deltas de saturação, valor, matiz e detalhe do `parallax_layers.csv` | §21, §22, §54 |
| Cavidades | Desenhadas como terra até serem descobertas; o `dither_reveal` abre-as | §11, §60 |
| Interface | Roda do rei como vitral de 6 segmentos com **ícones entalhados**, nunca palavras; fonte ≥ 12 px de altura de carácter | §24, §26 |
| Sinalética | Ícone entalhado em madeira, nunca texto | §01 |
| Efeitos e partículas | Ver VFX_REGISTER; partícula de impacto de 4 px | §24 |
| Ícones | Mesma gramática da sinalética: madeira entalhada, 2 tons | §24 |
| Retratos | **Não previstos** — o HUD é diegético. Só se a UX de gravação os pedir | §24 |
| Itens | Moeda: a animação mais importante do jogo (arco, *bounce*, sombra). Pilha até 99, depois saco | §24, §49 |
| Armas | 4 níveis por família + a arma saqueada; armas largadas no chão leem-se por nível | §09, §22 |
| Sombras | Uma elipse por escala e por classe de objeto | §22 bloco 4 |

## 7 · Checklist de revisão (estado `REVIEW`)

- [ ] Contorno certo para a categoria (1 px personagem · 2 px cenário · nenhum no parallax distante)
- [ ] Nenhum pixel solto no cenário; clusters ≥ 2×2 (≥ 4×4 nas camadas distantes)
- [ ] Só cores da paleta de trabalho (ou justificação escrita para a cor nova)
- [ ] Dois tons por material; sem gradientes; *dither* só onde é permitido
- [ ] Pivot no ponto de contacto dos pés; igual em todas as camadas e frames
- [ ] Tags com os nomes do ANIMATION_BIBLE e o número de frames certo
- [ ] Lê-se a 1× num ecrã de 1280 × 720 e no Steam Deck
- [ ] Lê-se em movimento (ver EXPRESSION_GUIDE para rostos)
- [ ] Sombra de contacto prevista (ou justificação: voa)
- [ ] Nome de ficheiro e de camada segundo a secção 3
- [ ] Linha do registo atualizada (estado, tamanho, frames)

## 8 · A ordem por que se acaba a arte

Do relatório mestre (§27), reconciliada com o §22 do dossiê — a ordem que desbloqueia mais por hora gasta:

1. Sombras de contacto e `CanvasModulate` por plano (≈ 3 h — melhora tudo o que já existe)
2. Separar as personagens em slots e animá-las (≈ 20 h)
3. Cena-cartaz, acabada a 100% (é o teste de quanto custa uma cena)
4. Terreno e parallax
5. Os sete edifícios do ciclo de 10 dias: núcleo, casa de treino, plantação, galinheiro, forja, cozinha, celeiro
6. Muralhas, os cinco níveis
7. Três criaturas: Rastejante, Alado, Bruto
8. Efeitos: a mancha da Podridão e a dissolução primeiro
9. O resto (Fase 6)

O cenário é o caminho crítico (§00): começa durante a Fase 1, aos sábados, em paralelo com o código (§22, opção C).

## 9 · O que já existe

| Ficheiro | Tela | Útil | Frames | Cores | Camadas | Vai para |
|---|---|---|---|---|---|---|
| `Empire troop` | 192 × 192 | 24 × 47 | 6 (idle) | 32 | Knight · Body · Face · Shield · Sword · Equipments | `enramados_villager` (escala 2) |
| `Knight Potato` | 128 × 128 | 35 × 64 | 6 (idle) | 41 | Background · Body · Face · Arms and Weapons | `horta_elite` (escala 3) |
| `Archer Leek` | — | — | — | — | — | `horta_villager` |
| `Healing Frog` | — | — | — | — | — | `companion_sniffer` (proposta — §08) |
| `Empire Concept.png` | 5120 × 720 | — | — | 115 | — | referência, não asset |

As medições são as da §01. Nenhum destes ficheiros se redesenha — separam-se e animam-se.

## Parte XIII — o preto na paleta, a noite castanha e a cara na casca

> Fonte: §74, §80 e a ADR 0011. Aqui ficam as consequências de produção; a intenção está lá.

### Teto de valores por camada

A restrição não é artística — é uma redução de horas. A §22 orçamenta 12 h para as seis camadas de *parallax*, e o
que as torna caras é a indecisão sobre quanto detalhe pôr. Com teto, as três camadas de fundo desenham-se em 5 h.

| Plano (§11) | Valores permitidos | Contorno | Cores |
|---|---|---|---|
| Distância · y 300–420 | 1 | nenhum | `#17130D` |
| Plano médio · y 420–517 | 2 | nenhum | `#241F17` · `#2E251A` |
| Plano de jogo · y 517–720 | toda a paleta | 2 px | inalterado (§22) |
| Primeiro plano · y ≈ 640–720 | 2 | nenhum | `#100D09` · `#14140F` |

**Portão de CI:** conta as cores únicas no PNG exportado de cada camada. Distância > 1, plano médio > 2 ou primeiro
plano > 2 chumba. Corre sobre qualquer captura, como o guião de densidade da §01.

### A noite

Matiz 32°, saturação 0,22, valor 0,16, com chão de valor em 0,11 — os números vivem em `data/source/clock.csv` e
chegam ao jogo em `data/economy/clock.tres`. Nunca em código.

**A regra das duas exceções.** À noite o ecrã tem exatamente duas cores que não são terra, e cada uma quer dizer
uma coisa: **violeta** (`#59386B`, o *token* `--rot`) é A Podridão e só A Podridão; **âmbar** (`#F6D89B` ao núcleo)
é luz, seja a candeia dela ou uma fogueira tua. Um jogador aprende isto em duas noites sem que ninguém lho diga.

**Portão de CI:** píxeis de matiz 200°–290° com saturação acima de 0,35, fora da mancha e à noite, não podem passar
de 0,5% do ecrã.

### A luz desenha-se com três paragens

Núcleo `#F6D89B`, meio `#E8A94E`, bordo `#AE4F16`, e depois dissolve para o ambiente com *dither* de 2 px — o mesmo
*shader* de revelação que a §11 já pede para o corte de terra. Nunca um gradiente.

Uma luz domina por ecrã. É consequência de design e não só de arte: **as fogueiras do jogador têm de ser mais fracas
do que a candeia à mesma distância.** É o que faz da candeia o centro de composição de todas as noites, que é
precisamente onde a §36 quer o GIF de marketing.

**Nada tem contorno dentro do raio de luz.** Perto da luz vê-se cor e volume; longe vê-se silhueta. Inverte-se a
lógica de *sprite* habitual, e é o que dá a sensação de pintura.

### A cara na casca

O Amargueiro é o *sprite* com maior retorno do jogo inteiro e custa três horas: **um tronco por escala — três — mais
o slot `face` das personagens que já existem**, encaixado na casca com uma máscara de casca por cima
(`rot_amargueiro_bark_mask`). Cada Amargueiro tem a cara de quem morreu ali porque é literalmente o mesmo ficheiro.

Não há *sprite* novo por unidade, não há variação a desenhar, e a variedade é automática e total. Um Amargueiro
nomeado usa também a fita do título (`lore_title_ribbon`) no slot `overlay`.

**O que isto obriga:** o slot `face` tem de estar exportado antes do Amargueiro entrar (ART-04 antes de XIII-03), e
a máscara tem de caber nas três telas — 64, 96 e 128.
