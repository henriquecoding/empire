/* Portão das três camadas novas: plano, saúde, recorte.
   Mede o COMPORTAMENTO, não a presença de classes CSS. */
import { chromium } from "playwright";
import { resolve } from "node:path";
import { existsSync } from "node:fs";
/* Ver a nota do verificar-dossie.mjs: pergunta-se ao Playwright PRIMEIRO, para
   que esta máquina meça com o mesmo motor que o CI. O caminho fixo é recurso,
   e não preferência — preferi-lo custou três corridas. */
const FIXO = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const DO_PW = (() => { try { return chromium.executablePath(); } catch { return undefined; } })();
const EXEC = process.env.PW_CHROME
  || (DO_PW && existsSync(DO_PW) ? DO_PW : (existsSync(FIXO) ? FIXO : undefined));
/* Correr como root (contentor, CI) obriga a desligar a caixa de areia do
   Chromium; numa sessão normal ela fica ligada, que é o que se quer. */
const ARGS = (typeof process.getuid === "function" && process.getuid() === 0) ? ["--no-sandbox"] : [];
// O caminho vem do argumento; sem argumento, o sitio de sempre. Assim o
// portao corre contra qualquer construcao e nao so contra a da pasta.
const ALVO = process.argv[2] || process.cwd() + "/saida/dossie-empire-v6.html";
const FICH = ALVO.startsWith("file://") ? ALVO : "file://" + resolve(ALVO);
// O evento `load` NAO garante que as fontes da rede ja foram aplicadas: com
// `display=swap` a pagina desenha-se com a de recurso e troca quando o ficheiro
// chega. Numa maquina fria isso acontece A MEIO da medicao, e o que se mede e
// uma pagina que ainda vai mudar de forma. Foi o que aconteceu na corrida #16:
// «320px · dia 11 fora do desenho» e «carregar num item leva a #s40 (desvio
// -4376px)» chumbaram no runner e passavam em todo o lado, porque aqui as
// fontes ja estavam em cache. document.fonts.ready e a barreira que faltava.
const b = await chromium.launch({ executablePath: EXEC, args: ARGS });
const p = await b.newPage({ viewport: { width: 1280, height: 900 } });
const erros = [];
p.on("pageerror", (e) => erros.push(String(e)));
/* Uma falha de REDE não é um erro do documento: neste ambiente a folha
   de fontes do Google não resolve, e é o achado A-1, não um defeito. */
const deRede = (t) => /Failed to load resource|ERR_(CONNECTION|NAME|INTERNET|NETWORK)/.test(t);
p.on("console", (m) => { if (m.type() === "error" && !deRede(m.text())) erros.push("console: " + m.text()); });
await p.goto(FICH, { waitUntil: "load" });
await p.evaluate(() => document.fonts.ready);
await p.waitForTimeout(900);

let falhas = 0;
/* O terceiro argumento só aparece quando a verificação chumba. Um portão que
   diz «FALHA» e mais nada obriga quem o lê a adivinhar o que ele viu — e
   adivinhar custou três corridas (#16, #17, #18) nestas mesmas duas linhas,
   porque o que falhava lá não falha em mais lado nenhum. Quem chumba diz
   sempre com que números. */
const diz = (ok, txt, detalhe) => {
  if (!ok) falhas++;
  console.log(`${ok ? "  ok  " : "  FALHA"} ${txt}`);
  if (!ok && detalhe) for (const l of String(detalhe).split("\n")) console.log(`         ${l}`);
};

/* QUE PÁGINA É QUE ISTO ACABOU DE ABRIR.
   A folha de tipos de letra vem de uma CDN, e por isso a página medida não é a
   mesma em todas as máquinas. Não é teoria: medido aqui, com os quatro tipos e
   sem eles, no mesmo ficheiro construído —

     sem a CDN   120 tabelas intactas · 3 a deslizar
     com a CDN   118 tabelas intactas · 5 a deslizar   ← o que o runner mede

   e uma face pode falhar sozinha (IBM Plex Mono 500 deu `error` numa das
   medições, e só ela muda a contagem dos blocos de código). Sem esta linha, uma
   corrida que chumbe num rótulo largo de mais não diz se mediu a página com os
   tipos certos ou com os de recurso. Q-062 pergunta se o dossiê deve depender
   de uma CDN para a sua própria verificação; esta linha é o mínimo até lá. */
const tipos = await p.evaluate(() => {
  const por = {}, maus = [];
  document.fonts.forEach((f) => {
    por[f.status] = (por[f.status] || 0) + 1;
    if (f.status === "error") maus.push(`${f.family} ${f.weight} ${f.style}`);
  });
  return { n: document.fonts.size, por, maus };
});
/* E com que motor. O `PREF` acima fixa uma versão que pode não ser a que o
   Playwright instala no runner — aqui correu 1194 durante três corridas
   enquanto o CI corria 1243, e ninguém o disse. Medir com um motor e chumbar
   noutro é a mesma armadilha do Makefile: correr os comandos não é correr o
   workflow. */
console.log(
  `\nmotor: ${b.version()} (${EXEC || "resolvido pelo Playwright"})` +
  `\ntipos de letra: ${tipos.n} faces · ` +
  (Object.entries(tipos.por).map(([k, v]) => `${k} ${v}`).join(" · ") || "nenhuma") +
  (tipos.maus.length ? ` · ERRO em ${tipos.maus.join(", ")}` : "")
);

