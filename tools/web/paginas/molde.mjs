// tools/web/paginas/molde.mjs — o HTML do site, a partir dos textos e dos dados (ADR 0025).
//
// Duas páginas saem daqui — a de entrada, uma por língua, e o 404 — e partilham
// a cabeça, o topo e o rodapé. Não há JavaScript nem estilos em linha: a
// política de segurança da página (CSP) só aceita scripts e folhas do próprio
// site, e um `style=""` ou um `<script>` escrito aqui partia-a em silêncio. O que
// depende dos dados e seria um `style` (a largura de cada fase, a cor da luz, o
// foco do recorte) sai numa folha gerada — ver `cssDosDados`.
//
// Tudo o que vem do repositório passa por `esc`: o texto do dossiê e os títulos
// dos tickets são dados, e não marcação. O que vem de textos.mjs pode trazer
// marcação (um <em>, uma ligação), porque é escrito aqui e revisto como código.

export const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);

/** Um modelo que o site.js preenche no browser: as chavetas vão como entidades,
    para o portão dos marcadores por preencher não o confundir com um esquecimento. */
const modelo = (s) => esc(s).replace(/\{/g, "&#123;").replace(/\}/g, "&#125;");

/** Os marcadores {assim}. Um marcador sem valor fica à vista — e o portão apanha-o. */
export const fmt = (s, v = {}) => String(s).replace(/\{(\w+)\}/g, (m, k) => (k in v ? v[k] : m));

const FASE_IMG = { dawn: "alvorada", morning: "manha", noon: "meiodia", afternoon: "tarde", dusk: "crepusculo", night: "noite" };
const INICIAL = "morning";
const ROMANOS = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"];

export const CSP = [
  "default-src 'self'", "script-src 'self'", "style-src 'self'", "img-src 'self' data:", "font-src 'self'",
  "connect-src 'self'", "manifest-src 'self'", "object-src 'none'", "base-uri 'self'", "form-action 'none'",
].join("; ");

const ICONE = `<svg viewBox="0 0 16 16" aria-hidden="true" shape-rendering="crispEdges"><rect x="5" y="1" width="6" height="2" fill="#9fc957"/><rect x="3" y="3" width="10" height="4" fill="#9fc957"/><rect x="2" y="5" width="12" height="2" fill="#7fa543"/><rect x="7" y="7" width="2" height="6" fill="#8a5a33"/><rect x="0" y="13" width="16" height="1" fill="#e9a54a"/><rect x="0" y="14" width="16" height="2" fill="#5a3d22"/></svg>`;
const LUA = `<svg class="lua" viewBox="0 0 16 16" aria-hidden="true"><path fill="currentColor" d="M10.5 1.5A6.5 6.5 0 1 0 14.5 11 5.5 5.5 0 0 1 10.5 1.5z"/></svg>`;
const SOL = `<svg class="sol" viewBox="0 0 16 16" aria-hidden="true"><circle cx="8" cy="8" r="3.2" fill="currentColor"/><g stroke="currentColor" stroke-width="1.5"><path d="M8 .8v2.4M8 12.8v2.4M.8 8h2.4M12.8 8h2.4M2.9 2.9l1.7 1.7M11.4 11.4l1.7 1.7M2.9 13.1l1.7-1.7M11.4 4.6l1.7-1.7"/></g></svg>`;
const PLAY = `<svg viewBox="0 0 14 14" aria-hidden="true"><path d="M2 1l11 6-11 6z" fill="currentColor"/></svg>`;
const PAUSA = `<svg class="i-pausa" viewBox="0 0 14 14" aria-hidden="true"><path d="M3 1h3v12H3zM8 1h3v12H8z" fill="currentColor"/></svg><svg class="i-play" viewBox="0 0 14 14" aria-hidden="true"><path d="M3 1l10 6-10 6z" fill="currentColor"/></svg>`;
const SETA = `<svg viewBox="0 0 12 12" aria-hidden="true"><path d="M2 6h8M6.5 2.5L10 6l-3.5 3.5" fill="none" stroke="currentColor" stroke-width="1.5"/></svg>`;

// ── A folha dos dados ────────────────────────────────────────────────────

/** O que seria um style="" e não pode ser: larguras, cores e focos que vêm dos dados. */
export function cssDosDados(d) {
  const r = [];
  for (const f of d.relogio.fases) r.push(`.f-${f.id}{--luz:${f.tinta};flex-grow:${f.dura}}`);
  for (const [fase, q] of Object.entries(d.capturas.quadros)) r.push(`.q-${fase}{--foco:${(q.foco * 100).toFixed(1)}%}`);
  const t = d.tickets;
  r.push(`.b-feito{flex-grow:${t.feitos}}.b-parcial{flex-grow:${t.parciais}}.b-falta{flex-grow:${t.faltam}}`);
  r.push(`:root{--violeta:${d.podridao.violeta};--nucleo:${d.podridao.paragens.nucleo};--meio:${d.podridao.paragens.meio};`
    + `--bordo:${d.podridao.paragens.bordo};--terra:${d.relogio.fases.at(-1).tinta}}`);
  return `/* Gerado de data/ e docs/ por tools/web/paginas/molde.mjs */\n${r.join("\n")}\n`;
}

