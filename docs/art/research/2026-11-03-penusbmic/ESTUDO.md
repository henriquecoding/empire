# Penusbmic para a Forja - estudo ampliado

Atualização: 03/11/2026. Catálogo-base consultado em 31/10/2026.

**50 estudos, 30 transcrições integrais com licença CC verificada e 95 arquivos de legendas recuperados para pesquisa.**

Todos os 229 itens públicos do catálogo-base receberam tentativa de recuperação. Há 13 itens de membros; 0 itens públicos ainda não tentados e 134 tentativas sem recuperação. Os 50 estudos incluem 38 fontes sobre arte e 12 casos sobre desenvolvimento, mecânicas ou divulgação. Legendas musicais não foram contadas como estudos.

A coleta foi priorizada por visualizações de 31/10. Alguns contadores de página foram consultados novamente entre 02 e 03/11; isso não torna o ranking inteiro atualizado. Não houve nova auditoria visual completa nem execução no Godot.

## Recuperação e limites atuais

Dos 95 arquivos de legendas obtidos, 50 sustentam estudos, 44 contêm música ou áudio não instrucional e um é fragmentário. Há 134 itens públicos sem texto recuperado. Uma falha na exportação não prova que o vídeo não tenha legendas.

O Descript foi conectado e testado com o tutorial de Sprite Stacking. O importador rejeitou a página do YouTube por exigir um arquivo de mídia direto; a tentativa de exportar a mídia do player também falhou. Nenhum projeto ou transcrição adicional resultou desse teste. A continuação por essa via depende de um arquivo de áudio/vídeo ou de um link direto de mídia que o serviço consiga ler.

Não foram acessados conteúdos de membros, adquiridos créditos, transcritas bibliotecas pagas nem revisadas integralmente as imagens de todos os vídeos. As consultas ao ecossistema oficial estão delimitadas no fim deste documento.

## Conteúdo integral e atribuição

A pasta `transcricoes-cc` contém os textos completos recuperados das fontes cuja licença de atribuição foi confirmada individualmente. Cada arquivo identifica autor, título, fonte, licença e adaptação. São legendas no idioma original, não uma tradução integral nem uma transcrição humana revisada. As quatro lives do estudo anterior não tiveram licença CC observada; seu texto integral não foi incluído.

Documentação da licença exibida pelo YouTube: https://www.youtube.com/t/creative_commons . A documentação atual remete a https://creativecommons.org/licenses/by/4.0/ ; a descrição de cada vídeo não especifica uma versão. O registro preserva o rótulo efetivamente observado.

## Aplicação à Forja

Preservar as referências aprovadas e as grades nativas de 64/80 px. Validar poses, mão e objeto, identidade facial, apoio e recuperação antes de efeitos. Rotação ou deformação é uma etapa de construção que exige limpeza de contorno. Cenários começam por escala, massas e circulação; textura e vegetação vêm depois. Popularidade serve à ordem de estudo, não à aprovação artística.

A leitura de código anterior permanece contextualizada pela base b2b4264dd765655ba5ba2bdb697fe04fd1a45f89. Não se presume que a PR #138 aberta já faça parte da main. Nenhuma proposta deste pacote foi implementada ou testada.

## Fluxo de design de personagens

Fonte: https://www.youtube.com/watch?v=sx665YgtZVQ

Trechos de legenda estudados na etapa anterior; não equivale a revisão audiovisual integral.

Tempos consultados: 0:16, 6:43, 12:51, 24:00

**Observação:** O autor compara silhuetas e proporções antes de desenvolver cor e acabamento. Considera a dificuldade de animar o desenho e separa componentes quando a direção está escolhida. A análise visual adicional do vidIQ identifica a comparação de massas, espaços negativos e organização em camadas.

**Aplicação:** Para personagens ainda sem design aprovado, comparar alternativas de cabeça, tronco, pernas, mãos e equipamento na grade final. Para os já aceitos, usar a comparação para preservar identidade e localizar perdas.

**Limite:** O personagem flutuante simplifica este exemplo; não autoriza remover membros do elenco. A análise visual foi mediada pelo vidIQ, não uma revisão humana integral do vídeo.

## Como desenvolver personagens únicos

Fonte: https://www.youtube.com/watch?v=zRGV_9GRBTc

Trechos de legenda estudados na etapa anterior; não equivale a revisão audiovisual integral.

Tempos consultados: 1:08, 3:03, 6:43, 38:37

**Observação:** No Pixquare, o professor explora silhuetas, abandona uma solução fraca e só depois desenvolve cores e tratamento de luz. O arquivo do exemplo começa em 192×192; não é uma demonstração de produção nativa em 64×64.

**Aplicação:** Comparar a distribuição das massas dentro da família visual. No Empire, desenhar a expressão, a mão e o equipamento no orçamento nativo definido para cada personagem.

**Limite:** Transferir o método de escolha, sem reduzir automaticamente a imagem do exemplo ou importar sua iluminação como regra do jogo.

## Workflow de animação explicado

Fonte: https://www.youtube.com/watch?v=mDy2aXfOWKU

Trechos de legenda estudados na etapa anterior; não equivale a revisão audiovisual integral.

Tempos consultados: 5:22, 9:09, 10:45, 13:28

**Observação:** Componentes são separados para animar, e o ataque serve como teste da viabilidade do personagem. Poses principais precedem intermediários; tecido e acessórios recebem movimento secundário. Em um trecho, o autor admite que efeitos podem disfarçar imperfeições.

**Aplicação:** Usar uma ação exigente como prova curta antes de expandir o lote. Revisar corpo, braço, mão e arma com o efeito desligado; depois avaliar a composição completa.

**Limite:** A sugestão de encobrir imperfeições conflita com as regras da Forja quando oculta um defeito real. Deve ser explicitamente rejeitada nesses casos.

## Pixels With Pen 1 — design ao vivo

Fonte: https://www.youtube.com/watch?v=V2bAarQ2Tek

Trechos de legenda estudados na etapa anterior; não equivale a revisão audiovisual integral.

Tempos consultados: 29:29, 53:34, 54:32, 2:18:00

**Observação:** Os trechos estudados tratam de formas iniciais, capacidade de animar e coerência entre personagens. O autor distingue contextos com paleta estrita de trabalhos próprios com maior liberdade.

**Aplicação:** Separar as restrições artísticas do Empire das escolhas ocasionais do tutorial. Registrar decisões sobre forma, materiais e escala antes de solicitar variações ao gerador.

**Limite:** Foram estudados trechos da transcrição de uma transmissão extensa. A obtenção das legendas não equivale a assistir e avaliar visualmente toda a transmissão.

## Idle simples

Fonte: https://www.youtube.com/watch?v=OnrmsMm6NMk

Trechos de legenda estudados na etapa anterior; não equivale a revisão audiovisual integral.

Tempos consultados: 1:39, 4:03, 5:39, 10:26

**Observação:** O movimento de repouso organiza alturas e desloca as fases do corpo e de acessórios. O peso da espada influencia sua reação. A limpeza exige redesenhar pixels expostos, além de deslocar componentes.

**Aplicação:** Marcar o que conduz o movimento, o que acompanha e o que permanece apoiado. Comparar corpo, cabeça, bolsa e arma em seus extremos e na passagem do último para o primeiro quadro.

