// tests/web/reportes.test.mjs — a triagem visita todos os reportes (BUG-06).
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import test from 'node:test';

const source = readFileSync('tools/web/paginas/painel-reportes.js', 'utf8');

class Element {
  constructor(tag) { this.tag = tag; this.children = []; this.handlers = {}; this.value = ''; this._text = ''; this.dataset = {}; this.parent = null; }
  set textContent(v) { this._text = v; this.children = []; }
  get textContent() { return this._text; }
  appendChild(e) { e.parent = this; this.children.push(e); return e; }
  addEventListener(e, fn) { this.handlers[e] = fn; }
  replaceChildren(...items) { this.children = items; }
  querySelectorAll() { return []; }
  setAttribute() {}
  remove() { if (this.parent) this.parent.children = this.parent.children.filter(c => c !== this); }
}

// Um PostgREST de brincar que percebe a consulta que o painel faz.
function servidor(linhas) {
  return path => {
    const url = new URL('https://x' + path);
    const limite = Number(url.searchParams.get('limit'));
    const estado = url.searchParams.get('estado');
    const ou = url.searchParams.get('or');
    let lista = [...linhas].sort((a, b) => b.criado_em.localeCompare(a.criado_em) || b.id.localeCompare(a.id));
    if (estado) lista = lista.filter(r => 'eq.' + r.estado === estado);
    if (ou) {
      const m = ou.match(/^\(criado_em\.lt\."([^"]+)",and\(criado_em\.eq\."([^"]+)",id\.lt\.([^)]+)\)\)$/);
      assert.ok(m, 'cursor mal formado: ' + ou);
      lista = lista.filter(r => r.criado_em < m[1] || (r.criado_em === m[2] && r.id < m[3]));
    }
    return lista.slice(0, limite);
  };
}

function boot(linhas) {
  const nodes = Object.fromEntries(['lista-reportes', 'fr-estado', 'fr-estado-msg', 'fr-atualizar'].map(id => [id, new Element(id)]));
  const pedidos = [];
  const responder = servidor(linhas);
  const win = { EmpireMotor: { sessao: () => ({ email: 'teste@example.invalid' }), sanitizar: s => s,
    pedir: path => { pedidos.push(path); return Promise.resolve(responder(path)); } } };
  runInNewContext(source, { window: win, sessionStorage: { getItem: () => null, setItem() {} },
    document: { getElementById: id => nodes[id], createElement: tag => new Element(tag) } });
  return { R: win.EmpireReportes, nodes, pedidos };
}

const flush = () => new Promise(r => setImmediate(r));
const cartoes = lista => lista.children.filter(c => c.tag === 'article');
const botao = lista => lista.children.find(c => c.tag === 'button');

test('401 reportes com datas empatadas: todos aparecem uma vez, por páginas', async () => {
  const linhas = Array.from({ length: 401 }, (_, i) => ({
    id: String(i).padStart(4, '0'), tipo: 'erro', estado: 'novo', mensagem: 'm' + i,
    criado_em: '2026-10-06T00:00:' + String(Math.floor(i / 7)).padStart(2, '0') + '.000000+00:00',
  }));
  const { R, nodes, pedidos } = boot(linhas);
  R.carregar(); await flush();
  const lista = nodes['lista-reportes'];
  while (botao(lista)) { botao(lista).handlers.click(); await flush(); }
  const vistos = cartoes(lista).map(c => c.dataset.reporte);
  assert.equal(vistos.length, 401);
  assert.equal(new Set(vistos).size, 401);
  assert.equal(pedidos.length, 5);
  assert.match(nodes['fr-estado-msg'].textContent, /^401 reporte\(s\)\.$/);
});

test('mudar o filtro recomeça do princípio e deixa de oferecer mais', async () => {
  const linhas = Array.from({ length: 150 }, (_, i) => ({ id: 'a' + String(i).padStart(3, '0'), tipo: 'erro',
    estado: i < 3 ? 'resolvido' : 'novo', mensagem: 'x', criado_em: '2026-10-06T10:00:00+00:00' }));
  const { R, nodes } = boot(linhas);
  R.carregar(); await flush();
  assert.ok(botao(nodes['lista-reportes']));
  assert.match(nodes['fr-estado-msg'].textContent, /há mais/);
  nodes['fr-estado'].value = 'resolvido';
  R.carregar(); await flush();
  assert.equal(cartoes(nodes['lista-reportes']).length, 3);
  assert.equal(botao(nodes['lista-reportes']), undefined);
});
