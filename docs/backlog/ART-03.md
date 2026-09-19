# ART-03 · As seis camadas de parallax com teto de valores

```text
Porque    Com teto de valores as três camadas de fundo desenham-se em 5 h e ficam melhores. Sem ele, 12 h.
Spec      docs/design/11-o-mundo-em-duas-camadas.md
          docs/design/80-o-preto-entra-na-paleta-e-a-noite-deixa-de-ser-a.md
Depende   ART-02, F0-08
Contrato  o "Feito" é o contrato; os números vêm de data/ e da Spec
Feito     Distância 1 valor, plano médio 2, primeiro plano 2; o teste de silhueta passa no CI
Fora      Os seis biomas — Fase 2.
Estado    em curso — integração parcial em VIS-01; arte final pendente
Horas     5
```

## Notas

- É a única dependência dura de calendário da Parte XIII (§82): decidir agora custa 4 h, decidir na Fase 5 custa redesenhar os seis biomas.

---

Uma tarefa, uma sessão, um *merge* (§29). O campo **Fora** é o mais importante: é o que impede o agente — e a ti — de fazer três tarefas numa (§34). Se a tarefa depender de um valor marcado em `_proposed`, ou de uma pergunta aberta, diz-o em `docs/QUESTIONS.md` em vez de decidir.

Integração de 19/09/2026: ver VIS-01 e ADR 0022. Preservar o contrato de saída; infraestrutura ou um export estático não o encerram.
