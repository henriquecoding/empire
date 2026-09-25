# ADR 0024 — O jogo publica-se na Vercel, construído de raiz em cada push

- Estado: aceite
- Data: 2026-09-25
- Secção do dossiê: §19, §32, §36
- Substitui: ADR 0022 (GitHub Pages)

## Contexto
A ADR 0022 pôs o jogo no GitHub Pages, servido pelo job `publicar` do `ci.yml`, e ficou à espera de um clique
que nunca chegou: ligar o Pages exige `admin` e o agente não o tem. Enquanto isso, o dono do repositório ligou
o projeto à **Vercel**. A Vercel construiu o primeiro commit em cinco segundos e respondeu `404` em todos os
caminhos: não havia nada a dizer-lhe o que construir, e a raiz do repositório não é um site.

Há duas coisas que a Vercel tem e o Pages não tem, e as duas contam para um jogo:

- **Pré-visualização por ramo.** Cada push num ramo dá um endereço próprio. Um PR passa a trazer o jogo desse PR
  para jogar, e não só o diff para ler.
- **Cabeçalhos.** O Pages não deixa escolher nenhum. A Vercel deixa (`vercel.json`), e isso abre a porta às
  threads do WebAssembly no dia em que forem precisas (COOP/COEP), sem mudar de sítio outra vez.

O problema é que a Vercel constrói **na máquina dela**, e lá não há Godot. Os templates de export vêm num `.tpz`
de 1,2 GB com todas as plataformas.

## Decisão
**O site constrói-se de raiz em cada push, com `tools/web/construir.sh`, e a Vercel serve `build/site/`.**

1. **O motor e o template vêm dos releases oficiais, na versão de `.godot-version`.** O `tools/web/obter_godot.mjs`
   lê a versão do mesmo ficheiro que a acção do CI lê: um número vive num sítio.
2. **Do `.tpz` tira-se só o template Web, por pedidos parciais** (`tools/web/zip_remoto.mjs`). Um `.zip` tem o
   índice no fim e o GitHub serve com `Accept-Ranges`. Em vez de descarregar 1,2 GB, descarregam-se cerca de
   10 MB, e o CRC-32 de cada entrada é conferido. Medido: 1,5 s em vez de minutos.
3. **Uma construção fria, do checkout ao site, leva cerca de 20 s** (medido sem `.godot/` nem cache). Não há
   passo de instalação: o script só precisa de `bash` e de Node, e a Vercel tem os dois.
4. **O site tem três partes.** Na raiz, a página de entrada (`tools/web/site/`), com os números contados na
   construção e nunca escritos à mão. Em `/jogar/`, o export Web com a casca `tools/web/shell.html`: carregamento
   na cara do jogo, erros em português, e um aviso nos ecrãs táteis. Em `/dossie/`, o dossiê construído pela
   camada de uso.
5. **O mesmo comando corre em qualquer lado:** `make site`, e o `build/site/` serve-se de qualquer servidor
   estático. A Vercel não tem nada que o repositório não tenha.

O job `publicar` do `ci.yml` sai. Avisava em cada corrida da `main` por causa de um interruptor que ninguém ia
ligar, e dois sítios a publicar o mesmo jogo eram dois endereços que divergem.

## A medida: a disciplina do Recibo Certo
O site segue as regras que o repositório Recibo Certo escreveu e mede, e mede-as da mesma maneira: contra o
artefacto, e não contra o código.

- **Telemóvel primeiro.** Nada de rolagem lateral nem de transbordo a 320, 360, 768 e 1440 px, nos dois temas;
  texto visível com pelo menos 12 px; o que se toca com pelo menos 36 px (a excepção *inline* da WCAG 2.5.8
  vale para as ligações no meio de uma frase); `safe-area` e `viewport-fit=cover`.
- **Dois temas, sem clarão.** Segue o sistema até alguém escolher, e a escolha fica guardada. O tema aplica-se
  num `<script>` no `<head>`, antes do primeiro pixel. Os tokens são os do dossiê, e o texto tem tokens
  próprios, calibrados para AA: a cor que se vê e a cor que se lê não têm a mesma régua.
