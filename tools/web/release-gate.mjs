// A produção só constrói depois do workflow completo do mesmo commit na main.
// O repositório é público: não há token no browser nem segredo de deploy no CI.
import { mkdir, writeFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';

export const REPOSITORY = 'henriquecoding/empire';
export function matchingRun(runs, sha) {
  return runs.filter(run => run.head_sha === sha && run.head_branch === 'main'
    && run.event === 'push' && run.head_repository?.full_name === REPOSITORY)
    .sort((a, b) => b.run_number - a.run_number || b.run_attempt - a.run_attempt)[0];
}

export async function releaseGate({ env = process.env, request = fetch,
  wait = ms => new Promise(resolve => setTimeout(resolve, ms)), now = Date.now,
  timeout = 30 * 60 * 1000, log = console.log } = {}) {
  if (env.VERCEL_ENV !== 'production') return { gated: false };
  const sha = env.VERCEL_GIT_COMMIT_SHA;
  if (!/^[a-f0-9]{40}$/.test(sha ?? '') || env.VERCEL_GIT_COMMIT_REF !== 'main')
    throw new Error('Publicação recusada: é necessário o SHA completo da main.');
  const url = `https://api.github.com/repos/${REPOSITORY}/actions/workflows/ci.yml/runs?head_sha=${sha}&branch=main&event=push&per_page=100`;
  const deadline = now() + timeout;
  while (now() < deadline) {
    const response = await request(url, { headers: { Accept: 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28', 'User-Agent': 'empire-release-gate' },
      signal: AbortSignal.timeout(20_000) });
    if (!response.ok) throw new Error(`Não foi possível verificar o CI: HTTP ${response.status}.`);
    const body = await response.json();
    if (!Array.isArray(body.workflow_runs)) throw new Error('Resposta do CI inválida.');
    const run = matchingRun(body.workflow_runs, sha);
    if (run?.status === 'completed') {
      if (run.conclusion !== 'success') throw new Error(`Publicação recusada: CI ${run.conclusion} (${run.html_url}).`);
      return { gated: true, source_sha: sha, run_url: run.html_url, run_id: run.id,
        attempt: run.run_attempt, checked_at: new Date(now()).toISOString() };
    }
    log(`A aguardar CI da main para ${sha.slice(0, 12)}${run ? `: ${run.status}` : ': ainda sem execução'}`);
    await wait(60_000);
  }
  throw new Error('Publicação recusada: o CI do mesmo commit não ficou verde dentro do prazo.');
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    const proof = await releaseGate();
    if (proof.gated) {
      await mkdir('build', { recursive: true });
      await writeFile('build/ci-release-proof.json', JSON.stringify(proof, null, 2) + '\n');
      console.log(`CI confirmado: ${proof.run_url}`);
    }
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
