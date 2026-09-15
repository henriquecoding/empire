# XIII-11 · §84 · Os catorze testes de design e as seis linhas de risco

```text
Porque    Sem eles, os números das outras secções desafinam-se sozinhos até ao mês oito.
Spec      docs/design/84-os-testes-que-impedem-isto-de-apodrecer-e-os-ris.md
          docs/design/31-testes-ci-e-os-testes-de-design.md
Depende   XIII-02
Contrato  o "Feito" é o contrato; os números vêm de data/ e da Spec
Feito     Os catorze escritos; os que precisam de sistemas ficam saltados com a razão e o sistema que falta
Fora      Escrever os sistemas que os testes esperam.
Estado    feito
Horas     6
```

## Notas

- ADR 0019. Feito: tests/parte_xiii_rot_test.gd e tests/parte_xiii_mundo_test.gd, 20 casos, 16 a correr e 4 saltados com razão escrita.
- As seis linhas novas do registo de risco entram em docs/risk/ com a §37.

---

Uma tarefa, uma sessão, um *merge* (§29). O campo **Fora** é o mais importante: é o que impede o agente — e a ti — de fazer três tarefas numa (§34). Se a tarefa depender de um valor marcado em `_proposed`, ou de uma pergunta aberta, diz-o em `docs/QUESTIONS.md` em vez de decidir.
