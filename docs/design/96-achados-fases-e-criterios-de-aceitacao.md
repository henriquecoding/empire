# 96 — Cobertura do relatório · Achados, fases e critérios de aceitação

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Resultado da comparação: a consolidação anterior cobria a visão territorial e a floresta, mas não o contrato completo do relatório. §§92–95 integram agora fontes, água, contratos, logística, arquitetura, geração e persistência. Esta secção conserva os critérios e dependências, sem atribuir aprovação a números exemplificativos nem conclusão às funcionalidades pendentes. O relatório original permanece datado; os estados abaixo foram reconciliados com main/5b4b24a.

## Achados reconciliados com a implementação

| Achado | Tema | Destino | Estado da implementação | Evidência/limite |
| --- | --- | --- | --- | --- |
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


## Evidência existente e limite dos casos territoriais

O RG-28 contém testes para T02/T03/T19 (fundação distante, local pobre e pagamento bloqueado), T06 (faixa/porão sem passagem), T10 (prévia versus confirmação), T44 (duas retomas) e T45 (obra legada tolerada). Ver tests/territorio_test.gd e tests/territorio_fundacao_test.gd. Esta correspondência é parcial: T10 ainda exige alteração da fonte entre prévia e confirmação; T44 exige também migração de versão quando houver um novo esquema; T06 não prova acesso por grafo. Não declarar o conjunto T01–T50 concluído com base nestes testes.

AUD-CIV-01–04 estão entregues no âmbito do protótipo; 07/08 são parciais; 12 cobre apenas a compatibilidade atual; 17 ainda exige o fluxo completo futuro. 05/06, 09–11, 13–16 e 18 permanecem pendentes. As tabelas seguintes conservam os requisitos de conclusão e a ordem do relatório.

## Plano de implementação e backlog

### Sequência recomendada

| Fase | Entrega | Saída verificável | Dependência |
| --- | --- | --- | --- |
| 0 — Reconciliação | Decisões, estados, versão e vocabulário | Matriz de verdade e ADRs do escopo novo | Nenhuma mudança de gameplay necessária. |
| 1 — Território funcional | Fontes, acesso e avaliador de implantação | Pesca, madeira e minério consultam a localização efetiva | Fase 0. |
| 2 — Água e escolha da base | Rede simples, ancoragens, cais/porto e pré-visualização | Comparação de local interior, fluvial e costeiro funciona | Fase 1. |
| 3 — Contrato mercenário | Companhia, guarnição/escolta, pagamento e término | Um contrato completo sobrevive a guardar/carregar | Fase 1; usa Fase 2 quando aquático. |
| 4 — Relações territoriais | Direitos, especialização, despertar e transporte simples | Dependência local resolvida por acordo verificável | Fases 2 e 3; integração RG-24 e UN pertinentes. |
| 5 — Profundidade | Reconhecimento, clima regional, eventos e aprendizagem | Estratégias distintas com custos claros | Evidência de playtest das fases anteriores. |
| 6 — Expansões | Logística maior, combate naval, coop/PvP | Apenas se justificadas pelo uso e pelo desempenho | Arquitetura própria e decisão específica. |


Não atribuo prazos em dias sem medir capacidade da equipa, cobertura reutilizável e produção de arte. O risco maior não é a quantidade de campos; é a integração com geração, reancoragem, economia e save. As fases devem ser entregues por ciclos completos, não por sistemas isolados sem utilização.

### Tickets propostos

Os identificadores AUD-CIV-* conservam o escopo e as dependências do relatório. O RG-28 já os rastreia; consultar a sua matriz e a atualização no início desta secção para o estado real. A coluna «critério de conclusão» abaixo é um requisito, não um resultado obtido.

