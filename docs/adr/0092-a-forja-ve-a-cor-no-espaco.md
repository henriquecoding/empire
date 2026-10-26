# ADR 0092 — A Forja vê a cor no espaço, protege até ao PNG final e não congela o movimento

- Estado: aceite
- Data: 2026-10-26
- Secção do dossiê: §01 e §22 (a unidade gráfica, a paleta, dois tons por material, o contorno, o dither)
- Complementa: ADR 0088 (a Forja), ADR 0089 (pede uma vez e mede) e ADR 0091 (o equipamento), que acrescenta um eixo
  aos sete vereditos dela; a Asset Bible §1 não muda
- Tarefa: [FORJA-04](../backlog/FORJA-04.md)
- Origem: o [relatório de 25/10](../art/research/2026-10-25-forja-pixels-cores/RELATORIO.md), o dossiê dos 200 vídeos
  da PixelLab e o pacote de provas, com o pedido do dono de 26/10: *«Trabalhe densamente analisando e aplicando esses
  arquivos ao meu jogo, faça por etapas, não tenha pressa, faça bem feito»*

## Contexto

O lint da Forja via o alfa, a paleta e o contorno; o detetor `orphans` só apanhava um pixel sem vizinho opaco. Duas
imagens com o mesmo histograma — 16 pontos de cor espalhados num corpo ou os mesmos 16 pixels num bloco — passavam com
zero erros e zero avisos, e a limpeza não mexia em nenhuma. O relatório reproduziu mais quatro lacunas com os módulos
reais, e todas continuavam na `main` de 26/10: `protect` valia na limpeza e perdia-se na paleta (um 105 protegido saía
100); com uma paleta dada, `--colors 2` acabava com três cores sem aviso; `blink` reabria um olho fechado de propósito
e `deflicker` igualava o segundo quadro ao primeiro numa faixa que andou uma coluna, porque comparavam a mesma
coordenada; `min_cluster`, com 4 vizinhos, apagava uma diagonal válida de oito pixels; e a força 0 do dither pintava
meio xadrez. O comentário do `deflicker` dizia-o equivalente ao `drift_threshold` do PixelLab, que compara com o
primeiro quadro e em que zero corrige tudo.

## Decisão

1. **A cor no espaço é uma pergunta própria** (`clusters.py`). Contam-se os componentes de cor com 4 e com 8 vizinhos;
   cada componente de 1–3 pixels é um candidato com descritores (área, caixa, peças N4, interior, distância à
   silhueta, cor dominante à volta e contraste, regiões que toca) e um estado: `protected` (zona protegida),
   `expected` (região com papel de acento declarado: olho, boca, brilho, corda, ponta, fivela, partícula…),
   `inconclusive` (ligado só pela diagonal — um traço a analisar, nunca a apagar —, ou região pouco fiável) e `review`
   (fragmento sem papel conhecido: suspeita com evidência, não defeito). Por região: S8, F e U do relatório; com área
   zero a taxa é `n/a`, não 0. O que não se mede (planos, banding, rampas, curvas, tempo) diz-se.
2. **Um eixo novo nos vereditos, `color_coherence`**, ao lado dos sete da ADR 0091 e sem média: `pass` sem fragmentos
   por rever, `needs_review` com algum, `inconclusive` só com traços ou regiões incertas, `not_evaluated` numa imagem
   vazia e nos efeitos (partículas e padrões têm política própria, por decidir). Nunca bloqueia nem pede outra geração.
   O lint traz o diagnóstico e uma linha `info` (`fragments`) sem frase para o gerador: o contrato raster e o
   `prompt_feedback` das duas fixtures do relatório ficam iguais, como devem.
3. **A proteção vale até ao PNG final** (`guard.py`). Os pixels de `--protect` repõem-se depois da paleta e do contorno
   forçado, o contorno não entra num pixel vazio protegido e E(P) mede-se no fim, nas posições finais (contorno,
   cluster e tela). Uma cor protegida fora da paleta obrigatória fica exata e é um erro `protect_conflict`; nunca se
   declaram as duas garantias cumpridas.
4. **O orçamento de cores nunca se cala** (`quantize.apply`). Com paleta e `--colors N`, sai um subconjunto de N
   cores da própria paleta, com as protegidas e o preto do contorno obrigatórios; se não cabem, o orçamento não se
   aplica e é um erro `colors_budget`. O relatório diz o pedido, o aplicado, as cores escolhidas e as que saíram.
   O `max_colors` do contrato continua a ser conferido pelo lint, não imposto.
