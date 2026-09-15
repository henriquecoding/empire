/* ═══════════════════════════════════════════════════════════════════════
   RECONHECIMENTO E PLANO — o que a frase diz, e o que a interface pode
   AFIRMAR a partir disso
   ---------------------------------------------------------------------
   ┌─────────────────────────────────────────────────────────────────────┐
   │ PORTADO DE `src/lib/busca/reconhecer.ts` E `plano.ts`                │
   │                                                                     │
   │ A pesquisa que já cá estava ordenava bem e respondia mal: devolvia   │
   │ uma LISTA a quem tinha feito uma PERGUNTA. Escrever «o F0-00 está    │
   │ feito?» dava dezassete resultados ordenados, e a resposta — que      │
   │ está no ZIP, num campo — ficava à espera de ser clicada.             │
   │                                                                     │
   │ O Recibo Certo resolve isto em duas camadas separadas, e a           │
   │ separação é o que faz a coisa funcionar:                             │
   │                                                                     │
   │  · `reconhecer` extrai o que ESTÁ ESCRITO e mais nada. Não           │
   │    preenche o que falta. Se a pessoa escreveu «fase 1», sai «fase    │
   │    1» — não sai «tickets da fase 1», que era um palpite.             │
   │                                                                     │
   │  · `plano` decide o TOM: afirmar, perguntar UMA coisa, mostrar sem   │
   │    coroar, ou dizer que não sabe. E guarda os CÓDIGOS das regras     │
   │    que o produziram, para o «porquê isto?» ter resposta em vez de    │
   │    uma frase escrita à mão.                                          │
   │                                                                     │
   │ Sem esta fronteira, «isto é uma certeza ou é um palpite?» acaba      │
   │ espalhado pelo código que desenha — um `resultados[0]` aqui, um      │
   │ `&&` ali — e passa a ser respondido por acidente.                    │
   └─────────────────────────────────────────────────────────────────────┘

   A REGRA QUE NÃO SE ATRAVESSA: nenhuma resposta chega ao ecrã sem
   proveniência. Um número que saiu do ZIP diz que saiu do ZIP; uma
   contagem diz que é contagem. Não há caminho no código para o evitar —
   `resposta()` exige o campo.

   Determinístico e local: expressões regulares e listas fechadas. Sem
   modelo, sem rede. A consulta nunca sai do ficheiro.
   ═══════════════════════════════════════════════════════════════════════ */

