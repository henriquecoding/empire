# 92 — Território funcional · Fontes, acessos, fundação e produção

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Estado em main/5b4b24a (RG-28, ADR 0077): fontes por intervalo/faixa, PlacementRules, TerritoryProfile, TerritoryWatch, reancoragem e prévia de fundação já existem. A assinatura v2 conserva o perfil do momento; o save continua v12. Acesso por caminho, direitos, capacidade sustentável partilhada e produção dependente da conectividade ainda não estão completos. O alcance atual não prova um grafo de acesso. Os números de territory.csv continuam propostas na Q-249; afinidade regional de Manor Lords fica na Q-253.

## Modelo territorial recomendado

### Seis condições diferentes

Um recurso produz benefício quando passa por seis condições: existe; é conhecido; pode ser alcançado; o reino tem direito de o usar; existe capacidade de exploração; o resultado chega a quem precisa dele. A descoberta afeta a informação do jogador; a existência física não deve depender dessa descoberta.

| Camada | Pergunta | Exemplo de falha |
| --- | --- | --- |
| Existência | A fonte está no mundo? | O bioma permite minério, mas este segmento não contém jazida. |
| Conhecimento | O jogador sabe o suficiente? | Há indícios de água, mas a margem ainda não foi visitada. |
| Acesso | Há percurso compatível? | Uma jazida está noutra faixa sem passagem utilizável. |
| Direito | Quem autoriza exploração ou trânsito? | A floresta pertence a um povo com quem não há acordo. |
| Exploração | Há instalação, trabalhador e capacidade? | Existe peixe, mas falta uma posição de pesca operável. |
| Abastecimento | O produto chega ao destino? | Um bloqueio interrompe a rota entre posto e base. |


Um recurso visível não deve conceder imediatamente um bónus ao reino inteiro. Da mesma forma, falta de posse não deve significar impossibilidade absoluta: acordo, compra, tributo ou transporte podem ser alternativas.

### Quatro conceitos de dados

| Conceito proposto | Responsabilidade |
| --- | --- |
| SiteSignature | Registo histórico e reproduzível do momento da fundação. |
| ResourceSource | Fonte concreta: identidade, posição/faixa, tipo, capacidade, estado e proprietário quando aplicável. |
| TerritoryProfile | Capacidades efetivas e impedimentos atuais numa área; derivado do mundo e dos acordos. |
| AccessGraph | Ligações válidas entre pontos de trabalho, passagens, ancoragens e destinos. |


O perfil vivo é invalidado por alterações relevantes: corte, obra, passagem fechada, acordo, mudança climática ou perda de controlo. Não deve ser reconstruído integralmente a cada frame.

### Recursos, capacidades e materiais não são a mesma coisa

Materiais existentes como madeira, minério, peixe, grão e produtos animais continuam a sustentar produção e conversão. Capacidades como água doce, solo fértil, abrigo, acesso costeiro ou navegabilidade condicionam atividades. Não precisam tornar-se itens novos no inventário.

| Característica territorial | Capacidade criada | Limite ou custo associado |
| --- | --- | --- |
| Solo fértil | Agricultura eficiente | Exposição, sazonalidade e ocupação de espaço. |
| Floresta | Madeira, abrigo e recolha | Corte reduz efeitos locais; transporte exige acesso. |
| Jazida acessível | Extração de minério | Trabalhadores, passagem e custo de operação. |
| Água doce | Certas atividades agrícolas e assentamento | Não implica pesca abundante nem navegação. |
| Margem navegável | Cais e transporte fluvial | Rede, sazonalidade e capacidade da embarcação. |
| Costa acessível | Porto marítimo e ligação externa | Investimento, acesso terrestre e exposição. |
| Cavidade | Espaço e possibilidade de instalação subterrânea | Reserva útil, entrada e compatibilidade com o terreno. |
| Posição elevada/estreita | Defesa potencial | Menos área útil e maior custo de transporte. |


