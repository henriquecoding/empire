/* tools/web/paginas/laboratorio.js — o laboratório de mecânicas, no browser (PUB-06, ADR 0085).

   Os controlos mudam o estado, as contas (window.EmpireContas, as do jogo) dão a
   resposta, e os instrumentos (laboratorio-instrumentos.js) mostram-na: é a ordem
   das explicações exploráveis — controlos, modelo, saída, imagem. O modelo (window.EmpireLaboratorio) vem da construção,
   no mesmo ficheiro, com os números dos CSV; aqui não há nenhum. O site.js só pede
   este ficheiro quando a secção se aproxima do ecrã, ou quando a ligação aponta
   para ela.

   Os separadores seguem o padrão da APG (setas, Home e End, ativação ao focar,
   porque o painel já está na página). O estado vai para o endereço com
   replaceState — partilha-se, e não enche o histórico — e só depois de alguém
   mexer: abrir a página não muda a barra do endereço. Para quem usa um leitor de
   ecrã, cada painel diz uma frase, meio segundo depois do último movimento, e
   não a cada passo do deslizador.

   Parado, não faz trabalho nenhum: só redesenha quando um controlo muda. */
(function () {
  "use strict";
  var raiz = document.getElementById("laboratorio");
  var C = window.EmpireContas;
  var M = window.EmpireLaboratorio;
  if (!raiz || !C || !M || !window.EmpireInstrumentos || raiz.classList.contains("lab-pronto")) return;
  var lingua = raiz.dataset.lingua, l = lingua === "pt-PT" ? "pt" : "en";
  var L = M.L, V = M.vivo[l];
  var num = new Intl.NumberFormat(lingua, { maximumFractionDigits: 1 });
  var fmt = function (s, v) { return String(s).replace(/\{(\w+)\}/g, function (m, k) { return k in v ? v[k] : m; }); };
  var separadores = Array.prototype.slice.call(raiz.querySelectorAll('[role="tab"]'));
  var paineis = {};
  raiz.querySelectorAll(".lab-painel").forEach(function (p) { paineis[p.dataset.ferramenta] = p; });
  var ativa = (raiz.querySelector(".lab-painel.ativo") || raiz.querySelector(".lab-painel")).dataset.ferramenta;
  var mexeu = false, falarDepois = 0;

  var slot = function (p, k) { return p.querySelector('[data-lab="' + k + '"]'); };
  var texto = function (p, k, t) { var e = slot(p, k); if (e) e.textContent = t; return e; };
  var mostrar = function (e, sim) { if (e) e.hidden = !sim; };
  var nome = function (x) { return x.nome[l]; };

  // ── o estado de um painel: os campos com nome (o «ver o dia» vive na saída) ──
  function ler(p) {
    var s = {};
    p.querySelectorAll("input[name]").forEach(function (i) {
      if (i.type === "range") s[i.name] = +i.value;
      else if (i.type === "checkbox") s[i.name] = i.checked ? 1 : 0;
      else if (i.type === "radio" && i.checked) s[i.name] = i.value;
    });
    return s;
  }
  function escrever(p, s) {
    p.querySelectorAll("input[name]").forEach(function (i) {
      if (!(i.name in s)) return;
      var v = String(s[i.name]);
      if (i.type === "range") {
        var x = Math.round(+v);
        if (isFinite(x)) i.value = String(Math.max(+i.min, Math.min(+i.max, x)));
      } else if (i.type === "checkbox") i.checked = v === "1";
      else if (i.type === "radio") { if (i.value === v) i.checked = true; }
    });
  }
  function ecoar(p) {
    p.querySelectorAll('input[type="range"]').forEach(function (i) {
      var o = document.getElementById(i.id + "-v");
      if (o) o.textContent = i.value;
    });
  }

  var DESENHO = window.EmpireInstrumentos({ L: L, V: V, l: l, C: C, num: num, fmt: fmt, slot: slot, texto: texto, mostrar: mostrar, nome: nome });

  // ── o endereço: #laboratorio?f=noite&dia=12 ─────────────────────────────
  function endereco() {
    var q = new URLSearchParams();
    q.set("f", ativa);
    var s = ler(paineis[ativa]);
    // Um controlo desligado não entra na conta, e por isso também não vai na ligação.
    paineis[ativa].querySelectorAll("input[name]:disabled").forEach(function (i) { delete s[i.name]; });
    Object.keys(s).forEach(function (k) { q.set(k, s[k]); });
    return location.pathname + location.search + "#laboratorio?" + q.toString();
  }
  function guardar() {
    if (!mexeu) return;
    try { history.replaceState(history.state, "", endereco()); } catch (e) {}
  }
  function lerEndereco() {
    var h = location.hash;
    if (h.indexOf("#laboratorio?") !== 0) return false;
    var q = new URLSearchParams(h.slice("#laboratorio?".length)), f = q.get("f");
    if (!paineis[f]) return false;
    var s = {};
    q.forEach(function (v, k) { if (k !== "f") s[k] = v; });
    escrever(paineis[f], s);
    selecionar(f, false);
    return true;
  }

  // ── desenhar, e dizer ───────────────────────────────────────────────────
  // O cenário em que o instrumento está, se estiver num: o «ver o dia» não conta.
  function marcarCenario(p, s) {
    p.querySelectorAll(".lab-cenario").forEach(function (b) {
      var igual = true;
      new URLSearchParams(b.dataset.cenario).forEach(function (v, k) { if (k !== "foco" && String(s[k]) !== v) igual = false; });
      b.classList.toggle("igual", igual);
    });
  }

  function atualizar(f, falar) {
    var p = paineis[f];
    ecoar(p);
    var s = ler(p);
    marcarCenario(p, s);
    var frase = DESENHO[f](p, s);
    if (!falar) return;
    clearTimeout(falarDepois);
    falarDepois = setTimeout(function () { texto(p, "resumo", frase); }, 500);
  }

  // ── os separadores (APG, ativação automática) ───────────────────────────
  function selecionar(f, foco) {
    ativa = f;
    separadores.forEach(function (b) {
      var sim = b.dataset.ferramenta === f;
      b.setAttribute("aria-selected", sim ? "true" : "false");
      b.tabIndex = sim ? 0 : -1;
      if (sim && foco) b.focus();
    });
    Object.keys(paineis).forEach(function (k) {
      paineis[k].classList.toggle("ativo", k === f);
      paineis[k].hidden = k !== f;
    });
    atualizar(f, false);
  }
  separadores.forEach(function (b, i) {
    b.addEventListener("click", function () { selecionar(b.dataset.ferramenta, false); mexeu = true; guardar(); });
    b.addEventListener("keydown", function (e) {
      var alvo = { ArrowRight: i + 1, ArrowLeft: i - 1, Home: 0, End: separadores.length - 1 }[e.key];
      if (alvo === undefined) return;
      e.preventDefault();
      selecionar(separadores[(alvo + separadores.length) % separadores.length].dataset.ferramenta, true);
      mexeu = true; guardar();
    });
  });
  Object.keys(paineis).forEach(function (f) {
    var p = paineis[f];
    var mudou = function (e) { if (e.target.name) { mexeu = true; atualizar(f, true); guardar(); } };
    p.addEventListener("input", mudou);
    p.addEventListener("change", mudou);
    // Um cenário é um estado inteiro, na forma do endereço: o mesmo caminho que uma ligação partilhada.
    p.addEventListener("click", function (e) {
      var b = e.target.closest(".lab-cenario");
      if (!b) return;
      var s = {};
      new URLSearchParams(b.dataset.cenario).forEach(function (v, k) { s[k] = v; });
      escrever(p, s);
      mexeu = true; atualizar(f, true); guardar();
    });
  });

  // ── partilhar: a folha do sistema num ecrã tátil, a área de transferência no resto ──
  var estado = document.getElementById("lab-estado");
  document.getElementById("lab-partilhar").addEventListener("click", function () {
    mexeu = true;
    guardar();
    var url = location.origin + endereco();
    var dizer = function (t) { estado.textContent = t; };
    var copiar = function () {
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(url).then(function () { dizer(V.copiada); }, function () { dizer(V.copiar_falhou); });
      } else dizer(V.copiar_falhou);
    };
    if (navigator.share && window.matchMedia("(pointer:coarse)").matches) {
      navigator.share({ title: document.title, url: url }).then(function () { dizer(V.partilhada); }, function (e) {
        if (!e || e.name !== "AbortError") copiar();
      });
    } else copiar();
  });

  // Os painéis que não se veem também ficam prontos: trocar de separador não espera por contas.
  Object.keys(paineis).forEach(function (f) { if (f !== ativa) atualizar(f, false); });
  var veioDeLigacao = lerEndereco();
  if (!veioDeLigacao) selecionar(ativa, false);
  raiz.classList.add("lab-pronto");
  if (veioDeLigacao) requestAnimationFrame(function () { raiz.scrollIntoView(); });
})();
