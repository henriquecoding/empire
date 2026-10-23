# FORJA-01 — a Forja: pixel art dos geradores nos contratos do Empire

Estado feito — ferramenta, servidor MCP, prova, testes e guia; uso real com geradores e aprovação de assets pendentes do dono

## Pedido

O dono, a 23/10/2026: engenharia reversa densa do PixelLab e uma ferramenta completa no repositório, acima da
original, para agentes que geram imagens (o ChatGPT, por exemplo) trabalharem com pixel art exatamente como o
projeto quer; pesquisar na web como tornar isso real.

## Spec e autoridade

[Guia da Forja](../art/FORJA.md), [pesquisa](../art/research/2026-10-23-forja-pixellab/README.md),
[ADR 0088](../adr/0088-a-forja-de-pixel-art.md), Asset Bible, Animation Bible, guia de personagens §5–§6 e
AGENTS.md (regras 8 e 9).

## Entrega

- `tools/forja/`: grade, amostragem, fundo, limpeza, paleta OKLab, contorno, cluster, tela e pivô; lint com
  correção e prompt corretivo; pranchas e animação; `.aseprite`; Wang 16 e `TileSet`; `SpriteFrames`; Scale2x e
  RotSprite; compilador de prompts e imagens-guia; conectores OpenAI, Gemini e PixelLab; edição por máscara com os
  pixels de fora idênticos; ciclo `auto`; servidor MCP.
- Contratos em `tools/forja/contracts.json`, conferidos contra as bíblias pelos testes.
- `make forja` (prova e testes) nos portões estáticos e no CI; `.mcp.json` na raiz.
- Pesquisa do PixelLab, das ferramentas abertas e das APIs de imagem, com fontes e medições.

## Limite

Sem alteração de `art/`, `audio/`, `src/`, `scenes/` ou `data/`; sem dependências novas; sem novas mecânicas. Nenhum
asset do jogo foi produzido. Não houve chamada real aos geradores (sem chaves) nem abertura do `.aseprite` no
aplicativo.

## Verificação

`make forja`; os testes em Python 3.11 com o Pillow fixado e com o Godot 4.7.2 fixado (o teste que abre o `TileSet` e
o `SpriteFrames` no motor); a bancada `forja prova --bench 150` guardada na pesquisa; portões estáticos locais.
