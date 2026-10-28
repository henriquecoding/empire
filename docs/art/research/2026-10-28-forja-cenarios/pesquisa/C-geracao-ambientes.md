# C — Geração de ambientes side-view com geradores de imagem (PixelLab, gpt-image, Gemini) e o que a Forja deve fazer com eles

Pesquisa de 28/10/2026 para estender a Forja (`tools/forja`, `docs/art/FORJA.md`) de personagens a ambientes:
edifícios, árvores, tiras de terreno, planos de parallax, em vista lateral. Nenhum ficheiro do repositório foi
alterado. As fontes estão em `C-fontes.json` (mesma pasta), com os ids `[Cnn]` usados aqui.

> **Nota de integração (28/10, FORJA-09).** P-1 aplicada: o `contrato.py` correu contra a especificação de hoje
> (só mudou a descrição de `POST /create-tiles-pro`; 63/63 limites conformes) e o adaptador regista `ae1f76eb…`.
> O plano por gerador das cenas (P-2, P-3 em parte) e a régua em imagem (P-4) entraram; P-5 a P-11 ficam no
> FORJA-09. Síntese: [README](../README.md).

Convenções:
- `[Cnn]` — afirmação factual sustentada por essa fonte (lida a 28/10/2026, salvo indicação).
- **(inferência)** — conclusão nossa a partir das fontes; não está escrita em nenhuma.
- **Proposta P-n** — sugestão para a Forja; não é decisão (AGENTS.md: proposta não equivale a decisão).
- «Célula» = pixel lógico da arte (um bloco do cluster). «px de jogo» = pixel do ecrã interno 1280×720.
- Contratos internos citados (não são fontes web): Asset Bible (`docs/art/ASSET_BIBLE.md`), `tools/forja/contracts.json`,
  `docs/art/FORJA.md`, adaptadores em `tools/forja/backends/`.

---

## 0. Resumo executivo

1. **A especificação pública do PixelLab mudou depois de a Forja a registar.** O adaptador guarda o SHA-256
   `b6dd212c…`; a `v2/openapi.json` descarregada hoje tem `ae1f76eb…` (501 206 bytes, versão "dev", 102 caminhos,
   113 operações) [C01]. A v1 continua com 8 operações [C02]. O `contrato.py` do dossiê de engenharia reversa deve
   ser corrido antes de qualquer pedido pago (não o corremos para não escrever no repositório).
2. **Há um endpoint feito para o nosso caso: `POST /create-tileset-sidescroller`** — plataformas laterais com fundo
   sempre transparente, tiles 16 ou 32 px, só superfícies horizontais (sem rampas) [C01]. O servidor MCP expõe ainda
   `mode: standard|pro` e encadeamento por `base_tile_id` (só em `pro`), que a especificação REST não lista [C04].
3. **Nenhum endpoint PixelLab gera uma elevação lateral de edifício grande "por contrato".** Os que aceitam `view: side`
   e tamanhos de edifício (≥192×128 células) são `create-image-pixen` (até 768 por lado, área ≤512²), `create-image-pixflux`
   (≤400), `map-objects` (32–400) e `generate-image-v2` (Pro, ≤512² quadrado, 688×384 a 16:9, 792×336 a 21:9) [C01][C07].
   O "building kit" de `create-tiles-pro` é só top-down/isométrico/oblíquo [C01][C08].
4. **O `view` é "weakly guiding" no pixflux** (escrito na própria especificação) [C01]: a câmara lateral não é garantida;
   mede-se.
5. **OpenAI (out./2026): `gpt-image-2.5-sunburst` (omissão) e `gpt-image-2.5-flare`, snapshots `2026-09-08`;** lados
   livres múltiplos de 16, 1:3–3:1, até 3840×2160, 655 360–8 294 400 px, acima de 2560×1440 "experimental"; fundo
   transparente suportado nos 2.5 e "preview" no `gpt-image-2`; até 16 imagens de entrada na edição; a máscara aplica-se
   à primeira imagem e é "prompt-based"; `input_fidelity` só no `gpt-image-1.5`/`1-mini`; `gpt-image-1` desligado a
   23/10/2026 [C17][C18][C19].
6. **Gemini (doc atualizada a 26/10/2026): a tabela de pixels de saída existe agora** (a FORJA.md diz que não a achou).
   O Nano Banana 2.1 e o 2 (`gemini-3.1-flash-image`) têm 4:1 e 8:1 (8:1 = 3072×384 a 1K, 6144×768 a 2K) — o único
   gerador geral que entrega uma tira de parallax numa só imagem [C23]. Não há fundo transparente documentado [C23];
   um praticante pede fundo preto/verde e recorta [C50].
7. **Nenhum gerador promete grade, escala ou emenda.** Praticantes relatam deriva de perspetiva e enquadramento [C49],
   pixels de tamanho irregular [C25], e tiles que não tilam [C47][C48]. A posição exata de elementos é uma limitação
   escrita pela OpenAI [C17].
8. **Recuperação de grade:** unfake.js (Sobel + histograma de distâncias entre picos, alinhamento por deslocamento,
   Wu, cor dominante com margem de 5%) [C25]; proper-pixel-art (Canny + Hough + malha não uniforme) [C28]; Pixel
   Snapper (Rust/WASM, tamanho auto, paleta) [C27]; K-Centroid (k-means por tile) [C31]; PixelLab `/unzoom` (mín.
   256×256, máx. área 2048², saída opaca sobre branco) [C01]. Todas assumem, explícita ou implicitamente, uma grade
   aproximadamente regular; numa cena larga a deriva local de escala é o risco (inferência).
9. **Emendas:** o caminho fiável é construir a emenda, não pedi-la — conjuntos Wang/cantos (PixelLab, Retro Diffusion,
   a própria `forja tileset`) [C01][C33]; difusão com padding circular ou cópia de latentes resolve texturas mas não
   está exposta nas APIs fechadas [C40][C42]; para tiras longas, outpainting com faixa de sobreposição e corte de
   erro mínimo por células (Efros–Freeman, graph cut) evita o desfoque que destrói pixel art [C10][C44][C45].
10. **Identidade entre variantes** (obra, dano, neve, noite): mestre bloqueado + inpainting com máscara binária e
    composição fora da máscara. Só o `inpaint-image-pro-flash` do PixelLab promete preservar o RGBA fora da máscara
    "exactly" [C01]; a máscara da OpenAI não segue a forma com precisão [C17]. Seeds: a Pro Flash diz que a mesma seed
    "does not promise the same image" [C01]; OpenAI e Gemini não documentam seed [C18][C23].
11. **Proposta central (§7):** rota por tipo de ativo — edifício e árvore pelo PixelLab no tamanho nativo de células
    (192×128, 64×96…) com o gpt-image como rota de conceito com silhueta do Rei; tiles de 32 px pelo
    `create-tileset-sidescroller` a 16 px de célula ×2, e o resto do terreno pela composição local da Forja a partir de
    texturas; parallax pelo Gemini 8:1 ou pelo pixen 640×76 com fecho de laço por inpainting de fronteira.

---

## 1. Âmbito e restrições do jogo (contratos internos)

| Ativo | Regra interna | Consequência para o pedido |
| --- | --- | --- |
| Edifício, prop | Cluster 2×2, contorno 2 px na silhueta, largura múltipla de 32, pivot no centro da base; estados `empty · scaffold · building · done · damaged · ruin` como frames do mesmo ficheiro (Asset Bible) | Pedir em células (metade do tamanho de jogo) e ampliar ×2 no fim, como o `--kind building` já faz (FORJA.md) |
| Tile de terreno | Grelha de 32 px, cluster 2 (`contracts.json`: `tile`, canvas 32×32); 4 tilesets por bioma: superfície, corte de solo, cavidade, transições | Tile = 16×16 células |
| Parallax far / mid | Cluster 4, sem contorno, 1 valor (far) / 2 valores (mid) (`contracts.json`) | 1280–2560 px de jogo → 320–640 células; ~300 px → 75 células |
| Escala de personagem | Monarca: altura útil 56–62 px de jogo (Asset Bible) | Silhueta de escala do Rei = 28–31 células de 2 px num pedido de edifício |
| Segmento | "Um assunto por segmento de 640 px" (Asset Bible) | Uma tira de parallax de 640 células cobre 4 segmentos a 4 px/célula (inferência) |

