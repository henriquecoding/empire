# ADR 0010 — Godot Aseprite Wizard para importar a arte

- Estado: proposta
- Data: 2026-09-11
- Secção do dossiê: §22, §28

## Contexto
O dossiê escolhe o Godot Aseprite Wizard (§22: "o plugin mais maduro do ecossistema") mas a regra 8 do `AGENTS.md`
exige uma ADR antes de qualquer dependência nova.

## Decisão
Vendorizar a versão compatível com o Godot 4.6 em `addons/`, fora do LFS, com a licença registada em
`THIRD_PARTY_ASSETS.csv`. Fonte: um `.aseprite` por corpo com uma camada por slot; exportação: uma folha por camada
(`docs/art/ASSET_BIBLE.md` §2, §5; `tools/export_aseprite.sh`).

## Alternativas consideradas
Exportar só pela linha de comandos da Aseprite e montar os `SpriteFrames` à mão: mais passos manuais, mais erros.

## Consequências
Para aceitar: instalar, importar o `Empire troop` separado em camadas, e confirmar pivot e tags.
