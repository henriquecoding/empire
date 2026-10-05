// tools/web/perguntas.mjs — as perguntas do docs/QUESTIONS.md, para o painel (ADR 0026).
//
// A fonte é o QUESTIONS.md. Pendências e decisões parciais ficam separadas;
// questões explicitamente encerradas são consultáveis e não pedem aprovação.
// Os resumos editoriais só valem enquanto a impressão da fonte coincide.

import { readFileSync } from "node:fs";
import { join } from "node:path";
import { createHash } from "node:crypto";
const resumos = JSON.parse(readFileSync(new URL("./decisoes-contexto.json", import.meta.url), "utf8"));

const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);

/** O markdown que o QUESTIONS.md usa, e só esse: negrito, itálico, código e listas. */
function linha(s) {
  return esc(s)
    .replace(/`([^`]+)`/g, "<code>$1</code>")
    .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
    .replace(/(^|[^*])\*([^*\s][^*]*)\*/g, "$1<em>$2</em>");
}

function corpoHtml(linhas) {
  const blocos = [];
  let item = null;
  let paragrafo = null;
  const fecharItem = () => { if (item !== null) blocos.push({ li: item }); item = null; };
  const fecharPar = () => { if (paragrafo !== null) blocos.push({ p: paragrafo }); paragrafo = null; };
  for (const l of linhas) {
    if (/^\s*$/.test(l)) { fecharItem(); fecharPar(); continue; }
    const m = /^-\s+(.*)$/.exec(l);
    if (m) { fecharPar(); fecharItem(); item = m[1]; continue; }
    if (item !== null) { item += " " + l.trim(); continue; }
    paragrafo = paragrafo === null ? l.trim() : paragrafo + " " + l.trim();
  }
  fecharItem();
  fecharPar();
  let html = "";
  let lista = false;
  for (const b of blocos) {
    if (b.li !== undefined && !lista) { html += "<ul>"; lista = true; }
    if (b.li === undefined && lista) { html += "</ul>"; lista = false; }
    html += b.li !== undefined ? `<li>${linha(b.li)}</li>` : `<p>${linha(b.p.replace(/^>\s*/, ""))}</p>`;
  }
  return html + (lista ? "</ul>" : "");
}

const limpo = (s) => s.replace(/[`*]/g, "").replace(/\s+/g, " ").trim();

// Lê rótulos também quando estão a meio de um item. Nunca corta uma proposta.
function campos(corpo) {
  const marcas = [...corpo.matchAll(/\*\*([^*\n]{2,140}?):\*\*/g)];
  return marcas.map((m, i) => ({
    nome: limpo(m[1]),
    texto: corpo.slice(m.index + m[0].length, marcas[i + 1]?.index ?? corpo.length)
      .replace(/\s*-\s*$/, "").replace(/\s+/g, " ").trim(),
  }));
}

function contextoDe(atual, corpo) {
  const partes = campos(corpo);
  const ler = (rx) => partes.filter(p => rx.test(p.nome)).map(p => p.texto).join("\n\n");
  const onde = ler(/^Onde$/i);
  const pendencia = ler(/por decidir|em aberto|continua aberto/i);
  const decisao = ler(/^Decidid|^Decisão|^O que foi decidido|^Fechada/i);
  const proposta = ler(/^Proposta|^Recomenda/i);
  const implementacao = ler(/^Por aplicar|^Implementação pendente/i);
  const encerrada = /fechada pelo/i.test(atual.titulo) || partes.some(p => /^Fechada/i.test(p.nome));
  const tipo = encerrada ? "encerrada" : pendencia ? "decidir"
    : decisao && !proposta ? "confirmar" : proposta ? "escolher" : "decidir";
  const contexto = ler(/^O que (diverg|est|aconte|há)|^A contradição|^O custo/i);
  const resumo = contexto || onde || decisao || pendencia || limpo(corpo);
  return {
    onde, pendencia, decisao, contexto: resumo,
    proposta: proposta || (!pendencia ? decisao : ""),
    aprovavel: !encerrada && !pendencia && !implementacao && Boolean(proposta || decisao),
    bloqueio: ler(/^Bloqueia$/i), tipo,
    fonte: `https://github.com/henriquecoding/empire/blob/main/docs/QUESTIONS.md#L${atual.numero}`,
    seccoes: [...new Set([...corpo.matchAll(/§(\d{2})/g)].map(m => m[1]))],
  };
}

export function perguntas(raiz) {
  const texto = readFileSync(join(raiz, "docs", "QUESTIONS.md"), "utf8");
  const saida = [];
  let grupo = "";
  let atual = null;
  const fechar = () => {
    if (!atual) return;
    const corpo = atual.linhas.join("\n").trim();
    if (!/^Resolvidas/i.test(atual.grupo)) {
      saida.push({
        id: atual.id,
        titulo: limpo(atual.titulo.replace(/\s*\((?:[^)]*aberta|em parte decidida)\)\s*$/, "")),
        grupo: atual.grupo.replace(/^Abertas\s+—\s+/, ""),
        ...contextoDe(atual, corpo),
        html: corpoHtml(atual.linhas),
      });
    }
    atual = null;
  };
  for (const [indice, l] of texto.split("\n").entries()) {
    const h2 = /^##\s+(.+)$/.exec(l);
    if (h2 && !l.startsWith("###")) { fechar(); grupo = h2[1].trim(); continue; }
    const h3 = /^###\s+(Q-\d{3})\s*·?\s*(.*)$/.exec(l);
    if (h3) { fechar(); atual = { id: h3[1], titulo: h3[2].trim(), grupo, numero: indice + 1, linhas: [] }; continue; }
    if (atual) atual.linhas.push(l);
  }
  fechar();
  for (const q of saida) {
    const r = resumos[q.id];
    if (r && r.fonteHash === createHash("sha256").update(q.html).digest("hex").slice(0, 16)) Object.assign(q, r);
  }
  return saida;
}
