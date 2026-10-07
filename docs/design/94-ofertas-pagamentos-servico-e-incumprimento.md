# 94 — Companhias e contratos · Ofertas, pagamentos, serviço e incumprimento

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Estado: recrutamento, soldo e esgotamento legado existem; ofertas persistentes, contratos e liquidação não estão entregues. Este é o desenho proposto para a Q-251 e UN-18–UN-21. Os valores e riscos antigos da §14 conservam-se como referência histórica/CSV, sem se tornarem o contrato novo. Nenhuma dívida nasce automaticamente ao abrir uma negociação.

## Negociação com mercenários

### Objetivo da negociação

O jogador deve escolher que problema quer resolver e que compromisso aceita. Descontos podem existir, mas o interesse principal está na troca entre preço, prazo, risco, disponibilidade e âmbito do serviço.

Uma companhia de batedores pode conhecer caminhos e preferir contratos curtos; uma companhia defensiva pode aceitar guarnição prolongada em troca de alojamento e previsibilidade. Estas preferências têm de afetar ofertas, sem exigir uma conversa livre gerada por IA.

### Identidade mínima de uma companhia

| Campo conceptual | Função |
| --- | --- |
| Identidade e origem | Continuidade entre encontros e saves. |
| Especialidade | Define vantagens e contratos adequados. |
| Efetivos disponíveis | Impede vender as mesmas unidades várias vezes. |
| Base/acampamento e posição | Localiza recrutamento, regresso e necessidades. |
| Necessidade principal | Dinheiro, descanso, abastecimento, acesso ou proteção. |
| Relação com o reino | Confiança e condições futuras, separadas de uma dívida concreta. |
| Compromissos ativos | Disponibilidade real e incompatibilidade entre trabalhos. |
| Memória contratual | Pagamentos, perdas, conclusão e quebras relevantes. |


No primeiro ciclo, duas especialidades e um conjunto pequeno de necessidades são suficientes. Personalidade não deve significar dezenas de variáveis ocultas.

### Serviços recomendados

| Serviço | Resultado contratado | Condição de conclusão | Prioridade |
| --- | --- | --- | --- |
| Guarnição temporária | Proteger uma zona definida | Fim do prazo ou condição contratada | Primeiro ciclo. |
| Escolta | Acompanhar pessoa ou remessa por rota acordada | Chegada e entrega confirmada | Primeiro ciclo, inicialmente numa rota simples. |
| Reconhecimento | Revelar acessos e oportunidades de uma área | Relatório entregue | Segundo incremento; depende do modelo de conhecimento. |
| Patrulha de rota | Manter circulação num trajeto | Serviço por períodos definidos | Depois das rotas. |
| Expedição de acesso | Explorar ou proteger passagem/jazida | Marco verificável | Depois do subsolo e das missões. |
| Apoio a cerco | Objetivo militar delimitado | Retirada, vitória ou limite do contrato | Posterior; risco elevado de escopo. |


O reconhecimento não deve revelar tesouros ou inimigos que o grupo nunca alcançou. Uma escolta não deve transformar-se automaticamente em participação em todas as guerras do reino.

### Três ofertas úteis em vez de regateio infinito

Na abertura, apresentar até três alternativas comparáveis:

1. Serviço curto: menor compromisso total; menor duração e âmbito.
1. Serviço regular: melhor custo por período; reserva de efetivos mais longa.
1. Serviço com contrapartida: dinheiro mais uma obrigação concreta, como abastecimento ou acesso autorizado.

A contraproposta altera um eixo de cada vez: duração, efetivos, área ou pagamento. Não permite reduzir o preço infinitamente por repetição. O interlocutor explica o fator decisivo: “A rota atravessa território hostil”, “Precisamos de pagamento adiantado” ou “A companhia já tem homens comprometidos”.

A oferta tem identidade, versão e validade. Reabrir a janela ou carregar o save não produz novas condições aleatórias. Quando o contexto mudar, a atualização deve ser explicada.

### Avaliação determinística da proposta

O motor deve avaliar remuneração, duração, risco conhecido, distância, necessidade da companhia e histórico. Pode usar faixas de aceitação e contrapropostas por dados. Não precisa simular um negociador humano nem usar um modelo de linguagem.

Regra essencial: a IA negocia com informação coerente com o seu conhecimento. Não cobra um prémio por um inimigo secreto que nem o jogador nem a companhia detetaram. Se houver risco adicional desconhecido, ele pertence à incerteza do contrato, não a uma leitura omnisciente do mapa.

O resultado pode ser aceitar, recusar com razão ou devolver uma contraproposta. Sorteios narrativos, quando existirem, usam o RNG autorizado e ficam persistidos no evento; não determinam secretamente a fidelidade de um contrato já aceite.

### Relação, reputação e confiança

Recomendo começar com uma relação por companhia e um histórico curto de contratos. Uma reputação global mais detalhada pode esperar.

Cumprir um acordo aumenta a disponibilidade ou reduz certas exigências futuras. Perdas previstas em combate não equivalem automaticamente a traição do empregador; enviar uma escolta para um objetivo não acordado pode ser uma quebra. A regra deve distinguir resultado infeliz de incumprimento.

