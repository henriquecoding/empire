# CONT-03 · Snapshot do trabalho: o Staffing no save

```text
Porque    Quem trabalhou antes de gravar deixava de contar ao retomar: 0,467 contínuo contra 0,292 retomado (N5), contra a Q-121.
Spec      docs/recovery/AUDITORIA-GAMEPLAY-2026-09-27.md
          docs/design/06-producao-conversao-e-comercio.md
Depende   —
Contrato  o "Feito" é o contrato; os números vêm de data/ e da Spec
Feito     Contínuo e retomado produzem o mesmo com trabalhador presente, ausente, morto ou transferido antes do snapshot
Fora      Produção por segundo.
Estado    feito — o Staffing grava a fase, quem serve e quem serviu; retomar fecha a fase igual (Q-141)
Horas     4
```