**Limite:** Não converter o tutorial em uma oscilação uniforme de todo o recorte. Seus tempos e quantidade de quadros não substituem o contrato do runtime.

## Corrida simples

Fonte: https://www.youtube.com/watch?v=Kgwiwbr4QS4

Trechos de legenda estudados na etapa anterior; não equivale a revisão audiovisual integral.

Tempos consultados: 0:36, 8:50, 12:02, 15:24

**Observação:** O ciclo combina variação vertical, fases diferentes para equipamento e alternância das pernas. A separação de valores ajuda a distinguir a perna próxima da distante. Contato e passagem precisam continuar legíveis.

**Aplicação:** Anotar qual pé apoia em cada fase e seguir a arma entre quadros. Revisar as oclusões do segundo meio do ciclo, sem tratá-lo como cópia indiscriminada do primeiro.

**Limite:** Oito quadros de uma demonstração não são uma prescrição universal. Manter a cadência contratada e a animação no lugar.

## Pixels With Pen 2 — idle e corrida

Fonte: https://www.youtube.com/watch?v=zSiRiuva_N4

Trechos de legenda estudados na etapa anterior; não equivale a revisão audiovisual integral.

Tempos consultados: 29:32, 1:09:00, 1:31:50, 2:16:00

**Observação:** Os trechos consultados acompanham a separação de mão e arma, a reação da bolsa e a correção de pixels que aparecem de maneira abrupta. A corrida é revisada com atenção às passagens e ao impulso do pé.

**Aplicação:** A revisão temporal deve preservar gestos intencionais e localizar defeitos em regiões específicas. Comparar apoio, contatos e hierarquia das partes antes de autorizar qualquer correção automática.

**Limite:** A Forja já diferencia movimento esperado e candidatos a cintilação; este estudo propõe ampliar as evidências de uso, não adicionar um filtro geral de estabilização.

## Ataque com transições suaves

Fonte: https://www.youtube.com/watch?v=KS837a-TFRc

Trechos de legenda estudados na etapa anterior; não equivale a revisão audiovisual integral.

Tempos consultados: 2:24, 5:23, 8:02, 14:29

**Observação:** As poses principais organizam a intenção do ataque. Pequenos intermediários e ajustes de timing ajudam a preparação, a ação e a recuperação. O retorno ao repouso é tratado como parte da animação.

**Aplicação:** Comparar o gesto com o efeito desligado e inspecionar especialmente a passagem entre a ação e a recuperação. Preservar o evento de combate e os tempos autorizados no jogo.

**Limite:** Suavidade não significa acrescentar quadros a todas as fases. Uma ação rápida pode precisar de poucos desenhos e pausas bem escolhidas.

## Ataque complexo

Fonte: https://www.youtube.com/watch?v=qODPK9kf-h4&pp=0gcJCSsMAYcqIYzv

Trechos de legenda estudados na etapa anterior; não equivale a revisão audiovisual integral.

Tempos consultados: 2:27, 25:00, 35:45, 45:54

**Observação:** A demonstração divide o gesto em preparação, salto, aterragem e outra ação. O autor corrige contatos, reconsidera uma pose e elimina uma passagem desnecessária. No final, declara que o retorno ao idle ainda falta.

**Aplicação:** Para sequências como sentar, agir e levantar, exigir entrada, passagens e saída explícitas. Conferir punho, objeto e oclusões em cada fase crítica.

**Limite:** O fim de um vídeo não prova que o asset está pronto para o jogo. Esta aula deixa uma transição por concluir; o relatório não a trata como ciclo completo.

## Ataque flamejante de chefe

Fonte: https://www.youtube.com/watch?v=r5VIb2wLww4

Trechos de legenda estudados na etapa anterior; não equivale a revisão audiovisual integral.

Tempos consultados: 5:53, 12:55, 16:32, 19:38

**Observação:** O fluxo parte das chaves, trabalha antecipação e intermediários e só depois aprofunda detalhes. A capa recebe uma reação própria, relacionada à energia do gesto.

**Aplicação:** Separar a revisão da intenção do golpe da revisão de tecido e efeitos. Comparar os extremos do corpo e da capa para verificar peso e continuidade, sem reduzir a identidade a uma silhueta genérica.

**Limite:** Exageros adequados a este chefe não devem ser aplicados automaticamente a toda a tropa.

## Animações de armas

Fonte: https://www.youtube.com/watch?v=NSOZKOLNP5w

Trechos de legenda estudados na etapa anterior; não equivale a revisão audiovisual integral.

Tempos consultados: 5:11, 8:50, 9:37, 19:11

**Observação:** O autor combina poses de disparo, ultrapassagem do repouso e acomodação. Durante rotações e recarga, volta à forma da arma e corrige o acompanhamento das mãos.

**Aplicação:** Transferir os princípios de peso, contato e persistência do objeto para espada, arco e poção. O mesmo item precisa continuar identificável durante o gesto.

**Limite:** A aula usa armas de fogo; isso não propõe novas armas ou mecânicas para o Empire. A duração exata não veio no metadado inicial do vidIQ.

## Pixels With Pen 3 — ataques ao vivo

Fonte: https://www.youtube.com/watch?v=Khc9_yU4zWc

Trechos de legenda estudados na etapa anterior; não equivale a revisão audiovisual integral.

Tempos consultados: 22:08, 39:35, 52:32, 1:15:23

**Observação:** Os trechos estudados reforçam poses-chave, antecipação, continuidade e ajuste de timing antes da limpeza fina. O professor desencoraja polir uma única chave enquanto o movimento ainda não está resolvido.

**Aplicação:** Uma rodada de revisão deve incluir a sequência inteira, mesmo em versão simples. Corrigir estrutura antes de investir em dentes, brilhos, contorno e ornamentos.

**Limite:** O estudo das legendas não valida automaticamente cada escolha anatômica mostrada na transmissão.

## Pixels With Pen 4 — saltos e deslizes

Fonte: https://www.youtube.com/watch?v=juFwyY7Mgw8&pp=0gcJCSsMAYcqIYzv

Trechos de legenda estudados na etapa anterior; não equivale a revisão audiovisual integral.

Tempos consultados: 33:01, 49:00, 50:22, 1:28:58

**Observação:** O professor diferencia o deslocamento desenhado para um filme do movimento de um sprite usado em jogo. Explica a animação no lugar e revisita a construção por poses.

**Aplicação:** Preservar origem e contatos na autoria; o deslocamento do ator continua pertencendo ao sistema do jogo. Testar a transição entre estados com os contratos existentes.

**Limite:** O exemplo não define a física, a velocidade, o evento de dano ou a máquina de estados do Empire.

## Asemulator — testar sprites dentro do Aseprite

Fonte: https://www.youtube.com/watch?v=dLvS_vtiXKQ

Trechos de legenda estudados na etapa anterior; não equivale a revisão audiovisual integral.

Tempos consultados: 3:51, 4:58, 6:51, 8:40

**Observação:** A legenda recuperada pelo navegador descreve configuração de colisão e sombra, associação de tags a estados e ensaio de ações. Uma gravação de ações acompanha alterações feitas no sprite.

**Aplicação:** A ideia útil é repetir o mesmo ensaio após uma edição para comparar seu efeito. Na Forja, manter uma prova previsível de entrada, ação e saída, com o sprite e os metadados exatos.

