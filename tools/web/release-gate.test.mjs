import { test } from 'node:test';
import assert from 'node:assert/strict';
import { releaseGate, REPOSITORY } from './release-gate.mjs';
const sha = 'a'.repeat(40);
const env = { VERCEL_ENV: 'production', VERCEL_GIT_COMMIT_REF: 'main', VERCEL_GIT_COMMIT_SHA: sha };
const run = { head_sha: sha, head_branch: 'main', event: 'push', head_repository: { full_name: REPOSITORY },
  run_number: 4, run_attempt: 1, id: 42, html_url: 'https://github.com/henriquecoding/empire/actions/runs/42', status: 'completed', conclusion: 'success' };
function setup(runs) {
  let time = 0;
  return { env, now: () => time, wait: async () => { time += 60_000; }, timeout: 120_000,
    log() {}, request: async () => ({ ok: true, json: async () => ({ workflow_runs: runs }) }) };
}
test('production accepts only successful CI for the exact main commit', async () => {
  assert.equal((await releaseGate(setup([run]))).source_sha, sha);
});
test('a green PR or an older SHA cannot authorize production', async () => {
  for (const change of [{ head_sha: 'b'.repeat(40) }, { event: 'pull_request' }, { head_branch: 'work' }, { head_repository: { full_name: 'someone/fork' } }])
    await assert.rejects(releaseGate(setup([{ ...run, ...change }])), /dentro do prazo/);
});
test('failed, cancelled and skipped checks block publication', async () => {
  for (const conclusion of ['failure', 'cancelled', 'skipped', 'timed_out'])
    await assert.rejects(releaseGate(setup([{ ...run, conclusion }])), /Publicação recusada/);
});
test('pending CI is waited for and the newest attempt wins', async () => {
  let count = 0;
  const options = setup([]);
  options.request = async () => ({ ok: true, json: async () => ({ workflow_runs: [run,
    { ...run, run_attempt: 2, status: ++count === 1 ? 'in_progress' : 'completed' }] }) });
  assert.equal((await releaseGate(options)).attempt, 2);
  assert.equal(count, 2);
});
test('missing SHA, network errors and absent workflow fail closed', async () => {
  await assert.rejects(releaseGate({ ...setup([run]), env: { ...env, VERCEL_GIT_COMMIT_SHA: '' } }), /SHA completo/);
  await assert.rejects(releaseGate({ ...setup([]), request: async () => ({ ok: false, status: 403 }) }), /HTTP 403/);
  await assert.rejects(releaseGate(setup([])), /dentro do prazo/);
});
test('local and preview builds never wait on their own CI', async () => {
  for (const VERCEL_ENV of ['', 'preview']) assert.deepEqual(await releaseGate({ env: { VERCEL_ENV } }), { gated: false });
});

// A API do GitHub sem token dá 60 pedidos por hora a cada IP, e a máquina de build da
// Vercel partilha o dela: a 19/10 o deploy do 722fad6 morreu num 403 a cinco minutos de o
// CI ficar verde. Este relógio anda o que se pede a wait(), para medir as esperas, e
// começa numa data a sério: o x-ratelimit-reset é uma hora em segundos, não uma duração.
const T0 = 1_792_000_000_000;
const cabecalhos = h => ({ get: k => h[k.toLowerCase()] ?? null });
const resposta = (status, h = {}, corpo = {}) => ({ ok: status < 400, status, headers: cabecalhos(h),
  json: async () => corpo, text: async () => JSON.stringify(corpo) });
