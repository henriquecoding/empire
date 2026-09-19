# Assets em falta

> Quando uma tarefa precisa de um asset que ainda não existe, o agente cria um *placeholder* de cor lisa em
> `art/export/_placeholder/` e acrescenta uma linha aqui (AGENTS.md). Nunca desenha arte a sério, nunca toca em
> `art/source/`. O registo completo do que se vai produzir é `docs/art/ASSET_REGISTER.csv`; esta lista é só o que
> está **a ser usado em jogo como placeholder**.

| Placeholder | Tamanho | Usado em | Substitui-se por | Criado | Estado |
|---|---|---|---|---|---|
| `art/export/_placeholder/unit_scale2_placeholder.png` | 24 × 47 | `scenes/boot.tscn` | `enramados_villager_body` (ASSET_REGISTER) | 2026-09-11 | em uso |
| `art/export/_placeholder/contact_shadow_18.png` | 18 × 6 | `scenes/boot.tscn` | `shadow_18` | 2026-09-11 | em uso |
| `art/export/enramados/vagrant.png` + marca de arco existente | 49 × 54; corpo 24 × 47 | `UnitArtBatch`: archer/canopy_archer | Arqueiro revisto na família do soldado; o conceito antigo foi rejeitado | 2026-09-19 | proxy temporário; REFERENCE_AUTHORITY.md |
| `art/export/enramados/monarch.png` | 60 × 94; corpo 46 × 90 | `UnitArtBatch`: monarch | Redesign do rei segundo as referências do autor | 2026-09-19 | original provisório; estudo novo ainda não aprovado |

## Como se acrescenta

```text
| art/export/_placeholder/<nome>.png | L × A | <cena ou recurso> | <asset_id do ASSET_REGISTER> | AAAA-MM-DD | em uso |
```

Cor lisa da categoria (GREYBOX_RULES §2), contorno de 1 px preto, tamanho útil e pivot iguais aos do asset final.
