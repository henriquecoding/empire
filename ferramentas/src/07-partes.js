/* ═══════════════════════════════════════════════════════════════════════
   AS PARTES — treze grupos que se abrem quando a pessoa quer
   ---------------------------------------------------------------------
   ┌─────────────────────────────────────────────────────────────────────┐
   │ PORTADO DA REGRA 11 DO RECIBO CERTO — «carregamento por mês»         │
   │                                                                     │
   │ Lá, o painel de Novidades só pode carregar o mês corrente. Os meses  │
   │ anteriores entram FECHADOS, como um grupo com nome e contagem, e os  │
   │ dados só são pedidos quando a pessoa clica nesse grupo.              │
   │                                                                     │
   │ O dossiê tinha o mesmo problema em maior: 86 secções, 16 mil nós e   │
   │ 360 mil caracteres de uma vez, para quem quase sempre quer uma.      │
   └─────────────────────────────────────────────────────────────────────┘

   A DIFERENÇA QUE IMPORTA: ISTO ENVOLVE, NÃO REMOVE

   A tentação era mover o conteúdo fechado para `<template>` e injetá-lo
   ao abrir. Reduzia mesmo o DOM — e partia uma propriedade que o portão
   verifica desde o início: **sem JavaScript, o dossiê lê-se de cima a
   baixo**. Um documento de produção que só existe se o script correr
   deixa de ser um documento.

   Por isso a direção é ao contrário: o HTML sai com TUDO aberto, e é o
   JavaScript que FECHA. Quem não o tiver recebe o documento inteiro, que
   é o pior caso aceitável; quem o tiver recebe o acordeão. Progressive
   enhancement da forma correta — a melhoria é o fecho, não a abertura.

   O custo de renderização, que era a razão do pedido, resolve-se com
   `content-visibility:auto` no conteúdo fechado: o browser salta o
   desenho e a disposição do que ninguém está a ver, e o `<details>`
   nativo dá-nos teclado, `Ctrl+F` e impressão de graça.

   O QUE NÃO SE PODE PARTIR: uma âncora dentro de uma parte fechada tem
   de continuar a funcionar. Todo o caminho de navegação — pesquisa,
   índice, referências §NN, J/K, o endereço com `#` — passa por
   `abrirPara()` antes de saltar. É um sítio só, de propósito.
   ═══════════════════════════════════════════════════════════════════════ */

