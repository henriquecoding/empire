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
