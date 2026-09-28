import { test } from 'node:test';
import assert from 'node:assert/strict';
import { perguntas } from '../../tools/web/perguntas.mjs';
const qs = perguntas(process.cwd());
const q = id => qs.find(x => x.id === id);
test('questões encerradas não pedem aprovação', () => {
  assert.equal(q('Q-006').tipo, 'encerrada');
  assert.equal(q('Q-076').tipo, 'encerrada');
  assert.equal(q('Q-006').aprovavel, false);
});
test('a decisão parcial não aprova o que continua aberto', () => {
  assert.equal(q('Q-143').aprovavel, false);
  assert.match(q('Q-143').pendencia, /identidade da comitiva/);
  assert.match(q('Q-143').decisao, /CampaignMemory/);
});
test('contexto e proposta completos, separados da localização', () => {
  assert.match(q('Q-005').onde, /30%/);
  assert.match(q('Q-005').proposta, /25%/);
  assert.equal(q('Q-005').aprovavel, true);
  assert.ok(q('Q-001').contexto.length > 100);
  assert.match(q('Q-001').bloqueio, /F1-09/);
});
test('sem proposta não existe aprovação vaga', () => {
  assert.equal(q('Q-145').aprovavel, false);
  assert.equal(q('Q-147').aprovavel, false);
});
test('títulos não expõem markdown; todas as perguntas têm fonte e contexto', () => {
  for (const item of qs) {
    assert.doesNotMatch(item.titulo, /\*\*|`/);
    assert.ok(item.contexto || item.onde || item.decisao || item.pendencia, item.id);
    assert.match(item.fonte, /^https:\/\/github.com\/henriquecoding\/empire\/blob\//);
  }
});
