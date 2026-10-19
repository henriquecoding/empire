/* tools/web/paginas/laboratorio-contas.js — as contas do laboratório (PUB-06, ADR 0085).

   As mesmas que o jogo faz, uma função por cada função do GDScript de onde vem,
   e com o nome dela ao lado. Corre em três sítios: no browser (window.EmpireContas),
   na construção, que pinta o estado inicial para quem não tem JavaScript, e nos
   testes (tests/web/laboratorio.test.mjs), que a conferem contra os números que o
   dossiê escreve. Não tem um único número de balanceamento: todos entram pelo
   modelo `m`, lido dos CSV por tools/web/dados.mjs. O 100 da ganância é a unidade
   de uma percentagem (EconomySystem.PERCENTAGEM), e não um número de balanço. */
(function (raiz) {
  "use strict";
  var PERCENTAGEM = 100;

  // ── §06 · EconomySystem ────────────────────────────────────────────────

  /** daily_income: a base construída a crescer a income_growth por dia. */
  function producao(fontes, dia, e) {
    return (e.fixo + fontes * e.porFonte) * Math.pow(e.crescimento, dia - 1);
  }

  /** trade_income: sem rotas é zero, e a rede só conta a partir da segunda. */
  function comercio(rotas, dia, e) {
    var rede = 1 + e.rede * Math.max(0, rotas - 1);
    return rotas * e.porRota * Math.pow(e.crescimentoComercio, dia - 1) * rede;
  }

  /** upkeep: de graça até à oitava tropa, depois dois escalões. */
  function manutencao(tropas, e) {
    if (tropas <= e.gratis) return 0;
    var escalao1 = Math.min(tropas, e.limite1) - e.gratis;
    var escalao2 = Math.max(0, tropas - e.limite1);
    return escalao1 * e.taxa1 + escalao2 * e.taxa2;
  }

  /** night_cost: o que custa sobreviver à noite. */
  function custoNoite(dia, e) {
    return e.noiteBase * Math.pow(e.noiteCrescimento, dia - 1);
  }

  /** net_income, termo a termo: o que se produz, o que os nobres levam e o soldo. */
  function balanco(p, dia, e) {
    var prod = producao(p.fontes, dia, e), com = comercio(p.rotas, dia, e);
    var nobres = (prod + com) * p.ganancia / PERCENTAGEM, soldo = manutencao(p.tropas, e);
    return { dia: dia, producao: prod, comercio: com, nobres: nobres, soldo: soldo,
      liquido: prod + com - nobres - soldo, noite: custoNoite(dia, e) };
  }

  /** suffocation_day: o primeiro dia em que a noite custa mais do que o reino rende; 0 se nenhum. */
  function asfixia(p, e, dias) {
    for (var d = 1; d <= (dias || e.dias); d++) {
      var b = balanco(p, d, e);
      if (b.noite > b.liquido) return d;
    }
    return 0;
  }

  /** RulesFactory.impulse_cost_mult: o perfil é o da gama onde a ganância cai, se cair numa. */
  function perfilGanancia(ganancia, perfis) {
    for (var i = 0; i < perfis.length; i++) if (ganancia >= perfis[i].de && ganancia <= perfis[i].ate) return perfis[i];
    return null;
  }

  // ── §74 e §51 · RotProfile, RotSystem e RotPick ─────────────────────────

  function proposta(n, k) { return n.propostas[k].valor; }

  /** RotProfile.calendar_mass: a rampa das primeiras noites e, com as propostas, o crescimento. */
  function massaCalendario(dia, n, comPropostas) {
    var cheia = n.base + n.porDia * dia;
    var desde = proposta(n, "desde"), cresce = proposta(n, "crescimento");
    if (comPropostas && desde > 0 && dia > desde && cresce > 1) return cheia * Math.pow(cresce, dia - desde);
    if (n.rampa <= 1 || n.abertura <= 0 || dia >= n.rampa) return cheia;
    var t = (Math.max(dia, 1) - 1) / (n.rampa - 1);
    return n.abertura + (cheia - n.abertura) * t;
  }

  /** RotProfile.rhythm: a noite funda e a calma, só com as propostas. */
  function ritmo(dia, n, comPropostas) {
    var cada = proposta(n, "picoCada");
    if (!comPropostas || cada <= 0) return 1;
    var primeiro = proposta(n, "primeiroPico") > 0 ? proposta(n, "primeiroPico") : cada;
    if (dia < primeiro) return 1;
    if ((dia - primeiro) % cada === 0) return proposta(n, "pico");
    if (dia > primeiro && (dia - primeiro - 1) % cada === 0) return proposta(n, "calma");
    return 1;
  }

  /** RotProfile.written_weight: o que escreveste de dia pesa em rampa, só com as propostas. */
  function pesoEscrito(dia, n, comPropostas) {
    if (!comPropostas || !proposta(n, "rampaEscrita") || n.rampa <= 1 || dia >= n.rampa) return 1;
    return (Math.max(dia, 1) - 1) / (n.rampa - 1);
  }

  /** RotSystem._massa_do_dia, termo a termo. */
  function massa(c, n, comPropostas) {
    var calendario = massaCalendario(c.dia, n, comPropostas);
    var fortalezas = n.porFortaleza * c.fortalezas;
    var peso = pesoEscrito(c.dia, n, comPropostas);
    var arvores = (n.porAmargueiro * c.amargueiros + n.porNomeado * c.nomeados) * peso;
    var recusas = Math.min(n.porRecusa * Math.min(c.recusas, n.recusasMax), n.tetoRecusas) * peso;
    var r = ritmo(c.dia, n, comPropostas);
    return { calendario: calendario, fortalezas: fortalezas, arvores: arvores, recusas: recusas, ritmo: r,
      total: (calendario + fortalezas + arvores + recusas) * r };
  }

  /** RotProfile.debut_cap: quantas de uma espécie que estreia cabem nesta noite (-1: sem teto). */
  function tetoEstreia(dia, abre, n, comPropostas) {
    var passo = proposta(n, "estreia");
    if (!comPropostas || passo <= 0 || abre <= 1) return -1;
    return Math.max(0, dia - abre + 1) * passo;
  }

  /** RotPick.choose e RotPick.take, até a massa não pagar mais nada: o orçamento da noite. */
  function invocar(total, dia, criaturas, n, o) {
    var resta = total, veio = {}, fila = [], ordem = [];
    for (;;) {
      var escolhida = null;
      for (var i = 0; i < criaturas.length && !escolhida; i++) {
        var c = criaturas[i];
        if (c.subsolo && !o.subsolo) continue;
        if (c.desde > dia || c.massa > resta) continue;
        var teto = tetoEstreia(dia, c.desde, n, o.propostas);
        if (teto < 0 || (veio[c.id] || 0) < teto) escolhida = c;
      }
      if (!escolhida) break;
      resta -= escolhida.massa;
      veio[escolhida.id] = (veio[escolhida.id] || 0) + 1;
      ordem.push(escolhida.id);
    }
    for (var j = 0; j < criaturas.length; j++) if (veio[criaturas[j].id]) fila.push({ id: criaturas[j].id, n: veio[criaturas[j].id] });
    return { fila: fila, sobra: resta, ordem: ordem };
  }

  /** RotSystem.tick: uma invocação por intervalo, sorteado em summon_interval, enquanto ela
      está no campo. Com os intervalos todos longos cabem `poucas`; com todos curtos, `muitas`. */
  function invocacoes(segundos, cadencia) {
    return { poucas: Math.floor(segundos / cadencia.ate), muitas: Math.floor(segundos / cadencia.de) };
  }

  /** As que chegam a vir: as primeiras da ordem do RotPick, por espécie — `de` com os intervalos
      longos, até `ate` com os curtos. `fora` é o resto da ordem, que fica por gastar à alvorada. */
  function chegam(r, t) {
    var conta = function (k) {
      var v = {};
      r.ordem.slice(0, k).forEach(function (id) { v[id] = (v[id] || 0) + 1; });
      return v;
    };
    var certas = conta(t.poucas), talvez = conta(t.muitas);
    return {
      fila: r.fila.filter(function (x) { return talvez[x.id]; }).map(function (x) { return { id: x.id, de: certas[x.id] || 0, ate: talvez[x.id] }; }),
      fora: r.ordem.slice(t.muitas),
    };
  }

  // ── §07 · o tempo até matar ─────────────────────────────────────────────

  /** A tabela do §07: golpes inteiros, cada um ao intervalo, divididos pela precisão. */
  function tempoAteMatar(atacante, vida, precisao) {
    var golpes = Math.ceil(vida / atacante.dano);
    return { golpes: golpes, segundos: golpes * atacante.intervalo / precisao };
  }

  // ── §10 · a escada do muro ──────────────────────────────────────────────

  /** O que custa chegar a um nível: cada degrau paga-se inteiro (WallSite). */
  function custoAte(muros, nivel) {
    var s = 0;
    for (var i = 0; i < muros.length && muros[i].nivel <= nivel; i++) s += muros[i].custo;
    return s;
  }

  raiz.EmpireContas = {
    producao: producao, comercio: comercio, manutencao: manutencao, custoNoite: custoNoite, balanco: balanco,
    asfixia: asfixia, perfilGanancia: perfilGanancia, massaCalendario: massaCalendario, ritmo: ritmo,
    massa: massa, invocar: invocar, invocacoes: invocacoes, chegam: chegam, tempoAteMatar: tempoAteMatar, custoAte: custoAte,
  };
})(typeof window !== "undefined" ? window : this);
