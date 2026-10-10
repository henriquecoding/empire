# Implementação da auditoria de 09/10/2026

Fonte: [auditoria entregue pelo dono](AUDITORIA-MESTRE-2026-10-09.md).
Regras: ADR 0082. Esta matriz distingue correção implementada de aceitação completa.
A validação e publicação identificam o commit; não alteram respostas guardadas no painel.

| Achado | Alteração | Limite / trabalho restante |
|---|---|---|
| AM-01 | Planeamento da cave antes da fundação; lados e baías alternativas; recusa explícita; entrada e baú exigem área válida; persistência | Não desloca interiores conhecidos; política de geometria documentada na ADR |
| AM-02 | Rampa 7; primeiro pico 12, cadência 6; CSV, recursos e relatório regenerados | Q-240 não fixa substituto para 3/6/9; afinação humana continua necessária |
| AM-03 | Despertar após fundação/noite/alvorada; nascimento global determinístico; obras pagas e trabalho real, depois guardas | Evolução avançada de cidades, companhias e campanha permanece no backlog |
| AM-04 | Manutenção contínua, perda por falta de fundos, novo treino, escolha na casa, recuperação de bónus e conservação de flechas | Elenco atual de três imperadores; encontros/rituais adicionais por implementar |
| AM-05 | Despesas domésticas pagas pelo tesouro; bolsa preservada; extrato e atraso visíveis | Não estabelece um novo balanceamento dos custos existentes |
| AM-06 | Recorte do subsolo oculto e de salas fora das janelas; evita recalcular reservas estrangeiras iguais a cada tick | Orçamento de GPU/dispositivos ainda exige medição representativa; Q-262 continua aberta |
| AM-07 | Build de produção espera pelo CI completo do mesmo SHA; seis testes do bloqueio; comprovativo público da autorização | Reconstrução do SHA aprovado; proteção de ramo administrativa é distinta |
| AM-08 | Acesso operacional separado da presença de rocha; fecho e reabertura recalculam produção sem apagar a obra | Rede de portos/rotas depende de Q-249/Q-250/Q-252 |
| AM-09 | Mantido como pendente, sem substituir números por valores inventados | Q-235/Q-252: modelo regional e meteorologia |
| AM-10 | Mantido como pendente | Q-247: pacto/evento de corrupção da tocha por definir |
| AM-11 | Água funcional representada no caminho com as coordenadas da fonte usada pelo pesqueiro | Lago com Ponte e Cais de Q-259 não foi presumido aprovado |
| AM-12 | Preservados os cenários e parallax integrados | Q-259–261: composição e transições específicas pendentes |
| AM-13/14 | Sem alterações aos pacotes de arte/áudio | Entrega de produção e aprovação estética continuam pendentes |
| AM-15 | Painel separa inventário e execução; data/SHA/run; JSON de cada execução no CI | Resultados históricos permanecem atribuídos às versões originais |
| AM-16 | Regressões dirigidas, suite, vistoria e capturas identificadas | Não equivalem a campanha humana longa ou certificação de comando/telefone físico |
| AM-17 | Pausa apresenta o dia do checkpoint; sair de noite tem rótulo correto | Retoma no checkpoint, não no segundo exato da noite |
| AM-18 | Escala 100/125/150% de texto/painéis, extrato, perda do herdeiro e motivos de acesso | Remapeamento completo e matriz física de dispositivos continuam por concluir |
| AM-19 | Banca básica de emissários acessível aos três imperadores sem conquista/Semente Real | Missões, captura/resgate, conquista presencial e governo completo não estão concluídos |
| AM-20 | Preservado o âmbito solo | Transporte, serviço e regras online de Q-236; coop/PvP não são entregues neste patch |

## Verificação

- Regressões `auditoria_*`: fundação com cavernas visitadas, treino/manutenção,
  dinheiro local, troca de imperador e flechas, nascimento social, exploração em
  ordens diferentes, trabalho de construção, acesso às minas, emissários e checkpoint.
- `tools/web/release-gate.test.mjs`: SHA errado, PR verde, workflow ausente, falha,
  cancelamento, reexecução e timeout não autorizam produção indevidamente.
- O inventário regenerado não atualiza resultados históricos. O JSON da suite
  efetivamente executada acompanha o artefacto `relatorio-gdunit4` de cada run.
- Capturas locais usam OpenGL Compatibility/Mesa llvmpipe; medem um renderer real
  em software, não o desempenho de uma GPU móvel.

## Evidência visual e reprodução

- [Opções a 150%, janela de 568 × 320](auditoria-2026-10-09/opcoes-150-compacto.png):
  a lista rola, a escala focada fica visível e Voltar permanece acessível.
  Reprodução: `tools/captura_menu.tscn -- saida.png options text150 textfocus --novo`.
- [Água funcional](auditoria-2026-10-09/agua.png): semente 20261007,
  monarca colocado a +1292 px do núcleo, primeiro amanhecer. A superfície usa
  o intervalo do recurso; esta captura é um estado preparado, não uma caminhada.
- Regressão da interface: 25 casos executados, sem falhas, incluindo confirmar
  e cancelar a sucessão. Regressão da fundação: 9 casos, sem falhas.
- O resultado definitivo da suite completa, da vistoria e dos exports é o CI
  associado ao commit do PR. Uma execução local interrompida não é uma aprovação.
