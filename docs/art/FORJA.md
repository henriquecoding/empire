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
O [relatório de 24–25/10](research/2026-10-24-forja-armas/README.md) mostrou que
um sprite pode cumprir o contrato e ter duas guardas na espada: a Forja passou a
julgar o equipamento à parte ([ADR 0091](../adr/0091-a-forja-julga-o-equipamento.md)).
O [relatório de 25/10](research/2026-10-25-forja-pixels-cores/README.md) mostrou que
16 pontos de cor espalhados e o mesmo histograma num bloco davam as mesmas
respostas: a Forja passou a ver a cor no espaço, a proteger até ao PNG final e a
não congelar o movimento ([ADR 0092](../adr/0092-a-forja-ve-a-cor-no-espaco.md)).
A [auditoria de 26/10](research/2026-10-26-forja-auditoria/README.md) achou dez
falhas (A01–A10) — a mais grave, uma ampliação exata medida na fase errada, que
fazia uma prancha 10× sair "exata 2×" — e reparou-as com testes; a 27/10 aplicou o
que ficara aberto (O1–O6) e mais duas falhas achadas pelo caminho (A11, A12).
A [solução de 27/10](research/2026-10-27-forja-fidelidade/README.md), depois de o dono rejeitar o Rei, o Arqueiro e
o Escudeiro, mudou a ordem: o desenho recupera-se antes de se proteger, e só se protege o mestre que o dono aprovou —
cada referência tem autoridade registada, a edição local prende-se ao mestre e o encerramento não chama aprovação a uma
evidência de ficheiro ([ADR 0093](../adr/0093-a-forja-protege-o-mestre-aprovado.md)).

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
   anexando exatamente as imagens de `attach`, por essa ordem (a referência, se
   compilou com `--reference`, e a amostra da paleta quando ela não
   cabe no texto). A referência leva o seu estado: sem registo, o prompt diz que a
   aprovação não está registada; `--reference-state adaptation_in_review` ou
   `concept` dizem-no; «APPROVED» só com `--refs registo.json --reference-file imagem.png`
   e uma linha `approved` do dono. O prompt numera as imagens anexadas e não promete nenhuma
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
tamanho errado, prancha animada no PixelLab, modelo desconhecido) falha aí —
e também um assunto que contradiz a câmara (três quartos, de frente, de costas,
vista de cima, ou virado ao contrário de `--facing`): a câmara resolve-se num
campo só. No PixelLab, sem `--init-strength` vai 300; um valor dado nunca é
trocado, e fora de 1–999 (o 0 incluído) o plano falha, porque a API o recusaria.
Também falham aí os lados fora do modelo (16–400 no pixflux, 16–768 no pixen,
16–200 no bitforge) e `text_guidance_scale` ou `style_strength` fora do
intervalo. A força da imagem inicial orienta; não é trava de identidade. Estes
limites vêm da especificação pública com o hash que o adaptador regista; quando
o hash muda,
[`contrato.py`](research/2026-10-26-pixellab-engenharia-reversa/README.md#repetir)
diz o que divergiu.

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
  corridas; uma retomada soma nele o custo que o fornecedor disser, e um job que o
  fornecedor dá por falhado conta como custo desconhecido). OpenAI e Gemini não
  devolvem dólares: aí o teto que vale é o número de chamadas.
- No `auto`, uma imagem sem figura é uma tentativa que pede outra geração; um erro
  da própria Forja para o ciclo com a imagem paga guardada no job. O resultado diz
  a última tentativa forjada (`best`) e, se o ciclo parou depois dela, porquê
  (`stopped`). O prompt corretivo é inglês, como o pedido: a grade não seguida e o
  tamanho errado chegam ao gerador com a medida.

### Como servidor MCP (Codex, Claude Code, outros clientes)

`python3 -m tools.forja mcp` serve todas as ferramentas por stdio
(`forja_prompt`, `forja_forge`, `forja_sheet`, `forja_lint`, `forja_tileset`…).
Os esquemas saem dos mesmos argumentos da linha de comandos; os repetíveis
(`protect`, `bare`, `static`, `action`, `hold`) vão como listas. As respostas trazem
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

