# 93 — Água e navegação · Rios, costa, lagos, cais e portos

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Estado: o protótipo identifica água com posição, incluindo lago inicial, segmentos water e borda sea. Não classifica ainda rede navegável nem implementa cais/portos. O desenho abaixo dá continuidade ao relatório e à Q-250; parâmetros e conteúdo permanecem por aprovar/implementar. A água visual não autoriza por si uma rota.

## Água, rios, costa e portos

### Regra fundamental

Ver água não basta para construir um porto. É necessário existir uma margem compatível, um local de implantação livre, acesso terrestre e uma ligação aquática adequada à função. A possibilidade de construir, a capacidade de operar e a existência de uma rota são estados diferentes.

Civilization VII permite portos em rios navegáveis desde uma correção de fevereiro de 2025. Isto sustenta a distinção entre rio comum e navegável como referência de design. As regras de profundidade, ancoragem e logística abaixo são propostas para Empire, não uma descrição pormenorizada da simulação de Civilization. C13

### Tipos mínimos de água

| Tipo | Usos possíveis | Não deve implicar automaticamente |
| --- | --- | --- |
| Ribeira ou curso menor | Água doce; efeitos agrícolas; pesca onde houver habitat | Transporte de carga por barco ou porto. |
| Rio navegável | Cais, transporte fluvial, pesca e travessia | Saída para o mar em todos os trechos. |
| Lago | Pesca; cais lacustre; transporte entre margens existentes | Comércio oceânico. |
| Mar/costa | Porto marítimo, pesca costeira e rotas marítimas | Margem acessível ao nível do solo. |
| Estuário | Ligação fluvial e marítima, se compatível | Água doce em todo o estuário. |
| Pântano | Ecossistema e atividades específicas | Navegabilidade contínua ou solo estável para grandes obras. |


O primeiro modelo não precisa simular fluidos. Basta uma topologia autoritativa, com tipos e estados discretos. Uma classe de navegação — por exemplo, sem navegação, embarcação leve e transporte maior — é suficiente até os testes demonstrarem necessidade de mais detalhe.

### Modelo da rede aquática

Uma massa de água tem um identificador estável. As ligações indicam quais os trechos conectados, tipos de embarcação admitidos e impedimentos. Pontos de margem ligam a rede terrestre à aquática. A decoração deve ser gerada a partir desses dados ou validada contra eles; não pode ser a única prova de que ali existe água funcional.

| Verificação | Resultado |
| --- | --- |
| Margem, implantação, acesso e direito válidos | Construção elegível. |
| Pessoal e condições operacionais disponíveis | Operação local. |
| Destino conhecido e ligação compatível | Rota disponível. |
| Requisito ausente | Impedimento ou suspensão com causa; sem inventar ligação. |


Uma rede parcialmente explorada só permite oferecer destinos conhecidos ou devidamente reportados. A simulação pode conhecer a continuidade do rio; a interface não deve revelar automaticamente uma cidade distante ou uma rota secreta.

### Regras de instalação propostas

| Instalação | Requisito espacial | Requisito funcional | Comportamento sem rota externa |
| --- | --- | --- | --- |
| Posto de pesca | Fonte de peixe e margem alcançável | Trabalhador e capacidade de exploração | Produção local; não exige porto comercial. |
| Cais fluvial | Ancoragem em rio navegável | Acesso terrestre e classe de embarcação compatível | Embarque local; comércio aguarda destino. |
| Cais lacustre | Ancoragem em lago | Outra margem/destino para transporte | Pesca ou serviço local; sem saída oceânica fictícia. |
| Porto marítimo | Ancoragem costeira apropriada | Espaço, acesso, manutenção e embarcação | Serviço costeiro disponível; exportação aguarda acordo. |
| Travessia por barco | Duas ancoragens ligadas | Operador e percurso válido | Serviço de passagem entre margens. |
| Ponte | Intervalo atravessável e apoios válidos | Obra e compatibilidade com navegação | Liga terreno; não cria porto. |
| Moinho de água, fase posterior | Corrente adequada | Local e atividade compatível | Não usa simplesmente a presença de qualquer água. |


Para o primeiro protótipo, cais fluvial e porto marítimo podem partilhar grande parte do comportamento, diferenciados por dados e aparência. Cais lacustre, ponte e moinho são extensões; não devem atrasar a validação inicial.

### Casos que precisam funcionar corretamente

- Costa com falésia: o mar existe, mas falta uma ancoragem terrestre acessível. O jogador vê a razão e pode procurar outra margem; uma futura obra de acesso é uma opção de progressão.
- Rio interrompido: uma queda de água ou trecho incompatível divide a rede. Não basta partilhar o mesmo nome de rio.
- Lago isolado: permite atividade local; uma rota marítima só aparece se houver uma ligação real.
- Rio junto da base, porto do outro lado: a propriedade e a passagem continuam relevantes. Proximidade visual não teletransporta trabalhadores.
- Trecho temporariamente fechado: suspende a rota, conserva edifício e carga e comunica uma previsão quando disponível.
- Construção sobre passagem importante: o validador preserva as regras de acessibilidade e os pontos protegidos já existentes.

O fecho sazonal não deve destruir instantaneamente um porto. Recomendo distinguir elegível, em construção, operacional, suspenso e danificado. Cada transição deve ter uma causa e uma solução legíveis.
