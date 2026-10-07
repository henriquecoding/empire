# 95 — Redes e persistência · Direitos, logística, arquitetura e compatibilidade

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Estado: esta secção especifica a continuação de RG-28, RG-24, RG-12–RG-15 e Q-252. PlacementRules/TerritoryProfile já têm implementação parcial; direitos, remessas e contratos não são funcionalidades concluídas. A Q-245 foi explicitamente adiada: fauna, ladrão, transporte subterrâneo por categorias e reservas visuais abrangidos por essa pergunta não são reativados por este relatório. A nova versão de save só é atribuída quando necessária; RG-28 mantém v12.

## Comércio, rotas e autonomia dos povos

### A negociação deve resolver limites territoriais

Um reino interior sem costa pode negociar acesso a um porto vassalo ou estrangeiro. Uma base florestal pode trocar produção por minério. Uma companhia pode aceitar escolta de uma rota que também a abastece. Assim, a localização continua importante sem condenar quem não encontrou todos os recursos.

| Acordo | O que concede | O que não concede |
| --- | --- | --- |
| Passagem | Trânsito num percurso definido | Propriedade, extração ou acesso militar ilimitado. |
| Exploração | Uso limitado de uma fonte | Anexação automática do povo proprietário. |
| Serviço portuário | Uso de ancoragem e capacidade contratada | Posse do porto nem ligação a qualquer oceano. |
| Fornecimento | Entrega de quantidade/tipo num período | Duplicação dos recursos que o fornecedor mantém. |
| Tributo | Prestação acordada de um vassalo | Microgestão completa da sua economia. |


### Duas etapas de logística

Etapa inicial: capacidades locais, direitos e ligações explicáveis; um serviço de transporte simples quando necessário. Se o comércio ainda for abstrato, a interface deve dizer que paga por uma ligação/serviço, sem fingir uma carga que não existe.

Etapa seguinte: remessas com origem, destino, quantidade, transportador, estado e eventos de entrega. Madeira, minério, peixe, grão e produtos existentes devem ser suficientes para começar. Não acrescentar uma dúzia de materiais antes de validar o transporte de um deles.

Uma rota precisa respeitar a capacidade do seu trecho mais limitado. Pode ser útil expressar o limite assim:

capacidade da rota = mínimo entre carga, transporte, porto, passagem e receção

Os custos devem incluir o que o jogo realmente simula: operação, salários, serviço portuário ou perdas. Não inventar rendimentos para compensar uma cadeia que não fecha economicamente.

### Contabilidade e interrupção

Uma remessa sai do stock ou fica formalmente reservada; ao entregar, entra no destino uma única vez. Se for capturada, muda de detentor; se for destruída, a perda fica registada. Cancelar a rota não pode fazer o produto reaparecer na origem depois de já ter chegado.

A atualização fora de cena deve usar o mesmo calendário e as mesmas regras de eventos. Ao reentrar numa área, materializam-se os estados resultantes, não uma segunda simulação do período ausente.

Uma interrupção de água pode conduzir a espera, transbordo ou alternativa terrestre, se existir. O primeiro ciclo pode apenas suspender a operação com motivo legível; desvio automático complexo não é obrigatório.

### Povos e vassalos especializados

O código de assentamentos já paga salários, produz, repara e repõe parte da defesa. Isso oferece um ponto de partida para especializações simples: agrícola, florestal, mineira, portuária ou defensiva.

A especialização deve emergir de capacidades locais mais uma escolha ou tendência cultural. Não atribuir um porto funcional a um povo apenas porque se chama Portuários. Identidade cultural e condições físicas podem entrar em tensão e gerar uma missão ou necessidade de acesso.

Vassalagem preserva a autonomia decidida para o projeto. O jogador escolhe acordos e prioridades limitadas; não passa a administrar manualmente cada casa. Custos de distância e defesa podem limitar a expansão de forma orgânica, depois de haver meios claros de os reduzir.

### Companhias também vivem no mundo

Uma companhia precisa reservar os próprios efetivos, receber pagamento, recuperar e deslocar-se. A reposição pode ser simplificada, mas não deve ignorar o calendário. Se aceitar dois contratos incompatíveis, o segundo é recusado ou remarcado.

Para companhias móveis, o calendário social deve existir antes da primeira visita, com estado determinístico. O mundo não precisa simular cada passo distante; precisa conservar disponibilidade, posição aproximada, compromissos e eventos relevantes.

