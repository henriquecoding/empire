// Executa contra build/site. A API é simulada: não escreve respostas reais.
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { createServer } from 'node:http';
import { readFileSync, existsSync, mkdirSync } from 'node:fs';
import { resolve, extname } from 'node:path';
const require = createRequire(resolve('ferramentas/LEIA-ME.md'));
const { chromium } = require('playwright');
const { default: AxeBuilder } = require('@axe-core/playwright');
const root = resolve('build/site');
const mime = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.woff2': 'font/woff2', '.svg': 'image/svg+xml' };
const server = createServer((req, res) => {
  let path = new URL(req.url, 'http://localhost').pathname;
  if (path.endsWith('/')) path += 'index.html';
  const file = resolve(root, '.' + path);
  if (!file.startsWith(root + '/') || !existsSync(file)) { res.writeHead(404); return res.end(); }
  res.setHeader('Content-Type', mime[extname(file)] || 'application/octet-stream'); res.end(readFileSync(file));
});
await new Promise(r => server.listen(0, '127.0.0.1', r));
const url = `http://127.0.0.1:${server.address().port}/painel/`;
const browser = await chromium.launch({ headless: true, ...(process.env.CHROMIUM_PATH ? {executablePath: process.env.CHROMIUM_PATH} : {}), args: ['--no-sandbox'] });
const context = await browser.newContext();
let rows = [{ pergunta: 'Q-001', escolha: 'aprovar', texto: null, estado: 'nova' }], writes = 0, failRead = false, failWrite = false;
await context.addInitScript(() => sessionStorage.setItem('empire.painel.sessao', JSON.stringify({token:'fixture',email:'teste@example.invalid',expira:Date.now()+3600000})));
await context.route('https://*.supabase.co/**', async route => {
  const req = route.request(), path = new URL(req.url()).pathname;
  if (path.endsWith('empire_e_admin')) return route.fulfill({json:true});
  if (path.endsWith('empire_feedback')) return route.fulfill({json:[]});
  if (req.method() === 'GET') return route.fulfill(failRead ? {status:503,json:{message:'Teste de falha de leitura'}} : {json:rows});
  writes++;
  if (failWrite) return route.fulfill({status:503,json:{message:'Teste de falha de gravação'}});
  const sent = req.postDataJSON();
  for (const row of sent) rows = [...rows.filter(r => r.pergunta !== row.pergunta), row];
  return route.fulfill({json:sent});
});
const page = await context.newPage();
const errors=[]; page.on('pageerror', e => errors.push(e.message));
const choose = async id => { await page.locator('#f-estado').selectOption(''); await page.locator('#f-texto').fill(id); await page.locator(`[data-pergunta="${id}"]`).click(); };
try {
  await page.goto(url); await page.locator('#area').waitFor({state:'visible'});
  await page.waitForFunction(() => document.querySelector('#c-por').textContent !== '—');
  assert.equal(await page.locator('#c-respondidas').textContent(), '1');
  await choose('Q-005');
  assert.equal(await page.locator('#Q-005 .decisao-bloco').first().isVisible(),true);
  assert.match(await page.locator('#Q-005').innerText(), /28%/);
  await page.locator('#Q-005 input[value=outra]').check();
  await page.locator('#Q-005 textarea').fill('Rascunho que não pode desaparecer.');
  await choose('Q-002'); await page.locator('#Q-002 input[value=aprovar]').check();
  await page.locator('#Q-002 button[type=submit]').click();
  await page.locator('#Q-002 .p-guardado.feito').waitFor(); assert.equal(writes,1);
  await choose('Q-005'); assert.equal(await page.locator('#Q-005 textarea').inputValue(),'Rascunho que não pode desaparecer.');
  failWrite=true; await page.locator('#Q-005 button[type=submit]').click();
  await page.locator('#Q-005 .p-guardado.erro').waitFor();
  assert.equal(await page.locator('#Q-005 textarea').inputValue(),'Rascunho que não pode desaparecer.');
  failWrite=false; await page.locator('#Q-005 input[value=adiar]').check();
  await page.locator('#Q-005 button[type=submit]').click(); await page.locator('#Q-005 .p-guardado.feito').waitFor();
  assert.equal(await page.locator('#c-adiadas').textContent(),'1');
  assert.equal(await page.locator('#c-respondidas').textContent(),'2');
  await choose('Q-006'); assert.equal(await page.locator('#Q-006 form').count(),0);
  await choose('Q-143'); assert.equal(await page.locator('#Q-143 input[value=aprovar]').count(),0);
  assert.match(await page.locator('#Q-143 .pendencia').innerText(),/identidade/);
  await page.locator('#f-texto').fill('nenhum-termo-deste-tipo'); assert.equal(await page.locator('#sem-resultados').isVisible(),true);
  await page.locator('#limpar-filtros').click(); await choose('Q-005');
  mkdirSync('build/qa', {recursive:true});
  for(const theme of ['light','dark']) for(const width of [320,360,768,1440]) {
    await page.setViewportSize({width,height:1000});
    await page.evaluate(theme => document.documentElement.dataset.theme=theme, theme);
    await page.locator('#Q-005').scrollIntoViewIfNeeded();
    assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth),true, `overflow ${theme} ${width}`);
    const axe = await new AxeBuilder({page}).withTags(['wcag2a','wcag2aa','wcag21aa']).analyze();
    assert.deepEqual(axe.violations.map(v=>({id:v.id,nodes:v.nodes.map(n=>n.target)})),[],`axe ${theme} ${width}`);
    await page.screenshot({path:`build/qa/painel-${theme}-${width}.png`});
  }
  await page.locator('#tab-perguntas').focus(); await page.keyboard.press('ArrowRight');
  assert.equal(await page.locator('#reportes').isVisible(),true);
  await page.keyboard.press('Home'); assert.equal(await page.locator('#perguntas').isVisible(),true);
  failRead=true; await page.reload(); await page.locator('#recarregar').waitFor({state:'visible'});
  assert.equal(await page.locator('#Q-005 button[type=submit]').isDisabled(),true);
  failRead=false; await page.locator('#recarregar').click(); await page.waitForFunction(() => !document.querySelector('#copiar').disabled);
  assert.deepEqual(errors,[]);
  console.log('PASS: contexto, estados, rascunhos, gravação, erros, teclado e axe em 8 combinações.');
} finally { await browser.close(); server.close(); }
