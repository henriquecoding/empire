// O laboratório do site (PUB-06, ADR 0085): as contas que ele faz no browser
// têm de dar os números que o dossiê escreve e que o jogo testa. Se uma destas
// falhar, o laboratório está a mostrar um jogo que não é este.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import test from 'node:test';
import { ler, csv } from '../../tools/web/dados.mjs';

const window = {};
runInNewContext(readFileSync('tools/web/paginas/laboratorio-contas.js', 'utf8'), { window });
const C = window.EmpireContas;
const d = ler(process.cwd());
const L = d.laboratorio;
const perto = (a, b, msg) => assert.ok(Math.abs(a - b) < 1e-9, `${msg}: ${a} ≠ ${b}`);

test('a manutenção é a do §29: upkeep(14) = 3,0 e upkeep(25) = 13,5', () => {
  assert.equal(C.manutencao(L.economia.gratis, L.economia), 0);
  perto(C.manutencao(14, L.economia), 3.0, 'upkeep(14)');
  perto(C.manutencao(25, L.economia), 13.5, 'upkeep(25)');
});

test('o dia da asfixia de cada perfil do economy_profiles.csv cai no alvo dele', () => {
  const perfis = csv(readFileSync('data/source/economy_profiles.csv', 'utf8'));
  const dia = (id) => {
    const p = perfis.find((x) => x.id === id);
    return C.asfixia({ fontes: +p.sources, rotas: +p.routes, tropas: +p.troops, ganancia: +p.greed }, L.economia, 40);
  };
  for (const p of perfis) {
    const [de, ate] = p.expect_suffocation.split('|').map(Number);
    if (de || ate) assert.ok(dia(p.id) >= de && dia(p.id) <= ate, `${p.id}: dia ${dia(p.id)} fora de ${de}–${ate}`);
  }
  assert.equal(dia('balanced'), 11, 'o modelo do §06 dá o dia 11 com os valores por omissão');
  assert.equal(dia('two_routes') - dia('balanced'), 4, '«põe as rotas a 2 e vê os quatro dias que a conquista te compra»');
  assert.equal(dia('everything_max'), 28, '«mesmo com tudo no máximo, a asfixia chega ao dia 28»');
  assert.ok(dia('greed_20') - dia('greed_80') >= 3, 'greed 80 antecipa a asfixia pelo menos 3 dias face a greed 20 (§29)');
});

test('os deslizadores do laboratório são os do simulador do §06, e o perfil por omissão está no alvo', () => {
  const s = L.economia.deslizadores;
  assert.deepEqual([s.fontes.max, s.rotas.max, s.tropas.min, s.ganancia.max], [16, 5, 4, 90]);
  const omissao = { fontes: s.fontes.valor, rotas: s.rotas.valor, tropas: s.tropas.valor, ganancia: s.ganancia.valor };
  const dia = C.asfixia(omissao, L.economia);
  assert.ok(dia >= L.economia.alvo[0] && dia <= L.economia.alvo[1], `dia ${dia}`);
});

test('a ganância cai num perfil só dentro da gama dele, como no RulesFactory', () => {
  assert.equal(C.perfilGanancia(28, L.economia.perfis).id, 'balanced');
  assert.equal(C.perfilGanancia(90, L.economia.perfis).id, 'tyrant');
  assert.equal(C.perfilGanancia(17, L.economia.perfis), null);
});

test('o tempo até matar é a tabela do §07', () => {
  const t = Object.fromEntries(L.tropas.map((x) => [x.id, x]));
  const c = Object.fromEntries(L.criaturas.map((x) => [x.id, x]));
  const s = (u, alvo, precisao = 1) => Math.round(C.tempoAteMatar(t[u], c[alvo].vida, precisao).segundos * 10) / 10;
  assert.deepEqual(['crawler', 'winged', 'brute', 'burrower', 'slime_ram'].map((x) => s('archer', x, L.torre)), [4.2, 5.6, 11.2, 9.8, 36.4]);
  assert.deepEqual(['crawler', 'winged', 'brute', 'burrower', 'slime_ram'].map((x) => s('spearman', x)), [2.2, 3.3, 6.6, 5.5, 19.8]);
  assert.deepEqual(['crawler', 'winged', 'brute', 'burrower', 'slime_ram'].map((x) => s('root_berserker', x)), [0.9, 1.8, 2.7, 2.7, 8.1]);
  assert.deepEqual(['crawler', 'winged', 'brute', 'burrower', 'slime_ram'].map((x) => s('mercenary', x)), [1.0, 2.0, 3.0, 3.0, 10.0]);
  // Em campo, o §07 faz a conta com 1/3 e os dados usam 0,34: «2% ao lado».
  const campo = s('archer', 'crawler', t.archer.precisao);
  assert.ok(Math.abs(campo - 12.6) / 12.6 < 0.03, `arqueiro em campo contra o Rastejante: ${campo}`);
  assert.ok(C.tempoAteMatar(t.archer, c.slime_ram.vida, t.archer.precisao).segundos > L.noiteSegundos, 'arqueiros não param aríetes: mais do que uma noite');
});

