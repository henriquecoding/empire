# XIII-07 · §77 · Os dez capítulos

```text
Porque    É o maior item único da parte e o risco alto da §84: 106 h, cortável até quatro sem partir nada.
Spec      docs/design/77-dez-lugares-uma-lei-cada.md
          docs/design/54-worldgen-determinista-e-por-camadas-separadas.md
Depende   GB-02, XIII-06
Contrato  o "Feito" é o contrato; os números vêm de data/ e da Spec
Feito     Seis por campanha, um por região, com O Cerco sempre; D-09, D-10 e D-11 a passar
Fora      Os diários — é o XIII-08.
Estado    parcial — a colocação e os diários feitos (D-09, D-11, D-12); as leis, a arte e as canções por fazer
Horas     106 (30 + 50 arte + 20 som + 6 escrita)
```

## Notas

- Q-043: seis por campanha. Q-054 e Q-055: duas raízes e três desvios por confirmar.
- Quatro é o mínimo viável se o calendário apertar (§84, risco 1).
- **Já feito — a colocação.** `src/sim/systems/chapter_plan.gd` (`ChapterPlan.draw`) sorteia no fluxo `world`
  os seis da campanha (`chapters_per_campaign` na curva), o Cerco sempre, um por região, e um capítulo de bioma
  só na região desse bioma. As regiões são uma por povo (`SimFactory.campaign_regions`). Os diários vão para o
  seu capítulo ou, se ele não saiu, para o seguinte que saiu, pela coluna `order` de `chapters.csv` (a ordem
  da §77). O D-09, o D-11 e o D-12 correm sobre mil sementes. Q-105: as contas dão 61 mundos, e não 126.
- **Por fazer:** a lei de cada um (dez sistemas pequenos), o habitante, a canção, a arte, e pôr o plano no
  mundo — o segmento do capítulo na região certa, com o desvio. É a Fase 5.

---

Uma tarefa, uma sessão, um *merge* (§29). O campo **Fora** é o mais importante: é o que impede o agente — e a ti — de fazer três tarefas numa (§34). Se a tarefa depender de um valor marcado em `_proposed`, ou de uma pergunta aberta, diz-o em `docs/QUESTIONS.md` em vez de decidir.
