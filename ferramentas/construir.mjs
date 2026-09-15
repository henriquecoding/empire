#!/usr/bin/env node
/**
 * CONSTRUTOR — aplica a camada de uso ao dossiê, sem lhe tocar no conteúdo.
 * ---------------------------------------------------------------------
 * ┌─────────────────────────────────────────────────────────────────────┐
 * │ PORQUE É QUE ISTO É UM SCRIPT E NÃO UMA EDIÇÃO À MÃO                 │
 * │                                                                     │
 * │ O dossiê tem 6 177 linhas e é a fonte de verdade do projeto. Editar  │
 * │ 6 177 linhas à mão para acrescentar uma barra de pesquisa é garantir │
 * │ que, na próxima versão do dossiê, o trabalho se perde — e que        │
 * │ ninguém consegue dizer o que mudou.                                 │
 * │                                                                     │
 * │ Isto faz cinco inserções cirúrgicas e mais nada. O conteúdo sai      │
 * │ byte a byte como entrou; o que muda é o que está à volta dele. Uma   │
 * │ versão nova do dossiê volta a passar por aqui e a camada reaplica-se.│
 * └─────────────────────────────────────────────────────────────────────┘
 *
 * Uso: node construir.mjs <original.html> <dados.json> <saída.html> [--artefacto]
 *
 * `--artefacto` omite `<!doctype>`, `<html>`, `<head>` e `<body>`, porque o
 * serviço de publicação os fornece. O ficheiro para descarregar leva-os —
 * sem `<!doctype>` o browser entra em modo quirks, e o dossiê original
 * estava a ser lido assim desde sempre.
 */

import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const AQUI = dirname(fileURLToPath(import.meta.url));
const [, , ORIG, DADOS, SAIDA, ...flags] = process.argv;
const ARTEFACTO = flags.includes("--artefacto");

let html = readFileSync(ORIG, "utf8");
const antes = html.length;

/* Os numeros da cabeca e da tira sao CONTADOS, nao escritos. Um numero
   escrito a mao aqui diverge no primeiro dia em que alguem acrescenta um
   ticket, e e a propria pagina a mentir sobre o que tem dentro. */
const D = JSON.parse(readFileSync(DADOS, "utf8"));
const N = {
  seccoes: D.validacao?.spec_sections ?? (html.match(/<section id="s\d+"/g) || []).length,
  tickets: D.tickets.length,
  perguntas: D.perguntas.length,
  adrs: D.adrs.length,
  tabelas: D.tabelas.length,
};

/* ─── Guarda: as inserções só valem se as âncoras existirem ───────────
   Um `replace` que não encontra o alvo devolve a string intacta e não dá
   erro — é assim que uma camada inteira desaparece em silêncio na versão
   seguinte do documento. Cada inserção é contada e conferida no fim. */
let inserções = 0;

/**
 * ┌─────────────────────────────────────────────────────────────────────┐
 * │ A INSERÇÃO NÃO PODE USAR UMA STRING DE SUBSTITUIÇÃO                  │
 * │                                                                     │
 * │ `String.replace(alvo, texto)` interpreta `$$`, `$&`, `` $` ``, `$'`  │
 * │ e `$1` DENTRO do texto de substituição. O JavaScript inserido tem    │
 * │ um atalho chamado `$$` (o `querySelectorAll`), e a inserção                │
 * │ transformou cada `$$` num `$` — o que produziu duas declarações de   │
 * │ `$` no mesmo âmbito e matou o script inteiro com um                  │
 * │ `SyntaxError` antes de a primeira linha correr.                      │
 * │                                                                     │
 * │ Não deu erro na construção: o ficheiro foi escrito, tinha o tamanho  │
 * │ certo e parecia bem. Só o portão apanhou. Por isso a substituição é  │
 * │ sempre uma FUNÇÃO, que devolve o texto literal e não o interpreta.   │
 * └─────────────────────────────────────────────────────────────────────┘
 */
