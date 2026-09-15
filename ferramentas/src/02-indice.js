/* ═══════════════════════════════════════════════════════════════════════
   O ÍNDICE — DERIVADO do documento, nunca escrito à mão
   ---------------------------------------------------------------------
   ┌─────────────────────────────────────────────────────────────────────┐
   │ PORQUE É QUE ISTO NÃO É UMA LISTA                                    │
   │                                                                     │
   │ A forma óbvia de dar pesquisa a um documento é escrever ao lado dele │
   │ uma lista do que ele contém. Funciona no dia em que se escreve e     │
   │ diverge no dia seguinte: alguém acrescenta a §86, ninguém toca na    │
   │ lista, e a pesquisa passa a responder «não existe» a uma coisa que   │
   │ existe — em silêncio, porque uma lista desactualizada não dá erro.   │
   │                                                                     │
   │ A regra vem de `documentos.ts` do Recibo Certo: o índice DERIVA das  │
   │ fontes canónicas. Aqui a fonte canónica é o próprio DOM do dossiê e  │
   │ o inventário extraído do ZIP. Uma secção nova entra no índice por    │
   │ existir, não por alguém se lembrar dela.                             │
   └─────────────────────────────────────────────────────────────────────┘
   ═══════════════════════════════════════════════════════════════════════ */