/* ─── 1 · O plano ─────────────────────────────────────────────── */
console.log("\nPLANO — o que a pesquisa pode afirmar");
const casos = [
  ["F0-00 está feito?", "pronto", true, "estado de um ticket"],
  ["o que o F0-00 bloqueia", "pronto", true, "dependência contada"],
  ["Q-001 bloqueia o quê", "pronto", true, "campo Bloqueia lido tal como está"],
  ["§07", "pronto", false, "identificador de secção"],
  ["F0-99", "sem_caminho", true, "forma válida de ticket que não existe"],
  ["F9-99", "sem_caminho", false, "F9 não é fase: é texto, não identificador"],
  ["fase 1", "clarificar", false, "família ambígua → UMA pergunta"],
  ["zzzqqqxyw", "sem_caminho", false, "sem confiança"],
];
for (const [q, esperado, exigeResposta, nota] of casos) {
  const r = await p.evaluate((q) => {
    const pl = window.XR.compilar(q, window.__X_IDX__.docs, window.__EMPIRE_DADOS__);
    return { estado: pl.estado, temResposta: !!pl.resposta, prov: pl.resposta && pl.resposta.proveniencia,
             texto: pl.resposta && pl.resposta.texto, porques: window.XR.porque(pl).length };
  }, q);
  diz(r.estado === esperado, `«${q}» → ${r.estado} (esperado ${esperado}) · ${nota}`);
  if (exigeResposta) {
    diz(r.temResposta && !!r.prov, `    responde com proveniência: ${r.texto || "—"} [${r.prov || "SEM"}]`);
  }
  diz(r.porques > 0, `    o «porquê isto?» tem ${r.porques} razão(ões)`);
}

/* A regra absoluta: nenhuma resposta sem proveniência. */
const semProv = await p.evaluate(() => {
  let n = 0;
  try { window.XR.resposta("texto sem fonte"); n++; } catch (e) { /* tem de rebentar */ }
  return n;
});
diz(semProv === 0, "uma resposta sem proveniência é impossível de construir");

/* O plano desenhado no ecrã */
await p.keyboard.press("/");
await p.waitForTimeout(150);
await p.keyboard.type("o que o F0-00 bloqueia", { delay: 8 });
await p.waitForTimeout(320);
const noEcra = await p.evaluate(() => {
  const pl = document.querySelector(".x-plano");
  if (!pl) return null;
  return { r: (pl.querySelector(".x-plano-r") || {}).textContent,
           prov: (pl.querySelector(".x-prov") || {}).textContent,
           lido: [...pl.querySelectorAll(".x-lido")].map((e) => e.textContent) };
});
diz(!!noEcra, "o plano aparece na região de resultados");
if (noEcra) {
  diz(/bloqueia/i.test(noEcra.r), `    afirma: «${noEcra.r}»`);
  diz(!!noEcra.prov, `    mostra a proveniência: «${noEcra.prov}»`);
  diz(noEcra.lido.includes("F0-00"), `    devolve o que leu: ${JSON.stringify(noEcra.lido)}`);
}
await p.keyboard.press("Escape");

/* ─── 2 · A saúde ─────────────────────────────────────────────── */
console.log("\nSAÚDE — fatores contados, nenhum escrito");
const s = await p.evaluate(() => {
  const sec = document.getElementById("x-saude");
  const st = window.XS.saude(window.__EMPIRE_DADOS__, new Map());
  return { existe: !!sec, fatores: sec ? sec.querySelectorAll(".x-fator").length : 0,
           estado: st.estado, evidencias: st.fatores.map((f) => f.id + "=" + f.evidencia),
           desconhecidos: st.fatores.filter((f) => f.estado === "desconhecido").length };
});
diz(s.existe, "o painel está montado no documento");
diz(s.fatores >= 5, `${s.fatores} fatores desenhados`);
diz(!!s.estado, `estado geral: «${s.estado}»`);
for (const e of s.evidencias) console.log("       " + e);
diz(s.desconhecidos > 0, `${s.desconhecidos} fator(es) dizem «por medir» em vez de contar como bons`);

/* ─── 3 · O recorte ───────────────────────────────────────────── */
console.log("\nRECORTE — levar o caso, com fronteira e impressão");
const botoes = await p.evaluate(() => document.querySelectorAll(".x-rec-b").length);
diz(botoes > 50, `${botoes} botões de recortar no documento`);

const rec = await p.evaluate(() => {
  const docs = window.__X_IDX__.docs;
  window.XC.limpar();
  const alvos = [docs.find((d) => d.tipo === "seccao"), docs.find((d) => d.tipo === "ticket"),
                 docs.find((d) => d.tipo === "questao"), docs.find((d) => d.tipo === "nota")].filter(Boolean);
  for (const d of alvos) window.XC.alternar(d.id);
  const r = window.XC.compor(docs, "Teste");
  const a = window.XC.auditar(r);
  // a impressão é sobre os DADOS: recompor dá o mesmo
  const r2 = window.XC.compor(docs, "Teste");
  // ... e muda quando o conteúdo muda
  const r3 = window.XC.compor(docs, "Outro título");
  return { itens: r.itens, seccoes: r.seccoes.map((x) => x.id), achados: a,
           impressao: r.impressao, estavel: r.impressao === r2.impressao, mudou: r.impressao !== r3.impressao,
           md: window.XC.FORMATOS.markdown.render(r).slice(0, 120),
           todosComProv: r.seccoes.every((sc) => sc.itens.every((i) => !!i.proveniencia)) };
});
diz(rec.itens === 4, `${rec.itens} itens compostos`);
diz(rec.achados.length === 0, `fronteira: ${rec.achados.length} campos fora da lista branca`);
diz(rec.todosComProv, "todos os itens levam proveniência");
diz(rec.estavel, `impressão estável entre composições: ${rec.impressao}`);
diz(rec.mudou, "a impressão muda quando o conteúdo muda");
console.log("       secções compostas: " + rec.seccoes.join(", ") + "  (as vazias não existem)");

