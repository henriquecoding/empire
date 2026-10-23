# Forja — pixel art de verdade a partir de qualquer gerador

Ferramenta do repositório (`tools/forja/`) para agentes de IA e pessoas
produzirem pixel art do Empire com geradores de imagem — ChatGPT/gpt-image,
Gemini, PixelLab ou desenho à mão. Ela não é um modelo de imagem: é o que fica
em volta do modelo. Planeia o pedido para o gerador que o vai receber, guarda
cada pedido pago como um job que não se repete nem se perde, estima a grade da
imagem devolvida e escolhe para cada célula uma cor, aplica a paleta e os
contratos do jogo, separa o que mede do que só suspeita, explica ao gerador o
que corrigir e exporta para Aseprite e Godot. A pesquisa que a fundamenta está
em [research/2026-10-23-forja-pixellab](research/2026-10-23-forja-pixellab/README.md);
as decisões, nas ADR [0088](../adr/0088-a-forja-de-pixel-art.md) e
[0089](../adr/0089-a-forja-pede-uma-vez-e-mede.md). A
[auditoria de 23/10](research/2026-10-23-pixellab/AUDITORIA-FORJA-CLAUDE.md)
achou nove falhas no primeiro corte; os reparos e o que ficou aberto estão em
[research/2026-10-23-forja-reparos](research/2026-10-23-forja-reparos/README.md).

```bash
python3 -m tools.forja --help          # todos os subcomandos
python3 -m tools.forja kinds           # os contratos: telas, pivôs, contornos, tags
python3 -m tools.forja prova           # a prova: pixel art falsa fabricada e recuperada
python3 -m unittest discover -s tools/forja/tests -t .   # os testes
```

Requisitos: Python 3.11 ou mais novo e o Pillow fixado em `tools/requirements.txt`
(`make ferramentas-python`). Nenhuma dependência nova. Os conectores de geração
usam a biblioteca padrão e só funcionam com a chave no ambiente.

## A lição que orienta a ferramenta

A pesquisa de 18/10/2026 registou porque as entregas anteriores falharam:
figuras grandes, reduzidas com nearest neighbor e quantização, **não
redesenham feições, proporções nem agrupamentos** para a resolução final
([estudo](research/2026-10-18-imperadores-escudeiros/PIXEL-ART-COMPACTA-E-PIXELLAB.md)).
A Forja inverte o processo:

1. O pedido diz ao gerador a **grade lógica final** (por exemplo, 64×64 pixels
   lógicos desenhados como blocos de 16×16) e, onde o gerador aceita lados
   livres (gpt-image), o tamanho de imagem que a torna exata. Ao PixelLab pede-se
   o tamanho nativo do contrato (64×64, 80×80). O Gemini só aceita proporções e
   resoluções fixas: a prancha é centrada numa delas, com margens escritas.
   Pedir a grade por palavras não a garante: o que chega é medido, não assumido.
2. A grade é estimada — não reduzida. Cada célula vota numa cor; onde o
   gerador desenhou mais fino do que a célula (rostos, muitas vezes), essa
   informação perde-se e o relatório aponta onde.
3. Se a figura não cabe na tela do contrato, a Forja **recusa** com o erro
   `clipped` e devolve ao gerador a altura certa. Não encolhe a figura.

## O ciclo

```text
forja prompt / plan ──► gerador (job) ──► forja forge / sheet ──► revisão + relatório
        ▲                                                              │
        └────────────── prompt_feedback (inglês, para o gerador) ◄─────┘
```

