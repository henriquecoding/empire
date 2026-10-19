> ARQUIVO DE ESTUDO. A rodada visual foi rejeitada em 18/10/2026. Este texto preserva pesquisa/propostas; não declara arte aprovada. Leia primeiro o README desta pasta.

## 12. Fontes primárias consultadas

Acessadas em 18/10/2026. As sínteses foram aplicadas às decisões específicas do projeto; não se copiaram sprites de terceiros.

| ID | Fonte | Utilidade nesta revisão |
| --- | --- | --- |
| S01 | [Derek Yu — Pixel Art Tutorial: Basics](https://derekyu.com/makegames/pixelart.html) | Resolução, linhas, volume, paleta e limites do detalhe |
| S02 | [Derek Yu — Common Mistakes](https://derekyu.com/makegames/pixelart2.html) | Tons semelhantes, pillow shading e desenho rígido |
| S03 | [Saint11 — Cluster Sketching and Painting](https://saint11.art/pixel_art_articles/article2/) | Organização por grupos de pixels e uso intencional do detalhe |
| S04 | [Saint11 — Anti-Alias and Banding](https://saint11.art/pixel_art_articles/article5/) | Limpeza das transições e controlo das bordas |
| S05 | [Saint11 — Consistency](https://saint11.art/blog/consistency/) | Coerência de resolução, posição, escala e rotação |
| S06 | [SLYNYRD — Pixelblog 8: Intro to Animation](https://www.slynyrd.com/blog/2018/8/19/pixelblog-8-intro-to-animation) | Poses principais, energia e duração dos quadros |
| S07 | [SLYNYRD — Pixelblog 9: Melee Attacks](https://www.slynyrd.com/blog/2018/9/8/pixelblog-9-melee-attacks) | Peso da arma, antecipação e resposta ao comando |
| S08 | [SLYNYRD — Pixelblog 22: Top Down Character Sprites](https://www.slynyrd.com/blog/2019/10/21/pixelblog-22-top-down-character-sprites) | Relação de escala entre personagem, frame e ambiente |
| S09 | [SLYNYRD — Pixelblog 55: Top Down Character Animation](https://www.slynyrd.com/blog/2025/3/24/pixelblog-55-top-down-character-animation) | Consistência de anatomia e detalhes durante as poses |
| S10 | [SLYNYRD — Pixelblog 57: Knights, Monsters & Castles](https://www.slynyrd.com/blog/2025/7/28/pixelblog-57-knights-monsters-amp-castles) | Corpo sob armadura, materiais e massas de luz |
| S11 | [SLYNYRD — Pixelblog 60: Side View Run ’N Gun](https://www.slynyrd.com/blog/2026/1/26/side-view-run-n-gun) | Corpo lateral, equipamento, roupa e movimento secundário |
| S12 | [SLYNYRD — Pixelblog 29: Anime Faces and Hair](https://www.slynyrd.com/blog/2020/7/28/pixelblog-29-anime-faces-and-hair) | Organização dos traços e do perfil; limites da aplicação de retratos aos sprites |
| S13 | [Dana Boadway-Masson — Facial Animation 101](https://www.animationmentor.com/blog/facial-animation-101/) | Intenção, reação e construção da atuação facial |
| S14 | [Shawn Kelly — Learn How to Animate Your Character’s Face](https://www.animationmentor.com/blog/how-to-get-great-expressions-and-animate-faces/) | Coerência do rosto como unidade expressiva |
| S15 | [Aseprite — Animation](https://www.aseprite.org/docs/animation/) | Quadros, camadas, tags e organização |
| S16 | [Aseprite — Onion Skinning](https://www.aseprite.org/docs/onion-skinning/) | Comparação de quadros e pontos de referência |
| S17 | [Aseprite — Linked Cels](https://www.aseprite.org/docs/linked-cels/) | Partilha de imagem/posição e prevenção de alterações propagadas |
| S18 | [Godot — Multiple Resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html) | Escala inteira e apresentação sem deformar os pixels |
| S19 | [Anthony Wong — Building Appealing Character Poses](https://www.animationmentor.com/blog/tutorial-building-appealing-character-poses-for-animation/) | Gesto, peso, silhueta, espaços entre membros e oposição entre quadril e ombros |
| S20 | [Jay Jackson — Solid Drawing](https://www.animationmentor.com/blog/solid-drawing-the-12-basic-principles-of-animation/) | Linha de ação, equilíbrio e assimetria |
| S21 | [SLYNYRD — Pixelblog 52: Idle Fighting Stance](https://www.slynyrd.com/blog/2024/9/26/pixelblog-52-idle-fighting-stance) | Decomposição da postura ativa e relação entre os movimentos |
| S22 | [Chris Bourassa — entrevista sobre Darkest Dungeon](https://www.gamedeveloper.com/audio/road-to-the-igf-red-hook-studios-i-darkest-dungeon-i-) | Massas escuras e intenção tonal; não é referência de resolução ou sprite |

Na documentação Godot, a escala inteira evita que pixels sejam apresentados com larguras diferentes durante o redimensionamento. Esse controlo será conferido na integração; não foi alterado nesta etapa [S18].

### Base documental do Empire

O estudo anterior consultou a main no commit [0c351775e2c569e83fc746ca339202753cd203ae](https://github.com/henriquecoding/empire/commit/0c351775e2c569e83fc746ca339202753cd203ae). Esta revisão reutiliza as cópias desse estudo, em particular:

- docs/design/08-imperadores-companhias-e-desbloqueios.md
- docs/art/EXPRESSION_GUIDE.md
- docs/art/REFERENCE_AUTHORITY.md
- docs/art/ANIMATION_BIBLE.md
- docs/art/ASSET_BIBLE.md
- data/source/monarchs.csv
- src/actors/original_art.gd e src/actors/actor_action.gd

A secção de compatibilidade descreve esse retrato documental, não uma nova auditoria da main ou um playtest do deployment. Nenhum desenho foi integrado no jogo nesta etapa.

