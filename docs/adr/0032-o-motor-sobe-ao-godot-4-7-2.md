# ADR 0032 — O motor sobe ao Godot 4.7.2-stable

- Estado: aceite
- Data: 2026-09-28
- Secção do dossiê: §69
- Substitui, na versão: o `.godot-version` 4.6-stable

## Contexto
A Q-025 propunha ficar no 4.6 e subir ao 4.6.3 só com correções. O dono respondeu: *"o Godot já tem a versão
4.7.2 estável, faça a princípio nela"*. O gdUnit4 fixado (6.2.1) declara suporte até ao 4.7.1.

## Decisão
**O projecto passa ao Godot 4.7.2-stable**: `.godot-version` e `config/features` do `project.godot` (o
`tools/manifesto.py` confere os dois). O CI, a Vercel e o `JOGAR-E-TESTAR.bat` leem o `.godot-version` e sobem
sozinhos. O gdUnit4 fica no 6.2.1.

## Como se provou
Antes de mudar o número, a suite inteira correu no 4.7.2 numa cópia do repositório: **922 casos, 3 saltados**, e as
falhas foram as mesmas que no 4.6 com as mesmas alterações — nenhuma do motor. A importação no 4.7.2 não reescreveu
nenhum ficheiro do projecto. A falha de desempenho do `minuto_0_20_test` (um tick de 300 unidades acima dos 4000 µs)
é da máquina onde se mediu e já acontecia no 4.6.

## Alternativas consideradas
Ficar no 4.6.3 (a proposta): o dono escolheu o 4.7.2. Subir também o gdUnit4: sem versão que declare o 4.7.2, e a
6.2.1 passa a suite inteira nele.

## Consequências
O template Web e os de exportação passam a ser os do 4.7.2 (o `obter_godot.mjs` vai buscá-los pela versão). Se o
gdUnit4 der problemas num 4.7.x, a subida dele é uma decisão com ADR, como esta.