Nenhuma destas vantagens deve eliminar a necessidade de trabalhadores, manutenção ou armazenamento. A geografia modifica a economia; não a substitui.

### Propriedade e alcance

Recomendo separar propriedade territorial de alcance funcional. Um posto pode explorar uma fonte próxima por acordo, sem anexar a aldeia. Uma fonte dentro de território reclamado pode continuar inacessível. O alcance de uma instalação deve ser pequeno e legível; redes mais extensas exigem postos ou transporte.

As distâncias devem usar unidades e regras do projeto. Os raios de Civilization não são valores de balanceamento adequados a Empire. Proximidade horizontal, distância percorrida e distância aquática são métricas diferentes e devem aparecer explicitamente na regra.

### Aplicação aos oito biomas já catalogados

Esta tabela parte dos identificadores e recursos de data/source/biomes.csv. A coluna de evolução é uma proposta. Vários campos do catálogo, incluindo recursos de alguns biomas, continuam marcados como _proposed; a sua presença no CSV não representa aprovação de todos os efeitos sugeridos.

| Bioma / povo | Recursos declarados no catálogo | Evolução territorial recomendada | Dependência a preservar |
| --- | --- | --- | --- |
| ancient_forest / Enramados | forest, water | Madeira, recolha e habitat; classificar o lago mencionado no catálogo | Água local não implica saída marítima; minério pode exigir troca. |
| coast / Portuários | water | Ancoragens costeiras, pesca e serviço portuário | Nem toda a costa é acessível; construção e metal podem vir de fora. |
| canyon / Fenda | rock | Jazidas e passagens estratégicas | Alimento, madeira e transporte precisam de alternativas. |
| floodplain / Horta | fertile, water | Agricultura, margens e abastecimento regional | Escolher entre área produtiva, circulação e espaço de defesa. |
| volcanic / Fornalha | rock | Geologia e especialização produtiva | Não introduzir indústria avançada gratuita nem alimentação impossível. |
| subterranean / SobRaiz | fungi | Ecossistema subterrâneo e aproveitamento de espaço acessível | Luz/acesso e capacidade espacial; fungos funcionais exigem conteúdo próprio aprovado. |
| glacier / Geada | water, rock | Recursos minerais e perfil climático específico | Água congelada não equivale a rota operável; garantir economia alternativa. |
| marsh / Bruma | water, fertile | Fontes húmidas, solo utilizável e passagens particulares | Terreno encharcado não autoriza qualquer edifício ou embarcação. |


O nome do povo não deve funcionar como uma licença universal. Um assentamento Portuário pode ter conhecimento de navegação e ainda precisar de uma margem adequada. Um povo mineiro pode conhecer extração sem transformar toda a rocha em jazida.

### Compatibilidade com o mundo contínuo atual

WorldPlan organiza povos, trilhos, limiares, terras, fortalezas e bordas, alternando regiões pelos dois lados da origem. O mapa tem limites de campanha. As oportunidades territoriais propostas devem ser distribuídas dentro desse plano, respeitando transições e passagem entre faixas.

Não é necessário mover povos inteiros para oferecer escolhas iniciais. Variação local — clareira com habitat, margem acessível, elevação defensiva, entrada subterrânea — já pode criar opções dentro de uma região. Comparar biomas distantes é uma possibilidade adicional, sujeita ao ritmo de exploração aprovado. A garantia de escolha inicial deve ser definida por percurso e capacidade de sobrevivência, não pela promessa de chegar a qualquer bioma antes da primeira noite.

## Exploração e escolha da base

### Tornar a exploração útil sem a tornar obrigatoriamente demorada

A decisão de fundar deve ser compreensível com informação local e melhorar com exploração adicional. Um jogador pode aceitar um local suficientemente bom cedo; outro pode arriscar mais tempo à procura de acesso costeiro ou de uma companhia útil.

