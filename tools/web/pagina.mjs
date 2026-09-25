// tools/web/pagina.mjs — a página de entrada, com os números contados agora.
//
// A regra do AGENTS.md vale aqui como no README: nenhum número que uma
// ferramenta conta se escreve à mão. Os tickets saem de docs/backlog/tickets.json,
// os testes, as ADRs e as secções de docs/recovery/validation.json, que o
// check_claims mantém certo contra a árvore. O commit e o endereço vêm das variáveis de
// sistema da Vercel, e do git quando se corre fora dela.
//
//   node tools/web/pagina.mjs build/site
//
// Chumba se sobrar um {{MARCADOR}} por preencher: uma página com chavetas à
// vista é pior do que nenhuma.

import { readFileSync, writeFileSync, statSync, cpSync, existsSync } from "node:fs";
import { join, resolve, dirname } from "node:path";
import { execSync } from "node:child_process";
import zlib, { brotliCompressSync } from "node:zlib";
import { fileURLToPath } from "node:url";

const RAIZ = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
const SITE = join(RAIZ, "tools", "web", "site");
const MOLDES = ["index.html"];

function git(cmd, omissao) {
  try {
    return execSync(`git ${cmd}`, { cwd: RAIZ, stdio: ["ignore", "pipe", "ignore"] }).toString().trim();
  } catch {
    return omissao;
  }
}

function repo() {
  const { VERCEL_GIT_REPO_OWNER: dono, VERCEL_GIT_REPO_SLUG: nome } = process.env;
  if (dono && nome) return `https://github.com/${dono}/${nome}`;
  const remoto = git("config --get remote.origin.url", "");
  const m = remoto.match(/github\.com[/:]([^/]+)\/([^/.]+?)(\.git)?$/) || remoto.match(/git\/([^/]+)\/([^/.]+)$/);
  return m ? `https://github.com/${m[1]}/${m[2]}` : "https://github.com/henriquecoding/empire";
}

function tickets() {
  const t = JSON.parse(readFileSync(join(RAIZ, "docs/backlog/tickets.json"), "utf8"));
  const estados = Object.values(t).map((x) => String(x.estado || "").trim().toLowerCase());
  const feitos = estados.filter((e) => e.startsWith("feito")).length;
  const parciais = estados.filter((e) => e.startsWith("parcial")).length;
  return { total: estados.length, feitos, parciais, faltam: estados.length - feitos - parciais };
}

function pct(n, total) {
  return total ? ((100 * n) / total).toFixed(2) : "0";
}

// O que o browser descarrega de facto: a Vercel serve o .wasm, o .pck e o .js
// com brotli, e o .wasm de 36 MB chega com 9 (medido; a qualidade 4 e a que
// mais se aproxima do que ela serve). Dizer o tamanho em disco era
// assustar quem vai jogar com um numero quatro vezes maior do que o real.
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

export function valores(saida) {
  const v = JSON.parse(readFileSync(join(RAIZ, "docs/recovery/validation.json"), "utf8"));
  const tk = tickets();
  const sha = process.env.VERCEL_GIT_COMMIT_SHA || git("rev-parse HEAD", "0000000");
  const dominio = process.env.VERCEL_PROJECT_PRODUCTION_URL || process.env.VERCEL_URL || "";
  const r = repo();
  // So a producao se indexa. Uma pre-visualizacao de um ramo e trabalho por
  // acabar, e um motor de busca que a guarde passa a servir o jogo errado.
  const producao = process.env.VERCEL_ENV === "production";
  const data = new Intl.DateTimeFormat("pt-PT", {
    day: "numeric", month: "long", year: "numeric", timeZone: "Europe/Lisbon",
  }).format(new Date());
  return {
    URL: dominio ? `https://${dominio}` : "",
    ROBOTS: producao ? "index, follow" : "noindex, nofollow",
    PRODUCAO: producao ? "1" : "",
    REPO: r,
    REPO_NOME: r.replace("https://github.com/", ""),
    SHA: sha,
    SHA7: sha.slice(0, 7),
    DATA: data,
    GODOT: readFileSync(join(RAIZ, ".godot-version"), "utf8").trim().replace("-stable", ""),
    MB: String(megas(saida)),
    TICKETS: String(tk.total),
    FEITOS: String(tk.feitos),
    PARCIAIS: String(tk.parciais),
    FALTAM: String(tk.faltam),
    PCT_FEITOS: pct(tk.feitos, tk.total),
    PCT_PARCIAIS: pct(tk.parciais, tk.total),
    TESTES: String(v.gdunit_discovered),
    // O validation.json e o que o check_claims mantem certo contra a arvore:
    // contar aqui outra vez era ter duas contas que um dia divergem.
    ADRS: String(v.adrs),
    SECCOES: String(v.spec_sections),
  };
}

export function preencher(texto, vals) {
  const saida = texto.replace(/\{\{([A-Z0-9_]+)\}\}/g, (tudo, k) => (k in vals ? vals[k] : tudo));
  const resto = saida.match(/\{\{[A-Z0-9_]+\}\}/g);
  if (resto) throw new Error(`pagina: marcadores por preencher: ${[...new Set(resto)].join(", ")}`);
  return saida;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const saida = resolve(process.argv[2] || join(RAIZ, "build", "site"));
  cpSync(SITE, saida, { recursive: true, filter: (f) => !MOLDES.includes(f.slice(SITE.length + 1)) && !f.endsWith(".gdignore") });
  const vals = valores(saida);
  for (const m of MOLDES) {
    writeFileSync(join(saida, m), preencher(readFileSync(join(SITE, m), "utf8"), vals));
  }
  // robots.txt e sitemap.xml: na producao abre-se tudo e diz-se onde esta o
  // mapa; numa pre-visualizacao fecha-se tudo.
  const robots = vals.PRODUCAO
    ? `User-agent: *\nAllow: /\n${vals.URL ? `Sitemap: ${vals.URL}/sitemap.xml\n` : ""}`
    : "User-agent: *\nDisallow: /\n";
  writeFileSync(join(saida, "robots.txt"), robots);
  if (vals.URL) {
    const hoje = new Date().toISOString().slice(0, 10);
    const urls = ["/", "/jogar/", "/dossie/"]
      .map((c) => `  <url><loc>${vals.URL}${c}</loc><lastmod>${hoje}</lastmod></url>`)
      .join("\n");
    writeFileSync(
      join(saida, "sitemap.xml"),
      `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls}\n</urlset>\n`,
    );
  }
  // Para quem quiser saber o que está publicado sem abrir a página.
  const versao = {
    commit: vals.SHA,
    ramo: process.env.VERCEL_GIT_COMMIT_REF || git("rev-parse --abbrev-ref HEAD", ""),
    ambiente: process.env.VERCEL_ENV || "local",
    godot: vals.GODOT,
    publicado: new Date().toISOString(),
  };
  writeFileSync(join(saida, "versao.json"), JSON.stringify(versao, null, 2) + "\n");
  console.log(`pagina: ${saida}/index.html · commit ${vals.SHA7} · ${vals.FEITOS}/${vals.TICKETS} tickets · ${vals.TESTES} testes`);
}