| Passo | Comando | O que sai |
| --- | --- | --- |
| Compilar o pedido | `forja prompt "<assunto>" --kind <tipo> [--tags walk] -o build/forja/x/pedido` | `prompt.txt`, `expect.json`, `guide_layout.png`, `guide_palette.png`, `pixellab.json` e a lista `attach` (o que anexar, por ordem) |
| Planear para um gerador | `forja plan "<assunto>" --backend pixellab --kind royal_64 [--reference aprovado.png] -o build/forja/x` | `plan/plan.json` validado sem rede: tamanho, imagens por papel com hash, limites, prompt |
| Gerar | a ferramenta de imagem do agente, ou `forja generate --backend openai --prompt-file … --max-calls 1 -o …` | PNG(s) num job em `jobs/<id>.json` e `budget.json` |
| Forjar uma figura | `forja forge <imagem> --expect …/expect.json -o build/forja/x` | `<nome>.png` na tela do contrato, `@4x`, `.json`, `report.html` |
| Forjar uma prancha | `forja sheet <imagem> --expect …/expect.json -o build/forja/x [--mirror]` | tira, JSON do Aseprite, `.aseprite`, GIF/APNG, SpriteFrames opcional, relatório com leitor |
| Corrigir | voltar a gerar com `prompts.corrective` (o `prompt_feedback` do relatório) | nova tentativa |
| Fechado com chave | `forja auto "<assunto>" --kind … --backend openai --max-calls 3 -o …` | plano, jobs e tentativas, até a revisão automática não pedir outra geração ou esgotar `--attempts`/teto |
| Rever pedidos pagos | `forja jobs build/forja/x [--resume ID] [--cancel ID]` | estado, tentativas, custo; retomar só consulta (GET) |

`python3 -m tools.forja` abrevia-se como `forja` nesta página.

### Agente com geração de imagens embutida (ChatGPT, Codex com imagegen)

1. `forja prompt "squire with a round wooden shield" --kind character_s1 --tags idle -o build/forja/escudeiro/pedido`
2. Gerar a imagem no tamanho indicado (`size`) com o texto de `prompt.txt`,
   anexando exatamente as imagens de `attach`, por essa ordem (o design
   aprovado, se compilou com `--reference`, e a amostra da paleta quando ela não
   cabe no texto). O prompt numera as imagens anexadas e não promete nenhuma
   outra; o molde `guide_layout.png` é opcional. A amostra da paleta não é
   enfeite: com as cores dela, quadros iguais saem iguais; sem ela, o ruído do
   gerador troca tons vizinhos de quadro para quadro. Se a resposta trouxer
   `advice`, cada pixel lógico ficaria com poucos pixels na imagem: peça menos
   quadros por prancha.
3. Guardar o PNG devolvido, sem recomprimir em JPEG, em `build/forja/escudeiro/`.
4. `forja sheet build/forja/escudeiro/gerada.png --expect build/forja/escudeiro/pedido/expect.json -o build/forja/escudeiro/v1`
5. Ler `review` (`contract_valid`, `motion_checks`, `needs_regeneration`),
   `found`/`requested` e `prompt_feedback`. Se `needs_regeneration`, gerar de
   novo com o prompt original seguido de
   `Corrections from the previous attempt (follow strictly): <prompt_feedback>`.
6. Abrir `report.html`, ver a animação na velocidade real e quadro a quadro, e
   mostrar o GIF ao dono. `artistic_approval` fica sempre `pendente`: é dele.

### Agente com terminal e chave de API

`forja auto` faz o ciclo inteiro: planeia, gera, forja, revê e corrige o
prompt. Variáveis: `OPENAI_API_KEY` (modelo por omissão
`gpt-image-2.5-sunburst`, ou `FORJA_OPENAI_MODEL`), `GEMINI_API_KEY`
(`FORJA_GEMINI_MODEL`, por omissão `gemini-3.1-flash-image`) ou
`PIXELLAB_API_KEY`. As chaves nunca entram em relatórios nem nos jobs.

Antes de gastar: `forja plan` com os mesmos argumentos mostra o pedido que
sairia, sem rede. Um pedido inválido (tamanho fora do modelo, referência no
tamanho errado, prancha animada no PixelLab, modelo desconhecido) falha aí.

### Pedidos pagos: um POST, um job, um teto

- Cada pedido é um ficheiro `jobs/<id>.json`, escrito **antes** de o POST sair:
  descritor do pedido (sem base64 nem chaves) e o hash dele, hashes e papéis das
  imagens, tentativas com tempos, id remoto, custo dito pelo fornecedor ou
  `unknown`, saídas com hash e tamanho medido.
