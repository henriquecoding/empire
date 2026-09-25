// tools/web/pagina.mjs — o site, montado a partir do repositório (ADR 0024, ADR 0025).
//
// Corre no fim do construir.sh, depois do export do jogo e do dossiê, e escreve
// em build/site/:
//
//   /index.html · /en/index.html   a página de entrada, uma por língua
//   /404.html                      o «fora do mapa», nas duas
//   /assets/*.<hash>.{css,js}      a folha e os scripts, com o conteúdo no nome —
//                                  por isso servem-se com cache imutável
//   /robots.txt · /sitemap.xml     abertos só na produção (VERCEL_ENV)
//   /site.webmanifest              o nome, as cores e os ícones
//   /versao.json                   o commit que está publicado
//
// e passa o dossiê construído a usar as fontes do site em vez das da Google.
//
// Tudo o que a página diz e que o repositório sabe vem de tools/web/dados.mjs.
// A construção chumba — e a Vercel não publica — se faltar um dado, se as duas
// línguas não tiverem a mesma forma, se a tradução de uma tabela do dossiê
// estiver atrasada em relação ao dossiê, ou se sobrar um {marcador} por
// preencher: uma página com um buraco é pior do que nenhuma.
//
//   node tools/web/pagina.mjs build/site

import { readFileSync, writeFileSync, statSync, cpSync, existsSync, mkdirSync, rmSync } from "node:fs";
import { join, resolve, dirname } from "node:path";
import { createHash } from "node:crypto";
import zlib, { brotliCompressSync } from "node:zlib";
import { fileURLToPath } from "node:url";
import { ler } from "./dados.mjs";
import { TEXTOS, conferirParidade } from "./paginas/textos.mjs";
import { entrada, erro, cssDosDados, controlosCasca } from "./paginas/molde.mjs";

const RAIZ = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
const SITE = join(RAIZ, "tools", "web", "site");
const PAGINAS = join(RAIZ, "tools", "web", "paginas");

const hash = (s) => createHash("sha256").update(s).digest("hex").slice(0, 10);

// O que o browser descarrega de facto: a Vercel serve o .wasm, o .pck e o .js
// com brotli, e o .wasm de 36 MB chega com 9 (medido; a qualidade 4 é a que
// mais se aproxima do que ela serve). Dizer o tamanho em disco era assustar
// quem vai jogar com um número quatro vezes maior do que o real.
function megas(saida) {
  let n = 0;
  for (const f of ["index.wasm", "index.pck", "index.js"]) {
    const p = join(saida, "jogar", f);
    if (!existsSync(p)) continue;
    n += brotliCompressSync(readFileSync(p), {
      params: { [zlib.constants.BROTLI_PARAM_QUALITY]: 4, [zlib.constants.BROTLI_PARAM_SIZE_HINT]: statSync(p).size },
    }).length;
  }
  return Math.max(1, Math.ceil(n / 1048576));
}

/** Uma impressão curta de uma linha do dossiê: muda quando o português muda. */
export const impressao = (linha) => hash(JSON.stringify(linha)).slice(0, 8);

// As três tabelas do dossiê que o site mostra têm o português lido do dossiê
// e o inglês escrito à mão, linha a linha. Cada linha inglesa guarda a
// impressão da portuguesa de onde foi traduzida: se o dossiê mudar a linha,
// a impressão deixa de bater e a construção diz qual é, e o que diz agora.
function conferirTraducoes(d) {
  const en = TEXTOS.en;
  const erros = [];
  const conferir = (onde, chave, pt, trad) => {
    if (!trad) return erros.push(`${onde}.${chave}: falta a tradução inglesa de ${JSON.stringify(pt)}`);
    const esperada = impressao(pt);
    if (!trad.pt) erros.push(`${onde}.${chave}: a tradução não diz de que linha é — põe-lhe pt: "${esperada}", depois de a conferir com ${JSON.stringify(pt)}`);
    else if (trad.pt !== esperada) {
      erros.push(`${onde}.${chave}: a linha portuguesa mudou (era ${trad.pt}, agora é ${esperada}) — revê a tradução contra ${JSON.stringify(pt)}`);
    }
  };
  for (const f of d.relogio.fases) conferir("dia.fases", f.id, { nome: f.nome, funcao: f.funcao, tropas: f.tropas }, en.dia.fases[f.id]);
  for (const p of d.povos.linhas) {
    const { id, hoje, ...pt } = p;
    conferir("povos.linhas", id, pt, en.povos.linhas[id]);
  }
  for (const r of d.roteiro) conferir("estado.fases", r.n, { nome: r.nome, meses: r.meses, feito: r.feito, criterio: r.criterio }, en.estado.fases[r.n]);
  for (const [onde, lista, dados] of [["dia.fases", en.dia.fases, d.relogio.fases.map((f) => f.id)], ["povos.linhas", en.povos.linhas, d.povos.linhas.map((p) => p.id)], ["estado.fases", en.estado.fases, d.roteiro.map((r) => String(r.n))]]) {
    for (const k of Object.keys(lista)) if (!dados.includes(k)) erros.push(`${onde}.${k}: tradução de uma linha que o dossiê já não tem`);
  }
  return erros;
}

