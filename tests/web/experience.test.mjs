import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import test from 'node:test';

test('a pesquisa indexa uma vez e encontra acentos, ids e respostas novas', () => {
  const window = {};
  runInNewContext(readFileSync('tools/web/paginas/painel-indice.js', 'utf8'), { window });
  let reads = 0;
  const records = Array.from({ length: 1000 }, (_, i) => ({ id: `Q-${i}`, get textContent() { reads++; return 'Construção do território'; } }));
  const index = window.EmpireIndice.criar(records);
  assert.equal(reads, 1000);
  for (let i = 0; i < 10; i++) assert.equal(index.procurar('construcao').size, 1000);
  assert.equal(reads, 1000, 'digitar não volta a ler o DOM de todas as decisões');
  assert.deepEqual([...index.procurar('Q-999')], ['Q-999']);
  index.responder('Q-7', 'Pomar de macieiras');
  assert.deepEqual([...index.procurar('macieiras')], ['Q-7']);
  index.responder('Q-7', '');
  assert.equal(index.procurar('macieiras').size, 0);
});

test('um pedido pendurado termina sem repetir a escrita nem perder a sessão', async () => {
  const window = {}, timers = new Map(); let sequence = 0, aborted = false, calls = 0;
  runInNewContext(readFileSync('tools/web/paginas/motor.js', 'utf8'), {
    window, AbortController,
    document: { documentElement: { lang: 'pt-PT' }, body: { getAttribute: () => 'public' } },
    sessionStorage: { getItem: () => JSON.stringify({ token: 'test', refresh: 'refresh', expira: Date.now() + 600000 }), setItem() {} },
    setTimeout: fn => { timers.set(++sequence, fn); return sequence; }, clearTimeout: id => timers.delete(id),
    fetch: (_, options) => { calls++; return new Promise((resolve, reject) => {
      options.signal?.addEventListener('abort', () => { aborted = true; reject(new DOMException('Timeout', 'AbortError')); });
    }); },
  });
  const pending = window.EmpireMotor.pedir('/rest/v1/empire_respostas', { metodo: 'POST', corpo: [{ texto: 'Não perder' }] });
  await new Promise(resolve => setImmediate(resolve));
  assert.equal(timers.size, 1, 'cada pedido tem um prazo');
  [...timers.values()][0]();
  await assert.rejects(pending, /demorou|ligação/);
  assert.equal(aborted, true); assert.equal(calls, 1); assert.equal(timers.size, 0);
  assert.equal(window.EmpireMotor.sessao().token, 'test');
});
