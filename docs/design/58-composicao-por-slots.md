# 58 — Sprites · Composição por slots

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Cinco Sprite2D empilhados por personagem, um AnimationPlayer partilhado. Custo de desenho desprezável em 2D; poupança de trabalho artístico enorme — e é o que torna viável ter seis povos (§22).

| Slot | Ordem Z | Trocado por | Fonte do valor |
| --- | --- | --- | --- |
| body | 0 | Povo e escala | UnitData.people + scale_tier |
| head | 1 | Identidade | UnitRec.slots["head"] — sorteado do fluxo visual |
| face | 2 | Estado e lealdade | Derivado de health e loyalty. Nunca guardado. |
| weapon / shield | 3 | Nível de ferreiro | UnitRec.slots["weapon"] |
| overlay | 4 | Efeitos | Capacidades ativas, marca do arqueiro, rasto da Podridão |
| shadow | −1 | Largura do sprite | UnitData.shadow_width — obrigatório, §22 |


- **Nomenclatura de exportação** — <povo>_<entidade>_<slot>.aseprite → art/export/<povo>_<entidade>_<slot>.png + .json. Obrigatória: é o que permite a um agente gerar cenas sem ver a arte.
- **Tags** — idle 6 frames · walk 8 · attack 5 · die 7, a 10 fps. O Godot Aseprite Wizard importa respeitando tags e camadas.
- **Desfasamento** — Cada unidade arranca a animação num frame aleatório do fluxo visual. Sem isto, 300 aldeões respiram em uníssono e parecem um exército de clones.
- **Fora do ecrã** — VisibleOnScreenNotifier2D: continua a simular, para de animar. A simulação nunca depende de estar visível.
