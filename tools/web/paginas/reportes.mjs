// tools/web/paginas/reportes.mjs — o formulário de reportes e o painel do dono (ADR 0026).
//
// Duas páginas, com a cabeça, o topo e o rodapé das outras (molde.mjs):
//
//   /reportar/ · /en/report/   qualquer pessoa envia um reporte, uma sugestão ou
//                              uma dúvida — nas duas línguas, como o resto
//   /painel/                   o dono entra e responde às perguntas do
//                              QUESTIONS.md e trata os reportes — só em
//                              português, fora do mapa do site e dos motores
//
// São as únicas páginas do site que podem falar com outra origem, e só com o
// Supabase do Empire: a CSP delas acrescenta-o ao `connect-src`, e nada corre
// antes de a pessoa carregar num botão. Sem o endereço e a chave configurados,
// as páginas publicam-se na mesma e dizem que o envio não está ligado.

import { cabeca, topo, rodape, esc, CSP } from "./molde.mjs";

const cspCom = (url) => (url ? CSP.replace("connect-src 'self'", `connect-src 'self' ${url}`) : CSP);

const corpoSb = (sb) => (sb.url ? ` data-sb-url="${esc(sb.url)}" data-sb-chave="${esc(sb.chave)}"` : "");

export function reportar({ t, d, v, sb, robots }) {
  const r = t.reportar;
  const outra = t.lingua === "pt-PT" ? "/en/report/" : "/reportar/";
  const cab = cabeca({
    t, v, titulo: r.titulo, descricao: r.descricao, robots,
    canonico: d.url ? `${d.url}${t.caminho}${r.caminho}` : "",
    alternativas: d.url ? [["pt-PT", `${d.url}/reportar/`], ["en", `${d.url}/en/report/`]] : [],
    csp: cspCom(sb.url),
    extra: `<script src="${v.motor}" defer></script>\n<script src="${v.reportar}" defer></script>\n`,
  });
  const tipos = r.tipos.map(([id, nome, desc], i) => `
        <label class="escolha"><input type="radio" name="tipo" value="${id}"${i === 0 ? " checked" : ""}><span><strong>${nome}</strong><small>${desc}</small></span></label>`).join("");
  const ondes = r.ondes.map(([id, nome]) => `<option value="${id}">${nome}</option>`).join("");
  const erros = Object.entries(r.erros).map(([k, x]) => ` data-erro-${k}="${esc(x)}"`).join("");
  return `${cab}
<body class="pagina-reportar"${corpoSb(sb)}>
${topo({ t, v, ancoras: false })}
<main id="conteudo" class="reportar">
  <div class="envolve reportar-grelha">
    <div class="reportar-lado">
      <p class="kicker"><span>${r.kicker}</span></p>
      <h1>${r.h1}</h1>
      <p class="reportar-intro">${r.intro}</p>
      <p class="reportar-guarda">${r.guarda}</p>
      <p class="reportar-lingua"><a href="${outra}" hreflang="${t.nav.outra.lingua}" lang="${t.nav.outra.lingua}">${t.nav.outra.titulo}</a></p>
    </div>
    <form class="reportar-form" id="reportar" novalidate data-versao="${esc(d.sha.slice(0, 12))}"
      data-enviando="${esc(r.enviando)}" data-enviado="${esc(r.enviado)}" data-desligado="${esc(r.desligado)}"${erros}>
      <fieldset class="tipos">
        <legend>${r.tipo}</legend>${tipos}
      </fieldset>
      <div class="campos-2">
        <label class="campo"><span>${r.onde}</span><select id="r-area" name="area">${ondes}</select></label>
        <label class="campo"><span>${r.assunto}</span><input id="r-assunto" name="assunto" type="text" maxlength="160" autocomplete="off"></label>
      </div>
      <label class="campo"><span>${r.mensagem}</span>
        <textarea id="r-mensagem" name="mensagem" rows="7" maxlength="4000" required aria-describedby="r-ajuda"></textarea>
        <small id="r-ajuda">${r.ajuda_msg} <span class="contador" id="r-contador">0 / 4000 ${r.caracteres}</span></small>
      </label>
      <div class="campos-2">
        <label class="campo"><span>${r.nome}</span><input id="r-nome" name="nome" type="text" maxlength="80" autocomplete="name"></label>
        <label class="campo"><span>${r.email}</span><input id="r-email" name="email" type="email" maxlength="254" autocomplete="email" aria-describedby="r-ajuda-email">
          <small id="r-ajuda-email">${r.ajuda_email}</small></label>
      </div>
      <p class="estado-envio" id="r-estado" role="status" aria-live="polite"></p>
      <div class="accoes">
        <button class="botao principal" id="r-enviar" type="submit">${r.enviar}</button>
        <button class="botao" id="r-outro" type="button" hidden>${r.outro}</button>
      </div>
    </form>
  </div>
</main>
${rodape({ t, d, v })}
</body>
</html>
`;
}

