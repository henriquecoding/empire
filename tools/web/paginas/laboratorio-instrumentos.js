/* tools/web/paginas/laboratorio-instrumentos.js — os quatro instrumentos do laboratório (PUB-06, ADR 0085).

   Cada um recebe o painel e o estado dos controlos, pede a resposta às contas do
   jogo (window.EmpireContas), escreve-a nos lugares data-lab do painel e devolve
   a frase que o leitor de ecrã ouve. A casca (laboratorio.js) dá-lhes o modelo e
   as ferramentas; vão os três no mesmo ficheiro servido (assets.mjs). */
(function () {
  "use strict";
  window.EmpireInstrumentos = function (casca) {
    var L = casca.L, V = casca.V, l = casca.l, C = casca.C, num = casca.num, fmt = casca.fmt;
    var slot = casca.slot, texto = casca.texto, mostrar = casca.mostrar, nome = casca.nome;
    var SVG = "http://www.w3.org/2000/svg";
    var MENOS = "\u2212";

    // ── 1 · quem vem esta noite (§74, §51) ──────────────────────────────────
    function noite(p, s) {
      var n = L.noite, prop = !!s.prop;
      var m = C.massa({ dia: s.dia, fortalezas: s.fort, amargueiros: s.arv, nomeados: s.nom, recusas: s.rec }, n, prop);
      var r = C.invocar(m.total, s.dia, L.criaturas, n, { subsolo: !!s.sub, propostas: prop });
      // Ela invoca uma de cada vez (§51): só a cabeça da ordem chega antes da alvorada.
      var t = C.invocacoes(n.duracao, n.cadencia), vem = C.chegam(r, t);
      var massaDe = function (id) { return L.criaturas.find(function (x) { return x.id === id; }).massa; };
      var veio = {}, quantas = {};
      vem.fila.forEach(function (x) { veio[x.id] = x.ate; quantas[x.id] = x.de === x.ate ? String(x.ate) : x.de + "–" + x.ate; });
      var semTempo = vem.fora.reduce(function (soma, id) { return soma + massaDe(id); }, 0);
      texto(p, "massa", num.format(m.total));
      [m.calendario, m.fortalezas, m.arvores, m.recusas].forEach(function (v, i) { texto(p, "t" + i, num.format(v)); });
      var ritmo = slot(p, "ritmo");
      mostrar(ritmo, m.ritmo !== 1);
      if (m.ritmo !== 1) ritmo.textContent = fmt(m.ritmo > 1 ? V.ritmo_pico : V.ritmo_calma, { mult: num.format(m.ritmo) });
      p.querySelectorAll("[data-o]").forEach(function (i) {
        var k = i.dataset.o;
        var c = L.criaturas.find(function (x) { return x.id === k; });
        var peso = k === "sobra" ? r.sobra + semTempo : (veio[k] || 0) * c.massa;
        i.hidden = peso < 0.05;
        i.style.flexGrow = String(peso);
      });
      var fila = [];
      p.querySelectorAll(".lab-besta").forEach(function (li) {
        var k = li.dataset.besta, q = veio[k] || 0;
        li.hidden = !q;
        if (q) {
          li.querySelector('[data-lab="n"]').textContent = "× " + quantas[k];
          fila.push(fmt(V.fila_item, { n: quantas[k], nome: nome(L.criaturas.find(function (x) { return x.id === k; })) }));
        }
      });
      mostrar(slot(p, "vazia"), !fila.length);
      var sobra = texto(p, "sobra", fmt(V.sobra, { sobra: num.format(r.sobra) }));
      mostrar(sobra, r.sobra >= 0.05);
      var tempo = fmt(V.tempo, { de: n.cadencia.de, ate: n.cadencia.ate, s: n.duracao, poucas: t.poucas, muitas: t.muitas });
      if (vem.fora.length) tempo += " " + fmt(V.tempo_fora, { fora: vem.fora.length });
      else if (r.ordem.length > t.poucas) tempo += " " + V.tempo_talvez;
      texto(p, "tempo", tempo);
      mostrar(texto(p, "lados", fmt(V.dois_lados, { dia: n.doisLados })), s.dia >= n.doisLados);
      var faltam = L.criaturas.filter(function (c) { return c.desde > s.dia || (c.subsolo && !s.sub); }).reverse().map(function (c) {
        return c.desde > s.dia ? nome(c) + " (" + fmt(V.desde_dia, { dia: c.desde }) + ")" : nome(c) + " (" + V.subsolo_fechado + ")";
      });
      texto(p, "por-chegar", faltam.join(" · "));
      mostrar(slot(p, "por-chegar-linha"), faltam.length > 0);
      mostrar(texto(p, "rampa", fmt(V.rampa, { rampa: n.rampa })), s.dia < n.rampa);
      var q = n.propostas;
      mostrar(texto(p, "propostas", fmt(V.propostas, {
        desde: q.desde.valor, pc: num.format(Math.round((q.crescimento.valor - 1) * 1000) / 10), cada: q.picoCada.valor,
        pico: num.format(q.pico.valor), calma: num.format(q.calma.valor), estreia: q.estreia.valor,
      })), prop);
      var frase = fmt(V.noite_resumo, { dia: s.dia, massa: num.format(m.total), fila: fila.length ? fila.join(", ") + "." : V.fila_vazia });
      texto(p, "placar", frase);
      return frase;
    }

    // ── 2 · o dia da asfixia (§06) ──────────────────────────────────────────
    var grelhaFeita = false;
    function economia(p, s) {
      var e = L.economia, dias = e.dias;
      var perfil = { fontes: s.fontes, rotas: s.rotas, tropas: s.tropas, ganancia: s.gan };
      var serie = [];
      for (var d = 1; d <= dias; d++) serie.push(C.balanco(perfil, d, e));
      var asf = C.asfixia(perfil, e);
      var asfTexto = asf ? fmt(V.asfixia, { dia: asf }) : fmt(V.sem_asfixia, { dias: dias });
      texto(p, "asfixia", asfTexto);
      var selo = slot(p, "alvo");
      var lugar = !asf ? "tarde" : asf < e.alvo[0] ? "cedo" : asf > e.alvo[1] ? "tarde" : "no_alvo";
      selo.textContent = V[lugar];
      selo.dataset.lugar = lugar;
      texto(p, "placar", asfTexto + " · " + V[lugar]);
      var g = C.perfilGanancia(s.gan, e.perfis);
      texto(p, "perfil", g ? fmt(V.perfil, { g: s.gan, nome: nome(g), de: g.de, ate: g.ate }) : fmt(V.sem_perfil, { g: s.gan }));

      // O gráfico: até onde a noite passa o reino, e um pouco mais — depois disso a
      // linha da noite sai por cima, que é o que ela faz.
      var liq = serie.map(function (b) { return b.liquido; });
      var alto = Math.max.apply(null, liq.concat([asf ? serie[asf - 1].noite : serie[dias - 1].noite])) * 1.5;
      var baixo = Math.min(0, Math.min.apply(null, liq));
      var X = function (dia) { return (dia - 1) / (dias - 1) * 300; };
      var Y = function (v) { return 100 - (v - baixo) / (alto - baixo) * 100; };
      var tela = p.querySelector(".lab-tela"), svg = tela.querySelector("svg");
      if (!grelhaFeita) {
        var grelha = svg.querySelector(".g-grelha");
        for (var k = 5; k < dias; k += 5) {
          var linha = document.createElementNS(SVG, "line");
          linha.setAttribute("x1", X(k)); linha.setAttribute("x2", X(k)); linha.setAttribute("y1", 0); linha.setAttribute("y2", 100);
          linha.setAttribute("vector-effect", "non-scaling-stroke");
          grelha.appendChild(linha);
        }
        grelhaFeita = true;
      }
      var alvo = svg.querySelector(".g-alvo");
      alvo.setAttribute("x", X(e.alvo[0])); alvo.setAttribute("width", X(e.alvo[1]) - X(e.alvo[0]));
      var pontos = function (k) { return serie.map(function (b) { return X(b.dia).toFixed(1) + "," + Y(b[k]).toFixed(2); }).join(" "); };
      svg.querySelector(".g-rende").setAttribute("points", pontos("liquido"));
      svg.querySelector(".g-custa").setAttribute("points", pontos("noite"));
      var foco = Math.max(1, Math.min(dias, s.foco)), b = serie[foco - 1];
      var linhaFoco = svg.querySelector(".g-foco");
      linhaFoco.setAttribute("x1", X(foco)); linhaFoco.setAttribute("x2", X(foco));
      [["g-ponto-rende", b.liquido], ["g-ponto-custa", b.noite]].forEach(function (par) {
        var ponto = tela.querySelector("." + par[0]), y = Y(par[1]);
        ponto.style.left = (X(foco) / 3) + "%";
        ponto.style.top = Math.max(0, Math.min(100, y)) + "%";
        ponto.hidden = y < 0 || y > 100;
      });
      tela.setAttribute("aria-label", fmt(V.grafico_alt, { dias: dias, asfixia: asfTexto }));
      [["c0", "+", b.producao], ["c1", "+", b.comercio], ["c2", MENOS, b.nobres], ["c3", MENOS, b.soldo], ["c4", "= ", b.liquido], ["c5", "", b.noite]]
        .forEach(function (c) { texto(p, c[0], c[1] + num.format(c[2])); });
      var conta = p.querySelector(".lab-contas");
      conta.dataset.vence = b.noite > b.liquido ? "noite" : "reino";
      var e1 = Math.max(0, Math.min(s.tropas, e.limite1) - e.gratis), e2 = Math.max(0, s.tropas - e.limite1);
      texto(p, "soldo", fmt(V.soldo, { tropas: s.tropas, gratis: Math.min(s.tropas, e.gratis), e1: e1, t1: num.format(e.taxa1), e2: e2, t2: num.format(e.taxa2), soldo: num.format(b.soldo) }));
      return fmt(V.economia_resumo, { asfixia: asfTexto, dia: foco, liquido: num.format(b.liquido), noite: num.format(b.noite) });
    }

    // ── 3 · quanto tempo até cair (§07) ─────────────────────────────────────
    function combate(p, s) {
      var tr = L.tropas.find(function (x) { return x.id === s.tropa; }) || L.tropas[0];
      var onde = p.querySelector(".lab-onde");
      onde.disabled = !tr.posto;
      var naTorre = tr.posto && s.onde === "torre";
      var precisao = naTorre ? L.torre : tr.precisao;
      texto(p, "tropa", fmt(V.tropa_linha, {
        dano: tr.dano, intervalo: num.format(tr.intervalo), dps: num.format(tr.dano / tr.intervalo), vida: tr.vida,
        custo: tr.custo === null ? V.por_decidir : fmt(V.moedas, { n: tr.custo }),
      }));
      mostrar(texto(p, "precisao", fmt(V.precisao_proposta, { nome: nome(tr) })), tr.precisaoProposta && !naTorre);
      var itens = [];
      p.querySelectorAll(".lab-ttk li").forEach(function (li) {
        var c = L.criaturas.find(function (x) { return x.id === li.dataset.besta; });
        var t = C.tempoAteMatar(tr, c.vida, precisao);
        var longa = t.segundos > L.noiteSegundos;
        li.querySelector('[data-lab="v"]').textContent = fmt(V.golpes, { golpes: t.golpes, s: num.format(t.segundos) });
        li.querySelector('[data-lab="nota"]').textContent = longa ? V.mais_que_noite : "";
        li.classList.toggle("longa", longa);
        li.querySelector(".ttk-barra i").style.width = Math.min(100, t.segundos / (L.noiteSegundos * 1.25) * 100) + "%";
        itens.push(fmt(V.combate_item, { nome: nome(c), s: num.format(t.segundos) }));
      });
      return fmt(V.combate_resumo, { tropa: nome(tr), linhas: itens.join(", ") });
    }

    // ── 4 · a escada do muro (§10) ──────────────────────────────────────────
    function bloco(svg, x, y, w, h, classe) {
      var r = document.createElementNS(SVG, "rect");
      r.setAttribute("x", x); r.setAttribute("y", y); r.setAttribute("width", w); r.setAttribute("height", h);
      r.setAttribute("class", classe);
      svg.appendChild(r);
    }
    function desenharMuro(svg, w, caminho) {
      while (svg.firstChild) svg.removeChild(svg.firstChild);
      var CHAO = 86, LARG = 36, X0 = 120, altura = 16 + w.nivel * 11, topo = CHAO - altura;
      bloco(svg, 0, CHAO, 200, 14, "m-chao");
      bloco(svg, 0, CHAO, 200, 2, "m-erva");
      // O muro, fiada a fiada, desencontradas como pedras (ou troncos, nos dois primeiros).
      for (var y = CHAO - 6, f = 0; y >= topo; y -= 6, f++) {
        for (var x = X0 - (f % 2 ? 6 : 0); x < X0 + LARG; x += 12) {
          var a = Math.max(X0, x), b = Math.min(X0 + LARG, x + 11);
          if (b > a) bloco(svg, a, y, b - a, 5, "m-n" + w.nivel);
        }
      }
      if (caminho === "b") {
        // A fortificação: um contraforte em degraus, do lado de fora.
        for (var i = 0; i < 4; i++) bloco(svg, X0 - 6 - i * 5, CHAO - altura * (4 - i) / 5, 6, altura * (4 - i) / 5, "m-n" + w.nivel + " m-forte");
      } else if (w.postosA) {
        // A guarnição: um arqueiro por posto, em cima do muro.
        var cabem = Math.min(w.postosA, 9), passo = LARG / cabem;
        for (var k = 0; k < cabem; k++) {
          var ax = Math.round(X0 + passo * k + passo / 2 - 1);
          bloco(svg, ax, topo - 7, 3, 5, "m-tropa");
          bloco(svg, ax, topo - 10, 3, 3, "m-cabeca");
        }
      }
      // Quem ataca: só cabem tantos quanto os slots de contacto (§07), à frente do muro.
      var frente = caminho === "b" ? X0 - 28 : X0 - 4;
      for (var j = 0; j < w.contacto; j++) {
        var cx = frente - 10 - j * 10;
        bloco(svg, cx, CHAO - 6, 7, 6, "m-podre");
        bloco(svg, cx + 1, CHAO - 5, 1, 1, "m-olho");
        bloco(svg, cx + 4, CHAO - 5, 1, 1, "m-olho");
      }
      // O núcleo, atrás: o que o muro defende.
      bloco(svg, 172, CHAO - 26, 20, 26, "m-nucleo");
      bloco(svg, 168, CHAO - 32, 28, 7, "m-copa");
    }
    function muro(p, s) {
      var w = L.muros.find(function (x) { return String(x.nivel) === String(s.nivel); }) || L.muros[0];
      var cam = s.caminho === "a" ? "a" : "b";
      var vida = cam === "a" ? w.vidaA : w.vidaB, postos = cam === "a" ? w.postosA : w.postosB;
      var ou = function (v) { return v === null ? V.por_decidir : String(v); };
      texto(p, "degrau", fmt(V.moedas, { n: w.custo }));
      var total = C.custoAte(L.muros, w.nivel);
      texto(p, "total", fmt(V.moedas, { n: total }));
      slot(p, "vida").classList.toggle("lab-por-decidir", vida === null);
      texto(p, "vida", ou(vida));
      slot(p, "postos").classList.toggle("lab-por-decidir", postos === null);
      texto(p, "postos", ou(postos));
      texto(p, "contacto", String(w.contacto));
      texto(p, "abre", w.estagio ? w.estagio[l] : "—");
      var ariete = L.criaturas.find(function (c) { return c.soMuros; });
      if (vida === null) texto(p, "ariete", fmt(V.ariete_por_decidir, { nome: nome(ariete) }));
      else {
        var t = C.tempoAteMatar(ariete, vida, 1);
        texto(p, "ariete", fmt(V.ariete, { nome: nome(ariete), golpes: t.golpes, s: num.format(t.segundos) }));
      }
      var req = [];
      if (w.unico) req.push(V.unico);
      if (w.conquista) req.push(fmt(V.conquista, { povo: w.conquista[l] }));
      mostrar(texto(p, "requisitos", req.join(" ")), req.length > 0);
      desenharMuro(p.querySelector(".lab-desenho-muro svg"), w, cam);
      slot(p, "muro-alt").setAttribute("aria-label", fmt(V.muro_alt, { nome: nome(w), caminho: cam.toUpperCase(), contacto: w.contacto }));
      return fmt(V.muro_resumo, { nome: nome(w), caminho: cam.toUpperCase(), custo: w.custo, total: total });
    }

    return { noite: noite, economia: economia, combate: combate, muro: muro };
  };
})();