**Limite:** A extensão não foi instalada nem testada. Uma prévia no Aseprite não substitui a verificação no Godot, e preços ou funções mencionados na gravação não são apresentados como atuais.

## Árvores — organização de massas

Fonte: https://www.youtube.com/watch?v=vmqPX7wjgDE

Trechos de legenda estudados na etapa anterior; não equivale a revisão audiovisual integral.

Tempos consultados: 0:48, 4:21, 7:02, 12:11

**Observação:** A árvore é construída por silhueta, grupos de galhos e seleção de luz. Detalhes direcionais reforçam o tipo de copa; a neve se concentra nas superfícies superiores.

**Aplicação:** Desenvolver árvores por tronco, massa principal, aberturas e poucos grupos de material. Testar a leitura com personagens e planos do cenário antes de multiplicar variações.

**Limite:** As observações informais sobre a estação do ano não são evidência botânica. A quantidade de cores e o tamanho do exemplo não viram limites universais.

## Paisagem simples

Fonte: https://www.youtube.com/watch?v=peFLDaokmtU

Trechos de legenda estudados na etapa anterior; não equivale a revisão audiovisual integral.

Tempos consultados: 3:13, 5:37, 9:00, 13:37

**Observação:** Valores, escala aparente e distribuição de detalhe separam planos de uma composição. Figuras ajudam a comparar escala; o detalhe diminui com a distância. O resultado é uma composição vertical de wallpaper.

**Aplicação:** No Empire, compor o ritmo horizontal, preservar acessos inferiores e testar o contraste perto de rostos e armas. A dimensão visual de uma passagem deve corresponder à sua função.

**Limite:** O wallpaper não fornece colisões, regiões de navegação ou um parallax pronto para o jogo. A composição precisa ser adaptada ao espaço real do cenário.

## Tileset estilizado

Fonte: https://www.youtube.com/watch?v=F4jEt9O3F1E

Trechos de legenda estudados na etapa anterior; não equivale a revisão audiovisual integral.

Tempos consultados: 2:14, 4:41, 11:59, 19:00

**Observação:** O tileset é experimentado com um personagem durante a construção. Variações evitam repetição evidente; paredes e sombras são organizadas como partes distintas da composição.

**Aplicação:** Construir primeiro um pequeno trecho com porta, encontro de materiais e ator. Avaliar emendas e repetição antes de gerar muitas peças.

**Limite:** A projeção top-down e os tiles do exemplo não alteram a câmera lateral nem o contrato de tiles do Empire. Uma variação de iluminação também precisa de revisão antes de espelhar.

## Explosões e VFX

Fonte: https://www.youtube.com/watch?v=qcI0mVFZd_U

Trechos de legenda estudados na etapa anterior; não equivale a revisão audiovisual integral.

Tempos consultados: 0:33, 1:40, 4:55, 8:23

**Observação:** O efeito combina expansão, grupos com ritmos diferentes e elementos menores. Uma interrupção de quadro é usada de forma deliberada para intensificar o efeito.

**Aplicação:** Distinguir cintilação defeituosa de flashes intencionais. Para a floração do Sombra, a ideia de inícios defasados pode inspirar uma prova de crescimento individual, como adaptação nossa.

**Limite:** A aula demonstra explosões, não crescimento botânico. Flores precisam de estados próprios de nascimento e abertura, em vez de apenas girar uma imagem pronta.

## Cenários com Asemulator

Fonte: https://www.youtube.com/watch?v=e6eCeelgIs0

Trechos de legenda estudados na etapa anterior; não equivale a revisão audiovisual integral.

Tempos consultados: 0:48, 1:34, 5:20, 6:28

**Observação:** O cenário fica em arquivo próprio e usa slices para delimitar regiões. A demonstração encontra uma configuração ainda sem efeito naquele momento e um problema de limites fora da tela.

**Aplicação:** Tratar a montagem de cenário como uma prova de limites, camadas e escala, além de uma ilustração. Conservar a relação entre o arquivo editável e os dados exportados.

**Limite:** O estado da extensão na gravação não prova seu comportamento atual. Nenhuma compatibilidade com o Godot foi verificada nesta pesquisa.

## Três extensões de Aseprite

Fonte: https://www.youtube.com/watch?v=1M3niV7jooU

Legenda automática lida integralmente

Tempos consultados: 0:25, 2:39, 3:03, 4:54, 5:47

**Observação:** O gerador de caixas isométricas fornece geometria em camadas como guia; não substitui o desenho final. O segundo fluxo separa animações em tags e exporta folhas por ação. O terceiro cria rolagem de cenário, exigindo continuidade nas bordas e durações distintas entre planos.

**Aplicação:** Organizar exportações por ação e preservar metadados de pivô, duração e dimensões. Usar guias geométricos em estudos de cenário; revisar em tamanho nativo. Em prévias, verificar costuras e a relação entre deslocamento do ator e dos planos.

**Limite:** Os valores de 8, 12, 24 e 48 quadros pertencem ao exemplo. Recorte automático não deve alterar o contrato de 64/80 px, o ponto de apoio ou o pivô. Preço e compatibilidade atuais das extensões não foram verificados.

## Dez dicas de Aseprite

Fonte: https://www.youtube.com/watch?v=m91mtS0267c&pp=0gcJCSsMAYcqIYzv

Legenda automática lida integralmente

Tempos consultados: 0:35, 2:13, 3:08, 4:12, 5:21, 6:49, 8:14, 9:57, 11:20, 12:39

**Observação:** A aula cobre substituição seletiva de cor, seleção por faixa de cor, cels vinculados, seleção e movimento de camadas, ordem Z por cel, navegação dentro de tags, miniaturas na timeline, onion skin com cores temporais, expansão/borda de seleção e trim. Distingue duplicação temporária de cels de posterior edição independente.

**Aplicação:** Relacionar camadas a partes semânticas e separar edição compartilhada de poses independentes. Exibir anterior/atual/seguinte com cores distintas, limitar navegação à ação em revisão e revelar a ordem de sobreposição por quadro. Recoloração deve respeitar regiões autorizadas e referências aprovadas.

**Limite:** Atalhos e recursos descrevem a versão usada em 2024. Vincular a cabeça em todos os quadros não produz atuação; alterações de pose exigem desenho apropriado. Trim e mudança de cor não autorizam modificar dimensões nativas, pele, nariz, barba, dentes ou highlights aceitos.

## Ataques em visão superior

Fonte: https://www.youtube.com/watch?v=__hbXdm1HN8

Legenda automática; trechos 0–24 e 31–40 min estudados

Tempos consultados: 1:39, 4:36, 6:15, 12:31, 14:43, 17:10, 33:07, 35:32

**Observação:** O ataque começa com poses de cabeça, corpo e espada; capa e antena recebem atraso e acomodação próprios. A ordem Z muda por quadro. A conversão entre frente e costas exige redesenho e revisão das sobreposições. O arco visual é ampliado para comunicar alcance de jogo; o autor mantém esse alcance coerente entre as direções.

**Aplicação:** Revisar direção, suporte, arco da arma, alcance do efeito e recuperação em conjunto. Acrescentar prévias com VFX ligados/desligados e sobreposição de hitbox, sem confundir contato anatômico com proximidade de pixels. Capa pode atrasar legitimamente; cabeça deve atuar dentro das referências autorizadas.