window.XR = (() => {
"use strict";

/* ═══ 1 · RECONHECER ════════════════════════════════════════════════
   Só sai o que está escrito. O que falta fica a faltar. */

/**
 * Os identificadores que este documento usa. Cada um traz o `texto` tal
 * como a pessoa o escreveu — devolver a nossa grafia em vez da dela seria
 * pedir-lhe que confirmasse uma tradução que não pediu.
 */
const PADROES = [
  {
    tipo: "seccao",
    re: /(?:§\s*|\bsec(?:ç|c)(?:ão|ao)\s+|\bs(?=\d))(\d{1,2})\b/gi,
    canon: (m) => String(Number(m[1])).padStart(2, "0"),
  },
  { tipo: "ticket", re: /\bF\s?([01])\s?[-–]\s?(\d{1,2})\b/gi, canon: (m) => `F${m[1]}-${String(Number(m[2])).padStart(2, "0")}` },
  { tipo: "questao", re: /\bQ\s?[-–]?\s?(\d{1,3})\b/gi, canon: (m) => "Q-" + String(Number(m[1])).padStart(3, "0") },
  { tipo: "adr", re: /\bADR\s?[-–]?\s?(\d{1,4})\b/gi, canon: (m) => "ADR " + String(Number(m[1])).padStart(4, "0") },
  { tipo: "fase", re: /\bfase\s*([0-8])\b/gi, canon: (m) => "Fase " + m[1] },
  { tipo: "parte", re: /\bparte\s+([ivxlcdm]{1,6}|\d{1,2})\b/gi, canon: (m) => "Parte " + romano(m[1]) },
  { tipo: "cor", re: /#([0-9a-f]{6})\b/gi, canon: (m) => "#" + m[1].toUpperCase() },
];

const ROMANOS = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII", "XIV", "XV"];
function romano(bruto) {
  const s = String(bruto).toUpperCase();
  if (/^\d+$/.test(s)) return ROMANOS[Number(s)] || s;
  return s;
}

/**
 * Sinais de INTENÇÃO. Não dizem de que assunto se fala — dizem o que se
 * quer saber sobre ele, que é a metade que decide se há resposta ou só
 * há destino.
 */
const SINAIS = [
  { sinal: "estado", termos: ["esta feito", "estao feitos", "ja esta", "falta", "faltam", "por fazer", "estado", "pronto", "acabado", "concluido", "parcial"] },
  { sinal: "dependencia", termos: ["bloqueia", "bloqueado", "depende", "dependencia", "trava", "travado", "impede", "desbloqueia"] },
  { sinal: "contagem", termos: ["quantos", "quantas", "quanto", "numero de", "total de"] },
  { sinal: "localizacao", termos: ["onde", "em que seccao", "em que parte", "onde fica", "onde esta"] },
  { sinal: "definicao", termos: ["o que e", "que significa", "significa", "define", "definicao", "quer dizer"] },
  { sinal: "estimativa", termos: ["horas", "quanto tempo", "estimativa", "esforco", "demora"] },
];

/**
 * `reconhecer` devolve sempre a mesma forma, com listas vazias quando
 * não há nada. Quem lê não tem de se defender de `undefined`.
 */
function reconhecer(consulta) {
  const bruto = String(consulta || "");
  const normal = X.normalizar(bruto);
  const entidades = [];
  const vistos = new Set();

  for (const p of PADROES) {
    p.re.lastIndex = 0;
    let m;
    while ((m = p.re.exec(bruto)) !== null) {
      const valor = p.canon(m);
      const chave = p.tipo + ":" + valor;
      if (vistos.has(chave)) continue;
      vistos.add(chave);
      entidades.push({ tipo: p.tipo, valor, texto: m[0].trim() });
    }
  }

  const sinais = [];
  for (const s of SINAIS) {
    if (s.termos.some((t) => normal.includes(t))) sinais.push(s.sinal);
  }

  return { consulta: bruto, normal, entidades, sinais };
}

/** A entidade de um tipo, se houver exactamente uma. */
function entidade(r, tipo) {
  const achadas = r.entidades.filter((e) => e.tipo === tipo);
  return achadas.length === 1 ? achadas[0] : undefined;
}

/* ═══ 2 · PROVENIÊNCIA ══════════════════════════════════════════════
   Um item sem ela não é um item; é uma afirmação órfã. */

const FONTE = {
  zip: "do inventário do ZIP",
  documento: "do texto do dossiê",
  contagem: "contagem sobre o inventário",
};

/**
 * Constrói uma resposta. Os três campos são obrigatórios de propósito:
 * não há sobrecarga que os deixe cair, e portanto não há resposta sem
 * proveniência.
 */
function resposta(texto, proveniencia, detalhe) {
  if (!texto || !proveniencia) throw new Error("[plano] resposta sem texto ou sem proveniência");
  return { texto, proveniencia, detalhe: detalhe || "" };
}

/* ═══ 3 · O PLANO ═══════════════════════════════════════════════════

   Os quatro estados, e o tom de cada um:

    · pronto       há um caminho e nada material falta. Afirma-se.
    · clarificar   há caminho, falta um dado que muda o resultado.
                   Faz-se UMA pergunta.
    · reconhecido  percebeu-se o assunto, nenhum caminho se destaca.
                   Mostram-se resultados, sem coroar nenhum.
    · sem_caminho  não há confiança. Diz-se isso. */

const MAX_ALTERNATIVAS = 3;

function achar(docs, tipo, marca) {
  return docs.find((d) => d.tipo === tipo && d.marca === marca) || null;
}

/** Quantos tickets declaram depender de `id`. */
function bloqueados(dados, id) {
  if (!dados || !dados.tickets) return [];
  return dados.tickets.filter((t) => String(t.depende || "").includes(id));
}

/**
 * Compila o plano. Recebe o índice já construído — não lhe chama nada
 * que possa falhar — e devolve sempre um objecto.
 */
function compilar(consulta, docs, dados) {
  const r = reconhecer(consulta);
  const codigos = [];
  const base = { reconhecimento: r, codigos, resposta: null, destino: null, alternativas: [], pergunta: null };

  /* ── 3.1 · Um identificador exacto ──────────────────────────────── */
  const exactos = [
    ["seccao", "seccao", (v) => "§" + v],
    ["ticket", "ticket", (v) => v],
    ["questao", "questao", (v) => v],
    ["adr", "adr", (v) => v],
    ["cor", "cor", (v) => v],
  ];
  for (const [tipoEnt, tipoDoc, marca] of exactos) {
    const e = entidade(r, tipoEnt);
    if (!e) continue;
    const doc = achar(docs, tipoDoc, marca(e.valor));
    if (!doc) {
      codigos.push("identificador_sem_correspondencia");
      return Object.assign(base, {
        estado: "sem_caminho",
        confianca: "baixa",
        titulo: `Não existe ${e.texto} neste dossiê`,
        resposta: resposta(
          `Reconheci «${e.texto}» como identificador, e não há nenhum com esse número.`,
          FONTE.contagem,
        ),
      });
    }
    codigos.push("identificador_exacto");
    const responde = responder(r, doc, dados, codigos);
    return Object.assign(base, {
      estado: "pronto",
      confianca: "alta",
      titulo: doc.titulo,
      destino: doc,
      resposta: responde,
    });
  }

  /* ── 3.2 · Uma família, e mais do que uma leitura ───────────────── */
  const fase = entidade(r, "fase");
  const parte = entidade(r, "parte");
  if ((fase || parte) && !r.sinais.length) {
    const alvo = fase || parte;
    const familias = familiasDe(alvo, docs);
    if (familias.length > 1) {
      codigos.push("familia_ambigua");
      return Object.assign(base, {
        estado: "clarificar",
        confianca: "media",
        titulo: `Reconheci «${alvo.texto}»`,
        pergunta: {
          texto: `O que queres ver da ${alvo.valor}?`,
          opcoes: familias,
        },
      });
    }
  }

  /* ── 3.3 · Assunto reconhecido, sem caminho destacado ───────────── */
  const resultados = X.pesquisar(consulta, docs, { limite: X.TETO });
  if (!resultados.length) {
    codigos.push("sem_confianca");
    return Object.assign(base, {
      estado: "sem_caminho",
      confianca: "baixa",
      titulo: "Nada respondeu com confiança suficiente",
    });
  }

  const coroa = X.melhorResposta(resultados);
  if (coroa) {
    codigos.push("melhor_resposta_destacada");
    const responde = responder(r, coroa.doc, dados, codigos);
    return Object.assign(base, {
      estado: "pronto",
      confianca: "media",
      titulo: coroa.doc.titulo,
      destino: coroa.doc,
      resposta: responde,
      alternativas: resultados.slice(1, 1 + MAX_ALTERNATIVAS).map((x) => x.doc),
    });
  }

  codigos.push("varios_sem_destaque");
  return Object.assign(base, {
    estado: "reconhecido",
    confianca: "media",
    titulo: `${resultados.length} sítios falam disto`,
    alternativas: resultados.slice(0, MAX_ALTERNATIVAS).map((x) => x.doc),
  });
}

/** As leituras possíveis de uma fase ou parte, com contagem real. */
function familiasDe(alvo, docs) {
  const v = X.normalizar(alvo.valor);
  const conta = (tipo) => docs.filter((d) => d.tipo === tipo && X.normalizar(d.aliases + " " + d.contexto).includes(v)).length;
  const out = [];
  for (const [tipo, rotulo] of [["ticket", "Os tickets"], ["mecanica", "As mecânicas"], ["seccao", "As secções"], ["questao", "As perguntas"]]) {
    const n = conta(tipo);
    if (n > 0) out.push({ id: tipo, rotulo, n, termo: alvo.texto });
  }
  return out;
}

/* ═══ 4 · RESPONDER ═════════════════════════════════════════════════
   Só quando a pergunta foi feita E o dado existe. Um campo vazio no ZIP
   responde «não diz», que é verdade e é útil — ao contrário de não
   responder, que deixa a pessoa a pensar que não procurou bem. */

function responder(r, doc, dados, codigos) {
  const ref = doc.ref;

  if (doc.tipo === "ticket" && ref) {
    if (r.sinais.includes("dependencia")) {
      const trava = bloqueados(dados, ref.id);
      codigos.push("resposta_dependencia");
      return trava.length
        ? resposta(
            `${ref.id} bloqueia ${trava.length} ticket${trava.length === 1 ? "" : "s"}.`,
            FONTE.contagem,
            trava.map((t) => t.id).join(" · "),
          )
        : resposta(`${ref.id} não bloqueia nenhum ticket.`, FONTE.contagem);
    }
    if (r.sinais.includes("estimativa")) {
      codigos.push("resposta_estimativa");
      const h = ref.horas || ref.estimativa;
      return h
        ? resposta(`${ref.id} declara ${h}.`, FONTE.zip)
        : resposta(`${ref.id} não declara estimativa.`, FONTE.zip, "O campo existe no formato e está vazio.");
    }
    codigos.push("resposta_estado");
    return resposta(`Estado: ${ref.estado || "não declarado"}.`, FONTE.zip, ref.depende ? "Depende de " + ref.depende : "");
  }

  if (doc.tipo === "questao" && ref) {
    if (r.sinais.includes("dependencia") || r.sinais.includes("estado")) {
      codigos.push("resposta_bloqueia");
      return ref.bloqueia
        ? resposta(`${ref.id} bloqueia: ${ref.bloqueia}.`, FONTE.zip)
        : resposta(
            `${ref.id} não diz o que bloqueia.`,
            FONTE.zip,
            "O campo «Bloqueia» está vazio — é o caso de 22 das 42 perguntas abertas.",
          );
    }
    codigos.push("resposta_estado");
    return resposta(`${ref.estado === "aberta" ? "Em aberto" : "Resolvida"}.`, FONTE.zip, ref.decide || "");
  }

  if (doc.tipo === "adr" && ref) {
    codigos.push("resposta_estado");
    return resposta(`Estado: ${ref.estado}.`, FONTE.zip, ref.ficheiro || "");
  }

  if (doc.tipo === "tabela" && ref) {
    codigos.push("resposta_contagem");
    return resposta(`${ref.registos} registos, ${ref.campos} campos.`, FONTE.zip);
  }

  if (doc.tipo === "seccao" && r.sinais.includes("localizacao")) {
    codigos.push("resposta_localizacao");
    return resposta(`${doc.marca} — ${doc.titulo}.`, FONTE.documento, doc.contexto || "");
  }

  return null;
}

/* ═══ 5 · O PORQUÊ ══════════════════════════════════════════════════
   A interface desenha o plano; não o inventa. Por isso o botão «porquê
   isto?» lê os códigos em vez de uma frase escrita à mão — e quando
   alguém acrescentar uma regra, a explicação acompanha sozinha. */

const EXPLICACAO = {
  identificador_exacto: "Escreveste um identificador que existe, e um identificador nomeia uma coisa só.",
  identificador_sem_correspondencia: "A forma é de identificador, mas não há nenhum com esse número.",
  familia_ambigua: "Reconheci o assunto e há mais do que uma leitura — por isso pergunto em vez de escolher por ti.",
  melhor_resposta_destacada: "Um resultado ficou à frente do segundo com margem suficiente para ser destacado.",
  varios_sem_destaque: "Vários resultados ficaram próximos. Destacar um seria fingir uma certeza que a pontuação não dá.",
  sem_confianca: "Nenhum sítio passou o limiar de pontuação.",
  resposta_dependencia: "A dependência está declarada no ZIP e é contável.",
  resposta_estado: "O estado está declarado no inventário.",
  resposta_bloqueia: "O campo «Bloqueia» da pergunta foi lido tal como está.",
  resposta_estimativa: "As horas declaradas foram lidas do ticket.",
  resposta_contagem: "Contagem direta sobre a tabela.",
  resposta_localizacao: "A secção foi localizada pelo número.",
};

function porque(plano) {
  return plano.codigos.map((c) => EXPLICACAO[c]).filter(Boolean);
}

return { reconhecer, entidade, compilar, porque, resposta, FONTE, EXPLICACAO, MAX_ALTERNATIVAS };
})();