---

## 2. PixelLab (API v1 e v2, MCP, extensões) — Pergunta 1

### 2.1 Estado das especificações (28/10/2026)

- **v2:** `https://api.pixellab.ai/v2/openapi.json`, `info.version: "dev"`, 102 caminhos / 113 operações, SHA-256
  `ae1f76eb70320706c9c6f375e5378177d5ff94323436474245bd81146554b596` [C01]. A descrição recomenda começar por
  `create-image-pixen`, `create-character-v3`, `animate-with-text-v3` e `create-tileset`, e manda passar qualquer
  referência por `POST /unzoom` antes: "Upscaled pixel art confuses every one of these models" [C01].
- **v1:** 8 operações (`generate-image-pixflux`, `generate-image-bitforge`, `animate-with-skeleton`, `animate-with-text`,
  `rotate`, `inpaint`, `estimate-skeleton`, `balance`), SHA-256 `eb7a18b1…` [C02]. Limites iguais aos equivalentes v2
  (pixflux ≤400, bitforge/inpaint/rotate ≤200) [C02]. Não há nada de ambientes na v1 além do pixflux/bitforge.
- **llms.txt** agrupa os endpoints por secção e marca os "legacy"; aponta para os guias e para o servidor MCP [C03].
- **MCP:** `tools/list` em `https://api.pixellab.ai/mcp` respondeu sem token, com 103 ferramentas [C04]. O README do
  repositório `pixellab-mcp` ainda só mostra 4 ferramentas (data de copyright 2025) — está desatualizado face ao
  servidor [C05].
- **Divergência a registar:** o adaptador da Forja tem `SPEC_SHA256 = "b6dd212c…"` (lido a 23/10 e conferido a
  26–27/10); o ficheiro de hoje tem outro hash. Ver **P-1**.

### 2.2 Endpoints relevantes para ambientes — parâmetros e limites

Tudo nesta tabela vem da especificação v2 [C01], salvo onde se indica a página de documentação [C06–C13] ou o MCP [C04].
"Transp." = fundo transparente.

| Endpoint | Tamanhos | Câmara / estilo | Referências e papéis | Transp. | Outros |
| --- | --- | --- | --- | --- | --- |
| `generate-image-v2` (Create S-XL image, Pro) | mín. 16×16; `width` ≤792, `height` ≤688; máx. "depende do aspeto": 512×512, 576×464 (5:4), 600×448 (4:3), 632×424 (3:2), 688×384 (16:9), 792×336 (21:9); "the closest supported aspect ratio is selected automatically" [C01][C07] | sem `view`; sem `direction` ("No facing control") [C04] | `reference_images` ≤4, cada uma com `usage_description` ≤500 ("subject guidance"); `style_image` + `style_options` {color_palette, outline, detail, shading} | `no_background` | `target_palette` (2–256 hex, `max_colors` 2–64, beta); `seed`; candidatos por tamanho: ≤32 → 64, … , 86–170 → 4, >170 → 1 |
| `create-image-pixen` | lados 16–768, área ≤512², múltiplos de 4, quadrado se um lado <32 | `view`: side, low top-down, high top-down; `direction` 8; `outline` 4 valores; `detail` 3 valores | nenhuma | `no_background` até 65 536 px de área (ex.: 256×256, 512×128); acima recusa | `seed`; `enhance_prompt` (+0,05 geração); 1 geração [C04] |
| `generate-with-style-v2` (Pro) | saída quadrada = maior lado das imagens de estilo, 16–512; não quadradas "centered on a square canvas" | — | `style_images` 1–4 (≤512) + `style_description` | `no_background` | `target_palette`; `image_size` "REMOVED" |
| `create-image-pixflux` (+ `-background`, assíncrono) | lados 16–400, área 32²–400² | `view` e `direction`, `isometric`, `outline`, `shading`, `detail` — todos "weakly guiding" | `init_image` + `init_image_strength` 1–999 (300) ; `color_image` (paleta forçada) | `no_background` ("blank background over 200x200 area") | `text_guidance_scale` 1–20 (8); `seed` |
| `create-image-bitforge` (Create S-M image) | lados 16–200, área ≤200² | `view`, `direction`, `isometric`, `oblique_projection` | `style_image` + `style_strength` 0–100; `init_image`; `inpainting_image` + `mask_image` (branco pinta); `color_image` | `no_background` | `coverage_percentage`; `skeleton_keypoints` |
| `create-image-pro-flash` | nativos: 16² (exp.), 24², 32², 32×48, 48², 64², 96×64, 96², 128²; personalizado (beta) 16–256 por lado, múltiplos de 4 | — | `style_image` + `style_options` | `no_background` (por omissão `true`) | "Five image generation units provisionally"; `seed`: "the same seed does not promise the same image" |
| `image-to-pixelart` | entrada 16–2048 por lado; saída 16–512 | — | a imagem | — | `init_image_strength` 0–999, útil 100–300; `fixer` (modo fiel) |
| `image-to-pixelart-pro` / `-pro-flash` | entrada >2048 no lado maior é reduzida; saída decidida pelo modelo ("native pixel scale is detected") | — | — | — | `target_palette`; pro-flash = 6 gerações |
| `create-tileset` (top-down) | tiles 16/32 (`standard`), 16/32/64 (`pro`, 64 experimental); 24 px beta só no site [C06] | `view`: só low/high top-down | `lower_/upper_/transition_reference_image`; `lower_/upper_base_tile_id` (encadear) | — | 16 tiles (25 com `transition_size` 1,0 ou >0,5 no standard); `pattern_4x4`; `shape_style`, `roundness`, `raggedness`, `boundary_amplitude`, `step_slope`… |
| `create-tileset-sidescroller` | tiles 16 ou 32 | "Always side perspective (fixed)" | `lower_reference_image`, `transition_reference_image`, `color_image`, `lower_base_tile_id` | sempre transparente | `transition_size` ∈ {0; 0,25; 0,5; 1,0}; "No slopes: Only flat horizontal platform surfaces"; `text_guidance_scale`, `tile_strength`, `tileset_adherence(_freedom)` |
| `create-tiles-pro` | 16–128 (32 recomendado); `tile_height` 16–256; conjuntos ligáveis com limites mais apertados | `tile_type` hex, hex_pointy, isometric, oblique, octagon, square_topdown; `tile_view` top-down / high / low / **side (~50% de profundidade)**; `tile_view_angle` 0–90 | `style_images` (não combina com `tile_feature`) | — | `tile_feature`: roads (18), tileset (16 ou 32), **building** (chão, paredes 1–3 tiles, portas, pilar, escada — só square_topdown/isometric/oblique) |
| `create-isometric-tile` | 16–64 | isométrico | `init_image`, `color_image` | — | `isometric_tile_shape` thin/thick/block |
| `map-objects` | 32–400 por lado | `view`: low/high top-down, **side** | `init_image`; `color_image`; `background_image` + `inpainting` (oval, retângulo ou máscara) para casar com o mapa | transparente até 40 000 px de área; maior → fundo de cor única [C04] | com inpainting máx. 192×192 [C04]; o objeto apaga-se 8 h depois [C01] |
| `create-1-direction-object` | quadrado 16–256 (64 por omissão) | `view`: top-down ou **sidescroller** | `style_images` (≤256 cada; o maior define o tamanho); `item_descriptions` | — | candidatos: ≤42 → 64, ≤85 → 16, ≤170 → 4, senão 1 (estado `review` + `select-frames`); 10–25 gerações |
| `objects/{id}/states` | o do objeto | — | o próprio objeto | — | `edit_description` ≤1000; "A state is the SAME object in another condition (open/closed, lit, broken)" [C04] |
| `inpaint-v3` (Pro) | 32–512 | — | `context_image` e `bounding_box` "deprecated" | `no_background` | máscara branco = gera, preto = preserva; `crop_to_mask`; custo 10 até 256², 15 até 341², 25 acima; acima de 256 px por lado pede Tier 2 [C04] |
| `inpaint` (pixflux) | ≤200 | `view`, `direction`, `isometric`, `oblique_projection` | `init_image`, `color_image` | `no_background` | `text_guidance_scale` 1–10 (3) |
| `inpaint-image-pro-flash` | dimensões nativas iguais (fonte e máscara) | — | `context_image` com `bounding_box` | `no_background` | "Replace only white mask pixels, preserving unmasked RGBA exactly"; máscara vazia recusada |
| `edit-image-pixen` | fonte ≤256 por lado; alvo área 16²–256² (65 536); múltiplos de 4 | — | a imagem | por omissão `true` | "pose, composition and pixel style are preserved"; 1 geração; manda acolchoar com transparência, "never rescale pixel art" |
| `edit-images-v2` (Pro) | 32–512 | — | `edit_with_text` ou `edit_with_reference` | `no_background` | até 16 quadros a 32–64 px, 1 quadro acima de 128 |
| `edit-image` | 16–400 (200 no grátis) | — | `color_image` | `no_background` | `text_guidance_scale` 1–10 |
| `rotate` | 16–200 (lista 16/32/64/128 como suportados) | `from_view`/`to_view`, `from_direction`/`to_direction`, `view_change` ±90, `direction_change` ±180 | `from_image`, `init_image`, `mask_image`, `color_image` | — | útil para props, não para elevações (inferência) |
| `animate-with-text-v3` | ≤256×256; largura × altura × quadros ≤524 288 | — | `first_frame`, `last_frame` | `no_background` | 4–16 quadros (pares); `drift_threshold` anti-cintilação de cor — candidato a bandeiras, fumo, água (inferência) |
| Limpeza: `unzoom`, `correct-pixelart`, `reduce-colors`, `resize` | unzoom: mín. 256², máx. área 2048², resultado opaco sobre branco; correct: área ≤1024², `strength` 0–1 (começar a 0,1); reduce: total ≤512² em todos os quadros, paleta partilhada, dither 2/4/8; resize: 16–200, passos ≤2× | — | — | correct preserva alfa | Úteis como segunda opinião; a Forja já faz o equivalente localmente |

