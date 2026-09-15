# ADR 0012 — A Parte XIII entra no repositório pelos dados, não pelo código

- Estado: aceite
- Data: 2026-09-14
- Secção do dossiê: §70, §71, §72, §74 a §85

## Contexto
A Parte XIII acrescenta nove sistemas ao dossiê. A §72 tinha fechado a pré-produção com uma regra: o dossiê só muda
por correção, por decisão que vira ADR, ou por número que um playtest desmentiu. A Parte XIII é do segundo tipo e
chega com 237 h orçamentadas (§82) e zero linhas de sistema escritas. Ao mesmo tempo, a recuperação da v6
(`docs/recovery/v6-validation.json`) mostrou um repositório com 17 tabelas e 154 recursos — menos dez tabelas do que
o que já existia aqui.

## Decisão
A Parte XIII entra primeiro inteira em `data/source/` e em `src/sim/data/`, e só depois em sistemas. O anexo §85 é o
contrato: `rot.csv` alargado, `amargueiros.csv`, `offers.csv`, `titles.csv` e `chapters.csv` novos, `journals.csv`
reescrito, e colunas novas em `peoples.csv`, `creatures.csv`, `clock.csv` e `economy.csv`. Cada valor que não está
escrito no dossiê entra marcado em `_proposed`, com a razão em `_notes`. O `_tables.csv` deste repositório — 27
tabelas, 202 recursos — manda sobre os números escritos à mão na §85.

## Alternativas consideradas
Escrever os sistemas primeiro e os dados a seguir: é o caminho que produz literais de balanceamento espalhados por
`src/`, que o portão G4 já proíbe. Rejeitado.
Adotar o repositório recuperado da v6 como base: perdia as dez tabelas, as cadeias de i18n, os segmentos e as
bíblias de produção que este já tem. Rejeitado — o que se adota da v6 é o dossiê, a camada de dados da Parte XIII e
a camada de ferramentas de leitura (`ferramentas/`).

## Consequências
Nenhum sistema da Parte XIII pode entrar sem o teste da §84 que o guarda. O `check_dossie_vs_csv.py` passa a
conferir também as tabelas da Parte XIII — 193 valores, contra 127 antes. A fórmula da massa da §05 fica marcada
como substituída pela §74 no próprio dossiê, para que ninguém leia a antiga por engano.
Reverter isto obriga a apagar quatro tabelas, quatro `Resource` e 34 `.tres` gerados; o dossiê fica intacto.
