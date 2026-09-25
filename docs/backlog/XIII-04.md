# XIII-04 · §75 · A Oferta e a Dívida da Candeia

```text
Porque    É a alavanca 1: transforma A Podridão de fenómeno em personagem sem lhe acrescentar um ponto de vida.
Spec      docs/design/75-a-oferta-e-a-divida-que-ninguem-te-mostra.md
Depende   XIII-03
Contrato  o "Feito" é o contrato; os números vêm de data/ e da Spec
Feito     Uma oferta por noite, no prato, com o Verbo 1; a Dívida sobe e nunca desce; o Zelador aos 6
Fora      Os epílogos — é o XIII-08.
Estado    feito
Horas     20 (12 + 4 arte + 2 som + 2 escrita)
```

## Notas

- Os testes D-04 a D-06 estão escritos; D-05 e D-06 ficam saltados até este ticket.
- Q-040 e Q-053 decidem-se aqui: a oferta que salta a noite, e o preço da décima.
- **Feito, pelas três frases do contrato.** *Uma oferta por noite, no prato, com o Verbo 1*:
  `OfferSystem` (puro) e `OfferDesk` (a ponte, em `src/core/`) — a mancha fala a 300 px da muralha, na
  janela depois do crepúsculo, sorteia no fluxo `rot` entre as elegíveis pela gramática `requires`; só
  conta o que cai no prato; passados 20 s caduca, devolve o que lá estava e conta como recusa; as
  recusas da janela pesam na massa. *A Dívida sobe e nunca desce*: `DebtLedger`, e o D-06 deixou de
  estar saltado — prova-o pelos caminhos. *O Zelador aos 6*: nasce ao crepúsculo, não morre e não é
  alvo. O D-05 também corre. A frase e o prato veem-se (`OfferView`), e a Dívida vê-se na luz: halo e
  segunda chama. Testes: `tests/offer_system_test.gd`, `tests/oferta_jogo_test.gd` (pelo SimLoop).
- **O que fica para outros tickets, e porquê** (Q-087): só duas das doze ofertas são ditas hoje — as
  outras pedem portões, capítulos, nomes, sucessor ou povos. A Q-040 lê-se do `once_per_campaign`; a
  Q-053 não se decide aqui porque a décima oferta ainda não pode ser dita. A arte (o alguidar, a
  tipografia entalhada, o âmbar dos 9) e o som (a música a baixar) não são código.

---

Uma tarefa, uma sessão, um *merge* (§29). O campo **Fora** é o mais importante: é o que impede o agente — e a ti — de fazer três tarefas numa (§34). Se a tarefa depender de um valor marcado em `_proposed`, ou de uma pergunta aberta, diz-o em `docs/QUESTIONS.md` em vez de decidir.