O ganho de explorar deve ser encontrar combinações e alternativas, não descobrir um único local correto escondido. A geração deve oferecer pelo menos duas soluções viáveis com custos diferentes dentro de um percurso inicial razoável. Distância e duração desse percurso são hipóteses de balanceamento a medir.

O ciclo recomendado é: observar sinais naturais; inspecionar uma oportunidade; comparar locais; entender o custo de fundar; confirmar; desenvolver vantagens; negociar aquilo que falta. Depois da fundação, exploração continua a revelar recursos, parceiros e novas rotas.

### Informação em três níveis

| Nível | Apresentação | Confiança |
| --- | --- | --- |
| Observado | “Margem navegável acessível”, “floresta próxima” | Confirmado por dados acessíveis ao jogador. |
| Indício | “Vestígios de minério”, “caminho usado por caravanas” | Pista consistente, ainda sem exploração completa. |
| Relato | “Uma companhia refere um cais a leste” | Informação atribuída a uma fonte, com validade e localização aproximada. |


O conhecimento deve persistir entre visitas. Se uma cheia, corte ou bloqueio tornar o relato desatualizado, a interface pode assinalar a última observação, em vez de apresentar um falso facto atual.

### Pré-visualização da fundação

A interface existente já mostra árvores removidas, perdas de recolha e abrigo, e pontos preservados. Recomendo ampliá-la com cinco perguntas:

1. O que posso fazer aqui? Construções disponíveis e capacidades relevantes.
1. O que falta? Recursos sem acesso, margem inadequada ou necessidade de acordo.
1. O que perco ao fundar? Vegetação e benefícios removidos pela clareira.
1. Qual é a fragilidade do local? Pouco espaço, transporte longo, exposição ou sazonalidade.
1. Como compensar? Um parceiro conhecido, acesso por construir ou alternativa produtiva.

Não recomendo mostrar um índice único como “qualidade 92/100”. Pode esconder preferências legítimas: produção inicial, defesa, diplomacia e expansão futura não têm sempre o mesmo peso.

### Comparação de quatro locais ilustrativos

Os exemplos abaixo são cenários de design, não mapas nem resultados medidos do jogo atual.

| Local | Vantagem inicial | Dependência criada | Oportunidade posterior | Perfil favorecido |
| --- | --- | --- | --- | --- |
| Margem fértil | Alimento e acesso fluvial | Madeira mais distante; proteger trabalhadores | Cais e aldeia agrícola parceira | Crescimento e comércio regional. |
| Enseada costeira | Porto e pesca | Construção inicial mais cara; pouco minério | Rotas externas e companhia marítima | Comércio e exploração. |
| Vale florestal | Madeira, recolha e habitat | Importar minério; sem transporte naval | Carpintaria e trocas com outro povo | Economia terrestre e manutenção. |
| Entrada de desfiladeiro | Defesa e depósito acessível | Alimentação e transporte mais exigentes | Metalurgia e contrato de escolta | Defesa e produção especializada. |


Cada local deve oferecer uma forma funcional de atravessar a fase inicial. “Sem mar” significa um ramo económico diferente, não uma campanha incompleta. “Sem minério local” deve permitir obter o necessário por troca, tributo ou uma expedição.

### Fundação e permanência

A confirmação consulta novamente o mesmo avaliador usado pela pré-visualização. Se o mundo mudou, a interface atualiza a diferença antes de consumir recursos. A fotografia de fundação preserva o contexto original; as capacidades continuam a mudar com o mundo.

Não proponho deslocar livremente a base depois de fundada. Isso reduziria o peso da escolha e poderia duplicar clareiras, postos e vantagens. A expansão deve ocorrer por obras, postos e acordos a partir da sede original; uma futura mudança de capital seria outra decisão de design.

## Influências, produção e equilíbrio ambiental

### Aproveitar o que já existe

