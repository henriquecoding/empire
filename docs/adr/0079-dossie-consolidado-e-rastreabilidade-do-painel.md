# ADR 0079 — Dossiê consolidado e rastreabilidade do painel

- Data: 2026-10-06; conclusão e reconciliação da base em 2026-10-07
- Estado: aceite para a consolidação documental; extensões regionais são propostas
- Pedido: atualizar intensamente o dossiê com as decisões do painel e os elementos de Civilization VII e Manor Lords, porque o projeto se baseia nele.

## Problema

O dossiê mantinha regras incompatíveis com decisões posteriores: troca livre entre imperadores, Casa do Herdeiro na Vila, tutorial com castelo e cronologia imposta, rei preso ao reino e povos ainda fora da campanha. Relatórios e respostas mais recentes não estavam integrados nas secções usadas para desenvolvimento. O estado «aplicada» no painel também não prova que toda a regra esteja implementada ou publicada.

## Decisão

1. `docs/dossie.html` continua a ser a fonte editável. `docs/design/` é regenerado por `tools/split_dossie.py`.
2. Atualizar as secções temáticas e acrescentar §§86–91: precedência, território/referências, mundo vivo, contratos de campanha, execução/aceitação e respostas consultadas.
3. Preservar a evidência literal num registo separado para o dono. O dossiê e o repositório público recebem apenas sínteses de design, IDs das perguntas, secções e alcance. Cruzar escolha, texto, pergunta e decisões posteriores; uma resposta parcial não aprova as restantes subperguntas.
4. Uma instrução explícita posterior prevalece apenas na cláusula incompatível. Dossiê descreve intenção; CSV e código descrevem execução; deployment identifica publicação. Divergências ficam nomeadas.
5. Desenvolver as relações entre ambiente, trabalho, crescimento e rede territorial já adotadas. A nova fórmula de afinidade regional fica proposta na Q-258, sem coeficientes ou mudanças na simulação.
6. Manter as Q-081/Q-112/Q-147/Q-191/Q-194 adiadas e os `_proposed` não abrangidos por resposta explícita.
7. Incorporar as respostas recentes Q-221/Q-235/Q-237/Q-239–Q-243 sem marcar os registos remotos como aplicados.

## Limites e consequências

A consulta começou no commit publicado `bafeb112` em main. Em 07/10, o PR #92 já estava integrado e publicado em `ba743da3a616d27a7df581646e9e7356134c89c8`; a revisão foi atualizada sobre essa base. As correções e a arte desse PR são trabalho recebido, não alterações documentais desta entrega. As ADRs 0075/0076 e as Q-247/Q-248 passam a constar das secções temáticas. As 226 respostas foram reconfirmadas integralmente; o mapa editorial deriva dessa leitura. Não se alteram arte, áudio, CSVs de balanceamento, saves, RLS ou mecânicas de jogo. A geração não pode deixar ficheiros antigos com o mesmo número de secção; referências internas são atualizadas com os novos títulos.

O portão do dossiê deve verificar a nova Parte XIV e o acesso às novas secções. A prova numérica existente continua a comparar a baseline com os CSV. Critérios de aceitação da §90 são contratos futuros, não resultados de testes realizados.

## Fontes

- `docs/reports/EMPIRE-MASTER.md`
- `docs/reports/VEGETACAO-BIOMAS.md`
- `docs/reports/SUBSOLO-ARMAZENS-DUNGEONS.md`
- `docs/reports/DECISOES-DOSSIE-2026-10-07.json`
- `docs/QUESTIONS.md`, ADRs 0052–0074 e backlog referido em §90
- Fontes oficiais das referências externas indicadas na §87

## Conclusão face ao relatório territorial — 07/10/2026

O dono pediu comparação com o relatório e publicação na main. §§92–96 completam fontes, água/portos, contratos, direitos, logística, arquitetura, migração e aceitação. A matriz de conformidade está em docs/reports/CONFORMIDADE-DOSSIE-CIVILIZATION-VII-2026-10-07.md.

A main avançou para 5b4b24a (PR #93/RG-28), reconciliada nesta revisão. ADR 0077 e Q-249–Q-252 da implementação conservam os IDs; esta ADR foi renumerada para 0078 e a afinidade regional para Q-258. Os estados do RG-28 não são reduzidos a «tudo pendente», nem a primeira fase é apresentada como o relatório inteiro implementado.

A nova consulta totaliza 229 respostas: Q-245 adiada, Q-247 com corrupção/consumo futuro da tocha e Q-248 com persistência confirmada. Apenas sínteses editoriais entram no repositório. Publicação explicitamente autorizada; nenhuma resposta remota é marcada em massa como aplicada.

A main avançou novamente durante a publicação: PR #94, f3efeac18b5732e68bad3154a0af340f9279d649, Atlas/UX-08/CV-01. Integração preservada. A ADR 0078 e Q-253–Q-257 pertencem a esse trabalho; a consolidação usa finalmente ADR 0079 e Q-258. As secções 24/90/92 refletem a ficha do sítio e a lacuna visual da Q-257.