const TIPO = {
  confirmar: ["Confirmar", "Já há uma decisão provisória: aprova-a ou muda-a."],
  escolher: ["Escolher", "Há uma proposta ou recomendação, e alguma parte por decidir."],
  decidir: ["Decidir", "Não há proposta: a resposta é tua."],
};

function cartaoPergunta(q) {
  const [rot, dica] = TIPO[q.tipo];
  const aprovar = q.proposta ? `Aprovar: ${esc(q.proposta.length > 220 ? q.proposta.slice(0, 217) + "…" : q.proposta)}` : "Aprovar como está";
  return `
    <article class="pergunta" id="${q.id}" data-id="${q.id}" data-tipo="${q.tipo}" data-grupo="${esc(q.grupo)}" data-titulo="${esc(q.titulo)}">
      <header>
        <p class="p-meta"><span class="p-id">${q.id}</span><span class="chip chip-${q.tipo}" title="${dica}">${rot}</span><span class="p-grupo">${esc(q.grupo)}</span><span class="p-estado" data-estado="por">Por responder</span></p>
        <h3>${esc(q.titulo)}</h3>
      </header>
      <details><summary>O texto da pergunta</summary><div class="p-corpo">${q.html}</div></details>
      <form class="resposta" data-id="${q.id}">
        <fieldset>
          <legend class="sr">A tua resposta a ${q.id}</legend>
          <label class="escolha"><input type="radio" name="e-${q.id}" value="aprovar"><span>${aprovar}</span></label>
          <label class="escolha"><input type="radio" name="e-${q.id}" value="outra"><span>Outra resposta</span></label>
          <label class="escolha"><input type="radio" name="e-${q.id}" value="adiar"><span>Adiar</span></label>
        </fieldset>
        <label class="campo"><span>Nota ou resposta (obrigatória em «Outra resposta»)</span>
          <textarea name="texto" rows="3" maxlength="4000"></textarea></label>
        <div class="accoes"><button class="botao principal" type="submit">Guardar</button><span class="p-guardado" role="status" aria-live="polite"></span></div>
      </form>
    </article>`;
}

