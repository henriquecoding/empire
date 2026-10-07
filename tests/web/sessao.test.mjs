import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import test from 'node:test';

const source = readFileSync('tools/web/paginas/motor.js', 'utf8');
const key = 'empire.painel.sessao';
const session = extra => ({ token: 'old', refresh: 'refresh-old', email: 'teste@example.invalid', expira: Date.now() + 3600000, ...extra });
const tokens = { access_token: 'new', refresh_token: 'refresh-new', expires_in: 3600, user: { email: 'teste@example.invalid' } };
const reply = (status, data) => ({ status, ok: status >= 200 && status < 300, text: async () => JSON.stringify(data) });
function boot(initial, handler, brokenStorage = false) {
  const storage = new Map(initial ? [[key, JSON.stringify(initial)]] : []), requests = [], events = [];
  const window = { dispatchEvent: event => events.push(event) };
  runInNewContext(source, {
    window, document: { body: { getAttribute: name => name === 'data-sb-url' ? 'https://test.supabase.co' : 'public-test' } },
    sessionStorage: {
      getItem: k => { if (brokenStorage) throw Error('blocked'); return storage.get(k); },
      setItem: (k, v) => { if (brokenStorage) throw Error('blocked'); storage.set(k, v); },
      removeItem: k => storage.delete(k),
    },
    CustomEvent: class { constructor(type, options) { this.type = type; this.detail = options?.detail; } },
    fetch: async (url, options) => {
      const req = { url, ...options, json: options.body ? JSON.parse(options.body) : null };
      requests.push(req); return handler(req, requests.length);
    },
  });
  return { M: window.EmpireMotor, storage, requests, events };
}
const refresh = req => req.url.includes('grant_type=refresh_token');
const expired = error => error.sessaoExpirada === true && !/JWT|refresh_token/.test(error.message);

test('login conserva os dois tokens e usa a chave pública, mesmo com uma sessão antiga', async () => {
  const { M, requests } = boot(session({ expira: 1 }), req => reply(200, req.url.includes('grant_type=password') ? tokens : true));
  await M.entrar('teste@example.invalid', 'senha-de-teste');
  assert.equal(M.sessao().refresh, 'refresh-new');
  assert.equal(requests[0].headers.Authorization, 'Bearer public-test');
  assert.equal(requests[1].headers.Authorization, 'Bearer new');
});

test('renova antes do prazo e antes de enviar uma decisão', async () => {
  const { M, requests } = boot(session({ expira: Date.now() + 10000 }), req => reply(200, refresh(req) ? tokens : [{ pergunta: 'Q-044' }]));
  await M.pedir('/rest/v1/empire_respostas', { metodo: 'POST', corpo: [{ pergunta: 'Q-044' }] });
  assert.equal(requests.length, 2);
  assert.deepEqual(requests[0].json, { refresh_token: 'refresh-old' });
  assert.equal(requests[1].headers.Authorization, 'Bearer new');
  assert.equal(M.sessao().refresh, 'refresh-new');
});

test('uma sessão expirada recuperável não é apagada ao abrir o painel', async () => {
  const { M } = boot(session({ expira: 1 }), req => reply(200, refresh(req) ? tokens : true));
  assert.equal(M.sessao().refresh, 'refresh-old');
  await M.pedir('/rest/v1/rpc/empire_e_admin', { metodo: 'POST', corpo: {} });
  assert.equal(M.sessao().token, 'new');
});

test('401 renova e repete apenas uma vez, com o mesmo corpo e cabeçalhos', async () => {
  const { M, requests } = boot(session(), req => reply(refresh(req) ? 200 : req.headers.Authorization === 'Bearer old' ? 401 : 200,
    refresh(req) ? tokens : { message: 'JWT expired' }));
  await M.pedir('/rest/v1/empire_respostas', { metodo: 'POST', corpo: [{ texto: 'Resposta em edição' }], cabecalhos: { Prefer: 'return=representation' } });
  assert.equal(requests.length, 3);
  assert.deepEqual(requests[0].json, requests[2].json);
  assert.equal(requests[2].headers.Prefer, 'return=representation');
  assert.equal(requests[2].headers.Authorization, 'Bearer new');
});

test('pedidos concorrentes partilham uma única renovação', async () => {
  let release;
  const gate = new Promise(r => { release = r; });
  const { M, requests } = boot(session({ expira: 1 }), async req => { if (refresh(req)) await gate; return reply(200, refresh(req) ? tokens : []); });
  const pending = Promise.all([M.pedir('/rest/v1/a'), M.pedir('/rest/v1/b')]);
  await new Promise(r => setImmediate(r)); release(); await pending;
  assert.equal(requests.filter(refresh).length, 1);
  assert.equal(requests.filter(r => !refresh(r)).length, 2);
});

test('sessão antiga sem refresh pede login sem enviar a decisão como anónimo', async () => {
  const { M, requests, events } = boot(session({ expira: 1, refresh: undefined }), () => reply(401, { message: 'JWT expired' }));
  await assert.rejects(M.pedir('/rest/v1/empire_respostas'), expired);
  assert.equal(requests.length, 0);
  assert.equal(events[0].type, 'empire:sessao-expirada');
  assert.equal(M.sessao(), null);
});

