# FORJA-02 — preservar arte e cumprir contratos dos geradores

Estado feito — correções e revisão local; piloto autenticado e aprovação artística pendentes

## Pedido

Refinar a engenharia reversa e a Forja do PixelLab, pesquisar mais profundamente
e verificar os commits atuais no GitHub e na Vercel. Continuação de FORJA-01 e
da auditoria ART-PIXELLAB-2026-10-23, preservando os contratos de 64/80 do elenco.

## Autoridade

[ADR 0088](../adr/0088-a-forja-de-pixel-art.md), [Forja](../art/FORJA.md),
[auditoria e refinamento](../art/research/2026-10-23-forja-pixellab/REFINAMENTO.md),
guias de pixel art, personagens e Aseprite. Sem mecânica de gameplay nova.

## Entrega

- Correções F01–F09 com regressões reproduzidas antes da implementação.
- Planos por fornecedor, `auto --dry-run`, guias anexadas e recibos de jobs.
- `animate-native`, `job` e `review`; sem reconstruir ou realinhar o desenho nativo.
- Preservação de origem, detalhes, cores, direção, duração e índices de células.
- Exportação bloqueada em pranchas inválidas; estados técnico e artístico distintos.
- Revisão reproduzível do acervo V15 e documentação corrigida sobre o PixelLab.

## Verificação

`make forja`, `make portoes`, `./run_tests.sh`, CI e deployment por SHA.
Conectores com transporte falso; nenhum gasto ou benchmark visual de modelos.
