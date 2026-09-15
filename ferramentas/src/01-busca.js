/* ═══════════════════════════════════════════════════════════════════════
   A PESQUISA — determinística, explicável, e sem subsequência
   ---------------------------------------------------------------------
   Porte directo da disciplina de `src/lib/busca/` do Recibo Certo:
   `normalizar.ts`, `pontuar.ts`, `recentes.ts` e a moldura de
   `moldura.tsx`. Os números são os mesmos porque foram calibrados contra
   um catálogo português real — reinventá-los aqui seria recomeçar a
   aprendizagem do zero num documento que também é em português.

   ┌─────────────────────────────────────────────────────────────────────┐
   │ O QUE NUNCA PODE VOLTAR A ACONTECER: A SUBSEQUÊNCIA                  │
   │                                                                     │
   │ A tentação, num documento de 6 177 linhas, é dar pontos quando as    │
   │ letras da consulta aparecem por ordem em qualquer sítio do texto.    │
   │ Em português isso encontra tudo em tudo: «podridão» é subsequência   │
   │ de meia dúzia de parágrafos que não falam dela. Não é um resultado   │
   │ mau — é um resultado INVENTADO, e o que se perde não é a pesquisa, é │
   │ a confiança de que a pesquisa sabe alguma coisa.                     │
   │                                                                     │
   │ O que fica: frase exacta, prefixo, subcadeia em FRONTEIRA DE         │
   │ PALAVRA, token exacto, prefixo de token e uma gralha a partir de     │
   │ cinco letras. Cada correspondência tem nome, e o nome viaja com o    │
   │ resultado — um resultado que ninguém explica não se consegue         │
   │ corrigir.                                                           │
   └─────────────────────────────────────────────────────────────────────┘
   ═══════════════════════════════════════════════════════════════════════ */

