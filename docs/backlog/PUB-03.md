# PUB-03 — Decisões compreensíveis no painel

Pedido do dono, 28/09/2026: as perguntas são vagas e não dão contexto suficiente
para aprovar. Refinar design e UX com o Recibo Certo como referência.

```text
Estado    feito
```

## Âmbito
- `tools/web/`: leitura de QUESTIONS, apresentação e formulários do painel.
- Contexto visível, proposta completa, pendências separadas, fontes consultáveis.
- Uma ficha de cada vez, fila pesquisável, estados distintos e acesso móvel.
- Preservar respostas guardadas, rascunhos e políticas existentes no Supabase.
- Sem alterações de mecânicas, balanceamento, arte ou áudio.

## Referências
- ADR 0025 (site), ADR 0026 (reportes e respostas), docs/QUESTIONS.md.
- Recibo Certo/main: `ProximaAccao.tsx`, `DashboardShellClient.tsx`,
  `src/app/dashboard/page.tsx`: próxima ação, contexto, cartões arredondados,
  tipografia legível e detalhes progressivos.

## Critérios
- Encerradas não pedem aprovação; decisões parciais mostram o que falta.
- Aprovação só aparece com um objeto explícito, sem truncamento.
- Adiar não conta como decisão à espera de implementação.
- Falha ao ler bloqueia escrita; falha ao guardar preserva o rascunho.
- Guardar A não altera um rascunho em B; duplicar cliques não duplica pedidos.
- Teclado, 320–1440 px e ambos os temas, incluindo área autenticada simulada.

## Manutenção
`decisoes-contexto.json` explica em linguagem corrente as questões com maior
ambiguidade. Cada explicação leva a impressão SHA-256 do HTML da fonte: se a
pergunta mudar, o painel volta automaticamente ao texto atual do repositório,
sem continuar a mostrar uma interpretação antiga. Não é fonte de balanceamento.
As restantes fichas usam os campos completos da própria pergunta. As ligações
apontam ao commit publicado, para tornar a decisão verificável.

## Verificação
`node --test tests/web/perguntas.test.mjs` (falhou antes da correção).
`node tests/web/painel-ui.mjs` (Playwright e axe em ferramentas/node_modules).
`./run_tests.sh`, `make portoes`, construção do site e portão do site.
