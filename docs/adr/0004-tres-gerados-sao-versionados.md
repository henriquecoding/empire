# ADR 0004 — Os `.tres` gerados são versionados

- Estado: aceite
- Data: 2026-09-11
- Secção do dossiê: §69 (`.gitignore`)

## Contexto
O *export* precisa dos `.tres`; o CI não devia ter de correr a ferramenta para os ter.

## Decisão
Os `.tres` de `data/` entram no repositório. O CI corre `csv_to_tres.gd -- --check` e chumba se algum divergir do
CSV — o que apanha tanto o `.tres` editado à mão como o CSV editado sem correr a ferramenta.

## Alternativas consideradas
Gerar no CI e ignorar no Git (a linha comentada no `.gitignore`): builds dependentes da ferramenta e *diffs* de
balanceamento invisíveis na revisão.

## Consequências
Um *commit* de balanceamento traz o CSV e os `.tres` juntos — o *diff* mostra o número antes e depois.