## Outras adaptações úteis de Civilization VII

### Missões com grupos e comando

Os comandantes de Civilization concentram gestão e progressão militar, incluindo agrupamento e reforços. A transferência útil é reduzir ordens repetitivas através de missões e líderes, sem copiar o empilhamento ou fazer tropas desaparecerem do terreno. C9

Empire pode beneficiar de uma ordem de escolta ou patrulha que define objetivo, rota, orçamento e condição de regresso. Um grupo contratado usa esse mesmo mecanismo. O diplomata autónomo pode utilizar a infraestrutura de missão quando UN-18 a UN-21 forem desenvolvidos.

### Feitos opcionais de exploração e diplomacia

Triumphs oferecem objetivos opcionais e recompensas, incluindo consequências de progressão entre Eras. A parte transferível é dar reconhecimento a estratégias distintas; a estrutura por Eras não é necessária. C6

Usar o livro de feitos existente para objetivos como estabelecer uma rota entre biomas, cumprir vários contratos sem incumprimento ou preservar uma área natural relevante. As recompensas devem ampliar opções ou dar reconhecimento; não tornar obrigatório completar uma lista antes de jogar a economia normal.

### Aprendizagem cultural limitada

O sistema atual de continuidade de civilizações e sincretismo de Civilization permite combinar continuidade com elementos de outras tradições. Isso sugere uma evolução por contacto, sem obrigar Empire a trocar a identidade do reino. C7

Um acordo prolongado pode ensinar uma técnica de conservação, uma construção ou uma doutrina específica. Recomendo limite de escolhas e custo de adoção, evitando acumular todas as vantagens de todos os povos. A aprendizagem deve depender de uma relação concreta, não apenas de visitar uma fronteira.

### Eventos que nascem de causas

Civilization usa eventos narrativos contextuais para reagir a escolhas e condições de campanha. A aplicação mais útil em Empire é ligar texto e consequência a estados já simulados. C10

Exemplos: uma companhia propõe melhores condições depois de um contrato cumprido; uma aldeia pede passagem porque perdeu o acesso ao rio; trabalhadores contestam uma exploração que destruiu o seu abastecimento. O evento apresenta uma escolha e modifica um sistema real. Evitar pop-ups que apenas oferecem um bónus aleatório sem relação com o território.

### Navegação e conflito posterior

Civilization diferencia papéis de unidades navais e ações marítimas. Isso pode inspirar uma fase avançada, mas a existência de um porto não exige imediatamente batalhas navais, corsários e cercos costeiros. C12

A primeira embarcação pode ser um transportador com capacidade, tempo de viagem e estado. Combate naval só deve avançar quando existirem rotas suficientes para justificar decisões próprias e quando a leitura visual do mundo 1.5D estiver resolvida.

## Experiência de utilização

### A informação deve aparecer no momento da decisão

Recomendo uma inspeção contextual do local com informação progressiva: uma frase de identidade, duas ou três oportunidades e o impedimento principal. Um detalhe opcional mostra fontes e cálculo. O ecrã não precisa expor classes de código, grafos ou IDs.

Exemplo de apresentação proposta:

Margem do rio
Cais fluvial disponível. Pesca possível nesta margem.
Falta uma ligação conhecida para iniciar comércio.
Fundar aqui remove parte do abrigo da caça.

Exemplo de impedimento:

Costa sem acesso
O mar está próximo, mas a falésia impede o acesso à margem.
Procure uma ancoragem acessível ou construa um acesso quando disponível.

### Camadas de inspeção

| Camada | Mostra | Deve esconder por omissão |
| --- | --- | --- |
| Capacidades | Fontes e construções viáveis | Cálculos extensos. |
| Acessos | Passagens, ancoragens e impedimentos | Destinos ainda desconhecidos. |
| Compromissos | Direitos, contratos e custos próximos | Histórico completo de eventos. |
| Riscos | Mudanças previstas e fragilidades | Probabilidades falsas ou precisão inexistente. |


No telemóvel, estas camadas devem ser alternativas selecionáveis, sem sobrepor várias legendas pequenas. No comando, o foco deve percorrer oportunidades e impedimentos relevantes sem exigir um cursor preciso sobre cada detalhe.

### Contrato antes e depois de aceitar

