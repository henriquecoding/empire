# EMPIRE | A construção de um mundo em pixel art

Atlas visual, pesquisa artística e engenharia de produção da Forja

Henrique Passos · 28 de outubro de 2026 · Revisão aprofundada

[IMAGE:enramados|Referência original gerada: Enramados. Estudo de direção visual em revisão, sem certificação de grade nativa.|270]

**Objetivo:** produzir cenários com a riqueza, o carácter e a intenção dos bons jogos em pixel art, conservando a identidade do Empire e a leitura do seu mundo lateral.

O cenário precisa de desenho: árvores com anatomia, arquitetura com volume, materiais com comportamento, espaço com profundidade e detalhes que contam o que acontece naquele lugar. Dimensões, paletas, máscaras e tiles entram para tornar esse desenho consistente e utilizável.

Esta revisão substitui os esquemas geométricos da edição anterior por capturas reais analisadas, referências originais, ampliações de materiais e um processo de produção detalhado. O núcleo do estudo é artístico; a implementação proposta explica como a Forja pode preservar e produzir essa linguagem.

**O pacote contém:** quatro referências originais, prompts completos, inventário de fontes, planos de produção propostos, inspeção dos ficheiros e um handoff para o Claude. Os estudos gerados não são apresentados como assets já adaptados e aprovados para o jogo.

<!-- PAGE -->

# 1. O nível de desenho que queremos alcançar

O resultado desejado tem três escalas de informação a trabalhar juntas. A forma grande torna a cena reconhecível; as formas intermédias explicam volumes, materiais e profundidade; as pequenas marcas dão carácter e uso. Um conjunto de formas básicas é uma etapa de construção, não o acabamento de referência.

Uma árvore convincente pode começar por massas de cor. Depois precisa de direção de crescimento, ramificações, distribuição de peso, bolsões de sombra, recortes da copa e uma linguagem de folhas. Uma oficina começa por corpo e cobertura, mas ganha identidade na inclinação, espessura do beiral, vãos, apoios, forno e desgaste coerente.

| Escala de leitura | O que decidir no Empire | Como rever |
|---|---|---|
| Cena inteira | Claridade, profundidade, ritmo e lugar de interesse | Janela completa com os atores |
| Objeto | Silhueta, volume, função e relação com os vizinhos | Edifício/árvore inteiro a 1× |
| Região | Madeira, pedra, folhas, junções e marcas de uso | Recortes ampliados por inteiro |
| Pixel | Degraus, ligações, cor de borda e sinais pequenos | Grade nativa, sem interpolação |

Este relatório distingue três tipos de evidência: **observação visual** das capturas e dos estudos; **processo declarado** pelos artistas e equipas; **proposta própria** para a Forja. A análise de uma captura não revela automaticamente o seu número de camadas ou o método de produção.

A base técnica continua a ser o commit `afbe0087dd4219752771c800a77e3786218257f8`. Mantêm-se 1280×720, superfície y=517 e referência inferior y=618,5. Tropas 64×64 e Rei 80×80 são réguas de atores, não limites de dimensão para casas ou panoramas. A edição anterior permanece como histórico técnico, não como autoridade visual.

<!-- PAGE -->

# 2. Kingdom: arquitetura, natureza e percurso no mesmo plano

[IMAGE:kingdom_norse|Kingdom Two Crowns: Norse Lands. Captura oficial publicada na Steam. Direitos dos respetivos titulares. [G02]|250]

**Leitura da captura.** A sede organiza a cena por uma silhueta alta e um símbolo circular. As duas torres laterais repetem uma família de formas; os edifícios menores quebram a simetria e mantêm o conjunto habitado. Portas escuras, postes e beirais fazem a arquitetura parecer espessa. A repetição das tábuas é subordinada aos volumes.

As copas têm recortes irregulares e grandes áreas cromáticas. A vegetação de contacto liga os prédios ao chão. A faixa de percurso é contínua e relativamente estreita; o corpo do cenário cresce acima dela. A água inferior prolonga as cores da arquitetura em segmentos horizontais quebrados. Estas são observações desta imagem, não uma reconstrução das camadas do jogo.

**Transferência para Empire.** Usar uma régua comum de porta, apoio e altura visual; montar sede e anexos como uma família; concentrar sinais de função nos pontos de uso; separar percurso, fundação e reflexão. O corte inferior do Empire continua a ter necessidades próprias, por isso a água de Kingdom não se torna um molde universal para os nossos 203 pixels inferiores.

O diário de arte de Call of Olympus relata pesquisa de arquitetura grega e de espécies vegetais, seguida de seleção para o ambiente pretendido. [G03] A Forja precisa dessa definição de assunto: “floresta” ou “casa medieval” é insuficiente para orientar uma família com identidade.

<!-- PAGE -->

# 3. Owlboy: detalhe que revela a forma

[IMAGE:owlboy_market|Owlboy: captura oficial do press kit da D-Pad Studio, imagem 4. [G06]|240]

**Leitura visual.** A rocha inferior tem faces grandes, sombras que descrevem fraturas e marcas menores que seguem esses planos. A copa clara é dividida em grupos que deixam aparecer ramos. As inscrições, tecidos e recipientes da banca contam a função do lugar. O céu amplo deixa o contorno da árvore respirar.

As plantas na borda da plataforma fazem a superfície parecer orgânica, enquanto a linha de uso continua compreensível. A casa, a banca e a rocha usam densidades de marca diferentes. A riqueza emerge dessas relações; não exige distribuir a mesma textura por todo o ecrã.

Os criadores descrevem ambientes que expressam história e temas: locais habitados mostram desenvolvimento, enquanto ruínas e templos revelam desgaste e passado. [G07] Para a Forja, isso sugere um brief de **quem construiu, com que materiais, para quê e como o lugar mudou**.

No Empire, uma oficina dos Enramados pode ter apoios de madeira, pedra húmida e raiz que contorna a fundação. A da Fornalha pede outras relações: alvenaria junto ao calor, metal funcional, fuligem na saída do forno e vegetação escassa. São propostas de desenho, não apenas trocas de paleta.

<!-- PAGE -->

# 4. Eastward: densidade arquitetónica organizada

[IMAGE:eastward_street|Eastward: captura oficial da página Media. A projeção é usada para estudar materiais e organização, não para substituir a vista lateral do Empire. [G04]|245]

**Leitura visual.** Planos largos de fachada convivem com portas, varandas, escadas e letreiros. Tubos e manchas são agrupados por superfície. A escada central conduz o percurso; as entradas são vazios legíveis. O detalhe tem hierarquia: uma parede pode ser calma ao lado de uma zona carregada de uso.

Na entrevista com Tommo Zhou, a equipa descreve a separação dos assets em partes naturais, como telhado e parede, a sua reconstrução no ambiente 3D e o trabalho de mapas de relevo para iluminação. [G05] O acabamento visível não vem apenas de uma textura plana.

