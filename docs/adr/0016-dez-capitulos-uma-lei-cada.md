# ADR 0016 — Dez capítulos, uma lei cada, e seis por campanha

- Estado: aceite
- Data: 2026-09-14
- Secção do dossiê: §17, §42, §53, §54, §77, §84

## Contexto
A §17 tinha quatro biomas caóticos tratados como modificadores de rota: sítios com uma regra estranha, sem
habitante, sem canção e sem narrativa agarrada. Eram a melhor ideia de mundo do dossiê a ser gasta como
modificador numérico.

## Decisão
Dez capítulos (`chapters.csv`), cada um com seis regras: uma lei numa frase; um habitante que a cumpre e nunca a
justifica; uma canção de 20 a 40 s sem letra traduzível; um diário ou uma Semente Anciã; um desvio com preço
escrito, porque nenhum capítulo bloqueia o caminho; e a lei não entra em casa. Exatamente um capítulo quebra a
última regra — o Forno Aceso — e é de propósito, para que a regra exista (Q-039).
O gerador coloca seis por campanha, no máximo um por região, sob a semente do mundo (§54) com o fluxo da §42. O
Cerco Que Não Acaba sai sempre, porque é ele que carrega o diário 12.
Cada lei tem uma raiz verificável, guardada na coluna `folk_root`, e o habitante nunca a explica: no momento em que
alguém disser ao jogador "isto é uma tradição portuguesa", o capítulo passou de mundo a museu.

## Alternativas consideradas
Escrever mais dez: o custo real não é escrevê-las, é a canção, o habitante e a arte de cada uma — 10,6 h por
capítulo. Trinta não cabem em lado nenhum.
Os dez sempre (Q-043): nove fichas sorteadas cinco a cinco dão 126 mundos, e quatro por descobrir valem mais do que
dez esgotados.

## Consequências
`chapters.csv` com dez linhas e 106 h na Fase 5 — o maior item único da Parte XIII, e o que a §84 marca como risco
alto. É cortável até quatro sem partir nada, porque só seis aparecem por campanha. Os testes D-09, D-10 e D-11
guardam o caminho alternativo, a exceção única e a presença do Cerco.
Reverter devolve os quatro biomas caóticos da §17 e deixa o diário 12 sem sítio.
