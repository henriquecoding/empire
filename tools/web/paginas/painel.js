/* tools/web/paginas/painel.js — o painel do dono em /painel/ (ADR 0026).
 *
 * Responder às perguntas do QUESTIONS.md e tratar os reportes. As perguntas já
 * vêm no HTML (geradas do repositório em cada publicação); daqui só se lê e
 * escreve o que o dono respondeu. O que vem da base de dados — os reportes são
 * escritos por qualquer pessoa — entra sempre por textContent, nunca por
 * innerHTML. */
(function () {
  "use strict";
  var M = window.EmpireMotor;
  if (!M) return;
  var $ = function (id) { return document.getElementById(id); };
  var todas = Array.prototype.slice.call(document.querySelectorAll("article.pergunta"));
  var respostas = {};

  function dizer(el, texto, tipo) {
    el.textContent = texto;
    el.className = el.className.replace(/\s*(erro|feito|aviso)\b/g, "") + (tipo ? " " + tipo : "");
  }

  // ── Entrar ──────────────────────────────────────────────────────────────
  if (!document.body.getAttribute("data-sb-url")) {
    $("entrar-desligado").hidden = false;
    $("entrar-form").hidden = true;
    return;
  }

  function abrir() {
    var s = M.sessao();
    $("entrar").hidden = true;
    $("area").hidden = false;
    $("sessao").textContent = "Entraste como " + (s && s.email ? s.email : "administração") + ".";
    carregarRespostas();
  }

  $("entrar-form").addEventListener("submit", function (ev) {
    ev.preventDefault();
    dizer($("entrar-estado"), "A entrar…", "");
    M.entrar($("en-email").value.trim(), $("en-senha").value).then(function () {
      $("en-senha").value = "";
      dizer($("entrar-estado"), "", "");
      abrir();
    }, function (e) {
      dizer($("entrar-estado"), "Não foi possível entrar: " + e.message, "erro");
    });
  });

  $("sair").addEventListener("click", function () {
    M.sair();
    location.reload();
  });

  if (M.sessao()) {
    M.pedir("/rest/v1/rpc/empire_e_admin", { metodo: "POST", corpo: {} }).then(function (admin) {
      if (admin === true) abrir(); else M.sair();
    }, function () { M.sair(); });
  }

  // ── Separadores ─────────────────────────────────────────────────────────
  function separador(qual) {
    ["perguntas", "reportes"].forEach(function (s) {
      $("tab-" + s).setAttribute("aria-selected", String(s === qual));
      $(s).hidden = s !== qual;
    });
    if (qual === "reportes") carregarReportes();
  }
  $("tab-perguntas").addEventListener("click", function () { separador("perguntas"); });
  $("tab-reportes").addEventListener("click", function () { separador("reportes"); });

  // ── Perguntas ───────────────────────────────────────────────────────────
  function estadoDe(id) {
    var r = respostas[id];
    if (!r) return "por";
    return r.estado === "aplicada" ? "aplicada" : "respondida";
  }

  function pintar(art) {
    var id = art.dataset.id;
    var r = respostas[id];
    var e = estadoDe(id);
    art.dataset.estado = e;
    var rot = art.querySelector(".p-estado");
    rot.dataset.estado = e;
    rot.textContent = e === "por" ? "Por responder"
      : (e === "aplicada" ? "Aplicada" : "Respondida") + " · " + ({ aprovar: "aprovada", outra: "outra resposta", adiar: "adiada" })[r.escolha];
    if (!r) return;
    var radio = art.querySelector("input[value=" + r.escolha + "]");
    if (radio) radio.checked = true;
    art.querySelector("textarea[name=texto]").value = r.texto || "";
  }

  function contar() {
    var n = { por: 0, respondida: 0, aplicada: 0 };
    todas.forEach(function (a) { n[estadoDe(a.dataset.id)]++; });
    $("c-respondidas").textContent = n.respondida + n.aplicada;
    $("c-por").textContent = n.por;
    $("c-aplicadas").textContent = n.aplicada;
  }

  function filtrar() {
    var txt = $("f-texto").value.trim().toLowerCase();
    var tipo = $("f-tipo").value;
    var est = $("f-estado").value;
    var grupo = $("f-grupo").value;
    var visiveis = 0;
    todas.forEach(function (a) {
      var ok = (!tipo || a.dataset.tipo === tipo)
        && (!est || estadoDe(a.dataset.id) === est)
        && (!grupo || a.dataset.grupo === grupo)
        && (!txt || a.textContent.toLowerCase().indexOf(txt) >= 0);
      a.hidden = !ok;
      if (ok) visiveis++;
    });
    $("sem-resultados").hidden = visiveis > 0;
  }
  ["f-texto", "f-tipo", "f-estado", "f-grupo"].forEach(function (id) {
    $(id).addEventListener(id === "f-texto" ? "input" : "change", filtrar);
  });

  function carregarRespostas() {
    M.pedir("/rest/v1/empire_respostas?select=pergunta,escolha,texto,estado,atualizado_em").then(function (linhas) {
      respostas = {};
      (linhas || []).forEach(function (r) { respostas[r.pergunta] = r; });
      todas.forEach(pintar);
      contar();
      filtrar();
    }, function (e) {
      dizer($("lote-estado"), "Não foi possível ler as respostas: " + e.message, "erro");
    });
  }

  // Guardar sobrepõe a resposta anterior e volta a pô-la em «nova»: uma
  // resposta mudada tem de ser aplicada outra vez.
  function guardar(linhas) {
    return M.pedir("/rest/v1/empire_respostas?on_conflict=pergunta", {
      metodo: "POST",
      cabecalhos: { Prefer: "resolution=merge-duplicates,return=representation" },
      corpo: linhas,
    }).then(function (gravadas) {
      (gravadas || []).forEach(function (r) { respostas[r.pergunta] = r; });
      todas.forEach(function (a) { if (respostas[a.dataset.id]) pintar(a); });
      contar();
    });
  }

  todas.forEach(function (art) {
    var form = art.querySelector("form.resposta");
    var aviso = art.querySelector(".p-guardado");
    form.addEventListener("submit", function (ev) {
      ev.preventDefault();
      var escolha = form.querySelector("input[type=radio]:checked");
      var texto = M.sanitizar(form.querySelector("textarea[name=texto]").value);
      if (!escolha) return dizer(aviso, "Escolhe uma das três.", "erro");
      if (escolha.value === "outra" && !texto) return dizer(aviso, "Escreve a outra resposta.", "erro");
      if (M.contemCodigo(texto)) return dizer(aviso, "Sem código nem HTML, por favor.", "erro");
      dizer(aviso, "A guardar…", "");
      guardar([{ pergunta: art.dataset.id, escolha: escolha.value, texto: texto || null,
        titulo: art.dataset.titulo.slice(0, 300), estado: "nova" }]).then(function () {
        dizer(aviso, "Guardada.", "feito");
      }, function (e) {
        dizer(aviso, "Não guardou: " + e.message, "erro");
      });
    });
  });

  // ── Em lote ─────────────────────────────────────────────────────────────
  var lote = [];
  $("aprovar-visiveis").addEventListener("click", function () {
    lote = todas.filter(function (a) {
      return !a.hidden && a.dataset.tipo === "confirmar" && estadoDe(a.dataset.id) === "por";
    });
    if (!lote.length) return dizer($("lote-estado"), "Não há «Confirmar» por responder à vista.", "aviso");
    $("lote-n").textContent = lote.length;
    $("lote-confirma").hidden = false;
  });
  $("lote-nao").addEventListener("click", function () { $("lote-confirma").hidden = true; });
  $("lote-sim").addEventListener("click", function () {
    $("lote-confirma").hidden = true;
    dizer($("lote-estado"), "A aprovar " + lote.length + "…", "");
    guardar(lote.map(function (a) {
      return { pergunta: a.dataset.id, escolha: "aprovar", texto: null, titulo: a.dataset.titulo.slice(0, 300), estado: "nova" };
    })).then(function () {
      dizer($("lote-estado"), lote.length + " aprovadas.", "feito");
      filtrar();
    }, function (e) {
      dizer($("lote-estado"), "Não aprovou: " + e.message, "erro");
    });
  });

  // O que se cola numa sessão com um agente para as aplicar ao repositório.
  $("copiar").addEventListener("click", function () {
    var linhas = ["# Respostas às perguntas do QUESTIONS.md", ""];
    todas.forEach(function (a) {
      var r = respostas[a.dataset.id];
      if (!r) return;
      var o = { aprovar: "aprovar a proposta", outra: "outra resposta", adiar: "adiar" }[r.escolha];
      linhas.push("- **" + a.dataset.id + "** · " + a.dataset.titulo + " — " + o + (r.texto ? ": " + r.texto : "")
        + (r.estado === "aplicada" ? " (já aplicada)" : ""));
    });
    var md = linhas.join("\n") + "\n";
    var fim = function (ok) {
      dizer($("lote-estado"), ok ? "Copiado." : "Não deu para copiar: a lista está na consola.", ok ? "feito" : "aviso");
      if (!ok) console.log(md);
    };
    if (navigator.clipboard) navigator.clipboard.writeText(md).then(function () { fim(true); }, function () { fim(false); });
    else fim(false);
  });

  // ── Reportes ────────────────────────────────────────────────────────────
  var ESTADOS = [["novo", "Novo"], ["em_analise", "Em análise"], ["valido", "Válido"], ["resolvido", "Resolvido"], ["rejeitado", "Rejeitado"]];
  var TIPOS = { sugestao: "Sugestão", erro: "Erro", duvida: "Dúvida", mensagem: "Mensagem" };

  function el(tag, classe, texto) {
    var e = document.createElement(tag);
    if (classe) e.className = classe;
    if (texto !== undefined && texto !== null) e.textContent = texto;
    return e;
  }

  function cartaoReporte(r) {
    var art = el("article", "reporte");
    var meta = el("p", "p-meta");
    meta.appendChild(el("span", "chip chip-" + r.tipo, TIPOS[r.tipo] || r.tipo));
    meta.appendChild(el("span", "p-grupo", new Date(r.criado_em).toLocaleString("pt-PT")));
    if (r.area) meta.appendChild(el("span", "p-grupo", r.area));
    if (r.versao) meta.appendChild(el("code", "", r.versao.slice(0, 7)));
    art.appendChild(meta);
    if (r.assunto) art.appendChild(el("h3", "", r.assunto));
    art.appendChild(el("p", "reporte-msg", r.mensagem));
    if (r.nome || r.email) art.appendChild(el("p", "reporte-quem", [r.nome, r.email].filter(Boolean).join(" · ")));

    var form = el("form", "resposta");
    var sel = el("select");
    ESTADOS.forEach(function (e) {
      var o = el("option", "", e[1]);
      o.value = e[0];
      if (e[0] === r.estado) o.selected = true;
      sel.appendChild(o);
    });
    var rotSel = el("label", "campo");
    rotSel.appendChild(el("span", "", "Estado"));
    rotSel.appendChild(sel);
    var nota = el("textarea");
    nota.rows = 2;
    nota.maxLength = 4000;
    nota.value = r.nota_admin || "";
    var rotNota = el("label", "campo");
    rotNota.appendChild(el("span", "", "Nota interna"));
    rotNota.appendChild(nota);
    var accoes = el("div", "accoes");
    var gravar = el("button", "botao principal", "Guardar");
    gravar.type = "submit";
    var apagar = el("button", "botao", "Apagar");
    apagar.type = "button";
    var aviso = el("span", "p-guardado");
    aviso.setAttribute("role", "status");
    accoes.appendChild(gravar);
    accoes.appendChild(apagar);
    accoes.appendChild(aviso);
    form.appendChild(rotSel);
    form.appendChild(rotNota);
    form.appendChild(accoes);
    art.appendChild(form);

    form.addEventListener("submit", function (ev) {
      ev.preventDefault();
      dizer(aviso, "A guardar…", "");
      M.pedir("/rest/v1/empire_feedback?id=eq." + encodeURIComponent(r.id), {
        metodo: "PATCH", cabecalhos: { Prefer: "return=minimal" },
        corpo: { estado: sel.value, nota_admin: M.sanitizar(nota.value) || null },
      }).then(function () { dizer(aviso, "Guardado.", "feito"); }, function (e) { dizer(aviso, "Não guardou: " + e.message, "erro"); });
    });
    // Apagar pede um segundo clique: o viewer não tem confirm().
    var armado = false;
    apagar.addEventListener("click", function () {
      if (!armado) {
        armado = true;
        apagar.textContent = "Carrega outra vez para apagar";
        return;
      }
      M.pedir("/rest/v1/empire_feedback?id=eq." + encodeURIComponent(r.id), { metodo: "DELETE" })
        .then(function () { art.remove(); }, function (e) { dizer(aviso, "Não apagou: " + e.message, "erro"); });
    });
    return art;
  }

  function carregarReportes() {
    var lista = $("lista-reportes");
    var est = $("fr-estado").value;
    dizer($("fr-estado-msg"), "A carregar…", "");
    M.pedir("/rest/v1/empire_feedback?select=*&order=criado_em.desc&limit=200" + (est ? "&estado=eq." + est : ""))
      .then(function (linhas) {
        lista.textContent = "";
        (linhas || []).forEach(function (r) { lista.appendChild(cartaoReporte(r)); });
        dizer($("fr-estado-msg"), (linhas || []).length ? (linhas.length + " reporte(s).") : "Nenhum reporte com este estado.", "");
      }, function (e) {
        dizer($("fr-estado-msg"), "Não foi possível ler os reportes: " + e.message, "erro");
      });
  }
  $("fr-estado").addEventListener("change", carregarReportes);
  $("fr-atualizar").addEventListener("click", carregarReportes);
})();
