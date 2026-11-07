# FORJA-20 — Levar Pixel Art Lighter ao jogo e à Forja

Estado feito — núcleo portado da versão 3.5.23, exportação editável e consumo de atlas alinhados no jogo.
Pedido de Henrique de 07/11/2026. Ver [ADR 0106](../adr/0106-luz-facetada-por-pixel.md), §80 e
[fluxo de luz da Forja](../art/FORJA.md#luz-facetada-e-aseprite).

- A Forja gera uma normal facetada e uma máscara de luz direta por quadro. Os perfis partem de pixels nativos.
- A fonte Aseprite RGB guarda camadas auxiliares ocultas e editáveis com a timeline, tags e pivôs.
- O jogo desenha os oito corpos reais V15 com os mapas na grade dos atlas atuais e as luzes da faixa.
- A prova automatizada cobre alfa, orientação da luz, reexportação manual, pivô, timeline e correspondência dos atlas.