function inserir(marca, texto, onde) {
  if (!html.includes(marca)) {
    console.error(`FALHOU: a âncora ${JSON.stringify(marca.slice(0, 40))} não existe no documento.`);
    process.exit(1);
  }
  html = html.replace(marca, () => (onde === "antes" ? texto + marca : marca + texto));
  inserções++;
}

/* ─── 1 · Cabeça ─────────────────────────────────────────────────────
   O defeito mais caro do dossiê não estava no desenho: não havia
   `<meta name="viewport">`. Sem ela, um telemóvel assume 980px de
   largura e encolhe a página até ninguém conseguir ler — as 122 tabelas,
   os 52 blocos de código e o texto todo. Nenhuma outra correção de
   telemóvel vale nada enquanto esta faltar. */
const CABECA =
  `<meta charset="utf-8">\n` +
  `<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n` +
  `<meta name="color-scheme" content="light dark">\n` +
  `<meta name="theme-color" content="#EBE6D6" media="(prefers-color-scheme: light)">\n` +
  `<meta name="theme-color" content="#131409" media="(prefers-color-scheme: dark)">\n` +
  `<meta name="description" content="Dossiê de produção do Empire — ${N.seccoes} secções de design, balanceamento, direção de arte e especificação técnica, com o estado medido do repositório, o inventário completo e pesquisa dentro do documento.">\n`;
inserir("<title>", CABECA, "antes");

/* ─── 2 · Estilos ────────────────────────────────────────────────── */
const css = readFileSync(join(AQUI, "src", "ux.css"), "utf8");
/* A camada de DESENHO entra depois da de USO, e depois da folha do autor:
   é a última a falar sobre disposição e matéria, e a primeira a ceder
   quando o autor decidir outra coisa na v7. */
const design = readFileSync(join(AQUI, "src", "design.css"), "utf8");
inserir("</style>", `\n/* ═══ CAMADA DE USO ═══ */\n${css}\n\n/* ═══ CAMADA DE DESENHO ═══ */\n${design}\n`, "antes");

/* ─── 3 · A tira de orientação ───────────────────────────────────────
   Uma funcionalidade que ninguém descobre não existe. Três linhas por
   baixo do estado da recuperação, onde o olho já está. */
const TIRA = `
<aside class="note dec" id="x-como" aria-label="Como usar este dossiê" style="margin-top:14px">
  <span class="lbl">Novo nesta cópia — como usar o documento</span>
  <p><strong>Pesquisa dentro do dossiê:</strong> <kbd class="x-kbd">/</kbd> ou <kbd class="x-kbd">Ctrl/⌘ K</kbd>.
  Procura nas ${N.seccoes} secções, nos sub-títulos, nas caixas de decisão, nos ${N.tickets} tickets,
  nas ${N.perguntas} perguntas, nas ${N.adrs} ADRs e nas ${N.tabelas} tabelas de dados — tudo no
  dispositivo, nada sai daqui.</p>
  <p><strong>Navegação:</strong> <kbd class="x-kbd">J</kbd> e <kbd class="x-kbd">K</kbd> saltam de secção,
  <kbd class="x-kbd">G</kbd> <kbd class="x-kbd">E</kbd> abre o estado medido,
  <kbd class="x-kbd">G</kbd> <kbd class="x-kbd">I</kbd> o inventário, e <kbd class="x-kbd">?</kbd> mostra tudo.
  As referências <em>§NN</em> passaram a ser ligações com pré-visualização, e os termos sublinhados a tracejado
  explicam-se ao passar por cima.</p>
</aside>
`;
/* ATENÇÃO à âncora: `</aside>\n\n<div class="shell">` com inserção
   «antes» punha a tira DENTRO do aside da retomada — um aside dentro de
   outro, com a moldura de brasa a envolver os dois. A âncora é a
   abertura do `shell`, e a tira entra imediatamente antes dela. */