const verde = resposta(200, {}, { workflow_runs: [run] });
const pendente = resposta(200, { 'x-ratelimit-remaining': '41' }, { workflow_runs: [{ ...run, status: 'in_progress' }] });
const esgotado = (h, message = 'API rate limit exceeded for 1.2.3.4.') => resposta(403, h, { message });
function relogio(respostas, mais = {}) {
  let time = T0;
  const fila = [...respostas], esperas = [], registos = [], pedidos = [];
  const opcoes = { env, now: () => time, timeout: 30 * 60_000, log: m => registos.push(m),
    wait: async ms => { esperas.push(ms); time += ms; },
    request: async (url, init) => {
      pedidos.push(init);
      const r = fila.length > 1 ? fila.shift() : fila[0];
      if (r instanceof Error) throw r;
      return typeof r === 'function' ? r(time - T0) : r;
    }, ...mais };
  return { opcoes, esperas, registos, pedidos };
}
test('an exhausted API limit is a wait until it renews, not a refusal', async () => {
  const renova = s => String(T0 / 1000 + s);
  const primario = relogio([esgotado({ 'x-ratelimit-remaining': '0', 'x-ratelimit-reset': renova(300) }), verde]);
  assert.equal((await releaseGate(primario.opcoes)).source_sha, sha);
  assert.ok(primario.esperas[0] >= 300_000 && primario.esperas[0] <= 305_000, `esperou ${primario.esperas[0]} ms`);
  const tarde = relogio([resposta(429, { 'retry-after': '90' }), verde]);
  assert.equal((await releaseGate(tarde.opcoes)).source_sha, sha);
  assert.deepEqual(tarde.esperas, [90_000]);
  const secundario = relogio([esgotado({}, 'You have exceeded a secondary rate limit.'), verde]);
  assert.equal((await releaseGate(secundario.opcoes)).source_sha, sha);
  assert.deepEqual(secundario.esperas, [60_000]);
  for (const r of [primario, tarde, secundario]) assert.equal(r.pedidos.length, 2, 'depois da espera volta a pedir');
  // A espera não autoriza nada: um CI vermelho depois do limite continua a recusar.
  const vermelho = relogio([esgotado({ 'x-ratelimit-remaining': '0', 'x-ratelimit-reset': renova(300) }),
    resposta(200, {}, { workflow_runs: [{ ...run, conclusion: 'failure' }] })]);
  await assert.rejects(releaseGate(vermelho.opcoes), /CI failure/);
});
test('a limit that only renews after the deadline refuses at once, and says why', async () => {
  const { opcoes, esperas } = relogio([esgotado({ 'x-ratelimit-remaining': '0', 'x-ratelimit-reset': String(T0 / 1000 + 3600) })]);
  await assert.rejects(releaseGate(opcoes), /limite de pedidos/);
  assert.deepEqual(esperas, []);
});
test('network errors and GitHub 5xx are retried, and fail closed at the deadline', async () => {
  const volta = relogio([new Error('fetch failed'), resposta(502), verde]);
  assert.equal((await releaseGate(volta.opcoes)).source_sha, sha);
  assert.equal(volta.esperas.length, 2);
  await assert.rejects(releaseGate(relogio([new Error('fetch failed')]).opcoes), /dentro do prazo.*fetch failed/);
  // A ligação que cai a meio do corpo também é rede.
  const corpo = relogio([{ ...verde, json: async () => { throw new TypeError('terminated'); } }, verde]);
  assert.equal((await releaseGate(corpo.opcoes)).source_sha, sha);
  assert.equal(corpo.pedidos.length, 2);
});
test('the last poll lands on the deadline, so a CI that goes green late still counts', async () => {
  // Pendente até aos 29,5 min de 30: de dois em dois minutos, o pedido dos 28 vê-o pendente,
  // e é o pedido no fim do prazo que o vê verde.
  const tarde = t => (t < 29.5 * 60_000 ? pendente : verde);
  const { opcoes, pedidos } = relogio([tarde]);
  assert.equal((await releaseGate(opcoes)).source_sha, sha);
  assert.equal(pedidos.length, 16);
});
test('a refusal that is not a rate limit still stops at once, with GitHub’s reason', async () => {
  const { opcoes, esperas } = relogio([esgotado({}, 'Resource not accessible by integration')]);
  await assert.rejects(releaseGate(opcoes), /HTTP 403.*Resource not accessible/);
  assert.deepEqual(esperas, []);
});
test('an optional read-only token is sent, and never written to the log', async () => {
  const com = relogio([pendente, verde], { env: { ...env, EMPIRE_GITHUB_TOKEN: 'ghp_segredo' } });
  await releaseGate(com.opcoes);
  assert.equal(com.pedidos[0].headers.Authorization, 'Bearer ghp_segredo');
  assert.ok(com.registos.length && !com.registos.join('\n').includes('ghp_segredo'));
  const sem = relogio([verde]);
  await releaseGate(sem.opcoes);
  assert.equal(sem.pedidos[0].headers.Authorization, undefined);
  const espacos = relogio([verde], { env: { ...env, EMPIRE_GITHUB_TOKEN: '  ghp_segredo\n' } });
  await releaseGate(espacos.opcoes);
  assert.equal(espacos.pedidos[0].headers.Authorization, 'Bearer ghp_segredo');
});
test('a malformed token refuses at once, without a request and without echoing it', async () => {
  // Uma quebra de linha no meio faz o fetch recusar o cabeçalho com uma mensagem que o
  // repete inteiro: o portão tem de parar antes de pedir, e com uma mensagem fixa.
  for (const token of ['ghp_segredo\nghp_outro', 'ghp_se gredo', 'ghp_segredo\r\nx']) {
    const { opcoes, pedidos, registos } = relogio([verde], { env: { ...env, EMPIRE_GITHUB_TOKEN: token } });
    const erro = await releaseGate(opcoes).then(() => null, e => e);
    assert.match(erro?.message ?? '', /EMPIRE_GITHUB_TOKEN/);
    assert.ok(!erro.message.includes('segredo') && !registos.join('\n').includes('segredo'));
    assert.equal(pedidos.length, 0);
  }
});
test('polls every two minutes, and says how much of the API limit is left', async () => {
  const { opcoes, esperas, registos } = relogio([pendente, verde]);
  await releaseGate(opcoes);
  assert.deepEqual(esperas, [120_000]);
  assert.match(registos[0], /41/);
});
