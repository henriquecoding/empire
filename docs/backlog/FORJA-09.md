# FORJA-09 — escala de tropa, defeitos da referência e preservação nativa

Estado: implementação local em revisão; validação e estado de integração no relatório de 28/10.

## Pedido e autoridade

Henrique, 28/10/2026: arqueiro de tropa em 64×64; corrigir erros da arma mesmo quando aparecem no conceito;
Rei dentro de 80×80; investigar margens e refinar pixels. Pesquisar e auditar a fundo.

AGENTS.md, ADR 0096, guias de personagens/pixel art/Aseprite, Forja e contrato atual em
`docs/art/research/2026-10-28-forja-escala-e-referencia/`.

## Alterações verificáveis

- Papel e tipo resolvidos antes do pedido, com recusa de conflitos; preset `troop_64`.
- Orçamento útil no contrato e no pedido, conferido na imagem devolvida.
- Defeitos conhecidos com exceção autorizada e prova de reparo vinculada ao hash do candidato.
- Medição de margens e extensão útil; diagnóstico sem corte quando o encaixe falha.
- Leitura a 1× sem reajustar a grade; perda de sinal obrigatório bloqueia o `forge.ok`.
- Ligações das duas pontas do arco conferidas além da reta da corda.
- Feedback sem simplificação genérica da expressão; invariantes mantidas também no texto ao PixelLab nativo.
- Conversão PixelLab com output_size nativo e fixer, campos verificados antes do job, sem repetição paga idêntica.

## Limites de entrega

Testes com dados sintéticos e arte existente, sem gasto de API, treino ou novos sprites aprovados. Falta validar
visualmente a conversão real e concluir a reconstrução/limpeza dos mestres nativos antes de animar ou integrar.