Antes de aceitar, mostrar serviço, unidades, duração, total, pagamento imediato e obrigações futuras. Depois, mostrar estado, localização, próximo vencimento e ação disponível. As consequências de cancelar ficam ao lado da ação, não escondidas numa ajuda geral.

A interface deve manter a linguagem de moeda e os verbos existentes. Uma janela de escolha é aceitável para decisões complexas; não exige acrescentar uma barra permanente de novas moedas ou transformar cada contratação num editor de contratos.

### Explicação económica consistente

Pré-visualização e simulação devem partilhar os mesmos resultados. Para produção, apresentar uma decomposição curta, por exemplo: taxa base; efeito do pessoal; efeito do local; impedimento atual. Os termos visíveis usam chaves PT/EN e símbolos acompanhados de texto, sem depender apenas de cor.

Uma promessa da interface é um contrato com o jogador: se disser “cais disponível”, a confirmação tem de validar a mesma regra. Se o contexto mudar, precisa explicar a alteração.

## Arquitetura e integração no código

### Princípios de implementação

1. A simulação decide; a interface apresenta. Pré-visualização, pagamento e produção consomem resultados do mesmo avaliador.
1. O mundo físico é a fonte de verdade. A etiqueta do bioma orienta a geração, mas não substitui fontes e acessos concretos.
1. Contratos são estado persistente. Não são apenas descontos temporários aplicados a recrutamento.
1. Cada evento económico é aplicado uma vez. Aceitação, cobrança, entrega, reembolso e libertação de efetivos têm identidade.
1. A primeira versão funciona em solo. Identidades e intenções preparam coop/PvP sem exigir rede para provar a mecânica.
1. Dados de balanceamento continuam nos CSV. Exemplos deste relatório não viram constantes escondidas no código.

### Pontos de integração existentes

Os caminhos desta secção são relativos à raiz do repositório; a secção 23 fornece ligações verificáveis ao commit auditado. Na baseline RG-28, PlacementRules e TerritoryProfile já existem, ligados por TerritoryWatch. Os restantes módulos são propostas; os campos sugeridos para PlacementResult excedem o resultado parcial atualmente implementado.

| Ponto existente | Responsabilidade a preservar | Alteração recomendada |
| --- | --- | --- |
| src/core/foundation_choice.gd | Gatilho, validade e confirmação da fundação | Consultar perfil territorial e persistir a fotografia escolhida. |
| src/ui/foundation_guide.gd | Pré-visualização de perdas e preservação | Mostrar capacidades e impedimentos usando o mesmo resultado da simulação. |
| src/sim/systems/site_validator.gd | Validade espacial e proteção | Compor validade física com requisitos do tipo de instalação. |
| src/world/greybox.gd | Autoria inicial de cenário e postos | Retirar do segmento fixo a autoridade final sobre elegibilidade geográfica. |
| src/core/last_cart_watch.gd | Reancoragem e fundação | Revalidar posições dependentes de recursos; não deslocar fontes naturais. |
| src/core/world_works.gd | Ligação entre obra e mundo | Validar antes de publicar obra e ao confirmar custo. |
| src/sim/systems/build_system.gd | Progressão e requisitos de construção | Integrar consulta comum; impedir caminhos que contornam requisitos. |
| src/sim/systems/influence.gd | Consulta de efeitos locais | Estender por regras tipadas e métricas distintas. |
| src/core/forest_work.gd | Trabalho e efeitos da floresta | Produzir alterações que invalidam perfis, sem duplicar bónus. |
| src/sim/systems/economy_system.gd | Produção e stock | Aplicar capacidade efetiva e impedimentos, preservando o resto da fórmula. |
| src/sim/systems/conversion_system.gd | Conversão de materiais | Continuar a consumir stock real, incluindo o que chega por entrega. |
| src/core/camps.gd | Presença/recrutamento em acampamentos | Diferenciar recrutamento legado de oferta contratual. |
| src/sim/systems/camp_life.gd | Contagem e esgotamento | Preservar política antiga e identificar companhias da versão nova. |
| src/sim/systems/upkeep_system.gd | Manutenção | Evitar cobrar o mesmo mercenário como salário normal e contratual. |
| src/core/settlement_watch.gd | Autonomia de assentamentos | Separar autoria, despertar, evolução e disponibilidade para acordos. |
| src/core/frontier.gd | Descoberta e publicação do mundo | Revelar estados persistentes; não recriar produção ou sociedades. |
| src/sim/systems/vassal_system.gd | Vassalagem e tributo | Acrescentar especialização/direitos sem perder a base original. |
| src/sim/systems/under_reserve.gd | Reserva e compatibilidade subterrânea | Impedir que jazidas/portos violem entradas ou espaço já reservado. |
| src/core/save_migrations.gd | Migrações sequenciais | Introduzir a próxima versão livre na implementação e preservar legado. |


