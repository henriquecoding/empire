# Auditoria da Forja — 27/10/2026

Pedido do dono, a 27/10/2026: *«Elabora uma densa e extensa auditoria na forja, encontre falhas e coisas a melhorar
e refinar, depois busque na web como fazer isso e aplique»*. Código auditado: `0fea413` (a `main` depois do PR #126).
Tarefa: [FORJA-07](../../../backlog/FORJA-07.md); decisão: [ADR 0094](../../../adr/0094-a-forja-le-como-se-ve.md).
Guia: [FORJA.md](../../FORJA.md). Auditorias anteriores: [23/10](../2026-10-23-pixellab/AUDITORIA-FORJA-CLAUDE.md)
(F01–F09) e [26/10](../2026-10-26-forja-auditoria/README.md) (A01–A12).

**Em resumo:** dezasseis achados (B01–B16), todos reproduzidos sem rede, sem chave e sem gasto; quinze reparados
com testes que falham no código auditado, e o décimo sexto é manutenção (a especificação do PixelLab mudou hoje). Os
três mais graves custam dinheiro ou dão a cor errada sem aviso: o conector do Gemini devolvia as *imagens de
pensamento* — rascunhos que o modelo desenha antes da final — e o `auto` forjava a primeira, depois de pagar (B01); o
voto que escolhe a cor de cada célula partia uma cor ruidosa na fronteira de um balde de 16 níveis e elegia a minoria,
e 86 das 112 cores da paleta estão a 3 níveis de uma fronteira (B02); e dois processos na mesma pasta faziam dois
pedidos pagos com um teto de um (B03). Uma observação medida fica para o dono (O1, [Q-286](../../../QUESTIONS.md)): o
preto do contorno, com o ruído do gerador, cai no `#0B0B0B` porque o L do OKLab é íngreme junto ao preto; a correção
de Ottosson acerta-o, mas muda a cor escolhida em 7% do espaço sRGB, e a ADR 0088 fixa o OKLab. Nenhuma chamada
paga, nada em `art/`, nenhuma dependência nova, nenhuma aprovação artística.

## Como se auditou

| Passo | O que se fez | Resultado |
| --- | --- | --- |
| Leitura | Os 67 módulos de produção (9 546 linhas no `0fea413`), um a um: grade, amostragem, fundo, limpeza, paleta, contorno, lint, pranchas, exportação, prompts, plano, jobs, conectores, MCP, equipamento, cor e referências | As suspeitas que as sondas confirmaram ou desmentiram |
| Pesquisa na web | Especificação MCP 2025-11-25 (transportes, ferramentas, esquema) e o registo de 2025-06-18; JSON-RPC 2.0; guia de geração de imagens do Gemini e da OpenAI; a especificação OpenAPI do PixelLab, relida ao vivo; Ottosson (gamut clipping e Lr); o histograma deslocado médio de Scott; atomicwrites e locks entre processos; Pillow (`exif_transpose`, `ImageCms`) | [Fontes](#fontes), lidas a 27/10/2026 |
| Sondas | [`sondas.py`](sondas.py): dezasseis cenários e a medida de O1, com transporte falso, sem rede nem gasto, que registam o comportamento (não o julgam) | [antes](observacoes-antes.json) (`0fea413`) e [depois](observacoes-depois.json), do mesmo script |
| Suíte e portões | `make forja` antes e depois; a suíte também em Python 3.11 com o Pillow 12.3.0 fixado (o do CI); `pyflakes` nos ficheiros mudados | 294 testes (3 saltados: sem Godot) → 318; prova 11/11; as provas de 24/10, 25/10 e 27/10 sem deriva nos JSON |
| PixelLab ao vivo | `contrato.py` contra `https://api.pixellab.ai/v2/openapi.json` (GET sem chave) | [`contrato-2026-10-27.json`](../2026-10-26-pixellab-engenharia-reversa/contrato-2026-10-27.json): só mudou a descrição de `POST /generate-font-pro`; 63 limites, 0 divergências |

## Achados

P1: dá um resultado errado ou paga duas vezes. P2: cala-se, perde trabalho, ou o agente não consegue usar o que a
ajuda promete. P3: contrato ou superfície. "Antes" e "depois" são do mesmo cenário em [`sondas.py`](sondas.py).

| ID | Prioridade | Problema | Antes | Depois | Testes |
| --- | --- | --- | --- | --- | --- |
| B01 | P1 | Gemini: as imagens de pensamento saíam como a imagem paga | 3 imagens; a primeira é o rascunho | 1 imagem, a final; `thought_images_skipped: 1` | `test_auditoria_ii_rede.GeminiThoughtTest` |
| B02 | P1 | O voto parte a cor ruidosa na fronteira de um balde | células na fronteira (σ=3): 50/50 com a cor da minoria; sprites σ=6: 40 de 2 580 pixels a mais de 6 níveis; JPEG q75: 21 | 0/50; 1; 10 | `test_auditoria_ii.VoteTest` |
| B03 | P1 | O teto não conta entre processos | teto de 1, dois processos: 2 POSTs, `budget.json` diz 1 | 1 POST; o segundo recusa (`BudgetExceeded`) antes de sair | `test_auditoria_ii_rede.BudgetTest` |
| B04 | P2 | O servidor MCP morre com JSON que não é um objeto | `[]`, `42`, `params` em lista: `AttributeError`, processo morto | `-32600`/`-32602` com id null; responde ao pedido seguinte | `McpTest` |
| B05 | P2 | O contorno que cobria metade da borda fica com 2 px nessa metade, e o lint não vê | linha do meio `#rrrrrrrrrrrr##` | `#rrrrrrrrrrrr#` | `test_auditoria_ii.OutlineGapTest` |
| B06 | P2 | A orientação EXIF é ignorada | foto 200×100 com Orientation 6 lida deitada (200×100) | 100×200; `provenance.input.opened` | `OpenTest` |
| B07 | P2 | O perfil ICC é ignorado | cinzento 128 num perfil linear lido 128 | 188, o mesmo cinzento em sRGB; um perfil sRGB fica exato | `OpenTest` |
| B08 | P2 | O hash dos pixels conta a cor escondida debaixo do alfa 0 | re-gravar o mestre a zerá-la: «a imagem mudou depois do registo» | registo válido; nenhum hash do repositório muda | `test_auditoria_ii.HashTest` |
| B09 | P2 | O registo de um pedido pago fica sem `fsync` | 0 `fsync` ao escrever um job `planned` | 2 (o ficheiro e a pasta) | `BudgetTest` |
| B10 | P2 | O stdio do MCP não é UTF-8 (Windows) | pipe em cp1252 e um ficheiro `cenários/Árvore.png`: `'charmap' codec can't decode byte 0x81`, 0 respostas JSON-RPC e uma linha que não é MCP no stdout | 2 respostas; o lint corre no ficheiro | `McpTest` |
| B11 | P3 | Uma ferramenta desconhecida é resultado, não erro de protocolo | `isError: true` | erro `-32602` | `McpTest` |
| B12 | P3 | As ferramentas não dizem o que fazem antes de ser chamadas | sem anotações nem título: o cliente não distingue o pedido pago do lint | `readOnlyHint`/`destructiveHint`/`idempotentHint`/`openWorldHint` e `title`; o `structuredContent` estudado e deixado de fora (ver abaixo) | `McpTest` |
| B13 | P3 | A bomba de descompressão não responde em JSON | *traceback*, código 1 | `{"ok": false, …}`, código 2 | `test_auditoria_ii.SurfaceTest` |
| B14 | P3 | Uma vírgula no caminho da paleta lê-o como cores | `ValueError: cor invalida` | lida do ficheiro | `SurfaceTest` |
| B15 | P3 | A rampa fora do gamut desvia o matiz | até 20,8° (`#FFD000`), 14,8° (`#2040FF`) | ≤ 0,8° | `test_auditoria_ii.RampTest` |
| B16 | manut. | A especificação do PixelLab mudou | adaptador com `1c895d3f…` | `b6dd212c…`; mudou só uma descrição; 63/63 conformes | `contrato-2026-10-27.json` |

Refinamentos sem achado próprio: o `forja_*` chamado por quem importa o servidor sem a CLI montada já não diz
«ferramenta desconhecida»; um `ResourceWarning` de ficheiro aberto nos testes; o perfil ICC de teste é escrito pelo
próprio teste (`helpers.linear_profile`), sem ficheiros do sistema.

### B01 — as imagens de pensamento do Gemini

O guia do Gemini lido hoje diz que os modelos 3.x «geram até duas imagens intermédias para testar a composição», que
não são cobradas, e que «a última imagem dentro do pensamento é também a imagem final». Na API Interactions vêm em
passos `type: "thought"`, com a imagem no `summary`; `output_image` «devolve o último bloco de imagem gerado». O
`parse` do conector chamava `find_images` sobre a resposta inteira: rascunhos e final, por ordem, e o `auto` forjava
`outputs[0]`. Agora usa `output_image` quando vem; senão, as imagens fora dos passos e das partes de pensamento (no
`generateContent`, as partes com `thought: true`), e conta as que ficaram de fora.

### B02 — o voto e as fronteiras dos baldes

O voto agrupa as cores de cada célula em baldes de 16 níveis por canal e escolhe o mais cheio. Uma cor cujo canal está
perto de um múltiplo de 16 (128, 64, 48…) divide-se, com o ruído do gerador, por dois a oito baldes, e um balde de uma
cor minoritária e limpa ganha. É o «problema da borda do balde» de um histograma: a solução de Scott (1985) é o
histograma deslocado médio — vários histogramas com a mesma largura e origens diferentes. Aqui são oito, deslocados
meio balde em cada canal; ganha o balde mais cheio de todos (no empate, o de antes), e a média faz-se na vizinhança
centrada nele, que a fronteira já não corta. Uma célula lisa, ou com duas cores exatas, sai igual a antes; as provas
de 24/10, 25/10 e 27/10 não mudaram um byte.

### B03 e B09 — o teto e o registo no disco

O `Budget` lia o `budget.json` ao abrir e escrevia-o da memória: dois `forja generate` na mesma pasta viam ambos
«0 chamadas». Agora cada conta relê o ficheiro com um lock exclusivo (`fcntl.flock` em POSIX, `msvcrt.locking` no
Windows, num `.lock` ao lado), e conferir e contar a chamada são um só passo (`reserve`). O job, escrito antes do POST
para que um pedido pago nunca fique sem rasto, era trocado de forma atómica mas sem `fsync`: numa queda da máquina o
ficheiro trocado pode voltar vazio. Agora escreve-se, faz-se `fsync`, troca-se e faz-se `fsync` da pasta — o padrão do
atomicwrites (`durable.py`).

### B04, B10, B11, B12 — o servidor MCP

O JSON-RPC 2.0 manda responder `-32600` com id null a um pedido que não é um objeto, e o MCP tirou o batch em
2025-06-18; o servidor chamava `.get` em qualquer JSON e morria com `[]` ou `42`. O MCP manda UTF-8 no stdio; no
Windows o pipe usa a página de código da consola, e o «Á» (C3 81 em UTF-8; 0x81 não existe no cp1252) matava o
servidor ao ler — com uma linha que não é MCP no stdout, que a especificação proíbe. Agora o stdin lê-se em bytes e o
stdout escreve UTF-8 com `\n`. Uma ferramenta desconhecida é erro de protocolo (`-32602`, o exemplo da própria
especificação); um erro de argumentos continua `isError`, para o modelo se corrigir. Cada ferramenta tem `title` e
anotações: `generate`, `auto` e `inpaint` saem para a rede e não se repetem iguais; `jobs` consulta e cancela no
fornecedor; `kinds`, `lint` e `verify` só leem. O `structuredContent` (2025-06-18) foi aplicado e tirado: há relatos de
que o Claude Code, quando ele vem, passa ao modelo só esse campo — e a prévia em imagem, que é a razão de as respostas a
trazerem, perdia-se ([relato num espelho das issues](https://claudeissues.com/issue/55677-mcp-tool-result-content-text-dropped-from-model-when-structuredcontent-is-also-p);
e o [SDK de C#](https://github.com/modelcontextprotocol/csharp-sdk/pull/1562), por omissão, duplica o mesmo JSON
nos dois campos). Fica para quando houver um `outputSchema` e um cliente que o use.

### B05 — o contorno que já existia

Com menos de 85% da borda a preto, o `forge` punha o anel exterior inteiro — também por fora do contorno que já lá
estava. Agora o contorno global fecha só as falhas: um pixel vazio cujos vizinhos opacos são todos da cor do contorno
fica vazio (`outline.add(..., gaps=True)`; `--outline force` continua a tirar e a pôr tudo). Com 85% ou mais nada muda,
como antes: é o que deixa uma corda de 1 px sem contorno de propósito (O2).

### B06 e B07 — abrir como se vê

A Forja aceita desenho à mão, e uma foto do telemóvel vem deitada com a etiqueta Orientation; um PNG exportado com um
perfil que não é sRGB (Display P3, Adobe RGB, o perfil do monitor numa captura) tem os números noutro espaço, e a
paleta do projeto é sRGB. A abertura aplica agora `ImageOps.exif_transpose` e converte para sRGB com o `ImageCms`
(intenção colorimétrica relativa). Um perfil sRGB, ou nenhum, não se converte: a conversão arredondaria cores
exatas. O que se fez fica em `provenance.input.opened`.

### B08 — o hash dos pixels

O registo de autoridade (ADR 0093) e as observações prendem-se a uma imagem pelo hash dos pixels RGBA. Um pixel de
alfa 0 entrava com a cor escondida, que nenhum ecrã mostra e que cada editor grava à sua maneira: o mestre aprovado,
aberto e gravado sem mudar um pixel visível, saía do registo. Agora um pixel transparente conta como `(0, 0, 0, 0)` —
a mesma regra que o `gridcheck` já seguia («o vazio conta como uma cor só»). As imagens registadas no repositório não
têm cor escondida, por isso nenhum hash gravado muda.

### B13, B14, B15 e B16

A bomba de descompressão do Pillow não é `OSError` e escapava ao JSON da CLI. A paleta inline (`#a,#b`) reconhecia-se
por ter uma vírgula, antes de ver se o texto era um ficheiro. A rampa prendia cada canal a [0, 255] fora do gamut, o
que muda o matiz; agora baixa o croma até caber, com a luminosidade e o matiz fixos — o método «preservar a
luminosidade» que Ottosson mostra ser o melhor dos simples (o contorno seletivo usa o mesmo). A especificação do
PixelLab mudou de hash a 27/10; o `contrato.py` diz que só mudou a descrição de `POST /generate-font-pro`, e o
adaptador continua conforme.

## O que fica aberto

| ID | Observação | Medida | Destino |
| --- | --- | --- | --- |
| O1 | O preto do contorno, ruidoso, cai no `#0B0B0B` | sprites com o contorno a `#000000`: 62, 317 e 39 de 588 pixels pretos errados (σ 3, σ 4, JPEG q85); com o Lr de Ottosson, 0 e as outras cores iguais; mas o Lr muda a cor escolhida em 1 459 de 20 000 cores sRGB sorteadas, em todas as luminosidades | [Q-286](../../../QUESTIONS.md) — muda a métrica que a ADR 0088 fixou |
| O2 | Uma falha no contorno com 85% ou mais da borda a preto passa calada | o lint não diz nada; o `forge` não a fecha, para não engrossar uma corda de 1 px | [Q-287](../../../QUESTIONS.md) |
| O3 | As ferramentas longas do MCP não dão progresso nem se cancelam | `forja_auto` pode esperar até 15 min por um job do PixelLab | proposta: `notifications/progress` quando o pedido traz `_meta.progressToken`, e `notifications/cancelled` entre consultas |
| O4 | Fundo transparente no `gpt-image-2` | o guia oficial lido hoje só nomeia os 2.5; fontes de terceiros dizem que o 2 não o aceita | sem mudança: a Forja pede o 2.5 por omissão, e uma recusa 4xx não é cobrada (`rejected`) |
| O5 | `imageSize` no `generateContent` do Gemini | um relato no fórum diz que é ignorado com `TEXT` nas modalidades | sem mudança: a Forja só pede 1K por esse caminho |

## Fontes

Lidas a 27/10/2026.

- MCP, [Transports](https://modelcontextprotocol.io/specification/2025-11-25/basic/transports) (UTF-8, uma mensagem
  por linha, nada no stdout que não seja MCP), [Tools](https://modelcontextprotocol.io/specification/2025-11-25/server/tools)
  (erros de protocolo e de execução, `structuredContent`, `title`), [Schema](https://modelcontextprotocol.io/specification/2025-11-25/schema)
  e o [registo de 2025-06-18](https://modelcontextprotocol.io/specification/2025-06-18/changelog) (sem batch, saída
  estruturada, `title`).
- [JSON-RPC 2.0](https://www.jsonrpc.org/specification): códigos de erro e id null num pedido inválido.
- Gemini, [geração de imagens](https://ai.google.dev/gemini-api/docs/image-generation): as imagens de pensamento, a
  última é a final, `output_image`; o relato do fórum sobre o
  [`imageSize` ignorado](https://discuss.ai.google.dev/t/gemini-3-pro-image-api-completely-ignores-imagesize-2k-parameter-node-js-sdk/110458).
- OpenAI, [geração de imagens](https://developers.openai.com/api/docs/guides/image-generation): os 2.5, tamanhos,
  máscara na primeira imagem; terceiros sobre o `gpt-image-2` ([Leonardo](https://docs.leonardo.ai/v1.0/docs/gpt-image-2),
  [WaveSpeed](https://wavespeed.ai/blog/posts/gpt-image-2-api-guide/)).
- PixelLab, [`/v2/openapi.json`](https://api.pixellab.ai/v2/openapi.json), lido pelo `contrato.py`.
- Björn Ottosson, [sRGB gamut clipping](https://bottosson.github.io/posts/gamutclipping) e
  [Okhsv e Okhsl](https://bottosson.github.io/posts/colorpicker/) (o Lr).
- D. W. Scott, *Averaged Shifted Histograms* (1985), resumido no
  [manual do Dataplot (NIST)](https://itl.nist.gov/div898/software/dataplot/refman1/auxillar/ash.htm) e no
  [pacote `ash`](https://cran.r-universe.dev/ash/doc/manual.html).
- [atomicwrites](https://android.googlesource.com/platform/external/python/atomicwrites/+/refs/heads/upstream-master/README.rst)
  (`fsync` do ficheiro e da pasta) e a [discussão do `atomicwrite` na stdlib](https://discuss.python.org/t/adding-atomicwrite-in-stdlib/11899);
  locks entre processos: [portalocker](https://portalocker.readthedocs.io/en/latest/_sources/platforms.rst.txt) e
  [filelock](https://py-filelock.readthedocs.io/en/latest/).
- Pillow, [`ImageOps.exif_transpose`](https://pillow.readthedocs.io/en/stable/reference/ImageOps.html) e
  [`ImageCms`](https://sources.debian.org/src/pillow/12.1.0-1/docs/reference/ImageCms.rst).

## Verificação

```bash
make forja                                                               # prova, suíte, provas sem deriva
python3 docs/art/research/2026-10-27-forja-auditoria/sondas.py           # o depois (ou --root <checkout> para o antes)
(cd docs/art/research/2026-10-26-pixellab-engenharia-reversa && python3 -I contrato.py --previous contrato-2026-10-26.json)
```
