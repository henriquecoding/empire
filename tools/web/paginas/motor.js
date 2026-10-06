/* tools/web/paginas/motor.js — o motor de reportes do Empire (ADR 0026).
 *
 * É a Central de Feedback do Recibo Certo (src/lib/supabase/feedback.ts e
 * src/lib/feedback-sanitize.ts de lá), em JavaScript sem dependências: o site
 * não tem npm nem SDK, e um fetch chega. As mesmas regras: bloquear código
 * antes de enviar, limpar o texto, e deixar a base de dados repetir a limpeza.
 *
 * Nada aqui corre ao carregar a página. O primeiro pedido a outra origem é o do
 * botão que a pessoa carrega — o resto do site continua sem pedir nada a
 * ninguém (ADR 0025).
 *
 * O endereço e a chave vêm do próprio <body> (data-sb-url, data-sb-chave). A
 * chave é a publicável: o que ela deixa fazer decide-o o RLS, não quem a tem. */
(function () {
  "use strict";

  var PADRAO_PERIGOSO =
    /<\/?[a-z!][^>]*>|<\s*script|javascript:|vbscript:|on[a-z]+\s*=|data:text\/html|srcdoc\s*=|\{\{[\s\S]*\}\}|<%[\s\S]*%>/i;
  var EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  var MAX = 4000;
  var SESSAO = "empire.painel.sessao";
  var memoria = null, lida = false, geracao = 0, renovacao = null;

  function contemCodigo(texto) {
    return PADRAO_PERIGOSO.test(texto || "");
  }

  function sanitizar(texto) {
    var semTags = String(texto || "").replace(/<\/?[a-z!][^>]*>/gi, "");
    var limpo = "";
    for (var i = 0; i < semTags.length; i++) {
      var c = semTags.charCodeAt(i);
      if (c < 0x20 && c !== 0x09 && c !== 0x0a && c !== 0x0d) continue;
      if (c === 0x7f || c === 0x200b || c === 0x200c || c === 0x200d || c === 0x2060 || c === 0xfeff) continue;
      limpo += semTags[i];
    }
    return limpo.trim();
  }

  function emailValido(email) {
    return !email || !email.trim() || EMAIL.test(email.trim());
  }

  function config() {
    var b = document.body;
    return { url: b.getAttribute("data-sb-url"), chave: b.getAttribute("data-sb-chave") };
  }

  function lerSessao() {
    if (!lida) {
      try { memoria = JSON.parse(sessionStorage.getItem(SESSAO) || "null"); } catch (e) { memoria = null; }
      lida = true;
    }
    return memoria;
  }

  function guardarSessao(s) {
    memoria = s; lida = true;
    try {
      if (s) sessionStorage.setItem(SESSAO, JSON.stringify(s));
      else sessionStorage.removeItem(SESSAO);
    } catch (e) { /* sem armazenamento: a sessão vive só nesta página */ }
  }

  function limpar() { geracao++; guardarSessao(null); }

  /* Sair fecha a sessão aqui e revoga-a no Supabase (scope=local: só esta). A
   * limpeza local vem primeiro, para nenhuma renovação em curso a ressuscitar; a
   * revogação leva o token que havia. Um access token já emitido vale até expirar
   * (é o Supabase), mas o refresh deixa de renovar. Nunca rejeita: devolve
   * {remoto} a dizer se o servidor confirmou (BUG-05). */
  function sair() {
    var s = lerSessao();
    limpar();
    if (!s || !s.token) return Promise.resolve({ remoto: false });
    var revogar = function (token) {
      return enviar("/auth/v1/logout?scope=local", { metodo: "POST" }, token);
    };
    // Com o token vencido o Auth responde 403 (bad_jwt), e não 401: renova-se uma vez
    // só para revogar, antes ou depois de uma recusa.
    var renovarERevogar = function () {
      if (!s.refresh) return Promise.reject(new Error("sem refresh"));
      return enviar("/auth/v1/token?grant_type=refresh_token", { metodo: "POST", corpo: { refresh_token: s.refresh } })
        .then(function (d) { return revogar(d && d.access_token); });
    };
    var vencido = s.expira && s.expira <= Date.now() + 60000;
    var pedido = vencido ? renovarERevogar() : revogar(s.token).catch(function (e) {
      if (e.estado !== 401 && e.estado !== 403) throw e;
      return renovarERevogar();
    });
    return pedido.then(function () { return { remoto: true }; }, function () { return { remoto: false }; });
  }

  function expirada() {
    var s = lerSessao();
    limpar();
    var erro = new Error("A tua sessão de acesso terminou. Entra novamente para guardar; a resposta continua no formulário.");
    erro.sessaoExpirada = true;
    window.dispatchEvent(new CustomEvent("empire:sessao-expirada", { detail: { email: s && s.email } }));
    return erro;
  }

  function guardarTokens(d, anterior) {
    if (!d || !d.access_token || !d.refresh_token) throw new Error("O servidor não confirmou a renovação da sessão.");
    var s = { token: d.access_token, refresh: d.refresh_token, email: d.user && d.user.email || anterior && anterior.email,
      expira: d.expires_at ? d.expires_at * 1000 : Date.now() + d.expires_in * 1000 };
    guardarSessao(s);
    return s;
  }

  function enviar(caminho, opcoes, token) {
    var c = config();
    var cab = { apikey: c.chave, "Content-Type": "application/json" };
    cab.Authorization = "Bearer " + (token || c.chave);
    var o = opcoes || {};
    for (var k in o.cabecalhos || {}) cab[k] = o.cabecalhos[k];
    return fetch(c.url + caminho, {
      method: o.metodo || "GET",
      headers: cab,
      body: o.corpo === undefined ? undefined : JSON.stringify(o.corpo),
    }).then(function (r) {
      if (r.status === 204) return null;
      return r.text().then(function (t) {
        var dados = t ? JSON.parse(t) : null;
        if (!r.ok) {
          var msg = (dados && (dados.message || dados.error_description || dados.msg)) || ("HTTP " + r.status);
          var erro = new Error(msg);
          erro.estado = r.status;
          throw erro;
        }
        return dados;
      });
    });
  }

  // O refresh roda os dois tokens. Uma única promessa evita gastá-lo em paralelo.
  function renovar(s) {
    if (renovacao) return renovacao;
    if (!s || !s.refresh) return Promise.reject(expirada());
    var inicio = geracao;
    renovacao = enviar("/auth/v1/token?grant_type=refresh_token", {
      metodo: "POST", corpo: { refresh_token: s.refresh },
    }).then(function (d) {
      if (inicio !== geracao) throw new Error("A sessão mudou. Entra novamente.");
      return guardarTokens(d, s);
    }).catch(function (e) {
      if (inicio !== geracao) throw e;
      if ([400, 401, 403].includes(e.estado)) throw expirada();
      throw new Error("Não foi possível renovar o acesso. Verifica a ligação e tenta guardar novamente.");
    }).finally(function () { renovacao = null; });
    return renovacao;
  }

  function acesso() {
    var s = lerSessao();
    if (!s || !s.token) return Promise.reject(expirada());
    return s.expira && s.expira <= Date.now() + 60000 ? renovar(s) : Promise.resolve(s);
  }

  // Só um 401 pode repetir a operação: a escrita foi recusada antes de executar.
  // Uma falha de rede não repete escritas cujo resultado é desconhecido.
  function pedir(caminho, opcoes) {
    if (opcoes && opcoes.publico) return enviar(caminho, opcoes);
    return acesso().then(function (s) {
      return enviar(caminho, opcoes, s.token).catch(function (e) {
        if (e.estado !== 401) throw e;
        var atual = lerSessao();
        if (!atual) throw expirada();
        var proxima = atual.token !== s.token ? Promise.resolve(atual) : renovar(atual);
        return proxima.then(function (nova) {
          return enviar(caminho, opcoes, nova.token).catch(function (erro) {
            if (erro.estado === 401) throw expirada();
            throw erro;
          });
        });
      });
    });
  }

  /** Envia um reporte. Devolve {erro} se não o puder enviar — nunca rejeita. */
  function enviarReporte(e, textos) {
    if (contemCodigo(e.mensagem) || contemCodigo(e.assunto)) return Promise.resolve({ erro: textos.codigo });
    if (!emailValido(e.email)) return Promise.resolve({ erro: textos.email });
    var mensagem = sanitizar(e.mensagem);
    if (!mensagem) return Promise.resolve({ erro: textos.vazio });
    if (mensagem.length > MAX) return Promise.resolve({ erro: textos.longo });
    var nulo = function (v) { v = sanitizar(v); return v ? v : null; };
    return pedir("/rest/v1/empire_feedback", {
      metodo: "POST", publico: true,
      // Quem envia não lê a tabela (RLS): pedir a linha de volta falhava.
      cabecalhos: { Prefer: "return=minimal" },
      corpo: {
        tipo: e.tipo, mensagem: mensagem, assunto: nulo(e.assunto), area: nulo(e.area),
        nome: nulo(e.nome), email: nulo(e.email), versao: nulo(e.versao),
      },
    }).then(function () { return {}; }, function (x) { return { erro: textos.falhou + " (" + x.message + ")" }; });
  }

  /** Entra com email e palavra-passe — uma conta que esteja em empire_admins. */
  function entrar(email, senha) {
    var inicio = ++geracao;
    return enviar("/auth/v1/token?grant_type=password", { metodo: "POST", corpo: { email: email, password: senha } })
      .then(function (d) {
        if (inicio !== geracao) throw new Error("A sessão mudou. Entra novamente.");
        guardarTokens(d);
        return pedir("/rest/v1/rpc/empire_e_admin", { metodo: "POST", corpo: {} });
      })
      .then(function (admin) {
        if (admin !== true) { sair(); throw new Error("Esta conta não é de administração."); }
        return lerSessao();
      });
  }

  function sessao() {
    return lerSessao();
  }

  window.EmpireMotor = {
    contemCodigo: contemCodigo, sanitizar: sanitizar, emailValido: emailValido, MAX: MAX,
    enviarReporte: enviarReporte, entrar: entrar, sessao: sessao,
    sair: sair,
    pedir: pedir,
  };
})();
