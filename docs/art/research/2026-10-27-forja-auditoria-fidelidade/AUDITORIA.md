# Forja: por que os sprites perderam o conceito

Auditoria da entrega de 27/10/2026, com pesquisa e ensaios reproduzíveis. **Revisão 2 ampliada**, no mesmo dia: acrescenta caracterização da amostragem, passagem pelo pipeline real, robustez da grade e uma especificação concreta de fidelidade.

**Conclusão:** a entrega sacrificou características do desenho para satisfazer escala e verificações de arquivo. Houve escolha de referência divergente, simplificação imposta no pedido, redução usada como guia de desenho e novas gerações orientadas por esse guia já empobrecido. A extração e o acabamento vieram depois. Corrigir a corda ou acrescentar dentes não restabeleceu a identidade que já tinha sido alterada.

O resultado entregue está **rejeitado pelo autor**. O objetivo deste documento é explicar as causas e especificar a recuperação. As imagens de comparação são evidências da falha, não novas propostas de personagens.

**Descoberta adicional mais importante:** a pureza da amostragem pode chegar a 100% enquanto um traço declarado importante desaparece completamente. Reproduzi isso tanto no amostrador quanto no pipeline da Forja. A ferramenta mede consistência da célula; esse número não comprova preservação de olhos, dentes ou cordas. As seções 12–17 documentam o mecanismo, os limites do ensaio e como corrigir o processo sem transformar outra métrica técnica em aprovação artística.

| Evidência nova | Resultado observado | Decisão que muda |
|---|---|---|
| Traço de 3 pixels na borda de uma célula de 16×16 | Apagado; pureza 1,000; sem aviso de subgrade | Inspecionar também informação descartada nas bordas |
| Linha de 4 pixels sobre transparência | 12 células de linha apagadas na grade declarada; pureza 1,000 | Medir conteúdo removido pelo limiar alfa, inclusive células que viraram transparentes |
| Detalhe central fino com detecção automática | Em parte dos casos, a grade cai para período 2 e a saída cresce para 128×128 | Distinguir recuperação exata de adaptação ao orçamento de pixels |
| Ampliação de PNGs de origem conhecida | 12/12 recuperações exatas nos quatro cenários PNG inteiros por personagem | Conservar o caminho que funciona; ele recupera pixels, sem julgar a qualidade do desenho |
| JPEGs de origem conhecida | Grade e silhueta recuperadas nos seis casos, mas cores não idênticas | Grade correta e pureza alta não significam recuperação RGBA exata |

## 1. O que foi examinado

- A prancha que Henrique anexou nesta mensagem: `7049546F-BD0D-40A7-9EE7-C5A2B388DC4B.jpeg`, 1536×1024.
- Os PNGs, prompts, guias e relatórios intermediários da sessão anterior, inclusive as três tentativas do rei e do escudeiro e as duas do arqueiro.
- O pacote `Empire-Forja-Personagens-2026-10-27.zip`, com os candidatos efetivamente entregues.
- A Forja em `henriquecoding/empire`, commit `0fea413d05b35d9311801c16d4dca883feceed52`. A `main` foi reconferida pelo GitHub e continuava nesse commit durante esta auditoria.
- Os artigos e documentos primários listados no final. O artigo de Gerstner e colaboradores foi também obtido do site de um dos autores e lido nas seções de restrições por importância, pixel e paleta.

Não houve nova geração de personagens nesta auditoria. Não houve alteração de código de produção, integração no jogo ou chamada paga à API do PixelLab.

Os testes e as figuras podem ser reproduzidos com `auditar.py` e os três scripts em `ampliacao-v2/`, conforme `REPRODUZIR.md`. As métricas iniciais estão em `evidencias/metricas.json`; os novos ensaios ficam em `ampliacao-v2/evidencias/`. As caixas usadas para recortar personagens e rostos são anotações manuais de inspeção; não são uma segmentação automática infalível.

## 2. O que os conceitos comunicam e a entrega perdeu

| Personagem | Características da prancha enviada | Divergência da entrega |
|---|---|---|
| Rei | Corpo largo; rosto com pálpebra, sobrancelha e sorriso assimétrico; cabelo e costeletas bem articulados; túnica vinho com dobras; losango; mangas volumosas; capa azul com planos de luz | Rosto e sorriso ficaram mais esquemáticos; relação entre marcas faciais mudou; dobras e planos perderam diferenciação; emblema mudou de forma. O retoque dos dentes foi insuficiente |
| Escudeiro | Expressão ansiosa; relação clara entre elmo, olho, nariz e boca; manga com volume; escudo à frente do corpo; brilho do metal distribuído por planos | Rosto menor e mais rígido; menos informação no elmo e na manga; postura e exposição da espada alteradas; desenho aproveita apenas 45 pixels de altura numa tela de 64 |
| Arqueiro | Capuz verde; túnica predominantemente creme; expressão contida/alerta; corpo relativamente compacto; arco baixo seguro à frente, com outra pose para o disparo | Foi usado outro desenho: roupa verde comprida, corpo mais esguio, sorriso largo, mão na cintura e arco vertical. A identidade mudou antes de qualquer quantização |

O pedido não era inventar versões alternativas desses personagens. Elementos de equipamento ou descrições genéricas da classe não autorizavam a troca da roupa, do sorriso ou da pose do conceito.

Há uma distinção importante entre perder microtextura e perder desenho. Em escala menor, algumas pequenas marcas podem precisar ser fundidas. Pálpebra, canto da boca, forma do nariz, queda da manga, contraste entre materiais e proporções do corpo precisam ser reinterpretados conscientemente. Apagá-los não produz uma adaptação fiel.

## 3. A sequência real que produziu a perda

### 3.1. Uma referência divergente entrou no início

O script `preparar.py` da sessão anterior usou a antiga prancha de rei/escudeiro do repositório e, para o arqueiro, o arquivo `Arqueiro imperial em pixel art.png`, de 26/10. Este último já tinha o traje verde comprido e o sorriso diferente da referência atual.

O próprio pedido descrevia um arqueiro sorridente, com uma mão na cintura e o arco erguido. O gerador seguiu uma direção diferente daquela que Henrique esperava. Recuperar os pixels dessa imagem não pode transformar automaticamente o desenho de volta no arqueiro de roupa creme.

A prancha anexada agora não estava anexada na solicitação inicial desta sessão. Isso limita qualquer afirmação de que o gerador ignorou exatamente este arquivo: ele não o recebeu. Mas confirma um erro no processo de autoridade das referências: a fonte escolhida para o arqueiro não representava o alvo visual esperado. A partir de agora, esta prancha é a referência de trabalho explicitamente indicada nesta revisão.

