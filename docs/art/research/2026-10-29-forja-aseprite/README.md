# A Forja e o Aseprite — o formato inteiro, provado contra o aplicativo (29/10/2026, FORJA-13)

> Pedido do dono (29/10/2026): *«Se puder fazer total compatibilidade ao aseprite é meu sonho pois quero que seja
> perfeitamente ajustado para essa ferramenta e compatível com camadas e animações bem searadas e definidas»*.
> Ticket [FORJA-13](../../../backlog/FORJA-13.md); decisão [ADR 0099](../../../adr/0099-a-forja-fala-aseprite-provado-contra-o-aplicativo.md).

## Em uma frase

A Forja passou a ler, escrever, renderizar e exportar o `.aseprite` 1.3 como o próprio Aseprite: cada ficheiro que o
Aseprite 1.3.18.6 fez, a Forja vê igual (camadas, grupos, mistura, cels, tags, slices, dados, paleta, tilesets) e
renderiza igual pixel a pixel; cada ficheiro que a Forja escreve, o Aseprite abre igual e regrava sem perder nada; a
folha e o JSON saem iguais aos da CLI; e a exportação por camada do `tools/export_aseprite.sh` sai igual sem o
Aseprite. Provou-se com o Aseprite compilado do código, nas **48 verificações** de `conformidade.py` e nas **22 fontes
`.aseprite` do dono em `art/source/`** (1256 quadros, 102 camadas, 125 tags), todas iguais
([`conformidade.json`](conformidade/conformidade.json), com o SHA-256 de cada ficheiro). O CI repete as conferências sem
o Aseprite (`tools/forja/tests/test_ase_conformidade.py`).

## O que entrou

| Peça | O que faz |
| --- | --- |
| `tools/forja/ase/` | O formato 1.3 completo: cabeçalho e flags, paletas nova e antigas, camadas (imagem, grupo, tilemap; flags, mistura, opacidade, UUID), cels (crua, ligada, comprimida, tilemap; z-index, cel extra), perfil de cor, ficheiros externos, tags, dados de utilizador com os 19 tipos de propriedade e mapas de extensão, slices (9-patch, pivot, chaves por quadro), tilesets. Leitor, escritor (byte a byte determinístico, na ordem do encoder do Aseprite), as 19 misturas e a composição portadas do código MIT do Aseprite, e a folha + JSON da CLI |
| `ase/empire.py` | As convenções do Empire: slots e variantes (ASSET_BIBLE §2–§3), ordem Z da §58, camadas de trabalho, `--list-layers`, a exportação por camada do script, e o lint `forja.ase_check/1` |
| `ase/cena.py` | O contrato de cena dentro do `.aseprite`: um quadro e uma tag por estado, o pivot, os vãos, os sinais e as zonas de mudança em slices, e o desvio entre o ficheiro e o contrato (o passo 2 que o FORJA-12 deixou) |
| `tools/forja/aseprite.py` | A fachada de sempre (`sheet`, `anim`, `forge --aseprite`, `prova`) sobre o núcleo novo, mais `assemble` (um corpo, uma camada por slot) e `tilemap` (um conjunto Wang no modo Tilemap) |
| Comandos | `aseprite` (com `--slot`, `--reference`, `--kind`), `ase` (só lê: como o Aseprite vê o ficheiro e as convenções; `--scene`), `exportar` (por camada como o script; `--composite`/`--layer` como a CLI), `tileset --aseprite`, `estrutura --aseprite`; todos também por MCP |

Um corpo montado pela Forja (`forja aseprite corpo_*.png --slot weapon_bow_l1=arco_*.png --reference ref.png --tags
idle,die --kind character_s1`) fica assim no Aseprite: `References` como camada de referência (o Aseprite nunca a
compõe nem a exporta), depois `shadow`, `body`, `face_*`, `weapon_*` pela ordem Z, cada uma com o slot e a variante
nos dados; uma tag por animação (`die`, que o ANIMATION_BIBLE diz sem ciclo, toca uma vez); um quadro igual ao anterior
na mesma camada como cel ligada; o pivot do contrato na slice `pivot`; o contrato nos dados do sprite.

## Como se provou

1. **O Aseprite compilado.** `v1.3.18.6` (commit `331e898`), `cmake -G Ninja -DCMAKE_BUILD_TYPE=Release
   -DLAF_BACKEND=none -DENABLE_UI=OFF -DENABLE_UPDATER=OFF -DENABLE_CCACHE=OFF` e `ninja aseprite`, com as bibliotecas
   de X11 do sistema que o `laf-os` pede. O proxy recusou o arquivo do libjpeg-turbo; usou-se um clone local da mesma
   tag (`3.0.2`), daí o `-dirty` na versão. É a CLI em modo batch, sem interface: o mesmo motor de documento, de
   leitura, escrita, composição e exportação do aplicativo. O binário não se versiona nem se distribui (EULA do
   Aseprite).
2. **`conformidade/gerar.lua`** faz o Aseprite criar sprites que cobrem a especificação: as 19 misturas em RGBA e em
   Grayscale sobre fundos de alfa 0, 128 e 255 com opacidade de camada e de cel; grupos aninhados, z-index, cels
   ligadas, camada contínua e escondida; tags nas quatro direções com repetições; slices com pivot e 9-patch; dados e
   propriedades; Indexed com alfa na paleta, índice transparente e fundo; tilemap com as três inversões.
3. **`tools/forja/tests/ase_cases.py`** são os sprites que a Forja escreve: o que o Lua não alcança (UUIDs, flags de
   camada, referência com limites, slices com várias chaves e uma escondida, os 19 tipos de propriedade, paleta que
   muda a meio, dados por peça de tileset) e as entregas reais — o corpo montado, o terreno Wang e a construção com os
   estados.
