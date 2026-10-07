// Texto editorial do primeiro contacto; números e controlos continuam derivados do jogo.
export const EXPERIENCIA = {
  pt: {
    identidade: "Construir · Explorar · Resistir",
    deck: "Escolhe o teu monarca, encontra um lugar para o teu povo e constrói um reino. Quando a luz cai, a Podridão avança. Cada moeda é uma escolha.",
    factos: ["Sem instalar", "Teclado, comando ou toque", "PT / EN"],
    imagem: "Um dia no Empire", origem: "Sobre estas imagens", guia: "Começa por aqui", titulo: "O teu primeiro dia no reino.",
    passos: [
      ["Escolhe quem governa", "Cada monarca tem a sua arma e um companheiro. Experimenta a forma de jogar que mais gostas."],
      ["Explora e funda", "A caravana acompanha-te. Encontra o teu lugar e confirma a fundação antes de começar a construir."],
      ["Prepara a primeira noite", "Usa as moedas para recrutar e construir. Regressa à segurança do reino quando a luz começar a cair."],
    ],
    controlos: "Consultar os controlos", feedback: "Reportar um problema", prototipo: "Protótipo em desenvolvimento. O progresso fica neste browser.",
    voltar: "Pronto para o teu primeiro reino?", jogar: "Jogar agora", final: "Explora ao teu ritmo. A próxima história começa contigo.",
  },
  en: {
    identidade: "Build · Explore · Endure",
    deck: "Choose your monarch, find a home for your people and build a kingdom. When the light fades, the Rot advances. Every coin is a choice.",
    factos: ["No installation", "Keyboard, controller or touch", "PT / EN"],
    imagem: "A day in Empire", origem: "About these images", guia: "Start here", titulo: "Your first day in the kingdom.",
    passos: [
      ["Choose your monarch", "Each monarch has a weapon and a companion. Try the play style that suits you."],
      ["Explore and settle", "Your caravan follows you. Find your place and confirm the settlement before you start building."],
      ["Prepare for the first night", "Spend coins to recruit and build. Return to the safety of your kingdom as the light begins to fade."],
    ],
    controlos: "See the controls", feedback: "Report a problem", prototipo: "A prototype in development. Progress stays in this browser.",
    voltar: "Ready for your first kingdom?", jogar: "Play now", final: "Explore at your own pace. The next story starts with you.",
  },
};

export function guiaInicial(t, esc) {
  const e = EXPERIENCIA[t.lingua === "pt-PT" ? "pt" : "en"];
  return `<section class="guia-inicial" id="comecar" aria-labelledby="comecar-t"><div class="envolve">
    <header class="guia-cabeca"><div><p class="rotulo-ui">${e.guia}</p><h2 id="comecar-t">${e.titulo}</h2></div>
    <a href="#controlos">${e.controlos} <span aria-hidden="true">↘</span></a></header>
    <ol>${e.passos.map(([titulo, texto], i) => `<li><span class="guia-numero" aria-hidden="true">0${i + 1}</span><div><h3>${esc(titulo)}</h3><p>${esc(texto)}</p></div></li>`).join("")}</ol>
    <div class="guia-rodape"><p>${e.prototipo}</p><a href="${t.caminho}${t.reportar.caminho}">${e.feedback} <span aria-hidden="true">↗</span></a></div>
  </div></section>`;
}

export function conviteFinal(t, v) {
  const e = EXPERIENCIA[t.lingua === "pt-PT" ? "pt" : "en"];
  return `<section class="convite-final escura" aria-labelledby="convite-t"><div class="envolve">
    <div><p class="rotulo-ui">Empire</p><h2 id="convite-t">${e.voltar}</h2><p>${e.final}</p></div>
    <a class="botao principal" href="${v.jogar}">${e.jogar} <span aria-hidden="true">→</span></a>
  </div></section>`;
}