**Aplicação proposta.** Separar estrutura, superfícies, detalhes de uso e resposta à luz. A Forja deve conservar o telhado que define a casa e permitir que parede, cobertura e interior tenham tratamentos distintos. Não é necessário reproduzir o motor de Eastward para aplicar essa organização.

Também é uma referência para espaços habitados: reparos, desgaste e objetos precisam de relação com o uso. Fuligem acima de uma fornalha explica atividade; pontos pretos aleatórios em todas as paredes só acrescentam ruído. Para Empire, transformar a complexidade vertical da captura numa organização adequada ao percurso horizontal e às suas faixas.

<!-- PAGE -->

# 5. O que transferir de cada referência

| Referência | Conhecimento útil | Tradução específica para Empire |
|---|---|---|
| Kingdom | Relação entre percurso lateral, volumes e ambiente | Edifícios legíveis e ancorados numa linha comum |
| Owlboy | Grandes formas naturais, recortes e história ambiental | Árvores e rochas com carácter; ruínas com motivo |
| Eastward | Arquitetura habitada e divisão por partes | Oficina com estrutura, materiais e peças de função editáveis |
| Estudos de artistas | Etapas de construção e vocabulário de clusters | Biblioteca de motivos e critérios de acabamento |

Estas leituras são síntese comparativa. Não se pretende copiar edifícios, layouts ou sprites. A autoridade de desenho do Empire deverá ser uma referência sua escolhida para aquele asset. As capturas ajudam a formular o nível de qualidade e os problemas que precisam de ser resolvidos.

**Três decisões que mudam a produção:**

1. Criar um mestre de composição do cenário que já mostre relações de escala, massas e focos.
2. Desenvolver mestres por objeto e material dentro dessa direção, com a sua própria grade e origem.
3. Montar e rever o conjunto continuamente, para evitar peças individualmente detalhadas que disputam a atenção ou parecem pertencer a jogos diferentes.

O treino do olhar deve acompanhar a ferramenta. Antes de pedir “mais detalhe”, identificar o que falta: espessura do telhado, separação de planos, um vazio na copa, contraste da abertura ou sinal de ofício. Cada pedido corretivo deve explicar uma região e uma função.

**Limite metodológico.** As capturas oficiais podem ter ampliação, JPEG, shaders e composição final. São evidência visual do resultado, não masters de pixel art a usar para extrair automaticamente paleta ou grade de autoria.

<!-- PAGE -->

# 6. Composição: massas, intervalos e ritmo horizontal

[IMAGE:enramados|Referência original: grandes árvores enquadram uma oficina e uma casa; o fundo recua em planos. [O01]|235]

Uma janela de cenário precisa de ter uma leitura que sobreviva ao movimento. No estudo, o tronco grosso dá peso à esquerda; a oficina funciona como massa de interesse; o intervalo mais claro à direita abre profundidade. Os ramos atravessam o alto sem ocupar a faixa de percurso. A composição também precisa de ser revista em janelas deslocadas, porque uma câmara lateral não fica presa a este enquadramento.

O estudo de Landscape Backgrounds de SLYNYRD começa por bandas de cor e desenvolve o relevo, a atmosfera e a textura por planos. [A07] A nossa aplicação acrescenta o percurso, a escala dos atores e a continuidade procedural do Empire.

**Para a Forja:** guardar um mapa de massas e papéis: enquadramento, intervalo de leitura, marco, volume funcional e distância. O modelo recebe esse mapa como composição, enquanto a referência de material explica como desenhar cada superfície. Uma paleta sozinha não transporta essa organização.

**O que ainda exige revisão no estudo.** A oficina domina uma largura considerável e há zonas de vegetação muito densas junto ao caminho. A prova no jogo deve testar se o rei, a moeda e uma criatura escura se separam nesses trechos. A imagem é uma direção proposta, não um mestre de montagem certificado.

<!-- PAGE -->

# 7. Clusters: da mancha ao desenho controlado

[CROPS:clusters]

Saint11 apresenta o cluster sketching como um processo de massas de cor que vão sendo refinadas, com correção de contornos e detalhe no fim. Também reconhece usos deliberados de pixels isolados. [A01] A consequência prática é trabalhar do conjunto para a região sem transformar uma preferência de limpeza numa proibição universal.

**Gramática proposta de acabamento.** Na copa, um grupo escuro estabelece o bolso de sombra, grupos médios constroem o volume e poucos acentos descrevem bordas iluminadas. No telhado, a direção dos grupos acompanha a água da cobertura; a sombra sob o beiral separa a face da parede. Na rocha, o cluster muda de forma quando muda a face, em vez de apenas variar o tom.

Uma biblioteca útil guarda motivos com função: folha em borda iluminada, recorte de sombra, junta funda, pedra lascada, tábua sob luz e remate de telha. A repetição é variada na distribuição e conservada na linguagem.

**Revisão da Forja:** localizar fragmentos e devolver a região para análise. Um fragmento pode ser uma folha que chama atenção indevida, mas também uma ponta de ferramenta ou um sinal de material. “Remover todos os pixels pequenos” destruiria precisamente a diferença entre uma superfície genérica e uma bem desenhada.

Os recortes ampliados acima vêm das referências geradas. Permitem discutir formas e densidade; não certificam um período de grade exato nessas imagens.

<!-- PAGE -->

# 8. Cor, luz e contorno pertencem aos volumes

[IMAGE:eastward_night|Eastward: luz quente no espaço central e massas frias na periferia. Captura oficial. [G04]|220]

Na captura, os veículos continuam identificáveis por planos e recortes enquanto o foco luminoso conduz o olhar. O chão junto aos personagens recebe luz suficiente sem exigir que todos os detalhes do ambiente sejam igualmente claros. Esta é uma leitura visual, não uma medição do sistema de iluminação do jogo.

Saint11 distingue sombra de volume, sombra projetada e brilhos de materiais. [A02] SLYNYRD recomenda estabelecer a luz desde o começo do desenho. [A11] A aplicação na Forja deve separar **cor do material, face/volume, oclusão de contacto e efeito luminoso**.

Uma parede não precisa de uma linha preta em cada tijolo. O contorno colorido pode reforçar a separação onde há necessidade, e desaparecer onde duas superfícies se ligam. O estudo de City Builder explicita a preferência do autor por bordas ligeiramente mais escuras que o material adjacente. [A15]

O orçamento de cores deve vir do asset e da direção escolhida. Não copiar um teto de 16 cores de uma aula para todo o Empire. Também não confundir semitons desenhados na grade com reamostragem automática: o estudo de anti-alias de Saint11 mostra decisões deliberadas de cor para curvas, não uma autorização para borrar a imagem inteira. [A03]

