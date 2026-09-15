/* ═══════════════════════════════════════════════════════════════════════
   SAÚDE DO PLANO — os fatores, calculados, nunca escritos
   ---------------------------------------------------------------------
   ┌─────────────────────────────────────────────────────────────────────┐
   │ PORTADO DE `src/lib/insights.ts` (`gerarInsights` e `saudeFiscal`)   │
   │                                                                     │
   │ Aquele módulo resolve um problema de produto que é igual aqui: a    │
   │ pessoa tem os dados todos à frente e mesmo assim não sabe se está    │
   │ bem. Uma lista de 42 tickets não responde a «isto anda?».            │
   │                                                                     │
   │ A forma que ele usa — um ESTADO em palavra, e por baixo os FATORES   │
   │ que o produziram, cada um com o seu — é o que transforma um monte    │
   │ de contagens numa leitura. E é honesta de uma maneira específica:    │
   │ um fator que não se consegue avaliar diz «desconhecido» em vez de    │
   │ contar como bom.                                                    │
   └─────────────────────────────────────────────────────────────────────┘

   A REGRA QUE FAZ ISTO VALER A PENA: nada aqui está escrito à mão. Os
   37, os 22, os 23 — saem todos de contar o ZIP no momento em que a
   página abre. Se o `tickets.json` mudar amanhã, o painel muda com ele.

   Foi para isto que valeu portar: um relatório de auditoria envelhece
   no dia em que se publica; um painel que conta, não.
   ═══════════════════════════════════════════════════════════════════════ */