## Armas e equipamento: o que o contrato raster não vê

O lint confere tela, alfa, paleta, contorno e pivô. Não sabe o que é uma espada:
uma lâmina bifurcada, duas guardas ou a arma em falta passam com 0 erros
([fixtures](research/2026-10-24-forja-armas/fixtures.png)). Para isso há três
registos que não se confundem:

1. **Intenção** — o manifesto (`forja.equipment/1`): cada objeto com `id`,
   família (`sword_straight`, `bow_simple`, `shield`, `storage`), `slot` da Asset
   Bible, estado de uso (`held`, `rest`, `draw`…), partes e quantidades
   (`count`, `optional`, `hidden`, `occluders` — o que tapa ou cruza a parte),
   contactos com o corpo e material. Só apresentação: capacidade, munição ou dano
   são recusados (vivem em `data/source`).
2. **Observação** (`forja.observation/1`) — regiões e âncoras marcadas **numa**
   imagem (o hash dela vai no ficheiro), por caixa e cores, lista de pixels ou
   máscara PNG (o alfa, se ela tem transparência; senão o claro: branco marca),
   com autor, método, data e incerteza (`baixa`, `media`, `alta`).
   Não é um detector: diz quem viu o quê. Mudou a imagem, observa-se de novo.
3. **Veredito** — `forja equip` mede sobre a observação: instâncias de cada parte
   (a oclusão declarada liga as peças; os braços do arco ligam-se pela
   empunhadura), um só traçado da base à ponta da lâmina, a corda com 1 px, perto
   da reta entre as pontas e ligada a elas (só nos estados em que não está
   puxada), a guarda entre lâmina e empunhadura, e os contactos (mão–punho).

```bash
forja equip sprite.png --manifest manifesto.json --observation observacao.json --kind royal_80 -o build/forja/x
forja line  sprite.png --manifest manifesto.json --observation observacao.json --kind royal_80 --item bow_main -o build/forja/x
```

O relatório traz oito vereditos que não se somam: `raster_contract`,
`color_coherence` (ADR 0092), `equipment_geometry`, `functional_pose`, `identity_consistency`,
`temporal_consistency`, `artistic_approval` e `runtime_integration`. O que não
foi medido fica `not_evaluated` (nunca `pass`); uma parte possivelmente tapada
fica `inconclusive`; uma região com incerteza alta não deixa passar; a
aprovação é sempre `pending` na ferramenta. A imagem `_equip.png` mostra as
regiões e as âncoras a 8×, para a revisão ver o que foi medido.

`forja line` refaz uma linha fina — a corda — a 1 px entre as âncoras, só na zona
da linha: não desenha por cima de um oclusor (reaproveita o pixel da própria
linha), e um pixel que sai de cima de outra peça herda a cor dos vizinhos e fica
registado como inferido. Depois julga outra vez com a observação reaplicada à
imagem nova. É um candidato, não arte aprovada. A cor é **declarada** (`--color`,
ou as `colors` do seletor da região) e vai para todo o pixel da linha final, salvo o
que já é da família declarada; sem ela o reparo é `inconclusive` — com o miolo e o
contorno na mesma seleção, a maioria era o preto. `--core`/`--core-box` separam o
miolo, e o resto da região da linha (o contorno) fica protegido; `--mode fill` pinta o
miolo tal como está, sem redesenhar o percurso (ADR 0093).

Ordem que o relatório recomenda: aprovar a forma simples da arma e a mão antes do
detalhe; reparar a menor unidade funcional inteira (a corda com as duas pontas, a
espada com a mão, o escudo com a pega e o antebraço); só animar depois de uma
prova estática convincente. A prova do [arqueiro](research/2026-10-24-forja-armas/README.md)
é o exemplo completo.

## A cor no espaço: o que o lint raster não via

Paleta certa e nenhum pixel sem vizinho opaco não querem dizer cor organizada: um
ponto de cor cercado de pixels opacos passava sem aviso, e 16 pontos espalhados
davam as mesmas respostas que os mesmos 16 pixels num bloco
([fixtures](research/2026-10-25-forja-pixels-cores/pacote/evidencias/scatter.png)).
A Forja conta agora a cor por componentes ligados, com 4 e com 8 vizinhos (com 4,
uma diagonal de 1 px parte-se em pedaços), e cada componente de 1–3 pixels é um
candidato com descritores e um estado:

| Estado | Quando |
| --- | --- |
| `protected` | toca a zona protegida (`--protect` ou as regiões presas de um plano) |
| `expected` | está numa região com papel de acento declarado: `eye`, `mouth`, `brow`, `nose`, `highlight`, `seam`, `string`, `tip`, `buckle`, `particle`, `flower`, `spark`, `accent` |
| `inconclusive` | ligado só pela diagonal (um traço: analisar, nunca apagar) ou numa região de incerteza alta |
| `review` | fragmento sem papel conhecido: suspeita com evidência, não defeito confirmado |

O lint traz este diagnóstico (`coherence`) e uma linha `info` (`fragments`) que não
chumba nem entra no prompt; os vereditos ganham o eixo `color_coherence`. Por
região: S8 (fração de pixels em singletons N8), F (componentes por 100 pixels) e U
(fragmentos a rever); com área zero a taxa é `n/a`. O limite de 1–3 pixels é o
ponto de partida do relatório, por calibrar (Q-281); nenhuma percentagem apaga
pixels.

```bash
forja cores sprite.png --kind royal_80 -o build/forja/x                    # diagnóstico e imagem dos candidatos
forja cores sprite.png --observation regioes.json --plan cores.json -o build/forja/x   # agrupar por região
```

A observação é a mesma `forja.observation/1` do equipamento (regiões marcadas numa
imagem, com o hash dela), com `material` e `role` opcionais por região. O plano
`forja.cores/1` diz que regiões ficam presas (`lock`), que rampa vale em cada região
editável (contida na paleta mestra; sem rampa, a região não muda) e onde se agrupa
(`group`, que pede uma rampa). Um teto global de cores e o dither num personagem são recusados. Um
fragmento só se funde com as quatro provas locais do relatório: dentro da zona
editável e longe do que está preso, o alfa igual, sem ser a cor do contorno nem um
traço diagonal, sem juntar duas massas que o desenho separa, e na cor da rampa que
tem a maioria estrita da vizinhança; na dúvida fica, com as alternativas escritas.
O resultado prova E(P) = 0 (nada preso mudou), zero mudanças fora da zona, o alfa
igual e C(R) (as fronteiras entre materiais diferentes continuam com cores
diferentes), e escreve o candidato a 1× e a 8×, antes/depois/diferenças (a
magenta), as zonas e os candidatos antes e depois. `ok` só prova o que não mudou;
a leitura a 1× e no jogo é do dono. A prova do
[arqueiro](research/2026-10-25-forja-pixels-cores/README.md#o-arqueiro-a-prova-pequena-da-22)
é o exemplo completo.

Com plano, o resultado diz também o **material**: um pixel preso fora da rampa da sua
região (a lâmina cuja caixa apanha a mão) ou uma fronteira perdida deixa `material:
pending`, mesmo com `ok` — revê-se o seletor, não se tira a proteção. E o banding
(`banding.py`, a definição do *Pixel Fixer*, TU Delft 2025): dois segmentos de cores
diferentes, 2+ px, vizinhos pelo lado comprido e com as pontas alinhadas, sem contorno
nem vazio — suspeita, como os fragmentos, por calibrar (Q-283).

A proteção (`--protect` no `forge` e no `sheet`) vale até ao PNG final: repõe-se
depois da paleta e do contorno, o contorno não entra num pixel vazio protegido e a
garantia mede-se nas posições finais — numa prancha, em cada quadro exportado, depois
do `--deflicker` (que não estabiliza um pixel protegido) e do `--lock`. Uma cor protegida que a paleta obrigatória
não tem fica exata e é o erro `protect_conflict`. `--colors N` com uma paleta dá
N cores da própria paleta (as protegidas e o preto do contorno entram sempre); se
não cabem, é o erro `colors_budget`.

## Recuperar antes de proteger: autoridade, edição local e encerramento

A [solução de 27/10](research/2026-10-27-forja-fidelidade/README.md) separa duas etapas que não usam o mesmo ciclo. A
**recuperação** reconcilia o conceito com a grade (80×80 para o Rei e o Arqueiro, 64×64 para o Escudeiro): massas,
rosto, materiais, equipamento — é desenho, e o que sai é uma adaptação em revisão. A **edição local** conserva um mestre
já aprovado e muda só a zona autorizada. Proteger o último resultado rejeitado congelaria a descaracterização.

1. **Registo de autoridade** (`forja.refs/1`, `forja refs`): o conceito, cada adaptação e cada versão rejeitada, pelo
   hash dos pixels, com o estado (`concept`, `adaptation_in_review`, `approved`, `rejected`), a origem e de onde
   deriva. `approved` e `rejected` dizem quem decidiu e quando; a Forja acrescenta estados e **nunca escreve
   `approved`** — é uma linha do dono, à mão. A última saída não substitui a referência só por ser mais recente.
2. **O pedido diz o estado.** `plan`/`auto` com `--refs`: só o mestre registado vai como «the APPROVED design»; a
   adaptação em revisão diz «IN REVIEW and NOT approved»; `--concept` anexa o conceito de autoridade (o rosto, as
   proporções e os materiais a redesenhar na grade); uma rejeitada, ou uma fora do registo dado, não entra. O plano diz
   a fase (`authority.stage`: `recovery` ou `from_master`).
3. **O que chega confere-se nos dois caminhos.** O `forge` e o `sheet` com `--expect` fazem a conta do `auto`
   (`expectation.py`): um tamanho que não é o pedido invalida o contrato e fica escrito em `expectation`; um pedido
   nativo só é lido a 1× com o tamanho certo.
4. **A edição local parte do mestre.** `forja inpaint --refs` recusa uma versão rejeitada e o conceito **antes** do
   pedido pago; o resultado leva o estado e o hash do mestre e `delivery` (o que falta). Um retorno noutro tamanho para
   a tentativa (`stopped: size_mismatch`, com o job): repete-se só a zona, nunca o personagem inteiro.
5. **O encerramento só lê.** `forja verify candidato.png --master mestre.png --box … --protect … --kind … [--refs …]
   [--cores …] [--equip …]` repete a prova contra o mestre depois de qualquer acabamento e responde às quatro condições:
   corresponde ao conceito, contrato e materiais, preservado fora da mudança, revisão registada. `ok` diz que nada
   falhou no que se mediu; `deliverable` só com a aprovação do dono **desta imagem exata** no registo — um pixel mudado e
   volta a pendente. Um eixo `not_evaluated` nunca fecha.

```bash
forja refs registo.json --add rei-v3.png --state adaptation_in_review --origin "conceito + mao" --by Claude
forja inpaint arqueiro-mestre.png --refs registo.json --mask arco-e-mao.png --protect 38,23,49,38 \
  --method replace --palette empire --change "Repair only the bow and grip inside the mask." --max-calls 1 -o cand.png
forja verify cand.png --master arqueiro-mestre.png --mask arco-e-mao.png --protect 38,23,49,38 --kind royal_80 \
  --refs registo.json
```

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
  desliga) e `--protect x0,y0,x1,y1` guarda uma caixa até ao PNG final. Uma
  imagem sem grade com mais do dobro da tela recusa-se logo (`no_grid`): não é
  pixel art nesta escala, e limpá-la levava minutos para pedir a coisa errada.