### 3.2. O pedido impôs uma simplificação estética

O compilador `tools/forja/prompts.py` acrescenta dois tons por material e sugere uma paleta de aproximadamente 12–24 cores. Isso acontece mesmo quando o contrato do personagem não fixa um número máximo de cores.

Os contratos `royal_80` e `royal_64` têm `max_colors: null`. Portanto, o limite aplicado nesta sessão não era uma obrigação numérica desses contratos. Era uma escolha de geração e acabamento.

Na tentativa seguinte, o pedido da sessão acrescentou proibições de novas dobras, textura, novos tons e traços mais finos. Ao tentar corrigir a grade, reduzi também a riqueza do desenho. Essas instruções entraram em conflito com os conceitos, cujas mangas, capa, metal e expressões dependem de planos e pequenas diferenças bem colocadas.

Uma paleta curta pode produzir ótima arte. O erro foi impor uma simplificação genérica antes de identificar quais relações de forma, luz e material precisavam sobreviver.

### 3.3. O gerador não cumpriu a grade inicial

O pedido inicial mencionava 1280×1280, com 80×80 ou 64×64 células lógicas. A superfície de geração integrada não expunha um argumento estruturado de tamanho; escrever o número no texto não o tornava garantido.

Na primeira imagem do rei, a Forja estimou um recorte de 125×123 pixels lógicos. Esse desenho não cabia na tela 80×80. A tentativa de encaixe cortou pixels e falhou. A ferramenta apontou esse problema corretamente.

O fato de a imagem ter aparência de pixel art não demonstrava que tivesse sido desenhada em 80×80. O modelo estava produzindo detalhes numa grade mais fina que a solicitada.

### 3.4. Uma redução virou referência de desenho

Para preparar guias compactos, usei `--cells` para impor novas grades de amostragem e limites de cores. Num dos guias do rei foi usada uma grade 72×72. Isso foi uma redução deliberada, não a descoberta de que a origem já tinha essa resolução.

Em `gridcheck.measure`, a presença de `scale` ou `cells` faz a ferramenta seguir os valores declarados pelo operador. Esse comportamento é útil para uma grade realmente conhecida; não prova que uma grade arbitrariamente fornecida corresponda ao desenho original.

Depois, o resultado reduzido e quantizado foi anexado como guia às gerações seguintes. Na última tentativa do rei e do escudeiro, a imagem anexada era apenas esse guia, e o texto exigia conservar seu rosto de baixa resolução. O conceito original deixou de estar visualmente presente nessa chamada.

Assim, o modelo passou a reproduzir a simplificação anterior. A tentativa de estabilizar os pixels estabilizou também a perda de expressão e detalhe. Esse ciclo precisa ser interrompido na origem: um guia empobrecido não pode assumir a autoridade visual do conceito.

### 3.5. Retoques locais chegaram quando a base já estava errada

No rei, sete pixels foram alterados para reabrir o sorriso com dentes. No arqueiro, dezoito pixels foram alterados no miolo da corda. As provas de composição confirmaram que o exterior dessas zonas permaneceu idêntico.

Isso demonstra preservação local. Não demonstra recuperação da expressão ou da identidade. O olho, a sobrancelha, a massa da bochecha e o contorno do sorriso do rei precisavam ser resolvidos como um conjunto. Acrescentar dentes a uma configuração facial diferente não reconstrói a atuação original.

O mesmo vale para o arqueiro: a corda pode ficar tecnicamente contínua enquanto roupa, pose e personalidade continuam diferentes do conceito.

## 4. Medições da entrega rejeitada

| Personagem | Tela final | Caixa opaca, incluindo equipamento | Altura ocupada | Cores RGB opacas |
|---|---:|---:|---:|---:|
| Rei | 80×80 | 69×66 | 82,5% da altura da tela | 27 |
| Escudeiro | 64×64 | 52×45 | 70,3% da altura da tela | 27 |
| Arqueiro | 80×80 | 51×73 | 91,3% da altura da tela | 27 |

Uma tela de 64×64 não significa que o corpo tenha 64 pixels de altura. O escudeiro entregue tinha 18 linhas vazias acima da caixa opaca e apenas 45 linhas de desenho. Há menos espaço para distinguir pálpebra, pupila, canto da boca, aba do elmo e separações de material.

Isso não significa que se deva ampliar todos os personagens até encostar nas bordas. A escala precisa preservar a relação entre personagens e a pose. Significa que a área útil deve ser planejada e medida separadamente da tela. Um encaixe que evita cortes pode, ainda assim, deixar o desenho pequeno e pobre.

Os contratos atuais permitem alturas a partir de 1 pixel, até o teto. Essa flexibilidade é necessária para poses baixas e efeitos, mas não define a altura desejada de um personagem parado. A leitura da pose estática precisa de um critério próprio de escala, derivado do conceito e do elenco.

Também não é correto comparar diretamente as caixas opacas de duas poses diferentes como se fossem a mesma anatomia. Uma espada levantada ou uma capa aberta altera a caixa. Por isso a recuperação deve primeiro conservar a pose de referência.

## 5. Ensaio controlado: quanto da falha vem da paleta final?

Foi reconstruída a extração de grade das imagens efetivamente selecionadas para a entrega. Mantive a mesma amostragem, limpeza, normalização do contorno e posicionamento, variando apenas o limite de cores: sem quantização, 28, 48 e 64 cores pedidas.

São doze variantes analíticas, sem nova geração. A variante com 28 cores reproduziu **byte a byte as três bases entregues antes dos retoques locais**. Isso verifica que o ensaio está isolando a operação realmente usada.

| Personagem | Cores antes da quantização final | Com limite 28 | Com limite 64 | Pixels opacos com RGB alterado no limite 28 | Distância média OKLab |
|---|---:|---:|---:|---:|---:|
| Rei | 958 | 27 | 63 | 75,0% | 0,00539 |
| Escudeiro | 532 | 27 | 63 | 69,9% | 0,00589 |
| Arqueiro | 656 | 27 | 63 | 64,8% | 0,00379 |

Essas porcentagens **não significam que 75% dos detalhes do rei foram apagados**. Basta uma pequena mudança de RGB para um pixel entrar na contagem; grande parte das centenas de cores de entrada é variação residual do gerador. A distância média pequena ajuda a contextualizar a diferença cromática, mas não é uma nota de qualidade artística nem um limiar perceptual calibrado para estes sprites.

A observação visual mais importante é outra: na variante sem quantização final, o rosto e as proporções já estão descaracterizados. A variante com 64 cores mantém os mesmos problemas. Aumentar o número de cores no fim não restaura formas ou expressões já perdidas.

