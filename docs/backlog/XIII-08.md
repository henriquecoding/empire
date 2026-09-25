# XIII-08 · §79 · Os doze diários e os três epílogos

```text
Porque    Três horas de código e dez de escrita. O trabalho todo é de escrita, e é o que não tem rede.
Spec      docs/design/79-a-arvore-foi-plantada-e-alguem-tinha-um-turno.md
Depende   XIII-04, XIII-07
Contrato  o "Feito" é o contrato; os números vêm de data/ e da Spec
Feito     Os doze diários alcançáveis em mil sementes (D-12) e o epílogo determinista (D-13)
Fora      O modo longo da Fase 8 — é onde O Turno vive.
Estado    parcial — a atribuição, o D-12, o D-13 e o diário 1 legível; os outros onze esperam pelas fortalezas e pelos capítulos
Horas     13 (3 + 10 escrita)
```

## Notas

- ADR 0018 tem a precedência. O D-13 já corre sobre os limiares do rot.tres.
- Doze fragmentos de 60 a 90 palavras. Se um precisar de 200, está a explicar.
- **Já feito:** a precedência dos três epílogos vive em `src/sim/systems/epilogue.gd` (`Epilogue.of`), o
  D-13 chama-a, e a `NightWatch.epilogue()` lê a Dívida e as listas da Colheita. O resto espera pelo XIII-07.
- **Feito com o XIII-07:** a atribuição por ato e o D-12. O `ChapterPlan` dá a cada capítulo colocado o seu
  diário, ou o de um capítulo que não saiu, e o D-12 prova-o em mil sementes.
- **O diário 1 já se lê.** Está na ruína dentro das muralhas desde o dia 1 (`Greybox.RUINA_X`), acha-se como um
  segredo do §17 — o rei entra lá — e o `JournalPanel` mostra o título e o corpo sem pausar o jogo. O sinal é o
  `secret_found` da §46 com o id do diário: o catálogo não tem um só para diários.
- **Falta:** os outros onze esperam pelas fortalezas (conquista, Fase 2) e pelos segmentos dos capítulos; e o
  ecrã do epílogo, que espera por um fim de campanha.

---

Uma tarefa, uma sessão, um *merge* (§29). O campo **Fora** é o mais importante: é o que impede o agente — e a ti — de fazer três tarefas numa (§34). Se a tarefa depender de um valor marcado em `_proposed`, ou de uma pergunta aberta, diz-o em `docs/QUESTIONS.md` em vez de decidir.
