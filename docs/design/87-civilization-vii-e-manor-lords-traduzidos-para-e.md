# 87 — Território e referências · Civilization VII e Manor Lords traduzidos para Empire

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Complemento do relatório: §§92–96 especificam fontes concretas, hidrologia, mercenários e persistência. A referência Civilization VII conserva a data de corte do relatório; a referência Manor Lords continua a orientar trabalho, cobertura e crescimento, sem aprovar automaticamente a afinidade regional da Q-253.

Âmbito: integrar os princípios territoriais já adotados nos relatórios e o pedido atual de aprofundamento. Os valores existentes aprovados mantêm-se. Extensões aqui identificadas como propostas precisam de contrato e teste próprios antes de alterar a simulação. Não se importa um sistema só porque existe num jogo de referência.

## A contribuição de cada referência

O diário oficial de gestão de império de Civilization VII discute cidades, povoações e profundidade sem microgestão desnecessária. Para Empire, a adaptação é a diferenciação entre núcleo principal e assentamentos de suporte, juntamente com o valor das relações espaciais já estudado no relatório de vegetação. Fonte oficial.

O diário de desenvolvimento de Manor Lords sobre afinidades descreve relações entre construções e tipos de ambiente, incluindo efeitos por área regional em vez de assumir que tudo cabe num círculo. A consequência útil para Empire é distinguir influência local de cobertura territorial; a fonte é uma descrição do desenvolvimento, não uma tabela de balanceamento a copiar. Fonte do estúdio.

| Elemento | Tratamento em Empire | Limite |
| --- | --- | --- |
| Relações de vizinhança de Civ VII | Origem, destinatário, condição, distância e acumulação explícitos | Nenhum bónus universal de “estar no bioma certo” |
| Centros e assentamentos de suporte | Sede profunda; futuros postos/povoações especializados e autónomos | RG-12–RG-15; não criar dezenas de filas manuais |
| Grupos políticos menores | Sementes sociais, companhias e crescimento causal | ADR 0069; não cidades prontas no Dia Um |
| Fases de desenvolvimento | A complexidade desbloqueia-se por fundação, feitos e maturidade | Não épocas obrigatórias por turnos nem troca forçada de identidade |
| Planeamento do território | Macroestrutura, acessos e recursos validados antes do detalhe | Sem impor hexágonos ou visão aérea |
| Afinidades ambientais de Manor Lords | Separar cobertura da paisagem e relação entre entidades | Extensão regional por especificar; floresta local já tem contrato |
| Trabalho e logística visíveis | Construtor presente, recurso físico, percurso e tempo | Mantém moeda como gesto central; não introduz famílias ou novas profissões sem decisão |
| Crescimento orgânico | Sede, recinto e pessoas tornam novos espaços funcionais | Não construção livre 3D; slots continuam suportes de legibilidade |
| Economia sazonal | Preparação e alternativas viáveis por ambiente | Q-172 e Q-235; sem inverno igual em todos os biomas |
| Custo de oportunidade | Cortar, deslocar trabalho e mobilizar tropas têm perdas observáveis | Efeitos novos devem ser apresentados e medidos, não ocultos |


Settlement limit, nova moeda global de influência, felicidade abstrata duplicada, árvore tecnológica extensa, cadeias industriais literais e quotas familiares não fazem parte do contrato atual. Comando de grandes forças, ecrã agregado de logística e especialização territorial são direções futuras já enquadradas no Documento Mestre, dependentes da escala que os justifique.

## Um modelo ambiental sem conceitos misturados

| Camada | Pergunta a que responde | Persistência e estado |
| --- | --- | --- |
| Bioma | Que condições de base caracterizam esta região? | Perfil estável e versão de geração |
| Cobertura | O que ocupa o chão agora: bosque, clareira, cultivo, área construída? | Alterável por intervenção; árvores individuais já persistem |
| Clima | Que variações são plausíveis neste bioma? | Modelo completo futuro, RG-24; não inferir de um placeholder |
| Estação | Em que fase do ciclo local estamos? | Calendário e efeitos existentes; completar diferenças por ambiente |
| Recurso/habitat | Que atividade pode acontecer aqui, com que renovação? | Estado causal: toca, reserva, matéria, produção e esgotamento |
| Influência local | Que entidade beneficia ou prejudica outra aqui perto? | Recalcular por estado real e regras identificadas |
| Afinidade regional | Que atividade beneficia da composição de uma área inteira? | Proposta de extensão; definir área, denominador e limite antes de aplicar |
| SiteSignature | Que lugar foi escolhido na fundação? | Registo de origem; não substitui o estado ambiental atual |


A assinatura da fundação conserva a memória do lugar. Desmatar não deve reescrever retroativamente a razão por que se fundou; deve mudar a cobertura atual e os efeitos que dependem dela. Uma bonificação baseada na situação presente não pode continuar ativa porque o save conserva “floresta” na assinatura inicial.

## Influência local: contrato implementável e já usado

Cada regra identifica: origem elegível → destino elegível → mesma faixa/alcance → condição → efeito → acumulação → causa de invalidação → informação ao jogador. A apresentação lê o resultado da simulação; não faz uma conta independente que possa discordar dela.

