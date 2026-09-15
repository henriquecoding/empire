/* ═══════════════════════════════════════════════════════════════════════
   PAINÉIS — estado medido, inventário, gráficos e glossário
   ---------------------------------------------------------------------
   ┌─────────────────────────────────────────────────────────────────────┐
   │ REGRA ABSOLUTA: NENHUM NÚMERO CHEGA AO ECRÃ SEM PROVENIÊNCIA         │
   │                                                                     │
   │ É a regra que o Recibo Certo impõe ao motor de descoberta e ao       │
   │ dossiê de guia, e aqui vale por uma razão que o próprio dossiê já    │
   │ escreveu: «as afirmações de feito, testes e inventários da Parte     │
   │ XII descrevem o ambiente original do Claude, não o estado desta      │
   │ cópia». Um painel de estado que apresentasse 29 testes verdes sem    │
   │ dizer QUEM os correu, QUANDO e CONTRA O QUÊ seria exactamente o      │
   │ problema que o dossiê passou uma versão inteira a corrigir — com     │
   │ melhor tipografia.                                                  │
   │                                                                     │
   │ Por isso: `userReviewedInputs`, `policyApproved` e                   │
   │ `calculationReproducible` são três coisas diferentes. Aqui           │
   │ traduzem-se em «gerado», «medido» e «por verificar», e nenhuma       │
   │ delas usa a palavra «validado».                                     │
   └─────────────────────────────────────────────────────────────────────┘
   ═══════════════════════════════════════════════════════════════════════ */

