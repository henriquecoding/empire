# A fidelidade dos personagens na Forja — 27/10/2026 (FORJA-06)

> Pedido do dono (27/10/2026), com o pacote `Solucao-Forja-Fidelidade-2026-10-27`: *«Implemente isso, e também
> pesquise profundamente na web mais coisas que possam complementar isso»*.

A solução recebida ([SOLUCAO.md](SOLUCAO.md), cópia exata: sha256 `b9d9303c…`, o mesmo do manifesto do pacote; o zip
tinha `e508982f…`) diz em uma frase o que mudou: **o desenho recupera-se antes de se proteger**. Proteger o último
resultado rejeitado só congelava a descaracterização. A Forja já tinha o mecanismo de composição local; faltava saber
*o que* proteger (a autoridade de cada referência), conferir o que chega nos dois caminhos, prender a edição ao mestre,
não deixar a maioria decidir a cor de uma corda, não confundir preservação técnica com material resolvido e não chamar
aprovação a uma evidência de ficheiro.

As fixtures em [fixtures/](fixtures/) são os sprites **rejeitados** pelo dono, só para regressão
([STATE.json](fixtures/STATE.json), com os hashes). As cinco passam no lint raster e continuam rejeitadas: é a melhor
prova de que um contrato válido não é aprovação. Os protótipos do pacote (`proof_solution.py`, `stroke_solution.py`)
não entraram: o que eles demonstravam está agora na Forja, e a [prova](prova_fidelidade.py) usa o código integrado.

## O que entrou (as seis etapas do §7)

| § | Etapa | O que entrou | Critério verificável | Teste |
| --- | --- | --- | --- | --- |
| 7.1 | Autoridade das referências | `refs.py`: o registo `forja.refs/1` (conceito, adaptação em revisão, aprovado, rejeitado), pelo hash dos pixels; `approved` e `rejected` dizem quem decidiu e quando, e a Forja nunca escreve `approved` (`forja refs`). O prompt nomeia o estado: só um mestre registado é «the APPROVED design»; a adaptação em revisão é «IN REVIEW and NOT approved»; o conceito é «the authority CONCEPT ART»; sem registo, «approval is NOT recorded». A rejeitada não entra. O plano diz `authority.stage`: `recovery` ou `from_master` | uma referência em revisão ou rejeitada não é chamada aprovada | `test_fidelidade.AuthorityTest` |
| 7.2 | Pedido contra retorno | `expectation.py`: a mesma conta no `auto` e no `forge`/`sheet` manuais com `--expect`; um tamanho que não é o pedido invalida o contrato e pede outra geração; uma grade não seguida fica na revisão e no prompt corretivo; um pedido nativo só é lido a 1× se o tamanho o confirmar | tamanhos e grades divergentes ficam pendentes nos dois caminhos | `ExpectationTest` |
| 7.3 | Edição local presa ao mestre | `forja inpaint --refs`: uma versão rejeitada ou o conceito são recusados antes do pedido pago; o resultado diz o estado e o hash do mestre e o que falta para entregar. Um retorno noutro tamanho para a tentativa com o job guardado (`stopped: size_mismatch`) e diz para repetir só a zona. `forja verify` repete a prova contra o mestre, só a ler | fora da máscara e no rosto, os bytes do mestre; tamanho errado não redesenha | `LocalEditTest`, `ClosureTest` |
| 7.4 | A corda | `repair.straighten` exige a cor declarada e pinta-a em todo o pixel da linha final (o que já é da família declarada fica: o brilho de uma corda); `repair.fill` pinta um miolo declarado sem redesenhar; `forja line --core/--core-box --color --mode fill`: o resto da região da linha (o contorno) fica protegido. Sem cor declarada (nem `--color`, nem `colors` no seletor) o reparo é `inconclusive` e nada se escreve | a fixture não perde os 30 claros; sem intenção, inconclusivo | `test_corda_cores.StringCoreTest` |
| 7.5 | Material | `materials.material_state`: um pixel preso fora da rampa ou uma fronteira perdida deixa o material `pending`, mesmo com o `ok` técnico; o `forja cores` di-lo | `locked_off_ramp` pendente impede a aprovação material | `MaterialTest` |
| 7.6 | Encerramento | `verdicts.closure`: as quatro condições do §9; um eixo `not_evaluated` nunca fecha; a identidade e a aprovação fecham-se só pelo registo do dono **desta imagem exata** (mudou um pixel, volta a pendente) | `not_evaluated` não vira entrega; evidência de ficheiro não é aprovação | `ClosureTest` |