/* A regra 2: nada inventado por ausência */
const vazio = await p.evaluate(() => {
  window.XC.limpar();
  const r = window.XC.compor(window.__X_IDX__.docs, "Vazio");
  return { seccoes: r.seccoes.length, itens: r.itens };
});
diz(vazio.seccoes === 0, "um recorte vazio não gera secções vazias");

/* A fronteira reprova mesmo — campo não autorizado */
const reprova = await p.evaluate(() => {
  const falso = { titulo: "x", seccoes: [{ id: "tickets", titulo: "T",
    itens: [{ id: "a", texto: "t", proveniencia: "p", segredo: "não autorizado" }] }] };
  return window.XC.auditar(falso).length;
});
diz(reprova === 1, "um campo não autorizado é reprovado pela lista branca");

/* A bandeja não vai para o endereço */
const url = p.url();
diz(!/recorte|bandeja/.test(url), "o endereço não carrega o que a pessoa escolheu ler");

/* ─── 4 · As partes ───────────────────────────────────────────── */
console.log("\nPARTES — trocar de forma, não embrulhar");
const pt = await p.evaluate(() => {
  const d = [...document.querySelectorAll("details.x-parte")];
  const aberta = d.find((x) => x.open), fechada = d.find((x) => !x.open);
  const vis = (el) => !!el && getComputedStyle(el).display !== "none";
  return {
    total: d.length, abertas: d.filter((x) => x.open).length,
    abertaArte: vis(aberta && aberta.querySelector(".part")),
    abertaSemLinha: !vis(aberta && aberta.querySelector(".x-parte-linha")),
    fechadaLinha: vis(fechada && fechada.querySelector(".x-parte-linha")),
    fechadaSemArte: !vis(fechada && fechada.querySelector(".part")),
    resumo: (fechada.querySelector(".x-parte-r") || {}).textContent || "",
    altura: Math.round(fechada.querySelector(".x-parte-linha").getBoundingClientRect().height),
    recolherNoFim: /x-parte-accoes/.test(aberta.querySelector(".x-parte-corpo").lastElementChild.className)
      && !!aberta.querySelector(".x-parte-accoes .x-parte-recolher"),
    // os painéis não podem cair para dentro do acordeão
    paineisFora: ["x-estado", "x-saude", "x-inventario"].every((id) => {
      const e = document.getElementById(id);
      return e && !e.closest("details.x-parte");
    }),
  };
});
diz(pt.total === 13, `${pt.total} partes, ${pt.abertas} aberta(s)`);
diz(pt.abertaArte && pt.abertaSemLinha, "aberta: o cabeçalho do autor aparece e a linha desaparece");
diz(pt.fechadaLinha && pt.fechadaSemArte, `fechada: só a linha, ${pt.altura}px`);
diz(pt.resumo.includes("§") && pt.resumo.length > 30,
    `o resumo antecipa o conteúdo: «${pt.resumo.slice(0, 64)}…»`);
diz(pt.recolherNoFim, "«Recolher» está no FIM do corpo, não a competir com o conteúdo");
diz(pt.paineisFora, "os painéis ficam FORA do acordeão");

/* Uma âncora dentro de uma parte fechada continua a funcionar? É a
   propriedade que o acordeão mais facilmente parte, e em silêncio. */
const salto = await p.evaluate(async () => {
  const alvos = ["s40", "s60", "s80"];
  const out = [];
  for (const id of alvos) {
    const sec = document.getElementById(id);
    if (!sec) continue;
    const det = sec.closest("details.x-parte");
    det.open = false;
    window.scrollTo(0, 0);
    await new Promise((r) => setTimeout(r, 60));
    window.__X_ATERRAR__(id, false);
    await new Promise((r) => setTimeout(r, 800));
    const margem = parseFloat(getComputedStyle(sec).scrollMarginTop) || 0;
    out.push({ id, abriu: det.open, desvio: Math.round(sec.getBoundingClientRect().top - margem) });
  }
  return out;
});
for (const s of salto) {
  diz(s.abriu && Math.abs(s.desvio) <= 4,
      `saltar para #${s.id} numa parte fechada: abriu=${s.abriu}, desvio ${s.desvio}px`);
}

/* A fechar uma parte NÃO se marcam as suas secções como lidas.
   ⚠️ PÁGINA LIMPA, de propósito: os saltos acima rolaram o documento e
   marcaram secções como lidas de VERDADE. Correr esta verificação na
   mesma página media a contaminação do teste anterior e não o defeito —
   foi exactamente o que aconteceu à primeira. */
const p2 = await b.newPage({ viewport: { width: 1280, height: 900 }, reducedMotion: "reduce" });
await p2.goto(FICH, { waitUntil: "load" });
await p2.evaluate(() => document.fonts.ready);
await p2.evaluate(() => { try { localStorage.removeItem("empire.lido.v1"); } catch (e) {} });
await p2.reload({ waitUntil: "load" });
await p2.waitForTimeout(900);
const lido = await p2.evaluate(async () => {
  const d = [...document.querySelectorAll("details.x-parte")].find((x) => x.open);
  const antes = window.XPT.lidas(d).lidas;
  d.open = false;
  window.dispatchEvent(new Event("scroll"));
  await new Promise((r) => setTimeout(r, 700));
  return { antes, depois: window.XPT.lidas(d).lidas, total: window.XPT.lidas(d).total };
});
await p2.close();
diz(lido.depois === lido.antes,
    `fechar uma parte não marca as ${lido.total} secções como lidas (${lido.antes} → ${lido.depois})`);

