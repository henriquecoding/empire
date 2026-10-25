# Forja: armas, equipamentos e consistência visual

**Relatório de pesquisa e plano de refinamento para o Claude**  
Empire · Pesquisa de 24–25 de outubro de 2026 · Revisão ampliada em 25/10 · Estado: diagnóstico e propostas, sem alteração da produção.

## 1. A conclusão principal

A Forja já resolve uma parte importante da preparação de imagens: planejamento, controle de pedidos, recuperação da grade, transparência, paleta, contorno, posicionamento e rastreabilidade. O que falta, para resolver a crítica às armas e aos equipamentos, é uma camada verificável de **construção do objeto, relação com o corpo e continuidade entre estados**.

Um arquivo pode ter 80×80 pixels, usar a paleta correta e passar no lint enquanto contém uma espada bifurcada ou duas guardas. Isso foi reproduzido nesta pesquisa. Portanto, melhorar apenas o texto do prompt ou trocar o gerador não fecha a lacuna.

A direção recomendada é:

1. Descrever cada equipamento como um objeto com partes, identidade e pontos de contato.
2. Aprovar a forma simples da arma e seu encaixe na mão antes de adicionar detalhes.
3. Conservar as partes aprovadas e corrigir regiões delimitadas.
4. Separar validação de arquivo, validação geométrica, revisão funcional, revisão artística e integração.
5. Só expandir para animações e variantes depois de uma prova estática convincente.

O aprendizado mais útil do canal PixelLab é seu processo de trabalho: referência selecionada, pose orientada, edição localizada, limpeza e inspeção. Os próprios tutoriais incluem falhas e intervenções manuais. Isso é diferente de uma promessa de geração impecável.

**Correção de expectativa sobre a entrega anterior:** os três personagens passaram nos critérios técnicos registrados pela Forja; isso não demonstrou que suas armas estavam bem construídas. A crítica do autor é compatível com os resultados técnicos. A aprovação artística continuava pendente.

## 2. Escopo, método e limites da evidência

Foram confrontados quatro conjuntos de evidências:

| Conjunto | O que foi efetivamente examinado |
|---|---|
| Entrega anterior | Fontes geradas, PNGs finais do rei, arqueiro e escudeiro, prompts e diagnósticos salvos |
| Código | `tools/forja/`, contratos e documentação de produção do Empire |
| Canal oficial PixelLab | Catálogo dos 70 vídeos retornados na consulta; leitura das transcrições automáticas de 13 vídeos pertinentes |
| Fontes primárias | Documentação PixelLab, especificação pública da API, referências de museu e World Archery |

A `main` consultada estava em `4471cde384c94e8833e4e61347551ac8c69320b0`. O checkout de execução estava em `cbc8366aca43f2d9d8021aec1797f6a34f23c43c`. A comparação não encontrou diferenças em `tools/forja`, `docs/art` ou `AGENTS.md` entre esses commits. Assim, o diagnóstico da Forja corresponde ao código desses caminhos na `main` consultada. Não foi feita nova auditoria completa do deploy ou do runtime.

**Sobre os vídeos:** a análise abaixo se baseia nas transcrições automáticas, títulos, metadados e documentação correspondente. Não constitui uma inspeção visual integral, quadro a quadro, dos vídeos. Os tempos são aproximados e apontam para os trechos da fala. O acesso ao arquivo de vídeo não produziu mídia utilizável. Em 24/10 foram lidas onze transcrições em inglês. Em 25/10, a exportação pelo navegador forneceu mais duas, em português, dos guias de inpainting e Pro Flash/Skeleton V3/PixMiniMax. Seis títulos selecionados continuam sem transcrição analisada; estão registrados como pesquisa complementar, sem lhes atribuir demonstrações não verificadas.

Não foram feitas gerações pagas no PixelLab nesta pesquisa. Os personagens criticados foram produzidos com geração de imagens anterior e adaptação pela Forja; não são um teste de qualidade do modelo PixelLab. Não há base para afirmar que a migração para PixelLab, sozinha, resolverá todos os defeitos.

As afirmações são separadas em **observação**, **medição**, **inferência** e **proposta**. Um ponto oculto por roupa, mão ou escudo não pode ser automaticamente declarado ausente.

## 3. O que está acontecendo nos três personagens

| Personagem | Evidência observada | Diagnóstico e prioridade |
|---|---|---|
| Rei | O conjunto mão–punho–guarda–pomo tem pouca separação visual. A lâmina e o brilho precisam ser avaliados como um único eixo. A fonte já contém a solução ambígua da empunhadura. | Rever a construção da espada inteira e sua relação com a mão. A existência de dois elementos dourados não prova duplicação: guarda e pomo são partes diferentes. É necessário identificar cada parte antes de remover qualquer uma. |
| Arqueiro | A linha clara entre as extremidades do arco é larga e irregular, com mudanças de posição e espessura. Isso já aparece na fonte anterior à Forja. A outra mão está no cinto, indicando uma pose de repouso, não uma puxada de corda. | Prioridade alta: reconstruir a corda como elemento fino e contínuo, conectado aos pontos corretos. A madeira deve continuar curva; “endireitar o arco” inteiro seria uma correção errada. |
| Escudeiro | A mão, o braço, a borda e a face do escudo formam uma região visualmente congestionada. A pega traseira e as correias não ficam suficientemente claras na imagem frontal/lateral. | Produzir uma referência de construção do verso e uma vista composta. Não concluir, apenas pela oclusão, que a pega não existe. Verificar posição da mão, cobertura do antebraço e volume do escudo. |
| Conjunto | O vinho dos tecidos fica mais próximo de marrom na adaptação; há diferenças de quantidade de cores e densidade de detalhes. | Rever rampas por material e leitura a 1×. A paleta global correta não garante a cor pretendida de cada material. |

### 3.1 Medições preservadas da entrega

| Asset | Tela | Altura útil | Cores opacas finais | Erros / avisos salvos | Células com mistura abaixo da grade |
|---|---:|---:|---:|---:|---:|
| Rei | 80×80 | 68 px | 27 | 0 / 2 | 155; aproximadamente 6% |
| Arqueiro | 80×80 | 74 px | 37 | 0 / 2 | 121; aproximadamente 5% |
| Escudeiro | 64×64 | 55 px | 46 | 0 / 2 | 269; aproximadamente 15% |

Os avisos são de gradiente e subgrade. As porcentagens não medem “qualidade artística” nem probabilidade de defeito de arma. São diagnósticos do processo de recuperação da grade.

Os prompts pediam aproximadamente 12–24 cores, mas os contratos reais `royal_80` e `royal_64` têm `max_colors: null`. Portanto, esse limite era uma intenção textual, não uma regra executada. Antes de transformá-lo em bloqueio, é preciso aprovar um orçamento de cores adequado ao elenco; reduzir tudo para um número arbitrário pode piorar rosto, couro e metal.

Também há uma instrução conflitante no pedido do rei: o assunto solicita um perfil de três quartos, enquanto a câmera exige perfil lateral estrito. O compilador de pedidos deve resolver a câmera em um campo único antes de escrever o prompt.

### 3.2 Separar defeito de origem e defeito de processamento

O arco irregular não nasceu exclusivamente da quantização: ele é visível na fonte gerada. A Forja pode conservar esse defeito e, dependendo das operações aplicadas, piorar detalhes estreitos. São problemas distintos:

