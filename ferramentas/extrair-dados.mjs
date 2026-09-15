#!/usr/bin/env node
/**
 * EXTRATOR — o inventário do dossiê, DERIVADO das fontes canónicas.
 * ---------------------------------------------------------------------
 * Regra herdada do Recibo Certo (`src/lib/busca/documentos.ts`): o índice
 * DERIVA das fontes, nunca é uma lista escrita à mão. Uma lista à mão
 * diverge no primeiro dia em que alguém acrescenta um ticket e esquece o
 * índice — e ninguém dá por isso, porque nada reprova.
 *
 * Fontes (todas dentro do repositório):
 *   docs/backlog/tickets.json     → os tickets
 *   docs/QUESTIONS.md             → as perguntas
 *   docs/adr/*.md                 → as ADRs (o 0000 é template e não conta)
 *   data/source/*.csv             → as tabelas e os registos
 *   docs/recovery/validation.json → o estado MEDIDO, não o prometido
 *                                   (o v6-validation.json fica como histórico)
 *
 * Cada número que sai daqui leva `fonte` — a proveniência é obrigatória.
 */

import { readFileSync, writeFileSync, readdirSync, existsSync } from "node:fs";
import { join } from "node:path";

/* O primeiro argumento é a RAIZ DO REPOSITÓRIO — a pasta que tem `docs/` e
   `data/` lá dentro. Aceita-se também a forma antiga (a pasta que CONTÉM
   `Empire/`), porque foi assim que o extrator nasceu e há comandos escritos
   nesse formato; sem esta tolerância, o CI e a máquina do dono precisariam de
   invocações diferentes, que é a classe de defeito que se descobre no dia em
   que o CI é ligado. Omitir o argumento usa a raiz a partir daqui. */
const ARG = process.argv[2] || join(import.meta.dirname, "..");
const SAIDA = process.argv[3];
const RAIZ = existsSync(join(ARG, "docs", "design")) ? ARG : join(ARG, "Empire");
if (!existsSync(join(RAIZ, "docs", "design"))) {
  console.error(`FALHOU: ${JSON.stringify(ARG)} não é a raiz do repositório nem a pasta que a contém.`);
  process.exit(1);
}
const docs = join(RAIZ, "docs");
const dados = join(RAIZ, "data", "source");

const ler = (p) => readFileSync(p, "utf8");

/* ─── 1 · Tickets ─────────────────────────────────────────────────── */

const ticketsRaw = JSON.parse(ler(join(docs, "backlog", "tickets.json")));
const tickets = Object.entries(ticketsRaw).map(([id, t]) => {
  const fase = /^F(\d)-/.test(id) ? `Fase ${id[1]}` : "Transversal";
  return {
    id,
    titulo: (t.title || "").replace(/\s+/g, " ").trim(),
    fase,
    estado: (t.estado || "por fazer").replace(/\s+/g, " ").trim(),
    depende: (t.depende || "—").replace(/\s+/g, " ").trim(),
    horas: (t.horas || "").replace(/\s+/g, " ").trim(),
    feito: (t.feito || "").replace(/\s+/g, " ").trim().slice(0, 220),
    porque: (t.porque || "").replace(/\s+/g, " ").trim().slice(0, 260),
    fora: (t.fora || "").replace(/\s+/g, " ").trim().slice(0, 200),
    // As secções citadas na spec — é o que liga um ticket ao dossiê.
    acoes: [...new Set((JSON.stringify(t).match(/§\s?\d{1,2}/g) || []).map((s) => s.replace(/\s/, "")))],
  };
});

/* ─── 2 · Perguntas em aberto ─────────────────────────────────────── */

