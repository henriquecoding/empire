// tools/web/dados.mjs — tudo o que o site diz e que o repositório já sabe (ADR 0025).
//
// A regra do AGENTS.md — nenhum número que uma ferramenta conta se escreve à
// mão — vale aqui para mais do que números. A duração de cada fase e a cor da
// luz saem do clock.csv; o raio da candeia, a velocidade e a massa da Podridão
// do rot.csv; as falas dela do strings.csv, nas duas línguas; os controlos do
// mapa de entrada do project.godot; os seis povos, o ciclo e o roteiro das
// tabelas do dossiê (§04, §05, §33); o estado do tickets.json e do
// validation.json. O site passa a ser uma leitura do repositório, e não uma
// segunda cópia dele que diverge no primeiro commit.
//
// Tudo o que não se consegue ler chumba a construção, com o nome do ficheiro:
// uma página com um buraco é pior do que nenhuma.

import { readFileSync, readdirSync, existsSync, statSync } from "node:fs";
import { join, relative, sep } from "node:path";
import { execSync } from "node:child_process";
import { createHash } from "node:crypto";

const falha = (msg) => {
  throw new Error(`dados: ${msg}`);
};

// ── Leitores ─────────────────────────────────────────────────────────────

/** Um CSV com aspas, vírgulas e quebras de linha dentro de campos (RFC 4180). */
export function csv(texto) {
  const linhas = [];
  let linha = [], campo = "", aspas = false;
  for (let i = 0; i < texto.length; i++) {
    const c = texto[i];
    if (aspas) {
      if (c === '"' && texto[i + 1] === '"') { campo += '"'; i++; }
      else if (c === '"') aspas = false;
      else campo += c;
    } else if (c === '"') aspas = true;
    else if (c === ",") { linha.push(campo); campo = ""; }
    else if (c === "\n" || c === "\r") {
      if (c === "\r" && texto[i + 1] === "\n") i++;
      linha.push(campo); campo = "";
      if (linha.some((x) => x !== "")) linhas.push(linha);
      linha = [];
    } else campo += c;
  }
  if (campo !== "" || linha.length) { linha.push(campo); linhas.push(linha); }
  const [cab, ...resto] = linhas;
  return resto.map((l) => Object.fromEntries(cab.map((k, i) => [k, l[i] ?? ""])));
}

const lerCsv = (raiz, f) => csv(readFileSync(join(raiz, f), "utf8"));

/** A tabela markdown de uma secção do dossiê cujo cabeçalho começa por `primeira`. */
export function tabelaDoDossie(raiz, prefixo, primeira) {
  const pasta = join(raiz, "docs", "design");
  const f = readdirSync(pasta).find((x) => x.startsWith(prefixo));
  if (!f) falha(`docs/design/${prefixo}* não existe`);
  const linhas = readFileSync(join(pasta, f), "utf8").split("\n");
  const i = linhas.findIndex((l) => l.startsWith(`| ${primeira} |`));
  if (i < 0) falha(`docs/design/${f}: não há tabela a começar por «${primeira}»`);
  const celulas = (l) => l.slice(1, -1).split(" | ").map((c) => c.trim());
  const cab = celulas(linhas[i]);
  const saida = [];
  for (const l of linhas.slice(i + 2)) {
    if (!l.startsWith("|")) break;
    saida.push(Object.fromEntries(celulas(l).map((c, k) => [cab[k], c])));
  }
  return { ficheiro: `docs/design/${f}`, linhas: saida };
}

// ── O relógio (§05, §80) ─────────────────────────────────────────────────

const FASES = ["dawn", "morning", "noon", "afternoon", "dusk", "night"];

/** Color.from_hsv do Godot, que é o que o BandLight usa: o mesmo tom, byte a byte. */
export function hsvParaHex(h, s, v) {
  const f = (n) => {
    const k = (n + h / 60) % 6;
    return v - v * s * Math.max(0, Math.min(k, 4 - k, 1));
  };
  const b = (x) => Math.round(x * 255).toString(16).padStart(2, "0");
  return `#${b(f(5))}${b(f(3))}${b(f(1))}`;
}

