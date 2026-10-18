# Construção dos rostos — fonte do autor e aplicação V9

## Autoridade visual

O pedido atual mantém os conceitos apreciados e exige melhorar a anatomia facial usando os rostos criados pelo próprio autor. As duas entradas foram lidas localmente, sem modificar seus arquivos:

| Entrada | SHA-256 |
| --- | --- |
| `Empire Tileset.aseprite` | `42e68ad619897aff2a0130bfb4a3492748a0efac6b9b3f7a91bf63ce0a477f77` |
| `image(20261018-112000).png` | `4231de3944f7f51331d901b65b817bd029b0017bece32ea4832e04d816d6e64c` |

O Aseprite tem uma tela RGBA de 1280×720, um quadro e grupos com personagens e cenário. A captura é uma apresentação ampliada; as medidas abaixo vêm dos cels nativos do arquivo editável.

- Grupo `Knight`: composição visível de 45×51 pixels. O cel da camada `Face` tem **12×14**, em (1037,470) na tela original. Há uma cópia do mesmo cavaleiro no grupo `Knight Copy`.
- Grupo `Emperor`: composição de 56×90; camada `Body` de 46×90, incluindo cabeça/corpo, e `Accessories` de 53×32. Essas dimensões são da fonte de estudo, não uma mudança dos quadros 64/80 pedidos para a entrega.

A referência demonstra uma linguagem cômica: olhos brancos com pupilas pequenas; sobrancelhas com espessura; ponte e base nasal; cavidade escura da boca; dentes agrupados; lábio inferior e queixo. A informação depende da relação entre esses grupos, não de pontilhar uma área com cores.

## Diagnóstico aplicado

Em V8, vários olhos eram reduzidos a traços, a boca do arqueiro formava um U semelhante a um bigode, e lábio e mandíbula estavam pouco separados. Havia área de pele disponível para reorganizar os marcos faciais.

V9 reaproveita essa área. O rosto maior do rei recebe olhos, nariz e boca mais subdivididos; os menores abreviam o olho distante e mantêm grupos de dentes. O nariz usa o mesmo conjunto de cores locais da bochecha, com sombra inferior, em vez de uma mancha rosa/vermelha exclusiva. Os pelos faciais continuam fazendo parte da identidade. O Sombra usa um elmo fechado: não se inventa uma face humana dentro dele.

As edições são explícitas em `source/faces.cjs` e `nativeEdits`. Os grupos de pixels têm coordenadas na imagem final. Não há reamostragem entre o desenho das novas feições e os PNGs 64/80. As pranchas de rosto são somente recortes desses PNGs.

## Apoio técnico consultado

- [Saint11 — Basic Shading](https://saint11.art/pixel_art_articles/article4/): seu exercício em 48×48 reorganiza e enfatiza olhos/boca para que leiam melhor que uma redução. Aplicação: aumentar a clareza de cada massa expressiva antes de adicionar detalhe.
- [SLYNYRD — Human Anatomy](https://www.slynyrd.com/blog/2019/5/21/pixelblog-17-human-anatomy): espaçamento de olhos, nariz, boca, orelhas e queixo como estrutura. Aplicação: usar marcos espaciais, mantendo a deformação cômica do autor.
- [SLYNYRD — Faces and Hair](https://www.slynyrd.com/blog/2020/7/28/pixelblog-29-anime-faces-and-hair): colocação precisa e abstração das feições. O estilo anime desse artigo não é adotado; a autoridade estética é o Aseprite do autor.
- [Aseprite — especificação oficial](https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md): leitura de camadas, hierarquia/visibilidade e cels RGBA comprimidos; arquivos de saída com camadas editáveis e paleta.

## Alcance da conferência

Foram conferidos os corpos completos, recortes iguais V8/V9, reprodução literal e integridade dos arquivos. O verificador compara pixels de PNG/Aseprite/atlas, tamanho, alfa, limites da edição facial e ampliações de apresentação. Esses controles confirmam a entrega técnica; a avaliação artística continua pertencendo ao autor.
