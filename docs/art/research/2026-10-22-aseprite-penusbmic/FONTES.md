# Fontes, método e limites da pesquisa

Data de consulta: 22/10/2026. Fonte primária é o próprio autor, a documentação
do software ou um documento do projeto. Resultados de busca serviram para
localizar essas fontes. Comentários de terceiros e páginas de resumo não
sustentam as instruções técnicas deste estudo.

## Vídeos solicitados

| Link | Autor e conteúdo confirmado | Acesso conseguido |
| --- | --- | --- |
| [Ep-_nJNHPc4](https://www.youtube.com/watch?v=Ep-_nJNHPc4) | Watt — ferramentas do Aseprite | Página, capítulos e transcrição |
| [hISJ2uflVCg](https://www.youtube.com/watch?v=hISJ2uflVCg) | Watt — cor, rampas e hue shifting | Página, capítulos e transcrição |
| [Playlist Pixel Art 101](https://www.youtube.com/playlist?list=PLmac3HPrav-9UWt-ahViIZxpyQxJ2wPSH) | Pixel Pete / Sad Slime Games | Catálogo e seleção de aulas por transcrição |
| [sx665YgtZVQ](https://www.youtube.com/watch?v=sx665YgtZVQ) | Penusbmic — processo de design de personagens | Página, capítulos e transcrição |

Os demais vídeos estudados estão ligados nas
[notas do Penusbmic](PENUSBMIC-NOTAS.md) e nas
[notas complementares](WATT-E-PIXEL-PETE-NOTAS.md). O
[catálogo JSON](catalogo-videos.json) registra o ID, o autor, a modalidade de
acesso, os tempos de consulta e o hash da transcrição usada como intermediário.
O hash identifica o material consultado; não prova observação visual ou
aprovação de uma técnica.

## Penusbmic — páginas públicas complementares

As páginas abaixo foram lidas para confirmar escopo e contexto dos materiais.
Isso **não** equivale a ter acesso aos ZIPs, fontes Aseprite ou aulas integrais
vendidos nessas páginas. Não houve compra, assinatura ou acesso a conteúdo pago.

| Página do autor | O que sustenta nesta pesquisa |
| --- | --- |
| [Catálogo oficial](https://penusbmic.itch.io/) | Organização de materiais de personagem, animação, cenário e efeitos |
| [Processo de personagem](https://penusbmic.itch.io/pixel-art-tutorial-the-ultimate-character-design-workflow) | Existência e escopo do tutorial correspondente |
| [Princípios de animação](https://penusbmic.itch.io/pixel-art-tutorial-12-principles-of-animation-applied-to-pixels) | Organização pública em staging/arcos, poses, aceleração e outros princípios |
| [Paletas](https://penusbmic.itch.io/pixel-art-tutorial-designing-palettes) | Escopo público da aula de teoria e criação de paleta |
| [Caminhada e corrida](https://penusbmic.itch.io/pixel-art-tutorial-run-walk-cycles) | Escopo público de análise de ciclos e corrida estilizada |
| [Castelo](https://penusbmic.itch.io/pixel-art-tutorial-create-a-castle-tileset) | Diferença entre tiles de base/fundo e decoração |
| [Cena com rochas e arbustos](https://penusbmic.itch.io/pixel-art-tutorial-building-a-statement-scene-bushes-rocks) | Escopo de composição e materiais da aula |
| [Casas](https://penusbmic.itch.io/pixel-art-tutorial-designing-houses) | Existência de uma aula de arquitetura do começo ao fim |
| [Inimigos voadores](https://penusbmic.itch.io/pixel-art-tutorial-creating-flying-enemies) | Relação entre versões condensadas públicas e material completo |
| [Pinheiros](https://penusbmic.itch.io/pixel-art-tutorial-drawing-pine-trees) | Escopo da aula de árvores |

A página de catálogo do canal não é prova de que todo o canal foi percorrido.
O inventário de vídeos recentes é uma janela do canal, não sua contagem total.
O vídeo `Ukg2n-G8aGA`, sobre paletas, exibiu restrição para membros e foi
registrado como não estudado. Não foi usado para extrair uma aula por outra via.

## Aseprite — documentação oficial lida

| Fonte | Operação conferida |
| --- | --- |
| [Documentação](https://www.aseprite.org/docs/) | Estrutura de autoria, animação e exportação |
| [Animação](https://www.aseprite.org/docs/animation/) | Relação entre timeline, frames, camadas e cels |
| [Onion Skin](https://www.aseprite.org/docs/onion-skinning/) | Referência de quadros vizinhos e configuração |
| [Cels vinculadas](https://www.aseprite.org/docs/linked-cels/) | Compartilhamento de imagem/posição e desvinculação |
| [Modo de cor](https://www.aseprite.org/docs/color-mode/) | RGB, Indexed e transparência |
| [Preview](https://www.aseprite.org/docs/preview-window/) | Prévia em tempo real durante a edição |
| [Ink](https://www.aseprite.org/docs/ink/) | Lock Alpha, composição e pintura |
| [Shading](https://www.aseprite.org/docs/shading/) | Percurso da rampa de cores selecionadas |
| [Tags](https://www.aseprite.org/docs/tags/) | Intervalos e modos de reprodução |
| [Slices](https://www.aseprite.org/docs/slices/) | Regiões, pivô e metadados |
| [Tilemap](https://www.aseprite.org/docs/tilemap/) | Reuso de peças e modos Manual/Auto/Stack |
| [Tiled Mode](https://www.aseprite.org/docs/tiled-mode/) | Teste de padrões e emendas |
| [CLI](https://www.aseprite.org/docs/cli/) | Opções de exportação e inclusão de metadados |

O exemplo de CLI deste estudo é ilustrativo e não foi executado. Não foi
instalado software ou plugin novo para a produção do jogo. A documentação pode
avançar depois desta revisão; conferir as opções na versão em uso.

## Fundamentos de pixel art

- [cure — tutorial no Pixel Joint](https://pixeljoint.com/forum/forum_posts.asp?TID=11299):
  agrupamentos, jaggies, banding, pillow shading e pixels isolados com função.
- [Derek Yu — fundamentos](https://derekyu.com/makegames/pixelart.html):
  autoria na escala dos pixels, ferramentas e processo de trabalho.

O estudo não reproduz integralmente essas obras. Usa explicações próprias e
remete ao original para os exemplos e demonstrações.

## Fontes internas e precedência

Foram confrontados o [contrato do agente](../../../../AGENTS.md), a
[Asset Bible](../../ASSET_BIBLE.md), a [Animation Bible](../../ANIMATION_BIBLE.md),
o [guia de personagens](../../CHARACTER_PRODUCTION_GUIDE.md), o
[fluxo de animação](../../CHARACTER_ANIMATION_WORKFLOW.md), a
[autoridade de referências](../../REFERENCE_AUTHORITY.md), a
[direção de outubro](../../ART_DIRECTION_2026-10-05.md) e a
[ADR do importador](../../../adr/0010-godot-aseprite-wizard.md).

A nova pesquisa organiza técnicas. As decisões posteriores de Henrique e os
contratos do projeto conservam sua precedência. Propostas antigas, desenhos
rejeitados e exemplos do professor não são promovidos silenciosamente a regras.

## Como interpretar a evidência

| Registro | Significado | Não comprova |
| --- | --- | --- |
| Página/metadados | Autor, título e contexto consultados | Aula estudada |
| Transcrição recuperada | Texto disponível para leitura | Imagens, áudio ou terminologia infalível |
| Trecho anotado | Parte do conteúdo usada na síntese | Domínio de todo o canal |
| Aplicação ao Empire | Proposta editorial coerente com o projeto | Regra original do professor |
| Integridade técnica | Arquivos e links conferidos | Aprovação artística |
| Exercício proposto | Próxima prova de autoria descrita | Exercício executado ou asset corrigido |

Preservar essa distinção numa continuação. A memória de uma conversa não
substitui consultar a fonte, a versão e o estado efetivo do projeto.