/** A folha: as fontes, o estilo e os dados, sem comentários nem espaço a mais. */
function minificarCss(css) {
  return css.replace(/\/\*[\s\S]*?\*\//g, "").replace(/\s+/g, " ").replace(/\s*([{}:;,>])\s*/g, "$1").replace(/;}/g, "}").trim();
}

function escreverAssets(saida, d) {
  const dir = join(saida, "assets");
  mkdirSync(dir, { recursive: true });
  const css = minificarCss([
    readFileSync(join(SITE, "fontes", "fontes.css"), "utf8"),
    readFileSync(join(PAGINAS, "estilo.css"), "utf8"),
    cssDosDados(d),
  ].join("\n"));
  const saidas = {};
  for (const [nome, ext, texto] of [
    ["estilo", "css", css],
    ["tema", "js", readFileSync(join(PAGINAS, "tema.js"), "utf8")],
    ["site", "js", readFileSync(join(PAGINAS, "site.js"), "utf8")],
  ]) {
    const f = `${nome}.${hash(texto)}.${ext}`;
    writeFileSync(join(dir, f), texto);
    saidas[nome] = `/assets/${f}`;
  }
  return { css: saidas.estilo, tema: saidas.tema, js: saidas.site };
}

function preencherOuChumbar(nome, html) {
  const resto = html.match(/\{[a-z_0-9]+\}/g);
  if (resto) throw new Error(`pagina: ${nome} tem marcadores por preencher: ${[...new Set(resto)].join(", ")}`);
  return html;
}

// O dossiê pedia as fontes à Google; no site servem-se daqui, como as do resto.
function dossieSemTerceiros(saida) {
  const f = join(saida, "dossie", "index.html");
  if (!existsSync(f)) return;
  const antes = readFileSync(f, "utf8");
  const depois = antes
    .replace(/<link rel="preconnect" href="https:\/\/fonts\.(gstatic|googleapis)\.com"[^>]*>\n?/g, "")
    .replace(/<link rel="stylesheet" href="https:\/\/fonts\.googleapis\.com\/css2\?[^"]*">/, '<link rel="stylesheet" href="/fontes/fontes.css">');
  if (/fonts\.(googleapis|gstatic)\.com/.test(depois)) throw new Error("pagina: o dossiê continua a pedir fontes à Google");
  writeFileSync(f, depois);
}

// A casca exportada pelo Godot (tools/web/shell.html) arranca sozinha — é o
// artefacto `empire-web` do CI, e tem de servir de um servidor qualquer. O que
// só o site sabe entra aqui, depois do export: os controlos lidos do
// project.godot, o robots do ambiente, e uma CSP estrita. Os blocos em linha
// da casca (a língua, o estilo, o arranque do motor com o GODOT_CONFIG) entram
// na CSP pelo hash, e mais nenhum: um script que alguém lá meta sem passar por
// aqui não corre.
const CSP_JOGO = (scripts, estilos) => [
  "default-src 'self'", `script-src 'self' 'wasm-unsafe-eval' ${scripts}`, `style-src 'self' ${estilos}`,
  "img-src 'self' data: blob:", "font-src 'self'", "connect-src 'self'", "media-src 'self' blob:", "worker-src 'self' blob:",
  "object-src 'none'", "base-uri 'self'", "form-action 'none'",
].join("; ");

function completarCasca(saida, d, robots) {
  const f = join(saida, "jogar", "index.html");
  let html = readFileSync(f, "utf8");
  // Já completada (uma segunda corrida sobre o mesmo build): não há nada a fazer.
  if (!html.includes("<!--EMPIRE:") && html.includes("Content-Security-Policy")) return;
  for (const m of ["<!--EMPIRE:CSP-->", "<!--EMPIRE:ROBOTS-->", "<!--EMPIRE:CONTROLOS-->"]) {
    if (!html.includes(m)) throw new Error(`pagina: a casca exportada não tem ${m} — o export usou a tools/web/shell.html?`);
  }
  html = html
    .replace("<!--EMPIRE:ROBOTS-->", `<meta name="robots" content="${robots}">`)
    .replace("<!--EMPIRE:CONTROLOS-->", controlosCasca({ textos: TEXTOS, d }));
  const b64 = (x) => `'sha256-${createHash("sha256").update(x).digest("base64")}'`;
  const scripts = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].map((m) => b64(m[1]));
  const estilos = [...html.matchAll(/<style>([\s\S]*?)<\/style>/g)].map((m) => b64(m[1]));
  if (scripts.length < 2 || !estilos.length) throw new Error("pagina: a casca exportada não tem os blocos em linha que se esperavam");
  html = html.replace("<!--EMPIRE:CSP-->", `<meta http-equiv="Content-Security-Policy" content="${CSP_JOGO(scripts.join(" "), estilos.join(" "))}">`);
  writeFileSync(f, html);
}

