// tools/web/zip_remoto.mjs — tira UMA entrada de um .zip remoto sem o descarregar.
//
// Os templates de export do Godot vêm num .tpz de 1,2 GB com todas as
// plataformas, e o Web precisa de um ficheiro de 9 MB lá de dentro. O GitHub
// serve os releases com `Accept-Ranges: bytes`, e um .zip tem o índice no fim:
// lê-se o fim, acha-se a entrada, e pede-se só o pedaço dela. Um build na
// Vercel passa de "descarregar 1,2 GB" para "descarregar 10 MB".
//
// Sem dependências: fetch, zlib e o formato do zip (APPNOTE 6.3). Confere o
// CRC-32 de cada entrada — um byte trocado é um erro, não um motor estranho.
//
//   node tools/web/zip_remoto.mjs <url> <entrada> <destino> [<entrada> <destino> ...]

import { writeFileSync, mkdirSync } from "node:fs";
import { dirname } from "node:path";
import { inflateRawSync, crc32 } from "node:zlib";

const EOCD = 0x06054b50;
const EOCD64 = 0x06064b50;
const EOCD64_LOCATOR = 0x07064b50;
const CENTRAL = 0x02014b50;
const LOCAL = 0x04034b50;
const CAUDA = 65536 + 22; // o maior comentário que um zip pode ter, mais o EOCD
const TENTATIVAS = 4;

async function pedaco(url, de, ate) {
  let erro;
  for (let i = 0; i < TENTATIVAS; i++) {
    try {
      const r = await fetch(url, { headers: { Range: `bytes=${de}-${ate}` }, redirect: "follow" });
      if (r.status !== 206) throw new Error(`HTTP ${r.status} (o servidor não serve por partes?)`);
      const b = Buffer.from(await r.arrayBuffer());
      if (b.length !== ate - de + 1) throw new Error(`vieram ${b.length} bytes, pedi ${ate - de + 1}`);
      return b;
    } catch (e) {
      erro = e;
      await new Promise((ok) => setTimeout(ok, 1000 * 2 ** i));
    }
  }
  throw new Error(`zip_remoto: ${url} [${de}-${ate}]: ${erro.message}`);
}

async function tamanho(url) {
  const r = await fetch(url, { method: "HEAD", redirect: "follow" });
  if (!r.ok) throw new Error(`zip_remoto: HEAD ${url}: HTTP ${r.status}`);
  return Number(r.headers.get("content-length"));
}

// O índice central: nome -> { metodo, comprimido, crc, local }.
async function indice(url) {
  const total = await tamanho(url);
  const cauda = await pedaco(url, Math.max(0, total - CAUDA), total - 1);
  const k = cauda.lastIndexOf(Buffer.from([0x50, 0x4b, 0x05, 0x06]));
  if (k < 0 || cauda.readUInt32LE(k) !== EOCD) throw new Error("zip_remoto: sem fim de índice");
  let n = cauda.readUInt16LE(k + 10);
  let tam = cauda.readUInt32LE(k + 12);
  let ini = cauda.readUInt32LE(k + 16);
  // ZIP64: os campos de 32 bits vêm a 0xFFFFFFFF e o valor verdadeiro está atrás.
  if (ini === 0xffffffff || tam === 0xffffffff || n === 0xffff) {
    const loc = k - 20;
    if (cauda.readUInt32LE(loc) !== EOCD64_LOCATOR) throw new Error("zip_remoto: ZIP64 sem localizador");
    const onde = Number(cauda.readBigUInt64LE(loc + 8));
    const e64 = await pedaco(url, onde, onde + 55);
    if (e64.readUInt32LE(0) !== EOCD64) throw new Error("zip_remoto: ZIP64 sem registo");
    n = Number(e64.readBigUInt64LE(32));
    tam = Number(e64.readBigUInt64LE(40));
    ini = Number(e64.readBigUInt64LE(48));
  }
  const cd = await pedaco(url, ini, ini + tam - 1);
  const saida = new Map();
  let p = 0;
  for (let i = 0; i < n; i++) {
    if (cd.readUInt32LE(p) !== CENTRAL) throw new Error("zip_remoto: índice central estragado");
    const metodo = cd.readUInt16LE(p + 10);
    const crc = cd.readUInt32LE(p + 16);
    let comprimido = cd.readUInt32LE(p + 20);
    let real = cd.readUInt32LE(p + 24);
    const lnome = cd.readUInt16LE(p + 28);
    const lextra = cd.readUInt16LE(p + 30);
    const lcoment = cd.readUInt16LE(p + 32);
    let local = cd.readUInt32LE(p + 42);
    const nome = cd.toString("utf8", p + 46, p + 46 + lnome);
    // O campo extra ZIP64 traz, por esta ordem, só os que vieram a 0xFFFFFFFF.
    let x = p + 46 + lnome;
    const fimx = x + lextra;
    while (x < fimx) {
      const id = cd.readUInt16LE(x);
      const lx = cd.readUInt16LE(x + 2);
      if (id === 0x0001) {
        let q = x + 4;
        if (real === 0xffffffff) { real = Number(cd.readBigUInt64LE(q)); q += 8; }
        if (comprimido === 0xffffffff) { comprimido = Number(cd.readBigUInt64LE(q)); q += 8; }
        if (local === 0xffffffff) { local = Number(cd.readBigUInt64LE(q)); }
      }
      x += 4 + lx;
    }
    saida.set(nome, { metodo, crc, comprimido, real, local });
    p = fimx + lcoment;
  }
  return saida;
}

async function entrada(url, e, nome) {
  const cab = await pedaco(url, e.local, e.local + 29);
  if (cab.readUInt32LE(0) !== LOCAL) throw new Error(`zip_remoto: ${nome}: cabeçalho local estragado`);
  const dados = e.local + 30 + cab.readUInt16LE(26) + cab.readUInt16LE(28);
  const bruto = e.comprimido === 0 ? Buffer.alloc(0) : await pedaco(url, dados, dados + e.comprimido - 1);
  let b;
  if (e.metodo === 0) b = bruto;
  else if (e.metodo === 8) b = inflateRawSync(bruto);
  else throw new Error(`zip_remoto: ${nome}: método ${e.metodo} não suportado`);
  if (b.length !== e.real) throw new Error(`zip_remoto: ${nome}: ${b.length} bytes, o índice diz ${e.real}`);
  if (crc32(b) >>> 0 !== e.crc >>> 0) throw new Error(`zip_remoto: ${nome}: CRC-32 não bate`);
  return b;
}

// pares: [[entrada, destino], ...]. Devolve os bytes escritos por destino.
export async function extrair(url, pares) {
  const idx = await indice(url);
  const escritos = {};
  for (const [nome, destino] of pares) {
    const e = idx.get(nome);
    if (!e) throw new Error(`zip_remoto: ${url} não tem ${nome}`);
    const b = await entrada(url, e, nome);
    mkdirSync(dirname(destino), { recursive: true });
    writeFileSync(destino, b);
    escritos[destino] = b.length;
  }
  return escritos;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const [url, ...resto] = process.argv.slice(2);
  if (!url || resto.length === 0 || resto.length % 2 !== 0) {
    console.error("uso: node tools/web/zip_remoto.mjs <url> <entrada> <destino> [...]");
    process.exit(2);
  }
  const pares = [];
  for (let i = 0; i < resto.length; i += 2) pares.push([resto[i], resto[i + 1]]);
  const escritos = await extrair(url, pares);
  for (const [d, n] of Object.entries(escritos)) console.log(`zip_remoto: ${d} (${n} bytes)`);
}
