# Empire — personagens animados V12

Continuação dos oito corpos completos V11. Preserva a aparência, a barba do Bardo, o bigode do Intendente, o rosto sem barba do Arqueiro e o elmo fechado do Sombra. Os movimentos foram construídos na grade final dos sprites, sem interpolação de cor ou suavização. A base V11 havia sido adaptada de conceitos gerados; este pacote não a reclassifica como desenho original do zero em 64/80.

## Abrir e implementar

1. Extraia o ZIP e abra **ABRIR-PREVIA.html** no navegador. Funciona sem servidor, com seleção de ação, direção, pausa e velocidade.
2. Em **personagens/<nome>/**, abra o **.aseprite** para editar camadas e tags; os PNGs transparentes estão em **acoes/** e **atlas.png**.
3. Cada célula tem exatamente o tamanho indicado abaixo. O atlas tem oito colunas; animacoes.json fornece o retângulo, duração e pivô de cada quadro. Não corte as margens nem redimensione para outra grade.
4. Use filtro **Nearest**, mipmaps desativados e coordenadas inteiras. O pivô de chão é [largura/2, altura−2]. A direção left é o espelho exato de right, incluindo os equipamentos.
5. Os ciclos são no lugar: o jogo move o personagem no mundo. O JSON marca momentos de impacto, flecha e entrega; esses marcadores não disparam sinais ou alteram a simulação.

## Conteúdo

| Personagem | Quadro | Animações (em ambas as direções) |
| --- | --- | --- |
| rei | 80×80 | idle, walk, run, hit, die, rise, interact, celebrate, blink, attack, command, pay |
| escudeiro | 64×64 | idle, walk, run, hit, die, rise, interact, celebrate, blink, block, block_hold, block_hit |
| nia | 64×64 | idle, walk, run, hit, die, rise, interact, celebrate, blink, attack, command |
| bardo | 64×64 | idle, walk, run, hit, die, rise, interact, celebrate, blink, play, cast, inspire |
| arqueiro | 80×80 | idle, walk, run, hit, die, rise, interact, celebrate, blink, shoot, reload, mark, pay |
| intendente | 64×64 | idle, walk, run, hit, die, rise, interact, celebrate, blink, receive, deliver, collect, no_payment |
| sombra | 80×80 | idle, walk, run, hit, die, rise, interact, celebrate, sit, heal, stand |
| dancarina | 64×64 | idle, walk, run, hit, die, rise, interact, celebrate, blink, dance_start, dance, dance_end |

Os ciclos principais usam 10 fps: idle 6 quadros, walk 8, attack 5 e die 7. Run usa seis quadros a 12 fps, com durações 83/84/83 ms. O piscar é uma ação separada para não ocorrer a cada ciclo de repouso; não se aplica ao elmo fechado do Sombra.

O manifesto registra 1006 entradas de quadro e 192 tags. A contagem inclui as duas direções e poses reaproveitadas; não representa esse número de desenhos distintos.

## Queda, coroa e cura

- **die** termina em queda sentada/ajoelhada, com os olhos fechados. **rise** levanta sem recolher a coroa. A camada **crown** é separada; a posse e a recolha continuam sob controle do jogo.
- **Sombra** tem sit → heal → stand. As flores são um efeito separado de 160×32, em **efeitos/**. Elas não aumentam o quadro do personagem. Use grow uma vez, idle durante a cura e wither ao terminar.
- Foram animadas as formas iniciais presentes na V11. Não se acrescentaram armas de evoluções ou um ataque indefinido ao Sombra.

## Arquivos de apoio

- **previas/**: GIFs individuais, duas pranchas animadas, PNG e vídeo MP4. As prévias têm fundo e ampliação; os PNGs de jogo têm transparência.
- **source/**: pixels-base, máscaras, poses, codificadores PNG/Aseprite e exportador reproduzível.
- **verificacao.json**: resultado da leitura independente de todos os PNGs e Aseprite.

Para reconstruir os assets, com Node.js e Python 3:

~~~sh
node source/export.cjs pasta-de-saida
node source/flowers.cjs pasta-de-saida
node source/viewer.cjs pasta-de-saida
python3 source/verify.py pasta-de-saida
~~~

A exportação de assets usa apenas bibliotecas padrão. O gerador opcional de prévias usa Sharp e FFmpeg, disponíveis no ambiente desta entrega; não são dependências do jogo.

## Validação e estado

Foram conferidos tamanho nativo, alfa 0/255, duração, pivô, intervalos das tags, espelhamento e igualdade de pixels entre PNG e Aseprite. As sequências foram inspecionadas em pranchas ampliadas. Os arquivos não foram abertos no aplicativo Aseprite nem executados no Godot nesta entrega, pois esses aplicativos não estavam disponíveis. A revisão artística final continua com o autor.

As alterações permanecem na documentação de arte e no pacote de entrega. Nenhum arquivo de art/, audio/ ou da simulação foi alterado.

## Referências de construção

- Pesquisa arquivada: docs/art/research/2026-10-18-imperadores-escudeiros/.
- Regras do projeto: ANIMATION_BIBLE.md, EXPRESSION_GUIDE.md, ASSET_BIBLE.md e docs/design/08-imperadores-companhias-e-desbloqueios.md. As dimensões 64/80 solicitadas pelo autor prevalecem sobre propostas antigas de 128.
- Especificação do formato Aseprite: https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md
- Referência de animação em pixel art: https://saint11.art/blog/pixel-art-tutorials/
- Godot SpriteFrames: https://docs.godotengine.org/en/stable/classes/class_spriteframes.html
