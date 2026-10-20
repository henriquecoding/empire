// tools/web/bestas.mjs — a linha do repouso de cada folha animada, para o laboratório (PUB-06, ADR 0085).
//
// O laboratório só mostra as criaturas no repouso, e a folha do dono (ADR 0083)
// traz as oito acções: 256 × 512 px para usar 256 × 64. Um PNG não entrelaçado
// guarda as linhas por ordem, e o filtro de cada linha só olha para a de cima —
// por isso as primeiras N linhas descomprimidas são, tal e qual, uma imagem com
// N linhas. Corta-se aí: sem descodificar píxeis, sem dependências, e com a
// paleta e a transparência do dono intactas. O art/ só se lê (regra 9).

import { readFileSync, writeFileSync } from "node:fs";
import { inflateSync, deflateSync } from "node:zlib";

const ASSINATURA = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
const CANAIS = { 0: 1, 2: 3, 3: 1, 4: 2, 6: 4 };

const TABELA = Array.from({ length: 256 }, (_, n) => {
  let c = n;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  return c >>> 0;
});
function crc32(buf) {
  let c = 0xffffffff;
  for (const b of buf) c = TABELA[(c ^ b) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

function pedaco(tipo, dados) {
  const t = Buffer.from(tipo, "latin1");
  const n = Buffer.alloc(4), crc = Buffer.alloc(4);
  n.writeUInt32BE(dados.length);
  crc.writeUInt32BE(crc32(Buffer.concat([t, dados])));
  return Buffer.concat([n, t, dados, crc]);
}

/** Os pedaços de um PNG, por ordem: [{ tipo, dados }]. */
export function pedacos(png) {
  if (!png.subarray(0, 8).equals(ASSINATURA)) throw new Error("bestas: não é um PNG");
  const saida = [];
  for (let i = 8; i < png.length;) {
    const n = png.readUInt32BE(i), tipo = png.toString("latin1", i + 4, i + 8);
    saida.push({ tipo, dados: png.subarray(i + 8, i + 8 + n) });
    i += 12 + n;
  }
  return saida;
}

/** As primeiras `linhas` linhas de um PNG não entrelaçado, como um PNG novo. */
export function topoDoPng(png, linhas) {
  const ps = pedacos(png);
  const ihdr = Buffer.from(ps[0].dados);
  const [largura, altura, bits, cor, entrelacado] = [ihdr.readUInt32BE(0), ihdr.readUInt32BE(4), ihdr[8], ihdr[9], ihdr[12]];
  if (entrelacado) throw new Error("bestas: um PNG entrelaçado não se corta pelas linhas");
  if (!CANAIS[cor] || linhas > altura) throw new Error(`bestas: não sei cortar ${linhas} linhas de um PNG ${largura}×${altura} de cor ${cor}`);
  const porLinha = 1 + Math.ceil((largura * CANAIS[cor] * bits) / 8);
  const cru = inflateSync(Buffer.concat(ps.filter((p) => p.tipo === "IDAT").map((p) => p.dados)));
  if (cru.length !== porLinha * altura) throw new Error("bestas: o tamanho descomprimido não bate com o IHDR");
  ihdr.writeUInt32BE(linhas, 4);
  const antes = ps.filter((p) => !["IHDR", "IDAT", "IEND"].includes(p.tipo) && ps.indexOf(p) < ps.findIndex((q) => q.tipo === "IDAT"));
  return Buffer.concat([
    ASSINATURA, pedaco("IHDR", ihdr), ...antes.map((p) => pedaco(p.tipo, p.dados)),
    pedaco("IDAT", deflateSync(cru.subarray(0, porLinha * linhas), { level: 9 })), pedaco("IEND", Buffer.alloc(0)),
  ]);
}

/** Escreve em `destino` a linha do repouso da folha `origem`, com `lado` px de altura. */
export function linhaDoRepouso(origem, destino, lado) {
  writeFileSync(destino, topoDoPng(readFileSync(origem), lado));
}