| Regra atual | Origem e destino | Limiar e alcance aprovados | Efeito e acumulação |
| --- | --- | --- | --- |
| Bosque apoia a coleta | Árvores com função forage de pé → provisões | Pelo menos 3 árvores até 240 px | +1 moeda/dia, teto 1; não soma por árvore nem por grupos sobrepostos |
| Floresta abriga caça | Árvores shelter de pé → toca que requer árvores | Pelo menos 2 até 200 px | Toca fica dormente abaixo do limiar; não cria uma fonte alternativa infinita |
| Corte pago | Árvore válida + construtor disponível, depois da fundação | Uma moeda; alcance e tempos vêm dos CSV | Trabalho diurno; tronco paga o rendimento da espécie; fica cepo |
| Limpeza de fundação/obra | Flora comum dentro do chão reservado | Geometria validada; não o halo inteiro de conteúdo protegido | Sem madeira ou moedas; conteúdo protegido conserva-se ou invalida o local |


Fonte numérica: forest.csv, Q-238 e ADR 0073. Distância é medida ao longo da faixa; no protótipo o muro não bloqueia a influência. O texto deve mostrar essa regra, para o jogador não imaginar uma oclusão inexistente. A altura visual da árvore não foi aprovada por associação aos parâmetros funcionais.

Exemplo de decisão, sem novos valores: uma coleta tem precisamente três árvores elegíveis. Cortar uma pode render moeda imediata, mas elimina o bónus diário; a pré-visualização mostra a origem removida, o destino e a perda. Se uma toca continuar com o mínimo necessário, o corte não a desativa. Os dois efeitos avaliam-se separadamente.

A contagem ignora cepos, árvores limpas e plantas decorativas que não existem na simulação. Um mesmo ID não é contado duas vezes por atravessar segmentos. Geração posterior, fundação, corte, mudança de estação, restauração e expansão invalidam apenas os cálculos afetados; a cache não é autoridade persistente.

## Afinidades regionais: proposta delimitada, não uma regra já aprovada

Para ampliar a influência local sem copiar os círculos de outro jogo, o protótipo seguinte pode medir a proporção de cobertura elegível de uma região. A unidade de Empire é o seu espaço lateral e as faixas utilizáveis; “área” não significa necessariamente uma área 3D.

Uma hipótese de contrato é: afinidade = cobertura_elegível / cobertura_utilizável; a resposta económica é uma curva limitada em dados. Antes de a usar, definir precisamente os intervalos que pertencem à região, sobreposições, água inacessível, terrenos de outros reinos e atualização após conquista. Esta fórmula é uma proposta desta revisão, registada na Q-253, sem coeficientes aprovados nem efeito ativado.

O primeiro ensaio deve acrescentar uma relação compreensível e comparar com o sistema local existente. Não criar uma cadeia de multiplicadores floresta → oficina → mercado → felicidade → toda a produção sem orçamento e explicação. Relações encadeadas precisam de impedir ciclos e dupla contagem. Se o benefício depende de uma oficina funcional, pagar uma fundação inacabada não o concede.

## Recursos, trabalho e logística

Empire conserva três circuitos: produção, conversão e comércio (§06). A leitura inspirada em Manor Lords é causal: origem disponível → pessoa/ferramenta → deslocação → trabalho → recolha/armazenamento → utilização ou venda. Cada interrupção precisa de uma razão visível: sem trabalhador, sem matéria, fora do turno, trajeto indisponível, reserva cheia ou destinatário ainda bloqueado.

Não se inventa nesta revisão uma nova lista de alimentos, ferramentas, receitas ou consumos domésticos. Agricultura, pesca, criação, madeira, minério, cozinha e processamento usam o catálogo atual. Uma futura logística por categorias, incluindo subsolo, permanece adiada na Q-245. A moeda física e os baús não podem ser substituídos silenciosamente por saldo ilimitado acessível de qualquer ponto.

O custo de oportunidade deve poder ser lido: um construtor que repara não está simultaneamente a desmatar; uma tropa enviada numa marcha deixa de defender a sede. A prioridade concreta de trabalho usa o sistema existente; novas prioridades ou automação precisam de decisão explícita, incluindo o circuito adiado da Q-112.

## Estações e sobrevivência planeada

Q-172 exige que seja possível ultrapassar o inverno com planeamento. Q-235 acrescenta clima geralmente quente e agradável, com biomas mais dinâmicos. As duas decisões são compatíveis: a intensidade sazonal depende do lugar. O gerador deve oferecer alternativas contextuais de alimento/rendimento, armazenamento ou acesso económico; não garante abundância igual nem um recurso específico em todo o mapa.

O teste deve demonstrar um percurso viável no bioma e estação escolhidos, com o orçamento inicial e deslocações reais. Somar recursos no mapa sem verificar se são alcançáveis não prova viabilidade. Chuva, seca, cheias, doenças e incêndios citados como possibilidades ambientais no relatório continuam exemplos de conteúdo futuro; não são novos sistemas automaticamente contratados.

## UX do território e critérios de aceitação

Antes de fundar, mostrar o que será limpo, o que permanece protegido, recursos próximos conhecidos e limitações observáveis. Antes de cortar, mostrar perda marginal, não só rendimento. Antes de expandir, mostrar as obras que poderão surgir, condições em falta e habitats/recrutamento que se perdem. A informação não revela dungeons ou facções que o jogador ainda não descobriu.

Aceitação mínima: mesma seed e posição produzem a mesma assinatura; a mesma entidade não é contada duas vezes; corte altera só os efeitos dependentes; limite de acumulação resiste a densidade alta; load não restaura árvores; construir depois de gerar e gerar depois de construir respeitam o mesmo chão; toque permite inspecionar todos os efeitos que o rato revela.

A integração deve ser reconhecível numa escolha jogável: “ganho espaço e moeda agora, mas perco uma atividade que dependia deste bosque”. Se só acrescentar percentagens numa janela, o princípio ainda não chegou à experiência.