- **Movimento contido.** A curva de easing é a do Recibo Certo (`cubic-bezier(.16,1,.3,1)`). Com
  `prefers-reduced-motion`, ou sem JavaScript, nada fica escondido à espera de uma animação.
- **Cabeçalhos de segurança** em todas as respostas: HSTS, `nosniff`, `X-Frame-Options: DENY`, CORP, e uma CSP
  conservadora (`base-uri`, `object-src`, `frame-ancestors`) que endurece sem partir as fontes.
- **Só a produção se indexa.** Fora de `VERCEL_ENV=production`, a página diz `noindex` e o `robots.txt` fecha
  tudo. Na produção há `sitemap.xml`, Open Graph com imagem própria e dados estruturados.

Há dois portões, e nenhum depende de alguém se lembrar de olhar:

- **`tools/web/verificar_site.mjs`** (`make site-verificar`, e o job `site` do CI) mede o `build/site/` num
  Chromium. Cobre o que está acima, mais o axe (WCAG 2.1 A e AA), as ligações e âncoras, o SEO, o teclado (o
  primeiro Tab é o «saltar para o conteúdo»), e o jogo a arrancar em `/jogar/`.
- **`tools/web/fumo.mjs`** (`make site-fumo URL=…`) pede ao endereço publicado e exige: as rotas, o
  `application/wasm`, os cabeçalhos, o 404 do Empire, o redireccionamento com barra, e o commit em
  `/versao.json`.

## O portão
A ADR 0022 tinha um portão forte: o `publicar` só arrancava depois do `ci` verde. A Vercel constrói logo no push
e não sabe do CI, e isto **aceita-se de olhos abertos**, pelas razões seguintes:

- **A produção é a `main`, e a `main` só recebe PRs fundidos**, que já passaram o `ci`. O portão continua a
  existir: mudou do job para a regra de ramo.
- **As pré-visualizações são de ramos por acabar**, e não se anunciam a ninguém. São para quem revê o PR.
- **O próprio build chumba** quando o export chumba: o `construir.sh` confirma que `index.wasm`, `index.pck`,
  `index.js` e `index.html` saíram, e a página de entrada recusa-se a sair com um `{{MARCADOR}}` por preencher.

## Configuração que fica fora do repositório
**O ramo de produção da Vercel tem de ser a `main`.** Ao importar o projeto, a Vercel escolhe o ramo por omissão
do GitHub, e o deste repositório não é a `main`. Resolve-se com uma de duas coisas: na Vercel, *Settings →
Environments → Production → Branch Tracking*; ou no GitHub, *Settings → General → Default branch*. A API da
Vercel não o deixa mudar de fora.

## Alternativas consideradas
**Construir no GitHub Actions e empurrar para a Vercel com a CLI.** Reutilizava o artefacto `empire-web` e
guardava o portão do `needs:`. Custa um segredo (`VERCEL_TOKEN`) no repositório, perde as pré-visualizações
automáticas por ramo — ou reimplementa-as à mão — e deixa a Vercel ligada ao Git a construir em duplicado.
Rejeitada: o portão já existe na regra de ramo.

**Descarregar o `.tpz` inteiro na Vercel.** Funciona, e custa 1,2 GB por build. Rejeitada por ser o mesmo
resultado mais devagar e com mais bytes.

**Pôr o export no repositório.** São 36 MB de `.wasm` binário por commit. Rejeitada sem discussão.

## Consequências
Passa a haver um endereço que funciona, e um endereço por PR. O `.pck` fica com 0,7 MB: ao montar isto,
descobriu-se que o export arrastava o `node_modules` do `ferramentas/` (21 MB de ícones do Playwright) e as
capturas de `build/`. O `ferramentas/.gdignore`, o `build/.gdignore` e o `exclude_filter` dos três presets
fecham isso também para o Linux e o Windows.
