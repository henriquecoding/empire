#!/usr/bin/env node
// tools/web/verificar_site.mjs — o site medido, não sentido (ADR 0024).
//
// A disciplina é a do Recibo Certo (scripts/verificar-movel.mjs e os
// auditar-*.mjs de lá): uma regra que só se verifica olhando para o ecrã certo
// não é uma regra, é uma intenção. Isto corre contra o ARTEFACTO — build/site,
// servido por um servidor estático aqui dentro — e não contra o código.
//
// O que mede, e porque cada coisa falha em silêncio:
//   1 · ROLAGEM LATERAL a 320, 360, 768 e 1440 px, nos dois temas.
//   2 · TRANSBORDO — algo visível a sair pela direita do ecrã.
//   3 · PISO TIPOGRÁFICO — texto visível abaixo de 12 px.
//   4 · ALVOS — o que se toca abaixo de 36 px (as ligações no meio de uma
//       frase estão isentas: é a excepção «inline» da WCAG 2.5.8).
//   5 · AXE — WCAG 2.0/2.1 A e AA, nos dois temas, estreito e largo.
//   6 · LIGAÇÕES — cada href e src interno responde 200; cada âncora existe.
//   7 · SEO — título, descrição, h1 único, lang, robots, og:image que existe.
//   8 · TECLADO — o primeiro Tab é o «saltar para o conteúdo», e ele leva lá;
//       o botão do tema funciona com Enter e a escolha sobrevive a recarregar.
//   9 · SEM CLARÃO — um tema guardado está aplicado antes do primeiro pixel.
//  10 · MOVIMENTO REDUZIDO — nada fica escondido à espera de uma animação.
//  11 · O JOGO — /jogar/ carrega, o ecrã de carregamento sai e o canvas fica.
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

const RAIZ = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
const SITE = resolve(process.argv[2] || join(RAIZ, "build", "site"));
const exigir = createRequire(join(RAIZ, "ferramentas", "LEIA-ME.md"));
// Os dois sao CommonJS: vistos de um modulo ES, o que exportam vem em `default`.
const pw = await import(pathToFileURL(exigir.resolve("playwright")));
const chromium = pw.chromium ?? pw.default.chromium;
const axe = await import(pathToFileURL(exigir.resolve("@axe-core/playwright")));
const AxeBuilder = axe.AxeBuilder ?? axe.default?.AxeBuilder ?? axe.default?.default ?? axe.default;

const LARGURAS = [320, 360, 768, 1440];
const TEMAS = ["light", "dark"];
const PISO_PX = 12;
const ALVO_PX = 36;
const JOGO_S = 90;
const TIPOS = {
  ".html": "text/html; charset=utf-8", ".js": "text/javascript", ".wasm": "application/wasm",
  ".pck": "application/octet-stream", ".png": "image/png", ".webp": "image/webp",
  ".svg": "image/svg+xml", ".json": "application/json", ".txt": "text/plain", ".xml": "application/xml",
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
    if (r.right > W + 1 && !el.closest(".salto")) saida.transbordo.push(`${nome(el)} (${Math.round(r.right)} > ${W})`);
    const temTexto = [...el.childNodes].some((n) => n.nodeType === 3 && n.textContent.trim());
    if (temTexto && parseFloat(getComputedStyle(el).fontSize) < piso) {
      saida.piso.push(`${nome(el)} (${getComputedStyle(el).fontSize})`);
    }
    if (el.matches("a[href], button, [role='button'], input, select, textarea") && !el.closest(".salto")) {
      const inline = getComputedStyle(el).display === "inline";
      if (!inline && (r.width < alvo || r.height < alvo)) {
        saida.alvos.push(`${nome(el)} ${Math.round(r.width)}×${Math.round(r.height)}`);
      }
    }
  }
  return saida;
};

