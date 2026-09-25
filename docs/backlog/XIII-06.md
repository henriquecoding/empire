# XIII-06 · §78 · A Colheita

```text
Porque    Dá corpo à melhor frase do dossiê — a escolha estava a ser feita desde o primeiro cerco.
Spec      docs/design/78-a-colheita-e-as-duas-maneiras-de-acabar-com-um-p.md
Depende   F1-16
Contrato  o "Feito" é o contrato; os números vêm de data/ e da Spec
Feito     C = 6 + 2 × povos; a aldeia fica fora das muralhas; soltar ou ficar, com o Verbo 1 no núcleo deles
Fora      O coro por povo — é o XIII-09. Os estandartes — entram aqui, por acessibilidade.
Estado    parcial — falta a conquista, que é da Fase 2 (Q-090)
Horas     11 (8 + 3 arte)
```

## Notas

- Q-042: a sexta Colheita em 16 dias mede-se em playtest.
- §82: cada povo solto hasteia um estandarte — é a redundância visual do coro.
- **O que está feito:** `src/sim/systems/harvest_system.gd` — C = 6 + 2 × povos, metade por assimilação,
  uma de cada vez com fila, soltar ou ficar no fim, a aldeia que cai perde o povo, a produção a 140% e
  depois +80% se ficaste, e o marco que cria raiz e pesa na noite. Anda na alvorada, vai no save, e conta
  para as ofertas (`peoples`) e para o epílogo (`NightWatch.epilogue()`). Teste:
  `tests/harvest_system_test.gd`.
- **O que falta** (Q-090): a conquista e as aldeias no mundo, que são da Fase 2 — sem elas nenhuma Colheita
  começa, e não há núcleo deles onde largar. Os estandartes e o que a decisão dá (Favor, rota, tropa única)
  esperam pelos sistemas deles.

---

Uma tarefa, uma sessão, um *merge* (§29). O campo **Fora** é o mais importante: é o que impede o agente — e a ti — de fazer três tarefas numa (§34). Se a tarefa depender de um valor marcado em `_proposed`, ou de uma pergunta aberta, diz-o em `docs/QUESTIONS.md` em vez de decidir.
