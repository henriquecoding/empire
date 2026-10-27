# ADR 0094 — A Forja mede o que a amostragem perde e prende cada pedido à autoridade da pose

- Estado: aceite
- Data: 2026-10-27
- Secção do dossiê: §01 e §22 (a unidade gráfica, a paleta, o contorno); o guia de produção de personagens
- Complementa: ADR 0088 (a Forja), ADR 0089 (pede uma vez e mede), ADR 0093 (recuperar antes de proteger); a Asset
  Bible e os contratos de runtime não mudam
- Tarefa: [FORJA-07](../backlog/FORJA-07.md)
- Origem: a [auditoria de 27/10, revisão 2](../art/research/2026-10-27-forja-auditoria-fidelidade/AUDITORIA.md) e o
  [plano de implementação](../art/research/2026-10-27-forja-auditoria-fidelidade/PLANO-DE-IMPLEMENTACAO.md), com o
  pedido do dono: *«Quero que implemente isso»*

## Contexto

O Rei, o Escudeiro e o Arqueiro entregues a 27/10 foram rejeitados. A auditoria mostra a sequência: para o arqueiro
entrou outra referência (túnica verde comprida, sorriso, mão na cintura); o compilador acrescentou «two tones per
material» e «about 12-24 colors» a contratos sem limite de cores; uma grade imposta (`--cells`) reduziu o desenho e
essa redução foi anexada às gerações seguintes como se fosse o conceito. E mostra o mecanismo por baixo: a pureza mede
só o miolo das células que ficaram opacas, por isso um traço na borda de uma célula, uma marca que perde o voto ou uma
linha fina sobre o vazio desaparecem com pureza 1,0 e sem aviso; uma grade dada pelo operador aparecia como evidência;
e nada dizia se o que se recuperou cabe na tela do jogo.

## Decisão

1. **A perda da amostragem é medida** (`loss.py`). Cada célula lê-se inteira contra o pixel escolhido; o que sumiu sem
   ficar num vizinho nem numa mistura com ele é `erased`, com a razão (`outside_core`, `minority`, `alpha_discarded`),
   a cor e as partes na célula e no miolo. Sem limiar global: uma célula conta. As células que saíram vazias
   continuam nos dados. O `forge` grava `snap.loss` e o achado `erased` (aviso). A pureza passa a ser a mesma medida em
   todos os métodos (`purity_basis: core`), e não um 1,0 por convenção.
2. **A grade diz de onde veio** (`Grid.origin`, `gridcheck.report`): `exactly_measured`, `estimated`,
   `operator_declared` (conferida contra a ampliação exata medida), `deliberately_reduced` (`--reduce`, ou uma grade
   dada mais grossa do que a medida) e `unmeasured`. O relatório separa o que a grade prova (o período, a autoria
   nativa) do que os valores provam (`pixel_values`, `lossy_input`, `original_colors`), diz se o recuperado cabe na
   tela e onde a imagem tem escala mais fina (`mixed_scale`). `grid_budget` e `grid_reduced` são achados.
3. **Cada pedido fiel prende-se à autoridade da pose** (`fidelity.py`, `forja.fidelity/1`). O contrato guarda a
   prancha de autoridade (sha256 dos bytes), o recorte de cada personagem e pose, as invariantes, as regiões, os pinos
   e os candidatos rejeitados (hash dos pixels, quem e quando). Com `--fidelity --character`, o `plan`, o `auto` e o
   `prompt` anexam o recorte como conceito; um conceito que não é ele é `reference_conflict`; um candidato rejeitado
   não entra; um guia em revisão sozinho é recusado.
4. **O modo do pedido é explícito** (`constraints.py`): `stylized` (o de antes), `adapt_concept`,
   `edit_approved_master` e `recover_grid` (que não gera). Cada linha do prompt diz a origem; os modos fiéis não
   recebem nenhuma preferência do compilador (`compiler_default`), e um teto de cores ou de tons só entra como
   decisão dita (`--max-colors`, `--tones`, origem `explicit_request`).