/* ─── 5 · Réguas e recorte ────────────────────────────────────── */
console.log("\nRÉGUAS E RECORTE — arrastar sobre um mapa, levar o caso");
// o botão deixou de ser uma barra
const bt = await p.evaluate(() => {
  const b = document.querySelector("section .x-rec-b");
  return { w: Math.round(b.getBoundingClientRect().width), h: Math.round(b.getBoundingClientRect().height) };
});
diz(bt.w < 160 && bt.h >= 36, `o botão mede ${bt.w}×${bt.h} (era 595 de largura)`);

// recortar a parte inteira
const rp = await p.evaluate(async () => {
  const d = [...document.querySelectorAll("details.x-parte")].find(x => x.open);
  const b = d.querySelector(".x-parte-recortar");
  const n = d.querySelectorAll("section[id]").length;
  window.XC.limpar();
  const antes = b.textContent;
  b.click(); await new Promise(r=>setTimeout(r,150));
  const depois = window.XC.conta(), rotulo = b.textContent;
  b.click(); await new Promise(r=>setTimeout(r,150));
  return { n, antes, depois, rotulo, voltouA: window.XC.conta() };
});
diz(rp.depois === rp.n, `«${rp.antes.trim()}» junta as ${rp.n} de uma vez`);
diz(/Tirar/.test(rp.rotulo), `o rótulo passa a «${rp.rotulo.trim()}» — diz para onde vai`);
diz(rp.voltouA === 0, "e carregar outra vez tira-as todas");

// atalho R
const r = await p.evaluate(async () => {
  window.XC.limpar();
  document.dispatchEvent(new KeyboardEvent("keydown", { key:"r", bubbles:true }));
  await new Promise(x=>setTimeout(x,150));
  const dentro = window.XC.bandeja();
  return { n: dentro.length, qual: dentro[0] || null };
});
diz(r.n === 1 && /^sec:/.test(r.qual || ""), `R recorta a secção que se está a ler (${r.qual})`);

// um item da bandeja é um destino
/* Mede-se ONDE A PÁGINA FICOU, e não onde ela ia ao fim de 900 ms.
   O salto é animado, e o desvio durante a animação é um valor de passagem:
   medido aqui, de 100 em 100 ms, dá -310px aos 213 ms e 0px aos 363 ms. Uma
   espera fixa lê um desses dois números conforme a máquina, e a vizinha desta
   linha — «saltar para #s40 numa parte fechada», que espera por uma CONDIÇÃO —
   passa sempre, no mesmo ficheiro e na mesma corrida.
   O que se AFIRMA não muda: o clique tem de levar à #s40. Muda só o momento em
   que se lê, que passa a ser «quando duas leituras seguidas concordam».
   O tecto é de propósito: uma página que nunca assenta é um defeito para
   relatar — com a série toda — e não um motivo para esperar para sempre. */
const ir = await p.evaluate(async () => {
  const d = window.__X_IDX__.docs.find(x => x.id === "sec:s40");
  window.XC.limpar(); window.XC.alternar(d.id);
  document.querySelector(".x-rec-flutua").click();
  await new Promise(x=>setTimeout(x,400));
  const it = document.querySelector(".x-rec-i[data-ir]");
  const alvo = it && it.dataset.ir;
  const ler = () => {
    const sec = document.getElementById(alvo);
    if (!sec) return null;
    const m = parseFloat(getComputedStyle(sec).scrollMarginTop) || 0;
    return Math.round(sec.getBoundingClientRect().top - m);
  };
  const t0 = performance.now();
  it.click();
  const serie = [];
  let ant = null, desvio = null, assentou = false;
  while (performance.now() - t0 < 6000) {
    await new Promise(x=>setTimeout(x,100));
    const v = ler(), t = Math.round(performance.now() - t0);
    serie.push(`${t}ms:${v}`);
    // Antes dos 400 ms o salto pode nem ter começado: duas leituras iguais aí
    // são a página PARADA, e não a página ASSENTE.
    if (t >= 400 && v !== null && v === ant) { desvio = v; assentou = true; break; }
    ant = v;
  }
  if (!assentou) desvio = ant;
  return { alvo, desvio, assentou, ms: Math.round(performance.now() - t0), serie,
           folhaFechada: document.getElementById("x-rec-folha").hidden };
});
diz(ir.alvo === "s40" && Math.abs(ir.desvio) <= 4 && ir.assentou,
  `carregar num item leva à #${ir.alvo} (desvio ${ir.desvio}px, assente aos ${ir.ms}ms)`,
  (ir.assentou ? "" : "a página nunca assentou em 6s — o valor é o último lido\n") +
  `série de ${ir.serie.length} leituras: ${ir.serie.join(" ")}`);
diz(ir.folhaFechada, "e a folha sai da frente");

/* ─── 5b · O SIMULADOR: as réguas, o gráfico e o «o que mais mexe» ───
   ┌─────────────────────────────────────────────────────────────────────┐
   │ ESTE BLOCO MEDE COISAS QUE NÃO DÃO ERRO                              │
   │                                                                     │
   │ Uma faixa meio passo ao lado, um rótulo por cima de outro, uma       │
   │ legenda que anuncia um estado que o modelo não produz, uma dica que  │
   │ aterra em cima dos comandos: nada disto lança excepção, nada disto   │
   │ falha um `--check`, e tudo isto se vê. É por isso que se mede.       │
   └─────────────────────────────────────────────────────────────────────┘ */
console.log("\nSIMULADOR — o mapa, o gráfico e o que mais mexe");

/* A §06 vive dentro de uma parte que entra FECHADA (a regra 11 das
   treze partes). Um SVG dentro de um `<details>` fechado não tem caixa
   para medir, e o portão media três vezes o mesmo desenho de 800px a
   pensar que estava a medir 320, 360 e 1280. Abre-se antes de medir. */
