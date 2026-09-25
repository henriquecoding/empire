# ADR 0025 — O site é a página do jogo: lê o repositório, fala duas línguas e não pede nada a terceiros

- Estado: aceite
- Data: 2026-09-25
- Secção do dossiê: §04, §05, §24, §32, §33, §36, §74, §75, §80
- Complementa: ADR 0024 (o site constrói-se na Vercel em cada push)

## Contexto
A ADR 0024 pôs o site no ar: a página de entrada na raiz, o jogo em `/jogar/`, o dossiê em `/dossie/`. Medido a
25/09/2026 na produção, o site funcionava — e tinha seis defeitos que nenhum portão via:

1. **Entregava o IP de cada visitante à Google.** A página, a casca do jogo, o 404 e o dossiê pediam as quatro
   famílias ao `fonts.googleapis.com` antes do primeiro parágrafo. É o contrário do §32 («medir sem espiar») e, na
   UE, uma transferência de dados pessoais sem base (LG München, 3 O 17493/20).
2. **Falava uma língua só.** O jogo tem PT-PT e EN desde o primeiro dia (`data/i18n/strings.csv`); a página não.
3. **Escrevia à mão o que o repositório já sabe.** Os controlos, o «terceiro crepúsculo» da primeira oferta, o
   que cada fase faz — tudo copiado, e por isso tudo a divergir no primeiro commit que mexesse no original.
4. **A CSP não podia restringir scripts**, porque a página tinha JavaScript em linha.
5. **A imagem de partilha era um recorte mal feito** do ecrã: «EMPIRE» sem o E, «DAY 01 · MORNING» cortado a meio.
6. **As duas capturas não tinham origem**: nenhum comando as refazia, e não diziam de que commit eram.

## Decisão
**O site é uma leitura do repositório, em duas línguas, sem um único pedido a outra origem, e medido.**

1. **Lê o repositório** (`tools/web/dados.mjs`). A duração e a cor de cada fase saem do `clock.csv` (a cor pelo
   `Color.from_hsv` do Godot, byte a byte a do `BandLight`); o raio da candeia, a velocidade e a massa da Podridão
   do `rot.csv`; as falas dela e o dia da primeira oferta do `strings.csv` e do `offers.csv`; o violeta da mancha
   do `WorldPalette`; os controlos do mapa de entrada do `project.godot`; os povos, o ciclo e o roteiro das
   tabelas do §04, do §05 e do §33; o estado do `tickets.json` e do `validation.json`. O que não se consegue ler
   **chumba a construção** com o nome do ficheiro — e um botão novo no `project.godot`, um trilho novo no
   `tickets.json` ou um povo novo sem nome no site também chumbam, de propósito.
2. **Duas línguas, com a mesma forma.** `/` é PT-PT e `/en/` é inglês americano — o do jogo («Colorblind»,
   «Favor»). As duas árvores de `tools/web/paginas/textos.mjs` têm de ter as mesmas chaves e os mesmos itens. As
   tabelas do dossiê têm o português lido do dossiê e o inglês escrito à mão; cada linha inglesa guarda a
   **impressão** da linha portuguesa de onde foi traduzida, e quando o dossiê muda a linha a construção pára e diz
   qual, e o que diz agora. Sem redireccionamento por `Accept-Language`: `hreflang` recíproco e uma ligação.
3. **Nada de terceiros.** As quatro famílias (Fraunces, Source Serif 4, IBM Plex Mono, Silkscreen — todas SIL OFL
   1.1) servem-se de `tools/web/site/fontes/`, subconjuntos latin e latin-ext, com a licença ao lado de cada uma
   (`tools/web/fontes.mjs` volta a trazê-las; corre-se à mão). O dossiê publicado passa a usá-las também.
