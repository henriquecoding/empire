# ADR 0008 — Convenções da base de dados de conteúdo

- Estado: aceite (v5.2 — reversível até à Fase 1)
- Data: 2026-09-11
- Secção do dossiê: §40 (I4), §44, §47, §64 (G4)

## Contexto
A §44 dá os campos-chave das doze classes, mas não diz como se escreve um CSV, onde se documentam os números, nem o
que fazer com os valores que o dossiê não dá. A decisão de 11/09/2026 foi **propor e marcar** em vez de deixar vazio.

## Decisão
1. **Colunas `_`** são documentação e a ferramenta ignora-as: `_src` (secção do dossiê), `_proposed` (campos com
   valor proposto), `_notes` (justificação), `_phase` (fase em que a linha é precisa), `_group`.
2. **Layout `kv`** para recursos de uma instância com muitos campos (`economy.csv` → `EconomyCurve`); `rows` para os
   restantes.
3. **Uma coluna desconhecida faz a ferramenta falhar.**
4. **Valores por omissão neutros** nas classes novas (0, 1.0 nos multiplicadores, vazio); as três classes que o
   dossiê escreve por extenso (`UnitData`, `RotProfile`, `ClockData`) mantêm os seus.
5. O portão **G4 ignora `src/sim/data/`** e `src/sim/band.gd`: os valores por omissão de um `Resource` de dados são
   sempre sobrepostos pelo `.tres` gerado, e o `--check` do CI prova-o.
6. `data/source/.gdignore` e `docs/.gdignore`: o Godot importava cada CSV como tradução.
7. Nove tabelas novas e os campos do grupo `v5.2` (CONTENT_DATABASE §4) — a subida de versão do dossiê regista-as.

## Alternativas consideradas
Deixar vazio o que o dossiê não dá: o *pipeline* não gerava recursos utilizáveis e a greybox não corria.
Proveniência campo a campo num ficheiro à parte: exata, mas ninguém a mantém.

## Consequências
`docs/content/PROPOSALS.md` lista 550 valores propostos, ordenados pela fatia vertical. Aceitar um é apagar o nome
do campo em `_proposed`.
