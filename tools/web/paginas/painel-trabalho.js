/* Rascunhos privados desta aba, separados por conta; nunca são enviados automaticamente. */
(function () {
  "use strict";
  var conta = "", rascunhos = {}, chave = () => "empire.painel.rascunhos." + conta;
  function persistir() {
    try { sessionStorage.setItem(chave(), JSON.stringify(rascunhos)); return true; }
    catch (_) { return false; }
  }
  window.EmpireTrabalho = {
    abrir: function (email) {
      conta = email || ""; rascunhos = {};
      try { var valor = JSON.parse(sessionStorage.getItem(chave()) || "{}");
        if (valor && typeof valor === "object" && !Array.isArray(valor)) rascunhos = valor;
      } catch (_) { /* Um rascunho inválido nunca bloqueia as respostas do servidor. */ }
    },
    repor: function (a) {
      var r = rascunhos[a.id], f = a.querySelector("form");
      if (!r || !f || !["aprovar", "outra", "adiar", ""].includes(r.escolha) || typeof r.texto !== "string") return false;
      f.querySelectorAll("input[type=radio]").forEach(x => { x.checked = x.value === r.escolha; });
      f.querySelector("textarea").value = r.texto.slice(0, 4000);
      return true;
    },
    guardar: function (a) {
      var f = a.querySelector("form");
      rascunhos[a.id] = { escolha: f.querySelector("input:checked")?.value || "", texto: f.querySelector("textarea").value };
      return persistir();
    },
    remover: function (id) { delete rascunhos[id]; persistir(); },
    resposta: function (a, r) {
      var caixa = a.querySelector(".resposta-guardada"); caixa.hidden = !r;
      if (!r) return;
      var escolha = { aprovar: "Proposta aprovada", outra: "Decisão personalizada", adiar: "Decisão adiada" };
      caixa.querySelector("p").textContent = (escolha[r.escolha] || "Resposta registada") + (r.texto ? "\n" + r.texto : "");
      var data = new Date(r.atualizado_em);
      caixa.querySelector("small").textContent = Number.isNaN(data.valueOf()) ? "" : "Guardada em " + data.toLocaleString("pt-PT");
    },
    descarregar: function (md) {
      var url = URL.createObjectURL(new Blob([md], { type: "text/markdown;charset=utf-8" }));
      var a = document.createElement("a"); a.href = url; a.download = "empire-decisoes-" + new Date().toISOString().slice(0, 10) + ".md";
      a.click(); setTimeout(() => URL.revokeObjectURL(url), 1000);
    }
  };
})();