**Limite:** 192×192 e 75 ms são escolhas deste exemplo, não padrões do Empire. Igualdade de volume não equivale a congelar silhueta. Um ataque não deve ser apenas espelhado para gerar outra direção. Não houve teste no Godot.

## Reação de jogador a Bullet Bunny

Fonte: https://www.youtube.com/shorts/G27HPL0OeB0

Legenda automática do Short lida integralmente; reação de jogo, não aula; imagem não verificada

Tempos consultados: 0:02, 0:14, 0:37, 0:43, 0:47

**Observação:** Uma reação selecionada pelo canal destaca companheiros invocados, melhorias dessas unidades e apreciação do estilo visual. O entusiasmo se liga a uma ação que o jogador consegue reconhecer e acompanhar.

**Aplicação:** Na prova de integração da Forja, observar se uma pessoa identifica ator, ação e efeito durante a partida, além de avaliar a imagem parada. Registrar as próprias palavras do participante e o contexto do teste.

**Limite:** Um recorte promocional não representa todos os jogadores, não mede retenção e não valida os sprites do Empire. O relato não autoriza copiar as mecânicas ou os personagens de Bullet Bunny.

## Cópia de apresentação e preservação do arquivo mestre

Fonte: https://www.youtube.com/shorts/4WsffG5KzQk

Legenda automática curta lida integralmente; imagem não verificada

Tempos consultados: 0:00, 0:07, 0:15, 0:18, 0:24

**Observação:** O autor trabalha numa cópia para apresentação, combina e duplica camadas, desloca os quadros e ajusta a opacidade. O trecho também registra que mãos foram apagadas por engano e que essa alteração não seria salva.

**Aplicação:** Gerar prévias em uma cópia ou derivação rastreável do mestre aprovado. Antes de entregar, conferir mãos, equipamento, quadros e transparência, incluindo a comparação com o mestre sem efeitos de apresentação.

**Limite:** A legenda chama o resultado de sombra, enquanto o título fala em reflexo; sem imagem não é possível validar sua geometria. Os atalhos e a duração informal do exemplo não são contratos de exportação. A proposta complementa a revisão de entrega existente.

## Vegetação por grupos de folhas e conexões

Fonte: https://www.youtube.com/shorts/UuxieFVHKIE

Legenda automática curta lida integralmente; imagem não verificada

Tempos consultados: 0:08, 0:16, 0:19, 0:25, 0:31, 0:51

**Observação:** O trecho constrói vegetação com grupos de folhas, algumas variações maiores, luz e limpeza de sobreposições. Ramos podem conectar os grupos para sugerir uma trepadeira; a distribuição depende da cena.

**Aplicação:** Organizar vegetação em massas legíveis, variar grupos e revisar junções, direção da luz e passagem dos personagens. Nas flores da Forja, preservar desenho orgânico e individualidade das referências aprovadas.

**Limite:** O bloco de 4 por 4 pixels e a repetição por cópia pertencem ao exemplo. Não definem tamanho obrigatório, densidade de vegetação nem permissão para duplicar flores mecanicamente. A legenda não permite auditar a composição visual final.

## Coerência entre arma, projétil e efeito

Fonte: https://www.youtube.com/shorts/OKmctc4MEVo

Legenda automática curta lida integralmente; apresentação de mecânica, não aula; imagem não verificada

Tempos consultados: 0:00, 0:04, 0:09, 0:13, 0:18, 0:20

**Observação:** O autor apresenta uma arma com tema de ossos, projéteis correspondentes e uma sequência de impacto, possível invocação, ataque do companheiro e término com explosão. A combinação com um personagem reforça essa proposta mecânica.

**Aplicação:** Na integração de uma ação da Forja, documentar separadamente origem do ataque, projétil, contato, efeito posterior e encerramento. Conferir se os elementos visuais ajudam a reconhecer essas etapas durante o jogo.

**Limite:** O trecho não prova legibilidade visual nem desempenho. Dano, probabilidade e duração narrados são escolhas desse jogo, sujeitos também a erro de legenda; não devem ser importados como balanceamento do Empire.

## Guias de volume para desenvolver uma cena isométrica

Fonte: https://www.youtube.com/shorts/d5pCfGXRv6I

Legenda automática curta lida integralmente; imagem não verificada

Tempos consultados: 0:00, 0:13, 0:15, 0:18, 0:26

**Observação:** O autor descreve usar formas produzidas por uma ferramenta como guias para objetos de uma cena e continuar o trabalho com cores e detalhes. O nome da ferramenta está ambíguo na legenda.

**Aplicação:** Em uma prova isométrica, separar a construção inicial do volume do acabamento autoral. Conferir perspectiva, escala e circulação com os objetos básicos antes de acrescentar material, cor e decoração.

**Limite:** Não foi verificada a imagem nem a identidade exata da ferramenta citada neste trecho. O tempo informal de execução não estabelece produtividade esperada. O procedimento não muda a perspectiva aprovada dos sprites do Empire.

## Ameaça à distância e janela de recarga

Fonte: https://www.youtube.com/shorts/xdUQVnWGn-s

Legenda automática curta lida integralmente; apresentação de mecânica, não aula; imagem não verificada

Tempos consultados: 0:00, 0:06, 0:09, 0:13, 0:18

**Observação:** O inimigo descrito avança lentamente e alterna um ataque a distância com recarga. O relato relaciona alcance, pressão sobre o movimento e risco de empurrar o jogador para uma área congestionada.

**Aplicação:** Para ações da Forja, distinguir preparação, ataque e recuperação na integração com o jogo e observar o efeito sobre a movimentação. Testar a leitura da ameaça em situações reais, inclusive quando o atacante está distante.

**Limite:** A legenda não permite confirmar que exista um aviso visual claro antes do ataque. Intervalos, vida e velocidade apresentados são escolhas de Bullet Bunny, não especificações para o Empire.

## Gravação de ações como prévia iterativa

Fonte: https://www.youtube.com/shorts/65nL1D3FZ5M

Legenda automática curta lida integralmente; imagem não verificada; licença CC observada

Tempos consultados: 0:00, 0:07, 0:12, 0:22, 0:29, 0:33

**Observação:** A demonstração grava uma sequência de ações, reproduz o resultado e mostra que mover uma camada repercute na prévia. O fluxo permite rever a sequência enquanto se ajusta o desenho.

**Aplicação:** Usar uma sequência fixa de revisão para comparar versões: movimento, ataque, recuperação e transições. Reproduzir essa mesma sequência após alterar camadas para encontrar regressões e preparar evidência consistente de aprovação.

**Limite:** Não foi verificada a execução da extensão nem sua compatibilidade atual. A prévia descrita não substitui a importação no Godot, a validação do contrato de exportação ou a revisão humana do sprite.

## Exportação de folhas separadas por tags

Fonte: https://www.youtube.com/shorts/1XMGUfL8KHU

Legenda automática curta lida integralmente; imagem não verificada

Tempos consultados: 0:00, 0:09, 0:17, 0:23, 0:28

**Observação:** A demonstração usa tags de animação para exportar ações em folhas separadas. Antes, remove elementos de apresentação e recorta a área para deixar a animação sem fundo.

