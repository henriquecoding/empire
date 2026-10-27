# FORJA-07 — auditoria da Forja de 27/10: a imagem paga certa, o voto sem fronteiras, o gasto entre processos e o MCP

Estado feito — B01–B15 reparados com testes e B16 (o hash da especificação do PixelLab) atualizado; O1 e O2 ficam para
          o dono (Q-286, Q-287)

## Pedido

O dono, a 27/10/2026: *«Elabora uma densa e extensa auditoria na forja, encontre falhas e coisas a melhorar e refinar,
depois busque na web como fazer isso e aplique»*.

## Spec e autoridade

[Guia da Forja](../art/FORJA.md), [ADR 0088](../adr/0088-a-forja-de-pixel-art.md),
[ADR 0089](../adr/0089-a-forja-pede-uma-vez-e-mede.md), [ADR 0093](../adr/0093-a-forja-protege-o-mestre-aprovado.md),
[ADR 0094](../adr/0094-a-forja-le-como-se-ve.md), as auditorias de
[23/10](../art/research/2026-10-23-pixellab/AUDITORIA-FORJA-CLAUDE.md) e
[26/10](../art/research/2026-10-26-forja-auditoria/README.md), AGENTS.md (regras 1, 8 e 9).

## Entrega

[Auditoria, antes e depois, e fontes](../art/research/2026-10-27-forja-auditoria/README.md), com as sondas
reproduzíveis:

| Achado | O que entrou | Evidência |
| --- | --- | --- |
| B01 as imagens de pensamento do Gemini | `gemini_images.parse`: `output_image`, ou as imagens fora dos passos e partes de pensamento; `thought_images_skipped` | `test_auditoria_ii_rede.GeminiThoughtTest` |
| B02 o voto na fronteira do balde | `resample`: oito grelhas deslocadas (Scott, 1985) e a média na vizinhança centrada | `test_auditoria_ii.VoteTest` |
| B03 e B09 o teto e o disco | `durable.py`: troca atómica com `fsync` e lock entre processos; `Budget.reserve` | `test_auditoria_ii_rede.BudgetTest` |
| B04, B10–B12 o servidor MCP | erros JSON-RPC com id null, sem batch; stdio em UTF-8; `-32602` para a ferramenta desconhecida; `title` e anotações (o `structuredContent` estudado e deixado de fora) | `test_auditoria_ii_rede.McpTest` |
| B05 o contorno parcial | `outline.add(..., gaps=True)` no `forge`: fecha só as falhas | `test_auditoria_ii.OutlineGapTest` |
| B06 e B07 a abertura | `imageops.open_rgba`: orientação EXIF e perfil ICC para sRGB; `provenance.input.opened` | `test_auditoria_ii.OpenTest` |
| B08 o hash dos pixels | `equipment.image_sha`: o alfa 0 conta como `(0, 0, 0, 0)` | `test_auditoria_ii.HashTest` |
| B13–B15 a superfície e a rampa | a bomba de descompressão em JSON; a vírgula num caminho de paleta; o croma da rampa baixa até caber, com o matiz fixo | `test_auditoria_ii.SurfaceTest`, `RampTest` |
| B16 a especificação do PixelLab | `SPEC_SHA256` novo; `contrato-2026-10-27.json` (só uma descrição mudou; 63/63 conformes) | `contrato.py` |

## Limite

Sem escrita em `art/`, `audio/`, `src/`, `scenes/` ou `data/`; sem dependências novas; sem chamada paga; sem aprovação
artística. A luminosidade Lr na escolha da cor (O1) foi medida e não aplicada: muda a métrica da ADR 0088 (Q-286).

## Verificação

`make forja` (a prova 11/11, a suíte com 318 testes e as provas de 24/10, 25/10 e 27/10 sem deriva); a suíte em Python
3.11 com o Pillow 12.3.0 fixado; `python3 docs/art/research/2026-10-27-forja-auditoria/sondas.py` (antes e depois no
mesmo cenário); portões estáticos locais; CI do PR.