<!-- PAGE -->

# 9. Projeção lateral com volume e espessura

Vista lateral não significa que toda a arquitetura se torne uma fachada plana. Beiral, soleira, topo de muro, arco e plataforma podem mostrar espessura, desde que obedeçam à mesma convenção e não inventem um percurso top-down.

No estudo de Side View Tiles, SLYNYRD usa faces de topo discretas e planos de suporte recuados, acrescentando vegetação visual sobre uma colisão limpa. [A05] Em Cityscapes, a diferença entre faces e a direção da luz organizam edifícios angulares. [A12] Para Empire, a convenção precisa de ser escolhida por família e verificada com os atores reais.

| Relação | O que a Forja deve conservar | Falha que pede redesenho |
|---|---|---|
| Telhado × parede | Beiral, espessura e sombra de apoio | Cobertura colada à fachada sem volume |
| Topo × face de pedra | Mudança coerente de plano | Ladrilhos que mudam de perspetiva a meio |
| Entrada × corpo | Abertura legível e dimensão de uso | Porta ornamental que o ator não consegue usar |
| Objeto × chão | Contacto e sombra localizada | Casa a flutuar ou enterrada até à porta |
| Fachada × percurso | Edifício observado do plano lateral | Instrução “facing right” a rodar a casa inteira |

O detetor lexical da Forja atual pode tratar “fachada frontal” como conflito de personagem. O planeador proposto deve resolver projeção do mundo, face arquitetónica e orientação de atores em campos distintos. Isso melhora a precisão sem abrir uma exceção genérica para aceitar qualquer perspetiva.

<!-- PAGE -->

# 10. Uma construção tem identidade tão concreta como um rosto

[IMAGE:oficina|Referência original isolada da oficina. Conserva a família visual da cena; requer redesenho nativo e revisão de alfa antes de uso como sprite. [O04]|265]

O equivalente arquitetónico dos sinais de um personagem é o conjunto de relações que faz reconhecer o edifício: cobertura comprida e baixa, chaminé deslocada, proporção dos vãos, ritmo dos apoios, área de trabalho e materiais.

No estudo, a chaminé, a boca do forno e a bigorna explicam o ofício. Os postes e escoras ligam cobertura e base. A roda e as ferramentas acrescentam carácter. Esses elementos devem ser nomeados no contrato; uma edição que conserve a cor castanha mas mude todos os vãos não preserva identidade.

O estudo de castelos de SLYNYRD começa por um elemento que estabelece luz e linguagem, depois organiza a estrutura e desenvolve as peças em conjunto. [A14] A proposta para a Forja é aprovar primeiro a casa/oficina inteira e só depois multiplicar módulos, estados ou decoração.

**Limite observado.** A extração gerada reorganizou detalhes e não é um recorte com pixels idênticos ao panorama. Deve ser tratada como uma nova adaptação em revisão. A etapa futura de preservação usa um mestre nativo e máscaras verificadas, como na fidelidade dos personagens.

<!-- PAGE -->

# 11. Materiais: madeira, pedra, telha e terra

[CROPS:materials]

Uma textura deve explicar um material e a face onde ele está. Madeira pede direção das tábuas, ligações, cortes e marcas de uso. Pedra pede volume, junta e fratura. Telha pede sobreposição e direção da cobertura. Terra pede estrato, corte, erosão e contacto com raízes. O mesmo padrão de pontos não serve para todos.

O artigo Texture descreve motivos simples, repetição e distribuição seletiva de informação. [A04] Bricks, Walls, Doors and More explora padrões de alvenaria e variações de desgaste sobre uma estrutura modular. [A13] A tradução abaixo é uma especificação de desenho própria para Empire.

| Material | Motivos a construir | Lugares onde concentrar informação |
|---|---|---|
| Madeira | Faixa longa, remate, nó, junta e escora | Encaixes e bordas voltadas à luz |
| Pedra | Face clara, face lateral, fenda e bloco saliente | Quinas, apoio, abertura e desgaste |
| Cobertura | Fiada, peça quebrada, cumeeira e beiral | Silhueta, sobreposição e zona de água |
| Terra | Massa de estrato, bolsão escuro e raiz | Mudança de plano e limite da cavidade |

Para a Forja, guardar esses motivos como exemplos do mestre e como máscaras de material. A quantização pode alterar a distinção entre faces; o contorno pode tapar uma junta; a limpeza pode fechar um vazio. O acabamento precisa de voltar a ser revisto depois dessas etapas.

<!-- PAGE -->

# 12. Vegetação: espécie, crescimento e posição no espaço

[IMAGE:owlboy_tree|Owlboy: copa pendente, vegetação de primeiro plano e ruínas. Captura oficial, imagem 7. [G06]|220]

A árvore da captura tem uma direção de crescimento clara e grupos pendentes que revelam ramos e peso. A vegetação próxima forma uma borda, enquanto céu e distância deixam espaço para reconhecer o percurso. A forma da copa dá identidade antes de qualquer contagem de folhas.

Plant Life recomenda conhecer o assunto e abstrair a folhagem em grupos coerentes. [A08] O diário de Call of Olympus mostra pesquisa e seleção de espécies para a sensação de um ambiente costeiro. [G03] Para Empire, a Forja deve receber uma família de árvores e a sua lógica, não apenas “mais plantas”.

**Especificação proposta:** tronco e ramos estruturais; massas da copa; buracos de céu; distribuição de luz; raiz de contacto; idade e estado. Nas variantes, a mesma árvore conserva a anatomia. O vento move partes ligadas aos ramos; uma estação altera cobertura, cor e acumulação sem deslocar a fundação.

Cogumelos, feto, erva e arbusto precisam de relação com humidade, sombra e apoio. Agrupar espécies e escalas cria bosques; espalhar o mesmo prop em intervalos regulares produz um padrão visível. Rever a faixa que fica imediatamente atrás dos rostos e das armas para impedir que os ramos criem falsas continuidades.

<!-- PAGE -->

# 13. Terreno lateral: uma superfície, várias funções

[IMAGE:side_tiles|SLYNYRD, Side View Tiles: quadro do tutorial público. Exemplo de autoria de terreno, cantos, face de topo e vegetação separados. [A05]|290]

O quadro torna visível o trabalho que um único padrão não resolve: cantos externos, cantos internos, massa de rocha, rebordo, vegetação e diferenças de face. O percurso precisa de uma linha funcional; o acabamento pode quebrar o contorno visual com plantas sem alterar automaticamente a colisão.

**Aplicação proposta na Forja.** Aprovar um trecho de material montado antes de gerar a família completa. Registar o perfil de superfície, as ligações permitidas e as variantes. Separar a massa estrutural do acabamento sobreposto quando isso permitir variar sem destruir os encaixes.