window.XP = (() => {
"use strict";

const $ = (s, r) => (r || document).querySelector(s);
const $$ = (s, r) => [...(r || document).querySelectorAll(s)];
const el = (t, a, h) => {
  const n = document.createElement(t);
  if (a) for (const k in a) { if (k === "class") n.className = a[k]; else if (a[k] != null) n.setAttribute(k, a[k]); }
  if (h !== undefined) n.innerHTML = h;
  return n;
};
const esc = (s) => X.escapar(s);
const parado = () => matchMedia("(prefers-reduced-motion: reduce)").matches;
const num = (n, casas) => n.toLocaleString("pt-PT", { minimumFractionDigits: casas || 0, maximumFractionDigits: casas || 0 });

const ico = (d) =>
  `<svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="2"` +
  ` stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false">${d}</svg>`;
const ESTADO_ICO = {
  ok: ico('<path d="M20 6 9 17l-5-5"/>'),
  aviso: ico('<path d="M12 9v4M12 17h.01M10.3 3.9 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0Z"/>'),
  grave: ico('<circle cx="12" cy="12" r="9"/><path d="m5.6 5.6 12.8 12.8"/>'),
  parado: ico('<circle cx="12" cy="12" r="9"/><path d="M12 8v4l2.5 2.5"/>'),
};
/** Cor NUNCA sozinha: sempre ícone + palavra. */
const selo = (tipo, texto) => `<span class="x-estado ${tipo}">${ESTADO_ICO[tipo]}${esc(texto)}</span>`;

const prov = (o) =>
  `<p class="x-prov"><b>Proveniência:</b> ${esc(o.fonte)}${o.data ? " · conferido a " + esc(o.data) : ""}` +
  `${o.nota ? " · " + esc(o.nota) : ""}</p>`;

/* ═══ Gráficos — utilitários comuns ═════════════════════════════════
   Um `<svg>` com `viewBox` e sem largura fixa: escala sozinho até aos
   320px sem rolar de lado. O texto usa tokens de tinta, nunca a cor da
   série — a cor é o reforço da identidade, não o dado. */

function svgBase(w, h, rotulo) {
  const s = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  s.setAttribute("viewBox", `0 0 ${w} ${h}`);
  s.setAttribute("preserveAspectRatio", "xMidYMid meet");
  s.setAttribute("role", "img");
  s.setAttribute("aria-label", rotulo);
  return s;
}

/**
 * ┌─────────────────────────────────────────────────────────────────────┐
 * │ UM `viewBox` FIXO ENCOLHE O TEXTO ATÉ AO INVISÍVEL                   │
 * │                                                                     │
 * │ O gráfico da economia tem `viewBox="0 0 720 260"` e `width:100%`.    │
 * │ A 1340px isso é 1:1 e os rótulos têm 11px. A 360px o SVG desenha-se  │
 * │ a 328 e a escala passa a 0,46: os mesmos 11px ficam CINCO pixéis no  │
 * │ ecrã. Nenhum portão tipográfico apanha isto, porque o `font-size`    │
 * │ computado continua a dizer 11 — a escala está no `viewBox`, não no   │
 * │ estilo.                                                             │
 * │                                                                     │
 * │ A correção não é aumentar o `font-size`: é desenhar à LARGURA REAL,  │
 * │ com uma unidade de utilizador por pixel. Aí 12 são 12, em qualquer   │
 * │ ecrã, e a figura reorganiza-se em vez de encolher.                   │
 * └─────────────────────────────────────────────────────────────────────┘
 */
function responsiva(hospedeiro, desenhar) {
  let ultimo = 0, agendado = null;
  const medir = () => {
    /* O piso dos 260 existia para evitar larguras degeneradas, mas a
       320px o SVG do simulador mede 246: o `viewBox` ficava a 260 e a
       escala caía para 0,95, o que punha um rótulo de 12,5 a 11,8. O
       piso desce para 200 — abaixo disso é que não há figura possível. */
    const w = Math.max(200, Math.round(hospedeiro.getBoundingClientRect().width));
    if (Math.abs(w - ultimo) < 4) return;
    ultimo = w;
    desenhar(w);
  };
  medir();
  if ("ResizeObserver" in window) {
    new ResizeObserver(() => {
      clearTimeout(agendado);
      agendado = setTimeout(medir, 90);
    }).observe(hospedeiro);
  } else {
    window.addEventListener("resize", () => { clearTimeout(agendado); agendado = setTimeout(medir, 140); });
  }
  window.addEventListener("x-tema", () => { ultimo = 0; medir(); });
  // A primeira medição pode acontecer antes de as fontes chegarem.
  if (document.fonts && document.fonts.ready) document.fonts.ready.then(() => { ultimo = 0; medir(); });
}
const cor = (nome) => getComputedStyle(document.documentElement).getPropertyValue(nome).trim();

/**
 * Tooltip único, partilhado por todos os gráficos.
 *
 * ┌─────────────────────────────────────────────────────────────────────┐
 * │ UMA CAIXA QUE SÓ SABE SUBIR ACABA POR CIMA DO QUE NÃO É DELA        │
 * │                                                                     │
 * │ A versão anterior punha a caixa sempre ACIMA do ponto e grampeava a  │
 * │ 8px do topo da janela. Quando o ponto está perto do topo do desenho  │
 * │ — e no gráfico da §06, em escala logarítmica, o custo da noite ao    │
 * │ dia 30 ESTÁ no topo — a caixa sai do gráfico e aterra em cima do que │
 * │ vier antes dele, que ali é a grelha das quatro réguas. Ler um dia    │
 * │ tapava os comandos com que se muda o dia.                           │
 * │                                                                     │
 * │ Passa a virar-se: por cima quando cabe, por baixo quando não cabe.   │
 * │ É a mesma regra de um menu que abre para cima ao fundo da página.    │
 * │                                                                     │
 * │ E «cabe» não é «está dentro da janela»: é «não sai do gráfico». Um   │
 * │ ponto perto do topo do desenho deixa espaço de sobra até ao topo da  │
 * │ JANELA, e a caixa aterrava lá — que é logo acima do gráfico, onde    │
 * │ estão os comandos. Quem chama passa o `topoMin`, o topo da sua       │
 * │ própria caixa, e a dica nunca o atravessa.                          │
 * └─────────────────────────────────────────────────────────────────────┘
 */
let tipEl = null;
function tip(html, x, y, topoMin) {
  if (!tipEl) { tipEl = el("div", { class: "x-tip", hidden: "", role: "status" }); document.body.appendChild(tipEl); }
  if (!html) { tipEl.hidden = true; return; }
  tipEl.innerHTML = html;
  tipEl.hidden = false;
  const r = tipEl.getBoundingClientRect();
  const esq = Math.max(8, Math.min(x - r.width / 2, window.innerWidth - r.width - 8));
  tipEl.style.left = Math.round(esq) + window.scrollX + "px";
  const limite = Math.max(8, topoMin == null ? 8 : topoMin);
  const acima = y - r.height - 12;
  const abaixo = Math.min(y + 16, window.innerHeight - r.height - 8);
  tipEl.style.top = Math.round(Math.max(8, acima >= limite ? acima : abaixo)) + window.scrollY + "px";
}

/* ═══ 1 · O ESTADO, MEDIDO ══════════════════════════════════════════ */

function painelEstado(d) {
  const v = d.validacao;
  const testesTotal = v.gdunit_discovered;
  const abertas = d.perguntas.filter((p) => p.estado === "aberta").length;

  // Os estados dos tickets vêm do texto livre de `tickets.json`. Três
  // baldes, e a regra é a do próprio ficheiro: «feito» só quando não
  // traz ressalva.
  const balde = (t) => {
    const e = t.estado.toLocaleLowerCase("pt-PT");
    if (/^por fazer/.test(e)) return "porFazer";
    if (/parcial|falta|pendente/.test(e)) return "parcial";
    if (/^feito/.test(e)) return "feito";
    return "porFazer";
  };
  const contas = { feito: 0, parcial: 0, porFazer: 0 };
  for (const t of d.tickets) contas[balde(t)]++;

  const sec = el("section", { id: "x-estado" });
  sec.innerHTML =
    `<span class="sec-no">★ — Estado</span>` +
    `<h3>Onde é que isto está, medido</h3>` +
    `<p class="lede">O dossiê tem ${d.validacao.spec_sections ?? 85} secções de intenção. Este painel tem o que foi <strong>executado</strong> ` +
    `— e, com o mesmo destaque, o que <strong>não</strong> foi. Os números vêm de ` +
    `<code>docs/recovery/validation.json</code> (medido a ${v.date}), do inventário do repositório e da contagem dos CSV; ` +
    `nenhum foi escrito à mão aqui.</p>` +

    `<div class="x-cartoes">` +
      cartao("Testes a passar", v.gdunit_passed, "de " + testesTotal + " descobertos",
             v.gdunit_failures === 0 ? selo("ok", "zero falhas") : selo("grave", v.gdunit_failures + " falhas")) +
      cartao("Contratos pendentes", v.gdunit_skipped, "comportamento por implementar", selo("aviso", "por fazer")) +
      cartao("Recursos gerados", v.generated_resources, "de " + v.csv_tables + " tabelas", selo("ok", "zero divergências")) +
      cartao("Perguntas em aberto", abertas, "de " + d.perguntas.length + " registadas", selo("aviso", "decide o dono")) +
      cartao("Tickets", d.tickets.length, contas.feito + " feitos · " + contas.parcial + " parciais", selo("parado", contas.porFazer + " por fazer")) +
      cartao("Jogabilidade", "0", "nenhum minuto jogável", selo("grave", "ainda não existe")) +
    `</div>` +

    `<h4 id="x-estado-testes">Os ${testesTotal} testes, e o que os ${v.gdunit_skipped} pendentes significam</h4>` +
    `<div id="x-fig-testes"></div>` +

    `<h4 id="x-estado-tickets">Os ${d.tickets.length} tickets, pelo estado que o ficheiro declara</h4>` +
    `<div id="x-fig-tickets"></div>` +

    `<h4 id="x-estado-nao">O que NÃO foi verificado</h4>` +
    `<p>Um painel de estado que só mostrasse verdes seria um painel de marketing. Estas seis linhas ` +
    `são a razão pela qual o dossiê continua a dizer «ainda não há gameplay»:</p>` +
    `<ul id="x-nao-verificado">` +
      naoVerificado("Exportação", v.export_tested, "Nenhum executável foi produzido.") +
      naoVerificado("GPU e arte", v.gpu_art_tested, "A medição correu sem placa gráfica; LUT, luz e silhuetas continuam por ver.") +
      naoVerificado("Playtest", v.gameplay_tested, "Ninguém jogou. Os números de balanceamento continuam a ser pontos de partida.") +
      `<li>${selo("grave", "não corrido")} <strong>CI remoto</strong> — a suite correu localmente; o portão do GitHub nunca viu este código.</li>` +
      `<li>${selo("grave", "não feito")} <strong>Push e deploy</strong> — o repositório não tem remoto.</li>` +
      `<li>${selo("aviso", "em falta")} <strong>Fontes ausentes</strong> — ${esc(v.source_gaps.join("; "))}.</li>` +
    `</ul>` +

    `<div class="note risk"><span class="lbl">A distinção que o dossiê pede, e que este painel respeita</span>` +
    `<p><strong>Gerado</strong>, <strong>medido</strong> e <strong>aprovado</strong> são três coisas. Os ` +
    `${v.generated_resources} recursos foram <em>gerados</em> e o <code>--check</code> confirma que voltam a sair iguais; ` +
    `os ${v.proposed_fields} campos propostos nos CSV (${v.proposed_phase_0_to_2} nas fases 0–2) continuam ` +
    `<em>propostas</em> — a coluna <code>_proposed</code> existe precisamente para que ninguém os leia como decisões. ` +
    `Nada nesta página aprova o que quer que seja.</p></div>` +

    prov({
      fonte: "Empire-v6.zip · docs/recovery/v6-validation.json, docs/backlog/tickets.json, docs/QUESTIONS.md, data/source/*.csv",
      data: v.date,
      nota: "motor " + v.engine + " · gdUnit4 " + v.gdunit,
    });

  return sec;
}

function cartao(k, valor, meta, estado) {
  return `<div class="x-cartao"><span class="x-k">${esc(k)}</span>` +
    `<span class="x-v">${esc(String(valor))}</span>` +
    `<p class="x-meta">${esc(meta)}<br>${estado || ""}</p></div>`;
}
function naoVerificado(nome, feito, porque) {
  return `<li>${feito ? selo("ok", "verificado") : selo("grave", "não corrido")} <strong>${esc(nome)}</strong> — ${esc(porque)}</li>`;
}

/* ─── Figura: barra segmentada dos testes ──────────────────────────
   Forma escolhida pela tarefa: três partes de um todo conhecido e
   pequeno. Um donut daria a mesma informação e obrigaria a comparar
   ângulos; uma barra segmentada compara comprimentos, que é o que o
   olho faz bem. Cada segmento leva rótulo — a cor é o reforço. */

function figuraTestes(v) {
  const partes = [
    { n: v.gdunit_passed, rot: "Passaram", tipo: "ok", nota: "dados e infraestrutura" },
    { n: v.gdunit_skipped, rot: "Pendentes", tipo: "aviso", nota: "16 contratos da Parte XIII + G3/EventBus" },
    { n: v.gdunit_failures, rot: "Falharam", tipo: "grave", nota: "" },
  ].filter((p) => p.n > 0 || p.rot === "Falharam");
  const total = v.gdunit_discovered;
  const rotulo = `Dos ${total} testes descobertos, ${v.gdunit_passed} passaram, ${v.gdunit_skipped} ficaram pendentes e ${v.gdunit_failures} falharam.`;

  const fig = el("figure", { class: "x-fig" });
  const caixa = el("div");
  fig.appendChild(caixa);
  const pinta = { ok: "--ok", aviso: "--aviso", grave: "--grave" };

  responsiva(fig, (W) => {
    const H = 56, GAP = 2;
    const s = svgBase(W, H, rotulo);
    let x = 0, corpo = "";
    for (const p of partes) {
      if (!p.n) continue;
      const w = (p.n / total) * W - GAP;
      // 3px de raio na ponta dos dados e 2px de folga entre segmentos:
      // sem a folga, dois segmentos vizinhos leem-se como um só.
      corpo +=
        `<rect x="${x.toFixed(1)}" y="0" width="${Math.max(2, w).toFixed(1)}" height="24" rx="3" fill="var(${pinta[p.tipo]})"/>` +
        `<text x="${x.toFixed(1)}" y="44" class="x-eixo" style="fill:var(--ink)">${p.n}</text>`;
      // O nome só entra se lá couber; o valor entra sempre, e a legenda
      // do `figcaption` diz o resto. Um rótulo cortado é pior que nenhum.
      const larguraNome = p.rot.length * 6.6 + 20;
      if (w > larguraNome) {
        corpo += `<text x="${(x + String(p.n).length * 8 + 6).toFixed(1)}" y="44" class="x-eixo">${esc(p.rot.toLowerCase())}</text>`;
      }
      x += (p.n / total) * W;
    }
    s.innerHTML = corpo;
    caixa.innerHTML = "";
    caixa.appendChild(s);
  });

  fig.insertBefore(el("div", { class: "x-legenda" },
    `<span><i style="background:var(--ok)"></i>${ESTADO_ICO.ok} passaram</span>` +
    `<span><i style="background:var(--aviso)"></i>${ESTADO_ICO.aviso} pendentes</span>` +
    `<span><i style="background:var(--grave)"></i>${ESTADO_ICO.grave} falharam</span>`), caixa);

  fig.appendChild(el("figcaption", {},
    `Os ${v.gdunit_skipped} pendentes não são falhas: são contratos de comportamento cujo código ainda não existe — ` +
    `os 16 da Parte XIII e o G3/EventBus. ${v.gdunit_discovered} descobertos não são ${v.gdunit_discovered} aprovados.`));
  return fig;
}

/* ─── Figura: tickets por estado, dentro de cada fase ──────────────
   As fases são ORDINAIS (0 vem antes de 1), portanto uma rampa de um
   matiz só e não cores de identidade. Os estados são uma escala de
   estado e usam a paleta de estado, com ícone e palavra na legenda. */

function figuraTickets(d) {
  const balde = (t) => {
    const e = t.estado.toLocaleLowerCase("pt-PT");
    if (/^por fazer/.test(e)) return 2;
    if (/parcial|falta|pendente/.test(e)) return 1;
    if (/^feito/.test(e)) return 0;
    return 2;
  };
  const fases = [...new Set(d.tickets.map((t) => t.fase))].sort();
  const linhas = fases.map((f) => {
    const ts = d.tickets.filter((t) => t.fase === f);
    const c = [0, 0, 0];
    for (const t of ts) c[balde(t)]++;
    return { fase: f, c, total: ts.length };
  });
  const maxT = Math.max(...linhas.map((l) => l.total));

  const fig = el("figure", { class: "x-fig" });
  fig.innerHTML =
    `<div class="x-legenda">` +
    `<span><i style="background:var(--ok)"></i>${ESTADO_ICO.ok} feito</span>` +
    `<span><i style="background:var(--aviso)"></i>${ESTADO_ICO.aviso} parcial</span>` +
    `<span><i style="background:var(--parado)"></i>${ESTADO_ICO.parado} por fazer</span></div>`;
  const caixa = el("div");
  fig.appendChild(caixa);

  responsiva(fig, (W) => {
    // Abaixo de 420px o rótulo da fase não cabe ao lado da barra: passa
    // para cima dela. É a mesma figura, reorganizada — não é a mesma
    // figura encolhida, que é o que um `viewBox` fixo faria.
    const estreito = W < 420;
    const ALT = 26, ROT = estreito ? 0 : 96, ESP = estreito ? 34 : 12;
    const H = linhas.length * (ALT + ESP) + (estreito ? 4 : 0);
    const s = svgBase(W, H, "Tickets por fase e estado.");
    const larg = W - ROT - 40;
    const cores = ["var(--ok)", "var(--aviso)", "var(--parado)"];
    let y = 0, corpo = "";
    for (const l of linhas) {
      const topo = estreito ? y + 14 : y;
      if (estreito) corpo += `<text x="0" y="${y + 10}" class="x-eixo" style="fill:var(--ink)">${esc(l.fase)}</text>`;
      else corpo += `<text x="0" y="${y + 18}" class="x-eixo" style="fill:var(--ink)">${esc(l.fase)}</text>`;
      let x = ROT;
      l.c.forEach((n, i) => {
        if (!n) return;
        const w = (n / maxT) * larg - 2;
        corpo +=
          `<rect x="${x.toFixed(1)}" y="${topo}" width="${Math.max(3, w).toFixed(1)}" height="${ALT}" rx="3" fill="${cores[i]}"/>` +
          (w > 20 ? `<text x="${(x + 6).toFixed(1)}" y="${topo + 18}" class="x-eixo" style="fill:var(--ground)">${n}</text>` : "");
        x += (n / maxT) * larg;
      });
      corpo += `<text x="${Math.min(W - 4, x + 7).toFixed(1)}" y="${topo + 18}" class="x-eixo" text-anchor="${x + 7 > W - 34 ? "end" : "start"}">${l.total}</text>`;
      y += ALT + ESP;
    }
    s.innerHTML = corpo;
    caixa.innerHTML = "";
    caixa.appendChild(s);
  });

  fig.appendChild(el("figcaption", {},
    "«Feito» aqui é o que o próprio ficheiro declara — e quase todos os feitos trazem ressalva " +
    "(«feito na v5.2 — falta o remoto», «parcial»). O inventário abaixo mostra a frase inteira de cada um."));
  return fig;
}

/* ═══ 2 · O SIMULADOR DE ECONOMIA ═══════════════════════════════════
   ┌─────────────────────────────────────────────────────────────────────┐
   │ O QUE ESTAVA ERRADO, MEDIDO — E NÃO ERA O DESENHO                    │
   │                                                                     │
   │ 1 · O GRÁFICO NÃO MOSTRAVA O FACTO QUE LHE DÁ NOME. A §06 chama-se   │
   │     «a curva, e o dia da asfixia» e diz, com todas as letras: «este  │
   │     é o tipo de erro que uma tabela esconde e um gráfico apanha em   │
   │     cinco segundos». Nos valores do próprio autor (7 fontes, 0       │
   │     rotas, 14 tropas, 28%) o cruzamento acontece a 5,7 px da base    │
   │     de um desenho de 250 px — 2,3% da altura. Os dias 1 a 19 vivem   │
   │     todos dentro dos 7% de baixo, empilhados numa linha. A culpa     │
   │     não é do desenho: é da escala. Três exponenciais (1,12 · 1,08 ·  │
   │     1,22) num eixo linear que tem de chegar a 1 949 esmagam os       │
   │     primeiros vinte dias contra o chão.                             │
   │                                                                     │
   │ 2 · O MAPA DAS RÉGUAS ERA ILEGÍVEL PARA UMA PESSOA EM CADA DOZE.     │
   │     As faixas usavam os quatro tokens de estado. Medidos com o       │
   │     validador de paleta: `--ok` contra `--aviso` dá ΔE 3,2 sob       │
   │     protanopia no claro, e `--ok` contra `--grave` dá ΔE 2,5 sob     │
   │     deuteranopia no escuro. O mínimo utilizável é 6. As cores do     │
   │     GRÁFICO tinham sido corrigidas para isto na passagem anterior;   │
   │     as das RÉGUAS, que são o mapa que se lê a arrastar, não.         │
   │                                                                     │
   │ 3 · A FAIXA VERDE ANUNCIAVA UM ESTADO QUE NÃO EXISTE. «Aguenta os    │
   │     30 dias» estava na legenda, pintada de `--ok`. Varridas as       │
   │     343 434 combinações dos quatro cursores: a asfixia chega em      │
   │     TODAS, o mais tarde ao dia 28 — exactamente como a §06 afirma    │
   │     («mesmo com tudo no máximo, a asfixia chega ao dia 28»). A       │
   │     legenda descrevia um território vazio, e pintava-o de bom.       │
   │                                                                     │
   │ 4 · E PINTAVA DE ÂMBAR O QUE A PRÓPRIA §06 CHAMA CERTO. O alvo de    │
   │     design publicado é «entre o dia 9 e o dia 14», e o número        │
   │     grande já ficava verde lá dentro — mas o carril por baixo dele   │
   │     dizia «a meio» em âmbar. Duas peças a dizer coisas diferentes    │
   │     sobre o mesmo dia.                                              │
   │                                                                     │
   │ 5 · A DICA DO GRÁFICO TAPAVA OS CURSORES. `tip()` põe a caixa ACIMA  │
   │     do ponto que recebe, e o gráfico passava-lhe o TOPO do desenho:  │
   │     a caixa aterrava sempre por cima da grelha de réguas.           │
   │                                                                     │
   │ A MATEMÁTICA NÃO MUDA. É a da §06, copiada linha a linha. Mudar um   │
   │ expoente aqui seria uma camada de interface a inventar balanceamento │
   │ — que é exactamente o que o dossiê proíbe. O que muda é a ESCALA em  │
   │ que se lê, que é uma decisão de leitura e não de modelo, e está      │
   │ dita no ecrã com um comutador ao lado.                              │
   └─────────────────────────────────────────────────────────────────────┘ */

/** §06, texto do autor: «Alvo de design: entre o dia 9 e o dia 14». */
const ALVO = { de: 9, ate: 14 };
const DIAS = 30;

/**
 * A que distância do alvo, em dias. Zero é dentro.
 *
 * `0` significa «não asfixiou em 30 dias» — que a varredura das 343 434
 * combinações mostra ser impossível neste modelo, mas que fica tratado
 * como o pior caso possível em vez de silenciosamente ausente: se alguém
 * mexer nos expoentes da §06, o mapa passa a ter esse território e a
 * legenda ganha-o sozinha.
 */
const distanciaAoAlvo = (d) => (d === 0 ? 99 : d < ALVO.de ? ALVO.de - d : d > ALVO.ate ? d - ALVO.ate : 0);

/* ┌─────────────────────────────────────────────────────────────────────┐
   │ PORQUE É QUE O CARRIL DEIXOU DE TER QUATRO CORES E PASSOU A TER TRÊS │
   │                                                                     │
   │ Vermelho–âmbar–verde–cinzento é um mapa DIVERGENTE: bom no meio,     │
   │ mau dos dois lados. Só que num carril o lado JÁ ESTÁ CODIFICADO —    │
   │ pela posição. Vê-se onde a pega está. Gastar matiz a repetir uma     │
   │ coisa que a geometria já diz é o que obriga a pôr vermelho ao lado   │
   │ de verde, e vermelho ao lado de verde é o par que a visão            │
   │ deficiente não separa (ΔE 2,5 sob deuteranopia).                    │
   │                                                                     │
   │ Sobra a informação que a geometria NÃO dá: a que distância do alvo   │
   │ se está. Isso é uma grandeza, e uma grandeza pinta-se com uma        │
   │ rampa de um matiz só, com a luminosidade a subir. Passa em todas as  │
   │ verificações ordinais (monotonia, ΔL ≥ 0,06 entre degraus, contraste │
   │ do degrau mais pálido contra a superfície, dispersão de matiz ≤ 40°) │
   │ e continua legível em cinzento, em impressão e em cores forçadas —   │
   │ porque a diferença é de LUMINOSIDADE, não de matiz.                 │
   │                                                                     │
   │ O degrau mais forte é o `--ok` que o documento já tem. O alvo não    │
   │ ganha uma cor nova: ganha a cor que o documento já usa para «certo». │
   └─────────────────────────────────────────────────────────────────────┘ */
const faixaDoDia = (d) => {
  const x = distanciaAoAlvo(d);
  return x === 0 ? "alvo" : x <= 4 ? "perto" : "longe";
};
/* Curtas de propósito: a 360px a legenda é uma coluna de três linhas, e
   uma entrada que se parte a meio deixa a amostra de cor a flutuar ao
   lado de duas linhas de texto. */
const FAIXAS = {
  alvo: `no alvo da §06 (dia ${ALVO.de}–${ALVO.ate})`,
  perto: "a menos de 5 dias do alvo",
  longe: "a 5 dias ou mais do alvo",
};
/** Do mais forte ao mais pálido. É a ordem em que a legenda se lê. */
const ORDEM_FAIXAS = ["alvo", "perto", "longe"];

/* ═══════════════════════════════════════════════════════════════════════
   A RÉGUA — arrastar sobre um MAPA, não sobre uma barra
   ---------------------------------------------------------------------
   ┌─────────────────────────────────────────────────────────────────────┐
   │ PORTADO DE `src/components/precos/ReguaPreco.tsx` E DE `faixas.ts`   │
   │                                                                     │
   │ Os quatro cursores da §06 eram `input[type=range]` crus: um traço    │
   │ do sistema, uma bolinha, e um `accent-color` azul que nem sequer é   │
   │ deste documento. Arrastar não dizia nada até se largar e ler o       │
   │ gráfico. A régua do Preço resolve isto de uma forma que se aplica    │
   │ aqui sem mudar uma vírgula: o carril deixa de ser uma barra e passa  │
   │ a ser um MAPA, e a cor diz o que acontece se largares ali.          │
   └─────────────────────────────────────────────────────────────────────┘

   AS CINCO REGRAS DO ORIGINAL, E O QUE CADA UMA CORRIGIU AQUI:

   ① UM SISTEMA DE COORDENADAS SÓ. Tudo — faixas, divisórias, pino e pega
     — é posicionado por `pos()`, com a mesma correção de meia-pega. Em
     percentagem pura a fronteira de uma faixa e o traço que a marca
     separam-se até 14px nos extremos, e quem olha conclui, e bem, que
     uma delas está errada.

   ② E O SISTEMA TEM DE SER O DA GRANDEZA, NÃO O DA PEGA. A versão
     anterior desenhava a faixa dos valores `a..b` de `pos(a)` a
     `pos(b+passo)`: meio passo à direita do sítio certo. Com o cursor
     das fontes (17 valores) isso são 3% do carril — a pega no primeiro
     valor de uma faixa aparecia EM CIMA da fronteira, e a cor por baixo
     dela era a da faixa anterior. Um valor discreto ocupa de `a−½` a
     `b+½`; é essa a caixa que se pinta.

   ③ SEM PREENCHIMENTO. Um gradiente da esquerda até à pega tapa
     precisamente a metade que mais interessa ler. A pega já diz onde
     estás; o carril não tem de o repetir.

   ④ AS DIVISÓRIAS SÃO A SUPERFÍCIE A PASSAR POR ENTRE AS FAIXAS. Eram um
     `border-inline-end` DENTRO da faixa — dois pixéis comidos ao
     território, com a cor a mudar dois pixéis antes da fronteira, que é
     o mesmo pecado do ①, mais pequeno. Passam a ser marcas próprias,
     centradas na fronteira (`margin-inline-start:-1px`).

   ⑤ O ALFINETE DO RECOMENDADO. No Preço marca o preço que o motor
     recomenda; aqui marca o valor que a §06 publica. Sem ele, mexer num
     cursor é uma porta sem retorno — e o «Repor a §06» que o acompanha
     refere-se a um sítio que tem de se ver.

   E o `input` nativo continua lá, invisível por cima: dá setas, Home/End,
   PageUp/PageDown, leitor de ecrã e arrasto por dedo de graça. A
   acessibilidade não é reimplementada — é herdada. O que se lhe
   acrescenta é o `aria-valuetext`, para que quem navega às setas ouça o
   MAPA e não só o número: «12 tropas — asfixia ao dia 11, no alvo».
   ═══════════════════════════════════════════════════════════════════════ */

const PEGA = 22;

/**
 * Envolve um `input[type=range]` numa régua com mapa.
 *
 * @param {HTMLInputElement} input   o comando, que continua a mandar
 * @param {object} o
 *   o.mapa()      → [{v, d}] uma entrada por valor possível do cursor
 *   o.faixaDe(p)  → a chave da faixa de um ponto do mapa
 *   o.nomes       → chave → nome legível (para o `title` e a legenda)
 *   o.nota(v,mapa)→ {html, chave} a linha por baixo
 *   o.fala(v,mapa)→ o `aria-valuetext`
 *   o.padrao      → o valor que o documento publica, marcado com o pino
 */
function regua(input, o) {
  const min = +input.min, max = +input.max, passo = +input.step || 1;
  const amplitude = Math.max(1e-9, max - min);

  /**
   * A ÚNICA geometria. `bruta` deixa sair das pontas de propósito: as
   * fronteiras de faixa vivem a meio passo para fora dos extremos, e é a
   * bandeira `primeira`/`ultima` que as encosta ao carril — como no
   * original, onde a primeira faixa é `left-0` e a última `right-0`.
   */
  const bruta = (v) => {
    const f = (v - min) / amplitude;
    return `calc(${(f * 100).toFixed(4)}% + ${((0.5 - f) * PEGA).toFixed(3)}px)`;
  };
  const pos = (v) => bruta(Math.min(max, Math.max(min, v)));

  const env = el("div", { class: "x-regua" });
  input.replaceWith(env);
  const carril = el("div", { class: "x-regua-carril", "aria-hidden": "true" });
  const pino = el("span", { class: "x-regua-pino", "aria-hidden": "true" });
  const pega = el("span", { class: "x-regua-pega", "aria-hidden": "true" });
  const nota = el("p", { class: "x-regua-nota" });
  input.classList.add("x-regua-nativa");
  env.append(carril, pino, pega, input, nota);

  if (o.padrao != null) {
    pino.style.insetInlineStart = pos(o.padrao);
    pino.title = `o valor da §06: ${o.padrao}`;
  } else {
    pino.hidden = true;
  }

  /* O carril só se reconstrói quando o TERRITÓRIO muda. Arrastar o
     próprio cursor não muda o mapa dele — muda o dos outros três. */
  let assinatura = null;

  const pintar = () => {
    const mapa = o.mapa();
    const chaves = mapa.map((p) => o.faixaDe(p));
    const assina = chaves.join("");
    if (assina !== assinatura) {
      assinatura = assina;
      carril.innerHTML = "";
      const corridas = [];
      for (let i = 0; i < mapa.length; ) {
        let j = i;
        while (j + 1 < mapa.length && chaves[j + 1] === chaves[i]) j++;
        corridas.push({ k: chaves[i], de: mapa[i].v, ate: mapa[j].v });
        i = j + 1;
      }
      corridas.forEach((c, i) => {
        const faixa = el("span", { class: "x-regua-faixa", "data-f": c.k });
        // Um valor discreto ocupa meio passo para cada lado. As pontas
        // encostam ao carril para não sobrar fundo nos cantos.
        faixa.style.insetInlineStart = i === 0 ? "0" : bruta(c.de - passo / 2);
        faixa.style.insetInlineEnd =
          i === corridas.length - 1 ? "0" : `calc(100% - ${bruta(c.ate + passo / 2)})`;
        faixa.title = o.nomes[c.k] || "";
        carril.appendChild(faixa);
        // A divisória é a superfície a passar por entre as faixas —
        // centrada na fronteira, e por isso o sítio onde a cor muda e o
        // sítio onde o número muda são o mesmo.
        if (i > 0) {
          const div = el("span", { class: "x-regua-div" });
          div.style.insetInlineStart = bruta(c.de - passo / 2);
          carril.appendChild(div);
        }
      });
    }

    const v = +input.value;
    pega.style.insetInlineStart = pos(v);
    const aqui = mapa.reduce((a, p) => (Math.abs(p.v - v) < Math.abs(a.v - v) ? p : a), mapa[0]);
    const k = aqui ? o.faixaDe(aqui) : "";
    pega.dataset.f = k;
    const n = o.nota(v, mapa);
    /* O separador é um nó de texto SOLTO entre os dois spans, e não a
       folga do `flex` nem um prefixo dentro do segundo: `textContent`
       cola os filhos («dia 11alvo 6–9 fontes»), e é assim que a linha
       chega a um leitor de ecrã, a um recorte e a um portão. Num
       contentor `flex` este nó vira um item anónimo e alinha-se com os
       outros. */
    nota.innerHTML = `<span class="x-regua-f" data-f="${esc(k)}">${n.forte}</span>` +
      (n.fraco ? ` · <span class="x-regua-mais">${n.fraco}</span>` : "");
    input.setAttribute("aria-valuetext", o.fala(v, mapa));
  };

  return { pintar, env, input };
}

function montarSimulador() {
  const CH = $("#chart");
  if (!CH) return;
  const ids = { fontes: "f-fontes", rotas: "f-rotas", tropas: "f-tropas", ganancia: "f-ganancia" };
  const ctl = {};
  for (const k in ids) {
    const antigo = document.getElementById(ids[k]);
    if (!antigo) return;
    // Clonar deixa cair os ouvintes do desenho original — sem isto os
    // dois desenhos disputavam o mesmo `innerHTML` a cada movimento.
    const novo = antigo.cloneNode(true);
    antigo.replaceWith(novo);
    ctl[k] = novo;
  }
  const CHAVES = Object.keys(ctl);
  /** Os valores que o documento publica. Lidos ANTES de qualquer toque. */
  const PADRAO = {};
  for (const k of CHAVES) PADRAO[k] = +ctl[k].value;

  /* Singular e plural. «alvo até 1 rotas» é o tipo de erro que ninguém
     reporta e toda a gente lê — e neste cursor o 1 é um valor comum. */
  const UNIDADE = {
    fontes: ["fonte", "fontes"], rotas: ["rota", "rotas"],
    tropas: ["tropa", "tropas"], ganancia: ["%", "%"],
  };
  const un = (k, n) => UNIDADE[k][Math.abs(n) === 1 ? 0 : 1];
  /** Por extenso, para o `aria-valuetext`, onde «28 %» não diz de quê. */
  const UNIDADE_FALADA = {
    fontes: "fontes de produção", rotas: "rotas de comércio",
    tropas: "tropas mantidas", ganancia: "por cento de ganância do rei",
  };
  const ROTULO = {
    fontes: "Fontes de produção", rotas: "Rotas de comércio",
    tropas: "Tropas mantidas", ganancia: "Ganância do rei",
  };

  const valores = () => {
    const v = {};
    for (const k of CHAVES) v[k] = +ctl[k].value;
    return v;
  };

  /* ─── O modelo da §06, palavra por palavra ─────────────────────── */
  const upkeep = (n) => (n <= 8 ? 0 : n <= 20 ? (n - 8) * 0.5 : 12 * 0.5 + (n - 20) * 1.5);

  const modelo = (v) => {
    const { fontes: F, rotas: R, tropas: T, ganancia: G } = v;
    const up = upkeep(T), base = 3 + F * 2.6;
    const rede = R > 1 ? 1 + 0.1 * (R - 1) : 1;
    const bruto = [], liquido = [], custo = [], comercio = [];
    let asfixia = 0;
    for (let d = 1; d <= DIAS; d++) {
      const prod = base * Math.pow(1.12, d - 1);
      const com = R * 4.5 * Math.pow(1.08, d - 1) * rede;
      const gr = prod + com;
      const nt = gr * (1 - G / 100) - up;
      bruto.push(gr); comercio.push(com * (1 - G / 100)); liquido.push(nt);
      custo.push(6.1 * Math.pow(1.22, d - 1));
      if (!asfixia && custo[d - 1] > nt) asfixia = d;
    }
    return { F, R, T, G, up, bruto, liquido, custo, comercio, asfixia };
  };

  /**
   * Só o dia, sem alocar as quatro séries.
   *
   * A varredura corre isto 151 vezes por movimento de cursor (17 + 6 +
   * 37 + 91 valores possíveis). Com `modelo()` seriam 151 × 4 arrays de
   * 30 por movimento, deitados fora a seguir. As duas funções TÊM de
   * concordar, e o portão confere-o em amostra — se alguém corrigir um
   * expoente numa e esquecer a outra, o mapa das réguas passa a descrever
   * uma economia que o gráfico não desenha.
   */
  const diaDaAsfixia = ({ fontes: F, rotas: R, tropas: T, ganancia: G }) => {
    const up = upkeep(T), base = 3 + F * 2.6;
    const rede = R > 1 ? 1 + 0.1 * (R - 1) : 1;
    for (let d = 1; d <= DIAS; d++) {
      const nt = (base * Math.pow(1.12, d - 1) + R * 4.5 * Math.pow(1.08, d - 1) * rede) * (1 - G / 100) - up;
      if (6.1 * Math.pow(1.22, d - 1) > nt) return d;
    }
    return 0;
  };
  window.__EMPIRE_SIM__ = { modelo, diaDaAsfixia, ALVO, faixaDoDia };

  /* ─── A varredura, com cache POR CURSOR ────────────────────────────
     O mapa do cursor `k` depende dos OUTROS TRÊS e não dele próprio.
     Guardar a chave com os quatro invalidava os quatro a cada
     movimento, e recalculava um mapa que não tinha mudado. */
  const cache = {};
  const mapaDe = (k) => {
    const v = valores();
    const chave = CHAVES.filter((o) => o !== k).map((o) => v[o]).join("|");
    if (cache[k] && cache[k].chave === chave) return cache[k].mapa;
    const min = +ctl[k].min, max = +ctl[k].max, passo = +ctl[k].step || 1;
    const mapa = [];
    for (let x = min; x <= max + 1e-9; x += passo) mapa.push({ v: x, d: diaDaAsfixia({ ...v, [k]: x }) });
    cache[k] = { chave, mapa };
    return mapa;
  };

  /** A corrida contígua de valores que põem a asfixia dentro do alvo. */
  const corridaDoAlvo = (mapa) => {
    let de = null, ate = null;
    for (const p of mapa) {
      if (distanciaAoAlvo(p.d) === 0) { if (de === null) de = p.v; ate = p.v; }
    }
    return de === null ? null : { de, ate };
  };

  /* ═══ AS RÉGUAS ═══════════════════════════════════════════════════
     ┌───────────────────────────────────────────────────────────────┐
     │ A LINHA POR BAIXO TEM DE DIZER ALGO PRÓPRIO DESTE CURSOR       │
     │                                                               │
     │ A primeira versão punha o dia da asfixia — e as quatro réguas  │
     │ diziam «asfixia ao dia 11», porque o dia é um só. A segunda    │
     │ punha o ALCANCE («alcança 1–21»), que já é próprio de cada     │
     │ cursor mas responde a uma pergunta que ninguém faz: o alcance  │
     │ inclui territórios que não interessam a ninguém.              │
     │                                                               │
     │ A pergunta que se faz antes de arrastar é «onde é que ponho    │
     │ ISTO?», e a resposta é o intervalo que aterra no alvo que a    │
     │ §06 publica. É também a única coisa que a cor do carril não    │
     │ consegue dizer: o carril mostra ONDE fica verde, a linha diz   │
     │ em que NÚMEROS — e é com números que se edita                 │
     │ `data/economy/curve.tres`.                                    │
     └───────────────────────────────────────────────────────────────┘ */
  const diaEmPalavras = (d) => (d === 0 ? "não asfixia em 30 dias" : `dia ${d}`);
  const intervaloAlvo = (k, mapa) => {
    const c = corridaDoAlvo(mapa);
    if (!c) return `sozinho não chega ao alvo ${ALVO.de}–${ALVO.ate}`;
    const min = +ctl[k].min, max = +ctl[k].max;
    if (c.de <= min && c.ate >= max) return "todo o cursor fica no alvo";
    if (c.de <= min) return `alvo até ${c.ate} ${un(k, c.ate)}`;
    if (c.ate >= max) return `alvo desde ${c.de} ${un(k, c.de)}`;
    if (c.de === c.ate) return `alvo só em ${c.de} ${un(k, c.de)}`;
    return `alvo ${c.de}–${c.ate} ${un(k, c.ate)}`;
  };

  const reguas = {};
  for (const k of CHAVES) {
    reguas[k] = regua(ctl[k], {
      padrao: PADRAO[k],
      nomes: FAIXAS,
      mapa: () => mapaDe(k),
      faixaDe: (p) => faixaDoDia(p.d),
      nota: (v, mapa) => {
        const aqui = mapa.reduce((a, p) => (Math.abs(p.v - v) < Math.abs(a.v - v) ? p : a), mapa[0]);
        return { forte: esc(diaEmPalavras(aqui ? aqui.d : 0)), fraco: esc(intervaloAlvo(k, mapa)) };
      },
      fala: (v, mapa) => {
        const aqui = mapa.reduce((a, p) => (Math.abs(p.v - v) < Math.abs(a.v - v) ? p : a), mapa[0]);
        const d = aqui ? aqui.d : 0;
        const estado = distanciaAoAlvo(d) === 0 ? "no alvo" : `fora do alvo, que é do dia ${ALVO.de} ao ${ALVO.ate}`;
        return `${v} ${UNIDADE_FALADA[k]} — asfixia ${diaEmPalavras(d)}, ${estado}`;
      },
    });
  }

  /* A ajuda, a legenda e o «repor» vivem FORA das réguas, e por isso
     lêem-se uma vez. Repetidos quatro vezes eram ruído a ocupar a linha
     que devia dizer o dia.

     E a LEGENDA É DERIVADA do que os quatro mapas contêm. A versão
     anterior tinha-a escrita à mão, com quatro entradas — e uma delas,
     «aguenta os 30 dias», descrevia um estado que este modelo não
     produz em nenhuma das 343 434 combinações. Uma legenda escrita à
     mão envelhece no dia em que o modelo muda; esta não pode. */
  const grelha = $(".sim-ctl", CH.closest(".sim") || document);
  const legenda = el("div", { class: "x-regua-legenda" });
  const chaves = el("span", { class: "x-regua-chaves" });
  const btRepor = el("button", { type: "button", class: "x-bt-mini x-regua-repor", hidden: "" },
    `<svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true"><path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5"/></svg> <span>Repor a §06</span>`);
  legenda.append(chaves, btRepor);
  if (grelha) grelha.insertAdjacentElement("afterend", legenda);

  const pintarLegenda = () => {
    const presentes = new Set();
    for (const k of CHAVES) for (const p of mapaDe(k)) presentes.add(faixaDoDia(p.d));
    chaves.innerHTML = ORDEM_FAIXAS.filter((f) => presentes.has(f))
      .map((f) => `<span><i data-f="${f}"></i>${esc(FAIXAS[f])}</span>`).join("");
  };

  const mexido = () => CHAVES.some((k) => +ctl[k].value !== PADRAO[k]);
  btRepor.addEventListener("click", () => {
    for (const k of CHAVES) ctl[k].value = String(PADRAO[k]);
    atualizar();
    ctl[CHAVES[0]].focus();
  });

  /* ═══ O GRÁFICO ═══════════════════════════════════════════════════ */
  /* As duas calhas são MEDIDAS a cada desenho (ver `medirTexto`), por
     isso são variáveis e não constantes: `lerEm()` e a grelha têm de
     usar a mesma geometria que o desenho usou. */
  let W = 720, H = 300, PL = 46, PR = 116, curto = false;
  const PT = 22, PB = 34;

  const SERIES = [
    { k: "liquido", rot: "Líquido", abr: "Líq.", cor: "--s2", larg: 2 },
    { k: "custo", rot: "Custo da noite", abr: "Custo", cor: "--s3", larg: 2 },
    { k: "comercio", rot: "Comércio", abr: "Com.", cor: "--s1", larg: 2 },
    { k: "bruto", rot: "Bruto", abr: "Bruto", cor: "--s-ref", larg: 1.5, tracejado: true },
  ];

  /* ┌───────────────────────────────────────────────────────────────┐
     │ A ESCALA — porque é que a logarítmica passou a ser a de entrada │
     │                                                               │
     │ Nos valores do autor a linha do custo chega a 1 949 ao dia 30  │
     │ e o cruzamento acontece a 44,5. Num eixo linear que tem de     │
     │ mostrar os dois, o cruzamento fica a 2,3% da altura: seis      │
     │ pixéis acima da base, com as duas curvas sobrepostas e         │
     │ indistinguíveis desde o dia 1 até ao 19. Não é um problema de  │
     │ desenho — é a escala errada para três exponenciais.           │
     │                                                               │
     │ Em logarítmica, `1,12^d`, `1,08^d` e `1,22^d` saem DIREITAS, e │
     │ a inclinação de cada uma é o expoente que a §06 publica. O     │
     │ cruzamento passa a ser o encontro de duas rectas, visível ao   │
     │ longo de todos os trinta dias, e a distância entre elas ao dia │
     │ 1 passa de meio pixel para vinte e três.                      │
     │                                                               │
     │ NÃO se esconde a linear: fica um comutador ao lado, com a      │
     │ escolha guardada. Mudar de escala é uma decisão de leitura, e  │
     │ decisões de leitura pertencem a quem lê — mas a que se oferece │
     │ à entrada tem de ser a que mostra o facto.                    │
     │                                                               │
     │ Nem tudo o que se desenha é positivo: com poucas fontes e      │
     │ muitas tropas o líquido é negativo. Um `log` puro não tem      │
     │ resposta para isso, por isso a transformação é SIMÉTRICA —     │
     │ `sinal(v)·log10(1+|v|)` — que é contínua, passa pelo zero e    │
     │ trata os negativos como o espelho dos positivos.              │
     └───────────────────────────────────────────────────────────────┘ */
  const CHAVE_ESCALA = "empire.sim.escala.v1";
  let escala = "log";
  try { const g = localStorage.getItem(CHAVE_ESCALA); if (g === "linear" || g === "log") escala = g; } catch { /* modo privado */ }

  /** A transformação simétrica. `tLog(0) === 0`, e os negativos são o espelho. */
  const tLog = (v) => Math.sign(v) * Math.log10(1 + Math.abs(v));

  /**
   * O rótulo de uma marca do eixo.
   *
   * `num(v, 0)` escrevia «0» tanto para 0 como para 0,3 — duas marcas
   * diferentes com o mesmo nome, que é a forma mais rápida de um eixo
   * deixar de se poder ler. Abaixo de 1 escreve-se uma casa.
   */
  const rotuloEixo = (v) => num(v, v !== 0 && Math.abs(v) < 1 ? 1 : 0);

  /** Os degraus 1–3 de cada década, para os dois lados do zero. */
  const ESCADA = (() => {
    const p = [];
    for (let e = -1; e <= 4; e++) for (const m of [1, 3]) p.push(m * Math.pow(10, e));
    return [...p.map((x) => -x).reverse(), 0, ...p];
  })();

  /** Marcas lineares «bonitas»: 1-2-5 × década, com o topo NA marca. */
  const marcasLineares = (lo, hi, quantas) => {
    const cru = Math.max(1e-9, (hi - lo) / quantas);
    const mag = Math.pow(10, Math.floor(Math.log10(cru)));
    const n = cru / mag;
    const passo = (n <= 1 ? 1 : n <= 2 ? 2 : n <= 5 ? 5 : 10) * mag;
    const t0 = Math.floor(lo / passo) * passo, t1 = Math.ceil(hi / passo) * passo;
    const m = [];
    for (let v = t0; v <= t1 + passo * 1e-6; v += passo) m.push(Math.round(v * 1e6) / 1e6);
    return { marcas: m, min: t0, max: t1 };
  };

  const marcasLog = (lo, hi) => {
    const abaixo = ESCADA.filter((c) => c <= lo);
    const acima = ESCADA.filter((c) => c >= hi);
    const min = abaixo.length ? abaixo[abaixo.length - 1] : ESCADA[0];
    const max = acima.length ? acima[0] : ESCADA[ESCADA.length - 1];
    let m = ESCADA.filter((c) => c >= min && c <= max);
    // Sete rótulos é o limite antes de o eixo virar uma régua. Corta-se
    // pelos meios (os «3») e nunca pelas décadas.
    if (m.length > 8) m = m.filter((c) => c === 0 || Math.abs(Math.log10(Math.abs(c)) % 1) < 1e-9);
    return { marcas: m, min, max };
  };

  /* A vista de tabela é o alívio obrigatório de qualquer gráfico: quem
     não distingue as linhas, e quem quer o número exacto, tem por onde. */
  const envolve = CH.closest(".sim") || CH.parentElement;
  const barra = el("div", { class: "x-sim-barra" });

  /* ┌───────────────────────────────────────────────────────────────┐
     │ UM BOTÃO SÓ, ESCRITO «ESCALA», NÃO DIZ EM QUE ESCALA SE ESTÁ   │
     │                                                               │
     │ Um comutador cujo rótulo é o estado actual é ambíguo — «Escala │
     │ linear» tanto pode ser o que está como o que vai passar a      │
     │ estar, e a única forma de saber é carregar e ver. Dois botões  │
     │ com `aria-pressed`, dentro de um grupo com nome, dizem as duas │
     │ coisas ao mesmo tempo: quais são as opções, e qual é a que     │
     │ está a valer. É a mesma decisão que o `SeletorModo` toma.      │
     └───────────────────────────────────────────────────────────────┘ */
  const grupoEscala = el("div", { class: "x-seg", role: "group", "aria-label": "Escala do eixo vertical" });
  const btsEscala = {};
  for (const [ch, rot] of [["log", "Logarítmica"], ["linear", "Linear"]]) {
    const b = el("button", { type: "button", class: "x-seg-b", "aria-pressed": String(escala === ch) }, esc(rot));
    b.addEventListener("click", () => {
      if (escala === ch) return;
      escala = ch;
      try { localStorage.setItem(CHAVE_ESCALA, escala); } catch { /* modo privado */ }
      for (const c in btsEscala) btsEscala[c].setAttribute("aria-pressed", String(c === escala));
      desenhar();
    });
    btsEscala[ch] = b;
    grupoEscala.appendChild(b);
  }
  const btTab = el("button", { type: "button", class: "x-tab-toggle x-bt-mini", "aria-expanded": "false", "aria-controls": "x-sim-tabela" },
    `<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.7" aria-hidden="true"><rect x="3" y="4" width="18" height="16" rx="1.5"/><path d="M3 10h18M9 10v10"/></svg> <span>Ver como tabela</span>`);
  barra.append(el("span", { class: "x-seg-rot" }, "Escala"), grupoEscala, btTab);
  const vista = el("div", { class: "x-tabela-vista tw", id: "x-sim-tabela", hidden: "" });
  const notaEscala = el("p", { class: "x-prov x-sim-escala-nota" });
  /* Os comandos do gráfico ficam ENCOSTADOS ao gráfico, não no fim do
     bloco: `appendChild` punha-os depois das métricas e do «o que mais
     mexe», a três ecrãs de distância da coisa que comandam. */
  const ancoraCh = $(".lg", envolve) || CH;
  ancoraCh.insertAdjacentElement("afterend", vista);
  ancoraCh.insertAdjacentElement("afterend", notaEscala);
  ancoraCh.insertAdjacentElement("afterend", barra);

  btTab.addEventListener("click", () => {
    const aberto = !vista.hidden;
    vista.hidden = aberto;
    btTab.setAttribute("aria-expanded", String(!aberto));
    $("span", btTab).textContent = aberto ? "Ver como tabela" : "Esconder a tabela";
  });

  /* ┌───────────────────────────────────────────────────────────────┐
     │ A LEGENDA JÁ EXISTIA — REPINTA-SE, NÃO SE DUPLICA              │
     │                                                               │
     │ A primeira versão acrescentou uma legenda por cima do gráfico  │
     │ e ficaram duas: a minha, com nomes curtos, e a do autor logo   │
     │ abaixo, com nomes melhores («Bruto (antes de sorvedouros)»).   │
     │ Fica a do autor, com as amostras repintadas nos passos de      │
     │ gráfico e mais duas entradas — a marca da asfixia e a janela   │
     │ do alvo — que eram as duas coisas desenhadas que a legenda não │
     │ explicava.                                                    │
     └───────────────────────────────────────────────────────────────┘ */
  const legendaCh = $(".lg", envolve);
  const ITENS = ["x-lg-liquido", "x-lg-custo", "x-lg-comercio", "x-lg-bruto"];
  if (legendaCh) {
    const spans = $$("span", legendaCh);
    const cores = ["--s2", "--s3", "--s1", "--s-ref"];
    spans.forEach((sp, i) => {
      const amostra = $("i", sp);
      if (!amostra || !cores[i]) return;
      sp.classList.add(ITENS[i]);
      amostra.style.background = `var(${cores[i]})`;
      amostra.style.opacity = "1";
      if (cores[i] === "--s-ref") {
        amostra.style.background = "none";
        amostra.style.borderTop = "2px dashed var(--s-ref)";
        amostra.style.height = "0";
      }
    });
    legendaCh.appendChild(el("span", { class: "x-lg-asfixia" },
      `<i style="background:none;border-top:2px dashed var(--ember);height:0"></i>Dia da asfixia`));
    legendaCh.appendChild(el("span", { class: "x-lg-alvo" },
      `<i class="x-am-alvo"></i>Alvo da §06: dia ${ALVO.de}–${ALVO.ate}`));
  }

  let m = null, geo = null;

  /* ┌───────────────────────────────────────────────────────────────┐
     │ MEDIR, NÃO ESTIMAR                                             │
     │                                                               │
     │ A conta dos «7,25 px por caractere» é verdadeira para a        │
     │ monoespaçada que o documento pede — e falsa para a que o       │
     │ browser usa quando essa não chega, que é o que acontece        │
     │ sempre que não há rede. Com a pilha de reserva o rótulo da     │
     │ asfixia cresce e, a 360px, aterrava por cima de «Custo».       │
     │                                                               │
     │ O SVG sabe medir. `getComputedTextLength()` devolve a largura  │
     │ real, na fonte real, no tamanho real — e com ela a calha da    │
     │ direita passa a ter exactamente a largura dos nomes que lá     │
     │ vão, em vez de 116 px escolhidos à mão. Num telemóvel isso     │
     │ devolve pixéis ao desenho; num ecrã grande impede o corte.     │
     │                                                               │
     │ Dentro de uma parte fechada não há caixa para medir e a medida │
     │ vem a zero: aí, e só aí, vale a estimativa.                   │
     └───────────────────────────────────────────────────────────────┘ */
  const POR_CARACTERE = 7.25;
  let fita = null;
  const medirTexto = (txt) => {
    if (!fita) {
      fita = document.createElementNS("http://www.w3.org/2000/svg", "text");
      fita.setAttribute("class", "x-eixo");
      fita.setAttribute("visibility", "hidden");
      fita.setAttribute("x", "-9999");
    }
    fita.textContent = txt;
    CH.appendChild(fita);
    let w = 0;
    try { w = fita.getComputedTextLength(); } catch { w = 0; }
    fita.remove();
    return w > 0 ? w : txt.length * POR_CARACTERE;
  };

  function desenhar(largura) {
    if (largura) {
      W = largura;
      // Abaixo de 560px os nomes inteiros das séries comem metade do
      // gráfico. A legenda continua lá e leva o nome por extenso; na
      // ponta da linha fica a abreviatura. A identidade nunca é só cor.
      curto = W < 560;
      H = Math.max(230, Math.min(340, Math.round(W * 0.54)));
    }
    m = modelo(valores());
    const { bruto, liquido, custo, comercio, asfixia, up, G } = m;
    const dados = { bruto, liquido, custo, comercio };
    const vivas = SERIES.filter((s) => !(s.k === "comercio" && m.R === 0));

    const agora = valores();
    for (const k of CHAVES) {
      const saida = $("#v-" + k);
      if (saida) saida.textContent = k === "ganancia" ? agora[k] + "%" : String(agora[k]);
    }

    const todos = [].concat(...vivas.map((s) => dados[s.k]));
    const lo = Math.min(...todos), hi = Math.max(...todos);

    let min, max, marcas, Yp;
    if (escala === "log") {
      /* O CHÃO encosta a uma marca — assim a grelha mais baixa vê-se e a
         escala tem um número onde começar. O TECTO não: encostá-lo à
         marca seguinte deixava até uma década inteira de papel vazio por
         cima da curva mais alta (1 949 empurrava o topo para 3 000, um
         terço da altura para nada). Fica o próprio máximo com 5% de
         folga, que é o suficiente para o ponto e o rótulo da ponta não
         tocarem na borda. */
      ({ marcas, min } = marcasLog(lo, hi));
      const t0 = tLog(min), tD = tLog(hi);
      const t1 = tD + Math.max(1e-9, tD - t0) * 0.05;
      max = hi;
      Yp = (v) => PT + (1 - (tLog(v) - t0) / Math.max(1e-9, t1 - t0)) * (H - PT - PB);
    } else {
      ({ marcas, min, max } = marcasLineares(Math.min(0, lo), hi, 5));
      Yp = (v) => PT + (1 - (v - min) / Math.max(1e-9, max - min)) * (H - PT - PB);
    }

    /* As duas calhas passam a ser medidas: a da esquerda cabe o maior
       número do eixo, a da direita cabe o maior nome de série. 116px
       escolhidos à mão sobravam num ecrã grande e faltavam com a fonte
       de reserva. */
    PL = Math.max(30, Math.min(90, Math.ceil(Math.max(...marcas.map((g) => medirTexto(rotuloEixo(g)))) + 14)));
    PR = Math.max(40, Math.min(180, Math.ceil(Math.max(...vivas.map((se) => medirTexto(curto ? se.abr : se.rot))) + 13)));
    const Xp = (d) => PL + ((d - 1) / (DIAS - 1)) * (W - PL - PR);
    const caminho = (a) => a.map((v, i) => (i ? "L" : "M") + Xp(i + 1).toFixed(1) + " " + Yp(v).toFixed(1)).join(" ");
    geo = { Xp, Yp, min, max };

    const s = [];

    /* ─── A janela do alvo, POR BAIXO de tudo ────────────────────────
       O alvo da §06 é um intervalo de dias, e um intervalo de dias
       desenha-se como uma faixa vertical. Com ela, «está no alvo?»
       deixa de ser uma comparação de números e passa a ser uma
       pergunta sobre POSIÇÃO: a linha tracejada cai dentro da faixa,
       ou não cai. Não precisa de cor nenhuma para se responder — o que
       é a única forma de a resposta sobreviver ao daltonismo, ao
       cinzento e à impressão. */
    const ax = Xp(ALVO.de), bx = Xp(ALVO.ate);
    s.push(`<rect x="${ax.toFixed(1)}" y="${PT}" width="${(bx - ax).toFixed(1)}" height="${(H - PT - PB).toFixed(1)}" class="x-alvo-faixa"/>`);
    const rotAlvo = `alvo ${ALVO.de}–${ALVO.ate}`;
    // Centrado na faixa, mas nunca a sair do desenho: com o alvo nos
    // primeiros dias e a calha da esquerda estreita, metade do rótulo
    // caía fora do `viewBox`.
    const lrgAlvo = medirTexto(rotAlvo);
    const xAlvo = Math.max(lrgAlvo / 2 + 2, Math.min((ax + bx) / 2, W - lrgAlvo / 2 - 2));
    s.push(`<text x="${xAlvo.toFixed(1)}" y="${(PT - 7).toFixed(1)}" class="x-eixo x-alvo-rot" text-anchor="middle">${esc(rotAlvo)}</text>`);

    for (const g of marcas) {
      const y = Yp(g);
      if (y < PT - 0.5 || y > H - PB + 0.5) continue;
      s.push(`<line x1="${PL}" y1="${y.toFixed(1)}" x2="${(W - PR).toFixed(1)}" y2="${y.toFixed(1)}" class="${g === 0 ? "x-zero" : "x-grelha"}"/>`);
      s.push(`<text x="${PL - 8}" y="${(y + 3.5).toFixed(1)}" class="x-eixo" text-anchor="end">${esc(rotuloEixo(g))}</text>`);
    }
    for (const d of curto ? [1, 10, 20, 30] : [1, 6, 12, 18, 24, 30]) {
      s.push(`<text x="${Xp(d).toFixed(1)}" y="${H - 12}" class="x-eixo" text-anchor="middle">d${d}</text>`);
    }

    if (asfixia) {
      const lx = Xp(asfixia);
      s.push(`<line x1="${lx.toFixed(1)}" y1="${PT}" x2="${lx.toFixed(1)}" y2="${(H - PB).toFixed(1)}" class="x-asf-linha"/>`);
      /* O rótulo tem de caber DENTRO do desenho, e a regra antiga («se
         a linha passou dos W−190, escreve para a esquerda») não garante
         isso: a 360px o desenho inteiro tem menos de 190, a condição dá
         sempre verdadeiro, e o texto saía pela esquerda — chegava ao
         ecrã como «fixia · dia 11». Escolhe-se o lado com mais espaço e
         grampeia-se ao desenho. Em monoespaçada a largura é previsível:
         12px de corpo dão cerca de 7,25px por caractere. */
      /* ── ONDE CABE O RÓTULO, E EM QUE TAMANHO ─────────────────────
         Três correções sobre a versão anterior, todas do mesmo tipo:
         ela decidia por estimativa e sem limites reais.

         · o limite da direita é o fim do DESENHO (`W − PR`), não o fim
           do SVG. A calha da direita é onde vivem os nomes das pontas
           das séries, e em escala logarítmica a ponta mais alta — o
           custo da noite — fica exactamente à altura deste rótulo;
         · o limite da esquerda é o início do desenho, senão o rótulo
           entra na coluna dos números do eixo;
         · e quando não cabe de nenhum dos lados, o que se faz NÃO é
           encostar à borda — é escrever menos. A versão anterior
           grampeava, e a 320px o resultado era o rótulo atravessado por
           cima da própria linha que estava a nomear. Aqui desce-se a
           «dia 11» e depois a «d11», que é o vocabulário do eixo x. */
      const esqLim = PL + 2, dirLim = W - PR;
      const colocar = (txt) => {
        const w = medirTexto(txt);
        if (lx + 7 + w <= dirLim) return { txt, x: lx + 7, anc: "start" };
        if (lx - 7 - w >= esqLim) return { txt, x: lx - 7, anc: "end" };
        return null;
      };
      const posto = colocar(`asfixia · dia ${asfixia}`) || colocar(`dia ${asfixia}`) || colocar(`d${asfixia}`) ||
        { txt: `d${asfixia}`, x: Math.max(2, Math.min(lx + 7, W - medirTexto(`d${asfixia}`) - 2)), anc: "start" };
      s.push(`<text x="${posto.x.toFixed(1)}" y="${(PT + 13).toFixed(1)}" class="x-eixo x-asf-rot" text-anchor="${posto.anc}">${esc(posto.txt)}</text>`);
      // O ponto onde as duas linhas se encontram. Uma linha vertical diz
      // QUANDO; o ponto diz onde é que isso acontece na curva.
      s.push(`<circle cx="${lx.toFixed(1)}" cy="${Yp(custo[asfixia - 1]).toFixed(1)}" r="4" class="x-asf-ponto"/>`);
    }

    /* ─── As linhas, e os rótulos que não se pisam ───────────────────
       Quatro rótulos na mesma coluna de 116px colidem sempre que duas
       séries acabam perto uma da outra — e em logarítmica isso é a
       regra, não a excepção. Empurram-se para um mínimo de 13px de
       intervalo, dentro do desenho, mantendo a ordem vertical: o rótulo
       de cima continua a ser o da série de cima. */
    const pontas = [];
    for (const se of vivas) {
      const arr = dados[se.k];
      s.push(`<path d="${caminho(arr)}" fill="none" stroke="var(${se.cor})" stroke-width="${se.larg}"` +
        `${se.tracejado ? ' stroke-dasharray="4 4" opacity=".85"' : ""} stroke-linejoin="round" stroke-linecap="round"/>`);
      pontas.push({ se, y: Yp(arr[DIAS - 1]) });
    }
    pontas.sort((a, b) => a.y - b.y);
    const GAP = 13, topo = PT + 5, base = H - PB - 3;
    for (let i = 0; i < pontas.length; i++) {
      pontas[i].ry = Math.max(pontas[i].y, topo + i * GAP);
    }
    for (let i = pontas.length - 1; i >= 0; i--) {
      pontas[i].ry = Math.min(pontas[i].ry, base - (pontas.length - 1 - i) * GAP);
      if (i > 0) pontas[i - 1].ry = Math.min(pontas[i - 1].ry, pontas[i].ry - GAP);
    }
    for (const p of pontas) {
      const x = Xp(DIAS);
      s.push(`<circle cx="${x.toFixed(1)}" cy="${p.y.toFixed(1)}" r="3.2" fill="var(${p.se.cor})" class="x-ponta"/>`);
      // Uma perna do ponto ao rótulo, quando o rótulo teve de fugir.
      if (Math.abs(p.ry - p.y) > 1.5) {
        s.push(`<path d="M${(x + 3.5).toFixed(1)} ${p.y.toFixed(1)} L${(x + 6).toFixed(1)} ${p.ry.toFixed(1)}" class="x-perna" stroke="var(${p.se.cor})"/>`);
      }
      s.push(`<text x="${(x + 7).toFixed(1)}" y="${(p.ry + 3.5).toFixed(1)}" class="x-eixo x-ponta-rot">${esc(curto ? p.se.abr : p.se.rot)}</text>`);
    }

    s.push(`<g id="x-cruz" opacity="0" aria-hidden="true"><line class="x-cruz-l" y1="${PT}" y2="${(H - PB).toFixed(1)}"/></g>`);

    CH.setAttribute("viewBox", `0 0 ${W} ${H}`);
    CH.setAttribute("role", "img");
    CH.setAttribute("aria-label", resumoDoGrafico(m));
    CH.innerHTML = s.join("");

    const lgCom = $(".x-lg-comercio", envolve);
    if (lgCom) {
      lgCom.style.opacity = m.R === 0 ? ".45" : "1";
      lgCom.title = m.R === 0 ? "Sem rotas de comércio, não há linha para desenhar." : "";
    }

    notaEscala.innerHTML = escala === "log"
      ? `<b>Escala logarítmica:</b> cada degrau do eixo vale dez vezes o anterior. ` +
        `As três curvas da §06 são exponenciais (1,12 · 1,08 · 1,22), por isso saem direitas — e a inclinação de cada uma é o expoente. ` +
        `Em escala linear o cruzamento acontece a 2% da altura do desenho e não se vê. <b>A matemática é a mesma.</b>`
      : `<b>Escala linear:</b> a mesma distância vale o mesmo número em qualquer altura do eixo. ` +
        `É a escala do desenho original — e é nela que os primeiros vinte dias ficam esmagados contra a base, porque o custo chega a ${esc(num(max, 0))} ao dia 30.`;

    /* ─── Os quatro números por baixo ──────────────────────────────── */
    const a = $("#o-asfixia");
    if (a) {
      const dentro = distanciaAoAlvo(asfixia) === 0;
      a.textContent = asfixia ? "dia " + asfixia : "nunca em 30";
      // A cor era `--s2`, que é a cor da SÉRIE do líquido: um veredicto
      // vestido com a identidade de uma linha do gráfico. Passa a ser
      // `--ok`, que é o que o documento usa para «certo» — e nunca vai
      // sozinha, que é a regra.
      a.style.color = dentro ? "var(--ok)" : "var(--ember)";
      let selo = a.parentElement.querySelector(".x-alvo-selo");
      if (!selo) {
        selo = el("span", { class: "x-alvo-selo" });
        a.insertAdjacentElement("afterend", selo);
      }
      selo.dataset.dentro = dentro ? "1" : "0";
      selo.textContent = dentro ? "no alvo" : asfixia < ALVO.de ? "cedo demais" : "tarde demais";
    }
    const põe = (id, txt) => { const n = $(id); if (n) n.textContent = txt; };
    põe("#o-upkeep", up.toFixed(1));
    põe("#o-nobres", (bruto[11] * G / 100).toFixed(1));
    põe("#o-d1", liquido[0].toFixed(1));

    vista.innerHTML =
      `<table><caption class="x-prov" style="text-align:left;margin:0 0 8px">Os mesmos trinta dias, em números. A linha do dia da asfixia vem a negrito.</caption>` +
      `<thead><tr><th class="n">Dia</th>` + SERIES.map((x) => `<th class="n">${esc(x.rot)}</th>`).join("") + `</tr></thead><tbody>` +
      Array.from({ length: DIAS }, (_, i) =>
        `<tr${asfixia === i + 1 ? ' style="font-weight:600"' : ""}><td class="n">${i + 1}</td>` +
        SERIES.map((x) => `<td class="n">${num(dados[x.k][i], 1)}</td>`).join("") + `</tr>`).join("") +
      `</tbody></table>`;
  }

  /** O equivalente textual do desenho. Obrigatório, e é o que o leitor de ecrã recebe. */
  function resumoDoGrafico(mm) {
    const dentro = distanciaAoAlvo(mm.asfixia) === 0;
    return `Trinta dias de economia, em escala ${escala === "log" ? "logarítmica" : "linear"}. ` +
      (mm.asfixia
        ? `O custo da noite ultrapassa o líquido no dia ${mm.asfixia} — ${dentro ? "dentro" : "fora"} do alvo de design, que é do dia ${ALVO.de} ao ${ALVO.ate}. `
        : `O custo da noite nunca ultrapassa o líquido em 30 dias. `) +
      `Líquido no dia 1: ${num(mm.liquido[0], 1)}; no dia 30: ${num(mm.liquido[29], 1)}. ` +
      `Custo no dia 30: ${num(mm.custo[29], 1)}. Os números todos estão na tabela por baixo do gráfico.`;
  }

  /* ═══ LEITURA PONTO A PONTO — rato, dedo e teclado ═══════════════════
     ┌───────────────────────────────────────────────────────────────┐
     │ A DICA APARECIA POR CIMA DOS CURSORES                          │
     │                                                               │
     │ `tip()` põe a caixa ACIMA do ponto que recebe. O gráfico       │
     │ passava-lhe `CH.getBoundingClientRect().top` — o topo do       │
     │ desenho — portanto a caixa aterrava sempre imediatamente acima │
     │ do gráfico, que é exactamente onde vive a grelha das quatro    │
     │ réguas. Ler um dia tapava os comandos com que se muda o dia.   │
     │                                                               │
     │ Passa a receber o Y do PONTO mais alto lido nesse dia, e o     │
     │ `tip()` vira-se para baixo quando não cabe por cima. A caixa   │
     │ fica encostada à curva que se está a ler, dentro do desenho.   │
     └───────────────────────────────────────────────────────────────┘ */
  let diaFoco = 0;
  const clientDe = (x, y) => {
    const r = CH.getBoundingClientRect();
    const k = r.width / W;
    return { cx: r.left + x * k, cy: r.top + y * k };
  };
  const lerEm = (clientX) => {
    const r = CH.getBoundingClientRect();
    const rel = ((clientX - r.left) / r.width) * W;
    const d = Math.round(((rel - PL) / (W - PL - PR)) * (DIAS - 1)) + 1;
    return Math.max(1, Math.min(DIAS, d));
  };
  const mostrarDia = (d) => {
    if (!m || !geo) return;
    diaFoco = d;
    const dados = { bruto: m.bruto, liquido: m.liquido, custo: m.custo, comercio: m.comercio };
    const vivas = SERIES.filter((s) => !(s.k === "comercio" && m.R === 0));
    const g = CH.querySelector("#x-cruz");
    const x = geo.Xp(d);
    if (g) {
      g.setAttribute("opacity", "1");
      // A cruz ganhou pontos: a linha diz QUE dia, os pontos dizem em
      // que valor cada série está nesse dia. Com um anel da superfície
      // por baixo, para se verem sobre a própria curva.
      g.innerHTML =
        `<line class="x-cruz-l" x1="${x.toFixed(1)}" x2="${x.toFixed(1)}" y1="${PT}" y2="${(H - PB).toFixed(1)}"/>` +
        vivas.map((s) => `<circle cx="${x.toFixed(1)}" cy="${geo.Yp(dados[s.k][d - 1]).toFixed(1)}" r="4" fill="var(${s.cor})" class="x-cruz-p"/>`).join("");
    }
    const alto = Math.min(...vivas.map((s) => geo.Yp(dados[s.k][d - 1])));
    const { cx, cy } = clientDe(x, alto);
    // O topo do próprio desenho é o limite: acima dele estão os cursores.
    const topoCh = CH.getBoundingClientRect().top;
    tip(
      `<b>Dia ${d}</b>` +
      vivas.map((s) =>
        `<div class="x-tip-l"><i style="background:var(${s.cor})"></i>${esc(s.rot)}` +
        `<span class="x-tip-v">${num(dados[s.k][d - 1], 1)}</span></div>`).join("") +
      (m.asfixia === d ? `<div class="x-tip-l x-tip-asf">a asfixia começa aqui</div>` : "") +
      (d >= ALVO.de && d <= ALVO.ate ? `<div class="x-tip-l x-tip-alvo">dentro do alvo da §06</div>` : ""),
      cx, cy, topoCh);
  };
  const esconder = () => {
    tip(null);
    const g = CH.querySelector("#x-cruz");
    if (g) g.setAttribute("opacity", "0");
  };

  CH.addEventListener("pointermove", (e) => mostrarDia(lerEm(e.clientX)));
  CH.addEventListener("pointerleave", esconder);
  CH.addEventListener("pointerdown", (e) => mostrarDia(lerEm(e.clientX)));
  CH.setAttribute("tabindex", "0");
  CH.addEventListener("keydown", (e) => {
    if (e.key === "Escape") { esconder(); return; }
    if (e.key !== "ArrowLeft" && e.key !== "ArrowRight" && e.key !== "Home" && e.key !== "End") return;
    e.preventDefault();
    const d = e.key === "Home" ? 1 : e.key === "End" ? DIAS
      : Math.max(1, Math.min(DIAS, (diaFoco || 1) + (e.key === "ArrowRight" ? 1 : -1)));
    mostrarDia(d);
  });
  CH.addEventListener("blur", esconder);

  /* ═══ 2b · O QUE MAIS MEXE ═══════════════════════════════════════════
     ┌───────────────────────────────────────────────────────────────┐
     │ PORTADO DE `src/components/negocio/SensibilidadeNegocio.tsx`   │
     │                                                               │
     │ O simulador do Descobrir tem um bloco chamado «o que mais mexe │
     │ no resultado»: uma barra por fator, ordenadas pela amplitude   │
     │ entre o melhor e o pior caso, com o crítico destacado e uma    │
     │ frase a dizer qual é o pressuposto a confirmar primeiro. O     │
     │ argumento dele vale aqui palavra por palavra: quatro cursores  │
     │ sem comparação obrigam a arrastar os quatro para descobrir     │
     │ qual é que interessa.                                         │
     │                                                               │
     │ Com uma diferença que o dossiê permite e o Descobrir não: aqui │
     │ as quatro barras podem partilhar UM eixo — os trinta dias —    │
     │ porque medem todas a mesma coisa. Assim não são quatro         │
     │ amplitudes para comparar de cabeça: são quatro segmentos       │
     │ alinhados, com o alvo da §06 desenhado por trás e o dia actual │
     │ marcado em todos. Vê-se de uma vez qual é o cursor que alcança │
     │ o alvo e qual é o que nem lá chega.                           │
     │                                                               │
     │ E não custa uma conta: é a MESMA varredura que pinta os        │
     │ carris, lida outra vez.                                       │
     └───────────────────────────────────────────────────────────────┘ */
  const torn = el("section", { class: "x-torn", "aria-labelledby": "x-torn-h" });
  torn.innerHTML =
    `<h4 class="x-torn-h" id="x-torn-h">O que mais mexe no dia da asfixia</h4>` +
    `<ol class="x-torn-l"></ol><p class="x-torn-f"></p>` +
    `<p class="x-prov"><b>Proveniência:</b> cálculo — cada cursor varrido de ponta a ponta com os outros três parados, ` +
    `no modelo da §06. Muda quando os outros cursores mudam.</p>`;
  const tornL = $(".x-torn-l", torn), tornF = $(".x-torn-f", torn);
  const saidas = $(".sim-out", envolve);
  if (saidas) saidas.insertAdjacentElement("afterend", torn); else envolve.appendChild(torn);

  const posDia = (d) => ((Math.min(DIAS, Math.max(1, d)) - 1) / (DIAS - 1)) * 100;

  const pintarTornado = () => {
    const hoje = m ? m.asfixia : 0;
    const linhas = CHAVES.map((k) => {
      const mapa = mapaDe(k);
      const dias = mapa.map((p) => (p.d === 0 ? DIAS + 1 : p.d));
      const lo = Math.min(...dias), hi = Math.max(...dias);
      return { k, lo, hi, amplitude: hi - lo, alcancaAlvo: !!corridaDoAlvo(mapa), alvo: corridaDoAlvo(mapa) };
    }).sort((a, b) => b.amplitude - a.amplitude);

    const critico = linhas[0];
    /* `DIAS + 1` é como a varredura marca «não asfixiou». Escrever «dia
       31» seria inventar um dia que o modelo não tem. */
    const diaOu = (d) => (d > DIAS ? "não asfixia" : "dia " + d);
    tornL.innerHTML = linhas.map((l) => {
      const e = posDia(l.lo), d = posDia(l.hi);
      const rotulo = l.amplitude === 0
        ? `${ROTULO[l.k]}: sozinho não muda o dia da asfixia, que fica no ${diaOu(l.lo)}.`
        : `${ROTULO[l.k]}: sozinho leva a asfixia do ${diaOu(l.lo)} ao ${diaOu(l.hi)}` +
          (l.alvo ? `, e alcança o alvo com ${l.alvo.de} a ${l.alvo.ate} ${un(l.k, l.alvo.ate)}` : ", sem alcançar o alvo") + ".";
      /* ── A PARTE DO ALCANCE QUE CAI DENTRO DO ALVO ──────────────
         A primeira versão desenhava a janela do alvo POR BAIXO da
         barra do alcance — e a barra tapava-a exactamente onde a
         resposta interessa. Via-se o alvo só onde o cursor NÃO chega,
         que é a informação ao contrário.
         Agora a janela fica como fundo (onde é o alvo) e o troço do
         alcance que a intersecta é repintado por cima com a cor do
         alvo: a barra diz, sozinha, quanto do que este cursor alcança
         é território bom. */
      const iDe = Math.max(l.lo, ALVO.de), iAte = Math.min(l.hi, ALVO.ate);
      const temInter = iDe <= iAte;
      return `<li class="x-torn-i"${l === critico && critico.amplitude > 0 ? ' data-critico="1"' : ""}>` +
        `<span class="x-torn-n">${esc(ROTULO[l.k])}</span>` +
        `<span class="x-torn-a">${l.amplitude === 0 ? "não mexe" : esc(num(l.amplitude, 0)) + (l.amplitude === 1 ? " dia" : " dias")}</span>` +
        `<span class="x-torn-b" role="img" aria-label="${esc(rotulo)}">` +
        `<span class="x-torn-janela" style="inset-inline:${posDia(ALVO.de).toFixed(2)}% ${(100 - posDia(ALVO.ate)).toFixed(2)}%"></span>` +
        `<span class="x-torn-r" style="inset-inline:${e.toFixed(2)}% ${(100 - d).toFixed(2)}%"></span>` +
        (temInter ? `<span class="x-torn-r-alvo" style="inset-inline:${posDia(iDe).toFixed(2)}% ${(100 - posDia(iAte)).toFixed(2)}%"></span>` : "") +
        (hoje ? `<span class="x-torn-p" style="inset-inline-start:${posDia(hoje).toFixed(2)}%"></span>` : "") +
        `</span></li>`;
    }).join("");

    const semAlvo = linhas.filter((l) => !l.alcancaAlvo);
    tornF.innerHTML = critico.amplitude === 0
      ? `Nesta configuração nenhum dos quatro cursores muda o dia da asfixia sozinho.`
      : `O que mais mexe é <b>${esc(ROTULO[critico.k].toLowerCase())}</b>: sozinho leva a asfixia do ${diaOu(critico.lo)} ao ${diaOu(critico.hi)}. ` +
        (semAlvo.length === CHAVES.length
          ? `Nenhum destes cursores sozinho põe a asfixia no alvo — daqui só se lá chega mexendo em dois.`
          : semAlvo.length
            ? `${semAlvo.length === 1 ? "Um deles não chega lá sozinho" : `${semAlvo.length} deles não chegam lá sozinhos`}: ${esc(semAlvo.map((l) => ROTULO[l.k].toLowerCase()).join(", "))}.`
            : `Todos os quatro alcançam o alvo sozinhos — a folga é grande.`);
  };

  /* ═══ A ORQUESTRAÇÃO ══════════════════════════════════════════════
     UM ouvinte por cursor, e UMA função que redesenha tudo. A versão
     anterior tinha dois: a régua registava o seu próprio `input` e o
     simulador registava outro que mandava pintar as quatro. O cursor
     que se arrastava pintava-se DUAS vezes por movimento, e varria a
     sua amplitude duas vezes para nada. */
  const atualizar = () => {
    desenhar();
    for (const k of CHAVES) reguas[k].pintar();
    pintarLegenda();
    pintarTornado();
    btRepor.hidden = !mexido();
  };
  for (const k of CHAVES) ctl[k].addEventListener("input", atualizar);

  /* Medir a caixa e subtrair o `padding` deixava de fora a BORDA: o
     `viewBox` ficava dois pixéis mais largo do que o desenho, a escala
     caía para 0,993, e um rótulo de 12px chegava ao ecrã com 11,92 —
     abaixo do piso por uma fracção. Mede-se o próprio SVG, que já é a
     largura de conteúdo, e a escala é exactamente 1. */
  responsiva(CH, (w) => { desenhar(w); pintarTornado(); });
  for (const k of CHAVES) reguas[k].pintar();
  pintarLegenda();
  pintarTornado();
}

/* ═══ 3 · AS FIGURAS DO DOSSIÊ, LEGÍVEIS NO TELEMÓVEL ══════════════
   ┌─────────────────────────────────────────────────────────────────────┐
   │ UMA FIGURA COM `viewBox` LARGO NÃO ENCOLHE: DESAPARECE               │
   │                                                                     │
   │ O ciclo do dia da §05 tem `viewBox="0 0 760 132"` e rótulos a 9,5px. │
   │ Num ecrã de 360px desenha-se a 328 — escala 0,43 — e os rótulos      │
   │ ficam a QUATRO pixéis. O desenho continua lá, bonito e ilegível, e   │
   │ nenhum portão tipográfico o apanha: o `font-size` computado          │
   │ continua a dizer 9,5, porque a escala está no `viewBox`.             │
   │                                                                     │
   │ A correção não toca no desenho, que é do autor e está certo: passa a │
   │ desenhar-se 1:1 dentro de uma calha que desliza com o dedo. É a      │
   │ mesma decisão que já se toma para uma tabela larga — melhor deslizar │
   │ do que ler uma mancha.                                              │
   │                                                                     │
   │ Os separadores de parte ficam de fora: são arte decorativa de        │
   │ sangrar, e esticar é exactamente o que têm de fazer.                 │
   └─────────────────────────────────────────────────────────────────────┘ */

function montarCalhas() {
  for (const svg of $$("figure svg[viewBox], svg[role='img'][viewBox]")) {
    if (svg.closest(".part-rule") || svg.closest(".x-fig")) continue;
    // O gráfico da economia é redesenhado à largura real pelo simulador:
    // metê-lo numa calha punha-o a deslizar quando não precisa, e punha
    // os controlos que lhe pertencem dentro da calha.
    if (svg.id === "chart") continue;
    if (svg.parentElement && svg.parentElement.classList.contains("x-calha")) continue;
    const vb = (svg.getAttribute("viewBox") || "").split(/[\s,]+/);
    const larguraArte = parseFloat(vb[2]);
    if (!larguraArte) continue;
    const calha = el("div", { class: "x-calha", "data-arte": String(Math.round(larguraArte)) });
    svg.parentElement.insertBefore(calha, svg);
    calha.appendChild(svg);
    /* ┌─────────────────────────────────────────────────────────────┐
       │ DUAS COISAS QUE A PRIMEIRA CALHA PARTIU                      │
       │                                                             │
       │ 1 · O ciclo do dia da §05 escreve «A Podridão nasce na       │
       │     borda do mapa ▸» a começar na unidade 592 de um          │
       │     `viewBox` de 760 — a frase SAI do `viewBox` de           │
       │     propósito, e o autor contava com o `overflow:visible`    │
       │     que os SVG têm por omissão. A calha recortou-a a meio.   │
       │                                                             │
       │ 2 · Os rótulos desse desenho têm 9,5px. Desenhado a 1:1 num  │
       │     telemóvel isso é ilegível — e o piso tipográfico não o   │
       │     apanha, porque é o `viewBox` que manda na escala.        │
       │     A calha passa a AMPLIAR até o menor rótulo chegar aos    │
       │     12px reais; quem lê passa a deslizar um desenho legível  │
       │     em vez de olhar para um desenho inteiro e minúsculo.     │
       └─────────────────────────────────────────────────────────────┘ */

    /* ┌─────────────────────────────────────────────────────────────┐
       │ O DESENHO É MAIOR DO QUE A JANELA QUE O AUTOR LHE DEU        │
       │                                                             │
       │ `getBBox()` devolve a caixa REAL do que está desenhado. No   │
       │ ciclo do dia da §05 ela passa o `viewBox` em ~80 unidades à  │
       │ direita, porque a frase «A Podridão nasce na borda do mapa»  │
       │ começa na unidade 592 de 760. Com `overflow:visible` isso    │
       │ pintava-se para fora e era a calha a cortar; com             │
       │ `overflow:hidden` cortava o próprio SVG.                     │
       │                                                             │
       │ A janela alarga-se para caber o desenho. Nada no desenho     │
       │ muda — muda o que se vê dele, que passa a ser tudo.          │
       └─────────────────────────────────────────────────────────────┘ */
    let larguraFinal = larguraArte;
    try {
      const bb = svg.getBBox();
      const [vx, vy, vw, vh] = vb.map(Number);
      const dir = Math.max(vx + vw, bb.x + bb.width);
      const baixo = Math.max(vy + vh, bb.y + bb.height);
      if (dir > vx + vw + 1 || baixo > vy + vh + 1) {
        svg.setAttribute("viewBox", `${vx} ${vy} ${dir - vx + 2} ${baixo - vy + 2}`);
        larguraFinal = dir - vx + 2;
      }
    } catch { /* SVG sem caixa mensurável: fica como está */ }

    /* ┌─────────────────────────────────────────────────────────────┐
       │ DOIS RÓTULOS DESTA FIGURA MONTAM-SE UM NO OUTRO              │
       │                                                             │
       │ «85 s · última janela» começa na unidade 488 e ocupa ~120;   │
       │ «30 s» começa na 592. Sobrepõem-se em dezasseis unidades —   │
       │ na fonte para que a figura foi desenhada, não por culpa de   │
       │ nenhuma substituição. É um defeito do desenho, e não se      │
       │ corrige reescrevendo a frase do autor.                       │
       │                                                             │
       │ O que se faz é o mínimo: MEDIR cada par de rótulos na mesma  │
       │ linha de base e, quando se tocam, encolher o da esquerda o   │
       │ estritamente necessário — nunca abaixo de 80% nem abaixo de  │
       │ oito unidades. Se não chegar, fica como está e vê-se: uma    │
       │ correção que esconde um defeito é pior do que o defeito.     │
       └─────────────────────────────────────────────────────────────┘ */
    const rotulos = [...svg.querySelectorAll("text")]
      .map((t) => ({ t, y: Math.round(parseFloat(t.getAttribute("y")) || 0) }))
      .filter((r) => r.y);
    const porLinha = new Map();
    for (const r of rotulos) {
      if (!porLinha.has(r.y)) porLinha.set(r.y, []);
      porLinha.get(r.y).push(r.t);
    }
    for (const linha of porLinha.values()) {
      if (linha.length < 2) continue;
      linha.sort((a, b) => (parseFloat(a.getAttribute("x")) || 0) - (parseFloat(b.getAttribute("x")) || 0));
      for (let i = 0; i < linha.length - 1; i++) {
        const a = linha[i], b = linha[i + 1];
        const xb = parseFloat(b.getAttribute("x")) || 0;
        let guarda = 0;
        while (guarda++ < 8) {
          const fim = a.getBBox().x + a.getBBox().width;
          if (fim <= xb - 3) break;
          const fs = parseFloat(getComputedStyle(a).fontSize) || 10;
          const alvo = Math.max(8, fs * 0.94);
          if (alvo >= fs || alvo < fs * 0.8) break;
          a.style.fontSize = alvo + "px";
        }
      }
    }

    const menorRotulo = [...svg.querySelectorAll("text")]
      .map((t) => parseFloat(getComputedStyle(t).fontSize) || 0)
      .filter((n) => n > 0)
      .reduce((a, b) => Math.min(a, b), Infinity);
    /* O piso dos 12px é uma regra de TELEMÓVEL. Num ecrã largo o
       dossiê usa rótulos de dez pixéis em todo o lado, e ampliar a
       figura até os 12 obrigava-a a deslizar numa janela onde ela
       cabia inteira — cortando o «Crepúsculo» a meio para resolver um
       problema que ali não existe. */
    const ampliar = matchMedia("(max-width:700px)").matches
      && Number.isFinite(menorRotulo) && menorRotulo > 0
      ? Math.max(1, Math.min(1.7, 12.6 / menorRotulo))
      : 1;
    const larguraMinima = Math.round(larguraFinal * ampliar);

    const ajustar = () => {
      const disponivel = calha.getBoundingClientRect().width;
      const estreito = disponivel < larguraMinima - 2;
      svg.style.width = estreito ? larguraMinima + "px" : "100%";
      svg.style.maxWidth = estreito ? "none" : "100%";
      calha.classList.toggle("desliza", estreito);
    };
    ajustar();
    if ("ResizeObserver" in window) {
      let t = null;
      new ResizeObserver(() => { clearTimeout(t); t = setTimeout(ajustar, 90); }).observe(calha.parentElement || calha);
    }
  }
}

/* ═══ 3b · AS 123 TABELAS, NUM TELEMÓVEL ════════════════════════════
   ┌─────────────────────────────────────────────────────────────────────┐
   │ O QUE FOI MEDIDO                                                     │
   │                                                                     │
   │ 123 tabelas. A 360px, **103 não cabem** — e todas tinham             │
   │ `overflow-x: hidden`, porque a camada de desenho arredondou os       │
   │ cantos do cartão com o atalho `overflow` e o atalho escreve os dois  │
   │ eixos. Não havia rolagem: havia corte, sem aviso e sem saída.       │
   │                                                                     │
   │   2 col ·  5 tabelas ·  1 não cabe                                   │
   │   3 col · 39 tabelas · 25 não cabem · 40 caracteres por célula       │
   │   4 col · 49 tabelas · 48 não cabem · 29 caracteres por célula       │
   │   5 col · 19 tabelas · 18 não cabem · 23 caracteres por célula       │
   │  6-8col · 11 tabelas · 11 não cabem ·  7-13 caracteres por célula    │
   │                                                                     │
   │ A distribuição diz o tratamento. Até quatro colunas com prosa são    │
   │ FICHAS — «nome · valor · o que isso quer dizer» — e uma ficha        │
   │ lê-se de cima a baixo: empilham. De cinco colunas para cima são      │
   │ MATRIZES de números, onde a comparação entre linhas É o conteúdo:    │
   │ deslizam, com sombra e com uma palavra a dizer que deslizam.        │
   │                                                                     │
   │ E a escolha é medida, não escrita à mão tabela a tabela: a largura   │
   │ MÍNIMA real de cada uma contra a largura que ela tem. Uma tabela     │
   │ que caiba não é tocada, aqui nem num ecrã de 1400.                  │
   └─────────────────────────────────────────────────────────────────────┘ */

/** Abaixo disto uma célula é um número ou um rótulo; acima, é prosa. */
const PROSA = 22;
/** Mais do que isto e a ficha vira matriz. */
const COLUNAS_FICHA = 5;
/**
 * O que uma coluna de prosa precisa para se ler, em pixéis.
 *
 * ┌───────────────────────────────────────────────────────────────────┐
 * │ «CABER» NÃO É «LER-SE»                                             │
 * │                                                                    │
 * │ A primeira versão desta decisão só empilhava as tabelas que não     │
 * │ CABIAM. Mas uma tabela de três colunas de prosa cabe sempre em      │
 * │ 328px — basta partir cada célula palavra a palavra. É o que a §35   │
 * │ fazia: «MÊS · AÇÃO · PORQUÊ AGORA» em três colunas de 85px, com     │
 * │ uma palavra por linha e a linha a ocupar 232px de altura. A         │
 * │ medição contou 121 células assim.                                   │
 * │                                                                     │
 * │ Por isso a decisão passa a ter duas perguntas. A primeira é «cabe   │
 * │ ao mínimo?». A segunda é «e cabe de forma legível?» — a soma das    │
 * │ larguras que as colunas QUEREM, cada uma travada num tecto, porque  │
 * │ acima dele uma coluna de prosa já não melhora com mais espaço.      │
 * └───────────────────────────────────────────────────────────────────┘
 */
const TECTO_COLUNA = 280;

function montarTabelas() {
  const tabelas = [];

  for (const tw of $$(".tw")) {
    const tab = $("table", tw);
    if (!tab || $(".x-rolo", tw)) continue;

    /* O scroller passa a ser um FILHO. Enquanto o cartão e o scroller
       foram o mesmo elemento, uma das duas propriedades tinha de ceder —
       e cedeu a que não dava erro. */
    const rolo = el("div", { class: "x-rolo" });
    tab.parentElement.insertBefore(rolo, tab);
    rolo.appendChild(tab);
    /* O aviso vive no cartão, que não rola — assim fica no canto de cima
       à direita, que é onde se vê a coluna cortada, e não viaja com o
       conteúdo. `aria-hidden` porque quem usa leitor de ecrã não desliza
       nada: recebe a tabela inteira. */
    tw.appendChild(el("span", { class: "x-tw-desliza", "aria-hidden": "true" }, "desliza →"));

    const ths = $$("thead th", tab).map((th) => th.textContent.trim());
    const tds = $$("tbody td", tab);
    const primeira = $("tr", tab);
    const colunas = ths.length || (primeira ? primeira.children.length : 0);
    const medio = tds.length
      ? tds.reduce((a, c) => a + c.textContent.trim().length, 0) / tds.length
      : 0;

    /* O nome da coluna vai num ELEMENTO e não num `::before`: o conteúdo
       gerado por CSS é anunciado por alguns leitores de ecrã, e ali
       repetiria o cabeçalho que a tabela continua a ter. Assim é
       `aria-hidden` por construção — quem lê com os olhos vê o rótulo,
       quem lê com um leitor recebe a tabela. */
    if (ths.length) {
      for (const tr of $$("tbody tr", tab)) {
        [...tr.children].forEach((td, i) => {
          if (td.colSpan > 1 || !ths[i] || !td.textContent.trim()) return;
          if ($(".x-td-rot", td)) return;
          td.insertBefore(el("span", { class: "x-td-rot", "aria-hidden": "true" }, esc(ths[i])), td.firstChild);
        });
      }
    }
    /* ┌───────────────────────────────────────────────────────────┐
       │ NUMA TABELA QUE DESLIZA, UMA COLUNA DE PROSA ENCOLHE ATÉ À │
       │ PALAVRA MAIS LONGA                                         │
       │                                                            │
       │ Quando a tabela não cabe, o motor dá a cada coluna a sua    │
       │ largura MÍNIMA — que numa coluna de números é o número, e   │
       │ numa coluna de prosa é a palavra mais comprida. O resultado │
       │ mede 85px e escreve uma palavra por linha. Medido: 191      │
       │ células assim, nas 40 matrizes que continuam a deslizar     │
       │ (empilhá-las destruía a comparação entre linhas, que é o    │
       │ conteúdo delas).                                           │
       │                                                            │
       │ Uma célula de prosa ganha um chão. A tabela fica mais       │
       │ larga e desliza mais — mas desliza sobre colunas que se     │
       │ lêem, que é a troca certa: um gesto a mais contra uma       │
       │ escada de palavras soltas.                                 │
       └───────────────────────────────────────────────────────────┘ */
    for (const td of tds) {
      if (td.textContent.trim().length > 40 && !td.classList.contains("n")) td.dataset.prosa = "1";
    }
    tabelas.push({ tw, tab, rolo, colunas, ficha: colunas <= COLUNAS_FICHA && medio >= PROSA, min: 0 });
  }
  if (!tabelas.length) return;

  /* ┌───────────────────────────────────────────────────────────────┐
     │ `display:block` TIRA A UMA TABELA A SEMÂNTICA DE TABELA        │
     │                                                               │
     │ Empilhada, uma `<tr>` deixa de ser uma linha na árvore de      │
     │ acessibilidade e uma `<td>` deixa de ser uma célula com        │
     │ cabeçalho: o leitor de ecrã passa a ler uma pilha de parágrafos│
     │ soltos. Devolve-se por `role`, e só enquanto está empilhada.   │
     └───────────────────────────────────────────────────────────────┘ */
  const PAPEIS = [["thead", "rowgroup"], ["tbody", "rowgroup"], ["tfoot", "rowgroup"],
                  ["tr", "row"], ["th", "columnheader"], ["td", "cell"]];
  const papeis = (tab, ligar) => {
    if (ligar) tab.setAttribute("role", "table"); else tab.removeAttribute("role");
    for (const [tag, papel] of PAPEIS) {
      for (const n of $$(tag, tab)) {
        if (ligar) n.setAttribute("role", papel); else n.removeAttribute("role");
      }
    }
  };

  /* A largura mínima real de cada tabela, medida UMA vez e em lote:
     todas a `min-content`, depois todas lidas, depois todas repostas.
     Três reflexões em vez de trezentas e sessenta e nove.

     E medida com o empilhamento DESLIGADO: a largura mínima de uma
     tabela cujas células são blocos é a de um parágrafo, e usá-la para
     decidir se empilha faria a decisão oscilar entre os dois estados a
     cada medição. */
  const medir = () => {
    for (const t of tabelas) {
      if (t.tw.dataset.modo) { t.tw.dataset.modo = ""; papeis(t.tab, false); }
    }
    for (const t of tabelas) t.tab.style.width = "min-content";
    for (const t of tabelas) t.min = Math.ceil(t.tab.getBoundingClientRect().width);
    /* E a largura CONFORTÁVEL: o que cada coluna pede quando ninguém a
       aperta, travada no tecto. Lê-se na linha de cabeçalho, que é a
       única que tem uma célula por coluna garantida. */
    for (const t of tabelas) t.tab.style.width = "max-content";
    for (const t of tabelas) {
      const linha = $("thead tr", t.tab) || $("tbody tr", t.tab);
      t.boa = linha
        ? [...linha.children].reduce((a, c) => a + Math.min(Math.ceil(c.getBoundingClientRect().width), TECTO_COLUNA), 0)
        : t.min;
    }
    for (const t of tabelas) t.tab.style.width = "";
  };

  /** As sombras de borda: só do lado para onde ainda há conteúdo. */
  const sombras = (t) => {
    const sobra = t.rolo.scrollWidth - t.rolo.clientWidth;
    const x = t.rolo.scrollLeft;
    t.tw.dataset.rolaEsq = sobra > 2 && x > 2 ? "1" : "0";
    t.tw.dataset.rolaDir = sobra > 2 && x < sobra - 2 ? "1" : "0";
  };

  /* ┌───────────────────────────────────────────────────────────────┐
     │ EMPILHAR É UM TRATAMENTO DE ECRÃ ESTREITO, NÃO UMA MELHORIA     │
     │                                                                │
     │ Uma tabela é uma tabela: alinha colunas para se comparar        │
     │ linhas, e desmontá-la custa isso. Num telemóvel o custo já foi  │
     │ pago — as colunas não cabem — e a pilha é o que resta. Num ecrã │
     │ largo não: aí uma tabela que não caiba na coluna de leitura     │
     │ desliza, com a sombra a dizê-lo, e continua a ser uma tabela.   │
     └───────────────────────────────────────────────────────────────┘ */
  const ESTREITO = 560;
  const decidir = () => {
    for (const t of tabelas) {
      const larg = t.rolo.clientWidth;
      const cabe = t.min <= larg + 2;
      const modo = larg < ESTREITO && t.ficha && (!cabe || t.boa > larg + 2)
        ? "empilha"
        : cabe ? "" : "rola";
      if (t.tw.dataset.modo !== modo) {
        t.tw.dataset.modo = modo;
        papeis(t.tab, modo === "empilha");
      }
    }
    for (const t of tabelas) sombras(t);
  };

  medir();
  decidir();

  /* Um ouvinte só, em captura: `scroll` não borbulha, mas é capturável,
     e 123 ouvintes para a mesma reacção é uma conta que se paga em cada
     rolagem de página. */
  document.addEventListener("scroll", (e) => {
    const n = e.target;
    if (!n || n.nodeType !== 1 || !n.classList || !n.classList.contains("x-rolo")) return;
    const t = tabelas.find((x) => x.rolo === n);
    if (t) sombras(t);
  }, true);

  let agendado = null;
  addEventListener("resize", () => {
    clearTimeout(agendado);
    agendado = setTimeout(decidir, 120);
  });
  /* As métricas mudam quando as fontes de ecrã chegam, e a largura
     mínima de uma tabela é feita de métricas. Mede-se outra vez. */
  if (document.fonts && document.fonts.ready) {
    document.fonts.ready.then(() => { medir(); decidir(); });
  }
  /* Abrir uma parte dá caixa a tabelas que não tinham nenhuma. Doze das
     treze partes entram fechadas, e uma tabela dentro de uma delas mede
     zero: sem isto nasciam todas com `min` a zero e nenhuma empilhava.
     `x-parte` é o evento que a camada das partes já emite. */
  addEventListener("x-parte", (e) => {
    if (e.detail && e.detail.aberta === false) return;
    clearTimeout(agendado);
    agendado = setTimeout(() => { medir(); decidir(); }, 60);
  });
}

/* ═══ 4 · INVENTÁRIO ════════════════════════════════════════════════ */

function painelInventario(d) {
  const sec = el("section", { id: "x-inventario" });
  const abertas = d.perguntas.filter((p) => p.estado === "aberta").length;
  sec.innerHTML =
    `<span class="sec-no">★ — Inventário</span>` +
    `<h3>Tudo o que o dossiê cita e não mostra</h3>` +
    `<p class="lede">O dossiê fala dos ${d.tickets.length} tickets, das ${d.perguntas.length} perguntas, das ${d.adrs.length} ADRs e das ${d.tabelas.length} tabelas — e nenhuma ` +
    `delas está aqui dentro para se ler. Estão agora: extraídas do ZIP, pesquisáveis, e cada uma com o estado que ` +
    `o próprio ficheiro declara. <strong>Nada foi reescrito.</strong></p>` +
    `<div class="x-inv-ctl">` +
      `<div class="x-inv-busca"><svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="1.7" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>` +
      `<input type="search" id="x-inv-q" aria-label="Filtrar o inventário" placeholder="Filtrar…" autocomplete="off"></div>` +
      `<div class="x-filtros" role="group" aria-label="Família" style="padding:0;border:0">` +
        `<button type="button" class="x-filtro" data-f="ticket" aria-pressed="true">Tickets <span class="x-n">${d.tickets.length}</span></button>` +
        `<button type="button" class="x-filtro" data-f="questao" aria-pressed="false">Perguntas <span class="x-n">${d.perguntas.length}</span></button>` +
        `<button type="button" class="x-filtro" data-f="adr" aria-pressed="false">ADRs <span class="x-n">${d.adrs.length}</span></button>` +
        `<button type="button" class="x-filtro" data-f="tabela" aria-pressed="false">Tabelas <span class="x-n">${d.tabelas.length}</span></button>` +
      `</div></div>` +
    `<ul class="x-inv-lista" id="x-inv-lista"></ul>` +
    prov({
      fonte: "Empire-v6.zip · docs/backlog/tickets.json, docs/QUESTIONS.md, docs/adr/*.md, data/source/*.csv",
      data: d.validacao.date,
      nota: abertas + " das " + d.perguntas.length + " perguntas continuam à espera de decisão do dono",
    });
  return sec;
}

function ligarInventario(d) {
  const lista = $("#x-inv-lista");
  const campo = $("#x-inv-q");
  if (!lista || !campo) return;
  let familia = "ticket";

  const linhas = {
    ticket: () => d.tickets.map((t) => ({
      id: t.id, titulo: t.titulo,
      meta: [t.fase, t.estado, t.horas ? "≈ " + t.horas.replace("≈ ", "") : "", t.depende !== "—" ? "depende de " + t.depende : ""],
      refs: t.acoes,
      busca: [t.id, t.titulo, t.fase, t.estado, t.porque, t.feito, t.fora].join(" "),
      estado: /^por fazer/.test(t.estado.toLocaleLowerCase("pt-PT")) ? "parado"
        : /parcial|falta|pendente/.test(t.estado.toLocaleLowerCase("pt-PT")) ? "aviso" : "ok",
    })),
    questao: () => d.perguntas.map((q) => ({
      id: q.id, titulo: q.titulo,
      meta: [q.onde, q.bloqueia ? "bloqueia: " + q.bloqueia : "", q.decide ? "proposta: " + q.decide : ""],
      refs: q.secoes,
      busca: [q.id, q.titulo, q.onde, q.decide, q.bloqueia, q.grupo].join(" "),
      estado: q.estado === "aberta" ? "aviso" : "ok",
      selo: q.estado === "aberta" ? "em aberto" : "resolvida",
    })),
    adr: () => d.adrs.map((a) => ({
      id: a.id, titulo: a.titulo, meta: [a.estado, a.ficheiro], refs: [],
      busca: [a.id, a.titulo, a.estado].join(" "),
      estado: /^aceite/.test(a.estado) ? "ok" : "aviso",
      selo: /^aceite/.test(a.estado) ? "aceite" : "proposta",
    })),
    tabela: () => d.tabelas.map((t) => ({
      id: t.nome, titulo: t.nome + ".csv",
      meta: [t.registos + " registos", t.campos + " campos", t.propostos + " colunas de disciplina"],
      refs: [],
      busca: t.nome + " csv dados",
      estado: "ok", selo: "gerada",
    })),
  };

  const pintar = () => {
    const q = campo.value.trim();
    let itens = linhas[familia]();
    if (q) {
      const qn = X.normalizar(q);
      itens = itens
        .map((i) => ({ i, p: Math.max(X.pontuarCampo(qn, i.titulo), X.pontuarCampo(qn, i.id) * 1.2, X.pontuarCampo(qn, i.busca) * 0.5) }))
        .filter((r) => r.p >= X.LIMIAR)
        .sort((a, b) => b.p - a.p)
        .map((r) => r.i);
    }
    if (!itens.length) {
      lista.innerHTML = `<li class="x-inv-vazio">Nada no inventário responde a «${esc(q)}».</li>`;
      return;
    }
    lista.innerHTML = itens.map((i) =>
      `<li><span class="x-inv-id">${esc(i.id)}</span>` +
      `<span class="x-inv-t">${X.realcar(i.titulo, q)}</span>` +
      `<span class="x-inv-m">` +
      (i.selo ? selo(i.estado, i.selo) : selo(i.estado, i.meta[1] || "")) +
      i.meta.filter(Boolean).slice(i.selo ? 0 : 2).map((mtx) => `<span>${esc(String(mtx))}</span>`).join("") +
      (i.refs && i.refs.length ? i.refs.slice(0, 6).map((r) => `<a class="x-ref" href="#" data-ref="${esc(r)}">${esc(r)}</a>`).join(" ") : "") +
      `</span></li>`).join("");
    for (const a of $$("a[data-ref]", lista)) {
      a.addEventListener("click", (e) => {
        e.preventDefault();
        const idx = window.__X_IDX__;
        const alvo = idx && idx.porNumero.get(a.dataset.ref.replace("§", "").padStart(2, "0"));
        if (alvo && window.__X_ATERRAR__) window.__X_ATERRAR__(alvo, true);
      });
    }
  };

  campo.addEventListener("input", pintar);
  for (const b of $$(".x-inv-ctl .x-filtro")) {
    b.addEventListener("click", () => {
      familia = b.dataset.f;
      for (const o of $$(".x-inv-ctl .x-filtro")) o.setAttribute("aria-pressed", String(o === b));
      pintar();
    });
  }
  pintar();
}

/* ═══ 5 · GLOSSÁRIO ═════════════════════════════════════════════════
   ┌─────────────────────────────────────────────────────────────────────┐
   │ NENHUMA DEFINIÇÃO AQUI FOI INVENTADA                                 │
   │                                                                     │
   │ Cada uma é a leitura da secção que a define, e leva o número dessa   │
   │ secção. Onde o dossiê não define um termo, ele não está nesta lista  │
   │ — um glossário que preenche buracos com o que parece razoável é      │
   │ pior do que não haver glossário, porque passa a ser citável.         │
   └─────────────────────────────────────────────────────────────────────┘ */

const TERMOS = [
  ["A Podridão", "51", "Sistema de primeira classe, não um gerador de ondas: tem posição contínua, um orçamento de massa e é a única fonte de criaturas do jogo. Avança de noite e recua de dia."],
  ["dia da asfixia", "06", "O dia em que o custo de sobreviver à noite (6,1 × 1,22^(d−1)) passa o rendimento líquido. A meta de desenho é que caia entre o dia 9 e o 14."],
  ["asfixia", "06", "O ponto em que o custo da noite passa o rendimento líquido. É o motor que empurra o jogo para a frente e mata o turtling."],
  ["faixa", "53", "Uma das três camadas do mundo — aérea, superfície e subsolo — com camadas de física separadas desde a primeira entidade. É a invariante I3."],
  ["faixas", "53", "As três camadas do mundo (aérea, superfície, subsolo), com física separada. Invariante I3, fixada na ADR 0002."],
  ["tick", "43", "Um passo de simulação. São 30 por segundo, metade do render, e a ordem do que corre dentro de cada um é fixa e escrita."],
  ["seed", "42", "A semente que reproduz um mundo inteiro. A aleatoriedade divide-se em fluxos independentes e cada consumidor usa sempre o mesmo — sem isso a semente deixa de reproduzir."],
  ["determinista", "42", "O mesmo estado e a mesma semente dão sempre o mesmo resultado. É o que permite mostrar a semente ao jogador e o que torna o lockstep viável."],
  ["greybox", "65", "Um segmento feito de caixas: retângulos para edifícios, uma barra para o chão. Leva vinte minutos a fazer e diz em cinco se a densidade está certa."],
  ["Amargueiro", "74", "A árvore que dá combustível à candeia. O corte exige que tenha aguentado pelo menos uma noite de pé — é a Q-047."],
  ["candeia", "74", "A luz que a Podridão passa a ter, e cujo combustível é o jogador. É a alavanca que transforma meteorologia em decisão."],
  ["A Oferta", "75", "A proposta que a Besta faz a quem está cansado: sensata no momento, e com uma dívida que ninguém mostra."],
  ["A Colheita", "78", "Uma das duas maneiras de acabar com um povo. Cordial, organizada, e insuportável por isso mesmo."],
  ["upkeep", "06", "O custo diário de manter tropas. É zero até 8, meia moeda por tropa entre 9 e 20, e uma e meia acima disso."],
  ["TTK", "07", "Tempo até matar — quantos segundos uma unidade demora a derrubar outra, com a precisão e o intervalo de ataque da tabela mestra."],
  ["Aríete de lodo", "07", "A criatura que os arqueiros não devem conseguir parar em campo aberto. É o objeto da Q-001 e da Q-038."],
  ["EventBus", "46", "O autoload por onde passam os sinais entre sistemas. Está no catálogo de eventos; o seu contrato continua por implementar."],
  ["GameClock", "48", "O relógio do jogo. É puro — o autoload apenas o faz andar, como a ADR 0006 fixou."],
  ["ADR", "28", "Architecture Decision Record: uma decisão de arquitetura escrita, com o estado (proposta ou aceite) à vista. Estão todas em docs/adr/, e o painel de inventário conta-as."],
];

function montarGlossario(porNumero) {
  const dica = el("div", { class: "x-dica", hidden: "", role: "tooltip", id: "x-dica" });
  document.body.appendChild(dica);

  const porTermo = new Map();
  for (const [t, sec, def] of TERMOS) porTermo.set(t.toLocaleLowerCase("pt-PT"), { termo: t, sec, def });
  // Os mais longos primeiro: sem isto «faixa» consumia «faixa aérea».
  const ordenados = [...porTermo.values()].sort((a, b) => b.termo.length - a.termo.length);

  // Os títulos ficam de fora: um termo sublinhado dentro de um `h4` parte
  // a linha do título e chama a atenção para a palavra errada — o título
  // é para ler de um lance, não para consultar.
  const PROIBIDO = new Set(["A", "PRE", "CODE", "SCRIPT", "STYLE", "BUTTON",
    "H1", "H2", "H3", "H4", "H5", "H6", "TEXTAREA", "KBD", "TH"]);
  /* Instrumentos, não prosa: o simulador e o rastreador são para operar,
     e um termo sublinhado dentro de um rótulo de leitura rouba o toque a
     quem queria mexer no controlo. */
  const INSTRUMENTOS = ".sim, .sim-out, .sim-ctl, .trk, #trklist, .x-fig, .x-legenda";
  // Uma vez por SECÇÃO, e não uma vez por página: um termo sublinhado
  // trinta vezes deixa de ser ajuda e passa a ser ruído.
  const usadoEm = new Map();

  for (const sec of $$("main section[id]")) {
    const walker = document.createTreeWalker(sec, NodeFilter.SHOW_TEXT, {
      acceptNode(n) {
        if (n.nodeValue.trim().length < 4) return NodeFilter.FILTER_REJECT;
        for (let p = n.parentElement; p && p !== sec; p = p.parentElement) {
          if (PROIBIDO.has(p.tagName)) return NodeFilter.FILTER_REJECT;
          /* Um `<button>` HTML dentro de um `<text>` de SVG fica na
             árvore e não é pintado: o glossário apagava «A Podridão»
             do desenho da §05 e «EventBus» do da §41. Ver a nota
             equivalente em `08-interface.js`. */
          if (p.namespaceURI === "http://www.w3.org/2000/svg") return NodeFilter.FILTER_REJECT;
          // A camada de uso não recebe glossário: sublinhar «asfixia» na
          // legenda que eu próprio escrevi é a ferramenta a comentar-se a
          // si mesma. O glossário é para a prosa do autor — mas um
          // INVÓLUCRO da camada continua a embrulhar prosa do autor, e
          // saltá-lo apagou 66 dos 150 termos sem dar erro. A lista dos
          // invólucros é a de `X.INVOLUCROS`, partilhada com o ligador
          // das referências §NN.
          if (p.classList && [...p.classList].some((c) => c.startsWith("x-") && !X.INVOLUCROS.has(c))) {
            return NodeFilter.FILTER_REJECT;
          }
        }
        if (n.parentElement && n.parentElement.closest(INSTRUMENTOS)) return NodeFilter.FILTER_REJECT;
        return NodeFilter.FILTER_ACCEPT;
      },
    });
    const nodos = [];
    let n;
    while ((n = walker.nextNode())) nodos.push(n);

    for (const nodo of nodos) {
      const txt = nodo.nodeValue;
      let achado = null, pos = -1;
      for (const t of ordenados) {
        const chave = sec.id + "|" + t.termo;
        if (usadoEm.has(chave)) continue;
        const i = txt.indexOf(t.termo);
        if (i === -1) continue;
        const antes = i === 0 || /[\s(«"'—-]/.test(txt[i - 1]);
        const depois = i + t.termo.length >= txt.length || /[\s.,;:)»"'?!—-]/.test(txt[i + t.termo.length]);
        if (!antes || !depois) continue;
        if (pos === -1 || i < pos) { achado = t; pos = i; }
      }
      if (!achado) continue;
      usadoEm.set(sec.id + "|" + achado.termo, true);
      const frag = document.createDocumentFragment();
      frag.appendChild(document.createTextNode(txt.slice(0, pos)));
      const b = el("button", {
        type: "button", class: "x-termo", "aria-describedby": "x-dica",
        "data-def": achado.def, "data-sec": achado.sec, "data-termo": achado.termo,
      }, esc(txt.substr(pos, achado.termo.length)));
      frag.appendChild(b);
      frag.appendChild(document.createTextNode(txt.slice(pos + achado.termo.length)));
      nodo.parentNode.replaceChild(frag, nodo);
    }
  }

  const mostrar = (b) => {
    const alvo = porNumero.get(b.dataset.sec);
    dica.innerHTML =
      `<b>${esc(b.dataset.termo)} · §${esc(b.dataset.sec)}</b>${esc(b.dataset.def)}` +
      (alvo ? ` <span style="opacity:.7">Enter abre a secção.</span>` : "");
    dica.hidden = false;
    const r = b.getBoundingClientRect();
    const w = Math.min(320, window.innerWidth * 0.86);
    dica.style.width = w + "px";
    dica.style.left = Math.max(8, Math.min(r.left, window.innerWidth - w - 8)) + window.scrollX + "px";
    const h = dica.offsetHeight;
    dica.style.top = (r.top > h + 12 ? r.top - h - 8 : r.bottom + 8) + window.scrollY + "px";
  };
  const esconder = () => { dica.hidden = true; };

  for (const b of $$("button.x-termo")) {
    b.addEventListener("mouseenter", () => mostrar(b));
    b.addEventListener("mouseleave", esconder);
    b.addEventListener("focus", () => mostrar(b));
    b.addEventListener("blur", esconder);
    b.addEventListener("click", () => {
      const alvo = porNumero.get(b.dataset.sec);
      if (alvo && window.__X_ATERRAR__) window.__X_ATERRAR__(alvo, true);
    });
  }
  window.addEventListener("scroll", esconder, { passive: true });
}

/* ═══ 6 · PROGRESSO DE LEITURA ══════════════════════════════════════ */

const CHAVE_LIDO = "empire.lido.v1";

function montarProgressoLeitura() {
  let lidas;
  try { lidas = new Set(JSON.parse(localStorage.getItem(CHAVE_LIDO) || "[]")); } catch { lidas = new Set(); }
  const guardar = () => { try { localStorage.setItem(CHAVE_LIDO, JSON.stringify([...lidas])); } catch { /* quota */ } };

  const pintar = () => {
    for (const a of $$("nav.toc a[href^='#']")) {
      a.classList.toggle("x-visto", lidas.has(a.getAttribute("href").slice(1)));
    }
    // As partes contam as suas lidas a partir daqui. O atributo vive na
    // secção e não na ligação porque a secção é que pertence à parte.
    for (const s of $$("main section[id]")) s.dataset.xVisto = lidas.has(s.id) ? "1" : "0";
    window.dispatchEvent(new CustomEvent("x-visto", { detail: { n: lidas.size } }));
  };

  /**
   * ┌─────────────────────────────────────────────────────────────────┐
   * │ «LIDA» NÃO É «VISÍVEL A 35%»                                     │
   * │                                                                 │
   * │ A primeira versão usava um `IntersectionObserver` com limiar de  │
   * │ 0,35 — e nunca marcou uma única secção. A razão é geométrica: o  │
   * │ `intersectionRatio` é a fracção DA SECÇÃO visível, e quase todas │
   * │ as secções deste dossiê são mais altas do que a janela. Uma      │
   * │ secção de 3 000px numa janela de 900 nunca passa de 0,3.         │
   * │                                                                 │
   * │ A definição que funciona é também a mais honesta: uma secção     │
   * │ conta como lida quando a pessoa ROLOU ATÉ AO FIM DELA — o fundo  │
   * │ passou o topo do ecrã. E não conta durante um salto, que é       │
   * │ passar por cima e não ler.                                       │
   * └─────────────────────────────────────────────────────────────────┘
   */
  const seccoes = $$("main section[id]");
  let agendado = null;
  const varrer = () => {
    if (window.__X_A_SALTAR__ && window.__X_A_SALTAR__()) return;
    let mudou = false;
    for (const s of seccoes) {
      if (lidas.has(s.id)) continue;
      const r = s.getBoundingClientRect();
      /* Uma secção dentro de uma parte FECHADA mede zero — e zero passa
         em `bottom < 140` com folga. Sem esta guarda, fechar uma parte
         marcava as suas catorze secções como lidas de uma vez, em
         silêncio, e o progresso do dossiê deixava de querer dizer nada.
         Só conta o que tem altura, que é o que se pode ter lido. */
      if (r.height <= 0) continue;
      if (r.bottom < 140) { lidas.add(s.id); mudou = true; }
    }
    if (mudou) { guardar(); pintar(); }
  };
  window.addEventListener("scroll", () => {
    clearTimeout(agendado);
    agendado = setTimeout(varrer, 220);
  }, { passive: true });
  setTimeout(() => { varrer(); pintar(); }, 400);
}

/* ═══ Montagem ══════════════════════════════════════════════════════ */

function montar(d) {
  const main = $("main");
  if (!main || !d) return;

  // O estado entra a seguir ao veredito: quem abre um dossiê de produção
  // pergunta «onde é que isto está?» antes de perguntar mais nada.
  const s00 = $("#s00");
  const estado = painelEstado(d);
  if (s00 && s00.nextSibling) main.insertBefore(estado, s00.nextSibling);
  else main.appendChild(estado);
  $("#x-fig-testes", estado).appendChild(figuraTestes(d.validacao));
  $("#x-fig-tickets", estado).appendChild(figuraTickets(d));

  // O inventário entra antes do rastreador, que é o outro instrumento.
  const trk = $("#trk");
  const inv = painelInventario(d);
  if (trk) main.insertBefore(inv, trk);
  else main.appendChild(inv);
  ligarInventario(d);

  montarSimulador();
  montarCalhas();
  montarTabelas();
  montarProgressoLeitura();
}

/* O tema muda as variáveis CSS que os gráficos leem por `var()` — o SVG
   acompanha sozinho. O evento existe para o simulador redesenhar os
   pontos que usam cores calculadas em JavaScript. */
const tema = $("#theme");
if (tema) tema.addEventListener("click", () => setTimeout(() => window.dispatchEvent(new CustomEvent("x-tema")), 30));

return { montar, montarGlossario, TERMOS };
})();