Complemento da pesquisa: `banding.py`, a definição do *Pixel Fixer* (TU Delft, 2025), no `forja cores` como suspeita
(`BandingTest`). Ver [a pesquisa](#pesquisa-complementar-o-que-a-web-acrescenta).

## A prova

[prova_fidelidade.py](prova_fidelidade.py) refaz os ensaios do §8 com a Forja deste ramo e grava
[prova.json](prova.json) (28 verificações) e [evidencias/](evidencias/); o `make forja` corre-a e chumba se o JSON mudar
sem commit. Sem rede, sem geração paga (as respostas do gerador são simuladas), sem aprovação.

| Ensaio | Resultado |
| --- | --- |
| Composição local no Rei, no Arqueiro e no Escudeiro, com cinco pixels do rosto pintados na resposta | o pixel autorizado entra; rosto e exterior iguais aos do mestre; o eco devolve o RGBA exato |
| Retorno com 16 px a mais | `stopped: size_mismatch`, um pedido, nenhuma imagem, o job guardado |
| Máscara sobre a zona protegida | recusada |
| A versão rejeitada do Rei com `--refs` | recusada antes de qualquer pedido; no plano, um erro; nenhuma das duas é chamada APPROVED |
| Rampa só na lâmina do Rei | 26 mudanças, 826 presos sem mudança; **9 conflitos → material `pending`**; `verify` diz contrato válido e não entregável (`material`, `artistic_approval`, `identity_consistency`) |
| Corda sem cor declarada | `inconclusive`: três cores no miolo (`#000000` do contorno, `#D9B836` das pontas, `#FBECC3`), nada escrito |
| Corda com o miolo x=56 e `#FBECC3` | 30 claros conservados, 10 interrupções preenchidas, o contorno x=57 e o antebraço iguais; cor fora da paleta e miolo sobre a mão recusados |
| `forge` manual de um escudeiro ampliado 8× contra um pedido de 1920×1920 | `size_mismatch`, `ok` falso, escrito no JSON |

### O que a prova mostrou além do pacote

1. **A geometria da corda continua a falhar depois do reparo** (`largura 2 px em 43 linhas`), e com razão: a observação
   da fixture marca o contorno x=57 dentro de `bow_main.string`. O reparo do miolo está certo; a observação é que tem de
   separar miolo e contorno também para a geometria (regiões `string` e `string_outline`) — trabalho de quem observa
   (Q-284).
2. **A prova de cores de 25/10 fica `pending`**: os 52 `#0B0B0B` que ficaram nas zonas presas (rosto, mão) são
   conflitos da região `lines`. O relatório de 25/10 já os escrevia (Q-279); agora o estado di-lo sem ler a prosa.
3. **Banding nas fixtures** (pares de segmentos alinhados, sem contorno): Rei 5, Arqueiro 11, Escudeiro 8; no elenco de
   25/10, Rei 14, Arqueiro 18, Escudeiro 26. Suspeita a ver a 1×, por calibrar (Q-283).
4. **A especificação do PixelLab mudou outra vez** desde 26/10 (sha256 `b6dd212c…`, antes `1c895d3f…`). O
   [contrato.py](../2026-10-26-pixellab-engenharia-reversa/contrato.py) de 26/10, corrido contra a cópia de hoje: só
   mudou a descrição de `POST /generate-font-pro`; os 63 limites que a Forja usa conferem, zero divergências. O hash do
   adaptador fica o lido a 26/10 (nenhum pedido mudou).

## Pesquisa complementar: o que a web acrescenta

Consulta a 27/10/2026, fontes primárias. Cada linha diz o que a fonte muda ou confirma aqui, e se entrou.

| Fonte | O que diz | O que faz no Empire |
| --- | --- | --- |
| PixelLab OpenAPI v2, `POST /image-to-pixelart` [W01] | `fixer` («Faithful mode. Stays true to the source image instead of re-interpreting it») com `init_image_strength` 0–999, por omissão 0: «100-300 is the useful range. Beyond that the model barely transforms the input at all — […] mean per-pixel change falls from 50 at strength 100 to 14 at 500, so a high value returns your source image rather than pixel art.» Entrada 16–2048, saída 16–512, saída recomendada a ¼ da entrada | **Qualifica o §6 da solução**: «subir a força» na conversão guiada tem teto; acima de ~300 devolve-se o conceito, não pixel art na grade. Não integrado: é chamada paga e endpoint novo no adaptador (Q-285) |
| PixelLab OpenAPI v2, `POST /unzoom` [W01] | mínimo 256×256; «The result is opaque. […] any transparency in the input is composited onto WHITE first»; `quantize` 0 deteta a paleta, **-1 mantém todas as cores**, 2–256 fixa | Confirma o §1 (recuperar a escala com a redução de cores desligada = `quantize: -1`) e acrescenta um risco: o alfa perde-se; o `forja snap` mantém-no |
| PixelLab OpenAPI v2, `POST /correct-pixelart` e `/reduce-colors` [W01] | `correct-pixelart`: não muda o tamanho, preserva o alfa, `strength` 0–1 («start at 0.1»; alto «can change details»), quadros corrigidos juntos. `reduce-colors`: vários quadros numa paleta partilhada, `palette_image` para a paleta do jogo | Uma limpeza do fornecedor é um acabamento global: depois dela, `forja verify` contra o mestre. A paleta partilhada entre quadros já é a da Forja (a mestra fixa) |
| PixelLab OpenAPI v2, `POST /inpaint-v3` [W01] | máscara «White = generate, Black = preserve», 32–512, `crop_to_mask` por omissão verdadeiro | Igual à convenção `pixellab` de `masks.py`; mesmo com o recorte, recompõe-se e confere-se |
| OpenAI, guia de geração de imagens [W02] | «Masking with GPT Image is entirely prompt-based»; «The model uses the mask as guidance, but may not follow its exact shape with complete precision»; a máscara tem de ter canal alfa | Confirma S06 e a regra do §3: a máscara orienta, a composição garante |
| OpenAI, guia de prompting de imagens [W03] | «If a region must remain pixel-identical, composite the approved edit into the original image»; «Refine one thing at a time and inspect the result»; «Repeated edits can still change details you intended to preserve. Restate those constraints and inspect each result» | Uma mudança por pedido, e `verify` a cada passo: entrou como a ordem de `inpaint` → `verify` |
| Bites, Eisemann, Kellnhofer e Molenaar, *Pixel Fixer* (TU Delft, 2025) [W04] | banding: «two different colored segments are 2+ pixels long, adjacent along the longer edge, and have aligned endpoints»; correção semiautomática com escolha do autor; *pillow shading* como caso extremo | **Entrou** como diagnóstico (`banding.py`), sem correção: o FORJA.md dizia que o diagnóstico não via banding |
| Kopf, Shamir e Peers, *Content-Adaptive Image Downscaling* (SIGGRAPH Asia 2013) [W05]; Öztireli e Gross, *Perceptually Based Downscaling of Images* (SIGGRAPH 2015) [W06] | núcleos adaptados ao conteúdo mantêm linhas finas ligadas; a redução perceptual guarda o que importa ao olho | Reforçam o §1: uma redução uniforme é só a primeira aproximação de um conceito denso. Não adotados (algoritmos novos; a Forja recupera grade de imagens que já são pixel art) |
| Wu et al., *Make Your Own Sprites: Aliasing-Aware and Cell-Controllable Pixelization* (ACM TOG 41(6), 2022) [W07] | a célula controlada por uma pixel art de referência, em etapas separadas de célula e de aliasing; código e dados públicos | Um caminho para a «conversão guiada» com a célula do mestre aceite. Não adotado: modelo treinado, dependência e licença por auditar |
| Kuo, Yang e Chu, *Feature-Aware Pixel Art Animation* (CGF 35(7), 2016) [W08] | otimiza as linhas de traço de cada quadro com métricas espaciais e temporais | Apoia o §9: comparar as marcas do rosto em coordenadas locais da cabeça, não na mesma coordenada do quadro |
| Inglis, Vogel e Kaplan, *Superpixelator* (NPAR 2013) [W09] | rasterizar linha em estilo pixel art mantendo simetria e ângulos; artistas julgaram-no igual ou melhor que à mão | Regras para uma linha de 1 px que não é reta (o braço do arco): o `repair.ideal` só faz retas |
| Aseprite, *Slices* [W10] | uma slice tem nome, cor, caixa por quadro, centro 9-slice, pivô e dados do utilizador; o JSON exporta-as em `meta.slices` | Próximo passo possível: escrever a máscara e as zonas protegidas como slices no `.aseprite`, para o autor as ver no editor (não feito) |

O que a pesquisa **não** achou: nenhuma ferramenta que prove a identidade de um personagem entre duas imagens de pixel
art. A identidade continua a olho, pelo dono, e o encerramento só a aceita do registo dele.

## Limites

Sem escrita em `art/`, `audio/`, `src/`, `scenes/` ou `data/`; sem dependências novas; sem chamada paga; sem aprovação
artística. **A recuperação dos rostos do Rei, do Arqueiro e do Escudeiro (§2) é desenho, e não foi feita**: a Forja
agora impede que se proteja o rejeitado e diz o que falta, mas o mestre fiel ao conceito continua por desenhar. Onde
fica o registo de cada personagem, e quem o mantém, é a Q-282.

## Repetir

```bash
python3 docs/art/research/2026-10-27-forja-fidelidade/prova_fidelidade.py
python3 -m unittest tools.forja.tests.test_fidelidade tools.forja.tests.test_corda_cores
make forja
```

## Fontes (consulta a 27/10/2026)

- **W01** · PixelLab — OpenAPI v2 (`/image-to-pixelart`, `/unzoom`, `/correct-pixelart`, `/reduce-colors`, `/inpaint-v3`), sha256 `b6dd212ca4e7f60c9eb93e776303a92f6e0bb4f794cf3a2bf49099e9a00e8834`: [api.pixellab.ai/v2/openapi.json](https://api.pixellab.ai/v2/openapi.json) · [docs](https://www.pixellab.ai/docs/tools/image-to-pixel-art)
- **W02** · OpenAI — Image generation: [developers.openai.com/api/docs/guides/image-generation](https://developers.openai.com/api/docs/guides/image-generation)
- **W03** · OpenAI — Image prompting: [developers.openai.com/api/docs/guides/image-prompting](https://developers.openai.com/api/docs/guides/image-prompting)
- **W04** · R. Bites, E. Eisemann, P. Kellnhofer, M. Molenaar — *Pixel Fixer: Semi-Automated Techniques for Correcting Pixel Art*, BSc, TU Delft, 2025: [poster](https://cse3000-research-project.github.io/static/38fffaaa7e934fdd5d9b8416b1ee386e/poster.pdf) · [repositório](https://repository.tudelft.nl/record/uuid:b3c91b18-d9e8-48e0-91ce-8afafd2439d8) · [dados](https://data.4tu.nl/datasets/11446578-c1f3-474c-9cc4-6978a79b675b)
- **W05** · J. Kopf, A. Shamir, P. Peers — *Content-Adaptive Image Downscaling*, ACM TOG 32(6), 2013: [johanneskopf.de/publications/downscaling](https://www.johanneskopf.de/publications/downscaling)
- **W06** · A. C. Öztireli, M. Gross — *Perceptually Based Downscaling of Images*, ACM TOG 34(4), 2015: [cl.cam.ac.uk/~aco41/imageDownscaling.htm](https://www.cl.cam.ac.uk/~aco41/imageDownscaling.htm)
- **W07** · Z. Wu et al. — *Make Your Own Sprites: Aliasing-Aware and Cell-Controllable Pixelization*, ACM TOG 41(6), 2022, DOI 10.1145/3550454.3555482: [orca.cardiff.ac.uk/id/eprint/152816](https://orca.cardiff.ac.uk/id/eprint/152816/)
- **W08** · M.-H. Kuo, Y.-L. Yang, H.-K. Chu — *Feature-Aware Pixel Art Animation*, CGF 35(7), 2016: [diglib.eg.org/handle/10.1111/cgf13038](https://diglib.eg.org/handle/10.1111/cgf13038)
- **W09** · T. C. Inglis, D. Vogel, C. S. Kaplan — *Rasterizing and antialiasing vector line art in the pixel art style*, NPAR 2013: [diglib.eg.org/handle/10.2312/14944](https://diglib.eg.org/handle/10.2312/14944)
- **W10** · Aseprite — Slices: [aseprite.org/docs/slices](https://aseprite.org/docs/slices/)
- As fontes S01–S10 da solução recebida estão no [SOLUCAO.md](SOLUCAO.md#10-fontes-primárias-consultadas).
