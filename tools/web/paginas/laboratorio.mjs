// tools/web/paginas/laboratorio.mjs — o laboratório de mecânicas, montado na construção (PUB-06, ADR 0085).
//
// O padrão é o da candeia: o HTML sai daqui com os rótulos, os controlos e os
// lugares (`data-lab`) que o laboratorio.js preenche no browser. O modelo — os
// números lidos dos CSV — vai dentro do próprio script (assets.mjs), que o site.js
// só pede quando a secção se aproxima do ecrã (ADR 0080). Sem JavaScript, cada
// instrumento diz numa frase o caso por omissão, contado aqui com as mesmas
// contas (laboratorio-contas.js) que o browser vai fazer.
//
// Nada de `style=""` nem de <script> em linha: o que seria um estilo vindo dos
// dados (a folha de cada criatura) sai na folha gerada — `cssDoLaboratorio`.

import { readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { runInNewContext } from "node:vm";
import { LABORATORIO } from "./laboratorio-textos.mjs";

const AQUI = dirname(fileURLToPath(import.meta.url));
const janela = {};
runInNewContext(readFileSync(join(AQUI, "laboratorio-contas.js"), "utf8"), { window: janela });
export const CONTAS = janela.EmpireContas;

export const FERRAMENTAS = ["noite", "economia", "combate", "muro"];

/** O estado com que cada instrumento abre: o caso que se lê sem mexer em nada. */
export function omissao(L) {
  const s = L.economia.deslizadores;
  const economia = { fontes: s.fontes.valor, rotas: s.rotas.valor, tropas: s.tropas.valor, gan: s.ganancia.valor };
  const asf = CONTAS.asfixia({ fontes: economia.fontes, rotas: economia.rotas, tropas: economia.tropas, ganancia: economia.gan }, L.economia);
  return {
    noite: { dia: L.noite.rampa + 1, fort: 0, arv: 0, nom: 0, rec: 0, sub: 0, prop: 0 },
    economia: { ...economia, foco: asf || 1 },
    combate: { tropa: (L.tropas.find((x) => x.posto) || L.tropas[0]).id, onde: "torre" },
    muro: { nivel: L.muros[Math.min(2, L.muros.length - 1)].nivel, caminho: "b" },
  };
}

// ── A folha gerada: cada criatura com a sua folha animada (ADR 0083) ─────────

export function cssDoLaboratorio(d) {
  // O orçamento gasto, espécie a espécie: três roxos da candeia, à vez, para duas vizinhas nunca terem o mesmo.
  const roxos = ["--bordo", "--violeta", "--meio"];
  const tons = d.laboratorio.criaturas.map((c, i) => `.o-${c.id}{background:var(${roxos[i % roxos.length]})}`);
  const r = d.laboratorio.criaturas.filter((c) => c.folha).map((c) => {
    const f = c.folha;
    return `.besta-${c.id}{background-image:url(${f.img});--quadros:${f.quadros};--ms:${f.ms}ms;--fl:${f.largura}px;--fa:${f.lado}px;--fy:0px;--fq:${f.lado}px}`;
  });
  return [...tons, ...r].join("\n");
}

// ── O HTML ─────────────────────────────────────────────────────────────────

const lingua = (t) => (t.lingua === "pt-PT" ? "pt" : "en");

/** O que o laboratorio.js recebe, dentro do próprio script: o modelo e as frases das duas línguas. */
export function modeloDoLaboratorio(d) {
  return { L: d.laboratorio, omissao: omissao(d.laboratorio), vivo: { pt: LABORATORIO.pt.vivo, en: LABORATORIO.en.vivo } };
}

export function laboratorio({ t, d, v, esc, fmt }) {
  const l = lingua(t);
  const x = LABORATORIO[l];
  const L = d.laboratorio;
  const o = omissao(L);
  const num = new Intl.NumberFormat(t.lingua, { maximumFractionDigits: 1 });
  const pc = (f) => num.format(Math.round((f - 1) * 1000) / 10);
  const nome = (n) => esc(n[l]);

  const regua = (f, par, rotulo, min, max, valor) => `<div class="lab-regua">
          <label for="lab-${f}-${par}"><span>${rotulo}</span> <output id="lab-${f}-${par}-v" for="lab-${f}-${par}">${valor}</output></label>
          <input type="range" id="lab-${f}-${par}" name="${par}" min="${min}" max="${max}" step="1" value="${valor}">
        </div>`;
  const caixa = (f, par, rotulo, marcado) => `<label class="lab-caixa" for="lab-${f}-${par}"><input type="checkbox" id="lab-${f}-${par}" name="${par}" value="1"${marcado ? " checked" : ""}><span>${rotulo}</span></label>`;
  const escolhas = (f, par, legenda, opcoes, valor, classe = "") => `<fieldset class="lab-escolhas${classe}"><legend>${legenda}</legend>${opcoes.map(([dela, rot, extra]) =>
    `<label class="lab-escolha"><input type="radio" name="${par}" value="${dela}"${dela === valor ? " checked" : ""}><span>${rot}${extra ? `<small>${extra}</small>` : ""}</span></label>`).join("")}</fieldset>`;
  // Os cenários: o estado inteiro de um instrumento, na mesma forma do endereço (ver laboratorio.js).
  const cenarios = (f, lista) => `<div class="lab-cenarios" role="group" aria-label="${x.experimenta}">
          <p class="lab-rotulo" aria-hidden="true">${x.experimenta}</p>
          <div class="lab-cenarios-lista">${lista.map(([estado, rot, dia]) => `<button type="button" class="lab-cenario" data-cenario="${esc(new URLSearchParams(estado).toString())}">`
            + `${dia ? `<small>${fmt(x.cenarios.dia, { dia })}</small>` : ""}<span>${rot}</span></button>`).join("")}`
          + `<button type="button" class="lab-cenario lab-repor" data-cenario="${esc(new URLSearchParams(o[f]).toString())}"><span>${x.omissao}</span></button></div>
        </div>`;
  const leads = {
    noite: x.noite.lead,
    economia: fmt(x.economia.lead, { producao: pc(L.economia.crescimento), comercio: pc(L.economia.crescimentoComercio), noite: pc(L.economia.noiteCrescimento), min: L.economia.alvo[0], max: L.economia.alvo[1] }),
    combate: fmt(x.combate.lead, { noite: L.noiteSegundos }),
    muro: x.muro.lead,
  };
  const painel = (f, i, controlos, saida, semJs, sugestoes = "") => `<div class="lab-painel${i === 0 ? " ativo" : ""}" id="lab-p-${f}" role="tabpanel" aria-labelledby="lab-t-${f}" data-ferramenta="${f}">
      <h3 class="lab-titulo">${x[f].tab}</h3>
      <p class="lab-lead">${leads[f]}</p>
      <p class="lab-sem-js">${semJs}</p>
      ${sugestoes}
      ${f === "noite" || f === "economia" ? '<p class="lab-placar" aria-hidden="true" data-lab="placar"></p>' : ""}
      <div class="lab-grelha">
        <div class="lab-controlos">
        ${controlos}
        </div>
        <div class="lab-saida">
        ${saida}
        </div>
      </div>
      <p class="sr" role="status" data-lab="resumo"></p>
    </div>`;

  // ── A noite ──
  const n = L.noite;
  const on = o.noite;
  const mNoite = CONTAS.massa({ dia: on.dia, fortalezas: 0, amargueiros: 0, nomeados: 0, recusas: 0 }, n, false);
  const fNoite = CONTAS.invocar(mNoite.total, on.dia, L.criaturas, n, { subsolo: false, propostas: false });
  const filaTexto = fNoite.fila.map((y) => fmt(x.vivo.fila_item, { n: y.n, nome: nome(L.criaturas.find((c) => c.id === y.id).nome) })).join(", ");
  const limpo = { fort: 0, arv: 0, nom: 0, rec: 0, sub: 0, prop: 0 };
  const estreia = L.criaturas[0];
  const sugestoesNoite = cenarios("noite", [
    [{ ...limpo, dia: 1 }, x.cenarios.noite.primeira, 1],
    [{ ...limpo, dia: n.doisLados }, x.cenarios.noite.dois_lados, n.doisLados],
    [{ ...limpo, dia: estreia.desde, sub: 1 }, fmt(x.cenarios.noite.estreia, { nome: nome(estreia.nome) }), estreia.desde],
  ]);
  const noite = painel("noite", 0, [
    regua("noite", "dia", x.noite.dia, 1, L.economia.dias, on.dia),
    regua("noite", "fort", x.noite.fortalezas, 0, 5, on.fort),
    regua("noite", "arv", x.noite.amargueiros, 0, 12, on.arv),
    regua("noite", "nom", x.noite.nomeados, 0, 6, on.nom),
    regua("noite", "rec", fmt(x.noite.recusas, { janela: n.janela }), 0, n.recusasMax, on.rec),
    caixa("noite", "sub", x.noite.subsolo, on.sub),
    caixa("noite", "prop", x.noite.propostas, on.prop),
  ].join("\n        "), `<div class="lab-mostrador"><p class="lab-rotulo">${x.noite.massa}</p><p class="lab-grande"><b data-lab="massa">${num.format(mNoite.total)}</b></p></div>
          <dl class="lab-termos">${x.noite.termos.map((rot, i) => `<div><dt>${rot}</dt><dd data-lab="t${i}">0</dd></div>`).join("")}</dl>
          <p class="lab-nota lab-ritmo" data-lab="ritmo" hidden></p>
          <p class="lab-rotulo">${x.noite.orcamento}</p>
          <div class="lab-orcamento" aria-hidden="true">${L.criaturas.map((c) => `<i class="o-${c.id}" data-o="${c.id}" hidden></i>`).join("")}<i class="o-sobra" data-o="sobra"></i></div>
          <p class="lab-rotulo">${x.noite.vem}</p>
          <ul class="lab-bestas">${L.criaturas.map((c) => `<li class="lab-besta" data-besta="${c.id}" hidden><span class="besta besta-${c.id}" aria-hidden="true"></span>`
            + `<span class="lab-besta-texto"><b data-lab="n">×</b> <span class="lab-besta-nome">${nome(c.nome)}</span>`
            + `<small>${fmt(x.noite.cada, { massa: c.massa })} · ${fmt(x.noite.desde, { dia: c.desde })}${c.subsolo ? ` · ${x.noite.subterraneo}` : ""}</small></span></li>`).join("")}</ul>
          <p class="lab-vazio" data-lab="vazia" hidden>${x.vivo.fila_vazia}</p>
          <p class="lab-nota" data-lab="sobra"></p>
          <p class="lab-nota lab-por-chegar" data-lab="por-chegar-linha"><span class="lab-rotulo">${x.noite.por_chegar}</span> <span data-lab="por-chegar"></span></p>
          <p class="lab-nota" data-lab="rampa" hidden></p>
          <p class="lab-nota lab-proposta" data-lab="propostas" hidden></p>`,
  fmt(x.noite.sem_js, { dia: on.dia, massa: num.format(mNoite.total), fila: filaTexto || x.vivo.fila_vazia }), sugestoesNoite);

  // ── A asfixia ──
  const e = L.economia, oe = o.economia, sl = e.deslizadores;
  const dentro = (k, v) => {
    if (v < sl[k].min || v > sl[k].max) throw new Error(`laboratorio: um perfil do economy_profiles.csv põe ${k} = ${v}, fora do deslizador do §06`);
    return v;
  };
  const sugestoesEconomia = cenarios("economia", e.cenarios.map((c) => {
    const rot = x.cenarios.economia[c.id];
    if (!rot) throw new Error(`laboratorio: o perfil ${c.id} do economy_profiles.csv não tem nome em laboratorio-textos.mjs (cenarios.economia)`);
    const estado = { fontes: dentro("fontes", c.fontes), rotas: dentro("rotas", c.rotas), tropas: dentro("tropas", c.tropas), gan: dentro("ganancia", c.ganancia) };
    return [{ ...estado, foco: CONTAS.asfixia({ ...c }, e) || 1 }, fmt(rot, c), null];
  }));
  const economia = painel("economia", 1, [
    regua("economia", "fontes", x.economia.fontes, sl.fontes.min, sl.fontes.max, oe.fontes),
    regua("economia", "rotas", x.economia.rotas, sl.rotas.min, sl.rotas.max, oe.rotas),
    regua("economia", "tropas", x.economia.tropas, sl.tropas.min, sl.tropas.max, oe.tropas),
    regua("economia", "gan", x.economia.ganancia, sl.ganancia.min, sl.ganancia.max, oe.gan),
  ].join("\n        "), `<div class="lab-mostrador"><p class="lab-grande lab-asfixia"><b data-lab="asfixia"></b> <span class="lab-selo" data-lab="alvo"></span></p></div>
          <p class="lab-nota" data-lab="perfil"></p>
          <figure class="lab-grafico">
            <figcaption class="lab-legenda"><span class="l-rende">${x.economia.rende}</span><span class="l-custa">${x.economia.custa}</span><span class="l-alvo">${x.economia.alvo}</span></figcaption>
            <div class="lab-tela" role="img" data-lab="grafico" aria-label="${esc(fmt(x.economia.grafico, { dias: e.dias }))}">
              <svg viewBox="0 0 300 100" preserveAspectRatio="none" aria-hidden="true">
                <rect class="g-alvo" x="0" y="0" width="0" height="100"></rect>
                <g class="g-grelha"></g>
                <polyline class="g-rende" points=""></polyline>
                <polyline class="g-custa" points=""></polyline>
                <line class="g-foco" x1="0" x2="0" y1="0" y2="100"></line>
              </svg>
              <span class="g-ponto g-ponto-rende" aria-hidden="true"></span><span class="g-ponto g-ponto-custa" aria-hidden="true"></span>
            </div>
            <div class="lab-eixo" aria-hidden="true"><span>${x.noite.dia} 1</span><span>${x.noite.dia} ${e.dias}</span></div>
          </figure>
          ${regua("economia", "foco", x.economia.foco, 1, e.dias, oe.foco)}
          <dl class="lab-contas">${x.economia.contas.map((rot, i) => `<div class="c-${i}"><dt>${rot}</dt><dd data-lab="c${i}">0</dd></div>`).join("")}</dl>
          <p class="lab-nota" data-lab="soldo"></p>`,
  fmt(x.economia.sem_js, { fontes: oe.fontes, rotas: oe.rotas, tropas: oe.tropas, ganancia: oe.gan, asfixia: CONTAS.asfixia({ fontes: oe.fontes, rotas: oe.rotas, tropas: oe.tropas, ganancia: oe.gan }, e) }), sugestoesEconomia);

  // ── O combate ──
  const oc = o.combate;
  const tropaO = L.tropas.find((y) => y.id === oc.tropa);
  const alvoO = L.criaturas[L.criaturas.length - 1];
  const combate = painel("combate", 2, [
    escolhas("combate", "tropa", x.combate.tropa, L.tropas.map((y) => [y.id, nome(y.nome), y.custo === null ? x.combate.custo_por_decidir : fmt(x.combate.custo, { custo: y.custo })]), oc.tropa, " lab-tropas"),
    escolhas("combate", "onde", x.combate.onde, [["torre", x.combate.torre, fmt(x.combate.precisao, { pc: Math.round(L.torre * 100) })], ["campo", x.combate.campo, ""]], oc.onde, " lab-onde"),
  ].join("\n        "), `<p class="lab-nota lab-tropa-linha" data-lab="tropa"></p>
          <p class="lab-nota lab-proposta" data-lab="precisao" hidden></p>
          <p class="lab-rotulo">${x.combate.alvo}</p>
          <ol class="lab-ttk">${L.criaturas.slice().reverse().map((c) => `<li data-besta="${c.id}"><span class="besta besta-${c.id} parada" aria-hidden="true"></span>`
            + `<span class="ttk-texto"><span class="ttk-nome">${nome(c.nome)}</span><span class="ttk-valor" data-lab="v"></span><span class="ttk-nota" data-lab="nota"></span></span>`
            + `<span class="ttk-barra" aria-hidden="true"><i></i><b class="ttk-noite"><span>${x.combate.uma_noite}</span></b></span></li>`).join("")}</ol>`,
  fmt(x.combate.sem_js, { tropa: nome(tropaO.nome), alvo: nome(alvoO.nome), segundos: num.format(CONTAS.tempoAteMatar(tropaO, alvoO.vida, L.torre).segundos) }));

  // ── O muro ──
  const om = o.muro;
  const muroO = L.muros.find((w) => w.nivel === om.nivel);
  const muro = painel("muro", 3, [
    escolhas("muro", "nivel", x.muro.nivel, L.muros.map((w) => [String(w.nivel), nome(w.nome), fmt(x.muro.moedas, { n: w.custo })]), String(om.nivel), " lab-niveis"),
    escolhas("muro", "caminho", x.muro.caminho, [["a", x.muro.a, ""], ["b", x.muro.b, ""]], om.caminho, " lab-caminhos"),
  ].join("\n        "), `<div class="lab-desenho-muro" role="img" data-lab="muro-alt" aria-label=""><svg viewBox="0 0 200 100" aria-hidden="true" shape-rendering="crispEdges"></svg></div>
          <dl class="lab-muro-numeros">
            <div><dt>${x.muro.degrau}</dt><dd data-lab="degrau"></dd></div>
            <div><dt>${x.muro.ate_aqui}</dt><dd data-lab="total"></dd></div>
            <div><dt>${x.muro.vida}</dt><dd data-lab="vida"></dd></div>
            <div><dt>${x.muro.postos}</dt><dd data-lab="postos"></dd></div>
            <div><dt>${x.muro.contacto}</dt><dd data-lab="contacto"></dd></div>
            <div><dt>${x.muro.abre}</dt><dd data-lab="abre"></dd></div>
          </dl>
          <p class="lab-nota" data-lab="ariete"></p>
          <p class="lab-nota" data-lab="requisitos" hidden></p>`,
  fmt(x.muro.sem_js, { muro: nome(muroO.nome), custo: muroO.custo, total: CONTAS.custoAte(L.muros, om.nivel) }));

  const separadores = FERRAMENTAS.map((f, i) => `<button type="button" class="lab-separador" role="tab" id="lab-t-${f}" aria-controls="lab-p-${f}" aria-selected="${i === 0}"${i ? ' tabindex="-1"' : ""} data-ferramenta="${f}"><span class="lab-sep-n" aria-hidden="true">0${i + 1}</span><span>${x[f].tab}</span></button>`).join("");
  return `<section class="secao laboratorio" id="laboratorio" aria-labelledby="laboratorio-t" data-lingua="${t.lingua}" data-adiado="${v.laboratorio}">
  <div class="envolve">
    <header class="cabeca revela">
      <p class="n">${x.n}</p>
      <h2 id="laboratorio-t">${x.h2}</h2>
      <p class="intro">${x.intro}</p>
    </header>
    <div class="lab revela">
      <div class="lab-separadores" role="tablist" aria-label="${x.separadores}">${separadores}</div>
      <p class="lab-sem-js lab-sem-js-geral">${x.sem_js}</p>
      ${[noite, economia, combate, muro].join("\n      ")}
      <div class="lab-rodape">
        <button type="button" class="botao lab-partilhar" id="lab-partilhar">${x.partilhar}</button>
        <a class="botao principal" href="${t.lingua === "pt-PT" ? "/jogar/" : "/jogar/?lingua=en"}">${x.jogar} <span aria-hidden="true">→</span></a>
        <p class="lab-estado" id="lab-estado" role="status"></p>
      </div>
    </div>
    <p class="fonte">${x.fonte}</p>
  </div>
</section>`;
}
