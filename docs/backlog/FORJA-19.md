# FORJA-19 — implementar o estudo Penusbmic de 03/11

Estado feito — implementação e provas automatizadas; suite e portões completos exigidos antes do merge.

Pedido de Henrique: implementar o estudo anexado no projeto GitHub/Vercel. Base: `main`, independente
do PR FORJA-18 ainda aberto. Autoridade: AGENTS.md, regras do dono, guias de personagens/pixel art/Aseprite,
contratos atuais; [ADR 0105](../adr/0105-estudo-penusbmic-em-ensaios-verificaveis.md).

## Entrega

- [Estudo preservado](../art/research/2026-11-03-penusbmic/README.md), índice de propostas e fontes consultável.
- Prompts com critérios de mãos/objetos, atuação, movimento e piloto de cena.
- Exportação por ação, canvas/pivô/tempos exatos e reconstrução após trim.
- Ensaio local e ficha por quadro/ação, corpo sem VFX, estado facial autorizado e escala do objeto partilhado.
- Replay repetível e comparação antes/depois; janelas temporais de efeitos na revisão e em `sheet`.
- Comparação de variantes de designs abertos e piloto de cenário com massas, planos, ator e dia/noite.
- [Guia de uso e limites](../art/PENUSBMIC_WORKFLOW.md), CLI e MCP.

## Aceitação

Testes novos reproduzem falhas antes da correção. `make portoes` e `./run_tests.sh` devem passar,
com importação no Godot fixado. Antes do PR, incorporar a `main`; só integrar com CI do head exato verde.
O deployment de produção permanece condicionado ao release gate existente e ao commit que passou no CI.

Não alterar arte aprovada nem inventar animações finais. Não chamar o ensaio HTML de teste Godot,
não conceder aprovação artística e não ampliar a cobertura das aulas além do registrado no estudo.

Os testes Python recompõem os pixels da fonte e o teste JavaScript percorre a timeline. Uma prova no
Chromium abriu o HTML gerado pela CLI com uma animação sintética e o conceito do escudeiro alquimista.
Conferiu a direção reversa, os tempos dos quadros, a troca dos pixels do efeito, os controles e a ampliação.
