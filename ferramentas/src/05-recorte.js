/* ═══════════════════════════════════════════════════════════════════════
   O RECORTE — levar o CASO a alguém, não um link
   ---------------------------------------------------------------------
   ┌─────────────────────────────────────────────────────────────────────┐
   │ PORTADO DE `src/lib/guias/dossie/`                                   │
   │                                                                     │
   │ O problema que aquele motor resolve é o mesmo que este dossiê tem:   │
   │ a pessoa leu, percebeu, e agora precisa de levar aquilo a um         │
   │ colaborador. Hoje a única coisa que se pode mandar é o ficheiro      │
   │ inteiro — 575 KB e 86 secções — ou um link para uma âncora, que do   │
   │ outro lado abre sem nada à volta.                                   │
   │                                                                     │
   │ Um recorte é o meio termo que faltava: escolhe-se o que interessa,   │
   │ e sai um documento pequeno que se lê sozinho.                        │
   └─────────────────────────────────────────────────────────────────────┘

   AS DUAS REGRAS QUE IMPEDEM A DEGRADAÇÃO SILENCIOSA
   (§4.3 do motor original, e valem aqui palavra por palavra)

    1. NADA É REESCRITO. O `texto` de um item é a string publicada no
       dossiê. Sem resumos, sem paráfrases, sem geração. O único texto
       que nasce aqui é aritmética — «4 itens» — e isso é contagem, não
       conteúdo. É a diferença entre um recorte que se pode citar e um
       que se tem de ir confirmar.

    2. NADA É INVENTADO POR AUSÊNCIA. Um recorte sem tickets não gera
       secção «tickets» vazia: gera recorte sem essa secção.

   E a fronteira, que é lista BRANCA e nunca negra: com uma lista negra,
   um campo novo passa a seguir por omissão e o erro descobre-se depois
   de já ter seguido. Aqui um campo que ninguém autorizou fica de fora, e
   o pior que acontece é faltar informação — que se vê e se corrige.
   ═══════════════════════════════════════════════════════════════════════ */