**Aplicação:** Associar cada ação a uma tag explícita e conferir o conjunto exportado contra o contrato do personagem. Caso haja recorte, conservar canvas lógico, pivô e deslocamentos necessários para evitar saltos na reprodução.

**Limite:** O recorte não autoriza reduzir arbitrariamente as grades nativas de 64/80 px. A legenda não verifica durações, metadados nem compatibilidade com o Godot; esses aspectos precisam de teste próprio.

## Estado de imobilização e coerência temática

Fonte: https://www.youtube.com/shorts/fELmpziXfJU

Legenda automática curta lida integralmente; apresentação de mecânica, não aula; imagem não verificada

Tempos consultados: 0:00, 0:06, 0:11, 0:15, 0:19

**Observação:** O personagem descrito usa raízes para imobilizar inimigos em uma área e recebe um benefício ofensivo durante a habilidade. O relato associa tema, alcance e mudança temporária de estado.

**Aplicação:** Na integração de efeitos, separar visualmente o estado afetado da animação base e registrar quando começa e termina. Testar se a condição do alvo permanece legível quando vários atores estão próximos.

**Limite:** Isso não altera a exigência de humano hortão aprovada para o Empire, nem autoriza criar pessoas-planta. Área, bônus e sinergias citados são escolhas do jogo de origem, sem validação visual nesta pesquisa.

## Carga, disparo e fragmentação de projéteis

Fonte: https://www.youtube.com/shorts/MXr3yQLqjg0

Legenda automática curta lida integralmente; apresentação de mecânica, não aula; imagem não verificada

Tempos consultados: 0:01, 0:07, 0:12, 0:16, 0:24

**Observação:** A arma apresentada acumula carga enquanto o comando é mantido; o impacto produz projéteis menores que ricocheteiam. O relato diferencia um disparo rápido de um disparo com maior preparação.

**Aplicação:** Ao revisar uma ação com carga, distinguir os estados de preparação, liberação, contato e efeitos posteriores. Conferir a leitura do personagem com os efeitos ligados e desligados, sobretudo em cenas densas.

**Limite:** A legenda não comprova que a intensidade visual comunique corretamente a carga. A mecânica descrita não é uma proposta de arma nova para o Empire; serve como caso para revisar estados e causalidade.

## Apresentação curta das funções de Örnöga

Fonte: https://www.youtube.com/shorts/s3_CTlR6rIs

Legenda automática curta lida integralmente; apresentação promocional, não aula; imagem não verificada; licença CC observada

Tempos consultados: 0:00, 0:05, 0:09, 0:11, 0:20

**Observação:** O autor apresenta o jogo por funções reconhecíveis: magias de diferentes elementos, coleta de equipamentos e contratação de companheiros. O trecho combina uma descrição curta com convite para acompanhar o projeto.

**Aplicação:** Ao apresentar uma prova da Forja, mostrar o que o personagem faz no jogo e quais estados foram validados. Uma demonstração curta deve apontar ações concretas, acompanhada de evidência da versão revisada.

**Limite:** O trecho é promocional e não contém medição de resultados de marketing. Não comprova desempenho, qualidade artística ou eficácia comercial de nenhuma proposta para o Empire.

## Veneno e transformação de elementos da cena em efeito

Fonte: https://www.youtube.com/shorts/6KffTZ6MMGk

Legenda automática curta lida integralmente; apresentação de mecânica, não aula; imagem não verificada

Tempos consultados: 0:00, 0:04, 0:08, 0:11, 0:17

**Observação:** O personagem é apresentado por uma especialidade em veneno e por uma habilidade que transforma objetos de experiência próximos em nuvens tóxicas. O resultado depende dos elementos que já estão distribuídos na cena.

**Aplicação:** Ao revisar efeitos acionados sobre objetos da cena, registrar quais objetos participam, como se transformam e quando o efeito termina. Verificar se o personagem e as áreas relevantes permanecem distinguíveis durante a sequência.

**Limite:** O raio citado é uma escolha do jogo de origem, não uma dimensão ou limite para sprites do Empire. Sem imagem e execução não há validação da legibilidade dessas nuvens nem de sua interação com os alvos.

## Magias automáticas e modificadores de equipamento

Fonte: https://www.youtube.com/shorts/rVUAfPdC6Ig

Legenda automática curta lida integralmente; apresentação de mecânica, não aula; imagem não verificada

Tempos consultados: 0:05, 0:10, 0:15, 0:18, 0:21

**Observação:** O autor descreve magias de elementos diferentes, lançamento automático com consumo de recurso e equipamentos que alteram o comportamento de uma magia, como o número de projéteis.

**Aplicação:** Em provas com variantes de efeito, manter explícitos a ação base e seus modificadores. Testar combinações relevantes na cena para verificar leitura de alvos, origens e continuidade da animação.

**Limite:** O vídeo não estabelece os sistemas ou o balanceamento do Empire. A transcrição não comprova clareza visual quando várias magias são usadas ao mesmo tempo.

## Identidade mecânica e teste de uma hipótese de personagem

Fonte: https://www.youtube.com/shorts/cisSo8Ah30Y

Legenda automática curta lida integralmente; apresentação de mecânica, não aula; imagem não verificada

Tempos consultados: 0:00, 0:04, 0:09, 0:19, 0:23

**Observação:** O personagem apresentado combina menor velocidade, maior capacidade de munição e uma habilidade ligada a essa capacidade. O autor relata dúvida inicial e satisfação após experimentar combinações.

**Aplicação:** Ao desenvolver um personagem novo, testar uma hipótese curta de função e animação dentro do jogo antes de ampliar o conjunto de ações. Registrar a experiência que sustenta manter ou rever a proposta.

**Limite:** O depoimento é uma avaliação do próprio autor, sem amostra de testes. Munição, velocidade e dano citados não se tornam atributos ou limites para personagens da Forja.

## Colisão e sombra configuradas na prévia do Aseprite

Fonte: https://www.youtube.com/shorts/8VZVFGJIrSs

Legenda automática curta lida integralmente; imagem não verificada; licença CC observada

Tempos consultados: 0:03, 0:13, 0:24, 0:32, 0:46, 1:00

**Observação:** O autor oculta camadas auxiliares, exibe a caixa de colisão e a define a partir de uma seleção. Depois ajusta a sombra separadamente, revendo largura e altura da seleção para sua aparência na prévia.

**Aplicação:** Separar arte do personagem, volume de colisão e sombra. Registrar pivô e apoio, testar diferenças de terreno e repetir a conferência na implementação real do jogo. A seleção visual serve como entrada inicial, não como validação automática.

**Limite:** A demonstração de uma extensão não verifica colisões do Godot. O pequeno salto referido na fala não comprova uma animação de salto criada. Sem imagem, não se pode reproduzir a caixa ou a sombra exata mostrada.

## Companheiros, posicionamento e efeitos adicionais

Fonte: https://www.youtube.com/shorts/TLufZMxoxaY

Legenda automática curta lida integralmente; apresentação de mecânica, não aula; imagem não verificada

Tempos consultados: 0:00, 0:04, 0:09, 0:15, 0:20, 0:30

**Observação:** O trecho apresenta companheiros reposicionáveis, progressão de habilidades e equipamentos que acrescentam outro efeito a uma ação. O exemplo associa uma cura a projéteis adicionais.