// ── Peças comuns ─────────────────────────────────────────────────────────

function cabeca({ t, v, titulo, descricao, robots, canonico, alternativas, og, extra = "" }) {
  const alt = alternativas.map(([l, h]) => `<link rel="alternate" hreflang="${l}" href="${h}">`).join("\n");
  return `<!DOCTYPE html>
<html lang="${t.lingua}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta http-equiv="Content-Security-Policy" content="${CSP}">
<title>${esc(titulo)}</title>
<meta name="description" content="${esc(descricao)}">
<meta name="robots" content="${robots}">
<meta name="color-scheme" content="light dark">
<meta name="theme-color" content="#ebe6d6" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#15120c" media="(prefers-color-scheme: dark)">
${canonico ? `<link rel="canonical" href="${canonico}">\n` : ""}${alt}
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="/icone-180.png">
<link rel="manifest" href="/site.webmanifest">
<link rel="preload" href="/fontes/fraunces-400-900-latin.woff2" as="font" type="font/woff2" crossorigin>
<link rel="preload" href="/fontes/source-serif-4-400-600-latin.woff2" as="font" type="font/woff2" crossorigin>
${extra}<link rel="stylesheet" href="${v.css}">
<script src="${v.tema}"></script>
<script src="${v.js}" defer></script>
${og || ""}</head>`;
}

function topo({ t, v, ancoras }) {
  const n = t.nav;
  const itens = ancoras
    ? [["#jogo", n.jogo], ["#dia", n.dia], ["#povos", n.povos], ["#controlos", n.controlos], ["#estado", n.estado]]
    : [];
  itens.push(["/dossie/", n.dossie]);
  const outraHref = t.nav.outra.lingua === "en" ? "/en/" : "/";
  return `<a class="salto" href="#conteudo">${n.saltar}</a>
<header class="topo" id="topo">
  <div class="envolve topo-barra">
    <a class="marca" href="${t.caminho}" aria-label="${n.inicio}">${ICONE}<span>EMPIRE</span></a>
    <nav class="menu" id="menu" aria-label="${n.rotulo}">
      <ul>${itens.map(([h, x]) => `<li><a href="${h}">${x}</a></li>`).join("")}</ul>
    </nav>
    <div class="topo-accoes">
      <a class="lingua" href="${outraHref}" hreflang="${n.outra.lingua}" lang="${n.outra.lingua}" title="${n.outra.titulo}" aria-label="${n.outra.titulo}">${n.outra.texto}</a>
      <button class="tema" id="tema" type="button" aria-label="${n.tema_escuro}" data-claro="${n.tema_claro}" data-escuro="${n.tema_escuro}">${LUA}${SOL}</button>
      <a class="botao-jogar" href="${v.jogar}">${n.jogar}</a>
      <button class="abre-menu" id="abre-menu" type="button" aria-expanded="false" aria-controls="menu" data-abrir="${n.menu}" data-fechar="${n.fechar}"><span class="traco" aria-hidden="true"></span><span class="rotulo">${n.menu}</span></button>
    </div>
  </div>
</header>`;
}

function rodape({ t, d, v }) {
  const r = t.rodape;
  const data = new Intl.DateTimeFormat(t.lingua, { day: "numeric", month: "long", year: "numeric", timeZone: "Europe/Lisbon" }).format(d.agora);
  const sha = `<a href="${d.repo}/commit/${d.sha}"><code>${d.sha.slice(0, 7)}</code></a>`;
  const jogo = [v.jogar, "/dossie/", d.repo];
  const projeto = [`${d.repo}/tree/main/docs/backlog`, `${d.repo}/blob/main/docs/QUESTIONS.md`, `${d.repo}/tree/main/docs/adr`];
  const lista = (hrefs, rot) => `<ul>${hrefs.map((h, i) => `<li><a href="${h}">${rot[i]}</a></li>`).join("")}</ul>`;
  return `<footer class="rodape">
  <div class="envolve">
    <div class="rodape-grelha">
      <div class="rodape-marca"><a class="marca" href="${t.caminho}" aria-label="${t.nav.inicio}">${ICONE}<span>EMPIRE</span></a>
        <p>${r.privacidade}</p></div>
      <div><h2>${r.jogo}</h2>${lista(jogo, r.ligacoes_jogo)}</div>
      <div><h2>${r.projeto}</h2>${lista(projeto, r.ligacoes_projeto)}</div>
    </div>
    <div class="rodape-fim">
      <p>${fmt(r.direitos, { ano: d.agora.getFullYear() })} ${r.godot}</p>
      <p>${fmt(r.versao, { data, sha, godot: d.godot })} · <a href="#topo">${r.topo}</a></p>
    </div>
  </div>
</footer>`;
}