Este ensaio não isola o efeito das instruções de cor e simplificação dadas **antes** da geração. Elas podem ter influenciado o desenho recebido. O que foi isolado foi o acabamento final, e ele não é a causa suficiente da descaracterização.

As figuras `01-referencia-versus-entrega.png`, `02-cadeia-de-perda-rei.png` e `03-teste-controlado-de-paleta.png` mostram essas diferenças. As imagens foram recortadas e ajustadas para exibição; não são novas revisões artísticas.

## 6. O que a Forja atual verifica e o que não produz

A Forja inspecionada organiza pedidos, mede ou estima grades, amostra células, trata transparência, converte cores, ajusta contorno e encaixe, verifica contratos e exporta arquivos. Não há, nesse pipeline, um modelo próprio treinado para redesenhar olhos, mãos ou tecido com a identidade de um personagem.

O núcleo de `pipeline.snap` amostra a cor de cada célula. Uma votação local não sabe que um pequeno branco é um dente indispensável ou que uma linha escura é a pálpebra que dá arrogância ao rei. Se o gerador desenhou esse sinal abaixo da grade, a votação pode perdê-lo.

Os módulos recentes de referências e preservação local são úteis. Porém, um registro com o rótulo de conceito não valida sozinho se o arquivo escolhido é o personagem certo. Uma máscara preserva o exterior de uma edição; não avalia se o desenho preservado está fiel.

O pacote anterior registrava os candidatos como `adaptation_in_review`, e o encerramento não os considerava aprovados. Isso foi tecnicamente honesto, mas não torna aceitável entregar um resultado visivelmente distante do pedido. Eu precisava ter reprovado a comparação artística antes de apresentar a rodada como trabalho concluído.

### Outros conflitos que precisam de revisão

- **Perfil estrito imposto a toda a figura.** O conceito usa leitura lateral com peito, mangas e mãos organizados para clareza. A instrução universal de perfil estrito pode restringir essa construção. É um possível conflito de direção visual; não foi isolado com uma nova geração controlada nesta auditoria.
- **Proibição indiscriminada de detalhes finos.** Pixel de um olho, brilho de metal e ruído são funções diferentes. A ferramenta já distingue algumas categorias, mas o pedido da sessão voltou a proibir detalhes úteis de forma genérica.
- **Paleta extraída da própria saída.** Verificar um PNG contra uma paleta extraída desse mesmo PNG confirma consistência interna, não correspondência aos materiais do conceito ou à paleta oficial.
- **Avaliação de equipamento depende da observação.** As regiões e oclusões foram anotadas pelo agente. Um resultado geométrico válido significa que as regiões declaradas passaram nos testes; não prova que o objeto tenha sido detectado corretamente nem que corresponda à arma do conceito.
- **Muitas etapas de redesenho global.** Cada nova geração pode alterar expressão, proporções e roupa. Preservar palavras no prompt não preserva os pixels nem os pontos anatômicos.

## 7. O que a pesquisa acrescenta à solução

### 7.1. Desenhar agrupamentos inclui refinar detalhes importantes

Saint11 descreve um processo que parte de agrupamentos grandes e avança para refinamento, correção das bordas, contraste e detalhes. Ele também mostra que pixels isolados podem ter funções fortes, como um olho. A aplicação ao Empire é conservar os sinais relevantes e retirar ruído, em vez de tratar toda pequena marca como algo a eliminar. [S1]

No estudo de luz, Saint11 distingue planos, sombras e reflexos. Em um exercício de adaptação, dá destaque a olhos e boca para mantê-los legíveis. Isso fundamenta a necessidade de redesenhar os traços importantes na escala final, em vez de esperar que uma redução uniforme os preserve. [S2]

Sua discussão de anti-aliasing trata a escolha de pixels e semitons como uma decisão de desenho. Não autoriza blur global nem obriga a introduzir anti-aliasing nos sprites do Empire. Qualquer alteração dessa regra artística precisaria ser reconciliada com o contrato do projeto. [S3]

### 7.2. A paleta e a posição das informações precisam ser controladas juntas

Gerstner e colaboradores estudam a abstração de imagens com redução de resolução e paleta e acrescentam controle humano. As seções 5.1–5.3 apresentam um mapa de importância, restrições de cor por pixel e a possibilidade de fixar cores da paleta. O método oferece uma aproximação ao trabalho de artistas, não uma prova automática de identidade. [S4]

A aplicação proposta aqui é reservar atenção para rosto, mãos e equipamento e limitar cores por material quando necessário. Não foi implementado nem executado o algoritmo integral do artigo nesta auditoria.

### 7.3. Controlar a célula exige mais do que citar seu tamanho no texto

O trabalho de Wu e colaboradores separa o controle das células e dos efeitos de aliasing, usando uma referência de pixel art no modelo. Isso demonstra uma abordagem específica de condicionamento da estrutura. Não demonstra que o gerador utilizado nesta sessão consiga obter o mesmo controle por um prompt textual, nem que esse método preserve qualquer personagem sem revisão. [S5]

A Forja atual estima uma estrutura depois da geração. Essa função não equivale a um gerador treinado para desenhar nessa estrutura.

### 7.4. O PixelLab distingue conversão, recuperação de escala e geração

A especificação pública consultada distingue `unzoom`, `image-to-pixelart` e correção de pixel art existente. O modo fiel da conversão usa `fixer`; a força de partida da imagem tem uma faixa útil documentada de 100–300. Aumentar indiscriminadamente essa força pode conservar a entrada sem realizar a adaptação desejada. O `unzoom` recupera escala; não é um redesenho semântico. [S6]

Há ainda uma diferença operacional: o endpoint padrão permite solicitar dimensões de saída, enquanto a descrição atual do endpoint Pro informa que o tamanho é decidido automaticamente. Portanto, “usar Pro” não garante por si só 80×80. Os retornos continuam precisando de medição. Esses endpoints não foram executados nesta auditoria.

### 7.5. Volume e expressão continuam sendo trabalho de desenho

O tutorial de Derek Yu trabalha forma e volume, planos de sombra, contornos e acabamento em sprites, incluindo um exercício de 96×96. A restrição de resolução não elimina a necessidade de construir anatomia e atuação. Para o Empire, um sorriso precisa funcionar com sobrancelha, olho, nariz e bochecha; quatro pixels brancos acrescentados no final não substituem essa construção. [S7]

## 8. Procedimento recomendado de recuperação

### Etapa A — fixar o alvo visual de cada pose

