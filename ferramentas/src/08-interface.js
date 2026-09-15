/* ═══════════════════════════════════════════════════════════════════════
   A INTERFACE — pesquisa, índice, contexto e teclado
   ---------------------------------------------------------------------
   ┌─────────────────────────────────────────────────────────────────────┐
   │ A SUPERFÍCIE DA PESQUISA É UMA REGIÃO, NÃO UM DIÁLOGO                │
   │                                                                     │
   │ Sem véu, sem `aria-modal`, sem foco preso, sem portal e sem bloquear │
   │ o scroll. O documento continua legível por baixo e continua          │
   │ clicável. A regra vem da `moldura.tsx` do Recibo Certo, e num dossiê │
   │ vale a dobrar: a pesquisa aqui é uma ferramenta de LEITURA. Prender  │
   │ a pessoa numa camada por cima do que ela está a ler inverte a        │
   │ relação entre o instrumento e o texto.                               │
   │                                                                     │
   │ A hierarquia é uma só e não se negoceia:                             │
   │   1. a consulta   2. a melhor resposta (se houver margem)            │
   │   3. os grupos, ordenados pelo seu melhor membro                     │
   │   4. porquê cada resultado está ali                                  │
   └─────────────────────────────────────────────────────────────────────┘
   ═══════════════════════════════════════════════════════════════════════ */

