#!/usr/bin/env node
// tools/web/verificar_site.mjs — o site medido, não sentido (ADR 0024, ADR 0025).
//
// A disciplina é a do Recibo Certo (scripts/verificar-movel.mjs e os
// auditar-*.mjs de lá) e a do Além da Sessão (check:privacy, check:contrast,
// check:budgets): uma regra que só se verifica olhando para o ecrã certo não é
// uma regra, é uma intenção. Isto corre contra o ARTEFACTO — build/site,
// servido por um servidor estático aqui dentro — e não contra o código.
//
// O que mede, e porque cada coisa falha em silêncio:
//    1 · ROLAGEM LATERAL a 320, 360, 768 e 1440 px, nos dois temas e nas duas línguas.
//    2 · TRANSBORDO — algo visível a sair pela direita do ecrã.
//    3 · PISO TIPOGRÁFICO — texto visível abaixo de 12 px.
//    4 · ALVOS — o que se toca abaixo de 36 px (as ligações no meio de uma
//        frase estão isentas: é a excepção «inline» da WCAG 2.5.8).
//    5 · AXE — WCAG 2.0/2.1 A e AA, nos dois temas, estreito e largo, nas três páginas.
//    6 · LIGAÇÕES — cada href e src interno responde 200; cada âncora existe.
//    7 · SEO — título, descrição, h1 único, lang, robots, hreflang recíproco, og:image.
//    8 · TECLADO — o primeiro Tab é o «saltar para o conteúdo», e ele leva lá;
//        o botão do tema funciona com Enter e a escolha sobrevive a recarregar.
//    9 · SEM CLARÃO — um tema guardado está aplicado antes do primeiro pixel.
//   10 · MOVIMENTO REDUZIDO — nada fica escondido, e o dia não anda sozinho.
//   11 · O JOGO — /jogar/ carrega, o ecrã de carregamento sai e o canvas fica,
//        com a CSP estrita e os controlos lidos do project.godot.
//   12 · PRIVACIDADE — nenhuma página pede nada a outra origem (§32).
//   13 · CSP — cada página tem a sua, e nenhuma é violada.
//   14 · AS DUAS LÍNGUAS — a mesma forma: as mesmas secções, os mesmos cartões.
//   15 · OS DADOS — o que a página diz é o que o repositório tem.
//   16 · O DIA — pausa (WCAG 2.2.2), deslizador pelo teclado, um quadro só à vista.
//   17 · O MENU — num ecrã estreito abre, fecha e fecha com Esc.
//   18 · A CANDEIA — as contas do instrumento são as do rot.csv.
//   19 · ORÇAMENTO — o peso da página de entrada, e o do caminho crítico.
//
//   node tools/web/verificar_site.mjs [build/site]
//
// Precisa do Playwright e do @axe-core/playwright em ferramentas/node_modules
// (npm install --no-save playwright @axe-core/playwright, como o CI faz).
// Código de saída: 0 = passa · 1 = pelo menos uma falha.

import { createServer } from "node:http";
import { readFileSync, existsSync, statSync } from "node:fs";
import { join, resolve, extname, dirname } from "node:path";
import { createRequire } from "node:module";
import { pathToFileURL, fileURLToPath } from "node:url";
import { ler } from "./dados.mjs";
import { TEXTOS } from "./paginas/textos.mjs";

const RAIZ = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
const SITE = resolve(process.argv[2] || join(RAIZ, "build", "site"));
const exigir = createRequire(join(RAIZ, "ferramentas", "LEIA-ME.md"));
// Os dois são CommonJS: vistos de um módulo ES, o que exportam vem em `default`.
const pw = await import(pathToFileURL(exigir.resolve("playwright")));
const chromium = pw.chromium ?? pw.default.chromium;
const axe = await import(pathToFileURL(exigir.resolve("@axe-core/playwright")));
const AxeBuilder = axe.AxeBuilder ?? axe.default?.AxeBuilder ?? axe.default?.default ?? axe.default;

