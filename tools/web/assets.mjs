import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { join, resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { createHash } from "node:crypto";
import { cssDosDados } from "./paginas/molde.mjs";
import { modeloDoLaboratorio } from "./paginas/laboratorio.mjs";
const RAIZ = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
const SITE = join(RAIZ, "tools/web/site"), PAGINAS = join(RAIZ, "tools/web/paginas");
const hash = s => createHash("sha256").update(s).digest("hex").slice(0, 10);

/** A folha: as fontes, o estilo e os dados, sem comentários nem espaço a mais. */
function minificarCss(css) {
  return css.replace(/\/\*[\s\S]*?\*\//g, "").replace(/\s+/g, " ").replace(/\s*([{}:;,>])\s*/g, "$1").replace(/;}/g, "}").trim();
}

export function escreverAssets(saida, d) {
  const dir = join(saida, "assets");
  mkdirSync(dir, { recursive: true });
  const css = minificarCss([
    readFileSync(join(SITE, "fontes", "fontes.css"), "utf8"),
    readFileSync(join(PAGINAS, "estilo.css"), "utf8"),
    readFileSync(join(PAGINAS, "experiencia.css"), "utf8"),
    readFileSync(join(PAGINAS, "laboratorio.css"), "utf8"),
    cssDosDados(d),
  ].join("\n"));
  const saidas = {};
  for (const [nome, ext, texto] of [
    ["estilo", "css", css],
    ["tema", "js", readFileSync(join(PAGINAS, "tema.js"), "utf8")],
    ...["palco", "candeia", "painelIndice"].map(nome => [nome, "js", readFileSync(join(PAGINAS, nome === "painelIndice" ? "painel-indice.js" : nome + ".js"), "utf8")]),
    ["site", "js", readFileSync(join(PAGINAS, "site.js"), "utf8")],
    // As contas, o modelo e o instrumento num pedido só, e só quando a secção se aproxima.
    ["laboratorio", "js", [readFileSync(join(PAGINAS, "laboratorio-contas.js"), "utf8"), `window.EmpireLaboratorio = ${JSON.stringify(modeloDoLaboratorio(d))};`,
      ...["laboratorio-instrumentos.js", "laboratorio.js"].map(f => readFileSync(join(PAGINAS, f), "utf8"))].join("\n")],
    ["motor", "js", readFileSync(join(PAGINAS, "motor.js"), "utf8")],
    ["painelConcorrencia", "js", readFileSync(join(PAGINAS, "painel-concorrencia.js"), "utf8")],
    ["reportar", "js", readFileSync(join(PAGINAS, "reportar.js"), "utf8")],
    ["painelCss", "css", minificarCss(readFileSync(join(PAGINAS, "painel.css"), "utf8"))],
    ["painelReportes", "js", readFileSync(join(PAGINAS, "painel-reportes.js"), "utf8")],
    ["painelTrabalho", "js", readFileSync(join(PAGINAS, "painel-trabalho.js"), "utf8")],
    ["painel", "js", readFileSync(join(PAGINAS, "painel.js"), "utf8")],
  ]) {
    const f = `${nome}.${hash(texto)}.${ext}`;
    writeFileSync(join(dir, f), texto);
    saidas[nome] = `/assets/${f}`;
  }
  return { ...saidas, css: saidas.estilo, tema: saidas.tema, js: saidas.site, motor: saidas.motor, reportar: saidas.reportar, painel: saidas.painel, painelTrabalho: saidas.painelTrabalho, painelCss: saidas.painelCss, painelReportes: saidas.painelReportes };
}