test('refresh revogado pede novo login com erro compreensível', async () => {
  const { M, storage, events } = boot(session({ expira: 1 }), () => reply(400, { message: 'Invalid Refresh Token: Already Used' }));
  await assert.rejects(M.pedir('/rest/v1/empire_respostas'), expired);
  assert.equal(storage.has(key), false);
  assert.equal(events.length, 1);
});

test('rede indisponível ao renovar mantém a sessão para tentar outra vez', async () => {
  let offline = true;
  const { M, events } = boot(session({ expira: 1 }), req => {
    if (offline) throw Error('Failed to fetch');
    return reply(200, refresh(req) ? tokens : []);
  });
  await assert.rejects(M.pedir('/rest/v1/empire_respostas'), /ligação|renovar/);
  assert.equal(M.sessao().refresh, 'refresh-old'); assert.equal(events.length, 0);
  offline = false; await M.pedir('/rest/v1/empire_respostas'); assert.equal(M.sessao().token, 'new');
});

test('403 de autorização não renova nem repete uma escrita', async () => {
  const { M, requests } = boot(session(), () => reply(403, { message: 'permission denied' }));
  await assert.rejects(M.pedir('/rest/v1/empire_respostas', { metodo: 'POST', corpo: [] }), /permission denied/);
  assert.equal(requests.length, 1);
});

test('um segundo 401 interrompe a repetição e pede login', async () => {
  const { M, requests } = boot(session(), req => refresh(req) ? reply(200, tokens) : reply(401, { message: 'JWT expired' }));
  await assert.rejects(M.pedir('/rest/v1/empire_respostas'), expired);
  assert.equal(requests.length, 3);
});

test('sair durante uma renovação não ressuscita a sessão nem envia a escrita', async () => {
  let release;
  const gate = new Promise(r => { release = r; });
  const { M, requests } = boot(session({ expira: 1 }), async () => { await gate; return reply(200, tokens); });
  const pending = assert.rejects(M.pedir('/rest/v1/empire_respostas'));
  await new Promise(r => setImmediate(r)); const saida = M.sair(); release(); await pending; await saida;
  assert.equal(M.sessao(), null);
  assert.equal(requests.filter(r => r.url.includes('/rest/v1/')).length, 0);
});

test('sair revoga a sessão no servidor, só esta, e depois pede autenticação (BUG-05)', async () => {
  const { M, requests, storage } = boot(session(), () => reply(204, null));
  const r = await M.sair();
  assert.equal(r.remoto, true);
  assert.equal(M.sessao(), null); assert.equal(storage.has(key), false);
  assert.equal(requests.length, 1);
  assert.match(requests[0].url, /\/auth\/v1\/logout\?scope=local$/);
  assert.equal(requests[0].method, 'POST');
  assert.equal(requests[0].headers.Authorization, 'Bearer old');
  await assert.rejects(M.pedir('/rest/v1/empire_respostas'), expired);
});

test('sair com o token vencido renova uma vez só para revogar', async () => {
  const { M, requests } = boot(session(), req => refresh(req) ? reply(200, tokens)
    : req.headers.Authorization === 'Bearer old' ? reply(401, { message: 'JWT expired' }) : reply(204, null));
  assert.equal((await M.sair()).remoto, true);
  assert.equal(requests.length, 3);
  assert.equal(requests[2].headers.Authorization, 'Bearer new');
  assert.equal(M.sessao(), null);
});

test('o Auth recusa o token vencido com 403: sair renova uma vez e revoga', async () => {
  const { M, requests } = boot(session(), req => refresh(req) ? reply(200, tokens)
    : req.headers.Authorization === 'Bearer old' ? reply(403, { error_code: 'bad_jwt' }) : reply(204, null));
  assert.equal((await M.sair()).remoto, true);
  assert.equal(requests.length, 3);
  assert.equal(requests[2].headers.Authorization, 'Bearer new');
});

test('com a sessão já vencida, sair renova primeiro e revoga com o token novo', async () => {
  const { M, requests } = boot(session({ expira: 1 }), req => refresh(req) ? reply(200, tokens) : reply(204, null));
  assert.equal((await M.sair()).remoto, true);
  assert.equal(requests.length, 2);
  assert.ok(refresh(requests[0]));
  assert.match(requests[1].url, /\/auth\/v1\/logout\?scope=local$/);
  assert.equal(requests[1].headers.Authorization, 'Bearer new');
});

test('sem rede, sair fecha na mesma a sessão local e diz que o servidor não confirmou', async () => {
  const { M } = boot(session(), async () => { throw new TypeError('Failed to fetch'); });
  assert.equal((await M.sair()).remoto, false);
  assert.equal(M.sessao(), null);
});

test('armazenamento bloqueado mantém a sessão em memória', async () => {
  const { M, requests } = boot(null, req => reply(200, req.url.includes('grant_type=password') ? tokens : true), true);
  await M.entrar('teste@example.invalid', 'senha-de-teste');
  assert.equal(M.sessao().refresh, 'refresh-new');
  assert.equal(requests[1].headers.Authorization, 'Bearer new');
});

test('reporte público não depende da sessão de administração expirada', async () => {
  const { M, requests } = boot(session({ expira: 1 }), () => reply(204, null));
  const result = await M.enviarReporte({ tipo: 'erro', mensagem: 'Um reporte' }, {});
  assert.equal(result.erro, undefined); assert.equal(requests.length, 1);
  assert.equal(requests[0].headers.Authorization, 'Bearer public-test');
});