function relogio(raiz) {
  const [r] = lerCsv(raiz, "data/source/clock.csv");
  const lista = (k) => r[k].split("|").map(Number);
  const [hs, ss, vs] = [lista("phase_tint_hue"), lista("phase_tint_sat"), lista("phase_tint_val")];
  let inicio = 0;
  const fases = FASES.map((id, i) => {
    const dura = Number(r[id]);
    const f = { id, dura, inicio, tinta: hsvParaHex(hs[i], ss[i], vs[i]) };
    inicio += dura;
    return f;
  });
  if (inicio !== Number(r.day_seconds)) falha(`clock.csv: as fases somam ${inicio} e day_seconds diz ${r.day_seconds}`);
  // O texto de cada fase é o da tabela do §05, e só a duração vem do CSV: a
  // tabela e o CSV já são conferidos um contra o outro pelo check_dossie_vs_csv.
  const s05 = tabelaDoDossie(raiz, "05-", "Fase");
  if (s05.linhas.length !== fases.length) falha(`${s05.ficheiro}: ${s05.linhas.length} fases, o clock.csv tem ${fases.length}`);
  s05.linhas.forEach((l, i) => Object.assign(fases[i], { nome: l.Fase, funcao: l["Função"], tropas: l["Estado das tropas"] }));
  return { dia: Number(r.day_seconds), fases, fonte: s05.ficheiro };
}

// ── A Podridão e a candeia (§74, §75, §80) ───────────────────────────────

function podridao(raiz) {
  const [r] = lerCsv(raiz, "data/source/rot.csv");
  const n = (k) => {
    const x = Number(r[k]);
    if (!Number.isFinite(x)) falha(`rot.csv: ${k} não é um número («${r[k]}»)`);
    return x;
  };
  const ofertas = lerCsv(raiz, "data/source/offers.csv");
  const falas = Object.fromEntries(lerCsv(raiz, "data/i18n/strings.csv").map((l) => [l.keys, l]));
  // As falas das primeiras ofertas: as que têm dia mínimo e não pedem nada. As
  // outras são de condições e de capítulos, e contá-las era estragar a partida.
  const primeiras = ofertas
    .filter((o) => Number(o.min_day) > 0 && !o.requires)
    .sort((a, b) => Number(a.min_day) - Number(b.min_day))
    .slice(0, 5)
    .map((o) => {
      const f = falas[o.display_key];
      if (!f) falha(`strings.csv: falta ${o.display_key}`);
      return { id: o.id, dia: Number(o.min_day), pt: f.pt_PT, en: f.en };
    });
  if (!primeiras.length) falha("offers.csv: não há ofertas com dia mínimo");
  // O violeta da mancha é uma cor do greybox e não um número de balanceamento:
  // vive no WorldPalette, e é de lá que se lê — é o #59386B do §80.
  const paleta = readFileSync(join(raiz, "src/world/world_palette.gd"), "utf8");
  const mancha = paleta.match(/^const MANCHA := Color\(([^)]+)\)/m);
  if (!mancha) falha("src/world/world_palette.gd: não há const MANCHA := Color(...)");
  const [vr, vg, vb] = mancha[1].split(",").map((x) => Math.round(Number(x) * 255).toString(16).padStart(2, "0"));
  return {
    violeta: `#${vr}${vg}${vb}`.toUpperCase(),
    velocidade: { base: n("speed_base"), porDia: n("speed_per_day") },
    massa: { base: n("mass_base"), porDia: n("mass_per_day") },
    doisLados: n("two_sided_from_day"),
    raio: { base: n("lantern_radius_base"), porDia: n("lantern_radius_per_day"), teto: n("lantern_radius_max") },
    paragens: { nucleo: r.lantern_tint, meio: r.lantern_tint_mid, bordo: r.lantern_tint_edge },
    dither: n("lantern_dither_px"),
    primeiraOferta: primeiras[0].dia,
    falas: primeiras,
  };
}

// ── Os controlos: o mapa de entrada do project.godot ──────────────────────

const TECLAS = {
  32: "Espaço|Space", 4194305: "Esc|Esc", 4194306: "Tab|Tab", 4194309: "Enter|Enter",
  4194319: "←|←", 4194320: "↑|↑", 4194321: "→|→", 4194322: "↓|↓", 4194325: "Shift|Shift",
};
const BOTOES = {
  0: "A|A", 1: "B|B", 2: "X|X", 3: "Y|Y", 4: "View|View", 6: "Menu|Menu",
  9: "LB|LB", 10: "RB|RB", 11: "cruzeta ↑|D-pad ↑", 12: "cruzeta ↓|D-pad ↓",
  13: "cruzeta ←|D-pad ←", 14: "cruzeta →|D-pad →",
};
const EIXOS = {
  "0-": "analógico esquerdo ←|left stick ←", "0+": "analógico esquerdo →|left stick →",
  "2-": "analógico direito ←|right stick ←", "2+": "analógico direito →|right stick →",
  "4+": "LT|LT", "5+": "RT|RT",
};
const RATO = { 1: "clique esquerdo|left click", 2: "clique direito|right click" };

