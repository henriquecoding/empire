# ADR 0073 — Painel de trabalho e pendências verificáveis

Data: 05/10/2026. Pedido: melhorar o Painel no desktop e no mobile e implementar o que espera.

## Painel

O cabeçalho da imagem enviada ocupava o primeiro ecrã inteiro. O painel passa a abrir como espaço de trabalho: título curto, ajuda recolhida, contadores que filtram a fila, pesquisa e estado à vista. Tipo e secção ficam nos filtros adicionais. Desktop mantém lista e ficha; mobile usa um seletor nativo, evitando percorrer centenas de cartões na horizontal. A navegação anterior/seguinte acompanha a leitura e cada ficha tem acesso direto à resposta.

A resposta guardada aparece também nas questões encerradas. As pendências de implementação do QUESTIONS.md são apresentadas separadamente do que falta decidir. Aprovação não é implementação; o estado no Supabase só é atualizado quando a alteração correspondente está publicada.

Os rascunhos usam sessionStorage, por conta, nesta aba. Sobrevivem a recarregar e a renovar a sessão, sem envio automático. Falha de armazenamento mantém o formulário em memória e avisa. Descartar repõe a resposta do servidor. Guardar e seguinte, Ctrl/Cmd+S e exportação Markdown completam o fluxo. Guardar a mesma resposta não reabre uma decisão aplicada. Sem bibliotecas novas no produto.

As notas dos reportes também sobrevivem à troca de separador, filtro e atualização. Guardar/apagar bloqueia cliques repetidos e só confirma quando o Supabase devolve o registo correspondente; uma resposta vazia deixa o rascunho disponível. Respostas de pesquisas antigas não substituem o filtro atual.

## Q-200 / UN-34

O escudeiro do Imperador Arqueiro evoluído passa a disparar no combate normal. Usa a aljava paga do patrono: um disparo consome uma flecha, inclusive quando falha. Sem flechas, patrono vivo, vínculo, faixa comum ou evolução, não dispara. Nunca cobra nem repõe automaticamente. A reposição continua a seis flechas por moeda e o crédito pago continua no save.

Reutilizam-se os números de combate do arqueiro de tropa nos dados do escudeiro, assinalados como proposta de balanceamento (Q-246). O vínculo de abastecimento é derivado a cada passo e após carregar. O arco usa os sinais e a apresentação de flechas existentes; não acrescenta sangramento.

## Q-238

A aprovação guardada em 05/10 às 16:45 UTC confirma densidade, trabalho, moedas e regras de influência apresentadas na pergunta. Esses campos saem de `_proposed`, sem mudar valores ou algoritmo. A altura visual das árvores não foi apresentada como número a aprovar e mantém-se proposta. Mais sistemas de ecologia e a medição P5 não se tornam concluídos por essa aprovação.

## Limites

UN-16/UN-32 (roster, ritual e sucessão escolhida), UN-18–21 (Diplomata), UN-33 (quarto imperador) e UN-29–31/RG-25 (online) continuam pendentes. Não se marca uma dessas decisões aplicada por estar aprovada ou por uma parte existir. A matriz PANEL-RECONCILIATION regista os tickets e as dependências.

## Verificação

`tests/web/painel-ui.mjs`: recuperação de rascunhos, filtros, seleção mobile, exportação, teclado, sessão e falhas de rede, layouts de 320 a 1440 e axe nos dois temas. `tests/quiver_escort_test.gd`: base/evolução, consumo, falta de flechas, morte do patrono e alcance. Suite e portões do projeto antes do merge.
