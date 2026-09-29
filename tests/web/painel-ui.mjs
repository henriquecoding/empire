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
let expireWrite = false, failRefresh = false, refreshes = 0, logins = 0;
await context.addInitScript(() => sessionStorage.setItem('empire.painel.sessao', JSON.stringify({token:'fixture',refresh:'fixture-refresh',email:'teste@example.invalid',expira:Date.now()+3600000})));
await context.route('https://*.supabase.co/**', async route => {
  const req = route.request(), path = new URL(req.url()).pathname;
  if (path.endsWith('/token')) {
    const isRefresh = req.url().includes('grant_type=refresh_token');
    if (isRefresh) refreshes++; else logins++;
    if (isRefresh && failRefresh) return route.fulfill({status:400,json:{message:'Invalid Refresh Token: Already Used'}});
    return route.fulfill({json:{access_token:'fixture-new',refresh_token:'fixture-refresh-new',expires_in:3600,user:{email:'teste@example.invalid'}}});
  }
  if (path.endsWith('empire_e_admin')) return route.fulfill({json:true});
  if (path.endsWith('empire_feedback')) return route.fulfill({json:[]});
  if (req.method() === 'GET') return route.fulfill(failRead ? {status:503,json:{message:'Teste de falha de leitura'}} : {json:rows});
  if (expireWrite) { expireWrite=false; return route.fulfill({status:401,json:{message:'JWT expired',code:'PGRST301'}}); }
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
  // O resumo do painel so se agarra a uma pergunta cujo texto nao mudou desde que foi escrito
  // (fonteHash): a Q-005 foi decidida no painel e perdeu-o; a Q-149 ainda esta aberta e tem-no.
  await choose('Q-149');
  assert.match(await page.locator('#Q-149').innerText(), /1,6 vezes/);
  await choose('Q-005');
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
  await choose('Q-044'); await page.locator('#Q-044 input[value=outra]').check();
  await page.locator('#Q-044 textarea').fill('Resposta preservada durante a renovação.');
  const beforeRefresh = writes; expireWrite=true;
  await page.locator('#Q-044 button[type=submit]').click(); await page.locator('#Q-044 .p-guardado.feito').waitFor();
  assert.equal(refreshes,1); assert.equal(writes,beforeRefresh+1); assert.equal(logins,0);
  assert.equal(rows.find(r=>r.pergunta==='Q-044').texto,'Resposta preservada durante a renovação.');
  await page.locator('#Q-044 textarea').fill('Rascunho que sobrevive ao novo login.');
  await choose('Q-045'); await page.locator('#Q-045 input[value=outra]').check();
  await page.locator('#Q-045 textarea').fill('Outra decisão também por guardar.');
  await choose('Q-044'); failRefresh=true; expireWrite=true; const beforeLogin=writes;
  await page.locator('#Q-044 button[type=submit]').click(); await page.locator('#entrar').waitFor({state:'visible'});
  assert.match(await page.locator('#entrar-ajuda').innerText(),/continuam nesta aba/);
  assert.equal(await page.locator('#en-email').inputValue(),'teste@example.invalid');
  assert.equal(await page.locator('#Q-044 textarea').inputValue(),'Rascunho que sobrevive ao novo login.');
  await page.setViewportSize({width:360,height:900});
  const loginAxe = await new AxeBuilder({page}).withTags(['wcag2a','wcag2aa','wcag21aa']).analyze();
  assert.deepEqual(loginAxe.violations.map(v=>v.id),[],'acessibilidade do novo login');
  failRefresh=false; await page.locator('#en-senha').fill('senha-de-teste');
  await page.locator('#entrar-form button').click(); await page.locator('#Q-044 button[type=submit]').waitFor({state:'visible'});
  await page.waitForFunction(() => !document.querySelector('#Q-044 button[type=submit]').disabled);
  assert.equal(writes,beforeLogin,'o login não submete automaticamente a decisão'); assert.equal(logins,1);
  assert.equal(await page.locator('#Q-044 input[value=outra]').isChecked(),true);
  assert.equal(await page.locator('#Q-044 textarea').inputValue(),'Rascunho que sobrevive ao novo login.');
  await page.locator('#Q-044 button[type=submit]').click(); await page.locator('#Q-044 .p-guardado.feito').waitFor();
  await choose('Q-045'); assert.equal(await page.locator('#Q-045 textarea').inputValue(),'Outra decisão também por guardar.');
  await page.locator('#Q-045 button[type=submit]').click(); await page.locator('#Q-045 .p-guardado.feito').waitFor();
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
  console.log('PASS: renovação, novo login sem perda nem envio automático, contexto, estados, rascunhos, erros, teclado e axe.');
} finally { await browser.close(); server.close(); }