const X = (() => {
"use strict";

/* ─── Normalização ─────────────────────────────────────────────────── */

/** Minúsculas pt-PT, sem acentos, pontuação → ESPAÇO (não vazio: «fatura-recibo» tem de dar dois tokens). */
function normalizar(v) {
  return String(v)
    .toLocaleLowerCase("pt-PT")
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/[^a-z0-9§]+/g, " ")
    .trim();
}

function tokens(v) {
  const l = normalizar(v);
  return l ? l.split(" ").filter(Boolean) : [];
}

/* Só artigos, preposições e contracções. Nenhuma palavra que possa ser
   assunto. Aplica-se à CONSULTA — o texto do documento fica inteiro. */
const LIGACAO = new Set(
  ("a ao aos as com da das de do dos e em na nas no nos o os ou para por um uma uns umas " +
   "que se ser sobre entre ate desde").split(" "),
);

function tokensDeConsulta(v) {
  const todos = tokens(v);
  const uteis = todos.filter((t) => !LIGACAO.has(t));
  return uteis.length ? uteis : todos;
}

/** `true` quando `a` e `b` estão a UMA edição. Sem matriz: a pergunta é «≤1», não «quanto». */
function distanciaAteUm(a, b) {
  if (a === b) return true;
  const [curta, longa] = a.length <= b.length ? [a, b] : [b, a];
  if (longa.length - curta.length > 1) return false;
  let i = 0, j = 0, erros = 0;
  while (i < curta.length && j < longa.length) {
    if (curta[i] === longa[j]) { i++; j++; continue; }
    if (++erros > 1) return false;
    if (curta.length === longa.length) i++;
    j++;
  }
  return erros + (longa.length - j) <= 1;
}

/* ─── Pontuação ────────────────────────────────────────────────────── */

const MIN_CARACTERES = 2;
const LIMIAR = 18;
const TETO = 40;

/**
 * Pesos por campo. O título manda; o corpo confirma, não decide.
 *
 * ┌─────────────────────────────────────────────────────────────────────┐
 * │ O IDENTIFICADOR É UM CAMPO PRÓPRIO, E PESA MAIS DO QUE O TÍTULO      │
 * │                                                                     │
 * │ Escrever `F1-08` devolvia, em primeiro lugar, o sub-título «O        │
 * │ formato de tarefa — copia para docs/backlog/F1-08.md» — um parágrafo │
 * │ que CITA o ticket — e só depois o próprio ticket F1-08. Os dois      │
 * │ tinham 90 pontos, e o título ganhou o desempate.                     │
 * │                                                                     │
 * │ Está errado por uma razão que não é de pontuação: quem escreve um    │
 * │ identificador não está a pesquisar texto, está a ENDEREÇAR uma       │
 * │ coisa. `§07`, `Q-001`, `ADR 0011`, `clock.csv` — todos iguais. Um    │
 * │ identificador exacto não compete com prosa; ganha-lhe.               │
 * └─────────────────────────────────────────────────────────────────────┘
 */
const PESO = { marca: 1.2, titulo: 1, aliases: 0.9, descricao: 0.55, corpo: 0.4 };

/**
 * A subcadeia vale — mas só a começar numa FRONTEIRA DE PALAVRA.
 * Sem isto, `includes` reintroduz o problema da subsequência pela porta
 * do lado: «ira» encontra «primeira» e «estrangeira».
 */
function contemEmFronteira(texto, q) {
  let i = texto.indexOf(q);
  while (i !== -1) {
    if (i === 0 || texto[i - 1] === " ") return true;
    i = texto.indexOf(q, i + 1);
  }
  return false;
}

/* Normalizar ~600 documentos × 4 campos por tecla é o grosso do custo, e
   o resultado é sempre o mesmo. O cache vive tanto quanto o índice. */
const cacheNorm = new Map();
function normCampo(v) {
  if (!v) return "";
  const em = cacheNorm.get(v);
  if (em !== undefined) return em;
  const n = normalizar(v);
  cacheNorm.set(v, n);
  return n;
}
const cacheTok = new Map();
function tokCampo(norm) {
  const em = cacheTok.get(norm);
  if (em !== undefined) return em;
  const t = norm ? norm.split(" ").filter(Boolean) : [];
  cacheTok.set(norm, t);
  return t;
}

/**
 * A pontuação de UM campo. Vale o MELHOR de dois sinais — frase e
 * palavras — e nunca só o primeiro que dispara.
 *
 * A versão que saía cedo na frase («frase exacta 120, devolve») dava a
 * uma consulta de quatro palavras 90 pontos por um alias inteiro, quando
 * quem acertava em três das quatro palavras valia 101. O melhor dos dois
 * não faz entrar ninguém na lista: só corrige quem já lá estava mal
 * ordenado.
 */
function pontuarCampo(qNorm, valor) {
  const texto = normCampo(valor);
  if (!qNorm || !texto) return 0;

  const porFrase =
    texto === qNorm ? 120
    : texto.startsWith(qNorm) ? 90
    : contemEmFronteira(texto, qNorm) ? 70
    : 0;

  const tDoc = tokCampo(texto);
  const tCon = tokensDeConsulta(qNorm);
  if (!tCon.length) return porFrase;

  let soma = 0, cobertos = 0;
  for (const alvo of tCon) {
    let p = 0;
    if (tDoc.includes(alvo)) p = 45;
    else if (alvo.length >= 3 && tDoc.some((t) => t.startsWith(alvo))) p = 28;
    // Uma gralha só é perdoada a partir de cinco letras: em palavras
    // curtas uma edição transforma «rot» em «rio» e passa a ser outra
    // pergunta.
    else if (alvo.length >= 5 && tDoc.some((t) => distanciaAteUm(t, alvo))) p = 18;
    if (p > 0) cobertos++;
    soma += p;
  }
  if (!cobertos) return porFrase;

  // Proporção de cobertura: quem cobre metade da pergunta vale metade.
  // É o que impede «a podridão avança» de devolver tudo o que diz
  // «podridão» ao mesmo nível de quem responde à frase toda.
  return Math.max(porFrase, soma * (cobertos / tCon.length));
}

function pontuarDoc(q, doc) {
  const candidatos = [
    ["marca", pontuarCampo(q, doc.marca) * PESO.marca],
    ["titulo", pontuarCampo(q, doc.titulo) * PESO.titulo],
    ["aliases", pontuarCampo(q, doc.aliases) * PESO.aliases],
    ["descricao", pontuarCampo(q, doc.descricao) * PESO.descricao],
    ["corpo", pontuarCampo(q, doc.corpo) * PESO.corpo],
  ];
  let campo = "titulo", melhor = 0;
  for (const [nome, p] of candidatos) if (p > melhor) { melhor = p; campo = nome; }
  if (melhor <= 0) return null;
  // A prioridade nunca faz passar o limiar sozinha: entra depois, e só
  // desempata (0–100 → 0–1 ponto).
  return { doc, pontos: melhor + (doc.prioridade || 0) / 100, campo };
}

const ORDEM_TIPOS = ["seccao", "sub", "ticket", "questao", "adr", "nota", "tabela", "mecanica", "cor"];

function pesquisar(consulta, documentos, opcoes) {
  const o = opcoes || {};
  const q = normalizar(consulta);
  if (q.length < MIN_CARACTERES) return [];
  const out = [];
  for (const doc of documentos) {
    if (o.tipo && o.tipo !== "tudo" && doc.tipo !== o.tipo) continue;
    const r = pontuarDoc(q, doc);
    if (r && r.pontos >= LIMIAR) out.push(r);
  }
  out.sort(
    (a, b) =>
      b.pontos - a.pontos ||
      (b.doc.prioridade || 0) - (a.doc.prioridade || 0) ||
      ORDEM_TIPOS.indexOf(a.doc.tipo) - ORDEM_TIPOS.indexOf(b.doc.tipo) ||
      // Sem o último critério, dois empatados trocavam de lugar entre
      // teclas conforme a ordem do índice.
      a.doc.id.localeCompare(b.doc.id, "pt-PT"),
  );
  return o.limite ? out.slice(0, o.limite) : out;
}

/**
 * A MELHOR RESPOSTA — no máximo uma, e só quando se destaca de facto.
 * Coroar sempre o primeiro seria um enfeite: numa lista em que o primeiro
 * e o segundo estão empatados, destacar um é anunciar uma certeza que não
 * existe.
 */
function melhorResposta(res) {
  const [p, s] = res;
  if (!p) return null;
  if (!s) return p;
  return p.pontos >= s.pontos * 1.25 ? p : null;
}

/** Agrupa por tipo — mas a ORDEM dos grupos vem do ranking, não da lista. */
function agrupar(res) {
  const m = new Map();
  for (const r of res) {
    const l = m.get(r.doc.tipo);
    if (l) l.push(r); else m.set(r.doc.tipo, [r]);
  }
  return [...m.entries()].sort(
    ([ta, la], [tb, lb]) =>
      lb[0].pontos - la[0].pontos || ORDEM_TIPOS.indexOf(ta) - ORDEM_TIPOS.indexOf(tb),
  );
}

/* ─── Recentes ─────────────────────────────────────────────────────────
   ┌─────────────────────────────────────────────────────────────────────┐
   │ UM HISTÓRICO DE PESQUISA NÃO É INÓCUO, NEM AQUI                      │
   │                                                                     │
   │ Num dossiê de produção o que se escreve na barra pode ser o nome de  │
   │ um contacto, um valor de orçamento ou uma nota privada colada da     │
   │ área de transferência. Três regras, e nenhuma depende de disciplina: │
   │ o que parece identificador nunca é guardado (na PORTA DE ENTRADA,    │
   │ não numa limpeza posterior que alguém esqueça), o que é guardado     │
   │ expira em 30 dias, e há um botão para apagar tudo onde a lista está. │
   └─────────────────────────────────────────────────────────────────────┘ */

const CHAVE_REC = "empire.busca.recentes.v1";
const MAX_REC = 4;
const TTL = 30 * 24 * 60 * 60 * 1000;

const SENSIVEL = [
  /\d{9}/,                              // NIF, NISS, telefone
  /PT50[\s\d]{10,}/i,                   // IBAN português
  /\b[A-Z]{2}\d{2}[A-Z0-9]{10,}\b/i,    // IBAN estrangeiro
  /\S+@\S+\.\S+/,                       // email
  /\d[\d\s.,]{7,}/,                     // qualquer número comprido
];

function termoGuardavel(c) {
  const v = String(c).trim().replace(/\s+/g, " ");
  if (v.length < 2 || v.length > 80) return null;
  if (SENSIVEL.some((p) => p.test(v))) return null;
  return v;
}

function lerCru() {
  try {
    const cru = localStorage.getItem(CHAVE_REC);
    if (!cru) return [];
    const l = JSON.parse(cru);
    if (!Array.isArray(l)) return [];
    const limite = Date.now() - TTL;
    return l.filter((x) => x && typeof x.termo === "string" && typeof x.em === "number" && x.em > limite);
  } catch { return []; }
}

/* A expiração é aplicada na LEITURA e o resultado é reescrito — um TTL
   que só filtrasse deixava a frase no disco para sempre, invisível mas lá. */
function lerRecentes() {
  const vivos = lerCru();
  try {
    const cru = localStorage.getItem(CHAVE_REC);
    if (cru && JSON.stringify(vivos) !== cru) localStorage.setItem(CHAVE_REC, JSON.stringify(vivos));
  } catch { /* modo privado */ }
  return vivos;
}

function guardarRecente(c) {
  const termo = termoGuardavel(c);
  if (!termo) return;
  const antes = lerCru().filter((r) => r.termo.toLocaleLowerCase("pt-PT") !== termo.toLocaleLowerCase("pt-PT"));
  try {
    localStorage.setItem(CHAVE_REC, JSON.stringify([{ termo, em: Date.now() }, ...antes].slice(0, MAX_REC)));
  } catch { /* quota */ }
}

function limparRecentes() {
  try { localStorage.removeItem(CHAVE_REC); } catch { /* nada a fazer */ }
}

/* ─── Realce do termo no resultado ─────────────────────────────────── */

/**
 * ┌─────────────────────────────────────────────────────────────────────┐
 * │ O PREFIXO `x-` SIGNIFICA DUAS COISAS, E ISSO JÁ CUSTOU TRÊS VEZES    │
 * │                                                                     │
 * │ Tudo o que esta camada acrescenta leva o prefixo `x-`, e dois        │
 * │ varrimentos usam-no como «não é do autor, não mexer»: o que liga as  │
 * │ referências §NN e o que sublinha os termos do glossário. Só que      │
 * │ nem tudo o que leva o prefixo é conteúdo da camada — alguns são      │
 * │ INVÓLUCROS que apenas embrulham a prosa do autor sem lhe acrescentar │
 * │ uma palavra.                                                        │
 * │                                                                     │
 * │ Cada vez que um invólucro novo apareceu, os dois varrimentos         │
 * │ passaram a saltar tudo o que estava lá dentro — sem erro, sem aviso, │
 * │ e com o portão a contar menos e a dizer que estava tudo bem:         │
 * │                                                                     │
 * │   `x-parte-corpo`  941 referências → 174                             │
 * │   `x-rolo`         940 referências → 531 · 150 termos → 84           │
 * │                                                                     │
 * │ A lista vive AQUI, uma vez, e é lida pelos dois. Um invólucro novo   │
 * │ acrescenta-se num sítio só — e o portão passou a reprovar se as      │
 * │ contagens caírem, para o quarto não custar outra versão.            │
 * └─────────────────────────────────────────────────────────────────────┘
 */
const INVOLUCROS = new Set(["x-como", "x-parte", "x-parte-corpo", "x-rolo", "x-calha"]);

const escapar = (s) =>
  String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

/**
 * Realça as palavras da consulta no texto, sem regex construída à mão a
 * partir de entrada do utilizador (que seria uma injecção à espera de
 * acontecer) e sem perder os acentos do original: percorre-se o texto
 * NORMALIZADO à procura das posições, e cortam-se as mesmas posições no
 * texto CRU — só funciona porque `normalizar` preserva o comprimento
 * carácter a carácter para as letras acentuadas.
 */
function realcar(texto, consulta) {
  const cru = String(texto);
  const alvos = tokensDeConsulta(consulta).filter((t) => t.length >= 2);
  if (!alvos.length) return escapar(cru);
  const norm = cru
    .toLocaleLowerCase("pt-PT")
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "");
  if (norm.length !== cru.length) return escapar(cru); // ligaduras: não arrisca
  const marcas = new Array(cru.length).fill(false);
  for (const alvo of alvos) {
    let i = norm.indexOf(alvo);
    while (i !== -1) {
      const antes = i === 0 || !/[a-z0-9]/.test(norm[i - 1]);
      if (antes) for (let k = i; k < i + alvo.length; k++) marcas[k] = true;
      i = norm.indexOf(alvo, i + 1);
    }
  }
  let out = "", aberto = false;
  for (let i = 0; i < cru.length; i++) {
    if (marcas[i] && !aberto) { out += "<em>"; aberto = true; }
    if (!marcas[i] && aberto) { out += "</em>"; aberto = false; }
    out += escapar(cru[i]);
  }
  return out + (aberto ? "</em>" : "");
}