- Um POST de geração sai uma vez. Recusa clara (4xx, 429 com `Retry-After`) fica
  `rejected` e pode pedir-se de novo; resposta perdida (rede, 5xx) fica
  `submission_unknown` e **não** se reenvia sem `force_resubmit` — pode ter
  sido cobrado. Só as consultas (GET, DELETE) se repetem, com espera, jitter,
  `Retry-After` e prazo.
- Jobs remotos (PixelLab) consultam-se com prazo e limite; "concluído sem
  imagens" é erro; um estado desconhecido não gera outro pedido.
  `forja jobs <pasta> --resume ID` só consulta; `--cancel ID` pede ao fornecedor
  e regista a resposta sem prometer que não houve cobrança.
- `--max-calls` e `--max-usd` são o teto da pasta (`budget.json`, somado entre
  corridas). OpenAI e Gemini não devolvem dólares: aí o teto que vale é o número
  de chamadas.

### Como servidor MCP (Codex, Claude Code, outros clientes)

`python3 -m tools.forja mcp` serve todas as ferramentas por stdio
(`forja_prompt`, `forja_forge`, `forja_sheet`, `forja_lint`, `forja_tileset`…).
Os esquemas saem dos mesmos argumentos da linha de comandos. As respostas trazem
o JSON e a prévia ampliada como imagem, para o agente ver o que fez. O servidor
trabalha a partir da raiz do repositório: os caminhos relativos partem dela.

Claude Code lê o `.mcp.json` da raiz (pede autorização na primeira vez). No
Codex, em `~/.codex/config.toml`:

```toml
[mcp_servers.forja]
command = "python3"
args = ["-m", "tools.forja", "mcp"]
env = { PYTHONPATH = "/caminho/para/empire" }
```

O ChatGPT na web só liga a servidores MCP remotos por HTTPS. A Forja é local;
nesse caso, use os passos da secção anterior e corra os comandos no repositório.

## Receitas por tipo de asset

Os tipos (`--kind`) e os números de cada contrato vêm de
`tools/forja/contracts.json`, conferido contra a Asset Bible e a Animation Bible
pelos testes. `forja kinds` mostra-os; esta página não os copia.

- **Personagem parado.** `prompt --kind character_s2` (ou `royal_64`/`royal_80`
  para o elenco V15) → `forge`. Contorno preto de 1 px, pés no pivô, alfa
  binário, paleta de trabalho. A limpeza segue o tipo (`--cleanup`): num
  personagem ou efeito, um pixel solto ou um furo de 1 px ficam e aparecem como
  candidatos no relatório (podem ser um olho, um brilho, um rebento); só o
  cenário os tira. Ruído de cor quase igual ao vizinho é alisado (`--noise 0`
  desliga) e `--protect x0,y0,x1,y1` guarda uma caixa.
- **Animação.** `prompt --tags walk` (ou `idle,walk`) pede a prancha com as
  contagens e notas da Animation Bible → `sheet`. A Forja conta as figuras
  reais contra as pedidas e **não inventa** um quadro em falta. Com o
  `expect.json` (ou `--layout CxL`) cada célula pedida é recortada com a sua
  própria máscara, e figuras que se tocam continuam separadas; sem grelha, a
  separação automática precisa de espaço vazio entre figuras. Escala e paleta
  comuns. Com a grelha, cada figura **fica onde estava na sua célula** e só o
  chão comum vai ao pivô (`--align preserve`): um salto continua no ar, um
  agachar não cresce, uma flor cresce da mesma raiz. `--align feet` alinha cada
  quadro pelo próprio apoio e o relatório diz que a deriva zero daí é imposta.
  Um quadro repetido de propósito declara-se: `--hold 3:200:antecipação`.
  A revisão separa `contract_valid` (contagem, tela, paleta, nada cortado), os
  indícios de movimento (quadros todos iguais — único que obriga a gerar de novo
  —, repetidos sem declaração, salto sem intermédio, parte que some) e a
  aprovação do dono. Ordem e continuidade de braços e mãos só se veem a olho.
  `--deflicker 0.05` prende cores que mudam quase nada; `--lock x0,y0,x1,y1`
  cola o rosto do quadro de referência em todos os quadros (o "fixed head" do
  PixelLab); `--mirror` exporta a esquerda como espelho, contado como espelho.