### Componentes existentes e extensões propostas

| Módulo proposto em src/sim/systems/ | Entrada | Saída/estado |
| --- | --- | --- |
| territory_profile.gd | Área, fontes, acessos, direitos e condições | Capacidades, fontes utilizadas e impedimentos. |
| placement_rules.gd | Tipo de edifício, local e perfil | Resultado de elegibilidade e razões localizáveis. |
| water_network.gd | Massas, ligações e ancoragens | Conectividade e classes de operação possíveis. |
| resource_access.gd | Fonte, instalação, proprietário e caminho | Direito e capacidade de exploração. |
| mercenary_offers.gd | Companhia, pedido e contexto conhecido | Ofertas válidas, preço e contraproposta. |
| contract_ledger.gd | Aceite e eventos de serviço/pagamento | Obrigações, reservas, saldo e estado contratual. |
| route_ledger.gd | Ligações, capacidade e remessas | Operação e entregas, numa fase posterior. |


Não é obrigatório criar todos estes ficheiros de início. A separação ajuda a manter responsabilidades pequenas; a organização final deve respeitar o limite de 250 linhas e evitar classes vazias criadas apenas para reproduzir este diagrama.

### Resultado de elegibilidade

Um contrato conceptual suficiente para a interface e a confirmação seria:

```gdscript
PlacementResult
  allowed: bool
  reason_keys: lista de chaves de localização
  source_ids: fontes realmente utilizadas
  access_ids: ligações necessárias
  modifiers: efeitos aprovados por dados
  losses: consequências da implantação
  world_revision: revisão usada na avaliação
```

A revisão ajuda a detetar uma pré-visualização desatualizada, mas não substitui a revalidação na confirmação. A interface nunca envia um allowed=true como autoridade; envia uma intenção de construir numa posição.

### Desempenho e atualização fora de cena

A simulação atual opera a 30 Hz. Não há razão para procurar rotas completas ou recalcular todas as influências a essa frequência.

- Indexar fontes e pontos de acesso por região/intervalo e faixa.
- Recalcular perfis apenas por mudanças relevantes, com caches identificadas por revisão.
- Agendar cobrança, produção distante e expiração por fases/instantes do relógio.
- Materializar unidades próximas; representar grupos distantes por estado e eventos equivalentes.
- Processar eventos simultâneos numa ordem determinística definida, usando IDs estáveis para desempate.

Para equivalência fora de cena, a aproximação deve conservar as variáveis relevantes: saldo, efetivos, carga, posição lógica, compromisso e perdas. Não é necessário conservar cada animação ou passo. RG-24 já exige atenção à equivalência de níveis de simulação; este trabalho deve integrar essa linha.

### Determinismo, ordem e multijogador futuro

Geração e negociação usam apenas os mecanismos de RNG autorizados pelo projeto. A mesma semente, calendário e sequência de intenções devem produzir o mesmo resultado. IDs não podem depender da ordem de visita aos segmentos.

Reservas de contrato precisam resolver concorrência: se dois jogadores tentarem contratar os mesmos guardas, só uma aceitação válida reserva os efetivos. Uma oferta apresentada não é uma reserva infinita. Preparar este contrato em solo simplifica a implementação futura de coop/PvP.

Não recomendo enviar cada tick para Supabase nem usar o browser como nova autoridade paralela da simulação. A arquitetura de rede pertence ao trabalho específico de RG-25.

## Dados, geração e persistência

### Catálogo proposto

Os nomes abaixo são sugestões de tabelas fonte; devem ser ajustados ao esquema atual e documentados antes da geração de .tres.