await p.evaluate(() => { const d = document.getElementById("s06").closest("details"); if (d) d.open = true; });
await p.waitForTimeout(600);
await p.evaluate(() => document.querySelector(".sim").scrollIntoView({ block: "center" }));
await p.waitForTimeout(300);

const ID = { fontes: "f-fontes", rotas: "f-rotas", tropas: "f-tropas", ganancia: "f-ganancia" };
const mexer = (id, v) => p.evaluate(([i, x]) => {
  const n = document.getElementById(i);
  n.value = String(x);
  n.dispatchEvent(new Event("input", { bubbles: true }));
}, [id, v]);

const rg = await p.evaluate(() => {
  const r = [...document.querySelectorAll(".x-regua")];
  const leg = document.querySelector(".x-regua-legenda");
  return {
    n: r.length,
    legendas: document.querySelectorAll(".x-regua-legenda").length,
    chaves: leg ? [...leg.querySelectorAll(".x-regua-chaves i")].map((i) => i.dataset.f) : [],
    nota: r[0] && r[0].querySelector(".x-regua-nota").textContent.trim(),
    notas: r.map((x) => x.querySelector(".x-regua-nota").textContent.trim()),
    fala: [...document.querySelectorAll(".x-regua-nativa")].map((i) => i.getAttribute("aria-valuetext")),
    pinos: document.querySelectorAll(".x-regua-pino:not([hidden])").length,
    alturas: [...document.querySelectorAll(".x-regua-nativa")].map((i) => Math.round(i.getBoundingClientRect().height)),
    // Todas as faixas que os quatro mapas contêm, tal como estão pintadas.
    presentes: [...new Set([...document.querySelectorAll(".x-regua-faixa")].map((f) => f.dataset.f))].sort(),
  };
});
diz(rg.n === 4, `${rg.n} réguas`);
diz(rg.legendas === 1 && rg.chaves.length >= 2, `a ajuda e as ${rg.chaves.length} faixas lêem-se UMA vez`);
diz(rg.pinos === 4, `${rg.pinos} alfinetes no valor que a §06 publica`);
diz(rg.alturas.every((h) => h >= 36), `o comando mede ${rg.alturas[0]}px de altura (o polegar precisa de 36)`);
diz(/^dia \d+ · /.test(rg.nota), `a nota diz o dia e o que é próprio deste cursor: «${rg.nota}»`);
diz(new Set(rg.notas.map((t) => t.split("· ")[1])).size >= 3,
  "as quatro notas dizem coisas DIFERENTES — quatro etiquetas iguais não informam");
diz(rg.fala.every((t) => /asfixia dia \d+|não asfixia/.test(t) && /alvo/.test(t)),
  `o \`aria-valuetext\` leva o mapa, não só o número: «${rg.fala[0]}»`);

/* A legenda é DERIVADA. A versão anterior tinha-a escrita à mão e
   anunciava «aguenta os 30 dias» — um estado que o modelo da §06 não
   produz em nenhuma das 343 434 combinações dos quatro cursores. */
diz(JSON.stringify(rg.chaves.slice().sort()) === JSON.stringify(rg.presentes),
  `a legenda lista exactamente as faixas que existem no mapa (${rg.presentes.join(", ")})`);

/* A geometria: um valor discreto ocupa de `v−½` a `v+½`. A versão
   anterior desenhava de `pos(v)` a `pos(v+1)` — meio passo à direita —
   e a pega no primeiro valor de uma faixa aparecia EM CIMA da fronteira,
   com a cor da faixa anterior por baixo dela. */
const geo = await p.evaluate(() => {
  const env = document.querySelectorAll(".x-regua")[0];
  const input = env.querySelector(".x-regua-nativa");
  const pega = env.querySelector(".x-regua-pega");
  const faixas = [...env.querySelectorAll(".x-regua-faixa")];
  const alvo = faixas.find((f) => f.dataset.f === "alvo");
  if (!alvo) return null;
  const c = (n) => { const r = n.getBoundingClientRect(); return { e: r.left, d: r.right, m: (r.left + r.right) / 2 }; };
  const pr = c(pega), ar = c(alvo);
  const passoPx = (env.querySelector(".x-regua-carril").getBoundingClientRect().width - 22) /
    ((+input.max - +input.min) / (+input.step || 1));
  return { dentro: pr.m > ar.e && pr.m < ar.d, folgaE: pr.m - ar.e, folgaD: ar.d - pr.m, passoPx,
           corPega: pega.dataset.f };
});
diz(!!geo && geo.dentro && geo.corPega === "alvo",
  `a pega está DENTRO da faixa que a pinta (folgas ${Math.round(geo.folgaE)}px / ${Math.round(geo.folgaD)}px, passo ${Math.round(geo.passoPx)}px)`);
diz(!!geo && geo.folgaE >= geo.passoPx * 0.3,
  "e não encostada à fronteira — a faixa cobre meio passo para cada lado do valor");

/* «Repor a §06»: só aparece quando há o que repor, e repõe mesmo. */
const antesRepor = await p.evaluate(() => document.querySelector(".x-regua-repor").hidden);
await mexer(ID.tropas, 40);
await p.waitForTimeout(200);
const comRepor = await p.evaluate(() => ({
  visivel: !document.querySelector(".x-regua-repor").hidden,
  asfixia: document.querySelector("#o-asfixia").textContent,
  selo: document.querySelector(".x-alvo-selo").textContent,
}));
/* Carregado DENTRO da página: o que se está a medir é o comportamento do
   botão, não a heurística de acionabilidade do Playwright numa página
   com barras fixas em cima e em baixo. O tamanho do alvo mede-se à
   parte, que é a propriedade que interessa. */