// ── A página de entrada ──────────────────────────────────────────────────

function nomeFase(t, f) {
  return t.lingua === "pt-PT" ? f.nome : t.dia.fases[f.id].nome;
}

function abertura({ t, d, v, mb }) {
  const a = t.abertura;
  const cap = d.capturas;
  const quadros = d.relogio.fases.map((f) => {
    const img = FASE_IMG[f.id];
    const ativo = f.id === INICIAL;
    const alt = f.id === "night" ? a.alt_noite : fmt(a.alt, { fase: nomeFase(t, f).toLowerCase() });
    return `<img class="quadro q-${img}${ativo ? " ativo" : ""}" src="/img/dia-${img}.webp" width="${cap.largura}" height="${cap.altura}"`
      + ` alt="${esc(alt)}" decoding="async" data-fase="${f.id}"${ativo ? ' fetchpriority="high"' : ' fetchpriority="low" aria-hidden="true"'}>`;
  }).join("\n        ");
  // A fita não é uma fila de botões: a alvorada é 4% do dia e, num telemóvel,
  // um botão com 10 px de largura. É um controlo só — um deslizador que o
  // site.js liga (role="slider", setas do teclado), e o rótulo de cada fase só
  // aparece onde cabe.
  const fases = d.relogio.fases.map((f) => `<li class="f-${f.id}${f.dura / d.relogio.dia < 0.1 ? " estreita" : ""}" data-fase="${f.id}" data-inicio="${f.inicio}" data-dura="${f.dura}"`
    + ` data-nome="${esc(nomeFase(t, f))}"><span>${esc(nomeFase(t, f))}</span></li>`).join("");
  const inicial = d.relogio.fases.find((f) => f.id === INICIAL);
  return `<section class="abertura escura" aria-labelledby="titulo">
  <div class="envolve abertura-grelha">
    <div class="abertura-titulo">
      <p class="kicker">${a.kicker.map((k) => `<span>${fmt(k, { godot: d.godot })}</span>`).join("")}</p>
      <h1 id="titulo">${a.h1}</h1>
    </div>
    <div class="abertura-lado">
      <p class="deck">${a.deck}</p>
      <div class="accoes">
        <a class="botao principal" href="${v.jogar}">${PLAY}${a.jogar}</a>
        <a class="botao" href="#controlos">${a.ver}</a>
      </div>
      <p class="nota">${fmt(a.nota, { mb })}</p>
      <p class="so-toque">${a.toque}</p>
    </div>
  </div>
  <figure class="palco" id="palco" aria-label="${a.palco}" data-dia="${d.relogio.dia}" data-agora="${modelo(a.agora)}" data-pausar="${a.pausar}" data-continuar="${a.continuar}">
    <div class="envolve-largo">
      <div class="quadros">
        ${quadros}
      </div>
      <div class="linha-do-dia">
        <button class="pausa" id="pausa" type="button" aria-pressed="false" aria-label="${a.pausar}">${PAUSA}</button>
        <div class="fases-palco" id="fita-palco" data-rotulo="${esc(t.dia.rotulo)}"><ol class="fases" aria-hidden="true">${fases}</ol><i class="agulha" aria-hidden="true"></i></div>
        <p class="agora" id="agora" aria-hidden="true">${esc(fmt(a.agora, { dia: 1, fase: nomeFase(t, inicial) }))}</p>
      </div>
      <figcaption>${fmt(a.legenda, { sha7: `<a href="${d.repo}/commit/${cap.commit}"><code>${cap.commit.slice(0, 7)}</code></a>` })}</figcaption>
    </div>
  </figure>
  <div class="solo" aria-hidden="true"></div>
</section>`;
}

function cabecaSeccao(id, s, extra = "") {
  return `<header class="cabeca revela">
      <p class="n">${s.n}</p>
      <div><h2 id="${id}-t">${s.h2}</h2>${s.intro ? `<p>${s.intro}</p>` : ""}${extra}</div>
    </header>`;
}

