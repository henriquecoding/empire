# AUD-01 · Integridade da simulação: a moeda, o muro, a torre, o rei e o save

```text
Porque    A auditoria de 26/09 reproduziu seis defeitos que nenhum teste apanhava: o celeiro trocava de modo sozinho, retomar repetia a alvorada, a torre dava certeza longe dela, o muro em obra deixava de travar, a moeda do 0:20 pagava a Casa de Treino e o rei morto deixava a partida sem comando.
Spec      docs/recovery/AUDITORIA-GAMEPLAY-2026-09-26.md
          docs/design/55-buildsystem-moeda-fisica-slots-pre-definidos.md
          docs/design/07-o-modelo-de-combate-com-a-matematica-feita.md
          docs/design/16-morte-ressurreicao-e-derrota.md
Depende   —
Contrato  o "Feito" é o contrato; os números vêm de data/ e da Spec
Feito     Os oito testes de reprodução do anexo A passam a dar o comportamento certo, com teste novo por defeito
Fora      A economia (AUD-02), a noite (AUD-03), as faixas (AUD-04) e a campanha (AUD-05).
Estado    feito
Horas     8
```