- **Corrigir uma parte.** `forja inpaint sprite.png --box x0,y0,x1,y1 --change "…"`
  manda a imagem ampliada sobre uma cor de chave que não existe no sprite nem
  na paleta, com máscara, ao gpt-image; volta pela grade conhecida (outro
  tamanho é erro) e compõe: fora da caixa os bytes ficam idênticos; dentro, o
  que voltou igual ao enviado fica com os bytes originais (um eco devolve o
  sprite exato, azul e transparência incluídos).
- **Edifício, prop, cenário.** `--kind building` ou `prop`: o pedido usa a
  grade de 2 px (cluster 2×2 da Asset Bible) e a Forja amplia por 2 no fim;
  contorno de 2 px na silhueta. O lint aponta manchas menores que 2×2.
- **Terreno em tiles.** Gerar texturas com `prompts.texture_prompt`, forjá-las
  (`--kind tile`), conferir com `forja seams` e montar o conjunto
  `forja tileset --lower terra.png --upper relva.png --rim #3C2C1E --godot-texture res://…`.
  Saem os 16 tiles por cantos (codificação do PixelLab: `NW<<3|NE<<2|SW<<1|SE`),
  um mapa de demonstração e um `TileSet` do Godot em "Match Corners". Com
  `--lower none --rim-side top` sai a plataforma lateral (relva só por cima).
- **Parallax e primeiro plano.** `--kind parallax_far`, `parallax_mid`,
  `foreground`: sem contorno e com o teto de valores da Parte XIII.
- **Efeitos.** `--kind fx` permite `--dither bayer2|bayer4|bayer8`.
  `forja motion dissolve|flash|knockback|breathe` gera ajudas procedurais;
  não substituem desenhar a pose.
- **Paletas.** `forja palette show empire`, `palette extract imagem.png --colors 16`,
  `palette ramp #5A8C3C --steps 5` (rampa com desvio de matiz, claros quentes e
  escuros frios). Uma rampa nova é proposta até o dono a aceitar.

## Referência dos comandos

| Comando | Para quê |
| --- | --- |
| `snap` | Só a grade: imagem ampliada → resolução nativa (o "unzoom") |
| `forge` | Uma figura gerada → sprite do contrato, com lint e relatório |
| `sheet` | Prancha gerada → quadros alinhados e animação exportada |
| `lint` | Conferir um PNG contra um contrato |
| `clean` | Alfa binário, pixels soltos, furos, ruído de cor, cluster mínimo, pixel perfect |
| `quantize` | Paleta (OKLab) ou N cores, dither ordenado opcional |
| `outline` | Contorno exterior, interior ou seletivo; ou tirá-lo |
| `fit` | Pousar na tela e no pivô do contrato |
| `scale` | Ampliação inteira, Scale2x, rotação RotSprite, redução por voto |
| `anim` / `aseprite` | Quadros PNG → tira, JSON do Aseprite, `.aseprite`, GIF/APNG, SpriteFrames |
| `lock` / `motion` | Travar o rosto; respirar, piscar, dissolver, empurrão |
| `tileset` / `seams` | Conjunto Wang 16 + TileSet do Godot; conferir emendas |
| `palette` | Mostrar, converter, extrair, rampa, fundir cores próximas |
| `prompt` / `plan` / `generate` / `auto` / `inpaint` | O lado do gerador: pedir, planear sem rede, gerar com job e teto |
| `jobs` | Pedidos pagos de uma pasta: ver, retomar (só consulta), cancelar |
| `prova` / `mcp` / `kinds` | A prova, o servidor MCP, os contratos |