inserir("\n\n<div class=\"shell\">", "\n" + TIRA, "antes");

/* ─── 4 · Dados ──────────────────────────────────────────────────────
   JSON num `<script type="application/json">` e não um literal dentro do
   JavaScript: não passa pelo parser de JS, e `</` escapado é a única
   coisa que o pode partir. */
const dados = readFileSync(DADOS, "utf8").replace(/<\//g, "<\\/");
const BLOCO_DADOS = `\n<script type="application/json" id="x-dados">${dados}</script>\n`;

/* ─── 5 · Comportamento ────────────────────────────────────────────── */
const ORDEM = [
  "01-busca.js",     // pontuação e tolerância a gralhas
  "02-indice.js",    // o índice DERIVADO do DOM e do ZIP
  "03-paineis.js",   // estado, inventário, gráficos, glossário
  "04-plano.js",     // reconhecer a frase → o que se pode AFIRMAR
  "05-recorte.js",   // levar o caso a alguém, com proveniência
  "06-saude.js",     // os fatores do plano, contados ao vivo
  "07-partes.js",    // treze grupos que se abrem quando se quer
  "08-interface.js", // desenha tudo o que está acima. Vai em último.
];
const js = ORDEM.map((f) => readFileSync(join(AQUI, "src", f), "utf8")).join("\n\n");
const BLOCO_JS =
  `<script>\n` +
  `/* A camada de uso. O dossiê continua a funcionar sem ela — sem\n` +
  `   JavaScript o documento lê-se de cima a baixo e o índice navega,\n` +
  `   que é o comportamento de um documento. */\n` +
  `try{ window.__EMPIRE_DADOS__ = JSON.parse(document.getElementById("x-dados").textContent); }\n` +
  `catch(e){ window.__EMPIRE_DADOS__ = null; }\n` +
  `document.documentElement.lang = "pt-PT";\n\n` +
  js +
  `\n</script>\n`;

const FIM = "</footer>";
if (!html.includes(FIM)) { console.error("FALHOU: não há rodapé onde ancorar os scripts."); process.exit(1); }
// Entra DEPOIS do script original: o rastreador das 48 mecânicas tem de
// ter desenhado a lista antes de o índice a derivar do DOM.
html = html.replace(/<\/script>\s*$/, () => `</script>\n${BLOCO_DADOS}${BLOCO_JS}`);
// Duas: o bloco de dados e o bloco de comportamento. Vao na mesma
// substituicao porque a ordem entre eles importa, mas contam como duas —
// o total tem de bater com as cinco seccoes numeradas acima.
inserções += 2;

/* Uma segunda rede, porque o defeito acima foi invisível durante uma
   construção inteira: se o `$$` não sobreviveu, não se publica nada. */
for (const sinal of ["const $$ = (s, r)", 'window.__EMPIRE_DADOS__', "montarGlossario",
                     "window.XR =", "window.XC =", "window.XS =", "montarRecorte", "window.XPT ="]) {
  if (!html.includes(sinal)) {
    console.error(`FALHOU: ${JSON.stringify(sinal)} não sobreviveu à inserção — a substituição comeu um marcador.`);
    process.exit(1);
  }
}

/* ─── 6 · Embrulho ─────────────────────────────────────────────────── */
if (!ARTEFACTO) {
  html =
    `<!doctype html>\n<html lang="pt-PT">\n<head>\n` +
    html.replace(/^([\s\S]*?<\/style>)/, "$1\n</head>\n<body>") +
    `\n</body>\n</html>\n`;
}

mkdirSync(dirname(SAIDA), { recursive: true });
writeFileSync(SAIDA, html);

console.log(
  `${inserções} inserções · ${(antes / 1024).toFixed(0)} KB → ${(html.length / 1024).toFixed(0)} KB` +
  `${ARTEFACTO ? " (artefacto)" : ""} → ${SAIDA}`,
);