Usar a prancha enviada agora como fonte desta revisão e extrair cada personagem e pose separadamente. Guardar o arquivo original, seu hash e a caixa do recorte. O recorte não muda a aprovação do desenho nem transforma uma imagem JPEG em sprite nativo.

Para cada pose, registrar roupa, expressão, posição das mãos, orientação da arma e relação entre cabeça e corpo. O arqueiro não recebe túnica verde comprida ou sorriso novo por ser um arqueiro. O escudeiro não precisa exibir a espada em outra posição para provar que a possui.

O conceito deve continuar anexado e identificado nas tentativas de recuperação. Um guia técnico pode fornecer grade ou pontos de apoio, mas não assumir a autoridade de rosto, roupa e materiais.

### Etapa B — distinguir recuperação de grade de adaptação

Se a imagem for uma ampliação real de pixel art, recuperar a grade medida, inicialmente sem reduzir cores. Se a origem tiver uma grade não uniforme ou detalhes incompatíveis com a tela final, reconhecer que ela requer adaptação de desenho.

Não fornecer `--cells 80x80` apenas para fazer uma origem maior caber. Quando uma grade é imposta para estudo, registrar explicitamente que houve redução e que a saída não é prova de recuperação fiel.

No JPEG anexado há compressão e uma prancha com várias figuras. Não é possível prometer uma recuperação exata de todos os pixels originais. Uma fonte PNG intacta, se já existir, melhora a análise; este diagnóstico não depende de obter outro anexo.

### Etapa C — resolver o desenho na escala útil

Manter as telas 80×80 para rei/arqueiro e 64×64 para escudeiro. Planejar a caixa útil a partir da pose e das proporções do conceito, com margens suficientes. Não começar pelo encaixe automático de um desenho excessivamente grande.

No rei, resolver em conjunto pálpebra, direção da pupila, inclinação da sobrancelha, nariz da mesma família da pele, abertura assimétrica do sorriso e volume da bochecha. No escudeiro, resolver olho, aba do elmo, nariz e boca ansiosa antes de ornamentar o metal. No arqueiro, recuperar primeiro a roupa creme, o capuz, a expressão e a pose correta.

A regra de que a pupila pode ter um pixel não significa que o olho inteiro só possa ter um pixel. A expressão resulta da disposição de várias marcas e de seus intervalos. O espaço para elas precisa ser reservado desde o início.

Se esses sinais não sobrevivem à primeira adaptação, o próximo passo é reconstruir essas regiões em pixels nativos, com referência e inspeção, e não quantizar novamente a figura inteira.

### Etapa D — organizar cores por material e função

Primeiro conferir se o desenho contém os planos essenciais. Depois escolher rampas para pele, cabelo, tecido vinho, creme, azul, metal e couro. Conservar as diferenças de material do conceito e os contrastes que separam as partes.

O limite de cores precisa vir do contrato e da direção de arte. Não deve ser escolhido apenas porque um número parece típico de pixel art. O ensaio de 28/48/64 serve para estudar impacto, não para declarar que 64 é uma cura automática.

Quantização global não deve decidir sozinha o tom de um dente, o brilho do elmo ou a corda. Para regiões sensíveis, usar cores declaradas e conferidas; onde houver conflito com a paleta oficial, registrá-lo e resolver a rampa conscientemente.

### Etapa E — editar localmente depois de obter uma base fiel

Quando a base realmente corresponder ao conceito, usar máscaras locais e composição para mudanças pontuais. A prova do exterior preservado deve continuar obrigatória após todo acabamento.

Se for necessário mudar o rosto inteiro para recuperar a expressão, a região autorizada precisa abranger esse sistema de traços. Uma caixa artificialmente pequena pode preservar tecnicamente a maior parte de um rosto errado.

Não registrar um dos candidatos rejeitados desta sessão como mestre aprovado. Sua preservação só teria utilidade de regressão ou comparação.

### Etapa F — conferir o objetivo artístico antes de encerrar

Examinar conceito e candidato lado a lado: corpo inteiro, rosto, mãos, materiais e equipamento; escala nativa e ampliação inteira. Usar a mesma pose para evitar confundir mudanças de gesto com deformação.

Reprovar a tentativa quando roupa, expressão, proporção ou posição do equipamento tiverem mudado sem pedido. Depois dessa leitura, verificar tela, alfa, encaixe, paleta, arquivos editáveis e integração. Os arquivos precisam estar corretos e o desenho precisa corresponder ao alvo.

## 9. Mudanças concretas propostas para a Forja

| Prioridade | Componente | Alteração proposta | Evidência de que funciona |
|---|---|---|---|
| Alta | Planejamento e referências | Vincular personagem e pose a um recorte de autoridade, com hash da origem e invariantes visuais | Uma referência alternativa não substitui silenciosamente a indicada; roupas e pose são conferidas na comparação |
| Alta | Compilador de pedidos | Separar adaptação fiel de geração estilizada; tornar quantidade de tons e cores decisões explícitas | Ausência de limite no contrato não impõe automaticamente 12–24 cores ou dois tons por material |
| Alta | Proveniência de grade | Distinguir grade medida, estimada e imposta, além de simples redução de estudo | Um `--cells` fornecido pelo operador não aparece como evidência de autoria nativa na grade |
| Alta | Revisão de identidade | Acrescentar comparação obrigatória de rosto, roupa, proporções, mãos e pose | Um contrato raster válido com arqueiro de roupa divergente permanece reprovado para fidelidade |
| Média | Planejamento de escala | Registrar altura útil por personagem/pose, separada da tela | A pose parada recebe a escala planejada; agachar e sentar não são esticados para preencher a tela |
| Média | Paleta e regiões | Aplicar restrições por material e proteger sinais com função declarada | Um branco de dente ou corda não é removido só por ser pequeno; conflitos permanecem visíveis |
| Média | Experimentos | Guardar comparações que alterem uma única etapa por vez | É possível localizar se uma falha entrou na geração, amostragem, cores ou edição, reproduzindo a base entregue |

Essas são especificações de mudança, não funcionalidades implementadas nesta auditoria. As regras do projeto e a direção de arte precisam continuar explícitas; não se propõe alterar silenciosamente o dossiê ou os contratos de runtime.

## 10. Piloto de recuperação com critério de sucesso

Começar por uma única pose do rei da prancha atual, preservando a referência integral. Comparar dois caminhos: recuperação de grade quando a origem a suporta, e adaptação com prioridade para os traços do conceito. Conferir primeiro cabeça e corpo estático; a série e as animações vêm depois.

Se for testada a conversão do PixelLab, usar o endpoint que aceita o tamanho de saída pretendido e comparar modo fiel com forças 100, 200 e 300, mantendo referência e seed. Esses valores são um desenho de experimento, não uma promessa de qualidade nem um pedido executado. Um modo Pro com saída automática requer outro tratamento e não pode ser comparado como se garantisse a mesma dimensão.

