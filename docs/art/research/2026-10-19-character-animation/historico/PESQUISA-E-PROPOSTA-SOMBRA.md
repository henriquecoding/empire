# Empire — Sombra, bailarina e floração

Pesquisa e proposta de direção visual · 19 de outubro de 2026

**Estado:** proposta posterior à rejeição da V13 e da primeira tentativa de V14. Não é um pacote de sprites aprovado, não substitui silenciosamente os arquivos entregues e não altera o jogo. A produção das folhas foi interrompida para rever o design.

## 1. Decisão principal

A direção recomendada é **Sombra como um monarca recolhido, de presença pesada e gestos delicados**, acompanhado de uma bailarina cuja postura aberta, leveza e curiosidade contrastam com ele. O jardim deve tornar essa relação visível: a figura escura e aparentemente intimidante se acomoda no chão; pequenas plantas começam a surgir ao seu redor; ele percebe uma delas e muda discretamente o gesto para lhe dar espaço.

Essa é uma proposta artística, não uma informação descoberta nas fontes nem uma alteração já aprovada da história ou das habilidades de Empire. Preserva a associação existente entre Sombra, repouso e flores, mas dá a ela uma atuação reconhecível.

A mudança central está na silhueta, na pose e no comportamento. Recolorir a armadura anterior e acrescentar um broche floral não foi suficiente.

## 2. O que falhou nas versões recentes

| Observação nas entregas | Consequência | Correção proposta |
|---|---|---|
| Ombreiras grandes, muitas placas, bordas douradas repetidas e capa aberta em triângulo | A leitura principal continua sendo a de um cavaleiro de fantasia genérico; muitos detalhes disputam a atenção | Reorganizar a massa do corpo e do manto; metal exposto apenas onde ajuda a reconhecer cabeça, mãos e apoio |
| Cabeça, coroa, mãos e volumes variam entre poses geradas | O personagem parece mudar de desenho durante a ação | Uma base fixa na resolução final e poses-chave comparadas lado a lado antes dos intermediários |
| O Sombra repousa numa pose de meditação relativamente simétrica | A posição comunica um estado, mas quase nada sobre sua personalidade | Sentar assimétrico, apoio real, acomodação do manto e uma pequena reação à primeira flor |
| A bailarina recebe as mesmas cores e uma flor no cabelo | A afinidade depende principalmente da decoração | Repetir apenas dois sinais de família e construir a relação também pela oposição entre os movimentos |
| O campo florido é transformado como uma imagem contínua | Caules, folhas e pétalas se comprimem juntos; a cena parece um tapete que se ergue | Cada planta terá posição, estágios e relógio próprios |
| PNG, Aseprite e JSON coincidem tecnicamente | Isso confirma integridade, mas não prova desenho ou animação convincentes | Conferência visual no tamanho real, silhueta, ritmo e estabilidade dos detalhes |

Há uma causa concreta para a floração da V13. O código `flowers.cjs` lê uma imagem pronta do campo e remapeia suas linhas verticalmente em torno do chão. Pequenos atrasos são aplicados a faixas de dez pixels, não a flores identificáveis. Não existe ali uma animação de caule ou de pétala por planta. Embora o efeito percebido lembre rotação, a operação principal é compressão/expansão vertical. Separar frente e fundo por um corte horizontal também pode dividir uma mesma planta de maneira inadequada.

Outro sinal de fragilidade: a primeira folha do novo Sombra solicitou 24 poses e a imagem retornada mostrou 20. Isso reforça que folhas geradas inteiras precisam ser tratadas como estudos, não como timelines de produção confiáveis.

## 3. O que a pesquisa acrescenta

### Função e postura antes do ornamento

O processo publicado pela Yacht Club Games começa pelo papel do personagem e sua relação com o mundo. O estúdio também documenta ajustes de escala, cores e pose de repouso para comunicar personalidade e conviver com o elenco. Aplicação aqui: avaliar Sombra junto ao Rei e ao Escudeiro, e escolher uma postura que diga algo mesmo parada. Não importar as restrições de cores do NES para Empire. [1]

O guia da Valve trata silhueta, orientação, distribuição de contraste e áreas visualmente tranquilas como partes da legibilidade. A aplicação a Empire é uma adaptação: o guia trata personagens 3D vistos de cima, enquanto Empire tem sprites laterais. A proposta é concentrar contraste em cabeça e mãos e deixar grandes trechos do manto respirarem. [2]