function pilares({ t }) {
  const s = t.pilares;
  return `<section class="secao" id="jogo" aria-labelledby="jogo-t">
  <div class="envolve">
    ${cabecaSeccao("jogo", s)}
    <ol class="pilares revela">
      ${s.itens.map((x, i) => `<li><span class="num" aria-hidden="true">${ROMANOS[i]}</span><h3>${x.t}</h3><p>${x.p}</p></li>`).join("\n      ")}
    </ol>
  </div>
</section>`;
}

function dia({ t, d }) {
  const s = t.dia;
  const fases = d.relogio.fases;
  const texto = (f) => (t.lingua === "pt-PT" ? f : { ...f, ...s.fases[f.id] });
  const rotulo = `${s.rotulo}: ${fases.map((f) => `${nomeFase(t, f)} ${f.dura} s`).join(", ")}`;
  return `<section class="secao" id="dia" aria-labelledby="dia-t">
  <div class="envolve">
    ${cabecaSeccao("dia", { ...s, h2: fmt(s.h2, { dia: d.relogio.dia }) })}
    <div class="corpo revela">
      <div class="fita" role="img" aria-label="${esc(rotulo)}">${fases.map((f) => `<span class="f-${f.id}${f.dura / d.relogio.dia < 0.1 ? " estreita" : ""}"><b>${esc(nomeFase(t, f))}</b><small>${f.dura} s</small></span>`).join("")}</div>
      <ol class="fases-cartoes">
        ${fases.map((f0) => {
          const f = texto(f0);
          return `<li class="cartao-fase f-${f.id}"><span class="amostra" aria-hidden="true"></span>
          <h3>${esc(f.nome)} <span class="dur">${fmt(s.segundos, { s: f.dura })}</span></h3>
          <p>${esc(f.funcao)}</p>
          <p class="tropas"><span>${s.tropas}</span> ${esc(f.tropas)}</p></li>`;
        }).join("\n        ")}
      </ol>
      <p class="fonte">${s.fonte}</p>
    </div>
  </div>
</section>`;
}

function candeia(p, dia) {
  return {
    raio: Math.min(p.raio.base + p.raio.porDia * dia, p.raio.teto),
    vel: p.velocidade.base + p.velocidade.porDia * dia,
    massa: p.massa.base + p.massa.porDia * dia,
    dois: dia >= p.doisLados,
  };
}

function noite({ t, d }) {
  const s = t.noite;
  const p = d.podridao;
  const num = new Intl.NumberFormat(t.lingua, { maximumFractionDigits: 1 });
  const c = candeia(p, 1);
  const ordinal = t.lingua === "pt-PT" ? `${p.primeiraOferta}.º` : `${p.primeiraOferta}${ordinalEn(p.primeiraOferta)}`;
  const falas = p.falas.map((f) => `<li><q>${esc(t.lingua === "pt-PT" ? f.pt : f.en)}</q> <span>${fmt(s.falas_dia, { dia: f.dia })}</span></li>`).join("");
  const formula = (base, porDia, extra = "") => `${num.format(base)} + ${num.format(porDia)} × ${s.inst_dia.toLowerCase()}${extra}`;
  const dados = [
    ["raio-base", p.raio.base], ["raio-dia", p.raio.porDia], ["raio-teto", p.raio.teto], ["vel-base", p.velocidade.base],
    ["vel-dia", p.velocidade.porDia], ["massa-base", p.massa.base], ["massa-dia", p.massa.porDia], ["lados", p.doisLados],
    ["dither", p.dither], ["um", s.inst_um], ["dois", s.inst_dois], ["alt", s.inst_alt], ["lingua", t.lingua],
  ].map(([k, x]) => `data-${k}="${modelo(x)}"`).join(" ");
  return `<section class="secao escura" id="noite" aria-labelledby="noite-t">
  <div class="envolve">
    ${cabecaSeccao("noite", s)}
    <div class="noite-grelha corpo revela">
      <div class="noite-texto">
        <p>${fmt(s.p1, { oferta: ordinal })}</p>
        <p>${s.p2}</p>
        <figure class="falas"><figcaption>${s.falas}</figcaption><ul>${falas}</ul></figure>
      </div>
      <div class="instrumento" id="candeia" ${dados}>
        <h3>${s.inst_t}</h3>
        <canvas width="480" height="200" role="img" aria-label="${esc(fmt(s.inst_alt, { dia: 1, raio: c.raio }))}">${esc(fmt(s.inst_alt, { dia: 1, raio: c.raio }))}</canvas>
        <div class="regua"><label for="candeia-dia">${s.inst_dia} <output id="candeia-n" for="candeia-dia">1</output></label>
          <input type="range" id="candeia-dia" min="1" max="30" value="1" step="1"></div>
        <dl class="leituras" aria-live="polite">
          <div><dt>${s.inst_raio}</dt><dd><b data-l="raio">${num.format(c.raio)}</b> ${s.inst_px}<small>${formula(p.raio.base, p.raio.porDia, `, ${s.inst_teto} ${p.raio.teto}`)}</small></dd></div>
          <div><dt>${s.inst_vel}</dt><dd><b data-l="vel">${num.format(c.vel)}</b> ${s.inst_pxs}<small>${formula(p.velocidade.base, p.velocidade.porDia)}</small></dd></div>
          <div><dt>${s.inst_massa}</dt><dd><b data-l="massa">${num.format(c.massa)}</b><small>${formula(p.massa.base, p.massa.porDia)}</small></dd></div>
          <div><dt>${s.inst_lados}</dt><dd><b data-l="lados">${c.dois ? s.inst_dois : s.inst_um}</b><small>${fmt(s.inst_desde, { dia: p.doisLados })}: ${s.inst_dois}</small></dd></div>
        </dl>
        <p class="fonte">${fmt(s.inst_fonte, { dither: p.dither })}</p>
      </div>
    </div>
    <div class="excecoes revela">
      <h3>${s.regra}</h3>
      <ul>
        <li class="ex-violeta"><span class="amostra" aria-hidden="true"></span><code>${p.violeta}</code><p>${s.violeta}</p></li>
        <li class="ex-ambar"><span class="amostra" aria-hidden="true"></span><code>${p.paragens.nucleo}</code><p>${s.ambar}</p></li>
        <li class="ex-terra"><span class="amostra" aria-hidden="true"></span><code>${d.relogio.fases.at(-1).tinta.toUpperCase()}</code><p>${s.terra}</p></li>
      </ul>
    </div>
  </div>
</section>`;
}

