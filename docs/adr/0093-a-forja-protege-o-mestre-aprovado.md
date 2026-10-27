# ADR 0093 — A Forja recupera antes de proteger, e só protege o mestre que o dono aprovou

- Estado: aceite
- Data: 2026-10-27
- Secção do dossiê: §01 e §22 (a unidade gráfica, a paleta, o contorno); o guia de produção de personagens
- Complementa: ADR 0088 (a Forja), ADR 0089 (pede uma vez e mede), ADR 0091 (o equipamento) e ADR 0092 (a cor no
  espaço); a Asset Bible não muda
- Tarefa: [FORJA-06](../backlog/FORJA-06.md)
- Origem: a [solução de 27/10](../art/research/2026-10-27-forja-fidelidade/SOLUCAO.md), com o pedido do dono:
  *«Implemente isso, e também pesquise profundamente na web mais coisas que possam complementar isso»*

## Contexto

O Rei, o Arqueiro e o Escudeiro foram rejeitados pelo dono: perderam a expressão, as proporções e a família de cor do
conceito. A Forja tinha o mecanismo certo para não estragar mais — a edição local que compõe a resposta só na máscara —
mas nada a impedia de proteger o ficheiro errado. A última saída passava por referência só por ser a mais recente; o
prompt chamava «APPROVED design» a qualquer imagem anexada; o `forge` manual com `--expect` não comparava o tamanho que
chegou com o pedido; um retorno de tamanho errado no `inpaint` era uma exceção que perdia o job; o `forja line` pintava
a corda com a cor da maioria da seleção (com o miolo e o contorno juntos, ganhou o preto) e só nos pixels novos; um
conflito de rampa em pixels presos saía com `ok`; e nada dizia o que falta para uma entrega.

## Decisão

1. **Cada referência tem autoridade registada** (`refs.py`, `forja refs`). O registo `forja.refs/1` guarda, pelo hash
   dos pixels, o estado de cada imagem: `concept`, `adaptation_in_review`, `approved`, `rejected`. `approved` e
   `rejected` dizem quem decidiu e quando; a Forja acrescenta estados e **nunca escreve `approved`** — essa linha é do
   dono, à mão. Uma imagem que mudou depois do registo é um erro.
2. **O prompt diz o estado do que vai anexado.** Só um mestre registado é «the APPROVED design»; a adaptação em revisão
   é «IN REVIEW and NOT approved» (a escala e o sítio, e o conceito manda onde divergem); o conceito é «the authority
   CONCEPT ART» (o rosto, as proporções e os materiais a redesenhar na grade); sem registo, «approval is NOT recorded».
   Uma referência rejeitada não entra; com um registo dado, uma que não esteja nele também não. O plano diz a fase:
   `recovery` (sai uma adaptação em revisão) ou `from_master`.
3. **O pedido confronta-se com o retorno nos dois caminhos** (`expectation.py`). O `auto` e o `forge`/`sheet` manuais
   com `--expect` usam a mesma conta: um tamanho que não é o pedido invalida o contrato e pede outra geração; uma grade
   não seguida vai para a revisão e para o prompt corretivo; um pedido nativo só é lido a 1× se o tamanho o confirmar.
4. **A edição local parte do mestre e para sem redesenhar.** `forja inpaint --refs` recusa, antes do pedido pago, uma
   versão rejeitada e o conceito; o resultado leva o estado e o hash do mestre e o que falta. Um retorno noutro tamanho
   devolve `stopped: size_mismatch` com o job e manda repetir só a zona — nunca é motivo para gerar o personagem
   inteiro. **`forja verify`** repete a prova contra o mestre, só a ler, depois de qualquer acabamento.
5. **A cor de uma linha fina é declarada.** `forja line` aceita o miolo (`--core`, `--core-box`; o resto da região da
   linha, o contorno, fica protegido) e a cor (`--color`, ou as `colors` do seletor da observação). A cor vai para
   todo o pixel da linha final, salvo o que já é da família declarada; `--mode fill` pinta o miolo tal como está. Sem
   cor declarada o reparo é `inconclusive`, e uma linha nova que passe por uma zona protegida é recusada.
6. **Material resolvido é outra coisa que preservação.** Um pixel preso fora da rampa da sua região, ou uma fronteira
   entre materiais perdida, deixa `material: pending`, mesmo com o `ok` técnico; a solução é rever os seletores, nunca
   tirar a proteção.
