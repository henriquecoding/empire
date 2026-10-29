**Forja — auditoria e pesquisa para cenários e construções**
28 de outubro de 2026 · Empire · base analisada: `91d3521ea99a520248bc1e48c5e72f39fa8dd44a`

**A próxima evolução deve tornar a Forja capaz de provar que uma peça funciona na composição do jogo.** O FORJA-11 acrescentou fundamentos importantes; o maior retorno agora está em corrigir verificações permissivas, transportar as referências efetivamente para o gerador, ligar a arte à pegada funcional e rever o resultado no Godot. A investigação abaixo identifica o que já existe, reproduz falhas e propõe uma ordem de execução.

Analisei o [PR #131](https://github.com/henriquecoding/empire/pull/131), o [ADR 0098](https://github.com/henriquecoding/empire/blob/91d3521ea99a520248bc1e48c5e72f39fa8dd44a/docs/adr/0098-a-forja-desenha-cenarios-pela-regua-dos-atores.md), o contrato de agente, os guias de pixel art e Aseprite, o relatório e piloto recentes, os módulos de cena da Forja e os pontos de integração visual do jogo. Consultei documentação pública de PixelLab, Gemini, Godot 4.7, Aseprite, Tiled, LDtk e material do autor SLYNYRD. As propostas deste relatório são recomendações; não alteram as decisões artísticas do projeto.

A verificação local foi feita sobre uma cópia seletiva do commit. Os **44 testes** de `test_cenarios`, `test_cenarios_revisao` e `test_estrutura` passaram. Seis sondas adicionais reproduziram os resultados da tabela abaixo; a medição da altura revelou também um erro de uma unidade. Não executei a suíte completa do Godot, o jogo no navegador ou gerações pagas nesta auditoria.

| Evidência | Estado verificado |
|---|---|
| Alteração recente do Claude | FORJA-11, PR #131, integrado na main |
| CI desse commit | [Execução concluída com sucesso](https://github.com/henriquecoding/empire/actions/runs/40764218311) |
| Vercel | Deployment de produção `dpl_AJMJ6pyzbKgaRMHUrd34Um6U3wDh`, READY, associado ao mesmo SHA |
| Endereço de produção | [Empire](https://empire-phi-eight.vercel.app/) |
| Entrega de cenários | [Backlog marcado como parcial](https://github.com/henriquecoding/empire/blob/91d3521ea99a520248bc1e48c5e72f39fa8dd44a/docs/backlog/FORJA-11.md): geração do piloto, integrações de ambiente e aprovação pendentes |

O estado READY prova a conclusão do deployment. A validação artística e funcional do novo piloto exige outras evidências.

**O trabalho recente merece ser preservado.** A régua lê os atores reais; a extensão deixou de ser uma tela de personagem por omissão; o prompt distingue elevação lateral e orientação do ator; referências têm papéis; os estados têm zonas autorizadas; e a revisão separa raster, estrutura, identidade, continuidade e integração. Também já existem verificações Wang de pares e cruzamentos, controlo de jobs e proteção da imagem aprovada. Reconstruir estes mecanismos atrasaria o trabalho.

A escala medida no commit confirma o ponto essencial:

| Grandeza | Valor atual | Consequência |
|---|---:|---|
| Janela do jogo | 1280 × 720 | Preservar a resolução interna contratada |
| Rei: tela / corpo visível | 80 × 80 / 65 px de altura | Medir arquitetura pelo corpo, sem confundir tela e altura |
| Nia: tela / corpo visível | 64 × 64 / 50 px de altura | Conferir também a leitura do ator mais baixo |
| Célula de cenário / personagem | 2 px / 1 px | Conservar a distinção intencional de densidade |
| Superfície | fila 517; aresta inferior 518 | A base assenta na fase par da arte existente |
| Nível inferior | 618,5 | A apresentação ainda precisa de uma solução validada |
| Pegada funcional da forja | 120 px | A arquitetura deve caber no espaço definido pela simulação |

Porta comum de 72–80 px, porta pública de 88–104 px e largura de porta de 30–40 px são **propostas parametrizadas**, ainda associadas à Q-295. A Forja já usa alguns desses mínimos como barreira. Convém tornar explícita a diferença entre um perfil experimental e uma regra aprovada, para uma hipótese de pesquisa não se transformar silenciosamente em obrigação.

**Os verificadores deixam passar contraexemplos importantes.** Os resultados a seguir pertencem aos verificadores específicos; não significam que estas imagens sintéticas receberam aprovação artística ou que passaram por todos os critérios de raster.

| ID | Achado reproduzido | Resultado atual | Ajuste recomendado |
|---|---|---|---|
| A1 | Contrato e imagem com porta de apenas 2 px de largura | Validação sem erros; `opening:porta = pass` pela altura | Validar largura declarada e largura livre medida, além da altura |
| A2 | Edifício suspenso 8 px; bloco separado de 2 × 2 px toca no fundo | `base_contact = pass`, com só 2 colunas em contacto | Exigir ligação dos apoios à estrutura principal |
| A3 | Duas faixas totalmente opacas, uma clara e outra escura | `joint.ok = true`, salto 0 | Separar continuidade de alfa, cor, textura e material |
| A4 | Imagem `damaged` idêntica à `done` | Estado recebe `pass` | Conferir alteração esperada dentro da zona, além da preservação fora dela |
| A5 | Cena PixelLab com referência `asset_concept` | Referência registada, `attachments = []`, sem erros | Enviar para uma entrada compatível ou recusar a exigência não suportada |
| A6 | Contrato com `states: []` | Validação aceita; revisão termina em `IndexError` | Rejeitar coleção vazia ou resolver uma base canónica antes de rever |
| A7 | Vão com 84 linhas reais | Altura reportada como 85 | Corrigir a convenção de limite exclusivo de `bbox` |

A1 e A5 são prioridades imediatas: afetam diretamente a utilidade da peça e a fidelidade à referência. A2, A6 e A7 são correções locais de robustez. A3 e A4 expõem limites do significado atual de “pass”: os verificadores demonstram apenas um subconjunto da qualidade pretendida.

Os pontos de código são [aberturas e medidas](https://github.com/henriquecoding/empire/blob/91d3521ea99a520248bc1e48c5e72f39fa8dd44a/tools/forja/estrutura.py#L80), [apoio na base](https://github.com/henriquecoding/empire/blob/91d3521ea99a520248bc1e48c5e72f39fa8dd44a/tools/forja/estrutura.py#L37), [junções](https://github.com/henriquecoding/empire/blob/91d3521ea99a520248bc1e48c5e72f39fa8dd44a/tools/forja/estrutura.py#L145), [estados](https://github.com/henriquecoding/empire/blob/91d3521ea99a520248bc1e48c5e72f39fa8dd44a/tools/forja/estrutura.py#L172), [planeamento PixelLab](https://github.com/henriquecoding/empire/blob/91d3521ea99a520248bc1e48c5e72f39fa8dd44a/tools/forja/scene_plan.py#L122) e [validação do contrato](https://github.com/henriquecoding/empire/blob/91d3521ea99a520248bc1e48c5e72f39fa8dd44a/tools/forja/scene.py#L104).

Em A5, `make()` recolhe as referências, mas chama `_pixellab()` sem as passar. Essa função pode anexar uma imagem de paleta, porém não o conceito nem a régua. O plano consegue, portanto, documentar uma referência que o modelo não verá. O teste deve comparar papéis exigidos com papéis realmente transportados no pedido. Isto não implica que todos os endpoints PixelLab aceitem os mesmos papéis.

Em A7, `masks.bbox()` devolve máximos exclusivos, mas `_opening()` calcula `bx[3] - bx[1] + 1`. Um teste da fronteira exata do mínimo deve acompanhar a correção.

**A estrutura deve ser medida semanticamente.** Uma região escura pode ser uma porta, uma viga ou uma fenda. A análise de luminosidade atual é um indício útil; não identifica sozinha a função arquitetónica.

Para uma abertura, recomendo guardar uma máscara do vão e medir a região conectada à soleira, a altura útil e as larguras por faixa. Um arco pode estreitar no topo sem impedir a leitura de passagem; por isso o algoritmo deve usar um perfil funcional e distinguir entrada utilizável, janela e abertura decorativa. O corpo e a arma devem ser envelopes separados. A caixa visual do Rei inclui acessórios e não deve virar automaticamente uma largura de colisão.

Para o apoio, marcar fundação e postes que devem tocar no solo. Conferir se esses componentes se ligam ao corpo ou aos suportes esperados. Uma cabana sobre postes não deve ser rejeitada por ter pouca área de contacto; um fragmento solto não deve “salvar” uma casa suspensa. A regra deve depender da tipologia.

Para emendas, produzir evidências independentes: contorno/alfa; materiais que chegam às bordas; diferença de cor e gradiente local; continuidade dos grupos de pixels; e uma prévia repetida. Comparar apenas com o maior salto interno pode esconder problemas quando o interior tem uma descontinuidade forte. O limite visual deve ser calibrado com pares aceites e rejeitados, incluindo mudanças intencionais de material.

**O contrato precisa de ligar a dimensão visual ao espaço funcional.** A oficina de referência resulta em aproximadamente 450 px de largura na escala do elenco; a forja do jogo ocupa 120 px. A solução já proposta no projeto — oficina ampla como marco e forja compacta numa tela de 128 px — é tecnicamente coerente como experimento e continua pendente de decisão na Q-298.

A evolução recomendada do contrato é explícita:

| Informação | Fonte / representação proposta | Verificação |
|---|---|---|
| Identidade funcional | ID da obra e ligação à linha de `buildings.csv` | A pegada corresponde aos dados do jogo |
| Área visual | Tela, caixa opaca e saliências permitidas | Telhado pode ultrapassar a pegada dentro da regra escolhida |
| Pivô e base | Coordenadas locais e transformação para o mundo | A mesma origem em todos os estados |
| Vãos e apoios | Regiões/máscaras com função | Medidas e ligações verificáveis |
| Encaixes | Lado, altura, material e classe de ligação | Só pares compatíveis podem ser montados |
| Profundidade | Plano de desenho e relação com os atores | Portas e interação permanecem no plano funcional |
| Estado | Correspondência com `SiteStage` | A revisão usa os estados que o jogo apresenta |
| Proveniência | Hashes de imagem, contrato, referências, paleta e versão da ferramenta | Mudanças invalidam apenas as provas afetadas |

Estes campos são uma proposta de evolução, não um novo schema já implementado. A migração deve manter leitura dos contratos existentes e seguir a disciplina de módulos curtos do projeto.

**A autoria deve começar por massas e função.** Proponho um percurso em que se revê o esboço antes de gastar detalhe: escolher a referência e os sinais essenciais; resolver a pegada e a régua; desenhar silhueta e aberturas; conferir a composição com os atores; gerar ou pintar materiais; corrigir localmente; e só depois preparar estados.

Na [bancada do piloto](https://github.com/henriquecoding/empire/blob/91d3521ea99a520248bc1e48c5e72f39fa8dd44a/docs/art/research/2026-10-28-forja-cenarios/evidencias/montagem-oficina-dia.png), observei uma oficina com muita microtextura e contraste no telhado, pedra e vigas, comparada com massas relativamente limpas no elenco. É uma observação visual desta prova reduzida, que o próprio projeto classifica como adaptação, não como mestre aprovado.

A intervenção que recomendo é concentrar detalhe nas junções, na chaminé, na boca de trabalho e nos sinais de identidade; dar áreas mais calmas às superfícies; separar claramente o interior escuro do contorno do personagem; e comparar madeira, pedra e telhado a 1×. O controlo não deve apagar material nem impor uma contagem universal de cores.

SLYNYRD demonstra como massas, contraste, saturação e detalhe por profundidade sustentam a leitura de um fundo. Aplicado ao Empire, isto justifica rever a hierarquia entre planos e atores, conservando a paleta e a gramática aprovadas do projeto. [Fonte: Landscape Backgrounds](https://www.slynyrd.com/blog/2026/5/27/pixelblog-62-landscape-backgrounds).

**Os módulos devem acompanhar o mundo lateral do Empire.** A Forja já prova topologia Wang, mas o catálogo de produção deve separar terra repetível, bordas, elementos únicos e edifícios. Uma boa peça repetível não precisa conter, ao mesmo tempo, uma árvore inteira, uma entrada e um monumento.

Recomendo uma família inicial de superfície 1D: miolos compatíveis, remates esquerdo/direito, mudanças de material e ligações a passagens já existentes. Por cima, distribuir objetos e marcos com pivôs próprios. Para edifícios, usar fundação, baía, poste, telhado, remate e chaminé como partes coordenadas por um desenho mestre. Preservar a aparência do conjunto é mais importante do que maximizar a quantidade de combinações.

A documentação do Tiled distingue conjuntos de cantos, arestas e mistos, e permite ponderar variantes. Isso apoia escolher uma topologia conforme a peça e controlar repetição; não obriga a migrar o editor. A Forja deve conservar as regras já existentes de variantes e distância, evitando espelhar peças com luz lateral. [Fonte: Tiled — Using Terrains](https://docs.mapeditor.org/en/stable/manual/terrain/).

O LDtk fornece outro princípio aproveitável: regras de desenho podem partir de uma grelha semântica e alimentar camadas visuais diferentes. No Empire, a simulação continua a decidir os sítios; a ferramenta de arte usa essa informação para compor. [Fonte: LDtk — Auto layers](https://ldtk.io/docs/general/auto-layers/).

**O gerador deve ser escolhido pela operação e pelos controlos que aceita.** A documentação atual do PixelLab oferece uma rota específica de sidescroller, descrita pelo material interior e pela superfície. Na página de Create Tileset, a variante Pro indicada é top-down. O rótulo “Pro” não demonstra adequação ao Empire. O adaptador deve resolver projeção, dimensões, alfa e entradas de controlo antes de enviar o pedido. [Fonte: PixelLab — Create Tileset](https://www.pixellab.ai/docs/tools/create-tileset).

Para a primeira integração, priorizaria o tileset lateral e um fluxo de edição por máscara, mantendo a proteção exterior que a Forja já possui. Objetos avulsos e construções devem usar rotas cuja referência possa ser efetivamente enviada e avaliada. A documentação da API separa criação de tiles, edição, inpainting e objetos; as capacidades devem ser lidas por endpoint. [Fonte: PixelLab API](https://api.pixellab.ai/v2/docs).

Uma tabela de capacidades útil deve registar endpoint e modelo, papéis de imagem aceites, limite de lado/área, tamanho efetivo, comportamento do alfa, edição mascarada e custo observado por tentativa. O dry-run deve falhar quando uma exigência obrigatória não é suportada. “Referência registada” e “referência enviada” precisam ser campos diferentes.

No Gemini, as proporções 4:1 e 8:1 **já constam no código**. A melhoria pendente é atualizar a tabela de dimensões: `capabilities()` ainda diz que não está documentada e `estimate()` usa área aproximada. Para 8:1 a 1K, medi uma estimativa local de **2896 × 368**, enquanto a documentação publica **3072 × 384** para os modelos pertinentes. Deve haver tabela por modelo/resolução, com conferência dos pixels efetivamente retornados. [Fontes: adaptador](https://github.com/henriquecoding/empire/blob/91d3521ea99a520248bc1e48c5e72f39fa8dd44a/tools/forja/backends/gemini_images.py#L33) e [Google — Image generation](https://ai.google.dev/gemini-api/docs/image-generation).

Para panoramas, a partição existente calcula regiões, mas não executa uma costura validada. O próximo passo deve partilhar coordenadas globais, mestre, contexto de borda e máscara protegida. Gerar faixas independentemente tende a deixar divergências que um prompt comum não elimina. Esta última conclusão é uma inferência de engenharia; precisa de um piloto comparativo.

**Os estados têm de comunicar mudanças, além de preservar a identidade.** O verificador atual prova que pixels não mudaram fora das regiões autorizadas. Falta provar que o estado pedido ficou reconhecível e continua estruturalmente válido.

Para cada variante, rever raster, portas que devem continuar livres, apoios, pivô e sinais protegidos. Exigir alteração numa região relevante quando o estado a pede; uma quantidade mínima de pixels alterados isoladamente também seria insuficiente, porque ruído satisfaz uma contagem. A avaliação deve combinar mudança localizada, significado declarado e revisão visual.

O runtime já tem `BuildingSkins` e `SiteStage`, que apresentam construção, reparação, operação e ruína. Antes de produzir folhas novas para todos os estados, definir a correspondência com estes mecanismos. Duplicar dano pintado com rachaduras sobrepostas pelo runtime pode piorar o resultado. Usar uma tabela que diga o que pertence à imagem, ao efeito e à simulação. [Código atual: BuildingSkins](https://github.com/henriquecoding/empire/blob/91d3521ea99a520248bc1e48c5e72f39fa8dd44a/src/world/building_skins.gd).

Separar visualmente a boca da fornalha e outros emissores permitiria testar luz sem repintar a construção inteira. A integração deve respeitar os shaders e as luzes do Empire. A documentação do Godot descreve iluminação ambiente, fontes e oclusão como elementos distintos; uma multiplicação global de cor não representa esse conjunto. [Fonte: Godot 4.7 — 2D lights and shadows](https://docs.godotengine.org/en/4.7/tutorials/2d/2d_lights_and_shadows.html).

**A bancada decisiva já tem um ponto de partida dentro do projeto.** A montagem Pillow atual é útil para escala e uma primeira leitura. A noite dela é explicitamente aproximada, sem as luzes nem o shader real; também não demonstra movimento, oclusão ou transições.

O repositório já documenta `tools/native_scenery_review.tscn`, `verify_native_scenery.tscn` e `capture_native_scenery.tscn`. Recomendo estender esta infraestrutura para consumir candidatos da Forja, em diretório de revisão, e produzir capturas relacionadas ao hash do candidato e ao commit. Evita-se criar outra bancada com regras divergentes. [Fonte interna: NATIVE_SCENERY](https://github.com/henriquecoding/empire/blob/91d3521ea99a520248bc1e48c5e72f39fa8dd44a/docs/art/NATIVE_SCENERY.md).

| Ensaio proposto | O que resolve |
|---|---|
| Rei e Nia ao lado, à frente e nas regiões de passagem | Escala relativa e legibilidade |
| Caminhada em ambos os sentidos | Deslizamento aparente, oclusão e repetição |
| Dia, crepúsculo e noite com as luzes existentes | Separação real entre ator e edifício |
| Mudança entre estados de construção | Saltos de pivô, forma ou sobreposição |
| Várias cópias e vizinhos diferentes | Emendas e repetição reconhecível |
| Superfície e nível inferior, quando aplicável | Fase de grelha e ancoragem |
| 720p, 1080p e tamanho de navegador representativo | Distribuição dos pixels e leitura final |

O Godot documenta que tamanho e posição das texturas precisam concordar com a repetição, e que alguns parâmetros não incorporam a escala dos nós automaticamente. Estes são critérios de teste para a integração existente, sem necessidade de substituir o `Parallax2D` que o projeto já utiliza. [Fonte: Godot 4.7 — 2D Parallax](https://docs.godotengine.org/en/4.7/tutorials/2d/2d_parallax.html).

A Q-300 também é relevante: 1280×720 para 1920×1080 implica fator 1,5. Células de cenário de 2 px passam a 3 px, mas pixels de ator de 1 px não podem ocupar uniformemente 1,5 pixels físicos. A documentação descreve a escala inteira como forma de evitar distribuição desigual. Para o Empire, comparar enquadramento, nitidez e legibilidade antes de escolher uma solução; a resolução interna de 1280×720 continua sendo o contrato. [Fonte: Godot 4.7 — Multiple resolutions](https://docs.godotengine.org/en/4.7/tutorials/rendering/multiple_resolutions.html).

**A saída editável deve transportar significado.** O escritor Aseprite da Forja já suporta camadas, tags e slices; o export Godot já contempla recursos como TileSet. A evolução necessária é transportar os metadados da cena através desse caminho e demonstrar que o importador os consome.

Slices podem guardar regiões nomeadas e pivôs, e o CLI exporta esses dados. Recomendo utilizá-los para base, vãos, pontos de apoio e encaixes, com uma convenção explícita de coordenadas e teste de ida e volta. A presença de um slice não cria automaticamente um socket ou uma colisão no jogo. [Fontes: Aseprite — Slices](https://www.aseprite.org/docs/slices/) e [CLI](https://www.aseprite.org/docs/cli/).

Um pacote de revisão deveria juntar imagem, fonte editável, contrato resolvido, manifesto de exportação, resultados por critério, versões das referências e capturas do motor. A aprovação deve apontar para os pixels exatos. O `--master` da revisão estrutural merece ser ligado ao registo de autoridade, porque a igualdade com uma imagem fornecida demonstra igualdade, mas não demonstra por si que essa imagem foi aprovada.

**Esta é a ordem de implementação com melhor relação entre esforço e benefício.** Os identificadores abaixo são rótulos desta proposta, não tickets já criados no GitHub.

| Ordem | Entrega proposta | Critério de conclusão |
|---|---|---|
| 1 | Fechar A1, A2, A5, A6 e A7 | Contraexemplos deixam de passar ou falham com erro útil; 44 testes atuais preservados |
| 2 | Reforçar emendas e estados, A3/A4 | Evidência por critério; variantes legítimas mantidas; alterações ausentes ou sem função sinalizadas |
| 3 | Ligar contrato à obra e às máscaras semânticas | ID funcional, pegada, pivô, vãos e apoios rastreáveis |
| 4 | Transportar contrato em Aseprite/export | Regiões e coordenadas sobrevivem ao percurso completo |
| 5 | Integrar candidatos na galeria Godot existente | Capturas de estados, luz, movimento e resoluções associadas ao candidato |
| 6 | Completar um piloto Enramados | Forja compacta, árvore, família de terreno e plano de fundo funcionam juntos |
| 7 | Adaptadores específicos de ambiente e dimensões por modelo | Planos honestos sobre controlos; retornos medidos; geração com teto explícito |
| 8 | Expandir catálogo e variantes | Novas peças passam pelos mesmos critérios e conservam identidade por povo |

O piloto deve ter um candidato mestre por elemento e alterações locais rastreáveis. A oficina ampla pode continuar como referência ou marco conforme a Q-298. O terreno deve ser ensaiado em várias ligações; a árvore deve preservar tronco, copa e raízes; o plano de fundo deve repetir sem impor sombras incompatíveis. Só depois de a cena funcionar em conjunto faz sentido multiplicar famílias e estilos.

Para comparar geradores, usar a mesma tarefa, referência e limite de tentativas. Registar custo total por peça aceite, tempo de correção, respeito pela geometria, recuperação da grelha e falhas por critério. O menor preço de chamada pode produzir o maior custo final se exigir mais tentativas e reparações. Sem piloto pago comparativo, não há evidência suficiente para eleger um fornecedor vencedor.

**As decisões pendentes podem ser apresentadas em provas pequenas.** A revisão das Q-295 a Q-300 deve acompanhar a implementação, com exemplos concretos, sem obrigar o dono a escolher números abstratos.

| Questão existente | Prova recomendada | Direção que recomendo testar |
|---|---|---|
| Q-295: proporções | Mesma casa com três perfis, junto do elenco | Usar a régua atual como perfil experimental até à escolha |
| Q-296: nível inferior | Caminhada e apoio em captura ampliada | Resolver primeiro na apresentação, preservando a simulação |
| Q-297: contorno | Mesma peça, duas alternativas, dia/noite | Medir a leitura conjunta antes de mudar a gramática |
| Q-298: forja compacta / oficina ampla | Ambas na mesma composição | Manter a pegada funcional no piloto e reduzir a complexidade da planta |
| Q-299: repetição e cadência | Travessia longa com luz lateral | Testar variantes sem espelho e avaliar a cadência observada |
| Q-300: escala de apresentação | Capturas equivalentes em 720p/1080p | Escolher pelo equilíbrio entre nitidez, enquadramento e leitura |

**O primeiro pacote para o Claude deve conter os contraexemplos, os critérios e o commit-base.** A tarefa imediata é corrigir o transporte de referências e os verificadores, acrescentando testes adversariais pequenos. Em seguida, ligar a peça à obra e à bancada real. As decisões de paleta, contorno, escala do elenco e geometria da simulação continuam nas perguntas existentes.

Para repetir a suíte relevante:

```bash
python3 -m unittest \
  tools.forja.tests.test_cenarios \
  tools.forja.tests.test_cenarios_revisao \
  tools.forja.tests.test_estrutura
```

As sondas adicionais foram feitas com a casa sintética de `scene_fixtures`: substituir a porta por uma faixa de 2 px; levantar a casa e acrescentar um bloco separado no solo; comparar duas faixas opacas de cores distintas; fornecer uma cópia intacta como `damaged`; planear uma cena PixelLab com um conceito local; e resolver um contrato com estados vazios. Todas operam localmente, sem geração.

A auditoria demonstra estes comportamentos no commit fixado. Não mede taxa de ocorrência em imagens reais, custo final de produção ou desempenho em dispositivos. O caminho proposto transforma essas incertezas em ensaios concretos, aproveitando a infraestrutura que o Empire já tem.