function ordinalEn(n) {
  const r = n % 100;
  if (r >= 11 && r <= 13) return "th";
  return { 1: "st", 2: "nd", 3: "rd" }[n % 10] || "th";
}

function povos({ t, d }) {
  const s = t.povos;
  const linhas = d.povos.linhas.map((p) => (t.lingua === "pt-PT" ? p : { ...p, ...s.linhas[p.id] }));
  return `<section class="secao" id="povos" aria-labelledby="povos-t">
  <div class="envolve">
    ${cabecaSeccao("povos", s)}
    <ul class="povos revela">
      ${linhas.map((p, i) => `<li class="povo${p.hoje ? " hoje" : ""}">
        <p class="povo-n">${String(i + 1).padStart(2, "0")}${p.hoje ? ` <span class="selo">${s.hoje}</span>` : ""}</p>
        <h3>${esc(p.nome)}</h3>
        <p class="povo-terreno"><span class="sr">${s.terreno}: </span>${esc(p.terreno)}</p>
        <dl>
          <div><dt>${s.constroi}</dt><dd>${esc(p.constroi)}</dd></div>
          <div><dt>${s.economia}</dt><dd>${esc(p.economia)}</dd></div>
          <div><dt>${s.defesa}</dt><dd>${esc(p.defesa)}</dd></div>
          <div><dt>${s.tropa}</dt><dd>${esc(p.tropa)}</dd></div>
        </dl>
      </li>`).join("\n      ")}
    </ul>
    <p class="fonte">${s.nota}</p>
  </div>
</section>`;
}

/** «A D» ou «← →»: as duas metades de uma acção de direção juntas numa tecla só. */
function juntar(esq, dir, l) {
  return esq.map((e, i) => {
    const x = e[l], y = dir[i]?.[l] ?? "";
    const m = x.match(/^(.*?)\s*([←→↑↓])$/), n = y.match(/^(.*?)\s*([←→↑↓])$/);
    if (m && n && m[1] === n[1]) return m[1] ? `<kbd>${esc(m[1])} ${m[2]} ${n[2]}</kbd>` : `<span class="par"><kbd>${m[2]}</kbd> <kbd>${n[2]}</kbd></span>`;
    return `<span class="par"><kbd>${esc(x)}</kbd> <kbd>${esc(y)}</kbd></span>`;
  });
}