O Wang 16 atual continua útil para a codificação por cantos que efetivamente produz. Uma plataforma lateral com topo, término e face de corte pode precisar de outra semântica. A importação deve conservar o significado das peças, a sua ordem e os metadados; a quantidade de imagens não identifica o sistema.

Não tratar a ferramenta de tiles como gerador universal de árvores e edifícios. Um grande objeto pode atravessar vários módulos, mantendo uma silhueta única e uma origem própria.

<!-- PAGE -->

# 14. Porto, água e reflexão

[IMAGE:porto|Referência original: porto central com cais, armazém, torre e água em primeiro plano. [O02]|260]

A leitura marítima depende de relações concretas: cais apoiado, borda de atracação, cordas ligadas, guindaste que alcança a água e objetos agrupados por atividade. As linhas horizontais da água ajudam a distinguir a superfície dos materiais verticais da arquitetura.

Water in Motion separa o problema do desenho da água do movimento e trata reflexão, corrente e queda como comportamentos diferentes. [A10] A aplicação ao estudo usa fragmentos horizontais de brilho e reflexão quebrada, conservando a leitura das massas refletidas.

**Para o Empire:** nível e âncora da água vêm do sítio funcional. O reflexo deve acompanhar os elementos que realmente estão presentes, e não conservar uma casa que desapareceu com o estado da obra. Cais, chão e interação ficam no mundo; planos distantes podem mover-se em parallax.

**Revisão pendente do estudo.** A água ocupa bastante área e as fachadas têm perspectiva visível. É necessário ajustar o enquadramento à superfície y=517, ao espaço inferior e à convenção lateral escolhida. O exemplo é uma referência de atmosfera e materiais, não um layout já adaptado.

O plano de geração deve pedir o armazém como armazém, com sinais de carga e armazenamento. Elementos de oficina e luz forte no estudo precisam de decisão de desenho; não devem entrar automaticamente na biblioteca de todas as construções portuárias.

<!-- PAGE -->

# 15. Fornalha: geologia, arquitetura e subsolo

[IMAGE:fornalha|Referência original: alvenaria de forno, basalto, luz localizada e galeria inferior. [O03]|260]

A pedra do terreno e a da construção devem ter parentesco sem se tornarem a mesma textura. No estudo, as colunas e fraturas de basalto organizam o relevo; a alvenaria do forno introduz um padrão construído. O arco e a chaminé estabelecem uma função distinta da paisagem.

Rocks relaciona forma e cor com a geologia representada e recomenda estudar as faces naturais. [A09] A aplicação para Fornalha procura massas angulares grandes, marcas de fratura seletivas e sinais de calor nos lugares que os justificam. O calor não precisa de cobrir todo o chão com pontos brilhantes.

A galeria inferior ganha volume por teto apoiado, escoras, parede de fundo e intervalo de circulação. Para a produção, separar desenho e envelope de uso: a distância entre y=517 e y=618,5 não é uma altura livre universal. O espaço permitido deve ser lido de `UnderFit`, dos segmentos e da passagem real.

**O que a Forja precisa de rever:** escala da oficina em relação aos atores; continuidade do corredor inferior; origem da descida; regiões que recebem luz; apoio de cada viga. A referência tem um grande desnível na extremidade e um enquadramento de penhasco: isso não autoriza alterar a geometria de gameplay.

<!-- PAGE -->

# 16. Os biomas precisam de desenho próprio

| Família | Forma natural dominante proposta | Arquitetura e detalhe característico |
|---|---|---|
| Enramados | Troncos amplos, copas e clareiras | Madeira estrutural; pedra húmida; raízes contornando apoios |
| Bruma | Copas pendentes e margens húmidas | Estruturas elevadas, junco e contacto com água |
| Horta | Campos em faixas e cercas | Abrigos, bancas e ferramentas agrícolas agrupadas |
| Portuários | Costa aberta, rocha e vegetação de vento | Cais, armazém, sal, cordas e peças de atracação |
| Fenda | Estratos, grandes faces e aberturas | Apoios presos à rocha; remates de entrada |
| Fornalha | Basalto, fraturas e vazio | Tijolo/metal junto ao calor; fuligem localizada |
| Geada | Acumulação de neve e árvores expostas | Beirais, cobertura e acesso que resistem ao clima |
| SobRaiz | Arcos de raiz e alcovas | Estrutura compacta e silhuetas orgânicas reconhecíveis |

Esta é uma direção proposta para desenvolver as referências do Empire. Cada família precisa de exemplos de árvore, rocha, solo, construção e luz na mesma régua. Uma paleta diferente sobre as mesmas peças não resolve espécies, arquitetura ou clima.

Também é preciso separar **variante de identidade** e **variante de condição**. Mudar da oficina Enramados para a de Portuários pode alterar a arquitetura. Neve, dano ou noite sobre uma oficina Enramados devem conservar a sua estrutura, salvo uma mudança de estado prevista.

Nas fronteiras, combinar gradualmente material e forma sem fundir duas cenas completas por transparência. O marco pertence ao limiar; o fundo organiza profundidade; o percurso conserva a ligação. A lista efetiva deve vir dos catálogos compostos, incluindo as substituições e a transição `fenda_geada` existente no catálogo do dono.

<!-- PAGE -->

# 17. A Forja deve trabalhar por etapas de desenho

O método dos personagens transfere-se quando se preserva a ordem: autoridade visual, desenho na resolução adequada, diagnóstico por região, reparo localizado e aprovação do resultado exato. Para cenários, há uma etapa adicional: resolver a composição e as relações entre vários objetos.

| Etapa proposta | Artefacto que deve existir | Condição para avançar |
|---|---|---|
| 1. Brief | Assunto, bioma, função e convenção de vista | O lugar tem intenção definida |
| 2. Referências | Conceito, composição, materiais e estilo com papéis distintos | Autoridade e versões conhecidas |
| 3. Composição | Massas, percurso, marcos, luz e intervalos | Leitura na janela de jogo |
| 4. Estrutura | Volumes, aberturas, apoios e geologia | Coerência espacial antes do acabamento |
| 5. Gramática | Motivos de material e densidade por plano | Peças pertencem à mesma família |
| 6. Mestre nativo | Desenho resolvido na grade final do asset | Sinais de identidade continuam legíveis |
| 7. Separação | Planos, objetos, efeitos e regiões ocultas reconstruídas | Composição remontável |
| 8. Biblioteca | Variantes, estados e módulos coerentes | Continuidade e origem preservadas |
| 9. Montagem | Cena com atores, obras e luz reais | Escala e função comprovadas |
| 10. Encerramento | Comparação visual, hashes e registo de aprovação | A versão entregue é a versão revista |

Uma etapa pode voltar atrás. Se uma conversão não conservar o recorte da copa ou o vão da oficina, corrigir a estrutura na grade em vez de pedir mais textura. Se o objeto só funciona numa captura parada, rever a montagem e o enquadramento.

