/* Um relógio de apresentação a 8 Hz. Parado, fora do ecrã ou noutra aba: zero trabalho. */
(function () {
  "use strict";
  var palco = document.getElementById("palco");
  if (!palco) return;
  var movimento = window.matchMedia("(prefers-reduced-motion: reduce)");
  var rede = navigator.connection;
  var poupar = () => rede && (rede.saveData || /(^|-)2g$|3g/.test(rede.effectiveType));
  var fita = document.getElementById("fita-palco"), pausa = document.getElementById("pausa"), agora = document.getElementById("agora");
  var fases = Array.from(fita.querySelectorAll("li"), li => ({ id: li.dataset.fase, inicio: +li.dataset.inicio, dura: +li.dataset.dura, nome: li.dataset.nome }));
  var quadros = Object.fromEntries(Array.from(palco.querySelectorAll(".quadro"), img => [img.dataset.fase, img]));
  var ativa = palco.querySelector(".quadro.ativo").dataset.fase;
  var DIA = +palco.dataset.dia, ESCALA = 15, t = fases.find(f => f.id === ativa).inicio;
  var parado = movimento.matches || poupar() || window.matchMedia("(pointer:coarse)").matches;
  var fora = "IntersectionObserver" in window, pedido = 0, ultimo = 0, segundo = -1, requisitado = ativa;
  var cargas = new Map();
  function faseEm(x) { return fases.findLast(f => x >= f.inicio) || fases[0]; }
  function carregar(id) {
    var img = quadros[id];
    if (img.complete && img.naturalWidth) return Promise.resolve(true);
    if (cargas.has(id)) return cargas.get(id);
    var carga = new Promise(resolve => {
      function concluir(ok) { img.removeEventListener("load", sim); img.removeEventListener("error", nao); resolve(ok); }
      function sim() { concluir(true); }
      function nao() { concluir(false); }
      img.addEventListener("load", sim); img.addEventListener("error", nao);
      if (img.dataset.srcset) img.srcset = img.dataset.srcset;
      if (img.dataset.src) img.src = img.dataset.src;
    });
    cargas.set(id, carga); return carga;
  }
  function mostrar() {
    var f = faseEm(t), n = Math.floor(t);
    fita.style.setProperty("--p", (t / DIA).toFixed(4));
    if (n !== segundo) {
      fita.setAttribute("aria-valuenow", String(n));
      fita.setAttribute("aria-valuetext", f.nome + " · " + n + " s"); segundo = n;
    }
    if (!parado && !poupar() && t - f.inicio >= f.dura * .4) carregar(fases[(fases.indexOf(f) + 1) % fases.length].id);
    requisitado = f.id;
    if (f.id === ativa) return;
    carregar(f.id).then(ok => {
      if (!ok || requisitado !== f.id || ativa === f.id) return;
      var sai = quadros[ativa], entra = quadros[f.id];
      Object.values(quadros).forEach(img => img.classList.remove("anterior"));
      sai.classList.remove("ativo"); sai.classList.add("anterior"); sai.setAttribute("aria-hidden", "true");
      entra.classList.add("ativo"); entra.removeAttribute("aria-hidden"); ativa = f.id;
      agora.textContent = palco.dataset.agora.replace(/\{dia\}/g, "1").replace(/\{fase\}/g, f.nome);
    });
  }
  function pararRelogio() { clearTimeout(pedido); pedido = 0; ultimo = 0; }
  function passo() {
    pedido = 0;
    if (parado || fora || document.hidden) { ultimo = 0; return; }
    var ms = performance.now();
    if (ultimo) t = (t + (ms - ultimo) / 1000 * ESCALA) % DIA;
    ultimo = ms; mostrar(); pedido = setTimeout(passo, 125);
  }
  function sincronizar() {
    pararRelogio();
    if (!parado && !fora && !document.hidden) passo();
  }
  function parar(sim) {
    parado = !!sim;
    pausa.setAttribute("aria-pressed", String(parado));
    pausa.setAttribute("aria-label", parado ? palco.dataset.continuar : palco.dataset.pausar);
    sincronizar();
  }
  function irPara(x) { parar(true); t = Math.max(0, Math.min(DIA - .001, x)); mostrar(); }
  fita.setAttribute("role", "slider"); fita.tabIndex = 0;
  fita.setAttribute("aria-label", fita.dataset.rotulo);
  fita.setAttribute("aria-valuemin", "0"); fita.setAttribute("aria-valuemax", String(DIA));
  pausa.addEventListener("click", () => parar(!parado));
  fita.addEventListener("click", e => { var r = fita.getBoundingClientRect(); irPara((e.clientX - r.left) / r.width * DIA); });
  fita.addEventListener("keydown", e => {
    var i = fases.indexOf(faseEm(t));
    var alvo = { ArrowRight: i + 1, ArrowUp: i + 1, ArrowLeft: i - 1, ArrowDown: i - 1, Home: 0, End: fases.length - 1 }[e.key];
    if (alvo === undefined) return;
    e.preventDefault(); irPara(fases[(alvo + fases.length) % fases.length].inicio + .01);
  });
  document.addEventListener("visibilitychange", sincronizar);
  window.addEventListener("pagehide", pararRelogio);
  window.addEventListener("pageshow", sincronizar);
  window.addEventListener("online", () => { cargas.clear(); mostrar(); });
  movimento.addEventListener("change", () => { if (movimento.matches) parar(true); });
  if (rede) rede.addEventListener("change", () => { if (poupar()) parar(true); });
  if ("IntersectionObserver" in window) new IntersectionObserver(entradas => { fora = !entradas[0].isIntersecting; sincronizar(); }).observe(palco);
  mostrar(); parar(parado);
})();