**Aplicação:** Nos testes de integração, verificar a ação base com e sem efeitos adicionais e em posições diferentes. Conferir se o efeito extra preserva a identificação do ator, a leitura da ação original e a continuidade dos objetos.

**Limite:** A fala não valida o resultado visual ou o balanceamento. O exemplo não autoriza mudar a função de classes do Empire nem acrescentar essas mecânicas ao projeto.

## Variação de detalhes sem perder a leitura do tileset

Fonte: https://www.youtube.com/shorts/5P4EVDuBzfI

Legenda automática curta lida integralmente; imagem não verificada; licença CC observada

Tempos consultados: 0:00, 0:04, 0:17, 0:30, 0:44, 0:53

**Observação:** O autor reduz a repetição percebida com rachaduras e pequenas cavidades, compara valores e varia os detalhes. Luz numa borda e sombra interna sugerem profundidade; o trecho alerta para não exagerar na quantidade.

**Aplicação:** Começar pela estrutura funcional do cenário e adicionar variação localizada onde a repetição prejudica a leitura. Conferir luz, profundidade e hierarquia em escala de jogo, mantendo as áreas de circulação claras.

**Limite:** A fala não define uma densidade numérica de detalhe nem um limite universal de cores. Sem inspeção visual, não há comprovação das junções do tileset ou de sua integração no Empire.

## Ataques com glitch

Fonte: https://www.youtube.com/watch?v=9rU5a_MM-ek

Legenda automática lida integralmente

Tempos consultados: 1:20, 3:18, 4:09, 6:31, 7:05, 9:29, 13:14, 16:25

**Observação:** O efeito parte de agachamento legível e silhueta duplicada em camada separada. Faixas horizontais são deslocadas em sentidos alternados; poucos resíduos desaparecem rapidamente. Os dois cortes são desenhados com variação, limpos após rotação e alinhados à espada da sombra. A varredura termina em recuperação para a pose inicial.

**Aplicação:** Separar o ator íntegro do efeito de desintegração. Marcar região e intervalo autorizados de glitch para que revisores temporais não confundam desaparecimento intencional com corrupção do sprite. Inspecionar contornos após qualquer transformação geométrica e alinhar arco, arma, pose e evento de impacto.

**Limite:** 65 ms é duração de quadro, não 65 FPS. O reflexo final com baixa opacidade é apresentação, não parte obrigatória do asset. O autor informa que o final da gravação falhou e recapitula as operações.

## Primeiro mês de Bullet Bunny

Fonte: https://www.youtube.com/watch?v=LVL7z2q5wWM

Legenda automática; primeiros 12 min estudados

Tempos consultados: 1:02, 3:13, 5:32, 6:41, 8:39, 9:00, 10:45

**Observação:** O autor relata diferença entre alcance em redes, listas de desejos e compras. Descreve a concentração de vendas no começo do lançamento, a frustração com previsões e críticas de jogadores à interface e progressão.

**Aplicação:** Na avaliação da Forja, manter popularidade como ordem de estudo, não como prova de qualidade artística ou de valor para jogadores. Para o Empire, testar legibilidade e função no jogo; uma animação atraente nas redes não demonstra sozinha boa experiência de combate.

**Limite:** Relato pessoal de abril de 2024, não uma previsão para o Empire. Há números ambíguos nas legendas automáticas; não foram convertidos em projeções de receita, taxas normativas ou regras do algoritmo Steam.

## Dicas e truques de Aseprite

Fonte: https://www.youtube.com/watch?v=PB6R95Q_4Xs

Legenda automática lida integralmente; tema já presente na pesquisa histórica de outubro

Tempos consultados: 0:21, 0:47, 1:27, 2:14, 3:47, 4:48, 6:28, 7:43, 8:53, 10:00

**Observação:** A aula combina coleta de cores, extensão de cels, janelas lado a lado, slices nomeadas, cores de organização, onion skin à frente ou atrás, transformação da seleção, rampas de sombreamento, estabilizador de traço e repetição do canvas. O modo tiled permite desenhar e conferir as emendas do parallax enquanto se trabalha.

**Aplicação:** Manter referência aprovada ao lado do sprite nativo; usar nomes e cores para ação, parte e revisão. Exportar regiões nomeadas junto com pivôs e metadados. Conferir emendas por camada de cenário e manter rampas por material, sem escurecer globalmente pele e detalhes faciais.

**Limite:** Não é conhecimento inteiramente novo no repositório; a contribuição desta rodada é recuperar a fonte completa e conectar os mecanismos aos critérios atuais. Estabilizador de entrada não corrige automaticamente clusters ou pixels duplos já existentes. Deformações geométricas exigem redesenho e revisão.

## Ataques em 10 segundos, 10 minutos, uma hora e dez horas

Fonte: https://www.youtube.com/watch?v=XbQ4RmritTY&pp=0gcJCSsMAYcqIYzv

Legenda automática lida integralmente

Tempos consultados: 0:59, 2:07, 3:50, 4:02, 5:23, 6:09, 7:02

**Observação:** O desafio evidencia custos de improvisar camadas, escolher uma arma difícil e começar detalhes cedo. Na versão longa, o autor reserva tempo para design, poses principais, movimento e só então efeitos; revisa também intermediários.

**Aplicação:** Estabelecer etapas verificáveis para conceito, poses, apoio, intermediários e acabamento. A Forja deve permitir voltar à pose ou ao desenho da arma sem reconstruir todos os efeitos. Avaliar corpo e equipamento antes de adicionar partículas.

**Limite:** É uma comparação artística informal, com personagens e complexidades diferentes. Não mede produtividade controlada nem determina um orçamento obrigatório de dez horas.

## Abrigo isométrico de ficção científica

Fonte: https://www.youtube.com/watch?v=l-GrnsUKlsg

Legenda automática; trechos 0–8, 14–19 e 25–27 min estudados

Tempos consultados: 0:29, 3:06, 6:34, 15:12, 16:24, 25:38, 26:29

**Observação:** O autor organiza a construção em volumes, cores-base, blocos menores e detalhes. Mantém um personagem na cena como referência de escala. Porta, cabos, sombras e vegetação são construídos sobre a estrutura; sobreposições de vegetação e sombra são corrigidas.

**Aplicação:** Para cenários do Empire, começar com massas, circulação e escala do ator antes de musgo, fungos e adornos. Reservar entrada e faixa inferior funcional. Identidade de material deve aparecer em formas e agrupamentos legíveis, não em ruído uniforme.

**Limite:** A perspectiva isométrica e o canvas 192×192 do exemplo não substituem a câmera nem a grade do Empire. A densidade de cabos e peças técnicas não é um modelo literal para um reino do bosque. Sombras por blend precisam de revisão de cor e contraste no resultado final.

## Loop Draw, Grassify e Record

Fonte: https://www.youtube.com/watch?v=mfUnB-yq53w

Legenda automática lida integralmente

Tempos consultados: 0:34, 2:14, 2:57, 3:48, 4:47, 5:14, 6:10, 7:11

**Observação:** Loop Draw desenha enquanto os quadros passam, com controle do momento de entrada do traço. Duas camadas permitem sugerir energia à frente e atrás do braço. Grassify aplica variação de comprimento em uma seleção; o autor reduz a uniformidade e prevê limpeza. Record registra estados de desenho para formar um timelapse.