Esta é a arquitetura proposta do processo. O relatório não afirma que esses dez passos já estejam implementados na CLI ou que os novos estudos tenham passado por todos eles.

<!-- PAGE -->

# 18. Contrato de referência: assunto, estilo e composição

Um único anexo não deve acumular todas as autoridades implicitamente. Uma captura de Kingdom pode orientar leitura lateral; não passa a definir o telhado da oficina do Empire. Uma paleta explica as cores disponíveis; não diz onde deve ficar uma árvore.

| Papel proposto | Informação que transporta | Informação que não autoriza copiar |
|---|---|---|
| Conceito do asset | Silhueta, proporções, partes e materiais | Resolução ou defeitos visuais acidentais |
| Composição da cena | Relação entre massas, percurso e marcos | Colisão e posição funcional inventadas |
| Mestre de estilo | Cluster, aresta, densidade e contorno | Outro assunto ou outra arquitetura |
| Material | Comportamento de madeira, pedra, folha ou água | Distribuição do padrão por toda a cena |
| Contexto de junção | Vizinhos, apoio e continuidade | Alterar o vizinho fora da região autorizada |
| Régua de atores | Corpo visível, arma, apoio e folga | Encolher os atores para fazer a casa caber |

O registo deve conter ficheiro, hash, recorte, papel e estado: conceito, adaptação em revisão ou mestre aprovado. A aprovação do Henrique pertence a uma imagem exata; não se estende automaticamente às variantes, ao isolamento de uma peça ou à conversão para outro tamanho.

Para um conceito com erro estrutural, registar a exceção e o reparo pretendido. Corrigir a ligação da chaminé não é autorização para substituir a cobertura ou alterar a quantidade de portas.

Nos prompts atuais da Forja, os papéis de identidade ainda usam linguagem de rosto, roupa e pose. A ampliação precisa de um vocabulário arquitetónico e ambiental, sem perder a rastreabilidade já conquistada nos personagens. [N01]

<!-- PAGE -->

# 19. Grade, escala e fase: o problema dos números ímpares

**Proposta inicial de trabalho, a validar:** atores na sua resolução própria; arquitetura e terreno com a unidade ambiental escolhida; distância com detalhe mais contido. O tamanho do módulo de 32 não obriga todas as coisas a terem 32 pixels, e o canvas de um ator não é a sua altura visível.

| Grandeza | Exemplo de plano | O que significa |
|---|---|---|
| Janela do jogo | 1280×720 | Área de composição e apresentação |
| Autoria ambiental 2× | 640×360 células | Cada célula ocupa 2×2 no mundo |
| Mestre de edifício | Extensão definida pelo conceito e pelo espaço | Não usar fallback quadrado arbitrário |
| Raster do gerador | Tamanho solicitado e tamanho recebido | São medidas que precisam de coincidir quando exigido |
| Prévia | Ampliação inteira | Inspeção; não substitui o mestre |

Há uma sutileza importante: `517 / 2 = 258,5` e `618,5 / 2 = 309,25`. Uma origem global arbitrária de blocos 2×2 não encaixa automaticamente em ambas as referências. Arredondar os valores para satisfazer a arte pode deslocar o contacto ou alterar a geometria.

A Forja deve conservar **origem local, âncora de mundo, passo da grade e fase**. A decisão de desenho/snap na apresentação é explícita e separada das posições da simulação. Este relatório não escolhe um novo arredondamento universal para o runtime.

Uma imagem ampliada exatamente pode ter a grade recuperada. Uma ilustração com detalhe mais fino não ganha essa propriedade só por ser reduzida. O mestre precisa de desenho adequado ao orçamento: o céu distante e a bigorna têm necessidades diferentes. [A16; proposta aplicada]

<!-- PAGE -->

# 20. Separar camadas exige reconstruir o que estava oculto

Uma imagem composta não contém todos os pixels necessários para mover as camadas. Atrás do telhado pode não existir floresta desenhada; atrás do tronco pode faltar céu; uma sombra pintada pode pertencer à casa e ao chão ao mesmo tempo.

**Processo proposto:**

1. Identificar o papel de cada região e o seu proprietário: fundo, objeto, solo ou efeito.
2. Recortar o objeto com origem e âncora conservadas.
3. Reconstruir uma placa limpa atrás dele, guiada pelos planos vizinhos e pela composição aprovada.
4. Separar luz, sombra de contacto e efeito quando precisarem de variar.
5. Remontar tudo na posição original e comparar com o mestre.
6. Testar deslocamento de câmara, mudança de estado e fronteiras das camadas.

O preenchimento do fundo oculto é uma nova inferência artística. Não deve ser descrito como recuperação exata de pixels inexistentes. A área reconstruída precisa de revisão, sobretudo perto de marcos e linhas de horizonte.

Preferir produção já organizada em planos quando houver controlo do gerador e do desenho. Para objetos separados, usar contexto da cena e vizinhos bloqueados. Pedidos independentes de “mesma floresta” podem trocar espécie, luz e escala; o mestre de composição e os exemplos de material precisam de acompanhar cada pedido.

O Aseprite oferece camadas, tilemaps e slices para organizar a autoria. [T01–T03] No Godot, a movimentação relativa vem do contrato de parallax, da cobertura e da origem; não da simples quantidade de PNGs. [T04] Exportar dez camadas incoerentes não produz profundidade convincente.

<!-- PAGE -->

# 21. Rotas de geração: escolher pelo contrato real

O código inspecionado planeia PixelLab sobretudo pelos modelos de imagem estática já ligados e recusa alguns perfis sem tela resolvida. A ampliação proposta deve acrescentar operações por capacidade, não trocar silenciosamente um nome de modelo. [N01]

| Operação pública consultada | Candidato de uso | Limite que muda a escolha |
|---|---|---|
| `generate-image-v2` | Mestre ou camada com dimensão explícita e referências | Validar tamanho por proporção, anexos e resposta |
| `generate-with-style-v2` | Estudos de família a partir de estilo | Saída quadrada deduzida das referências; não é um panorama de tamanho livre |
| `image-to-pixelart` | Conversão com `output_size` explícito | Cada lado da saída é limitado a 512 no schema consultado |
| `image-to-pixelart-pro` | Exploração de escala e acabamento | Tamanho de saída decidido automaticamente; não prova cumprimento do contrato |
| Tileset lateral | Família de chão/plataforma | Não confundir com kit de arquitetura top-down |
| Inpainting | Reparo localizado | Convenção da máscara e preservação final verificadas |

O schema público de `generate-image-v2` distingue referências de assunto, estilo e opções do que copiar. O plano pode usar isso para separar identidade e linguagem visual. Nenhuma dessas opções é uma trava matemática de identidade. [P01]