Para cada retorno, guardar o original e medir o resultado antes de qualquer acabamento. Examinar a expressão e a proporção antes de usar a imagem como referência de outra geração. Uma variante que corrige a grade mas destrói a atuação é descartada.

O critério de sucesso é a leitura próxima do conceito nas telas existentes, com os materiais e sinais de personalidade preservados, arquivo íntegro e revisão artística real. Não é apenas obter `ok` na ferramenta ou um PNG com as dimensões certas.

## 11. Limites e estado final desta auditoria

O diagnóstico do caminho executado é sustentado por arquivos, código, medições e comparação visual. O efeito isolado de cada frase do prompt não foi medido com novas gerações. As propostas de adaptação e os métodos externos ainda precisam de piloto com as mesmas referências; não se declara que algum deles já resolveu o elenco.

Os candidatos anteriores continuam rejeitados. A reconstrução fiel dos personagens não foi realizada neste trabalho de pesquisa. O relatório não apresenta novas imagens como se essa reconstrução estivesse pronta.

## 12. Ensaio novo: um sinal pode desaparecer sem reduzir a pureza

### 12.1. O que foi isolado

Construí seis imagens artificiais com uma grade conhecida: 16×16 células, cada uma ampliada para 16×16 pixels de arquivo. Acrescentei marcas escuras ou claras de tamanho e posição declarados. O restante da imagem permanece igual a uma versão de controle sem a marca. Não são propostas de personagens e não simulam toda a complexidade de um rosto.

O script `testar_microdetalhes.py` compara cinco métodos (`dominant`, `mode`, `center`, `median`, `mean`) com dois recuos de amostragem (`inset=0,18` e `0`). São 60 configurações sobre seis fixtures, não 60 personagens independentes. A comparação pergunta se a marca teve algum efeito no pixel final e se a cor declarada sobreviveu exatamente. Não chama qualquer gerador.

### 12.2. O recuo elimina grande parte da célula antes do voto

No padrão atual, `_inner` retira uma margem arredondada de 18% de cada lado. Para uma célula de 16×16, são 3 pixels por lado: o voto usa apenas o centro de 10×10. Isso corresponde a **39,06% da área da célula**; os outros 60,94% não participam da escolha da cor.

Essa operação tem um propósito válido: reduzir a influência de bordas suavizadas e ruído de um gerador. Entretanto, um traço intencional na margem também é excluído. No primeiro caso, uma linha escura de 3×16 pixels fica inteiramente fora do centro amostrado. O resultado é pele uniforme e a medição de pureza é exatamente 1,0, porque o centro remanescente é uniforme.

Aqui a métrica não encontrou e aprovou o traço; ela nunca o mediu. O diagnóstico precisa distinguir uma célula cujo conteúdo inteiro é uniforme de uma célula cujo centro é uniforme após excluir um sinal relevante.

### 12.3. Maioria cromática e importância de desenho são coisas diferentes

No segundo caso, o traço central ocupa 4 das 10 colunas amostradas: 40% da área. O voto dominante escolhe os 60% de pele e apaga o sinal. No terceiro, o traço ocupa 6 colunas, torna-se maioria e sobrevive. A pureza global arredondada fica em **0,9984 em ambos**, apesar dos resultados opostos para a marca.

Uma marca clara central de 4×4 pixels ocupa 16% do centro de 10×10. Ela desaparece, e a pureza global fica em 0,9994. A pureza local da célula ainda supera o limite de 0,7 usado para marcar mistura. Assim, nem sequer entra na lista de células impuras.

| Fixture | Sinais na grade final, padrão dominante | Pureza global | Alerta de subgrade |
|---|---:|---:|---|
| Traço escuro de 3 pixels na borda | 0/1 | 1,0000 | Não |
| Traço escuro central de 4 pixels | 0/1 | 0,9984 | Não |
| Traço escuro central de 6 pixels | 1/1 | 0,9984 | Não |
| Marca clara central de 4×4 | 0/1 | 0,9994 | Não |
| Controle positivo: célula inteira | 1/1 | 1,0000 | Não |
| Linha fina sobre transparência | 0/12 | 1,0000 | Não |

Na tabela, “sinal” é uma marca cujo propósito foi declarado no teste. Não há reconhecimento automático de dentes ou pálpebras. O ensaio demonstra um mecanismo plausível e reproduzível de perda, sem atribuir a ele uma porcentagem da descaracterização dos três personagens reais.

### 12.4. Transparência cria um ponto cego adicional

A linha de 4 pixels sobre transparência cobre 40% do centro amostrado. A regra `coverage=0,5` transforma a célula em transparente. Isso acontece nas 12 células percorridas pela linha.

O código devolve pureza 1,0 para uma célula descartada por cobertura. Além disso, a média global reúne apenas pixels finais opacos. O diagnóstico de subgrade também considera a opacidade da saída. Portanto, a linha removida pode desaparecer da própria população de células examinadas.

Não basta procurar baixa pureza nos pixels que sobraram. É preciso registrar a massa alfa de entrada, a decisão de descarte e a informação perdida antes de formar a saída. Em uma região declarada como corda ou outro elemento fino, esse descarte precisa ficar visível mesmo que ocupe uma fração pequena da imagem.

### 12.5. Os limiares globais escondem uma perda local importante

No caso do traço central de 4 pixels, a célula aparece como misturada, mas representa apenas 1/256 da tela, aproximadamente 0,4%, com grupo máximo de uma célula. O aviso atual de subgrade exige participação de pelo menos 5% ou grupo com pelo menos 12 células. Não dispara.

Esses limiares podem ser úteis contra ruído espalhado. Não servem como garantia de um detalhe facial: perder uma única célula pode mudar um olho ou a abertura da boca. A revisão precisa de um critério por região e função declarada, além do resumo global.

Também é necessário explicitar o significado de `purity` por método. No código examinado, `mode`, `center`, `median` e `mean` retornam 1,0 sem calcular a concordância cromática usada pelo dominante. Esse valor não deve ser apresentado como uma confiança comparável entre todos os métodos. Uma opção de relatório é marcar essa confiança como “não calculada”, conservando a compatibilidade dos dados técnicos onde necessário.

### 12.6. Trocar um parâmetro não resolve a adaptação

O ensaio com `inset=0` não recuperou o traço de borda pelo voto dominante. Ele continua minoria. O traço central de 6 pixels, antes preservado no núcleo de 10, passa a ser minoria na célula completa de 16 e desaparece. Retirar o recuo pode piorar esse caso.