**Aplicação:** Usar geração procedural em regiões autorizadas e revisar o resultado. Para o bosque, variar agrupamentos e comprimentos sem espalhar detalhe por toda a cena. Registrar etapas de criação pode ajudar a localizar quando a identidade ou a forma do equipamento se perdeu.

**Limite:** Os percentuais de cobertura são parâmetros demonstrativos de um script, não critérios de ocupação dos sprites da Forja. Ruído aleatório não cria composição nem crescimento orgânico de flores. Os preços citados no vídeo de 2024 não foram verificados para hoje.

## Conservação de volume em uma edição

Fonte: https://www.youtube.com/shorts/PzlWnrpb6Lo

Legenda automática curta lida integralmente; imagem não verificada

Tempos consultados: 0:00, 0:15

**Observação:** O trecho orienta a compensar as partes removidas ao ajustar uma forma, preservando a percepção de volume.

**Aplicação:** Ao deslocar ou redesenhar uma parte, comparar sua massa aparente e sua relação com as partes vizinhas. Usar a referência aprovada como guia.

**Limite:** O texto isolado não mostra qual parte está sendo editada. Não transforma igualdade de contagem de pixels em aprovação automática nem proíbe squash, perspectiva ou oclusão.

## Porta isométrica a partir de uma forma plana

Fonte: https://www.youtube.com/shorts/OKQTKgNiMQI

Legenda automática curta lida integralmente; imagem não verificada

Tempos consultados: 0:00, 0:13, 0:17, 0:24

**Observação:** O trecho descreve deslocar grupos de linhas para obter a inclinação 2:1. Uma cópia deslocada e recolorida dá espessura à porta antes dos detalhes.

**Aplicação:** Em estudos isométricos, conservar a cadência das diagonais e separar face, espessura e iluminação. A transformação deve ser conferida na grade, com correção manual das junções.

**Limite:** Não é uma instrução para inclinar automaticamente sprites laterais do Empire. A imagem não foi verificada; o texto não basta para validar a geometria exata demonstrada.

## Örnöga em 100 horas

Fonte: https://www.youtube.com/watch?v=-eTPhlUlcm4

Legenda automática lida integralmente

Tempos consultados: 0:47, 1:08, 1:57, 3:18, 4:02, 4:35, 6:22

**Observação:** O desenvolvimento parte de movimento, inimigos e progressão, passa por magias e inventário e recebe testes antes do polimento final de áudio e animação. O relato mostra redução de escopo e correções orientadas por jogadores.

**Aplicação:** Criar uma prova pequena da Forja dentro do jogo: importar personagem, tocar ações, verificar equipamento e eventos, testar transições e só então ampliar o lote. Manter arte provisória identificada e substituir sem perder o contrato de integração.

**Limite:** O desafio não estabelece prazo realista universal. O relatório não transforma a implementação de um jogo incremental em modelo mecânico para o Empire, nem considera o relato uma validação da Forja.

## Pintura restrita ao alfa existente no Aseprite

Fonte: https://www.youtube.com/shorts/mCM6gACqtkM

Legenda automática curta lida integralmente; imagem não verificada

Tempos consultados: 0:04, 0:06, 0:11, 0:18

**Observação:** O autor ativa Lock Alpha na camada selecionada para pintar apenas nas áreas já ocupadas, sem ultrapassar a silhueta dessa camada.

**Aplicação:** Usar a restrição de alfa em ajustes de cor e sombra que devem conservar o contorno aprovado. Na Forja, separar a proteção da silhueta da proteção semântica de olhos, dentes e outros detalhes internos.

**Limite:** Bloquear o alfa não protege cores ou identidade dentro da silhueta e não substitui a validação facial existente. A legenda não documenta atalhos universais nem comprova o resultado visual.

## Opacidade e limpeza seletiva de uma camada

Fonte: https://www.youtube.com/shorts/UEtnPs52cFI

Legenda automática curta lida integralmente; imagem não verificada

Tempos consultados: 0:00, 0:04, 0:16, 0:28

**Observação:** O autor reduz a opacidade de uma camada, compara intensidades e apaga manualmente áreas que parecem excessivas. A legenda não identifica com segurança o material ou o efeito representado.

**Aplicação:** Ao ajustar uma camada de acabamento, comparar o resultado sobre o sprite aprovado e remover intervenções que reduzam a leitura. Registrar a intensidade escolhida por caso, preservando os detalhes internos importantes.

**Limite:** Os percentuais falados pertencem à demonstração, não constituem limites globais de opacidade, ocupação ou preenchimento. A ausência de imagem impede determinar exatamente quais áreas deveriam ser apagadas.

## Propostas de engenharia - inferências para avaliação

### P0-01 - Revisão de mãos e objetos ao longo da ação

Um objeto pode manter a forma e ainda estar mal segurado em um intermediário.

Associar as observações existentes a ação, quadro, mão, objeto, orientação e oclusor. Marcar contato, visibilidade e trajetória nas passagens críticas. Integrar à revisão por quadro da PR #138 se ela for incorporada.

**Aceitação:** Na prova dos dois alquimistas, conservar o mesmo tamanho absoluto da poção e distinguir pega válida, mão solta, braço ausente e objeto oculto. Ausência de evidência produz pendência, não aprovação.

**Fontes:** https://www.youtube.com/watch?v=qODPK9kf-h4, https://www.youtube.com/watch?v=NSOZKOLNP5w, https://www.youtube.com/watch?v=4WsffG5KzQk

**Estado:** Proposta; nenhum código ou sprite alterado nesta pesquisa.

### P0-02 - Identidade facial por pose e estado

Uma única cabeça congelada não cobre rotação, esforço, dano e oclusão; movimento livre também pode destruir identidade.

Complementar as fichas semânticas atuais com estados autorizados e referências por orientação, quando disponíveis. Conservar a assimetria e relações das feições; explicitar quando não há observação suficiente.

**Aceitação:** Comparar repouso, esforço e dano sem perder barba, bigode, nariz e expressão característica. Olho fechado ou boca diferente só passam quando pertencem a um estado admitido e visualmente revisado.

**Fontes:** https://www.youtube.com/watch?v=sx665YgtZVQ, https://www.youtube.com/watch?v=mCM6gACqtkM

**Estado:** Proposta; as fichas de feições já existem em main.

### P0-03 - Evidência de apoio, fases e recuperação

Uma lista de chaves ou um ciclo sem cintilação não comprova apoio, peso e saída do gesto.

Acrescentar à prova de animação o apoio por fase, as partes condutoras e secundárias, as passagens de oclusão e a ligação com o repouso. Revisar corpo sem VFX e composição final.

**Aceitação:** A ação mantém origem e contratos de tempo; cada mudança de apoio é explicável; não há perda de membro ou arma. Recuperação e loop são vistos, e os efeitos não escondem defeitos conhecidos.

**Fontes:** https://www.youtube.com/watch?v=OnrmsMm6NMk, https://www.youtube.com/watch?v=Kgwiwbr4QS4, https://www.youtube.com/watch?v=KS837a-TFRc, https://www.youtube.com/watch?v=mDy2aXfOWKU

**Estado:** Proposta; não ampliar quadros ou alterar janelas de combate automaticamente.

### P1-01 - Variação controlada de personagens novos

Variações geradas podem repetir o mesmo rosto e corpo ou abandonar uma autoridade já aprovada.

