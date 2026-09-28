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
    try { return JSON.parse(sessionStorage.getItem(SESSAO) || "null"); } catch (e) { return null; }
  }

  function guardarSessao(s) {
    try {
      if (s) sessionStorage.setItem(SESSAO, JSON.stringify(s));
      else sessionStorage.removeItem(SESSAO);
    } catch (e) { /* sem armazenamento: a sessão vive só nesta página */ }
  }

  // Um pedido ao Supabase. Com sessão, vai com o token de quem entrou — é esse
  // o `auth.uid()` que o is_admin() lê; sem ela, vai como anon.
  function pedir(caminho, opcoes) {
    var c = config();
    var s = lerSessao();
    var cab = { apikey: c.chave, "Content-Type": "application/json" };
    cab.Authorization = "Bearer " + (s && s.token ? s.token : c.chave);
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

  /** Envia um reporte. Devolve {erro} se não o puder enviar — nunca rejeita. */
  function enviarReporte(e, textos) {
    if (contemCodigo(e.mensagem) || contemCodigo(e.assunto)) return Promise.resolve({ erro: textos.codigo });
    if (!emailValido(e.email)) return Promise.resolve({ erro: textos.email });
    var mensagem = sanitizar(e.mensagem);
    if (!mensagem) return Promise.resolve({ erro: textos.vazio });
    if (mensagem.length > MAX) return Promise.resolve({ erro: textos.longo });
    var nulo = function (v) { v = sanitizar(v); return v ? v : null; };
    return pedir("/rest/v1/empire_feedback", {
      metodo: "POST",
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
    return pedir("/auth/v1/token?grant_type=password", { metodo: "POST", corpo: { email: email, password: senha } })
      .then(function (d) {
        guardarSessao({ token: d.access_token, email: d.user && d.user.email, expira: Date.now() + d.expires_in * 1000 });
        return pedir("/rest/v1/rpc/empire_e_admin", { metodo: "POST", corpo: {} });
      })
      .then(function (admin) {
        if (admin !== true) { guardarSessao(null); throw new Error("Esta conta não é de administração."); }
        return lerSessao();
      });
  }

  function sessao() {
    var s = lerSessao();
    if (s && s.expira && s.expira < Date.now()) { guardarSessao(null); return null; }
    return s;
  }

  window.EmpireMotor = {
    contemCodigo: contemCodigo, sanitizar: sanitizar, emailValido: emailValido, MAX: MAX,
    enviarReporte: enviarReporte, entrar: entrar, sessao: sessao,
    sair: function () { guardarSessao(null); },
    pedir: pedir,
  };
})();
