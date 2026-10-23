# Forja — pixel art de verdade a partir de qualquer gerador

Ferramenta do repositório (`tools/forja/`) para agentes de IA e pessoas
produzirem pixel art do Empire com geradores de imagem — ChatGPT/gpt-image,
Gemini, PixelLab ou desenho à mão. Ela não é um modelo de imagem: é o que fica
em volta do modelo. Compila o pedido, recupera a grade exata da imagem
devolvida, aplica a paleta e os contratos do jogo, confere o resultado, explica
ao gerador o que corrigir e exporta para Aseprite e Godot. A pesquisa que a
fundamenta está em
[research/2026-10-23-forja-pixellab](research/2026-10-23-forja-pixellab/README.md);
a decisão, na [ADR 0088](../adr/0088-a-forja-de-pixel-art.md).
O [refinamento FORJA-02](research/2026-10-23-forja-pixellab/REFINAMENTO.md)
registra as correções da auditoria, a revisão V15 e os limites de validação.

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
   lógicos desenhados como blocos de 16×16) e o tamanho de imagem que a torna
   exata. O gerador desenha *para* a resolução do jogo.
2. A grade é estimada e discretizada. Cores chapadas podem ser recuperadas
   exatamente; traços menores que a célula perdem informação. No PixelLab,
   o pedido já usa dimensões nativas e escala 1.
3. Se a figura não cabe na tela do contrato, a Forja **recusa** com o erro
   `clipped` e devolve ao gerador a altura certa. Não encolhe a figura.

## O ciclo

```text
forja prompt  ──►  gerador  ──►  forja forge / sheet  ──►  lint + relatório
     ▲                                                          │
     └─────────────── prompt_feedback (inglês, para o gerador) ◄┘
```

| Passo | Comando | O que sai |
| --- | --- | --- |
| Compilar o pedido | `forja prompt "<assunto>" --kind <tipo> [--tags walk] -o build/forja/x/pedido` | `prompt.txt`, `expect.json`, `guide_layout.png`, `guide_palette.png`, `pixellab.json` |
| Gerar | a ferramenta de imagem do agente, ou `forja generate --backend openai --prompt-file … --expect …` | PNG(s) e `*.generation.json` |
| Forjar uma figura | `forja forge <imagem> --expect …/expect.json -o build/forja/x` | `<nome>.png` na tela do contrato, `@4x`, `.json`, `report.html` |
| Forjar uma prancha | `forja sheet <imagem> --expect …/expect.json -o build/forja/x [--mirror]` | tira, JSON do Aseprite, `.aseprite`, GIF/APNG, SpriteFrames opcional, relatório com leitor |
| Corrigir | voltar a gerar com `prompts.corrective` (o `prompt_feedback` do relatório) | nova tentativa |
| Fechado com chave | `forja auto "<assunto>" --kind … --backend openai -o …` | as tentativas, até passar ou esgotar `--attempts` |

`python3 -m tools.forja` abrevia-se como `forja` nesta página.

### Agente com geração de imagens embutida (ChatGPT, Codex com imagegen)

1. `forja prompt "squire with a round wooden shield" --kind character_s1 --tags idle -o build/forja/escudeiro/pedido`
2. Gerar a imagem no tamanho indicado (`size`) com o texto de `prompt.txt`,
   anexando `guide_layout.png` e `guide_palette.png` (e o design aprovado, se
   houver — nesse caso compile com `--reference`). A amostra da paleta não é
   enfeite: com as cores dela, quadros iguais saem iguais; sem ela, o ruído do
   gerador troca tons vizinhos de quadro para quadro. Se a resposta trouxer
   `advice`, cada pixel lógico ficaria com poucos pixels na imagem: peça menos
   quadros por prancha.
3. Guardar o PNG devolvido, sem recomprimir em JPEG, em `build/forja/escudeiro/`.
4. `forja sheet build/forja/escudeiro/gerada.png --expect build/forja/escudeiro/pedido/expect.json -o build/forja/escudeiro/v1`
5. Ler `ok`, `found`/`requested`, `findings` e `prompt_feedback`. Se não passou,
   gerar de novo com o prompt original seguido de
   `Corrections from the previous attempt (follow strictly): <prompt_feedback>`.
6. Abrir `report.html` e mostrar o GIF ao dono. A aprovação é dele.