Para designs em aberto, comparar alternativas na escala nativa usando eixos explícitos de silhueta, proporção, feições e função. Para designs aprovados, restringir a tarefa a preservar e reparar.

**Aceitação:** A prancha mostra diferenças legíveis a 1× e registra por que uma alternativa atende à função. Nenhum candidato rejeitado vira nova referência por conveniência.

**Fontes:** https://www.youtube.com/watch?v=sx665YgtZVQ, https://www.youtube.com/watch?v=zRGV_9GRBTc

**Estado:** Proposta de processo; sem definir um número obrigatório de alternativas.

### P1-02 - Prova de cenário antes de expansão

Um cenário bonito isolado pode falhar em escala, circulação, repetição e contraste com o elenco.

Usar um trecho pequeno com ator, porta ou margem, acesso inferior, três planos e encontro de materiais. Conferir dia/noite e emendas antes do lote.

**Aceitação:** A leitura do ator permanece; a porta corresponde ao corpo; a faixa inferior funciona; troncos, copas e materiais têm grupos deliberados. Não há ruído uniforme para simular riqueza.

**Fontes:** https://www.youtube.com/watch?v=l-GrnsUKlsg, https://www.youtube.com/watch?v=UuxieFVHKIE, https://www.youtube.com/watch?v=5P4EVDuBzfI

**Estado:** Proposta de prova visual; não houve auditoria completa de todos estes módulos.

### P1-03 - Ensaio repetível da peça editada

Comparar duas exportações sem repetir a mesma ação dificulta localizar regressões visuais.

Guardar uma sequência curta de revisão com entradas, estados e câmera definidos. Repeti-la após uma edição, ligando a evidência ao hash da imagem e aos metadados exatos.

**Aceitação:** Antes/depois têm a mesma escala e ação; PNG, JSON e fonte Aseprite correspondem; o teste no Godot é identificado separadamente da prévia de autoria.

**Fontes:** https://www.youtube.com/watch?v=dLvS_vtiXKQ, https://www.youtube.com/watch?v=65nL1D3FZ5M, https://www.youtube.com/watch?v=8VZVFGJIrSs

**Estado:** Proposta; Asemulator é referência de processo, não nova dependência.

### R2-01 - Contrato de exportação por ação

Exportar tags e aplicar trim pode gerar arquivos corretos isoladamente, mas desalinhados quando o jogo troca de ação.

Proposta: acompanhar cada ação por uma lista ordenada de quadros com duração em milissegundos, tamanho nativo, pivô e ponto de apoio. Recorte de armazenamento, se utilizado, deve preservar offsets e permitir reconstrução exata no canvas contratado.

**Aceitação:** Na mesma prévia, alternar idle, run, ataque e retorno sem salto de pivô. Conferir dimensões de 64/80 px antes e depois de exportar/importar. Um efeito que ultrapasse o corpo não deve provocar escala diferente do personagem.

**Fontes:** https://www.youtube.com/watch?v=1M3niV7jooU, https://www.youtube.com/watch?v=m91mtS0267c, https://www.youtube.com/watch?v=PB6R95Q_4Xs

**Estado:** Inferência de engenharia a partir das aulas; não implementada. Conferir exportador atual antes de adicionar comportamento duplicado.

### R2-02 - Revisão de efeitos intencionais por região e intervalo

Glitch, resíduos de corte e partículas podem parecer corrupção temporal se avaliados sem a fase da ação; os mesmos efeitos podem esconder uma arma mal posicionada.

Proposta: vincular o efeito a uma região e intervalo autorizados; preservar uma prévia do ator sem efeitos e outra com efeitos. Usar os classificadores temporais existentes como apoio, mantendo falhas de mão, rosto e equipamento visíveis na revisão.

**Aceitação:** Um glitch autorizado não deve ser apagado por estabilização automática. Fora da região e intervalo, alterações continuam exigindo explicação. Arma, arco, oclusão e retorno devem permanecer verificáveis com o efeito desligado.

**Fontes:** https://www.youtube.com/watch?v=9rU5a_MM-ek, https://www.youtube.com/watch?v=__hbXdm1HN8, https://www.youtube.com/watch?v=XbQ4RmritTY

**Estado:** Ampliação proposta da evidência semântica; não afirma que temporal.py carece das proteções já existentes.

### R2-03 - Prova de cenário por massas, escala e circulação

Detalhes de vegetação ou materiais podem aumentar a densidade sem melhorar identidade, legibilidade e função do cenário.

Proposta: revisar primeiro volumes e caminho com um ator aprovado na escala final; depois materiais e agrupamentos característicos do bioma. Aplicações procedurais devem ficar em regiões escolhidas e passar por limpeza e revisão de sobreposição.

**Aceitação:** No bosque, musgo, fungos e cogumelos devem construir identidade por formas e agrupamentos reconhecíveis. A faixa inferior funcional e os acessos continuam legíveis. Comparar a cena no enquadramento de jogo, sem estabelecer um percentual universal de ocupação.

**Fontes:** https://www.youtube.com/watch?v=l-GrnsUKlsg, https://www.youtube.com/watch?v=mfUnB-yq53w, https://www.youtube.com/watch?v=PB6R95Q_4Xs

**Estado:** Prova artística proposta, não cenário aprovado nem alteração de câmera para isometria.

## Ecossistema oficial - alcance da consulta

- [Itch.io — catálogo oficial](https://penusbmic.itch.io/): Página pública consultada. Séries DARK, STRANDED, TINY THRONES e coleções anuais de tutoriais. Não foram baixados todos os pacotes.
- [Patreon](https://www.patreon.com/cw/penusbmic): Apresentação pública consultada. Posts e arquivos exclusivos não foram estudados.
- [Tutorial de paletas](https://penusbmic.itch.io/pixel-art-tutorial-designing-palettes): Descrição pública consultada; conteúdo pago não acessado.
- [Ciclo de quadrúpede pesado](https://penusbmic.itch.io/pixel-art-tutorial-heavy-4-legged-walk-cycle): Descrição pública consultada. É uma referência futura para animais, não prova de biomecânica já estudada.
- [Composição com arbustos e rochas](https://penusbmic.itch.io/pixel-art-tutorial-building-a-statement-scene-bushes-rocks): Descrição pública consultada. Pode orientar a próxima etapa de cenários; a aula completa não foi acessada.
- [TINY THRONES](https://penusbmic.itch.io/tiny-thrones-series): Página pública consultada. É material colaborativo; não atribuir todas as unidades e componentes exclusivamente ao Penusbmic.
- [Cidade élfica](https://penusbmic.itch.io/tiny-thrones-series-ancient-elvish-city): Página pública consultada; sem inspeção dos arquivos editáveis compráveis.
- [Fundos TINY THRONES](https://penusbmic.itch.io/tiny-thrones-series-arallax-bg-pack): Página pública consultada; observar a separação entre o que o pacote inclui e o que aparece apenas na demonstração.
- [Animação completa de inimigo](https://penusbmic.itch.io/pixel-art-tutorial-complete-enemy-animation): Descrição pública consultada. A versão pública resumida não equivale à compra ou leitura integral do tutorial.
- [Comunidade Aseprite — sombreamento](https://community.aseprite.org/t/script-more-color-shading-options/3668): Post público consultado; o script não foi instalado nem validado nesta tarefa.