test('a massa da noite é a da §74, com a rampa decidida e as propostas à parte', () => {
  const n = L.noite;
  const campo = (dia, extra = {}) => ({ dia, fortalezas: 0, amargueiros: 0, nomeados: 0, recusas: 0, ...extra });
  perto(C.massa(campo(1), n, false).total, n.abertura, 'a noite 1');
  perto(C.massa(campo(n.rampa), n, false).total, n.base + n.porDia * n.rampa, 'a fórmula manda por inteiro a partir da noite 7');
  perto(C.massa(campo(20), n, false).total, 400, 'campo limpo ao dia 20, pela fórmula (D-01)');
  // A tabela da §74 já traz o crescimento de 6% depois da noite 10 (Q-151), que no rot.csv é proposta.
  const tabela = (dia, extra) => Math.round(C.massa(campo(dia, extra), n, true).total);
  assert.deepEqual([tabela(10), tabela(20)], [220, 716]);
  assert.deepEqual([tabela(10, { amargueiros: 3 }), tabela(20, { amargueiros: 3 })], [286, 782]);
  assert.deepEqual([tabela(10, { amargueiros: 8 }), tabela(20, { amargueiros: 8 })], [396, 892]);
  assert.deepEqual([tabela(10, { amargueiros: 5, nomeados: 3 }), tabela(20, { amargueiros: 5, nomeados: 3 })], [465, 961]);
  perto(C.massa(campo(9, { recusas: 99 }), n, false).recusas, Math.min(n.porRecusa * n.recusasMax, n.tetoRecusas), 'as recusas contam até cinco');
});

test('a escolha é a do §51: a mais cara que cabe, e a noite 1 traz três Rastejantes (§25)', () => {
  const n = L.noite;
  const noite = (dia, o = {}) => {
    const m = C.massa({ dia, fortalezas: 0, amargueiros: 0, nomeados: 0, recusas: 0 }, n, !!o.propostas).total;
    return C.invocar(m, dia, L.criaturas, n, { subsolo: !!o.subsolo, propostas: !!o.propostas });
  };
  // O vm devolve objetos de outro «realm»: compara-se a forma, e não o protótipo.
  assert.equal(JSON.stringify(noite(1).fila), JSON.stringify([{ id: 'crawler', n: 3 }]));
  assert.equal(noite(1).sobra, 0);
  assert.ok(noite(12).fila.every((x) => x.id !== 'burrower'), 'sem o subsolo aberto, o Cavador não vem');
  assert.ok(noite(12, { subsolo: true }).fila.some((x) => x.id === 'burrower'));
  for (let dia = 1; dia <= 30; dia++) {
    const r = noite(dia, { subsolo: true });
    const menor = Math.min(...L.criaturas.filter((c) => c.desde <= dia).map((c) => c.massa));
    assert.ok(r.sobra >= 0 && r.sobra < menor, `dia ${dia}: sobram ${r.sobra}, e ainda cabia uma`);
    for (const x of r.fila) assert.ok(L.criaturas.find((c) => c.id === x.id).desde <= dia, `dia ${dia}: ${x.id} antes do dia dela`);
  }
  // Com a proposta da estreia (Q-240), o primeiro Alado é um Alado, e não nove.
  const alados = (dia) => noite(dia, { propostas: true }).fila.find((x) => x.id === 'winged')?.n || 0;
  assert.ok(alados(4) <= n.propostas.estreia.valor);
});

test('a escada do muro paga cada degrau inteiro: 6 · 11 · 20 · 36 · 65', () => {
  assert.deepEqual(L.muros.map((w) => w.custo), [6, 11, 20, 36, 65]);
  assert.equal(C.custoAte(L.muros, 3), 37);
  assert.equal(C.custoAte(L.muros, 5), 138);
});