/**
 * O excerto: a janela de texto à volta da primeira palavra encontrada.
 * Um resultado que só diz «§07 — Combate» obriga a abrir para saber se é
 * aquele; um resultado que mostra a frase responde antes do clique.
 */
function excerto(texto, consulta, janela) {
  const cru = String(texto || "");
  if (!cru) return "";
  const w = janela || 150;
  const alvos = tokensDeConsulta(consulta).filter((t) => t.length >= 3);

  /**
   * ┌─────────────────────────────────────────────────────────────────┐
   * │ A POSIÇÃO TEM DE SER MEDIDA NO TEXTO CRU                         │
   * │                                                                 │
   * │ A primeira versão procurava no texto NORMALIZADO e cortava o     │
   * │ texto CRU nessa posição. `normalizar` colapsa espaços e          │
   * │ pontuação, portanto os dois índices divergem — e a divergência   │
   * │ cresce com o comprimento. O resultado eram excertos a começar a  │
   * │ meio de uma palavra: «…conomy: rendimento, sorvedouros…».        │
   * │                                                                 │
   * │ A dobra abaixo preserva o comprimento carácter a carácter        │
   * │ (minúsculas e sem acentos, mas sem mexer em espaços), portanto   │
   * │ o índice é o mesmo nos dois. E a janela ajusta-se para começar   │
   * │ e acabar em fronteira de palavra — uma palavra cortada a meio    │
   * │ faz o leitor duvidar do excerto inteiro.                         │
   * └─────────────────────────────────────────────────────────────────┘
   */
  const dobrado = cru
    .toLocaleLowerCase("pt-PT")
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "");
  const alinhado = dobrado.length === cru.length;

  let pos = -1;
  if (alinhado) {
    for (const a of alvos) {
      let i = dobrado.indexOf(a);
      while (i !== -1) {
        if (i === 0 || !/[a-z0-9]/.test(dobrado[i - 1])) break;
        i = dobrado.indexOf(a, i + 1);
      }
      if (i !== -1 && (pos === -1 || i < pos)) pos = i;
    }
  }
  if (pos === -1) {
    const corte = cru.length > w ? recuarAteEspaco(cru, w) : cru.length;
    return cru.slice(0, corte).trim() + (corte < cru.length ? "…" : "");
  }

  let inicio = Math.max(0, pos - Math.floor(w / 3));
  if (inicio > 0) {
    // Avança até depois do primeiro espaço: começar a meio de uma palavra
    // é o defeito que isto existe para não ter.
    const espaco = cru.indexOf(" ", inicio);
    inicio = espaco !== -1 && espaco < pos ? espaco + 1 : inicio;
  }
  const fim = Math.min(cru.length, recuarAteEspaco(cru, inicio + w));
  return (inicio > 0 ? "…" : "") + cru.slice(inicio, fim).trim() + (fim < cru.length ? "…" : "");
}

/** Recua até ao espaço anterior, para não cortar uma palavra ao meio. */
function recuarAteEspaco(texto, i) {
  if (i >= texto.length) return texto.length;
  const espaco = texto.lastIndexOf(" ", i);
  return espaco > i - 24 && espaco > 0 ? espaco : i;
}

return {
  normalizar, tokens, tokensDeConsulta, distanciaAteUm,
  pontuarCampo, pontuarDoc, pesquisar, melhorResposta, agrupar,
  lerRecentes, guardarRecente, limparRecentes, termoGuardavel,
  realcar, excerto, escapar,
  MIN_CARACTERES, LIMIAR, TETO, ORDEM_TIPOS,
  INVOLUCROS,
};
})();