window.XPT = (() => {
"use strict";

const esc = (t) =>
  String(t).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

const ROMANO = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII", "XIV", "XV"];

/** Quantas secções desta parte já foram lidas — o `x-visto` do índice. */
function lidas(det) {
  const secs = det.querySelectorAll("section[id]");
  let n = 0;
  for (const s of secs) if (s.dataset.xVisto === "1") n++;
  return { lidas: n, total: secs.length };
}

/**
 * Envolve cada `.part` e as secções que a seguem num `<details>`.
 *
 * Os painéis desta camada (`#x-estado`, `#x-saude`, …) NÃO entram: são o
 * quadro de bordo do documento e ficam sempre à vista, como irmãos antes
 * do grupo. Um painel que se esconde dentro de um acordeão é um painel
 * que ninguém volta a ver.
 */
function envolver() {
  const main = document.querySelector("main");
  if (!main) return [];
  const partes = [...main.querySelectorAll(":scope > .part")];
  if (!partes.length) return [];

  const feitos = [];
  for (let i = 0; i < partes.length; i++) {
    const cab = partes[i];
    const fim = partes[i + 1] || null;

    // A corrida: tudo entre esta parte e a seguinte.
    const corrida = [];
    for (let n = cab.nextElementSibling; n && n !== fim; n = n.nextElementSibling) corrida.push(n);

    const secoes = corrida.filter((n) => n.matches("section[id]") && !/^x-/.test(n.id));
    if (!secoes.length) continue;
    /* A tira conta as secções NUMERADAS — as que o índice lista. Contar
       `section[id]` incluía o rastreador, que não tem número e não está
       no índice, e a tira dizia 12 onde o índice dizia 11. Dois números
       para a mesma coisa é pior do que nenhum. */
    const numeradas = secoes.filter((n) => n.querySelector(".sec-no"));

    const no = (cab.querySelector(".part-no") || {}).textContent || "";
    const titulo = (cab.querySelector("h2") || {}).textContent || "";

    const det = document.createElement("details");
    det.className = "x-parte";
    det.open = true;                      // fecha-se depois, com estado conhecido
    const sum = document.createElement("summary");
    sum.className = "x-parte-cab";
    cab.replaceWith(det);
    sum.appendChild(cab);                 // a arte do autor sobrevive, dentro do resumo

    const corpo = document.createElement("div");
    corpo.className = "x-parte-corpo";
    for (const n of corrida) {
      if (/^x-/.test(n.id || "")) det.parentNode.insertBefore(n, det); // painéis ficam fora
      else corpo.appendChild(n);
    }
    det.append(sum, corpo);

    /* `.part-no` diz «PARTE IV», não «IV». Guardar o texto inteiro fazia
       `ROMANO.indexOf` falhar sempre e o atributo caía no número da
       posição — e era esse atributo que o índice usava para se casar com
       a parte, portanto nenhum grupo encontrava a sua. Aqui tira-se o
       romano de onde ele está, e o número da posição fica para o caso de
       uma parte que não o traga. */
    const rom = (no.toUpperCase().match(/\b([IVXLCDM]+)\b/) || [])[1];
    det.dataset.parte = rom && ROMANO.indexOf(rom) > 0 ? rom : String(i + 1);
    det.dataset.titulo = titulo.trim();

    /* ┌─────────────────────────────────────────────────────────────┐
       │ FECHADA É UMA LINHA, NÃO UM CARTÃO                           │
       │                                                             │
       │ A primeira versão embrulhava o cabeçalho do autor — que já   │
       │ é um cartão completo, com título, régua e frase — num        │
       │ SEGUNDO cartão de 202px. Dois títulos e duas bordas para a   │
       │ mesma coisa, treze vezes seguidas.                           │
       │                                                             │
       │ O `SeccaoRevelavel` do Preço resolve isto trocando de FORMA  │
       │ em vez de embrulhar: fechada é uma linha; aberta é o cartão  │
       │ original, e a linha desaparece. É o que se faz aqui.         │
       │                                                             │
       │ E o resumo da linha não é decoração. Se disser «11 secções», │
       │ a pessoa tem de abrir para saber se lhe interessa, e a carga │
       │ não desceu — só passou a ser treze decisões de «abro ou      │
       │ não?». Por isso a linha diz o INTERVALO e os PRIMEIROS       │
       │ NOMES: «§35–§45 · Repositório, prompts, testes, dinheiro».   │
       │ Muita gente já sabe aí que não é ali que quer estar.          │
       └─────────────────────────────────────────────────────────────┘ */
    const nomes = numeradas.map((n) => {
      const t = (n.querySelector("h3") || {}).textContent || "";
      return t.replace(/\s+/g, " ").trim();
    }).filter(Boolean);

    const nums = numeradas.map((n) => {
      const m = /^(\d{1,2}|★)/.exec(((n.querySelector(".sec-no") || {}).textContent || "").trim());
      return m ? m[1] : "";
    }).filter(Boolean);
    const intervalo = nums.length > 1 ? `§${nums[0]}–§${nums[nums.length - 1]}` : nums.length ? `§${nums[0]}` : "";

    /* Quantos nomes cabem antes de a linha deixar de se ler. Quatro é o
       que cabe a 360px em duas linhas; o resto vira «e mais N». */
    const MOSTRA = 4;
    const lista = nomes.slice(0, MOSTRA).join(", ");
    const resto = nomes.length - MOSTRA;
    const resumo = nomes.length
      ? (intervalo ? intervalo + " · " : "") + lista + (resto > 0 ? ` e mais ${resto}` : "")
      : "";   // sem nada concreto a antecipar, nenhuma frase é melhor do que uma vaga

    const linha = document.createElement("div");
    linha.className = "x-parte-linha";
    linha.innerHTML =
      `<span class="x-parte-id">${esc(no.trim() || "Parte")}</span>` +
      `<span class="x-parte-t">${esc(titulo.trim())}</span>` +
      (resumo ? `<span class="x-parte-r">${esc(resumo)}</span>` : "") +
      `<span class="x-parte-e">` +
        `<span class="x-parte-faixa" aria-hidden="true"><i style="inline-size:0%"></i></span>` +
        `<span class="x-parte-lidas"></span>` +
      `</span>` +
      `<span class="x-parte-seta" aria-hidden="true">` +
        `<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" ` +
        `stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="m6 9 6 6 6-6"/></svg>` +
      `</span>`;
    sum.insertBefore(linha, sum.firstChild);

    /* Recolher é acção secundária: quem abriu quis ver. Fica no FIM, onde
       a pessoa chega depois de ler, e não a competir com o conteúdo. */
    const recolher = document.createElement("button");
    recolher.type = "button";
    recolher.className = "x-parte-recolher";
    recolher.innerHTML =
      `<svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" ` +
      `stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m18 15-6-6-6 6"/></svg>` +
      `Recolher ${esc(no.trim().toLowerCase() || "esta parte")}`;
    recolher.addEventListener("click", () => {
      det.open = false;
      det.scrollIntoView({ block: "nearest" });
      sum.focus();
    });

    /* Recortar a parte inteira. Quem leu uma parte e a quer levar tinha
       de carregar em catorze botões, um por secção. O rótulo diz o que
       vai acontecer — «recortar as 14» ou «tirar as 14» — porque um
       botão que alterna sem dizer para onde obriga a experimentar. */
    const recortarParte = document.createElement("button");
    recortarParte.type = "button";
    recortarParte.className = "x-parte-recortar";
    const idsDaParte = () => secoes.map((n) => "sec:" + n.id);
    const todasDentro = () => window.XC && idsDaParte().every((id) => window.XC.tem(id));
    const rotular = () => {
      const dentro = todasDentro();
      recortarParte.textContent = dentro
        ? `Tirar as ${secoes.length} do recorte`
        : `Recortar as ${secoes.length} secções`;
      recortarParte.setAttribute("aria-pressed", String(dentro));
    };
    recortarParte.addEventListener("click", () => {
      if (!window.XC) return;
      const tirar = todasDentro();
      for (const id of idsDaParte()) {
        if (window.XC.tem(id) === tirar) window.XC.alternar(id);
      }
      rotular();
    });
    window.addEventListener("x-recorte", rotular);
    rotular();

    const accoes = document.createElement("div");
    accoes.className = "x-parte-accoes";
    accoes.append(recortarParte, recolher);
    corpo.appendChild(accoes);

    feitos.push(det);
  }
  return feitos;
}

/** Actualiza a contagem de lidas de uma parte (ou de todas). */
function actualizar(det) {
  for (const d of det ? [det] : todas()) {
    const { lidas: n, total } = lidas(d);
    const faixa = d.querySelector(".x-parte-faixa i");
    const txt = d.querySelector(".x-parte-lidas");
    if (faixa) faixa.style.inlineSize = total ? Math.round((n / total) * 100) + "%" : "0%";
    if (txt) txt.textContent = n === 0 ? "por ler" : n >= total ? "lida" : `${n} de ${total} lidas`;
    d.dataset.lidas = n >= total && total > 0 ? "todas" : n > 0 ? "algumas" : "nenhuma";
  }
}

const todas = () => [...document.querySelectorAll("details.x-parte")];

/** A parte que contém um elemento — ou nada, se ele viver fora de uma. */
const parteDe = (el) => (el && el.closest ? el.closest("details.x-parte") : null);

/**
 * Abre a parte que contém `alvo`. É por aqui que passa TODA a navegação:
 * saltar para uma âncora fechada sem abrir primeiro entrega o topo da
 * página em silêncio, que é exactamente o defeito que o portão das
 * ligações existe para apanhar.
 */
function abrirPara(alvo) {
  const el = typeof alvo === "string" ? document.getElementById(alvo) : alvo;
  const det = parteDe(el);
  if (det && !det.open) { det.open = true; return true; }
  return false;
}

/** Fecha todas menos a que contém `alvo` (ou menos a primeira). */
function sozinha(alvo) {
  const manter = parteDe(typeof alvo === "string" ? document.getElementById(alvo) : alvo);
  const lista = todas();
  const escolhida = manter || lista[0] || null;
  for (const d of lista) d.open = d === escolhida;
  return escolhida;
}

function abrirTodas(abrir) {
  for (const d of todas()) d.open = !!abrir;
}

/**
 * Monta. Devolve as partes, já fechadas menos uma — a que o endereço
 * pede, ou a primeira.
 */
function montar() {
  const feitos = envolver();
  if (!feitos.length) return feitos;

  const alvo = location.hash.length > 1 ? location.hash.slice(1) : null;
  sozinha(alvo);
  actualizar();

  /* Uma parte que abre vale como intenção de leitura: fecha-se o resto
     só quando a pessoa pede «uma de cada vez», e isso é uma preferência
     e não uma imposição — por isso o padrão é acumular. */
  for (const d of feitos) {
    d.addEventListener("toggle", () => {
      if (d.open) actualizar(d);
      window.dispatchEvent(new CustomEvent("x-parte", { detail: { parte: d.dataset.parte, aberta: d.open } }));
    });
  }

  /* `Ctrl+F` do browser abre um `<details>` fechado ao encontrar texto lá
     dentro; o índice tem de acompanhar, senão fica a dizer que está
     fechada uma parte que está aberta. */
  window.addEventListener("x-visto", () => actualizar());

  /* IMPRIMIR TEM DE DAR O DOSSIÊ INTEIRO.
     Um `<details>` fechado também sai fechado no papel, e nenhuma regra
     de `@media print` o abre — o browser esconde o conteúdo por uma via
     interna que o CSS não alcança. Abre-se tudo antes, e repõe-se o que
     estava depois: quem imprime quer o documento, não o acordeão. */
  let antesDeImprimir = null;
  window.addEventListener("beforeprint", () => {
    antesDeImprimir = todas().map((d) => d.open);
    abrirTodas(true);
  });
  window.addEventListener("afterprint", () => {
    if (!antesDeImprimir) return;
    todas().forEach((d, i) => { d.open = antesDeImprimir[i]; });
    antesDeImprimir = null;
  });

  return feitos;
}

return { montar, envolver, abrirPara, sozinha, abrirTodas, actualizar, todas, parteDe, lidas };
})();