5. **Sinais declarados com conflito** (`signals.py`, `forja.signals/1`, `forge --signals`, `verify --signals`). Um
   pino `authorized` aplica a cor depois do voto e fica protegido até ao PNG final; dois pinos de cores diferentes na
   mesma célula são `layout_conflict` e nenhum se aplica; sem cor, coordenada ou autorização, `pending`. Uma região
   `required` com uma célula apagada fica `lost` e bloqueia, por pequena que seja.
6. **A revisão tem quatro estados** (`review_state.py`, `forja fidelity`): `runtime`, `declared_feature_preservation`,
   `identity_and_pose` e `native_master_approval`. Um candidato rejeitado fica `blocked` na identidade mesmo com o
   runtime em `pass`; a identidade só passa por uma revisão humana registada desta imagem exata, com observação por
   aspeto (rosto, roupa, proporções, mãos, equipamento), ou pela aprovação do dono; `--sheet` põe o conceito e o
   candidato lado a lado. A Forja não escreve nenhuma das duas.

## Alternativas consideradas

- **Tirar o recuo do miolo, ou mudar o método por omissão.** A auditoria (§12.6) mostra que o recuo zero apaga o traço
  central de 6 px que hoje sobrevive, e que nenhum dos cinco métodos guarda a linha alfa. Medir a perda é o que muda a
  decisão; o voto fica.
- **Um limiar global de perda.** Era o defeito do `subgrid` (5 % ou 12 células): uma célula pode ser um olho.
- **Uma nota de fidelidade (SSIM, LPIPS).** Sem pares do projeto aceites e rejeitados, qualquer limiar é inventado
  (§15.2); e uma média é dominada pela capa e pelo tronco.
- **Detetar dentes e pálpebras automaticamente.** Não há modelo para isso na Forja; quem sabe declara (pinos e regiões).
- **Pôr as coordenadas das regiões por escala da tela.** A auditoria proíbe-o: sem um destino nativo fiel, ficam
  pendentes.
- **Algoritmos de redução adaptativa (Kopf 2013, Öztireli 2015, Gerstner 2013).** Ficam para o piloto, com a mesma
  entrada e o mesmo destino; seriam dependências ou algoritmos novos sem ensaio no projeto.

## Consequências

- Nenhuma dependência nova. Módulos novos: `loss.py`, `signals.py`, `constraints.py`, `fidelity.py`,
  `review_state.py` e `cmd_fidelity.py` (`forja fidelity`, também no MCP). O `subgrid` passa de `pipeline.py` para
  `loss.py` (o nome antigo continua importável); `fit_aspect` passa do `plan.py` para o adaptador do Gemini, para os
  dois ficarem dentro das 250 linhas.
- **Muda de comportamento:** a pureza dos métodos `mode`, `center`, `median` e `mean` é medida (era 1,0); o `forge`
  ganha `snap.loss`, `snap.grid_report`, `signals` e os achados `erased`, `grid_budget` e `grid_reduced`; o JSON da
  grade ganha `origin`; um conceito anexado infere `adapt_concept` (o prompt perde «two tones», «12-24» e o perfil
  estrito); um guia em revisão sem o conceito deixa o plano inválido — na prova de 27/10 (FORJA-06), o plano do
  arqueiro passa de `ok: true` a `ok: false`, e a verificação dela continua a passar.
- A prova corre em [prova_auditoria.py](../art/research/2026-10-27-forja-auditoria-fidelidade/prova_auditoria.py), no
  `make forja`.
- Fica por fazer: a base nativa fiel dos três personagens (desenho, plano §6); anotar as regiões, os pinos e a caixa
  útil (Q-286, Q-288); calibrar a perda em pares reais e levá-la ao `sheet` (Q-287); a paleta do runtime do elenco
  (Q-289).
- Se a decisão for revertida: tirar os seis módulos novos e os testes `test_perdas.py`, `test_sinais.py` e
  `test_contrato_fidelidade.py`, voltar `grid.py`, `gridcheck.py`, `resample.py`, `pipeline.py`, `limits.py`,
  `prompts.py`, `plan.py`, `cmd_ai.py`, `cmd_image.py`, `cmd_local.py`, `cli.py`, `mcp_server.py` e
  `backends/gemini_images.py` ao commit anterior — e a marca apagada volta a sair com pureza 1,0 e sem aviso.
