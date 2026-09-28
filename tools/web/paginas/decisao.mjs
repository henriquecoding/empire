// A ficha é gerada da mesma fonte que a fila; a aprovação nunca fica sem objeto.
import { esc } from './molde.mjs';
export const TIPOS = { confirmar: 'Rever decisão', escolher: 'Avaliar proposta', decidir: 'Precisa da tua decisão', encerrada: 'Encerrada no projeto' };
const bloco = (titulo, texto, classe = '') => texto ? `<section class="decisao-bloco ${classe}"><h4>${titulo}</h4><p>${esc(texto.replace(/[`*]/g, ''))}</p></section>` : '';

export function cartaoPergunta(q) {
  const objeto = q.proposta.replace(/[`*]/g, '');
  const encerrada = q.tipo === 'encerrada';
  return `<article class="pergunta" id="${q.id}" data-id="${q.id}" data-tipo="${q.tipo}" data-grupo="${esc(q.grupo)}" data-titulo="${esc(q.titulo)}" data-aprovavel="${q.aprovavel}" hidden>
    <header class="decisao-cabeca">
      <p class="p-meta"><span class="p-id">${q.id}</span><span class="chip chip-${q.tipo}">${TIPOS[q.tipo]}</span><span class="p-estado">A carregar resposta…</span></p>
      <h3 tabindex="-1">${esc(q.titulo)}</h3><p class="p-grupo">${esc(q.grupo)}</p>
    </header>
    <div class="decisao-conteudo">
      ${bloco('O que está em causa', q.resumo || q.contexto)}
      ${q.decisao && q.pendencia ? bloco('O que já foi decidido', q.decisao) : ''}
      ${bloco('O que falta decidir', q.pendencia, 'pendencia')}
      ${bloco(encerrada ? 'Decisão registada' : q.tipo === 'confirmar' ? 'Decisão provisória para rever' : 'Proposta em análise', q.proposta, 'proposta')}
      ${bloco('Na prática', q.impacto)}
      ${bloco('O que depende disto', q.bloqueio)}
      ${!q.aprovavel && !encerrada ? '<p class="sem-proposta">Esta questão ainda não tem uma proposta única que possas aprovar. Escreve a tua decisão ou deixa-a para mais tarde.</p>' : ''}
      ${q.alerta ? `<p class="sem-proposta">${esc(q.alerta)}</p>` : ''}
      <details class="fontes-decisao"><summary>Consultar contexto completo e fontes</summary>
        <div class="p-corpo">${q.html}</div>
        <nav aria-label="Fontes de ${q.id}"><a href="${q.fonte}" target="_blank" rel="noopener">Pergunta no repositório ↗</a>
        ${q.seccoes.map(n => `<a href="/dossie/#s${n}" target="_blank" rel="noopener">Dossiê §${n} ↗</a>`).join('')}</nav>
      </details>
    </div>
    ${encerrada ? '<p class="decisao-fim">Esta questão já foi encerrada no repositório. Está aqui para consulta; não precisa de nova aprovação.</p>' : `
    <form class="resposta" data-id="${q.id}">
      <fieldset disabled><legend>A tua decisão</legend>
        ${q.aprovavel ? `<label class="escolha"><input type="radio" name="e-${q.id}" value="aprovar"><span><strong>${q.tipo === 'confirmar' ? 'Confirmar esta decisão' : 'Aprovar esta proposta'}</strong><small>Aprovas o texto completo apresentado acima.</small></span></label>` : ''}
        <label class="escolha"><input type="radio" name="e-${q.id}" value="outra"><span><strong>${q.aprovavel ? 'Propor uma alteração' : 'Escrever a minha decisão'}</strong><small>Explica a regra ou alternativa que queres adotar.</small></span></label>
        <label class="escolha"><input type="radio" name="e-${q.id}" value="adiar"><span><strong>Decidir mais tarde</strong><small>Fica na lista «Adiadas», sem aprovar alterações.</small></span></label>
      </fieldset>
      <label class="campo"><span>Nota ou decisão <span class="nota-obrigatoria">(opcional)</span></span><textarea name="texto" rows="3" maxlength="4000" disabled placeholder="Que comportamento queres no jogo? O que deve mudar?"></textarea></label>
      <div class="decisao-recibo" hidden><strong>Vais guardar</strong><p></p></div>
      <p class="decisao-ajuda">Guardar regista a tua resposta. A alteração só chega ao jogo depois de ser implementada e publicada.</p>
      <div class="accoes"><button class="botao principal" type="submit" disabled>Guardar decisão</button><span class="p-guardado" role="status" aria-live="polite"></span></div>
      <span class="objeto-aprovacao" hidden>${esc(objeto)}</span>
    </form>`}
  </article>`;
}

export function filaPergunta(q) {
  return `<button class="fila-item" type="button" data-pergunta="${q.id}" aria-controls="${q.id}"><span class="fila-meta"><span>${q.id}</span><span class="fila-estado">${q.tipo === 'encerrada' ? 'Encerrada' : 'A carregar'}</span></span><strong>${esc(q.titulo)}</strong><span class="fila-tipo">${TIPOS[q.tipo]}</span></button>`;
}
