/* tools/web/paginas/reportar.js — o formulário de /reportar/ e /en/report/ (ADR 0026).
 * Os textos vêm do próprio HTML (data-*), nas duas línguas; o envio é o do motor. */
(function () {
  "use strict";
  var M = window.EmpireMotor;
  var form = document.getElementById("reportar");
  if (!form || !M) return;
  var $ = function (id) { return document.getElementById(id); };
  var estado = $("r-estado");
  var enviar = $("r-enviar");
  var outro = $("r-outro");
  var msg = $("r-mensagem");
  var contador = $("r-contador");
  var unidade = contador.textContent.replace(/^[0-9]+ \/ [0-9]+ /, "");
  var d = form.dataset;
  var textos = { codigo: d.erroCodigo, email: d.erroEmail, vazio: d.erroVazio, longo: d.erroLongo, falhou: d.erroFalhou };

  function dizer(texto, tipo) {
    estado.textContent = texto;
    estado.className = "estado-envio" + (tipo ? " " + tipo : "");
  }

  if (!document.body.getAttribute("data-sb-url")) {
    enviar.disabled = true;
    dizer(d.desligado, "aviso");
    return;
  }

  msg.addEventListener("input", function () {
    contador.textContent = msg.value.length + " / " + M.MAX + " " + unidade;
    contador.classList.toggle("perto", msg.value.length > M.MAX * 0.9);
  });

  form.addEventListener("submit", function (ev) {
    ev.preventDefault();
    if (enviar.disabled || enviar.hidden) return;
    form.querySelectorAll('[aria-invalid="true"]').forEach(function (campo) {
      campo.removeAttribute("aria-invalid");
      campo.setAttribute("aria-describedby", (campo.getAttribute("aria-describedby") || "").replace(/\s*r-estado/g, ""));
    });
    var tipo = form.querySelector("input[name=tipo]:checked");
    enviar.disabled = true;
    form.setAttribute("aria-busy", "true");
    dizer(d.enviando, "");
    M.enviarReporte({
      tipo: tipo ? tipo.value : "sugestao",
      mensagem: msg.value,
      assunto: $("r-assunto").value,
      area: $("r-area").value + " · " + location.pathname,
      nome: $("r-nome").value,
      email: $("r-email").value,
      versao: d.versao,
    }, textos).then(function (r) {
      if (r.erro) {
        enviar.disabled = false;
        dizer(r.erro, "erro");
        var campo = r.campo && $(r.campo);
        if (campo) {
          campo.setAttribute("aria-invalid", "true");
          campo.setAttribute("aria-describedby", ((campo.getAttribute("aria-describedby") || "") + " r-estado").trim());
          campo.focus();
        }
        return;
      }
      form.reset();
      contador.textContent = "0 / " + M.MAX + " " + unidade;
      dizer(d.enviado, "feito");
      enviar.hidden = true;
      outro.hidden = false;
      outro.focus();
    }).finally(function () { form.setAttribute("aria-busy", "false"); });
  });

  outro.addEventListener("click", function () {
    outro.hidden = true;
    enviar.hidden = false;
    enviar.disabled = false;
    dizer("", "");
    msg.focus();
  });
})();
