// A produção só constrói depois do workflow completo do mesmo commit na main.
// O repositório é público: não há token no browser nem segredo de deploy no CI.
// Sem token, a API do GitHub dá 60 pedidos por hora a cada IP, e a máquina de build
// da Vercel partilha o dela com outros projetos: um limite esgotado não é um CI
// vermelho, é uma espera (a 19/10 o 722fad6 morreu num 403 a cinco minutos do verde).
// Um EMPIRE_GITHUB_TOKEN só de leitura nas variáveis da Vercel, que só o build vê, sobe-o
// para 5000 por hora.
import { mkdir, writeFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';

export const REPOSITORY = 'henriquecoding/empire';
// O CI da main leva ~20 min: de dois em dois minutos são ~10 pedidos, e não ~20.
const INTERVALO = 2 * 60 * 1000;
const UM_MINUTO = 60 * 1000;

export function matchingRun(runs, sha) {
  return runs.filter(run => run.head_sha === sha && run.head_branch === 'main'
    && run.event === 'push' && run.head_repository?.full_name === REPOSITORY)
    .sort((a, b) => b.run_number - a.run_number || b.run_attempt - a.run_attempt)[0];
}

// Quanto esperar antes de voltar a pedir quando a resposta é o limite da API, e não uma
// recusa — como a documentação do GitHub diz para o ler. null se não é o limite.
function esperaDoLimite(response, mensagem, agora) {
  if (response.status !== 403 && response.status !== 429) return null;
  const cabecalho = k => response.headers?.get?.(k) ?? null;
  const depois = Number(cabecalho('retry-after'));
  if (depois > 0) return depois * 1000;
  if (cabecalho('x-ratelimit-remaining') === '0') {
    const renova = Number(cabecalho('x-ratelimit-reset'));
    return renova > 0 ? Math.max(1000, renova * 1000 - agora + 1000) : UM_MINUTO;
  }
  return response.status === 429 || /rate limit/i.test(mensagem) ? UM_MINUTO : null;
}

async function mensagemDe(response) {
  try { return String(JSON.parse(await response.text()).message ?? '').slice(0, 200); } catch { return ''; }
}

export async function releaseGate({ env = process.env, request = fetch,
  wait = ms => new Promise(resolve => setTimeout(resolve, ms)), now = Date.now,
  timeout = 30 * 60 * 1000, log = console.log } = {}) {
  if (env.VERCEL_ENV !== 'production') return { gated: false };
  const sha = env.VERCEL_GIT_COMMIT_SHA;
  if (!/^[a-f0-9]{40}$/.test(sha ?? '') || env.VERCEL_GIT_COMMIT_REF !== 'main')
    throw new Error('Publicação recusada: é necessário o SHA completo da main.');
  const url = `https://api.github.com/repos/${REPOSITORY}/actions/workflows/ci.yml/runs?head_sha=${sha}&branch=main&event=push&per_page=100`;
  const headers = { Accept: 'application/vnd.github+json', 'X-GitHub-Api-Version': '2022-11-28', 'User-Agent': 'empire-release-gate' };
  // Uma quebra de linha no meio do token faria o fetch recusar o cabeçalho com uma mensagem
  // que o repete inteiro: para-se antes de pedir, e sem o escrever.
  const token = (env.EMPIRE_GITHUB_TOKEN ?? '').trim();
  if (token && !/^[\x21-\x7e]+$/.test(token))
    throw new Error('Publicação recusada: o EMPIRE_GITHUB_TOKEN tem espaços, quebras de linha ou caracteres que não cabem num cabeçalho.');
  if (token) headers.Authorization = `Bearer ${token}`;
  const semToken = m => (token ? String(m).split(token).join('***') : String(m));
  const deadline = now() + timeout;
  let falha = '';
  for (;;) {
    let response = null, body = null;
    try {
      response = await request(url, { headers, signal: AbortSignal.timeout(20_000) });
      if (response.ok) body = await response.json();  // a ligação pode cair a meio do corpo
    } catch (error) {
      response = null;
      falha = `rede: ${semToken(error.message)}`;
    }
    if (response?.ok) {
      falha = '';
      if (!Array.isArray(body?.workflow_runs)) throw new Error('Resposta do CI inválida.');
      const run = matchingRun(body.workflow_runs, sha);
      if (run?.status === 'completed') {
        if (run.conclusion !== 'success') throw new Error(`Publicação recusada: CI ${run.conclusion} (${run.html_url}).`);
        return { gated: true, source_sha: sha, run_url: run.html_url, run_id: run.id,
          attempt: run.run_attempt, checked_at: new Date(now()).toISOString() };
      }
      const resta = response.headers?.get?.('x-ratelimit-remaining');
      log(`A aguardar CI da main para ${sha.slice(0, 12)}${run ? `: ${run.status}` : ': ainda sem execução'}`
        + (resta ? ` (API: ${resta} pedidos restantes)` : ''));
    } else if (response) {
      const mensagem = await mensagemDe(response);
      const espera = esperaDoLimite(response, mensagem, now());
      if (espera !== null) {
        if (now() + espera >= deadline) {
          throw new Error('Publicação recusada: o limite de pedidos da API do GitHub só renova depois do prazo'
            + (token ? '.' : ' (um EMPIRE_GITHUB_TOKEN só de leitura na Vercel tira-o).'));
        }
        log(`Limite de pedidos da API do GitHub esgotado: a esperar ${Math.ceil(espera / 1000)} s.`);
        await wait(espera);
        continue;
      }
      if (response.status < 500) throw new Error(`Não foi possível verificar o CI: HTTP ${response.status}${mensagem ? ` (${mensagem})` : ''}.`);
      falha = `HTTP ${response.status}`;
    }
    if (falha) log(`O GitHub não respondeu (${falha}): volta-se a pedir.`);
    // O último pedido cai no fim do prazo: um CI que fique verde nos dois minutos finais conta.
    const falta = deadline - now();
    if (falta <= 0) break;
    await wait(Math.min(INTERVALO, falta));
  }
  throw new Error(`Publicação recusada: o CI do mesmo commit não ficou verde dentro do prazo${falha ? ` (último erro: ${falha})` : ''}.`);
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
