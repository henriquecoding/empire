/* A pesquisa lê cada ficha uma vez; respostas guardadas têm um índice separado. */
(function () {
  "use strict";
  var normal = s => String(s || "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
  window.EmpireIndice = {
    criar: function (fichas) {
      var entradas = new Map(fichas.map(a => [a.id, normal(a.id + " " + a.textContent)]));
      var respostas = new Map();
      return {
        responder: (id, texto) => respostas.set(id, normal(texto)),
        procurar: function (texto) {
          var termo = normal(texto.trim()), ids = new Set();
          entradas.forEach((conteudo, id) => {
            if (!termo || conteudo.includes(termo) || (respostas.get(id) || "").includes(termo)) ids.add(id);
          });
          return ids;
        }
      };
    }
  };
})();