O método `center` conserva algumas marcas centrais, mas perde o traço na borda. Todos os cinco métodos perdem a linha fina transparente na configuração testada, porque a regra de cobertura ocorre antes da escolha da cor. A média introduz influência cromática em alguns casos, mas um tom intermediário não equivale a conservar um dente branco ou uma linha escura legível.

A terceira coluna da prancha `04-microdetalhes-e-pureza.png` demonstra uma restrição explícita de cor: a célula nativa é pintada com a cor declarada. Isso amplia a marca para um pixel inteiro. É uma decisão de adaptação, não recuperação exata, nem prova de boa expressão. Duas marcas de cores diferentes que disputem o mesmo pixel não podem ser preservadas simultaneamente por uma única cor; o conflito exige reorganizar o desenho.

## 13. Confirmação no pipeline e limites da detecção automática

Repeti as seis fixtures pelo `pipeline.forge`, uma vez declarando a escala conhecida de 16 e outra deixando a ferramenta medir a grade. São 12 passagens. Usei o contrato livre, sem quantização, sem encaixe e com contorno preservado, para estudar a passagem pelo pipeline sem impor o desenho de um personagem.

Com escala declarada, os resultados de presença de marca confirmaram o ensaio do amostrador. O traço de borda e a linha transparente desapareceram com pureza 1,0 e sem aviso de subgrade. Isso não significa que todos os relatórios estivessem vazios: algumas fixtures produziram outros achados, como fragmentos; eles não identificavam a perda do sinal declarado. A linha transparente com escala conhecida não produziu nenhum desses achados.

Com detecção automática, houve dois comportamentos distintos:

- Para o traço de borda, o período estimado ficou em aproximadamente 16. A marca desapareceu, a pureza foi 1,0 e não houve aviso de subgrade. Portanto, o ponto cego não depende apenas de uma escala forçada pelo operador.
- Para a marca central de 4 pixels e a marca clara, a ferramenta identificou uma ampliação exata de período 2. Preservou o detalhe, mas produziu uma grade de 128×128, em vez da grade corporal pretendida de 16×16. Na linha transparente, também escolheu período 2 e preservou a linha numa saída maior.

O segundo comportamento não é um erro de cálculo de uma ampliação exata. Um divisor menor pode representar todos os traços de uma imagem de escalas misturadas. O problema é outro: **a grade que explica todos os pixels pode exceder o orçamento de pixels do jogo**. Forçar a grade mais grossa então se torna uma adaptação com perda, que precisa de decisões de desenho.

Os testes usam contrato livre para caracterizar esse comportamento. Não se afirma que as saídas maiores passariam nos contratos `royal_80` ou `royal_64`. O erro anterior foi tentar resolver o conflito reduzindo e usando essa redução como nova autoridade artística.

O relatório de grade deve apresentar pelo menos: origem da grade, período, dimensão recuperada, evidência de ampliação exata, zonas de escala incompatível e adequação à tela de destino. Um único campo de confiança não substitui essas informações. `confidence=0,92` não significa “92% de fidelidade ao personagem”.

## 14. Robustez: o que a Forja recupera corretamente

### 14.1. Método e resultados

Parti dos três PNGs nativos rejeitados, cuja origem exata é conhecida, e apliquei sete perturbações a cada um. Eles servem como fixtures técnicas; não como exemplos positivos de direção de arte. O objetivo foi testar a recuperação de pixels com verdade de referência disponível.

| Perturbação | Casos | Pixels RGBA exatos após recuperar | Silhueta exata | Interpretação |
|---|---:|---:|---:|---|
| PNG com nearest-neighbor 8× | 3 | 3 | 3 | Recuperação correta |
| PNG com nearest-neighbor 13× | 3 | 3 | 3 | Recuperação correta |
| PNG 8× com corte fora de fase no topo/esquerda | 3 | 3 | 3 | Fase recuperada sem cortar o conteúdo opaco |
| PNG 8× com blur gaussiano leve, raio 0,35 | 3 | 3 | 3 | Os centros bastaram nessas três fixtures |
| JPEG 8×, qualidade 95 e 75, sem subamostragem de croma | 6 | 0 | 6 | Grade e forma recuperadas; cores mudaram |
| Redimensionamento bilinear para 1254×1254 | 3 | 0 | 0 | Grade não recuperada; retorno tratado como nativo em escala 1 |

São 21 perturbações sobre três origens. Nos quatro primeiros cenários, a recuperação foi exata em 12/12 casos. Isso reforça que o caminho de recuperar uma ampliação verdadeira deve ser preservado. Não há justificativa para regenerar globalmente um sprite que já existe como ampliação recuperável.

### 14.2. JPEG: acertar a grade não recupera as cores originais

Nos seis JPEGs, o período 8 e a silhueta foram recuperados, mas nenhum retorno foi idêntico em RGBA à origem. Em seguida, fiz um diagnóstico adicional com a paleta verdadeira de cada PNG, conhecida apenas porque construí o ensaio a partir dele.

O remapeamento à paleta verdadeira recuperou exatamente os dois JPEGs do arqueiro. Permaneceram 29 pixels diferentes em cada JPEG do rei e 7 em cada JPEG do escudeiro, incluindo um pixel diferente nas caixas faciais anotadas de cada um. Não se mediu se esses pixels mudaram a expressão; a comparação é técnica.

Esse resultado demonstra que “a paleta certa” tampouco garante sempre a recuperação de pixels. Em um JPEG arbitrário, a paleta verdadeira nem sequer está disponível. Nos seis casos a pureza da amostragem era 1,0, o que novamente não significava igualdade com a origem.

O ensaio usou fundo magenta conhecido para remover o fundo que o JPEG não consegue tornar transparente. Não representa toda combinação de compressão, subamostragem, fundo e recorte encontrada em pranchas. A referência real é um JPEG de uma prancha maior; esses resultados não autorizam prometer recuperação perfeita dela.

### 14.3. Reamostragem fracionária: reconhecer a insuficiência da medição

Nas três entradas bilineares de 1254×1254, a estimativa de período foi recusada pela própria medição por baixa pureza. A imagem foi tratada como nativa em escala 1 e o recorte continuou muito maior que o destino. Isso é uma falha de recuperação identificável; não é evidência de um sprite errado aprovado pelo contrato real.

A mensagem que sugere `--scale` ou `--cells` é útil quando o operador conhece a grade de origem. Se não a conhece, esses argumentos não devem servir como atalho automático para declarar que a recuperação foi fiel. A nova interface precisa deixar explícita a diferença entre “não consegui medir” e “o operador escolheu reduzir para este tamanho”.