- **Animação.** `prompt --tags walk` (ou `idle,walk`) pede a prancha com as
  contagens e notas da Animation Bible → `sheet`. A Forja conta as figuras
  reais contra as pedidas e **não inventa** um quadro em falta. Com o
  `expect.json` (ou `--layout CxL`) cada célula pedida é recortada com a sua
  própria máscara, e figuras que se tocam continuam separadas; uma mancha vai para
  a célula onde está a maior parte dela (a ponta de uma lança que entra na vizinha
  volta à figura dona) e o que fica dividido corta-se pela linha — as duas saem no
  relatório (`cell_crossing`, aviso) com o pedido ao gerador; sem grelha, a
  separação automática precisa de espaço vazio entre figuras. Escala e paleta
  comuns; `--same-height` mede cada figura na sua própria grade (pixels de
  tamanhos diferentes na mesma prancha) e não estica nada — um agachar continua
  mais baixo. Com a grelha, cada figura **fica onde estava na sua célula** e só o
  chão comum vai ao pivô (`--align preserve`): um salto continua no ar, um
  agachar não cresce, uma flor cresce da mesma raiz. `--align feet` alinha cada
  quadro pelo próprio apoio e o relatório diz que a deriva zero daí é imposta.
  Um quadro repetido de propósito declara-se: `--hold 3:200:antecipação`.
  A revisão separa `contract_valid` (contagem, tela, paleta, nada cortado), os
  indícios de movimento (quadros todos iguais — único que obriga a gerar de novo
  —, repetidos sem declaração, salto sem intermédio, parte que some) e a
  aprovação do dono. Ordem e continuidade de braços e mãos só se veem a olho.
  `--deflicker 0.05` só corrige dentro de `--static x0,y0,x1,y1` (caixas
  confirmadas paradas) e nunca em `--action` (o olho que pisca, a boca, a chama):
  uma vizinhança deslocada é movimento e fica; sem `--static`, nada muda e o
  relatório diz quantas mudanças ficaram por avaliar (o `drift_threshold` do
  PixelLab compara com o primeiro quadro e não é este controlo); `--lock x0,y0,x1,y1`
  cola o rosto do quadro de referência em todos os quadros (o "fixed head" do
  PixelLab); `--mirror` exporta a esquerda como espelho, contado como espelho.
