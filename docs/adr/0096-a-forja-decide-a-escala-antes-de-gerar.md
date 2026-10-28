# ADR 0096 — A Forja decide a escala antes de gerar e não canoniza um defeito da referência

Data: 28/10/2026. Estado: decisão do dono para a escala; implementação e ensaios no FORJA-09. Não aprova arte.

## Contexto

O arqueiro de tropa da prancha foi tratado como o Arqueiro Real e entregue num quadro 80×80. Henrique corrigiu:
tropa deve ser moldada em 64×64; a referência tinha um erro visual da arma que foi copiado; o Rei não pode
exceder 80×80; pixels e agrupamentos ainda precisam de refinamento. Pediu pesquisa, auditoria e correção.

Na entrega, a caixa ocupada estimada do Rei é 97×96. As margens da imagem grande já foram removidas; o espaço
do painel de apresentação não é extensão removível do sprite. Uma segunda geração por palavras repetiu o
excesso. Um prompt com números não equivale a um controle nativo do modelo.

## Decisão

1. Papel antes do preset: `troop_64` para tropas, incluindo arqueiro de tropa; `royal_80` para Rei e Arqueiro Real;
   `royal_64` conserva o Escudeiro atual. O contrato de fidelidade fornece o papel e o tipo; contradições são erros.
   As propostas antigas de telas 96/128 não substituem esta regra. Não reescalar o runtime existente nesta tarefa.
2. Planejar a caixa útil completa antes de detalhar. Conferir a caixa ocupada contra o orçamento, sem chamar
   redução ou corte a recuperação de grade. Reportar margens e vazio interior separadamente.
3. Tratar defeitos conhecidos como exceções de referência com região, autor e data. Não copiar um erro por
   fidelidade nem mudar a identidade por o corrigir. Um reparo só fecha pela observação da imagem exata corrigida.
4. Preservar cada pixel na leitura nativa 1×. Sinais obrigatórios perdidos bloqueiam o `forge`, não só a revisão
   posterior. Uma corda reta só passa a geometria se as pontas também se ligarem à madeira observada.
5. Separar geração nativa (`create-image-*`), conversão com tamanho nativo (`image-to-pixelart`, fixer e
   output_size) e geração grande por prompt. A nova conversão usa a biblioteca padrão, os jobs/tetos existentes,
   uma fonte e campos documentados. Não tem instruções textuais nem corrige semântica de arma: a entrada com
   defeito conhecido para corrigir é recusada antes do gasto. Não repetir o mesmo pedido pago como correção.
6. O feedback de refinamento preserva expressão, dobras e materiais; não impõe dois tons ou olhos/bocas
   limitados genericamente a um ou dois pixels.

## Consequências e limites

Não há modelo novo treinado, detector universal de armas ou aprovação automática da identidade. As observações
continuam atribuídas a quem as fez e presas ao hash; uma oclusão duvidosa continua inconclusiva. A rota nativa
foi conferida contra a especificação pública e testada por transporte simulado. Sem credencial PixelLab nesta
sessão, não há prova visual de conversão real nem novos sprites aceitos. Não há dependência nova nem edição
de art/, audio/, src/, scenes/ ou data/.