Boa relação deve abrir opções, não eliminar todos os custos. Uma companhia amiga ainda paga os seus membros e não dispõe de efetivos ilimitados.

## Contratos, pagamentos e incumprimento

### Conteúdo mínimo de um contrato

| Grupo | Informação obrigatória |
| --- | --- |
| Partes | Reino pagador e companhia prestadora. |
| Serviço | Tipo, objetivo, zona e limites da ordem. |
| Efetivos | Unidades reservadas, papel e capacidade mínima. |
| Tempo | Início, períodos pagos, termo e eventual prazo de chegada. |
| Preço | Mobilização, pagamentos periódicos, prémio de risco e teto total. |
| Pagamento | O que foi pago, o que está reservado e o que vence depois. |
| Abastecimento | Quem fornece provisões/equipamento e onde. |
| Desfecho | Sucesso, interrupção, cancelamento, atraso e regra de reembolso. |
| Perdas | Se existe compensação e em que condições; zero também deve ser explícito. |
| Evidência | Versão da oferta, aceite e eventos já liquidados. |


Não introduzir renovação automática silenciosa. Não criar dívida por deixar cair uma moeda perto de um acampamento. A confirmação do contrato deve ser um ato inequívoco dentro do sistema de interação existente.

### Exemplo financeiro completo

Valores exclusivamente ilustrativos, para demonstrar a apresentação e a contabilidade. Não são preços aprovados nem uma medição do equilíbrio atual.

| Componente | Guarnição de dois guardas, por três períodos diários |
| --- | --- |
| Mobilização, paga ao aceitar | 4 moedas |
| Salário por período, para o par | 2 moedas |
| Três períodos de salário | 6 moedas |
| Total contratado | 10 moedas |
| Pago na aceitação | 4 moedas |
| Restante, explicitamente anunciado | 6 moedas |


Se uma escolta equivalente acrescentar um prémio de risco de 2 moedas pago na aceitação, o total será 12, o pagamento inicial 6 e o restante 6. Uma caução que conta para o preço não pode ser somada outra vez ao total.

O CSV atual contém um salário mercenário diário de 1 marcado como proposta; a coincidência com o exemplo não o transforma em decisão aprovada. A implementação deve esclarecer também se o primeiro período começa na aceitação, na chegada ou numa fase do relógio. Recomendo iniciar a cobrança do serviço quando ele estiver disponível, cobrando deslocação separadamente apenas se tiver sido acordada.

### Fonte do dinheiro e compatibilidade com a moeda física

O contrato precisa declarar uma fonte de pagamento. No primeiro ciclo, deve usar o mecanismo económico já existente e autorizado pelo reino, sem criar um novo saldo invisível.

Uma reserva de pagamento, quando utilizada, deve transferir ou marcar moedas de forma contabilisticamente real. Não pode manter o dinheiro simultaneamente disponível na bolsa e garantido ao prestador. A criação do contrato, a reserva de efetivos e o débito inicial devem formar uma operação indivisível: ou todos acontecem, ou nenhum acontece.

Fases futuras podem permitir pagamento através de tesouros locais e missões diplomáticas. Isso depende do trabalho de autonomia e orçamento previsto no backlog; não deve ser apresentado como já funcional.

### Ciclo de vida

| Estado | Transição normal |
| --- | --- |
| Oferta | Recusar/expirar encerra; aceitar e validar reserva. |
| Reservado | Mobilizar e deslocar unidades reais. |
| Em deslocação | Chegada inicia serviço ativo. |
| Ativo | Objetivo/prazo conclui; obrigação em falta gera aviso. |
| Aviso | Regularização retoma; fim de tolerância suspende. |
| Suspenso ou concluído | Regresso acordado e acerto de saldo. |
| Liquidado | Contrato encerrado; eventos económicos não se repetem. |


Captura, morte, perda da companhia e cancelamento devem ser eventos explícitos com regras próprias. A representação acima descreve o caminho normal e o incumprimento financeiro; não é uma lista completa de todas as transições militares.

### Consequências proporcionais

Recomendo esta sequência para falta de pagamento: aviso com montante e prazo; limitação de novas ordens; suspensão; retirada para local seguro quando possível; consequência na relação; cobrança contratual se estiver prevista.

Não recomendo mudança instantânea de dono, traição aleatória ou juros exponenciais sem teto. Também não recomendo que um pagamento residual de uma moeda reinicie indefinidamente o prazo. Uma renegociação deve alterar o saldo e o calendário uma vez, com condições explícitas.

O contrato deve definir o comportamento se a falta de pagamento ocorrer durante um combate. A saída não pode teletransportar unidades nem surpreender o jogador com uma exceção invisível. O encerramento seguro e a responsabilidade por perdas devem fazer parte dos termos.

### Livros separados

Separar pelo menos três conceitos: obrigação mercenária, acordo diplomático e dívida sobrenatural de Candeia. Podem aparecer num resumo comum de compromissos, mas não partilham automaticamente juros, penalizações ou consequências de propriedade.

Prisioneiros, resgate e diplomata capturado são compatíveis com a visão existente, mas pertencem a uma etapa posterior. O primeiro contrato de guarnição não deve depender da implementação de toda essa cadeia.