7. **O encerramento tem quatro condições** (`verdicts.closure`): corresponder ao conceito, contrato e materiais,
   preservado fora da mudança (numa edição local) e revisão registada. Um eixo `not_evaluated` nunca fecha; a
   identidade e a aprovação fecham-se só pelo registo do dono **desta imagem exata**. Lint, hashes e provas são
   evidência de ficheiro, e o resultado di-lo.
8. **O banding é uma suspeita medida** (`banding.py`): dois segmentos de cores diferentes, 2+ px, vizinhos pelo lado
   comprido e com as pontas alinhadas (a definição do *Pixel Fixer*, TU Delft, 2025), sem contorno nem vazio. Sai no
   `forja cores`; não corrige nem bloqueia.

## Alternativas consideradas

- **Proteger o último ficheiro gerado.** Congelava a descaracterização que levou à rejeição (solução, §1).
- **Deixar a Forja escrever `approved` com um `--by`.** Um agente podia aprovar arte; a aprovação seria tão fiável como
  a vontade de quem corre o comando. Fica à mão, no registo, como o `artistic_approval` dos vereditos.
- **Um parâmetro de cor só, no `straighten`.** A solução mostra porque não basta: a cor ia só para `new - line`, e os
  pixels pretos que já eram da linha continuavam pretos.
- **Tirar a proteção para o relatório de cores sair limpo.** Escondia o conflito de seletores (a lâmina que apanha a
  mão); o material fica pendente até as regiões terem autoridade.
- **Integrar já o `fixer` do `/image-to-pixelart`.** A especificação de 27/10 diz que acima de ~300 de força a
  resposta é a imagem de entrada, não pixel art; é um endpoint pago novo sem ensaio. Fica como pergunta (Q-285).
- **Um algoritmo de pixelização com regiões (Gerstner 2013, Kopf 2013, Wu 2022).** Resolvem a primeira aproximação de
  um conceito denso, que é desenho; seriam algoritmos ou modelos novos. Ficam como referência na pesquisa.

## Consequências

- Nenhuma dependência nova. Módulos novos: `refs.py`, `expectation.py`, `banding.py` e `cmd_local.py` (`inpaint`, que
  sai do `cmd_ai.py`, `verify` e `refs`, também no servidor MCP).
- **Muda de comportamento:** uma referência anexada sem registo deixa de ser «the APPROVED design» (o teste antigo do
  plano passou a usar um registo); `forja line` sem cor declarada é `inconclusive` (a prova de 24/10 tinha as cores no
  seletor e sai igual); `repair.straighten` exige `colors`; o `forge` e o `sheet` com `--expect` podem sair com `ok`
  falso por tamanho; `inpaint.run` devolve `(None, relatório)` num tamanho errado; `do_inpaint` com `--refs` recusa uma
  versão rejeitada.
- Os JSON de detalhe das provas de 24/10 e 25/10 ganham campos (`paint`, `material`, `banding`) sem mudar nenhum valor; o
  arqueiro de 25/10 fica `material: pending` pelos 52 `#0B0B0B` presos que o relatório já escrevia (Q-279).
- A prova corre em [prova_fidelidade.py](../art/research/2026-10-27-forja-fidelidade/prova_fidelidade.py), no `make forja`.
- Fica por fazer: o mestre fiel ao conceito dos três personagens (desenho); onde vive o registo de cada personagem e
  quem o mantém (Q-282); calibrar o banding (Q-283); separar miolo e contorno da corda também para a geometria (Q-284); a
  conversão guiada do PixelLab (Q-285); as slices do `.aseprite` com as zonas.
- Se a decisão for revertida: tirar os quatro módulos novos e os testes `test_fidelidade.py` e `test_corda_cores.py`,
  voltar `plan.py`, `prompts.py`, `guides.py`, `auto.py`, `cmd_ai.py`, `cmd_image.py`, `cmd_make.py`, `cmd_equip.py`,
  `cmd_cores.py`, `inpaint.py`, `repair.py`, `materials.py`, `verdicts.py`, `cli.py`, `mcp_server.py` e os dois testes
  antigos ao commit anterior — e o rejeitado volta a poder ser protegido e chamado aprovado.