async function nova(b, base, largura, tema, extra = {}) {
  const ctx = await b.newContext({ viewport: { width: largura, height: 900 }, colorScheme: tema, ...extra });
  const p = await ctx.newPage();
  const erros = [];
  p.on("pageerror", (e) => erros.push(e.message));
  p.on("console", (m) => {
    // As fontes vêm de fora; uma rede sem elas não é um defeito do site.
    if (m.type() === "error" && !/fonts\.g|ERR_CERT|ERR_NAME|ERR_INTERNET/.test(m.text() + (m.location()?.url || ""))) {
      erros.push(m.text());
    }
  });
  return { ctx, p, erros };
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
  const srv = await servir();
  const base = `http://127.0.0.1:${srv.address().port}`;
  const b = await chromium.launch({
    executablePath: process.env.PLAYWRIGHT_CHROMIUM || (existsSync("/opt/pw-browsers/chromium") ? "/opt/pw-browsers/chromium" : undefined),
    args: ["--use-gl=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"],
  });

  console.log("\n1–4 · telemóvel primeiro: rolagem, transbordo, piso e alvos");
  for (const tema of TEMAS) {
    for (const w of LARGURAS) {
      const { ctx, p, erros } = await nova(b, base, w, tema);
      await p.goto(base + "/", { waitUntil: "load" });
      await revelar(p);
      const lateral = await p.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
      const d = await p.evaluate(SONDA, { piso: PISO_PX, alvo: ALVO_PX });
      const rot = `${w}px · ${tema === "light" ? "claro" : "escuro"}`;
      resultado(`${rot}: sem rolagem lateral`, lateral <= 0, `${lateral}px a mais`);
      resultado(`${rot}: nada sai do ecrã`, d.transbordo.length === 0, d.transbordo.slice(0, 4).join(", "));
      resultado(`${rot}: texto ≥ ${PISO_PX}px`, d.piso.length === 0, d.piso.slice(0, 4).join(", "));
      resultado(`${rot}: alvos ≥ ${ALVO_PX}px`, d.alvos.length === 0, d.alvos.slice(0, 4).join(", "));
      resultado(`${rot}: sem erros de JavaScript`, erros.length === 0, erros.slice(0, 2).join(" | "));
      await ctx.close();
    }
  }

  console.log("\n5 · axe (WCAG 2.1 A e AA)");
  for (const tema of TEMAS) {
    for (const w of [360, 1440]) {
      for (const rota of ["/", "/404.html"]) {
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
  {
    const { ctx, p } = await nova(b, base, 1440, "dark");
    await p.goto(base + "/", { waitUntil: "load" });
    const refs = await p.evaluate(() => ({
      hrefs: [...document.querySelectorAll("a[href]")].map((a) => a.getAttribute("href")),
      srcs: [...document.querySelectorAll("[src], link[rel~='icon'][href], link[rel='prefetch'][href]")]
        .map((e) => e.getAttribute("src") || e.getAttribute("href")),
      ids: [...document.querySelectorAll("[id]")].map((e) => e.id),
    }));
    const internos = [...new Set([...refs.hrefs, ...refs.srcs])].filter((h) => h && h.startsWith("/"));
    for (const h of internos) {
      const r = await fetch(base + h, { redirect: "follow" });
      resultado(`${h} responde`, r.status === 200, `HTTP ${r.status}`);
    }
    for (const h of refs.hrefs.filter((x) => x.startsWith("#"))) {
      resultado(`âncora ${h} existe`, refs.ids.includes(h.slice(1)));
    }
    for (const rota of ["/jogar", "/dossie"]) {
      const r = await fetch(base + rota, { redirect: "manual" });
      resultado(`${rota} leva a ${rota}/`, r.status === 308 && r.headers.get("location") === rota + "/", `HTTP ${r.status}`);
    }
    const nada = await fetch(base + "/nao-existe");
    resultado("uma página que não existe dá 404", nada.status === 404, `HTTP ${nada.status}`);
    await ctx.close();
  }

  console.log("\n7 · SEO");
  {
    const html = readFileSync(join(SITE, "index.html"), "utf8");
    const meta = (n) => html.match(new RegExp(`<meta (?:name|property)="${n}" content="([^"]*)"`))?.[1];
    resultado("sem marcadores por preencher", !/\{\{[A-Z0-9_]+\}\}/.test(html));
    resultado("<html lang=\"pt-PT\">", /<html lang="pt-PT">/.test(html));
    const titulo = html.match(/<title>([^<]+)<\/title>/)?.[1] || "";
    resultado(`título com 10–65 caracteres («${titulo}»)`, titulo.length >= 10 && titulo.length <= 65);
    const desc = meta("description") || "";
    resultado(`descrição com 70–170 caracteres (${desc.length})`, desc.length >= 70 && desc.length <= 170);
    resultado("um só <h1>", (html.match(/<h1[\s>]/g) || []).length === 1);
    resultado("meta robots", !!meta("robots"));
    const og = meta("og:image") || "";
    const ogLocal = og.replace(/^https?:\/\/[^/]+/, "");
    resultado(`og:image existe (${ogLocal})`, !!ogLocal && existsSync(join(SITE, ogLocal)));
    resultado("robots.txt", existsSync(join(SITE, "robots.txt")));
    resultado("versao.json com o commit", /"commit": "[0-9a-f]{7,40}"/.test(readFileSync(join(SITE, "versao.json"), "utf8")));
  }

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
    await ctx.close();
  }

  console.log("\n11 · o jogo");
  {
    const { ctx, p, erros } = await nova(b, base, 1280, "dark");
    await p.goto(base + "/jogar/", { waitUntil: "load" });
    const saiu = await p.waitForFunction(() => !document.getElementById("status"), null, { timeout: JOGO_S * 1000 })
      .then(() => true, () => false);
    resultado(`o carregamento acaba em menos de ${JOGO_S} s`, saiu);
    const canvas = await p.evaluate(() => { const c = document.getElementById("canvas"); return c ? [c.width, c.height] : [0, 0]; });
    resultado("o canvas tem tamanho", canvas[0] > 0 && canvas[1] > 0, canvas.join("×"));
    resultado("sem erros de JavaScript", erros.length === 0, erros.slice(0, 2).join(" | "));
    await ctx.close();
  }

  await b.close();
  srv.close();
  console.log(falhas ? `\nverificar_site: ${falhas} falha(s)` : "\nverificar_site: tudo passa");
  process.exit(falhas ? 1 : 0);
}

await main();