### Afinidade visual e atuação

Aardman descreve como diferenciou integrantes de uma mesma família por formas e variações de cor sem perder a afinidade. No mesmo projeto, personagens sem boca exigiram atuação corporal clara. Isso fundamenta duas decisões: Sombra e bailarina não precisam vestir uma combinação idêntica; o capacete fechado exige gestos legíveis de cabeça, ombros e mãos. [3]

### Construção na grade final

SLYNYRD distingue a aparência de baixa resolução do cuidado intencional com os pixels. Pedro Medeiros demonstra uma construção por grandes grupos de cor, refinando depois bordas e detalhes. Aplicação: definir as massas em 64/80 pixels e só depois resolver as divisões internas. Um detalhe que funciona ampliado, mas desaparece ou vira ruído a 1×, precisa ser simplificado. Não há uma proibição universal de pixels isolados; eles devem cumprir uma função clara. [4][5]

No exemplo de referência 3D de Medeiros, a redução de imagem e paleta é seguida por redesenho. A redução é um apoio, não o acabamento. Foi essa distinção que faltou na confiança depositada na adaptação automática das entregas anteriores. [6]

### Ação e apoio

SLYNYRD mostra que poses-chave fortes e duração adequada importam mais do que acumular intermediários. A Royal Ballet School enfatiza alinhamento do corpo sobre a perna de apoio, distribuição de peso, coordenação de braços, cabeça e respiração. Para a bailarina, isso exige uma frase corporal contínua; alternar braços e pés sem transferir o peso não basta. As páginas públicas das aulas foram consultadas; as aulas pagas não foram assistidas. [7][8][9]

### Desabrochar é mudança de forma

O estudo de Liang e Mahadevan combina observações e experimentos sobre a abertura do lírio. O mecanismo investigado envolve crescimento diferencial e mudança de curvatura das pétalas. A revisão de van Doorn e Van Meeteren descreve mecanismos e ritmos diferentes entre espécies. A tradução artística para Empire é separar crescimento do caule, formação do botão e abertura da flor. Não se deve afirmar que toda espécie abre como um lírio, nem que a natureza sempre floresce de modo aleatório. O escalonamento individual é a direção solicitada para este efeito mágico. [10][11]

## 4. Três caminhos considerados para Sombra

| Caminho | Potencial | Limitação neste projeto |
|---|---|---|
| Sentinela de armadura cerimonial | Preserva quase toda a forma atual e a identificação de guerreiro | Foi o caminho repetido nas versões rejeitadas; tende a acrescentar detalhes sem resolver identidade |
| **Monarca recolhido — recomendado** | Manto, capacete e mãos criam uma silhueta simples; a atuação delicada dá sentido à floração | Exige redesenhar a estrutura, não apenas trocar peças da armadura |
| Entidade vegetal de madeira e raízes | Torna imediata a associação com plantas | Alteraria muito a identidade existente e poderia confundi-lo com uma criatura do mundo |

O segundo caminho preserva o imperador de rosto oculto e muda de maneira substancial a sua presença.

## 5. Proposta concreta para Sombra

### Silhueta

Uma massa principal de manto em forma de gota curta, com a parte superior recolhida e o peso concentrado abaixo. A cabeça fica ligeiramente projetada para a frente e baixa entre os ombros. O contorno das costas descreve uma curva contínua. Uma mão pesada aparece fora do manto; a outra se distingue pelo espaço entre antebraço e corpo. Botas curtas aparecem na base e definem apoio e orientação.

A capa deixa de abrir numa grande asa triangular. Ombreiras deixam de ser os pontos mais largos e chamativos do personagem. O recorte precisa continuar legível quando todo o sprite for preenchido com uma única cor.

### Cabeça, coroa e materiais

Capacete fechado simples, arredondado no topo, com uma fenda escura curta orientada para a frente. Sem rosto exposto. Coroa pequena, de três pontas desiguais, ligeiramente inclinada; a assimetria pode contribuir para o humor sem acrescentar adereços.

Manto dominante em carvão com tendência ao violeta. Metal cinza frio com discretos tons de líquen. Tecido interior ameixa ou vinho apagado. Bronze envelhecido apenas na coroa e em um fecho. Evitar contornar cada placa com dourado. O broche floral não é obrigatório: as flores reais e a reação dele já comunicam a relação com o jardim.