| Ticket | Objetivo | Critério de conclusão | Dependências |
| --- | --- | --- | --- |
| AUD-CIV-01 | Reconciliar decisões e estados | Q-221, save v12, regras de acampamento e fontes de verdade alinhadas | Nenhuma. |
| AUD-CIV-02 | Inventariar capacidades e fontes | Água, floresta e rocha deixam de depender apenas da etiqueta do bioma | 01. |
| AUD-CIV-03 | Avaliador comum de implantação | Prévia e confirmação devolvem o mesmo resultado e razão | 02. |
| AUD-CIV-04 | Corrigir ligação da reancoragem à geografia | Nova sede não herda autorização indevida do segmento inicial | 03. |
| AUD-CIV-05 | Rede de água mínima | Rio navegável, costa e lago têm conectividade distinta | 02. |
| AUD-CIV-06 | Cais e porto por dados | Construir, operar e abrir rota são estados separados | 03, 05. |
| AUD-CIV-07 | Comparação territorial na fundação | Mostra capacidades, perdas e dependências; confirmação revalida | 03–06. |
| AUD-CIV-08 | Regras ambientais generalizadas | Efeitos limitados, métricas corretas e sem duplicação da floresta | 02, 03. |
| AUD-CIV-09 | Companhia e ofertas | Efetivos finitos, ofertas persistentes e motivos legíveis | 01; regra de legado decidida. |
| AUD-CIV-10 | Contrato e livro de obrigações | Aceitação, cobrança, prazo e término idempotentes | 09. |
| AUD-CIV-11 | Guarnição e escolta | Cumprimento ligado a unidades e percurso reais | 10; missão mínima. |
| AUD-CIV-12 | Migração e compatibilidade | Saves v12 preservam sede, economia, acampamentos e subsolo | 04–11; desenvolvido em conjunto, não só no fim. |
| AUD-CIV-13 | Direitos de uso e passagem | Acordo desbloqueia uma capacidade concreta e revogação é explicada | 03, 10. |
| AUD-CIV-14 | Despertar e evolução distante | Calendário social independente da primeira visita | RG-24; 02, 09. |
| AUD-CIV-15 | Remessa e transporte | Conservação de stock e entrega única | 06, 11, 13. |
| AUD-CIV-16 | Especialização de vassalos | Uma dependência económica resolvida sem microgestão de outro reino | 13–15. |
| AUD-CIV-17 | Export web e interação móvel | Fluxo completo legível, controlável e persistente | Primeiro ciclo integrado. |
| AUD-CIV-18 | Playtest e equilíbrio | Comparação de estratégias, compreensão e custos registados | 07, 11, 12, 17. |


### O que constitui o primeiro ciclo completo

O primeiro ciclo fica pronto quando uma nova partida oferece escolhas territoriais distintas; a prévia informa; a fundação preserva o lugar; uma instalação usa a fonte correta; uma companhia vende um serviço delimitado; as moedas e os efetivos são contabilizados; guardar/carregar mantém o resultado; e o mesmo fluxo funciona no export web.

Pode usar arte provisória autorizada e poucas variantes de conteúdo. Não pode depender de bónus falsos, portos sem água funcional ou contratos que existem apenas num painel.

## Validação e critérios de aceitação

### Matriz de testes proposta

Esta é a matriz integral de aceitação do relatório. O RG-28 acrescentou cobertura parcial identificada no início desta secção; os restantes casos continuam por implementar ou executar. A matriz não declara cinquenta testes aprovados. A exigência de testes para funções públicas de simulação vem das regras do repositório.

