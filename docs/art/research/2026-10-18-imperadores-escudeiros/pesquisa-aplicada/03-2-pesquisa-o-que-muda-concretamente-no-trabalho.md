> ARQUIVO DE ESTUDO. A rodada visual foi rejeitada em 18/10/2026. Este texto preserva pesquisa/propostas; não declara arte aprovada. Leia primeiro o README desta pasta.

## 2. Pesquisa: o que muda concretamente no trabalho

A pesquisa usa artigos dos próprios artistas, materiais de professores de animação e documentação oficial das ferramentas. As dimensões, cores e personalidades propostas para Empire são decisões de projeto, não regras universais extraídas dessas fontes.

### 2.1 Pixel art: detalhe útil dentro de uma resolução definida

Derek Yu trabalha o desenho, a limpeza das linhas e o volume em resoluções concretas. O seu segundo tutorial mostra como tons semelhantes, sombreado que acompanha o contorno e formas rígidas prejudicam a leitura. A aplicação a Empire é conservar o detalhe apreciado, mas concentrá-lo em volumes, dobras essenciais e materiais reconhecíveis [S01–S02].

Saint11 define a construção por grupos de pixels da mesma cor. O detalhe pode existir, mas deve apoiar massas legíveis. A discussão de antialias e banding também impede uma conclusão simplista: suavização manual não é universalmente proibida em pixel art. Neste projeto, a borda do sprite deve funcionar sobre cenários diferentes, sem halo pintado para um fundo específico [S03–S04].

O estudo de SLYNYRD sobre cavaleiros começa pela anatomia sob a armadura e organiza luz e sombra em grupos. Ele distingue explicitamente o detalhe de uma peça estática das exigências da animação. Para Empire, os elementos com maior custo de continuidade — correias pequenas, rebites, dedos, cabelo fragmentado — só entram quando contribuem para o desenho [S10].

**Consequência prática:** manter a riqueza das roupas e da armadura preferidas por Henrique; reduzir ruído e resolver as articulações; não aumentar a resolução dos olhos, dentes ou nariz para esconder problemas de desenho.

### 2.2 Expressão: intenção antes de trocar a boca

Dana Boadway-Masson trata a expressão como resposta do personagem ao que percebe. Isso orienta a pergunta anterior ao desenho: o que este indivíduo está a tentar mostrar ou esconder? O rei pode disfarçar o medo; o escudeiro pode expô-lo imediatamente. São leituras do mesmo acontecimento, com atuação diferente [S13].

Shawn Kelly sublinha que o rosto deve agir como uma unidade. A aplicação em baixa resolução é coordenar o ângulo das sobrancelhas, a abertura das pálpebras e a boca. Uma boca triste colada a olhos de vitória deixa de comunicar a intenção, mesmo que cada elemento isolado esteja bem desenhado [S14].

Os estudos de faces de SLYNYRD reforçam a necessidade de simplificar e posicionar os traços na grelha. São estudos de retratos e estética anime; servem aqui para estudar organização e perfil. Não autorizam importar olhos grandes ou a resolução desses retratos para os sprites pequenos do Empire [S12].

**Consequência prática:** fixar a identidade do rosto e, em seguida, desenhar estados específicos dessa identidade. A boca do bardo é mais vertical e expansiva; a do arqueiro é estreita e contida; o bigode limita a boca visível do intendente.

### 2.3 Consistência: comparar em sequência, não apenas lado a lado

No estudo de personagem em várias direções, SLYNYRD identifica erros de proporção que aparecem quando as vistas são sequenciadas. Também explica como um detalhe atraente numa pose pode criar ruído em movimento. Para Empire, a validação inclui reproduzir a troca de expressões e as poses extremas antes de multiplicar ciclos [S09].

Saint11 discute consistência de resolução, posição e rotação. Aqui, a regra é manter uma grelha de autoria, deslocamentos inteiros nos detalhes do rosto e uma escala comum no mundo do jogo. A ampliação de apresentação não pode criar uma segunda resolução dentro do mesmo sprite [S05].

