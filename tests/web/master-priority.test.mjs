import { test } from 'node:test';
import assert from 'node:assert/strict';
import { perguntas } from '../../tools/web/perguntas.mjs';

const question = id => perguntas(process.cwd()).find(q => q.id === id);

test('multiplayer follows the report and does not ask to approve the old proposal', () => {
  const q = question('Q-204');
  assert.match(q.decisao, /criador/);
  assert.match(q.decisao, /servidor/);
  assert.doesNotMatch(q.proposta, /dois comandos|continuidade dele/);
  assert.equal(q.aprovavel, false);
});

test('the new foundation keeps the approved layout without the paid hearth', () => {
  const q = question('Q-231');
  assert.match(q.decisao, /livre e gratuita/);
  assert.match(q.decisao, /relatório/);
});
