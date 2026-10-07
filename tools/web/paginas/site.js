/* Navegação partilhada. Conteúdo e ligações funcionam sem este script. */
(function () {
  "use strict";
  var raiz = document.documentElement;

  // ── 1 · o tema ─────────────────────────────────────────────────────────
  var botaoTema = document.getElementById("tema");
  function escuroAgora() {
    var t = raiz.dataset.theme;
    return t ? t === "dark" : window.matchMedia("(prefers-color-scheme: dark)").matches;
  }
  function rotularTema() {
    if (!botaoTema) return;
    botaoTema.setAttribute("aria-label", escuroAgora() ? botaoTema.dataset.claro : botaoTema.dataset.escuro);
  }
  if (botaoTema) {
    rotularTema();
    botaoTema.addEventListener("click", function () {
      var escuro = !escuroAgora();
      raiz.dataset.theme = escuro ? "dark" : "light";
      try { localStorage.setItem("empire:tema", escuro ? "escuro" : "claro"); } catch (e) {}
      rotularTema();
    });
  }

  // ── 2 · o menu ─────────────────────────────────────────────────────────
  var topo = document.getElementById("topo");
  var abre = document.getElementById("abre-menu");
  function menu(aberto) {
    if (!topo || !abre) return;
    topo.classList.toggle("aberto", aberto);
    abre.setAttribute("aria-expanded", aberto ? "true" : "false");
    abre.querySelector(".rotulo").textContent = aberto ? abre.dataset.fechar : abre.dataset.abrir;
  }
  if (abre) {
    raiz.classList.add("menu-pronto");
    document.addEventListener("click", e => { if (!topo.contains(e.target)) menu(false); });
    topo.addEventListener("focusout", e => { if (e.relatedTarget && !topo.contains(e.relatedTarget)) menu(false); });
    window.matchMedia("(min-width:1121px)").addEventListener("change", () => menu(false));
    abre.addEventListener("click", function () { menu(!topo.classList.contains("aberto")); });
    document.getElementById("menu").addEventListener("click", function (e) {
      if (e.target.closest("a")) menu(false);
    });
    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape" && topo.classList.contains("aberto")) { menu(false); abre.focus(); }
    });
  }

  // ── 3 · onde se está ───────────────────────────────────────────────────
  var ligacoes = {};
  document.querySelectorAll('.menu a[href^="#"]').forEach(function (a) { ligacoes[a.getAttribute("href").slice(1)] = a; });
  if ("IntersectionObserver" in window && Object.keys(ligacoes).length) {
    var vistas = new IntersectionObserver(function (entradas) {
      entradas.forEach(function (e) {
        var a = ligacoes[e.target.id];
        if (!a) return;
        if (e.isIntersecting) {
          Object.keys(ligacoes).forEach(function (k) { ligacoes[k].removeAttribute("aria-current"); });
          a.setAttribute("aria-current", "true");
        }
      });
    }, { rootMargin: "-45% 0px -50% 0px" });
    Object.keys(ligacoes).forEach(function (id) {
      var s = document.getElementById(id);
      if (s) vistas.observe(s);
    });
    // De volta à abertura, nenhuma secção do menu está a ser lida.
    var cimo = document.querySelector(".abertura");
    if (cimo) new IntersectionObserver(function (e) {
      if (e[0].isIntersecting) Object.keys(ligacoes).forEach(function (k) { ligacoes[k].removeAttribute("aria-current"); });
    }, { rootMargin: "-45% 0px -50% 0px" }).observe(cimo);
  }

  // Só aquece o arranque quando há intenção de jogar, numa ligação adequada.
  var preparado = false;
  function prepararJogo() {
    var rede = navigator.connection;
    if (preparado || (rede && (rede.saveData || /(^|-)2g$|3g/.test(rede.effectiveType)))) return;
    preparado = true;
    var link = document.createElement("link"); link.rel = "prefetch"; link.href = "/jogar/index.js";
    document.head.appendChild(link);
  }
  document.querySelectorAll('a[href^="/jogar/"]').forEach(a => {
    a.addEventListener("pointerenter", prepararJogo, { once: true });
    a.addEventListener("focus", prepararJogo, { once: true });
  });
})();