- **Origem:** forma ou relação funcional incorreta já desenhada pelo gerador.
- **Recuperação:** amostragem de uma grade que não foi respeitada uniformemente.
- **Acabamento:** perda de contraste entre materiais, engrossamento de linhas ou fechamento de espaços.
- **Validação:** ausência de uma regra que reconheça a falha e impeça sua aceitação.

Registrar imagens intermediárias e diferenças por região permite atribuir cada regressão à etapa correta. Não convém culpar genericamente “a IA” ou “a quantização” por tudo.

## 4. Pesquisa ampliada no canal PixelLab

### 4.1 Os treze vídeos analisados

Os resumos são interpretações da transcrição, não transcrições reproduzidas. A coluna final contém propostas para o Empire, não recursos já implementados pela Forja.

| Vídeo e data | Trechos úteis e conteúdo confirmado pela fala | Aplicação proposta |
|---|---|---|
| [How to Generate Consistent Pixel Art for Games](https://www.youtube.com/watch?v=nITrIQw1gag), 29/12/2025 — vídeo enviado pelo autor | [1:43](https://www.youtube.com/watch?v=nITrIQw1gag&t=103s): referências devem compartilhar densidade, contorno, sombreamento e proporções. [2:22](https://www.youtube.com/watch?v=nITrIQw1gag&t=142s): separar o assunto desejado do estilo fornecido pelas imagens. | Criar um pacote pequeno de referências coerentes. Não usar uma prancha heterogênea como se fosse uma identidade única. Referência de estilo não substitui referência de construção da arma. |
| [Using inpainting to create style consistent characters](https://www.youtube.com/watch?v=68BYzLoLh-U), 17/01/2025 | [4:13](https://www.youtube.com/watch?v=68BYzLoLh-U&t=253s): contexto completo no pedido de inpainting. [7:01–8:47](https://www.youtube.com/watch?v=68BYzLoLh-U&t=421s): introdução de espada e escudo com esboço, imagem inicial e máscara; depois, correção da espada e limpeza manual. | É a referência mais direta para o defeito atual. Orientar posição e tamanho com um desenho simples antes de pedir acabamento; corrigir arma e contato da mão juntos. |
| [Learn how to animate, rotate and inpaint your character](https://www.youtube.com/watch?v=hOZzbQBjKPc), 27/01/2025 | [7:59](https://www.youtube.com/watch?v=hOZzbQBjKPc&t=479s): limpar frames que servirão de referência. [9:50–11:29](https://www.youtube.com/watch?v=hOZzbQBjKPc&t=590s): corrigir qual braço fica à frente usando imagem inicial e inpainting. | Registrar oclusão e identidade de cada braço. Uma pose com braço invertido pode manter área e contorno plausíveis e ainda estar errada. |
| [How to animate pixel art using a skeleton](https://www.youtube.com/watch?v=zBfVT5pwCSs), 26/10/2024 | [0:42–2:27](https://www.youtube.com/watch?v=zBfVT5pwCSs&t=42s): revisar esqueleto estimado e proporções. [6:35–7:54](https://www.youtube.com/watch?v=zBfVT5pwCSs&t=395s): editar apenas o frame problemático. [14:33–18:17](https://www.youtube.com/watch?v=zBfVT5pwCSs&t=873s): mão ausente e conflito entre pose e imagem inicial. | Conferir pose antes de gerar. Congelar frames bons. Uma referência ruim não deve alimentar automaticamente a sequência seguinte. As opções mostradas são de uma versão antiga. |
| [Animation to animation with PixelLab](https://www.youtube.com/watch?v=owkamgYVWAs), 20/06/2025 | [0:49–1:24](https://www.youtube.com/watch?v=owkamgYVWAs&t=49s): aparência, ação, câmera e paleta têm controles separados. [2:19](https://www.youtube.com/watch?v=owkamgYVWAs&t=139s): selecionar referência para continuidade. [4:09](https://www.youtube.com/watch?v=owkamgYVWAs&t=249s): limpeza manual permanece necessária. | Separar identidade de movimento no manifesto. O link aparece na descrição do vídeo enviado, mas o título e o assunto são de animação; não é uma continuação detalhada da ferramenta de estilo. |
| [How to use the Edit tool](https://www.youtube.com/watch?v=XhmpenTmPLg), 16/07/2025 | [0:59](https://www.youtube.com/watch?v=XhmpenTmPLg&t=59s): instrução de edição descreve uma mudança. [5:55–6:24](https://www.youtube.com/watch?v=XhmpenTmPLg&t=355s): mudanças pequenas e iterativas. [9:27–9:47](https://www.youtube.com/watch?v=XhmpenTmPLg&t=567s): ressalva sobre adicionar objetos em resoluções pequenas. | Usar gramática de pedido própria para criar, editar, reparar ou animar. Não reenviar sempre a descrição inteira de geração como se fosse uma instrução de edição. |
| [Building a Cohesive Game Art Style Using PixelLab](https://www.youtube.com/watch?v=7HTLYLo3tTQ), 22/01/2026 | [1:18–2:37](https://www.youtube.com/watch?v=7HTLYLo3tTQ&t=78s): uma referência visual organiza a família de assets; personagens fora de templates usam movimentos descritos. | Construir uma biblioteca do Empire com referências aceitas. Não importar o estilo do jogo demonstrado nem assumir que toda ação cabe num template humanoide genérico. |
| [Animate Between 2 Frames](https://www.youtube.com/watch?v=1CjxHZoZE_I), 25/03/2026 | [3:58–4:49](https://www.youtube.com/watch?v=1CjxHZoZE_I&t=238s): preparar pose inicial de ataque e interpolar. [5:35–6:19](https://www.youtube.com/watch?v=1CjxHZoZE_I&t=335s): há frame parado e detalhes que exigem limpeza. | Definir poses-chave de preparação e recuperação; verificar os intermediários. Ter início e fim corretos não prova um golpe funcional no meio. |
| [Introducing Object Creator](https://www.youtube.com/watch?v=Hhx9QZwYoZY), 27/04/2026 | [0:00–0:45](https://www.youtube.com/watch?v=Hhx9QZwYoZY&t=0s): objetos individuais ou packs, com estilo e perspectiva. [1:06–1:40](https://www.youtube.com/watch?v=Hhx9QZwYoZY&t=66s): variações de estado e animação de objetos. | Aprovar espada, arco, escudo e armazenamento isoladamente; depois compor com o corpo. Um objeto bonito isolado ainda precisa passar no teste de encaixe. |
| [How to Generate & Animate GBA-Style Sprites](https://www.youtube.com/watch?v=moCpjMOOBGk), 10/05/2026 | [2:52–3:35](https://www.youtube.com/watch?v=moCpjMOOBGk&t=172s): ataque de espada com intervenção manual. [6:10–8:18](https://www.youtube.com/watch?v=moCpjMOOBGk&t=370s): o autor alerta sobre templates e objetos segurados, usa animação customizada e corrige capacete/espada. [8:32](https://www.youtube.com/watch?v=moCpjMOOBGk&t=512s): canvas de referência afeta escala. [11:37](https://www.youtube.com/watch?v=moCpjMOOBGk&t=697s): flechas são selecionadas e ajustadas manualmente. | Dar tratamento explícito à arma durante a animação e distinguir tela de altura útil. A observação sobre treinamento dos templates é uma afirmação do apresentador, não uma auditoria independente dos modelos. |
| [Character States: The New Way to Animate Sprites](https://www.youtube.com/watch?v=oCJWxfEwX-o), 16/05/2026 | [2:19–3:58](https://www.youtube.com/watch?v=oCJWxfEwX-o&t=139s): preparar estado/pose antes do movimento. [4:07](https://www.youtube.com/watch?v=oCJWxfEwX-o&t=247s): corrigir apenas o rosto. [5:05](https://www.youtube.com/watch?v=oCJWxfEwX-o&t=305s): espelhamento depende da assimetria. [6:56–7:42](https://www.youtube.com/watch?v=oCJWxfEwX-o&t=416s): transição entre estados. | Organizar repouso, preparação, uso e recuperação do equipamento. Aplicar as regras de espelhamento já aceitas no Empire; a advertência geral do vídeo não revoga decisões do projeto. |
| [The Ultimate PixelLab Inpainting Guide for Creator](https://www.youtube.com/watch?v=9eAlZlQmZBg), 22/07/2026 | [1:34–2:33](https://www.youtube.com/watch?v=9eAlZlQmZBg&t=94s): a camada só com alterações conserva o chapéu antigo por baixo; para removê-lo, o autor troca o método de saída. [4:17–5:04](https://www.youtube.com/watch?v=9eAlZlQmZBg&t=257s): pixels externos mudam sem recorte; a opção de recortar à máscara limita a edição. | Distinguir adicionar de substituir/remover. Sobrepor uma espada corrigida não pode deixar a antiga na composição. Validar também o resultado achatado e a preservação externa, não apenas a camada nova. |
| [Images Pro Flash, Skeleton V3 & PixMiniMax](https://www.youtube.com/watch?v=Y68m9k60Lg0), analisado em 25/10/2026 | [6:24–6:51](https://www.youtube.com/watch?v=Y68m9k60Lg0&t=384s): máscara pequena demais precisa ser ampliada. [9:16–10:11](https://www.youtube.com/watch?v=Y68m9k60Lg0&t=556s): o autor recomenda experimentar Skeleton V3, mantendo a limpeza. [10:36–11:43](https://www.youtube.com/watch?v=Y68m9k60Lg0&t=636s): o prompt aprimorado conflita com a direção; [11:46–13:23](https://www.youtube.com/watch?v=Y68m9k60Lg0&t=706s): a cor do efeito também varia. | Revisar o pedido expandido; preservar câmera, direção e cores aprovadas. Testar templates por versão e por equipamento. A crítica histórica aos modelos antigos não deve ser uma proibição permanente do V3. |

### 4.2 O que a pesquisa ampliada muda no diagnóstico

O vídeo inicial ensina principalmente **consistência de estilo**. Os outros tutoriais acrescentam as peças que faltavam para esta tarefa: esboço da arma, máscara, pose, ordem dos braços, seleção de frames, correções manuais e estados.

Esses aspectos precisam ser tratados separadamente:

| Controle | Pergunta que responde | Exemplo no Empire |
|---|---|---|
| Estilo | Parece pertencer ao mesmo jogo? | Contorno, materiais, cabeça e densidade de detalhe |
| Identidade | Continua sendo o mesmo personagem/objeto? | Mesmo rei, mesma espada curta, mesmo escudo |
| Geometria | As partes estão construídas e conectadas? | Uma guarda, um punho e uma lâmina coerente |
| Função visual | A pose comunica um uso possível? | Mão no punho; corda e flecha no estado adequado |
| Continuidade | Isso permanece correto no tempo? | Arma não troca de mão nem perde partes entre frames |

Reforçar a referência de estilo pode melhorar a primeira coluna e continuar falhando nas demais. É por isso que a arquitetura precisa de dados e verificações adicionais.

### 4.3 Vídeos adicionais catalogados, sem análise integral das legendas

Foram localizados e priorizados estes materiais, mas as legendas não puderam ser obtidas. Seus conteúdos não são usados como prova de passos específicos:

- [Create Image from Style Reference (Pro)](https://www.youtube.com/watch?v=tx-JUE8KbJM).
- [Level Up Your Game: Custom Sprite Animation Tutorial](https://www.youtube.com/watch?v=r8ySiSRRvz4).
- [How to Reduce Colors Like a Pro!](https://www.youtube.com/watch?v=WSbBuAwRm18).
- [How to Use Animate with Text](https://www.youtube.com/watch?v=j2bE9gq914U).
- [Vibe Coding a Full Game with PixelLab MCP + API](https://www.youtube.com/watch?v=fvPmuk-usgw).
- [Animate a Pixel Art Character in All 8 Directions](https://www.youtube.com/watch?v=zqZiQBS3LX0).

O catálogo de 70 vídeos acompanha o pacote. Ele registra quais transcrições foram analisadas; catalogar um título não equivale a assistir ao vídeo. Conteúdos sobre mapas, UI e VFX foram classificados como secundários para corrigir armas e equipamentos.

### 4.4 Duas verificações acrescentadas na revisão de 25/10

**Composição:** o caso do chapéu no guia de inpainting mostra por que adicionar uma camada e substituir pixels são operações distintas. Aplicação proposta: cada reparo deve declarar `add`, `replace` ou `remove`; testar se a composição final ainda contém o objeto anterior. Isso é uma hipótese de falha a prevenir, não a causa comprovada das duplicações nos três personagens examinados.

**Pedido expandido:** o tutorial dos modelos novos mostra um conflito de orientação introduzido no aprimoramento do texto. Aplicação proposta: guardar pedido original e expandido, confrontar ambos com câmera, direção, inventário e estado; bloquear contradições antes da geração. A melhoria de um modelo não elimina a necessidade de verificar seus resultados.

## 5. Auditoria da Forja: o que conservar e o que falta

Os caminhos abaixo podem ser consultados no [commit auditado](https://github.com/henriquecoding/empire/tree/cbc8366aca43f2d9d8021aec1797f6a34f23c43c/tools/forja).

| Área e arquivo | Comportamento atual observado | Lacuna / ação proposta |
|---|---|---|
| `contracts.json`, `contracts.py` | Contratos de canvas, pivô, altura, paleta, contorno e clusters | Adicionar contrato auxiliar de personagem e equipamento. Não sobrecarregar o contrato raster com toda a anatomia. |
| `prompts.py` | Assunto em texto livre e referências por papel | Compilar inventário, câmera e estado a partir de dados consistentes. Detectar contradições antes da chamada. |
| `plan.py` | Referência `identity` vira `init_image` no caminho PixelLab; valor padrão de força 300 | Imagem inicial é orientação, não trava de identidade. Escolher estratégia por tarefa e capacidade real do modelo. |
| `plan.py:120` | `init_strength or 300` | Zero explícito é substituído por 300. Correção concreta: distinguir `None` de zero; testar zero, valor positivo e ausência. |
| `backends/pixellab_api.py` | Adaptador estático para PixFlux, Pixen e BitForge; `static_image_only: True` | PixelLab tem recursos além disso, mas a Forja ainda não os expõe nesse adaptador. Evoluir por operações, com contratos próprios. |
| `pipeline.py:100–124` | Limpeza, normalização do contorno, quantização e eventual adição global de contorno | Preservar linhas finas e espaços negativos com máscaras e política por região. Auditar antes/depois. |
| `quantize.py:30–48` | Escolha de cores da paleta por proximidade, sem identificação de material | Adicionar rampas aprovadas por região/material e comparação de contraste. Não inventar nova paleta mestra. |
| `lint.py` | Examina estrutura raster e avisos de estilo | Não identifica espada, corda, mão, correia ou duplicação de objeto dentro do frame. |
| `review.py` | Indícios de movimento, frames repetidos, mudanças de massa; aprovação artística pendente | `hidden_duplicate` detecta repetição de frames completos, não duas guardas na mesma espada. Acrescentar acompanhamento de objetos e contatos. |
| `inpaint.py` | Reparo por caixa; preservação byte a byte fora dela; retorno de tamanho incorreto é rejeitado; execução OpenAI | É uma base útil já existente. Evoluir para máscara arbitrária, proteção de regiões e adaptador PixelLab. Não reimplementar do zero. |
| `auto.py` | Validade e necessidade de regeneração derivam principalmente do lint; desvio de grade pode ser apenas achado | Acrescentar estados semânticos independentes e uma escolha entre ajuste determinístico, reparo local ou regeneração. |

### 5.1 Uma especificação existente ainda não executada pela ferramenta

A documentação do Empire já pede função, atuação, equipamento por estado, sockets, revisão de objetos extras e prova em movimento. A Asset Bible também define camadas de equipamento. Portanto, a lacuna não é simplesmente “falta pesquisar”: parte do conhecimento já existe, mas não foi convertida em entradas obrigatórias, evidências e verificações executáveis na Forja.

Conservar especialmente:

- Fontes e prompts completos, histórico de tentativas e hashes.
- Controle de jobs e proteção contra repetir POSTs pagos.
- Rejeição de cortes e de mudanças silenciosas de tamanho.
- Distinção entre recuperação de grade e autoria nativa.
- Preservação externa ao reparo em `inpaint.merge`.
- Aprovação artística reservada ao autor.

### 5.2 Provas executadas nesta pesquisa

Foi criado um conjunto sintético de 80×80, com a paleta do Empire, contrato `royal_80` e o lint real, sem alterar o repositório:

| Caso controlado | Resultado esperado na revisão de uma espada simples | Erros do lint atual |
|---|---|---:|
| Referência sintética | Candidato para comparar | 0 |
| Lâmina bifurcada | Rejeitar | 0 |
| Duas guardas | Rejeitar | 0 |
| Arma removida | Rejeitar, quando exigida pelo pedido | 0 |

Essa prova não mede a taxa de erro dos modelos e não demonstra que o lint esteja mal implementado para sua finalidade atual. Demonstra que o contrato atual não expressa a finalidade semântica necessária.

Um segundo teste, isolando `outline.add`, transformou uma linha de 1 pixel em 3 pixels de largura e fechou um espaço transparente de 2 pixels entre duas linhas. Isso confirma um **risco da operação global**. Nos três resultados finais examinados, o registro `finish` não indica `outline_added`: esse ramo não foi executado. Portanto, esse teste aponta uma prevenção necessária para outras execuções, não a causa da corda larga desta entrega, que já aparecia na fonte gerada.

As fixtures, o script reproduzível e os resultados JSON estão no pacote. Elas são diagramas de teste, não propostas de arte para o jogo.

## 6. O contrato funcional que a Forja precisa conhecer

### 6.1 Três registros separados

O sistema precisa guardar:

1. **Intenção:** o que deveria existir, segundo o brief e as referências aceitas.
2. **Observação:** o que foi localizado na imagem, com método, autor, versão e incerteza.
3. **Veredito:** comparação entre intenção e observação.

Um JSON dizendo `blade_count: 1` não demonstra que a imagem tenha uma lâmina. Máscaras e pontos desenhados automaticamente também podem estar errados. A implementação inicial pode exigir marcação humana das regiões críticas; um modelo visual pode sugeri-las, mas não deve aprová-las sozinho sem evidência verificável.

### 6.2 Dados mínimos por equipamento

| Campo conceitual | Finalidade |
|---|---|
| Identificador persistente | Distinguir a mesma espada entre frames de uma segunda espada acidental |
| Família e referência aprovada | Espada reta, arco simples, escudo etc.; evitar regras universais inadequadas |
| Partes e quantidades | Lâmina, guarda, punho e pomo; partes visíveis, ocultas ou opcionais |
| Pontos de conexão | Mão–punho, corda–extremidades, correia–bolsa, escudo–pega |
| Máscaras por parte | Editar e medir a região correta; separar objeto de corpo e efeito |
| Geometria de referência | Eixo, pontos extremos, envelope, espessura e espaço livre |
| Comportamento | Rígido, flexível, articulado ou tecido; diferentes verificações |
| Estado de uso | Guardado, transportado, segurado, preparado, em uso, recuperação |
| Oclusão | Quem cobre quem e quais partes não são observáveis nesta vista |
| Material e rampa | Madeira, aço, couro, tecido; evitar troca semântica de cores |
| Aprovação e procedência | Referência aceita, candidato gerado, reparado ou revisado |

Os estados são descrições de apresentação. Não criam novas mecânicas, capacidades de inventário ou eventos da simulação.

### 6.3 Espada: construção e leitura

Para a espada curta reta proposta no estudo do rei, validar a sequência **pomo → punho → guarda → lâmina → ponta**. A mão deve envolver o punho; pode ocultar parte dele. Guarda e pomo não são duas versões da mesma peça.

Referências de museu ajudam a distinguir essas partes. O [exemplar do Met de cerca de 1400–1450](https://www.metmuseum.org/art/collection/search/35388) documenta guarda, pomo e lâmina afilada. É uma espada de duas mãos: serve como referência de construção, não como medida ou desenho a copiar para a espada curta do rei.

Verificações propostas:

- Eixo contínuo da lâmina, sem bifurcação ou desvio acidental.
- Largura e afilamento coerentes com a referência; brilho não deve parecer uma segunda lâmina.
- Guarda associada à base da lâmina, não solta no braço.
- Punho suficientemente legível para explicar o contato da mão.
- Ponta e bordas dentro do envelope previsto para aquela pose.
- Comprimento aparente consistente entre frames de orientação comparável.

Não exigir verticalidade: uma espada pode estar inclinada. Não tratar o serrilhado regular de uma diagonal raster como curvatura indevida. E não aplicar a regra de lâmina reta a sabres ou outras famílias curvas.

### 6.4 Arco, corda e flecha

A [World Archery](https://www.worldarchery.sport/sport/equipment/barebow) distingue empunhadura, membros e corda ligada às extremidades. Essas relações são úteis para o desenho; acessórios de arcos esportivos modernos não devem ser importados automaticamente para o Empire.

O arco tem partes com comportamentos diferentes: a empunhadura organiza o contato, os membros se flexionam e a corda muda de configuração com a puxada. A curva da madeira é intencional. No repouso representado no estudo, a corda precisa ler como um elemento tensionado entre seus pontos de ligação, não como uma faixa ondulada.

| Estado visual | Relações a conferir |
|---|---|
| Repouso | Uma arma; mão na empunhadura; corda entre as extremidades; ausência de flecha encaixada é permitida |
| Preparação | A flecha, quando mostrada, tem identidade própria; não surge como uma segunda corda |
| Puxada | Mão de apoio permanece na empunhadura; outra mão atua sobre a corda; encaixe da flecha acompanha o ponto de puxada |
| Soltura | Flecha e projétil não ficam duplicados por erro de apresentação; obedecer ao evento já definido pelo jogo |
| Recuperação | Objeto conserva identidade e volta à configuração prevista sem peças surgirem ou desaparecerem |

No raster, uma corda pode usar uma única linha de pixels e dispensar bordas adicionais ao redor dela. Essa exceção precisa ser aprovada como regra de detalhe; não deve remover silenciosamente o contorno do resto do personagem.

A mão pode ocultar um trecho. A verificação deve considerar essa oclusão e aceitar continuidade lógica com evidência, em vez de exigir que toda a corda seja um componente opaco único.

### 6.5 Escudo: o verso também precisa existir no projeto

O [Met documenta uma pega interior de escudo](https://www.metmuseum.org/art/collection/search/22636); o [Worcester Art Museum documenta um escudo com correias traseiras](https://worcester.emuseum.com/objects/49827/dhal-shield). São construções diferentes. Não se deve misturá-las sem escolher o tipo pretendido.

Para o escudeiro, preparar uma ficha com frente, verso simplificado, pega, pontos de apoio e vista composta com a mão. O verso não precisa ficar visível no sprite final, mas precisa orientar o desenho.

Testar: mão posicionada na pega; antebraço coberto de forma coerente; face e borda pertencendo ao mesmo volume; ponta inferior sem colidir visualmente com a bota; decoração acompanhando o escudo em vez de deslizar sobre ele. A largura aparente pode variar com a perspectiva: uma caixa delimitadora mais estreita não significa automaticamente perda de massa.

### 6.6 Equipamentos transportados e armazenamento

O projeto já diferencia `storage` de `weapon`, `shield`, `head` e `face`. `Equipments`, nos arquivos de trabalho, corresponde ao armazenamento do personagem; não é um nome genérico para todos os acessórios.

As referências documentadas incluem `royal_belt`, `quiver`, `satchel`, `climbing_belt`, `knight_pack`, `saddlebags` e `dispatch_case`. O CSV `data/source/storages.csv` marca `holds|worn` como campos propostos. Assim, o Claude deve verificar as decisões vigentes antes de transformar capacidades e posições em regras definitivas. Não interpretar uma tabela de design como prova de integração no runtime.

Para cada bolsa, aljava ou mochila, validar suspensão, abertura e relação com o corpo: correia com trajeto compreensível, fivela ligada a uma correia, recipiente com volume suficiente para o conteúdo visível e ausência de correias duplicadas sem função. Uma correia pode desaparecer atrás do corpo; isso é oclusão, não necessariamente quebra.

As penas vistas na aljava não autorizam inventar um sistema de consumo de flechas. Do mesmo modo, adicionar uma bolsa não deve alterar capacidade de moedas ou archotes. O relatório trata de coerência visual com os dados aprovados.

### 6.7 Camadas, sockets e espelhamento: respeitar o Empire

A [Asset Bible](https://github.com/henriquecoding/empire/blob/4471cde384c94e8833e4e61347551ac8c69320b0/docs/art/ASSET_BIBLE.md) já define os slots e suas relações. Não criar uma nova ordem global de camadas só porque um tutorial usa outra organização. Máscaras de oclusão podem existir na produção e ser consolidadas para os slots aceitos na exportação.

A [Animation Bible](https://github.com/henriquecoding/empire/blob/4471cde384c94e8833e4e61347551ac8c69320b0/docs/art/ANIMATION_BIBLE.md) registra `socket_weapon`, `socket_fx`, `socket_head` e `socket_carry`. O ponto de pega proposto para análise não deve reutilizar `socket_weapon`: este tem função documentada ligada à ponta/emissão no frame de ação.

Também existe uma decisão explícita permitindo espelhar arma/escudo, inclusive com troca de braço do escudo. A pesquisa externa não revoga essa decisão. O validador deve aplicar a política do projeto e transformar pontos e máscaras consistentemente. Exceções de identidade, como a coroa torta, precisam permanecer explícitas.

## 7. Como transformar essas ideias em verificações úteis

### 7.1 Geometria com tolerância de pixel art

| Verificação proposta | Método inicial viável | Cuidado necessário |
|---|---|---|
| Eixo de lâmina reta | Marcar base/ponta e comparar uma linha central da máscara com o eixo esperado | Medir em pixels nativos; não penalizar a escada normal da diagonal |
| Contato mão–punho | Distância entre âncoras e sobreposição/adjacência das regiões aprovadas | O contato pode estar oculto; retornar inconclusivo quando necessário |
| Corda | Comparar trajeto com extremidades e estado; usar conectividade compatível com diagonais | Separar corda de madeira, flecha, brilho e dedos |
| Duplicações | Inventário de instâncias e partes, confrontado com regiões observadas | Simetria, decoração repetida e guarda+pomo não são duplicação automaticamente |
| Equipamento perdido | Identidade e visibilidade por frame; comparação com oclusões esperadas | Variação de área por perspectiva não basta para acusar perda |
| Espaço negativo | Preservar corredores entre arma, mão e corpo quando exigidos | Contato intencional não deve ser “corrigido” abrindo um buraco |
| Consistência temporal | Trajetória de pega, orientação do objeto e partes por frame | Arco e tecido podem deformar; espada e escudo têm outra regra |
| Preservação do reparo | Comparar RGBA fora da máscara e hashes das regiões protegidas | Fazer a comparação após todas as operações de acabamento |

Como ponto de partida experimental, distâncias próximas de 1 pixel nativo podem ser toleradas para certos contatos e desvios raster. Isso é uma hipótese de calibração, não um padrão universal. A tolerância deve variar por família, escala, pose e referência aceita. Não copiar números entre um personagem de 32 px e outro de 80 px sem avaliação.

Se não houver máscara confiável da lâmina, não emitir “lâmina reta: aprovado”. Emitir “não avaliado” ou “inconclusivo”, com a evidência que falta.

### 7.2 Vereditos separados, sem uma nota que esconda falhas

O relatório de cada tentativa deveria conter:

```json
{
  "raster_contract": "pass",
  "equipment_geometry": "fail",
  "functional_pose": "needs_review",
  "identity_consistency": "not_evaluated",
  "temporal_consistency": "not_applicable",
  "artistic_approval": "pending",
  "runtime_integration": "not_tested"
}
```

Os nomes são proposta. O importante é conservar as distinções. “Não avaliado” não pode virar aprovação por ausência de erro. Também não se deve calcular uma média em que uma boa paleta compense uma segunda lâmina.

Uma avaliação visual por modelo pode localizar suspeitas, mas deve produzir região, motivo e incerteza. As regras determinísticas trabalham sobre evidências verificadas; a revisão humana decide ambiguidades e qualidade final.

## 8. Fluxo de produção recomendado

### Etapa A — Brief e referências

Resolver personagem, função, câmera, direção, escala, estado e inventário. Separar imagens de identidade, estilo, construção, pose e paleta. Classificar cada referência como aprovada, estudo ou rejeitada. O estudo criticado não se torna referência de construção só porque já tem um arquivo final.

### Etapa B — Construção simples

Desenhar ou marcar o corpo, a arma e os pontos de contato na grade de destino. Reservar espaço para mãos, ponta da espada, extremidades do arco e escudo. Usar massas simples; detalhes vêm depois.

Para as armas atuais, começar com fichas isoladas de espada, arco e escudo. Comparar em escala real, não apenas numa imagem ampliada. As proporções caricaturais do elenco são intencionais; a exigência é legibilidade e construção coerente dentro desse estilo.

### Etapa C — Geração orientada

Escolher a operação adequada ao problema. Criar uma identidade nova, aplicar estilo, mudar uma pose e reparar uma corda são tarefas diferentes. Nem todo backend aceita todos os tipos de guia.

Quando o gerador já retorna um raster nativo no tamanho aceito, preservar esse raster. Quando retorna uma imagem ampliada, recuperar a grade com evidência e revisar regiões subgrade. Não declarar “nativo” apenas porque o arquivo final tem 80×80.

### Etapa D — Validação antes do acabamento global

Revisar contagem de objetos, topologia e contatos antes de quantizar e engrossar contornos. Uma espada defeituosa não deve receber acabamento e ser promovida a referência para mais personagens.

### Etapa E — Reparo localizado

Escolher a menor **unidade funcional suficiente**. Para uma espada, pode ser arma inteira e mão; para uma corda, incluir seus pontos de ligação; para um escudo, incluir pega e contato do antebraço. Uma máscara minúscula que exclui a conexão necessária pode produzir uma emenda ruim.

Preservar cabeça, roupa e corpo fora da máscara; fornecer contexto ao gerador; recompor localmente o resultado; verificar novamente o exterior preservado. Manter uma versão anterior recuperável. Uma linha simples pode ser corrigida deterministicamente na grade em vez de consumir outra geração.

### Etapa F — Cor e contorno conscientes da região

Aplicar rampas por material, protegendo a separação entre couro, madeira, metal e tecido. Comparar o resultado com a referência. Usar uma máscara de detalhes finos e outra de espaços negativos para impedir que o contorno global engrosse cordas ou feche vazios importantes.

### Etapa G — Poses e animação

Preparar poses-chave que já expliquem a ação. Verificar contatos e equipamentos nessas poses antes de interpolar. Não expandir automaticamente um frame defeituoso. Reparar apenas os frames/regiões que falharam e manter os aprovados.

A contagem final segue o contrato do Empire. A Animation Bible registra, entre outros, `idle` 6, `walk` 8, `attack` 5 e `die` 7. O fato de um tutorial produzir seis frames mais um inicial não autoriza mudar essas tags. O adaptador precisa registrar separadamente frames pedidos, recebidos, referência e entradas finais da timeline.

### Etapa H — Revisão e integração

Apresentar PNG a 1×, ampliação inteira, fundo claro/escuro e prova em movimento. Confrontar o personagem com referências aceitas do elenco. Exportar camadas, pivôs, tempos e sockets conforme os contratos vigentes. A apresentação acompanha a simulação; não deve criar projéteis ou efeitos de gameplay adicionais por conta própria.

## 9. PixelLab: capacidades reais e pontos de integração

### 9.1 O adaptador atual é menor que a plataforma

O adaptador da Forja consultado cobre geração estática por três modelos. A documentação oficial também descreve [inpainting](https://www.pixellab.ai/docs/tools/inpaint-v3), [edição de animação](https://www.pixellab.ai/docs/tools/edit-animation-pro), [transferência de roupa](https://www.pixellab.ai/docs/tools/transfer-outfit-pro), [animação com esqueleto](https://www.pixellab.ai/docs/tools/animate-with-skeleton) e [referências de estilo](https://www.pixellab.ai/docs/tools/consistent-style). Cada operação precisa de seu próprio adaptador e testes de contrato.

| Operação candidata | Uso na Forja | Critério de aceite da integração |
|---|---|---|
| Inpainting com máscara | Corrigir arma/pega sem redesenhar o restante | Máscara traduzida corretamente, tamanho verificado, exterior recomposto e idêntico |
| Geração por estilo | Criar candidatos coerentes com referências do Empire | Referências identificadas; escala e contagem recebida verificadas |
| Esqueleto | Orientar corpo e mãos em poses | Esqueleto corresponde ao frame de referência; arma recebe controles adicionais |
| Edição de animação | Aplicar uma alteração consistente numa sequência | Não remover objetos, trocar mãos ou alterar tempo sem registro |
| Transferência de roupa | Variantes de vestuário/equipamento visual | Conservação da ação e identidade; contagem de peças e contatos revisados |
| Interpolação | Completar transições entre poses aprovadas | Intermediários passam nos mesmos testes funcionais das poses-chave |

Um esqueleto humano não modela sozinho lâmina, corda, escudo, aljava ou correias. Mesmo quando a pose do corpo está correta, essas estruturas continuam exigindo orientação e revisão próprias.

### 9.2 Diferenças verificadas entre vídeo, editor e API

A especificação pública foi obtida de [OpenAPI v2](https://api.pixellab.ai/v2/openapi.json) em 24/10/2026; SHA-256: `48bb9b6fbf8a445190c61433f6aa822840d6ea7ad22d9a2240a581f4b70094db`.

Nesse snapshot, `generate-with-style-v2` aceita 1–4 referências; tamanho é deduzido delas, e `image_size` está depreciado. Para 80 px, a descrição indica nove saídas. A documentação do editor descreve limites diferentes, inclusive 16 saídas no intervalo 65–85 px. Não transportar o limite mostrado no vídeo diretamente para a API.

`inpaint-v3` usa branco para gerar e preto para preservar. `animate-with-skeleton-v3` requer os pontos da pose inicial, aceita 3–15 poses de saída e não devolve a referência como frame adicional. A Forja precisa traduzir convenções e contar o retorno real, não deduzi-lo do nome “V3”.

As operações `edit-animation-v2` e `transfer-outfit-v2` também constam na API. Sua presença não significa que já estejam integradas ou testadas na Forja. A capacidade deve ser verificada por operação e versão antes de qualquer pedido pago.

Saídas múltiplas de geração por estilo são candidatos de assets; não devem ser tratadas automaticamente como frames consecutivos de uma animação. E os tamanhos admitidos pela ferramenta antiga de esqueleto não devem levar a reduzir um personagem de 80×80 para 64×64: escolher uma operação compatível ou, quando cabível, adicionar margem explícita, transformar as coordenadas e recortar sem perder pixels. Não confundir esse procedimento com redimensionar a arte.

### 9.3 Força da imagem inicial não é preservação exata

A [documentação de imagem inicial](https://www.pixellab.ai/docs/options/init-image) descreve uma progressão de orientação grosseira para preservação mais detalhada conforme aumenta a força. O padrão 300 usado pela Forja não é uma garantia de manter desenho ou identidade. Tampouco se deve aumentar a força indiscriminadamente: isso pode conservar justamente a arma torta que se deseja corrigir.

A escolha deve considerar a tarefa: ideia inicial, mudança de forma ou refinamento de uma região quase pronta. Os valores só fazem sentido nos modelos que oferecem esse parâmetro. Não inventar equivalência numérica para outro backend.

### 9.4 Recuperação de grade e redução de cores

O [Unzoom do PixelLab](https://www.pixellab.ai/docs/tools/unzoom-pixelart) trata recuperação de escala de pixel art ampliada. O [Reduce Colors](https://www.pixellab.ai/docs/tools/reduce-colors) trata quantização. Nenhuma dessas finalidades equivale a corrigir a anatomia de uma espada.

A Forja já possui operações locais nessas áreas. Antes de substituí-las, comparar qualidade, custo, preservação de regiões e erros sobre o mesmo conjunto de entrada. A prioridade atual é controle funcional, não duplicar ferramentas de conversão existentes.

### 9.5 Pro Flash e PixMiniMax: atualização verificada em 25/10

A [página oficial da API](https://www.pixellab.ai/pixellab-api) documenta edição e inpainting Pro Flash entre 32 e 256 px por lado, em incrementos de quatro, preservando o canvas. O inpainting declara preservação dos pixels externos. Assim, 64×64 e 80×80 cabem nesses limites; isso torna a operação candidata ao reparo dos personagens atuais. É compatibilidade documentada, não qualidade demonstrada nesta pesquisa.

Comparar `inpaint-v3` e `inpaint-image-pro-flash` com a mesma fonte, máscara e objetivo. Medir construção da arma, preservação de identidade, pixels externos alterados e esforço de limpeza. Manter a recomposição local da Forja: o verificador deve confirmar a garantia no arquivo entregue, inclusive depois de quantização e contorno.

PixMiniMax admite 4–40 frames, em múltiplos de quatro, com tamanho máximo de 256×256 e quadro final opcional. Isso não coincide diretamente com `idle` de seis, `attack` de cinco ou `die` de sete frames do Empire. O adaptador precisa de uma decisão explícita sobre seleção e tempo; cortar frames automaticamente pode remover antecipação, impacto ou recuperação. Uma operação compatível com a contagem exata pode ser melhor. Verificar também o encontro entre último e primeiro frame de loops.

O OpenAPI foi consultado novamente em 25/10, SHA-256 `9009818a8750bfa4fb23f4371e093458b01358fafbc7a8fc59bb91bac876919b`. Nele, Pro Flash exige `crop_to_mask: true`; PixMiniMax separa `direction`, `view`, `subject_description` e `initial_pose`, e pode devolver `enhanced_prompt`. Usar esses campos conforme o contrato da operação, conservando uma validação independente do texto expandido. Não presumir que a interface de um tutorial antigo representa o comportamento atual da API.

## 10. Plano de implementação para o Claude

Os nomes de módulos abaixo são sugestões. Nenhuma mudança foi implementada nesta pesquisa. Respeitar o limite de 250 linhas por script e a exigência de ADR para novas dependências.

| Prioridade / ticket proposto | Entrega concreta | Arquivos a considerar | Evidência de conclusão |
|---|---|---|---|
| P0-1 — Vereditos explícitos | Separar raster, equipamento, pose, identidade e aprovação | `review.py`, `auto.py`, exportação de relatórios | Casos sem avaliação semântica exibem “não avaliado”, nunca “aprovado” |
| P0-2 — Manifesto de equipamento | Esquema auxiliar com objetos, partes, contatos, estados e referências | Novo módulo pequeno de contrato; integração com `plan.py` | Espada/arco/escudo descritos sem inventar dados de gameplay |
| P0-3 — Prova estática de geometria | Anotação de máscaras/âncoras e verificações simples | Novo módulo de geometria e fixtures | Lâmina bifurcada, guarda duplicada e arma ausente são sinalizadas; diagonal válida não é rejeitada |
| P0-4 — Proteção do reparo | Máscara arbitrária, regiões protegidas, método de composição e recomposição local | `inpaint.py` e módulo de máscaras | Exterior idêntico; substituição não mantém a arma antiga por baixo |
| P0-5 — Linhas finas e vazios | Proteção de corda, correias e espaços entre partes | `pipeline.py`, `outline.py`, `lint.py` | Os probes de linha e vazio não sofrem alteração quando protegidos |
| P0-6 — Pedido sem contradições | Câmera única, inventário, papel das referências e revisão do texto expandido; correção de zero em força | `prompts.py`, `plan.py` | Contradição de câmera/direção é detectada; zero explícito permanece zero |
| P1-1 — Operações PixelLab | Adaptador de inpainting primeiro; demais operações conforme necessidade | `backends/`, registro de capacidades e jobs | Fixtures de request/response, falhas controladas e uma prova pequena autorizada |
| P1-2 — Poses e objetos no tempo | Identidade de equipamento, contatos e oclusões por frame | `review.py`, módulos de análise temporal | Nenhuma troca indevida de mão, objeto perdido ou frame extra silencioso |
| P1-3 — Material e cor | Rampas por material sem alterar a paleta mestra | `quantize.py`, metadados de regiões | Vinho não muda para couro por simples proximidade sem aviso; contraste preservado |
| P2 — Biblioteca reutilizável | Armas e equipamentos aceitos, guias de pose e exemplos negativos | Diretório de referências e manifesto | Cada referência tem origem, escala, estado e aprovação identificados |

**Primeiro incremento recomendado:** P0-1 a P0-4 sobre um único caso, a corda e a empunhadura do arqueiro. Em seguida, espada do rei e escudo do escudeiro. Isso testa o fluxo completo antes de criar dezenas de opções novas.

Não instalar todo o conjunto de operações PixelLab antes de demonstrar que a Forja consegue reconhecer, reparar e revisar um defeito. A correção de um objeto pequeno fornece uma prova mais útil do que uma grande galeria sem critérios.

## 11. Benchmark e critérios de aceitação

### 11.1 Conjunto inicial proposto

Montar um conjunto pequeno, versionado, com os três personagens atuais, referências aceitas e variantes negativas controladas. Incluir ao menos estas famílias de erro:

| Família | Casos negativos | Controle positivo necessário |
|---|---|---|
| Lâmina | Bifurcação, eixo quebrado, ponta duplicada | Espada diagonal com escada raster regular |
| Empunhadura | Guarda extra, mão sobre lâmina, punho desconectado | Punho parcialmente oculto pela mão |
| Arco | Segunda corda, ligação errada, corda larga, flecha confundida com corda | Arco curvo válido e corda parcialmente oculta |
| Escudo | Mão na face errada, pega flutuante, decoração deslocada | Verso oculto por perspectiva |
| Armazenamento | Correia solta, bolsa duplicada, volume incompatível | Correia que passa legitimamente atrás do torso |
| Animação | Arma troca de mão, peça desaparece, comprimento oscila | Espelhamento permitido pelo contrato do Empire |
| Processamento | Contorno fecha vazio; quantização apaga separação; overlay conserva a arma substituída | Linha fina intencional, contraste de material aprovado, adição legítima de camada |

As primeiras fixtures sintéticas deste relatório são um começo, não um benchmark representativo. Separar exemplos usados para calibrar tolerâncias de exemplos reservados para avaliação.

### 11.2 Medidas que importam

- Defeitos críticos corretamente detectados e defeitos críticos que escaparam.
- Falsos alarmes sobre diagonais, curvas intencionais, oclusões e espelhamento permitido.
- Quantidade de pixels alterados fora da região autorizada: objetivo zero para reparo localizado.
- Regiões aprovadas que regrediram após reparo ou quantização.
- Tempo de correção humana e número de chamadas pagas por asset aceito.
- Consistência de tamanho, identidade e contatos nos frames finais.
- Aprovação visual a 1× e no contexto do elenco, registrada separadamente.

Um número como “90% pronto” citado num tutorial não é uma métrica de aceitação para o Empire. Medir o próprio fluxo com os próprios personagens.

### 11.3 Portões para declarar uma entrega concluída

1. Fonte e contrato de intenção preservados.
2. Raster validado e nenhuma redução/corte silencioso.
3. Inventário e construção dos equipamentos revisados; inconclusões explicitadas.
4. Contatos e estados visuais coerentes.
5. Regiões protegidas preservadas após o acabamento.
6. Poses e frames finais respeitando o contrato do projeto.
7. Revisão artística feita pelo autor ou mantida claramente pendente.
8. Integração na engine testada apenas quando efetivamente realizada.

## 12. Instrução pronta para entregar ao Claude

O texto abaixo pode iniciar a próxima tarefa de implementação. Ele não afirma que as propostas já estejam aprovadas como novas regras de arte ou gameplay.

> Leia `AGENTS.md`, `docs/art/CHARACTER_PRODUCTION_GUIDE.md`, `docs/art/REFERENCE_AUTHORITY.md`, `docs/art/ASSET_BIBLE.md`, `docs/art/ANIMATION_BIBLE.md` e `docs/art/FORJA.md`. Use o relatório “Forja: armas, equipamentos e consistência visual”, revisado em 25/10/2026, como diagnóstico e proposta de implementação.
>
> O problema prioritário é que a Forja valida o raster, mas não a construção e o uso visual de armas/equipamentos. Não considere uma imagem aprovada só porque o lint passou. Preserve os controles existentes de grade, jobs, custos, proveniência, máscara externa e aprovação artística.
>
> Comece por uma prova pequena: arqueiro, uma pose estática, arco/corda/empunhadura. Separe intenção, observação e veredito. Crie um contrato auxiliar de equipamentos com partes, instâncias, contatos, oclusão e estado; não confunda esse contrato com um detector de imagem. Onde faltar evidência confiável, retorne “não avaliado” ou “inconclusivo”.
>
> Acrescente vereditos independentes para raster, geometria, função visual, identidade, temporalidade, aprovação artística e integração. Estenda o reparo existente para máscara arbitrária e recomposição local, verificando que os pixels protegidos continuem idênticos depois de todas as operações. Proteja cordas e vazios contra contorno global.
>
> Reproduza os casos negativos do pacote: lâmina bifurcada, guarda duplicada e ausência de arma passam no lint atual. Crie testes de comportamento que passem a detectar essas falhas quando houver observações válidas, mantendo controles positivos para diagonal raster, oclusão e curvatura intencional. Corrija também `init_strength or 300` para preservar zero explícito.
>
> Se integrar PixelLab, use a especificação atual da operação, não limites copiados da interface de um vídeo. Comece pelo inpainting, com tradução explícita da máscara e controle de jobs. Verifique tamanho, contagem real de frames e retorno assíncrono. Não repita POST pago em caso de resultado desconhecido.
>
> Diferencie adicionar, substituir e remover na composição: uma camada nova não pode deixar a arma antiga visível por baixo. Registre e valide o prompt expandido contra câmera, direção, inventário e estado. Compare inpainting V3 e Pro Flash sobre o mesmo caso antes de escolher; não transforme a recomendação recente de Skeleton V3 em aprovação automática. PixMiniMax gera múltiplos de quatro frames, portanto não adapte às tags do Empire por corte silencioso.
>
> Respeite slots, pivôs, tags, eventos e espelhamento já decididos no Empire. `socket_weapon` não é automaticamente o ponto de pega. Não crie mecânicas de munição, capacidades de bolsas ou estados de gameplay a partir de inferências visuais. Observe os campos `_proposed` do CSV de armazenamento.
>
> Entregue o primeiro incremento com diff pequeno, testes adequados, antes/depois a 1× e ampliado, máscaras e âncoras visíveis, custo/tentativas e falhas restantes. Só amplie para espada do rei, escudo e animações depois de a prova mostrar melhora funcional sem regressão de identidade. Mudanças de paleta, contorno ou contratos artísticos precisam conservar seu estado de proposta até decisão do autor.

## 13. Fontes de apoio e rastreabilidade

Os links dos treze vídeos e os tempos de interesse estão na seção 4. A pesquisa foi realizada em 24–25/10/2026. O código e os três personagens correspondem ao snapshot auditado em 24/10; a revisão de 25/10 amplia as fontes PixelLab, sem presumir um novo estado da produção. Limites de produto e nomes de operações podem mudar.

### PixelLab — documentação primária

- [Índice da documentação](https://www.pixellab.ai/docs).
- [Imagens iniciais e inpainting: guia](https://www.pixellab.ai/docs/getting-started).
- [Opções de imagem inicial](https://www.pixellab.ai/docs/options/init-image).
- [Convenção de inpainting no editor](https://www.pixellab.ai/docs/options/inpainting).
- [Inpaint v3](https://www.pixellab.ai/docs/tools/inpaint-v3).
- [Referências de estilo](https://www.pixellab.ai/docs/tools/consistent-style).
- [Animação com esqueleto](https://www.pixellab.ai/docs/tools/animate-with-skeleton).
- [Animation to animation](https://www.pixellab.ai/docs/tools/animation-to-animation).
- [Edição de animação](https://www.pixellab.ai/docs/tools/edit-animation-pro).
- [Transferência de roupa](https://www.pixellab.ai/docs/tools/transfer-outfit-pro).
- [Redução de cores](https://www.pixellab.ai/docs/tools/reduce-colors).
- [Unzoom](https://www.pixellab.ai/docs/tools/unzoom-pixelart).
- [API v2](https://api.pixellab.ai/v2/docs) e [especificação legível por máquina](https://api.pixellab.ai/v2/openapi.json).
- [Catálogo oficial de operações da API, incluindo Pro Flash e PixMiniMax](https://www.pixellab.ai/pixellab-api).

### Construção de objetos — referências primárias

- [Met: espada de duas mãos, ca. 1400–1450](https://www.metmuseum.org/art/collection/search/35388), para distinguir partes; não usar como escala do rei.
- [World Archery: barebow](https://www.worldarchery.sport/sport/equipment/barebow), para relações entre empunhadura, membros e corda.
- [World Archery: diagrama do arco recurvo](https://extranet.worldarchery.sport/documents/index.php/Media/Information_Sheets/002_The_Recurve_Bow.pdf), com acessórios modernos que devem ser filtrados pelo contexto do jogo.
- [Met: pega de escudo](https://www.metmuseum.org/art/collection/search/22636), para montagem interior.
- [Worcester Art Museum: dhal](https://worcester.emuseum.com/objects/49827/dhal-shield), para exemplo de correias traseiras; não é modelo histórico imposto ao escudeiro.

### Empire — autoridade interna

- [Contrato do agente](https://github.com/henriquecoding/empire/blob/4471cde384c94e8833e4e61347551ac8c69320b0/AGENTS.md).
- [Guia de produção](https://github.com/henriquecoding/empire/blob/4471cde384c94e8833e4e61347551ac8c69320b0/docs/art/CHARACTER_PRODUCTION_GUIDE.md).
- [Asset Bible](https://github.com/henriquecoding/empire/blob/4471cde384c94e8833e4e61347551ac8c69320b0/docs/art/ASSET_BIBLE.md).
- [Animation Bible](https://github.com/henriquecoding/empire/blob/4471cde384c94e8833e4e61347551ac8c69320b0/docs/art/ANIMATION_BIBLE.md).
- [Código da Forja](https://github.com/henriquecoding/empire/tree/4471cde384c94e8833e4e61347551ac8c69320b0/tools/forja).
- [Dados de armazenamento e estado de proposta](https://github.com/henriquecoding/empire/blob/4471cde384c94e8833e4e61347551ac8c69320b0/data/source/storages.csv).

O resultado desta pesquisa é um plano verificável para refinar a Forja. Não é uma nova aprovação dos personagens, uma avaliação de geração real do PixelLab, nem uma alteração já publicada.
