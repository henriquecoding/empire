# Empire — da pesquisa ao conceito nativo · V6

18 de outubro de 2026. Proposta de desenho para revisão. O relatório descreve os ficheiros desta entrega, sem converter decisões de ensaio em regras definitivas do jogo.

## 1. Pesquisa e referências que orientam o trabalho

Foram lidos o ponto de continuidade da outra sessão, as decisões e rejeições do autor, o estudo V5 de estrutura/luz/sombra, os capítulos da pesquisa aplicada, o diagnóstico dos experimentos e os prompts rejeitados. A pesquisa foi cruzada com `REFERENCE_AUTHORITY`, `ASSET_BIBLE`, `EXPRESSION_GUIDE`, `ANIMATION_BIBLE` e o elenco descrito no design atual.

A referência enviada nesta conversa coincide com a versão de rei/escudeiro preservada como preferência anterior. O soldado original foi aberto para comparar contorno, equipamento e humor. O imperador sombrio e a dançarina foram confrontados com a referência arquivada. Nia, bardo e fornecedor foram também conferidos nos exports existentes, cuja presença no jogo não equivale a aprovação artística.

As sete referências vegetais e a análise já arquivada orientam massas, intervalos e diversidade de crescimento. A V6 conserva essa intenção numa camada pequena, com três famílias de flores. A peça continua aberta à avaliação estética do autor.

### O que muda nesta execução

| Problema registrado | Aplicação na V6 |
| --- | --- |
| Imagens grandes a esconder resolução | A fonte dos corpos é uma grelha final de 64 ou 80; a apresentação lê esses PNGs |
| Construções geométricas anteriores sem acabamento apreciado | Silhuetas recortadas, roupas sobrepostas, dobras concentradas e rampas específicas por material |
| Nariz com mancha rosa independente | Nariz, testa e bochecha partilham a rampa de pele; o perfil dá o volume |
| Bigode ausente na careta | Camada persistente aplicada depois da boca; conferida em todos os estados |
| O mesmo emoji para todos | Largura e direção da boca dependem do rosto; atuação musical do bardo, contenção do arqueiro e medo exposto do escudeiro |
| Armadura amistosa e brilhante | Ferro escuro, visor sem olhos, ombreiras desiguais e luz restrita às faces necessárias |
| Flores como confetes | Hastes ligadas ao chão, bases de folhagem e famílias agrupadas com intervalos |
| Teste técnico tratado como aprovação | O relatório de verificação declara expressamente que não avalia qualidade artística |

Três imagens do gerador integrado ajudaram a explorar acabamento de escudeiro, rei e Nia nesta sessão. Elas são estudos visuais de resolução grande. Os PNGs entregues foram desenhados de novo por coordenadas na grelha pequena: o construtor não abre nem reduz essas imagens. Os prompts ficam em `source/ESTUDOS-DE-IMAGEM.md` para rastreabilidade.

## 2. Quadro, corpo e cabeça são orçamentos diferentes

O quadro inclui margem e equipamento. Altura útil é a caixa opaca do PNG; no intendente inclui as flechas. A caixa de cabeça inclui cabelo, elmo/coroa e, no bardo, a pena. A área de pele indicada abaixo é a caixa dos pixels de pele dentro desse recorte, não uma superfície retangular inteiramente disponível para expressão.

| Personagem | Quadro | Corpo/equipamento útil | Recorte da cabeça | Pele exposta no recorte | Cores opacas |
| --- | --- | --- | --- | --- | --- |
| Rei | 80×80 | 66×73 | 40×32 | 30×22 | 26 |
| Escudeiro | 64×64 | 47×54 | 24×27 | 13×10 | 21 |
| Nia | 64×64 | 54×56 | 25×25 | 15×13 | 24 |
| Bardo | 64×64 | 36×55 | 25×28 | 16×13 | 18 |
| Arqueiro | 80×80 | 52×67 | 24×30 | 16×18 | 19 |
| Intendente | 64×64 | 44×58 | 23×23 | 15×13 | 16 |
| Sombra | 80×80 | 66×74 | 18×31 | Elmo fechado | 8 |
| Dançarina | 64×64 | 44×52 | 25×23 | 15×14 | 17 |

Medidas extraídas de `manifest.json` e dos PNGs desta revisão. O campo de flores usa 128×24 por camada e mantém o mesmo pixel do corpo. O assento não é uma peça do cenário: a pose sentada encosta diretamente à linha de chão.