function controlos({ t, d }) {
  const s = t.controlos;
  const l = t.lingua === "pt-PT" ? "pt" : "en";
  const ou = ` <span class="ou">${s.ou}</span> `;
  const kbd = (xs) => xs.map((x) => `<kbd>${esc(x[l])}</kbd>`);
  const linhas = s.acoes.map((a) => {
    const [x, y] = a.de.map((id) => {
      const acao = d.controlos[id];
      if (!acao) throw new Error(`molde: a acção ${id} não está no project.godot`);
      return acao;
    });
    const teclado = y ? [...juntar(x.teclas, y.teclas, l), ...juntar(x.rato, y.rato, l)] : [...kbd(x.teclas), ...kbd(x.rato)];
    const comando = y ? juntar(x.comando, y.comando, l) : kbd(x.comando);
    return `<tr><th scope="row">${a.t}</th><td>${teclado.join(ou) || "—"}</td><td>${comando.join(ou) || "—"}</td></tr>`;
  }).join("\n            ");
  return `<section class="secao" id="controlos" aria-labelledby="controlos-t">
  <div class="envolve">
    ${cabecaSeccao("controlos", s)}
    <div class="corpo">
      <div class="verbos revela">
        ${s.verbos.map((x) => `<div class="verbo"><h3>${x.t}</h3><p>${x.p}</p></div>`).join("\n        ")}
      </div>
      <div class="controlos-grelha revela">
        <div class="tabela-rola" tabindex="0" role="region" aria-label="${s.tabela}">
          <table class="teclas-tabela">
            <caption>${s.tabela}</caption>
            <thead><tr>${s.cab.map((c) => `<th scope="col">${c}</th>`).join("")}</tr></thead>
            <tbody>
            ${linhas}
            </tbody>
          </table>
          <p class="fonte">${s.fonte}</p>
        </div>
        <figure class="ecra">
          <div class="moldura"><img src="/img/ecra.webp" width="${d.capturas.ecra[0]}" height="${d.capturas.ecra[1]}" loading="lazy" decoding="async" alt="${esc(s.ecra)}"></div>
          <figcaption>${s.ecra}</figcaption>
        </figure>
      </div>
    </div>
  </div>
</section>`;
}

function estado({ t, d }) {
  const s = t.estado;
  const tk = d.tickets;
  const num = new Intl.NumberFormat(t.lingua);
  const sha = `<a href="${d.repo}/commit/${d.sha}"><code>${d.sha.slice(0, 7)}</code></a>`;
  const rotEstado = { feito: s.feito, parcial: s.parcial, falta: s.falta };
  // A ordem dos trilhos é a de textos.mjs (o plano primeiro, o resto depois), e
  // um trilho novo no tickets.json sem nome lá chumba a construção.
  for (const tr of tk.trilhos) if (!s.trilhos[tr.id]) throw new Error(`molde: o trilho ${tr.id} não tem nome em textos.mjs (estado.trilhos)`);
  const ordem = Object.keys(s.trilhos);
  const trilhos = [...tk.trilhos].sort((a, b) => ordem.indexOf(a.id) - ordem.indexOf(b.id)).map((tr) => {
    const nome = s.trilhos[tr.id];
    const feitos = tr.tickets.filter((x) => x.estado === "feito").length;
    const legEstado = { feito: s.leg_feito, parcial: s.leg_parcial, falta: s.leg_falta };
    const resumo = ["feito", "parcial", "falta"].map((e) => `${tr.tickets.filter((x) => x.estado === e).length} ${legEstado[e]}`).join(", ");
    return `<div class="trilho"><p class="trilho-nome">${nome} <span>${feitos}/${tr.tickets.length}</span><span class="sr">: ${resumo}</span></p>
          <ol class="celas" aria-hidden="true">${tr.tickets.map((x) => `<li class="cela c-${x.estado}" title="${esc(`${x.id} · ${x.titulo} — ${rotEstado[x.estado]}`)}"></li>`).join("")}</ol></div>`;
  }).join("\n        ");
  const lista = tk.lista.map((x) => `<tr><th scope="row"><a href="${d.repo}/blob/main/docs/backlog/${x.id}.md">${x.id}</a></th><td lang="pt-PT">${esc(x.titulo)}</td><td><span class="estado e-${x.estado}">${rotEstado[x.estado]}</span></td></tr>`).join("\n              ");
  const porFase = (n) => tk.trilhos.find((tr) => tr.id === `F${n}`)?.tickets;
  const roteiro = d.roteiro.map((r0) => {
    const r = t.lingua === "pt-PT" ? r0 : { ...r0, ...s.fases[r0.n] };
    const tks = porFase(r.n);
    const feitos = tks ? tks.filter((x) => x.estado === "feito").length : 0;
    const classe = !tks ? "r-futuro" : feitos === tks.length ? "r-feito" : "r-curso";
    const est = tks ? fmt(s.em_curso, { feitos, total: tks.length }) : s.por_comecar;
    return `<li class="${classe}"><span class="r-n" aria-hidden="true">${r.n}</span>
          <div class="r-corpo"><h4><span class="sr">${r.n} · </span>${esc(r.nome)} <small>${esc(r.meses)}</small></h4><p>${esc(r.feito)}</p>
          <p class="criterio"><span>${s.criterio}</span> ${esc(r.criterio)}</p></div>
          <p class="r-estado">${est}</p></li>`;
  }).join("\n        ");
  const ler = [["/dossie/", s.ler[0]], [`${d.repo}/tree/main/docs/backlog`, s.ler[1]], [`${d.repo}/blob/main/docs/QUESTIONS.md`, s.ler[2]], [d.repo, s.ler[3]]];
  return `<section class="secao" id="estado" aria-labelledby="estado-t">
  <div class="envolve">
    ${cabecaSeccao("estado", { ...s, intro: fmt(s.intro, { sha }) })}
    <div class="corpo">
      <div class="numeros revela">
        <div class="numero"><b data-conta="${tk.feitos}">${num.format(tk.feitos)}</b><span>${fmt(s.feitos, { total: tk.total })}</span></div>
        <div class="numero"><b data-conta="${d.contas.testes}">${num.format(d.contas.testes)}</b><span>${s.testes}</span></div>
        <div class="numero"><b data-conta="${d.contas.adrs}">${num.format(d.contas.adrs)}</b><span>${s.adrs}</span></div>
        <div class="numero"><b data-conta="${d.contas.conferidos}">${num.format(d.contas.conferidos)}</b><span>${s.conferidos}</span></div>
      </div>
      <div class="barra revela" role="img" aria-label="${esc(fmt(s.barra, { feitos: tk.feitos, parciais: tk.parciais, faltam: tk.faltam, total: tk.total }))}"><i class="b-feito"></i><i class="b-parcial"></i><i class="b-falta"></i></div>
      <ul class="legenda">
        <li><i class="c-feito" aria-hidden="true"></i>${tk.feitos} ${s.leg_feito}</li>
        <li><i class="c-parcial" aria-hidden="true"></i>${tk.parciais} ${s.leg_parcial}</li>
        <li><i class="c-falta" aria-hidden="true"></i>${tk.faltam} ${s.leg_falta}</li>
      </ul>
      <div class="quadro-tickets revela">
        <h3>${fmt(s.quadro, { total: tk.total })}</h3>
        ${t.lingua === "pt-PT" ? "" : `<p class="fonte">${s.quadro_nota}</p>`}
        ${trilhos}
        <details class="lista">
          <summary>${s.lista}</summary>
          <div class="tabela-rola" tabindex="0" role="region" aria-label="${s.lista}">
            <table>
              <thead><tr>${s.cab.map((c) => `<th scope="col">${c}</th>`).join("")}</tr></thead>
              <tbody>
              ${lista}
              </tbody>
            </table>
          </div>
        </details>
      </div>
      <div class="roteiro revela">
        <h3>${s.roteiro}</h3>
        <ol>
        ${roteiro}
        </ol>
        <p class="fonte">${s.roteiro_nota}</p>
      </div>
      <div class="ler">${ler.map(([h, x]) => `<a class="botao" href="${h}">${x}${SETA}</a>`).join("")}</div>
    </div>
  </div>
</section>`;
}