Notas de leitura:
- **Contagens de candidatos divergem entre três fontes**: a especificação dá 33–35 px → 49 e 85 px → 16 [C01]; a página
  "Create S-XL image" dá 33–42 → 64 [C07]; o MCP dá 64 para 16–33 e 49 para 34–35, e diz que um canvas não quadrado
  "is not the longest side applied to those ladders" (48×72 → 16 candidatos a 10 gerações; 72×72 → 9 a 15) [C04].
  A Forja deve ler a contagem e o custo do recibo, nunca deduzi-los (o MCP diz o mesmo: "the submit receipt reports the
  actual cost") [C04].
- **Parâmetros mortos:** no `create-tileset`, `text_guidance_scale`, `outline`, `tile_strength`, `tileset_adherence*` são
  "No effect" [C01]. No `create-tileset-sidescroller` REST os mesmos campos aparecem sem essa nota, mas o MCP marca-os
  "No effect: standard runs on pixen and pro ignores it" [C01][C04]. Tratar como sem efeito (inferência) e não os enviar.
- **Transparência por área**, quatro regras diferentes: pixen ≤65 536 px; pixflux "blank background over 200x200";
  map-objects ≤40 000 px; bitforge sem limite escrito [C01][C04].

### 2.3 Preços e créditos

- O objeto `Usage` de cada resposta traz `type: usd|generations` e o valor cobrado [C01]; `GET /balance` mostra créditos
  em USD e gerações da subscrição [C04].
- Custos publicados por ferramenta (gerações): pixen 1; pixflux não publicado aqui; Pro image/estilo 10, 15 ou 25 pelo
  tamanho (342–512 px → 25) [C07][C13]; `create-1-direction-object` 10–25 [C01]; `inpaint-v3` 10/15/25 pelo canvas
  inteiro, "not the mask" [C04]; `edit-image-pixen` 1 [C01]; `image-to-pixelart-pro-flash` 6 [C01]; Pro Flash imagem
  ~5 (provisório; `GET /pro-flash/cost`) [C01]; tiles Pro 10–25 [C08].
- Tilesets: a página diz top-down standard 1–4 (normalmente 3–4), sidescroller 2–3, Pro 10–25 [C06]; o MCP diz que o
  standard passou a 1 geração "now that it runs on pixen" (o modelo antigo cobrava em média 3,1 e 2,6 "over … prod
  charges") e o `pro` 15 (até 32 px) ou 25 [C04]. Divergência datada: confiar no recibo.
- "Jobs that fail are not charged" [C06]. A ferramenta exige pelo menos Tier 1 [C06]; o Map Workshop pede "Pixel
  Apprentice or higher" [C14]. Preços mensais dos planos não estão em nenhuma página oficial que abrisse
  (`/pricing` dá 404); uma fonte de terceiros dá 10/30/50 USD por mês com 1000/3000/6000 gerações [C16] — não fiável.
- A FAQ permite uso comercial e Steam e pede que não se treinem modelos com as imagens [C15].

### 2.4 MCP, Map Workshop, extensões

- Ferramentas MCP de ambiente [C04]: `create_sidescroller_tileset` (`mode` standard|pro; `base_tile_id` só em pro:
  "Chaining needs mode="pro": standard draws the new top around every edge of a chained platform"),
  `create_topdown_tileset`, `create_tiles_pro`, `create_path_tiles`, `create_building_kit` (telhados "gable"/"round" só no
  layout materials), `create_map_object`, `create_1_direction_object`, `create_object_state`, `inpaint_image` ("The area
  outside the mask is frozen"), `create_map` / `edit_map` / `view_map` / `place_map_object` / `place_map_tiles` (mapas
  top-down por vértices), e `pixelart_workbench` (lint, `score` 0–100, `repair`, `selout`, `split`/`join`/`scale`).
- O MCP tem regras que a REST não diz: o sidescroller standard tem `transition_size` "snapped to the nearest of 0, 0.25
  and 0.5" [C04]; o `create_map` avisa que "Being in the same family makes a terrain AVAILABLE, not blendable: only a
  pair with its own tileset renders a border" [C04].
- O site documenta "Create map (pixflux)" em vista "top-down or sidecroller" com canvas máximo 200² (grátis), 320² (Tier 1),
  400² (Tier 2+) [C09], e um guia de construção de mapa por secções sobrepostas com inpainting: "The model can only see
  what is inside the selection when generating" — deixar pixels de referência em cada seleção [C10]. "Extend map (v2)"
  é experimental, canvas ≤180×180, Tier 2 [C11]. "Create texture" serve para alimentar o Create Tileset; a página não
  menciona tileabilidade nem tamanhos [C12].
- O Create Tileset do site exporta "Wang tileset, dual-grid 15-tileset and 3x3 tileset formats" e, em sidescroller,
  descreve o material interior e o topo ("dirt" com "grass") e uma espessura de plataforma [C06].
- Interfaces: Simple Creator, Character Creator, Map Workshop, Pixelorama, extensão Aseprite, Game Builder, MCP, API
  [C14]. A extensão Aseprite exige Aseprite ≥1.3 e não corre na versão de teste [C54]. Não achámos documentação de
  "tile connections" na extensão (lacuna).

### 2.5 O que o PixelLab não promete (para ambientes)

- Câmara lateral: só "weakly guiding" no pixflux [C01]; os Pro não têm controlo de direção [C04] (inferência: a vista
  lateral fica a cargo do texto e das referências).
- Rampas e encostas em sidescroller: "No slopes" [C01].
- Elevação de edifício como kit: o `building` só existe em projeções top-down/iso/oblíquas [C01][C08].
- Seed reprodutível: não na Pro Flash [C01]; `create_character` "takes NO seed and cannot be made reproducible" [C04].
- Tamanhos grandes: nada acima de 768 px por lado (pixen) nem de 512² de área [C01].

---

## 3. OpenAI gpt-image e Google Gemini — Pergunta 2

### 3.1 OpenAI (guia sem data, referência e página do modelo lidas a 28/10/2026)

| Item | Estado | Fonte |
| --- | --- | --- |
| Modelos | `gpt-image-2.5-sunburst` ("editing precision matters most", omissão nas edições), `gpt-image-2.5-flare` ("fast, high-quality everyday"), snapshots `…-2026-09-08`; `gpt-image-2` (`-2026-04-21`), `gpt-image-1.5`, `gpt-image-1-mini`, `chatgpt-image-latest`. `gpt-image-1` "was shut down on October 23, 2026" | [C17][C18][C19] |
| Tamanhos | `1024x1024`, `1536x1024`, `1024x1536` e livres: múltiplos de 16, aspeto 1:3–3:1, lado ≤3840 (máx. 3840×2160), 655 360–8 294 400 px; ">2560x1440 are experimental" ("results can be more variable") | [C17][C18][C20] |
| Qualidade | low, medium, high; `xhigh` e `max` só nos 2.5; `auto` por omissão | [C17][C18] |
| Transparência | `background: transparent` com `png`/`webp`; suportado nos 2.5; "For gpt-image-2 … this support is in preview"; jpeg não suporta | [C18][C20] |
| Edição | `/v1/images/edits`: "up to 16 images"; `mask` com canal alfa, mesmo tamanho e formato; "entirely prompt-based" — o modelo "may not follow its exact shape with complete precision"; com várias imagens a máscara vale para a primeira | [C17][C18] |
| `input_fidelity` | `high`/`low` no `gpt-image-1.5`, só `low` no `1-mini`, por omissão `low`; "For gpt-image-2, omit this parameter" (sempre alta fidelidade). Para os 2.5 a referência não diz: não enviar (inferência). Relato de 2025: com máscara e fidelidade alta o modelo desvia-se mais dentro da máscara | [C18][C17][C22] |
| Seed | não documentada na referência das imagens | [C18] |
| Custo | 2.5: 8 USD/M tokens de imagem de entrada, 30 USD/M de saída (15 em Batch); `gpt-image-2` 1024² ≈ 0,006 / 0,053 / 0,211 USD (low/medium/high) | [C17][C19] |
| Limites escritos | consistência de personagens/marcas "may occasionally struggle"; "may have difficulty placing elements precisely"; até 2 min por pedido complexo | [C17] |

### 3.2 Gemini (página "Last updated 2026-10-26 UTC")

| Modelo (id) | Aspetos | Tamanhos | Referências | Notas |
| --- | --- | --- | --- | --- |
| Nano Banana 2.1 (`gemini-nano-banana-2.1`) | 1:1, 2:3, 3:2, 3:4, 4:3, 4:5, 5:4, 9:16, 16:9, 21:9, **1:4, 4:1, 1:8, 8:1** | 1K, 2K, 4K | até 10 objetos, 5 personagens (tabela) — 4 personagens na secção Limitations; 14 no total | pensamento `minimal/medium/high` |
| Nano Banana 2 (`gemini-3.1-flash-image`) | idem 2.1 | **0.5K**, 1K, 2K, 4K | idem | "previous-generation"; pensamento `minimal/high` |
| Nano Banana 2 Lite (`gemini-3.1-flash-lite-image`) | os 10 padrão | só 1K | até 14 objetos, 4 personagens | "Not optimized for multiple reference inputs" |
| Nano Banana Pro (`gemini-3-pro-image`) | os 10 padrão | 1K, 2K, 4K | até 6 objetos, **3 imagens de estilo**, 5 em alta fidelidade, 14 no total | "precision creative control" |
| Nano Banana (`gemini-2.5-flash-image`) | os 10 padrão | só 1K (1024², 1344×768, 1536×672…) | "works best with up to 3 images" | legado |

Fonte de toda a tabela: [C23]. Pixels por aspeto (extrato relevante para ambientes) [C23]:

| Aspeto | 0.5K (só 3.1 Flash) | 1K | 2K | 4K |
| --- | --- | --- | --- | --- |
| 1:1 | 512×512 | 1024×1024 | 2048×2048 | 4096×4096 |
| 3:2 | 632×424 | 1264×848 | 2528×1696 | 5056×3392 |
| 16:9 | 688×384 | 1376×768 | 2752×1536 | 5504×3072 |
| 21:9 | 792×168 (sic) | 1584×672 | 3168×1344 | 6336×2688 |
| 4:1 | 1024×256 | 2048×512 | 4096×1024 | 8192×2048 |
| 8:1 | 1536×192 | 3072×384 | 6144×768 | 12288×1536 |

- O valor 21:9 a 0.5K "792x168" não é 21:9 (seria ~792×336): erro provável da página (inferência). Os tokens de saída são
  747 (0.5K), 1120 (1K), 1680 (2K), 2520 (4K) no 2.1/3.1 Flash [C23].
- Os 3.x "always think for complex prompts", até duas "thought images" não cobradas antes da final [C23] — a Forja já as
  descarta (FORJA.md, B-série).
- Sem fundo transparente na documentação [C23]; SynthID em todas as imagens [C23]. Sem seed documentada [C23].
- A Google recomenda edição em várias voltas, dizer o que fica igual e "Describe what you want, not what you don't want
  (e.g. 'empty street' instead of 'no cars')"; câmara por termos fotográficos; fórmula "[Reference images] +
  [Relationship instruction] + [New scenario]" [C24][C23].

### 3.3 Práticas de pedido para ativos side-view — o que a evidência sustenta

| Prática | Evidência | Grau |
| --- | --- | --- |
| Ordem fixa: cena → assunto → detalhes → restrições; segmentos rotulados | guia da OpenAI [C20][C21] | documentado |
| Nomear cada imagem anexada por índice e papel ("Image 1: …") | OpenAI [C20]; fórmula de relação da Google [C24]; `usage_description` no PixelLab [C01] | documentado |
| "If layout matters, call out placement" (linha do solo, margens, onde fica a silhueta do Rei) | OpenAI [C20] | documentado; a posição exata não é garantida [C17] |
| Moldura positiva: descrever o fundo liso que se quer em vez de "no background" | Google [C24] | documentado |
| Fundo de cor-chave liso quando não há alfa | praticante com Gemini pediu preto/verde e recortou [C50]; comentário de Reddit: modelos gerais "can't output transparency" (comentário promocional) [C55] | relato |
| Transparência nativa no gpt-image 2.5 | referência [C18] | documentado; a Forja binariza o alfa de qualquer forma |
| Termos de câmara "low angle", "wide-angle" | Google [C24] | **evitar em elevações**: introduzem perspetiva (inferência). Usar "orthographic side elevation", "camera perpendicular to the facade", "no vanishing points" |
| Grade escrita no prompt | a Forja já mede que "Pedir a grade por palavras não a garante" (FORJA.md); pixels irregulares relatados em geradores gerais [C25] | relato + interno |
| Cena única primeiro, depois planos far/mid/near com o mesmo horizonte, luz e estilo | tutorial de parallax com IA [C51]; guia de gerador de parallax: camadas têm de tilar na horizontal, tiras 4:1 no plano médio, primeiro plano transparente [C52] | relato (lido só por resumo de pesquisa) |
| Gerar o aspeto/resolução do jogo, não um papel de parede | guia "honest" [C48] | relato de fornecedor |
| Reaproveitar a mesma imagem âncora em todas as chamadas | MCP PixelLab: "pass the same anchor sprite as style_image on every call … without it each call picks its own look" [C04]; guia [C48] | documentado |
| Iluminação plana vs luz cozida | nenhuma fonte trata isto para elevações; a Asset Bible quer luz quente pontual nas oficinas como dado (`warm_light`) | **lacuna**: proposta em §7.4 |

### 3.4 O que falhou a quem tentou (relatos)

| Fonte | Data | O que falhou | Tipo |
| --- | --- | --- | --- |
| r/aigamedev (espelho) [C49] | ~24/08/2025 | Gemini, Grok e ChatGPT "arbitrarily change the perspective of the sprite or the framing" e trocam detalhes | comunidade |
| jenissimo, "How to Tame Your AI Pixel Art" [C25] | 30/07/2025 | "the pixel grid is all over the place"; sem arestas duras nem paleta fixa; paleta enorme; antialias e salpicos | praticante / autor de ferramenta |
| SpriteForge [C47] | 13/08/2026 | emendas visíveis; o modelo "has no concept of a tile grid"; a redução "destroys edge precision"; tiles que evitam a emenda desvanecendo para uma borda neutra dão repetição de carimbo | fornecedor |
| Summer Engine [C48] | 06/06/2026 | tilesets "the hardest 2D ask for AI"; mesmo os geradores especializados "usually get a manual pass"; fundos e parallax "strong" | fornecedor |
| Kenji, dev.to [C50] | 14/03 (ano não indicado; usa "Nano Banana 2", logo 2026 — inferência) | combos perdem consistência; sem PNG transparente; resolvido com passos menores e fundo liso | praticante |
| Comunidade de PixelLab (espelho) [C56] | 02/2026 | opiniões mistas; o tileset por outpainting é elogiado por um concorrente | comunidade (só resumo) |

Leitura (inferência): para ambientes, os quatro modos de falha que importam são (a) deriva de perspetiva — telhados vistos
de cima, fachadas em três quartos; (b) tamanho de pixel irregular, pior numa tira larga do que num sprite; (c) emendas
— tiles e laços de parallax; (d) luz cozida incoerente entre peças geradas em separado. (a) e (d) resolvem-se só no
pedido e na revisão; (b) e (c) resolvem-se na Forja.

---

## 4. Recuperação da grade e limpeza — Pergunta 3

| Ferramenta | Método (como descrito pela fonte) | Limites declarados | Fonte |
| --- | --- | --- | --- |
| unfake.js (Eugeniy Smirnov) e porta Python/Rust `unfake` | divide em 3×3 e fica com os blocos de maior variância; Sobel X/Y → perfis 1D de linhas/colunas → histograma das distâncias entre picos = escala; testa todos os deslocamentos 0…escala−1; quantização Wu (image-q); por bloco, cor dominante se lidera por >5%, senão média; limpeza morfológica opcional; porta tem modo "runs-based" (GCD de corridas) e `--no-snap` | "Some AI outputs are just too messy — or too painterly"; não substitui o artista | [C25][C26] |
| proper-pixel-art (KennethJAllen) | apara; ampliação 2× vizinho; Canny; fecho morfológico; Hough probabilístico, linhas quase verticais/horizontais agrupadas e encostadas a picos de um perfil de gradiente; largura por espaçamento/picos/autocorrelação validada pela variância dentro da célula; preenche linhas em falta subdividindo; cor dominante ou paleta; vídeo/GIF com grade e paleta únicas | "performs well for images that are already approximately aligned to a grid"; `-c` é o parâmetro mais sensível | [C28] |
| Pixel Snapper (Sprite Fusion, Hugo Duprez) | "Pixel are snapped to a perfect grid"; tamanho de pixel detetado; paleta quantizada (16 por omissão) ou hex dada; preserva dither; CLI e WASM; MIT | `--pixel-size` entre 1 e metade do menor lado; o README não descreve o algoritmo | [C27] |
| K-Centroid (Astropulse) | divide em tiles e escolhe a cor mais proeminente por k-means (2 centroides por omissão) | mais centroides = mais ruído; Lua, lento em reduções grandes (resumo de pesquisa) | [C31][C32] |
| Retro Diffusion (pós-processamento próprio) | "proprietary downscaling method using clustering to pick colors per section, followed by color quantization"; modelos "trained specifically for grid-aligned, limited-palette pixel art" | — | [C36][C35] |
| PixelLab `unzoom` / `correct-pixelart` / `reduce-colors` | grade não uniforme tolerada; quantização auto, −1 ou 2–256; correct não redimensiona; reduce partilha paleta entre quadros | unzoom: mín. 256², máx. área 2048², resultado opaco (alfa composto sobre branco); correct ≤1024²; reduce ≤512² somados | [C01] |
| PixelFixer (pyezo, itch.io) | deteção de tamanho de pixel "evolutionary training on a manually labeled dataset", aceita tamanhos não inteiros; RMBG-2.0 para fundo | em desenvolvimento; alinhamento manual de grade só planeado; Windows | [C30] |
| "Pixel Fixer" (TU Delft, BSc 2025, Rares Bites) | **não é recuperação de grade**: corrige banding e pillow-shading com regras artísticas e anotações; métrica conta pares de segmentos em banda | — | [C29] |
| PixelOver | escala/rotação "pixel-perfect", indexação de paleta e dither, contornos; "Nothing is AI-generated" | não documenta deteção de grade | [C37] |

Limites em cenas grandes vs sprites (inferência fundamentada):
- Todos os métodos acima estimam **uma** escala (ou uma malha) para a imagem inteira; o proper-pixel-art é o único que
  admite malha não uniforme preenchendo linhas em falta [C28]. Numa tira de 6144×768 do Gemini, o gerador pode desenhar
  células de largura diferente nas duas pontas; a estimativa global erra localmente. A Forja deve estimar a grade por
  janelas (ver **P-6**).
- O unfake escolhe os blocos de maior variância para medir [C25]; num parallax far (1 valor, céu liso) quase só a linha
  do horizonte tem arestas — a medição depende dela (inferência).
- O `/unzoom` devolve imagem opaca sobre branco [C01]: um ativo com alfa perde-o e a cor-chave tem de ser reaplicada.
- O `image-to-pixelart-pro` reduz entradas acima de 2048 px no lado maior [C01]: uma tira 8:1 a 2K (6144 px) seria
  reduzida antes de converter (inferência sobre a consequência).
- Nos sprites, a perda mais grave é o traço sub-célula (rostos); nos ambientes é a aresta reta de telhados e tijolo —
  uma linha que oscila ±1 célula ao longo de 192 células lê-se como "torta" (inferência). O lint deve medir retilinearidade
  em edifícios (**P-7**).

---

## 5. Saídas tileáveis e sem emenda com difusão — Pergunta 4

### 5.1 Métodos e o que exigem

| Método | Como funciona | Exige acesso ao modelo? | Fonte |
| --- | --- | --- | --- |
| Padding circular (Conv2d `padding_mode=circular`) | as convoluções veem a borda oposta; tila em x, y ou ambos | sim (pesos locais) | [C43]; nós ComfyUI (resumo) |
| Circular só nos passos finais + "noise rolling" desde o início | evita a perda de FID/CLIP que o circular em todas as camadas causa | sim | [C42] |
| Tiled Diffusion (Madar & Fried, CVPR 2025) | a cada passo copia uma faixa de latente de um lado para acolchoar o outro (janela `w`); restrição de similaridade de largura 5 no latente para muitos-para-muitos; recorta depois de descodificar; artefactos pequenos nas ligações entre eixos X/Y | sim | [C40] |
| MultiDiffusion (ICML 2023) | funde várias trajetórias de difusão sobre recortes sobrepostos numa otimização em que "each crop will follow as closely as possible its denoised version" — panoramas 512×4608 | sim | [C41] |
| Inpainting de fronteira exterior; Wang e "Dual Wang" (Sartor & Peers 2024) | reescreve a geração de tiles como inpainting com condições de fronteira escolhidas; usa modelos de inpainting existentes sem treino; o Dual Wang dá mais continuidade e diversidade | não: só precisa de inpainting com máscara | [C38][C39] |
| Outpainting com faixa sobreposta (Create Map do PixelLab) | cada nova seleção sobrepõe a parte já gerada; "the model can only see what is inside the selection" | não | [C10] |
| Conjuntos Wang/cantos gerados pelo fornecedor | PixelLab: vértices, `pattern_4x4`, "Adjacent cells share vertices, so tiles connect seamlessly by construction" [C01]; Retro Diffusion `rd_tile__tileset` (tile 16–32, transições entre materiais [C34]) e `tile_x`/`tile_y` + ferramenta `seam_tiling` com `seam_width` [C33] | não | [C01][C33][C34] |
| Composição local (Forja) | `forja tileset` compõe 16 tiles por cantos (codificação `NW<<3\|NE<<2\|SW<<1\|SE`) a partir de texturas e `forja seams` confere | não | FORJA.md |

Nas APIs fechadas (OpenAI, Gemini, PixelLab genérico) não há padding circular nem cópia de latentes: só o inpainting
com máscara, o outpainting e a construção explícita servem (inferência a partir das referências [C01][C18][C23]).

### 5.2 Partição em regiões sobrepostas — o caso da tira de 640 células

Para uma largura lógica `L` com segmentos de largura `s` e sobreposição `o`, o número de segmentos é
`n = ceil((L − o) / (s − o))`. Com `L = 640`, `s = 352`, `o = 64`: `n = ceil(576/288) = 2`, e `352 + 352 − 64 = 640`
exato. Procedimento (proposta, ver **P-5**):

1. Segmento A: células 0–351, gerado livre (pixen 352×76, por exemplo: lados múltiplos de 4, área 26 752 — dentro de
   todos os limites do pixen [C01]).
2. Segmento B: canvas de 352 células em que as colunas 0–63 são as colunas 288–351 de A (fixas, máscara preta) e o
   resto é máscara branca → `inpaint-v3` (32–512) ou `inpaint-image-pro-flash` (preserva o RGBA fora da máscara) [C01].
3. **Fecho do laço** (o parallax repete): no mesmo pedido de B, fixar também as últimas 64 colunas como cópia das
   colunas 0–63 de A; o modelo só pinta o miolo entre duas fronteiras conhecidas — é o inpainting de fronteira
   exterior de [C38] aplicado a 1D (inferência). O resultado tem `640 − 64 = 576` colunas únicas e fecha sem emenda.
4. Corte na sobreposição: se A e B forem gerados independentemente com sobreposição, escolher em vez de misturar —
   caminho de custo mínimo pela diferença das células sobrepostas (programação dinâmica de Efros–Freeman [C44], ou graph
   cut de Kwatra et al. [C45]). Em pixel art o caminho percorre **células**, não pixels, e cada célula do resultado vem
   de uma única fonte: a paleta não ganha cores (inferência).
5. Proibido: alfa-blend ou feather na faixa (inventa cores intermédias e desfaz o cluster); Poisson blending, usado por
   ferramentas de parallax com Gemini [C53], também cria cores novas — se usado, requantizar à paleta e reconferir os
   clusters (inferência).

### 5.3 Tiles de terreno de 32 px

- **Superfície (topo de plataforma):** o `create-tileset-sidescroller` faz exatamente o caso lateral, transparente,
  tiles 16/32 [C01]. Pedir `tile_size` 16 e ampliar ×2 dá 32 px com cluster 2 — o contrato do `tile` (inferência sobre
  o encaixe; o pedido a 32 desenharia detalhe de 1 px que o contrato proíbe).
- **Corte de solo, cavidade, transições:** não há endpoint lateral para "terra vista em corte com cavidade". Rota:
  gerar texturas de material periódicas e compor com `forja tileset` (cantos) — a emenda é construída, não pedida.
  Tornar uma textura periódica: deslocar meio período em x e y e repintar a cruz central por inpainting com máscara
  (técnica clássica; equivalente 2D do passo 3 acima — inferência), depois `forja seams`.
- O top-down `create-tileset` não serve: `view` só aceita low/high top-down [C01]. O `create-tiles-pro` com
  `tile_view: side` dá tiles "com 50% de profundidade" — um bloco visto de lado com face superior, não um corte
  ortográfico (inferência a partir da descrição [C01]).

---

## 6. Identidade entre variantes (obra, dano, neve, noite) — Pergunta 5

| Mecanismo | O que a fonte promete | O que não promete | Fonte |
| --- | --- | --- | --- |
| Mestre bloqueado + inpainting com máscara binária | Pro Flash: "Replace only white mask pixels, preserving unmasked RGBA exactly"; MCP `inpaint_image`: "The area outside the mask is frozen, so the rest of the sprite cannot drift" | coerência de estilo dentro da máscara | [C01][C04] |
| Máscara OpenAI | edição local | "may not follow its exact shape with complete precision"; só sobre a primeira imagem | [C17] |
| Estados de objeto PixelLab | "A state is the SAME object in another condition (open/closed, lit, broken)"; agrupados por `group_id`; paleta aplicada também à fonte antes da edição | que a silhueta não mude | [C04][C01] |
| `edit-image-pixen` / `edit-images-v2` | "pose, composition and pixel style are preserved and only what you asked for changes"; até 16 quadros editados juntos | — | [C01] |
| Referências com papel | PixelLab v2: `reference_images` (assunto) ≠ `style_image` (estilo, com interruptores por traço); Gemini: objetos vs personagens vs estilo (Pro); OpenAI: índice + descrição | que o papel seja respeitado; estilo e conteúdo misturam-se nas representações de referência — a InstantStyle mostra que é preciso separá-los por blocos | [C01][C23][C20][C46] |
| Multi-volta (Gemini) | "multi-turn consistency"; dizer o que fica igual | identidade ao píxel; a contagem de imagens pedida nem sempre é respeitada | [C23][C24] |
| Seeds | RD: "Same seed + settings ≈ same image"; PixelLab Pro Flash: "does not promise the same image"; `create_character` sem seed | reprodutibilidade | [C33][C01][C04] |
| Consistência geral | OpenAI escreve que pode "struggle to maintain visual consistency" | — | [C17] |

Leitura para o Empire (inferência + proposta):
- Os estados `empty · scaffold · building · done · damaged · ruin` são frames do mesmo ficheiro (Asset Bible). A única
  forma com garantia escrita de não derivar é: aprovar `done` como mestre (`forja refs`), derivar cada estado por
  máscaras declaradas sobre ele (andaimes, buracos, telhado ruído), compor fora da máscara a partir do mestre e fechar
  com `forja verify`. É o que a Forja já faz para personagens (ADR 0093) — estende-se a edifícios sem mecanismo novo.
- `ruin` e `empty` mudam a silhueta: a máscara cobre a zona que desaparece e o `--method remove` da Forja tem de tirar
  tudo o que lá estava (FORJA.md). Em `scaffold` o `add` é o certo.
- Neve e noite não são estados de construção: neve é uma camada aditiva (máscara = faces superiores, `add`); noite deve
  ser um tratamento de paleta/luz no motor, não uma imagem gerada — uma noite gerada muda cada cor e destrói a
  identidade cromática (inferência). Ver **P-9**.

---

## 7. Propostas para a Forja — Pergunta 6

### 7.1 P-1 — Reconferir o contrato do PixelLab antes de qualquer pedido

**Proposta P-1.** Correr `docs/art/research/2026-10-26-pixellab-engenharia-reversa/contrato.py` contra a especificação
de hoje (hash `ae1f76eb…` ≠ `b6dd212c…` do adaptador) e só depois acrescentar endpoints ao adaptador. Novos para
ambientes: `generate-image-v2`, `map-objects`, `create-1-direction-object` + `objects/{id}/states`,
`create-tileset-sidescroller`, `inpaint-v3`, `inpaint-image-pro-flash`, `edit-image-pixen`. Registar por endpoint o
limite de transparência por área (65 536 / 40 000 / "200×200") e marcar como "sem efeito" os campos que o MCP declara
mortos.

### 7.2 Tabela de capacidades por rota (proposta de `capabilities()` para ambientes)

**Proposta P-2.** O planeador (`forja plan`) recusa sem rede o que esta tabela não permite e escreve no plano o que a
rota "não promete".

| Rota / operação | Tamanhos aceites | Aspeto | Referências e papéis | Transparência | Não pode prometer |
| --- | --- | --- | --- | --- | --- |
| `openai.generate` (2.5-sunburst/flare, 2) | WxH múltiplos de 16, 655 360–8 294 400 px, lado ≤3840; >2560×1440 experimental | 1:3–3:1 | nenhuma (só texto) | 2.5: sim; 2: preview | grade, posição exata, vista ortográfica, consistência entre chamadas |
| `openai.edit` | idem | idem | ≤16 imagens, por índice; máscara alfa só na 1.ª | idem | forma exata da máscara → compor fora dela localmente |
| `gemini.generate` (2.1 / 3.1 Flash) | tabela fixa 0.5K–4K | 14 aspetos incl. 4:1 e 8:1 | 10 objetos + 4–5 personagens (14 total) | não documentada → cor-chave | grade, tamanho de célula inteiro (centrar com margens), máscara binária |
| `gemini.generate` (3 Pro) | 1K–4K | 10 aspetos | 6 objetos, 3 de estilo | idem | idem |
| `pixellab.pixen` | 16–768 por lado, área ≤512², múltiplos de 4 | livre dentro da área | nenhuma | ≤65 536 px | vista lateral (texto + `view`), seed estável |
| `pixellab.pixflux` | 16–400, área 32²–400² | livre | `init_image` (1–999), `color_image` | sim; "blank" acima de 200² | `view` "weakly guiding" |
| `pixellab.bitforge` | ≤200 | livre | `style_image`+força; inpainting+máscara; `init_image`; `color_image` | sim | — |
| `pixellab.v2_pro` | ≥16; ≤512² ou ≤688×384 (16:9), ≤792×336 (21:9) | aspeto ajustado ao mais próximo | ≤4 assunto + 1 estilo com interruptores; `target_palette` | sim | direção; número de candidatos e custo (ler recibo) |
| `pixellab.map_object` | 32–400; com inpainting ≤192² | livre | `background_image` (estilo do mapa), `init_image`, `color_image` | ≤40 000 px | persistência (apaga em 8 h) |
| `pixellab.object_1dir` + `states` | quadrado 16–256 | 1:1 | `style_images` ≤256 | sim | aspeto não quadrado (acolchoar) |
| `pixellab.sidescroller_tileset` | tile 16 ou 32 | — | refs de material e topo; `base_tile_id` (pro) | sempre | rampas; corte de solo; cavidade |
| `pixellab.inpaint_v3` | 32–512 | livre | — | opcional | preservação exata fora da máscara (compor localmente) |
| `pixellab.inpaint_pro_flash` | dimensões nativas | nativos | `context_image`+caixa | opcional | tamanhos fora dos nativos/beta |
| `pixellab.edit_pixen` | fonte ≤256/lado; alvo ≤65 536 px; múltiplos de 4 | livre | a imagem | por omissão | mudança de silhueta grande |
| `local.tileset` (Forja) | 32 px | — | texturas aprovadas | — | variedade além das texturas |

### 7.3 Regra de decisão "que rota para que ativo"

**Proposta P-3.** Valores em células (cluster) e entre parêntesis em px de jogo. Custos PixelLab segundo [C04][C07];
"(i)" = inferência a validar no piloto.

**Edifício — até 192×128 células (384×256 px, cluster 2).**
1. *Produção, com mestre de estilo aprovado:* PixelLab `generate-image-v2` a 192×128 (lado maior >170 → 1 candidato),
   `style_image` = cenário aprovado do povo, `target_palette` = paleta do Empire, `no_background`; custo ~10 gerações
   (i: 320×180 custa 10 [C04]). Variação barata: `create-image-pixen` 192×128, `view: side`, `outline: single color
   black outline`, 1 geração, transparente (24 576 px ≤65 536) [C01].
2. *Conceito ou povo novo sem mestre:* `gpt-image-2.5-sunburst` a **1792×1024** = tabuleiro de 224×128 células a 8 px
   por célula (192 de edifício + 32 de margem esquerda para a silhueta do Rei; múltiplos de 16, aspeto 1,75, 1 835 008 px)
   com `guide_layout.png` (grade, linha do solo, silhueta) como Image 1. Sem silhueta: **1536×1024** = 192×128 × 8, um
   tamanho padrão.
3. *Várias referências de objeto (portas, telhados de outro povo):* Gemini 2.1 a 16:9 2K (2752×1536): 224×128 × 12 px =
   2688×1536, margens de 32 px à esquerda e à direita, cor-chave.
4. *Estados:* sempre a partir do mestre aprovado, por `inpaint-image-pro-flash` (se o tamanho for nativo) ou
   `inpaint-v3` + composição local; nunca regenerar o edifício inteiro.
- Não promete: ortografia, retas de telhado, coerência de luz → lint de retilinearidade (**P-7**) e revisão do dono.

**Árvore — p. ex. 64×96 células (128×192 px, cluster 2; tamanho ilustrativo).**
1. PixelLab `generate-image-v2`: a 64×96 dá 4 candidatos (lado maior 86–170); uma árvore até 84 células de altura dá 9
   e até 64 dá 16 [C01] — o melhor custo por escolha para formas orgânicas; ou `create-1-direction-object` com `view: sidescroller`
   (quadrado 96 → 4 candidatos) e depois `states` para outono/neve/abatida (`add moss`, `make it snowy`) [C01][C04].
2. Rota geral: gpt-image 1024×1536 = 64×96 × 16 px (tamanho padrão); Gemini 2:3 1K 848×1264 → 13 px/célula, 832×1248,
   margens de 8 px.
- As 4 variantes mínimas de prop (Asset Bible) saem do mesmo pedido Pro (candidatos) com a mesma `style_image`.

**Tira de terreno — tiles de 32 px (16×16 células).**
1. Topo de plataforma: `create-tileset-sidescroller` `tile_size` 16, `transition_size` 0,25–0,5, `shading: basic`,
   `lower_reference_image`/`color_image` da paleta; ampliar ×2. Variações do mesmo corpo (neve, musgo): `mode: pro` +
   `base_tile_id` (MCP; 15 gerações) [C04].
2. Solo, cavidade, transição: texturas periódicas de 64×64 células (4×4 tiles) — PixelLab pixen 64×64 (1 geração),
   gpt-image 1024×1024 a 16 px/célula, ou Gemini 1:1 1K 1024×1024 a 16 px/célula — tornadas periódicas por
   deslocamento + inpainting da cruz, e composição `forja tileset` + `forja seams`.
- Nunca aceitar "seamless" de um gerador geral sem `forja seams` [C47][C48].

**Plano de parallax — 1280–2560 × ~300 px a cluster 4 (320–640 × 75 células; far 1 valor, mid 2, sem contorno).**
1. 640 células de uma vez: Gemini 2.1 ou 3.1 Flash a **8:1 2K (6144×768)** → 9 px/célula = 5760×675, margens 192 px e
   46/47 px (centrado) [C23]. A 1K (3072×384) seriam 4,8 px/célula — abaixo do limiar de 4–6 px onde a FORJA.md já
   regista trocas de tom.
2. 640 células no PixelLab: `create-image-pixen` **640×76** cabe no contrato (lado ≤768, múltiplos de 4, área 48 640,
   transparência ≤65 536) [C01] — 1 geração; qualidade em 8,4:1 desconhecida (i, sondar). Alternativa: dois segmentos
   352×76 com sobreposição de 64 e fecho de laço por inpainting de fronteira (§5.2).
3. gpt-image: não há 8:1 (máx. 3:1) — usar canvas 3840×1280 (3:1; acima de 2560×1440, logo "experimental" [C18]) com a tira numa faixa e céu de cor-chave, ou
   segmentos; pior rota para parallax (inferência).
4. 320 células (1280 px): pixen 320×76, ou Gemini 4:1 1K (2048×512 → 6 px/célula = 1920×450).
- Como far = 1 valor e mid = 2 (contracts.json), a Forja quantiza a 1–2 cores e a revisão é sobre a silhueta e o laço;
  a rota mais barata ganha (inferência). Conferir o laço com `forja seams` em modo horizontal (**P-5**).

### 7.4 Esqueleto de prompt (inglês) para uma elevação lateral de edifício com a silhueta do Rei

**Proposta P-4.** Ordem segundo [C20][C21]; imagens numeradas [C20]; moldura positiva [C24]; posição dita
explicitamente [C20]. Campos entre chavetas são preenchidos pela Forja. Exemplo para o caso 2 de §7.3 (1792×1024,
224×128 células de 8 px).

```text
[USE] Game asset for a 2D side-scrolling kingdom-builder. One building, drawn as pixel art, for a fixed 1:1 game camera.

[ATTACHED IMAGES]
Image 1 — layout guide: a {224}x{128} grid of square cells, the ground line, and a solid black figure at the left.
  Follow its geometry exactly. Do not copy its colours.
Image 2 — {style reference: an approved Empire building of the {people}}. Copy line weight, palette use and shading
  style only. Do not copy its shape.
Image 3 — palette swatch. Use only these {N} colours.

[CANVAS AND GRID]
The image is {1792}x{1024} pixels and represents exactly {224} columns x {128} rows of square cells.
Every cell is exactly {8}x{8} image pixels and is filled with one flat colour.
All edges, outlines and details snap to cell boundaries. No anti-aliasing, no gradients, no blur, no noise.

[SCALE REFERENCE]
The black figure in the left margin (columns 0-31) is the King, {30} cells tall, standing on the ground line.
Draw the building at the same scale: its door is {18} cells tall, so the King fits through it.
Leave the figure exactly as it is in Image 1; leave columns 0-31 as plain background apart from the figure.

[CAMERA]
Orthographic side elevation, camera perpendicular to the front wall, at the height of the door.
All vertical edges are perfectly vertical and all horizontal edges are perfectly horizontal.
Parallel lines stay parallel; the roof is seen in pure profile; the ground is a single straight line at row {120}.

[SUBJECT]
A {people} {building_id} ({one-line function}). Width {176} cells, height {112} cells above the ground line,
centred in columns {40}-{215}. Walls of {material}, roof of {material} with {ridge/finial: identity of the people},
{windows/doors/sign}. A doorstep {6}-{10} cells deep drawn in front of the facade on the ground line.

[LIGHT AND SHADING]
Even, soft light from the upper left. Two to three tones per material, flat shading in large clusters of at least
2x2 cells. No cast shadow on the ground, no sky light, no time-of-day colour.
{Optional: warm light only inside the {forge} window, as a single flat colour.}

[OUTLINE]
A solid black (#000000) outline exactly 1 cell thick around the outer silhouette. Interior lines are dark tones of the
material, not black.

[BACKGROUND]
Everything outside the building and the King figure is one flat colour, {#FF00FF}, edge to edge.
```

Notas:
- A silhueta do Rei fica numa margem que a Forja recorta pelo `expect.json`: não é preciso pedir ao modelo que a apague
  (inferência; evita um segundo pedido).
- "1 cell thick" = 2 px de jogo depois da ampliação ×2: é o contorno de 2 px da Asset Bible.
- No **PixelLab** o texto é curto e o trabalho vai nos parâmetros: `description` = "side view elevation of a {people}
  {building}, flat front facade, {materials}, {roof}, standing on flat ground", `view: side`, `outline: single color black
  outline`, `shading: basic shading`, `detail: medium detail`, `no_background: true`, tamanho = células; a escala é o
  próprio canvas, e a silhueta do Rei só entraria como `reference_images` com `usage_description` "scale reference: this
  character is 30 px tall" (não verificado que o modelo a respeite — sondar).
- No **Gemini** substituir `[BACKGROUND]` por cor-chave liso (sem transparência documentada [C23]) e manter as margens
  de centragem da tabela fixa.
- Para cada **estado** derivado, o prompt corretivo repete a lista do que fica igual ("Keep everything outside the
  masked area identical") [C20][C24], e a Forja compõe fora da máscara de qualquer modo.

### 7.5 Outras propostas

- **P-5 — Planeador de tiras.** `forja plan --kind parallax_far|parallax_mid --width-cells 640 --loop` calcula segmentos
  (`n = ceil((L−o)/(s−o))`), escreve as máscaras de cada segmento (fronteira fixa, miolo branco), e o `forja seams`
  ganha modo `--wrap x` para conferir o fecho do laço. Corte na sobreposição por caminho de custo mínimo em células,
  nunca mistura [C44][C45].
- **P-6 — Grade por janelas.** Em ativos com mais de ~1000 px de lado, estimar a grade por janelas sobrepostas e
  registar a variação do tamanho de célula ao longo da imagem (achado `grid_drift`), em vez de uma escala global. O
  proper-pixel-art mostra que malhas não uniformes são tratáveis [C28].
- **P-7 — Lint de edifício.** Retilinearidade (desvio máximo de arestas que deviam ser horizontais/verticais),
  convergência de verticais (perspetiva), linha do solo única e reta, largura múltipla de 16 células (32 px), soleira
  12–20 px presente. São as falhas (a) da §3.4 que nenhuma ferramenta da §4 mede.
- **P-8 — Gemini: usar a tabela publicada.** Substituir a estimativa de pixels de saída pela tabela de [C23] (ver o
  provável erro em 21:9 a 0.5K) e recusar 4:1/8:1 nos modelos que não os têm (Pro, Lite, 2.5).
- **P-9 — Variantes como dados.** Noite e luz do dia ficam no motor (paleta/`warm_light`), não em imagens geradas;
  neve como camada aditiva por máscara das faces superiores; os seis estados de obra derivam do mestre `done`
  aprovado, cada um com máscara e método (`add`/`replace`/`remove`) registados.
- **P-10 — Recibo manda.** Para o PixelLab, gravar no job o `usage` e a contagem de candidatos devolvidos; o plano mostra
  um intervalo, nunca um valor, porque três fontes oficiais divergem [C01][C07][C04].
- **P-11 — Retro Diffusion como rota candidata, não integrada.** Tem `rd_pro__platformer` (12–256), `rd_plus__environment`
  (64–384), `rd_tile__*` com `tile_x`/`tile_y`, `check_cost` grátis e preços por imagem (0,06–0,18 USD; tileset 0,10)
  [C33]. Integrar exige ADR (AGENTS.md, regra 8); vale um piloto comparativo para tiles e texturas.

---

## 8. Lacunas, riscos e o que não verificámos

- Não houve nenhuma chamada paga. Tudo o que diz "cabe no contrato" é contrato, não qualidade (o pixen 640×76 em 8,4:1,
  o v2 a 192×128 com `view` implícita, a silhueta do Rei como referência no PixelLab).
- Preços dos planos PixelLab: sem página oficial acessível; o único número é de terceiros [C16].
- Iluminação plana vs cozida em elevações: nenhuma fonte encontrada; a proposta em §7.4 é nossa.
- Threads do r/PixelArt e r/gamedev sobre tilesets gerados: os motores de pesquisa só devolveram espelhos e blogues de
  fornecedores; um espelho (`redlib.hackliberty.org`) não resolve nesta sessão e teria de ser permitido na rede.
- O repositório TU Delft e o 4TU deram 503; a descrição do "Pixel Fixer" vem do resumo do registo [C29].
- O README do MCP oficial está desatualizado face ao servidor [C05][C04]; tratar o `tools/list` como a fonte.
- O guia de imagem da OpenAI e a receita de prompting estão marcados "archived" ou sem data [C20][C21]; a referência da API
  [C18] é a fonte que manda nos limites.
- Kenji [C50] não indica o ano; a dedução 2026 é nossa.

---

## 9. Índice das fontes

Ver `C-fontes.json` (56 entradas: especificações e documentação oficiais PixelLab, OpenAI, Google; artigos
científicos; repositórios de ferramentas; relatos de praticantes e de fornecedores, marcados como tal no campo `kind`).
