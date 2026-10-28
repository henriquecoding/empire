# FORJA-10 — revisão visual, patch nativo e os três pilotos na grade da prancha

Estado parcial — P0, P1, tons e os três pilotos feitos e provados no make forja; a conversão real (sem
          credencial), a identidade e o mestre ficam para o dono (Q-292–Q-294)

## Pedido e autoridade

Henrique, 28/10/2026: «Quero que implemente o que está no relatório, além disso pesquise densamente na web para
refinar e melhorar ainda mais essa pesquisa e elaboração dos relatórios», com o handoff, o relatório e o pacote de
28/10 (patch do FORJA-09). Durante o trabalho: «A corda está atrás do personagem, a arma está mal feita».

AGENTS.md, ADR 0096 e 0097, guias de personagens/pixel art/Aseprite, Forja, contrato de fidelidade de 28/10.

## Alterações verificáveis

- Patch do FORJA-09 aplicado tal como veio (C01–C12) e revisto; a conversão passa a emoldurar a fonte na proporção
  da saída, sem reamostrar.
- P0: `forja.visual_review/1` e `forja visual`, ligados ao contrato (fase reference), ao `forja fidelity` (fase
  candidate), aos `reference_issue_reviews` e à observação do `forja equip`; controlos positivos e negativos.
- P1: `forja.pixel_patch/1` e `forja patch`, só na máscara, com protegidos, pinos, hashes e diferença.
- `tones.py`: tons por limiar perceptual, sem teto de cores.
- Pilotos (`docs/art/research/2026-10-28-forja-pilotos-nativos/`): Rei 80×80, Escudeiro 64×64 e Arqueiro de tropa
  64×64 recuperados na grade da prancha, com limpeza, tons, orçamento e o arco refeito, reproduzíveis no `make forja`.
- Instruções do servidor MCP com os dois comandos novos.

## Limites de entrega

Sem chamada paga, sem credencial PixelLab e sem modelo treinado. As revisões visuais são do agente; identidade e
mestre ficam pendentes para o dono. As decisões de orçamento e da corda estão em Q-292–Q-294. Os candidatos não
foram integrados no jogo (art/ intocado).
