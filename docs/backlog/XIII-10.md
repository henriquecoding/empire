# XIII-10 · §83 · Os primeiros vinte minutos

```text
Porque    Sem isto o jogador conhece o Amargueiro tarde demais para ele significar alguma coisa.
Spec      docs/design/83-os-primeiros-vinte-minutos-com-a-candeia-la-dent.md
          docs/design/25-os-primeiros-doze-minutos.md
Depende   GB-01, XIII-03
Contrato  o "Feito" é o contrato; os números vêm de data/ e da Spec
Feito     O minuto 0:00 tem a candeia e um Amargueiro velho; o 17:00 tem a primeira oferta
Fora      O resto da campanha.
Estado    parcial — a primeira oferta fala na noite 2 e o §83 quer a 3 (Q-096)
Horas     8 (3 + 4 arte + 1 escrita)
```

## Notas

- §84, risco 5: o Amargueiro velho do minuto 0:00 existe para que a pergunta 'porque é que aquela árvore tem cara?' chegue depois da resposta.
- **0:00** — o Amargueiro velho está lá (GB-01); a candeia vem com a mancha ao crepúsculo, desde o F1-17.
- **17:00** — a primeira oferta da campanha é sempre *"Nada. Só quero ver."*: uma moeda no prato, +1 de Dívida, e um Capítulo por revelar guardado para o XIII-07 (o "sítio distante que se acende" do minuto 18:00). A noite corre igual nos dois casos, com teste.
- **Divergência (Q-096):** o `offers.csv` dá-lhe dia 2+ (§75) e o §83 põe-na no crepúsculo do dia 3; com os dados como estão, fala na noite 2.
- O minuto 13:10 (o vagabundo do 0:20 a levantar-se como árvore) já acontece pelos sistemas do XIII-03 e XIII-05; o 20:00 (o primeiro nome) pelo XIII-05.

---

Uma tarefa, uma sessão, um *merge* (§29). O campo **Fora** é o mais importante: é o que impede o agente — e a ti — de fazer três tarefas numa (§34). Se a tarefa depender de um valor marcado em `_proposed`, ou de uma pergunta aberta, diz-o em `docs/QUESTIONS.md` em vez de decidir.
