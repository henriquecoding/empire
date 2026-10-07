// Contratos do primeiro contacto, contra o artefacto publicado. A API é simulada.
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { createServer } from 'node:http';
import { readFileSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { resolve, extname } from 'node:path';
const require = createRequire(resolve('ferramentas/LEIA-ME.md'));
const { chromium } = require('playwright');
const root = resolve('build/site');
const mime = { '.html':'text/html', '.js':'text/javascript', '.css':'text/css', '.woff2':'font/woff2', '.webp':'image/webp', '.svg':'image/svg+xml' };
const server = createServer((req, res) => {
  let path = new URL(req.url, 'http://localhost').pathname;
  if (path.endsWith('/')) path += 'index.html';
  const file = resolve(root, '.' + path);
  if (!file.startsWith(root + '/') || !existsSync(file)) { res.writeHead(404); return res.end(); }
  res.setHeader('Content-Type', mime[extname(file)] || 'application/octet-stream'); res.end(readFileSync(file));
});
await new Promise(r => server.listen(0, '127.0.0.1', r));
const url = `http://127.0.0.1:${server.address().port}`;
const browser = await chromium.launch({ ...(process.env.PLAYWRIGHT_CHROMIUM ? { executablePath:process.env.PLAYWRIGHT_CHROMIUM } : {}), args:['--no-sandbox'] });
const measurements = [];
mkdirSync('build/qa', {recursive:true});
try {
  for (const route of ['/', '/en/']) {
    for (const width of [390, 1440]) {
      const ctx = await browser.newContext({viewport:{width, height:900}, reducedMotion:'reduce', colorScheme:'dark'});
      const page = await ctx.newPage(), requests = [], errors = [];
      page.on('request', r => requests.push(r.url())); page.on('pageerror', e => errors.push(e.message));
      await page.goto(url + route);
      await page.locator('.quadro.ativo').evaluate(img => img.decode());
      assert.equal(requests.some(r => r.includes('/jogar/')), false, 'não descarrega o motor sem intenção');
      assert.equal(await page.locator('#pausa').getAttribute('aria-pressed'), 'true');
      assert.equal(await page.locator('#comecar li').count(), 3);
      const cta = await page.locator('.abertura .principal').boundingBox();
      assert.ok(cta.y + cta.height < 900, 'Jogar visível no primeiro ecrã');
      assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > innerWidth), false);
      const resources = await page.evaluate(() => performance.getEntriesByType('resource').map(r => ({path:new URL(r.name).pathname, bytes:r.decodedBodySize})));
      const picture = await page.locator('.quadro.ativo').evaluate(img => new URL(img.currentSrc).pathname);
      assert.ok(picture.includes(width < 640 ? 'mini-manha' : 'dia-manha'));
      measurements.push({route, width, picture, resources, initialResourceBytes:resources.reduce((n,r) => n+r.bytes,0)});
      await page.screenshot({path:`build/qa/entrada-${route === '/' ? 'pt' : 'en'}-${width}.png`});
      if (width === 390) {
        await page.locator('#abre-menu').click();
        await page.keyboard.press('Escape');
        assert.equal(await page.locator('#abre-menu').getAttribute('aria-expanded'), 'false');
        assert.equal(await page.locator('#abre-menu').evaluate(e => e === document.activeElement), true);
        await page.locator('#abre-menu').click();
        await page.locator('.abertura .principal').focus();
        assert.equal(await page.locator('#abre-menu').getAttribute('aria-expanded'), 'false');
      }
      assert.deepEqual(errors, []);
      await ctx.close();
    }
  }
  // A falha do JS partilhado não esconde conteúdo nem os links móveis.
  const fallback = await browser.newContext({viewport:{width:390,height:844}});
  await fallback.route('**/assets/site.*.js', r => r.abort());
  const pf = await fallback.newPage(); await pf.goto(url);
  assert.equal(await pf.locator('#menu a').first().isVisible(), true);
  assert.equal(await pf.locator('#comecar').evaluate(e => getComputedStyle(e).opacity), '1');
  await fallback.close();
  // Save-Data e toque começam parados; a intenção de jogar não vence Save-Data.
  const saving = await browser.newContext({isMobile:true,hasTouch:true,viewport:{width:390,height:844}});
  await saving.addInitScript(() => Object.defineProperty(navigator, 'connection', {value:{saveData:true,effectiveType:'4g',addEventListener(){}}}));
  const ps = await saving.newPage(), savingRequests = [];
  ps.on('request', r => savingRequests.push(r.url())); await ps.goto(url);
  await ps.locator('.abertura .principal').focus();
  assert.equal(await ps.locator('#pausa').getAttribute('aria-pressed'), 'true');
  assert.equal(savingRequests.some(r => r.includes('/jogar/')), false);
  await ps.locator('#fita-palco').focus(); await ps.keyboard.press('End');
  await ps.waitForFunction(() => document.querySelector('.quadro.ativo').dataset.fase === 'night');
  await saving.close();
  for (const route of ['/reportar/', '/en/report/']) {
    const ctx = await browser.newContext(); let writes = 0, release;
    await ctx.route('https://*.supabase.co/**', async r => {
      writes++; await new Promise(resolve => { release = resolve; });
      await r.fulfill({status:201,json:[]});
    });
    const page = await ctx.newPage(); await page.goto(url + route);
    assert.equal(await page.locator('.lingua').getAttribute('href'), route === '/reportar/' ? '/en/report/' : '/reportar/');
    await page.locator('#r-enviar').click();
    assert.equal(await page.locator('#r-mensagem').getAttribute('aria-invalid'), 'true');
    assert.equal(await page.locator('#r-mensagem').evaluate(e => e === document.activeElement), true);
    await page.locator('#r-mensagem').fill('Relato de teste: a primeira noite do reino.');
    await page.locator('#r-enviar').click();
    await page.waitForFunction(() => document.querySelector('#reportar').getAttribute('aria-busy') === 'true');
    await page.locator('#reportar').dispatchEvent('submit');
    await page.waitForTimeout(50);
    assert.equal(writes, 1, 'um único POST durante envio pendente');
    release(); await page.locator('#r-outro').waitFor({state:'visible'});
    assert.equal(await page.locator('#reportar').getAttribute('aria-busy'), 'false');
    assert.equal(await page.locator('#r-mensagem').getAttribute('aria-invalid'), null);
    await ctx.close();
  }
  writeFileSync('build/qa/site-experience.json', JSON.stringify(measurements,null,2)+'\n');
  console.log('experience-ui: PT/EN, mobile/desktop, rede poupada, teclado, JS indisponível, validação e envio único — passam');
} finally { await browser.close(); server.close(); }
