# Cenários de produção nativa — CV-02

As composições aprovadas em 15/10 e as variações de 16/10 foram reconstruídas em
camadas: oito reinos, porto, lago, rio e duas transições. As fontes estão em
art/source/scenery_native. Os PNG de fonte são intermediários criativos; o jogo usa
somente os PNG menores e recortados em art/export/scenery_native.

## Usar no projeto

Abra tools/native_scenery_review.tscn no Godot fixado em .godot-version.
A/D ou setas: andar; E junto à escada: mudar de faixa; B: alternar obra
construída/terreno livre; Page Up/Page Down: trocar composição. Cada composição
também tem uma cena em scenes/scenery_native.

A galeria usa os personagens reais do projeto e um controlador de revisão.
Não acrescenta regras de campanha, economia, personagens ou posições de rios.
Os planos far/mid/near dos reinos entram na campanha pelo SceneryArt;
céu e nuvens conservam o mosaico original. A cobertura do solo usa uma fonte nova com
massas maiores, caminhos livres e menos ruído, na grade de 2 px. Mantém
as faixas e os sítios existentes;
a geometria dos sítios e das passagens da campanha continua autoritativa.
Porto, lago e rio são prefabs de produção, com pisos e acessos exercitados na galeria.
Sua população e construção pertencem ao estado registrado do jogo.

## Contrato técnico

Viewport 1280 × 720; superfície y=517; nível inferior y=618,5.
O corpo do personagem controlado cabe em 64 × 64; PNJs de revisão em 32 × 32,
preservando proporção, animação, transparência e posição dos pés.
Cada margem inferior seca tem acesso próprio. Vãos sobre água bloqueiam a
caminhada inferior. A travessia superior e as escadas permanecem visíveis no
estado sem edifícios. Edifícios, objetos e PNJs ficam fora do Parallax2D.

Céu, nuvens, fundo distante, plano médio e marcos próximos usam, respectivamente,
0,03125 / 0,07 / 0,125 / 0,25 / 0,5 no eixo horizontal.
Água de fundo e água jogável são separadas na linha da superfície: a água não
atravessa a copa ou o tronco das árvores. Corte de solo, piso, travessias,
construções e acessórios também são camadas distintas.
A campanha conserva o terreno funcional associado aos sítios existentes.

PNG com alfa binário; redução de paleta sem dithering; amostragem nearest e grade
de 2 px na ação / 4 px à distância. Variações compartilham as texturas e aplicam
receitas discretas de cor, estação, maré e aurora, sem filtro de desfoque.

Cada família inclui modules_64.png, um TileSet .tres, a colocação dos módulos em
JSON e layers.ora, fonte editável em camadas no formato OpenRaster. O módulo é
uma unidade de montagem; não obriga um edifício inteiro a caber em um tile.

## Reproduzir e verificar

- python3 tools/export_native_scenery.py
- python3 tools/export_native_scenery.py --check
- godot --headless --import --path .
- godot --headless --path . tools/verify_native_scenery.tscn
- xvfb-run -a godot --path . --rendering-method gl_compatibility tools/capture_native_scenery.tscn
- ./run_tests.sh
- make vistoria
- make portoes

O relatório docs/art/scenery_native_validation.json contém o resultado real da
travessia física, ida/volta pelas passagens, estados construído/vazio e importação
dos TileSets. Capturas e medições do renderizador ficam em build/scenery-native.
Essas capturas mostram montagens preparadas; não certificam uma campanha
com novos portos nem desempenho em um dispositivo físico.

Fontes e pacotes de referência anteriores foram preservados. Não se misturou
um ZIP antigo com a entrega nova.


## Conteúdo do jogo exportado

Os presets de Linux, Windows e Web incluem as texturas da campanha e deixam
fora os atlas de edição, os prefabs de revisão e as cópias antigas substituídas.
Esses materiais continuam disponíveis no projeto e no pacote de produção.
O CI abre os três PCKs em um projeto vazio e confere a presença das texturas
usadas pelo jogo, além da exclusão dos materiais de revisão.