4. **CSP estrita.** A página de entrada e o 404 não têm JavaScript nem estilos em linha: a folha e os scripts saem
   para `/assets/<nome>.<hash>.<ext>`, servidos com cache imutável, e a página diz `script-src 'self'` e
   `style-src 'self'`. O que seria um `style=""` (a largura de cada fase, a cor da luz, o foco de cada captura) sai
   numa folha gerada dos dados. A casca do jogo continua **autossuficiente** — é o artefacto `empire-web` do CI e
   tem de arrancar de um servidor qualquer —, e é a construção do site que lhe acrescenta a CSP com o SHA-256 de
   cada bloco em linha, `'wasm-unsafe-eval'` e mais nada. Medido: o jogo arranca com zero violações. O único `eval`
   do motor é o do `JavaScriptBridge`, que o jogo não usa.
5. **As imagens são o jogo.** `tools/web/capturas.py` fotografa o segmento de abertura ao meio de cada fase (os
   instantes contados do `clock.csv`), confirma na ficha da captura que cada fase é a certa e que a candeia está
   dentro do quadro, recorta os instrumentos do greybox pela ficha, e grava WebP sem perdas (5 KB por fase: é pixel
   art de cor lisa). O `capturas.json` diz de que commit são e onde está a candeia — que é o foco do recorte num
   ecrã estreito. `tools/web/partilha.mjs` compõe as imagens de partilha (uma por língua) e os ícones num
   Chromium. Correm à mão (`make site-capturas`), e o que sai fica versionado: a Vercel não tem ecrã nem browser.
6. **Medido.** `tools/web/verificar_site.mjs` passa de 11 para 19 grupos de verificações: às de antes
   junta a privacidade (nenhuma página pede nada a outra origem), a CSP (cada página tem a sua e nenhuma é
   violada), as duas línguas com a mesma forma, os dados (o que a página diz é o que o repositório tem), o dia da
   abertura (pausa da WCAG 2.2.2, deslizador pelo teclado), o menu estreito, as contas da candeia e um orçamento de
   peso. O `fumo.mjs` confere na produção o `/en/`, a cache imutável, as fontes e a ausência da Google.

## Alternativas consideradas
**Um gerador de sites (Astro, Eleventy) ou o Next.js do Recibo Certo.** São duas páginas. Um `npm install` na
Vercel acrescentava minutos e uma árvore de dependências a vigiar a um site que o Node constrói em menos de um
segundo com o que já traz. Rejeitada; reabre-se no dia em que houver dezenas de páginas (um devlog, um press kit).

**Manter a Google e pôr um aviso de consentimento.** Um banner para mostrar uma fonte. Rejeitada.

**As fontes pelo npm (Fontsource).** Obrigava a instalar na construção o que se pode versionar uma vez. São
~620 KB no repositório, e só se descarregam os subconjuntos que a página usa.

**Tirar as capturas na construção.** A Vercel não tem ecrã; o CI tem, mas o site passava a depender de um
artefacto do CI, que é exactamente o acoplamento que a ADR 0024 recusou.

**Traduzir as tabelas do dossiê sem impressão.** Era a forma mais simples, e é a que diverge sem ninguém ver.

## Consequências
O que a página diz actualiza-se sozinho: um ticket fechado, uma fase mais curta, uma tecla nova, um povo
renomeado no dossiê aparecem na publicação seguinte — ou param a construção até alguém lhes dar nome. O custo é
esse atrito, e é o que se quer.

A página não carrega nada de fora: nem fontes, nem analytics, nem imagens de outro sítio. Um script que alguém
cole na casca do jogo sem passar pela construção não corre.

Fica proibido: escrever no `tools/web/paginas/` um número que um ficheiro de `data/` ou de `docs/` já tenha;
pôr `<script>` ou `style=""` em linha nas páginas; ligar a uma origem externa para carregar o que quer que seja.
O ícone continua a ser a árvore em píxeis e não é um logótipo: o NAMING_BIBLE proíbe logótipo antes do nome
final (NB-01).

Dependências novas: as quatro famílias de fontes, todas SIL OFL 1.1, registadas no `NOTICE.md` e no
`docs/legal/THIRD_PARTY_ASSETS.csv`. Nenhum pacote de npm novo: o portão usa o Playwright e o axe que já usava.