| ID | Cenário | Resultado exigido |
| --- | --- | --- |
| T01 | Fundação em dois biomas na mesma partida de referência | Cada perfil reflete a posição efetiva. |
| T02 | Fundação distante do segmento inicial | Nenhum requisito usa implicitamente o recurso inicial. |
| T03 | Local pobre mas fisicamente válido | Pode fundar, com dependências explicadas. |
| T04 | Sede sobre ponto protegido | Recusa preservando regra existente e sem cobrar. |
| T05 | Clareira inicial | Perda prevista igual à aplicada; nenhuma madeira gratuita. |
| T06 | Fonte próxima sem passagem entre faixas | Produção dependente bloqueada por acesso. |
| T07 | Reabertura de passagem | Capacidade recupera sem recriar a fonte. |
| T08 | Árvores além de uma parede | Habitat segue regra ecológica; transporte segue caminho. |
| T09 | Duas instalações sobre a mesma fonte | Respeitam capacidade partilhada e limites de acumulação. |
| T10 | Corte entre prévia e confirmação | Resultado atualizado antes da ação irreversível no jogo. |
| T11 | Ribeira não navegável | Água doce não autoriza cais de carga. |
| T12 | Rio navegável com margem livre | Cais elegível; rota depende ainda de destino. |
| T13 | Lago fechado | Serviço local possível; rota marítima impossível. |
| T14 | Costa com falésia | Exige ancoragem/acesso adequado. |
| T15 | Estuário | Usa continuidade e salinidade corretas, sem duplicar capacidades. |
| T16 | Obstáculo aquático | Divide percursos conforme a classe de embarcação. |
| T17 | Fecho temporário de trecho | Suspende operação, preserva edifício e carga. |
| T18 | Destino não descoberto | Interface não revela informação indevida. |
| T19 | Construção por caminho alternativo de código | Não contorna requisitos do avaliador. |
| T20 | Alteração de estação regional | Só aplica fatores apropriados; mantém alternativas. |
| T21 | Reabrir oferta/carregar save | Termos iguais enquanto o contexto não muda. |
| T22 | Duas aceitações para os mesmos mercenários | Uma reserva válida; sem duplicar unidades ou pagamento. |
| T23 | Falta de moedas na aceitação | Nenhum débito parcial nem efetivos presos. |
| T24 | Pagamento inicial | Total e saldo remanescente calculados uma vez. |
| T25 | Alvorada repetida por reload | Cobrança não é duplicada. |
| T26 | Mercenário contratual com manutenção normal | Salário não é cobrado duas vezes. |
| T27 | Fim do prazo | Serviço termina sem renovação oculta. |
| T28 | Incumprimento | Aviso, prazo e consequência correspondem aos termos. |
| T29 | Pagamento residual repetido | Não prolonga tolerância infinitamente. |
| T30 | Falta de pagamento em combate | Comportamento previsto, sem teletransporte ou traição arbitrária. |
| T31 | Perda de unidade durante serviço | Aplica cláusula de perdas sem recriar unidade. |
| T32 | Cancelamento antes e depois de mobilizar | Reembolso e custos correspondem ao estágio real. |
| T33 | Missão muda para fora do âmbito | Exige novo acordo ou recusa explicada. |
| T34 | Companhia sem efetivos suficientes | Recusa ou oferece composição válida. |
| T35 | Acampamento legado com três contratações | Mantém estado de esgotamento após migração. |
| T36 | Fonte estrangeira com direito negociado | Produção habilita apenas no âmbito concedido. |
| T37 | Expiração/revogação de passagem | Rota atualiza sem destruir bens silenciosamente. |
| T38 | Remessa entregue e save recarregado | Stock e rendimento aplicados uma única vez. |
| T39 | Remessa capturada | Conservação de quantidade e detentor. |
| T40 | Aldeia visitada tarde | Estado social segue calendário global, não a hora de visita. |
| T41 | Mundo antes do despertar | Respeita regra de novas partidas e exceções legadas. |
| T42 | Simulação próxima versus distante | Mesmo saldo, efetivos, carga e eventos finais relevantes. |
| T43 | Duas ordens de exploração da mesma semente | Mesmas fontes e identidades físicas. |
| T44 | Save v12 migrado duas vezes | Sem duplicação de fontes, moeda, clareira ou sociedade. |
| T45 | Instalação legada tolerada | Exceção não permite construir cópias inválidas. |
| T46 | Fonte junto de cave/masmorra reservada | Não viola entrada nem área útil subterrânea. |
| T47 | Teclado, comando e toque | Todas as decisões essenciais são alcançáveis e legíveis. |
| T48 | Export web guardar/carregar | Contrato e perfil territorial persistem corretamente. |
| T49 | PT/EN e razões de recusa | Não aparecem chaves internas nem texto cortado em ações críticas. |
| T50 | Eventos simultâneos de entrega, cobrança e fim | Ordem determinística e saldos conservados. |


