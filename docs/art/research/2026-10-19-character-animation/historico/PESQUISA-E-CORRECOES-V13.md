# Pesquisa aplicada — animação de personagens Empire

Consulta: 18–19 de outubro de 2026. A tarefa é corrigir a V12 e entregar personagens completos animados em quadros 64×64/80×80.

## Diagnóstico confirmado nos arquivos

1. `source/pose.cjs` da V12 deslocava, girava e deformava máscaras extraídas da pose parada. Na caminhada, as pernas eram deformadas por uma função de deslocamento entre quadril e bota. Isso não desenhava corretamente a perna que passa por baixo do corpo.
2. `source/special.cjs` da V12 ocultava braços e arco do Arqueiro para repor formas muito simples. A presença de pixels e o tamanho correto do arquivo não comprovavam uma anatomia legível.
3. Sombra descia o tronco e girava pernas. Faltavam poses de quadril e joelhos que conduzissem ao repouso, e as ombreiras exigiram remendos.
4. O campo de flores existia num arquivo separado, mas não era composto com o Sombra na prévia entregue. A habilidade parecia não acontecer.
5. Os números de quadros da V12 incluíam espelhos e repetições. Quantidade de entradas não representa quantidade de poses desenhadas.

## O que a pesquisa estabeleceu

**Poses antes de quantidade.** Raymond Schlitter demonstra que contato e passagem sustentam o movimento; intermediários devem conectar poses fortes, não diluir o gesto. Também chama atenção para erros de um único pixel que se tornam evidentes em loops. Aplicação: caminhada com contato, carga, passagem e subida das duas pernas; ataque com preparação e retorno reconhecíveis. Fonte: [SLYNYRD, Pixelblog 8](https://www.slynyrd.com/blog/2018/8/19/pixelblog-8-intro-to-animation).

**Tempo não é uniforme.** No estudo de ataques, Schlitter organiza antecipação, movimento, contato e recuperação, com exposições diferentes conforme a arma. Aplicação: tempos próprios para espada, duas machadinhas e disparo. O estudo usa vista superior; a transferência para Empire é dos princípios de timing, não uma cópia das poses ou da perspectiva. Fonte: [SLYNYRD, Pixelblog 56](https://www.slynyrd.com/blog/2025/5/23/pixelblog-56-top-down-character-attack-animation).

**Construção de sequência.** Pedro Medeiros distingue desenho sequencial de trabalho por poses-chave e explica timing e manutenção de volume. Aplicação: corpo inteiro coerente em cada fase; preservar volume de cabeça e tronco ao sentar e cair. Fonte: [Saint11, A Basic Aseprite Animation](https://saint11.art/pixel_art_articles/article3/).

**Revisar vizinhos.** A documentação do Aseprite permite comparar quadros adjacentes e controlar duração e tags. Aplicação: inspeção em sequência, origem fixa, fontes editáveis com tempos explícitos. Fontes: [Onion skinning](https://www.aseprite.org/docs/onion-skinning/), [Animation](https://www.aseprite.org/docs/animation/), [Tags](https://www.aseprite.org/docs/tags/).

**O que PixelLab documenta hoje.** A ferramenta nova de animação textual aceita de 4 a 16 quadros em contagens pares e preserva a primeira imagem. O editor de animações permite corrigir várias poses conjuntamente. A documentação de esqueletos recomenda corrigir articulações e congelar quadros/regiões satisfatórios, inclusive para reparar um braço. São recursos documentados, não uma descrição confirmada dos mecanismos internos do modelo. O interpolador antigo tem limitação de 64×64; essa restrição não deve ser generalizada às ferramentas novas. Fontes: [Animate with Text New](https://www.pixellab.ai/docs/tools/animate-with-text-new), [Edit Animation Pro](https://www.pixellab.ai/docs/tools/edit-animation-pro), [Animate with Skeleton](https://www.pixellab.ai/docs/tools/animate-with-skeleton), [Interpolation](https://www.pixellab.ai/docs/tools/interpolation). O PixelLab não foi executado nesta entrega.

**Tempo e textura na engine.** Godot admite animação com imagens individuais ou atlas e permite duração relativa por quadro em SpriteFrames. Aplicação: guardar retângulos, pivôs, tempos e eventos em JSON, sem pressupor que isso já conecte as ações à simulação. Fontes: [Godot, 2D sprite animation](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html), [SpriteFrames](https://docs.godotengine.org/en/stable/classes/class_spriteframes.html).

## Correções executadas

| Problema | Alteração | Como inspecionar |
|---|---|---|
| Braços do arqueiro ilegíveis | Nova sequência completa de armar e disparar, com ombros, braços, mãos e retorno | `shoot_right` e `shoot_left` |
| Sombra apenas comprimido | Poses de flexão, apoio e pernas dobradas, seguidas por repouso e levantar | `sit`, `heal`, `stand` |
| Floração ausente na demonstração | Novo campo, crescimento e camadas compostas com o Sombra | `SOMBRA-FLORACAO-V13.gif` e `sombra-cura-composta.aseprite` |
| Bardo leva mão ao chapéu | Segunda geração específica para manter ambas as mãos no alaúde | `play` |
| Recortes desalinhados | Separação por componentes opacos e verificação das caixas antes da adaptação | PNGs individuais e arquivo de verificação |
| Espaço insuficiente para o arco | Pivô do Arqueiro deslocado para reservar área à frente | JSON de cada direção |
| Ações sem fases intermediárias | Sequências com preparação, desenvolvimento e recuperação | Controle de quadro da prévia |

## Limites que permanecem

A geração das poses começou em pranchas maiores; depois elas foram adaptadas à grade final. A revisão não deve ser descrita como desenho manual original em 64/80. A direção esquerda é espelhada; `rise` reverte os quadros de queda. A coroa e os eventos ainda precisam ser ligados à mecânica do jogo. Não houve teste de importação no Godot nem abertura no aplicativo Aseprite. A validação binária independente confirma os arquivos, não aprovação artística.