const qMd = ler(join(docs, "QUESTIONS.md"));
const perguntas = [];
{
  /**
   * ┌─────────────────────────────────────────────────────────────────┐
   * │ AS 52 PERGUNTAS ESTÃO EM TRÊS FORMATOS, E SÓ UM DELES É UM       │
   * │ CABEÇALHO                                                        │
   * │                                                                 │
   * │ Um extrator que só lesse `### Q-NNN` encontrava 36 e dava por    │
   * │ terminado — as outras 16 vivem em LINHAS DE TABELA (as           │
   * │ resolvidas na v5.2 e as dez da Parte XIII). O dossiê diz «52» e  │
   * │ o inventário diria «36» sem nada reprovar: seria o próprio       │
   * │ painel de estado a mentir sobre o estado.                        │
   * │                                                                 │
   * │ Por isso as tabelas são lidas pelo CABEÇALHO — a coluna que se   │
   * │ chama «A pergunta» é o título, a que se chama «Bloqueia» é o     │
   * │ bloqueio — e não por posição, que muda de tabela para tabela.    │
   * └─────────────────────────────────────────────────────────────────┘
   */
  const linhas = qMd.split("\n");
  let grupo = "";
  let atual = null;
  let colunas = null;
  const vistos = new Set();
  const seccoesDe = (s) => [...new Set((s.match(/§\s?\d{1,2}/g) || []).map((x) => x.replace(/\s/, "")))];
  const limpar = (s) =>
    (s || "")
      .replace(/\*\*/g, "")
      .replace(/`/g, "")
      .replace(/\[([^\]]+)\]\([^)]*\)/g, "$1")
      .replace(/\s+/g, " ")
      .trim();
  const fechar = () => {
    if (atual && !vistos.has(atual.id)) {
      vistos.add(atual.id);
      perguntas.push(atual);
    }
    atual = null;
  };
  const estadoDe = (g, titulo) =>
    /^resolvidas/i.test(g) || /\bresolvida\b/i.test(titulo) ? "resolvida" : "aberta";

  for (const linha of linhas) {
    const h2 = /^##\s+(.+)$/.exec(linha);
    if (h2) {
      fechar();
      colunas = null;
      grupo = limpar(h2[1]);
      continue;
    }
    const h3 = /^###\s+(Q-\d{3})\s*·?\s*(.*)$/.exec(linha);
    if (h3) {
      fechar();
      const titulo = limpar(h3[2]).replace(/^Resolvida\s*[—·-]\s*/i, "");
      atual = {
        id: h3[1],
        titulo,
        grupo,
        estado: estadoDe(grupo, limpar(h3[2])),
        onde: "",
        decide: "",
        bloqueia: "",
        secoes: seccoesDe(linha),
      };
      continue;
    }

    // Linhas de tabela: `| Q-038 | §05 vs §74 | … |`
    if (/^\|/.test(linha)) {
      const celulas = linha.split("|").slice(1, -1).map((c) => c.trim());
      if (celulas.length < 3) continue;
      if (/^-+$/.test(celulas[0].replace(/[: ]/g, ""))) continue; // separador
      if (!/^Q-\d{3}$/.test(celulas[0])) {
        // Cabeçalho: guarda o significado de cada coluna.
        if (/^#$/.test(celulas[0])) colunas = celulas.map((c) => limpar(c).toLowerCase());
        continue;
      }
      if (!colunas) continue;
      fechar();
      const valor = (nomes) => {
        for (const n of nomes) {
          const i = colunas.findIndex((c) => c.includes(n));
          if (i > 0 && celulas[i]) return limpar(celulas[i]);
        }
        return "";
      };
      const titulo = valor(["a pergunta", "o quê", "o que"]) || limpar(celulas[1]);
      const q = {
        id: celulas[0],
        titulo,
        grupo,
        estado: estadoDe(grupo, titulo),
        onde: valor(["onde"]),
        decide: valor(["decisão", "proposta"]),
        bloqueia: valor(["bloqueia"]),
        secoes: seccoesDe(linha),
      };
      if (!vistos.has(q.id)) {
        vistos.add(q.id);
        perguntas.push(q);
      }
      continue;
    }

    if (!atual) continue;
    const campo = /^-\s+\*\*(Onde|Decide|Bloqueia|Correção|Proposta):?\*\*:?\s*(.*)$/.exec(linha);
    if (campo) {
      const chave = campo[1].toLowerCase();
      const v = limpar(campo[2]);
      if (chave === "onde") atual.onde = v;
      if (chave === "decide") atual.decide = v;
      if (chave === "bloqueia") atual.bloqueia = v;
      if (chave === "proposta" && !atual.decide) atual.decide = v;
    }
    atual.secoes = [...new Set([...atual.secoes, ...seccoesDe(linha)])];
  }
  fechar();
  perguntas.sort((a, b) => a.id.localeCompare(b.id, "pt-PT"));
}

/* ─── 3 · ADRs ────────────────────────────────────────────────────── */

const adrs = readdirSync(join(docs, "adr"))
  .filter((f) => /^\d{4}-/.test(f) && f.endsWith(".md"))
  .map((f) => {
    const txt = ler(join(docs, "adr", f));
    const tit = /^#\s+ADR\s+(\d{4})\s+—\s+(.+)$/m.exec(txt);
    const est = /^-?\s*Estado:\s*(.+)$/m.exec(txt);
    return {
      id: tit ? `ADR ${tit[1]}` : f.slice(0, 4),
      titulo: (tit ? tit[2] : f).replace(/`/g, "").trim(),
      estado: (est ? est[1] : "—").replace(/\*/g, "").trim(),
      ficheiro: `docs/adr/${f}`,
    };
  })
  .filter((a) => a.id !== "0000" && !a.titulo.startsWith("<"));

