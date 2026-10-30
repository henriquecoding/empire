# FORJA-16 — regras do dono consultadas antes de produzir e entregar

Estado feito — regras, consulta nos pedidos e portão de entrega implementados; validação no `make forja` e na CI do PR

## Pedido e autoridade

Henrique, em 30/10/2026, pediu para gravar na Forja as observações e regras anteriores e fazer merge na `main`.
Reiterou mãos mal desenhadas, contorno com pixels duplos, expressão incorreta, poção sem bojo redondo/pega e
resolução aparente abaixo dos 64×64/80×80 pedidos. [ADR 0102](../adr/0102-a-forja-consulta-as-regras-do-dono-antes-de-entregar.md),
[regras consolidadas](../art/OWNER_RULES.md), guias de produção/pixel art e elenco escolhido são a autoridade.

## Entrega

- Fonte versionada de regras com falas/datas do dono, leitura obrigatória e hashes nativos do lote rejeitado.
- Consulta no AGENTS e nos pontos de entrada; `forja regras` disponível na CLI e no MCP.
- Regras nos prompts ampliados/nativos; consulta vinculada ao conceito no `expect` e conservada na cadeia/patch.
- Planos antigos, prompts sem regras e guias rejeitados recusados antes de geração pelo fluxo planeado.
- Ficha visual pendente ligada aos pixels, ao conceito e à revisão das regras; oito aspetos com caixas/evidência.
- `forja entrega` exige revisão e cadeia resolvidas; mostra ausências no elenco e distingue piloto explícito.
- Redução com perda permanece diagnóstica após reexportação; revisão pronta não concede aprovação do mestre.

## Verificação

`test_owner_rules.py` e `test_owner_rules_flow.py` reproduzem os desvios desta sessão. O teste inicial falhou
por ausência dos novos módulos. O `make forja` repete a suite e as provas anteriores para conferir compatibilidade.
Os testes de fluxo constroem pedidos locais e usam imagens sintéticas; não gastam chamadas a geradores.

O protocolo não desenha automaticamente boas mãos ou expressões: exige que os problemas sejam observados,
corrigidos e revistos antes de apresentar. Não houve nova geração nem aprovação de personagens nesta tarefa.