## 15. Pesquisa adicional: alternativas e critérios de avaliação

### 15.1. Preservar bordas é uma direção de pesquisa, não compreensão do personagem

Kopf, Shamir e Peers ajustam posição e forma dos filtros de redução às estruturas locais da imagem. O trabalho apresenta resultados para imagens naturais e preservação de linhas em gráficos vetoriais convertidos para pixel art. Isso sustenta testar amostragem adaptativa ao conteúdo como alternativa à votação uniforme. Não demonstra que o método saiba qual sorriso pertence ao rei. [S8]

Öztireli e Gross formulam a redução com uma função perceptual e mostram preservação de sinais relevantes nos seus experimentos. O resultado motiva comparar conservação de contraste e estrutura, além de erro médio de cor. Seu estudo não certifica rostos do Empire em 80×80, nem substitui um teste com nossos alvos e a paleta do projeto. [S9]

Para um piloto, as alternativas devem receber a mesma entrada e o mesmo destino. Primeiro comparar amostrador atual, variações de parâmetros e restrições locais declaradas. Somente depois incorporar um método externo com custo, licença e dependências conhecidos. Não foi executado o algoritmo desses dois artigos nesta auditoria.

### 15.2. SSIM, LPIPS e médias não devem emitir aprovação de identidade

Zhang e colaboradores avaliaram atributos profundos como medidas de similaridade perceptual contra julgamentos humanos no conjunto de dados do trabalho. Isso faz do LPIPS uma ferramenta possível de comparação, não um avaliador já calibrado para estes sprites. [S10]

Uma medida global pode ser dominada por capa, fundo ou tronco e diluir uma alteração pequena de olho ou boca. Cortar e alinhar regiões pode torná-la mais informativa, mas a escolha de alinhamento, máscara, interpolação e escala também muda o resultado. Não existe, nesta auditoria, base para inventar um limiar como “SSIM acima de 0,95” ou “LPIPS abaixo de 0,1” e declarar o personagem aprovado.

Blau e Michaeli distinguem matematicamente distorção e qualidade perceptual em restauração de imagens, sob a formulação do artigo. A aplicação prudente aqui é evitar equiparar erro numérico pequeno a qualidade percebida. O estudo não prova que fidelidade de identidade e boa pixel art sejam incompatíveis, nem que a simplificação desta entrega fosse inevitável. [S11]

Para Empire, há pelo menos quatro perguntas separadas: o arquivo cumpre o runtime? Os sinais declarados sobreviveram ao processamento? O candidato conserva a identidade e a pose? O desenho é bom e legível na escala de uso? Uma única pontuação mistura tarefas que exigem evidências diferentes.

## 16. Especificação concreta de fidelidade proposta

O arquivo `ampliacao-v2/CONTRATO-FIDELIDADE-PROPOSTO.json` transforma as recomendações em dados revisáveis. É uma proposta de formato, **ainda não lida pela Forja atual**. Não registra os candidatos como mestres e não inventa uma aprovação do usuário.

### 16.1. Autoridade e modo de trabalho

Cada personagem/pose deve referenciar o SHA-256 da origem e uma caixa de recorte. As caixas incluídas são anotações manuais, com possíveis sombras ou chão, e precisam de confirmação durante o piloto. Recortar uma prancha não torna seu raster um mestre nativo.

O modo da operação deve ser explícito:

- `recover_grid`: recuperar uma ampliação existente; igualdade com uma origem nativa conhecida é uma prova técnica forte quando essa origem existe.
- `adapt_concept`: reorganizar desenho para o destino; precisa de invariantes e comparação artística, sem promessa de igualdade pixel a pixel ao conceito maior.
- `edit_approved_master`: alterar uma região autorizada de um mestre realmente aprovado; requer máscara e igualdade do exterior após todo o acabamento.

Uma proposta de adaptação não pode ganhar autoridade só porque passou no runtime. Um derivado usado como guia carrega o hash de sua origem e seu estado de revisão, mantendo o conceito original anexado como referência de identidade.

### 16.2. Invariantes por personagem

| Personagem | Preservar primeiro | Bloqueia a fidelidade quando alterado sem pedido |
|---|---|---|
| Rei | Massa larga do corpo, relação cabeça/tronco; atuação conjunta de sobrancelha, pálpebra, pupila e sorriso; túnica vinho, capa azul, manga creme, losango; nariz na família da pele | Emagrecimento, sorriso genérico, emblema arbitrário, rosto reduzido a dentes sem a expressão |
| Escudeiro | Ansiedade no rosto; relação entre aba do elmo e olho; escudo de madeira com miolo azul à frente; tecido vinho e creme; postura da referência | Rosto neutro, mudança do gesto para mostrar espada, elmo e escudo que ocultam sinais diferentes daqueles do conceito |
| Arqueiro | Capuz verde e roupa creme; expressão alerta; arco baixo segurado à frente na pose estática; relações entre mãos e equipamento | Túnica verde comprida, sorriso novo, mão na cintura ou arco vertical retirados de outra referência |

Essas são decisões visuais extraídas da prancha. Não devem virar caixas de verificação preenchidas automaticamente por quem acabou de gerar a imagem. A comparação precisa mostrar o conceito e o candidato e registrar observações específicas de cada região.

### 16.3. Regiões críticas, perda e conflitos

Para uma região crítica, guardar coordenadas na origem e no destino, função, material e o que deve continuar visível. Onde ainda não existe um destino nativo fiel, as coordenadas ficam pendentes: não se deduz um ponto preciso só pela escala da tela inteira.

O processamento deve produzir uma trilha por etapa: informação de entrada, cobertura alfa, cor escolhida, justificativa de descarte e violações das restrições declaradas. Perder uma região marcada como indispensável deve bloquear a fidelidade, mesmo que a média global continue alta.

Restrições pontuais precisam de detecção de conflito. Se uma pálpebra escura e um dente claro acabam exigindo o mesmo pixel, o resultado é `layout_conflict`. Não vale sobrescrever silenciosamente a primeira cor ou fundi-las numa média. É preciso reservar outra célula, ajustar o desenho ou revisar a exigência com evidência visual.

### 16.4. Estado final sem aprovação fictícia

A proposta distingue quatro verificações: runtime, preservação de sinais declarados, revisão visual de identidade e autorização do mestre. `technical_pass=true` não preenche os demais campos. Uma avaliação ausente fica pendente; uma divergência obrigatória fica bloqueada.

O arquivo inclui o estado atual como rejeitado para os três candidatos, conserva 80×80/64×64/80×80 e deixa o planejamento da caixa útil e as coordenadas nativas em aberto. Também conserva `max_colors=null` dos contratos: uma quantidade de cores só é imposta por decisão explícita de direção de arte ou regra real do projeto.

