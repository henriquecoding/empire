# XIII-10 · §83 · Os primeiros vinte minutos

```text
Porque    Sem isto o jogador conhece o Amargueiro tarde demais para ele significar alguma coisa.
Spec      docs/design/83-os-primeiros-vinte-minutos-com-a-candeia-la-dent.md
          docs/design/25-os-primeiros-doze-minutos.md
Depende   GB-01, XIII-03
Contrato  o "Feito" é o contrato; os números vêm de data/ e da Spec
Feito     O minuto 0:00 tem a candeia e um Amargueiro velho; o 17:00 tem a primeira oferta
Fora      O resto da campanha.
Estado    parcial — a primeira oferta cai no dia 2 e não no 3 (Q-089)
Horas     8 (3 + 4 arte + 1 escrita)
```

## Notas

- §84, risco 5: o Amargueiro velho do minuto 0:00 existe para que a pergunta 'porque é que aquela árvore tem cara?' chegue depois da resposta.
- **O minuto 0:00** tem o Amargueiro velho e a candeia (F1-17). **A primeira oferta** é sempre *"Nada.
  Só quero ver."* — a mais barata, de propósito —, com o alguidar e o preço de uma moeda; paga, acende a
  bifurcação. A árvore de uma tropa tua leva o chapéu na casca (13:10). Teste: `tests/abertura_test.gd`.
- **O que falta:** a primeira oferta cai ao minuto ~11 (dia 2) e não ao 17:00 (dia 3). É o `min_day 2`
  do `offers.csv` contra o §83 — ver a Q-089. O resto do ticket é arte e escrita.

---

Uma tarefa, uma sessão, um *merge* (§29). O campo **Fora** é o mais importante: é o que impede o agente — e a ti — de fazer três tarefas numa (§34). Se a tarefa depender de um valor marcado em `_proposed`, ou de uma pergunta aberta, diz-o em `docs/QUESTIONS.md` em vez de decidir.