const LARGURAS = [320, 360, 768, 1440];
const TEMAS = ["light", "dark"];
const PAGINAS = ["/", "/en/"];
const PISO_PX = 12;
const ALVO_PX = 36;
const JOGO_S = 90;
// O orçamento da página de entrada, em KB e sem compressão (a Vercel serve com
// brotli, e por isso o que chega é menos). O caminho crítico é o que a página
// precisa antes do primeiro ecrã: HTML, folha, os dois scripts, as duas fontes
// pré-carregadas e o primeiro quadro. O total é tudo o que ela pede ao abrir,
// menos o prefetch do motor do jogo, que é para depois.
const CRITICO_KB = 420;
const TOTAL_KB = 800;
const TIPOS = {
  ".html": "text/html; charset=utf-8", ".js": "text/javascript", ".wasm": "application/wasm", ".css": "text/css",
  ".pck": "application/octet-stream", ".png": "image/png", ".webp": "image/webp", ".woff2": "font/woff2",
  ".svg": "image/svg+xml", ".json": "application/json", ".txt": "text/plain", ".xml": "application/xml",
  ".webmanifest": "application/manifest+json",
};

let falhas = 0;
const resultado = (nome, ok, detalhe = "") => {
  console.log(`  ${ok ? "✓" : "✗"} ${nome}${ok || !detalhe ? "" : ` — ${detalhe}`}`);
  if (!ok) falhas++;
};

// Um servidor estático com as regras do vercel.json que importam aqui:
// trailingSlash (redirecciona /jogar para /jogar/) e o 404.html.
function servir() {
  const srv = createServer((req, res) => {
    const caminho = decodeURIComponent(new URL(req.url, "http://x").pathname);
    let f = join(SITE, caminho);
    if (existsSync(f) && statSync(f).isDirectory()) {
      if (!caminho.endsWith("/")) { res.writeHead(308, { Location: caminho + "/" }); return res.end(); }
      f = join(f, "index.html");
    }
    if (!existsSync(f)) {
      res.writeHead(404, { "Content-Type": TIPOS[".html"] });
      return res.end(readFileSync(join(SITE, "404.html")));
    }
    res.writeHead(200, { "Content-Type": TIPOS[extname(f)] || "application/octet-stream" });
    res.end(readFileSync(f));
  });
  return new Promise((ok) => srv.listen(0, "127.0.0.1", () => ok(srv)));
}

// Sonda que corre DENTRO da página: devolve os defeitos 2, 3 e 4.
const SONDA = ({ piso, alvo }) => {
  const nome = (el) => el.tagName.toLowerCase() + (el.id ? `#${el.id}` : "") +
    (el.className && typeof el.className === "string" ? "." + el.className.trim().split(/\s+/).join(".") : "");
  const visivel = (el) => {
    const cs = getComputedStyle(el);
    if (cs.visibility === "hidden" || cs.display === "none" || +cs.opacity === 0) return false;
    const r = el.getBoundingClientRect();
    return r.width > 0 && r.height > 0;
  };
  const decorativo = (el) => el.closest("[aria-hidden='true']");
  const W = document.documentElement.clientWidth;
  const saida = { transbordo: [], piso: [], alvos: [] };
  for (const el of document.body.querySelectorAll("*")) {
    if (!visivel(el) || decorativo(el)) continue;
    const r = el.getBoundingClientRect();
    // O que está dentro de uma caixa que rola de lado (uma tabela larga) não
    // sai do ecrã: sai da caixa, e a caixa rola.
    const rola = el.closest(".tabela-rola");
    if (r.right > W + 1 && !el.closest(".salto") && !rola) saida.transbordo.push(`${nome(el)} (${Math.round(r.right)} > ${W})`);
    const temTexto = [...el.childNodes].some((n) => n.nodeType === 3 && n.textContent.trim());
    if (temTexto && parseFloat(getComputedStyle(el).fontSize) < piso) {
      saida.piso.push(`${nome(el)} (${getComputedStyle(el).fontSize})`);
    }
    if (el.matches("a[href], button, [role='button'], input, select, textarea, summary") && !el.closest(".salto")) {
      const inline = getComputedStyle(el).display === "inline";
      if (!inline && (r.width < alvo || r.height < alvo)) {
        saida.alvos.push(`${nome(el)} ${Math.round(r.width)}×${Math.round(r.height)}`);
      }
    }
  }
  return saida;
};

