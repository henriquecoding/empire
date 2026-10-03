# ADR 0056 — O site mostra o jogo de hoje: fotografias sem interface, monarcas lidos do jogo e uma letra para a interface

- Estado: aceite
- Data: 2026-10-03
- Secção do dossiê: §08, §32, §36, §74, §80
- Complementa: ADR 0025 (o site é a página do jogo)

## Contexto
O dono, a 03/10/2026: *«melhore o design e a experiência do site, ainda está tudo muito amador; pesquise densamente
e refine tudo, inclusive tem muita informação desatualizada»*. Medido no build da `main` (`caa92b5`):

- **As seis fotografias eram do greybox de 25/09**, de antes dos sprites (ADR 0042, 0049–0051). A página dizia-o num
  aviso a negrito, por baixo de cada imagem.
- **Os oito povos diziam todos «É este que se joga hoje»**: a regra era «tem segmentos», e desde o mundo contínuo
  (ADR 0038) todos os povos têm.
- **«Atacar» não tinha tecla** e a habilidade perdia o clique direito: o `project.godot` passou a ter eventos escritos
  à mão no formato compacto (`Object(InputEventKey,"physical_keycode":70)`), e o leitor só conhecia o longo.
- **A candeia era «cor de brasa»** e o âmbar era «a candeia dela ou uma fogueira tua», quando o Lume é roxo e o âmbar
  é teu desde a ADR 0034.
- **Faltava o que o jogo é hoje**: os três monarcas e os companheiros (ADR 0052), o combate manual (ADR 0045), o
  subsolo em sítios (ADR 0046) e as tuas luzes (ADR 0034, 0048).
- **O jogo só se via abaixo da dobra**: a 1440×900, o título de três linhas a 108 px ocupava o primeiro ecrã.

A pesquisa (páginas oficiais do Kingdom e do Kingdom Two Crowns; os guias de páginas de Steam do presskit.gg e do
Indie Game Joe) diz o mesmo de várias maneiras: mostrar o jogo a ser jogado logo no primeiro ecrã, dizer o género e a
diferença numa frase, e ler-se na diagonal — rótulos curtos, cartões, nada de parede de texto.

## Decisão
**O site mostra o jogo de hoje, lido do jogo, e lê-se como uma página de jogo e não como um documento.**

1. **As fotografias são o mundo, sem a interface.** O `tools/captura.gd` ganha `--limpo true` (esconde a
   `CanvasLayer` «Interface»), e o `capturas.py` tira as seis fases no quadro inteiro, 16:9, mais uma miniatura de
   meio tamanho para os cartões das fases. O ecrã *com* a interface tira-se uma vez por língua (o `LANG` de cada
   corrida), e a página portuguesa mostra o painel em português.
2. **A abertura mostra o jogo acima da dobra**, com a linha do dia por baixo do quadro, como a barra de um vídeo. Só a
   manhã vem com `src`; o `site.js` pede cada fotografia a meio da fase anterior, ou logo que se salta para ela. Sem
   JavaScript, o dia fica parado na manhã e não se descarregam cinco imagens que ninguém vê.
3. **Os monarcas lêem-se do ecrã de escolha do jogo**: o título, a introdução e a regra (`MONARCH_CHOOSE_*`), e o
   papel, a base, o companheiro e a evolução de cada um, com os números do `classes.csv` preenchidos pela mesma regra
   do `class_selection.gd`. Um monarca novo no `monarchs.csv` aparece sozinho. O que lê um campo em `_proposed` — hoje,
   as três condições de evolução e a classe da Nia e do Imperador Arqueiro — não se publica como decidido (regra 10):
   o cartão diz «por decidir», e o texto do jogo aparece sozinho quando o campo for aprovado.
4. **O povo de partida é o do segmento onde a partida começa** (`SimFactory.SEGMENTO_DE_PARTIDA`), e a construção
   chumba se não for exatamente um. **O roxo é do Lume e o âmbar do fogo**, os dois do `rot.csv`.
5. **As últimas decisões são as últimas ADR**, lidas de `docs/adr/` com o título e a data: o diário do projeto que
   já existe, em vez de um segundo.
6. **Uma letra para a interface.** A IBM Plex Mono passa a fazer os botões, os rótulos, o menu e os números; a
   Silkscreen, de píxel, fica no nome e no 404 — em corpo 12, maiúsculas e espaçada, era um efeito que não se lia. O
   topo é escuro com qualquer tema, como a abertura que vem a seguir.
7. **O portão mede o que a página nova diz**: os monarcas e o texto deles (e quantos ficam por decidir), o povo de
   partida, o âmbar, uma tecla ou
   um botão por acção, as últimas ADR, o ecrã na língua da página, e as fotografias pedidas a pedido entram na
   conferência das ligações.

## Alternativas consideradas
**Pôr o título por cima da fotografia, em ecrã inteiro.** É o que fazem as páginas dos grandes lançamentos. Rejeitada:
o dia muda a luz debaixo do texto de segundo a segundo, da alvorada clara à noite castanha, e o contraste do título
deixava de se poder garantir (axe, AA).

**Usar o ecrã de escolha como imagem dos monarcas.** Os retratos da Nia e do Imperador Arqueiro ainda são provisórios e
pequenos; a imagem envelhecia antes do texto. Fica o texto, que é o do jogo.

**Subir o orçamento de peso para caberem as seis fotografias.** O jogo de hoje pesa ~45 KB por fase, contra 5 KB do
greybox. Rejeitada: pedir a fotografia quando é precisa deixa a página inteira em ~520 KB, abaixo dos 800 de sempre.

**Uma quinta família de letra (uma sem-serifa).** Era uma dependência nova (regra 8) para um papel que a Plex Mono, que
o site já serve, faz bem.

## Consequências
- As imagens voltam a ficar antigas no primeiro commit que mexa no aspeto do jogo, e a página diz-o, como antes
  (`aparencia`); refazem-se com `make site-capturas`.
- Um povo, um monarca, uma ADR ou uma tecla nova aparecem na publicação seguinte, ou param a construção até terem nome.
- Fica proibido voltar a usar a Silkscreen abaixo de 16 px na página de entrada.
