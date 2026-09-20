# ADR 0022 — Arte original no jogo e apresentação em lotes

Estado: implementada para o trecho dos Enramados, por pedido do autor de aplicar o relatório visual de 19/09/2026.

Revisão posterior do autor: [REFERENCE_AUTHORITY.md](../art/REFERENCE_AUTHORITY.md) corrige a seleção de personagens. O arqueiro original era conceito rejeitado; sua fonte fica arquivada, mas não é exportada nem usada. Arqueiros usam provisoriamente Body/Face da tropa e a marca de arco existente. Rei requer redesign e permanece provisório. O novo estudo visual não entra no runtime. O elenco quase concluído enviado pelo autor passa a orientar as próximas peças.

O pedido autoriza a integração de `art/` neste trabalho. A fonte é o conjunto original enviado pelo autor: `Empire troop.aseprite`, `Archer Troop.aseprite` e `Empire Concept.aseprite`. Não foram redesenhados ou reamostrados os pixels. A ferramenta de geração de imagens devolveu limite de utilização; nenhuma imagem nova foi produzida.

- As fontes pequenas e os exports necessários ficam em Git normal, com exceções explícitas ao LFS. Um checkout de CI sem LFS tem imagens utilizáveis. `make arte` confere a reprodução byte a byte.
- `tools/aseprite_source.py` suporta apenas os recursos necessários: RGBA, composição normal, cels raw/comprimidos/ligados, camadas e tags. Rejeita blend/opacity não suportados nas camadas selecionadas e tilemaps. Não substitui o editor Aseprite.
- Pillow já existe em `tools/requirements.txt`; não há dependência nova no jogo. O exportador não precisa de licença/comando Aseprite instalado no CI.
- `manifest.json` fixa seleção de camadas, ordem (incluindo Shield), recorte, pivot, durações e SHA-256 de cada fonte. `export_presets.cfg` inclui esse JSON no PCK.
- O idle original tem 100/100/100/100/150/100 ms, total 650 ms. O atlas compõe os slots offline. Cada faixa tem um canvas de unidades; não há AnimationPlayer ou conjunto de nós por entidade. A sombra e os corpos usam passes separados.
- Rei original: corpo de 90 px, canvas exportado de 60×94. É uma exceção explícita à meta 64×64. Tropas: corpo de 24×47 em canvas 49×54. Redesenhar a escala final exige arte; o runtime não encolhe o rosto.
- Perfis com original reconhecido usam sprite; outros mantêm a silhueta funcional anterior, para não transformar cavalos, aríetes ou lanceiros em cavaleiros com espada.
- Snapshot anterior/atual por ID fica apenas em apresentação, após o tick. Spawn, salto >32 px, mudança de faixa, novo estado e saltos de tick assentam imediatamente. A pausa mostra a posição atual. Câmera e sprite leem a mesma amostra.
- A região mantém 3840 px e o chão em y=517. A cena autorada organiza seis planos visuais e três Parallax2D, sem alterar as três faixas de simulação. A escada é desenhada em cada posição real de `SimLoop.passages`.
- `viewport` 1280×720, filtro nearest e escala inteira tornam a nitidez o padrão. 1080p tem barras; 1440p usa 2×. Isto substitui a proposta anterior da ADR 0001. Não foi acrescentado um menu de opções fictício.

Limite: sprites estáticos do concept não são ciclos de caminhada. O deslocamento de 1 px é um feedback transitório, documentado. O mínimo artístico completo (roupas, normal/hurt/hit/fear, walk/work/attack/die e copa final) permanece aberto. Nenhum ART é encerrado só por ter infraestrutura.