function main() {
  const saida = resolve(process.argv[2] || join(RAIZ, "build", "site"));
  const d = ler(RAIZ);
  const erros = [...conferirParidade(TEXTOS.pt, TEXTOS.en), ...conferirTraducoes(d)];
  if (erros.length) throw new Error(`pagina: as duas línguas não batem certo:\n  ${erros.join("\n  ")}`);

  // O site/ é o que se serve tal e qual; o 404 e as páginas saem do molde.
  cpSync(SITE, saida, { recursive: true, filter: (f) => !f.endsWith(".gdignore") && !f.endsWith("capturas.json") });
  rmSync(join(saida, "index.html"), { force: true });
  const assets = escreverAssets(saida, d);
  const url = d.url;
  const robots = d.producao ? "index, follow" : "noindex, nofollow";
  const mb = megas(saida);

  for (const [lingua, t] of Object.entries(TEXTOS)) {
    const v = { ...assets, jogar: lingua === "pt" ? "/jogar/" : "/jogar/?lingua=en" };
    const dir = join(saida, t.caminho);
    mkdirSync(dir, { recursive: true });
    writeFileSync(join(dir, "index.html"), preencherOuChumbar(`${t.caminho}index.html`, entrada({ t, d, v, mb, url, robots })));
  }
  writeFileSync(join(saida, "404.html"), preencherOuChumbar("404.html", erro({ textos: TEXTOS, d, v: { ...assets, jogar: "/jogar/" } })));
  dossieSemTerceiros(saida);
  if (existsSync(join(saida, "jogar", "index.html"))) completarCasca(saida, d, robots);

  // robots.txt e sitemap.xml: na produção abre-se tudo e diz-se onde está o
  // mapa; numa pré-visualização fecha-se tudo.
  writeFileSync(join(saida, "robots.txt"), d.producao
    ? `User-agent: *\nAllow: /\n${url ? `Sitemap: ${url}/sitemap.xml\n` : ""}`
    : "User-agent: *\nDisallow: /\n");
  if (url) {
    const hoje = d.agora.toISOString().slice(0, 10);
    const alt = `<xhtml:link rel="alternate" hreflang="pt-PT" href="${url}/"/><xhtml:link rel="alternate" hreflang="en" href="${url}/en/"/>`;
    const urls = [["/", alt], ["/en/", alt], ["/jogar/", ""], ["/dossie/", ""]]
      .map(([c, a]) => `  <url><loc>${url}${c}</loc><lastmod>${hoje}</lastmod>${a}</url>`).join("\n");
    writeFileSync(join(saida, "sitemap.xml"), `<?xml version="1.0" encoding="UTF-8"?>\n`
      + `<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">\n${urls}\n</urlset>\n`);
  }
  writeFileSync(join(saida, "site.webmanifest"), JSON.stringify({
    name: "Empire", short_name: "Empire", description: TEXTOS.pt.meta.descricao, lang: "pt-PT",
    start_url: "/", display: "standalone", background_color: "#15120c", theme_color: "#15120c",
    icons: [
      { src: "/icone-192.png", sizes: "192x192", type: "image/png" },
      { src: "/icone-512.png", sizes: "512x512", type: "image/png", purpose: "any maskable" },
      { src: "/favicon.svg", sizes: "any", type: "image/svg+xml" },
    ],
  }, null, 2) + "\n");
  // Para quem quiser saber o que está publicado sem abrir a página.
  writeFileSync(join(saida, "versao.json"), JSON.stringify({
    commit: d.sha, ramo: d.ramo, ambiente: d.ambiente, godot: d.godot, publicado: d.agora.toISOString(),
    capturas: d.capturas.commit,
  }, null, 2) + "\n");
  console.log(`pagina: / e /en/ · commit ${d.sha.slice(0, 7)} · ${d.tickets.feitos}/${d.tickets.total} tickets · ${d.contas.testes} testes · jogo ${mb} MB`);
}

if (import.meta.url === `file://${process.argv[1]}`) main();