| Tabela conceptual | Exemplos de campos | Validação necessária |
| --- | --- | --- |
| Fontes territoriais | Tipo, capacidades, faixa, regime de renovação | Tipo conhecido; capacidade não negativa. |
| Requisitos de instalação | Edifício, capacidade, acesso, distância, exclusões | Edifício existe; métricas compatíveis. |
| Tipos de água | Navegação, salinidade, usos admitidos | Nenhuma equivalência implícita entre água e navegação. |
| Regras de influência | Fonte, destinatário, efeito, limite, acumulação | Ausência de ciclos produtivos e acumulação sem teto. |
| Arquétipos de companhia | Especialidade, efetivos, preferências | Contratos admitidos e limites consistentes. |
| Modelos de contrato | Serviço, termos, pagamentos, cancelamento | Total calculável; condição de término obrigatória. |
| Perfis regionais | Geração, clima, acessos mínimos, alternativas | Viabilidade inicial e diversidade. |


Campos experimentais seguem a prática _proposed. As alterações devem atualizar o esquema e a documentação de conteúdo. Textos de interface ficam em data/i18n/strings.csv, com PT/EN.

### Geração com diversidade e garantias

O gerador deve criar diferenças de verdade, mas impedir bloqueios básicos. Garantir uma oportunidade funcional não significa colocar todos os recursos ao lado da caravana.

Invariantes recomendadas para novas partidas:

- Existe uma fundação fisicamente válida e alcançável no percurso inicial.
- Existe pelo menos uma cadeia económica compatível com a sobrevivência inicial aprovada.
- Uma necessidade universal pode ser satisfeita localmente ou por uma alternativa alcançável em tempo útil.
- Há escolhas com vantagens e custos distintos; nenhum local precisa reunir todas as capacidades.
- Ancoragens, passagens, fontes e elementos visuais concordam entre si.
- A ordem de exploração não altera identidades nem oportunidades previamente determinadas.
- O despertar dos povos respeita fundação, noite e alvorada, preservando exceções legadas.

Uma estratégia útil é gerar oportunidades e depois validar restrições; se falhar, reparar a menor parte necessária de forma determinística. Não reconstruir silenciosamente toda a região ao carregar uma partida.

### Estado que deve ser guardado

| Área | Estado persistente essencial |
| --- | --- |
| Geração | Semente, versão do gerador e identidades estáveis. |
| Fundação | Posição, assinatura, proveniência e consequências já aplicadas. |
| Fontes | Estado alterado, capacidade/reserva quando aplicável e titularidade. |
| Água | Topologia autoritativa ou referência versionada, obras e interrupções. |
| Conhecimento | Fontes descobertas, relatos e última observação relevante. |
| Direitos | Partes, âmbito, validade e suspensão. |
| Companhias | Efetivos, posição lógica, estado e compromissos. |
| Contratos | Termos aceites, pagamentos, reservas, calendário e eventos concluídos. |
| Transporte | Carga, detentor, origem, destino e entregas realizadas. |
| Simulação distante | Último instante processado e eventos pendentes. |


Caches deriváveis não devem ser tratadas como uma segunda fonte de verdade. Podem ser reconstruídas, desde que usem os mesmos dados persistentes.

### Migração dos saves v12

A próxima versão concreta deve ser atribuída durante a implementação, depois de confirmar o estado do ramo. Este relatório não reserva automaticamente o número 13.

Regras recomendadas:

1. Preservar posição da sede, unidades, stocks, floresta e reservas subterrâneas.
1. Não interpretar PENDING_CLIMATE_MODEL como um clima conhecido.
1. Não criar mar, jazidas ou árvores apenas para justificar uma instalação antiga.
1. Marcar instalações legadas cuja elegibilidade não possa ser reconstruída com confiança; preservar operação por uma regra de compatibilidade explícita, quando necessário.
1. Aplicar requisitos novos às construções novas; documentar exceções de legado na inspeção técnica, sem confundir o jogador com IDs.
1. Não repetir a clareira inicial nem oferecer madeira retroativa.
1. Preservar acampamentos esgotados e sociedades já existentes nos saves antigos.
1. Não converter automaticamente recrutados antigos em contratos com dívida.
1. Migrar de forma idempotente: repetir a migração não cria novas fontes, pagamentos ou companhias.

Uma instalação antiga tolerada por compatibilidade não deve propagar essa exceção para novas cópias. A proveniência diferencia conteúdo legado de nova construção válida.

## Fronteira de infraestrutura

Supabase continua a apoiar painel e feedback; a simulação de território e contratos mantém autoridade no jogo. Os alertas e contagens do relatório §18 são históricos, não uma certificação atual. Mudanças de RLS, autenticação ou schema requerem tarefa própria e verificação por papel. A entrega web usa tools/web/construir.sh, Godot e o manifesto versao.json; não é uma aplicação Next.js.
