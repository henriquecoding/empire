# 23 — Áudio · Camadas que respondem ao dia

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

- Motor: AudioStreamInteractive e AudioStreamSynchronized, nativos do Godot desde a 4.3. Não precisas de FMOD nem Wwise — poupa licença e complexidade de export web.
- Música: uma faixa por bioma, gravada em 4 stems: base, dia, tensão, noite. O GameClock faz crossfade de volumes. A Podridão a aproximar-se sobe o stem de tensão proporcionalmente à distância — o jogador ouve-a antes de a ver do outro lado do ecrã.
- Sino da manhã: marcador sonoro do amanhecer, como no Kingdom. É o teu sinal mais importante e deve ser inconfundível.
- Aviso do crepúsculo: som distinto quando A Podridão nasce. O jogador tem de conseguir reagir sem olhar para o HUD.
- SFX: variação por pitch (±8%) em tudo o que se repete: passos, moedas, flechas. Sem isto, 300 unidades soam a metralhadora.
- Limite de vozes: máx. 24 em simultâneo, com prioridade por proximidade da câmara. Obrigatório no export web (máx. 1 stream de música).

> **O orçamento de áudio**
>
> 6 biomas × 4 stems = 24 faixas, mais ~80 SFX. Isto é o item mais provável de subcontratares (§35): entre 1 200 € e 4 000 € para um compositor indie, ou biblioteca licenciada a 200–600 €. Decide cedo, porque a música define o tom das capturas de ecrã e dos trailers tanto quanto a arte.
