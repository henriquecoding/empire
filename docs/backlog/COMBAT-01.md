# COMBAT-01 — Combate direto das classes

```text
Estado    feito
```

Pedido do dono em 01/10/2026: ataque e habilidade por botão nas classes, com combate refinado. Fontes: §07, §08, §24, §43, §50, §61; ADR 0045 e Q-184.

## Critérios

- [x] Corpo controlado não ataca sozinho; tropas mantêm a IA.
- [x] Ataque e habilidade têm botões visíveis e gestos de teclado, rato e comando.
- [x] Direção, alcance, faixa e aliados são respeitados no golpe.
- [x] Cadência, tolerância curta, pausa e troca de corpo não duplicam ataques.
- [x] Marca não dispara flecha; canto não depende da recarga do ataque.
- [x] Efeitos, mira e recargas tornam o combate legível.
- [x] Suite completa, portões, dados, vistoria, export e verificação visual.
- [ ] PR e merge na main; publicação verificada.

Testes novos em `player_combat_test.gd`, escritos antes da implementação. Ajustes de integração em `classes_gameplay_test.gd`. Números propostos do ataque do Bardo e tolerância continuam declarados nos CSV.

Verificação final: suite integral executada; as duas suites que falharam foram corrigidas/reexecutadas com as suites de combate, total de 47 casos sem falhas. Tick com 300 unidades: 2197,2 µs, abaixo do limite de 4000 µs. Vistoria: três dias, núcleo perdido, nenhuma invariante quebrada. Export Web revisto em 1280×720, 800×600 e 390×844, com entrada real por teclado e botões; textos PT e EN.