Essa paleta é uma hipótese para teste ao lado do elenco, não uma regra encontrada na pesquisa. A coroa, o rosto fechado e as mãos precisam continuar identificáveis também em fundo escuro.

### Personalidade visível

O Sombra parece cansado e difícil de mover, mas cuidadoso com o que é pequeno. O humor está na diferença entre sua presença e sua atenção a uma flor. Cabeça, mãos e pausas têm prioridade sobre movimentos ornamentais da capa.

Pose de repouso proposta: um ombro mais baixo, mão próxima do joelho, cabeça ligeiramente inclinada. Ao sentar, ele deixa uma perna dobrada e a outra mais solta. Essa assimetria dá leitura de peso e evita repetir a meditação simétrica da tentativa anterior.

## 6. Proposta concreta para a bailarina

Manter a identidade ruiva e a expressividade. Melhorar a leitura de perfil: nariz curto reconhecível, sobrancelha definida e uma linha de boca econômica. Não resolver expressão acrescentando minúsculos pixels que mudem de lugar a cada quadro.

A silhueta se abre por braços e pernas, em contraste com o Sombra recolhido. Ombros relativamente estreitos, tronco levemente curvo e um pé de apoio claro. A mão livre deve ter espaço negativo em relação ao vestido; em 64×64 é mais útil ler a palma e sua direção do que tentar desenhar todos os dedos.

Roupa proposta: corpete simples verde-acinzentado, tecido claro concentrado no rosto e em pequenas áreas das mangas, saia curta assimétrica com duas massas grandes de tecido, meias opacas e calçado baixo. Reduzir o volume das mangas e a quantidade de pontas da saia. Um único painel solto pode acompanhar o giro. O cabelo permanece preso numa massa compacta para não competir com o arco dos braços.

Dois sinais unem a dupla: tecido vinho/ameixa e um acabamento de bronze envelhecido. A distribuição muda: no Sombra, esses elementos são pequenos acentos numa massa escura; nela, o tecido aparece com mais movimento. Não é necessário repetir broche e flor no cabelo para provar afinidade.

Sua atitude é curiosa e brincalhona, não uma pose constante de apresentação. Pode olhar para a primeira flor e terminar uma frase de dança ao lado do Sombra. Isso é uma proposta de atuação, sem criar uma nova mecânica de jogo.

## 7. Animações a resolver primeiro

### Sombra: repousar, notar e levantar

| Momento | Ação física | Leitura desejada |
|---|---|---|
| Preparação | Cabeça baixa; joelhos cedem; mão procura apoio | Decisão de descansar e sensação de peso |
| Descida | Uma luva toca o chão antes de o quadril descer completamente | O corpo tem apoio; não encolhe como uma imagem |
| Acomodação | Quadril assenta; uma perna relaxa; manto termina de cair | Peso se estabiliza, tecido chega depois |
| Primeira planta | Capacete se orienta discretamente; dedos se afastam do broto | Curiosidade e cuidado |
| Repouso | Pequena respiração com pausas; mãos quase imóveis | Quietude, sem oscilação mecânica contínua |
| Levantar | Pé se planta, torso avança, luva empurra e joelhos estendem | Esforço legível; manto acompanha com atraso |

Levantar merece poses próprias. Reproduzir a descida ao contrário tende a perder a diferença entre ceder peso e produzir impulso.

### Bailarina: uma frase curta com apoio

Começar com passo lateral, transferir o peso, conduzir um arco de braço com o tronco, fazer um giro curto, abrir o braço oposto e terminar numa pausa expressiva. Cada pose precisa indicar qual pé sustenta o corpo. A saia segue a mudança de direção e assenta depois; a cabeça não troca de orientação sem acompanhar o corpo.

Um giro completo de 360° adiciona muitas oportunidades de erro em rosto, cabelo e roupa. A primeira prova deve usar uma frase mais curta, executada com clareza. Quantidade de quadros será consequência do movimento, não o objetivo inicial.

## 8. Floração individual e orgânica

### Unidade mínima: uma planta

Cada planta começa com uma raiz fixa no solo. A sequência de desenhos é:

1. Uma ponta de broto rompe o chão.
2. O caule se alonga e uma pequena folha se distingue.
3. A segunda folha se abre; o botão já tem forma própria.
4. O botão aumenta um pouco e mostra a cor das pétalas.
5. As primeiras pétalas se afastam do centro.
6. A flor abre; a silhueta muda de botão para corola.
7. A flor assenta e passa a um movimento discreto de manutenção.