5. **Cor por material só dentro da paleta autorizada, e agrupar só com prova local** (`materials.py`, `forja cores`).
   Um plano `forja.cores/1` diz que regiões ficam presas, que rampa vale em cada região (contida na paleta mestra) e
   onde se agrupa; uma região sem rampa não muda; um teto global e o dither num personagem são recusados. Um fragmento
   funde-se só dentro da zona editável, longe do que está preso, sem mexer no alfa, sem ser a cor do contorno nem um
   traço diagonal, sem juntar duas massas que o desenho separa e com a maioria estrita da vizinhança numa cor da rampa;
   na dúvida fica, com as alternativas escritas. O resultado prova E(P) = 0, zero mudanças fora da zona, o alfa igual e
   C(R), as fronteiras entre materiais diferentes que deixariam de ter cores diferentes.
6. **O tempo diagnostica antes de corrigir** (`temporal.py`). Cada mudança pequena e cada piscar A → B → A é um
   candidato: `expected` numa região de ação declarada (`--action`), `motion` quando a vizinhança 3×3 com estrutura
   está deslocada no quadro anterior, `review` numa região declarada parada (`--static`) e `inconclusive` fora dela.
   `--deflicker` só corrige `review`; **sem `--static`, nada muda** e o relatório diz quantas mudanças ficaram por
   avaliar. O `drift_threshold` do PixelLab não é este controlo, e o código já não o diz.
7. **Área, conectividade e bloco são três medidas.** `min_cluster` funde com 8 vizinhos por omissão (4 só por escolha,
   no cenário) e respeita caixas protegidas; `footprint` mede área, caixa e bloco k×k; o lint do cenário mantém o erro
   por área e acrescenta uma linha `info` (`blocks`) quando uma mancha tem área mas não tem bloco — a regra de bloco é
   decisão do dono (Q-277). A força do dither é a amplitude da matriz: 0 é sem dither.

## Alternativas consideradas

- **Apagar todo o pixel isolado, ou uma mediana no sprite inteiro.** Apagaria olhos, brilhos, pontas e diagonais; o
  relatório (§5, §21) e o guia da Forja (F05) recusam-no.
- **Uma percentagem global de pixels soltos como limite.** Não há calibração (o conjunto de 48 imagens e 8 sequências da
  §18 não existe); um número inventado faria do lint um juiz de beleza.
- **Fazer de `color_coherence` uma falha do contrato raster.** Mudaria a validade de assets que cumprem a Asset Bible e
  poria no prompt uma frase por cada olho de um pixel. Fica um eixo separado, que informa.
- **Um otimizador espacial (custo de fidelidade + fragmentação + material + tempo).** O relatório pede-o depois de haver
  diagnóstico, máscaras, um mapeamento regional determinístico e um conjunto de referência revisto (§12.5).
- **Comparar quadros na mesma coordenada com um limiar mais baixo.** A faixa de baixo contraste mostra que o problema é
  de correspondência, não de limiar.
- **Ferramentas externas de recuperação de grade (Pixel Art Fixer, proper-pixel-art).** Resolvem outro problema e
  seriam dependências novas; o relatório pede auditoria antes de qualquer adoção.

## Consequências

- Nenhuma dependência nova. Módulos novos: `clusters.py`, `guard.py`, `materials.py`, `temporal.py` e `cmd_cores.py`
  (`forja cores`, também no servidor MCP); `verdicts.AXES` passa a ter oito eixos.
- **Muda de comportamento:** `forja sheet --deflicker` já não corrige sem `--static`; `forja clean --cluster` já não
  funde uma diagonal de 1 px (use `--connectivity 4` no cenário); `--colors` com paleta aplica-se como subconjunto; a
  proteção pode transformar um sucesso calado num erro de conflito; `quantize --strength 0` deixou de pintar xadrez.
  O teste antigo do `deflicker` foi reescrito para a regra nova.
- O mapeamento de uma caixa do recorte nativo para o PNG final usa o deslocamento real do contorno (antes somava um
  pixel fixo, que errava com o cluster 2 do cenário).
- A prova do arqueiro e as provas do pacote correm em [prova_cores.py](../art/research/2026-10-25-forja-pixels-cores/prova_cores.py)
  e os números que o README cita estão em `tools/forja/tests/test_cores.py`.
- Fica por fazer: o conjunto de calibração e as anotações revistas por um humano; a política de efeitos; a
  correspondência temporal por regiões anotadas (âncoras) além da vizinhança deslocada; o rei e o escudeiro com regiões
  e plano; a interface de revisão que marca um detalhe como intencional e o reutiliza (§19, incremento 6). Ver FORJA-04.
- Se a decisão for revertida: tirar os cinco módulos novos e os testes deles, voltar `lint.py`, `verdicts.py`,
  `pipeline.py`, `quantize.py`, `cleanup.py`, `sheetforge.py`, `cmd_make.py`, `cmd_image.py`, `review.py`,
  `geometry.py`, `cmd_equip.py`, `annotate.py`, `cli.py` e `mcp_server.py` ao commit anterior — e a Forja volta a não
  distinguir os 16 pontos do bloco e a reabrir o olho fechado.