export function painel({ textos, d, v, sb, perguntas }) {
  const t = textos.pt;
  const grupos = [...new Set(perguntas.map((q) => q.grupo))];
  const cab = cabeca({
    t, v, titulo: "Painel · Empire", descricao: "As perguntas do QUESTIONS.md e os reportes, para o dono responder.",
    robots: "noindex, nofollow", canonico: "", alternativas: [], csp: cspCom(sb.url),
    extra: `<script src="${v.motor}" defer></script>\n<script src="${v.painel}" defer></script>\n`,
  });
  const n = (tipo) => perguntas.filter((q) => q.tipo === tipo).length;
  return `${cab}
<body class="pagina-painel"${corpoSb(sb)}>
${topo({ t, v, ancoras: false })}
<main id="conteudo" class="painel">
  <div class="envolve">
    <p class="kicker"><span>Commit ${esc(d.sha.slice(0, 7))} · ${perguntas.length} perguntas à espera</span></p>
    <h1>Painel do dono</h1>
    <p class="painel-intro">As perguntas abertas do <code>docs/QUESTIONS.md</code> e os reportes de quem joga. Cada resposta fica
      guardada no Supabase do Empire; um agente lê-as e aplica-as no repositório, e a pergunta passa a «aplicada».</p>

    <section class="entrar" id="entrar" aria-labelledby="entrar-t">
      <h2 id="entrar-t">Entrar</h2>
      <p id="entrar-desligado" hidden>O Supabase não está configurado nesta publicação: define <code>EMPIRE_SUPABASE_URL</code> e
        <code>EMPIRE_SUPABASE_CHAVE</code> na Vercel (ver <code>tools/web/supabase/</code>).</p>
      <form id="entrar-form" class="entrar-form">
        <label class="campo"><span>Email</span><input id="en-email" type="email" autocomplete="username" required></label>
        <label class="campo"><span>Palavra-passe</span><input id="en-senha" type="password" autocomplete="current-password" required></label>
        <div class="accoes"><button class="botao principal" type="submit">Entrar</button></div>
        <p class="estado-envio" id="entrar-estado" role="status" aria-live="polite"></p>
      </form>
    </section>

    <div id="area" hidden>
      <div class="painel-barra">
        <p id="sessao" class="sessao"></p>
        <div class="separadores" role="tablist">
          <button class="separador" role="tab" id="tab-perguntas" aria-selected="true" aria-controls="perguntas" type="button">Perguntas</button>
          <button class="separador" role="tab" id="tab-reportes" aria-selected="false" aria-controls="reportes" type="button">Reportes</button>
        </div>
        <button class="botao" id="sair" type="button">Sair</button>
      </div>

      <section id="perguntas" role="tabpanel" aria-labelledby="tab-perguntas">
        <div class="resumo" id="resumo">
          <p><strong id="c-total">${perguntas.length}</strong> perguntas</p>
          <p><strong id="c-respondidas">0</strong> respondidas</p>
          <p><strong id="c-por">${perguntas.length}</strong> por responder</p>
          <p><strong id="c-aplicadas">0</strong> aplicadas</p>
        </div>
        <div class="filtros">
          <label class="campo"><span>Procurar</span><input id="f-texto" type="search" placeholder="Q-143, herdeiro, soldo…"></label>
          <label class="campo"><span>Tipo</span><select id="f-tipo">
            <option value="">Todos</option><option value="confirmar">Confirmar (${n("confirmar")})</option>
            <option value="escolher">Escolher (${n("escolher")})</option><option value="decidir">Decidir (${n("decidir")})</option></select></label>
          <label class="campo"><span>Estado</span><select id="f-estado">
            <option value="">Todas</option><option value="por" selected>Por responder</option>
            <option value="respondida">Respondidas</option><option value="aplicada">Aplicadas</option></select></label>
          <label class="campo"><span>Secção</span><select id="f-grupo"><option value="">Todas</option>
            ${grupos.map((g) => `<option>${esc(g)}</option>`).join("")}</select></label>
        </div>
        <div class="lote">
          <button class="botao" id="aprovar-visiveis" type="button">Aprovar as «Confirmar» que estão à vista</button>
          <span id="lote-confirma" hidden>Aprovar <strong id="lote-n">0</strong> de uma vez?
            <button class="botao principal" id="lote-sim" type="button">Sim, aprovar</button>
            <button class="botao" id="lote-nao" type="button">Não</button></span>
          <button class="botao" id="copiar" type="button">Copiar as respostas em markdown</button>
          <span class="p-guardado" id="lote-estado" role="status" aria-live="polite"></span>
        </div>
        <p class="vazio" id="sem-resultados" hidden>Nenhuma pergunta com estes filtros.</p>
        <div class="lista-perguntas">${perguntas.map(cartaoPergunta).join("")}
        </div>
      </section>

      <section id="reportes" role="tabpanel" aria-labelledby="tab-reportes" hidden>
        <div class="filtros">
          <label class="campo"><span>Estado</span><select id="fr-estado">
            <option value="">Todos</option><option value="novo" selected>Novos</option><option value="em_analise">Em análise</option>
            <option value="valido">Válidos</option><option value="resolvido">Resolvidos</option><option value="rejeitado">Rejeitados</option></select></label>
          <button class="botao" id="fr-atualizar" type="button">Atualizar</button>
        </div>
        <p class="estado-envio" id="fr-estado-msg" role="status" aria-live="polite"></p>
        <div class="lista-reportes" id="lista-reportes"></div>
      </section>
    </div>
  </div>
</main>
${rodape({ t, d, v })}
</body>
</html>
`;
}
