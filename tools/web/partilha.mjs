#!/usr/bin/env node
// tools/web/partilha.mjs — a imagem de partilha e os ícones, compostos das capturas (ADR 0025).
//
// A imagem que aparece quando alguém cola o endereço numa conversa era um
// recorte de 1200×630 do ecrã com os instrumentos cortados a meio: «EMPIRE»
// sem o E, «DAY 01 · MORNING» sem a linha de cima. É o primeiro contacto que
// muita gente tem com o jogo, e dizia «captura mal cortada».
//
// Agora compõe-se num Chromium, com as fontes do site e as capturas que o
// tools/web/capturas.py tirou do jogo — a noite com a candeia a chegar ao
// castelo-árvore, que é o argumento visual do §36. Uma por língua. E os ícones
// PNG (180, 192, 512) saem do mesmo favicon.svg, para que haja um desenho só.
//
//   node tools/web/partilha.mjs        # ou: make site-capturas, que corre as duas
//
// Precisa do Playwright em ferramentas/node_modules. Corre-se à mão, e o que
// sai fica versionado: a Vercel não tem browser.

import { readFileSync, existsSync } from "node:fs";
import { join, resolve, dirname } from "node:path";
import { createRequire } from "node:module";
import { pathToFileURL, fileURLToPath } from "node:url";

const RAIZ = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
const SITE = join(RAIZ, "tools", "web", "site");
const exigir = createRequire(join(RAIZ, "ferramentas", "LEIA-ME.md"));
const pw = await import(pathToFileURL(exigir.resolve("playwright")));
const chromium = pw.chromium ?? pw.default.chromium;

const TEXTOS = {
  pt: { lema: "Cada império é uma civilização.", sub: "Kingdom-builder em pixel art · joga-se no browser", tag: "Nome de trabalho" },
  en: { lema: "Every empire is a civilization.", sub: "Pixel-art kingdom builder · play it in your browser", tag: "Working title" },
};

const dados = (f, tipo) => `data:${tipo};base64,${readFileSync(f).toString("base64")}`;

function fontes() {
  // As mesmas faces do site, embebidas: a página de composição não tem servidor.
  const css = readFileSync(join(SITE, "fontes", "fontes.css"), "utf8");
  return css.replace(/url\(\/fontes\/([^)]+)\)/g, (_, f) => `url(${dados(join(SITE, "fontes", f), "font/woff2")})`);
}

// A candeia entra por um lado ou pelo outro, conforme a partida (o capturas.py
// guarda onde ficou). O texto vai para o lado contrário: debaixo do véu do
// texto, a candeia — que é o assunto da imagem — não se via.
function lado() {
  const f = JSON.parse(readFileSync(join(SITE, "img", "capturas.json"), "utf8")).quadros.noite.foco;
  return f < 0.5 ? "direita" : "esquerda";
}

function cartaz(t) {
  const noite = dados(join(SITE, "img", "dia-noite.webp"), "image/webp");
  const direita = lado() === "direita";
  const icone = dados(join(SITE, "favicon.svg"), "image/svg+xml");
  return `<!DOCTYPE html><html><head><meta charset="utf-8"><style>${fontes()}
  html,body{margin:0;width:1200px;height:630px;overflow:hidden;background:#15120c}
  .quadro{position:absolute;inset:0;background:url(${noite}) center 38%/cover no-repeat;image-rendering:pixelated}
  .veu{position:absolute;inset:0;background:linear-gradient(${direita ? "270deg" : "90deg"},#15120cf2 0%,#15120cd9 34%,#15120c40 62%,transparent 80%),
    linear-gradient(0deg,#15120ccc 0%,transparent 30%)}
  .texto{position:absolute;${direita ? "right" : "left"}:72px;top:0;bottom:0;display:flex;flex-direction:column;justify-content:center;width:640px}
  .marca{display:flex;align-items:center;gap:18px;font-family:Silkscreen;font-size:34px;letter-spacing:.16em;color:#efeada}
  .marca img{width:44px;height:44px;image-rendering:pixelated}
  h1{font-family:Fraunces;font-variation-settings:'SOFT' 0,'WONK' 1,'opsz' 144;font-weight:620;font-size:64px;line-height:1.02;max-width:560px;
    letter-spacing:-.02em;color:#efeada;margin:34px 0 22px}
  p{font-family:'IBM Plex Mono';font-size:20px;color:#c7c1aa;margin:0}
  .tag{position:absolute;right:40px;bottom:32px;font-family:Silkscreen;font-size:16px;letter-spacing:.14em;color:#e9a54a;text-transform:uppercase}
  .solo{position:absolute;left:0;right:0;bottom:0;height:6px;background:linear-gradient(90deg,#6b4a29,#e9a54a 50%,#6b4a29)}
  </style></head><body><div class="quadro"></div><div class="veu"></div>
  <div class="texto"><div class="marca"><img src="${icone}" alt="">EMPIRE</div><h1>${t.lema}</h1><p>${t.sub}</p></div>
  <div class="tag">${t.tag}</div><div class="solo"></div></body></html>`;
}

async function main() {
  if (!existsSync(join(SITE, "img", "dia-noite.webp"))) {
    console.error("partilha: falta img/dia-noite.webp — corre primeiro tools/web/capturas.py");
    process.exit(2);
  }
  const b = await chromium.launch({
    executablePath: process.env.PLAYWRIGHT_CHROMIUM || (existsSync("/opt/pw-browsers/chromium") ? "/opt/pw-browsers/chromium" : undefined),
  });
  const p = await b.newPage({ viewport: { width: 1200, height: 630 } });
  for (const [lingua, t] of Object.entries(TEXTOS)) {
    await p.setContent(cartaz(t), { waitUntil: "load" });
    await p.evaluate(() => document.fonts.ready);
    const f = join(SITE, "img", `partilha-${lingua}.png`);
    await p.screenshot({ path: f });
    console.log(`partilha: ${f}`);
  }
  // Os ícones: o favicon.svg, a 180 (Apple), 192 e 512 (manifesto). O de 512
  // leva margem, para o recorte redondo dos ícones «maskable» não comer o solo.
  const svg = readFileSync(join(SITE, "favicon.svg"), "utf8");
  for (const [lado, nome, margem] of [[180, "icone-180.png", 0], [192, "icone-192.png", 0], [512, "icone-512.png", 0.12]]) {
    await p.setViewportSize({ width: lado, height: lado });
    const dentro = Math.round(lado * (1 - 2 * margem));
    await p.setContent(`<body style="margin:0;background:#15120c;display:grid;place-items:center;width:${lado}px;height:${lado}px">`
      + `<div style="width:${dentro}px;height:${dentro}px">${svg.replace("<svg ", `<svg width="${dentro}" height="${dentro}" `)}</div></body>`);
    await p.screenshot({ path: join(SITE, nome) });
    console.log(`partilha: ${nome}`);
  }
  await b.close();
}

await main();
