# Aseprite — preparar, desenhar, animar e conferir

Fluxo de trabalho derivado da pesquisa de 22/10/2026. Entrada:
[guia de estudo](PIXEL_ART_STUDY_GUIDE.md). Este documento complementa os
contratos de exportação e nomenclatura; não substitui a [Asset Bible](ASSET_BIBLE.md).
As operações abaixo foram conferidas na documentação. Não houve execução do
Aseprite nesta sessão.

## 1. Preparar a sessão

Abrir a referência aceita, a fonte editável e uma composição de teste com o
personagem na escala do jogo. Conferir tela, pivô, linha do solo, direção,
paleta e camadas antes de acrescentar frames. Guardar uma cópia de trabalho
fora dos diretórios gerados quando estiver apenas experimentando.

Manter o [Preview](https://www.aseprite.org/docs/preview-window/) visível para
confrontar a edição ampliada com a leitura pequena. O atalho padrão é F7;
Shift+Enter reproduz a prévia. Atalhos podem ser personalizados, portanto
confirmar o comando no menu se a instalação divergir.

Criar uma grade que represente a função do arquivo: pixel para limpeza,
módulos para cenário e margem para armas. O Snap to Grid ajuda a posicionar
módulos, mas pode atrapalhar a correção de um rosto. Antes de interpretar
saltos do cursor como defeito do desenho, conferir essa opção e a seleção ativa.

## 2. Cor e transparência

[RGB e Indexed](https://www.aseprite.org/docs/color-mode/) têm comportamentos
diferentes. Em RGB cada pixel guarda seus canais; em Indexed ele referencia
uma entrada da paleta, cuja alteração afeta todos os pixels correspondentes.
Em camadas transparentes de Indexed existe um índice reservado à transparência.
Duplicar a fonte antes de converter e conferir esse índice na conversão.

Uma paleta de trabalho organiza escolhas; ela não comprova contraste nem
harmonia da cena. Usar a paleta do Empire e propor separadamente qualquer
alteração. Não adotar Apollo, Resurrect ou outra paleta porque aparece na aula.
HSV é uma forma de selecionar cor: **V é valor**, não uma medida de luminância
percebida. Uma checagem em cinza continua útil para avaliar a hierarquia.

O [Lock Alpha](https://www.aseprite.org/docs/ink/) preserva o alpha já existente
ao pintar RGB; serve para sombrear uma silhueta sem expandi-la. Desativá-lo
quando for necessário mudar a borda. Não confundir com travar a camada inteira.

O [Shading ink](https://www.aseprite.org/docs/shading/) percorre as cores
selecionadas da paleta nos dois sentidos com os botões do mouse. Conferir a
ordem da rampa antes de usar. Ele não calcula luz nem decide onde está o plano
de sombra. Misturas com alpha e ajustes globais podem criar cores novas:
conferir o resultado contra a paleta antes de exportar.

## 3. Da silhueta ao material

| Passo de trabalho | Operação útil | Conferência |
| --- | --- | --- |
| Explorar forma | Contour, formas preenchidas, seleção e cópias lado a lado | Silhuetas diferem por massas, não apenas acessórios |
| Marcar volumes | Seleção ou Lock Alpha; poucas massas de luz/sombra | Fonte de luz consistente e volumes reconhecíveis |
| Ajustar proporções | Mover agrupamentos inteiros; conservar versão anterior | Pés, mãos, rosto e escala continuam coerentes |
| Produzir detalhes | Lápis e seleção por região/material | Detalhe acrescenta função sem fragmentar a forma |
| Limpar | Rever diagonais, junções, banding e pixels residuais | Leitura preservada a 1× e em fundos diferentes |

Pixel Perfect ajuda certos traços do lápis; não é um botão que resolve todas as
diagonais ou uma garantia de qualidade. Seleções e rotações são úteis no
blockout, mas o raster transformado precisa de revisão. Não reduzir uma pintura
e declarar a conversão automaticamente concluída como pixel art nativa.

As [notas das aulas](research/2026-10-22-aseprite-penusbmic/PENUSBMIC-NOTAS.md)
identificam o contexto em que cada ferramenta foi demonstrada.

## 4. Animação em passes

Seguir o [fluxo de poses do projeto](CHARACTER_ANIMATION_WORKFLOW.md):
resolver chaves; testar tempo e transições; completar passagens; acrescentar
reações secundárias; limpar todas as camadas. A translação de componentes é
uma ferramenta de trabalho, não substituto para desenhar uma articulação.

Usar [Onion Skin](https://www.aseprite.org/docs/onion-skinning/) para comparar
quadros anteriores e seguintes; configurar quantos aparecem e sua cor de
referência. Comparar também duas poses sem sobreposição, pois onion skin pode
ocultar uma mão faltando ou uma mudança de volume.

As [cels vinculadas](https://www.aseprite.org/docs/linked-cels/) compartilham
imagem e posição. Isso é útil em partes realmente estáticas. Desvincular antes
de criar uma variação independente e conferir se a alteração não se propagou
para um trecho que deveria permanecer igual. A extensão de cel apresentada na
aula do Penusbmic é um complemento, não requisito nativo do fluxo.

[Tags](https://www.aseprite.org/docs/tags/) organizam intervalos e direção de
reprodução. Usar os nomes existentes no projeto. Reverse e Ping-pong são modos
de execução; não equivalem a novos desenhos. Conferir também o último quadro
e o primeiro da tag seguinte.

Anotar tempos em milissegundos e respeitar a cadência contratada. Os exemplos
de oito quadros do professor não mudam o `idle` canônico do Empire. Expressões
como “75” numa legenda automática não devem ser convertidas em 75 fps sem
verificação da unidade na interface.

## 5. Camadas e pontos de ligação

Camadas de autoria podem ajudar a separar membros e testar sobreposição, mas
a entrega precisa mapear cada uma aos slots da Asset Bible. Anotar o que é
parte de trabalho e o que realmente será exportado. Conferir partes ocultas:
mover a cabeça pode expor um pescoço que nunca foi desenhado.

[Slices](https://www.aseprite.org/docs/slices/) registram regiões nomeadas e
podem guardar um pivô. Seu pivô é relativo à região; converter para a convenção
usada pelo importador. Slices não se tornam automaticamente sockets do jogo.
Preservar o contrato atual de `socket_*` até existir uma migração verificada.

No estudo de personagens feito no Pixquare, o autor usa máscaras e modos de
mesclagem daquela aplicação. Importar a intenção de separar volumes; conferir
a operação equivalente disponível no Aseprite antes de prescrever o mesmo menu.

## 6. Tiles e repetição

[Tiled Mode](https://www.aseprite.org/docs/tiled-mode/) mostra a repetição do
canvas e ajuda a encontrar emendas de um fundo. [Tilemap](https://www.aseprite.org/docs/tilemap/)
trabalha com células que referenciam peças de um tileset. São recursos diferentes.

No modo de edição de pixels de um Tilemap, Manual altera peças existentes sem
reordená-las; Auto pode criar, reutilizar e remover peças não usadas; Stack
cria novas peças nas modificações. Para um atlas com índices já referenciados,
trabalhar numa cópia e conferir IDs depois da edição. O Aseprite não valida por
isso as colisões ou os caminhos no Godot.

Montar uma área de teste maior que uma peça, incluindo cantos internos,
externos, encontro entre materiais e margem de água. Manter base e decoração
separadas. Testar repetição irregular, noite e personagem sobre o chão antes
de gastar tempo numa biblioteca inteira.

## 7. Exportação de diagnóstico

O [CLI oficial](https://www.aseprite.org/docs/cli/) exporta imagem e metadados.
Exemplo de diagnóstico composto, usando uma cópia de trabalho com apenas as
camadas desejadas visíveis:

```bash
ASEPRITE="${ASEPRITE:-aseprite}"
SOURCE="build/study_aseprite/character.aseprite"
mkdir -p build/study_aseprite/export
"$ASEPRITE" -b --list-tags --list-slices --list-layers "$SOURCE" \
  --format json-array --sheet-type rows \
  --sheet build/study_aseprite/export/character.png \
  --data build/study_aseprite/export/character.json
```

O exemplo preserva quadros vazios e caixas inteiras: não usa `--trim`,
`--ignore-empty` ou `--merge-duplicates`. Reduzir duplicação ou recortar pode
ser adequado num pipeline que reconstitui offsets; conferir isso antes.
`--list-slices` e `--list-tags` incluem esses metadados no JSON. Sua presença
não comprova que o importador os consome.

Para entrega por slot, a referência é `tools/export_aseprite.sh`. A 29/10
(FORJA-13) correu com o Aseprite 1.3.18.6 sobre o `troop.aseprite`: nomes,
quadros, tags e durações conferem, e o pivot não vai no JSON (o script não passa
`--list-slices`; Q-302). A Forja faz o mesmo sem o Aseprite (`forja exportar`;
`--composite` é este diagnóstico) e confere um `.aseprite` contra as convenções
(`forja ase`); ver o [guia da Forja](FORJA.md#aseprite-o-formato-inteiro-como-o-aplicativo-o-vê).
Nada disto declara o Aseprite Wizard instalado.

## 8. Conferência da entrega

Comparar PNG e fonte; verificar retângulos, ordem, duração, tags e direção;
conferir pivô e sockets; montar a composição com a linha do solo; abrir o
`.aseprite` no editor; testar no Godot. Registrar separadamente cada etapa.
Não transformar “metadados presentes” em “animação aprovada”.

Plugins e scripts vistos nos tutoriais permanecem opcionais e não foram
instalados. Uma necessidade real de dependência segue a regra de ADR do projeto.