Os estágios não usam escala vertical da flor pronta. Os desenhos preservam continuidade do caule e da raiz. Espécies diferentes precisam de variações de abertura, não apenas mudanças de cor no mesmo desenho.

### Uma a uma, com sobreposição natural

Sortear uma ordem de nascimento entre posições previamente distribuídas. Cada início é individual; enquanto a segunda planta começa, a primeira pode estar formando o botão e a terceira ainda não surgiu. Não esperar a floração inteira de uma planta terminar para só então iniciar a seguinte.

O sorteio acontece uma vez por ativação. A posição, o tipo e a duração de cada flor permanecem estáveis durante sua vida. Sortear de novo a cada quadro causaria tremores ou troca de espécie, não organicidade.

Como ponto de partida para um teste visual — valores de direção artística, não dados botânicos — usar 20 a 30 plantas, intervalos de início entre cerca de 70 e 180 ms, crescimento individual de aproximadamente 0,7 a 1,4 s e uma pequena parcela de botões tardios. Os valores finais devem ser ajustados vendo o conjunto no jogo. A largura visual do jardim não redefine automaticamente o alcance da habilidade.

### Composição do campo

Distribuir pequenos grupos irregulares com espaços vazios, sobretudo perto das mãos e do rosto quando o personagem está sentado. Misturar plantas baixas, médias e poucas altas. A maioria deve permanecer abaixo dos joelhos do personagem em pé. Usar algumas flores claras como pontos focais e vegetação menos contrastada entre elas.

Evitar fileiras, simetria perfeita, uma onda uniforme da esquerda para a direita e flores todas do mesmo tamanho. Definir cada planta inteira como pertencente ao plano de trás ou da frente, considerando sua raiz e a posição no chão. Não cortar caules horizontalmente para fabricar as duas camadas.

Os lírios da pesquisa servem para compreender transformação de forma, não para introduzir grandes lírios em Empire. A proposta é um campo de flores pequenas e simples, com duas ou três famílias visuais reconhecíveis.

### Manutenção e saída

Depois da abertura, folhas e corolas podem variar sutilmente de pose em ritmos diferentes, com uma direção geral de vento coerente. O caule não deve girar inteiro como uma placa presa a uma dobradiça. Sem vento, é aceitável que várias plantas permaneçam quietas por alguns instantes.

Ao encerrar a habilidade, a saída é outra sequência: algumas corolas fecham ou abaixam, folhas cedem e a planta desaparece gradualmente em estágios próprios. Recolher todas ao mesmo tempo ou tocar o crescimento ao contrário reproduziria parte do problema. Se a regra do jogo permitir permanência das flores, a saída visual deve obedecer a essa regra; este documento não altera a persistência da habilidade.

## 9. Limites visuais para o próximo estudo

| Item | Critério proposto |
|---|---|
| Sombra | Quadro 80×80; cabeça, mãos, pés e coroa preservam dimensões entre poses |
| Bailarina | Quadro 64×64; articulações e perna de apoio legíveis no tamanho real |
| Pixel | Uma grade final consistente; ampliação inteira para inspeção |
| Cor | Começar com poucas massas e aproximadamente 16–24 cores úteis por personagem; ajustar ao elenco |
| Luz | Uma direção de luz consistente; contraste focal em cabeça e gesto |
| Detalhe | Dobras grandes e materiais reconhecíveis; metal não precisa brilhar em todas as bordas |
| Flores | Raiz fixa, estágios próprios e inícios distintos; um botão não salta de lugar entre desenhos |
| Afinidade | Dois sinais de família visuais, mais uma relação de atuação; personagens permanecem distinguíveis |

Esses números são propostas de trabalho. Não são uma definição universal de pixel art, nem justificam empobrecer a textura que já funciona nos outros personagens de Empire.

## 10. Prova mínima antes de expandir a produção

O próximo estudo visual útil contém: Sombra em pé, Sombra sentado percebendo uma flor, bailarina em repouso e bailarina em uma pose de transferência de peso. Apresentar os quatro ao lado dos sprites de referência do Rei e do Escudeiro, com comparação a 1× e ampliação inteira. Separadamente, mostrar três plantas crescendo em tempos diferentes.

Essa prova deve responder perguntas observáveis:

- Sombra é distinguível pela silhueta, sem depender do broche ou da cor?
- O repouso comunica uma atitude específica?
- A bailarina mantém expressão, pernas e mãos legíveis a 64×64?
- A dupla parece pertencer a Empire mesmo com formas diferentes?
- A raiz de cada flor fica parada e a pétala muda de forma durante a abertura?
- O jardim deixa o personagem legível e continua interessante sem movimento constante?

Só depois de resolver essas relações faz sentido expandir as ações. A entrega desta etapa é a pesquisa e esta proposta; nenhuma das imagens rejeitadas foi promovida a novo design final.

## Fontes principais e alcance

Todas consultadas em 19/10/2026. As propostas estéticas e os parâmetros de teste acima são interpretações para Empire, não prescrições atribuídas aos autores.

1. **Yacht Club Games — Creating a Shovel Knight Character Sprite.** Processo de conceito, escala, pose e adequação ao elenco. [Artigo](https://old.yachtclubgames.com/2020/03/creating-a-shovel-knight-character-sprite/).
2. **Valve — Dota 2 Workshop: Character Art Guide.** Silhueta, orientação, contraste e áreas de descanso. Conteúdo consultado pela indexação da página oficial; sua abertura direta retornou conteúdo incompleto. [Guia oficial](https://help.steampowered.com/en/faqs/view/0688-7692-4D5A-1935).
3. **Aardman — Behind the Craft: Legends Family Adventure.** Diferenciação dentro de uma família de personagens e atuação sem boca. [Artigo](https://www.aardman.com/latest-news/2020/november/behind-the-craft-legends-family-adventure/).
4. **Raymond Schlitter / SLYNYRD — Pixelblog 5: Back to Basics.** Controle intencional dos pixels e agrupamentos de cor. [Artigo](https://www.slynyrd.com/blog/2018/5/16/pixelblog-5-back-to-basics).
5. **Pedro Medeiros / Saint11 — Cluster Sketching and Painting.** Grandes massas, refinamento e controle de ruído. [Artigo](https://saint11.art/pixel_art_articles/article2/).
6. **Pedro Medeiros / Saint11 — Using 3D Models as Pixel Art Reference.** Referência reduzida seguida de redesenho. [Artigo](https://saint11.art/blog/3d-ref/).
7. **Raymond Schlitter / SLYNYRD — Pixelblog 8: Intro to Animation.** Poses-chave, intermediários, ritmo e duração. [Artigo](https://www.slynyrd.com/blog/2018/8/19/pixelblog-8-intro-to-animation).
8. **The Royal Ballet School — Ballet Class: Transference of Weight.** Descrição pública sobre alinhamento e apoio. [Página](https://ondemand.royalballetschool.org.uk/product/ballet-class-transference-of-weight/).
9. **The Royal Ballet School — Focus Class: Port de Bras.** Descrição pública sobre braços, cabeça, postura e respiração. [Página](https://ondemand.royalballetschool.org.uk/product/focus-class-port-de-bras/).
10. **Liang e Mahadevan — Growth, Geometry, and Mechanics of a Blooming Lily (PNAS, 2011); divulgação dos pesquisadores em Harvard SEAS.** Mecanismo específico de abertura e mudança de forma das pétalas. [Harvard](https://seas.harvard.edu/news/how-lily-blooms) · [artigo na página do laboratório](https://softmath.seas.harvard.edu/wp-content/uploads/2019/10/2011-03.pdf).
11. **Van Doorn e Van Meeteren — Flower Opening and Closure: A Review (2003).** Revisão sobre mecanismos e ritmos, consultada pelo resumo. [PubMed](https://pubmed.ncbi.nlm.nih.gov/12869518/).

Leituras complementares: [SLYNYRD — Developing Style](https://www.slynyrd.com/blog/2018/7/14/pixelblog-7-developing-style), [SLYNYRD — Side View Run ’N Gun](https://www.slynyrd.com/blog/2026/1/26/side-view-run-n-gun), [SLYNYRD — Top Down Character Animation, Part 3](https://www.slynyrd.com/blog/2025/10/2/pixelblog-58-top-down-character-animation-part-3), [Aardman — Morph, Thingy-Ma-Bobstacle Course](https://www.aardman.com/latest-news/2023/august/behind-the-craft-morph-thingy-ma-bobstacle-course/), [Integration of Hormonal and Nutritional Cues Orchestrates Progressive Corolla Opening](https://pmc.ncbi.nlm.nih.gov/articles/PMC4902604/).
