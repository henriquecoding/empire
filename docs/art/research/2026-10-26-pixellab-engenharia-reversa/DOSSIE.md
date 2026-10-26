# PixelLab — dossiê de engenharia reversa (26/10/2026)

O que se sabe do PixelLab a 26/10/2026, com o nível de cada afirmação (ver a
[escada de evidência](METODOLOGIA.md#3-o-método-da-evidência-à-inferência)), o que mudou desde a pesquisa de
[23/10](../2026-10-23-pixellab/README.md), o que se corrigiu na Forja, a conferência do envio de hoje e o
que continua desconhecido. Recolha: 86 respostas públicas por GET, sem chave nem sessão
([proveniencia.json](proveniencia.json)); nenhuma geração, nenhuma chamada paga.

## 1. Em resumo

1. **O contrato mudou em três dias.** A especificação OpenAPI tem outro hash (`1c895d3f…` contra
   `e322e725…` de 23/10) com as mesmas contagens: 102 caminhos, 113 operações, 275 esquemas. O guia MCP
   também mudou (de 139 422 para 145 566 bytes). O `llms.txt` da API v2 está igual, byte a byte.
2. **A Forja divergia do contrato em 10 pontos** (limites por eixo e intervalos numéricos). Todos
   corrigidos e testados; a conformidade passa agora em 63 verificações sem divergências. Um deles
   desfaz uma recomendação do relatório de 24/10 (ver [§7](#forja)).
3. **A forense das imagens públicas achou um defeito destrutivo na Forja**: o estimador de grade errava
   8 de 16 saídas de modelo da documentação (um personagem nativo de 64×64 saía com 12×11 pixels). Com
   as salvaguardas novas erra 0 de 16.
4. **Os termos obrigam à licença Open RAIL-M do Stable Diffusion** — indício de linhagem que a pesquisa de
   23/10 não registou ([H01](#h01)).
5. **As ferramentas "Pro" desenham numa tela de ~1024 px a escala inteira (4×, 3×, 2×) e fatiam o
   resultado** — inferência forte, de três fontes independentes ([H02](#h02)). Os tetos por proporção
   coincidem com metade da tabela 1K de dez proporções da família Gemini 3.x ([H03](#h03)): indício de
   fornecedor, não prova.
6. **O envio de hoje (FORJA-04, PR #123) confere**: pacote 12/12, 200/200 vídeos existentes do canal,
   alegações sobre a API verdadeiras, 239 testes e CI verdes ([§8](#envio)).

## 2. O que o contrato público diz hoje

Medido por `contrato.py` em [contrato-2026-10-26.json](contrato-2026-10-26.json).

| Facto (publicado a 26/10) | Consequência |
| --- | --- |
| Pixflux: cada lado 16–400, área 32×32–400×400; `init_image_strength` 1–999 (300), `text_guidance_scale` 1–20 (8); fundo transparente "em branco acima de 200×200" | A Forja recusa agora lados e valores fora destes intervalos antes da rede |
| Pixen: cada lado 16–768, múltiplo de 4, área até 512×512, quadrado se um lado < 32; transparente até 65 536 px; `enhance_prompt` custa mais 0,05 gerações | O "até 768 px" da introdução é por eixo, não por área |
| Bitforge: cada lado 16–200; `style_strength` 0–100; aceita máscara (branco = gerar), esqueleto e `coverage_percentage` | A Forja não envia os campos que não usa; a máscara fica para quando houver adaptador de inpainting |
| Pro (`generate-image-v2`): 16 a 512 no quadrado, 688×384 a 16:9, largura até 792 e altura até 688; candidatos por tamanho de 64 (≤32 px) a 1 (>170 px); paleta-alvo em beta com modo `smart` | Ver [H02](#h02) e [H03](#h03) |
| Pro Flash: tamanhos "nativos" (16 experimental, 24, 32, 32×48, 48, 64, 96×64, 96, 128) e personalizados em beta até 256; "a mesma seed não promete a mesma imagem"; `operationId` escritos à mão, ao contrário dos outros 105 | Família de código e de modelo diferente ([H05](#h05)) |
| `reduce-colors`: até 512×512 somados entre quadros, paleta partilhada, `num_colors` e `palette_image` exclusivos; dither 2×2/4×4/8×8 com força 0–10 (5) | Confirma o relatório de 25/10 |
| `drift_threshold` (animação v3 e PixMiniMax): compara com o **primeiro** quadro; 0 corrige todos | Confirma o relatório de 25/10: não é o `--deflicker` da Forja |

### Sinais da pilha no próprio contrato

Os esquemas `HTTPValidationError` e `ValidationError`, 105 `operationId` no formato automático do FastAPI
(`<função>_<caminho>_<método>`) e nomes de esquemas desambiguados pelo caminho do módulo
(`app__endpoints__external__v2__create_image_pixen__ImageSize`) dizem que a API é **Python com FastAPI e
Pydantic**, servida por `uvicorn` (cabeçalho `server`), organizada em 25 módulos
`app/endpoints/external/v2/<operação>`. Os nomes das funções guardam história: `/create-image-pixen` é
servido por `generate_image_pixen`, `/rotate` por `generate_rotation`, como no SDK antigo. É uma medição
passiva: nada foi pedido ao servidor além da especificação pública.

## 3. Infraestrutura e organização (só fontes públicas e passivas)

| Observação | Fonte | Nível |
| --- | --- | --- |
| A API (`api.pixellab.ai`) é um CNAME para um balanceador AWS em `eu-west-1` (Irlanda), sem Cloudflare à frente | DNS público | Medição |
| O site (`www`) e o armazenamento (`backblaze.pixellab.ai`) passam pela Cloudflare; o site é Next.js com Chakra UI | DNS, cabeçalhos, HTML | Medição |
| Há `supabase.pixellab.ai` e `*.play.pixellab.ai` nos registos de transparência de certificados; o construtor de jogos publica em `<projeto>.pixellab.run` | crt.sh, `llms.txt` | Medição / facto publicado |
| Pagamentos pela Paddle; email pela Cloudflare | Registos TXT e MX | Medição |
| Empresa sob lei sueca; subscrição mensal porque "pagamos GPUs na nuvem"; os modelos correm na nuvem | Termos 7.1; FAQ em `llms-full.txt` | Facto publicado |
| O site diz que a plataforma usa "os seus próprios modelos, feitos para pixel art"; o catálogo diz "Powered by MiniMax H3" no PixMiniMax | `llms.txt`; página da API | Afirmação do fornecedor |
| O modelo de mapas foi treinado com tiles de 16×16 e a descrição deve falar do centro da seleção | `llms-full.txt` | Facto publicado |
| Personagens v3 usam um corpo-modelo (`mannequin`, `bear`, `cat`, `dog`, `horse`, `lion`); sem referência, o v3 desenha sempre dois braços e duas pernas; o esqueleto v3 tira a profundidade do corpo-modelo | Guia MCP; especificação | Facto publicado |
| Nenhuma patente nem entrevista técnica encontrada; um relato do fundador (2025) está atrás de paywall | Pesquisa web | Lacuna |

## 4. SDKs, modelos públicos e terceiros

- **SDK Python** `pixellab` 1.0.5 (PyPI, 07/05/2025): oito métodos (`generate_image_pixflux`,
  `generate_image_bitforge`, `animate_with_text`, `animate_with_skeleton`, `estimate_skeleton`,
  `inpaint`, `rotate`, `get_balance`) e só a base `https://api.pixellab.ai/v1`, lido por análise estática
  do pacote, sem o executar. Os exemplos Python da especificação v2 (`create_image_pixen`,
  `generate_image_v2`…) não existem nesse pacote. O repositório no GitHub está no mesmo commit de 23/10.
- **SDK JavaScript** `@pixellab-code/pixellab` 1.0.2 (npm); repositório no mesmo commit de 23/10.
- **MCP**: o guia atual usa o servidor remoto (`https://api.pixellab.ai/mcp`) com 117 ferramentas
  descritas (cabeçalhos de ferramenta no guia), incluindo um agente de chat e uma *sandbox* de código para o construtor de jogos; os
  descarregamentos não pedem autenticação ("o UUID é a chave"). O pacote npm `pixellab-mcp` 1.1.0
  (17/06/2025, MIT) é o servidor local antigo.
- **Hugging Face**: a organização `pixelparty` tem um só modelo, Pixel Party XL (08/08/2023): SDXL
  ajustado por completo, licença declarada `creativeml-openrail-m`, recomenda reduzir 8× por vizinho mais
  próximo e uma tela de ~128 px, e pede que não seja alojado.
- **Benchmark independente** (Shilo/pixellab-pip, 13/07/2026): 124 gerações, teto de US$5, revisão cega
  por ordenação de um só revisor, quatro modelos. O Pro ganhou em personagens e itens pequenos e perdeu em
  cenas; devolveu 64 candidatos a 32 px e 1 a 256 px; falhou a transparência duas vezes. Peso
  estatístico baixo, como o próprio autor diz. ([fonte](https://github.com/Shilo/pixellab-pip/blob/main/docs/pixellab-image-model-benchmark-results.md))

<a id="matriz"></a>
## 5. Matriz de hipóteses

Cada linha diz o que a refutaria. "Sonda" remete para o [protocolo](PROTOCOLO-SONDAGEM.md).

| ID | Hipótese | A favor | Contra ou limite | Refutaria | Nível |
| --- | --- | --- | --- | --- | --- |
| <a id="h01"></a>H01 | Pelo menos um modelo servido (ou servido no passado) deriva de um modelo Stable Diffusion sob licença Open RAIL-M | Termos §4 obrigam o utilizador à Open RAIL-M e ligam à LICENSE do CompVis/stable-diffusion; a licença exige que quem serve um derivado imponha as restrições de uso aos seus utilizadores; o modelo público da casa é SDXL com `creativeml-openrail-m` | A cláusula pode ser herança de 2023; não diz que modelo atual; o SDXL tem outra licença (RAIL++-M) | Termos sem a cláusula num serviço que só use modelos com outra licença | Indício moderado |
| <a id="h02"></a>H02 | As ferramentas Pro desenham uma tela de ~1024 px com o sprite a escala inteira (4×, 3×, 2×) e fatiam a grelha de candidatos, quadros ou direções | Escalões de preço 256/341/512 = 1024/4, 1024/3, 1024/2 e os das outras ferramentas Pro na proporção da grelha; grelha × lado máximo entre 245 e 256 (3×3 a 8×8) e 340 (2×2 e o caso de 85 px) | Nenhuma regra única de margem reproduz todas as linhas da tabela | S06 devolver outro número de candidatos, ou candidatos sem relação de tamanho com a tabela | Inferência forte |
| <a id="h03"></a>H03 | O gerador das ferramentas Pro é da família Gemini 3.x de imagem (ou partilha a sua tabela de proporções) | Os tetos publicados são exatamente metade da tabela 1K de dez proporções do Gemini 3.x (1024², 1376×768, 768×1376, 1584×672); as tabelas de 14 proporções e a do Gemini 2.5 não coincidem | Coincidência de tabela não é identidade; o PixelLab pode ter escolhido a mesma tabela para outro gerador | Uma saída Pro com metadados de outro fornecedor, ou tetos que mudem sem o Gemini mudar | Indício |
| <a id="h04"></a>H04 | Os modelos clássicos (Pixflux, Pixen, Bitforge) geram em cor contínua e não num espaço de índices de paleta | 15 de 16 saídas da documentação têm pares de cores quase iguais (OKLab < 0,02); a especificação diz que saídas de IA trazem "centenas de cores quase idênticas" e vende o `reduce-colors`; `color_image` chama-se "paleta forçada" | Imagens de documentação são antigas e escolhidas | S04: `color_image` com zero pixeis fora da paleta mostraria uma restrição estrutural nesse caminho | Moderado |
| <a id="h05"></a>H05 | O Pro Flash é um modelo nativo de sprites, à parte | Tamanhos "nativos" por balde, 16 px experimental, preço pelo tempo de GPU, `operationId` escritos à mão | Nenhuma medição de saída | Saídas Pro Flash com escala exata > 1 | Fraco |
| <a id="h06"></a>H06 | Os personagens v3 partem de um corpo-modelo articulado | Corpos-modelo com nome; humanoide imposto sem referência; profundidade do esqueleto tirada do corpo-modelo | — | — | Facto publicado |
| <a id="h07"></a>H07 | A mesma seed repete os bytes nos modelos clássicos | A especificação chama-lhe "seed que decide o ruído inicial" | O Pro Flash diz o contrário para si | S01 | Hipótese |
| <a id="h08"></a>H08 | Mais força da imagem inicial preserva mais, de forma monótona | Documentação da imagem inicial | Não há curva publicada | S03 | Hipótese |
| <a id="h09"></a>H09 | `color_image` impõe a paleta | "Forced color palette" | A documentação admite cores a mais e vende a redução | S04 | Hipótese |
| <a id="h10"></a>H10 | O enum `outline` muda o contorno de forma mensurável | Documentado como orientação "fraca" | — | S05 | Hipótese |
| <a id="h11"></a>H11 | Na máscara do Bitforge o branco gera e o exterior fica igual | Especificação | A documentação antiga do editor usava preto | S07 | Hipótese |
| <a id="h12"></a>H12 | O `reduce-colors` com `palette_image` partilha uma paleta entre quadros sem mudar regiões paradas | Especificação | — | S08 | Hipótese |
| <a id="h13"></a>H13 | A API é Python (FastAPI/Pydantic, uvicorn) em AWS `eu-west-1` | §2 e §3 | — | — | Medição |
| <a id="h14"></a>H14 | O PixMiniMax usa um modelo de vídeo da MiniMax | "Powered by MiniMax H3"; preço pelo tempo de geração; quadros em múltiplos de 4 | — | — | Facto publicado |
| <a id="h15"></a>H15 | As saídas públicas são gravadas nativas (sem ampliação) | 15 de 16 com escala exata 1; um tileset a 2× exato | Amostra pequena e antiga | S02 | Medição na amostra |

## 6. Forense das imagens da documentação

`forense.py` mediu as 60 imagens que o `llms-full.txt` referencia ([forense-imagens.json](forense-imagens.json)).
O papel de cada imagem veio do contexto da página, escrito no script: 16 saídas de modelo, 4 imagens do
utilizador (esboços, esqueleto) e 40 ecrãs da interface. As imagens não estão no repositório.

| Medida, nas 16 saídas | Resultado |
| --- | --- |
| Gravadas nativas (escala exata 1) | 15; um tileset é uma ampliação exata 2× de 160×128 |
| Cores opacas | de 130 a 1603 |
| Com pares de cores quase iguais (OKLab < 0,02) | 15 |
| Alfa | 12 binário, 4 com meios-tons (os magos e o mapa mais antigos) |
| Metadados | nenhuma com C2PA, EXIF ou blocos de texto |
| Grade estimada pela Forja **antes** | errada em 8 de 16 (o pirata de 64×64 → 12×11; o mapa de 128×128 → 8×9; o tileset 2× → metade) |
| Grade com as salvaguardas **depois** | errada em 0 de 16 |

<a id="forja"></a>
## 7. O que mudou na Forja por causa disto

**Conformidade do adaptador** (`tools/forja/backends/pixellab_api.py`). Antes, no commit da `main`
`74f71a1`, 10 divergências ([conformidade-forja-antes.json](conformidade-forja-antes.json)): sem lado
mínimo de 16 no Pixflux e no Bitforge, sem lado máximo nos três modelos (400, 768, 200) e sem os
intervalos de `init_image_strength`, `text_guidance_scale` e `style_strength`. Depois: os limites por eixo
e a tabela `RANGES` entram no `check`, que já corre antes de qualquer rede; o adaptador regista o hash
novo; o `contrato.py` dá 63 verificações sem divergências.

**A força zero.** O relatório de 24/10 (P0-6) pediu que um zero explícito deixasse de virar 300 — certo —
e que fosse enviado como zero. O contrato diz que o mínimo é 1 (a ajuda da própria CLI já dizia "1-999"):
um pedido com 0 seria recusado pela API com 422. Agora um valor dado nunca é trocado e, fora de 1–999, o
plano falha antes da rede com a razão. O teste do FORJA-03 foi atualizado para afirmar isto.

**A grade.** Novo `tools/forja/gridcheck.py`, usado por `snap`, `forge` e `sheet`: uma ampliação exata
k×k mede-se em vez de se estimar, e um período estimado cuja amostragem dá pureza abaixo de 0,8 é
recusado, com a imagem tratada como nativa e a razão escrita. Na prova da Forja (imagens falsas com
ruído, desfoque e escala fracionária) a pureza fica entre 0,96 e 1,0; no pirata nativo foi 0,54. O
limiar é provisório: calibrado nessas imagens, não num conjunto real de geradores. Testes:
`tools/forja/tests/test_gridcheck.py`.

<a id="envio"></a>
## 8. Conferência do envio de 26/10 (FORJA-04, PR #123)

O dono pediu que se verificasse também o envio de hoje, no último deploy da Vercel: o ramo
`claude/magical-fermat-i82f48`, commit `7b2e50b`, PR #123 ("A Forja vê a cor no espaço"), com o relatório
de 25/10, o dossiê dos 200 vídeos e o pacote. `conferir_envio.py` grava
[conferencia-forja-04.json](conferencia-forja-04.json).

| Verificação | Resultado |
| --- | --- |
| Manifesto SHA-256 do pacote | 12 de 12 ficheiros conferem (os dois Markdown estão fora de `pacote/`, renomeados, com os mesmos bytes) |
| Os 200 vídeos do catálogo (oEmbed público) | 200 existem, todos do canal PixelLab; 199 com o título registado; 1 mudou de título depois da recolha (de "Tutorial: Make a Full Game Character…" para "How to Make a Full Game Character…") |
| As 12 páginas PixelLab que o relatório cita | Todas respondem 200 com o título esperado |
| Alegações sobre a API (512×512 somados, exclusividade, dither, `drift_threshold`) | Todas verdadeiras na especificação de hoje |
| Suíte da Forja no ramo | 239 testes, 3 saltados como antes; `prova_cores.py` dá o mesmo resultado (44 pixeis mudados, S8 0,062 → 0,050) |
| CI do PR | 16 verificações verdes, sem conflitos com a `main` (lido às 06:20 UTC); o PR entrou depois na `main` (`c401ac7`) e este trabalho foi junto por cima, com as provas do FORJA-04 a dar o mesmo resultado |

Um pormenor sem consequência: a descrição do PR diz 236 testes da Forja; o commit de revisão posterior
acrescentou três. O dossiê dos vídeos diz o que não fez (não transcreve, não assistiu a tudo) e a
conferência não muda isso: o oEmbed confirma existência, autor e título, não as legendas.

## 9. Errata ao que já estava escrito

| Onde | O que dizia | O que se sabe agora |
| --- | --- | --- |
| [Relatório mestre §4](../2026-10-23-pixellab/RELATORIO-MESTRE.md) | Pixen: múltiplos de quatro "com limites adicionais de área" | E cada lado de 16 a 768; os três modelos clássicos têm limites por eixo |
| Relatório mestre §3.3 e §5 | Pixel Party XL como evidência histórica; termos lidos para treino e revenda | Os termos têm também a cláusula Open RAIL-M ([H01](#h01)) |
| Relatório mestre §3.4 | Arquitetura e pesos desconhecidos | Continuam; mas a forma das ferramentas Pro e a pilha da API passaram a inferência e medição ([H02](#h02), [H13](#h13)) |
| [Pesquisa da Forja de 23/10](../2026-10-23-forja-pixellab/README.md) | "118 ferramentas" no MCP | O guia de hoje descreve 117; a contagem depende do que se conta como ferramenta |
| `pixellab_api.py` (23/10) | Limites só por área; hash `e322e725…` | Limites por eixo e intervalos; hash `1c895d3f…` |
| FORJA-03 / guia da Forja | "`--init-strength 0` vai como 0" | 0 é recusado antes da rede ([§7](#forja)) |

## 10. O que continua desconhecido

Pesos, dados de treino, número de parâmetros, custo real por geração, o algoritmo de paleta, a regra
exata da tabela de candidatos do Pro, se as seeds são deterministas e que fornecedor serve cada família.
As sondas S01–S08 resolvem as hipóteses que a API oficial pode resolver; as outras ficam como estão, e
nenhum documento deste repositório as deve apresentar como sabidas.
