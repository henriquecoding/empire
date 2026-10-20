# Fontes primárias e aplicação ao Empire

Leituras das pesquisas de 18–19/10/2026. Este registro preserva a consulta daquela ocasião; não é nova auditoria de disponibilidade ou de versões atuais. Documentos completos no [índice](README.md).

## Design, identidade e pixel art

| Fonte | Aplicação | Limite |
|---|---|---|
| [Yacht Club Games — Creating a Shovel Knight Character Sprite](https://old.yachtclubgames.com/2020/03/creating-a-shovel-knight-character-sprite/) | Função/tema antes de ornamento; personalidade na pose parada; escala/cor no elenco | Restrições NES não são regras de Empire |
| [Valve — Character Art Guide](https://help.steampowered.com/en/faqs/view/0688-7692-4D5A-1935) | Silhueta, orientação, contraste e áreas tranquilas | Guia 3D visto de cima; adaptar princípios. Indexação oficial consultada; abertura direta incompleta |
| [Aardman — Legends Family Adventure](https://www.aardman.com/latest-news/2020/november/behind-the-craft-legends-family-adventure/) | Afinidade com formas/cores diferentes e atuação sem boca | Não copiar acabamento de massinha |
| [Aardman — Morph, Thingy-Ma-Bobstacle Course](https://www.aardman.com/latest-news/2023/august/behind-the-craft-morph-thingy-ma-bobstacle-course/) | Gesto, função e personalidade concordam | Referência de atuação, não de grade |
| [Aardman — Warm Follows Function](https://www.aardman.com/latest-news/2020/october/warm-follows-function/) | Forma e imperfeição a serviço da presença humana | Não autoriza ruído aleatório |
| [SLYNYRD — Back to Basics](https://www.slynyrd.com/blog/2018/5/16/pixelblog-5-back-to-basics) | Controle intencional de pixels e massas | Baixa resolução por si só não basta |
| [SLYNYRD — Developing Style](https://www.slynyrd.com/blog/2018/7/14/pixelblog-7-developing-style) | Consistência de clusters, perspectiva e resolução | Elenco do autor continua sendo referência local |
| [Saint11 — Cluster Sketching and Painting](https://saint11.art/pixel_art_articles/article2/) | Massas grandes, depois bordas e detalhes | Pixel isolado com função não é erro automático |
| [Saint11 — Using 3D Models as Pixel Art Reference](https://saint11.art/blog/3d-ref/) | Redução seguida de redesenho | Adaptação automática não é acabamento nativo concluído |

## Movimento e atuação

| Fonte | Aplicação | Limite |
|---|---|---|
| [SLYNYRD — Intro to Animation](https://www.slynyrd.com/blog/2018/8/19/pixelblog-8-intro-to-animation) | Poses, contato/passagem, ritmo e pixel que cintila | Mais quadros não garantem movimento melhor |
| [SLYNYRD — Top Down Character Attack](https://www.slynyrd.com/blog/2025/5/23/pixelblog-56-top-down-character-attack-animation) | Antecipação, contato e recuperação com tempos próprios | Adaptar princípios, não projeção superior |
| [SLYNYRD — Top Down Character Animation Part 3](https://www.slynyrd.com/blog/2025/10/2/pixelblog-58-top-down-character-animation-part-3) | Capa/cabelo secundários e detalhe em movimento | Não impõe oito direções a todo corpo |
| [SLYNYRD — Side View Run ’N Gun](https://www.slynyrd.com/blog/2026/1/26/side-view-run-n-gun) | Dummy anatômico e contato/carga/passagem/subida | Ritmo de corrida não substitui metrônomo local |
| [Saint11 — A Basic Aseprite Animation](https://saint11.art/pixel_art_articles/article3/) | Pose-to-pose, desenho sequencial, timing e volume | Método não aprova sprites gerados |
| [Royal Ballet School — Transference of Weight](https://ondemand.royalballetschool.org.uk/product/ballet-class-transference-of-weight/) | Corpo sobre a perna de apoio e transferência de peso | Descrição pública consultada; aula paga não assistida |
| [Royal Ballet School — Port de Bras](https://ondemand.royalballetschool.org.uk/product/focus-class-port-de-bras/) | Coordenação de braços, cabeça, postura e respiração | Adaptação a dança cortesã/popular estilizada |

## Flores

| Fonte | Aplicação | Limite |
|---|---|---|
| [Harvard — How a Lily Blooms](https://seas.harvard.edu/news/how-lily-blooms), [Liang e Mahadevan, PNAS 2011](https://softmath.seas.harvard.edu/wp-content/uploads/2019/10/2011-03.pdf) | Crescimento diferencial/curvatura mudam pétalas; abrir não é ampliar uniformemente | Mecanismo do lírio, não de toda espécie ou da velocidade mágica |
| [Van Doorn e Van Meeteren — Flower Opening and Closure](https://pubmed.ncbi.nlm.nih.gov/12869518/) | Diversidade de mecanismos e ritmos | Resumo consultado, não texto integral |
| [Integration of Hormonal and Nutritional Cues Orchestrates Progressive Corolla Opening](https://pmc.ncbi.nlm.nih.gov/articles/PMC4902604/) | Abertura progressiva como processo regulado | Não generalizar uma espécie a todas |
| [NYBG — Corpse Flower Bloom](https://www.nybg.org/planttalk/watch-the-2019-corpse-flower-bloom-in-an-instant/) | Transformação de forma ao longo do tempo | Espécie/escala diferentes; leitura de página não equivale a assistir toda mídia |

Raízes fixas, agenda embaralhada e durações do jardim são soluções para o pedido artístico, não conclusões botânicas dessas fontes.

## Ferramentas e exportação

| Documentação oficial | Uso e limite |
|---|---|
| Aseprite: [Onion skinning](https://www.aseprite.org/docs/onion-skinning/), [Animation](https://www.aseprite.org/docs/animation/), [Tags](https://www.aseprite.org/docs/tags/) | Vizinhos, origem fixa, durações e tags; conferir binário não prova abertura no aplicativo |
| Godot: [2D sprite animation](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html), [SpriteFrames](https://docs.godotengine.org/en/stable/classes/class_spriteframes.html), [CanvasItem](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html) | Atlas/imagens, duração relativa, Nearest e camadas; testar na versão fixada do projeto e ligar à simulação |
| PixelLab: [Animate with Text New](https://www.pixellab.ai/docs/tools/animate-with-text-new) | Na consulta, contagens pares de 4–16 e primeira imagem preservada; reconfirmar antes de nova produção |
| PixelLab: [Animate with Skeleton](https://www.pixellab.ai/docs/tools/animate-with-skeleton), [Edit Animation Pro](https://www.pixellab.ai/docs/tools/edit-animation-pro) | Articulações, congelamento de regiões/quadros e edição conjunta como possibilidades documentadas |
| PixelLab: [Interpolation](https://www.pixellab.ai/docs/tools/interpolation), [Animate with Text Pro](https://www.pixellab.ai/docs/tools/animate-with-text-pro) | Distinguir ferramentas antigas/novas; limite 64×64 do interpolador antigo não é universal |

PixelLab foi pesquisado, não executado nas V13/V15. As folhas vieram da geração integrada, seguidas de extração, alinhamento e adaptação. Não atribuir ferramenta ou mecanismo interno não observado.

Forma comunica papel; apoio explica movimento; tempo organiza intenção; pixel exige controle. Manto, cores, dança e jardim são interpretações para Empire. Os [guias](README.md) tornam esse aprendizado aplicável sem apresentar propostas como fatos ou decisões do autor.
