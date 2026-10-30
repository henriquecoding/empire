# FORJA-18 — geração nativa de animações e revisão da sequência completa

Estado feito — adaptadores, retoma, reparo por quadro e portão implementados; CI exigida antes do merge.

Henrique, 30/10/2026, pediu para implementar os pontos pendentes da auditoria FORJA-17.
Autoridade: OWNER_RULES.md, guias de personagens/animação, Animation Bible, ADR 0103 e auditoria de 30/10.

Fechar adaptadores PixelLab text-v3/skeleton-v3 com referência nativa, contagens e pontos validados,
jobs/budget retomáveis sem repetir POST, conservação de todos os quadros e revisão vinculada à sequência.
A aprovação artística da sequência permanece separada e exclusiva do dono; o programa não a fabrica.

Sem novos assets, mecânicas, paletas ou cadências. Esqueletos devem ser observados e fornecidos explicitamente;
não inventar anatomia para satisfazer o adaptador. A prova usa transporte falso e rasters sintéticos.

Implementado: plano offline com recompilação antes da rede; text-v3/skeleton-v3; índice plano/job e
retoma GET; preservação dos brutos/ordem; export nativo PNG/JSON/Aseprite/GIF/APNG; prova com conceito;
reparo por máscara em quadros explícitos; identidade da sequência completa; perdas por quadro;
revisão de cada quadro/ação e aprovação separada do dono. Guia: docs/art/FORJA_ANIMATION.md, ADR 0104.

Testes novos começam por falhar com os módulos ausentes; casos de integridade também reproduziram
divergências de pivô/tags e revisão inválida. Validação paga/artística não executada. `hit` 2 não cabe
nos limites v3 e mantém desenho nativo/prancha, sem truncar uma geração maior.