A documentação de Aseprite fornece ferramentas concretas para a revisão: camadas, quadros, tags, onion skin e cels vinculadas. Estas últimas partilham imagem e posição; exigem atenção para não propagar uma alteração de expressão a quadros que deveriam continuar diferentes [S15–S17].

**Consequência prática:** comparar a silhueta e os pixels de identidade com uma referência fixa, limitar as mudanças à região facial apropriada e rever a expressão no contexto da cabeça e do corpo em movimento.

### 2.4 Animação: poses fortes e ações que respeitam o jogo

SLYNYRD mostra que quantidade de quadros não equivale automaticamente a energia ou boa leitura. As poses principais e o tempo de exposição continuam decisivos. O estudo lateral de ataques também relaciona arma, postura e resposta ao comando [S06–S07].

O estudo lateral de 2026 parte de um corpo simples e acrescenta equipamento e movimento secundário depois. Essa separação orienta o trabalho de capas, bandeira, aljava e armadura. Não implica acrescentar ao Empire as mecânicas de tiro daquele exemplo [S11].

**Consequência prática:** aprovar corpo, rosto e poses extremas; produzir as ações com os tempos do projeto; ligar o evento de flecha, bloqueio ou recuperação ao momento visual correto.

### 2.5 Rigidez: trabalhar a força da pose

Anthony Wong propõe avaliar significado, silhueta, linha de ação e oposição entre quadril e ombros. Os exemplos mostram que a simetria e o alinhamento do corpo com as bordas do enquadramento podem enfraquecer uma pose. A aplicação aqui é redesenhar o apoio e o gesto, envolvendo tronco, braços e pernas na mesma intenção [S19].

Jay Jackson relaciona a linha de ação com peso, equilíbrio e oposição das curvas. Para Empire, isso não significa deformar o crânio nem tornar a armadura flexível: a curva principal atravessa as articulações; as placas continuam a encaixar sobre elas [S20].

O estudo de postura de combate de SLYNYRD ajuda a decompor o repouso ativo em pequenos movimentos coordenados. A referência orienta a produção posterior; os novos estudos estáticos mostram as poses que o ciclo deverá ligar [S21].

| Personagem | Organização da pose a trabalhar |
| --- | --- |
| Rei | Barriga à frente, ombros recuados e quadril sobre a perna de apoio; passada curta e braços assimétricos |
| Escudeiro | Curva de esforço atrás do escudo, cotovelos fletidos e joelhos a receber a carga |
| Nia | Corpo compacto em prontidão, quadril e ombros em oposição, gesto que continua pela mão da arma |
| Bardo | Peito e cabeça acompanham o canto; alavanca do alaúde e apoio dos pés equilibram a pose |
| Arqueiro | Curva longa e contida, braço de mira estável e braço de puxada articulado |
| Intendente | Corpo compensa a aljava, joelho cede e a mão do pagamento permanece clara na silhueta |
| Imperador | Massa ameaçadora com ombros desiguais, cabeça afundada e articulações pesadas; descanso baixa o peso até ao solo |
| Dançarina | Preservar o conceito que Henrique apreciou, incluindo os apoios, os gestos e a leveza |

### 2.6 Ameaça e campo florido: contraste de forma e valor

Na entrevista com Chris Bourassa, a direção de Darkest Dungeon relaciona massas escuras e acabamento envelhecido ao tom do jogo. A referência é de intenção tonal, não de técnica de pixel art nem de personagem para copiar [S22].

Para o imperador, a nova decisão combina elmo fechado e estreito, armadura de ferro escuro, ombreiras angulares desiguais e uma postura que avança sobre o espaço. A leitura das placas conserva alguns planos de luz; escurecer tudo até perder a anatomia não resolveria o desenho.

Ao sentar, o mesmo personagem conserva a aparência sombria. A mudança é o gesto e o aparecimento do campo florido. Pétalas pequenas e vivas, distribuídas horizontalmente, criam o contraste com a massa escura sem mudar a identidade da armadura.