// Cada página nova: regista os pedidos, as violações de CSP e os erros.
async function nova(b, base, largura, tema, extra = {}) {
  const ctx = await b.newContext({ viewport: { width: largura, height: 900 }, colorScheme: tema, ...extra });
  const p = await ctx.newPage();
  const erros = [], pedidos = [];
  await p.addInitScript(() => {
    window.__csp = [];
    document.addEventListener("securitypolicyviolation", (e) => window.__csp.push(`${e.violatedDirective} ${e.blockedURI}`));
  });
  p.on("pageerror", (e) => erros.push(e.message));
  p.on("console", (m) => { if (m.type() === "error") erros.push(m.text()); });
  p.on("request", (r) => pedidos.push(r.url()));
  return { ctx, p, erros, pedidos };
}

// Faz aparecer tudo o que entra ao rolar, para medir a página inteira.
async function revelar(p) {
  await p.evaluate(async () => {
    for (let y = 0; y < document.body.scrollHeight; y += 400) { window.scrollTo(0, y); await new Promise((r) => setTimeout(r, 30)); }
    window.scrollTo(0, 0);
    document.querySelectorAll(".revela, .barra").forEach((e) => e.classList.add("visto"));
  });
  await p.waitForTimeout(700);
}

async function main() {
  if (!existsSync(join(SITE, "index.html"))) {
    console.error(`verificar_site: ${SITE}/index.html não existe — corre primeiro \`make site\``);
    process.exit(2);
  }
  const d = ler(RAIZ);
  const srv = await servir();
  const base = `http://127.0.0.1:${srv.address().port}`;
  const b = await chromium.launch({
    executablePath: process.env.PLAYWRIGHT_CHROMIUM || (existsSync("/opt/pw-browsers/chromium") ? "/opt/pw-browsers/chromium" : undefined),
    args: ["--use-gl=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"],
  });
  const externos = new Set();
  const violacoes = [];

  console.log("\n1–4 · telemóvel primeiro: rolagem, transbordo, piso e alvos");
  for (const rota of PAGINAS) {
    for (const tema of TEMAS) {
      for (const w of LARGURAS) {
        const { ctx, p, erros, pedidos } = await nova(b, base, w, tema);
        await p.goto(base + rota, { waitUntil: "load" });
        await revelar(p);
        const lateral = await p.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
        const s = await p.evaluate(SONDA, { piso: PISO_PX, alvo: ALVO_PX });
        const rot = `${rota} · ${w}px · ${tema === "light" ? "claro" : "escuro"}`;
        resultado(`${rot}: sem rolagem lateral`, lateral <= 0, `${lateral}px a mais`);
        resultado(`${rot}: nada sai do ecrã`, s.transbordo.length === 0, s.transbordo.slice(0, 4).join(", "));
        resultado(`${rot}: texto ≥ ${PISO_PX}px`, s.piso.length === 0, s.piso.slice(0, 4).join(", "));
        resultado(`${rot}: alvos ≥ ${ALVO_PX}px`, s.alvos.length === 0, s.alvos.slice(0, 4).join(", "));
        resultado(`${rot}: sem erros de JavaScript`, erros.length === 0, erros.slice(0, 2).join(" | "));
        pedidos.filter((u) => !u.startsWith(base) && !u.startsWith("data:")).forEach((u) => externos.add(`${rota} → ${u}`));
        violacoes.push(...(await p.evaluate(() => window.__csp)).map((v) => `${rota}: ${v}`));
        await ctx.close();
      }
    }
  }

  console.log("\n5 · axe (WCAG 2.1 A e AA)");
  for (const tema of TEMAS) {
    for (const w of [360, 1440]) {
      for (const rota of [...PAGINAS, "/404.html"]) {
        const { ctx, p } = await nova(b, base, w, tema);
        await p.goto(base + rota, { waitUntil: "load" });
        await revelar(p);
        const { violations: v } = await new AxeBuilder({ page: p })
          .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"]).analyze();
        const resumo = v.map((x) => `${x.id} (${x.nodes.length}): ${x.nodes[0]?.target?.join(" ")}`).join("; ");
        resultado(`${rota} · ${w}px · ${tema === "light" ? "claro" : "escuro"}: 0 violações`, v.length === 0, resumo);
        await ctx.close();
      }
    }
  }

  console.log("\n6 · ligações e âncoras");
  for (const rota of [...PAGINAS, "/404.html"]) {
    const { ctx, p } = await nova(b, base, 1440, "dark");
    await p.goto(base + rota, { waitUntil: "load" });
    const refs = await p.evaluate(() => ({
      hrefs: [...document.querySelectorAll("a[href]")].map((a) => a.getAttribute("href")),
      srcs: [...document.querySelectorAll("[src], link[href]")].map((e) => e.getAttribute("src") || e.getAttribute("href")),
      ids: [...document.querySelectorAll("[id]")].map((e) => e.id),
    }));
    const internos = [...new Set([...refs.hrefs, ...refs.srcs])].filter((h) => h && h.startsWith("/"));
    let partidos = [];
    for (const h of internos) {
      const r = await fetch(base + h, { redirect: "follow" });
      if (r.status !== 200) partidos.push(`${h} (HTTP ${r.status})`);
    }
    resultado(`${rota}: as ${internos.length} ligações e recursos internos respondem`, partidos.length === 0, partidos.join(", "));
    const soltas = refs.hrefs.filter((x) => x.startsWith("#") && !refs.ids.includes(x.slice(1)));
    resultado(`${rota}: todas as âncoras existem`, soltas.length === 0, soltas.join(", "));
    await ctx.close();
  }
  for (const rota of ["/jogar", "/dossie", "/en"]) {
    const r = await fetch(base + rota, { redirect: "manual" });
    resultado(`${rota} leva a ${rota}/`, r.status === 308 && r.headers.get("location") === rota + "/", `HTTP ${r.status}`);
  }
  const nada = await fetch(base + "/nao-existe");
  resultado("uma página que não existe dá 404", nada.status === 404, `HTTP ${nada.status}`);

  console.log("\n7 · SEO");
  for (const [rota, t] of [["/", TEXTOS.pt], ["/en/", TEXTOS.en]]) {
    const html = readFileSync(join(SITE, rota, "index.html"), "utf8");
    const meta = (n) => html.match(new RegExp(`<meta (?:name|property)="${n}" content="([^"]*)"`))?.[1];
    resultado(`${rota}: sem marcadores por preencher`, !/\{[a-z_0-9]+\}/.test(html));
    resultado(`${rota}: <html lang="${t.lingua}">`, html.includes(`<html lang="${t.lingua}">`));
    const titulo = html.match(/<title>([^<]+)<\/title>/)?.[1] || "";
    resultado(`${rota}: título com 10–65 caracteres (${titulo.length})`, titulo.length >= 10 && titulo.length <= 65);
    const desc = meta("description") || "";
    resultado(`${rota}: descrição com 70–170 caracteres (${desc.length})`, desc.length >= 70 && desc.length <= 170);
    resultado(`${rota}: um só <h1>`, (html.match(/<h1[\s>]/g) || []).length === 1);
    resultado(`${rota}: meta robots`, !!meta("robots"));
    const og = (meta("og:image") || "").replace(/^https?:\/\/[^/]+/, "");
    resultado(`${rota}: og:image existe (${og})`, !!og && existsSync(join(SITE, og)));
    const alt = [...html.matchAll(/<link rel="alternate" hreflang="([^"]+)" href="([^"]+)">/g)].map((m) => m[1]);
    resultado(`${rota}: hreflang pt-PT, en e x-default`, ["pt-PT", "en", "x-default"].every((l) => alt.includes(l)), alt.join(", "));
    resultado(`${rota}: dados estruturados (VideoGame)`, /"@type":"VideoGame"/.test(html));
  }
  resultado("robots.txt", existsSync(join(SITE, "robots.txt")));
  resultado("site.webmanifest com ícones que existem", (() => {
    const m = JSON.parse(readFileSync(join(SITE, "site.webmanifest"), "utf8"));
    return m.icons.every((i) => existsSync(join(SITE, i.src)));
  })());
  resultado("versao.json com o commit", /"commit": "[0-9a-f]{7,40}"/.test(readFileSync(join(SITE, "versao.json"), "utf8")));

  console.log("\n8 · teclado");
  {
    const { ctx, p } = await nova(b, base, 1440, "light");
    await p.goto(base + "/", { waitUntil: "load" });
    await p.keyboard.press("Tab");
    const primeiro = await p.evaluate(() => document.activeElement?.className);
    resultado("o primeiro Tab é «saltar para o conteúdo»", primeiro === "salto", String(primeiro));
    const contorno = await p.evaluate(() => getComputedStyle(document.activeElement).outlineStyle);
    resultado("o foco vê-se", contorno !== "none", contorno);
    await p.keyboard.press("Enter");
    resultado("e leva ao conteúdo", await p.evaluate(() => location.hash === "#conteudo"));
    await p.focus("#tema");
    await p.keyboard.press("Enter");
    const depois = await p.evaluate(() => document.documentElement.dataset.theme);
    resultado("o tema muda com Enter", depois === "dark", String(depois));
    await p.reload({ waitUntil: "load" });
    resultado("e a escolha sobrevive a recarregar", (await p.evaluate(() => document.documentElement.dataset.theme)) === "dark");
    await ctx.close();
  }

  console.log("\n9 · sem clarão");
  {
    const { ctx, p } = await nova(b, base, 1440, "light");
    await p.addInitScript(() => localStorage.setItem("empire:tema", "escuro"));
    let cedo = null;
    await p.exposeFunction("__tema", (t) => { cedo = cedo ?? t; });
    await p.addInitScript(() => document.addEventListener("DOMContentLoaded", () => window.__tema(document.documentElement.dataset.theme || "")));
    await p.goto(base + "/", { waitUntil: "load" });
    resultado("o tema guardado já está lá no DOMContentLoaded", cedo === "dark", String(cedo));
    await ctx.close();
  }

  console.log("\n10 · movimento reduzido");
  {
    const { ctx, p } = await nova(b, base, 1440, "dark", { reducedMotion: "reduce" });
    await p.goto(base + "/", { waitUntil: "load" });
    const escondidos = await p.evaluate(() => [...document.querySelectorAll(".revela")].filter((e) => +getComputedStyle(e).opacity < 1).length);
    resultado("nada fica à espera de uma animação", escondidos === 0, `${escondidos} secções invisíveis`);
    const antes = await p.evaluate(() => document.querySelector(".quadro.ativo")?.dataset.fase);
    await p.waitForTimeout(6500);
    const depois = await p.evaluate(() => document.querySelector(".quadro.ativo")?.dataset.fase);
    resultado("o dia não anda sozinho", antes === depois, `${antes} → ${depois}`);
    resultado("e a pausa diz que está parado", (await p.getAttribute("#pausa", "aria-pressed")) === "true");
    await ctx.close();
  }

  console.log("\n11 · o jogo");
  for (const q of ["", "?lingua=en"]) {
    // O que a casca TRAZ confere-se no HTML servido, e não no DOM vivo: os
    // controlos vivem no ecrã de carregamento, que sai quando o motor arranca —
    // e numa segunda carga, com o motor em cache, sai antes de se poder contar.
    const html = await (await fetch(base + "/jogar/" + q)).text();
    resultado(`/jogar/${q}: tem CSP e robots`, html.includes("Content-Security-Policy") && /<meta name="robots"/.test(html));
    const controlos = html.match(/<div class="controlos">[\s\S]*?<\/dl><\/div>/)?.[0] || "";
    resultado(`/jogar/${q}: os controlos do project.godot estão lá`, (controlos.match(/<dt>/g) || []).length === TEXTOS.pt.controlos.acoes.length);
    const { ctx, p, erros, pedidos } = await nova(b, base, 1280, "dark");
    await p.goto(base + "/jogar/" + q, { waitUntil: "load" });
    resultado(`/jogar/${q}: a língua é ${q ? "en" : "pt-PT"}`, (await p.evaluate(() => document.documentElement.lang)) === (q ? "en" : "pt-PT"));
    const saiu = await p.waitForFunction(() => !document.getElementById("status"), null, { timeout: JOGO_S * 1000 })
      .then(() => true, () => false);
    resultado(`/jogar/${q}: o carregamento acaba em menos de ${JOGO_S} s`, saiu);
    const canvas = await p.evaluate(() => { const c = document.getElementById("canvas"); return c ? [c.width, c.height] : [0, 0]; });
    resultado(`/jogar/${q}: o canvas tem tamanho`, canvas[0] > 0 && canvas[1] > 0, canvas.join("×"));
    resultado(`/jogar/${q}: sem erros de JavaScript`, erros.length === 0, erros.slice(0, 2).join(" | "));
    violacoes.push(...(await p.evaluate(() => window.__csp)).map((v) => `/jogar/${q}: ${v}`));
    pedidos.filter((u) => !u.startsWith(base) && !/^(data|blob):/.test(u)).forEach((u) => externos.add(`/jogar/ → ${u}`));
    await ctx.close();
  }

  console.log("\n12 · privacidade (§32) — nenhum pedido a outra origem");
  for (const rota of ["/404.html", "/dossie/"]) {
    const { ctx, p, pedidos } = await nova(b, base, 1440, "light");
    await p.goto(base + rota, { waitUntil: "load" });
    await p.waitForTimeout(500);
    pedidos.filter((u) => !u.startsWith(base) && !/^(data|blob):/.test(u)).forEach((u) => externos.add(`${rota} → ${u}`));
    await ctx.close();
  }
  resultado("/, /en/, /404.html, /jogar/ e /dossie/ só pedem ao próprio site", externos.size === 0, [...externos].slice(0, 4).join(", "));

  console.log("\n13 · CSP");
  for (const rota of [...PAGINAS, "/404.html"]) {
    const html = readFileSync(join(SITE, rota === "/404.html" ? "404.html" : join(rota, "index.html")), "utf8");
    resultado(`${rota}: tem CSP com script-src 'self'`, /http-equiv="Content-Security-Policy" content="[^"]*script-src 'self'/.test(html));
    resultado(`${rota}: sem <script> em linha nem style=""`, !/<script>|<script type="(?!application\/ld\+json)/.test(html) && !/\sstyle="/.test(html));
  }
  resultado("nenhuma página viola a sua CSP", violacoes.length === 0, violacoes.slice(0, 3).join(" | "));

  console.log("\n14 · as duas línguas, com a mesma forma");
  {
    const forma = async (rota) => {
      const { ctx, p } = await nova(b, base, 1440, "light");
      await p.goto(base + rota, { waitUntil: "load" });
      const f = await p.evaluate(() => ({
        seccoes: [...document.querySelectorAll("main > section")].map((s) => s.id || s.className),
        contas: [".pilares li", ".cartao-fase", ".povo", ".teclas-tabela tbody tr", ".cela", ".roteiro li", ".perguntas details", ".falas li", ".numero"]
          .map((s) => `${s}=${document.querySelectorAll(s).length}`),
      }));
      await ctx.close();
      return f;
    };
    const [pt, en] = [await forma("/"), await forma("/en/")];
    resultado("as mesmas secções, pela mesma ordem", pt.seccoes.join() === en.seccoes.join(), `${pt.seccoes} ≠ ${en.seccoes}`);
    resultado("os mesmos cartões, linhas e itens", pt.contas.join() === en.contas.join(), pt.contas.filter((x, i) => x !== en.contas[i]).join(", "));
  }

  console.log("\n15 · os dados — o que a página diz é o que o repositório tem");
  {
    const { ctx, p } = await nova(b, base, 1440, "light");
    await p.goto(base + "/", { waitUntil: "load" });
    const pag = await p.evaluate(() => ({
      h2dia: document.querySelector("#dia-t")?.textContent || "",
      duracoes: [...document.querySelectorAll(".cartao-fase .dur")].map((e) => parseInt(e.textContent, 10)),
      celas: document.querySelectorAll(".cela").length,
      feitos: document.querySelectorAll(".cela.c-feito").length,
      numeros: [...document.querySelectorAll(".numero b")].map((e) => Number(e.dataset.conta)),
      povos: [...document.querySelectorAll(".povo h3")].map((e) => e.textContent.trim()),
      hoje: [...document.querySelectorAll(".povo.hoje h3")].map((e) => e.textContent.trim()),
      falas: [...document.querySelectorAll(".falas q")].map((e) => e.textContent.trim()),
      violeta: document.querySelector(".ex-violeta code")?.textContent,
    }));
    resultado(`o dia tem ${d.relogio.dia} s, como o clock.csv`, pag.h2dia.includes(String(d.relogio.dia)), pag.h2dia);
    resultado("as seis durações são as do clock.csv", pag.duracoes.join() === d.relogio.fases.map((f) => f.dura).join(), pag.duracoes.join());
    resultado(`um quadrado por ticket (${d.tickets.total}), e ${d.tickets.feitos} feitos`, pag.celas === d.tickets.total && pag.feitos === d.tickets.feitos, `${pag.celas}, ${pag.feitos}`);
    resultado("os números do estado são os do tickets.json e do validation.json",
      pag.numeros.join() === [d.tickets.feitos, d.contas.testes, d.contas.adrs, d.contas.conferidos].join(), pag.numeros.join());
    resultado("os seis povos são os do §04", pag.povos.join() === d.povos.linhas.map((x) => x.nome).join(), pag.povos.join());
    resultado("o povo de hoje é o que tem segmentos", pag.hoje.join() === d.povos.linhas.filter((x) => x.hoje).map((x) => x.nome).join());
    resultado("as falas são as do strings.csv", pag.falas.join("|") === d.podridao.falas.map((f) => f.pt).join("|"), pag.falas.join(" | "));
    resultado(`o violeta é o do WorldPalette (${d.podridao.violeta})`, pag.violeta === d.podridao.violeta, String(pag.violeta));
    await ctx.close();
  }

  console.log("\n16 · o dia na abertura");
  {
    const { ctx, p } = await nova(b, base, 1440, "light");
    await p.goto(base + "/", { waitUntil: "load" });
    const um = async () => p.evaluate(() => {
      const a = [...document.querySelectorAll(".quadro.ativo")];
      return { n: a.length, fase: a[0]?.dataset.fase, escondido: a[0]?.getAttribute("aria-hidden") };
    });
    const antes = await um();
    resultado("um quadro só à vista, e não escondido dos leitores de ecrã", antes.n === 1 && antes.escondido === null, JSON.stringify(antes));
    await p.waitForTimeout(6500);
    resultado("sem movimento reduzido, o dia anda", (await um()).fase !== antes.fase);
    await p.click("#pausa");
    resultado("a pausa diz que parou", (await p.getAttribute("#pausa", "aria-pressed")) === "true");
    const parado = (await um()).fase;
    await p.waitForTimeout(3000);
    resultado("e parou mesmo", (await um()).fase === parado);
    await p.focus("#fita-palco");
    resultado("a fita é um deslizador", (await p.getAttribute("#fita-palco", "role")) === "slider");
    await p.keyboard.press("Home");
    resultado("Home leva à alvorada", (await um()).fase === "dawn", (await um()).fase);
    await p.keyboard.press("ArrowRight");
    resultado("→ leva à fase seguinte", (await um()).fase === d.relogio.fases[1].id, (await um()).fase);
    await ctx.close();
  }

  console.log("\n17 · o menu num ecrã estreito");
  {
    const { ctx, p } = await nova(b, base, 360, "light");
    await p.goto(base + "/", { waitUntil: "load" });
    resultado("o menu começa fechado", !(await p.isVisible("#menu a[href='#povos']")));
    await p.click("#abre-menu");
    resultado("abre", (await p.isVisible("#menu a[href='#povos']")) && (await p.getAttribute("#abre-menu", "aria-expanded")) === "true");
    await p.keyboard.press("Escape");
    resultado("e fecha com Esc", !(await p.isVisible("#menu a[href='#povos']")) && (await p.getAttribute("#abre-menu", "aria-expanded")) === "false");
    await ctx.close();
  }

  console.log("\n18 · a candeia");
  {
    const { ctx, p } = await nova(b, base, 1440, "dark");
    await p.goto(base + "/", { waitUntil: "load" });
    const r = d.podridao;
    for (const dia of [1, r.doisLados, 30]) {
      await p.fill("#candeia-dia", String(dia));
      await p.dispatchEvent("#candeia-dia", "input");
      const l = await p.evaluate(() => Object.fromEntries([...document.querySelectorAll("[data-l]")].map((e) => [e.dataset.l, e.textContent])));
      const raio = Math.min(r.raio.base + r.raio.porDia * dia, r.raio.teto);
      const massa = r.massa.base + r.massa.porDia * dia;
      resultado(`dia ${dia}: raio ${raio} e massa ${massa}, pelo rot.csv`, Number(l.raio) === raio && Number(l.massa.replace(/\s/g, "")) === massa, JSON.stringify(l));
      resultado(`dia ${dia}: chega por ${dia >= r.doisLados ? "dois lados" : "um lado"}`, l.lados === (dia >= r.doisLados ? TEXTOS.pt.noite.inst_dois : TEXTOS.pt.noite.inst_um), l.lados);
    }
    await ctx.close();
  }

  console.log("\n19 · orçamento");
  {
    const { ctx, p, pedidos } = await nova(b, base, 1440, "light");
    await p.goto(base + "/", { waitUntil: "load" });
    await revelar(p);
    await p.waitForTimeout(800);
    const tamanho = (u) => {
      const c = new URL(u).pathname;
      const f = join(SITE, c.endsWith("/") ? join(c, "index.html") : c);
      return existsSync(f) ? statSync(f).size : 0;
    };
    const unicos = [...new Set(pedidos.filter((u) => u.startsWith(base) && !u.includes("/jogar/")))];
    const total = unicos.reduce((n, u) => n + tamanho(u), 0) / 1024;
    const criticos = await p.evaluate(() => [location.href,
      ...[...document.querySelectorAll('link[rel="stylesheet"], link[rel="preload"], script[src]')].map((e) => e.href || e.src)]);
    const critico = [...new Set(criticos)].reduce((n, u) => n + tamanho(u), 0) / 1024;
    resultado(`caminho crítico ≤ ${CRITICO_KB} KB (${critico.toFixed(0)} KB)`, critico <= CRITICO_KB);
    resultado(`a página inteira ≤ ${TOTAL_KB} KB (${total.toFixed(0)} KB, ${unicos.length} pedidos)`, total <= TOTAL_KB);
    await ctx.close();
  }

  await b.close();
  srv.close();
  console.log(falhas ? `\nverificar_site: ${falhas} falha(s)` : "\nverificar_site: tudo passa");
  process.exit(falhas ? 1 : 0);
}

await main();