/* ─── 4 · Tabelas de dados ────────────────────────────────────────── */

const registoTabelas = ler(join(dados, "_tables.csv"))
  .trim()
  .split("\n")
  .slice(1)
  .map((l) => l.split(",")[0]);

const tabelas = registoTabelas.map((nome) => {
  const txt = ler(join(dados, `${nome}.csv`));
  const linhas = txt.trim().split("\n");
  const cabecalho = linhas[0].split(",");
  // Contagem de registos: linhas menos o cabeçalho. Campos que abrem aspas
  // podem ter quebras — contam-se as linhas que começam com um id simples.
  const registos = linhas.slice(1).filter((l) => /^[a-z0-9_]+,/.test(l)).length;
  return {
    nome,
    registos,
    campos: cabecalho.length,
    // Os campos `_proposed` são propostas do gerador — não aprovações.
    propostos: cabecalho.filter((c) => c.startsWith("_")).length,
  };
});

/* ─── 5 · O estado MEDIDO ─────────────────────────────────────────── */

// O registo MEDIDO mais recente manda. O v6-validation.json e o historico da
// recuperacao de 13/09; o validation.json e a medicao desta arvore. Se o
// segundo existir, e ele que o painel de estado mostra — senao o painel
// continuaria a afirmar 17 tabelas num repositorio que tem 27.
const registos = ["validation.json", "v6-validation.json"]
  .map((f) => join(docs, "recovery", f))
  .filter((f) => existsSync(f))
  .map((f) => JSON.parse(ler(f)))
  .sort((a, b) => String(b.date).localeCompare(String(a.date)));
if (registos.length === 0) throw new Error("docs/recovery/: nenhum registo de validacao");
const validacao = registos[0];
const validacaoHistorico = registos.slice(1);

/* ─── Saída ───────────────────────────────────────────────────────── */

const saida = {
  gerado: new Date().toISOString().slice(0, 10),
  fonte: "o repositorio — docs/backlog/tickets.json, docs/QUESTIONS.md, docs/adr/, data/source/, docs/recovery/",
  tickets,
  perguntas,
  adrs,
  tabelas,
  validacao,
  validacaoHistorico,
};

writeFileSync(SAIDA, JSON.stringify(saida));

const abertas = perguntas.filter((p) => p.estado === "aberta").length;
console.log(
  `tickets ${tickets.length} · perguntas ${perguntas.length} (${abertas} abertas) · ADRs ${adrs.length} · ` +
    `tabelas ${tabelas.length} · registos ${tabelas.reduce((s, t) => s + t.registos, 0)} · ` +
    `${(JSON.stringify(saida).length / 1024).toFixed(0)} KB`,
);
