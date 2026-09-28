/* Uma decisão de cada vez. Rascunhos vivem no formulário até guardar. */
(function () {
  "use strict";
  var M = window.EmpireMotor, $ = function (id) { return document.getElementById(id); };
  if (!M) return;
  var todas = Array.from(document.querySelectorAll("article.pergunta"));
  var botoes = Array.from(document.querySelectorAll(".fila-item"));
  var respostas = {}, visiveis = [], atual = null, pronto = false, sujas = new Set(), retomar = null;
  function dizer(el, texto, tipo) { el.textContent = texto; el.className = "p-guardado " + (tipo || ""); }
  function estado(a) {
    if (a.dataset.tipo === "encerrada") return "encerrada";
    var r = respostas[a.id];
    return !r ? "por" : r.estado === "aplicada" ? "aplicada" : r.escolha === "adiar" ? "adiada" : "respondida";
  }
  var rotulos = { por: "Por decidir", aplicada: "Aplicada", adiada: "Adiada", respondida: "À espera de implementação", encerrada: "Encerrada no projeto" };
  function pintar(a, preencher) {
    var r = respostas[a.id], e = estado(a), b = botoes.find(b => b.dataset.pergunta === a.id);
    a.dataset.estado = e;
    a.querySelector(".p-estado").textContent = pronto ? rotulos[e] : "A carregar resposta…";
    b.querySelector(".fila-estado").textContent = pronto ? rotulos[e] : "A carregar";
    var f = a.querySelector("form");
    if (!f || !preencher) return;
    f.querySelectorAll("input[type=radio]").forEach(x => { x.checked = !!r && x.value === r.escolha; });
    f.querySelector("textarea").value = r && r.texto || "";
    if (r && r.escolha === "aprovar" && a.dataset.aprovavel !== "true")
      dizer(a.querySelector(".p-guardado"), "Existe uma aprovação anterior. Revê-a: esta questão tem pontos em aberto.", "aviso");
    recibo(a);
  }
  function contar() {
    var n = { por: 0, respondida: 0, aplicada: 0, adiada: 0, encerrada: 0 };
    todas.forEach(a => { n[estado(a)]++; });
    $("c-por").textContent = n.por;
    $("c-respondidas").textContent = n.respondida;
    $("c-adiadas").textContent = n.adiada;
    $("c-aplicadas").textContent = n.aplicada + n.encerrada;
  }
  function selecionar(id, foco) {
    atual = visiveis.find(a => a.id === id) || visiveis[0] || null;
    todas.forEach(a => { a.hidden = a !== atual; });
    botoes.forEach(b => {
      if (atual && b.dataset.pergunta === atual.id) b.setAttribute("aria-current", "true");
      else b.removeAttribute("aria-current");
    });
    var i = visiveis.indexOf(atual);
    $("posicao").textContent = atual ? (i + 1) + " de " + visiveis.length : "";
    $("anterior").disabled = i <= 0; $("seguinte").disabled = i < 0 || i >= visiveis.length - 1;
    document.querySelector(".decisao-palco").hidden = !atual;
    if (atual && foco) {
      history.replaceState(null, "", "#" + atual.id);
      atual.querySelector("h3").focus({ preventScroll: true });
      atual.scrollIntoView({ block: "start" });
    }
  }
  function filtrar(preferida) {
    var normal = s => s.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
    var txt = normal($("f-texto").value.trim());
    visiveis = todas.filter(a => (!$('f-tipo').value || a.dataset.tipo === $('f-tipo').value)
      && (!$('f-estado').value || estado(a) === $('f-estado').value)
      && (!$('f-grupo').value || a.dataset.grupo === $('f-grupo').value)
      && (!txt || normal(a.textContent).includes(txt)));
    botoes.forEach(b => { b.hidden = !visiveis.some(a => a.id === b.dataset.pergunta); });
    $("sem-resultados").hidden = visiveis.length > 0;
    $("fila-contagem").textContent = visiveis.length + " decisões nesta lista";
    selecionar(preferida || (atual && atual.id), false);
  }
  function recibo(a) {
    var f = a.querySelector("form"), r = f.querySelector("input:checked"), caixa = f.querySelector(".decisao-recibo");
    var outra = r && r.value === "outra";
    f.querySelector("textarea").required = !!outra;
    f.querySelector(".nota-obrigatoria").textContent = outra ? "(obrigatória)" : "(opcional)";
    caixa.hidden = !r;
    if (r) caixa.querySelector("p").textContent = r.value === "aprovar" ? "Aprovar: " + f.querySelector(".objeto-aprovacao").textContent
      : outra ? (f.querySelector("textarea").value.trim() || "Escreve abaixo a regra ou alteração que queres guardar.") : "Adiar esta decisão. Nenhuma proposta será aprovada.";
  }
  function habilitar(valor) {
    todas.forEach(a => a.querySelectorAll("fieldset, textarea, button[type=submit]").forEach(e => { e.disabled = !valor; }));
    $("copiar").disabled = !valor;
  }
  function carregar() {
    pronto = false; habilitar(false); $("recarregar").hidden = true;
    dizer($("lote-estado"), "A carregar respostas…");
    M.pedir("/rest/v1/empire_respostas?select=pergunta,escolha,texto,estado,atualizado_em").then(linhas => {
      respostas = {}; (linhas || []).forEach(r => { respostas[r.pergunta] = r; });
      pronto = true; habilitar(true); todas.forEach(a => pintar(a, !sujas.has(a.id))); contar();
      var id = retomar || location.hash.slice(1);
      if (todas.some(a => a.id === id)) $("f-estado").value = "";
      filtrar(id); dizer($("lote-estado"), "Respostas atualizadas. Escolhe uma decisão para começar.");
      if (retomar) {
        retomar = null; selecionar(id, true);
        dizer($("lote-estado"), "Sessão recuperada. As alterações por guardar continuam aqui. Revê a resposta e carrega em Guardar decisão.");
      }
    }, e => { dizer($("lote-estado"), "Não foi possível ler as respostas. Tenta novamente antes de editar. " + e.message, "erro"); $("recarregar").hidden = false; });
  }
  function abrir() {
    $("entrar").hidden = true; $("entrar-ajuda").hidden = true; $("area").hidden = false;
    $("sessao").textContent = "Sessão de administração · " + (M.sessao()?.email || "Empire"); carregar();
  }
  window.addEventListener("empire:sessao-expirada", ev => {
    pronto = false; habilitar(false);
    if (!$("perguntas").hidden) retomar = atual && atual.id;
    $("area").hidden = true; $("entrar").hidden = false; $("entrar-ajuda").hidden = false;
    $("entrar-t").textContent = "Entrar novamente";
    if (ev.detail?.email) $("en-email").value = ev.detail.email;
    $("en-senha").value = "";
    dizer($("entrar-estado"), "A sessão de acesso terminou. Confirma a tua palavra-passe para continuar.", "aviso");
    $("en-senha").focus(); $("entrar").scrollIntoView({ block: "center" });
  });
  $("entrar-form").addEventListener("submit", ev => {
    ev.preventDefault(); var b = ev.target.querySelector("button"); b.disabled = true;
    dizer($("entrar-estado"), "A entrar…");
    M.entrar($("en-email").value.trim(), $("en-senha").value).then(() => { $("en-senha").value = ""; abrir(); },
      e => dizer($("entrar-estado"), "Não foi possível entrar: " + e.message, "erro")).finally(() => { b.disabled = false; });
  });
  $("sair").addEventListener("click", () => {
    if (sujas.size) return dizer($("lote-estado"), "Tens decisões por guardar. Guarda-as antes de sair ou recarrega a página para as descartar.", "aviso");
    M.sair(); location.reload();
  });
  function separador(qual) {
    ["perguntas", "reportes"].forEach(s => { $("tab-" + s).setAttribute("aria-selected", String(s === qual)); $("tab-" + s).tabIndex = s === qual ? 0 : -1; $(s).hidden = s !== qual; });
    if (qual === "reportes") window.EmpireReportes.carregar();
  }
  ["perguntas", "reportes"].forEach(s => {
    $("tab-" + s).addEventListener("click", () => separador(s));
    $("tab-" + s).addEventListener("keydown", ev => {
      if (!["ArrowLeft", "ArrowRight", "Home", "End"].includes(ev.key)) return;
      ev.preventDefault(); var proximo = ev.key === "Home" ? "perguntas" : ev.key === "End" ? "reportes" : s === "perguntas" ? "reportes" : "perguntas";
      separador(proximo); $("tab-" + proximo).focus();
    });
  });
  ["f-texto", "f-tipo", "f-estado", "f-grupo"].forEach(id => $(id).addEventListener(id === "f-texto" ? "input" : "change", () => filtrar()));
  $("limpar-filtros").addEventListener("click", () => { ["f-texto", "f-tipo", "f-estado", "f-grupo"].forEach(id => { $(id).value = ""; }); filtrar(); });
  botoes.forEach(b => b.addEventListener("click", () => selecionar(b.dataset.pergunta, true)));
  $("anterior").addEventListener("click", () => selecionar(visiveis[visiveis.indexOf(atual) - 1]?.id, true));
  $("seguinte").addEventListener("click", () => selecionar(visiveis[visiveis.indexOf(atual) + 1]?.id, true));
  $("recarregar").addEventListener("click", carregar);
  todas.forEach(a => {
    var f = a.querySelector("form"); if (!f) return;
    f.addEventListener("input", () => { sujas.add(a.id); recibo(a); dizer(a.querySelector(".p-guardado"), "Alterações por guardar."); });
    f.addEventListener("submit", ev => {
      ev.preventDefault(); if (!pronto || f.dataset.enviando) return;
      var r = f.querySelector("input:checked"), nota = f.querySelector("textarea").value, aviso = a.querySelector(".p-guardado");
      if (!r) return dizer(aviso, "Escolhe como queres responder.", "erro");
      if (r.value === "aprovar" && a.dataset.aprovavel !== "true") return;
      if (M.contemCodigo(nota)) return dizer(aviso, "Escreve a decisão sem código HTML.", "erro");
      var texto = M.sanitizar(nota);
      if (r.value === "outra" && !texto) return dizer(aviso, "Escreve a tua decisão.", "erro");
      f.dataset.enviando = "true"; f.querySelectorAll("fieldset, textarea, button").forEach(e => { e.disabled = true; });
      dizer(aviso, "A guardar…");
      M.pedir("/rest/v1/empire_respostas?on_conflict=pergunta", { metodo: "POST", cabecalhos: { Prefer: "resolution=merge-duplicates,return=representation" },
        corpo: [{ pergunta: a.id, escolha: r.value, texto: texto || null, titulo: a.dataset.titulo.slice(0, 300), estado: "nova" }],
      }).then(gravadas => {
        if (!gravadas?.some(x => x.pergunta === a.id)) throw new Error("O servidor não confirmou a resposta.");
        gravadas.forEach(x => { respostas[x.pergunta] = x; }); sujas.delete(a.id); pintar(a, false); contar();
        dizer(aviso, r.value === "adiar" ? "Adiada. Podes retomá-la no filtro «Adiadas»." : "Decisão guardada. Aguarda implementação no jogo.", "feito");
      }).catch(e => dizer(aviso, "Não foi guardada. A tua resposta continua aqui. " + e.message, "erro"))
        .finally(() => { delete f.dataset.enviando; f.querySelectorAll("fieldset, textarea, button").forEach(e => { e.disabled = !pronto; }); });
    });
  });
  $("copiar").addEventListener("click", () => {
    var linhas = ["# Decisões do Empire", ""];
    todas.forEach(a => { var r = respostas[a.id]; if (!r) return;
      linhas.push("## " + a.id + " · " + a.dataset.titulo, "Escolha: " + r.escolha + " · Estado: " + r.estado);
      var objeto = a.querySelector(".objeto-aprovacao");
      if (r.escolha === "aprovar") linhas.push("Proposta na versão consultada (conferir antes de aplicar): " + (objeto?.textContent || "Consultar a fonte; questão encerrada ou alterada."));
      if (r.texto) linhas.push("Resposta: " + r.texto); linhas.push("");
    });
    var md = linhas.join("\n");
    if (!navigator.clipboard) return dizer($("lote-estado"), "O navegador não permite copiar nesta ligação.", "erro");
    navigator.clipboard.writeText(md).then(() => dizer($("lote-estado"), "Decisões copiadas.", "feito"), () => dizer($("lote-estado"), "Não foi possível copiar. Permite o acesso à área de transferência.", "erro"));
  });
  window.addEventListener("beforeunload", ev => { if (sujas.size) { ev.preventDefault(); ev.returnValue = ""; } });
  if (!document.body.dataset.sbUrl) { $("entrar-desligado").hidden = false; $("entrar-form").hidden = true; return; }
  if (M.sessao()) M.pedir("/rest/v1/rpc/empire_e_admin", { metodo: "POST", corpo: {} }).then(admin => {
    if (admin === true) abrir(); else M.sair();
  }, e => { if (!e.sessaoExpirada) dizer($("entrar-estado"), "Não foi possível confirmar o acesso. Verifica a ligação e tenta entrar novamente.", "erro"); });
})();
