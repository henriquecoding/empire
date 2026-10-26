# Auditoria da Forja — 26/10/2026

Pedido do dono, a 26/10/2026: *«Quero que faça uma auditoria na forja e veja o que pode melhorar e refinar»*.
Código auditado: `00bc2d3` (a `main` depois do PR #124). Tarefa: [FORJA-05](../../../backlog/FORJA-05.md).
Guia: [FORJA.md](../../FORJA.md). Auditoria anterior: [23/10](../2026-10-23-pixellab/AUDITORIA-FORJA-CLAUDE.md),
com os [reparos](../2026-10-23-forja-reparos/README.md).

**Em resumo:** dez falhas reproduzidas sem rede (A01–A10), todas reparadas com testes que falham no código
auditado. A mais grave é uma regressão de 26/10: a medida de "ampliação exata" só conferia blocos a partir do
canto da imagem, e numa prancha — onde cada recorte começa fora da grade — uma ampliação 10× saía "exata 2×", com
a nota "medida, não estimada": quadros cinco vezes maiores, cortados, e o contrato a falhar sem dizer porquê. A
segunda é do ciclo pago: uma imagem sem figura rebentava o `forja sheet` e o `forja auto` com um `IndexError`,
depois de o pedido já ter sido cobrado. Nenhuma chamada paga, nenhuma chave, nada em `art/`, nenhuma dependência
nova, nenhuma aprovação artística.

## Como se auditou

| Passo | O que se fez | Resultado |
| --- | --- | --- |
| Leitura | Os 61 módulos de produção (8 646 linhas no `00bc2d3`), um a um: grade, amostragem, fundo, limpeza, paleta, contorno, lint, pranchas, exportação, prompts, plano, jobs, conectores, MCP, equipamento e cor | Os achados abaixo |
| Formato `.aseprite` | O escritor (`aseprite.py`) contra o [`ase-file-specs.md`](https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md) lido a 26/10: cabeçalho de 128 bytes, quadro de 16, camada, cel comprimido, perfil de cor, tags, paleta e slice com pivô | Bate campo a campo; continua por abrir no aplicativo |
| Suíte e prova | `make forja` antes e depois | 246 testes (3 saltados: sem Godot) → 265; prova 11/11 nos dois |
| Sondas | [`sondas.py`](sondas.py): dez cenários com transporte falso, sem rede nem gasto, que registam o comportamento (não o julgam) | [antes](observacoes-antes.json) e [depois](observacoes-depois.json), do mesmo script |
| Regressões | As sondas F01–F09 de 23/10, as provas do arqueiro (24/10 e 25/10) | F01–F09 iguais (só o hash do commit muda); as duas provas passam |
| Tempos | `forge` de um `royal_64` a 1920×1920; `sheet` de 8 quadros a 2560×1280 | 3,3 s e 2,9 s; uma imagem vazia de 1920×1920, 0,8 s |

## Achados

P1: dá um resultado errado ou perde trabalho pago. P2: cala-se, ou o agente não consegue usar o que a ajuda
promete. P3: contrato ou texto. "Antes" e "depois" são do mesmo cenário em [`sondas.py`](sondas.py).

| ID | Prioridade | Problema | Antes | Depois | Testes |
| --- | --- | --- | --- | --- | --- |
| A01 | P1 | Ampliação exata medida só em fase com o canto | prancha 10× → período 2, quadros 73×151, contrato falha; recorte 6 px ao lado → "exata 2x" | período 10 e fase medidos; quadros 18×34, contrato válido; "exata 10x, fase (4,4)" | `test_gridcheck.ExactScaleTest` |
| A02 | P1 | Imagem sem figura rebenta `sheet` e `auto` | `IndexError`; `auto.json` por escrever; a 2.ª tentativa nunca sai | `found: 0`, `needs_regeneration` e o pedido ao gerador; o `auto` corrige e tenta de novo | `test_auditoria.EmptyAndStopTest` |
| A03 | P2 | O `auto` que para no teto depois de uma tentativa forjada diz "nada foi forjado" | `best: null`; um job `planned` órfão | `best: try1`, `stopped` diz o teto; o teto confere-se antes de criar o job | `EmptyAndStopTest` |
| A04 | P2 | O custo de um job retomado não chega ao teto da pasta | `--resume`: job com US$0,25, `budget.json` com US$0 | `budget.json` com US$0,25; job falhado conta como custo desconhecido | `test_auditoria.BudgetResumeTest` |
| A05 | P2 | O prompt corretivo leva português ao gerador; o tamanho errado não leva nada | "grade detetada 4.00 px, pedida 8.00 px: o gerador nao seguiu…" | "Use exactly 64x64 logical pixels… about 8x8 image pixels, not 4x4."; "The image must be exactly 1920x1920 pixels." | `test_auditoria.CorrectiveTest` |
| A06 | P2 | MCP: os argumentos "repetíveis" só aceitam um | esquema `string`; uma lista dá "argumentos inválidos" | esquema `array`; uma flag por item (uma string continua a valer) | `test_auditoria.SurfaceTest` |
| A07 | P2 | Máscara PNG sem alfa marca a imagem inteira | branco sobre preto, 9 pixels → 256 selecionados (o `inpaint --mask` editava o sprite todo) | 9; alfa se a máscara tem transparência, senão o claro | `SurfaceTest` |
| A08 | P2 | A figura que passa a fronteira da célula é cortada e colada na vizinha, calada | lança de 6 px: quadros 26×30 e 26×30, sem aviso | 32×30 (com a lança) e 12×30; `cell_crossing` no quadro dono | `test_auditoria.CellCrossingTest` |
| A09 | P3 | Um ficheiro que não é imagem dá um *traceback*, código 1 | `UnidentifiedImageError` | JSON `{"ok": false, …}`, código 2 | `SurfaceTest` |
| A10 | P3 | A altura pedida ao gerador no elenco V15 é "1-62 pixels" | "The figure must be 1-62 pixels tall" | "at most 62 pixels tall" | `CorrectiveTest` |

### A01 — a ampliação exata e a fase

`gridcheck.exact_scale` (PR #124) procurava, de 16 para baixo, o maior k em que reduzir e voltar a ampliar por
vizinho mais próximo devolvia a imagem. Só vê blocos que começam no canto. Num recorte que começa 6 px dentro de
uma grade de 10, todas as fronteiras caem em posições pares — a imagem é, de facto, uma ampliação exata 2× — e o
k=2 ganhava. O `sheet.extract` recorta cada figura com 6 px de margem a partir da caixa dela: em toda a prancha
exata (um export do Aseprite, uma prévia ampliada, uma saída do PixelLab aumentada) o recorte está fora de fase.
Antes do #124 a extração usava a estimativa, que acertava (período 10,00).

Agora mede-se pelas fronteiras: as colunas (e as linhas) onde a imagem muda; o período é o máximo divisor comum
das distâncias entre elas e a fase é a da primeira. Se todas as mudanças caem nessa grade, dentro de cada bloco
não há mudança nenhuma — o bloco é de uma cor só — e por isso a medida é exata sem outra conferência. As células
das pontas podem ser parciais. O vazio conta como uma cor (a cor escondida num pixel transparente não é desenho);
uma imagem lisa é ampliação de qualquer k e fica com a resposta de antes.

### A02 e A03 — o ciclo pago

O `sheetforge` assumia pelo menos uma figura (`anim.strip` lia `frames[0]`), e o `auto` não apanhava erros da
forja: o pedido já cobrado ficava no job, mas o ciclo morria sem `auto.json` e sem a tentativa corretiva. Agora
uma prancha sem figura é um resultado (`found: 0`, `needs_regeneration`, com o pedido "The image came back with
no figure at all…"), o achado `empty` do lint tem o mesmo pedido para uma figura só, e um erro da Forja no `auto`
fica na tentativa e para o ciclo (outra geração pagaria o mesmo erro). O resultado do `auto` olha para a última
tentativa **forjada**, não para a última entrada, e diz porque parou.

### A04 — o teto

O `forja jobs --resume` chamava `jobs.execute` sem o teto, e o custo dito pelo fornecedor ficava só no job. Agora
abre o `budget.json` da pasta, se existe (`Budget.saved`). Um job que o fornecedor dá por falhado fecha o custo
como desconhecido; o prazo esgotado e o estado remoto estranho continuam abertos (a retomada ainda os fecha).

### A05 e A10 — o que o gerador lê

O pedido é inglês porque os geradores o seguem melhor (`prompts.py`), mas o achado `grid_not_followed` ia para o
prompt com o `detail` português. Cada achado do `auto` tem agora um `hint` inglês com a medida, e o `size_mismatch`
também. No elenco V15 a altura útil é `[1, 62]` — só um teto —, e o lint pedia "1-62 pixels tall".

### A06, A07 e A09 — a superfície do agente

O esquema MCP derivava do argparse e tratava um `action="append"` como texto; `_argv` passava uma lista como um
argumento posicional a mais. A máscara de observação e do `inpaint --mask` lia sempre o alfa: uma máscara sem
transparência (a convenção do PixelLab, branco gera, e a de quase todos os editores) marcava tudo. A CLI só
apanhava `FileNotFoundError` entre os erros de ficheiro.

### A08 — a fronteira da célula

O `find_cells` cortava cada figura pela linha da sua célula. Isso separa figuras que se tocam, mas também cortava a
ponta de uma lança que entrava na vizinha — e a ponta entrava, calada, no quadro do lado. Agora (`cells.py`) as
manchas contam-se por célula numa versão reduzida da máscara: quase toda numa célula (fora < 25 %) vai inteira
para ela; dividida, corta-se pela linha, como antes. As duas ficam no quadro (`cell_crossing`) e no lint (aviso),
com o pedido "Keep every pose completely inside its own cell…". Na grelha, cada figura usa só a sua máscara
(`exact`): a caixa de uma figura que ganhou a ponta da vizinha pode conter outra.

### Refinamentos sem achado

- `resample`: uma grade de uma célula por pixel devolve a imagem binarizada em vez de votar célula a célula
  (conferido igual ao voto, pixel a pixel, com alfas 0, 60, 127, 128, 200 e 255).
- `snap`: um recorte sem nenhum pixel opaco fica 1×1, em vez da imagem inteira a passar pela limpeza e pelo lint.
- `Palette.__contains__` refazia um conjunto com as 112 cores a cada chamada.
- `_common_canvas` passou do `sheetforge` para `placement.common_canvas`, onde vive a pergunta "onde fica cada
  quadro" (o `sheetforge` precisava das linhas para as travessias e fica abaixo das 250).

## O que fica aberto

| # | Observação | Porque não se mexeu |
| --- | --- | --- |
| O1 | A [forense de 26/10](../2026-10-26-pixellab-engenharia-reversa/forense.py) tem a sua cópia do `exact_scale` alinhado ao canto: numa imagem pública com margem fora de fase, a coluna `exact_scale` dela subestima o k | As imagens de terceiros não entram no repositório e pedem rede; repetir com `gridcheck.exact_grid` |
| O2 | Os artefactos do arqueiro de 24/10 (FORJA-03) estão atrás do código desde o FORJA-04: `prova_arqueiro.py` reescreve-os com o eixo `color_coherence` e não falha — só compara as medidas dela | É o registo do que se viu a 24/10; refrescá-lo é decisão do dono |
| O3 | `sheet --same-height` redimensiona com LANCZOS antes da grade, o que borra os blocos | Opção explícita e documentada; trocar pela grade própria de cada figura é escolha de comportamento |
| O4 | Uma imagem grande sem grade (tratada como nativa) passa pela limpeza e pelo lint em Python, pixel a pixel: dezenas de segundos a 1920×1920 | Só o caso vazio e a amostragem ficaram rápidos; vetorizar a limpeza é outro trabalho |
| O5 | Uma figura cortada pela tela recebe também "Surround the whole silhouette with… outline" e "Keep clear empty space… image border": duas frases para uma causa, e "image border" fala da tela, não da imagem gerada | Avisos verdadeiros; juntar as frases pede uma regra de prioridade entre achados |
| O6 | O `forge` amostra a imagem duas vezes (a pureza no `gridcheck` e o recorte no `snap`), ~0,6 s a 1920×1920 | Pouco para o código que pede |
| O7 | O piloto pago continua por executar ([piloto.json](../2026-10-23-forja-reparos/piloto.json)) | Sem chaves nem teto aprovado |

## Repetir

```bash
python3 -m unittest discover -s tools/forja/tests -t .                     # 265 testes (GODOT=<motor> para os do Godot)
python3 -m tools.forja prova                                                # 11/11
python3 docs/art/research/2026-10-26-forja-auditoria/sondas.py --out /tmp/depois.json
python3 docs/art/research/2026-10-23-forja-reparos/sondas_depois.py         # F01-F09, iguais
```

As sondas usam transportes falsos e chaves sintéticas (`synthetic-test-token`) num ambiente isolado do processo;
nenhuma sai para a rede. O `observacoes-antes.json` foi gravado no `00bc2d3`, antes de qualquer reparo.
