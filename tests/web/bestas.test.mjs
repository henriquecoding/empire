// O site serve das folhas animadas do dono (ADR 0083) só a linha do repouso
// (PUB-06): tem de ser, byte a byte, o topo da folha, com a paleta dela.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { inflateSync, crc32 } from 'node:zlib';
import test from 'node:test';
import { pedacos, topoDoPng } from '../../tools/web/bestas.mjs';

const FOLHA = 'art/export/animated/beast_crawler.png';

test('a linha do repouso é o topo da folha, com a mesma paleta e transparência', () => {
  const original = readFileSync(FOLHA);
  const cortado = topoDoPng(original, 64);
  const [a, b] = [pedacos(original), pedacos(cortado)];
  assert.equal(b[0].tipo, 'IHDR');
  assert.equal(b[0].dados.readUInt32BE(0), a[0].dados.readUInt32BE(0), 'a largura não muda');
  assert.equal(b[0].dados.readUInt32BE(4), 64);
  for (const tipo of ['PLTE', 'tRNS']) {
    const x = a.find((p) => p.tipo === tipo), y = b.find((p) => p.tipo === tipo);
    if (x) assert.ok(y && y.dados.equals(x.dados), `o ${tipo} do dono fica igual`);
  }
  const idat = (ps) => inflateSync(Buffer.concat(ps.filter((p) => p.tipo === 'IDAT').map((p) => p.dados)));
  const cru = idat(b);
  assert.ok(cru.equals(idat(a).subarray(0, cru.length)), 'as linhas são as do topo da folha, tal e qual');
  assert.equal(cru.length, 64 * (1 + a[0].dados.readUInt32BE(0)), 'uma linha por píxel de altura, com o byte do filtro');
  assert.ok(cortado.length < original.length / 3, `${cortado.length} bytes contra ${original.length}`);
});

test('cada pedaço do PNG cortado tem o CRC certo', () => {
  const png = topoDoPng(readFileSync(FOLHA), 64);
  for (let i = 8; i < png.length;) {
    const n = png.readUInt32BE(i);
    assert.equal(png.readUInt32BE(i + 8 + n), crc32(png.subarray(i + 4, i + 8 + n)), png.toString('latin1', i + 4, i + 8));
    i += 12 + n;
  }
});