function rotulo(mapa, k, oque) {
  const r = mapa[k];
  if (!r) falha(`project.godot: ${oque} ${k} não tem nome no site — acrescenta-o a tools/web/dados.mjs`);
  const [pt, en] = r.split("|");
  return { pt, en };
}

function controlos(raiz) {
  const texto = readFileSync(join(raiz, "project.godot"), "utf8");
  const seccao = texto.split(/^\[input\]\s*$/m)[1]?.split(/^\[/m)[0];
  if (!seccao) falha("project.godot: não há secção [input]");
  const acoes = {};
  for (const [, nome, corpo] of seccao.matchAll(/^([a-z_]+)=\{([\s\S]*?)^\}/gm)) {
    const teclas = [], comando = [], rato = [];
    // Um evento acaba em `"script":null)`; os Vector2(0, 0) do rato têm
    // parênteses lá dentro, e por isso não se corta no primeiro «)».
    for (const [, tipo, campos] of corpo.matchAll(/Object\(InputEvent(\w+),(.*?)"script":null\)/gs)) {
      const v = (k) => campos.match(new RegExp(`"${k}":(-?[0-9.]+)`))?.[1];
      if (tipo === "Key") {
        const c = Number(v("physical_keycode") || v("keycode"));
        teclas.push(c >= 33 && c <= 126 ? { pt: String.fromCharCode(c), en: String.fromCharCode(c) } : rotulo(TECLAS, c, "a tecla"));
      } else if (tipo === "JoypadButton") comando.push(rotulo(BOTOES, v("button_index"), "o botão"));
      else if (tipo === "JoypadMotion") comando.push(rotulo(EIXOS, `${v("axis")}${Number(v("axis_value")) < 0 ? "-" : "+"}`, "o eixo"));
      else if (tipo === "MouseButton") rato.push(rotulo(RATO, v("button_index"), "o botão do rato"));
    }
    acoes[nome] = { teclas, comando, rato };
  }
  if (!Object.keys(acoes).length) falha("project.godot: a secção [input] não tem acções");
  return acoes;
}

// ── Os povos (§04) e o roteiro (§33) ─────────────────────────────────────

function povos(raiz) {
  const t = tabelaDoDossie(raiz, "04-", "Povo");
  const csvPovos = lerCsv(raiz, "data/source/peoples.csv");
  const chave = (s) => s.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase().replace(/[^a-z]/g, "");
  const linhas = t.linhas.map((l) => {
    // «Enramados (a tua cena)» e «Horta (os legumes)»: o parêntese fala com o
    // autor do dossiê, não com quem lê o site.
    const nome = l.Povo.replace(/\s*\(.*\)\s*$/, "");
    const p = csvPovos.find((x) => chave(x.id) === chave(nome));
    if (!p) falha(`${t.ficheiro}: o povo «${nome}» não está no peoples.csv`);
    // O povo que se joga hoje é o que já tem segmentos: os outros cinco ainda
    // não têm chão onde se pisar (§33, a fatia vertical é de um povo só).
    return {
      id: p.id, nome, terreno: l.Terreno, constroi: l["Constrói"], economia: l["Economia forte"],
      defesa: l.Defesa, tropa: l["Tropa única"], hoje: p.segment_kit.trim() !== "",
    };
  });
  if (linhas.length !== csvPovos.length) falha(`${t.ficheiro}: ${linhas.length} povos, o peoples.csv tem ${csvPovos.length}`);
  return { linhas, fonte: t.ficheiro };
}

function roteiro(raiz) {
  const t = tabelaDoDossie(raiz, "33-", "Fase");
  return t.linhas.map((l) => {
    const [n, nome] = l.Fase.split(" · ");
    return { n: Number(n), nome, meses: l["Duração"], feito: l["O que fica feito"], criterio: l["Critério de saída"] };
  });
}

// ── O estado: tickets e contagens ────────────────────────────────────────

function estadoDe(texto) {
  const e = String(texto || "").trim().toLowerCase();
  return e.startsWith("feito") ? "feito" : e.startsWith("parcial") ? "parcial" : "falta";
}

function tickets(raiz) {
  const t = JSON.parse(readFileSync(join(raiz, "docs/backlog/tickets.json"), "utf8"));
  const lista = Object.entries(t).map(([id, x]) => ({ id, titulo: x.title, estado: estadoDe(x.estado), trilho: id.split("-")[0] }));
  const conta = (e) => lista.filter((x) => x.estado === e).length;
  const trilhos = [...new Set(lista.map((x) => x.trilho))].map((id) => ({ id, tickets: lista.filter((x) => x.trilho === id) }));
  return { lista, trilhos, total: lista.length, feitos: conta("feito"), parciais: conta("parcial"), faltam: conta("falta") };
}

function git(raiz, cmd, omissao) {
  try {
    return execSync(`git ${cmd}`, { cwd: raiz, stdio: ["ignore", "pipe", "ignore"] }).toString().trim();
  } catch {
    return omissao;
  }
}

function repo(raiz) {
  const { VERCEL_GIT_REPO_OWNER: dono, VERCEL_GIT_REPO_SLUG: nome } = process.env;
  if (dono && nome) return `https://github.com/${dono}/${nome}`;
  const remoto = git(raiz, "config --get remote.origin.url", "");
  const m = remoto.match(/github\.com[/:]([^/]+)\/([^/.]+?)(\.git)?$/) || remoto.match(/git\/([^/]+)\/([^/.]+)$/);
  return m ? `https://github.com/${m[1]}/${m[2]}` : "https://github.com/henriquecoding/empire";
}

function linguasDoJogo(raiz) {
  const cab = readFileSync(join(raiz, "data/i18n/strings.csv"), "utf8").split("\n")[0].split(",");
  return cab.filter((c) => c && !c.startsWith("_") && c !== "keys");
}

// A impressão dos ficheiros de que o jogo depende para se ver — a mesma conta do
// aparencia() do tools/web/capturas.py, que a grava na ficha das imagens. Se a
// de agora diferir, as imagens são de um jogo que já não é o publicado.
const APARENCIA_PASTAS = ["src", "scenes", "art/export", "shaders", "data"];
const APARENCIA_TIPOS = [".gd", ".tscn", ".tres", ".gdshader", ".png", ".json", ".csv", ".godot"];

function ficheirosEm(pasta) {
  if (!existsSync(pasta)) return [];
  return readdirSync(pasta, { withFileTypes: true }).flatMap((e) => {
    const caminho = join(pasta, e.name);
    return e.isDirectory() ? ficheirosEm(caminho) : [caminho];
  });
}

export function aparencia(raiz) {
  const ficheiros = [join(raiz, "project.godot")];
  for (const pasta of APARENCIA_PASTAS) {
    ficheiros.push(...ficheirosEm(join(raiz, pasta)).filter((f) => APARENCIA_TIPOS.some((t) => f.endsWith(t)) && statSync(f).isFile()));
  }
  const caminhos = ficheiros.map((f) => relative(raiz, f).split(sep).join("/")).sort();
  const total = createHash("sha256");
  for (const c of caminhos) {
    const conteudo = createHash("sha256").update(readFileSync(join(raiz, c))).digest("hex");
    total.update(`${c}\0${conteudo}\n`);
  }
  return total.digest("hex");
}

/** O repositório inteiro, lido uma vez. */
export function ler(raiz) {
  const v = JSON.parse(readFileSync(join(raiz, "docs/recovery/validation.json"), "utf8"));
  const capturas = join(raiz, "tools/web/site/img/capturas.json");
  if (!existsSync(capturas)) falha("tools/web/site/img/capturas.json não existe — corre make site-capturas");
  const sha = process.env.VERCEL_GIT_COMMIT_SHA || git(raiz, "rev-parse HEAD", "0000000");
  const dominio = process.env.VERCEL_PROJECT_PRODUCTION_URL || process.env.VERCEL_URL || "";
  return {
    relogio: relogio(raiz),
    podridao: podridao(raiz),
    controlos: controlos(raiz),
    povos: povos(raiz),
    roteiro: roteiro(raiz),
    tickets: tickets(raiz),
    capturas: JSON.parse(readFileSync(capturas, "utf8")),
    aparencia: aparencia(raiz),
    linguas: linguasDoJogo(raiz),
    contas: {
      testes: v.gdunit_discovered, adrs: v.adrs, seccoes: v.spec_sections, tabelas: v.csv_tables,
      recursos: v.generated_resources, conferidos: v.numeric_comparisons, chaves: v.i18n_keys,
    },
    godot: readFileSync(join(raiz, ".godot-version"), "utf8").trim().replace("-stable", ""),
    sha,
    ramo: process.env.VERCEL_GIT_COMMIT_REF || git(raiz, "rev-parse --abbrev-ref HEAD", ""),
    ambiente: process.env.VERCEL_ENV || "local",
    producao: process.env.VERCEL_ENV === "production",
    url: dominio ? `https://${dominio}` : "",
    repo: repo(raiz),
    agora: new Date(),
  };
}
