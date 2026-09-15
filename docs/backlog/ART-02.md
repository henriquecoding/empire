# ART-02 · A paleta mestra e o LUT

```text
Porque    A paleta decide-se uma vez e entra em tudo. Com o preto na paleta (ADR 0011), muda a base.
Spec      docs/design/22-pipeline-de-pixel-art-e-a-paleta-mestra.md
          docs/design/80-o-preto-entra-na-paleta-e-a-noite-deixa-de-ser-a.md
Depende   F0-01
Contrato  o "Feito" é o contrato; os números vêm de data/ e da Spec
Feito     112 cores com as famílias do §22; o LUT da noite leva a saturação para 0,22
Fora      Desenhar seja o que for com ela — é o ART-01.
Estado    por fazer
Horas     4
```

## Notas

- ADR 0011: os três valores de silhueta entram aqui — #17130D, #241F17 e #2E251A, #100D09 e #14140F.

---

Uma tarefa, uma sessão, um *merge* (§29). O campo **Fora** é o mais importante: é o que impede o agente — e a ti — de fazer três tarefas numa (§34). Se a tarefa depender de um valor marcado em `_proposed`, ou de uma pergunta aberta, diz-o em `docs/QUESTIONS.md` em vez de decidir.