O kit Building documentado pelo Create tiles (Pro) enumera top-down, isométrica e oblíqua. Não assumir que devolve fachadas laterais prontas. [P03] O tileset lateral tem uma função própria de terreno. [P02]

Os payloads de exemplo do pacote são **planos de pesquisa**, com anexos por resolver e aprovação pendente. Não são recibos de geração PixelLab. As quatro referências foram geradas pela ferramenta de imagens desta sessão; não houve ensaio pago da API PixelLab.

<!-- PAGE -->

# 22. Converter com fidelidade sem conservar o problema

Uma referência pode ter boa composição e uma textura pictórica demasiado fina. A conversão deve conservar telhado, aberturas, raízes e relações de massa, enquanto redesenha o acabamento em clusters adequados. Maximizar semelhança pixel a pixel à pintura pode impedir justamente essa transformação.

O schema consultado de `image-to-pixelart` oferece `fixer` e `init_image_strength`; a variante Pro decide automaticamente a escala de saída. [P01, P04] Estes controlos devem ser ensaiados por caso, medindo conjuntamente fidelidade e desenho na grade. Uma força alta não é uma garantia universal de pixel art melhor.

**Duas experiências propostas:**

- Um edifício completo com saída fixa que caiba no endpoint: comparar silhueta, vãos, materiais e leitura a 1× antes de qualquer variante.
- Uma camada ambiental com uma resolução compatível: preferir dimensão explícita; se o limite exigir divisão, usar uma faixa de contexto comum e conservar a região de ligação como parte do contrato.

Por exemplo, uma camada lógica de 640×360 pode ser dividida em duas regiões de 352×360 com 64 células de sobreposição: `352 + 352 - 64 = 640`. Isto é uma proposta de particionamento, não uma promessa de costura automática. A faixa comum precisa de mestre, máscara, origem e revisão; duas gerações independentes podem divergir.

O caminho para os personagens continua a ser relevante: reservar pixels para os sinais distintivos, observar o que se perdeu e reparar por região. Para arquitetura, esses sinais são a ligação da chaminé, o vazio da porta, a inclinação da cobertura ou o ritmo dos apoios.

<!-- PAGE -->

# 23. Reparar regiões com o mestre bloqueado

O pedido corretivo deve apontar a mudança necessária e as relações a conservar. “Aumentar qualidade” não indica uma ação verificável. “Refazer os grupos de telha nesta água, conservando o beiral, o apoio e a chaminé” delimita uma intervenção.

| Região editável | Estrutura a proteger | Prova de preservação |
|---|---|---|
| Cobertura | Silhueta, inclinação, apoio e chaminé | Comparação dos marcos e dos pixels protegidos |
| Copa | Anatomia dos ramos e recorte principal | Silhueta e buracos de céu preservados |
| Porta | Posição da soleira e dimensão de uso | Abertura livre e âncora invariável |
| Pedra | Face, fratura e contacto | Junções e perfil de encaixe conservados |
| Dano/neve | Identidade e função da construção | Mudança limitada à condição autorizada |

Usar uma máscara interna booleana de edição, traduzida para cada adaptador. Compor localmente o candidato sobre o mestre e verificar novamente o resultado depois de paleta, contorno, crop e exportação. O contexto visível pode ser maior que a área autorizada a mudar.

Sem mestre nativo aprovado, o trabalho ainda é adaptação e desenho. Uma nova imagem que “parece a mesma oficina” não recebe a garantia de preservação que só uma comparação efetiva pode demonstrar.

O isolado da oficina ilustra esse ponto: a ferramenta gerou uma versão relacionada e com transparência, mas reorganizou detalhes e produziu alfa parcial. O passo seguinte é resolver o sprite no seu contrato, não rotular o candidato como extração exata.

<!-- PAGE -->

# 24. Módulos e costuras: textura, forma e função

Modularidade deve reutilizar decisões boas. Uma faixa de parede, um troço de cerca e um estrato de pedra podem repetir; uma árvore antiga ou uma sede de silhueta única podem atravessar a grelha e conservar uma origem própria.

O Aseprite permite editar o conteúdo de tiles e a sua colocação como operações distintas. [T01] O TileSet do Godot acrescenta semântica de desenho e formas funcionais. [T05] A Forja deve transportar as duas coisas sem deduzir colisão a partir da transparência da imagem.

**Verificações propostas:**

- Perfil e material da aresta; sentido da luz e fase do padrão.
- Conectores permitidos, cantos e regiões de vazio.
- Alternância de variantes sem criar uma marca repetida demasiado óbvia.
- Origem após crop e posição de topo/apoio entre estados.
- Repetição apenas nos eixos declarados.

A função atual `tiles.seams` compara bordas com o contraste médio do interior. As sondas anteriores mostram que o seu `seamless=true` não significa diferença zero. Um padrão de alternância pode repetir bem com bordas diferentes; uma falha topológica pode exigir um teste específico mesmo quando a diferença média é pequena. [N01]

Manter o Wang 16 para a codificação que ele produz e validar os 64 pares horizontais e 64 verticais compatíveis. Para outra semântica, criar um mapeamento explícito. Não corrigir uma ligação defeituosa com blur ou com uma pintura que muda os vizinhos fora da região autorizada.

<!-- PAGE -->

# 25. Luz, clima e movimento sem redesenhar a identidade

Uma variante de noite deve conservar a arquitetura. Neve precisa de acumular em superfícies plausíveis; musgo deve relacionar-se com humidade e apoio; uma casa danificada deve continuar reconhecível. A mudança de condição não é oportunidade para trocar todas as janelas.

| Componente | Parte estática proposta | Parte que pode variar |
|---|---|---|
| Oficina | Corpo, apoios, aberturas e cobertura | Forno, fumo e atividade |
| Árvore | Tronco, ramos e raiz | Folhagem e pequenos movimentos ligados |
| Água | Nível e margens | Reflexo, corrente e brilho |
| Edifício em obra | Origem e volume do nível previsto | Materiais expostos e sinais de progresso |
| Ambiente | Geologia e marcos | Luz, tempo e vegetação de condição |

O Godot permite trabalhar iluminação, recetores e oclusores separadamente. [T06] A aplicação para Empire deve respeitar o sistema atual e o custo medido, sem adotar automaticamente mapas normais ou luz dinâmica em toda a arte.

O parallax exige que os planos possam mover-se sem revelar vazios ou separar uma porta do seu sítio. Cobertura da camada, origem e período de repetição são condições de montagem. [T04] A arte distante precisa de continuar convincente parada; o movimento acrescenta profundidade, não corrige massas mal organizadas. [A06]

Também separar brilho emitido da cor base. Uma luz laranja já pintada e uma modulação adicional podem escurecer ou saturar a mesma região duas vezes. Comparar as variantes com os mesmos atores, câmera e estado do mundo.

