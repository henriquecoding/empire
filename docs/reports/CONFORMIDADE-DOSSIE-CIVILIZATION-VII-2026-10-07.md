# Conformidade do dossiê com o relatório territorial

Revisão: 07/10/2026. Pedido: verificar a consolidação face ao relatório em implementação e publicar na main. Baseline territorial: main/5b4b24a (PR #93, RG-28). Base final reconciliada: main/f3efeac18b5732e68bad3154a0af340f9279d649 (PR #94, Atlas/UX-08/CV-01).

**Conclusão:** a revisão anterior era parcial. A revisão atual integra os contratos em §§92–96, liga-os às secções originais e preserva os critérios do relatório. Conformidade documental não equivale à implementação completa do jogo.

## Fonte e integridade

Anexo do dono idêntico a [TERRITORIO-CIVILIZATION-VII.md](TERRITORIO-CIVILIZATION-VII.md), já integrado por RG-28. SHA-256: `51cb947b59c1958f26f94977b084225d00f9876262d51dea0e14027627c4cd79`. A fonte conserva a data de corte 06/10 e o commit auditado bafeb112; não se reescrevem os resultados históricos.

## Correspondência integral

| Capítulo do relatório | Tema | Secções do dossiê |
|---|---|---|
| 1 | Conclusões e prioridades | 90, 96 |
| 2 | Escopo, evidência e limites | 90, 96 |
| 3 | Decisões do projeto que orientam a proposta | 00, 86, 88–89 |
| 4 | Estado real do projeto | 90, 92, 96 |
| 5 | Achados da auditoria | 96 |
| 6 | Civilization VII: referência atual e transferibilidade | 87, 96 |
| 7 | Modelo territorial recomendado | 92 |
| 8 | Água, rios, costa e portos | 93 |
| 9 | Exploração e escolha da base | 25, 92 |
| 10 | Influências, produção e equilíbrio ambiental | 87, 92 |
| 11 | Negociação com mercenários | 94 |
| 12 | Contratos, pagamentos e incumprimento | 94 |
| 13 | Comércio, rotas e autonomia dos povos | 88, 95 |
| 14 | Outras adaptações úteis de Civilization VII | 95 |
| 15 | Experiência de utilização | 92–95 |
| 16 | Arquitetura e integração no código | 95 |
| 17 | Dados, geração e persistência | 62, 95 |
| 18 | Infraestrutura, segurança e rastreabilidade | 90, 95–96 |
| 19 | Plano de implementação e backlog | 96 |
| 20 | Validação e critérios de aceitação | 96 |
| 21 | Cenário completo de referência | 96 |
| 22 | Decisões recomendadas e limites de escopo | 96 |
| 23 | Fontes e mapa de evidências | 96 e relatório original |

## Achados e estado real

| Achado | Tema | Destino | Estado da implementação | Evidência/limite |
|---|---|---|---|---|
| A01 | Elegibilidade e reancoragem | §92; RG-28 | Corrigido no protótipo | PlacementRules, TerritoryWatch; territorio_fundacao_test |
| A02 | Assinatura e perfil vivo | §92 | Parcial | Assinatura v2; direitos e acessos completos pendentes |
| A03 | Água e portos | §93; Q-250 | Parcial | Fontes posicionadas; navegação/portos ausentes |
| A04 | Geologia e extração | §92; Q-252 | Parcial | Porões/cavernas; jazidas próprias pendentes |
| A05 | Influência ecológica e transporte | §87, §92 | Floresta conservada; extensão pendente | ADR 0070/0073; caminho não equivale a proximidade |
| A06 | Negociação mercenária | §94; Q-251 | Por implementar | Recrutamento não demonstra contrato |
| A07 | Dívida e penalizações | §14, §94 | Proposta por fechar | Separar obrigações; sem transportar juros antigos |
| A08 | Companhias e acampamentos legados | §94–§95; Q-251 | Por implementar | Preservar três contratações/esgotamento |
| A09 | Despertar social | §88, §95; RG-24 | Por implementar | Calendário independente da primeira visita |
| A10 | Logística física | §95; Q-252 | Por implementar | Conservação de carga; entrega única |
| A11 | Clima regional | §87, §92, §95 | Direção aprovada; execução pendente | Q-235; alternativas sazonais |
| A12 | Rastreabilidade e governação | §86, §90–§91, §96 | Consolidado documentalmente | main é agora também ramo predefinido; RG-28 e ADR 0079 |

## O que foi acrescentado

- Seis condições do recurso: existência, conhecimento, acesso, direito, exploração e abastecimento; perfil vivo separado da assinatura.
- Tipos e conectividade da água; construção, operação e rota como estados distintos.
- Companhias, ofertas persistentes, compromissos limitados, contabilidade, incumprimento e legado.
- Direitos, conservação de remessas, autonomia distante, módulos/dados, migrações e compatibilidade.
- Matriz integral AUD-CIV-01–18 e T01–T50, com limites dos testes já existentes no RG-28.
- Decisões Q-245/Q-247/Q-248 e atualização do mapa editorial, sem respostas literais ou metadados administrativos novos.

## Precedência e decisões abertas

ADR 0077 e Q-249–Q-252 pertencem ao RG-28 já publicado. A consolidação usa ADR 0079; a afinidade regional antes chamada Q-249 passa a Q-258 para evitar colisão. Q-250 (água/porto), Q-251 (contratos/legado), Q-252 (sequência) e Q-258 (afinidade regional) conservam os âmbitos por decidir. Os preços exemplificativos, métricas propostas e a campanha de 1.000 sementes do relatório não são resultados medidos.

## Verificação e entrega

Regenerar docs/design a partir de docs/dossie.html; conferir valores com CSV, referências, pesquisa, âncoras e leitura móvel; executar o CI no SHA da revisão e verificar o manifesto da produção após integrar. Resultados e URLs definitivos ficam no PR, evitando afirmar aqui resultados de um commit ainda não testado. O conteúdo de gameplay do RG-28 é preservado; esta entrega modifica documentação e verificações de navegação.

## Atualização recebida durante a entrega

O PR #94 acrescentou o Atlas, a ficha da fundação e o diagnóstico de fontes. Preservados sem alterações. A Q-257 identifica uma divergência entre água funcional e o cenário; §§24/90/92 tornam explícito que a validação do território não prova ainda concordância visual. A ADR 0078 e Q-253–Q-257 deste trabalho mantêm os seus IDs; esta consolidação passa a ADR 0079 e afinidade regional Q-258.
