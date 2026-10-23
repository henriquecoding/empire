# Fontes, evidências e limites

Data de corte: 23/10/2026. Este inventário identifica fontes primárias; não redistribui seus textos integrais. O relatório concentra as conclusões e a proposta original de implementação.

## Evidências que mudam decisões

| Evidência | Estado | Fonte | Consequência |
|---|---|---|---|
| Existe modelo público histórico associado à marca | Documentado; arquitetura atual desconhecida | P01 | Usar como evidência histórica, verificar condições antes de hospedagem |
| O produto reúne várias famílias de operações | Documentado | P02–P16 | Projetar adaptadores e perfis por tarefa |
| Há diferenças entre versões de máscara e limites | Comparação documental, sem chamada de geração | P09, P12, P15 | Testar o contrato no adaptador |
| Os SDKs públicos consultados usam v1 como base | Inspeção de código nos commits registrados | P10 | Não presumir cobertura de v2 |
| Referência, pose e temporalidade têm mecanismos públicos de pesquisa | Documentado nos trabalhos | P19–P25 | Validar compatibilidade e generalização |
| É possível reconstruir os pesos atuais a partir das páginas | Não demonstrado | Nenhuma | Não fazer essa afirmação |
| A arquitetura proposta já gera com qualidade equivalente | Não medido | Nenhuma | Executar benchmark antes de alegar paridade |

## Fontes centrais citadas no relatório

