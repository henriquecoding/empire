/* tools/web/paginas/tema.js — o tema, antes do primeiro pixel (ADR 0024, ADR 0025).
   Corre no <head>, de propósito bloqueante: sem isto a página pisca no tema
   errado (o guarda anti-clarão do Recibo Certo). É um ficheiro e não um
   <script> em linha porque a CSP do site só aceita scripts do próprio site. A
   classe `js` assinala a disponibilidade do JavaScript. */
(function () {
  var raiz = document.documentElement;
  try {
    var t = localStorage.getItem("empire:tema");
    if (t === "claro" || t === "escuro") raiz.dataset.theme = t === "claro" ? "light" : "dark";
  } catch (e) {}
  raiz.classList.add("js");
})();