<!-- PAGE -->

# 26. Benchmark visual: a prova precisa de uma cena

A bancada proposta compara uma mesma oficina, árvore e trecho de chão em três contextos: peça isolada, montagem de dia e montagem de noite. O objetivo é descobrir onde a transformação perde desenho ou leitura, usando a referência exata e o resultado final.

| Eixo de revisão | Evidência exigida | Falha que bloqueia exportação |
|---|---|---|
| Identidade | Conceito e mestre a 1×; marcos e máscaras | Parte distintiva ausente ou duplicada |
| Grade | Dimensão real, período quando recuperável e sinais preservados | Raster tratado como nativo sem prova |
| Material | Recortes iguais e comparação por face | Madeira/pedra fundidas ou textura sem direção |
| Arquitetura | Vãos, cobertura, apoios e contacto | Porta fechada, viga solta ou origem deslocada |
| Continuidade | Vizinhos e panorama montados | Junção, fase ou conector incompatível |
| Leitura | Rei, tropa, criatura, arma e moeda reais | Elementos de uso deixam de se distinguir |
| Estado | Mesmo sítio em construção/ativa/danificada | Mudança indevida de escala ou apoio |
| Apresentação | Parado, movimento, 1,5× e 2× | Tremor, irregularidade ou efeito que oculta a ação |

Métricas ajudam a localizar problemas: área de fragmentos, contraste por região, deriva estática e diferenças fora da máscara. Não atribuir uma nota global que compense uma porta defeituosa com uma textura bonita. “Contrato válido” e “imagem aprovada” permanecem resultados diferentes.

Não foi executado um novo benchmark de runtime nesta revisão. A bancada descrita é o critério para avaliar a futura implementação com os assets adaptados, não uma afirmação de FPS ou de qualidade já alcançada pela Forja.

<!-- PAGE -->

# 27. O que os quatro estudos provam e o que ainda falta

As imagens desta revisão foram geradas como referências e inspecionadas como ficheiros. A primeira passagem de floresta ficou demasiado pictórica; foi retrabalhada para tornar os clusters mais evidentes. A mudança melhora a direção visual, mas não certifica a grade nativa.

| Estudo entregue | Dimensão real | Papel e revisão pendente |
|---|---|---|
| Enramados | 1672×941, RGB | Composição, madeira, pedra e vegetação; adaptar escala, linha de chão e densidade |
| Porto | 1671×941, RGB | Arquitetura marítima, luz e água; ajustar projeção e função do edifício |
| Fornalha | 1672×941, RGB | Geologia, forno e galeria; ajustar encaixe e espaço de uso |
| Oficina isolada | 1536×1024, RGBA | Identidade de edifício; redesenho nativo e revisão de transparência |

Os pedidos usaram resoluções lógicas como orientação artística. As dimensões recebidas não equivalem a um mestre de 480×270 ou 192×128. Não é correto chamar a estes ficheiros “nativos” ou “prontos para o jogo” por terem aparência pixelada.

No isolado, a inspeção encontrou alfa de 0 a 254, incluindo muitos pixels parcialmente transparentes. Existe transparência real; não existe alfa binário certificado. A geometria e os detalhes também precisam de comparação antes de o resultado substituir um mestre.

**Consequência para a Forja:** separar `visual_reference`, `native_master` e `runtime_asset`. A entrega inclui hashes e inspeção reproduzível que conserva essa distinção. As quatro referências permitem discutir a direção com evidência visual concreta; a adaptação posterior deve manter a riqueza sem voltar a uma casa em forma de caixa ou a uma árvore genérica.

<!-- PAGE -->

# 28. Implementação: responsabilidades concretas

| Trabalho proposto | Ligação ao código inspecionado | Comportamento esperado |
|---|---|---|
| Pedido por tipo | `contracts.json`, `prompts.py`, `plan.py` | Extensão e operação explícitas para cena, árvore, edifício e terreno |
| Contrato artístico | Papéis e regras em `prompts.py`/`constraints.py` | Autoridade arquitetónica, materiais e composição sem instruções faciais |
| Fundo e bordas | `pipeline.py`, `lint.py` | Preservar céu/terreno opaco; borda intencional não é corte acidental |
| Escala e fase | Expectativas e metadados | Grandezas e origens sem arredondamento implícito |
| Operações do fornecedor | Adaptadores PixelLab | Geração, conversão, estilo e tiles com schemas próprios |
| Fidelidade por região | Referências, máscaras e verificação | Proteger pixels e sinais até à exportação final |
| Continuidade | `tiles.py`, `cmd_make.py`, `godot.py` | Eixos e semântica dos conectores explícitos |
| Montagem visual | Catálogos e consumidores existentes | Mesmo apoio, estado e sítio funcional no mundo |

O estado efetivo dos cenários resulta do catálogo legado, do patch nativo e do patch das composições do dono. Já existem famílias, variantes e sítios de água. A implementação não deve criar uma segunda biblioteca desconectada nem somar contagens sobrepostas como se fossem assets únicos.

O limite de 250 linhas por script continua aplicável no repositório. Nomes como `scene_art_contract`, `scene_plan` e `scene_review` são sugestões de divisão, não comandos já existentes.

Preservar os reparos anteriores dos personagens. Um novo gerador de cenas não deve reintroduzir remoção genérica de detalhe, perda de referência ou aprovação automática por lint.

<!-- PAGE -->

# 29. Piloto e handoff para o Claude

O handoff do pacote transforma esta pesquisa em tarefas e provas. A primeira implementação deve fechar um exemplo pequeno de ponta a ponta, com arte e critérios concretos, antes de multiplicar biomas.

**Piloto proposto:** uma oficina Enramados, uma árvore com anatomia, um trecho de terreno e os planos necessários à montagem. Usar os atores reais como régua e manter a superfície e o nível inferior atuais. Rever a oficina ativa, em construção e danificada com a mesma origem.

**Entregas do piloto:** conceito vinculado; contrato artístico; plano de geração sem rede; mestre nativo; materiais e partes; cena remontada; comparações a 1× e ampliadas; casos negativos; resultado no motor; aprovação da imagem exata quando concedida pelo Henrique.

Para testar o fornecedor, comparar as rotas e parâmetros sobre a mesma referência e o mesmo tamanho. Registar versão de schema, hashes, dimensões recebidas, job e custo reportado quando houver execução autorizada. Uma imagem bonita não demonstra repetibilidade; uma conversão fiel numa peça não prova qualidade de todo o lote.

**Critério de fecho artístico:** o conjunto conserva identidade e riqueza por meio de formas, materiais e pequenos sinais deliberados; o percurso continua legível; noite e movimento não desfazem a montagem. Se a grade final eliminar o sinal de função da construção, o desenho precisa de ser resolvido, mesmo que o ficheiro esteja tecnicamente íntegro.

