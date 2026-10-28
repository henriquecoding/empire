# Pilotos nativos de 28/10 — Rei 80×80, Escudeiro 64×64 e Arqueiro de tropa 64×64

Estado: **candidatos em revisão**. Nenhum mestre aprovado; identidade e aprovação são de Henrique. Nada em `art/`.
Ticket [FORJA-10](../../../backlog/FORJA-10.md), [ADR 0097](../../../adr/0097-a-forja-observa-a-imagem-exata-e-edita-ao-pixel.md),
perguntas Q-292–Q-294 em [QUESTIONS.md](../../../QUESTIONS.md).

## O que foi feito, o que passou e o que falta

| Eixo | Estado | Evidência |
|---|---|---|
| Classe | pass | Rei `royal_80`, Escudeiro `royal_64`, Arqueiro de tropa `troop_64`; papel e preset sem conflito (contrato de fidelidade) |
| Grade | pass | 80×80, 64×64, 64×64 reais; zero pixels cortados; fonte e método por etapa com hash (`prova.json`) |
| Preservação | pass nos pinos; regiões pendentes | 10 pinos de 1 px verificados no PNG final; as regiões não têm o JSON de perda do forge porque a perda aconteceu na recuperação (medida abaixo) |
| Identidade | **pendente (dono)** | revisão visual do agente por invariante (`revisoes/*-candidato.json`) e folhas lado a lado; o `identity_reviews` é de uma pessoa |
| Arma | pass na geometria | uma corda, 1 px, reta, ligada à madeira nas duas pontas, pega entre elas, mão da frente na pega (`equip/veredito.json`) |
| Cor e pixels | revisto | tons da própria prancha, sem teto (60/49/38 cores); materiais separados; nenhum pixel isolado apagado às cegas |
| Revisão | pass nos reparos | três defeitos da referência corrigidos e registados por hash (`reference_issue_reviews`); aprovação do mestre pendente |
| Integração | **não integrado** | Godot 4.7.2 abre os três PNG com as mesmas medidas e alfa binário (sonda, não o jogo); `.aseprite` relido igual ao PNG pelo leitor do projeto, não aberto no Aseprite |

Falta: a decisão do dono sobre identidade, Q-292 (orçamento), Q-293 (rampas) e Q-294 (corda); a prova real de
uma geração ou conversão paga (sem credencial nesta sessão); animação e integração no jogo.

## O achado que mudou o caminho

A entrega anterior mediu o Rei em 97×96 com confiança 0,429 — mas mediu a **imagem regerada de 1254 px**, não a
prancha. Medido no recorte de autoridade, o `gridcheck` encontra a grade da própria prancha:

| Personagem | Período | Confiança | Recuperado (A) | Na tela | Caixa opaca | Margens e/c/d/b | Pivô | Cores |
|---|---|---|---|---|---|---|---|---|
| Rei | 6,037 px | 0,961 | 81×77 | 80×80 | [0,2,77,79] | 0/2/3/1 | (40,78) | 60 |
| Escudeiro | 6,476 px | 0,943 | 45×48 | 64×64 | [12,15,57,63] | 12/15/7/1 | (32,62) | 49 |
| Arqueiro de tropa | 6,245 px | 0,950 | 53×64 | 64×64 | [10,2,62,63] | 10/2/2/1 | (32,62) | 38 |

A prancha já é pixel art ampliada: recuperar a grade dela não é uma redução nem uma grade escolhida para caber.
O próprio PixelLab documenta o mesmo princípio no `/unzoom` («detecta a grade e reduz de volta para ela; usar antes
de mandar arte ao `image-to-pixelart`»). O Escudeiro cabe como está; o Rei e o arqueiro pedem decisões de desenho.

## Etapas (cada uma com hash em `prova.json`)

1. **Recuperar**: `snap` no recorte, voto dominante, fundo plano da prancha removido.
2. **Limpar** (`patches/<id>/01-limpeza.json`, de `propor_limpeza.py`): fundo preso entre partes (entre as pernas,
   dentro do arco, atrás do escudo) e a sombra do chão; 142/183/280 pixels, conferidos a olho (magenta/ciano).
3. **Tons** (`tools/forja/tones.py`): 2637/1171/1375 cores do JPEG → 60/49/38 tons. Quantizar para a paleta de
   trabalho trocava a túnica vinho do Escudeiro por castanho e manchava pele e escudo; os tons ficam como
   [proposta](paleta-pilotos-proposta.gpl) (Q-293).