64×64 deixa espaço para nariz, olho, boca e equipamento, mas não para copiar toda a ornamentação de uma ilustração. Neste conjunto, a abertura do olho cabe num grupo de 3×3/3×4; a pupila é uma coluna de 1 px. Dentes aparecem em manchas de até duas linhas. A escolha de 80×80 para os maiores foi feita antes do desenho e não por aumentar um corpo de 64.

## 3. Silhueta, proporção e roupa por personagem

| Personagem | Construção preservada | Decisões efetivamente desenhadas |
| --- | --- | --- |
| Rei guerreiro | Barriga coberta, cabelo/costeletas, coroa torta, vinho/marfim/azul | Volume abdominal contínuo, cinto a atravessar a barriga, mangas amplas, capa presa à gola; espada baixa fora do rosto, botas separadas |
| Escudeiro | Elmo grande, escudo azul com madeira, pequena escala | Joelho dobrado, punho atrás da borda e braço a receber a carga; face de apenas 13×10 de pele, com sobrancelha limitada pela aba |
| Nia | Mulher negra adulta, caracóis, capa vinho e duas machadinhas | Cabelo em massas, pequeno aro dourado, túnica verde/marfim, pernas em prontidão e dois punhos independentes; nenhuma arma atravessa a face |
| Bardo | Chapéu, pena, bandeira, alaúde e canto | Boca vertical, mãos em posições diferentes no instrumento, corpo apoiado em duas botas e volume do alaúde à frente |
| Arqueiro | Perfil comprido, verde/azul/marfim, capuz/coroa e arco | Nariz e queixo distintos do rei, mão de transporte junto da aljava, braço de mira estendido; corda contínua entre as pontas do arco |
| Intendente | Corpo compacto, boina vinho, grande aljava e bigode | Carga diagonal, palma voltada para pagamento, moeda isolada como objeto legível; bigode em duas massas permanentes |
| Sombra | Armadura completa, visor vazio, vinho e ferro escuro | Ombreiras assimétricas, elmo estreito entre ombros largos, dedos agrupados, joelhos definidos e pose sentada sobre o chão |
| Dançarina | Coque cobre, mangas marfim, verde e fitas laranja | Apoio principal numa perna, outra fletida, mãos abertas e gesto levantado afastado do rosto; fitas em duas trajetórias |

O sombreado organiza planos antes de ornamentos. Metal recebe facetas e acentos curtos; tecido recebe massas mais largas. Couro mantém brilho discreto. Cabelo não recebe fios soltos. As oito cores do Sombra conservam leitura das placas sem um acabamento prateado espalhado.

## 4. Expressões dentro do corpo

Os sete rostos visíveis têm calma, foco, medo, golpe, ferido e vitória. A cabeça não é redesenhada com mais resolução para a prancha. Mudam apenas os grupos faciais; cabelo, elmo, coroa, nariz e bigode conservam a identidade.

| Personagem | Contraste de atuação desenhado |
| --- | --- |
| Rei | Sorriso lateral com dentes; foco fecha a boca; medo conserva dentes tensos; golpe comprime o olho; ferido deixa a pálpebra pesada |
| Escudeiro | Atenção nervosa; olho e boca ganham abertura no medo; golpe fecha o olho sob a aba; vitória revela um sorriso curto |
| Nia | Sorriso provocador; foco curto e firme; alerta com mandíbula tensa; golpe breve; ferida com pálpebra caída |
| Bardo | Boca pronta a cantar; foco aproxima o gesto vocal; surpresa interrompe o canto; ferido fecha a boca; vitória abre uma vogal maior |
| Arqueiro | Sorriso contido, queixo comprido e olho de mira; a vitória continua pequena, diferente da do rei |
| Intendente | O esforço passa por sobrancelha, pálpebra e bochecha; o bigode cobre parte da boca em todos os estados |
| Dançarina | Pequeno sorriso e reação mais contida, conservando queixo, coque e perfil |

Uma expressão parada não prova boa atuação em combate. A futura animação deve levar a mesma intenção aos ombros, cotovelos, joelhos e apoio. A V6 não apresenta o corpo neutro com outra boca como um ataque ou reação corporal concluídos.

## 5. Repouso e campo florido

