/* tools/web/paginas/site.js — o que a página faz (ADR 0024, ADR 0025).

   Seis coisas, todas opcionais: sem JavaScript a página está inteira, lê-se e
   navega-se — o dia fica parado na manhã, a candeia no dia 1, o menu numa
   segunda linha. Nada do que aqui está esconde conteúdo à espera de si.

     1 · o tema, que segue o sistema até alguém escolher
     2 · o menu, em ecrãs estreitos
     3 · a ligação do menu da secção que se está a ler
     4 · as entradas das secções e a contagem dos números
     5 · o dia a passar na abertura, com pausa (WCAG 2.2.2)
     6 · a candeia, noite a noite, com as contas do rot.csv */
(function () {
  "use strict";
  var raiz = document.documentElement;
  var reduz = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var fmt = function (s, v) {
    return String(s).replace(/\{(\w+)\}/g, function (m, k) { return k in v ? v[k] : m; });
  };

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
  }

  // ── 4 · entradas e contagens ───────────────────────────────────────────
  var numero = new Intl.NumberFormat(raiz.lang || "pt-PT");
  function contar(el) {
    var alvo = parseInt(el.dataset.conta, 10);
    if (!alvo || reduz) return;
    var t0 = performance.now(), dura = 900;
    (function passo(t) {
      var k = Math.min(1, (t - t0) / dura), e = 1 - Math.pow(1 - k, 4);
      el.textContent = numero.format(Math.round(alvo * e));
      if (k < 1) requestAnimationFrame(passo);
    })(t0);
  }
  var revelar = document.querySelectorAll(".revela, .barra");
  if (!("IntersectionObserver" in window)) {
    revelar.forEach(function (el) { el.classList.add("visto"); });
  } else {
    var io = new IntersectionObserver(function (entradas) {
      entradas.forEach(function (e) {
        if (!e.isIntersecting) return;
        e.target.classList.add("visto");
        e.target.querySelectorAll("[data-conta]").forEach(contar);
        io.unobserve(e.target);
      });
    }, { rootMargin: "0px 0px -8% 0px", threshold: 0.1 });
    revelar.forEach(function (el) { io.observe(el); });
  }

  // ── 5 · o dia a passar ─────────────────────────────────────────────────
  // Um dia do jogo (360 s no clock.csv) passa em 24 s: a mesma proporção entre
  // as fases, quinze vezes mais depressa. As seis fotografias são do mesmo
  // sítio, e o que muda entre elas é só a luz — que é o que o §23 quer que se
  // leia. Pára quando sai do ecrã ou do separador, e com movimento reduzido
  // não arranca sozinho: fica na manhã, e a fita escolhe-se à mão.
  var palco = document.getElementById("palco");
  if (palco) (function () {
    var DIA = +palco.dataset.dia, ESCALA = 15;
    var fita = document.getElementById("fita-palco");
    var agora = document.getElementById("agora");
    var pausa = document.getElementById("pausa");
    var fases = [].map.call(fita.querySelectorAll("li"), function (li) {
      return { id: li.dataset.fase, inicio: +li.dataset.inicio, dura: +li.dataset.dura, nome: li.dataset.nome };
    });
    var quadros = {};
    palco.querySelectorAll(".quadro").forEach(function (img) { quadros[img.dataset.fase] = img; });
    var ativa = palco.querySelector(".quadro.ativo").dataset.fase;
    var t = fases.filter(function (f) { return f.id === ativa; })[0].inicio;
    var parado = reduz, fora = false, ultimo = 0, pedido = 0;

    fita.setAttribute("role", "slider");
    fita.setAttribute("tabindex", "0");
    fita.setAttribute("aria-label", fita.dataset.rotulo);
    fita.setAttribute("aria-valuemin", "0");
    fita.setAttribute("aria-valuemax", String(DIA));

    function faseEm(x) {
      for (var i = fases.length - 1; i >= 0; i--) if (x >= fases[i].inicio) return fases[i];
      return fases[0];
    }
    function mostrar() {
      fita.style.setProperty("--p", (t / DIA).toFixed(4));
      var f = faseEm(t);
      fita.setAttribute("aria-valuenow", String(Math.round(t)));
      fita.setAttribute("aria-valuetext", f.nome + " · " + Math.round(t) + " s");
      if (f.id === ativa) return;
      quadros[ativa].classList.remove("ativo");
      quadros[ativa].setAttribute("aria-hidden", "true");
      quadros[f.id].classList.add("ativo");
      quadros[f.id].removeAttribute("aria-hidden");
      ativa = f.id;
      agora.textContent = fmt(palco.dataset.agora, { dia: 1, fase: f.nome });
    }
    function passo(agoraMs) {
      pedido = 0;
      if (parado || fora || document.hidden) return;
      if (ultimo) t = (t + ((agoraMs - ultimo) / 1000) * ESCALA) % DIA;
      ultimo = agoraMs;
      mostrar();
      pedido = requestAnimationFrame(passo);
    }
    function andar() {
      ultimo = 0;
      if (!pedido && !parado && !fora && !document.hidden) pedido = requestAnimationFrame(passo);
    }
    function parar(sim) {
      parado = sim;
      pausa.setAttribute("aria-pressed", sim ? "true" : "false");
      pausa.setAttribute("aria-label", sim ? palco.dataset.continuar : palco.dataset.pausar);
      andar();
    }
    function irPara(x) {
      t = Math.max(0, Math.min(DIA - 0.001, x));
      mostrar();
    }
    pausa.addEventListener("click", function () { parar(!parado); });
    fita.addEventListener("click", function (e) {
      var r = fita.getBoundingClientRect();
      irPara(((e.clientX - r.left) / r.width) * DIA);
      parar(true);
    });
    fita.addEventListener("keydown", function (e) {
      var f = faseEm(t), i = fases.indexOf(f);
      var alvo = { ArrowRight: i + 1, ArrowUp: i + 1, ArrowLeft: i - 1, ArrowDown: i - 1, Home: 0, End: fases.length - 1 }[e.key];
      if (alvo === undefined) return;
      e.preventDefault();
      irPara(fases[(alvo + fases.length) % fases.length].inicio + 0.01);
      parar(true);
    });
    document.addEventListener("visibilitychange", andar);
    if ("IntersectionObserver" in window) {
      new IntersectionObserver(function (e) { fora = !e[0].isIntersecting; andar(); }).observe(palco);
    }
    mostrar();
    parar(parado);
  })();

  // ── 6 · a candeia ──────────────────────────────────────────────────────
  // As contas são as do WorldLight e do rot.csv (lidas na construção, nos
  // data-* do instrumento): raio = base + por_dia × dia, com teto; três discos
  // do bordo para o núcleo, a 3/3, 2/3 e 1/3 do raio; e um anel de dither em
  // quadrados, um aceso e um apagado. A escala é meio píxel de ecrã por píxel
  // do jogo, e o canvas desenha-se píxel a píxel — sem suavização, como no jogo.
  var inst = document.getElementById("candeia");
  if (inst) (function () {
    var d = inst.dataset, n = function (k) { return +d[k]; };
    var tela = inst.querySelector("canvas"), g = tela.getContext("2d");
    var regua = document.getElementById("candeia-dia"), saida = document.getElementById("candeia-n");
    var ler = function (k) { return inst.querySelector('[data-l="' + k + '"]'); };
    var cor = getComputedStyle(raiz);
    var paragens = ["--bordo", "--meio", "--nucleo"].map(function (v) { return cor.getPropertyValue(v).trim(); });
    var terra = cor.getPropertyValue("--terra").trim() || "#292520";
    var um = new Intl.NumberFormat(d.lingua, { maximumFractionDigits: 1 });
    var W = tela.width, H = tela.height, ESC = 0.5, CX = Math.round(W * 0.62), CHAO = Math.round(H * 0.74);

    function disco(r, c) {
      g.fillStyle = c;
      for (var y = -r; y <= r; y++) {
        var m = Math.floor(Math.sqrt(r * r - y * y));
        g.fillRect(CX - m, CHAO + y, 2 * m + 1, 1);
      }
    }
    function desenhar(dia) {
      var raio = Math.min(n("raioBase") + n("raioDia") * dia, n("raioTeto"));
      var r = Math.round(raio * ESC);
      g.fillStyle = terra; g.fillRect(0, 0, W, H);
      g.fillStyle = "#17130d"; g.fillRect(0, CHAO, W, H - CHAO);
      g.fillStyle = "#3b2d1d"; g.fillRect(0, CHAO, W, 1);
      // O teto, em pontos: é o raio que a candeia nunca passa.
      var teto = Math.round(n("raioTeto") * ESC);
      g.fillStyle = "rgba(239,234,218,.28)";
      for (var a = 0; a < Math.PI * 2; a += 4 / teto) g.fillRect(Math.round(CX + Math.cos(a) * teto), Math.round(CHAO + Math.sin(a) * teto), 1, 1);
      // O bordo em dither: quadrados sobre a circunferência, um sim, um não.
      var celula = Math.max(1, Math.round(n("dither") * ESC)), passo = celula * 2;
      var quantos = Math.floor((Math.PI * 2 * (r + celula)) / passo);
      g.fillStyle = paragens[0];
      for (var i = 0; i < quantos; i++) {
        var ang = (Math.PI * 2 * i) / quantos;
        g.fillRect(Math.round(CX + Math.cos(ang) * (r + celula)), Math.round(CHAO + Math.sin(ang) * (r + celula)), celula, celula);
      }
      for (var p = 0; p < 3; p++) disco(Math.round((r * (3 - p)) / 3), paragens[p]);
      return raio;
    }
    function atualizar() {
      var dia = +regua.value;
      var raio = desenhar(dia);
      saida.textContent = dia;
      ler("raio").textContent = um.format(raio);
      ler("vel").textContent = um.format(n("velBase") + n("velDia") * dia);
      ler("massa").textContent = um.format(n("massaBase") + n("massaDia") * dia);
      ler("lados").textContent = dia >= n("lados") ? d.dois : d.um;
      var alt = fmt(d.alt, { dia: dia, raio: um.format(raio) });
      tela.setAttribute("aria-label", alt);
      tela.textContent = alt;
    }
    regua.addEventListener("input", atualizar);
    atualizar();
  })();
})();