- **Corrigir uma parte.** `forja inpaint sprite.png --box x0,y0,x1,y1 --change "…"`
  (ou `--mask zona.png` para uma zona qualquer) manda a imagem ampliada sobre uma
  cor de chave que não existe no sprite nem na paleta, com máscara, ao gpt-image;
  volta pela grade conhecida (outro tamanho é erro) e compõe: fora da zona os
  bytes ficam idênticos; dentro, o que voltou igual ao enviado fica com os bytes
  originais (um eco devolve o sprite exato, azul e transparência incluídos).
  `--method add|replace|remove` declara a composição: `add` só acrescenta (o
  objeto antigo fica por baixo do que vier transparente — é o que deixava o
  chapéu velho no guia do PixelLab), `replace` manda na zona, `remove` tem de
  tirar tudo o que lá estava. `--protect x0,y0,x1,y1` recusa uma zona que toque
  essa caixa. As máscaras seguem a convenção de cada gerador (OpenAI: alfa 0
  edita; PixelLab: branco gera, preto preserva). Com `--refs`, só sobre um mestre ou
  uma adaptação registada; um tamanho errado para a tentativa; depois, `forja verify`.
- **Corda, fio, vazio entre partes.** O contorno global engrossa uma linha de
  1 px para 3 e fecha um vazio de 2 px. `forge --bare x0,y0,x1,y1` (no recorte
  nativo) declara uma zona onde o contorno não entra e que o lint não conta na
  parte da borda com contorno. É uma exceção escrita no relatório, por decidir
  pelo autor como regra de arte (Q-272).
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
| `clean` | Alfa binário, pixels soltos, furos, ruído de cor, cluster mínimo (8 vizinhos; `--connectivity 4` no cenário), pixel perfect |
| `quantize` | Paleta (OKLab) ou N cores, dither ordenado opcional (`--strength 0` é sem dither) |
| `outline` | Contorno exterior, interior ou seletivo; ou tirá-lo |
| `fit` | Pousar na tela e no pivô do contrato |
| `scale` | Ampliação inteira, Scale2x, rotação RotSprite, redução por voto |
| `anim` / `aseprite` | Quadros PNG → tira, JSON do Aseprite, `.aseprite`, GIF/APNG, SpriteFrames |
| `lock` / `motion` | Travar o rosto; respirar, piscar, dissolver, empurrão |
| `tileset` / `seams` | Conjunto Wang 16 + TileSet do Godot; conferir emendas |
| `palette` | Mostrar, converter, extrair, rampa, fundir cores próximas |
| `prompt` / `plan` / `generate` / `auto` / `inpaint` | O lado do gerador: pedir, planear sem rede, gerar com job e teto |
| `equip` / `line` | Vereditos de equipamento contra o manifesto e a observação; a corda refeita na máscara, na cor declarada |
| `refs` / `verify` | O registo de autoridade das referências; reconferir um candidato contra o mestre, só a ler, e dizer se a entrega fecha |
| `cores` | A cor no espaço: fragmentos N4/N8 e o estado de cada um; com plano, rampas por material e agrupamento só nas regiões editáveis |
| `jobs` | Pedidos pagos de uma pasta: ver, retomar (só consulta), cancelar |
| `prova` / `mcp` / `kinds` | A prova, o servidor MCP, os contratos |

