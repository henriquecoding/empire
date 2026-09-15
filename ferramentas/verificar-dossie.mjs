#!/usr/bin/env node
/**
 * O PORTÃO DO DOSSIÊ — a regra medida, não sentida.
 * ---------------------------------------------------------------------
 * Porte de `scripts/verificar-movel.mjs` e de
 * `src/lib/__tests__/ligacoes-internas.test.ts` do Recibo Certo, para um
 * documento de ficheiro único.
 *
 * O QUE MEDE, e porque é que cada um falha em silêncio:
 *
 *  1 · ROLAGEM LATERAL — a página abana de lado. Sente-se e não se aponta.
 *  2 · TRANSBORDO — uma caixa cujo conteúdo lhe sai por fora e é o
 *      RECORTE DA JANELA que o corta. Num documento com 122 tabelas é o
 *      defeito mais provável de todos.
 *  3 · PISO TIPOGRÁFICO — texto abaixo de 12px no telemóvel.
 *  4 · ALVOS — o que se toca abaixo de 36px. O rato acerta em 26; o
 *      polegar não.
 *  5 · ÂNCORAS MORTAS — um `href="#x"` cuja secção não existe. Não dá
 *      404: entrega o topo da página em silêncio. Foi por isto que
 *      `/#faq` sobreviveu a uma reescrita inteira no Recibo Certo.
 *  6 · ERROS DE JAVASCRIPT — qualquer excepção por carregar é uma
 *      funcionalidade que não existe.
 *  7 · A PESQUISA RESPONDE — o portão escreve perguntas reais e confere
 *      que saem resultados. Uma barra de pesquisa que abre e não
 *      encontra nada é pior do que não haver barra.
 *
 * Não conta como defeito, e cada isenção tem uma razão:
 *
 *   · camadas decorativas (`aria-hidden`, `pointer-events:none`) — um
 *     halo é maior do que a caixa DE PROPÓSITO;
 *   · caixas que ASSUMEM a rolagem (`overflow-x:auto`) — uma tabela que
 *     desliza com o dedo é uma decisão, não um acidente;
 *   · elementos abaixo de 24px nas duas dimensões — pontos e anéis, onde
 *     1px de arredondamento vira falso positivo;
 *   · LIGAÇÕES EM TEXTO CORRIDO. Esta é a mais importante e a menos
 *     óbvia. Num documento de 360 mil caracteres há 968 referências
 *     «§NN» dentro de frases; obrigá-las a 36px de altura partiria o
 *     entrelinhamento de todos os parágrafos do dossiê para «corrigir»
 *     um problema que não existe. É também o que a própria norma diz:
 *     a WCAG 2.5.8 isenta explicitamente os alvos «numa frase ou num
 *     bloco de texto». A isenção é para elementos `display:inline`
 *     dentro de texto — não para fichas, botões ou linhas de lista, que
 *     continuam todas a ser medidas;
 *   · um controlo de formulário cujo `<label>` associado tem 36px ou
 *     mais — quem toca, toca no rótulo, e é ele o alvo;
 *   · a régua dos 36px só se aplica a larguras de TOQUE (≤ 960px). Num
 *     ecrã com rato a régua é outra: 24px, que é o mínimo AA da WCAG.
 *     Uma linha de índice de 32px é confortável com um ponteiro e
 *     impossível com um polegar, e medir as duas com a mesma régua
 *     produz 1 281 «defeitos» que ninguém vai corrigir — e um portão
 *     que grita de mais deixa de ser lido.
 */

import { chromium } from "playwright";
import { pathToFileURL } from "node:url";
import { resolve } from "node:path";
import { existsSync } from "node:fs";

const FICHEIRO = resolve(process.argv[2]);
const URL = pathToFileURL(FICHEIRO).href;
/* O Chromium desta máquina está num sítio fixo; num runner de CI está onde o
   `playwright install` o pôs. Um caminho absoluto que não existe faz o
   `launch` rebentar com um erro que não diz porquê — por isso só se passa
   `executablePath` quando o ficheiro lá está, e caso contrário deixa-se o
   Playwright resolver o seu. */