### Testes de propriedades e geração

Além de cenários específicos, testar conservação de moeda/carga, unicidade de fontes/contratos e equivalência de ordem de geração. Uma campanha de 1.000 sementes é uma proposta de cobertura para a validação do gerador, não um teste já realizado nem garantia estatística suficiente por si só.

Registar sementes que falham e reduzir o caso até uma reprodução pequena. Verificar especialmente extremos: pouco espaço, várias passagens próximas, costa sem ancoragem, misturas de bioma e fronteiras entre faixas. Não corrigir uma semente problemática apenas deslocando o jogador para um local privilegiado sem regra geral.

### Playtests orientados a decisões

| Hipótese | Como medir | Sinal de revisão |
| --- | --- | --- |
| O jogador compreende a vantagem do local | Pedir que explique duas vantagens e uma dependência antes de fundar | Escolha baseada apenas em estética ou tentativa/erro. |
| Existem estratégias distintas | Observar escolhas em várias sementes e perfis de jogador | Um tipo de local domina quase todas as escolhas. |
| O contrato é compreensível | Perguntar total, prazo e consequência de atraso | Confusão entre depósito, preço total e salário. |
| Explorar compensa sem se arrastar | Medir tempo até fundação e descobertas que alteram a decisão | Procura exaustiva obrigatória ou fundação sem interesse. |
| Uma deficiência territorial tem saída | Acompanhar uma campanha sem recurso local importante | Bloqueio de progressão ou solução universal demasiado barata. |
| A camada nova preserva o ritmo | Observar noites iniciais, interrupções e tempo em menus | Sobrecarga de decisões antes de dominar o ciclo básico. |


Como ponto de partida, pode-se procurar compreensão correta em pelo menos 8 de 10 sessões de teste iniciais. É um limiar proposto para revisão qualitativa, não uma estimativa de toda a população de jogadores. Desempenho deve ser comparado com uma linha de base medida no mesmo dispositivo; nenhum ganho de desempenho é afirmado neste relatório.

### Gate de conclusão

A entrega só deve ser considerada concluída quando código, dados, documentação, migração e interface concordarem. CI aprovado é necessário, mas não substitui o cenário jogado no export web. A documentação de validação deve apontar para o commit exato e distinguir casos automatizados de verificações manuais.

## Cenário completo de referência

Este cenário descreve o comportamento desejado e pode orientar uma demonstração integrada.

Exploração. A caravana encontra um vale com floresta e uma margem fluvial fértil. O primeiro oferece madeira e habitat; o segundo oferece agricultura e um cais possível. Um relato indica minério a leste, mas a passagem ainda não foi inspecionada.

Comparação. Na margem, a prévia mostra que a clareira remove parte da cobertura de caça. O cais será construível, mas ainda não há rota externa conhecida. O vale não terá navegação; a sua produção inicial será menos dependente de transporte de madeira.

Fundação. O jogador escolhe a margem. A assinatura guarda esse momento; a floresta efetivamente removida coincide com a prévia. Nada desloca a jazida, o rio ou as passagens para acompanhar a sede.

Despertar. Depois do gatilho social aprovado, uma companhia e um povo vizinho evoluem segundo o calendário global. A primeira visita revela o estado que já lhes corresponde, sem produção retroativa duplicada.

Negociação. A companhia oferece guarnição curta e uma escolta. O jogador precisa de madeira e aceita escolta até uma floresta acessível por acordo. Os termos mostram pagamento inicial, salários, área e término. A companhia reserva efetivos reais.

Operação. O cais tem pessoal e acesso, mas só abre comércio quando um destino é conhecido e aceita a ligação. A entrega retira madeira da origem e acrescenta-a à base uma vez. A escolta termina no marco acordado e as unidades regressam.