4. **Orçamento** (`03-*`): Rei — o pivô fica no centro dos pés e a capa ia 44 px para trás com 40 de tela; o
   contorno de trás entra 4 px (curva comprimida, borda clara e contorno mantidos), margem esquerda 0 só desse lado;
   a alternativa com margem 2 deixava a faixa da capa com 3–4 px (Q-292). Arqueiro — 64 linhas para 61: saem a 3
   (copa do capuz), a 30 (tronco) e a 52 (calças), fora do rosto e das mãos. Escudeiro — o topo do escudo volta a
   ter os 2 pixels de contorno que a recuperação perdeu.
5. **Arco** (`patches/arqueiro_tropa/04-arco.json`, de `propor_arco.py`), autorizado por Henrique: abaixo.
6. **Tela**: `forja forge` a 1× no contrato do papel, com a caixa útil e a paleta proposta; lint sem erros.

## A arma do arqueiro de tropa

Na prancha: a corda sai da ponta de cima mas o pixel de cima toca o contorno e não a madeira; desce e **some atrás
da manga e do tronco**; o membro de baixo acaba na mão de trás; entre as mãos há uma linha cinzenta de 1 px com
contorno dos dois lados, da cor do fundo, que não continua nenhum membro e não tem haste nem ponta — não é flecha.
Henrique: «A corda está atrás do personagem, a arma está mal feita» (registado como `bow_string_behind_body`).

Reparo, só na arma: a lasca sai e a túnica continua até ao contorno da braçadeira; a ponta de cima entra 1 px
(margem da tela); a corda velha sai; a corda nova é **uma linha reta em degraus 2-1, do entalhe de cima (59,28) ao
de baixo (35,45), à frente do corpo** — clara sobre o fundo e a braçadeira, num tom médio sobre o creme, onde a
clara desaparecia; um brilho da manga com o tom da corda, encostado a ela, passou a creme (o `forja equip` mediu
2 px de largura nesse ponto). Rosto, capuz, roupa, mãos e gesto de repouso ficam. Medido pelo `forja equip`:
`string_line`, `bow_nocks` e `contact` em pass. Num fundo claro a parte clara da corda quase some (Q-294).

## Identidade (observação do agente, não aprovação)

As revisões `forja.visual_review/1` de referência e candidato (`revisoes/`) registam, invariante a invariante, o
que se vê; as caixas foram conferidas nas imagens marcadas. Os pixels do rosto **não foram editados** nos três:
são os da grade da prancha. O Rei mantém pálpebra, pupila, sobrancelha e o sorriso torto com os dentes; a capa
ficou 4 px mais estreita atrás. O Escudeiro mantém olho arregalado, boca aberta, elmo e escudo à frente. O arqueiro
mantém capuz, expressão contida e corpo compacto, com 3 linhas a menos. A identidade fica **pendente**: só o dono,
ou uma revisão de pessoa por aspecto, a fecha. Folhas: `candidatos/*_comparacao.png` (conceito, 6× em fundo claro e
escuro, 1×) e `candidatos/*_fidelidade.png` (região a região).

Perda medida na recuperação (`snap.loss`): 72/42/35 células apagadas, quase todas preto dentro de quase-preto
(o L do OKLab é íngreme junto ao preto, Q-290). Com cor distinta e ≥10 % da célula: Rei 15 (joia da coroa,
sombreado da lâmina, uma célula na borda do cabelo), Escudeiro 5 (um brilho numa célula de contorno), Arqueiro 7
(ponta do capuz, creme debaixo da mão de trás). Nenhuma no olho, na pupila ou na boca; ficam como estão.

## Validade técnica

`make forja` corre os pilotos, as revisões e a prova do arco e chumba se um JSON mudar (o PNG comprimido varia
com o zlib, por isso confere-se o hash dos pixels). Determinístico byte a byte entre duas corridas. Os portões, a
suíte da Forja e a do Godot estão no relatório da sessão, com o que passou e o que não passou.

## Pesquisa (28/10), e o que mudou na Forja

