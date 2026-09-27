# CONT-01 · Transição durável: o legado como transação

```text
Porque    Uma escrita falhada do legado apagava os saves na mesma, e o jogo novo gastava o legado antes de ter um save seu (N7, N8): perdia-se a única recuperação.
Spec      docs/recovery/AUDITORIA-GAMEPLAY-2026-09-27.md
          docs/design/16-morte-ressurreicao-e-derrota.md
          docs/adr/0007-save-security.md
Depende   —
Contrato  o "Feito" é o contrato; os números vêm de data/ e da Spec
Feito     Falhas ao abrir, escrever, validar e renomear deixam exatamente um estado recuperável; reiniciar em cada fronteira não duplica nem perde recompensas; o erro não se anuncia como travessia feita
Fora      Quanto se retém, custos, recompensas e a regra da derrota.
Estado    feito — LegacyStore: temporário, leitura de volta e rename; os slots só se apagam depois; o primeiro save do jogo novo gasta o legado (Q-139)
Horas     8
```