Mudança. Uma condição temporária suspende um trecho do rio. O porto continua construído; a interface mostra o motivo e a carga aguarda. Uma ligação terrestre conhecida pode ser contratada, com custo superior, sem criar recursos adicionais.

Persistência. O jogador guarda e retoma. Mantêm-se a dívida já paga, o calendário do serviço, a carga, as árvores cortadas e a origem dos recursos. Nenhum evento cobra ou produz uma segunda vez.

O resultado pretendido é uma história produzida por decisões compreensíveis: a margem foi escolhida pelo futuro fluvial, a falta de madeira criou um acordo, o acordo tornou a escolta valiosa e a interrupção do rio gerou uma alternativa. Não foi necessário acrescentar um sistema 4X completo.

## Decisões recomendadas e limites de escopo

### Proposta de decisão para o próximo ciclo

| Tema | Recomendação | Estatuto |
| --- | --- | --- |
| Geografia | Fonte concreta + acesso + direito + exploração | Proposta técnica que operacionaliza o pedido atual. |
| Fundação | Livre em local fisicamente válido, com consequências visíveis | Preservação de decisão existente. |
| Base original | Continua a ser a sede; postos e vassalos complementam | Preservação de decisão existente. |
| Água | Separar curso menor, navegável, lago e mar | Proposta. |
| Porto | Construção, operação e rota avaliadas separadamente | Proposta. |
| Recursos | Usar materiais existentes; capacidades ambientais não viram novas moedas | Proposta de contenção de escopo. |
| Mercenários | Ofertas limitadas, contrato explícito e efetivos finitos | Proposta central. |
| Relações | Favor/histórico simples antes de reputação global complexa | Proposta. |
| Incumprimento | Aviso, prazo, suspensão e consequência previsível | Proposta que exige revisão das regras históricas incompatíveis. |
| Acampamentos | Legado preservado; companhia persistente versionada | Proposta de compatibilidade, sem revogação silenciosa da regra antiga. |
| Clima | Perfis regionais e alternativas antes de catástrofes | Alinhamento com decisões recentes; detalhes por aprovar. |
| Rede | Preparar identidades e autoridade; entregar solo primeiro | Proposta de sequência. |


### O que não deve entrar por acidente

- Um requisito universal de mar, rio ou minério próprio para concluir a progressão básica.
- Outra moeda obrigatória apenas para imitar Influência de Civilization.
- Um inventário genérico do imperador que substitua os stocks e a moeda física.
- Uma segunda base soberana criada automaticamente por comércio ou vassalagem.
- Companhias infinitas, salários invisíveis, renovação automática ou traição não anunciada.
- Bonificações multiplicativas sem teto e fontes duplicadas por reancoragem ou save.
- Combate naval, fluidos, mundo hexagonal ou grandes árvores tecnológicas como pré-requisito para construir o primeiro cais.

### Ordem de decisão quando houver conflito

O pedido atual determina a direção nova. As decisões explícitas anteriores continuam a orientar identidade, fundação, vassalos e controlo do personagem. O código auditado determina o que já funciona; não transforma automaticamente uma implementação parcial na regra desejada. Este relatório identifica propostas e incompatibilidades para que os próximos ADRs possam ser concretos.

Para iniciar implementação, o conjunto mais importante a consolidar é: contrato territorial, política de portos, modelo de serviço mercenário e tratamento dos acampamentos legados. Não é necessário decidir agora todos os valores finais, eventos ou tipos de embarcação.

## Proveniência e leitura das propostas

Fonte: relatório integral, fornecido pelo dono; reprodução verificada contra o anexo. As fontes C1–C15/E1–E20 e a data de corte permanecem na §23 desse relatório. As referências a capítulos numerados no conteúdo integrado referem-se ao relatório original. Matriz da revisão. As propostas detalhadas complementam o trabalho autorizado; valores exemplificativos, _proposed e decisões adiadas não recebem aprovação implícita.