Esta revisão conclui pesquisa, referências originais e especificação. As futuras alterações da Forja, conversões nativas e provas de runtime têm critérios de aceitação explícitos no handoff. Nenhum novo mestre ambiental foi aprovado pelo utilizador nesta sessão.

<!-- PAGE -->

# 30. Fontes primárias: jogos e linguagem visual

Consulta em 28/10/2026. Capturas de jogos foram analisadas visualmente; processos de produção foram atribuídos às equipas quando declarados. Os estudos de terceiros não foram tratados como contratos do Empire.

| IDs | Fonte | Objeto da consulta |
|---|---|---|
| G01–G03 | Kingdom: [site oficial](https://kingdomthegame.com/kingdom-two-crowns/), [Norse Lands](https://store.steampowered.com/app/1708680/Kingdom_Two_Crowns_Norse_Lands/) e [diário de arte](https://store.steampowered.com/news/posts/?appids=701160&enddate=1718377302&feed=steam_community_announcements) | Referências laterais e pesquisa de arquitetura/vegetação |
| G04–G05 | Eastward: [Media oficial](https://eastwardgame.com/media/) e [entrevista](https://www.gamedeveloper.com/art/eastward-s-creators-share-insights-on-making-pixel-art-adventures) | Capturas; divisão dos assets e iluminação |
| G06–G07 | Owlboy: [press kit](https://www.dpadstudio.com/presskitOwlboy.html) e [entrevista](https://www.gamedeveloper.com/art/using-graphics-to-express-character-and-theme-in-i-owlboy-i-) | Capturas; história e identidade dos ambientes |
| A01–A03 | Saint11: [Cluster Sketching](https://saint11.art/pixel_art_articles/article2/), [Shading](https://saint11.art/pixel_art_articles/article4/), [Anti-Alias](https://saint11.art/pixel_art_articles/article5/) | Massas, volumes e decisões de aresta |
| A04–A07 | SLYNYRD: [Texture](https://www.slynyrd.com/blog/2018/2/15/pixelblog-2-texture), [Side View Tiles](https://www.slynyrd.com/blog/2020/5/21/pixelblog-28-side-view-tiles), [Parallax](https://www.slynyrd.com/blog/2019/11/12/pixelblog-23-parallax-scrolling), [Landscape](https://www.slynyrd.com/blog/2026/5/27/pixelblog-62-landscape-backgrounds) | Acabamento, terreno e profundidade |
| A08–A11 | SLYNYRD: [Plant Life](https://www.slynyrd.com/blog/2019/3/7/pixelblog-15-plant-life), [Rocks](https://www.slynyrd.com/blog/2019/1/22/pixelblog-13-rocks), [Water](https://www.slynyrd.com/blog/2018/10/12/pixelblog-10-water-in-motion), [Light](https://www.slynyrd.com/blog/2018/6/15/pixelblog-6-light-and-shadow) | Famílias naturais e comportamento de luz/água |
| A12–A15 | SLYNYRD: [Cityscapes](https://www.slynyrd.com/blog/2019/2/23/pixelblog-14-cityscapes), [Bricks/Walls/Doors](https://www.slynyrd.com/blog/2023/7/21/pixelblog-45-bricks-walls-doors-and-more), [Castles](https://www.slynyrd.com/blog/2025/7/28/pixelblog-57-knights-monsters-amp-castles), [City Builder](https://www.slynyrd.com/blog/2024/7/25/pixelblog-51-city-builder) | Organização da arquitetura e materiais |
| A16 | Saint11: [Scaling Pixel Art](https://saint11.art/blog/scaling/) | Distinção entre autoria, ampliação e redução |

Os URLs individuais e o alcance de cada leitura estão em `fontes-v2.csv` e `fontes-v2.json`. O catálogo contém também a origem dos ficheiros visuais usados no PDF. As capturas são incluídas como referências de análise; os respetivos direitos pertencem aos seus titulares.

**Leitura dirigida recomendada:** observar primeiro a captura inteira; localizar a massa dominante e o percurso; escolher um objeto; identificar as faces e os materiais; aproximar uma região; só então discutir os clusters e as decisões de pixel. Fazer o caminho inverso confirma se o acabamento continua a servir a imagem completa.

Alex Vede permanece uma referência compositiva histórica descrita no estudo anterior. A presente revisão não o usa como exemplo de técnica de pixel art nem confirma novamente a autoria da imagem antiga.

<!-- PAGE -->

# 31. Fontes técnicas, rastreabilidade e estado

| IDs | Fonte primária | Alcance |
|---|---|---|
| P01 | [PixelLab OpenAPI v2](https://api.pixellab.ai/v2/openapi.json) | Schemas e operações; snapshot com hash no pacote |
| P02 | [Create Tileset](https://www.pixellab.ai/docs/tools/create-tileset) | Função do gerador lateral e top-down |
| P03 | [Create tiles (Pro)](https://www.pixellab.ai/docs/tools/create-tiles-pro) | Building e condições dos conjuntos conectáveis |
| P04 | [Image to pixel art](https://www.pixellab.ai/docs/tools/image-to-pixel-art) | Conversão e fidelidade |
| P05 | [Create S-XL image (Pro)](https://www.pixellab.ai/docs/tools/create-sl-image-pro) | Geração com referências e dimensão |
| T01–T03 | Aseprite: [Tilemap](https://www.aseprite.org/docs/tilemap/), [Sprite Sheets](https://www.aseprite.org/docs/sprite-sheet/), [Slices](https://www.aseprite.org/docs/slices/) | Organização e exportação da autoria |
| T04–T06 | Godot: [Parallax](https://docs.godotengine.org/en/stable/tutorials/2d/2d_parallax.html), [TileSets](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html), [2D Lights](https://docs.godotengine.org/en/stable/tutorials/2d/2d_lights_and_shadows.html) | Montagem e componentes de apresentação |
| N01 | [Empire: base inspecionada](https://github.com/henriquecoding/empire/commit/afbe0087dd4219752771c800a77e3786218257f8) | Código e inventário preservados da auditoria; leitura adicional do palco nativo |

Os caminhos e hashes da auditoria anterior acompanham o pacote. A revisão não declara uma nova execução de toda a suíte nem uma auditoria de deployment. A documentação pública do fornecedor foi relida; não houve chamada da API PixelLab.

**O01–O04:** referências Enramados, Porto, Fornalha e Oficina, geradas nesta sessão. Os prompts completos, dimensões reais, hashes e inspeção de alfa estão no pacote. São propostas de direção visual, sem aprovação artística ou certificação de grade nativa.

A inspeção dos exemplos e dos planos é reproduzível. A avaliação artística é apresentada com limites e problemas concretos, para que uma geração visualmente apelativa não se transforme silenciosamente numa alegação de asset pronto.
