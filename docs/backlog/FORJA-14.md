# FORJA-14 — a Forja fala Aseprite: o formato inteiro, provado contra o aplicativo

Estado feito — o formato 1.3, a composição, a folha e o JSON da CLI e a exportação por camada provados contra o
          Aseprite 1.3.18.6; as convenções do Empire, o corpo, o terreno e a construção em `.aseprite`; Q-302 e Q-303
          para o dono

## Pedido

O dono, a 29/10/2026: *«Se puder fazer total compatibilidade ao aseprite é meu sonho pois quero que seja
perfeitamente ajustado para essa ferramenta e compatível com camadas e animações bem searadas e definidas»*.

## Spec e autoridade

[Pesquisa e prova](../art/research/2026-10-29-forja-aseprite/README.md) (a especificação pública
`docs/ase-file-specs.md` do Aseprite 1.3.18.6, o código MIT de `src/doc` e `src/render`, e o aplicativo compilado),
[ADR 0100](../adr/0100-a-forja-fala-aseprite-provado-contra-o-aplicativo.md), [Asset Bible §2, §3 e §5](../art/ASSET_BIBLE.md),
[Aseprite: preparar, desenhar, animar e conferir](../art/ASEPRITE_WORKFLOW.md), [Guia da Forja](../art/FORJA.md),
[FORJA-12](FORJA-12.md) (o passo 2 do que ficou), AGENTS.md (regras 1, 8 e 9).

## Entrega

| Pedido | O que entrou | Evidência |
| --- | --- | --- |
| Compatibilidade total com o formato | `tools/forja/ase/`: leitor e escritor do 1.3 inteiro (camadas, grupos, tilemaps, cels ligadas e z-index, tags, slices com chaves, os 19 tipos de propriedade, paletas, tilesets, perfil de cor, ficheiros externos) | `test_ase_conformidade`: o que o Aseprite viu, os bytes, a ida e volta |
| Ver como o Aseprite vê | As 19 misturas e a composição portadas do código MIT; Indexed e Grayscale com as exceções do aplicativo | Cada quadro igual ao `--save-as` do Aseprite |
| Exportar como a CLI | `ase/export.py`: folha + JSON (`json-array`), `--layer`, tags, camadas, slices | As folhas da CLI, iguais menos `app`/`version` |
| Camadas bem separadas | `ase/empire.py`: slots e variantes da §2–§3, ordem Z da §58, camadas de trabalho, a exportação por camada do `tools/export_aseprite.sh`; `forja aseprite --slot --reference --kind` monta um corpo | A exportação igual à do script verdadeiro, no `troop.aseprite` do dono |
| Animações bem definidas | Uma tag por animação; o `die` sem ciclo toca uma vez; cels ligadas nos quadros repetidos; o lint `forja ase` (nomes do ANIMATION_BIBLE, `_left`/`_right`, contagens, durações, sobreposição, quadros sem tag) | `test_ase_empire` |
| Cenários e terreno | `forja estrutura --aseprite` (estados em tags, vãos, sinais, zonas e pivot em slices; `forja ase --scene` diz o desvio sem reescrever o contrato) e `forja tileset --aseprite` (o conjunto Wang no modo Tilemap) | `CenaTest`; o Aseprite abre e regrava os dois |
| As fontes do dono | As 22 de `art/source/` leem-se e exportam-se iguais ao Aseprite | `conformidade.json` (SHA-256 de cada uma) |

## Limite

Sem escrita em `art/` (o script correu numa cópia), `audio/`, `src/`, `scenes/` ou `data/`; sem dependências novas (o
Aseprite compilado é só da prova e não se versiona); sem aprovação artística. Fora da folha: `--trim`,
`--ignore-empty`, `--merge-duplicates`, `--split-*`, `packed`, bordas, `--scale` e `json-hash`; sem prova: a
composição com `compose_groups` ligado, a mistura antiga, a conversão ICC e os tilesets e paletas externos. A interface
gráfica não se abriu (a CLI em batch é o mesmo motor de documento). A importação no Godot não muda (ADR 0010). O pivot
no JSON do script e o nome da slice são a Q-302; as tags V15 fora do ANIMATION_BIBLE, a Q-303.

## Verificação

`ASEPRITE=… python3 docs/art/research/2026-10-29-forja-aseprite/conformidade/conformidade.py` (48 verificações e as
22 fontes, com o Aseprite); `python3 -m unittest tools.forja.tests.test_ase_conformidade tools.forja.tests.test_ase_empire`
(sem ele); `make forja`; portões estáticos locais; CI do PR.