const caixaRepor = await p.evaluate(() => {
  const bt = document.querySelector(".x-regua-repor");
  const r = bt.getBoundingClientRect();
  bt.click();
  return { w: Math.round(r.width), h: Math.round(r.height) };
});
diz(caixaRepor.h >= 36 && caixaRepor.w >= 36, `e mede ${caixaRepor.w}×${caixaRepor.h} — tocável`);
await p.waitForTimeout(250);
const depoisRepor = await p.evaluate(() => ({
  escondido: document.querySelector(".x-regua-repor").hidden,
  valores: ["f-fontes", "f-rotas", "f-tropas", "f-ganancia"].map((i) => document.getElementById(i).value).join(","),
  asfixia: document.querySelector("#o-asfixia").textContent,
  selo: document.querySelector(".x-alvo-selo").textContent,
}));
diz(antesRepor && comRepor.visivel && depoisRepor.escondido,
  "«Repor a §06» só existe enquanto houver o que repor");
diz(depoisRepor.valores === "7,0,14,28" && depoisRepor.asfixia === "dia 11",
  `e repõe os valores do documento (${depoisRepor.valores} → ${depoisRepor.asfixia})`);
diz(comRepor.selo === "cedo demais" && depoisRepor.selo === "no alvo",
  `o veredicto vai escrito, não só a cor: «${comRepor.selo}» → «${depoisRepor.selo}»`);

/* «O que mais mexe» — o porte do `SensibilidadeNegocio`. */
const torn = await p.evaluate(() => {
  const linhas = [...document.querySelectorAll(".x-torn-i")].map((li) => ({
    nome: li.querySelector(".x-torn-n").textContent,
    amp: li.querySelector(".x-torn-a").textContent,
    critico: li.hasAttribute("data-critico"),
    rotulo: li.querySelector(".x-torn-b").getAttribute("aria-label"),
    hoje: li.querySelector(".x-torn-p") ? li.querySelector(".x-torn-p").style.insetInlineStart : null,
    // o troço do alcance que cai no alvo tem de estar POR CIMA da barra
    ordem: [...li.querySelector(".x-torn-b").children].map((c) => c.className),
  }));
  return { linhas, frase: document.querySelector(".x-torn-f").textContent.trim() };
});
const amps = torn.linhas.map((l) => parseInt(l.amp, 10) || 0);
diz(torn.linhas.length === 4, `${torn.linhas.length} cursores comparados no mesmo eixo`);
diz(amps.every((a, i) => i === 0 || a <= amps[i - 1]), `ordenados pelo que mais mexe (${amps.join(" ≥ ")})`);
diz(torn.linhas.filter((l) => l.critico).length === 1, "e um só marcado como o crítico");
diz(new Set(torn.linhas.map((l) => l.hoje)).size === 1,
  "o dia de hoje está no mesmo sítio nas quatro barras — é isso que as torna comparáveis");
diz(torn.linhas.every((l) => /do dia \d+ ao dia \d+|não muda o dia/.test(l.rotulo)),
  "cada barra tem equivalente textual com os dois números");
diz(torn.linhas.every((l) => {
  const i = l.ordem.indexOf("x-torn-r"), j = l.ordem.indexOf("x-torn-r-alvo");
  return j === -1 || j > i;
}), "e o troço que cai no alvo é pintado POR CIMA do alcance, não por baixo");

/* O gráfico: rótulos que não se pisam, em três larguras. */
for (const larg of [320, 360, 1280]) {
  await p.setViewportSize({ width: larg, height: 900 });
  await p.waitForTimeout(450);
  const g = await p.evaluate(() => {
    const ch = document.getElementById("chart");
    const W = +ch.getAttribute("viewBox").split(" ")[2];
    const cx = (n) => {
      const w = n.getComputedTextLength(), x = +n.getAttribute("x");
      const a = n.getAttribute("text-anchor") || "start";
      const f = a === "end" ? x : a === "middle" ? x + w / 2 : x + w;
      return [f - w, f];
    };
    const t = [...ch.querySelectorAll("text")];
    const asf = t.find((n) => (n.getAttribute("class") || "").includes("x-asf-rot"));
    const alvo = t.find((n) => (n.getAttribute("class") || "").includes("x-alvo-rot"));
    const nsPontas = t.filter((n) => (n.getAttribute("class") || "").includes("x-ponta-rot"));
    const pontas = nsPontas.map(cx);
    const linha = ch.querySelector("line.x-asf-linha");
    const lx = linha ? +linha.getAttribute("x1") : null;
    const a = asf ? cx(asf) : null;
    const pisa = (u, v) => !(u[1] <= v[0] + 0.5 || u[0] >= v[1] - 0.5);
    const r1 = (n) => Math.round(n * 10) / 10;
    return {
      W, texto: asf && asf.textContent,
      fora: [a, alvo && cx(alvo), ...pontas].filter(Boolean).some((c) => c[0] < -0.5 || c[1] > W + 0.5),
      pisaPonta: a ? pontas.some((c) => pisa(a, c)) : false,
      cruzaLinha: a && lx != null ? a[0] < lx && a[1] > lx : false,
      pontasSeparadas: (() => {
        const ys = nsPontas.map((n) => +n.getAttribute("y")).sort((x, y) => x - y);
        return ys.every((y, i) => i === 0 || y - ys[i - 1] >= 12.5);
      })(),
      // Só se imprime quando chumba, mas mede-se sempre: é o que distingue
      // «o rótulo é largo de mais» de «os nomes ficaram colados».
      caixas: {
        asf: a && a.map(r1), alvo: alvo && cx(alvo).map(r1), linhaX: lx,
        pontas: nsPontas.map((n, i) => `«${n.textContent}» [${pontas[i].map(r1)}] y=${+n.getAttribute("y")}`),
      },
    };
  });
  const porque = [
    g.fora && "um rótulo sai do desenho",
    g.pisaPonta && `«${g.texto}» pisa um nome de série`,
    g.cruzaLinha && `«${g.texto}» cruza a própria linha`,
    !g.pontasSeparadas && "dois nomes de série a menos de 12.5 um do outro",
  ].filter(Boolean).join(" · ");
  diz(!g.fora && !g.pisaPonta && !g.cruzaLinha && g.pontasSeparadas,
    `${larg}px · viewBox ${g.W} · «${g.texto}» dentro do desenho, sem pisar nomes nem a própria linha`,
    `${porque}\nasf=[${g.caixas.asf}] alvo=[${g.caixas.alvo}] linha x=${g.caixas.linhaX} viewBox 0..${g.W}\n` +
    g.caixas.pontas.join("\n"));
}
await p.setViewportSize({ width: 1280, height: 900 });
await p.waitForTimeout(400);