window.XS = (() => {
"use strict";

/* ─── O contrato ──────────────────────────────────────────────────── */

/** `desconhecido` não é `ok`. É a distinção que impede o verde falso. */
const ESTADOS_FATOR = ["ok", "atencao", "alerta", "desconhecido"];

/** A palavra que resume. Por ordem de gravidade. */
const ESTADOS = ["Por medir", "A andar", "Atenção", "Travado"];

const TOM = { ok: "ok", atencao: "info", alerta: "alerta", desconhecido: "info" };

/**
 * Um fator. `evidencia` é o que se conta, `estado` é a leitura, e
 * `porque` é a frase que a justifica — sempre com o número lá dentro,
 * para ninguém ter de confiar na etiqueta.
 */
function fator(id, rotulo, estado, evidencia, porque, destino) {
  if (ESTADOS_FATOR.indexOf(estado) === -1) throw new Error("[saude] estado desconhecido: " + estado);
  return { id, rotulo, estado, evidencia, porque, destino: destino || "" };
}

/* ─── Os fatores ──────────────────────────────────────────────────── */

/**
 * O estado de um ticket, pela PALAVRA COM QUE O CAMPO COMEÇA.
 *
 * A primeira versão disto procurava «falta» em qualquer sítio da frase e
 * contava 40 parciais — porque «por fazer» contém «fazer» e porque muitas
 * ressalvas dizem «falta». Classificar pela palavra inicial é o que o
 * campo realmente declara; o resto da frase é a ressalva, e essa é uma
 * segunda pergunta, não a mesma.
 *
 * Quatro baldes, porque «feito» e «feito, mas» são coisas diferentes e
 * juntá-las é exatamente o verde falso que este painel existe para
 * evitar.
 */
const RESSALVA = /—.*(falta|pendente|proposta|em curso|placeholder)/i;

function estadoDoTicket(t) {
  const e = String(t.estado || "").trim().toLowerCase();
  if (!e) return "por-fazer";
  if (/^por fazer/.test(e)) return "por-fazer";
  if (/^parcial/.test(e)) return "parcial";
  if (/^(feito|conclu|fechado|pronto)/.test(e)) return RESSALVA.test(e) ? "feito-com-ressalva" : "feito";
  return "por-fazer";
}

function analisar(dados, secoes) {
  const tickets = (dados && dados.tickets) || [];
  const perguntas = (dados && dados.perguntas) || [];
  const adrs = (dados && dados.adrs) || [];
  const fatores = [];

  /* 1 · Quanto está mesmo fechado */
  if (tickets.length) {
    const porEstado = { feito: 0, "feito-com-ressalva": 0, parcial: 0, "por-fazer": 0 };
    for (const t of tickets) porEstado[estadoDoTicket(t)]++;
    const feito = porEstado.feito;
    fatores.push(fator(
      "fechados", "Tickets fechados sem ressalva",
      feito === 0 ? "alerta" : feito / tickets.length < 0.25 ? "atencao" : "ok",
      `${feito} de ${tickets.length}`,
      `Mais ${porEstado["feito-com-ressalva"]} declaram-se feitos com ressalva no próprio campo de estado, ` +
      `${porEstado.parcial} estão parciais e ${porEstado["por-fazer"]} por começar.`,
      "#x-inventario",
    ));
  }

  /* 2 · Os gargalos — quem bloqueia mais */
  if (tickets.length) {
    const trava = new Map();
    for (const t of tickets) {
      for (const dep of String(t.depende || "").split(/[,;\s]+/).filter(Boolean)) {
        trava.set(dep, (trava.get(dep) || 0) + 1);
      }
    }
    const topo = [...trava.entries()].sort((a, b) => b[1] - a[1]).slice(0, 2);
    const livres = tickets.filter((t) => !String(t.depende || "").trim()).length;
    if (topo.length) {
      const abertos = topo.filter(([id]) => {
        const t = tickets.find((x) => x.id === id);
        return !t || estadoDoTicket(t) !== "feito";
      });
      fatores.push(fator(
        "gargalos", "Tickets que mais bloqueiam",
        abertos.length ? "alerta" : "ok",
        topo.map(([id, n]) => `${id} → ${n}`).join(" · "),
        `${livres} dos ${tickets.length} tickets não dependem de nada. ` +
        (abertos.length ? `${abertos.map(([id]) => id).join(" e ")} ainda não ${abertos.length === 1 ? "está fechado" : "estão fechados"}.` : "Os gargalos estão fechados."),
        "#x-inventario",
      ));
    }
  }

  /* 3 · O dossiê cresceu mais do que o plano? */
  if (tickets.length && secoes && secoes.size) {
    const citadas = new Set();
    const texto = tickets.map((t) => [t.titulo, t.porque, t.feito, t.fora, (t.acoes || []).join(" ")].join(" ")).join(" ");
    for (const [, s] of secoes) {
      if (!s.numero || s.numero === "★") continue;
      const re = new RegExp("§\\s?0?" + Number(s.numero) + "\\b");
      if (re.test(texto)) citadas.add(s.numero);
    }
    const total = [...secoes.values()].filter((s) => s.numero && s.numero !== "★").length;
    const orfas = total - citadas.size;
    fatores.push(fator(
      "cobertura", "Secções citadas por algum ticket",
      orfas > total / 2 ? "alerta" : orfas > total / 4 ? "atencao" : "ok",
      `${citadas.size} de ${total}`,
      `${orfas} secções não são nomeadas por ticket nenhum — o dossiê cresceu mais depressa do que o plano para o construir.`,
      "#x-inventario",
    ));
  }

  /* 4 · As perguntas são ordenáveis? */
  if (perguntas.length) {
    const abertas = perguntas.filter((q) => q.estado === "aberta");
    const mudas = abertas.filter((q) => !String(q.bloqueia || "").trim());
    fatores.push(fator(
      "triagem", "Perguntas que dizem o que bloqueiam",
      !abertas.length ? "desconhecido" : mudas.length > abertas.length / 2 ? "atencao" : "ok",
      `${abertas.length - mudas.length} de ${abertas.length} abertas`,
      mudas.length
        ? `${mudas.length} deixam o campo «Bloqueia» vazio. Sem ele não há resposta para «qual destas me trava esta semana».`
        : "Todas as perguntas abertas declaram o que travam.",
      "#x-inventario",
    ));
  }

  /* 5 · As decisões que congelam */
  if (adrs.length) {
    const propostas = adrs.filter((a) => /propost/i.test(a.estado || ""));
    fatores.push(fator(
      "decisoes", "Decisões de arquitetura fechadas",
      propostas.length ? "alerta" : "ok",
      `${adrs.length - propostas.length} de ${adrs.length}`,
      propostas.length
        ? `Por fechar: ${propostas.map((a) => a.id).join(" · ")}. Uma decisão de escala entra em todos os ficheiros escritos a seguir.`
        : "Nenhuma ADR ficou em proposta.",
      "#x-inventario",
    ));
  }

  /* 6 · Há total? */
  if (tickets.length) {
    const comHoras = tickets.filter((t) => /\d/.test(String(t.horas || t.estimativa || "")));
    fatores.push(fator(
      "estimativa", "Tickets com estimativa",
      !comHoras.length ? "desconhecido" : comHoras.length < tickets.length / 2 ? "atencao" : "ok",
      `${comHoras.length} de ${tickets.length}`,
      comHoras.length < tickets.length
        ? `${tickets.length - comHoras.length} não declaram esforço, por isso não há resposta para «quanto falta para fechar».`
        : "Todos os tickets declaram esforço.",
      "#x-inventario",
    ));
  }

  /* 7 · Quantas fases têm trabalho descrito */
  if (tickets.length) {
    const fases = new Set(tickets.map((t) => String(t.fase || "").trim()).filter(Boolean));
    fatores.push(fator(
      "fases", "Fases com tickets", "desconhecido",
      `${fases.size} com trabalho descrito`,
      "Planear uma fase antes de a anterior se jogar seria o erro que o resto do dossiê evita — por isso isto não conta como defeito. Conta como coisa a declarar.",
      "#x-inventario",
    ));
  }

  return fatores;
}

/**
 * O estado geral. `desconhecido` NÃO puxa para baixo — mas também não
 * puxa para cima: um plano medido só em fatores desconhecidos fica «Por
 * medir», que é a verdade.
 */
function resumir(fatores) {
  const avaliaveis = fatores.filter((f) => f.estado !== "desconhecido");
  if (!avaliaveis.length) return ESTADOS[0];
  if (avaliaveis.some((f) => f.estado === "alerta")) {
    return avaliaveis.filter((f) => f.estado === "alerta").length > 1 ? ESTADOS[3] : ESTADOS[2];
  }
  if (avaliaveis.some((f) => f.estado === "atencao")) return ESTADOS[2];
  return ESTADOS[1];
}

function saude(dados, secoes) {
  const fatores = analisar(dados, secoes);
  return {
    estado: resumir(fatores),
    fatores,
    avaliados: fatores.filter((f) => f.estado !== "desconhecido").length,
    total: fatores.length,
  };
}

/**
 * Os insights: o mesmo material, ordenado por o que fazer a seguir. Um
 * fator descreve; um insight propõe.
 */
function insights(s) {
  const peso = { alerta: 0, atencao: 1, ok: 2, desconhecido: 3 };
  return s.fatores
    .slice()
    .sort((a, b) => peso[a.estado] - peso[b.estado])
    .filter((f) => f.estado === "alerta" || f.estado === "atencao")
    .map((f) => ({ tom: TOM[f.estado], titulo: f.rotulo, texto: f.porque, evidencia: f.evidencia, destino: f.destino }));
}

return { saude, insights, analisar, resumir, fator, ESTADOS, ESTADOS_FATOR, TOM, estadoDoTicket };
})();
