# Plano de revisão — HUD medieval em pixel art

```text
Estado    parcial — pesquisa e conceitos entregues para aprovação visual; implementação não iniciada
```

Pedido do dono de 18/10/2026: estudar profundamente os fundamentos de pixel art,
criar conceitos medievais coerentes com personagens de base 64 × 64 e registar
o conhecimento no repositório. Aprofundar os conceitos 1 e 3: Oficina do Reino
e Vigília da Fronteira. As propostas anteriores não constituem aprovação.

Especificação de base: §§22, 24, 26 e 61; ADR 0074/0078; UX-08 e UX-10.

- Pesquisa e contrato: `docs/ux/HUD-PIXEL-2026-10-18.md`.
- Pranchas, galeria e proveniência: `tools/web/site/estudos/hud/`.
- Reprodução: `python3 tools/render_hud_study.py`.
- Verificação: `python3 tools/verify_hud_study.py`.

As composições demonstram dia, noite, subsolo, pausa, ficha de fundação, toque,
estados e ícones nos dois conceitos. Os contadores são ilustrativos. A roda,
o conteúdo completo do estado do reino, a sucessão e a viagem ainda não têm
pranchas próprias; a continuidade desses percursos está especificada no estudo.

A implementação do tema no Godot depende da escolha visual do dono. Não se
alteram `src/`, `art/`, `audio/`, simulação, dados, gestos, saves ou preços.

Aceitação da fase seguinte: direção aprovada, tipografia legível, atlas nativo,
mesma linguagem nos menus pendentes, capturas comparáveis e validação real de
teclado/comando/toque com a escala física correta. Não marcar como feito apenas
porque há imagens e uma página de revisão.
