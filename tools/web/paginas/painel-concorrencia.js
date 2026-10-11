/* Uma escrita só substitui a revisão que a pessoa leu. */
(function () {
  'use strict';
  var M = window.EmpireMotor, pendentes = 0;
  function escrever(tabela, chave, id, base, corpo, apagar) {
    var existe = Number(base) > 0;
    var path = '/rest/v1/' + tabela;
    if (existe || apagar) path += '?' + chave + '=eq.' + encodeURIComponent(id) + '&revisao=eq.' + Number(base || 0);
    else path += '?on_conflict=' + chave;
    pendentes++;
    return M.pedir(path, { metodo: apagar ? 'DELETE' : existe ? 'PATCH' : 'POST',
      cabecalhos: { Prefer: (existe || apagar ? '' : 'resolution=ignore-duplicates,') + 'return=representation' },
      ...(apagar ? {} : { corpo: existe ? corpo : [{ ...corpo, [chave]: id }] }),
    }).then(linhas => {
      if (!linhas?.some(x => x[chave] === id)) {
        var e = new Error('O servidor não confirmou a alteração: a versão guardada mudou. Carrega-a para rever antes de substituir.');
        e.conflito = true; throw e;
      }
      return linhas;
    }).finally(() => { pendentes--; });
  }
  function rever(form, tabela, chave, id, receber, aviso) {
    var b = form.querySelector('.rever-conflito');
    if (b) return;
    b = document.createElement('button'); b.type = 'button'; b.className = 'botao rever-conflito';
    b.textContent = 'Carregar versão guardada para rever'; form.querySelector('.accoes').appendChild(b);
    b.addEventListener('click', () => {
      b.disabled = true;
      M.pedir('/rest/v1/' + tabela + '?' + chave + '=eq.' + encodeURIComponent(id) + '&select=*').then(linhas => {
        var detalhe = receber(linhas?.[0] || null);
        if (detalhe === false) return;
        b.remove();
        aviso.textContent = (typeof detalhe === 'string' ? detalhe + '\n' : '') +
          'Versão guardada carregada. Compara-a com o teu rascunho; Guardar irá substituir essa versão.';
      }).catch(e => { aviso.textContent = e.message; b.disabled = false; });
    });
  }
  window.EmpireConcorrencia = { escrever, rever, pendente: () => pendentes > 0 };
})();