## 17. Ordem de implementação e prova de resultado

O arquivo `ampliacao-v2/PLANO-DE-IMPLEMENTACAO.md` detalha módulos, comportamento esperado e critérios de aceite. A ordem prioriza impedir a repetição da falha antes de acrescentar um novo conversor.

1. **Corrigir autoridade e pedidos.** Exigir origem/personagem/pose, separar guia técnico de conceito, retirar restrições estéticas implícitas no modo fiel e registrar o modo de operação.
2. **Tornar as perdas visíveis.** Medir centro e célula inteira separadamente, preservar diagnóstico de descarte alfa e informar o significado da pureza por método. Acrescentar avaliações nas regiões críticas.
3. **Proteger sinais declarados.** Aplicar restrições locais com detecção de conflitos e auditoria após paleta, limpeza, contorno e encaixe. A proteção precisa sobreviver ao pipeline inteiro.
4. **Conferir identidade antes de fechar.** Mostrar corpo, rosto, mãos e materiais na mesma pose, em escala nativa e inteira, com estados de revisão reais.
5. **Executar um piloto de uma pose.** Construir uma base fiel do rei antes de produzir o elenco e as animações. Não alimentar outra geração com uma base reprovada.

Os novos ensaios formam uma caracterização reproduzível, não uma alegação de correção: 60 configurações do amostrador, 12 passagens pelo pipeline e 21 perturbações de grade. As 12 variantes de paleta da primeira revisão permanecem separadas. Os grupos reutilizam origens e não constituem uma amostra estatística de qualidade artística.

Para regressão técnica, manter ampliações exatas, fase deslocada, transparência, marcas finas e conflitos de restrição. Para avaliar adaptação artística, construir um conjunto diferente: pares conceito/candidato revisados pelo autor, com exemplos aceitos e rejeitados e razões por região. Os três PNGs desta entrega só fornecem exemplos rejeitados; não bastam para calibrar automaticamente uma nota de fidelidade.

O primeiro resultado que demonstrará recuperação artística será uma pose nativa que conserve a atuação, roupa, proporção e equipamentos do conceito, julgada lado a lado pelo autor. Até esse resultado existir, a correção do processo pode estar pronta e os testes técnicos podem passar, mas a recuperação dos personagens continua pendente.

## Fontes primárias

Consultadas em 27/10/2026. Os estudos anteriores do projeto não foram tratados como prova de que a nova entrega estava boa.

- **[S1] Saint11 — Cluster Sketching and Painting.** Agrupamentos, refinamento, função de pequenos detalhes: https://saint11.art/pixel_art_articles/article2/
- **[S2] Saint11 — Basic Shading.** Planos de luz e adaptação de sinais importantes: https://saint11.art/pixel_art_articles/article4/
- **[S3] Saint11 — Anti-Alias and Banding.** Escolhas locais de desenho de bordas: https://saint11.art/pixel_art_articles/article5/
- **[S4] Gerstner et al. — Pixelated Image Abstraction with Integrated User Constraints, Computers & Graphics 37(5), 2013, pp. 333–347.** DOI: https://doi.org/10.1016/j.cag.2012.12.007 ; página do projeto: https://cragl.cs.gmu.edu/pixelate/journal.html ; PDF do autor: https://www.nealen.net/papers/pixelated_image_abstraction-journal.pdf
- **[S5] Wu et al. — Make Your Own Sprites: Aliasing-Aware and Cell-Controllable Pixelization, ACM TOG 41(6), 2022.** DOI: https://doi.org/10.1145/3550454.3555482 ; registro universitário: https://researchportal.bath.ac.uk/en/publications/make-your-own-sprites-aliasing-aware-and-cell-controllable-pixeli/ ; código dos autores: https://github.com/WuZongWei6/Pixelization
- **[S6] PixelLab — OpenAPI v2 e documentação de conversão.** https://api.pixellab.ai/v2/openapi.json ; https://www.pixellab.ai/image-to-pixel-art . SHA-256 da especificação lida: `b6dd212ca4e7f60c9eb93e776303a92f6e0bb4f794cf3a2bf49099e9a00e8834`. Foram examinados os campos de conversão, recuperação de escala e correção. Nenhuma chamada de geração ao serviço foi feita.
- **[S7] Derek Yu — Pixel Art Tutorial: Basics.** Exercício de sprite, forma, volume e acabamento: https://derekyu.com/makegames/pixelart.html
- **[S8] Kopf, Shamir e Peers — Content-Adaptive Image Downscaling, ACM TOG 32(6), 2013, artigo 173.** DOI: https://doi.org/10.1145/2508363.2508370 ; página de um dos autores e acesso ao artigo/pseudocódigo: https://www.cs.wm.edu/~ppeers/showPublication.php?id=Kopf:2013:CID
- **[S9] Öztireli e Gross — Perceptually Based Downscaling of Images, ACM TOG 34(4), 2015.** Página do autor e artigo: https://www.cl.cam.ac.uk/~aco41/imageDownscaling.htm
- **[S10] Zhang et al. — The Unreasonable Effectiveness of Deep Features as a Perceptual Metric, CVPR 2018.** Projeto: https://richzhang.github.io/PerceptualSimilarity/ ; artigo: https://arxiv.org/abs/1801.03924
- **[S11] Blau e Michaeli — The Perception-Distortion Tradeoff, CVPR 2018.** Artigo e versões: https://arxiv.org/abs/1711.06077
- **[C1] Código da Forja conferido.** https://github.com/henriquecoding/empire/tree/0fea413d05b35d9311801c16d4dca883feceed52/tools/forja . Pontos relevantes: `prompts.py` (paleta sugerida, perfil e dois tons), `gridcheck.py` (grade declarada pelo operador), `pipeline.py` (amostragem e acabamento), `contracts.json` (dimensões e limites), `expectation.py` (comparação entre pedido e retorno).

## Conteúdo do pacote de evidências

- Este relatório em Markdown.
- Três pranchas de diagnóstico, identificadas como comparação e teste controlado.
- Métricas completas e script de reprodução dos ensaios.
- Prancha adicional de microdetalhes, três scripts e resultados dos ensaios de amostragem/pipeline/grade.
- Contrato de fidelidade proposto e plano de implementação com critérios de aceite, identificados como especificações ainda não implementadas.
- A referência anexada e registros selecionados da execução rejeitada.
- Resumo factual dos parâmetros públicos consultados e hashes dos arquivos usados.

Os PDFs dos artigos e o texto integral da documentação externa não são redistribuídos no pacote.
