#!/usr/bin/env node
// tools/web/fontes.mjs — as fontes do site passam a ser servidas pelo próprio site (ADR 0025).
//
// Até aqui a página de entrada, a casca do jogo, o 404 e o dossiê pediam as
// quatro famílias ao fonts.googleapis.com. Cada visita entregava o IP de quem
// lia à Google antes do primeiro parágrafo — o contrário do §32 («medir sem
// espiar») e, na UE, uma transferência de dados pessoais sem base (LG München,
// 3 O 17493/20). E custava duas ligações a outras origens no caminho crítico.
//
// Isto corre UMA vez, à mão, quando se muda de família ou de eixo — não na
// construção: a Vercel não precisa de rede para servir fontes que já estão no
// repositório. Pede à Google o mesmo CSS que o dossiê pedia, fica só com os
// subconjuntos latin e latin-ext (o português cabe no primeiro; o segundo
// entra só quando uma página o usa, pelo unicode-range), descarrega os .woff2
// e escreve o fontes.css com caminhos locais. As licenças (OFL 1.1) ficam ao
// lado de cada ficheiro, como a OFL exige.
//
//   NODE_USE_ENV_PROXY=1 node tools/web/fontes.mjs

import { mkdirSync, writeFileSync, rmSync } from "node:fs";
import { join, resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const RAIZ = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
const SAIDA = join(RAIZ, "tools", "web", "site", "fontes");

// O pedido é o do docs/dossie.html: os mesmos eixos, para o dossiê construído
// poder usar estas fontes sem perder o SOFT e o WONK do Fraunces.
const PEDIDO = "https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght,SOFT,WONK@9..144,400..900,0..100,0..1"
  + "&family=Source+Serif+4:ital,opsz,wght@0,8..60,400;0,8..60,600;1,8..60,400"
  + "&family=IBM+Plex+Mono:wght@400;500;600&family=Silkscreen&display=swap";
// Um browser recente: é o User-Agent que faz a Google servir woff2 e variáveis.
const UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0 Safari/537.36";
const SUBCONJUNTOS = new Set(["latin", "latin-ext"]);
const LICENCAS = {
  "Fraunces": "fraunces",
  "Source Serif 4": "sourceserif4",
  "IBM Plex Mono": "ibmplexmono",
  "Silkscreen": "silkscreen",
};

const pedir = async (url, tipo) => {
  const r = await fetch(url, { headers: { "User-Agent": UA } });
  if (!r.ok) throw new Error(`fontes: ${url} respondeu ${r.status}`);
  return tipo === "texto" ? r.text() : Buffer.from(await r.arrayBuffer());
};

const lento = (s) => s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");

async function main() {
  const css = await pedir(PEDIDO, "texto");
  const blocos = [...css.matchAll(/\/\* ([a-z-]+) \*\/\s*@font-face\s*\{([^}]+)\}/g)];
  rmSync(SAIDA, { recursive: true, force: true });
  mkdirSync(SAIDA, { recursive: true });
  // A Google serve o MESMO ficheiro variável uma vez por peso pedido (o Source
  // Serif 4 a 400 e a 600 são 120 KB iguais, duas vezes). Um ficheiro por URL,
  // e os pesos juntam-se num intervalo — que é o que um variável é.
  const faces = new Map();
  for (const [, sub, corpo] of blocos) {
    if (!SUBCONJUNTOS.has(sub)) continue;
    const campo = (k) => corpo.match(new RegExp(`${k}:\\s*([^;]+);`))?.[1].trim();
    const url = corpo.match(/url\(([^)]+)\)/)[1];
    const pesos = campo("font-weight").split(" ").map(Number);
    const face = faces.get(url);
    if (face) {
      face.pesos.push(...pesos);
      continue;
    }
    faces.set(url, {
      familia: campo("font-family").replace(/'/g, ""), estilo: campo("font-style"),
      sub, pesos, intervalo: campo("unicode-range"),
    });
  }
  const saida = [];
  let bytes = 0;
  for (const [url, f] of faces) {
    const [de, ate] = [Math.min(...f.pesos), Math.max(...f.pesos)];
    const peso = de === ate ? `${de}` : `${de} ${ate}`;
    const nome = `${lento(f.familia)}-${f.estilo === "italic" ? "italico-" : ""}${peso.replace(" ", "-")}-${f.sub}.woff2`;
    const dados = await pedir(url);
    writeFileSync(join(SAIDA, nome), dados);
    bytes += dados.length;
    saida.push(
      `@font-face{font-family:'${f.familia}';font-style:${f.estilo};font-weight:${peso};font-display:swap;`
      + `src:url(/fontes/${nome}) format('woff2');unicode-range:${f.intervalo}}`,
    );
  }
  for (const [familia, pasta] of Object.entries(LICENCAS)) {
    const ofl = await pedir(`https://raw.githubusercontent.com/google/fonts/main/ofl/${pasta}/OFL.txt`, "texto");
    writeFileSync(join(SAIDA, `OFL-${lento(familia)}.txt`), ofl);
  }
  const cabeca = "/* Gerado por tools/web/fontes.mjs — nao editar a mao. Quatro familias OFL 1.1,\n"
    + "   subconjuntos latin e latin-ext, servidas pelo proprio site (ADR 0025). */\n";
  writeFileSync(join(SAIDA, "fontes.css"), cabeca + saida.join("\n") + "\n");
  console.log(`fontes: ${saida.length} ficheiros, ${(bytes / 1024).toFixed(0)} KB, em ${SAIDA}`);
}

await main();