A floresta atual oferece uma boa linguagem para o sistema: fontes no mundo, condição de proximidade, efeito limitado e pré-visualização da perda. Os valores observados incluem raios e limiares próprios para recolha e abrigo. Não recomendo reequilibrá-los automaticamente ao acrescentar água ou solo.

O nome Influence já tem significado espacial no código. Recomendo reservar Favor/relação para diplomacia e influência territorial para efeitos ambientais. Isto evita confundir a moeda diplomática de Civilization com o sistema de proximidade existente.

### Contrato de uma regra de influência

Cada regra deve declarar: fonte, destinatário, condições, métrica de distância, valor, limite, grupo de acumulação e razão apresentada ao jogador. Efeitos que parecem iguais visualmente podem ter regras diferentes.

| Efeito proposto | Fonte → destinatário | Métrica | Forma de evitar abuso |
| --- | --- | --- | --- |
| Recolha florestal | Árvores preservadas → instalação de recolha | Proximidade ecológica existente | Limite por instalação; não multiplicar por cada árvore indefinidamente. |
| Madeira | Árvores exploráveis → serraria | Caminho de trabalho | Capacidade, trabalhadores e fonte identificada. |
| Agricultura | Solo/água apropriados → campo | Área útil e acesso | Um benefício de irrigação por categoria; sem cadeia infinita de adjacências. |
| Pesca | Habitat → posto de pesca | Margem e alcance | Capacidade partilhada por postos que usam a mesma fonte. |
| Mineração | Jazida → extração | Passagem e trajeto | Taxa limitada pela fonte e pela operação. |
| Comércio | Rota ativa → posto comercial | Conexão logística | Rendimento por serviço/remessa real, não por simples proximidade. |
| Proteção | Patrulha contratada → área de serviço | Percurso e presença | Não defender dois locais distantes com a mesma unidade. |


### Forma de cálculo recomendada

Uma expressão útil para discutir o modelo é:

produção efetiva = taxa base × pessoal × condição da fonte × acesso × modificador local limitado

Todos os fatores devem ter domínio explícito. Ausência de acesso reduz a produção dependente daquela fonte a zero; não é apenas uma pequena penalização. Um modificador local melhora uma capacidade existente, mas não cria peixe onde não há habitat.

Esta expressão é uma proposta conceptual. A implementação deve integrar os fatores já existentes em EconomySystem, incluindo estações, crescimento e outros modificadores, sem os aplicar duas vezes. Os multiplicadores novos devem ter teto e ordem documentados. Uma alternativa aditiva pode ser superior quando facilitar a explicação.

### Fontes renováveis, finitas e estado ambiental

O primeiro ciclo pode representar capacidade produtiva sem introduzir esgotamento permanente em todos os recursos. Isto reduz o risco de campanhas inviáveis antes de existir comércio suficiente.

- Árvores mantêm a persistência já implementada; não adicionar regeneração automática apenas para compensar a nova mecânica.
- Pesca pode começar com uma capacidade sustentável partilhada por instalação e fonte. Sobre-exploração é uma extensão posterior.
- Jazidas podem começar com rendimento limitado e identidade própria. Reserva finita só deve entrar quando existirem alternativas e comunicação suficientes.
- Solo fértil é uma capacidade do terreno, não uma pilha de itens para recolher.

Se houver degradação, o jogador precisa ver a causa, a velocidade e uma resposta possível. Evitar ciclos em que baixa produção causa falta de manutenção, que reduz ainda mais a produção, sem uma saída acessível.

### Clima e Podridão

Clima deve alterar oportunidades de regiões específicas com aviso: um rio pode reduzir capacidade, uma região fria exigir reservas, uma costa oferecer períodos melhores de navegação. Não é necessário simular meteorologia contínua para obter estas decisões.

A Podridão pode afetar segurança de acesso ou condição da fonte, desde que isso não duplique automaticamente a pressão noturna. Primeiro deve haver sinais locais e uma ação de recuperação. Cheias, tempestades e contaminação são conteúdo posterior ao funcionamento estável das fontes e rotas.