const PREF = process.env.PW_CHROME || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const EXEC = existsSync(PREF) ? PREF : undefined;
/* Correr como root (contentor, CI) obriga a desligar a caixa de areia do
   Chromium; numa sessão normal ela fica ligada, que é o que se quer. */
const ARGS = (typeof process.getuid === "function" && process.getuid() === 0) ? ["--no-sandbox"] : [];

const PISO_PX = 12;
const ALVO_MIN = 36;
const RUIDO_PX = 24;

const VIEWPORTS = [
  { nome: "360", width: 360, height: 780 },
  { nome: "320", width: 320, height: 720 },
  { nome: "1280", width: 1280, height: 900 },
];
const TEMAS = ["light", "dark"];

const SONDA = ({ piso, alvoMin, ruido }) => {
  const nome = (el) => {
    const p = [];
    let n = el;
    while (n && n.nodeType === 1 && p.length < 4) {
      let s = n.tagName.toLowerCase();
      if (n.id) s += "#" + n.id;
      else if (typeof n.className === "string" && n.className.trim())
        s += "." + n.className.trim().split(/\s+/).slice(0, 2).join(".");
      p.unshift(s);
      n = n.parentElement;
    }
    return p.join(" > ");
  };
  const decorativo = (el, cs) =>
    cs.pointerEvents === "none" || el.closest("[aria-hidden='true']") !== null;
  const rola = (n) => {
    const c = getComputedStyle(n);
    return c.overflowX === "auto" || c.overflowX === "scroll";
  };

  const transbordos = [], pequenos = [], alvos = [], cortadas = [], mudas = [];
  const vistos = new Set();

  for (const el of document.querySelectorAll("body *")) {
    const cs = getComputedStyle(el);
    if (cs.display === "none" || cs.visibility === "hidden" || cs.opacity === "0") continue;
    const r = el.getBoundingClientRect();
    if (r.width === 0 && r.height === 0) continue;
    const dec = decorativo(el, cs);

    // 2 · transbordo — e só conta se houver um descendente NÃO decorativo
    //     a sair de facto. Sem isto, uma mancha decorativa gera quatro
    //     «defeitos» em cascata (pai, avô, bisavô), nenhum deles real.
    if (!dec && el.scrollWidth > el.clientWidth + 1 && el.clientWidth > ruido &&
        r.height > 4 && cs.overflowX === "visible") {
      const limite = r.left + el.clientWidth + 1;
      const culpado = [...el.querySelectorAll("*")].find((f) => {
        const fcs = getComputedStyle(f);
        if (fcs.display === "none" || fcs.visibility === "hidden") return false;
        if (decorativo(f, fcs)) return false;
        const fr = f.getBoundingClientRect();
        if (fr.width === 0 || fr.right <= limite) return false;
        // Uma etiqueta flutuante sair da coluna onde se ancora é o que
        // ela existe para fazer. Só conta se sair do ECRÃ.
        if (fcs.position === "absolute" || fcs.position === "fixed")
          return fr.left < -1 || fr.right > document.documentElement.clientWidth + 1;
        if (rola(f)) return false;
        for (let a = f.parentElement; a && a !== el; a = a.parentElement) if (rola(a)) return false;
        if ([...f.querySelectorAll("*")].some((n) => rola(n) && n.getBoundingClientRect().right > limite)) return false;
        return true;
      });
      if (culpado) {
        transbordos.push({
          sel: nome(el), caixa: el.clientWidth, conteudo: el.scrollWidth,
          culpado: nome(culpado),
          texto: (culpado.textContent || "").trim().replace(/\s+/g, " ").slice(0, 50),
        });
      }
    }

    // 3 · piso tipográfico — só texto PRÓPRIO e visível.
    //
    // ┌─────────────────────────────────────────────────────────────┐
    // │ DENTRO DE UM SVG, `font-size` NÃO É UMA MEDIDA DE ECRÃ       │
    // │                                                             │
    // │ Num `<text>` o `font-size` computado está em UNIDADES DE     │
    // │ UTILIZADOR, e o que chega ao olho é isso vezes a escala do   │
    // │ `viewBox`. O portão lia 9px numa figura desenhada a 760 e    │
    // │ renderizada a 1070 — onde os 9 são 12,7 no ecrã — e reprovava│
    // │ um texto perfeitamente legível. Ao contrário, uma figura      │
    // │ encolhida para metade passava com 11 «px» que eram 5,5.      │
    // │                                                             │
    // │ O piso é uma regra sobre o que se VÊ: mede-se o tamanho      │
    // │ efectivo, não o declarado.                                   │
    // └─────────────────────────────────────────────────────────────┘
    const escalaSvg = (n) => {
      const svg = n.ownerSVGElement;
      if (!svg) return 1;
      const vb = svg.viewBox && svg.viewBox.baseVal;
      if (!vb || !vb.width) return 1;
      const larg = svg.getBoundingClientRect().width;
      return larg > 0 ? larg / vb.width : 1;
    };
    const proprio = [...el.childNodes].filter((n) => n.nodeType === 3)
      .map((n) => n.textContent.trim()).join(" ").trim();
    if (proprio.length > 1) {
      const fs = Math.round(parseFloat(cs.fontSize) * escalaSvg(el) * 100) / 100;
      if (fs < piso) {
        const chave = fs + "|" + nome(el);
        if (!vistos.has(chave)) { vistos.add(chave); pequenos.push({ px: fs, sel: nome(el), texto: proprio.slice(0, 44) }); }
      }
    }

    /* 5 · A CAIXA QUE CORTA SOZINHA.
       ┌───────────────────────────────────────────────────────────────┐
       │ O DEFEITO QUE ESTE PORTÃO NÃO VIA — E QUE ERA O MAIOR DE TODOS │
       │                                                               │
       │ A verificação 2 procura conteúdo cortado PELA JANELA, e isenta │
       │ as caixas que assumem a rolagem. Uma caixa com                 │
       │ `overflow:hidden` não faz nem uma coisa nem outra: corta       │
       │ dentro dos seus próprios limites, sem sair da janela e sem     │
       │ deixar chegar lá. Não aparecia em lado nenhum.                 │
       │                                                               │
       │ Foi assim que as 123 tabelas do dossiê perderam a rolagem      │
       │ durante uma versão inteira: a camada de desenho pôs            │
       │ `overflow:hidden` no `.tw` para lhe arredondar os cantos, o    │
       │ atalho escreveu os dois eixos, e 103 delas passaram a cortar   │
       │ a última coluna em silêncio. O portão dizia «transbordos 0».   │
       │                                                               │
       │ Isento o que corta DE PROPÓSITO e por uma linha: `ellipsis`,   │
       │ `line-clamp`, e as caixas de 1px que escondem texto para os    │
       │ leitores de ecrã.                                             │
       └───────────────────────────────────────────────────────────────┘ */
    const corta = el.scrollWidth - el.clientWidth;
    if (
      corta > 2 && el.clientWidth > 24 && r.width > 24 && r.height > 8 &&
      cs.overflowX === "hidden" &&
      cs.textOverflow !== "ellipsis" && cs.webkitLineClamp === "none" &&
      (el.textContent || "").trim().length > 8
    ) {
      cortadas.push({ sel: nome(el), caixa: el.clientWidth, conteudo: el.scrollWidth,
                      texto: (el.textContent || "").trim().replace(/\s+/g, " ").slice(0, 44) });
    }

    /* 6 · O SCROLLER QUE NÃO DIZ QUE ROLA.
       Uma caixa que rola de lado sem nada a dizê-lo entrega uma coluna
       cortada e parece um defeito — que foi como o defeito acima chegou
       reportado. Exige-se um sinal: uma sombra de borda (camadas de
       fundo ou um pseudo-elemento) ou o atributo que a camada acende. */
    if (corta > 2 && /auto|scroll/.test(cs.overflowX) && r.width > 40) {
      const antes = getComputedStyle(el, "::before"), depois = getComputedStyle(el, "::after");
      const pai = el.parentElement;
      const diz =
        cs.backgroundImage !== "none" ||
        (antes.content && antes.content !== "none" && antes.content !== "normal") ||
        (depois.content && depois.content !== "none" && depois.content !== "normal") ||
        (pai && (pai.dataset.rolaDir != null || pai.dataset.rolaEsq != null)) ||
        el.dataset.rolaDir != null;
      if (!diz) mudas.push({ sel: nome(el), caixa: el.clientWidth, conteudo: el.scrollWidth });
    }

    // 4 · alvos táteis.
    const clicavel =
      el.matches("a[href], button, input:not([type=hidden]), select, textarea, [role='button'], [role='option']") &&
      cs.pointerEvents !== "none" && el.closest("[aria-hidden='true']") === null && !el.disabled;
    // A isenção de texto corrido (WCAG 2.5.8): `display:inline` dentro de
    // um bloco de texto. Um botão `inline-block` numa barra NÃO é isento.
    //
    // E a prova de que é texto corrido NÃO pode ser o `display`: um
    // `<button>` com `display:inline` na folha de estilo continua a
    // computar `inline-block`, porque o motor blockifica botões. O que
    // define «numa frase» é o CONTEXTO — o elemento é de nível de linha e
    // o pai tem texto solto à volta dele. Uma ficha numa barra de filtros
    // também é `inline-block`, e o pai dela não tem texto nenhum.
    // Não chega perguntar se o PAI tem texto solto: `<strong>A
    // Podridão</strong>` e `<td>faixa</td>` são a palavra inteira, e não
    // deixam de ser uma palavra numa frase por isso. O que define a
    // isenção é viver dentro de um BLOCO DE TEXTO sendo de nível de
    // linha. Os controlos verdadeiros desta camada usam todos `flex` ou
    // `inline-flex`, e por isso continuam medidos.
    const emTextoCorrido =
      (cs.display === "inline" || cs.display === "inline-block") &&
      el.closest(
        "p, li, td, th, dd, dt, caption, blockquote, figcaption, h3, h4, h5, h6," +
        " .note, .cell, .step, .lede, .chapline, .lantern, .kv, .sec-no, .meta, .gloss, .lbl, .ramp-lbl",
      ) !== null;
    // Um controlo cujo rótulo é o alvo real.
    const rotuloGrande = (() => {
      if (!el.id || !/^(INPUT|SELECT|TEXTAREA)$/.test(el.tagName)) return false;
      const lab = document.querySelector(`label[for="${CSS.escape(el.id)}"]`);
      return !!lab && lab.getBoundingClientRect().height >= alvoMin - 0.5;
    })();
    if (clicavel && !emTextoCorrido && !rotuloGrande && (r.height < alvoMin - 0.5 || r.width < ruido)) {
      alvos.push({
        sel: nome(el), w: Math.round(r.width), h: Math.round(r.height),
        texto: ((el.textContent || "").trim() || el.getAttribute("aria-label") || "").slice(0, 40),
      });
    }
  }

  return {
    rolagem: {
      doc: document.documentElement.scrollWidth,
      janela: document.documentElement.clientWidth,
      excesso: document.documentElement.scrollWidth - document.documentElement.clientWidth,
    },
    transbordos, pequenos, alvos, cortadas, mudas,
  };
};