function perguntas({ t, d }) {
  const s = t.perguntas;
  const nomes = d.linguas.map((l) => t.linguas_nome[l] || l);
  const linguas = nomes.length > 1 ? `${nomes.slice(0, -1).join(", ")} ${t.e} ${nomes.at(-1)}` : nomes[0];
  const fase = d.roteiro.find((r) => /demo/i.test(r.nome));
  const v = {
    linguas: t.lingua === "en" ? linguas[0].toUpperCase() + linguas.slice(1) : linguas,
    chaves: d.contas.chaves, testes: d.contas.testes, adrs: d.contas.adrs, seccoes: d.contas.seccoes, repo: d.repo,
    fase_demo: fase ? fase.n : "?",
  };
  return `<section class="secao" id="perguntas" aria-labelledby="perguntas-t">
  <div class="envolve">
    ${cabecaSeccao("perguntas", s)}
    <div class="perguntas corpo revela">
      ${s.itens.map((x) => `<details><summary>${x.q}</summary><div>${fmt(x.r, v)}</div></details>`).join("\n      ")}
    </div>
  </div>
</section>`;
}

function jsonLd({ t, d, url, og }) {
  const o = {
    "@context": "https://schema.org",
    "@type": "VideoGame",
    name: "Empire",
    alternateName: t.lingua === "pt-PT" ? "Empire (nome de trabalho)" : "Empire (working title)",
    description: t.meta.descricao,
    inLanguage: t.lingua,
    url: url ? `${url}${t.caminho}` : undefined,
    image: og || undefined,
    genre: ["Strategy", "Kingdom builder", "Pixel art"],
    gamePlatform: "Web browser",
    playMode: "SinglePlayer",
    applicationCategory: "Game",
    author: { "@type": "Person", name: "Henrique Passos" },
    availableLanguage: d.linguas.map((l) => l.replace("_", "-")),
    codeRepository: d.repo,
  };
  return `<script type="application/ld+json">${JSON.stringify(o).replace(/</g, "\\u003c")}</script>`;
}

