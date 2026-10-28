# Empire — Forja: cenários e construções em pixel art

Revisão aprofundada de 28/10/2026.

Comece pelo PDF. São 32 páginas com análise de capturas reais de Kingdom, Owlboy e Eastward, composição lateral, volume, clusters, materiais, vegetação, água, geologia e arquitetura. A segunda metade transforma esses princípios em etapas concretas de produção para a Forja, preservando o método de identidade e reparo regional dos personagens.

## Ficheiros

- `Relatorio-Forja-Cenarios-Construcoes-2026-10-28.pdf`: relatório ilustrado completo.
- Mesmo nome em `.md`: texto editável. As marcações IMAGE/CROPS indicam as figuras incorporadas no PDF.
- `Instrucoes-Claude-Cenarios-Construcoes.md`: tarefas, dependências, piloto e provas de aceitação para a implementação posterior.
- `referencias-originais/`: quatro PNGs gerados nesta revisão, conservados sem redimensionamento: Enramados, Porto, Fornalha e oficina isolada.
- `prompts-referencias.json`: pedidos completos usados para criar os estudos.
- `fontes-v2.csv` e `fontes-v2.json`: 34 fontes externas primárias e base técnica. O JSON inclui origem e hash das imagens pesquisadas.
- `plano-piloto-enramados.json`: plano proposto de composição, referências, geração, conversão e bloqueios. Não é uma submissão pronta à API.
- `inspecao-referencias.json`: dimensões, SHA-256 e transparência dos estudos.
- `inspecionar_referencias.py`: repete a inspeção com Python e Pillow; executar a partir de qualquer diretório.
- `validacao-entrega.json`: verificações realmente executadas e limites.
- `evidencias/`: inventário da auditoria técnica anterior e snapshot público OpenAPI consultado nesta revisão.

## Estado da entrega

Pesquisa concluída, referências geradas e especificação aprofundada. As quatro imagens são `visual_reference`, com aprovação pendente. As dimensões recebidas são as do inventário; nenhuma foi promovida a `native_master` ou `runtime_asset`. A oficina isolada contém alfa parcial e não é uma extração exata do panorama.

Não houve implementação da Forja, ensaio pago da API PixelLab, novo benchmark Godot ou aprovação artística pelo utilizador nesta revisão. O plano distingue esses passos para que possam ser executados e revistos com evidência concreta.

As capturas de terceiros aparecem no PDF como exemplos analisados. Os respetivos direitos pertencem aos titulares; não são propostas de cópia de assets. O pacote oferece os URLs de origem, não uma biblioteca de sprites desses jogos.
