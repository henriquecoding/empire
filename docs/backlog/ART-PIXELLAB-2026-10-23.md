# ART-PIXELLAB-2026-10-23 — pesquisa técnica do PixelLab

Estado feito — pesquisa pública, relatório de implementação e auditoria reproduzível da Forja do PR #117

## Pedido

Investigar profundamente o PixelLab e guardar no repositório um relatório
detalhado de como construir uma ferramenta comparável, pronto para continuar
com Claude. Na continuidade, verificar o trabalho que Claude já integrou,
os problemas, o que falta e a publicação GitHub/Vercel. A entrega é pesquisa,
projeto técnico e auditoria; correções de produção são um ciclo posterior.

## Autoridade

AGENTS.md, guias de personagem, pixel art e Aseprite, Asset/Animation Bibles,
REFERENCE_AUTHORITY e decisões atuais de arte. A pesquisa não promove estudos
ou animações arquivadas a assets aprovados.

## Entrega

- [Relatório mestre](../art/research/2026-10-23-pixellab/RELATORIO-MESTRE.md).
- [Instruções para Claude](../art/research/2026-10-23-pixellab/PROMPT-PARA-CLAUDE.md).
- [Auditoria da Forja](../art/research/2026-10-23-pixellab/AUDITORIA-FORJA-CLAUDE.md),
  nove sondas sem rede, resultados, prioridades e critérios de regressão.
- Fontes, hashes, distinções entre evidência e proposta, contrato de asset e
  benchmark planejado com resultados explicitamente não executados.
- Inspeção reproduzível e somente de leitura do OpenAPI público; verificador
  local da integridade do pacote.

## Limites

Não recupera código ou pesos privados, não treina modelos, não chama geração
paga, não integra novos assets e não muda runtime, arte, áudio ou dependências.
O sistema futuro tem critérios de conclusão próprios no relatório. A Forja
existente foi preservada. A inspeção privada da equipe Vercel não foi possível
por falta de acesso ao escopo; site público e status do GitHub foram verificados.

## Verificação

Verificador documental, exemplos JSON, referência cruzada, aritmética do
benchmark, inspeção da especificação pública, contagens do backlog e
`git diff --check`. Portões disponíveis localmente; CI completo do projeto
deve estar verde antes do merge, conforme AGENTS.md.
