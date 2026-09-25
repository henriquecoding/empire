#!/usr/bin/env node
// tools/web/fumo.mjs — o site publicado responde como deve (ADR 0024).
//
// O verificar_site.mjs mede o artefacto antes de sair; isto mede o que a Vercel
// está de facto a servir, com os cabeçalhos do vercel.json e a compressão dela.
// É o smoke-production.mjs do Recibo Certo, para um site estático: pede, e
// exige. Não precisa de browser nem de dependências.
//
//   node tools/web/fumo.mjs https://empire-….vercel.app [commit-esperado]
//
// Código de saída: 0 = passa · 1 = pelo menos uma falha.

const [base0, esperado] = process.argv.slice(2);
if (!base0) {
  console.error("uso: node tools/web/fumo.mjs <url> [commit]");
  process.exit(2);
}
const base = base0.replace(/\/$/, "");
let falhas = 0;
const exigir = (nome, ok, detalhe = "") => {
  console.log(`  ${ok ? "✓" : "✗"} ${nome}${ok || !detalhe ? "" : ` — ${detalhe}`}`);
  if (!ok) falhas++;
};
const pedir = (caminho, init = {}) =>
  fetch(base + caminho, { redirect: "manual", signal: AbortSignal.timeout(30_000), ...init });

const SEGURANCA = [
  "strict-transport-security", "x-content-type-options", "x-frame-options",
  "referrer-policy", "content-security-policy", "permissions-policy",
];

console.log(`fumo: ${base}`);

const raiz = await pedir("/");
exigir("/ responde 200", raiz.status === 200, `HTTP ${raiz.status}`);
const html = await raiz.text();
exigir("/ é a página do Empire", html.includes("Cada império é uma"));
exigir("/ sem marcadores por preencher", !/\{[a-z_0-9]+\}/.test(html));
exigir("/ não pede nada à Google (as fontes são daqui)", !/fonts\.(googleapis|gstatic)\.com/.test(html));
for (const h of SEGURANCA) exigir(`cabeçalho ${h}`, raiz.headers.has(h));

const ingles = await pedir("/en/");
exigir("/en/ responde 200", ingles.status === 200, `HTTP ${ingles.status}`);
exigir("/en/ é a página inglesa", (await ingles.text()).includes("Every empire is a"));

// A folha e os scripts têm o conteúdo no nome, e por isso servem-se para
// sempre; as fontes são do próprio site e chegam como font/woff2.
const css = html.match(/href="(\/assets\/estilo\.[0-9a-f]+\.css)"/)?.[1];
exigir("/ liga a uma folha com hash", !!css);
if (css) {
  const r = await pedir(css);
  exigir(`${css} responde 200`, r.status === 200, `HTTP ${r.status}`);
  exigir(`${css} tem cache imutável`, /immutable/.test(r.headers.get("cache-control") || ""), r.headers.get("cache-control") || "sem cache-control");
}
const fonte = await pedir("/fontes/fraunces-400-900-latin.woff2", { method: "HEAD" });
exigir("as fontes servem-se daqui, como font/woff2", fonte.status === 200 && /woff2/.test(fonte.headers.get("content-type") || ""),
  `HTTP ${fonte.status} ${fonte.headers.get("content-type")}`);

for (const [rota, texto] of [["/jogar/", "new Engine("], ["/dossie/", "<html"]]) {
  const r = await pedir(rota);
  exigir(`${rota} responde 200`, r.status === 200, `HTTP ${r.status}`);
  const corpo = await r.text();
  exigir(`${rota} tem o que devia`, corpo.includes(texto));
  exigir(`${rota} não pede nada à Google`, !/fonts\.(googleapis|gstatic)\.com/.test(corpo));
  if (rota === "/jogar/") exigir("/jogar/ tem a CSP com o hash dos blocos em linha", /script-src 'self' 'wasm-unsafe-eval' 'sha256-/.test(corpo));
}

const wasm = await pedir("/jogar/index.wasm", { headers: { "Accept-Encoding": "br, gzip" } });
exigir("index.wasm responde 200", wasm.status === 200, `HTTP ${wasm.status}`);
exigir("index.wasm é application/wasm", (wasm.headers.get("content-type") || "").includes("application/wasm"),
  wasm.headers.get("content-type") || "sem tipo");
const comp = wasm.headers.get("content-encoding") || "nenhuma";
console.log(`    (compressão do .wasm: ${comp}; ${wasm.headers.get("content-length") || "?"} bytes na rede)`);
await wasm.body?.cancel();

const pck = await pedir("/jogar/index.pck", { method: "HEAD" });
exigir("index.pck responde 200", pck.status === 200, `HTTP ${pck.status}`);

const sem = await pedir("/jogar");
exigir("/jogar leva a /jogar/", [301, 307, 308].includes(sem.status) && (sem.headers.get("location") || "").endsWith("/jogar/"),
  `HTTP ${sem.status} → ${sem.headers.get("location")}`);

const nada = await pedir("/nao-existe-de-certeza/");
exigir("uma página que não existe dá 404", nada.status === 404, `HTTP ${nada.status}`);
exigir("e o 404 é o do Empire", /fora do mapa/i.test(await nada.text()));

const v = await pedir("/versao.json");
exigir("/versao.json responde 200", v.status === 200, `HTTP ${v.status}`);
if (v.status === 200) {
  const versao = await v.json();
  console.log(`    (publicado: ${versao.commit?.slice(0, 7)} · ${versao.ramo} · ${versao.ambiente} · ${versao.publicado})`);
  if (esperado) exigir(`o commit publicado é ${esperado.slice(0, 7)}`, versao.commit?.startsWith(esperado));
}

const robots = await pedir("/robots.txt");
exigir("/robots.txt responde 200", robots.status === 200, `HTTP ${robots.status}`);

console.log(falhas ? `\nfumo: ${falhas} falha(s)` : "\nfumo: tudo passa");
process.exit(falhas ? 1 : 0);
