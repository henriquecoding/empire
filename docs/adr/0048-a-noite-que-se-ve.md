# ADR 0048 — A noite que se vê: o olho habitua-se e as luzes alumiam

- Estado: aceite
- Data: 2026-10-02
- Secção do dossiê: §22, §74, §80
- Complementa: ADR 0011, ADR 0034

## Contexto
O dono, a 02/10/2026: *«a iluminação à noite deve existir, adoro o clima difícil de ver, mas não quero que seja
impossível; os pontos de luz devem existir para afastar as criaturas e iluminar, e o brilho do jogo não pode ser tão
nulo ao ponto de não ver nada como está»*.

O que se mediu numa captura do meio da noite na `main` (`make captura-noite`): o fundo a luminância **14** de 255. O
cenário inteiro levava a tinta da noite no `modulate` (valor 0,16), e o chão ainda menos; os corpos caíam na silhueta;
o castelo-árvore era uma mancha preta. E as luzes não alumiavam nada: a fogueira e o Lume eram **três discos opacos
pintados por cima do mundo** — um alvo que tapava o chão, visível até ao meio-dia. A fogueira desenhava-se como uma
torre de 80 px (a forma da categoria *defesa*), e o rei dentro da luz dela continuava preto: os corpos só olhavam para a
candeia da Podridão.

O que a pesquisa trouxe, e serviu:

- **«Hollywood darkness»** (cinema e level design): *parecer* escuro sem *ser* escuro. Levanta-se o piso do ambiente
  para um mínimo jogável, e é o contraste — luzes fortes contra o resto — que faz a noite, não o preto.
- **O mapa de luz em 2D**: o ambiente mais a soma das luzes, multiplicado pela cor do que se desenha. É a técnica de
  quase todos os jogos 2D com luz (e do `PointLight2D` do Godot), e é a que separa *luz* de *tinta*.
- **Luz em pixel art**: degraus em vez de gradiente, e dither ordenado (Bayer) nas passagens — o que o §80 já pedia
  («três paragens, nunca um gradiente», «dither de 2 px»).
- **Fogo**: cintila com ondas sobrepostas de frequências que não se dividem umas pelas outras, e varia pouco (menos de
  10%), senão pisca em vez de alumiar.
- **Silhueta contra um horizonte mais claro**, e os olhos acesos de quem vem do escuro: lê-se que há alguma coisa sem
  se ver o que é.
- **Luz azul de lua, não.** É o conselho de quase toda a gente, e a ADR 0011 já o recusou com razão: o frio funde-se com
  o roxo da Podridão. A noite continua castanha.

## Decisão
1. **O olho habitua-se** (`night_vision` no `clock.csv`, 0,42, proposta). A cor da noite é a da ADR 0011 — matiz,
   saturação, e o chão abaixo do céu pela mesma razão do §80 —, mas o valor da luz que chega ao mundo não desce abaixo
   deste piso (`BandLight.seen`). De dia nada muda: o dia já está acima dele.
2. **A luz alumia.** Uma luz é um centro, um raio e as três paragens do §80 (`Glow`); soma-se ao ambiente e alumia o
   que está debaixo dela. O cenário recebe-a pixel a pixel num shader (`world_light`, `SceneryLight`), com as paragens
   em degrau e o dither de Bayer de 2 px nas passagens e no bordo; os corpos recebem-na no sítio deles (`Lighting`). As
   contas são as mesmas nos dois sítios, e é no GDScript que se testam. Ninguém pinta discos.
3. **As luzes são as que já existiam, todas juntas** (`LightField`): as obras com `light_radius` (fogueira, farol), o
   archote de quem se conduz e o Lume — e a **lareira do núcleo**, com o raio que o `Torchlight` já contava como «não é
   escuro» (meia largura do núcleo). A lareira não afasta ninguém: só o fogo que compras afasta (ADR 0034). Se deve, é a
   Q-190.
4. **O fogo cintila; o Lume respira** (`Flicker`): a borda anda aos saltos de uma célula do dither, e duas fogueiras
   nunca cintilam em união. Só de noite as luzes se vêem: ao meio-dia contam zero.
5. **A chama é emissiva** (`FlameArt`): pixel a pixel, com as três paragens da própria luz, a dançar mais na ponta do
   que na base, com fagulhas. A fogueira é um anel de pedras com lenha; o farol, uma torre com braseiro (`HearthArt`).
   O Lume é uma chama roxa na base dela.
6. **As obras levam a luz pixel a pixel** (um canvas por trás do resto da faixa): a lareira alumia a porta do castelo e
   as torres ficam no escuro. As barras de vida não levam luz (Q-080), e pintam-se por cima.
7. **A silhueta lê-se**: com o piso, longe de qualquer luz uma tropa fica a meio caminho entre a silhueta quente e a cor
   dela, e a borda de qualquer fogueira já a revela toda. Céu com estrelas, e a lua brilha por si.

## Alternativas consideradas
- **Subir o valor da noite no `clock.csv` (0,16 → 0,42).** É o mesmo número no ecrã, mas apagava a decisão da ADR 0011
  e o teste que lê o chão a 0,11; e misturava a cor da noite com quanto dela se vê.
- **O `PointLight2D` e o `CanvasModulate` do motor.** Um `CanvasModulate` só por canvas (Q-069), as luzes 2D não sabem de
  paragens nem de dither, e o limite de luzes por item morde com dezenas de obras.
- **Pós-processamento do ecrã inteiro.** Escurecia também as chamas, os olhos e os instrumentos, que não levam luz.
- **Luar azul de enchimento.** Recusado pela ADR 0011: o frio é da Podridão.

## Consequências
- Medido na captura do meio da noite: o fundo sobe de 14 para 29 de luminância; a gama do ecrã continua a abrir 235×,
  muito acima dos 16,5× que a paleta do §80 pede, e as duas frias continuam abaixo de 0,05% do ecrã
  (`make silhueta`).
- Os números de composição (o ganho e o tecto das luzes, o alcance por plano, a lareira, as chamas) são greybox como as
  alturas do Silhouette (Q-079): não mudam nada na simulação. `night_vision` é dado, e está em `_proposed`.
- O cenário deixa de ter `modulate`: quem acrescentar um plano novo dá-lhe o `SceneryLight.material()` do plano dele.
- Reverter é pôr o `modulate = BandLight.ambient(...)` de volta nos planos e `night_vision` a 0.