- **P01**: [https://huggingface.co/pixelparty/pixel-party-xl](https://huggingface.co/pixelparty/pixel-party-xl)
- **P02**: [https://www.pixellab.ai/docs/getting-started](https://www.pixellab.ai/docs/getting-started)
- **P03**: [https://www.pixellab.ai/docs/tools/consistent-style](https://www.pixellab.ai/docs/tools/consistent-style)
- **P04**: [https://www.pixellab.ai/docs/tools/animate-with-skeleton](https://www.pixellab.ai/docs/tools/animate-with-skeleton)
- **P05**: [https://www.pixellab.ai/docs/tools/reduce-colors](https://www.pixellab.ai/docs/tools/reduce-colors)
- **P06**: [https://www.pixellab.ai/docs/tools/resize](https://www.pixellab.ai/docs/tools/resize)
- **P07**: [https://www.pixellab.ai/docs/tools/unzoom-pixelart](https://www.pixellab.ai/docs/tools/unzoom-pixelart)
- **P08**: [https://www.pixellab.ai/pixellab-api](https://www.pixellab.ai/pixellab-api)
- **P09**: [https://api.pixellab.ai/v2/openapi.json](https://api.pixellab.ai/v2/openapi.json); [https://api.pixellab.ai/v2/llms.txt](https://api.pixellab.ai/v2/llms.txt)
- **P10**: [https://github.com/pixellab-code/pixellab-python](https://github.com/pixellab-code/pixellab-python); [https://github.com/pixellab-code/pixellab-js](https://github.com/pixellab-code/pixellab-js)
- **P11**: [https://github.com/pixellab-code/pixellab-mcp](https://github.com/pixellab-code/pixellab-mcp); [https://api.pixellab.ai/mcp/llms.txt](https://api.pixellab.ai/mcp/llms.txt)
- **P12**: [https://www.pixellab.ai/docs/options/inpainting](https://www.pixellab.ai/docs/options/inpainting)
- **P13**: [https://www.pixellab.ai/docs/options/init-image](https://www.pixellab.ai/docs/options/init-image)
- **P14**: [https://www.pixellab.ai/docs/tools/image-to-image-depth](https://www.pixellab.ai/docs/tools/image-to-image-depth)
- **P15**: [https://www.pixellab.ai/docs/tools/inpaint-v3](https://www.pixellab.ai/docs/tools/inpaint-v3)
- **P16**: [https://www.pixellab.ai/docs/tools/animate-with-text-new](https://www.pixellab.ai/docs/tools/animate-with-text-new)
- **P17**: [https://www.pixellab.ai/termsofservice](https://www.pixellab.ai/termsofservice)
- **P18**: [https://kenney.nl/support](https://kenney.nl/support)
- **P19**: [https://arxiv.org/abs/2302.05543](https://arxiv.org/abs/2302.05543); [https://github.com/lllyasviel/ControlNet](https://github.com/lllyasviel/ControlNet)
- **P20**: [https://arxiv.org/abs/2308.06721](https://arxiv.org/abs/2308.06721); [https://github.com/tencent-ailab/IP-Adapter](https://github.com/tencent-ailab/IP-Adapter)
- **P21**: [https://github.com/guoyww/AnimateDiff](https://github.com/guoyww/AnimateDiff)
- **P22**: [https://arxiv.org/html/2410.06236v1](https://arxiv.org/html/2410.06236v1); [https://github.com/AlexandreBinninger/SD-piXL](https://github.com/AlexandreBinninger/SD-piXL)
- **P23**: [https://doi.org/10.1016/j.entcom.2025.101021](https://doi.org/10.1016/j.entcom.2025.101021)
- **P24**: [https://arxiv.org/html/2412.03685v1](https://arxiv.org/html/2412.03685v1); [https://chenganhsieh.github.io/spritesheet-diffusion/](https://chenganhsieh.github.io/spritesheet-diffusion/)
- **P25**: [https://arxiv.org/html/2610.27253v1](https://arxiv.org/html/2610.27253v1)
- **P26**: [https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0)
- **P27**: [https://huggingface.co/docs/diffusers/training/lora](https://huggingface.co/docs/diffusers/training/lora)
- **P28**: [https://huggingface.co/black-forest-labs/FLUX.1-schnell](https://huggingface.co/black-forest-labs/FLUX.1-schnell)
- **P29**: [https://arxiv.org/abs/2006.11239](https://arxiv.org/abs/2006.11239)
- **P30**: [https://www.pixellab.ai/docs/guides/rotating-a-character](https://www.pixellab.ai/docs/guides/rotating-a-character)
- **P31**: [https://www.pixellab.ai/docs/tools/create-8-rotations-pro](https://www.pixellab.ai/docs/tools/create-8-rotations-pro)
- **P32**: [https://www.pixellab.ai/docs/tools/transfer-outfit-pro](https://www.pixellab.ai/docs/tools/transfer-outfit-pro)
- **P33**: [https://www.pixellab.ai/docs/tools/animation-to-animation](https://www.pixellab.ai/docs/tools/animation-to-animation)
- **P34**: [https://bottosson.github.io/posts/oklab/](https://bottosson.github.io/posts/oklab/)
- **P35**: [https://doc.mapeditor.org/en/stable/manual/terrain/](https://doc.mapeditor.org/en/stable/manual/terrain/)
- **P36**: [https://www.pixellab.ai/docs/tools/create-tileset](https://www.pixellab.ai/docs/tools/create-tileset)
- **P37**: [https://www.pixellab.ai/docs/tools/create-texture](https://www.pixellab.ai/docs/tools/create-texture)
- **P38**: [https://www.pixellab.ai/docs/tools/create-tiles-pro](https://www.pixellab.ai/docs/tools/create-tiles-pro)
- **P39**: [https://www.pixellab.ai/docs/tools/create-ui-elements-pro](https://www.pixellab.ai/docs/tools/create-ui-elements-pro)
- **P40**: [https://www.aseprite.org/docs/cli/](https://www.aseprite.org/docs/cli/)
- **P41**: [https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md](https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md)
- **P42**: [https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html)

## Inventário de respostas públicas coletadas

Coleta HTTP e leitura dirigida. Os hashes completos e tamanhos estão em `proveniencia.json`; um HTTP 200 prova acesso à resposta, não que cada afirmação da página foi validada. Páginas antigas permanecem no inventário para distinguir versões.

| URL | HTTP | SHA-256 abreviado |
|---|---|---|
| [https://www.pixellab.ai/docs](https://www.pixellab.ai/docs) | 200 | `c646e61010b642fd` |
| [https://www.pixellab.ai/docs/faq](https://www.pixellab.ai/docs/faq) | 200 | `7588c85960003327` |
| [https://www.pixellab.ai/docs/getting-started](https://www.pixellab.ai/docs/getting-started) | 200 | `065fbb9af5d456d4` |
| [https://www.pixellab.ai/docs/guides/map-tiles](https://www.pixellab.ai/docs/guides/map-tiles) | 200 | `4f81fbc4a4839fe6` |
| [https://www.pixellab.ai/docs/guides/rotating-a-character](https://www.pixellab.ai/docs/guides/rotating-a-character) | 200 | `e0c309fcbc694f60` |
| [https://www.pixellab.ai/docs/installation](https://www.pixellab.ai/docs/installation) | 200 | `fb706271b622b658` |
| [https://www.pixellab.ai/docs/introduction-pixelorama](https://www.pixellab.ai/docs/introduction-pixelorama) | 200 | `9d47eea101683b42` |
| [https://www.pixellab.ai/docs/options/camera](https://www.pixellab.ai/docs/options/camera) | 200 | `e14aae40a29fef05` |
| [https://www.pixellab.ai/docs/options/character](https://www.pixellab.ai/docs/options/character) | 200 | `fe70677e5e4f07b3` |
| [https://www.pixellab.ai/docs/options/color](https://www.pixellab.ai/docs/options/color) | 200 | `07441c0e80e67622` |
| [https://www.pixellab.ai/docs/options/general](https://www.pixellab.ai/docs/options/general) | 200 | `7007d381c42c6514` |
| [https://www.pixellab.ai/docs/options/guidance](https://www.pixellab.ai/docs/options/guidance) | 200 | `e07aca9520b79202` |
| [https://www.pixellab.ai/docs/options/init-image](https://www.pixellab.ai/docs/options/init-image) | 200 | `36047edf467d8c6c` |
| [https://www.pixellab.ai/docs/options/inpainting](https://www.pixellab.ai/docs/options/inpainting) | 200 | `74323cb31f4c81ef` |
| [https://www.pixellab.ai/docs/options/projection](https://www.pixellab.ai/docs/options/projection) | 200 | `799c4d589afeb0af` |
| [https://www.pixellab.ai/docs/tools/animate-with-skeleton](https://www.pixellab.ai/docs/tools/animate-with-skeleton) | 200 | `69e55eb41e2bfb42` |
| [https://www.pixellab.ai/docs/tools/animate-with-text-new](https://www.pixellab.ai/docs/tools/animate-with-text-new) | 200 | `52eaedfd0b5dd608` |
| [https://www.pixellab.ai/docs/tools/animate-with-text-pro](https://www.pixellab.ai/docs/tools/animate-with-text-pro) | 200 | `da8c0a07ada9a863` |
| [https://www.pixellab.ai/docs/tools/animation](https://www.pixellab.ai/docs/tools/animation) | 200 | `454ef2111198377d` |
| [https://www.pixellab.ai/docs/tools/animation-to-animation](https://www.pixellab.ai/docs/tools/animation-to-animation) | 200 | `66034ef7ff2c478c` |
| [https://www.pixellab.ai/docs/tools/consistent-style](https://www.pixellab.ai/docs/tools/consistent-style) | 200 | `e5c8061033194649` |
| [https://www.pixellab.ai/docs/tools/create-8-rotations-pro](https://www.pixellab.ai/docs/tools/create-8-rotations-pro) | 200 | `91088c2ece4e96f2` |
| [https://www.pixellab.ai/docs/tools/create-animations-automatic](https://www.pixellab.ai/docs/tools/create-animations-automatic) | 200 | `69958a84125c667b` |
| [https://www.pixellab.ai/docs/tools/create-image-flux](https://www.pixellab.ai/docs/tools/create-image-flux) | 200 | `3899d8ab99e3094a` |
| [https://www.pixellab.ai/docs/tools/create-instant-character](https://www.pixellab.ai/docs/tools/create-instant-character) | 200 | `4cfd3eebb9490a5e` |
| [https://www.pixellab.ai/docs/tools/create-isometric-tile](https://www.pixellab.ai/docs/tools/create-isometric-tile) | 200 | `91daa14a9acbd4be` |
| [https://www.pixellab.ai/docs/tools/create-map](https://www.pixellab.ai/docs/tools/create-map) | 200 | `7b4bb2d0f1be9a7f` |
| [https://www.pixellab.ai/docs/tools/create-sl-image-pro](https://www.pixellab.ai/docs/tools/create-sl-image-pro) | 200 | `c9d860f09cd72bda` |
| [https://www.pixellab.ai/docs/tools/create-texture](https://www.pixellab.ai/docs/tools/create-texture) | 200 | `b9ef079419efc115` |
| [https://www.pixellab.ai/docs/tools/create-tiles-pro](https://www.pixellab.ai/docs/tools/create-tiles-pro) | 200 | `f91fee1e6b3eccb9` |
| [https://www.pixellab.ai/docs/tools/create-tileset](https://www.pixellab.ai/docs/tools/create-tileset) | 200 | `33050196cebffcf0` |
| [https://www.pixellab.ai/docs/tools/create-ui-elements](https://www.pixellab.ai/docs/tools/create-ui-elements) | 200 | `233ed671b71f27dc` |
| [https://www.pixellab.ai/docs/tools/create-ui-elements-pro](https://www.pixellab.ai/docs/tools/create-ui-elements-pro) | 200 | `d76408c590a8de33` |
| [https://www.pixellab.ai/docs/tools/edit-animation-pro](https://www.pixellab.ai/docs/tools/edit-animation-pro) | 200 | `4071bd178d52e219` |
| [https://www.pixellab.ai/docs/tools/edit-image](https://www.pixellab.ai/docs/tools/edit-image) | 200 | `e469266fd3395ba6` |
| [https://www.pixellab.ai/docs/tools/edit-image-pro](https://www.pixellab.ai/docs/tools/edit-image-pro) | 200 | `4275a7934e9cf56d` |
| [https://www.pixellab.ai/docs/tools/extend-map](https://www.pixellab.ai/docs/tools/extend-map) | 200 | `8ccf58516bc170be` |
| [https://www.pixellab.ai/docs/tools/extend-map-old](https://www.pixellab.ai/docs/tools/extend-map-old) | 200 | `3ebd87c974172f78` |
| [https://www.pixellab.ai/docs/tools/extend-map-v2](https://www.pixellab.ai/docs/tools/extend-map-v2) | 200 | `9b44c1320cc0d909` |
| [https://www.pixellab.ai/docs/tools/image-to-image-depth](https://www.pixellab.ai/docs/tools/image-to-image-depth) | 200 | `1833d4ec84916f8d` |
| [https://www.pixellab.ai/docs/tools/image-to-pixel-art](https://www.pixellab.ai/docs/tools/image-to-pixel-art) | 200 | `7de93d9112cf5ab0` |
| [https://www.pixellab.ai/docs/tools/inpaint](https://www.pixellab.ai/docs/tools/inpaint) | 200 | `cbb8d490632e57ac` |
| [https://www.pixellab.ai/docs/tools/inpaint-pixpatch-v2](https://www.pixellab.ai/docs/tools/inpaint-pixpatch-v2) | 200 | `c022eefe3ac6cf04` |
| [https://www.pixellab.ai/docs/tools/inpaint-v3](https://www.pixellab.ai/docs/tools/inpaint-v3) | 200 | `7d391d885532f5a3` |
| [https://www.pixellab.ai/docs/tools/interpolation](https://www.pixellab.ai/docs/tools/interpolation) | 200 | `78065f86b7d195a5` |
| [https://www.pixellab.ai/docs/tools/multi-image](https://www.pixellab.ai/docs/tools/multi-image) | 200 | `9f8df2a024fee2cf` |
| [https://www.pixellab.ai/docs/tools/pose-to-image](https://www.pixellab.ai/docs/tools/pose-to-image) | 200 | `734736379c12b8e1` |
| [https://www.pixellab.ai/docs/tools/re-pose](https://www.pixellab.ai/docs/tools/re-pose) | 200 | `985e1ec24623f525` |
| [https://www.pixellab.ai/docs/tools/reduce-colors](https://www.pixellab.ai/docs/tools/reduce-colors) | 200 | `8203dad8627975ee` |
| [https://www.pixellab.ai/docs/tools/remove-background](https://www.pixellab.ai/docs/tools/remove-background) | 200 | `bcb0b14d7495b8ae` |
| [https://www.pixellab.ai/docs/tools/reshape](https://www.pixellab.ai/docs/tools/reshape) | 200 | `d1fd145846ea9064` |
| [https://www.pixellab.ai/docs/tools/resize](https://www.pixellab.ai/docs/tools/resize) | 200 | `2f9f736f5a6be17e` |
| [https://www.pixellab.ai/docs/tools/rotate](https://www.pixellab.ai/docs/tools/rotate) | 200 | `1b4d39ae39633ddf` |
| [https://www.pixellab.ai/docs/tools/style](https://www.pixellab.ai/docs/tools/style) | 200 | `677e5755314a6550` |
| [https://www.pixellab.ai/docs/tools/style_old](https://www.pixellab.ai/docs/tools/style_old) | 200 | `d1a9af3d274b2cd5` |
| [https://www.pixellab.ai/docs/tools/text2animation](https://www.pixellab.ai/docs/tools/text2animation) | 200 | `66c02b3c0732a2d0` |
| [https://www.pixellab.ai/docs/tools/transfer-outfit-pro](https://www.pixellab.ai/docs/tools/transfer-outfit-pro) | 200 | `79db1837ea5bc112` |
| [https://www.pixellab.ai/docs/tools/try-on](https://www.pixellab.ai/docs/tools/try-on) | 200 | `ed199e5f95d42e0b` |
| [https://www.pixellab.ai/docs/tools/unzoom-pixelart](https://www.pixellab.ai/docs/tools/unzoom-pixelart) | 200 | `36ad7e2240aa7460` |
| [https://www.pixellab.ai/docs/ways-to-use-pixellab](https://www.pixellab.ai/docs/ways-to-use-pixellab) | 200 | `5c0c0434b2eebafd` |
| [https://api.pixellab.ai/v2/llms.txt](https://api.pixellab.ai/v2/llms.txt) | 200 | `b5078f3604e387b7` |
| [https://api.pixellab.ai/mcp/llms.txt](https://api.pixellab.ai/mcp/llms.txt) | 200 | `a851acb532ff6fcf` |
| [https://www.pixellab.ai/pixellab-api](https://www.pixellab.ai/pixellab-api) | 200 | `dbc4b56c8d7cb472` |
| [https://www.pixellab.ai/mcp](https://www.pixellab.ai/mcp) | 200 | `7d665293fa216d77` |
| [https://www.pixellab.ai/termsofservice](https://www.pixellab.ai/termsofservice) | 200 | `fbebc5ac1474efcb` |
| [https://huggingface.co/pixelparty/pixel-party-xl/raw/main/README.md](https://huggingface.co/pixelparty/pixel-party-xl/raw/main/README.md) | 200 | `724fd31dd62b654a` |

## Outras fontes consideradas

- [Relato público do fundador, fevereiro de 2025](https://medium.com/@oscarleo/this-niche-generative-ai-product-have-110-000-registered-users-6b62d33fa8e4): apenas a introdução acessível; não usado para alegar conhecimento do texto pago.
- [Sprite Sheet Generation Using Diffusion Models, CVMP 2025](https://marcovolino.github.io/docs/papers/2025-wong-cvmp.pdf): trabalho relacionado; seu protocolo não substitui uma avaliação de autoria nativa no Empire.

## Limites de acesso e de validação

- Sem execução autenticada do produto, chamadas pagas, treino ou medição de qualidade visual.
- Tentativas de baixar alguns exemplos visuais oficiais retornaram erro de acesso; não foram tratadas como benchmark.
- Não foi encontrada publicação dos pesos atuais nem receita completa de dados/treino do serviço.
- Hashes de HTML podem mudar por conteúdo dinâmico; guardar data e URL junto deles.
- Licença de código, licença de pesos e permissão sobre dados são verificações separadas.
- A listagem de fontes não promove toda funcionalidade antiga a contrato atual.