### Agente com terminal e chave de API

`forja auto` faz o ciclo inteiro: compila, gera, forja, confere e corrige o
prompt até passar. Variáveis: `OPENAI_API_KEY` (modelo por omissão
`gpt-image-2.5-sunburst`, ou `FORJA_OPENAI_MODEL`), `GEMINI_API_KEY`
(`FORJA_GEMINI_MODEL`, por omissão `gemini-3.1-flash-image`) ou
`PIXELLAB_API_KEY`. As chaves nunca entram em relatórios.

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
  binário, paleta de trabalho. Um olho de um pixel é intenção e fica; ruído de
  cor quase igual ao vizinho é limpo.
- **Animação.** `prompt --tags walk` (ou `idle,walk`) pede a prancha com as
  contagens e notas da Animation Bible → `sheet`. A Forja conta as figuras
  reais contra as pedidas e **não inventa** um quadro em falta. Com o
  `expect.json` (ou `--layout CxL`) cada célula pedida é recortada com a sua
  própria máscara, e figuras que se tocam continuam separadas; sem grelha, a
  separação automática precisa de espaço vazio entre figuras. Escala e paleta
   comuns. Com layout e escala conhecidos, conserva a origem de cada célula:
   saltos e recuos mantêm o deslocamento. `--anchor feet` pede estabilização
   explícita do apoio; sem geometria conhecida, o alinhamento usa os pés.
  `--deflicker 0.05` prende cores que mudam quase nada; `--lock x0,y0,x1,y1`
  cola o rosto do quadro de referência em todos os quadros (o "fixed head" do
  PixelLab); `--mirror` exporta a esquerda como espelho, contado como espelho.
- **Corrigir uma parte.** `forja inpaint sprite.png --box x0,y0,x1,y1 --change "…"`
  manda a imagem ampliada com máscara ao gpt-image, volta pela grade conhecida
  e compõe: fora da caixa, os pixels ficam idênticos (verificado).
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
| `review` | Revisão de movimento por tag e comparação de regiões, sem alterar pixels |
| `animate-native` / `job` | Animação PixelLab a partir de quadro nativo / retomar o mesmo job |
| `clean` | Alfa binário, pixels soltos, furos, ruído de cor, cluster mínimo, pixel perfect |
| `quantize` | Paleta (OKLab) ou N cores, dither ordenado opcional |
| `outline` | Contorno exterior, interior ou seletivo; ou tirá-lo |
| `fit` | Pousar na tela e no pivô do contrato |
| `scale` | Ampliação inteira, Scale2x, rotação RotSprite, redução por voto |
| `anim` / `aseprite` | Quadros PNG → tira, JSON do Aseprite, `.aseprite`, GIF/APNG, SpriteFrames |
| `lock` / `motion` | Travar o rosto; respirar, piscar, dissolver, empurrão |
| `tileset` / `seams` | Conjunto Wang 16 + TileSet do Godot; conferir emendas |
| `palette` | Mostrar, converter, extrair, rampa, fundir cores próximas |
| `prompt` / `generate` / `auto` / `inpaint` | O lado do gerador |
| `prova` / `mcp` / `kinds` | A prova, o servidor MCP, os contratos |

Todos os comandos imprimem JSON. O código de saída é 0 quando o resultado
cumpre, 1 quando há achados de erro e 2 quando o pedido é inválido.

## Fluxo refinado: planejar, preservar, rever

Preparar um pedido sem credencial ou gasto:

```bash
python3 -m tools.forja auto "comic squire with wooden shield" \
  --backend pixellab --kind royal_64 --dry-run -o build/forja/plano
```

Saem `plan.json`, prompt, `expect.json` e guias. O plano registra modelo,
dimensões, hashes das referências e máximo de submissões. Para executar,
usar outra pasta e retirar `--dry-run`; `--attempts 2` limita a duas tentativas.
Cada saída bruta fica guardada. `run.json` registra a melhor tentativa por
erros e avisos, sem conceder aprovação artística. Não reutilizar pastas com
recibos anteriores. A referência PixelLab precisa da tela nativa pedida;
o conector não a reduz nem ignora referências extras.