4. **`conformidade/conformidade.py`** junta-lhes três fontes pequenas do dono (`troop`, `archer`, `rose-7`) e, para
   cada ficheiro, pede ao Aseprite os quadros (`--save-as`), o que ele vê (`ler.lua`), a regravação dos da Forja, as
   folhas da CLI e o próprio `tools/export_aseprite.sh` numa cópia fora de `art/`; depois confere tudo. Passa também
   todas as fontes de `art/source/` pela leitura e pela folha completa. Com `--fixtures` copia os ficheiros para
   `tools/forja/tests/ase_fixtures/` (fora do LFS, 0,7 MB), onde o CI os confere de novo.

Reproduzir: `ASEPRITE=/caminho/aseprite python3 docs/art/research/2026-10-29-forja-aseprite/conformidade/conformidade.py`.

## O que o Aseprite faz e a especificação não diz

Observado no aplicativo e reproduzido na Forja; cada ponto tem caso nas fixtures.

- **A composição achata os grupos** (a preferência `compose_groups` vem desligada): a mistura e a opacidade de um
  grupo não contam, e a ordem é a das camadas mais o z-index da cel; a opacidade de camada só vale com a flag 1 do
  cabeçalho. Em Grayscale, os modos HSL compõem como `normal` e `addition` como `exclusion`.
- **A cor de uma tag** é o RGB antigo do chunk, opaco, até um chunk de dados a substituir inteira; o Aseprite escreve
  a cor de volta nesse campo. As fontes V15 do dono não têm chunk de dados por tag: as tags delas são `#6caea4`.
- **Uma paleta toda preta num sprite RGB** é regenerada ao abrir; por isso só se compara a paleta em Indexed.
- **As slices ficam na ordem inversa à do ficheiro** dentro do Aseprite (o Lua e o JSON da CLI listam-nas assim).
- **No PNG Indexed**, o alfa de cada entrada vai para o tRNS e o índice transparente só é transparente sem camada de
  fundo visível; um sprite com fundo opaco grava o quadro em RGB.
- **`--layer X`** torna visíveis X e os grupos acima dele (os descendentes escondidos continuam escondidos) e o JSON
  lista só esses; `--list-layers` lista as camadas visíveis, cada grupo depois dos filhos.
- **O JSON da CLI** escreve a repetição em texto e só quando existe, a cor da tag só quando tem alfa, as camadas de
  imagem com opacidade e mistura (os grupos sem), e cada cel só com o que não é omissão (num grupo, as dos
  descendentes); uma folha Indexed é `I8` com a paleta, uma Grayscale é RGBA; `--save-as` numera mesmo um quadro só.

## O que os ficheiros do dono mostram

- As 22 fontes leem-se e exportam-se iguais. O `troop.aseprite` (o «Empire troop» com que o script pedia para ser
  testado) tem `Knight` como **grupo** com `Body`, `Face`, `Shield`, `Sword` e `Equipments` dentro: o script salta o
  `Knight` e exporta os cinco, igual à Forja.
- O `tools/export_aseprite.sh` funciona: nomes, quadros, tags e durações conferem. **O pivot não chega ao JSON**: o
  script não passa `--list-slices`, e os originais não têm slice. As fontes V15 têm-no numa slice `ground_pivot` (a
  tela inteira, o ponto nos pés: 40,78 no rei de 80×80, 32,62 na Nia de 64×64, os pivots dos contratos `royal_80` e
  `royal_64`), nome que nenhum documento regista; a Forja escreve `pivot`. Ver Q-302.
- Os nomes antigos de camada (`Body`, `Equipments`, `Sword`, `Arms and Weapons`…) são os da tabela de correspondência da
  §2: o lint di-lo como informação. As tags V15 têm `_right`/`_left` (RUNTIME_ART) e ações que o ANIMATION_BIBLE não
  lista (`rise`, `play`, `deliver`, `sit`…), com contagens e durações próprias: o lint avisa e não decide (Q-303).
- O `concept.aseprite` (5120×720, 67 camadas) repete nomes (`Body` sete vezes): uma composição, não uma fonte por
  camada; o `--layer` não separa camadas com o mesmo nome e o lint di-lo como erro de exportação por camada.

## Limites

- Provou-se a CLI em modo batch, não a interface gráfica; o que só existe na interface (pele de cebola, preferências)
  não entra num ficheiro.
- A folha da Forja cobre `rows`, `columns`/`horizontal`/`vertical` e colunas por linha, com tags, camadas e slices.
  Não faz `--trim`, `--ignore-empty`, `--merge-duplicates`, `--split-layers`, `--split-tags`, `packed`, bordas,
  `--scale` nem `json-hash`: o pipeline do Empire não os usa (ASEPRITE_WORKFLOW §7), e pedi-los é erro, não aproximação.
- A composição com a preferência `compose_groups` ligada e a mistura antiga (`newBlend` desligado) estão no código e
  sem prova contra o aplicativo; o perfil ICC lê-se e escreve-se, mas não se converte; tilesets e paletas em ficheiro
  externo e os chunks antigos de máscara e caminho não têm caso.
- Um ficheiro em particular aberto no aplicativo continua a ser outra etapa (`opened_in_aseprite_app: false`): o que
  se provou é o formato, e as entregas da Forja de cada tipo (corpo, terreno, construção).
- A importação no Godot não muda: o Aseprite Wizard continua a pedir a ADR 0010 (ASSET_BIBLE §5).
