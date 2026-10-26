# PixelLab — dossiê de vídeos, cobertura e fichamentos

**Pesquisa para o Claude / Forja Empire · 25/10/2026 · data de referência: Lisboa**

## 1. Cobertura verificável

Inventário público do canal [@pixellab_ai](https://www.youtube.com/@pixellab_ai): **200 itens únicos**, nas abas Vídeos, Shorts e Live. A paginação das três abas foi percorrida até o fim: 3, 3 e 1 páginas, respectivamente. O universo é o conteúdo público exposto nessas abas na coleta; não inclui vídeos privados, excluídos, não listados ou exclusivos não expostos.

| Seção pública | Itens | Legendas obtidas | Dessas, muito breves | Sem transcrição no exportador |
|---|---:|---:|---:|---:|
| Vídeos | 90 | 77 | 3 | 13 |
| Shorts | 105 | 98 | 17 | 7 |
| Lives arquivadas | 5 | 5 | 0 | 0 |

**Resultado: 180 arquivos de legenda obtidos; 20 itens sem texto de transcrição utilizável retornado pelo exportador; 0 itens ainda não verificados.** Das legendas obtidas, 20 têm menos de 25 palavras depois de remover marcações entre colchetes. Esse é um sinal de texto muito escasso, não uma classificação definitiva do áudio.

Há **40 fichamentos originais selecionados: 35 de vídeos/Shorts e 5 recortes temáticos das lives**, baseados nas legendas. As lives não foram lidas integralmente; foram pesquisadas por termos e conferidas nas passagens indicadas. A recuperação de um arquivo não significa que o vídeo inteiro foi assistido, que todo o áudio foi ouvido ou que cada quadro foi inspecionado. Os demais itens ficam documentados na matriz, sem resumo inventado a partir do título.

### Método e limites

- A coleta usou o exportador público de transcrição do YouTube; os 23 itens inicialmente sem legenda foram verificados uma segunda vez e validou o ID no cabeçalho de cada arquivo. As primeiras tentativas por outros endpoints falharam; o estado final positivo de exportação prevalece sobre esses erros anteriores.
- São legendas automáticas, em inglês e português, sujeitas a erros em nomes de ferramentas, números e palavras técnicas. O idioma corresponde à faixa devolvida; não foi certificada a língua original da gravação nem a origem de eventual dublagem.
- A última marca é o **início do último segmento de legenda**, não o fim do áudio nem prova de cobertura integral. Silêncios, músicas, trechos sem fala e segmentos perdidos não foram auditados pelo áudio.
- “Sem transcrição no exportador” registra a resposta obtida, não afirma que o vídeo não contenha fala. Não foi realizado ASR independente dos itens sem legenda.
- Os tempos dos fichamentos permitem voltar à fonte. Quando um fichamento só contextualiza o fluxo, isso está indicado; não se fabricou minuto exato.
- O vidIQ foi conectado e seu saldo consultado. A coleta pública não consumiu créditos pagos do plugin. Não houve geração paga de arte.
- A entrega contém sínteses originais, análise e referências. Não reproduz integralmente as falas de vídeos de terceiros protegidos por direitos autorais. Portanto, o pedido de transcrição integral de todos os vídeos **não está atendido**.

## 2. Como o Claude deve usar este material

Começar pelo relatório técnico `Relatorio-Forja-Pixels-Cores-Claude-2026-10-25.md` e pelas provas locais. Usar os fichamentos abaixo para conferir fundamentos e limitações das ferramentas, não como especificação oculta da arquitetura da PixelLab. Conferir a documentação atual antes de transpor um parâmetro antigo.

Prioridade temática: Reduce Colors; referência consistente; Inpaint/Edit; estados e skeleton; interpolação e efeitos; mapas e escala. Shorts que reapresentam o mesmo recurso são material de navegação, não estudos independentes de eficácia.

## 3. Fichamentos originais

As aplicações à Forja são propostas desta pesquisa. Não são promessas dos apresentadores nem mudanças já implementadas.

### F01 — PixelLab Tutorial: How to Reduce Colors Like a Pro!

Fonte: [WSbBuAwRm18](https://www.youtube.com/watch?v=WSbBuAwRm18) · Vídeos · legenda: pt-BR.

**Localização:** 1:13–3:17; 4:39–5:14; 5:16–7:00.

**Síntese:** O tutorial estabelece a paleta do personagem antes de criar estados e animações. Recomenda corrigir pixels indesejados e detalhes confusos antes da redução; usa uma camada nova para comparar com o original. Aplica a paleta escolhida às oito direções e, depois, a todos os frames de cada animação. Estende o mesmo procedimento à interface, aos tiles e aos objetos.

**Aplicação à Forja:** Separar limpeza estrutural, normalização cromática e revisão final. Uma paleta comum impede tons extras, mas não prova que cada cluster esteja bem desenhado.

### F02 — PixelLab Tutorial: Create Image from Style Reference(Pro)

Fonte: [tx-JUE8KbJM](https://www.youtube.com/watch?v=tx-JUE8KbJM) · Vídeos · legenda: pt-BR.

**Localização:** 0:58–3:38; 4:48–6:25.

**Síntese:** Usa um personagem como referência para variações e para ampliar o elenco. Seleciona resultados aproveitáveis e acrescenta referências de estilo; repete o procedimento com retratos, frutas, alimentos e edifícios. A quantidade de saídas varia com o canvas apresentado. Destaca cores, sombreamento, contorno e linguagem de formas como sinais oferecidos pelas referências.

**Aplicação à Forja:** Curar as referências antes de reutilizá-las. Não promover automaticamente cada geração a referência, porque isso pode perpetuar ruído. Os números de saídas demonstrados pertencem à versão da aula.

### F03 — Make infinite characters in the SAME style!

Fonte: [LcJQQwltQ2Q](https://www.youtube.com/watch?v=LcJQQwltQ2Q) · Vídeos · legenda: en.

**Localização:** 1:05–1:37; 2:38–2:52; 5:05–6:42; 8:07–9:44.

**Síntese:** A limpeza aparece após gerar rotações, após criar novos personagens, antes de animar cada estado e antes de espelhar. O apresentador reconhece artefatos e pixels dispersos. Recorta a referência perto do personagem para o próximo instrumento. Distingue ciclos de ações únicas ao configurar o frame inicial e relata mais correção manual em certas direções.

**Aplicação à Forja:** Criar pontos de revisão antes de operações que multiplicam um defeito. O recorte de referência precisa preservar escala e pivô conhecidos. Uma recomendação histórica de modelo não substitui comparação atual.

### F04 — Tutorial: Make a Full Game Character in PixelLab (Idle, Walk, Attacks, States)

Fonte: [zqZiQBS3LX0](https://www.youtube.com/watch?v=zqZiQBS3LX0) · Vídeos · legenda: pt.

**Localização:** 6:38–7:21; 8:08–11:32; 12:09–15:42.

**Síntese:** Na reação a golpe, remove pontos dispersos, recompõe contornos e reaproveita a cor do cabelo. Usa frames inicial e final, reenquadramento e linha do chão para conectar queda e recuperação. Mostra um bastão na mão errada e uma manga assimétrica cuja cor se perde numa direção; explica por que não espelhar esses casos.

**Aplicação à Forja:** Reparo deve contemplar remover, preencher e reconstruir contorno. Proteger lateralidade e identidade material entre direções. A própria aula relata exceções à alegação de preservação do Skeleton V3; não tratá-la como garantia absoluta.

### F05 — How to Use the PixelLab VFX Creator

Fonte: [VxAHJvcJr_Y](https://www.youtube.com/watch?v=VxAHJvcJr_Y) · Vídeos · legenda: pt.

**Localização:** 2:37–3:52; 5:05–5:49; 6:45–7:15; 8:42–10:26.

**Síntese:** O criador de VFX permite ajustar cores, contorno, faixas de sombra, quantidade de cores e dithering. Organiza camadas atrás e à frente do personagem, compara fundos claros e escuros e sincroniza impactos com poses. Mostra iluminação móvel do sprite, exportação com manifesto e correção de uma fumaça que apareceu no momento inadequado.

**Aplicação à Forja:** Definir contratos próprios para efeitos e iluminação. Mudança de brilho, partículas e dispersão podem ser intencionais; não usar a mesma política de limpeza aplicada ao corpo estável do personagem.

### F06 — PixelLab Pro Tilesets: Full Guide (Sizes, Styles, Height & Diagonals)

Fonte: [MbkqpDUFkEg](https://www.youtube.com/watch?v=MbkqpDUFkEg) · Vídeos · legenda: pt.

**Localização:** 0:54–1:16; 2:55–4:06; 7:25–9:17; 9:22–10:46.

**Síntese:** Compara tamanhos e palavras de estilo. Recomenda descrições curtas de material e relata que a palavra textura reduz adereços indesejados nos exemplos. Conecta tilesets por terrenos compartilhados, corrige uma pedra manualmente e demonstra a opção de união de cantos diagonais. Um exemplo de mapa desloca um caminho após detectar uma borda preta.

**Aplicação à Forja:** Auditar continuidade de bordas no mapa montado, inclusive diagonais e encontros entre conjuntos. Reposicionar o mapa é um contorno do problema demonstrado, não prova de que o tile foi corrigido. Testar alterações de prompt isoladamente.

### F07 — How to Make Animated Pixel Art VFX in PixelLab

Fonte: [t8FIMv-8QpI](https://www.youtube.com/watch?v=t8FIMv-8QpI) · Vídeos · legenda: pt.

**Localização:** 2:18–2:46; 5:07–6:14; 7:40–7:46; 9:22–9:33; 11:10–11:15.

**Síntese:** Relata cintilação de cores e a corrige entre frames; limpa pixels verdes de um portal quadro a quadro. Alinha animações antes de uni-las e usa poucos pixels azuis como início intencional de um efeito de gelo. Remove um frame final com deslocamento e distingue expansão do texto da opção de aprimoramento durante a geração.

**Aplicação à Forja:** Os pixels pequenos do nascimento do gelo são um controle positivo para o detector. O descarte de frames mostrado exige revisar duração e eventos no jogo; não deve virar limpeza automática. Diferenciar cor instável de energia e partículas planejadas.

### F08 — The Ultimate PixelLab Inpainting Guide for Creator

Fonte: [9eAlZlQmZBg](https://www.youtube.com/watch?v=9eAlZlQmZBg) · Vídeos · legenda: pt-BR.

**Localização:** 1:34–2:33; 4:13–5:04; 5:26–6:55.

**Síntese:** Distingue acrescentar conteúdo em camada de substituir ou remover parte do original. Relata alterações externas à máscara e apresenta o recorte à máscara para restringir a edição. Na expansão de cenário, seleciona uma região compatível com o limite do modelo e mantém parte da imagem existente como contexto. Recomenda revisar pixels, perspectiva e cores após gerar.

**Aplicação à Forja:** A máscara deve governar a composição achatada. Acrescentar uma camada não remove pixels antigos. Validar a preservação fora da região editável até o fim do acabamento.

### F09 — How to Use Animate with Text in PixelLab

Fonte: [j2bE9gq914U](https://www.youtube.com/watch?v=j2bE9gq914U) · Vídeos · legenda: pt-BR.

**Localização:** 1:15–2:15; 3:48–4:37; 7:25–9:36; 10:13–12:19.

**Síntese:** Relaciona a pose inicial à ação solicitada. Na fogueira, propõe copiar a madeira do primeiro frame quando ela deve ficar imóvel, mas reconhece que variação luminosa também pode ser desejada. Explica transições com dois frames, encadeamento pelo frame final e ciclos ancorados na mesma pose.

**Aplicação à Forja:** Usar estabilização apenas em regiões explicitamente estáticas. Registrar intenção de iluminação e de movimento; um piscar deliberado ou uma transformação não pode ser removido por votação temporal.

### F10 — PixelLab Tutorial: Images Pro Flash, Skeleton V3 & PixMiniMax

Fonte: [Y68m9k60Lg0](https://www.youtube.com/watch?v=Y68m9k60Lg0) · Vídeos · legenda: pt-BR.

**Localização:** 5:35–7:17; 9:16–10:11; 10:34–13:23; 15:47–16:36.

**Síntese:** Apresenta Pro Flash, Skeleton V3 e PixMiniMax. Corrige máscara insuficiente ao criar roupa. A recomendação de animação muda com a atualização do modelo. O texto expandido para uma direção entra em conflito com outras; efeitos também trocam de cor. O apresentador ajusta orientação e cor, regenera algumas direções e revisa o conjunto. Usa a mesma imagem nas extremidades de um ciclo.

**Aplicação à Forja:** Guardar versão do modelo e prompt efetivamente enviado por direção. Não reutilizar texto expandido sem conferir orientação. Referência e promessa de consistência não substituem inspeção cromática final.

### F11 — Build a Complete RPG UI Set with PixelLab AI

Fonte: [BdoUMKhZ1Ys](https://www.youtube.com/watch?v=BdoUMKhZ1Ys) · Vídeos · legenda: en.

**Localização:** 1:34–2:30; 2:42–3:40; 3:44–4:33.

**Síntese:** Organiza o layout de interface, corrige limites antes de separar elementos e configura nine-slice manualmente para preservar bordas. Abre o editor para remover pixels dispersos e cria estados de barra. Reutiliza um botão como referência de estilo para itens de inventário.

**Aplicação à Forja:** Separação, estados e redimensionamento precisam de validação própria. Limpar bordas antes de multiplicá-las no nine-slice; avaliar a leitura dos ícones na interface final.

### F12 — PixelLab Tutorial: Create Image(Pro)

Fonte: [OHrdbkpmcHE](https://www.youtube.com/watch?v=OHrdbkpmcHE) · Vídeos · legenda: pt-BR.

**Localização:** 0:51–1:42; 2:09–2:24; 4:29–5:33; 6:29–7:41.

**Síntese:** Diferencia referência de conceito, que orienta assunto, de referência de estilo em pixel art na escala aceita. Combina ambas para produzir poses e famílias de personagens. As opções de estilo abrangem paleta, contorno, detalhe e sombreamento. Reconhece que as saídas ainda precisam de limpeza e refinamento.

**Aplicação à Forja:** Separar os papéis das imagens de entrada no manifesto e registrar sua escala. Não confundir uma referência conceitual de alta resolução com uma amostra nativa de clusters aprovados.

### F13 — Level Up Your Game: Custom Sprite Animation Tutorial

Fonte: [r8ySiSRRvz4](https://www.youtube.com/watch?v=r8ySiSRRvz4) · Vídeos · legenda: pt-BR.

**Localização:** 3:11–3:49; 9:54.

**Síntese:** A aula corrige a face copiando uma versão limpa e alinhando-a aos frames. Um disparo esbarra no limite do canvas: o problema requer espaço para a ação. Parte de poses-chave e depois interpola; ao final, considera a resposta da animação dentro do jogo.

**Aplicação à Forja:** Tratar posicionamento, margem e identidade antes do acabamento; copiar detalhes somente quando pose e expressão permitirem.

### F14 — How to Make a Full Side-Scroller Asset Pack with PixelLab

Fonte: [o8AZRTx36DE](https://www.youtube.com/watch?v=o8AZRTx36DE) · Vídeos · legenda: en.

**Localização:** 0:52–2:14; 2:39–4:46; 7:38–10:07; 10:42–10:59.

**Síntese:** Limpa pontos antes de animar, acrescenta margem e realinha uma cabeça instável. Seleciona frames para responder melhor no jogo. Usa personagem e chão como contexto do cenário, testa repetição horizontal e separa camadas para paralaxe. Uma cópia indesejada do personagem no fundo exige novo reparo.

**Aplicação à Forja:** Validar escala útil, espaço para ação, ritmo e emendas. Extrair camadas ou pedir preservação não garante composição correta; inspecionar o resultado achatado e o mapa em movimento.

### F15 — PixelLab Tutorial: How to Generate & Animate GBA-Style Sprites

Fonte: [moCpjMOOBGk](https://www.youtube.com/watch?v=moCpjMOOBGk) · Vídeos · legenda: en.

**Localização:** 0:54; 2:36; 6:10; 8:32; 11:57.

**Síntese:** Recomenda limpar as rotações antes de animar, observa contorno duplicado e inconsistências de escala dos pixels. Expõe limitações dos templates usados para objetos nas mãos. Distingue o tamanho do canvas do tamanho útil do personagem e limpa uma flecha antes de gerar rotações.

**Aplicação à Forja:** Registrar resolução útil e função dos equipamentos. Limpar e aprovar referências antes de propagá-las.

### F16 — PixelLab Character States: The New Way to Animate Sprites

Fonte: [oCJWxfEwX-o](https://www.youtube.com/watch?v=oCJWxfEwX-o) · Vídeos · legenda: en.

**Localização:** 4:07; 5:05; 8:04.

**Síntese:** O fluxo de estados permite preparar variações antes de animar. O apresentador corrige mudanças na boca e ressalta que espelhar depende da simetria do personagem. Uma direção incompleta permanece como parte da demonstração.

**Aplicação à Forja:** Uma boca que muda pode ser ruído ou expressão necessária. Não transformar exemplos inacabados em referência aprovada.

### F17 — How to Generate Consistent Pixel Art for Games

Fonte: [nITrIQw1gag](https://www.youtube.com/watch?v=nITrIQw1gag) · Vídeos · legenda: en.

**Localização:** 1:42–2:21.

**Síntese:** Defende referências semelhantes em densidade de pixels, contorno, sombreamento e proporção. Prefere um pequeno conjunto coerente a muitas imagens heterogêneas; a quantidade citada é orientação prática da aula, não limite universal validado.

**Aplicação à Forja:** Criar famílias de referência compatíveis com os contratos 64/80 e com a paleta existente.

### F18 — Building a Cohesive Game Art Style Using PixelLab

Fonte: [7HTLYLo3tTQ](https://www.youtube.com/watch?v=7HTLYLo3tTQ) · Vídeos · legenda: en.

**Localização:** 1:18–2:12; 2:38–3:14.

**Síntese:** Parte de uma referência visual para desenvolver um elenco e usa animação por texto para ações sem templates adequados. Estende regras visuais à interface e ao cenário; o fundo maior recebe inpainting. A afirmação de ausência de deriva é a avaliação do apresentador, não uma medição independente.

**Aplicação à Forja:** Manter uma referência aprovada como âncora, revisando cada nova família. O motor e o agente de código usados no exemplo não garantem qualidade dos pixels.

### F19 — Tutorial: How to use the Edit tool

Fonte: [XhmpenTmPLg](https://www.youtube.com/watch?v=XhmpenTmPLg) · Vídeos · legenda: en.

**Localização:** 0:59–1:45; 3:26–3:37; 5:54–6:24; 9:27–9:47.

**Síntese:** Pede instruções de mudança explícitas e recomenda edições pequenas e iterativas. Usa redução de cores para alguns artefatos. Registra limites da versão demonstrada em imagens pequenas: mudar cor pode funcionar melhor que acrescentar objetos.

**Aplicação à Forja:** O adaptador de Edit deve descrever a mudança; o de Inpaint deve seguir o contrato específico. Checar identidade, composição e pixels externos após cada operação, sem transportar limitações antigas como fatos atuais.

### F20 — How to Make Walking Animations for Pixel Art Characters in PixelLab

Fonte: [8TRHAC3fUpo](https://www.youtube.com/watch?v=8TRHAC3fUpo) · Vídeos · legenda: en.

**Localização:** 1:39–2:35; 3:19–3:37; 6:07–7:18; 8:35–8:42.

**Síntese:** Compara caminhada pelo criador, skeleton e transferência de animação. Corrige cabeça, cor dos olhos e mochila que muda de forma. Cada frame aceito pode alimentar a geração seguinte; referências sujas podem propagar inconsistência. Espelhar depende de simetria.

**Aplicação à Forja:** Aprovar o frame antes de reutilizá-lo como contexto. Preservar expressão e deslocamento ao copiar uma região; não congelar indiscriminadamente a cabeça.

### F21 — New PixelLab Tool: Animate Between 2 Frames

Fonte: [1CjxHZoZE_I](https://www.youtube.com/watch?v=1CjxHZoZE_I) · Vídeos · legenda: en.

**Localização:** 3:14–3:19; 5:35–6:18; 7:14–7:30; 8:28–8:57.

**Síntese:** Interpola entre imagens inicial e final, corrige um detalhe desaparecido e comenta um frame parado e uma boca que se move sem intenção. Mostra redução de cores depois da animação e edição de duração/quantidade de frames.

**Aplicação à Forja:** Checar eventos, loop e intenção da boca separadamente da estabilidade cromática. Remover um frame muda o ritmo e requer revisão; elogios percentuais do apresentador não são métricas de qualidade.

### F22 — Tutorial: Animation to animation with PixelLab

Fonte: [owkamgYVWAs](https://www.youtube.com/watch?v=owkamgYVWAs) · Vídeos · legenda: en.

**Localização:** 0:30–1:40; 2:19–2:28; 4:09–4:17.

**Síntese:** Explica transferência de animação, controles de câmera, detalhe, sombreamento, paleta e referência. Uma geração aceita vira referência das seguintes; a aula reconhece a necessidade de limpeza manual.

**Aplicação à Forja:** Não tratar a estimativa promocional de progresso como medição. Aprovar referência e movimento antes de gerar o restante.

### F23 — Tutorial: Learn how to animate, rotate and inpaint your character

Fonte: [hOZzbQBjKPc](https://www.youtube.com/watch?v=hOZzbQBjKPc) · Vídeos · legenda: en.

**Localização:** 1:50–2:24; 7:59–8:24; 9:24–11:32; 13:10–13:25.

**Síntese:** Combina redução de cores, rotação, skeleton e edição. Recomenda limpar frames antes de usá-los como contexto. Corrige mão e braço em ordem errada por inpainting e imagem inicial; reconhece mudanças de cor ainda presentes.

**Aplicação à Forja:** Avaliar oclusão e movimento antes da correção cromática. O conselho antigo sobre forçar pontos da cabeça depende da versão e não deve sobrepor instruções recentes sem teste.

### F24 — Tutorial: Using inpainting to create style consistent characters

Fonte: [68BYzLoLh-U](https://www.youtube.com/watch?v=68BYzLoLh-U) · Vídeos · legenda: en.

**Localização:** 0:37–1:17; 2:05–3:13; 4:13–4:56; 7:01–8:47.

**Síntese:** Limpa o sprite e reduz cores próximas. Usa áreas visíveis como contexto de estilo, observa reutilização de cores e relaciona o tamanho da máscara ao volume do elemento gerado. Esboça espada e escudo antes do inpainting e revisa o resultado manualmente.

**Aplicação à Forja:** Distinguir instrução para Inpaint daquela para Edit. O contexto de cor ajuda, mas não é garantia de paleta nem de equipamento funcional.

### F25 — Pixellab Tutorial: Tilesets (Isometric/Hexagonal/Oblique/Square Topdown)

Fonte: [sE1s5ZYfxqk](https://www.youtube.com/watch?v=sE1s5ZYfxqk) · Vídeos · legenda: pt-BR.

**Localização:** 0:29–1:35; 3:04–4:17; 7:15–7:33.

**Síntese:** Gera transições de terreno com controles de projeção, tamanho e contorno. Depois do inpainting das escadas, remove pixels indesejados e ajusta bordas para conexão com o terreno. Auto-tiling seleciona peças; a revisão pode exigir seleção manual.

**Aplicação à Forja:** Testar o mapa composto, as emendas e a perspectiva. Escolha correta de tile e correção dos pixels na borda são problemas distintos.

### F26 — Tutorial: How to animate pixel art using a skeleton

Fonte: [zBfVT5pwCSs](https://www.youtube.com/watch?v=zBfVT5pwCSs) · Vídeos · legenda: en.

**Localização:** 6:39–7:57; 8:09–11:16; 13:41–18:17; 23:07–23:25.

**Síntese:** Corrige um frame específico e usa máscaras para preservar outros. Limpa pequenos pixels antes de continuar a geração. A falta de uma mão exige rever pose, posição, imagem inicial e visibilidade das camadas; uma restrição de pose pode conflitar com o esboço.

**Aplicação à Forja:** Validar camadas, frames de contexto e coordenadas antes de culpar o modelo. Parâmetros numéricos antigos de força não devem ser transportados automaticamente para versões atuais.

### F27 — Pixelorama + PixelLab: Create, Edit, Rotate, and Animate Pixel Art

Fonte: [9KUAQqzaxsU](https://www.youtube.com/watch?v=9KUAQqzaxsU) · Vídeos · legenda: en.

**Localização:** 3:25–3:57; 4:54–5:44; 6:47–8:31; 9:54–10:24.

**Síntese:** Apresenta o editor, esboço inicial, geração com referência de estilo, rotação, edição e inpainting de cenário. Demonstra escolher a saída como camada ou frame e distinguir uma alteração textual de uma região pintada.

**Aplicação à Forja:** Separar exploração de candidatos da promoção de uma referência. O fluxo mostra ferramentas; não demonstra correção automática de clusters ou qualidade garantida.

### F28 — How to Fix Pixel Art Scale Perfectly (PixelLab Trick)

Fonte: [-L4Zyvklsc8](https://www.youtube.com/shorts/-L4Zyvklsc8) · Shorts · legenda: en.

**Localização:** 0:11–0:54.

**Síntese:** Gera objetos por inpainting ao lado de um personagem já presente, usando-o como referência de escala.

**Aplicação à Forja:** Comparar altura e densidade de detalhe no contexto real. A presença da referência ajuda o pedido, mas a dimensão e a legibilidade ainda precisam ser medidas.

### F29 — Turn Any Photo Into Real Pixel Art

Fonte: [Tz4LHify1Is](https://www.youtube.com/shorts/Tz4LHify1Is) · Shorts · legenda: en.

**Localização:** 0:30–1:05.

**Síntese:** Apresenta conversão de fotografia ou arte conceitual por Image to Pixel Art Pro, definindo a imagem como referência.

**Aplicação à Forja:** Converter uma imagem é etapa distinta de reparar ruído num sprite nativo. As comparações promocionais com outros geradores não equivalem a benchmark.

### F30 — Did You Know You Can Edit Pixel Art Like This?

Fonte: [dFQ2ffwMlo4](https://www.youtube.com/shorts/dFQ2ffwMlo4) · Shorts · legenda: pt-BR.

**Localização:** 0:08–0:59.

**Síntese:** Propõe variações de casa, personagem e arma a partir de uma imagem base, incluindo mudanças de estação, classe, equipamento e elemento.

**Aplicação à Forja:** A variação precisa manter os atributos exigidos e ter suas alterações autorizadas por região; reconhecer a mesma ideia não significa preservar exatamente os pixels.

### F31 — PixelLab in 60 Seconds: 10 Tools for Game Dev

Fonte: [QzoLfjllbPg](https://www.youtube.com/shorts/QzoLfjllbPg) · Shorts · legenda: pt-BR.

**Localização:** 0:02–1:01.

**Síntese:** Apresenta um panorama de dez ferramentas: personagem, animação, conversão, tiles, edição, objetos, retrato, interface e fonte.

**Aplicação à Forja:** Usar como índice de funcionalidades e encaminhar a análise técnica às aulas longas e à documentação; a lista não ensina um algoritmo de limpeza.

### F32 — I Made a Full Game Character Inside Aseprite

Fonte: [ibJHXTuTzFQ](https://www.youtube.com/shorts/ibJHXTuTzFQ) · Shorts · legenda: pt-BR.

**Localização:** 0:21–0:50.

**Síntese:** Um disparo falha por falta de espaço para recuo e efeito; reposicionar o personagem permite nova tentativa. A queda parte de poses importantes e usa interpolação.

**Aplicação à Forja:** Registrar margem de ação e âncoras. Evitar tentar resolver com paleta ou remoção de pixels uma falha causada pelo limite do canvas.

### F33 — Turn one idle pixel art character into walk, run, attack, and death animations using PixelLab

Fonte: [3zs3FdJEdBA](https://www.youtube.com/shorts/3zs3FdJEdBA) · Shorts · legenda: pt-BR.

**Localização:** 0:24–0:51; 0:53–1:41.

**Síntese:** Prepara estados a partir de uma referência, remove pixels perdidos antes de animar e usa interpolação entre poses para ataque e morte.

**Aplicação à Forja:** Aprovar estados limpos antes das sequências. Revisar também o texto expandido e a estabilidade dos materiais após a animação.

### F34 — Fix your sprites color palette with PixelLab #pixelart #gamedev #indiedev #godot #animation #unity

Fonte: [X0B_u-TTYVM](https://www.youtube.com/shorts/X0B_u-TTYVM) · Shorts · legenda: en.

**Localização:** 0:19–0:48.

**Síntese:** Apresenta três caminhos de redução: seleção automática, quantidade escolhida e adesão a uma paleta existente no editor.

**Aplicação à Forja:** Conferir pertencimento e orçamento no arquivo final; respeitar a paleta não comprova agrupamento espacial adequado.

### F35 — Perfect character consistency using this method #pixelart #animation #characterdesign

Fonte: [tdEZVVqslys](https://www.youtube.com/shorts/tdEZVVqslys) · Shorts · legenda: en.

**Localização:** 0:09–1:20; 1:25–1:51.

**Síntese:** Parte de um personagem em 64×64 para gerar outros por referência de estilo. Adiciona referências e reserva margem antes de animar.

**Aplicação à Forja:** A curadoria precisa anteceder a expansão do elenco. O padding deve permitir a ação mantendo escala útil e pivô.

### F36 — Pixel Art AI Workshop LIVE - Tips, Workflows & Q&A | PixelLab

Fonte: [q6oEg-HxyqI](https://www.youtube.com/watch?v=q6oEg-HxyqI) · Lives arquivadas · legenda: en.

**Localização:** 58:52–59:48; 1:01:30–1:02:46.

**Síntese:** Recorte temático da live: corrige um pixel, aplica redução a vários frames e compara quantidade escolhida com paleta específica. O fluxo retorna ao editor para limpeza e salva a animação revisada.

**Aplicação à Forja:** Distinguir a paleta compartilhada da revisão local. O número 20 é exemplo daquela demonstração e não teto recomendado ao Empire.

### F37 — Pixel Art AI Workshop LIVE - Tips, Workflows & Q&A | PixelLab

Fonte: [fBPLVhV_jag](https://www.youtube.com/watch?v=fBPLVhV_jag) · Lives arquivadas · legenda: en.

**Localização:** 10:47–12:14; 1:56:41–1:58:28.

**Síntese:** Recorte temático da live: apresenta redução automática, por quantidade ou paleta. Depois extrai uma paleta do personagem e aplica às animações; ainda observa mudança de sombreamento na face.

**Aplicação à Forja:** Mesmo com cores permitidas, a posição e a forma das sombras podem variar. A associação verbal entre redução e mixels não prova correção geométrica da grade.

### F38 — Pixel Art AI Workshop LIVE - Tips, Workflows & Q&A | PixelLab

Fonte: [lWSeMkZTsT4](https://www.youtube.com/watch?v=lWSeMkZTsT4) · Lives arquivadas · legenda: en.

**Localização:** 12:10–12:24; 1:51:22–1:51:45; 2:34:17–2:34:42; 2:47:01–2:47:23.

**Síntese:** Recortes temáticos da live: combina redução de cores e correção manual. Diz que certos modelos da interface daquela versão não tinham opção direta de paleta e propõe redução posterior.

**Aplicação à Forja:** Registrar quais controles existem no backend e na versão usados. Não presumir que um campo de paleta esteja disponível em toda ferramenta, nem transformar a observação histórica em limite atual.

### F39 — Pixel Art AI Workshop LIVE - Tips, Workflows & Q&A | PixelLab

Fonte: [jP5hyRELbLw](https://www.youtube.com/watch?v=jP5hyRELbLw) · Lives arquivadas · legenda: en.

**Localização:** 1:23:02–1:27:48; 1:29:29–1:30:56.

**Síntese:** Recorte temático da live: responde a uma dúvida sobre quatro tons de cinza e paleta reduzida. Procura o importador no lugar errado e depois localiza a importação de paleta nas opções. Diferencia a geração da aplicação posterior da paleta.

**Aplicação à Forja:** Conferir a interface real e a documentação; não copiar a primeira tentativa hesitante como procedimento. Uma paleta de quatro tons responde a esse exemplo, sem redefinir a paleta Empire.

### F40 — Pixel Art AI Workshop LIVE - Tips, Workflows & Q&A | PixelLab

Fonte: [qYeGOijp-3w](https://www.youtube.com/watch?v=qYeGOijp-3w) · Lives arquivadas · legenda: en.

**Localização:** 15:18–15:52; 19:36–20:03; 1:20:13–1:20:44; 1:50:30–1:51:00.

**Síntese:** Recortes temáticos da live: extrai paleta de um sprite base, seleciona frames e a reaplica. A redução é acompanhada de correções manuais de linhas; reforça limpar rotações antes de reutilizá-las.

**Aplicação à Forja:** Guardar a origem da paleta e selecionar explicitamente frames e regiões. Cor comum não dispensa revisão de contorno, sombra e detalhes.

## 4. Matriz de todos os 200 itens

“Obtida breve” requer atenção especial; pode conter apenas música, interjeições ou reconhecimento incompleto. Duração “—” significa metadado não recuperado, não duração zero. A ausência de fichamento é explícita.

| Nº | Tipo | Vídeo | Legenda | Idioma | Última marca / duração | Ficha |
|---:|---|---|---|---|---|---|
| 1 | Vídeos | [Tutorial: Make a Full Game Character in PixelLab (Idle, Walk, Attacks, States)](https://www.youtube.com/watch?v=zqZiQBS3LX0) | Obtida | pt | 16:46 / 16:49 | F04 |
| 2 | Vídeos | [How to Use the PixelLab VFX Creator](https://www.youtube.com/watch?v=VxAHJvcJr_Y) | Obtida | pt | 10:50 / 10:56 | F05 |
| 3 | Vídeos | [PixelLab Pro Tilesets: Full Guide (Sizes, Styles, Height & Diagonals)](https://www.youtube.com/watch?v=MbkqpDUFkEg) | Obtida | pt | 11:08 / 11:12 | F06 |
| 4 | Vídeos | [How to Make Animated Pixel Art VFX in PixelLab](https://www.youtube.com/watch?v=t8FIMv-8QpI) | Obtida | pt | 15:11 / 15:13 | F07 |
| 5 | Vídeos | [PixelLab Tutorial: Images Pro Flash, Skeleton V3 & PixMiniMax](https://www.youtube.com/watch?v=Y68m9k60Lg0) | Obtida | pt-BR | 18:23 / 18:25 | F10 |
| 6 | Vídeos | [Build a Game with AI - Full PixelLab Game Builder Tutorial](https://www.youtube.com/watch?v=Iaxk_8ftJ5s) | Obtida | pt-BR | 20:05 / 20:06 | — |
| 7 | Vídeos | [Level Up Your Game: Custom Sprite Animation Tutorial](https://www.youtube.com/watch?v=r8ySiSRRvz4) | Obtida | pt-BR | 10:45 / 10:47 | F13 |
| 8 | Vídeos | [Vibe Coding a Full Game with PixelLab MCP + API](https://www.youtube.com/watch?v=fvPmuk-usgw) | Obtida | pt-BR | 6:55 / 6:57 | — |
| 9 | Vídeos | [PixelLab Tutorial: How to Reduce Colors Like a Pro!](https://www.youtube.com/watch?v=WSbBuAwRm18) | Obtida | pt-BR | 7:19 / 7:22 | F01 |
| 10 | Vídeos | [Pixellab Tutorial: Tilesets (Isometric/Hexagonal/Oblique/Square Topdown)](https://www.youtube.com/watch?v=sE1s5ZYfxqk) | Obtida | pt-BR | 8:06 / 8:07 | F25 |
| 11 | Vídeos | [The Ultimate PixelLab Inpainting Guide for Creator](https://www.youtube.com/watch?v=9eAlZlQmZBg) | Obtida | pt-BR | 8:17 / 8:19 | F08 |
| 12 | Vídeos | [How to Use Animate with Text in PixelLab](https://www.youtube.com/watch?v=j2bE9gq914U) | Obtida | pt-BR | 12:32 / 0:00 | F09 |
| 13 | Vídeos | [PixelLab Tutorial: Create Image from Style Reference(Pro)](https://www.youtube.com/watch?v=tx-JUE8KbJM) | Obtida | pt-BR | 7:24 / 7:26 | F02 |
| 14 | Vídeos | [PixelLab Tutorial: Create Image(Pro)](https://www.youtube.com/watch?v=OHrdbkpmcHE) | Obtida | pt-BR | 9:08 / 9:10 | F12 |
| 15 | Vídeos | [Build a Complete RPG UI Set with PixelLab AI](https://www.youtube.com/watch?v=BdoUMKhZ1Ys) | Obtida | en | 4:43 / 4:45 | F11 |
| 16 | Vídeos | [Make infinite characters in the SAME style!](https://www.youtube.com/watch?v=LcJQQwltQ2Q) | Obtida | en | 11:04 / 11:06 | F03 |
| 17 | Vídeos | [Pixelorama + PixelLab: Create, Edit, Rotate, and Animate Pixel Art](https://www.youtube.com/watch?v=9KUAQqzaxsU) | Obtida | en | 11:37 / 11:39 | F27 |
| 18 | Vídeos | [PixelLab Character States: The New Way to Animate Sprites](https://www.youtube.com/watch?v=oCJWxfEwX-o) | Obtida | en | 11:13 / 11:15 | F16 |
| 19 | Vídeos | [PixelLab Tutorial: How to Generate & Animate GBA-Style Sprites](https://www.youtube.com/watch?v=moCpjMOOBGk) | Obtida | en | 12:38 / 12:40 | F15 |
| 20 | Vídeos | [Introducing Object Creator: Make Pixel Art Objects, Packs, States & Animations](https://www.youtube.com/watch?v=Hhx9QZwYoZY) | Obtida | en | 1:51 / 1:53 | — |
| 21 | Vídeos | [I Tried Using PixelLab for a Game Jam… Here’s What Happened](https://www.youtube.com/watch?v=sMV94of38ck) | Obtida | en | 13:04 / 13:07 | — |
| 22 | Vídeos | [How to Make a Full Side-Scroller Asset Pack with PixelLab](https://www.youtube.com/watch?v=o8AZRTx36DE) | Obtida | en | 11:12 / 11:13 | F14 |
| 23 | Vídeos | [How to Make Animated Pixel Art Scenes with PixelLab](https://www.youtube.com/watch?v=1FWEXTiJnlc) | Obtida | en | 24:19 / 24:22 | — |
| 24 | Vídeos | [New PixelLab Tool: Animate Between 2 Frames](https://www.youtube.com/watch?v=1CjxHZoZE_I) | Obtida | en | 10:17 / 10:20 | F21 |
| 25 | Vídeos | [This Tool Generates Pixel Animations for You… Here’s How](https://www.youtube.com/watch?v=zghUW8fGqsM) | Obtida | en | 6:52 / 6:56 | — |
| 26 | Vídeos | [How to Make Walking Animations for Pixel Art Characters in PixelLab](https://www.youtube.com/watch?v=8TRHAC3fUpo) | Obtida | en | 9:44 / 9:46 | F20 |
| 27 | Vídeos | [How to Create Interior Maps for Top-Down Games (PixelLab Map Workshop Tutorial)](https://www.youtube.com/watch?v=qVDkp1baJkU) | Obtida | en | 7:07 / 7:09 | — |
| 28 | Vídeos | [Create a Full Side Scroller Level (Tiles + Backgrounds) in 5 Minutes](https://www.youtube.com/watch?v=84yChPoOaew) | Obtida | en | 5:46 / 5:48 | — |
| 29 | Vídeos | [Create a Pixel Art PNGTuber in 5 Minutes / PixelLab + Veadotube](https://www.youtube.com/watch?v=up2hU_lzQsA) | Obtida | en | 5:08 / 5:10 | — |
| 30 | Vídeos | [How to Create Destructible Environments in Seconds](https://www.youtube.com/watch?v=0SQRclReGo4) | Obtida | en | 14:41 / 14:43 | — |
| 31 | Vídeos | [How To Create Isometric Animals for Games Using PixelLab (Full Workflow)](https://www.youtube.com/watch?v=T4by1uEXuE4) | Obtida | en | 8:12 / 8:14 | — |
| 32 | Vídeos | [Building a Cohesive Game Art Style Using PixelLab](https://www.youtube.com/watch?v=7HTLYLo3tTQ) | Obtida | en | 4:41 / 4:43 | F18 |
| 33 | Vídeos | [This AI Tool Changes Pixel Art Forever](https://www.youtube.com/watch?v=7ChVezZPv64) | Obtida | pt | 2:30 / 2:33 | — |
| 34 | Vídeos | [How to Generate Consistent Pixel Art for Games](https://www.youtube.com/watch?v=nITrIQw1gag) | Obtida | en | 3:18 / 3:20 | F17 |
| 35 | Vídeos | [How to Animate Pixel Art with TEXT](https://www.youtube.com/watch?v=XdgK1KeN-3s) | Obtida | en | 4:03 / 4:05 | — |
| 36 | Vídeos | [Easiest way to create pixel art UI](https://www.youtube.com/watch?v=OdRIHQ4ar2c) | Obtida | en | 3:49 / 3:53 | — |
| 37 | Vídeos | [Export Your PixelLab Map to Godot in 3 Minutes (Complete Guide)](https://www.youtube.com/watch?v=br2EO65qHAU) | Obtida | en | 2:23 / 2:28 | — |
| 38 | Vídeos | [PixelLab Map Workshop Tutorial: Make Maps 10x Faster with Al Tilesets](https://www.youtube.com/watch?v=O9maOTbLuHQ) | Obtida | en | 4:49 / 4:50 | — |
| 39 | Vídeos | [AI Builds a Godot Game From Scratch / PixelLab MCP + Claude Code Workflow](https://www.youtube.com/watch?v=THwZYWuOdZI) | Obtida | en | 23:43 / 23:46 | — |
| 40 | Vídeos | [PixelLab update: Generate Tibia styled characters and animations](https://www.youtube.com/watch?v=a_ygRPpBmnI) | Obtida | pt-BR | 0:23 / 0:26 | — |
| 41 | Vídeos | [Pixel art map creator in the browser](https://www.youtube.com/watch?v=ZuQpsEE3uoE) | Obtida breve | en | 1:21 / 1:24 | — |
| 42 | Vídeos | [How to Generate Tilesets & Animations with Pixelorama](https://www.youtube.com/watch?v=EHh1hVXOj_0) | Obtida | en | 12:27 / 12:30 | — |
| 43 | Vídeos | [Tutorial: Generating pixel art tilesets](https://www.youtube.com/watch?v=q9z2Vhpz-Z8) | Obtida | en | 16:04 / 16:05 | — |
| 44 | Vídeos | [Tutorial: Generating pixel art characters and animations](https://www.youtube.com/watch?v=ptWw9gkgorQ) | Obtida | en | 5:54 / 5:55 | — |
| 45 | Vídeos | [Tutorial: How to use the Edit tool](https://www.youtube.com/watch?v=XhmpenTmPLg) | Obtida | en | 12:05 / 12:20 | F19 |
| 46 | Vídeos | [Tutorial: Animation to animation with PixelLab](https://www.youtube.com/watch?v=owkamgYVWAs) | Obtida | en | 4:20 / 4:24 | F22 |
| 47 | Vídeos | [Tutorial: Creating a pixel art isometric tiles and map with PixelLab](https://www.youtube.com/watch?v=CuBvG9mfQng) | Obtida | en | 5:44 / 5:51 | — |
| 48 | Vídeos | [Tutorial: Creating a pixel art sidescroller map and tilesets with PixelLab](https://www.youtube.com/watch?v=H-dPJKmKr1E) | Obtida | en | 10:33 / 10:35 | — |
| 49 | Vídeos | [Tutorial: How to create tilesets and maps using AI](https://www.youtube.com/watch?v=jPPznIEK7HY) | Obtida | en | 9:57 / 10:05 | — |
| 50 | Vídeos | [Creating pixel art tilesets with PixelLab](https://www.youtube.com/watch?v=p1l9S3ta_XA) | Obtida | en | 10:45 / 10:53 | — |
| 51 | Vídeos | [Creating pixel art characters with rotation and animations in one click](https://www.youtube.com/watch?v=RISPOYqeEGo) | Obtida | en | 6:19 / 6:28 | — |
| 52 | Vídeos | [Tutorial: How to create tilesets using AI](https://www.youtube.com/watch?v=D0uZTaHj0Do) | Obtida | en | 13:30 / 13:36 | — |
| 53 | Vídeos | [Tutorial: Learn how to animate, rotate and inpaint your character](https://www.youtube.com/watch?v=hOZzbQBjKPc) | Obtida | en | 17:24 / 17:32 | F23 |
| 54 | Vídeos | [Tutorial: Using inpainting to create style consistent characters](https://www.youtube.com/watch?v=68BYzLoLh-U) | Obtida | en | 9:27 / 9:32 | F24 |
| 55 | Vídeos | [Tutorial: Generating pixel art](https://www.youtube.com/watch?v=GdqO3IYTPFk) | Obtida | en | 8:38 / 8:40 | — |
| 56 | Vídeos | [Tutorial: How to animate pixel art using a skeleton](https://www.youtube.com/watch?v=zBfVT5pwCSs) | Obtida | en | 23:54 / 24:00 | F26 |
| 57 | Vídeos | [Tutorial: How to quickly create punching animations](https://www.youtube.com/watch?v=LQS4J4ub8G4) | Obtida | en | 11:06 / 11:10 | — |
| 58 | Vídeos | [Tutorial: How to bring your pixel art to life](https://www.youtube.com/watch?v=XEAsDRDmmU0) | Obtida | en | 5:58 / 6:27 | — |
| 59 | Vídeos | [Tutorial: Generate infinitely tiling background in a few simple steps](https://www.youtube.com/watch?v=5o1oK4ILYBM) | Obtida | en | 4:28 / 4:42 | — |
| 60 | Vídeos | [Tutorial: Creating animations](https://www.youtube.com/watch?v=RVVuDhyEbRI) | Obtida | en | 3:35 / 3:38 | — |
| 61 | Vídeos | [Tutorial: How to quickly generate pixel art animations](https://www.youtube.com/watch?v=inyHAOkwDlc) | Obtida | en | 11:42 / 11:42 | — |
| 62 | Vídeos | [Creating character and animation from scratch](https://www.youtube.com/watch?v=rAtY1U9QWKM) | Obtida | en | 2:50 / 3:23 | — |
| 63 | Vídeos | [How to quickly create pixel art animations](https://www.youtube.com/watch?v=3Oh5nX9aDiE) | Obtida | en | 5:20 / 5:22 | — |
| 64 | Vídeos | [Creating pixel art animations with AI](https://www.youtube.com/watch?v=32AotdXscy4) | Obtida | en | 9:03 / 9:29 | — |
| 65 | Vídeos | [Fastest way of rotating your pixel art character](https://www.youtube.com/watch?v=8jt0f-9wHRQ) | Obtida | en | 3:20 / 3:25 | — |
| 66 | Vídeos | [Tutorial: How to create animations with different frame rates with PixelLab](https://www.youtube.com/watch?v=H98R_o2nw30) | Obtida | en | 3:17 / 3:20 | — |
| 67 | Vídeos | [Rotate your pixel art character with AI!](https://www.youtube.com/watch?v=9bnsjsAG-hM) | Não retornada | — | — / 0:51 | — |
| 68 | Vídeos | [Tutorial: Generate rotations for your pixel art characters with PixelLab](https://www.youtube.com/watch?v=ufQ72nGORC0) | Obtida | en | 2:07 / 2:08 | — |
| 69 | Vídeos | [Tutorial: Generate map tiles for your sidescroller game with PixelLab](https://www.youtube.com/watch?v=XVlbYNMI3xg) | Obtida | en | 5:58 / 5:59 | — |
| 70 | Vídeos | [Tutorial: Generate pixel art images with PixelLab](https://www.youtube.com/watch?v=Tbmfh4pBPeo) | Obtida | en | 4:47 / 4:52 | — |
| 71 | Vídeos | [Tutorial: How to create maps with PixelLab](https://www.youtube.com/watch?v=Xx4UQpDyMFQ) | Obtida | en | 17:46 / 17:47 | — |
| 72 | Vídeos | [Easily create attack animations for your pixel art characters with AI!](https://www.youtube.com/watch?v=8GuAMFoIFBs) | Não retornada | — | — / 2:11 | — |
| 73 | Vídeos | [Tutorial: How to rotate your character with PixelLab](https://www.youtube.com/watch?v=bNtMm0SeJ74) | Obtida | en | 12:51 / 12:53 | — |
| 74 | Vídeos | [Tutorial: How to create an animation with a template in PixelLab](https://www.youtube.com/watch?v=w_E_kbCXRn4) | Obtida | en | 19:27 / 19:28 | — |
| 75 | Vídeos | [Tutorial: How to get style consistent images in PixelLab](https://www.youtube.com/watch?v=iBMq3P_Fazk) | Obtida | en | 11:55 / 11:56 | — |
| 76 | Vídeos | [Easily rotate your pixel art character with AI!](https://www.youtube.com/watch?v=qVc_cMn53sk) | Obtida breve | en | 1:29 / 1:32 | — |
| 77 | Vídeos | [Generate tile maps for your sidescroller game with AI](https://www.youtube.com/watch?v=yuXcjgZJJv0) | Obtida | en | 7:08 / 7:09 | — |
| 78 | Vídeos | [Tutorial: How I created an animation for my panda in under 5 minutes](https://www.youtube.com/watch?v=NCINAMZqWjg) | Obtida breve | en | 1:22 / 1:34 | — |
| 79 | Vídeos | [Tutorial: How to create pixel art animations with PixelLab](https://www.youtube.com/watch?v=mlCa0UdAhow) | Obtida | en | 5:54 / 6:06 | — |
| 80 | Vídeos | [How to create attack animations for pixel art characters](https://www.youtube.com/watch?v=lf49lGl-2Kk) | Não retornada | — | — / 3:44 | — |
| 81 | Vídeos | [How to create walk and running animations for pixel art characters](https://www.youtube.com/watch?v=9Supp_resOo) | Não retornada | — | — / 5:18 | — |
| 82 | Vídeos | [How to create a pixel art knight with 4 rotations](https://www.youtube.com/watch?v=tWSuzBRKG3U) | Não retornada | — | — / 1:22 | — |
| 83 | Vídeos | [Tutorial: Make a forest map with PixelLab AI tools](https://www.youtube.com/watch?v=j2dI0B4VHxk) | Não retornada | — | — / 4:27 | — |
| 84 | Vídeos | [Tutorial on how to make map tiles with PixelLab AI tools](https://www.youtube.com/watch?v=1H-1IjSv1wM) | Não retornada | — | — / 1:09 | — |
| 85 | Vídeos | [Easy way of creating pixelart animations using PixelLab](https://www.youtube.com/watch?v=OgsU9T1SEVQ) | Não retornada | — | — / 0:00 | — |
| 86 | Vídeos | [How to generate a pixelart attack animation](https://www.youtube.com/watch?v=wijMirHw6QQ) | Não retornada | — | — / 0:25 | — |
| 87 | Vídeos | [Generate pixel art from a sketch with PixelLab](https://www.youtube.com/watch?v=_84V5_0ftL0) | Não retornada | — | — / 0:35 | — |
| 88 | Vídeos | [Generate attacks for your 2D pixelart game with PixelLab](https://www.youtube.com/watch?v=vYnfRtjftDs) | Não retornada | — | — / 0:29 | — |
| 89 | Vídeos | [Generate  2D pixelart with PixelLab](https://www.youtube.com/watch?v=h0D-oVAFdMs) | Não retornada | — | — / 0:00 | — |
| 90 | Vídeos | [Reshape your 2D pixelart with PixelLab](https://www.youtube.com/watch?v=i9uTBo3EdvE) | Não retornada | — | — / 0:47 | — |
| 91 | Shorts | [Turn your photo into a pixel art character with PixelLab](https://www.youtube.com/shorts/4JTelvSK7xc) | Obtida | pt | 1:35 / 1:39 | — |
| 92 | Shorts | [Turn a Pixel Art Mage into a Lightning Wolf Spell ⚡🐺](https://www.youtube.com/shorts/aZpyBA6-8R0) | Obtida | pt | 0:47 / 0:51 | — |
| 93 | Shorts | [Give Your Pixel Art Character New Hair & Clothes with PixelLab!](https://www.youtube.com/shorts/oVoH58n1sUA) | Obtida | pt | 0:48 / 0:51 | — |
| 94 | Shorts | [Change Pixel Art Outfits & Poses with PixelLab](https://www.youtube.com/shorts/VuEt8YIg43o) | Obtida | pt | 0:47 / 0:50 | — |
| 95 | Shorts | [Our newest animation model "PixMiniMax" lets you create perfect loops! #pixelart #pixelartanimation](https://www.youtube.com/shorts/VeqXkAKz790) | Obtida | pt | 1:05 / 1:08 | — |
| 96 | Shorts | [PixelLab AI animation test - results are insane! #ai #animation #shorts](https://www.youtube.com/shorts/4_HO-Jo0qXE) | Obtida | pt-BR | 1:19 / 1:20 | — |
| 97 | Shorts | [The secret to better game combat #gamedev #pixelart #animation](https://www.youtube.com/shorts/k-lt0QviMj0) | Obtida | pt-BR | 0:57 / 0:59 | — |
| 98 | Shorts | [Don't build a game until you try this #gamedev #indiedev #pixelart](https://www.youtube.com/shorts/2p_RMiC1XQ4) | Obtida | pt-BR | 1:09 / 1:11 | — |
| 99 | Shorts | [Built a whole vampire game with PixelLab’s new Game Builder. #PixelLab #GameDev #IndieDev #PixelArt](https://www.youtube.com/shorts/2NkAhaKTl8U) | Obtida | pt-BR | 0:48 / 0:48 | — |
| 100 | Shorts | [The fastest way to animate pixel art #pixelart #animation #vfx](https://www.youtube.com/shorts/i67sr-WCpKc) | Obtida | pt-BR | 2:10 / 2:13 | — |
| 101 | Shorts | [I Made a Full Game Character Inside Aseprite](https://www.youtube.com/shorts/ibJHXTuTzFQ) | Obtida | pt-BR | 1:03 / 1:05 | F32 |
| 102 | Shorts | [PixelLab in 60 Seconds: 10 Tools for Game Dev](https://www.youtube.com/shorts/QzoLfjllbPg) | Obtida | pt-BR | 1:03 / 1:06 | F31 |
| 103 | Shorts | [Did You Know You Can Edit Pixel Art Like This?](https://www.youtube.com/shorts/dFQ2ffwMlo4) | Obtida | pt-BR | 1:19 / 1:19 | F30 |
| 104 | Shorts | [Don’t make a pixel art game without this website... 👾](https://www.youtube.com/shorts/tLJreYfrboE) | Obtida | pt-BR | 0:29 / 0:31 | — |
| 105 | Shorts | [Don't build your tiles manually until you see this #pixelart #gamedev #tips](https://www.youtube.com/shorts/H8ZhKVQcMO4) | Obtida | pt-BR | 1:24 / 1:26 | — |
| 106 | Shorts | [Building a farming game with animated trees, growing crops, and collectible resources using PixelLab](https://www.youtube.com/shorts/SE0diuqjzTk) | Obtida | pt-BR | 1:15 / 1:17 | — |
| 107 | Shorts | [I Combined 3 Images Into One Pixel-Art Character](https://www.youtube.com/shorts/52U6FAml3Ok) | Obtida | pt-BR | 0:49 / 0:51 | — |
| 108 | Shorts | [I Made a Custom Pixel Art Font for My Game](https://www.youtube.com/shorts/dr_BFbsvJW8) | Obtida | pt-BR | 0:49 / 0:51 | — |
| 109 | Shorts | [I Made Animated Dog Portraits for My Game 🐶](https://www.youtube.com/shorts/inJ2_C47x7s) | Obtida | pt-BR | 0:59 / 1:01 | — |
| 110 | Shorts | [I Remade My Dog Game UI With AI](https://www.youtube.com/shorts/RzePdziy8sU) | Obtida | pt-BR | 0:59 / 1:02 | — |
| 111 | Shorts | [I Turned My Real Dog Into a Pixel Art Game Character](https://www.youtube.com/shorts/OnE0axPeWlE) | Obtida | pt-BR | 2:04 / 2:05 | — |
| 112 | Shorts | [Turn one idle pixel art character into walk, run, attack, and death animations using PixelLab](https://www.youtube.com/shorts/3zs3FdJEdBA) | Obtida | pt-BR | 1:46 / 1:47 | F33 |
| 113 | Shorts | [Making custom mouse cursors for a game was never easier!](https://www.youtube.com/shorts/I0PBu6zgGGk) | Obtida | pt-BR | 1:06 / 1:09 | — |
| 114 | Shorts | [Turn Any Photo Into Real Pixel Art](https://www.youtube.com/shorts/Tz4LHify1Is) | Obtida | en | 1:15 / 1:17 | F29 |
| 115 | Shorts | [Make Game UI That Actually Matches Your World](https://www.youtube.com/shorts/CyGTPY82Hfk) | Obtida | en | 0:47 / 0:50 | — |
| 116 | Shorts | [How to Fix Pixel Art Scale Perfectly (PixelLab Trick)](https://www.youtube.com/shorts/-L4Zyvklsc8) | Obtida | en | 0:54 / 0:56 | F28 |
| 117 | Shorts | [Stop making static pixel art for your indie game!](https://www.youtube.com/shorts/H-kG7mZzItQ) | Obtida | en | 0:41 / 0:44 | — |
| 118 | Shorts | [This AI Website Makes Pixel Art Game Assets](https://www.youtube.com/shorts/PBdEvBbQ0sA) | Obtida | en | 1:06 / 1:07 | — |
| 119 | Shorts | [This Feature Saves Hours of Animation Work #pixelart #gamedev](https://www.youtube.com/shorts/OZWtWFBeGCA) | Obtida | en | 1:18 / 1:21 | — |
| 120 | Shorts | [Making Objects Respond to Players Hits Different #gamedev #shorts #pixellab #pixelart](https://www.youtube.com/shorts/MGoSAVSscjU) | Obtida | en | 1:45 / 1:47 | — |
| 121 | Shorts | [This AI tool saves game devs HOURS on pixel art #gamedev #pixelart #ai #pixellab](https://www.youtube.com/shorts/PFboT6rn1Yw) | Obtida | en | 0:47 / 0:50 | — |
| 122 | Shorts | [This auto-rotate feature saves hours #pixelart #gamedev #shorts](https://www.youtube.com/shorts/cnfNZECAkPg) | Obtida | en | 0:52 / 0:53 | — |
| 123 | Shorts | [Stop stressing over game assets. 🛠️ try pixellab.ai #pixelart #pixellab #gamedev](https://www.youtube.com/shorts/OtiWy3wOm4o) | Obtida | en | 1:17 / 1:19 | — |
| 124 | Shorts | [This Loot Generation Trick Saves Hours #gamedev #ai #pixelart](https://www.youtube.com/shorts/j9mE8lHPPcM) | Obtida | en | 0:54 / 0:57 | — |
| 125 | Shorts | [Stop Wasting Hours Making Game Assets #pixelart #gamedev #tutorial](https://www.youtube.com/shorts/S6LTbuiAeuQ) | Obtida | en | 0:47 / 0:49 | — |
| 126 | Shorts | [Never hand-draw pixels again #pixelart #gamedev](https://www.youtube.com/shorts/iANuVjBhFQA) | Obtida | en | 1:00 / 1:02 | — |
| 127 | Shorts | [Perfect character consistency using this method #pixelart #animation #characterdesign](https://www.youtube.com/shorts/tdEZVVqslys) | Obtida | en | 1:59 / 2:01 | F35 |
| 128 | Shorts | [Game dev trick: Create tilesets with a single click #pixelart #indiedev #gamedevelopment #gamedev](https://www.youtube.com/shorts/2YMEY5ullUA) | Obtida | en | 1:18 / 1:21 | — |
| 129 | Shorts | [Generate tiles in seconds with PixelLab 👀  #pixelart #indiedev #gamedevelopment #gamedev](https://www.youtube.com/shorts/r8oEOa2cvsw) | Obtida | en | 1:03 / 1:07 | — |
| 130 | Shorts | [Game dev trick: Turn one character into a whole crowd #pixelart #indiedev #gamedevelopment #gamedev](https://www.youtube.com/shorts/6MwvFyOu3d0) | Obtida | en | 1:06 / 1:08 | — |
| 131 | Shorts | [3D Animation to pixel art animation #pixelart #gamedev #indiedev #godot #animation #2dgameart](https://www.youtube.com/shorts/y-RL3FgiEhg) | Obtida | en | 1:20 / 1:21 | — |
| 132 | Shorts | [How to make bosses with PixelLab #pixelart #gamedev #indiedev #godot #animation #2dgameart](https://www.youtube.com/shorts/V3exgHvwnYA) | Obtida | en | 1:43 / 1:47 | — |
| 133 | Shorts | [Creating car assets with PixelLab #pixelart #gamedev #indiedev #godot #animation](https://www.youtube.com/shorts/8yiNYyXXz1U) | Obtida | en | 1:17 / 1:21 | — |
| 134 | Shorts | [Creating large pixel art images with PixelLab #pixelart #gamedev #indiedev #godot #animation](https://www.youtube.com/shorts/ITNO9Adl5-I) | Obtida | en | 0:42 / — | — |
| 135 | Shorts | [Creating a Visual Novel with PixelLab #pixelart #gamedev #indiedev #godot #animation #visualnovel](https://www.youtube.com/shorts/6g-_2ILSVlg) | Obtida | en | 2:24 / — | — |
| 136 | Shorts | [Creating a Visual Novel with PixelLab #pixelart #gamedev #indiedev #godot #animation #visualnovel](https://www.youtube.com/shorts/dC13HGrI0Tk) | Obtida | en | 1:19 / — | — |
| 137 | Shorts | [Fix your sprites color palette with PixelLab #pixelart #gamedev #indiedev #godot #animation #unity](https://www.youtube.com/shorts/X0B_u-TTYVM) | Obtida | en | 0:51 / — | F34 |
| 138 | Shorts | [I built a doom style protype with AI #pixelart #gamedev #indiedev #godot #animation #unity](https://www.youtube.com/shorts/7PrveMMR3oI) | Obtida | en | 1:20 / — | — |
| 139 | Shorts | [Building modular clothes with PixelLab! #pixelart #gamedev #indiedev #godot #animation #unity](https://www.youtube.com/shorts/1EDq2xHQcJ8) | Obtida | en | 1:10 / — | — |
| 140 | Shorts | [Easier than ever to animate with PixelLab! #pixelart #gamedev #indiedev #godot #animation #unity](https://www.youtube.com/shorts/Lx9r3TzoIWY) | Obtida | en | 1:12 / — | — |
| 141 | Shorts | [Create maps and tilesets with PixelLab! #pixelart #gamedev #indiedev #godot #animation #unity](https://www.youtube.com/shorts/nJj9Nm77b7E) | Obtida | en | 1:18 / — | — |
| 142 | Shorts | [Animate portraits with PixelLab! #pixelart #gamedev #indiedev #godot #animation #unity #pixel](https://www.youtube.com/shorts/WP8l9fV0nSc) | Obtida | en | 0:49 / — | — |
| 143 | Shorts | [Create animated sprites with PixelLab! #pixelart #gamedev #indiedev #godot #animation #unity #pixel](https://www.youtube.com/shorts/BzNkHM3kMtU) | Obtida | en | 1:16 / — | — |
| 144 | Shorts | [Change your characters' outfits with PixelLab! #pixelart #gamedev #indiedev #godot #animation #unity](https://www.youtube.com/shorts/XF3VEbLnWCw) | Obtida | en | 0:59 / — | — |
| 145 | Shorts | [Edit your pixel art sprites with PixelLab! #pixelart #gamedev #indiedev #godot #animation #unity](https://www.youtube.com/shorts/QUJjEcCuKsM) | Obtida | en | 0:23 / — | — |
| 146 | Shorts | [Bringing life to pixel art sprites with PixelLab! #pixelart #gamedev #indiedev #godot #animation](https://www.youtube.com/shorts/V9Vn0ARLjXQ) | Obtida | en | 1:00 / — | — |
| 147 | Shorts | [Rotating existing sprites with PixelLab! #pixelart #gamedev #indiedev #godot #artstyle #pixelartist](https://www.youtube.com/shorts/RggRpboljjY) | Obtida breve | en | 0:23 / — | — |
| 148 | Shorts | [Trying out our new rotation tool in PixelLab with Style image! #pixelart #gamedev #indiedev #godot](https://www.youtube.com/shorts/-0EU15goVjo) | Obtida breve | en | 0:29 / — | — |
| 149 | Shorts | [Trying out our new rotation tool in PixelLab with Concept image! #pixelart #gamedev #indiedev #godot](https://www.youtube.com/shorts/A8ZYb7CvbGg) | Obtida breve | en | 0:21 / — | — |
| 150 | Shorts | [Trying out our new animation tool in PixelLab! #pixelart #gamedev #indiedev #godot](https://www.youtube.com/shorts/lPC5-b7ToPU) | Obtida | en | 0:50 / — | — |
| 151 | Shorts | [Day 11: Creating new Maps! 2D game with PixelLab #pixelart #gamedev #indiedev #godot #retrogaming](https://www.youtube.com/shorts/4WBLaxfREtc) | Obtida | pt-BR | 1:03 / — | — |
| 152 | Shorts | [Day 10: Creating character variations with PixelLab #pixelart #gamedev #indiedev #godot #retrogaming](https://www.youtube.com/shorts/PTGZU6w6J8E) | Obtida | en | 1:01 / — | — |
| 153 | Shorts | [Day 9: Adding map selection 2D platformer made with PixelLab #pixelart #gamedev #indiedev #godot](https://www.youtube.com/shorts/8D3EbA-Us2g) | Obtida | pt-BR | 1:13 / — | — |
| 154 | Shorts | [Day 8: Finetuning my 2D pixel art platformer made with PixelLab #pixelart #gamedev #indiedev #godot](https://www.youtube.com/shorts/Qm21Y5nrnGw) | Obtida | en | 1:13 / — | — |
| 155 | Shorts | [Day 7: Taking my 2D pixel art platformer to the next level #pixelart #gamedev #indiedev #godot](https://www.youtube.com/shorts/hSrJchzrBUU) | Obtida | en | 1:23 / — | — |
| 156 | Shorts | [Day 6: Add new enemies and stages to my 2D pixel art platformer #pixelart #gamedev #indiedev #godot](https://www.youtube.com/shorts/wOBil1rTw8U) | Obtida | pt-BR | 1:26 / — | — |
| 157 | Shorts | [Day 5: Creating background for my 2D pixel art platformer #pixelart #gamedev #indiedev #godot](https://www.youtube.com/shorts/gOldqYcRTfM) | Obtida | en | 1:32 / — | — |
| 158 | Shorts | [Day 4: NPC fights back! 2D pixel art platformer #pixelart #gamedev #indiedev #godot #tutorial #ai](https://www.youtube.com/shorts/b8U8oHdsfZU) | Obtida | en | 0:59 / — | — |
| 159 | Shorts | [Day 3: Creating attack animation, 2D Platformer #pixelart #gamedev #indiedev #godot #tutorial](https://www.youtube.com/shorts/t8pul8kbrTY) | Obtida | pt-BR | 1:06 / — | — |
| 160 | Shorts | [Day 2: Creating a pixel art platformer with PixelLab #pixelart #gamedev #indiedev #godot #tutorial](https://www.youtube.com/shorts/0jikWOvcnu0) | Obtida | en | 1:11 / — | — |
| 161 | Shorts | [Day 1: Vibecoding a 2D pixel art platformer with PixelLab #ai #pixelart #gamedev #indiedev #godot](https://www.youtube.com/shorts/Kwd3yAZup2I) | Obtida | en | 1:09 / — | — |
| 162 | Shorts | [Vibecoding a game and map with Claude and PixelLab #ai #pixelart #gamedev #indiedev #art #godot](https://www.youtube.com/shorts/bGJ_AcDZuY0) | Obtida | pt-BR | 0:57 / — | — |
| 163 | Shorts | [Vibecoding a game with PixelLab MCP #ai #pixelart #gamedev #indiedev #art #godot #unity #claude](https://www.youtube.com/shorts/XBLZc-jhiks) | Obtida | en | 1:30 / — | — |
| 164 | Shorts | [Vibecoding a game with Claude and PixelLab #ai #pixelart #gamedev #indiedev #art #godot #unity](https://www.youtube.com/shorts/1zLxqJOB6b0) | Obtida | pt-BR | 0:53 / — | — |
| 165 | Shorts | [Pixel art map creator in the browser by PixelLab  #pixelart #gamedev #unity #indiedev #art](https://www.youtube.com/shorts/eLdjLfvEPzA) | Obtida breve | en | 0:44 / — | — |
| 166 | Shorts | [Start creating pixel art assets with PixelLab #ai #pixelart #gamedev #indiedev #art #godot #unity](https://www.youtube.com/shorts/8EjXev_9Pj0) | Não retornada | — | — / — | — |
| 167 | Shorts | [Creating characters and animations with PixelLab #ai #pixelart #gamedev #indiedev #art](https://www.youtube.com/shorts/pJYf2JTgZBA) | Obtida | en | 0:51 / — | — |
| 168 | Shorts | [Creating isometric pixel art tiles with PixelLab #ai #pixelart #gamedev #indiedev #art](https://www.youtube.com/shorts/qcqVGOp2kFQ) | Obtida | en | 0:26 / — | — |
| 169 | Shorts | [Turning images to pixel art #ai #pixelart #gamedev #indiedev #art](https://www.youtube.com/shorts/ORFuLXEmNmo) | Obtida | en | 0:48 / — | — |
| 170 | Shorts | [Pixel art animation to animation with PixelLab #pixelarttutorial #ai #pixelart #gamdev #indiedev](https://www.youtube.com/shorts/tfHavyN0sSo) | Obtida | en | 0:27 / — | — |
| 171 | Shorts | [Creating map with PixelLab #ai #pixelart #gamedev #indiedev #artshorts  #tutorial #shorts](https://www.youtube.com/shorts/6aW4C4IGLxU) | Obtida breve | en | 0:55 / — | — |
| 172 | Shorts | [Creating map with PixelLab #ai #pixelart #gamedev #indiedev #artshorts  #tutorial #shorts](https://www.youtube.com/shorts/ISZEqrD5LZM) | Obtida | en | 0:56 / — | — |
| 173 | Shorts | [Creating high top-down tileset with PixelLab #ai #pixelart #gamedev #indiedev #artshorts  #tutorial](https://www.youtube.com/shorts/41ACEfzJS4c) | Não retornada | — | — / — | — |
| 174 | Shorts | [Creating high top-down tileset with PixelLab #ai #pixelart #gamedev #indiedev #artshorts  #tutorial](https://www.youtube.com/shorts/cqYWmMBQn_E) | Obtida breve | en | 0:16 / — | — |
| 175 | Shorts | [Creating tileset with PixelLab #ai #pixelart #gamedev #indiedev #art](https://www.youtube.com/shorts/ggsEA67F1qw) | Obtida breve | en | 0:15 / — | — |
| 176 | Shorts | [Generating characters with PixelLab #ai #pixelart #gamedev #indiedev #art](https://www.youtube.com/shorts/yRjEhVeXbiY) | Obtida | en | 0:51 / — | — |
| 177 | Shorts | [Generating Jinx from arcane](https://www.youtube.com/shorts/9T6yvB-wCLk) | Obtida breve | en | 0:33 / — | — |
| 178 | Shorts | [Generate a pirate with AI #shorts #pixelart #gamedev #ai #art #animation](https://www.youtube.com/shorts/S4G7OtWM0Is) | Não retornada | — | — / — | — |
| 179 | Shorts | [Generate punch animation for characters with AI #shorts #pixelart #gamedev #ai #art #animation](https://www.youtube.com/shorts/onWVM7tVOwI) | Obtida breve | en | 0:57 / — | — |
| 180 | Shorts | [Bring your pixel art alive #pixelart #animation #gamedevelopment #gamedev #gameart #unity #indiedev](https://www.youtube.com/shorts/xUntE48CHIY) | Obtida | en | 0:44 / — | — |
| 181 | Shorts | [How to generate goblin using AI #pixelart #gamedevelopment #animationsoftware  #shorts #gamedev #art](https://www.youtube.com/shorts/Nt-v1uO-rjo) | Obtida breve | en | 0:50 / — | — |
| 182 | Shorts | [Rotate your games furniture #pixelart #gamedev #unity #animationsoftware #tutorial #gamedevelopment](https://www.youtube.com/shorts/9l2BJPiWI4Q) | Obtida breve | en | 0:31 / — | — |
| 183 | Shorts | [Rotate your pixel art game assets with AI #pixelart #gamedev #unity](https://www.youtube.com/shorts/Bz49AAxb92Y) | Obtida breve | en | 0:32 / — | — |
| 184 | Shorts | [Transfer animations to your characters with AI #pixelart #gamedev #unity](https://www.youtube.com/shorts/da-r6lmcqEY) | Obtida breve | en | 0:48 / — | — |
| 185 | Shorts | [Generate rotations for characters with AI #shorts #pixelart #gamedev #ai #unity #art](https://www.youtube.com/shorts/S1ejemlrhmU) | Obtida breve | en | 0:27 / — | — |
| 186 | Shorts | [How to generate rotations for your objects using AI #shorts #pixelart #gamedev](https://www.youtube.com/shorts/Wk2ZRNWCdWw) | Obtida breve | en | 0:22 / — | — |
| 187 | Shorts | [How to generate rotations using AI #shorts #gamedev #pixelart](https://www.youtube.com/shorts/Pr-LKUCfwkE) | Obtida breve | en | 0:33 / — | — |
| 188 | Shorts | [How to create animations with different frame rates #gamedev  #pixelart #indiedev #shorts](https://www.youtube.com/shorts/qOhMp_X_gbU) | Obtida | en | 0:47 / — | — |
| 189 | Shorts | [Fast way to rotate your pixel art characters  #gamedev #pixelart #aseprite](https://www.youtube.com/shorts/yZPrhZBaE70) | Obtida | en | 0:27 / — | — |
| 190 | Shorts | [Rotate your pixel art characters with AI #pixelart #gamedev #unity2d](https://www.youtube.com/shorts/Ckf8P2YyQ24) | Obtida | en | 0:28 / — | — |
| 191 | Shorts | [Creating a pokémon ferret in under 60 seconds with PixelLab](https://www.youtube.com/shorts/Bq_8pg0Qnqo) | Não retornada | — | — / — | — |
| 192 | Shorts | [Created Pokemon Panda in under 60 seconds with AI](https://www.youtube.com/shorts/po1CDvRZuVM) | Obtida breve | en | 0:37 / — | — |
| 193 | Shorts | [Creating a cozy village with PixelLab](https://www.youtube.com/shorts/uqcoqML9ymE) | Não retornada | — | — / — | — |
| 194 | Shorts | [Generate dungeon map tiles using PixelLab.ai](https://www.youtube.com/shorts/F9Fbva9ngV8) | Não retornada | — | — / — | — |
| 195 | Shorts | [How to generate map tiles using AI #shorts](https://www.youtube.com/shorts/ZO8u-mZWPAA) | Não retornada | — | — / — | — |
| 196 | Lives arquivadas | [Pixel Art AI Workshop LIVE - Tips, Workflows & Q&A / PixelLab](https://www.youtube.com/watch?v=q6oEg-HxyqI) | Obtida | en | 2:28:54 / — | F36 |
| 197 | Lives arquivadas | [Pixel Art AI Workshop LIVE - Tips, Workflows & Q&A / PixelLab](https://www.youtube.com/watch?v=fBPLVhV_jag) | Obtida | en | 3:09:48 / — | F37 |
| 198 | Lives arquivadas | [Pixel Art AI Workshop LIVE - Tips, Workflows & Q&A / PixelLab](https://www.youtube.com/watch?v=lWSeMkZTsT4) | Obtida | en | 3:29:17 / — | F38 |
| 199 | Lives arquivadas | [Pixel Art AI Workshop LIVE - Tips, Workflows & Q&A / PixelLab](https://www.youtube.com/watch?v=jP5hyRELbLw) | Obtida | en | 3:41:38 / — | F39 |
| 200 | Lives arquivadas | [Pixel Art AI Workshop LIVE - Tips, Workflows & Q&A / PixelLab](https://www.youtube.com/watch?v=qYeGOijp-3w) | Obtida | en | 3:20:45 / — | F40 |

## 5. Lacunas que permanecem

A matriz identifica cada item sem legenda retornada. Mesmo nos arquivos obtidos, revisão humana do áudio e inspeção dos quadros permanecem necessárias para uma transcrição certificada e uma análise visual exaustiva. Nenhuma porcentagem de correção automática ou de ganho artístico foi estimada a partir da mera coleta.

Para materiais que o usuário fornecer com direito de reprodução, uma etapa posterior pode produzir transcrição integral e alinhar texto, áudio e quadros. Os fichamentos atuais já sustentam a investigação técnica; não devem ser apresentados como substituto certificado de todos os vídeos.