const XI = (() => {
"use strict";

const texto = (el) => (el ? (el.textContent || "").replace(/\s+/g, " ").trim() : "");

/** Um id estável a partir de um texto — para ancorar sub-títulos. */
function chaveDe(s, usados) {
  let base = X.normalizar(s).replace(/\s+/g, "-").slice(0, 48).replace(/^-+|-+$/g, "");
  if (!base) base = "t";
  let k = base, n = 2;
  while (usados.has(k)) k = base + "-" + n++;
  usados.add(k);
  return k;
}

const ROTULO = {
  seccao: "Secções",
  sub: "Dentro das secções",
  nota: "Caixas de decisão e risco",
  ticket: "Tickets do backlog",
  questao: "Perguntas em aberto",
  adr: "Decisões de arquitetura",
  tabela: "Tabelas de dados",
  mecanica: "As 48 mecânicas",
  cor: "Paleta",
};

const ROTULO_UM = {
  seccao: "Secção", sub: "Dentro de", nota: "Caixa", ticket: "Ticket",
  questao: "Pergunta", adr: "ADR", tabela: "Tabela", mecanica: "Mecânica", cor: "Cor",
};

function construir(dados) {
  const docs = [];
  const usados = new Set(
    [...document.querySelectorAll("[id]")].map((e) => e.id),
  );
  /** §NN → id da secção. É o que faz as referências cruzadas virarem ligações. */
  const porNumero = new Map();
  /** id da secção → metainformação, para o contexto e o «peek». */
  const secoes = new Map();

  /* ─── 1 · Partes ──────────────────────────────────────────────────── */
  const partes = [...document.querySelectorAll(".part")].map((p) => ({
    no: texto(p.querySelector(".part-no")),
    titulo: texto(p.querySelector("h2")),
    el: p,
  }));
  const parteDe = (el) => {
    let melhor = null;
    for (const p of partes) {
      if (p.el.compareDocumentPosition(el) & Node.DOCUMENT_POSITION_FOLLOWING) melhor = p;
    }
    return melhor;
  };

  /* ─── 2 · Secções, sub-títulos e caixas ───────────────────────────── */
  for (const sec of document.querySelectorAll("main section[id]")) {
    const secNo = texto(sec.querySelector(".sec-no"));
    const m = /^(\d{1,2}|★)\s*[—-]\s*(.*)$/.exec(secNo);
    const numero = m ? m[1] : "";
    const rotulo = m ? m[2].replace(/\s*·.*$/, "").trim() : secNo;
    const titulo = texto(sec.querySelector("h3"));
    const lede = texto(sec.querySelector(".lede"));
    const parte = parteDe(sec);
    const corpo = texto(sec).slice(0, 9000);
    const subs = [...sec.querySelectorAll("h4, h5, h6")];

    if (numero && numero !== "★") porNumero.set(numero.padStart(2, "0"), sec.id);
    secoes.set(sec.id, {
      id: sec.id, numero, rotulo, titulo, lede,
      parte: parte ? parte.no : "", parteTitulo: parte ? parte.titulo : "",
      el: sec,
      palavras: corpo.split(/\s+/).length,
    });

    docs.push({
      id: "sec:" + sec.id,
      tipo: "seccao",
      marca: numero ? "§" + numero : "★",
      titulo,
      descricao: lede,
      aliases: [rotulo, secNo, parte ? parte.titulo : "", ...subs.map(texto)].join(" · "),
      corpo,
      href: "#" + sec.id,
      contexto: (parte ? parte.no + " · " : "") + (numero ? "§" + numero : "") + " " + rotulo,
      prioridade: 90,
    });

    for (const h of subs) {
      const t = texto(h);
      if (t.length < 3) continue;
      if (!h.id) h.id = "h-" + chaveDe(t, usados);
      // A descrição de um sub-título é o que vem a seguir a ele — que é
      // exactamente o que a pessoa quer ler para saber se é aquele.
      let seg = h.nextElementSibling, desc = "";
      let saltos = 0;
      while (seg && saltos++ < 3 && desc.length < 240) {
        if (/^H[2-6]$/.test(seg.tagName)) break;
        desc += " " + texto(seg);
        seg = seg.nextElementSibling;
      }
      docs.push({
        id: "sub:" + h.id,
        tipo: "sub",
        marca: numero ? "§" + numero : "★",
        titulo: t,
        descricao: desc.replace(/\s+/g, " ").trim().slice(0, 300),
        aliases: titulo,
        corpo: "",
        href: "#" + h.id,
        contexto: (numero ? "§" + numero + " " : "") + rotulo,
        prioridade: 60,
      });
    }

    for (const nota of sec.querySelectorAll(".note, .lantern")) {
      const lbl = texto(nota.querySelector(".lbl"));
      if (!lbl) continue;
      if (!nota.id) nota.id = "n-" + chaveDe(lbl, usados);
      const classe = nota.classList.contains("risk") ? "risco"
        : nota.classList.contains("dec") ? "decisão"
        : nota.classList.contains("lantern") ? "candeia" : "nota";
      docs.push({
        id: "nota:" + nota.id,
        tipo: "nota",
        marca: numero ? "§" + numero : "★",
        titulo: lbl,
        descricao: texto(nota).replace(lbl, "").trim().slice(0, 320),
        aliases: classe + " " + titulo,
        corpo: "",
        href: "#" + nota.id,
        contexto: (numero ? "§" + numero + " " : "") + rotulo + " · " + classe,
        prioridade: 45,
      });
    }
  }

  /* ─── 3 · A paleta ────────────────────────────────────────────────── */
  for (const sw of document.querySelectorAll(".sw[data-hex]")) {
    const hex = sw.dataset.hex;
    const nome = sw.getAttribute("title") || sw.getAttribute("aria-label") || texto(sw.parentElement).slice(0, 40);
    docs.push({
      id: "cor:" + hex,
      tipo: "cor",
      marca: hex,
      titulo: nome || hex,
      descricao: "Carrega para copiar " + hex + ".",
      aliases: hex + " " + hex.replace("#", ""),
      corpo: "",
      href: "#s22",
      contexto: "§22 Paleta",
      prioridade: 20,
      hex,
    });
  }

  /* ─── 4 · As 48 mecânicas (o rastreador já as desenhou) ───────────── */
  for (const li of document.querySelectorAll("#trklist li")) {
    const lab = li.querySelector("label");
    if (!lab) continue;
    const t = texto(lab).replace(/§\d+$/, "").trim();
    const ref = texto(lab.querySelector("span"));
    const fase = texto(li.querySelector(".ph"));
    const cb = li.querySelector("input");
    docs.push({
      id: "mec:" + (cb ? cb.id : t),
      tipo: "mecanica",
      marca: ref || "★",
      titulo: t,
      // O contexto já diz a fase; repeti-la aqui punha «Fase 1 Fase 1»
      // lado a lado em cada resultado de mecânica.
      descricao: ref ? "Especificada em " + ref : "",
      aliases: "mecânica " + fase + " " + ref,
      corpo: "",
      href: "#trk",
      contexto: "Rastreador · " + fase,
      prioridade: 35,
    });
  }

  /* ─── 5 · O inventário do ZIP ─────────────────────────────────────── */
  if (dados) {
    for (const t of dados.tickets) {
      docs.push({
        id: "tic:" + t.id,
        tipo: "ticket",
        marca: t.id,
        titulo: t.titulo,
        descricao: t.feito || t.porque,
        aliases: [t.fase, t.estado, t.depende, t.acoes.join(" ")].join(" "),
        corpo: t.porque + " " + t.fora,
        href: "#x-inventario",
        contexto: t.fase + " · " + t.estado,
        prioridade: 55,
        ref: t,
      });
    }
    for (const q of dados.perguntas) {
      docs.push({
        id: "que:" + q.id,
        tipo: "questao",
        marca: q.id,
        titulo: q.titulo,
        descricao: q.decide || q.onde,
        aliases: [q.estado, q.onde, q.bloqueia, q.secoes.join(" ")].join(" "),
        corpo: q.grupo,
        href: "#x-inventario",
        contexto: q.estado === "aberta" ? "Em aberto" : "Resolvida",
        prioridade: 58,
        ref: q,
      });
    }
    for (const a of dados.adrs) {
      docs.push({
        id: "adr:" + a.id,
        tipo: "adr",
        marca: a.id,
        titulo: a.titulo,
        descricao: "Estado: " + a.estado,
        aliases: a.ficheiro + " decisão de arquitetura",
        corpo: "",
        href: "#x-inventario",
        contexto: a.estado,
        prioridade: 52,
        ref: a,
      });
    }
    for (const t of dados.tabelas) {
      docs.push({
        id: "tab:" + t.nome,
        tipo: "tabela",
        marca: t.nome,
        titulo: t.nome + ".csv",
        descricao: t.registos + " registos · " + t.campos + " campos",
        aliases: "csv tabela dados " + t.nome + " data/source",
        corpo: "",
        href: "#x-inventario",
        contexto: "data/source",
        prioridade: 40,
        ref: t,
      });
    }
  }

  /**
   * A MARCA ENTRA NOS ALIASES — e não era óbvio que faltasse.
   *
   * Escrever `F1-08` devolvia o sub-título «O formato de tarefa — copia
   * para docs/backlog/F1-08.md» à frente do PRÓPRIO TICKET F1-08, porque
   * o identificador vivia no campo `marca`, que não é pontuado. Quem
   * escreve um identificador quer a coisa que ele nomeia, não um
   * parágrafo que o cita.
   *
   * Vale para todas as famílias: `§07` passa a encontrar a §07, `Q-001`
   * a pergunta, `ADR 0011` a decisão.
   */
  for (const d of docs) {
    if (d.marca) d.aliases = d.marca + " " + (d.aliases || "");
  }

  return { docs, porNumero, secoes, partes };
}

return { construir, ROTULO, ROTULO_UM, texto, chaveDe };
})();
