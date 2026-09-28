/* Tratamento dos reportes; texto externo entra apenas por textContent. */
(function () {
  "use strict";
  var M = window.EmpireMotor;
  var $ = function (id) { return document.getElementById(id); };
  function dizer(el, texto, tipo) { el.textContent = texto; el.className = "estado-envio " + (tipo || ""); }
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
  window.EmpireReportes = { carregar: carregarReportes };
})();
