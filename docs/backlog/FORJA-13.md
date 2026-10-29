# FORJA-13 — Integrar os conceitos escolhidos no elenco da Forja

Estado feito — catálogo de conceitos, contratos, referências e pedidos CLI/MCP integrados; sprites nativos e animações por produzir

## Pedido e autoridade

Henrique, 29/10/2026: «implemente todos esses conceitos e os aprovados no chat
anterior na forja». Os três novos pares foram aprovados como design; seguiram-se
os pedidos de tornar o alquimista asiático conservando o nariz original e de
dar uma função compatível ao seu escudeiro.

Referências: [elenco e decisões](../art/concepts/2026-10-29-elenco/README.md),
[guia de personagens](../art/CHARACTER_PRODUCTION_GUIDE.md),
[Forja](../art/FORJA.md), [ADR 0099](../adr/0099-a-forja-conserva-o-elenco-escolhido.md),
ADR 0093/0094/0096/0097 e AGENTS.md.

## Entrega

- Originais preservados e identificados; os recortes são coordenadas do contrato.
- Decisão do dono por personagem, sem promoção de conceitos a mestres nativos.
- Contratos de fidelidade e observações das imagens exatas, função do equipamento,
  pares e telas; as regiões do futuro sprite continuam por desenhar/rever.
- `forja elenco` / `forja_elenco` e resolução por `--character` nos comandos existentes.
- Inferência correta dos papéis femininos, com as mesmas telas dos masculinos.
- Humano com nabo e berserker humano; escudeiro real existente preservado.

## Verificação

`tools/forja/tests/test_cast.py` começou a falhar antes da implementação.
Verifica seleção e planos de todo o elenco, papel/tela, aliases nos comandos
existentes, nariz longo e identidade asiática, função do assistente, metadados de
aprovação e exposição MCP. `make forja` integra a suíte e as provas existentes.
O PR regista os resultados locais e do CI, incluindo a disponibilidade do Godot.

## Próxima etapa de arte

Desenhar/adaptar cada corpo na tela escolhida, rever identidade e contactos do
equipamento em pixels, depois animar. Isso não é substituído pelo catálogo de
conceitos e não foi declarado concluído nesta tarefa.
