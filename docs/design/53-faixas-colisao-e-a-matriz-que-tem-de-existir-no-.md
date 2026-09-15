# 53 — Faixas · Faixas, colisão e a matriz que tem de existir no dia 1

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

A invariante I3. Uma câmara só, três faixas, camadas de física separadas. A matriz abaixo é a configuração exata do projeto.

| Camada | Bit | Colide com | Notas |
| --- | --- | --- | --- |
| L_AERIAL | 1 | Terreno alto, projéteis de arqueiro e torre | Voadoras. Ignoram tudo o que é de solo. |
| L_SURFACE | 2 | Terreno, edifícios, muralhas, moedas | O jogo do Kingdom acontece aqui |
| L_UNDER | 4 | Terreno de cavidade, passagens | Tropas de defesa nunca descem |
| L_TERRAIN | 8 | Todas as três faixas, seletivamente | TileMapLayer com máscara de revelação |
| L_BUILDING | 16 | Superfície e subsolo | Só o que é atacável |
| L_COIN | 32 | Nada — é apanha por proximidade | Colisão de moeda com 300 unidades é desperdício |


**Transição de faixa** — Só através de PassageRec. Um grafo de 20 a 60 nós, Dijkstra, recalculado quando uma cavidade é revelada. Não é NavigationServer2D — é pequeno de mais para justificar.

sign(alvo.x − self.x) mais separação por steering. O mundo é uma linha; A* seria absurdo.

Aí sim há túneis ramificados. NavigationRegion2D só nesta faixa, e só depois da Fase 3.

Movimento livre em X e Y dentro da faixa aérea, com flocking leve. Só atacáveis por arqueiros e torre alta — e isso é a máscara, não um if.
