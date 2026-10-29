// A bancada percorre pacote -> pixels -> observacao -> arquivo, sem enviar imagens.
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { createServer } from 'node:http';
import { readFileSync, existsSync, mkdirSync } from 'node:fs';
import { resolve, extname } from 'node:path';
const require=createRequire(resolve('ferramentas/package.json'));
const { chromium }=require('playwright');
const root=resolve('tools/web/site/forja');
const mime={'.html':'text/html','.js':'text/javascript','.css':'text/css'};
const server=createServer((req,res)=>{
  const path=new URL(req.url,'http://localhost').pathname, file=resolve(root,'.'+(path.endsWith('/')?path+'index.html':path));
  if(!file.startsWith(root+'/')||!existsSync(file)){res.writeHead(404);return res.end();}
  res.setHeader('Content-Type',mime[extname(file)]||'application/octet-stream');res.end(readFileSync(file));
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const url=`http://127.0.0.1:${server.address().port}`;
const browser=await chromium.launch({...(process.env.PLAYWRIGHT_CHROMIUM?{executablePath:process.env.PLAYWRIGHT_CHROMIUM}:{}),args:['--no-sandbox']});
mkdirSync('build/qa',{recursive:true});
try {
  for(const width of [390,1440]) {
    const context=await browser.newContext({viewport:{width,height:950},acceptDownloads:true});
    const page=await context.newPage(), errors=[], requests=[];
    page.on('pageerror',e=>errors.push(e.message));page.on('request',r=>requests.push(r));
    await page.goto(url);
    await page.locator('#demo80').click();await page.waitForFunction(()=>document.querySelector('#counter').textContent==='1 / 5');
    await page.locator('#scale').selectOption('1');
    assert.equal(await page.locator('#candidate').evaluate(c=>c.getBoundingClientRect().width),80);
    await page.locator('#skeleton').check();await page.locator('#onion').check();await page.locator('#trajectory').check();
    await page.locator('#difference').check();await page.locator('#background').selectOption('light');
    await page.locator('#play').click();await page.waitForFunction(()=>document.querySelector('#play').textContent==='Reproduzir');
    assert.equal(await page.locator('#counter').textContent(),'5 / 5');
    await page.locator('#previous').click();assert.equal(await page.locator('#counter').textContent(),'4 / 5');
    const packet=await page.evaluate(()=>JSON.stringify(ForjaRenderer.demo(64)));
    await page.locator('#package').setInputFiles({name:'review.json',mimeType:'application/json',buffer:Buffer.from(packet)});
    await page.waitForFunction(()=>document.querySelector('#counter').textContent==='1 / 8');
    await page.locator('#note').fill('Contacto conferido neste quadro.');await page.locator('#verdict').selectOption('observed');
    await page.locator('#reviewer').fill('Teste da bancada');
    const downloadPromise=page.waitForEvent('download');await page.locator('#save').click();const download=await downloadPromise;
    const notes=JSON.parse(readFileSync(await download.path(),'utf8'));
    assert.match(notes.loaded_file_sha256,/^[a-f0-9]{64}$/);assert.equal(notes.observations[0].status,'observed');
    assert.equal(notes.approval,'pending');
    await page.locator('#scale').selectOption('4');
    assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false);
    assert.equal(requests.some(r=>r.method()!=='GET'),false);
    assert.deepEqual(errors,[]);
    await page.screenshot({path:`build/qa/forja-${width}.png`,fullPage:true});
    await context.close();
  }
  console.log('Forja: desktop e mobile; pacote, encerramento, controlos, observacoes e privacidade OK.');
} finally {await browser.close();server.close();}
