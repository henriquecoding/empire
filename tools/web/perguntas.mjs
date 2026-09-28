// tools/web/perguntas.mjs — as perguntas do docs/QUESTIONS.md, para o painel (ADR 0026).
//
// O painel mostra cada pergunta que ainda espera pelo dono, com o texto dela tal
// como está no repositório: o QUESTIONS.md é a fonte, e o painel é uma leitura
// dele em cada publicação — como o resto do site (ADR 0025). As resolvidas
// vivem em tabelas nas secções «Resolvidas»; as que esperam têm um cabeçalho
// `### Q-NNN`, e são estas que se leem.
//
// Cada uma sai com um de três tipos, lido do próprio texto:
//   confirmar — já tem uma decisão provisória («Decidido») e nada por decidir
//   escolher  — tem uma proposta ou recomendação, ou uma decisão com uma parte
//               ainda aberta
//   decidir   — não tem proposta nenhuma
//
//   import { perguntas } from "./perguntas.mjs"; perguntas(raiz)

import { readFileSync } from "node:fs";
import { join } from "node:path";

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

function tipoDe(grupo, titulo, corpo) {
  const decidida = /\*\*Decidid[oa]/.test(corpo) || /^Decididas/.test(grupo);
  const aberta = /\((aberta|em parte decidida)\)/.test(titulo) || /Fica por (decidir|fazer)|Continua aberto|Por decidir/.test(corpo);
  if (decidida && !aberta) return "confirmar";
  if (decidida || /\*\*(Proposta|Recomenda)/.test(corpo)) return "escolher";
  return "decidir";
}

/** O que o painel aprova quando se carrega em «Aprovar»: a decisão ou a proposta, numa linha. */
function proposta(corpo) {
  // Num item próprio («- **Proposta:** ...») ou a meio de outro («... **Proposta nos dados:** ...»).
  const m = /\*\*(Decidido[^*]*|Proposta[^*]*|Recomendação[^*]*):?\*\*:?\s*([\s\S]*?)(?=\n-\s+\*\*|\n*$)/.exec(corpo);
  return m ? m[2].replace(/\s+/g, " ").replace(/\*\*/g, "").replace(/`/g, "").trim() : "";
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
        titulo: atual.titulo.replace(/\s*\((aberta|em parte decidida)\)\s*$/, ""),
        grupo: atual.grupo.replace(/^Abertas\s+—\s+/, ""),
        tipo: tipoDe(atual.grupo, atual.titulo, corpo),
        proposta: proposta(corpo),
        html: corpoHtml(atual.linhas),
      });
    }
    atual = null;
  };
  for (const l of texto.split("\n")) {
    const h2 = /^##\s+(.+)$/.exec(l);
    if (h2 && !l.startsWith("###")) { fechar(); grupo = h2[1].trim(); continue; }
    const h3 = /^###\s+(Q-\d{3})\s*·?\s*(.*)$/.exec(l);
    if (h3) { fechar(); atual = { id: h3[1], titulo: h3[2].trim(), grupo, linhas: [] }; continue; }
    if (atual) atual.linhas.push(l);
  }
  fechar();
  if (!saida.length) throw new Error("perguntas: o QUESTIONS.md não tem nenhuma pergunta por responder — o formato mudou?");
  return saida;
}