Todos os comandos imprimem JSON. O código de saída é 0 quando o resultado
cumpre, 1 quando há achados de erro e 2 quando o pedido é inválido (também um
ficheiro que não é imagem).

## O que a Forja faz por dentro

- **Grade.** Uma ampliação exata por vizinho mais próximo mede-se, não se estima:
  as colunas e linhas onde a imagem muda dão o período (o máximo divisor comum das
  distâncias) e a fase, mesmo num recorte que não começa na grade. Senão: perfil
  de bordas por eixo; período pela autocorrelação dos dois
  eixos juntos, com o pico alargado contra células desiguais; afinação
  fracionária por pente de contraste (dentes nas linhas menos meios entre elas:
  múltiplos e submúltiplos perdem); linhas por uma reta refeita por mínimos
  quadrados com as bordas confirmadas e interpolação nas zonas lisas.
- **Amostragem.** Cada célula vota a cor dominante no miolo (sem a borda
  suavizada); uma cor chapada sai igual, uma ruidosa sai limpa. `--method mode`
  toma só a cor exata mais frequente, sem misturar (o `scale --down` usa-o). A
  grade de um recorte mede-se antes da máscara da figura.
- **Fundo.** Alfa, chave (a cor mais longe da paleta do projeto, escolhida pelo
  prompt) ou fundo liso por enchimento a partir da borda, na resolução nativa.
- **Cor.** OKLab para todas as distâncias; k-means sem sorteio; dither
  posicional entre as duas cores mais próximas. A distância perceptual não diz se
  um pixel é pele, pano ou fundo: isso vem das regiões e das rampas (`cores`).
- **Exportação.** `.aseprite` escrito pela especificação pública e relido pelo
  leitor do projeto (`tools/aseprite_source.py`); JSON no formato do CLI do
  Aseprite; `.tres` do Godot carregados no motor fixado pelo teste opcional. As
  direções das tags (`reverse`, `pingpong`, `pingpong_reverse`) saem na ordem
  em que tocam, cada quadro com a sua duração. Um escritor e um leitor nossos
  podem partilhar um erro: abrir no aplicativo continua por registar.

## Estados e limites

- Uma imagem forjada é **adaptação de imagem gerada**. A proveniência grava a
  entrada, o prompt, o gerador e os parâmetros, com `artistic_approval: false`
  e `manual_review: pendente`. Cumprir o contrato não é aprovação artística: as cinco
  fixtures rejeitadas de 27/10 passam no lint. A aprovação vem só do registo do dono
  (`forja.refs/1`), para a imagem exata, e é o que o `verify` lê.
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
- A geometria do equipamento só mede o que foi observado: sem regiões marcadas,
  `not_evaluated`. A identidade (mesmo personagem, mesmo objeto da referência) e a
  continuidade no tempo (arma que troca de mão, peça que some entre quadros com
  equipamento) ainda não têm verificação: continuam a olho, quadro a quadro.
- O diagnóstico de cor não vê planos de luz, rampas nem curvas (o banding, desde
  27/10, conta-se como suspeita), e não
  sabe o que é intencional sem uma região anotada: `review` é suspeita. As
  anotações da prova do arqueiro são do agente; as do dono são as que contam
  (Q-281). Os efeitos (`fx`) ficam `not_evaluated` até haver política para eles.