(() => {
"use strict";

const $ = (s, r) => (r || document).querySelector(s);
const $$ = (s, r) => [...(r || document).querySelectorAll(s)];
const el = (tag, attrs, html) => {
  const n = document.createElement(tag);
  if (attrs) for (const k in attrs) {
    if (k === "class") n.className = attrs[k];
    else if (attrs[k] !== null && attrs[k] !== undefined) n.setAttribute(k, attrs[k]);
  }
  if (html !== undefined) n.innerHTML = html;
  return n;
};

/* ─── Ícones — SVG, nunca emojis ───────────────────────────────────── */
const svg = (d, extra) =>
  `<svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="1.7" ` +
  `stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false">${d}${extra || ""}</svg>`;
const ICO = {
  lupa: svg('<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>'),
  mais: svg('<path d="M12 5v14M5 12h14"/>'),
  recorte: svg('<path d="M4 4h10l6 6v10a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1Z"/><path d="M14 4v6h6"/>'),
  x: svg('<path d="M18 6 6 18M6 6l12 12"/>'),
  seta: svg('<path d="m9 18 6-6-6-6"/>'),
  cima: svg('<path d="m18 15-6-6-6 6"/>'),
  baixo: svg('<path d="m6 9 6 6 6-6"/>'),
  lista: svg('<path d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01"/>'),
  topo: svg('<path d="M12 19V5M5 12l7-7 7 7"/>'),
  tema: svg('<circle cx="12" cy="12" r="4.2"/><path d="M12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M19.1 4.9l-1.4 1.4M6.3 17.7l-1.4 1.4"/>'),
  ligacao: svg('<path d="M10 13a5 5 0 0 0 7.5.5l3-3a5 5 0 0 0-7-7l-1.7 1.7"/><path d="M14 11a5 5 0 0 0-7.5-.5l-3 3a5 5 0 0 0 7 7l1.7-1.7"/>'),
  certo: svg('<path d="M20 6 9 17l-5-5"/>'),
  alerta: svg('<path d="M12 9v4M12 17h.01M10.3 3.9 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0Z"/>'),
  pausa: svg('<circle cx="12" cy="12" r="9"/><path d="M12 8v4l2.5 2.5"/>'),
  proibido: svg('<circle cx="12" cy="12" r="9"/><path d="m5.6 5.6 12.8 12.8"/>'),
  volta: svg('<path d="M9 14 4 9l5-5"/><path d="M4 9h10a6 6 0 0 1 0 12h-3"/>'),
  ajuda: svg('<circle cx="12" cy="12" r="9"/><path d="M9.4 9a2.6 2.6 0 0 1 5 .9c0 1.7-2.6 2.6-2.6 2.6M12 17h.01"/>'),
  tabela: svg('<rect x="3" y="4" width="18" height="16" rx="1.5"/><path d="M3 10h18M9 10v10"/>'),
};

/* ═══ 0 · Estado partilhado ════════════════════════════════════════ */

const DADOS = window.__EMPIRE_DADOS__ || null;
let IDX = null;
let origem = null;   // de onde a pessoa saltou, para poder voltar

/* ═══ 0b · O MARCO — o número da secção sai para a calha ═══════════
   O `.sec-no` diz «34 — Backlog · novo»: um número, um travessão e um
   rótulo, tudo numa linha de dez pixéis por cima do título. O número é o
   que se procura ao folhear 85 secções e é o que tem de estar grande na
   margem; o rótulo é o que se lê, e fica onde estava.

   Divide-se o PRIMEIRO NÓ DE TEXTO e mais nada — o `<span>` do «novo»
   que o autor pinta de brasa continua intacto, dentro do rótulo. */
function montarMarcos() {
  for (const sec of $$("main section[id]")) {
    const sn = $(".sec-no", sec);
    if (!sn || $(".x-marco", sec)) continue;
    const primeiro = [...sn.childNodes].find((n) => n.nodeType === 3 && n.nodeValue.trim());
    if (!primeiro) continue;
    const m = /^\s*(\d{1,2}|★)\s*[—–-]\s*(.*)$/.exec(primeiro.nodeValue);
    if (!m) continue;
    primeiro.nodeValue = m[2];
    const marco = el("span", { class: "x-marco" }, X.escapar(m[1]));
    sec.insertBefore(marco, sn);
  }
}

/* ═══ 1 · Âncoras nos títulos ══════════════════════════════════════ */

function montarAncoras() {
  for (const sec of $$("main section[id]")) {
    const h3 = $("h3", sec);
    if (h3 && !$(".x-anc", h3)) h3.appendChild(ancora(sec.id, "Ligação para esta secção"));
    for (const h of $$("h4[id], h5[id], h6[id]", sec)) {
      if (!$(".x-anc", h)) h.appendChild(ancora(h.id, "Ligação para este ponto"));
    }
  }
}
function ancora(id, rotulo) {
  const a = el("a", { class: "x-anc", href: "#" + id, "aria-label": rotulo, title: rotulo }, ICO.ligacao);
  a.addEventListener("click", (e) => {
    if (e.metaKey || e.ctrlKey || e.shiftKey) return;
    e.preventDefault();
    const url = location.href.split("#")[0] + "#" + id;
    history.replaceState(null, "", "#" + id);
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(url).then(() => anunciar("Ligação copiada"), () => {});
    }
  });
  return a;
}

/* ═══ 2 · Referências §NN ══════════════════════════════════════════
   Doze sítios do dossiê escrevem «§07» em texto corrido, e nenhum deles
   é uma ligação: quem quer ver a §07 tem de ir ao índice à mão. Isto
   percorre os nós de TEXTO (nunca `pre`, `code`, `a` ou atributos — um
   `replace` sobre HTML cru corrompia atributos e blocos de código) e
   transforma cada referência numa ligação com pré-visualização. */

function montarReferencias(porNumero, secoes) {
  const PROIBIDO = new Set(["A", "PRE", "CODE", "SCRIPT", "STYLE", "BUTTON", "TEXTAREA", "KBD"]);
  /**
   * O prefixo `x-` marca a MINHA interface, e a regra abaixo recusa
   * linkificar lá dentro — um §07 no meu painel de saúde é copy minha,
   * não uma referência do autor.
   *
   * Mas dois `x-` não são interface: são INVÓLUCROS à volta do texto do
   * autor. Quando as partes passaram a viver em `.x-parte-corpo`, a
   * regra passou a recusar o documento inteiro e as referências caíram
   * de 941 para 174 — sem erro, sem aviso, e com o portão a contar menos
   * e a dizer que estava tudo bem. Uma lista de excepções explícita é o
   * que impede o prefixo de significar duas coisas ao mesmo tempo.
   */
  const INVOLUCROS = X.INVOLUCROS;
  const alvos = [];
  // O `main` não chega: a introdução do documento e o aviso de retomada
  // vivem fora dele e são onde a §39 e a §73 aparecem pela primeira vez.
  const raiz = document.querySelector(".wrap") || document.body;
  const walker = document.createTreeWalker(raiz, NodeFilter.SHOW_TEXT, {
    acceptNode(n) {
      if (!/§\s?\d{1,2}/.test(n.nodeValue)) return NodeFilter.FILTER_REJECT;
      for (let p = n.parentElement; p && p !== raiz; p = p.parentElement) {
        if (PROIBIDO.has(p.tagName)) return NodeFilter.FILTER_REJECT;
  /* ┌───────────────────────────────────────────────────────┐
         │ UM `<button>` DENTRO DE UM `<text>` DE SVG NÃO EXISTE  │
         │                                                       │
         │ Um elemento HTML inserido dentro de SVG fora de um     │
         │ `<foreignObject>` fica na árvore e NÃO é pintado. Os   │
         │ dois varrimentos entravam nos desenhos, e o que        │
         │ marcavam desaparecia do ecrã:                          │
         │                                                       │
         │   §05  «A Podridão nasce na borda do mapa ▸»           │
         │        chegava ao ecrã como «nasce na borda do mapa ▸» │
         │   §41  «Autoloads: EventBus · GameClock · …»           │
         │        perdia «EventBus»                              │
         │                                                       │
         │ Sem erro, sem aviso, e numa figura que uma passagem    │
         │ anterior já tinha corrigido por outra razão. Um SVG    │
         │ não recebe camada nenhuma: o que lá está é desenho.    │
         └───────────────────────────────────────────────────────┘ */
      if (p.namespaceURI === "http://www.w3.org/2000/svg") return NodeFilter.FILTER_REJECT;

        if (p.tagName === "NAV" || (p.classList && [...p.classList].some((c) => c.startsWith("x-") && !INVOLUCROS.has(c))))
          return NodeFilter.FILTER_REJECT;
      }
      return NodeFilter.FILTER_ACCEPT;
    },
  });
  let n;
  while ((n = walker.nextNode())) alvos.push(n);

  for (const nodo of alvos) {
    const frag = document.createDocumentFragment();
    const txt = nodo.nodeValue;
    const re = /§\s?(\d{1,2})/g;
    let ultimo = 0, m;
    while ((m = re.exec(txt))) {
      const num = m[1].padStart(2, "0");
      const destino = porNumero.get(num);
      if (!destino) continue;
      if (m.index > ultimo) frag.appendChild(document.createTextNode(txt.slice(ultimo, m.index)));
      const a = el("a", { class: "x-ref", href: "#" + destino, "data-sec": destino }, X.escapar(m[0]));
      frag.appendChild(a);
      ultimo = m.index + m[0].length;
    }
    if (!ultimo) continue;
    if (ultimo < txt.length) frag.appendChild(document.createTextNode(txt.slice(ultimo)));
    nodo.parentNode.replaceChild(frag, nodo);
  }

  /* A pré-visualização: uma referência responde «é aquela?» sem obrigar
     a sair de onde se está a ler. */
  const peek = el("div", { class: "x-peek", hidden: "", role: "tooltip" });
  document.body.appendChild(peek);
  let timer = null;
  const mostrar = (a) => {
    const s = secoes.get(a.dataset.sec);
    if (!s) return;
    peek.innerHTML =
      `<span class="x-peek-n">${X.escapar((s.parte ? s.parte + " · " : "") + (s.numero ? "§" + s.numero : ""))} ${X.escapar(s.rotulo)}</span>` +
      `<b>${X.escapar(s.titulo)}</b>${X.escapar((s.lede || "").slice(0, 190))}${(s.lede || "").length > 190 ? "…" : ""}`;
    peek.hidden = false;
    const r = a.getBoundingClientRect();
    const w = Math.min(360, window.innerWidth * 0.88);
    peek.style.width = w + "px";
    const esq = Math.max(10, Math.min(r.left, window.innerWidth - w - 10));
    peek.style.left = esq + window.scrollX + "px";
    const ph = peek.offsetHeight;
    const acima = r.top > ph + 14;
    peek.style.top = (acima ? r.top - ph - 8 : r.bottom + 8) + window.scrollY + "px";
  };
  const esconder = () => { peek.hidden = true; };
  for (const a of $$("a.x-ref[data-sec]")) {
    a.addEventListener("mouseenter", () => { clearTimeout(timer); timer = setTimeout(() => mostrar(a), 180); });
    a.addEventListener("mouseleave", () => { clearTimeout(timer); esconder(); });
    a.addEventListener("focus", () => mostrar(a));
    a.addEventListener("blur", esconder);
  }
  window.addEventListener("scroll", esconder, { passive: true });
}

/* ═══ 3 · Aterragem — onde é que eu caí? ═══════════════════════════ */

/* Enquanto um salto suave está a decorrer, o scroll atravessa todas as
   secções pelo caminho. Quem ouvir esse scroll conclui que a pessoa
   esteve lá — e não esteve: está a passar. */
let saltoAte = 0;
function aSaltar() { return Date.now() < saltoAte; }

function aterrar(id, guardarOrigem) {
  const alvo = document.getElementById(id);
  if (!alvo) return false;
  /* A parte que o contém pode estar fechada. Saltar sem abrir entrega o
     topo da página em silêncio — o mesmo defeito que uma âncora morta,
     e igualmente invisível. É o ÚNICO sítio onde isto é preciso porque
     toda a navegação passa por aqui. */
  const abriu = window.XPT && window.XPT.abrirPara(alvo);
  saltoAte = Date.now() + (prefereParado() ? 160 : 950);
  const ok = aterrarAgora(id, alvo, guardarOrigem);
  if (abriu) assentar(alvo);
  return ok;
}

/**
 * ┌─────────────────────────────────────────────────────────────────────┐
 * │ RECONFERIR EM VEZ DE ADIVINHAR O INSTANTE                            │
 * │                                                                     │
 * │ Abrir uma parte faz o cabeçalho dela passar de compacto (192px) a    │
 * │ editorial (435px) — 243px que aparecem ACIMA do alvo depois de o     │
 * │ `scrollIntoView` já ter medido. O salto aterrava sempre 243px ao     │
 * │ lado, e a diferença era exactamente essa.                            │
 * │                                                                     │
 * │ Tentei forçar o layout antes de rolar e não chegou, porque o que     │
 * │ cresce não cresce num instante conhecido. Adivinhar um `setTimeout`  │
 * │ dá um número que funciona nesta máquina e falha noutra.              │
 * │                                                                     │
 * │ Isto não adivinha: volta a medir durante meio segundo e só corrige   │
 * │ quando o alvo saiu do sítio. Quando nada mexe, não faz nada.         │
 * └─────────────────────────────────────────────────────────────────────┘
 */
function assentar(alvo) {
  const destino = () => {
    const cs = parseFloat(getComputedStyle(alvo).scrollMarginTop) || 0;
    return Math.round(alvo.getBoundingClientRect().top - cs);
  };
  let restantes = 6;
  const tentar = () => {
    if (--restantes < 0) return;
    const fora = destino();
    if (Math.abs(fora) > 3) {
      window.scrollBy({ top: fora, behavior: "auto" });
      saltoAte = Date.now() + 260;
    }
    setTimeout(tentar, 80);
  };
  setTimeout(tentar, 60);
}

function aterrarAgora(id, alvo, guardarOrigem) {
  if (guardarOrigem) origem = { y: window.scrollY, titulo: tituloVisivel() };
  alvo.scrollIntoView({ behavior: prefereParado() ? "auto" : "smooth", block: "start" });
  history.replaceState(null, "", "#" + id);
  const marca = alvo.matches("section") ? $("h3", alvo) || alvo : alvo;
  marca.classList.remove("x-aterrou");
  void marca.offsetWidth;
  marca.classList.add("x-aterrou");
  setTimeout(() => marca.classList.remove("x-aterrou"), 2000);
  if (!alvo.hasAttribute("tabindex")) alvo.setAttribute("tabindex", "-1");
  alvo.focus({ preventScroll: true });
  actualizarVoltar();
  return true;
}
const prefereParado = () => matchMedia("(prefers-reduced-motion: reduce)").matches;

let btVoltar = null;
function montarVoltar() {
  btVoltar = el("button", { class: "x-voltar", hidden: "", type: "button" }, ICO.volta + "<span>Voltar</span>");
  btVoltar.addEventListener("click", () => {
    if (!origem) return;
    window.scrollTo({ top: origem.y, behavior: prefereParado() ? "auto" : "smooth" });
    origem = null;
    actualizarVoltar();
  });
  document.body.appendChild(btVoltar);
}
function actualizarVoltar() {
  if (!btVoltar) return;
  if (!origem) { btVoltar.hidden = true; return; }
  btVoltar.hidden = false;
  const t = origem.titulo ? " a " + origem.titulo : "";
  $("span", btVoltar).textContent = "Voltar" + (t.length < 30 ? t : "");
}
function tituloVisivel() {
  let melhor = null;
  for (const s of $$("main section[id]")) {
    const r = s.getBoundingClientRect();
    if (r.top <= 120) melhor = s;
  }
  if (!melhor) return "";
  const n = XI.texto($(".sec-no", melhor)).split("—")[0].trim();
  return n ? "§" + n : "";
}

/* ═══ 4 · Anúncio para leitores de ecrã ════════════════════════════ */
let vivo = null;
function anunciar(msg) {
  if (!vivo) {
    vivo = el("div", { "aria-live": "polite", "aria-atomic": "true", class: "x-salto", style: "position:absolute;left:-9999px" });
    document.body.appendChild(vivo);
  }
  vivo.textContent = "";
  setTimeout(() => { vivo.textContent = msg; }, 30);
}

/* ═══ 5 · A PESQUISA ═══════════════════════════════════════════════ */

const EXEMPLOS = [
  "a podridão à noite",
  "quanto custa o jogo",
  "o que bloqueia a fase 0",
  "determinismo e seed",
  "tempo até matar",
];

let campo, caixaRes, resultados = [], activo = -1, tipoFiltro = "tudo", plano = null;

/**
 * ┌─────────────────────────────────────────────────────────────────────┐
 * │ A PESQUISA NÃO PODE VIVER DENTRO DE `nav.toc`                        │
 * │                                                                     │
 * │ Parecia o sítio óbvio — é a coluna do índice. Mas o dossiê tem       │
 * │ `nav.toc a{display:flex;padding:5px 9px}` e `nav.toc ol{display:flex}│
 * │ para desenhar o índice, e essas regras apanhavam TODOS os resultados │
 * │ da pesquisa: cada resultado virava uma linha de flex, o título       │
 * │ espremia-se a 93px e o excerto ia para o lado dele. A 1340px mal se  │
 * │ notava; a 360 era ilegível.                                         │
 * │                                                                     │
 * │ Ganhar a guerra de especificidade resolvia o sintoma e deixava a     │
 * │ armadilha montada para a próxima regra que o autor escrevesse.       │
 * │ A pesquisa passa a ser IRMÃ do índice, dentro de uma coluna própria  │
 * │ — que é também o que permite fixar o campo no topo e deixar só o     │
 * │ índice rolar.                                                        │
 * └─────────────────────────────────────────────────────────────────────┘
 */
function montarBusca(nav) {
  const lado = el("div", { class: "x-lado" });
  nav.parentElement.insertBefore(lado, nav);
  lado.appendChild(nav);
  const bloco = el("div", { class: "x-busca", id: "x-busca" });
  const idCampo = "x-q";
  bloco.innerHTML =
    `<div class="x-campo">${ICO.lupa}` +
    `<input id="${idCampo}" type="search" role="combobox" aria-expanded="false" aria-controls="x-res"` +
    ` aria-autocomplete="list" aria-label="Pesquisar no dossiê" autocomplete="off" spellcheck="false"` +
    ` placeholder="Pesquisar…">` +
    `<button type="button" class="x-limpar" aria-label="Limpar a pesquisa">${ICO.x}</button>` +
    `<span class="x-kbd" aria-hidden="true">${atalhoDoSistema()}</span></div>` +
    `<div class="x-res" id="x-res" role="listbox" aria-label="Resultados da pesquisa" hidden></div>`;
  lado.insertBefore(bloco, nav);

  campo = $("#" + idCampo, bloco);
  caixaRes = $("#x-res", bloco);
  const cx = $(".x-campo", bloco);

  // Um marcador comprido trunca-se numa coluna de 250px («Pesquisar — quant»)
  // e uma frase cortada a meio parece um erro. Os exemplos passam a ser
  // fichas no estado vazio, onde há largura para os ler inteiros.
  campo.placeholder = "Pesquisar no dossiê";

  $(".x-limpar", bloco).addEventListener("click", () => {
    campo.value = "";
    cx.classList.remove("tem");
    desenhar("");
    campo.focus();
  });

  let debounce = null;
  campo.addEventListener("input", () => {
    cx.classList.toggle("tem", campo.value.length > 0);
    clearTimeout(debounce);
    debounce = setTimeout(() => desenhar(campo.value), 90);
  });
  campo.addEventListener("focus", () => { if (!campo.value) desenhar(""); });
  campo.addEventListener("keydown", teclaNoCampo);

  // Um clique fora fecha — mas não rouba o foco de volta: quem clicou
  // fora já disse para onde queria ir.
  document.addEventListener("click", (e) => {
    if (!bloco.contains(e.target) && !caixaRes.hidden) fechar(false);
  });
}

function atalhoDoSistema() {
  const mac = /Mac|iPhone|iPad/.test(navigator.platform || navigator.userAgent);
  return mac ? "⌘K" : "Ctrl K";
}

function teclaNoCampo(e) {
  if (e.key === "Escape") {
    e.preventDefault();
    if (campo.value) { campo.value = ""; $(".x-campo").classList.remove("tem"); desenhar(""); }
    else fechar(true);
    return;
  }
  if (e.key === "ArrowDown" || e.key === "ArrowUp") {
    const itens = $$(".x-item", caixaRes);
    if (!itens.length) return;
    e.preventDefault();
    activo = e.key === "ArrowDown"
      ? (activo + 1) % itens.length
      : (activo <= 0 ? itens.length - 1 : activo - 1);
    marcarActivo(itens);
    return;
  }
  if (e.key === "Enter") {
    const itens = $$(".x-item", caixaRes);
    const alvo = itens[activo] || itens[0];
    if (alvo) { e.preventDefault(); abrirResultado(alvo); }
    return;
  }
  if (e.key === "Home" && caixaRes.hidden === false && activo >= 0) {
    const itens = $$(".x-item", caixaRes);
    if (itens.length) { e.preventDefault(); activo = 0; marcarActivo(itens); }
  }
}

function marcarActivo(itens) {
  itens.forEach((it, i) => it.setAttribute("aria-selected", i === activo ? "true" : "false"));
  const at = itens[activo];
  if (!at) return;
  campo.setAttribute("aria-activedescendant", at.id);
  const r = at.getBoundingClientRect(), c = caixaRes.getBoundingClientRect();
  if (r.top < c.top + 34) caixaRes.scrollTop -= c.top + 34 - r.top;
  else if (r.bottom > c.bottom) caixaRes.scrollTop += r.bottom - c.bottom;
}

function abrirResultado(a) {
  const href = a.getAttribute("href") || "";
  if (campo.value.trim()) X.guardarRecente(campo.value);
  if (href.startsWith("#")) {
    const id = href.slice(1);
    fechar(false);
    aterrar(id, true);
    if (window.__X_DOCK_FECHAR__) window.__X_DOCK_FECHAR__();
  }
}

function fechar(devolverFoco) {
  caixaRes.hidden = true;
  campo.setAttribute("aria-expanded", "false");
  campo.removeAttribute("aria-activedescendant");
  activo = -1;
  if (devolverFoco) campo.focus();
}

/* O desenho da região. Toda a hierarquia da moldura vive aqui. */
function desenhar(consulta) {
  const q = String(consulta || "").trim();
  activo = -1;
  campo.removeAttribute("aria-activedescendant");

  if (q.length < X.MIN_CARACTERES) {
    const recentes = X.lerRecentes();
    if (!recentes.length && !q.length) { fechar(false); return; }
    caixaRes.innerHTML =
      (recentes.length
        ? `<div class="x-recentes"><span class="x-rec-lbl">Recentes</span>` +
          recentes.map((r) => `<button type="button" class="x-chip-btn" data-termo="${X.escapar(r.termo)}">${X.escapar(r.termo)}</button>`).join("") +
          `<button type="button" class="x-chip-btn x-apagar">Apagar</button></div>`
        : "") +
      `<div class="x-vazio"><p>As secções e os sub-títulos, as caixas de decisão, os tickets, ` +
      `as perguntas, as ADRs, as tabelas de dados e as 48 mecânicas.</p>` +
      `<div class="x-exemplos">` +
      EXEMPLOS.map((e) => `<button type="button" class="x-chip-btn" data-termo="${X.escapar(e)}">${X.escapar(e)}</button>`).join("") +
      `</div></div>`;
    abrirRegiao();
    ligarRecentes();
    return;
  }

  /* O PLANO vem antes da lista — e é ele que decide se há lista.
     Ver `04-plano.js`: a interface desenha o plano, não o inventa. */
  plano = window.XR && tipoFiltro === "tudo" ? window.XR.compilar(q, IDX.docs, DADOS) : null;
  if (plano && plano.estado === "clarificar") { desenharPergunta(q, plano); return; }

  resultados = X.pesquisar(q, IDX.docs, { limite: X.TETO, tipo: tipoFiltro });
  const todos = tipoFiltro === "tudo" ? resultados : X.pesquisar(q, IDX.docs, { limite: X.TETO });
  const contagens = new Map();
  for (const r of (tipoFiltro === "tudo" ? resultados : todos)) {
    contagens.set(r.doc.tipo, (contagens.get(r.doc.tipo) || 0) + 1);
  }

  if (!resultados.length) {
    caixaRes.innerHTML =
      `<div class="x-vazio"><p><b>Nada no dossiê respondeu com confiança suficiente</b> a «${X.escapar(q)}».</p>` +
      `<ul><li>Tenta uma palavra só, ou o número da secção (por exemplo <code>§07</code>)</li>` +
      `<li>Uma gralha é perdoada a partir de cinco letras — abaixo disso a palavra tem de estar certa</li>` +
      `<li>O documento está em português de Portugal</li></ul></div>`;
    abrirRegiao();
    return;
  }

  const coroa = X.melhorResposta(resultados);
  const grupos = X.agrupar(coroa ? resultados.slice(1) : resultados);

  let n = 0;
  const item = (r) => {
    const id = "x-r" + n++;
    const d = r.doc;
    const porque =
      r.campo === "marca" ? "é o identificador"
      : r.campo === "titulo" ? "o título responde"
      : r.campo === "aliases" ? "nomeado ali"
      : r.campo === "descricao" ? "na introdução"
      : "no corpo do texto";
    const trecho =
      r.campo === "corpo" || r.campo === "descricao"
        ? X.realcar(X.excerto(r.campo === "corpo" ? d.corpo : d.descricao, q, 130), q)
        : X.realcar((d.descricao || "").slice(0, 120), q);
    return (
      `<a class="x-item" id="${id}" role="option" aria-selected="false" href="${d.href}" data-tipo="${d.tipo}">` +
      `<span class="x-item-t"><span class="x-id">${X.escapar(d.marca || "")}</span>` +
      `<span>${X.realcar(d.titulo, q)}</span></span>` +
      `<span class="x-item-s"><span>${X.escapar(d.contexto || "")}</span>` +
      (trecho ? `<span class="x-porque">${trecho}</span>` : "") +
      `<span class="x-porque">· ${porque}</span></span></a>`
    );
  };

  const filtros =
    `<div class="x-filtros" role="group" aria-label="Filtrar por tipo">` +
    `<button type="button" class="x-filtro" data-t="tudo" aria-pressed="${tipoFiltro === "tudo"}">Tudo <span class="x-n">${todos.length}</span></button>` +
    X.ORDEM_TIPOS.filter((t) => contagens.get(t))
      .map((t) => `<button type="button" class="x-filtro" data-t="${t}" aria-pressed="${tipoFiltro === t}">${X.escapar(XI.ROTULO_UM[t])} <span class="x-n">${contagens.get(t)}</span></button>`)
      .join("") +
    `</div>`;

  caixaRes.innerHTML =
    blocoDoPlano(plano) +
    `<div class="x-res-cab"><b>${resultados.length}</b> resultado${resultados.length === 1 ? "" : "s"}` +
    `<span>· setas para navegar, Enter para abrir</span></div>` +
    filtros +
    (coroa
      ? `<div class="x-coroa"><span class="x-coroa-lbl">Melhor resposta</span>${item(coroa)}</div>`
      : "") +
    grupos
      .map(([tipo, lista]) =>
        `<div class="x-grupo">${X.escapar(XI.ROTULO[tipo] || tipo)}</div><ol>` +
        lista.map((r) => `<li>${item(r)}</li>`).join("") + `</ol>`)
      .join("");

  abrirRegiao();
  ligarItens();
  ligarFiltros();
  ligarPorque();
}

/* ─── O plano, desenhado ─────────────────────────────────────────────
   Só há bloco quando há RESPOSTA. Um plano «pronto» sem resposta é um
   destino, e para destinos já há a coroa — repetir seria dizer duas
   vezes a mesma coisa com palavras diferentes. */
function blocoDoPlano(p) {
  if (!p || !p.resposta) return "";
  const r = p.resposta;
  const ent = p.reconhecimento.entidades;
  return (
    `<div class="x-plano" data-conf="${p.confianca}">` +
    (ent.length
      ? `<p class="x-plano-lido">Li <span class="x-lido">${ent.map((e) => X.escapar(e.texto)).join("</span> <span class=\"x-lido\">")}</span></p>`
      : "") +
    `<p class="x-plano-r">${X.escapar(r.texto)}</p>` +
    (r.detalhe ? `<p class="x-plano-d">${X.escapar(r.detalhe)}</p>` : "") +
    `<p class="x-plano-p"><span class="x-prov">${X.escapar(r.proveniencia)}</span>` +
    `<button type="button" class="x-porque-b" aria-expanded="false">porquê isto?</button></p>` +
    `<div class="x-porque-c" hidden><ul>` +
    window.XR.porque(p).map((l) => `<li>${X.escapar(l)}</li>`).join("") +
    `</ul></div></div>`
  );
}

/* Uma pergunta de cada vez — nunca duas, nunca uma lista disfarçada de
   pergunta. Cada opção traz a contagem real, para a escolha ser
   informada em vez de adivinhada. */
function desenharPergunta(q, p) {
  caixaRes.innerHTML =
    `<div class="x-plano x-plano-q" data-conf="${p.confianca}">` +
    `<p class="x-plano-lido">Li <span class="x-lido">${X.escapar(p.reconhecimento.entidades[0].texto)}</span></p>` +
    `<p class="x-plano-r">${X.escapar(p.pergunta.texto)}</p>` +
    `<div class="x-opcoes">` +
    p.pergunta.opcoes
      .map((o) => `<button type="button" class="x-opcao" data-t="${X.escapar(o.id)}" data-termo="${X.escapar(o.termo)}">` +
        `${X.escapar(o.rotulo)} <span class="x-n">${o.n}</span></button>`)
      .join("") +
    `</div>` +
    `<p class="x-plano-p"><span class="x-prov">contagem sobre o índice</span>` +
    `<button type="button" class="x-porque-b" aria-expanded="false">porquê isto?</button></p>` +
    `<div class="x-porque-c" hidden><ul>` +
    window.XR.porque(p).map((l) => `<li>${X.escapar(l)}</li>`).join("") +
    `</ul></div></div>`;
  abrirRegiao();
  ligarPorque();
  for (const b of $$(".x-opcao", caixaRes)) {
    b.addEventListener("click", () => {
      tipoFiltro = b.dataset.t;
      desenhar(campo.value);
      campo.focus();
    });
  }
}

function ligarPorque() {
  for (const b of $$(".x-porque-b", caixaRes)) {
    b.addEventListener("click", () => {
      const c = b.closest(".x-plano").querySelector(".x-porque-c");
      const aberto = b.getAttribute("aria-expanded") === "true";
      b.setAttribute("aria-expanded", String(!aberto));
      c.hidden = aberto;
    });
  }
}

function abrirRegiao() {
  caixaRes.hidden = false;
  campo.setAttribute("aria-expanded", "true");
}
function ligarItens() {
  for (const a of $$(".x-item", caixaRes)) {
    a.addEventListener("click", (e) => {
      if (e.metaKey || e.ctrlKey || e.shiftKey) return;
      e.preventDefault();
      abrirResultado(a);
    });
    a.addEventListener("mousemove", () => {
      const itens = $$(".x-item", caixaRes);
      const i = itens.indexOf(a);
      if (i !== activo) { activo = i; marcarActivo(itens); }
    });
  }
}
function ligarFiltros() {
  for (const b of $$(".x-filtro", caixaRes)) {
    b.addEventListener("click", () => {
      tipoFiltro = b.dataset.t;
      desenhar(campo.value);
      campo.focus();
    });
  }
}
function ligarRecentes() {
  for (const b of $$(".x-chip-btn[data-termo]", caixaRes)) {
    b.addEventListener("click", () => {
      campo.value = b.dataset.termo;
      $(".x-campo").classList.add("tem");
      desenhar(campo.value);
      campo.focus();
    });
  }
  const ap = $(".x-apagar", caixaRes);
  if (ap) ap.addEventListener("click", () => { X.limparRecentes(); desenhar(campo.value); campo.focus(); });
}

function focarBusca() {
  if (window.__X_DOCK_ABRIR__ && matchMedia("(max-width:960px)").matches) window.__X_DOCK_ABRIR__();
  campo.focus();
  campo.select();
  if (!caixaRes.hidden || campo.value.length >= X.MIN_CARACTERES) desenhar(campo.value);
  else desenhar("");
}

/* ═══ 6 · ÍNDICE — grupos que dobram, filtro e progresso ═══════════ */

const CHAVE_GRUPOS = "empire.indice.abertos.v1";

function montarIndice(nav) {
  const filhos = [...nav.children];
  const grupos = [];
  let actual = null;
  for (const c of filhos) {
    if (c.classList.contains("grp")) {
      actual = { rotulo: XI.texto(c), div: c, lista: null };
      grupos.push(actual);
    } else if (c.tagName === "OL" && actual && !actual.lista) {
      actual.lista = c;
    }
  }

  let abertos;
  try { abertos = JSON.parse(localStorage.getItem(CHAVE_GRUPOS) || "null"); } catch { abertos = null; }

  grupos.forEach((g, i) => {
    if (!g.lista) return;
    const n = g.lista.children.length;
    const idLista = "x-grp-" + i;
    g.lista.id = idLista;
    const bt = el("button", {
      type: "button", class: "x-grp-btn", "aria-expanded": "true", "aria-controls": idLista,
    }, `<span class="x-caret" aria-hidden="true">${ICO.baixo}</span><span>${X.escapar(g.rotulo)}</span><span class="x-grp-n">${n}</span>`);
    g.div.replaceWith(bt);
    g.btn = bt;

    /* ┌─────────────────────────────────────────────────────────────────┐
       │ UM SÓ MECANISMO DE DOBRAR                                       │
       │                                                                 │
       │ Com o acordeão das partes passaram a existir dois sítios que    │
       │ dobram a mesma coisa: o grupo do índice e a parte no documento. │
       │ Dois modelos mentais para uma ideia é como não ter nenhum — a   │
       │ pessoa fecha um lado, vê o outro aberto, e deixa de confiar em  │
       │ qualquer um deles.                                              │
       │                                                                 │
       │ Aqui são a mesma alavanca: o grupo `i` do índice é a parte `i`  │
       │ do documento. Fechar num sítio fecha no outro.                  │
       └─────────────────────────────────────────────────────────────────┘ */
    /* A correspondência é por IDENTIDADE, não por posição.
       O índice tem 14 grupos e o documento 13 partes — «ABERTURA» é um
       grupo do índice e não uma parte, porque a §00 vive antes da
       primeira `.part`. Casar pelo número da lista desalinhava tudo a
       partir daí: o grupo «I · FUNDAÇÃO» passava a comandar a Parte II,
       e cada clique abria a parte errada. Uma correspondência posicional
       entre duas listas que ninguém garante ter o mesmo tamanho é um
       erro à espera da primeira secção nova. */
    const romano = (g.rotulo.match(/^\s*([IVXLCDM]+)\s*·/i) || [])[1];
    const parte = () => {
      if (!window.XPT || !romano) return null;
      return window.XPT.todas().find((d) => d.dataset.parte === romano.toUpperCase()) || null;
    };
    const aplicar = (aberto, propagar) => {
      bt.setAttribute("aria-expanded", String(aberto));
      g.lista.hidden = !aberto;
      const d = parte();
      if (propagar && d && d.open !== aberto) d.open = aberto;
    };
    g.aplicar = aplicar;
    g.parte = parte;

    bt.addEventListener("click", () => {
      aplicar(bt.getAttribute("aria-expanded") !== "true", true);
      guardarAbertos(grupos);
    });

    const d0 = parte();
    if (d0) aplicar(d0.open, false);          // o documento manda no arranque
    else if (abertos && Array.isArray(abertos) && !abertos.includes(i)) aplicar(false, false);
  });

  /* E o caminho inverso: abrir uma parte no documento (ou o `Ctrl+F` do
     browser a abri-la por nós) acerta o índice. */
  window.addEventListener("x-parte", () => {
    if (!window.XPT) return;
    for (const g of grupos) {
      if (!g.aplicar || !g.parte) continue;
      const d = g.parte();                 // por identidade, como acima
      if (d) g.aplicar(d.open, false);
    }
  });

  /* O filtro do índice: 86 ligações são muitas para o olho, poucas para
     a pesquisa. Isto é o meio-termo — reduzir a lista sem sair dela. */
  const filtro = el("div", { class: "x-campo x-toc-filtro" },
    ICO.lista +
    `<input type="search" aria-label="Filtrar o índice" placeholder="Filtrar o índice" autocomplete="off" spellcheck="false">`);
  const primeiro = $(".x-grp-btn", nav);
  if (primeiro) nav.insertBefore(filtro, primeiro);
  else nav.insertBefore(filtro, nav.firstChild);
  const vazio = el("div", { class: "x-toc-vazio", hidden: "" }, "Nada no índice com esse nome.");
  nav.insertBefore(vazio, filtro.nextSibling);

  $("input", filtro).addEventListener("input", (e) => {
    const q = X.normalizar(e.target.value);
    let visiveis = 0;
    for (const g of grupos) {
      if (!g.lista) continue;
      let n = 0;
      for (const li of g.lista.children) {
        const a = $("a", li);
        const bate = !q || X.pontuarCampo(q, XI.texto(a)) > 0;
        li.hidden = !bate;
        if (bate) n++;
      }
      visiveis += n;
      if (g.btn) {
        g.btn.hidden = q ? n === 0 : false;
        if (q && n > 0) { g.btn.setAttribute("aria-expanded", "true"); g.lista.hidden = false; }
        else if (!q) { const ab = g.btn.getAttribute("aria-expanded") === "true"; g.lista.hidden = !ab; }
      }
      if (q && g.lista) g.lista.hidden = n === 0;
    }
    vazio.hidden = visiveis > 0;
  });

  return grupos;
}

function guardarAbertos(grupos) {
  const abertos = grupos.map((g, i) => (g.btn && g.btn.getAttribute("aria-expanded") === "true" ? i : -1)).filter((i) => i >= 0);
  try { localStorage.setItem(CHAVE_GRUPOS, JSON.stringify(abertos)); } catch { /* quota */ }
}

/** O grupo da secção corrente abre-se sozinho — um índice dobrado que
    esconde onde estamos é pior do que um índice aberto. */
function abrirGrupoDe(grupos, a) {
  for (const g of grupos) {
    if (!g.lista || !g.lista.contains(a)) continue;
    if (g.btn && g.btn.getAttribute("aria-expanded") === "false") {
      g.btn.setAttribute("aria-expanded", "true");
      g.lista.hidden = false;
    }
  }
}

/* ═══ 6b · O ÍNDICE ABRE-SE NA SECÇÃO ONDE SE ESTÁ ═════════════════
   ┌─────────────────────────────────────────────────────────────────┐
   │ OITENTA E SEIS LINHAS IGUAIS NÃO SÃO UM ÍNDICE                   │
   │                                                                 │
   │ O índice dizia o nome de 86 secções e nada sobre o que está      │
   │ dentro delas — e há 174 sub-títulos lá dentro. Numa secção de    │
   │ três mil palavras (a §22, a §29, a §69) chegar ao ponto certo    │
   │ era rolar à procura.                                            │
   │                                                                 │
   │ A secção onde se está abre-se e mostra os seus sub-títulos, com  │
   │ o que se está a ler marcado. Só a corrente: abrir as 86 seria    │
   │ trocar uma lista de 86 por uma de 260.                          │
   └─────────────────────────────────────────────────────────────────┘ */

function montarSubIndice(nav, secoes) {
  const porSeccao = new Map();
  for (const [id, s] of secoes) {
    const subs = [...s.el.querySelectorAll("h4[id]")]
      .map((h) => ({ id: h.id, texto: XI.texto(h).replace(/\s*#$/, ""), el: h }))
      .filter((x) => x.texto.length > 2);
    if (subs.length >= 2) porSeccao.set(id, subs);
  }
  if (!porSeccao.size) return () => {};

  let abertoEm = null;
  let lista = null;

  const fechar = () => {
    if (lista) lista.remove();
    lista = null; abertoEm = null;
  };

  const abrir = (a, id) => {
    if (abertoEm === id) return;
    fechar();
    const subs = porSeccao.get(id);
    if (!subs) return;
    abertoEm = id;
    lista = el("ol", { class: "x-sub", "aria-label": "Dentro desta secção" },
      subs.map((s) => `<li><a href="#${s.id}" data-sub="${s.id}">${X.escapar(s.texto)}</a></li>`).join(""));
    a.parentElement.appendChild(lista);
    for (const link of $$("a[data-sub]", lista)) {
      link.addEventListener("click", (e) => {
        if (e.metaKey || e.ctrlKey || e.shiftKey) return;
        e.preventDefault();
        aterrar(link.dataset.sub, true);
      });
    }
  };

  /** Qual dos sub-títulos está a ser lido agora. */
  const marcarSub = () => {
    if (!lista) return;
    const subs = porSeccao.get(abertoEm) || [];
    let atual = null;
    for (const s of subs) if (s.el.getBoundingClientRect().top <= 140) atual = s.id;
    for (const link of $$("a[data-sub]", lista)) {
      link.classList.toggle("cur", link.dataset.sub === atual);
    }
  };

  return (aCorrente) => {
    const href = aCorrente && aCorrente.getAttribute("href");
    const id = href && href.slice(1);
    if (!id || !porSeccao.has(id)) { fechar(); return; }
    abrir(aCorrente, id);
    marcarSub();
  };
}

/* ═══ 7 · BARRA DE CONTEXTO + anterior/seguinte ════════════════════ */

function montarContexto(secoes) {
  const barra = el("div", { class: "x-ctx", role: "status", "aria-live": "off" },
    `<span class="x-ctx-parte"></span><span class="x-ctx-sep">›</span><b></b>` +
    `<span class="x-ctx-nav"><a href="#" class="x-ant" aria-label="Secção anterior">${ICO.cima}</a>` +
    `<a href="#" class="x-seg" aria-label="Secção seguinte">${ICO.baixo}</a></span>`);
  document.body.appendChild(barra);

  const lista = [...secoes.values()];
  const parteEl = $(".x-ctx-parte", barra), tituloEl = $("b", barra);
  const ant = $(".x-ant", barra), seg = $(".x-seg", barra);
  for (const a of [ant, seg]) {
    a.addEventListener("click", (e) => {
      e.preventDefault();
      const h = a.getAttribute("href");
      if (h && h.length > 1) aterrar(h.slice(1), false);
    });
  }

  let actualId = null;
  const actualizar = () => {
    let i = -1;
    for (let k = 0; k < lista.length; k++) {
      if (lista[k].el.getBoundingClientRect().top <= 96) i = k;
    }
    barra.classList.toggle("on", window.scrollY > 340);
    if (i < 0 || lista[i].id === actualId) return;
    actualId = lista[i].id;
    const s = lista[i];
    parteEl.textContent = s.parte || "Abertura";
    // `§★` não quer dizer nada: o rastreador e os painéis não têm número.
    tituloEl.textContent = (s.numero ? (/^\d+$/.test(s.numero) ? "§" + s.numero : s.numero) + " " : "") + s.titulo;
    const a = lista[i - 1], b = lista[i + 1];
    ant.setAttribute("href", a ? "#" + a.id : "#");
    ant.setAttribute("aria-disabled", a ? "false" : "true");
    const marca = (x) => (/^\d+$/.test(x.numero) ? "§" + x.numero : x.numero || "") + " " + x.rotulo;
    ant.title = a ? marca(a) : "";
    seg.setAttribute("href", b ? "#" + b.id : "#");
    seg.setAttribute("aria-disabled", b ? "false" : "true");
    seg.title = b ? marca(b) : "";
  };
  window.addEventListener("scroll", actualizar, { passive: true });
  actualizar();

  /**
   * ┌─────────────────────────────────────────────────────────────────┐
   * │ O «ONDE ESTOU» DO TECLADO NÃO PODE VIR DO SCROLL                 │
   * │                                                                 │
   * │ Carregar `J` duas vezes seguidas saltava uma secção e ficava na  │
   * │ mesma: a segunda tecla lia `actualId`, e `actualId` só muda      │
   * │ quando o scroll SUAVE chega ao destino — o que demora mais do    │
   * │ que o intervalo entre duas teclas. Quem navega por teclado       │
   * │ carrega depressa, e o defeito só aparece nessa velocidade.       │
   * │                                                                 │
   * │ O índice do teclado passa a ser estado próprio: a tecla move-o,  │
   * │ o scroll sincroniza-o, e nenhum dos dois espera pelo outro.      │
   * └─────────────────────────────────────────────────────────────────┘
   */
  let indiceTeclado = 0;
  const sincronizar = () => {
    // Durante um salto o scroll passa por cima de tudo o que está no
    // caminho; sincronizar aí punha o teclado a recuar para a secção
    // que se está a atravessar.
    if (aSaltar()) return;
    const i = lista.findIndex((s) => s.id === actualId);
    if (i >= 0) indiceTeclado = i;
  };
  window.addEventListener("scroll", sincronizar, { passive: true });

  return {
    lista,
    irPara: (delta) => {
      const i = Math.max(0, Math.min(lista.length - 1, indiceTeclado + delta));
      if (i === indiceTeclado && delta !== 0) return;
      indiceTeclado = i;
      aterrar(lista[i].id, false);
      saltoAte = Date.now() + (prefereParado() ? 150 : 950);
    },
  };
}

/* ═══ 8 · DOCK MÓVEL ═══════════════════════════════════════════════ */

function montarDock(nav) {
  const folha = el("div", { class: "x-folha", id: "x-folha", hidden: "", role: "group", "aria-label": "Índice e pesquisa" },
    `<div class="x-folha-cab"><h2>Índice e pesquisa</h2>` +
    `<button type="button" class="x-folha-fechar" aria-label="Fechar">${ICO.x}</button></div>` +
    `<div class="x-folha-corpo"></div>`);
  document.body.appendChild(folha);

  const dock = el("nav", { class: "x-dock", "aria-label": "Ações rápidas" },
    `<button type="button" data-a="busca" aria-expanded="false" aria-controls="x-folha">${ICO.lupa}<span>Pesquisar</span></button>` +
    `<button type="button" data-a="indice" aria-expanded="false" aria-controls="x-folha">${ICO.lista}<span>Índice</span></button>` +
    `<button type="button" data-a="tema">${ICO.tema}<span>Tema</span></button>` +
    `<button type="button" data-a="topo">${ICO.topo}<span>Topo</span></button>`);
  document.body.appendChild(dock);

  const corpo = $(".x-folha-corpo", folha);
  const lado = nav.closest(".x-lado") || nav;
  const casaDesktop = lado.parentElement;
  const mq = matchMedia("(max-width:960px)");

  const recolocar = () => {
    if (mq.matches) { if (lado.parentElement !== corpo) corpo.appendChild(lado); }
    else if (lado.parentElement !== casaDesktop) casaDesktop.insertBefore(lado, casaDesktop.firstChild);
  };
  recolocar();
  mq.addEventListener ? mq.addEventListener("change", recolocar) : mq.addListener(recolocar);

  let aberta = false;
  const abrir = () => {
    if (aberta) return;
    aberta = true;
    folha.hidden = false;
    void folha.offsetWidth;
    folha.classList.add("on");
    for (const b of $$("[data-a='busca'],[data-a='indice']", dock)) b.setAttribute("aria-expanded", "true");
  };
  const fecharFolha = () => {
    if (!aberta) return;
    aberta = false;
    folha.classList.remove("on");
    for (const b of $$("[data-a='busca'],[data-a='indice']", dock)) b.setAttribute("aria-expanded", "false");
    setTimeout(() => { if (!aberta) folha.hidden = true; }, prefereParado() ? 0 : 230);
  };
  window.__X_DOCK_ABRIR__ = abrir;
  window.__X_DOCK_FECHAR__ = fecharFolha;

  $(".x-folha-fechar", folha).addEventListener("click", fecharFolha);
  for (const b of $$("button", dock)) {
    b.addEventListener("click", () => {
      const a = b.dataset.a;
      if (a === "topo") { window.scrollTo({ top: 0, behavior: prefereParado() ? "auto" : "smooth" }); fecharFolha(); return; }
      if (a === "tema") { $("#theme").click(); return; }
      if (aberta && ((a === "busca" && document.activeElement === campo) || a === "indice")) { fecharFolha(); return; }
      abrir();
      if (a === "busca") setTimeout(() => { campo.focus(); if (!campo.value) desenhar(""); }, 60);
    });
  }
  // Um clique no documento por baixo fecha a folha — não há véu a apanhá-lo.
  document.addEventListener("click", (e) => {
    if (!aberta) return;
    if (folha.contains(e.target) || dock.contains(e.target)) return;
    fecharFolha();
  });
  document.addEventListener("keydown", (e) => { if (e.key === "Escape" && aberta) fecharFolha(); });
}

/* ═══ 9 · TECLADO ══════════════════════════════════════════════════ */

/**
 * Que secção se está a ler AGORA.
 *
 * O índice marca a corrente com `a.cur`, mas só depois de a leitura ter
 * começado: no topo da página não há nenhuma, e o `R` não fazia nada —
 * calado, que é o pior. Sem marca, vale a primeira secção que ainda
 * está no ecrã, que é o que a pessoa tem à frente.
 */
function seccaoALer() {
  const cur = $("nav.toc a.cur");
  if (cur) return cur.getAttribute("href").slice(1);
  for (const s of $$("main section[id]")) {
    if (/^x-/.test(s.id)) continue;
    const r = s.getBoundingClientRect();
    if (r.height > 0 && r.bottom > 120) return s.id;
  }
  return null;
}

function montarAtalhos(ctx) {
  const ajuda = el("div", { class: "x-ajuda", hidden: "", role: "dialog", "aria-modal": "true", "aria-label": "Atalhos de teclado" },
    `<div class="x-ajuda-cx"><div class="x-ajuda-cab"><h2>Atalhos</h2>` +
    `<button type="button" aria-label="Fechar">${ICO.x}</button></div>` +
    `<div class="x-ajuda-corpo"><dl>` +
    `<dt><kbd>${atalhoDoSistema()}</kbd> <span aria-hidden="true">ou</span> <kbd>/</kbd></dt><dd>Pesquisar no dossiê</dd>` +
    `<dt><kbd>J</kbd> <span aria-hidden="true">·</span> <kbd>K</kbd></dt><dd>Secção seguinte · anterior</dd>` +
    `<dt><kbd>G</kbd> <kbd>G</kbd></dt><dd>Ir para o topo</dd>` +
    `<dt><kbd>G</kbd> <kbd>E</kbd></dt><dd>Ir para o estado do projeto</dd>` +
    `<dt><kbd>G</kbd> <kbd>I</kbd></dt><dd>Ir para o inventário</dd>` +
    `<dt><kbd>T</kbd></dt><dd>Trocar de tema</dd>` +
    `<dt><kbd>R</kbd></dt><dd>Recortar a secção que estás a ler</dd>` +
    `<dt><kbd>?</kbd></dt><dd>Este painel</dd>` +
    `<dt><kbd>Esc</kbd></dt><dd>Fechar o que estiver aberto</dd>` +
    `</dl></div></div>`);
  document.body.appendChild(ajuda);
  const fecharAjuda = () => { ajuda.hidden = true; };
  $("button", $(".x-ajuda-cab", ajuda)).addEventListener("click", fecharAjuda);
  ajuda.addEventListener("click", (e) => { if (e.target === ajuda) fecharAjuda(); });

  let ultimaG = 0;
  document.addEventListener("keydown", (e) => {
    const alvo = e.target;
    const aEscrever = alvo && (alvo.tagName === "INPUT" || alvo.tagName === "TEXTAREA" || alvo.isContentEditable);

    if ((e.key === "k" || e.key === "K") && (e.metaKey || e.ctrlKey)) {
      e.preventDefault(); focarBusca(); return;
    }
    if (e.key === "Escape" && !ajuda.hidden) { e.preventDefault(); fecharAjuda(); return; }
    if (aEscrever || e.metaKey || e.ctrlKey || e.altKey) return;

    if (e.key === "/") { e.preventDefault(); focarBusca(); return; }
    if (e.key === "?") { e.preventDefault(); ajuda.hidden = !ajuda.hidden; return; }
    if (e.key === "j" || e.key === "J") { e.preventDefault(); ctx.irPara(1); return; }
    if (e.key === "k" || e.key === "K") { e.preventDefault(); ctx.irPara(-1); return; }
    if (e.key === "t" || e.key === "T") { e.preventDefault(); $("#theme").click(); return; }
    /* R recorta a secção que se está a ler. É o gesto que faltava: quem
       lê com o teclado tinha de ir buscar o rato ao botão. */
    if (e.key === "r" || e.key === "R") {
      e.preventDefault();
      const id = seccaoALer();
      const bt = id && $(`.x-rec-b[data-doc="sec:${id}"]`);
      if (bt) { bt.click(); bt.focus({ preventScroll: true }); }
      return;
    }
    if (e.key === "g" || e.key === "G") { ultimaG = Date.now(); return; }
    if (Date.now() - ultimaG < 900) {
      if (e.key === "g" || e.key === "G") { e.preventDefault(); window.scrollTo({ top: 0, behavior: prefereParado() ? "auto" : "smooth" }); }
      if (e.key === "e" || e.key === "E") { e.preventDefault(); aterrar("x-estado", true); }
      if (e.key === "i" || e.key === "I") { e.preventDefault(); aterrar("x-inventario", true); }
      ultimaG = 0;
    }
  });
}

/* ═══ 10 · Arranque ════════════════════════════════════════════════ */

/* ═══ SAÚDE DO PLANO ════════════════════════════════════════════════
   Um estado em palavra, e por baixo os fatores que o produziram — a
   forma do `saudeFiscal` do Recibo Certo. Nenhum número está escrito:
   todos saem de contar o ZIP ao abrir a página. */
function montarSaude() {
  if (!window.XS || !DADOS) return;
  /* Deriva os números das secções do DOM em vez de esperar pelo índice:
     este painel é montado ANTES dele, para entrar no índice por existir
     — que é a regra que faz o índice não divergir. */
  const secoes = new Map();
  for (const s of $$("main section[id]")) {
    const m = /^(\d{1,2}|★)\s*[—-]/.exec((($(".sec-no", s) || {}).textContent || "").trim());
    if (m) secoes.set(s.id, { numero: m[1] });
  }
  const s = window.XS.saude(DADOS, secoes);
  const ins = window.XS.insights(s);
  const sec = el("section", { id: "x-saude" });

  const grau = { ok: "ok", atencao: "aviso", alerta: "grave", desconhecido: "parado" };
  const palavra = { ok: "em dia", atencao: "atenção", alerta: "trava", desconhecido: "por medir" };

  sec.innerHTML =
    `<span class="sec-no">★ — Saúde</span>` +
    `<h3>O plano anda? ${X.escapar(s.estado)}</h3>` +
    `<p class="lede">Sete fatores, ${s.avaliados} deles avaliáveis. Um fator que não se consegue ler diz ` +
    `<strong>por medir</strong> em vez de contar como bom — é a distinção que impede o verde falso. ` +
    `Nenhuma contagem desta secção está escrita à mão: se o <code>tickets.json</code> mudar, isto muda com ele.</p>` +

    (ins.length
      ? `<div class="x-insights"><h4 id="x-saude-primeiro">A seguir, por esta ordem</h4><ol>` +
        ins.map((i) =>
          `<li class="x-ins x-ins-${X.escapar(i.tom)}"><b>${X.escapar(i.titulo)}</b>` +
          `<span class="x-ins-e">${X.escapar(i.evidencia)}</span>` +
          `<span class="x-ins-t">${X.escapar(i.texto)}</span></li>`).join("") +
        `</ol></div>`
      : "") +

    `<h4 id="x-saude-fatores">Os fatores, um a um</h4>` +
    `<div class="x-fatores">` +
    s.fatores.map((f) =>
      `<div class="x-fator" data-e="${X.escapar(f.estado)}">` +
      `<div class="x-fator-c"><span class="x-fator-r">${X.escapar(f.rotulo)}</span>` +
      `<span class="x-estado ${grau[f.estado]}">${X.escapar(palavra[f.estado])}</span></div>` +
      `<p class="x-fator-e">${X.escapar(f.evidencia)}</p>` +
      `<p class="x-fator-p">${X.escapar(f.porque)}</p></div>`).join("") +
    `</div>`;

  const main = $("main"), estado = $("#x-estado");
  if (estado && estado.nextSibling) main.insertBefore(sec, estado.nextSibling);
  else if (estado) main.appendChild(sec);
  else main.insertBefore(sec, main.firstChild);
}

/* ═══ RECORTE ═══════════════════════════════════════════════════════
   A bandeja vive em `05-recorte.js`; aqui só se desenha. O botão entra
   em cada secção e em cada caixa de decisão porque são essas as duas
   coisas que alguém quer mandar a um colaborador. */
function montarRecorte(docs) {
  if (!window.XC) return;
  const XCc = window.XC;

  const botao = (idDoc, rotulo) =>
    el("button", {
      type: "button", class: "x-rec-b", "data-doc": idDoc,
      "aria-pressed": String(XCc.tem(idDoc)),
      title: "Juntar ao recorte",
    }, `${ICO.mais}<span class="x-rec-b-t">${rotulo}</span>`);

  for (const s of $$("main section[id]")) {
    if (/^x-(estado|saude|inventario|glossario)$/.test(s.id)) continue;
    const no = $(".sec-no", s);
    const b = botao("sec:" + s.id, "Recortar");
    if (no && no.parentElement === s) s.insertBefore(b, no.nextSibling);
    else s.insertBefore(b, s.firstChild);
  }
  for (const n of $$("main .note[id], main .lantern[id]")) {
    n.appendChild(botao("nota:" + n.id, "Recortar"));
  }

  const folha = el("div", {
    class: "x-rec-folha", id: "x-rec-folha", hidden: "",
    role: "group", "aria-label": "Recorte",
  },
    `<div class="x-folha-cab"><h2>Recorte</h2>` +
    `<button type="button" class="x-rec-fechar" aria-label="Fechar">${ICO.x}</button></div>` +
    `<div class="x-rec-corpo"></div>`);
  document.body.appendChild(folha);

  const flutuante = el("button", {
    type: "button", class: "x-rec-flutua", hidden: "",
    "aria-controls": "x-rec-folha", "aria-expanded": "false",
  }, `${ICO.recorte}<span>Recorte <b class="x-rec-n">0</b></span>`);
  document.body.appendChild(flutuante);

  const corpo = $(".x-rec-corpo", folha);
  let formato = "markdown";

  function pintar() {
    const r = XCc.compor(docs, $("#x-rec-titulo") ? $("#x-rec-titulo").value : "");
    const achados = XCc.auditar(r);

    if (!r.itens) {
      corpo.innerHTML =
        `<div class="x-rec-vazio"><p><b>Ainda não recortaste nada.</b></p>` +
        `<p>Cada secção e cada caixa de decisão tem um botão <em>Recortar</em>. ` +
        `Junta o que interessa e sai daqui um documento pequeno que se lê sozinho — ` +
        `com a proveniência de cada linha e uma impressão que muda se o dossiê mudar.</p></div>`;
      return;
    }

    const texto = XCc.FORMATOS[formato].render(r);
    corpo.innerHTML =
      `<label class="x-rec-tit"><span>Título</span>` +
      `<input id="x-rec-titulo" type="text" value="${X.escapar(r.titulo)}" maxlength="120"></label>` +

      `<div class="x-rec-lista">` +
      r.seccoes.map((sec) =>
        `<div class="x-rec-grupo">${X.escapar(sec.titulo)} <span class="x-n">${sec.itens.length}</span></div><ul>` +
        sec.itens.map((it) =>
          `<li><button type="button" class="x-rec-i" data-ir="${X.escapar(String(it.id).replace(/^[a-z]+:/, ""))}">` +
          `${it.marca ? `<span class="x-id">${X.escapar(it.marca)}</span>` : ""}` +
          `<span class="x-rec-i-t">${X.escapar(String(it.texto).slice(0, 90))}</span></button>` +
          `<button type="button" class="x-rec-tira" data-doc="${X.escapar(it.id)}" ` +
          `aria-label="Tirar do recorte">${ICO.x}</button></li>`).join("") +
        `</ul>`).join("") +
      `</div>` +

      `<div class="x-rec-meta"><span><b>${r.itens}</b> ${r.itens === 1 ? "item" : "itens"}</span>` +
      `<span>impressão <code>${X.escapar(r.impressao)}</code></span></div>` +
      (achados.length
        ? `<p class="x-rec-alerta">${achados.length} item(ns) fora da lista branca — não seguem.</p>`
        : "") +

      `<div class="x-rec-formatos" role="group" aria-label="Formato">` +
      Object.keys(XCc.FORMATOS).map((k) =>
        `<button type="button" class="x-filtro" data-f="${k}" aria-pressed="${k === formato}">` +
        `${X.escapar(XCc.FORMATOS[k].rotulo)}</button>`).join("") +
      `</div>` +
      `<pre class="x-rec-saida" id="x-rec-saida" tabindex="0">${X.escapar(texto)}</pre>` +
      `<div class="x-rec-accoes">` +
      `<button type="button" class="x-rec-copiar">Copiar</button>` +
      `<button type="button" class="x-rec-limpar">Esvaziar</button></div>`;

    $("#x-rec-titulo", corpo).addEventListener("input", () => {
      // Só o meta e a saída dependem do título — repintar tudo tirava o foco.
      const novo = XCc.compor(docs, $("#x-rec-titulo").value);
      $(".x-rec-saida", corpo).textContent = XCc.FORMATOS[formato].render(novo);
      $(".x-rec-meta code", corpo).textContent = novo.impressao;
    });
    /* Um item do recorte é um destino: carregar leva lá, e a folha sai
       da frente. Sem isto, rever o que se juntou obrigava a fechar,
       procurar e voltar. */
    for (const b of $$("[data-ir]", corpo)) {
      b.addEventListener("click", () => { fechar(); window.__X_ATERRAR__(b.dataset.ir, true); });
    }
    for (const b of $$(".x-rec-tira", corpo)) {
      b.addEventListener("click", () => { XCc.alternar(b.dataset.doc); pintar(); });
    }
    for (const b of $$("[data-f]", corpo)) {
      b.addEventListener("click", () => { formato = b.dataset.f; pintar(); });
    }
    $(".x-rec-copiar", corpo).addEventListener("click", (e) => {
      const t = $(".x-rec-saida", corpo).textContent;
      const dizer = (ok) => { e.target.textContent = ok ? "Copiado" : "Selecionado — Ctrl+C"; setTimeout(() => { e.target.textContent = "Copiar"; }, 1800); };
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(t).then(() => dizer(true), () => { selecionarSaida(); dizer(false); });
      } else { selecionarSaida(); dizer(false); }
    });
    $(".x-rec-limpar", corpo).addEventListener("click", () => { XCc.limpar(); pintar(); });
  }

  function selecionarSaida() {
    const pre = $(".x-rec-saida", corpo);
    const r = document.createRange();
    r.selectNodeContents(pre);
    const sel = getSelection();
    sel.removeAllRanges(); sel.addRange(r);
    pre.focus();
  }

  function sincronizar() {
    const n = XCc.conta();
    flutuante.hidden = n === 0;
    $(".x-rec-n", flutuante).textContent = String(n);
    for (const b of $$(".x-rec-b")) {
      const dentro = XCc.tem(b.dataset.doc);
      b.setAttribute("aria-pressed", String(dentro));
      $(".x-rec-b-t", b).textContent = dentro ? "No recorte" : "Recortar";
    }
  }

  /* A bandeja anuncia-se; a interface ouve. O caminho é UM — quem mexer
     na bandeja por outra via (uma restauração da sessão, outro separador,
     uma funcionalidade que ainda não existe) acerta os botões na mesma.
     Sincronizar no sítio de cada clique era o mesmo que não sincronizar:
     funciona até ao dia em que alguém muda a bandeja sem clicar. */
  window.addEventListener("x-recorte", sincronizar);

  document.addEventListener("click", (e) => {
    const b = e.target.closest && e.target.closest(".x-rec-b");
    if (!b) return;
    e.preventDefault();
    XCc.alternar(b.dataset.doc);
    if (!folha.hidden) pintar();
  });

  const abrir = () => {
    folha.hidden = false;
    void folha.offsetWidth;
    folha.classList.add("on");
    flutuante.setAttribute("aria-expanded", "true");
    pintar();
  };
  const fechar = () => {
    folha.classList.remove("on");
    flutuante.setAttribute("aria-expanded", "false");
    setTimeout(() => { folha.hidden = true; }, prefereParado() ? 0 : 230);
    flutuante.focus();
  };
  flutuante.addEventListener("click", () => (folha.hidden ? abrir() : fechar()));
  $(".x-rec-fechar", folha).addEventListener("click", fechar);
  folha.addEventListener("keydown", (e) => { if (e.key === "Escape") { e.stopPropagation(); fechar(); } });

  sincronizar();
}

function arrancar() {
  const nav = $("nav.toc");
  if (!nav) return;

  // O salto para o conteúdo — o primeiro tabulador de qualquer página.
  const salto = el("a", { class: "x-salto", href: "#conteudo" }, "Saltar para o conteúdo");
  document.body.insertBefore(salto, document.body.firstChild);
  const main = $("main");
  if (main && !main.id) main.id = "conteudo";

  // Os painéis novos são construídos ANTES do índice: entram no índice
  // por existirem no DOM, e não por alguém os acrescentar à lista.
  if (window.XP) window.XP.montar(DADOS);
  montarSaude();

  /* As partes envolvem-se DEPOIS dos painéis (para os empurrar para fora
     do acordeão, que é onde eles têm de ficar) e ANTES do índice — o
     índice deriva do DOM, e o DOM que interessa é já o agrupado. */
  if (window.XPT) window.XPT.montar();

  IDX = XI.construir(DADOS);
  window.__X_IDX__ = IDX;

  // Depois do índice: a bandeja identifica os itens pelos ids do índice,
  // e é o índice que atribui id a cada caixa de decisão.
  montarRecorte(IDX.docs);

  montarMarcos();
  montarAncoras();
  montarReferencias(IDX.porNumero, IDX.secoes);
  if (window.XP) window.XP.montarGlossario(IDX.porNumero);
  montarBusca(nav);
  const grupos = montarIndice(nav);
  const ctx = montarContexto(IDX.secoes);
  const actualizarSub = montarSubIndice(nav, IDX.secoes);
  montarDock(nav);
  montarVoltar();
  montarAtalhos(ctx);

  // O índice acompanha a leitura: o grupo da secção corrente abre-se, e
  // a ligação activa é trazida para dentro da calha.
  const obs = new MutationObserver(() => {
    const cur = $("nav.toc a.cur");
    if (!cur) return;
    abrirGrupoDe(grupos, cur);
    actualizarSub(cur);
    const r = cur.getBoundingClientRect(), n = nav.getBoundingClientRect();
    if (r.top < n.top + 8 || r.bottom > n.bottom - 8) {
      cur.scrollIntoView({ block: "nearest", behavior: "auto" });
    }
  });
  obs.observe(nav, { attributes: true, subtree: true, attributeFilter: ["class"] });
  // O observador só acorda quando a secção MUDA; qual sub-título se está
  // a ler muda a cada rolo dentro da mesma secção.
  let subAgendado = null;
  window.addEventListener("scroll", () => {
    clearTimeout(subAgendado);
    subAgendado = setTimeout(() => actualizarSub($("nav.toc a.cur")), 120);
  }, { passive: true });

  // Chegar por URL com âncora: dar o mesmo destaque de aterragem.
  if (location.hash.length > 1) {
    setTimeout(() => aterrar(location.hash.slice(1), false), 120);
  }

  window.__X_ATERRAR__ = aterrar;
  window.__X_A_SALTAR__ = aSaltar;
  window.__X_FOCAR_BUSCA__ = focarBusca;
}

if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", arrancar);
else arrancar();
})();
