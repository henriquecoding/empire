# XIII-04 · §75 · A Oferta e a Dívida da Candeia

```text
Porque    É a alavanca 1: transforma A Podridão de fenómeno em personagem sem lhe acrescentar um ponto de vida.
Spec      docs/design/75-a-oferta-e-a-divida-que-ninguem-te-mostra.md
Depende   XIII-03
Contrato  o "Feito" é o contrato; os números vêm de data/ e da Spec
Feito     Uma oferta por noite, no prato, com o Verbo 1; a Dívida sobe e nunca desce; o Zelador aos 6
Fora      Os epílogos — é o XIII-08.
Estado    feito — 4 das 12 ofertas com preço e efeito ligados (Q-091)
Horas     20 (12 + 4 arte + 2 som + 2 escrita)
```

## Notas

- Os testes D-04 a D-06 estão escritos; D-05 e D-06 ficam saltados até este ticket.
- Q-040 e Q-053 decidem-se aqui: a oferta que salta a noite, e o preço da décima.
- **Os sistemas.** `OfferRules` (a gramática da §75: três formas, vírgulas em AND, e o que não cabe nunca é elegível), `DebtLedger` (a Dívida de 0 a 20, que só tem `incur` e nenhuma subtracção; as recusas das últimas cinco noites; o que é permanente), `OfferSystem` + `OfferPrice` (quando fala, o prato, os 20 s, se o preço caiu dentro) e `Tender` (o Zelador). A ponte com o jogo é o `OfferWatch`, chamado pela `NightWatch`.
- **Uma por noite, no prato, com o Verbo 1.** Fala quando a mancha chega a 300 px da muralha mais exterior do lado dela, nunca antes dos 20 s depois do crepúsculo e sempre até aos 60. O sorteio entre as candidatas sai do fluxo `rot` (§42), sobre as ofertas por id. O prato fica à borda da mancha, do lado do império. Só conta o que cai lá dentro; o monarca não é preço de ninguém. Aceitar sai como `rot_fed` na §46 — é o "alimentar" que a §75 diz ter finalmente interface.
- **Recusar** é não fazer nada: passam os 20 s e conta como recusa. As recusas das últimas cinco noites pesam no crepúsculo (+8 cada, até +40) e voltam a zero ao aceitar uma vez. Uma noite sem candidatas fica calada, e isso não é recusa.
- **A Dívida sobe e nunca desce**, e o D-06 prova-o por caminhos. **O D-05 e o D-06 deixaram de estar saltados.**
- **O Zelador aos 6**: nasce com a mancha, anda atrás dela, um muro de pé pára-o, e se chegar ao núcleo leva uma tropa nomeada — uma por noite. Afastá-lo não tem gesto (Q-092).
- **O mostrador é a luz.** A candeia só ilumina a faixa da mancha; a Dívida vai-a estendendo às vizinhas (1, 1,5, 2 faixas, o ecrã inteiro), pela tabela da §75. A frase aparece no mundo por chave de `strings.csv`, sem caixa e sem contador. O ambiente âmbar dos 9–11 e as duas chamas dos 12+ ficam para a arte da candeia.
- **Só quatro ofertas têm hoje onde pegar** (a quarta, *Nada. Só quero ver.*, entrou com o XIII-10) — o preço e o efeito das outras dependem de portões, tesouraria, Capítulos, sucessor e povos (Q-091). Nenhuma aparece para não fazer nada. Q-040 e Q-053 ficam por decidir por isto.
- **Informação para o §66 (Q-093):** o instrumento dos dez dias não paga ofertas, e por isso recusa todas; com o imposto das recusas, a defesa do décimo dia cai ao dia 9. O teste do §66 mede o que media (a mancha calada) e diz-o; o de recusar sempre está saltado com a razão. Nenhum número de `data/` foi mexido.
- `rot.csv` ganha `offer_plate_px` (96, em `_proposed`, Q-090).

---

Uma tarefa, uma sessão, um *merge* (§29). O campo **Fora** é o mais importante: é o que impede o agente — e a ti — de fazer três tarefas numa (§34). Se a tarefa depender de um valor marcado em `_proposed`, ou de uma pergunta aberta, diz-o em `docs/QUESTIONS.md` em vez de decidir.
