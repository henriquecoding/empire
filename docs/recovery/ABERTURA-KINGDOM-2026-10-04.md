# Empire — pesquisa e implementação da abertura inspirada em Kingdom

Data: 04/10/2026. Pedido: afastar respawn da sede, dar espaço ao mundo e elaborar um início
de gameplay coerente; depois, implementar o relatório. Tarefa RG-20, decisão ADR 0062.

## Resultado de design

A abertura deve ensinar uma relação por vez: estabelecer um lugar, contratar uma pessoa,
dar-lhe uma ferramenta, ver o trabalho produzir moedas, investir e proteger o resultado.
O mundo precisa sustentar essa sequência. A sede é um lugar para fundar; o prado é um lugar
para obter renda; a floresta é um lugar para descobrir e arriscar. Misturar tudo na praça
faz o jogador receber conteúdo antes de compreender a função dele.

Esta é uma adaptação a Empire, não uma cópia da escala, dos custos ou dos portais de Kingdom.
Todas as recomendações de implementação listadas abaixo integram esta entrega. Os valores
de distância permanecem propostas de playtest, identificadas nos dados.

## Método e limitações

Foram examinadas as duas capturas fornecidas, a geração e a simulação de Empire, testes
da abertura, documentação de design e a main. A base inicial foi `cc8bfb4` (PR #79);
durante o trabalho integrou-se também `e07b129` (PR #80), que já afastava as tocas regionais.
Essa correção foi preservada, não substituída por uma restauração da densidade anterior.

O vídeo indicado é [Kingdom New Lands Gameplay / Let's Play — Part 1, Splattercatgaming](https://www.youtube.com/watch?v=bVjZtPjY_Rs).
Foi obtida e analisada a transcrição automática em inglês. A reprodução de imagem não
carregou na sessão: não se afirma ter assistido integralmente ao vídeo nem ter medido seus
pixels. As capturas do usuário foram inspecionadas visualmente. As fontes distinguem
New Lands, Kingdom original e Two Crowns; diferenças entre versões não viram regras universais.

Na verificação da implementação, o navegador remoto informou falta de WebGL2. A captura
local também não pôde iniciar seu servidor gráfico no ambiente atual. Portanto, não se
declara concluído um playtest gráfico manual da nova versão. A exportação, os testes de
simulação e os portões gráficos já existentes no CI são evidências distintas desse playtest.

## O que a referência ensina

### A moeda comunica uma intenção

Na [entrevista com Thomas van den Berg de 2014](https://cliqist.com/2014/05/19/thomas-van-den-berg-discusses-the-new-kingdom/),
o criador explica a origem do jogo em pequenas interações entre monarca, arqueiro, coelho
e moeda, e o papel de explorar para sustentar o reino. Aplicação em Empire: preservar a
moeda física e a leitura de causa e efeito; não entregar um exército pronto ou um bônus
invisível para corrigir a economia. Esta aplicação é uma inferência de design.

### Procedural não significa tudo em todo lugar

Na [entrevista de 2015 sobre a criação de Kingdom](https://80.lv/articles/kingdom-how-2-guys-created-a-side-scrolling-strategy),
o criador descreve blocos com assuntos específicos, vegetação colocada depois e sítios de
construção que evitam sobreposição. Também destaca a previsibilidade dos cidadãos em um
jogo de controle indireto. Aplicação: um trecho tem uma função dominante, espaço para o
seu assunto e poucos habitats coerentes, em vez de uma coleção obrigatória de espécies.

### Legibilidade depende de composição, não só de tamanho de sprite

O [blog oficial de desenvolvimento #8 e notas 2.0](https://store.steampowered.com/news/posts/?appids=701160&enddate=1729169450&feed=steam_community_announcements)
explicam melhorias na distribuição de muralhas, fazendas e torres, menos sobreposição de
árvores e arbustos e javalis mais distantes das muralhas. Não fornecem uma distância
numérica para copiar. Em Empire, disso decorrem zonas espaciais e limites por espécie;
os números são próprios e provisórios.

### A expansão altera a fonte de renda

A [documentação comunitária de Rabbit](https://kingdomthegame.fandom.com/wiki/Rabbit)
descreve coelhos associados aos arbustos de planície e a perda de arbustos com a ocupação
por edifícios e fronteiras em New Lands/Two Crowns. Animais já nascidos não precisam sumir
no instante da expansão. A [página Ghost](https://kingdomthegame.fandom.com/wiki/Ghost)
documenta a introdução por fundação, recrutamento, ferramentas e construção. São fontes
secundárias de funcionamento, não documentação dos algoritmos internos.

### O vídeo mostra decisões, não um cronômetro obrigatório

| Trecho da transcrição | Observação relevante | Aplicação em Empire |
|---|---|---|
| 0:36–1:26 | Moedas, fogo, recrutas, arcos e caça | Primeiras ações com resultado reconhecível |
| 2:05–3:25 | Pessoas no exterior e diferença entre dia e noite | Recrutamento como exploração; renda e defesa com funções distintas |
| 5:20–5:33 | Evitar uma muralha para não perder o campo de coelhos | Expandir muda a economia, não apenas a posição da defesa |
| 9:50–11:13 | Pouca área de caça; agricultura e proteção como escolhas | Criar renda produtiva antes de consumir todo o campo |

Esses tempos localizam a fala do vídeo, não metas de velocidade para Empire. A compreensão
vem da sequência de consequências, não de obrigar o jogador a apertar um botão no segundo certo.

## Diagnóstico de Empire

Antes da correção regional, tocas de caça ficavam a 60–180 px da sede. A captura mostrava
animais e habitats no mesmo ponto em que o jogador precisava reconhecer marco, carroça e
pessoas. A PR #80 resolveu esse primeiro excesso, preservando um coelho nos arrabaldes de
oeste e transferindo mais variedade para as terras.

Restavam quatro problemas verificáveis no código:

- O primeiro segmento tentava garantir todas as espécies elegíveis. Em 640 px, isso
  concentrava vários habitats junto de um único assunto de exploração.
- Não havia distância mínima por espécie que considerasse corpo, pastar e fuga.
- Erguer uma muralha ou pagar uma obra não encerrava as tocas que ficavam dentro do reino.
- Fortalezas decorativas repetidas no fundo sugeriam um reino já construído na chegada.

O problema não era apenas reposicionar um sprite. Era separar as funções do espaço e
assegurar que a simulação acompanhasse a expansão mostrada na tela.

## Abertura elaborada e implementada

| Momento | O jogador compreende | Estado do jogo |
|---|---|---|
| Chegada | Este lugar ainda precisa ser fundado | Clareira, monarca e companhia; dois vagabundos neutros; carroça |
| Fundação | A moeda estabelece o acampamento | Bancas básicas disponíveis; nenhuma pessoa gratuita criada |
| Primeiro ofício | Recrutar e equipar são ações distintas | Um recrutado pode receber arco; o outro, martelo |
| Primeira renda | Trabalho acontece fora da praça | Coelho a oeste; arqueiro caça; jogador recolhe suas moedas |
| Primeiro investimento | Dinheiro compra capacidade | Canteiro e defesa já existentes na escada de progressão |
| Anoitecer | O exterior útil de dia exige prudência | Aviso do flanco, formação defensiva e Podridão existentes |
| Expansão | Território tem custo de oportunidade | Habitats ocupados param de gerar; produção e exploração ganham importância |

Não se alteraram custos da fundação, vida da sede, dano, recompensas de caça, duração do
dia nem calendário noturno para fazer o circuito passar. A entrega mantém a progressão
da ADR 0060 e valida a viabilidade do trajeto natural, sem injetar pessoas ou moedas.

### Espaço e risco

Os valores abaixo são de Empire, em pixels de mundo, não medidas de Kingdom. A distância
considera o alcance inteiro: distância ao centro da sede menos o maior deslocamento do
animal e metade da largura do seu corpo. `habitat_min_px` fica em CSV e `_proposed`.

| Espécie | Distância mínima proposta | Distribuição |
|---|---:|---|
| Coelho | 640 | Arrabaldes de oeste e trechos exteriores compatíveis |
| Faisão | 1120 | Exterior; sem toca regional, preservando a PR #80 |
| Veado / cervo branco | 1440 | Bosque; o raro continua vindo de toca de veado |
| Raposa | 1600 | Borda e trilhos compatíveis |
| Javali | 2240 | Floresta exterior; sem toca na chegada |

As posições regionais existentes de coelho, veado e raposa foram mantidas. Os segmentos
gerados filtram espécies pela distância e pelo bioma. A composição dos segmentos deixa 192 px entre
centros de tocas; um trecho de 640 px com seu assunto comporta no máximo duas. A primeira
fonte pequena é garantida; as demais não aparecem obrigatoriamente em cada trecho.

### Expansão e persistência

`HuntHabitats` calcula o recinto até as muralhas próprias de pé, independentemente por
flanco. Também considera as superfícies de obras pagas, em curso ou de pé. Uma torre,
uma comunidade estrangeira ou uma obra subterrânea não amplia esse recinto. Convites
futuros vazios não consomem o habitat antecipadamente.

O encerramento acontece antes do crescimento da caça no tick. Não mata, não teleporta
e não retira moedas do animal já caçado. A toca encerrada permanece assim no save, mesmo
se a muralha cair. Isso impede que a cidade gere animais depois de perder a defesa.

A migração v9 reautora uma vez a distribuição antiga de fauna. Preserva moedas ganhas,
bolsas dos arqueiros, tropas, obras, dia, sementes e segmentos explorados. Ao carregar um
reino expandido, aplica ocupação antes do primeiro nascimento. Os animais antigos podem
ser substituídos por essa migração única; a regra de não sumir animais refere-se à expansão
durante a partida, não à atualização de distribuição entre versões.

### Informação e cenário

O guia de renda, em português e inglês, explica que os arqueiros caçam nos prados e que
o jogador recolhe as moedas. O objetivo é orientar uma atividade observável, sem um
pop-up que entregue todas as respostas. As fortalezas falsas do horizonte inicial foram
retiradas; relevo, floresta, construções próprias e fortalezas reais continuam.

## Matriz de execução do relatório

| Recomendação | Implementação | Verificação |
|---|---|---|
| Clareira sem caça colada | Preserva deslocamento regional da PR #80 | Primeira vista e alcance do animal |
| Risco crescente no exterior | CSV de habitat e filtragem de segmentos; javali exterior | Elegibilidade nos dois lados e ausência na chegada |
| Densidade orgânica | Menos tocas e garantia apenas da pequena caça | Limite, espaçamento, determinismo e fonte garantida |
| Expansão encerra respawn | Reserva territorial e de obras | Obra vazia/paga, flancos, ruína, estrangeiro e subsolo |
| Economia compreensível | Circuito existente e guia dos prados | Abertura apenas por movimento e moedas |
| Compatibilidade | Migração v9 e persistência de habitats encerrados | Progresso conservado e reino expandido carregado |
| Chegada visualmente honesta | Retirada de fortalezas decorativas | Exportação; revisão visual manual pendente |

## Critério de conclusão e playtest

Evidência local final após integrar a main: 1584 casos, 1582 a passar, 2 saltados,
zero erros, falhas, casos instáveis ou órfãos (13min 15s 101ms). Portões estáticos e
sincronia CSV/recursos passaram. O teste da renda natural financia um canteiro apenas
por gestos, sem acrescentar dinheiro ou pessoas ao arranque.

A [execução CI do código](https://github.com/henriquecoding/empire/actions/runs/37163201449)
confirmou exportação de Linux/Windows/Web, portões estáticos, dossiê, arranque no Chromium,
PT/EN, teclado, toque e silhueta noturna. A vistoria local terminou com derrota do piloto
no dia 4 de 8, sem invariantes quebradas: isso é sinal para playtest, não prova de equilíbrio.

A entrega exige a suite completa após integrar a main, portões estáticos, recursos
sincronizados, vistoria e export web. O PR guarda a evidência da execução e o commit
publicado. Testes automáticos provam propriedades e a viabilidade do trajeto exercitado;
não provam equilíbrio de todas as estratégias nem diversão.

O playtest deve observar três coisas: tempo até perceber quem fornece a renda, frequência
de deslocamentos vazios e efeito da segunda muralha sobre a caça. Se a renda regional
ficar escassa, a primeira opção é afinar a quota ou ritmo nos dados, não devolver tocas
à praça. Se o exterior continuar cheio, reduzir densidade com a mesma regra de composição.
Não se presume que um jogador iniciante seguirá a sequência ótima.

Não entram nesta entrega novos portais, derrubada de árvores como mecânica econômica,
arte original, uma Capital ou uma nova cadeia tecnológica. Isso ampliaria o projeto para
além de elaborar o respawn e a abertura solicitados. As ameaças do escuro e a Podridão
mantêm seus contratos anteriores.