- PixelLab, especificação pública v2 (`https://api.pixellab.ai/v2/openapi.json`, sha256 `b6dd212c…8834`,
  reconferida): o `image-to-pixelart` pede a mesma proporção na entrada e na saída e recomenda a saída a 1/4; a
  conversão passou a emoldurar a fonte. A página da ferramenta diz que, fora disso, a imagem é redimensionada em
  segundo plano. `/unzoom` recupera a grade (resultado opaco); `/correct-pixelart` limpa «stray and anti-aliased
  pixels», o que pode apagar pupilas — não entra sem revisão; `/inpaint-v3` (máscara) e `/edit-image-pixen` são as
  rotas pagas para um reparo local. https://www.pixellab.ai/docs/tools/image-to-pixel-art
- Retro Diffusion, pixel-art-fixer `HOW_IT_WORKS`: a ambiguidade de harmónicos (2× contra 1×) é a falha dominante;
  «uma grade fina demais perde pouco, uma grossa demais destrói detalhe» — o mesmo que «não escolher uma grade
  mais grossa para caber». https://github.com/Retro-Diffusion/pixel-art-fixer/blob/main/docs/HOW_IT_WORKS.md
- unfake e Sprite Fusion Pixel Snapper: voto da cor dominante com recurso à média e o aviso de que a saída precisa
  de revisão; nada disso redesenha um rosto. https://dev.to/jenissimo/how-to-tame-your-ai-pixel-art-3pk5
- Rahmanzadehgervi et al., *Vision language models are blind* (arXiv 2407.06581): os modelos de visão falham em
  posição e contacto finos e em primitivas próximas — por isso a revisão visual leva caixa e certeza e a geometria
  mede a corda. Yang et al., *Set-of-Mark* (arXiv 2310.11441): marcas numeradas ancoram o que o modelo aponta — o
  `--marks-out`. Estudos de 2025–2026 sobre ancoragem de objetos pequenos dão caixas grosseiras mesmo com a região
  certa (p. ex. arXiv 2605.20306).
- Saint11, *Cluster sketching and painting*: um pixel isolado nem sempre é ruído (olho, acento) — os pinos e o
  `tones` que guarda o tom pequeno e longe. https://saint11.art/pixel_art_articles/article2/ · Pixel Parmesan,
  *Anti-aliasing fundamentals*: num sprite pequeno o AA pode ler-se como ruído e o sel-out é opção de estilo — a
  corda fica sem AA. https://pixelparmesan.com/anti-aliasing-fundamentals-for-pixel-artists
- World Archery (*Recurve*) e o guia de caça de NSW: a corda prende nas pontas dos membros (string groove/nock da
  ponta), a pega fica entre eles; o «nocking point» é na corda — o `bow_nocks` mede as pontas, não esse ponto.
  https://www.worldarchery.sport/sport/equipment/recurve
- Inpainting por difusão mexe nos pixels fora da máscara (ida e volta pelo VAE); a prática é recompor o original
  fora dela — o `forja patch` confere o exterior byte a byte. https://arxiv.org/html/2506.12530v1
- Fórum do Aseprite sobre reduzir arte: «o programa não sabe que pixels importam; faz-se à mão» — o rosto não é
  reduzido, recupera-se. https://community.aseprite.org/t/resizing-down-pixel-design/13657
- Especificação do `.ase` (slices com pivô): https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md
- Mantidas do relatório de 28/10: Wu et al. 2022 (DOI 10.1145/3550454.3555482), Gerstner et al. 2013 (DOI
  10.1016/j.cag.2012.12.007); nova: Binninger e Sorkine-Hornung, *SD-πXL* (SIGGRAPH Asia 2024, arXiv 2410.06236),
  quantização com paleta fixa por destilação — não implementado.

## Reproduzir

```bash
python3 docs/art/research/2026-10-28-forja-pilotos-nativos/pilotos.py --write   # candidatos, paleta, prova.json
python3 docs/art/research/2026-10-28-forja-pilotos-nativos/revisoes.py --contrato
python3 docs/art/research/2026-10-28-forja-pilotos-nativos/prova_arco.py
python3 -m tools.forja fidelity docs/art/research/2026-10-28-forja-escala-e-referencia/fidelidade.json \
  --character arqueiro_tropa --candidate docs/art/research/2026-10-28-forja-pilotos-nativos/candidatos/arqueiro_tropa.png \
  --visual-review docs/art/research/2026-10-28-forja-pilotos-nativos/revisoes/arqueiro_tropa-candidato.json \
  --palette docs/art/research/2026-10-28-forja-pilotos-nativos/paleta-pilotos-proposta.gpl
```

Os scripts `propor_*.py` mostram como cada patch foi proposto; os patches gravados são a fonte.
