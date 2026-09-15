# 57 — Coroa · CrownSystem — ganância, impulsos, sucessão

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

- **Ganância** — Um float de 0 a 100 por império. Lê-se no mundo pelo número de nobres visíveis na varanda — não há número no ecrã. Sobe com riqueza acumulada, desce com gasto.
- **Impulso real** — Um por dia, pela roda do rei. Emite royal_impulse_used; o efeito é um Resource, não um match com cinco casos.
- **Morte do rei** — king_died com heir_id. Se há herdeiro, succession_started. Se não, é derrota — e a morte é permanente, por isso este caminho tem de ser à prova de bala e testado desde a Fase 1, não na Fase 6.
- **Herança** — O herdeiro herda a ganância do pai com desvio. É como um império se degrada ao longo de uma partida sem nenhum sistema de dificuldade.