/* A dica: NUNCA por cima dos comandos que mudam o que ela mostra. */
const dicas = [];
for (const f of [0.05, 0.35, 0.7, 0.98]) {
  dicas.push(await p.evaluate(async (fr) => {
    const ch = document.getElementById("chart");
    ch.scrollIntoView({ block: "center" });
    const r = ch.getBoundingClientRect();
    ch.dispatchEvent(new PointerEvent("pointermove", { clientX: r.left + r.width * fr, clientY: r.top + r.height / 2, bubbles: true }));
    await new Promise((x) => setTimeout(x, 90));
    const t = document.querySelector(".x-tip"), tr = t.getBoundingClientRect();
    const c = document.querySelector(".sim-ctl").getBoundingClientRect();
    const cobre = !(tr.bottom <= c.top || tr.top >= c.bottom || tr.right <= c.left || tr.left >= c.right);
    return { cobre, fora: tr.top < 0 || tr.bottom > innerHeight || tr.left < 0 || tr.right > innerWidth,
             caixa: [tr.left, tr.top, tr.right, tr.bottom].map(Math.round),
             grafico: [r.left, r.top, r.right, r.bottom].map(Math.round),
             pontos: ch.querySelectorAll("#x-cruz circle").length };
  }, f));
}
const mau = dicas.find((d) => d.cobre || d.fora);
diz(dicas.every((d) => !d.cobre), `a dica nunca aterra por cima dos cursores${mau ? " — dica " + JSON.stringify(mau.caixa) + " gráfico " + JSON.stringify(mau.grafico) : ""}`);
diz(dicas.every((d) => !d.fora), "nem fora da janela");
diz(dicas.every((d) => d.pontos >= 3), "e marca o ponto de cada série no dia que se está a ler");

/* A escala: duas opções à vista, uma carregada, e a escolha fica. */
const esc1 = await p.evaluate(() => [...document.querySelectorAll(".x-seg-b")].map((b) => b.getAttribute("aria-pressed")));
await p.evaluate(() => document.querySelectorAll(".x-seg-b")[1].click());
await p.waitForTimeout(300);
const esc2 = await p.evaluate(() => {
  const ch = document.getElementById("chart");
  const marcas = [...ch.querySelectorAll("text")].filter((n) => n.getAttribute("text-anchor") === "end").map((n) => n.textContent);
  const gs = [...ch.querySelectorAll("line.x-grelha,line.x-zero")].map((l) => +l.getAttribute("y1"));
  return { press: [...document.querySelectorAll(".x-seg-b")].map((b) => b.getAttribute("aria-pressed")),
           marcas, topo: Math.min(...gs) };
});
diz(esc1.filter((x) => x === "true").length === 1 && esc2.press.join() === "false,true",
  "o comutador de escala diz sempre em qual das duas se está");
/* Em linear o topo do desenho encosta a uma marca: era `ceil(max/50)*50`
   com passos de 400, o que deixava a última linha da grelha a flutuar. */
diz(esc2.topo <= 23, `e em linear a marca mais alta é o topo do desenho (y=${esc2.topo})`);

/* As duas contas do modelo têm de concordar: a varredura usa um caminho
   rápido que não aloca as séries, e um expoente corrigido só numa delas
   punha o mapa das réguas a descrever uma economia que o gráfico não
   desenha. */
const conc = await p.evaluate(() => {
  const S = window.__EMPIRE_SIM__;
  if (!S) return null;
  let mau = 0, n = 0;
  for (let i = 0; i < 500; i++) {
    const v = { fontes: (i * 7) % 17, rotas: (i * 3) % 6, tropas: 4 + ((i * 11) % 37), ganancia: (i * 13) % 91 };
    n++;
    if (S.modelo(v).asfixia !== S.diaDaAsfixia(v)) mau++;
  }
  return { n, mau };
});
diz(!!conc && conc.mau === 0, `o caminho rápido da varredura concorda com o modelo em ${conc && conc.n} combinações`);

/* ─── 5c · AS 123 TABELAS ─────────────────────────────────────────────
   ┌─────────────────────────────────────────────────────────────────────┐
   │ O DEFEITO MAIOR DO DOCUMENTO NÃO ESTAVA NUMA FUNCIONALIDADE NOVA     │
   │                                                                     │
   │ Estava numa que já existia e que uma camada posterior desligou. A    │
   │ camada de uso pôs `overflow-x:auto` nas 123 tabelas; a camada de     │
   │ desenho pôs `overflow:hidden` no mesmo `.tw` para lhe arredondar os  │
   │ cantos, e o atalho escreve os dois eixos. 103 tabelas não cabem a    │
   │ 360px, e as 103 passaram a cortar a última coluna sem aviso e sem    │
   │ saída — foi assim que chegou reportado, com uma captura de ecrã.     │
   │                                                                     │
   │ Estas asserções medem o COMPORTAMENTO das duas decisões que o        │
   │ substituíram: empilhar as fichas, deslizar as matrizes.             │
   └─────────────────────────────────────────────────────────────────────┘ */