window.XC = (() => {
"use strict";

/* ═══ 1 · A FRONTEIRA ═══════════════════════════════════════════════ */

/**
 * Chaves estruturais: existem em todos os itens, de todas as secções, e
 * não são opcionais. `proveniencia` está aqui porque um item sem ela não
 * é um item — é uma afirmação órfã.
 */
const CAMPOS_ESTRUTURAIS = ["id", "marca", "texto", "proveniencia"];

/** O que um item de cada secção pode transportar, além dos estruturais. */
const CAMPOS_POR_SECCAO = {
  seccoes: ["parte", "lede"],
  tickets: ["estado", "fase", "depende"],
  perguntas: ["estado", "bloqueia", "decide"],
  adrs: ["estado"],
  notas: ["classe"],
  tabelas: ["registos", "campos"],
};

const ORDEM_SECCOES = ["seccoes", "notas", "tickets", "perguntas", "adrs", "tabelas"];

const TITULO_SECCAO = {
  seccoes: "Secções",
  notas: "Caixas de decisão e risco",
  tickets: "Tickets",
  perguntas: "Perguntas",
  adrs: "Decisões de arquitetura",
  tabelas: "Tabelas de dados",
};

/** Mapeia o tipo do índice para a secção do recorte. */
const SECCAO_DE = {
  seccao: "seccoes", sub: "seccoes", nota: "notas",
  ticket: "tickets", questao: "perguntas", adr: "adrs", tabela: "tabelas",
};

/**
 * Passa um item pela lista branca. O que não está declarado não viaja —
 * e isto corre em TODOS os itens, não só nos que alguém se lembrou de
 * verificar.
 */
function sanitizar(seccao, item) {
  const permitidas = CAMPOS_ESTRUTURAIS.concat(CAMPOS_POR_SECCAO[seccao] || []);
  const out = {};
  for (const k of permitidas) {
    if (item[k] !== undefined && item[k] !== "" && item[k] !== null) out[k] = item[k];
  }
  return out;
}

/**
 * Reprova um recorte que leve um campo não autorizado. É a rede que
 * apanha o dia em que alguém acrescenta um campo ao índice e ele começa
 * a viajar sem ninguém ter decidido isso.
 */
function auditar(recorte) {
  const achados = [];
  for (const sec of recorte.seccoes) {
    const permitidas = new Set(CAMPOS_ESTRUTURAIS.concat(CAMPOS_POR_SECCAO[sec.id] || []));
    for (const item of sec.itens) {
      for (const k of Object.keys(item)) {
        if (!permitidas.has(k)) achados.push(`${sec.id}/${item.id}: campo «${k}» não está na lista branca`);
      }
      if (!item.proveniencia) achados.push(`${sec.id}/${item.id}: item sem proveniência`);
    }
  }
  return achados;
}

/* ═══ 2 · A BANDEJA ═════════════════════════════════════════════════
   O que a pessoa foi juntando enquanto lia. Vive em memória e em
   `sessionStorage` — nunca no endereço, que é a regra do `handoff.ts`:
   um URL é partilhado, indexado e registado em servidores que não são
   nossos, e o que a pessoa escolheu ler é dela. */

const CHAVE = "empire:recorte";
let bandeja = [];

function carregar() {
  try {
    const cru = sessionStorage.getItem(CHAVE);
    bandeja = cru ? JSON.parse(cru) : [];
  } catch (e) { bandeja = []; }
  return bandeja;
}

function gravar() {
  try { sessionStorage.setItem(CHAVE, JSON.stringify(bandeja)); } catch (e) { /* sessão fechada a escrita */ }
  window.dispatchEvent(new CustomEvent("x-recorte", { detail: { n: bandeja.length } }));
}

const tem = (id) => bandeja.indexOf(id) !== -1;
const conta = () => bandeja.length;

function alternar(id) {
  const i = bandeja.indexOf(id);
  if (i === -1) bandeja.push(id); else bandeja.splice(i, 1);
  gravar();
  return tem(id);
}

function limpar() { bandeja = []; gravar(); }

/* ═══ 3 · COMPOR ════════════════════════════════════════════════════ */

/** O texto publicado de um documento — lido, nunca reescrito. */
function textoDe(doc) {
  if (doc.tipo === "seccao" || doc.tipo === "sub") return doc.descricao || doc.titulo;
  return doc.descricao || doc.titulo;
}

function itemDe(doc) {
  const seccao = SECCAO_DE[doc.tipo];
  const ref = doc.ref || {};
  const bruto = {
    id: doc.id,
    marca: doc.marca,
    texto: textoDe(doc),
    // Proveniência: de onde é que esta linha veio. Sem isto, um recorte
    // é um conjunto de afirmações sem dono.
    proveniencia: doc.ref ? "inventário do ZIP" : "texto do dossiê",
    parte: doc.contexto,
    lede: doc.descricao,
    estado: ref.estado,
    fase: ref.fase,
    depende: ref.depende,
    bloqueia: ref.bloqueia,
    decide: ref.decide,
    classe: doc.tipo === "nota" ? (doc.contexto || "").split("·").pop().trim() : undefined,
    registos: ref.registos,
    campos: ref.campos,
  };
  return sanitizar(seccao, bruto);
}

/**
 * Compõe o recorte a partir da bandeja e do índice.
 *
 * A regra 2 em código: uma secção sem itens não entra no objeto. Não é
 * escondida na leitura nem filtrada na apresentação — não existe.
 */
function compor(docs, titulo) {
  const porId = new Map(docs.map((d) => [d.id, d]));
  const porSeccao = new Map();

  for (const id of bandeja) {
    const doc = porId.get(id);
    if (!doc) continue;                       // saiu do índice: não se inventa
    const sec = SECCAO_DE[doc.tipo];
    if (!sec) continue;
    if (!porSeccao.has(sec)) porSeccao.set(sec, []);
    porSeccao.get(sec).push(itemDe(doc));
  }

  const seccoes = ORDEM_SECCOES
    .filter((s) => porSeccao.has(s) && porSeccao.get(s).length > 0)
    .map((s) => ({ id: s, titulo: TITULO_SECCAO[s], itens: porSeccao.get(s) }));

  const recorte = {
    titulo: (titulo || "Recorte do dossiê Empire v6").trim(),
    origem: "Empire v6 · dossiê de desenho",
    itens: seccoes.reduce((n, s) => n + s.itens.length, 0),
    seccoes,
  };
  recorte.impressao = impressao(recorte);
  return recorte;
}

/* ═══ 4 · A IMPRESSÃO ═══════════════════════════════════════════════
   Serve uma frase concreta que sem ela é impossível dizer: «este recorte
   foi feito sobre a versão de terça; o dossiê mudou — vê o que mudou.»

   Duas regras de construção, e as duas são a diferença entre uma
   impressão útil e uma decorativa:

    1. É SOBRE OS DADOS, não sobre a apresentação. Dois recortes com os
       mesmos itens dão a mesma impressão ainda que o markdown mude.

    2. NÃO INCLUI O INSTANTE DA COMPOSIÇÃO. Se incluísse, cada abertura
       da folha daria uma impressão nova e a pergunta «é o mesmo
       recorte?» deixaria de ter resposta.

   Não é criptográfica e não finge ser: é uma impressão digital para
   comparar duas coisas, não para as proteger de alguém. */

function canonico(valor) {
  if (Array.isArray(valor)) return "[" + valor.map(canonico).join(",") + "]";
  if (valor && typeof valor === "object") {
    return "{" + Object.keys(valor).sort()
      .filter((k) => valor[k] !== undefined && k !== "impressao")
      .map((k) => JSON.stringify(k) + ":" + canonico(valor[k])).join(",") + "}";
  }
  return JSON.stringify(valor);
}

function impressao(recorte) {
  const s = canonico({ titulo: recorte.titulo, seccoes: recorte.seccoes });
  // FNV-1a de 32 bits, duas passagens com sementes diferentes para dar
  // 16 caracteres legíveis sem depender de `crypto.subtle`, que é
  // assíncrono e não existe em `file://` em todos os browsers.
  const fnv = (semente) => {
    let h = semente >>> 0;
    for (let i = 0; i < s.length; i++) {
      h ^= s.charCodeAt(i);
      h = Math.imul(h, 16777619) >>> 0;
    }
    return h.toString(16).padStart(8, "0");
  };
  return (fnv(2166136261) + fnv(0x811c9dc5 ^ 0x5bf03635)).slice(0, 16);
}

/* ═══ 5 · FORMATOS ══════════════════════════════════════════════════
   Três, porque servem três destinos diferentes: markdown para colar numa
   conversa, JSON para uma ferramenta ler, CSV para uma folha de cálculo.
   Nenhum deles reescreve o texto. */

function markdown(r) {
  const l = [];
  l.push("# " + r.titulo, "");
  l.push(`> ${r.itens} ${r.itens === 1 ? "item" : "itens"} recortados de ${r.origem}.`);
  l.push(`> Impressão \`${r.impressao}\` — se o dossiê mudar, esta muda.`, "");
  for (const sec of r.seccoes) {
    l.push(`## ${sec.titulo}`, "");
    for (const it of sec.itens) {
      l.push(`### ${it.marca ? it.marca + " — " : ""}${it.texto}`);
      const meta = [];
      for (const k of CAMPOS_POR_SECCAO[sec.id] || []) if (it[k]) meta.push(`**${k}:** ${it[k]}`);
      if (meta.length) l.push("", meta.join(" · "));
      l.push("", `<sub>proveniência: ${it.proveniencia}</sub>`, "");
    }
  }
  return l.join("\n");
}

function json(r) { return JSON.stringify(r, null, 2); }

function csv(r) {
  const campos = ["seccao", "marca", "texto", "proveniencia", "estado", "fase", "depende", "bloqueia"];
  const esc = (v) => {
    const s = v === undefined || v === null ? "" : String(v);
    return /[",\n]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s;
  };
  const linhas = [campos.join(",")];
  for (const sec of r.seccoes) {
    for (const it of sec.itens) linhas.push(campos.map((c) => esc(c === "seccao" ? sec.id : it[c])).join(","));
  }
  return linhas.join("\n");
}

const FORMATOS = {
  markdown: { rotulo: "Markdown", ext: "md", tipo: "text/markdown", render: markdown },
  json: { rotulo: "JSON", ext: "json", tipo: "application/json", render: json },
  csv: { rotulo: "CSV", ext: "csv", tipo: "text/csv", render: csv },
};

carregar();

return {
  carregar, gravar, tem, conta, alternar, limpar, bandeja: () => bandeja.slice(),
  compor, impressao, auditar, sanitizar, FORMATOS,
  CAMPOS_ESTRUTURAIS, CAMPOS_POR_SECCAO, SECCAO_DE, ORDEM_SECCOES, TITULO_SECCAO,
};
})();