Todos os comandos imprimem JSON. O código de saída é 0 quando o resultado
cumpre, 1 quando há achados de erro e 2 quando o pedido é inválido.

## O que a Forja faz por dentro

- **Grade.** Perfil de bordas por eixo; período pela autocorrelação dos dois
  eixos juntos, com o pico alargado contra células desiguais; afinação
  fracionária por pente de contraste (dentes nas linhas menos meios entre elas:
  múltiplos e submúltiplos perdem); linhas por uma reta refeita por mínimos
  quadrados com as bordas confirmadas e interpolação nas zonas lisas.
- **Amostragem.** Cada célula vota a cor dominante no miolo (sem a borda
  suavizada); uma cor chapada sai igual, uma ruidosa sai limpa.
- **Fundo.** Alfa, chave (a cor mais longe da paleta do projeto, escolhida pelo
  prompt) ou fundo liso por enchimento a partir da borda, na resolução nativa.
- **Cor.** OKLab para todas as distâncias; k-means sem sorteio; dither
  posicional entre as duas cores mais próximas.
- **Exportação.** `.aseprite` escrito pela especificação pública e relido pelo
  leitor do projeto (`tools/aseprite_source.py`); JSON no formato do CLI do
  Aseprite; `.tres` do Godot carregados no motor fixado pelo teste opcional. As
  direções das tags (`reverse`, `pingpong`, `pingpong_reverse`) saem na ordem
  em que tocam, cada quadro com a sua duração. Um escritor e um leitor nossos
  podem partilhar um erro: abrir no aplicativo continua por registar.

## Estados e limites

- Uma imagem forjada é **adaptação de imagem gerada**. A proveniência grava a
  entrada, o prompt, o gerador e os parâmetros, com `artistic_approval: false`
  e `manual_review: pendente`. Cumprir o contrato não é aprovação artística.
- A Forja escreve onde lhe dizem; use `build/forja/`. Não escreve em `art/`
  sem pedido explícito do dono (AGENTS.md, regra 9).
- O `.aseprite` foi conferido como ficheiro (ida e volta pixel a pixel); não
  houve abertura no aplicativo Aseprite neste ambiente.
- Os conectores OpenAI, Gemini e PixelLab seguem as referências lidas em
  23/10/2026 (o hash da especificação do PixelLab está no adaptador) e foram
  testados com um transporte falso. Não houve chamada real (sem chaves): o
  [piloto](research/2026-10-23-forja-reparos/piloto.json) está definido, com
  referências e teto, e por executar. Os nomes de modelos mudam: confirme antes
  de depender deles. A tabela de pixels de saída do Gemini não foi achada na
  documentação: a Forja estima-a e mede o que chega.
- A prova (`forja prova`) e a bancada usam distorções fabricadas com verdade
  conhecida: demonstram a recuperação nesses casos, não a qualidade de rostos,
  identidade ou ações. Nenhum benchmark compara a Forja com o PixelLab nem com
  outras ferramentas de recuperação no mesmo conjunto de imagens.
- Um gerador geral costuma desenhar o rosto mais fino do que a própria grade
  (um sorriso de meio bloco, olhos em traço fino). Nenhum voto por célula
  recupera esse traço. A Forja mede as células misturadas, mostra-as a vermelho
  no relatório e, quando pesam, avisa (`subgrid`) com a instrução para o
  gerador; o conserto é gerar de novo ou `forja inpaint` nessa caixa. Nas duas
  pranchas reais do projeto o corpo voltou fiel e o rosto perdeu traços
  ([comparação](research/2026-10-23-forja-pixellab/README.md#imagens-reais-do-projeto)).
- Escalas muito pequenas (4–6 px por pixel lógico) com desfoque podem trocar
  tons vizinhos junto ao contorno. Os geradores trabalham em escalas maiores.
- A grade recuperada é uma estimativa do que o gerador desenhou. Se ele
  desenhou mal (mãos ilegíveis, poses sem apoio), a Forja entrega pixel art
  limpa de um desenho fraco. A checklist de revisão de personagens continua a
  valer; um score automático não aprova direção de arte.