console.log("\nTABELAS — a ficha empilha, a matriz desliza");

const tabelasEm = async (larg) => {
  await p.setViewportSize({ width: larg, height: 900 });
  await p.waitForTimeout(500);
  return p.evaluate(() => {
    const tws = [...document.querySelectorAll(".tw")];
    const modos = {};
    for (const t of tws) modos[t.dataset.modo || "intacta"] = (modos[t.dataset.modo || "intacta"] || 0) + 1;
    const corta = tws.filter((t) => {
      const r = t.querySelector(".x-rolo");
      return r && getComputedStyle(r).overflowX === "hidden" && r.scrollWidth - r.clientWidth > 2;
    }).length;
    const semAviso = tws.filter((t) => {
      if (t.dataset.modo !== "rola") return false;
      const r = t.querySelector(".x-rolo");
      return r.scrollWidth - r.clientWidth > 2 && !t.querySelector(".x-tw-desliza");
    }).length;
    // colunas de prosa espremidas fora do modo que empilha
    const espremidas = [...document.querySelectorAll('.tw:not([data-modo="empilha"]) tbody td')]
      .filter((td) => td.textContent.trim().length > 40 && td.clientWidth < 150).length;
    // uma empilhada, por dentro
    const uma = document.querySelector('.tw[data-modo="empilha"]');
    let ficha = null;
    if (uma) {
      const td = [...uma.querySelectorAll("tbody td")].find((c) => c.querySelector(".x-td-rot"));
      const tab = uma.querySelector("table");
      ficha = {
        papelTabela: tab.getAttribute("role"),
        papelLinha: (uma.querySelector("tbody tr") || {}).getAttribute
          ? uma.querySelector("tbody tr").getAttribute("role") : null,
        papelCelula: td ? td.getAttribute("role") : null,
        rotulo: td ? td.querySelector(".x-td-rot").textContent : null,
        rotuloOculto: td ? td.querySelector(".x-td-rot").getAttribute("aria-hidden") === "true" : false,
        cabecalhoNaArvore: getComputedStyle(uma.querySelector("thead")).display !== "none",
        blocos: getComputedStyle(uma.querySelector("tbody tr")).display === "block",
        larguraCelula: td ? Math.round(td.getBoundingClientRect().width) : 0,
      };
    }
    return { total: tws.length, modos, corta, semAviso, espremidas, ficha };
  });
};

const t360 = await tabelasEm(360);
diz(t360.corta === 0, `a 360px, ${t360.corta} tabelas cortam o próprio conteúdo (eram 103)`);
diz((t360.modos.empilha || 0) >= 60,
  `a 360px: ${t360.modos.empilha || 0} fichas empilhadas · ${t360.modos.rola || 0} matrizes a deslizar · ${t360.modos.intacta || 0} intactas`);
diz(t360.semAviso === 0, `e ${t360.semAviso} das que deslizam o fazem sem o dizer`);
diz(t360.espremidas < 40, `células de prosa abaixo de 150px: ${t360.espremidas} (eram 362)`);
if (t360.ficha) {
  const f = t360.ficha;
  diz(f.blocos, "empilhada: a linha passa a bloco");
  diz(f.papelTabela === "table" && f.papelLinha === "row" && f.papelCelula === "cell",
    `e devolve a semântica que o \`display:block\` lhe tira (${f.papelTabela}/${f.papelLinha}/${f.papelCelula})`);
  diz(f.cabecalhoNaArvore, "o `<thead>` continua na árvore de acessibilidade — escondido, não removido");
  diz(!!f.rotulo && f.rotuloOculto, `cada célula leva o nome da coluna («${f.rotulo}»), e é \`aria-hidden\` para não o repetir`);
  diz(f.larguraCelula > 200, `e a célula passa a ter ${f.larguraCelula}px em vez de uma coluna de 85`);
}

const t1280 = await tabelasEm(1280);
diz(!t1280.modos.empilha,
  `a 1280px nenhuma empilha (${t1280.modos.intacta || 0} intactas, ${t1280.modos.rola || 0} a deslizar) — uma tabela larga é uma tabela`);
diz(t1280.corta === 0, "e nenhuma corta o próprio conteúdo");

/* Os 52 blocos de código: a mesma pergunta, e a affordance que um atalho
   `background` já apagou uma vez. */
const codigo = await p.evaluate(() => {
  const pres = [...document.querySelectorAll("pre")];
  const rolam = pres.filter((n) => n.scrollWidth - n.clientWidth > 2);
  const cs = pres[0] ? getComputedStyle(pres[0]) : null;
  return { total: pres.length, rolam: rolam.length,
           temSombra: !!cs && cs.backgroundImage !== "none",
           local: !!cs && /local/.test(cs.backgroundAttachment) };
});
diz(codigo.temSombra && codigo.local,
  `os blocos de código dizem que deslizam (${codigo.rolam} de ${codigo.total} deslizam a 1280px; sombra em \`background-attachment: local\`)`);

await p.setViewportSize({ width: 1280, height: 900 });
await p.waitForTimeout(300);

/* ─── 6 · Sem erros ───────────────────────────────────────────── */
console.log("\nERROS DE JAVASCRIPT");
diz(erros.length === 0, erros.length ? erros.slice(0, 4).join(" | ") : "nenhum");

await b.close();
console.log(falhas === 0 ? "\nTudo passa." : `\n${falhas} FALHA(S).`);
process.exit(falhas === 0 ? 0 : 1);