No Gemini, `auto` usa 2K quadrado com a grade inteira dentro de margens
registradas. As guias são anexadas; a área de conteúdo é recortada depois de
validar o raster recebido. Um modelo sem suporte a esse plano é recusado.
Pedidos `prompt --target gemini` também guardam o recorte no `expect.json`;
passar esse arquivo a `forge` ou `sheet` conserva a geometria.

Para animar um quadro aprovado sem o limpar ou reancorar:

```bash
python3 -m tools.forja animate-native build/forja/referencia.png \
  --action "walk in place, side view, preserve face and shield" \
  --frames 8 --kind royal_64 --tag walk --dry-run -o build/forja/anim-plano
```

Retirar `--dry-run` e usar uma pasta nova para executar com `PIXELLAB_API_KEY`.
`--last-frame` fornece uma pose final opcional na mesma tela. O recibo
`native-job.json` é salvo antes do polling. O comando preserva os rasters e
recusa primeiro quadro alterado, quantidade ou tamanho incorretos. `seed=0`
significa aleatório nesse endpoint; uma seed positiva é registrada no plano.

```bash
python3 -m tools.forja job --job-id ID_GUARDADO -o build/forja/retomado
python3 -m tools.forja review build/forja/retomado/resumed_*.png \
  --tags walk:8 --kind royal_64 --reference build/forja/referencia.png \
  -o build/forja/revisao
```

`job` apenas consulta e baixa o resultado do trabalho existente. `review`
produz JSON e HTML com leitor, onion skin, tira 1×, medidas e achados.
`--protected-box x0,y0,x1,y1` exige pixels idênticos numa região explicitamente
imóvel; não usar para uma cabeça que precisa mover-se. Para diagnóstico,
preferir essa comparação à opção destrutiva `--lock`.

`ok` indica validade estrutural; `ready` também exige ausência de avisos.
Nenhum deles é `artistic_approval`. Uma caminhada toda estática exige revisão;
pausas e holds repetidos podem ser intencionais. Pranchas com lacunas, extras
ou clipping não recebem exportações para o jogo; os índices de origem e o
relatório permitem corrigir a entrada sem deslocar tags.

No pipeline `forge`/`sheet`, pixels isolados e furos são preservados por padrão.
Usar `--remove-orphans` e `--fill-holes` apenas quando a alteração for desejada;
`--noise 0` desliga o alisamento cromático. `review` nunca aplica esses passos.
`--same-height` foi retirado por deformar o personagem.

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
  Aseprite; `.tres` do Godot carregados no motor fixado pelo teste opcional.

## Estados e limites

- Uma imagem forjada é **adaptação de imagem gerada**. A proveniência grava a
  entrada, o prompt, o gerador e os parâmetros, com `artistic_approval: false`
  e `manual_review: pendente`. Cumprir o contrato não é aprovação artística.
- A Forja escreve onde lhe dizem; use `build/forja/`. Não escreve em `art/`
  sem pedido explícito do dono (AGENTS.md, regra 9).
- O `.aseprite` foi conferido como ficheiro (ida e volta pixel a pixel); não
  houve abertura no aplicativo Aseprite neste ambiente.
- Os conectores OpenAI, Gemini e PixelLab seguem as referências lidas em
  23/10/2026 e foram testados com um transporte falso. Não houve chamada real
  (sem chaves). Os nomes de modelos mudam: confirme antes de depender deles.
- Um gerador geral costuma desenhar o rosto mais fino do que a própria grade
  (um sorriso de meio bloco, olhos em traço fino). Nenhum voto por célula
  recupera esse traço. A Forja mede as células misturadas, mostra-as a vermelho
  no relatório e, quando pesam, avisa (`subgrid`) com a instrução para o
  gerador; o conserto é gerar de novo ou `forja inpaint` nessa caixa. Nas duas
  pranchas reais do projeto o corpo voltou fiel e o rosto perdeu traços
  ([comparação](research/2026-10-23-forja-pixellab/README.md#imagens-reais-do-projeto)).
- Escalas muito pequenas (4–6 px por pixel lógico) com desfoque podem trocar
  tons vizinhos junto ao contorno. Os geradores trabalham em escalas maiores.
- A grade recuperada é a que o gerador desenhou. Se ele desenhou mal (mãos
  ilegíveis, poses sem apoio), a Forja entrega pixel art limpa de um desenho
  fraco. A checklist de revisão de personagens continua a valer.