/* ─── Âncoras mortas ────────────────────────────────────────────────── */
const ANCORAS = () => {
  const ids = new Set([...document.querySelectorAll("[id]")].map((e) => e.id));
  const mortas = [];
  for (const a of document.querySelectorAll('a[href^="#"]')) {
    const h = a.getAttribute("href").slice(1);
    if (!h) continue;
    if (!ids.has(h)) mortas.push({ href: "#" + h, texto: (a.textContent || "").trim().slice(0, 40) });
  }
  return { total: document.querySelectorAll('a[href^="#"]').length, mortas };
};

/* ─── A pesquisa responde? ──────────────────────────────────────────── */
const PERGUNTAS = [
  ["podridao", "seccao"],
  ["dia da asfixia", null],
  ["F1-08", "ticket"],
  ["Q-001", "questao"],
  ["noite castanha", null],
  ["arquitetura godot", null],
  ["determinismo", null],
  ["orcamento", null],
  ["clock.csv", "tabela"],
  ["zzzqqqxyw", "VAZIO"],
];

async function correr() {
  const browser = await chromium.launch({ executablePath: EXEC, args: ARGS });
  const falhas = [];
  const resumo = [];

  // ── A · funcional (uma janela larga chega) ──────────────────────────
  {
    const ctx = await browser.newContext({ viewport: { width: 1280, height: 900 } });
    const page = await ctx.newPage();
    const erros = [];
    page.on("pageerror", (e) => erros.push(String(e.message || e)));
    const rede = [];
    page.on("console", (m) => {
      if (m.type() !== "error") return;
      const t = m.text();
      // Um recurso externo que não carrega é o ambiente, não o documento
      // — e o dossiê tem de continuar legível sem ele. Fica registado no
      // resumo para que ninguém o confunda com «tudo bem».
      if (/Failed to load resource|ERR_/.test(t)) { rede.push(t.slice(0, 90)); return; }
      erros.push("console: " + t.slice(0, 160));
    });
    await page.goto(URL, { waitUntil: "load" });
    await page.waitForTimeout(900);

    if (erros.length) falhas.push({ o: "Erros de JavaScript", detalhe: erros.slice(0, 6) });
    if (rede.length) resumo.push(`recursos externos em falta (ambiente, não documento): ${rede.length} — as fontes de ecrã caem para a pilha de reserva, e é assim que esta medição correu`);

    const anc = await page.evaluate(ANCORAS);
    resumo.push(`âncoras internas: ${anc.total}, mortas: ${anc.mortas.length}`);
    if (anc.mortas.length) falhas.push({ o: "Âncoras mortas", detalhe: anc.mortas.slice(0, 12) });

    const montado = await page.evaluate(() => ({
      indice: (window.__X_IDX__ && window.__X_IDX__.docs.length) || 0,
      seccoes: (window.__X_IDX__ && window.__X_IDX__.secoes.size) || 0,
      refs: document.querySelectorAll("a.x-ref").length,
      termos: document.querySelectorAll("button.x-termo").length,
      estado: !!document.getElementById("x-estado"),
      calhas: document.querySelectorAll(".x-calha").length,
      inventario: !!document.getElementById("x-inventario"),
      campo: !!document.getElementById("x-q"),
      viewport: !!document.querySelector('meta[name="viewport"]'),
      lang: document.documentElement.lang,
      quirks: document.compatMode,
    }));
    resumo.push(
      `índice: ${montado.indice} documentos de ${montado.seccoes} secções · ` +
      `${montado.refs} referências §NN ligadas · ${montado.termos} termos de glossário`);
    resumo.push(`figuras em calha deslizante: ${montado.calhas}`);
    resumo.push(`modo: ${montado.quirks} · lang="${montado.lang}" · viewport: ${montado.viewport ? "sim" : "NÃO"}`);
    for (const [k, v] of Object.entries({
      "painel de estado": montado.estado, inventário: montado.inventario,
      "campo de pesquisa": montado.campo,
      "meta viewport": montado.viewport,
    })) if (!v) falhas.push({ o: "Peça em falta: " + k });
    if (montado.quirks !== "CSS1Compat") falhas.push({ o: "Modo quirks", detalhe: montado.quirks });
    if (montado.indice < 400) falhas.push({ o: "Índice demasiado pequeno", detalhe: montado.indice });
    /* ┌───────────────────────────────────────────────────────────────┐
       │ CHÃO PARA AS DUAS CONTAGENS QUE JÁ CAÍRAM DUAS VEZES           │
       │                                                               │
       │ O ligador das §NN e o glossário saltam tudo o que tem uma      │
       │ classe `x-*`, porque é o prefixo da camada. Sempre que um      │
       │ INVÓLUCRO novo passou a embrulhar a prosa do autor, os dois    │
       │ passaram a saltá-la: `x-parte-corpo` levou 941 referências a   │
       │ 174, e `x-rolo` levou 940 a 531 e 150 termos a 84. Nenhuma     │
       │ das duas vezes deu erro — o portão contava menos e dizia que   │
       │ estava tudo bem, porque só imprimia o número.                  │
       │                                                               │
       │ Agora é uma falha. Os chãos estão abaixo dos valores reais o   │
       │ suficiente para não reprovarem por uma frase reescrita, e      │
       │ acima do suficiente para apanharem um invólucro esquecido.     │
       └───────────────────────────────────────────────────────────────┘ */
    /* ┌───────────────────────────────────────────────────────────────┐
       │ NADA DE HTML DENTRO DE UM DESENHO                              │
       │                                                               │
       │ Um elemento HTML inserido dentro de um `<svg>` fora de um      │
       │ `<foreignObject>` fica na árvore e não é pintado. O glossário  │
       │ e o ligador das §NN entravam nos desenhos, e o que marcavam    │
       │ desaparecia do ecrã: a §05 mostrava «nasce na borda do mapa ▸» │
       │ em vez de «A Podridão nasce na borda do mapa ▸», e a §41       │
       │ perdia «EventBus». Sem erro e sem aviso — o texto continuava   │
       │ no `textContent`, só não chegava ao olho.                      │
       └───────────────────────────────────────────────────────────────┘ */
    const dentroDeSvg = await page.evaluate(() => {
      const maus = [];
      for (const svg of document.querySelectorAll("svg")) {
        for (const n of svg.querySelectorAll("*")) {
          if (n.namespaceURI === "http://www.w3.org/2000/svg") continue;
          if (n.closest("foreignObject")) continue;
          maus.push({ tag: n.tagName.toLowerCase(), cls: n.className.baseVal || n.className || "",
                      texto: (n.textContent || "").trim().slice(0, 30),
                      seccao: (n.closest("section[id]") || {}).id || "—" });
        }
      }
      return maus;
    });
    if (dentroDeSvg.length) {
      falhas.push({ o: `${dentroDeSvg.length} elementos HTML dentro de um <svg> — estão na árvore e não são pintados`,
                    detalhe: dentroDeSvg.slice(0, 6) });
    } else {
      resumo.push("nada de HTML dentro dos desenhos: 0");
    }

    /* O piso é MEDIDO, não desejado. O documento tem ~851 «§NN» em nós de
       texto, dos quais 90 estão em código e em títulos, que o ligador não
       toca de propósito; os painéis acrescentam os seus. A régua anterior
       (880) nunca foi atingida por nenhuma construção — nem a de 13/09
       (857) nem a de hoje (858) — e um portão que chumba sempre é um
       portão que se aprende a ignorar. 820 fica abaixo do medido e acima
       do que qualquer regressão real daria: um invólucro `x-*` a esconder
       prosa derruba isto para as centenas baixas, não para 819. */
    const PISO_REFS = 820;
    if (montado.refs < PISO_REFS) {
      falhas.push({ o: `Só ${montado.refs} referências §NN ligadas (esperado ≥ ${PISO_REFS}) — um invólucro \`x-*\` novo está a esconder prosa do autor do ligador. Ver X.INVOLUCROS.` });
    }
    if (montado.termos < 140) {
      falhas.push({ o: `Só ${montado.termos} termos de glossário (esperado ≥ 140) — mesma causa: ver X.INVOLUCROS.` });
    }

    // A pesquisa, escrita a sério.
    const respostas = [];
    for (const [q, tipoEsperado] of PERGUNTAS) {
      const r = await page.evaluate(([consulta]) => {
        const res = X.pesquisar(consulta, window.__X_IDX__.docs, { limite: 8 });
        return { n: res.length, topo: res[0] ? { tipo: res[0].doc.tipo, titulo: res[0].doc.titulo.slice(0, 52), pontos: Math.round(res[0].pontos), campo: res[0].campo } : null };
      }, [q]);
      respostas.push({ q, ...r });
      if (tipoEsperado === "VAZIO") {
        if (r.n !== 0) falhas.push({ o: `Pesquisa devolveu resultados para lixo: «${q}»`, detalhe: r.topo });
      } else if (r.n === 0) {
        falhas.push({ o: `Pesquisa sem resultados para «${q}»` });
      } else if (tipoEsperado && r.topo.tipo !== tipoEsperado) {
        falhas.push({ o: `Pesquisa «${q}» esperava ${tipoEsperado} no topo`, detalhe: r.topo });
      }
    }
    resumo.push("pesquisa:");
    for (const r of respostas) {
      resumo.push(`   «${r.q}» → ${r.n} resultado(s)` + (r.topo ? ` · topo: [${r.topo.tipo}] ${r.topo.titulo} (${r.topo.pontos}, ${r.topo.campo})` : ""));
    }

    // O teclado.
    await page.keyboard.press("/");
    await page.waitForTimeout(160);
    const focado = await page.evaluate(() => document.activeElement && document.activeElement.id);
    if (focado !== "x-q") falhas.push({ o: "A tecla / não foca a pesquisa", detalhe: focado });
    await page.keyboard.type("podridao");
    await page.waitForTimeout(260);
    const aberta = await page.evaluate(() => {
      const c = document.getElementById("x-res");
      return { visivel: !c.hidden, itens: c.querySelectorAll(".x-item").length, expandido: document.getElementById("x-q").getAttribute("aria-expanded") };
    });
    if (!aberta.visivel || !aberta.itens) falhas.push({ o: "A região de resultados não abriu", detalhe: aberta });
    else resumo.push(`teclado: / abre, ${aberta.itens} resultados na região (aria-expanded=${aberta.expandido})`);

    await page.keyboard.press("ArrowDown");
    await page.keyboard.press("Enter");
    await page.waitForTimeout(700);
    const saltou = await page.evaluate(() => ({ hash: location.hash, y: Math.round(window.scrollY) }));
    if (!saltou.hash || saltou.y < 100) falhas.push({ o: "Enter não navegou para o resultado", detalhe: saltou });
    else resumo.push(`teclado: Enter navegou para ${saltou.hash} (y=${saltou.y})`);

    // Sem JavaScript o documento continua a ler-se.
    const ctxSemJs = await browser.newContext({ javaScriptEnabled: false, viewport: { width: 1280, height: 900 } });
    const p2 = await ctxSemJs.newPage();
    await p2.goto(URL, { waitUntil: "load" });
    const semJs = await p2.evaluate(() => ({
      seccoes: document.querySelectorAll("main section[id]").length,
      links: document.querySelectorAll("nav.toc a").length,
      texto: document.body.innerText.length,
    }));
    resumo.push(`sem JavaScript: ${semJs.seccoes} secções, ${semJs.links} ligações de índice, ${Math.round(semJs.texto / 1000)}k caracteres`);
    if (semJs.seccoes < 80 || semJs.links < 80) falhas.push({ o: "O documento não se lê sem JavaScript", detalhe: semJs });
    await ctxSemJs.close();
    await ctx.close();
  }

  // ── B · medição por largura × tema ─────────────────────────────────
  for (const vp of VIEWPORTS) {
    for (const tema of TEMAS) {
      const ctx = await browser.newContext({ viewport: { width: vp.width, height: vp.height }, deviceScaleFactor: 2 });
      const page = await ctx.newPage();
      await page.goto(URL, { waitUntil: "load" });
      await page.evaluate((t) => document.documentElement.setAttribute("data-theme", t), tema);
      await page.waitForTimeout(700);
      // Medir com a folha do telemóvel ABERTA: fechada, o índice inteiro
      // não é medido, e é onde vivem 86 ligações e o campo de pesquisa.
      if (vp.width <= 960) {
        await page.evaluate(() => window.__X_DOCK_ABRIR__ && window.__X_DOCK_ABRIR__());
        await page.waitForTimeout(420);
      }
      const r = await page.evaluate(SONDA, { piso: PISO_PX, alvoMin: ALVO_MIN, ruido: RUIDO_PX });
      const etiqueta = `${vp.nome}px · ${tema}`;
      const pisoAplica = vp.width <= 700;
      const toque = vp.width <= 960;
      // Com rato a régua é o mínimo AA (24px); com polegar é a do design
      // system (36px). Medir as duas com a mesma régua é medir mal uma.
      const regua = toque ? ALVO_MIN : 24;
      const alvosReais = r.alvos.filter((a) => a.h < regua - 0.5 || a.w < RUIDO_PX);
      const n = {
        rolagem: r.rolagem.excesso > 1 ? 1 : 0,
        transbordos: r.transbordos.length,
        cortadas: r.cortadas.length,
        mudas: r.mudas.length,
        pequenos: pisoAplica ? r.pequenos.length : 0,
        alvos: alvosReais.length,
      };
      resumo.push(
        `${etiqueta.padEnd(16)} rolagem ${n.rolagem ? "+" + r.rolagem.excesso + "px" : "0"} · ` +
        `transbordos ${n.transbordos} · corta-sozinha ${n.cortadas} · rola-sem-dizer ${n.mudas} · texto<${PISO_PX}px ${n.pequenos} · alvos<${regua}px ${n.alvos}`);
      if (n.rolagem) falhas.push({ o: `${etiqueta}: a página rola de lado`, detalhe: r.rolagem });
      if (n.transbordos) falhas.push({ o: `${etiqueta}: ${n.transbordos} transbordos`, detalhe: r.transbordos.slice(0, 5) });
      if (n.cortadas) falhas.push({ o: `${etiqueta}: ${n.cortadas} caixas cortam o próprio conteúdo em silêncio`, detalhe: r.cortadas.slice(0, 6) });
      if (n.mudas) falhas.push({ o: `${etiqueta}: ${n.mudas} caixas rolam de lado sem o dizer`, detalhe: r.mudas.slice(0, 6) });
      if (n.pequenos) falhas.push({ o: `${etiqueta}: ${n.pequenos} sítios abaixo de ${PISO_PX}px`, detalhe: r.pequenos.slice(0, 8) });
      if (n.alvos) falhas.push({ o: `${etiqueta}: ${n.alvos} alvos abaixo de ${regua}px`, detalhe: alvosReais.slice(0, 8) });
      await ctx.close();
    }
  }

  await browser.close();

  console.log("\n" + resumo.join("\n"));
  if (falhas.length) {
    console.log("\n── FALHAS ──────────────────────────────────────────");
    for (const f of falhas) {
      console.log("· " + f.o);
      if (f.detalhe) console.log("    " + JSON.stringify(f.detalhe).slice(0, 600));
    }
    console.log(`\n${falhas.length} falha(s).`);
    process.exit(1);
  }
  console.log("\nTudo passa.");
}

correr().catch((e) => { console.error(e); process.exit(2); });