Há duas poses do Sombra: em pé e sentado. O elmo continua fechado; a armadura conserva cor e identidade no repouso. O contacto do corpo/capa termina no mesmo chão dos pés, sem cadeira, pedra ou tronco.

O crescimento tem três estados estáticos: brotos baixos, botões e flores abertas. Frente e trás são independentes. Bases escuras conectam folhas; alturas variam; flores rosa, marfim e lavanda são agrupadas. Há intervalos entre os grupos e junto das botas. A máscara do corpo sentado é a mesma nas três composições.

A ordem de atuação continua a ser baixar o peso, tocar o chão, brotar e florir. Esta entrega desenha repouso e crescimento; não contém ainda os quadros intermediários de descer/levantar. Tempo de cura, persistência e efeito de gameplay não foram modificados.

## 6. Construção, edição e verificação

As formas estão descritas em polígonos, linhas e retângulos de coordenadas inteiras, organizados por camadas. Não existe uma imagem de entrada no rasterizador. A indexação associa exatamente cada RGB da paleta à sua entrada, sem quantização. A ampliação da apresentação só acontece depois de exportado o PNG pequeno.

As fontes Aseprite têm camadas de corpo, roupa, cabeça, expressão e equipamento conforme o personagem. Coroas e bigode têm camadas próprias onde necessário. Uma origem de chão acompanha cada ficheiro. Os quadros faciais são comparações estáticas, com tags individuais, não ciclos de caminhada ou ataque.

As verificações realizadas cobrem dimensão, alfa binário, margem sem corte, pés na origem, recortes do corpo, seis estados distintos, camadas persistentes e igualdade entre os PNGs e a composição dos Aseprite reabertos com o leitor independente já existente no projeto. Diagnósticos de valores/silhueta e fundos diferentes ajudam a revisão visual.

## 7. Pesquisa complementar consultada

As aplicações abaixo são decisões deste trabalho. As fontes não prescrevem 64/80, esta paleta ou o elenco do Empire.

| Fonte primária reaberta nesta sessão | Aplicação concreta |
| --- | --- |
| [Saint11 — Cluster Sketching and Painting](https://saint11.art/pixel_art_articles/article2/) | Refinar grupos contíguos; limpar escadas e reservar pixels soltos para sinais úteis |
| [Saint11 — Basic Shading](https://saint11.art/pixel_art_articles/article4/) | Separar volumes, sombra entre peças e brilho; ajustar detalhes que não cabem |
| [Saint11 — Anti-Alias and Banding](https://saint11.art/pixel_art_articles/article5/) | Conferir encontros de grupos; nesta exportação, conservar borda opaca sem halo dependente do fundo |
| [SLYNYRD — Light and Shadow](https://www.slynyrd.com/blog/2018/6/15/pixelblog-6-light-and-shadow) | Escolher uma luz principal superior esquerda para comparar materiais |
| [SLYNYRD — Knights, Monsters & Castles](https://www.slynyrd.com/blog/2025/7/28/pixelblog-57-knights-monsters-amp-castles) | Organizar anatomia e placas antes do acabamento; limitar detalhes que seriam caros de manter em movimento |
| [SLYNYRD — Plant Life](https://www.slynyrd.com/blog/2019/3/7/pixelblog-15-plant-life) | Traduzir vegetação em massas, perfis e ritmos legíveis |
| [Aseprite — especificação oficial](https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md) | Exportar camadas, cels, tags e origem sem alterar os pixels |

A bibliografia integral da sessão anterior permanece em [FONTES.md](https://github.com/henriquecoding/empire/blob/8915b8b06db97d51e1163a64910a00769b63503e/docs/art/research/2026-10-18-imperadores-escudeiros/FONTES.md). A V6 não substitui esse arquivo nem repete como novas decisões os ensaios rejeitados.

## 8. Limites e continuação

O conjunto apresenta conceitos utilizáveis para avaliação dentro da grelha pedida. A escolha artística de proporções, rosto e acabamento continua a pertencer ao autor. Os 80×80 são uma proposta desta revisão; não são uma aprovação retroativa dos 96/128 sugeridos antes.

Antes de produzir ciclos completos, convém avaliar estes corpos a 1× ao lado do soldado e nos enquadramentos reais do jogo, escolher ajustes e então desenhar as poses extremas de cada ação. O quarto imperador continua sem novo armamento definido por esta entrega. Não foi atribuída função nova à dançarina, às flores ou aos companheiros.
