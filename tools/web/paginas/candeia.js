/* O instrumento da Podridão só é carregado na página do jogo. */
(function () {
  "use strict";
  var raiz = document.documentElement;
  var fmt = (s, v) => String(s).replace(/\{(\w+)\}/g, (m, k) => k in v ? v[k] : m);
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