export function entrada({ t, d, v, mb, url, robots }) {
  const canonico = url ? `${url}${t.caminho}` : "";
  const base = url || "";
  const og = url ? `${url}/img/partilha-${t.lingua === "pt-PT" ? "pt" : "en"}.png` : `/img/partilha-${t.lingua === "pt-PT" ? "pt" : "en"}.png`;
  const ogTags = `<meta property="og:type" content="website">
<meta property="og:site_name" content="Empire">
<meta property="og:title" content="${esc(t.meta.og_titulo)}">
<meta property="og:description" content="${esc(t.meta.descricao)}">
<meta property="og:image" content="${og}">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:image:alt" content="${esc(t.meta.og_alt)}">
${canonico ? `<meta property="og:url" content="${canonico}">\n` : ""}<meta property="og:locale" content="${t.og_locale}">
<meta property="og:locale:alternate" content="${t.og_locale === "pt_PT" ? "en_US" : "pt_PT"}">
<meta name="twitter:card" content="summary_large_image">
${jsonLd({ t, d, url, og })}
`;
  const extra = `<link rel="preload" as="image" href="/img/dia-${FASE_IMG[INICIAL]}.webp" fetchpriority="high">
<link rel="prefetch" href="/jogar/index.js">
`;
  return `${cabeca({
    t, v, titulo: t.meta.titulo, descricao: t.meta.descricao, robots, canonico, og: ogTags, extra,
    alternativas: [["pt-PT", `${base}/`], ["en", `${base}/en/`], ["x-default", `${base}/`]],
  })}
<body>
${topo({ t, v, ancoras: true })}
<main id="conteudo">
${abertura({ t, d, v, mb })}
${pilares({ t })}
${dia({ t, d })}
${noite({ t, d })}
${povos({ t, d })}
${controlos({ t, d })}
${estado({ t, d })}
${perguntas({ t, d })}
</main>
${rodape({ t, d, v })}
</body>
</html>
`;
}

// ── A casca do jogo: os controlos, enquanto o motor chega ─────────────────

/** Os controlos de teclado, nas duas línguas, para o ecrã de carregamento de /jogar/. */
export function controlosCasca({ textos, d }) {
  const [pt, en] = [textos.pt, textos.en];
  const linhas = pt.controlos.acoes.map((a, i) => {
    const [x, y] = a.de.map((id) => d.controlos[id]);
    const teclas = y ? juntar(x.teclas, y.teclas, "pt").slice(0, 1) : [...x.teclas, ...x.rato].slice(0, 1).map((k) => `<kbd>${esc(k.pt)}</kbd>`);
    const teclasEn = y ? juntar(x.teclas, y.teclas, "en").slice(0, 1) : [...x.teclas, ...x.rato].slice(0, 1).map((k) => `<kbd>${esc(k.en)}</kbd>`);
    const dd = teclas[0] === teclasEn[0] ? teclas[0] : `<span lang="pt-PT">${teclas[0]}</span><span lang="en">${teclasEn[0]}</span>`;
    return `<div><dt><span lang="pt-PT">${a.t}</span><span lang="en">${en.controlos.acoes[i].t}</span></dt><dd>${dd}</dd></div>`;
  }).join("");
  return `<div class="controlos"><p><span lang="pt-PT">${pt.controlos.cab[1]} · ${pt.controlos.tabela.toLowerCase()}</span>`
    + `<span lang="en">${en.controlos.cab[1]} · ${en.controlos.tabela.toLowerCase()}</span></p><dl>${linhas}</dl></div>`;
}

// ── O 404 ────────────────────────────────────────────────────────────────

export function erro({ textos, d, v }) {
  const [pt, en] = [textos.pt, textos.en];
  return `${cabeca({ t: pt, v, titulo: pt.erro.titulo, descricao: pt.erro.p, robots: "noindex", canonico: "", alternativas: [] })}
<body class="pagina-erro">
<main id="conteudo" class="erro escura">
  <div class="erro-corpo">
    <p class="kicker"><span>404</span></p>
    <h1>${pt.erro.h1}</h1>
    <div class="solo" aria-hidden="true"></div>
    <p>${pt.erro.p}</p>
    <p lang="en" class="erro-en">${en.erro.p}</p>
    <div class="accoes">
      <a class="botao principal" href="${v.jogar}">${PLAY}${pt.erro.jogar}</a>
      <a class="botao" href="/">${pt.erro.voltar}</a>
      <a class="botao" href="/en/" lang="en" hreflang="en">${en.erro.voltar}</a>
    </div>
  </div>
</main>
</body>
</html>
`;
}
