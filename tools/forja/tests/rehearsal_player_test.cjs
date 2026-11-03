// Regressao do player sem navegador: DOM/canvas simulados; pixels conferidos no teste Python.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const html = fs.readFileSync(process.argv[2], 'utf8');
const payload = html.match(/<script id="data" type="application\/json">([\s\S]*?)<\/script>/)[1];
const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
const elements = {};
const get = id => elements[id] ??= {
  value: '', checked: id === 'pivot', textContent: '', children: [], draws: [],
  append(child) { this.children.push(child); },
  getContext() { return {fillRect() {}, drawImage: (...args) => this.draws.push(args)}; }
};
get('data').textContent = payload;
get('zoom').value = '4';
get('background').value = '#28221e';
let nextTick;
const context = {
  document: {getElementById: get, createElement: () => ({}), addEventListener() {}},
  Image: class {decode() { return Promise.resolve(); }},
  performance: {now: () => 0}, requestAnimationFrame: fn => { nextTick = fn; }
};
vm.runInNewContext(script, context);
setImmediate(() => {
  assert.ok(nextTick, 'player initialized after decoding images');
  assert.equal(get('native').width, 64);
  assert.equal(get('large').width, 256);
  assert.match(get('status').textContent, /idle · quadro 0 · 90 ms/);
  get('play').onclick();
  nextTick(89);
  assert.match(get('status').textContent, /quadro 0/);
  nextTick(90);
  assert.match(get('status').textContent, /attack · quadro 2 · 140 ms/);
  nextTick(229);
  assert.match(get('status').textContent, /quadro 2/);
  nextTick(230);
  assert.match(get('status').textContent, /attack · quadro 1 · 65 ms/);
  get('action').value = 'attack';
  get('action').onchange();
  assert.equal(get('seek').max, 1);
  assert.match(get('status').textContent, /quadro 2/);
  get('next').onclick();
  get('effects').checked = true;
  get('effects').onchange();
  assert.match(get('status').textContent, /quadro 1 · 65 ms.*composição final/);
  const m = JSON.parse(payload);
  assert.equal(get('native').draws.at(-1)[0].src, m.images.final['1']);
  get('zoom').value = '2';
  get('zoom').onchange();
  assert.equal(get('large').width, 128);
  get('play').onclick();
  nextTick(1);
  assert.match(get('status').textContent, /quadro 2/, 'replay restarts from first frame');
  console.log('player: native scale, reverse order, exact durations, effects, controls and restart OK');
});
