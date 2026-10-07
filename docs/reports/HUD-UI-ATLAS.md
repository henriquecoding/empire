# Empire — Plano mestre para uma HUD e uma UI com identidade própria

**Direção proposta: Atlas do Império**  
Pesquisa, diagnóstico visual, sistema de design e plano de implementação · 7 de outubro de 2026

## 1. A decisão central

O Empire deve ter uma interface que pareça pertencer ao ato de **percorrer, fundar, conhecer e defender um território**. A identidade deve nascer dessas ações. O cenário é o elemento dominante durante o jogo; a interface organiza o que o jogador precisa de saber, mostra a consequência da ação e abre espaço para uma leitura mais profunda quando solicitada.

A recomendação é construir um único sistema chamado, neste documento, **Atlas do Império**. O nome identifica a direção de design; não obriga a chamar “Atlas” a todos os menus. O sistema combina marcas cartográficas, divisórias horizontais, um selo próprio e superfícies inspiradas em instrumentos de campo e registos do reino. A mesma gramática aparece na bolsa, no relógio, nos controlos, nas fichas de edifícios, no mapa e nas definições.

O resultado pretendido tem cinco características reconhecíveis:

1. **O horizonte fica livre.** A personagem, o terreno utilizável e as aproximações de ameaças continuam legíveis.
2. **A interface tem uma assinatura.** Três traços horizontais, um recorte assimétrico e um selo interrompido distinguem o Empire, sem depender de decoração pesada.
3. **Cada informação tem um lugar previsível.** Recursos, tempo, contexto e comandos não competem em painéis equivalentes.
4. **A ação explica a sua consequência.** Construir, gastar, entrar e atacar são ações diferentes e continuam distinguíveis.
5. **A linguagem atravessa todos os ecrãs.** A pausa, a gestão e as mensagens seguem as mesmas regras da HUD.

### Prioridades executivas

| Ordem | Mudança | Resultado esperado |
| --- | --- | --- |
| P0 | Substituir o painel central automático por indicação curta e inspeção voluntária | Recuperar a leitura do mundo e da personagem |
| P0 | Separar visualmente ação contextual, combate e moeda | Reduzir ambiguidade e gastos acidentais |
| P0 | Definir um único contrato de posição, medição e hitbox por componente | Evitar desencontros entre texto, moldura e área de toque |
| P0 | Preservar Correr e Fixar analógico, incluindo as preferências existentes | Melhorar a composição sem retirar controlo ao jogador |
| P1 | Aplicar o sistema Atlas à HUD e à ficha de local | Estabelecer a identidade no percurso mais frequente |
| P1 | Unificar pausa, Estado do reino, edifícios e definições | Eliminar a sensação de várias interfaces dentro do mesmo jogo |
| P2 | Afinar tipografia, iconografia, som e transições | Consolidar a qualidade e a personalidade visual |

## 2. Âmbito e qualidade da evidência

### O que foi observado

- Captura fornecida pelo utilizador: `20254041-4cc5-4bee-aa63-9bcecef3d58a.png`, com 2048 × 941 píxeis.
- Paisagem em pixel art, apresentação lateral, referências a moedas, dia, fase do dia e primavera.
- Painel central “Fundar o Império aqui?”, com mensagens sobre pesqueiro e poço de minério.
- Controlos visíveis: Fixar, Impulsos, Vigília, Interagir, Correr, Espada, Moeda e pausa.

### Contexto anterior relevante

Foram consultados os relatórios `empire_planeamento_subsolos_armazens_dungeons.md` e `relatorio_kingdom_vegetacao_biomas.md`. O primeiro descreve uma referência histórica do projeto em 1,5D, com três faixas, câmara única e geração determinística. Essa informação orienta a proposta; deve ser reconciliada com o código atual antes da implementação.

O histórico do trabalho anterior também indica a necessidade de **preservar Correr e Fixar analógico**. Esta é uma restrição deste plano. Há ainda um relato de revisão anterior da HUD, com compactação de controlos e acesso ao Estado do reino pela pausa. Esse relato não foi tratado como uma auditoria da versão atual.

### O que este documento não comprova

Não foi executada uma sessão da versão publicada nem inspecionado o repositório atual nesta tarefa. A captura pode corresponder a uma versão diferente da `main`. As observações abaixo referem-se ao ecrã enviado; as propostas de arquitetura são especificações, não descrições de ficheiros que tenha encontrado no código atual.

Não estão confirmados pela imagem: o significado exato de `6 / 33`, o custo de fundação, a interpretação de `1 de 2`, as regras de Impulsos e Vigília, o comportamento do mundo durante a pausa, a existência de vida, resistência ou munições e a implementação atual de acessibilidade. Não acrescentar esses sistemas apenas para preencher a interface.

### Como são distinguidas as conclusões

| Etiqueta | Significado |
| --- | --- |
| **Observação** | Visível na captura ou explicitamente descrito numa fonte consultada |
| **Interpretação** | Explicação plausível que ainda precisa de validação |
| **Proposta** | Decisão de design recomendada para o Empire |
| **Meta** | Critério de aceitação a medir; não é um resultado já alcançado |

As fontes externas são páginas de estúdios/editoras, publicações dos próprios criadores, documentação do W3C, Microsoft, MDN e fontes tipográficas oficiais. A pesquisa usa casos históricos de design e revisões de UI; não pretende enumerar os patches mais recentes de cada jogo. As aplicações ao Empire são síntese original, assinalada como tal.

## 3. Diagnóstico do ecrã enviado

### 3.1. Ocupação e hierarquia

A área de jogo visível ocupa aproximadamente o retângulo entre x=145 e x=1903, y=132 e y=941: cerca de 1758 × 809 píxeis. A barra do navegador e as bandas laterais ficam excluídas desta estimativa.

O painel de fundação ocupa aproximadamente 748 × 453 píxeis: **23,8% da área de jogo visível**. As duas caixas superiores somam aproximadamente mais 10,6%. Só os retângulos destes três painéis abrangem perto de **34,4%** do jogo, antes de contabilizar controlos.

São estimativas manuais dos retângulos exteriores, não medições de opacidade, nem percentagens de perda de visibilidade. Mesmo uma superfície translúcida continua a disputar a atenção com o cenário. A medição não permite inferir dimensões em CSS ou a densidade física do telemóvel.

| Observação | Consequência provável | Mudança proposta |
| --- | --- | --- |
| Painel grande no centro, sobre a zona de ação | É difícil ler o local e decidir sobre o próprio local | Indicação contextual curta; detalhes por pedido explícito |
| Moedas e tempo em caixas muito largas | Informação simples ocupa área de exposição permanente | Blocos compactos com alinhamento e hierarquia internos |
| Comandos circulares semelhantes | Ações com consequências diferentes parecem equivalentes | Famílias distintas para navegação, combate, contexto e economia |
| Pausa muito saliente | Compete com ações que exigem resposta imediata | Botão discreto, com alvo de toque confortável |
| Mensagens técnicas extensas no fluxo de fundação | O jogador tem de interpretar o gerador | Separar possibilidade, limitação e requisito em linhas curtas |
| “INTERAGIR: Fundar” repete a ação | Ocupa espaço sem esclarecer consequência | Verbo direto e indicação do dispositivo apenas quando útil |
| `6 / 33` sem explicação da relação | Pode ser capacidade, objetivo ou progressão | Validar semântica e rotular corretamente |
| Mesmo tom de moldura em praticamente tudo | Falta hierarquia funcional e identidade específica | Reservar cor e recortes a funções estáveis |
| Letras visualmente suaves sobre cenário pixelizado | Sensação de incoerência e possível perda de nitidez | Separar escala do mundo da renderização de texto; investigar a causa |

### 3.2. O problema de linguagem visual

O cenário tem muito mais personalidade do que a interface. As caixas e círculos poderiam pertencer a vários jogos. Há uma intenção medieval através das cores, mas faltam regras que relacionem essas formas com o território, a construção e o tempo.

**Interpretação:** a sensação de genericidade resulta sobretudo de uma hierarquia pouco diferenciada e da ausência de uma gramática consistente. Mudar apenas a fonte ou acrescentar ornamentos deixaria esses dois problemas intactos.

### 3.3. O problema de informação

O painel mistura três questões:

- Posso fundar o império aqui?
- Que atividades este lugar permite?
- Que condição específica falha para um determinado edifício?

Estas respostas precisam de estar relacionadas, mas não precisam de aparecer todas com o mesmo tamanho e urgência. Um local sem pesca pode continuar a ser válido para a fundação. **Não transformar uma limitação de um edifício num bloqueio global sem confirmação das regras do jogo.**

### 3.4. A investigação necessária antes de mexer no código

Reproduzir o mesmo estado numa build identificada; registar viewport CSS, DPR, escala de UI, orientação e dispositivo de entrada. Confirmar se a captura precede as correções anteriores. Comparar também um estado normal, sem interação, para distinguir densidade permanente de densidade contextual.

Investigar a suavidade do texto: captura reescalada, bitmap de baixa resolução, transformação fracionária, renderização do canvas e compressão podem produzir resultados semelhantes. A imagem isolada não identifica a causa.

## 4. Pesquisa comparativa: oito jogos, oito contributos diferentes

O objetivo da comparação é escolher mecanismos úteis. As adaptações abaixo não afirmam que o Empire deva reproduzir a aparência dos jogos estudados.

| Referência | Evidência consultada | Aplicação proposta ao Empire | Limite da adaptação |
| --- | --- | --- | --- |
| **Kingdom Two Crowns** | O estúdio descreve microestratégia lateral, minimalismo, pixel art e a relação entre monarca, moedas e coroa [S01] | Manter cenário e ação económica no centro da leitura | O Empire tem informação adicional; não ocultar regras de terreno só para ter menos HUD |
| **Thronefall** | A descrição oficial organiza o jogo em construção diurna e defesa noturna [S02] | A saliência da informação acompanha a tarefa e o perigo | Não assumir que o ciclo do Empire tem as mesmas regras |
| **Bad North** | A página oficial centra a tática na forma das ilhas e no posicionamento dos súbditos [S03] | Fazer a inspeção explicar possibilidades espaciais do local | Não converter as faixas laterais do Empire numa interface de RTS isométrico |
| **Factorio** | Os criadores discutem ligação entre objeto e informação, legibilidade, consistência e organização por separadores [S04–S06] | Um componente de recurso, um padrão de inspeção e uma hierarquia reutilizável | A densidade de gestão não deve invadir a exploração móvel |
| **Pentiment** | A equipa liga a apresentação a manuscritos e gravuras; fornece opções de fonte e leitura [S07] | Fazer a identidade nascer do universo; garantir alternativa tipográfica legível | Evitar caligrafia e efeitos de escrita em valores críticos |
| **Against the Storm** | Uma revisão substituiu cálculos pouco legíveis por um indicador de progressão e detalhes adicionais; outra corrigiu ícones e categorias [S08–S09] | Mostrar consequência imediata e permitir aprofundar a regra | Não criar um mostrador para cada variável interna |
| **Into the Breach** | A descrição oficial torna explícita a antecipação de ataques inimigos [S10] | Mostrar origem e consequência de perigos que o jogador pode conhecer | O jogo é por turnos; não importar a revelação total das intenções para um jogo em tempo real |
| **Civilization VII** | Notas oficiais registam ações mais visíveis, dados condicionais, melhorias de tooltips e correções de foco [S11] | Avaliar cada ocultação; manter as ações descobríveis e os dados ligados à seleção certa | “Minimalista” não significa esconder comandos essenciais |

### 4.1. Kingdom: preservar a ligação entre recurso e ação

**Proposta para o Empire:** a moeda deve ser reconhecida pelo mesmo símbolo na HUD, no custo e na confirmação. Quando uma compra termina, o recurso e o objeto afetado dão feedback coordenado. Não é necessário encher o ecrã de moedas animadas ou reproduzir a bolsa de Kingdom. A clareza vem da continuidade entre “tenho”, “vou gastar” e “o que recebo”.

Manter uma leitura numérica exata quando for útil. Se `33` for capacidade, a UI pode explicar “6 moedas · capacidade 33”. Se for outra coisa, essa microcopy é inválida e deve ser substituída pela semântica real.

### 4.2. Thronefall: adaptar a ênfase, estabilizar os controlos

**Proposta:** durante uma aproximação de inimigos, destacar a direção de ameaça e o estado de combate relevante. Durante inspeção, destacar alvo, custo e requisito. A posição de atacar, interagir e moeda não muda entre esses estados. Adaptar a informação é diferente de trocar os botões de lugar.

### 4.3. Bad North: transformar geografia em decisão legível

**Proposta:** a ficha de local deve explicar o que existe ao alcance e o que impede uma atividade. Quando uma condição tiver expressão espacial, mostrar a relação no mundo através de uma marca temporária: margem de água, passagem bloqueada ou área utilizável. A leitura textual e a marca devem apontar para o mesmo requisito.

### 4.4. Factorio: resolver a consistência antes da decoração

Os relatos dos criadores mostram uma tensão útil: aproximar a ação do objeto ajuda, mas quebrar convenções pode tornar um botão menos reconhecível [S04]. **Proposta:** manter um verbo visível nas ações primárias e uma localização previsível para Fechar/Voltar. O selo do Empire pode personalizar o controlo sem obrigar o jogador a descobrir novamente como um botão funciona.

A integração visual entre jogo e outras superfícies documentada pelos criadores também demonstra o valor de um sistema comum [S06]. Para o Empire, esse princípio deve unir menus e HUD, sem forçar ambos a ter a mesma densidade.

### 4.5. Pentiment: identidade expressiva, leitura confortável

**Proposta:** usar carácter editorial nos títulos e no selo, mas texto de leitura rápida em requisitos, números e controlos. A opção de maior legibilidade conserva paleta, composição e símbolos. A personalidade do jogo não pode depender de o jogador aceitar uma fonte difícil.

### 4.6. Against the Storm: resumir a consequência sem perder a regra

**Proposta:** a primeira linha responde “o que impede esta ação?”. A segunda, quando aberta, explica “porquê?”. A leitura técnica completa fica na ficha, nunca numa mensagem longa durante a deslocação. Os estados indisponíveis precisam de motivo, e símbolos diferentes não devem representar o mesmo conceito por acidente.

### 4.7. Into the Breach: informação justa sobre perigo

**Proposta:** uma ameaça conhecida pode gerar uma marca direcional, nome curto e ação possível, por exemplo “Muralha leste sob ataque”. Um perigo ainda não descoberto não deve revelar a sua posição através da HUD. O sistema precisa de distinguir conhecimento do jogador de dados internos da simulação.

### 4.8. Civilization VII: verificar o custo de esconder informação

Uma das revisões consultadas expande as ações das unidades por defeito e retira um contador que deixara de fazer sentido num estado específico [S11]. **Proposta:** esconder o que é irrelevante para o estado; manter o que o jogador precisa de descobrir ou executar. Impulsos e Vigília não devem desaparecer por conveniência estética sem uma auditoria da sua função.

## 5. A identidade visual: Atlas do Império

### 5.1. A ideia que une tudo

O jogador é uma presença dentro do mundo e também alguém que o organiza. A interface deve lembrar instrumentos que servem essas duas necessidades: **marca de território, registo de recursos e observação do tempo**.

Durante a exploração, aparecem apontamentos curtos e pequenos instrumentos escuros. Na gestão, abre-se uma superfície clara de registo, com divisórias e anotações. Ambos usam o mesmo selo, grelha, tipografia funcional, iconografia e linguagem de estados.

Não é necessário justificar que cada número existe fisicamente na mão da personagem. A metáfora serve a identidade e a compreensão; não deve introduzir passos lentos para executar ações simples.

### 5.2. Três motivos próprios

| Motivo | Construção visual proposta | Significado | Onde aparece |
| --- | --- | --- | --- |
| **Linhas de território** | Três traços horizontais de comprimentos diferentes, derivados das faixas do projeto | Terreno organizado e profundidade | Separadores, selo, cabeçalho da ficha e margens do mapa |
| **Canto de registo** | Recorte curto num único canto; terminal quadrado no canto oposto | Documento ou instrumento marcado pelo reino | Botões, fichas, seleção e notificações |
| **Selo do horizonte** | Emblema compacto que reúne os traços e uma abertura central | Fundação e domínio sobre um lugar | Menu principal, contexto de fundação e registos importantes |

As três linhas são um motivo gráfico. Só devem funcionar como indicador de faixa quando cada linha tiver mapeamento inequívoco para a faixa correspondente. Não atribuir valor de gameplay a uma decoração.

O selo exige desenho original numa fase de arte. Não usar uma coroa de uma biblioteca de ícones como identidade definitiva. Fazer variantes monocromáticas, pequenas e de alto contraste; testar se continuam reconhecíveis sem animação.

### 5.3. Materialidade com contenção

- **Superfície de campo:** verde-ardósia profundo e opaco nas áreas de texto; textura subtil apenas nas margens.
- **Superfície de registo:** linho claro e tinta escura para leitura demorada.
- **Metal:** latão pálido usado em moeda, seleção económica e detalhes do selo.
- **Construção:** contornos retos ou escalonados, compatíveis com a geometria do cenário.
- **Profundidade:** sombra curta ou desnível simples; sem volumes de aplicação móvel sobrepostos ao jogo.

O metal não contorna todos os componentes. A textura não atravessa letras. O desenho pode ser rico em identidade e contido em superfície ocupada.

### 5.4. Paleta inicial e função

| Token proposto | Cor | Função |
| --- | --- | --- |
| `surface.field` | `#172A2B` | Fundo opaco de HUD e controlos |
| `surface.raised` | `#233B3C` | Subáreas e controlos secundários |
| `text.primary` | `#F1E9D8` | Texto principal sobre fundo escuro |
| `text.secondary` | `#BDC9C3` | Explicação secundária legível |
| `accent.coin` | `#DAB879` | Moeda e ação económica destacada |
| `state.danger` | `#FFA28E` | Perigo e falha com significado imediato |
| `state.valid` | `#A5CCA5` | Condição cumprida, acompanhada de símbolo/texto |
| `state.info` | `#9CC8DE` | Seleção espacial e informação |
| `surface.folio` | `#E7DECB` | Plano de leitura dos menus de gestão |
| `text.ink` | `#253839` | Texto sobre a superfície clara |

**Verificação calculada dos pares sólidos:** texto principal/campo ≈12,40:1; secundário/campo ≈8,77:1; latão/campo ≈7,92:1; perigo/campo ≈7,71:1; tinta/linho ≈9,22:1. Foram calculados por luminância relativa sRGB. Isto valida apenas estes pares, não a interface completa, nem combinações transparentes ou todos os estados.

A cor da estação pode aparecer num pequeno acento identificado. As cores de perigo, moeda e validade mantêm significado estável em todos os biomas.

### 5.5. Tipografia

**Direção recomendada:** Alegreya para títulos editoriais; Atkinson Hyperlegible para informação funcional. A documentação oficial do Braille Institute fundamenta a escolha de uma família orientada à distinção dos caracteres; o repositório da Alegreya disponibiliza a licença OFL [S23–S24]. Confirmar os ficheiros e licenças exatos ao integrar, manter os avisos e alojar localmente os recursos necessários.

| Uso | Regra inicial de desenho |
| --- | --- |
| Nome de ecrã ou edifício | Serifada expressiva, frases curtas, sem efeitos de escrita |
| Botões, custos, requisitos | Família funcional, peso médio, verbo legível |
| Valores que variam | Algarismos com largura estável quando suportados pela fonte |
| HUD compacta | Evitar frases longas, mas conservar rótulos para conceitos ambíguos |
| Texto ampliado | Redistribuir conteúdo; não encolher outra vez a fonte para caber |

Usar 18–20 CSS px como ponto inicial do texto funcional no protótipo de tamanho real, com escala configurável. Este valor é uma proposta, não uma declaração de conformidade com a XAG 101: essa orientação mede a dimensão visível de caracteres em relação ao ecrã e à densidade, não apenas o `font-size` CSS [S12]. Inspecionar especialmente `1/I/l`, `0/O`, diacríticos e palavras como “Vigília”, “Minério”, “Construção” e “Ação” no conjunto de testes linguísticos.

Não usar uma fonte pixelizada pequena em parágrafos. Se existir uma fonte bitmap de identidade, reservá-la a elementos em que a dimensão real permita leitura confortável e oferecer alternativa.

### 5.6. Ícones, bordas e grelha

Definir uma família original de ícones com grelha mestra consistente, versões óticas pequenas e silhuetas distintas. Moeda, espada, inspeção, água e minério não devem parecer variantes do mesmo losango. Uma base de 24 unidades, com derivados de 16 e 32, é um ponto de partida artístico a validar.

Usar uma grelha de espaçamento de 4 unidades lógicas, com passos 4/8/12/16/24/32. Definir espessura de traço, recorte e sombra em tokens; não ajustar cada ecrã individualmente até “parecer certo”. O tamanho do ícone visível e o alvo interativo são propriedades distintas.

### 5.7. Como verificar a identidade

Apresentar a HUD, a pausa e uma ficha de edifício sem logótipo a um pequeno grupo de jogadores. Perguntar quais pertencem ao mesmo jogo e que sensações transmitem. O teste é exploratório; não prova originalidade universal.

A aprovação artística exige reconhecer os motivos comuns em escalas diferentes. Se a proposta só se distingue por ter uma fonte serifada e uma borda dourada, ainda não atingiu o objetivo.

## 6. Arquitetura da informação

### 6.1. Quatro níveis

| Nível | Pergunta | Conteúdo | Comportamento |
| --- | --- | --- | --- |
| **HUD persistente** | O que preciso de acompanhar agora? | Recurso económico principal, dia/fase, acesso a pausa e controlos relevantes | Compacta e previsível |
| **Contexto** | O que posso fazer neste ponto? | Alvo, ação e custo/restrição principal | Surge ao selecionar ou aproximar; desaparece sem interromper |
| **Inspeção** | Vale a pena fazer isto? | Benefício, condições, alcance, custo completo e consequência | Aberta deliberadamente; leitura aprofundada |
| **Gestão** | Como está o meu reino? | Estado do reino, registos, mapa e definições que existam | Ecrã dedicado com hierarquia própria |

Um problema deve ter uma fonte de dados e diferentes níveis de apresentação. Não manter quatro versões independentes da frase que explica o mesmo bloqueio.

### 6.2. Inventário de informação

| Informação | Lugar principal | Quando ganha destaque |
| --- | --- | --- |
| Moedas disponíveis | HUD | Ao receber, gastar ou faltar para uma ação |
| Capacidade da bolsa, se confirmada | Detalhe do recurso; compacta na HUD quando útil | Próximo do limite ou ao inspecionar |
| Dia e fase | HUD | Mudança de fase ou evento relevante |
| Estação e transição | Relógio/detalhe de tempo | Quando afeta uma decisão próxima |
| Ação do local | Contexto | Alvo selecionado e válido |
| Requisitos de pesqueiro | Ficha do local/edifício | Ao ponderar pesca, não em toda a deslocação |
| Requisitos de mineração | Ficha do local/edifício | Ao ponderar mineração |
| Ameaça conhecida | Marca direcional e aviso prioritário | Enquanto o problema está ativo |
| Histórico de avisos | Estado do reino ou registos | Por consulta |
| Ajuda de comando | Aprendizagem e definições | Primeira utilização, mudança de dispositivo ou pedido |

Não adicionar barras de vida, energia, experiência, minimapa ou indicadores de produção sem confirmar que correspondem a sistemas existentes e a decisões frequentes.

## 7. Composição da HUD

### 7.1. Desktop

- **Canto superior esquerdo:** bolsa/recurso; valor principal e descrição curta. Altura inicial de 56–64 CSS px, a ajustar à fonte efetiva.
- **Topo central:** instrumento de tempo compacto; “Dia 1 · Alvorada”. A estação é informação secundária. Uma progressão visual só representa tempo se existir duração calculável e corretamente comunicável.
- **Canto superior direito:** Reino e Pausa; o objetivo fica numa região própria se a build tiver esse sistema, sem ampliar o relógio indefinidamente.
- **Próximo do alvo:** marca pequena e estável que identifica a seleção. A caixa com texto fica numa zona de contexto que não cobre a personagem.
- **Zona inferior:** apenas pistas de atalhos relevantes. Controlos táteis não aparecem por se ter uma janela pequena.

O layout é ancorado à área efetiva do jogo, considerando barras laterais quando existirem. Evitar esticar o mundo para preencher um rácio diferente.

### 7.2. Telemóvel em horizontal

O conjunto divide-se em duas zonas de polegar com centro livre:

| Zona | Elementos | Regra |
| --- | --- | --- |
| Esquerda inferior | Analógico, Fixar analógico e Correr | Manter acesso direto, estado e posições estáveis |
| Direita inferior | Interagir, Espada/Atacar e Moeda | Ações distintas com silhuetas e rótulos distintos |
| Junto da zona direita | Impulsos e Vigília | Manter acesso direto até auditoria da função e frequência |
| Topo | Moedas, tempo e pausa | Uma leitura compacta sem preencher a largura com caixas |
| Centro | Personagem, ambiente e perigos | Proteger contra mensagens de inspeção automática |

Não é obrigatório que todos os controlos sejam permanentemente opacos. Os símbolos podem ter menos peso visual em repouso; o contorno funcional, rótulo e capacidade de os encontrar têm de continuar suficientes. Uma definição permite maior opacidade.

### 7.3. Dimensões iniciais para toque

| Elemento | Alvo interativo inicial proposto |
| --- | --- |
| Ação contextual principal | 64 × 64 CSS px ou maior conforme rótulo |
| Espada/Atacar e Moeda | 56 × 56 CSS px |
| Correr, Fixar, Impulsos e Vigília | Pelo menos 48 × 48 CSS px; texto pode exigir mais largura |
| Pausa/fechar | Pelo menos 44 × 44 CSS px |
| Analógico | Área de manipulação inicial de 104–128 CSS px, ajustável |
| Separação entre alvos adjacentes | 8 CSS px como ponto inicial; aumentar quando o uso real mostrar erros |

Estes são valores de projeto a testar em aparelhos reais. A WCAG 2.2 distingue o mínimo de 24 × 24 CSS px do critério reforçado de 44 × 44 CSS px, ambos com exceções próprias [S15–S16]. Cumprir uma medida não demonstra conforto de jogo nem conformidade global. O retângulo útil deve continuar a existir quando o desenho visual tem cantos recortados.

### 7.4. Escala, altura e orientação

Definir o modo compacto pela área disponível, pela altura e pela entrada efetiva. Proposta inicial: altura útil inferior a 420 CSS px ativa uma composição de pouca altura; menos de 720 CSS px de largura exige outra distribuição. Estes valores são pontos de teste, não correspondências rígidas com modelos de telefone.

Em ecrãs estreitos, uma ficha de gestão pode ocupar um ecrã dedicado. Em vertical, menus e definições devem continuar utilizáveis. Se o gameplay exigir horizontal, explicar a rotação e preservar a sessão; não apertar todos os controlos num centro inutilizável.

Reservar as margens de segurança do dispositivo [S19]. A interface deve continuar utilizável com as barras do navegador visíveis. Ecrã inteiro é uma opção, não uma condição para conseguir jogar. As unidades de viewport e a área efetivamente visível precisam de tratamento próprio [S20–S21].

### 7.5. Orçamento de ocupação

**Metas iniciais, ainda não medidas no jogo:**

- Em exploração normal, sem inspeção ou modal, procurar que superfícies opacas de informação persistente ocupem no máximo cerca de 12% da área útil.
- Com controlos táteis, apontar inicialmente para um total até cerca de 25% de superfícies opacas. Se o conforto dos alvos exigir mais, rever a composição; não reduzir os alvos para cumprir o número.
- A personagem e a aproximação imediata de ameaças não podem ficar cobertas por mensagens automáticas de gestão.
- Fichas abertas pelo jogador têm outro orçamento: privilegiar leitura confortável e declarar se o mundo continua ativo.

Medir máscaras de superfície e interseções geométricas, separando alvos transparentes de áreas pintadas. A estimativa da captura usou retângulos exteriores e serve de diagnóstico; não é diretamente comparável com uma futura medição de opacidade.

## 8. O fluxo de fundação, redesenhado

Este é o primeiro percurso que deve ser prototipado de ponta a ponta.

### 8.1. Aproximação

No mundo, o local selecionado recebe uma marca discreta. A indicação curta mostra:

> **Fundar neste local**  
> Ver condições

Se houver um custo confirmado e espaço, mostrar o custo. Não inventar um valor e não usar um número de exemplo numa build de produção. O texto não deve afirmar que o local é válido sem `canFound` verdadeiro no domínio.

### 8.2. Inspeção voluntária

A ficha abre por Interagir ou por um comando explícito de inspeção. Deve distinguir:

| Bloco | Conteúdo |
| --- | --- |
| Cabeçalho | Nome do local ou ação: “Fundar neste local” |
| Viabilidade de fundação | Pode fundar / não pode fundar, com motivo global real |
| Potencial local | Atividades possíveis e limitações do terreno |
| Condições | Requisitos satisfeitos e pendentes, ligados à ação correspondente |
| Custo | Recursos gastos e saldo resultante, se os dados estiverem disponíveis |
| Rodapé | Ação de confirmar, Voltar e, quando útil, Mostrar no terreno |

**Pesqueiro:** “Sem água ao alcance” é uma limitação de pesca. Só bloqueia a fundação se isso fizer parte da regra real.

**Poço de minério:** o texto `1 de 2` precisa de interpretação no domínio. Se forem requisitos, apresentar cada requisito. Se forem candidatos, depósitos ou posições, rotular a quantidade corretamente. Até confirmar, conservar a mensagem original na inspeção; não rebatizar o valor como número de depósitos.

### 8.3. Localização da ficha

Em desktop, uma ficha lateral pode coexistir com o mundo se não cobrir o alvo. Em telefone com pouca altura, preferir uma ficha dedicada com retorno explícito. O local permanece identificável por nome, pequeno enquadramento ou marcação; não tentar encaixar um relatório completo entre os polegares.

Um componente curto de contexto e uma ficha longa são duas composições da mesma informação, não o mesmo painel reduzido à força.

### 8.4. Confirmação e segurança da ação

Fundar é uma decisão de maior consequência do que abrir a ficha. A confirmação deve mostrar custo e efeito antes de executar. Pode usar botão explícito de confirmação ou pressão contínua configurável. Se houver pressão contínua, oferecer alternativa de confirmação simples para quem não a consegue manter [S14].

Não aplicar uma confirmação demorada a cada moeda de uma ação económica repetida. A ação Moeda mantém o comportamento conhecido, com alvo claro e proteção contra troca de contexto durante o gesto.

### 8.5. Resultado

Depois de a simulação confirmar a fundação:

1. Atualizar o estado económico a partir do resultado real.
2. Atualizar o lugar e o seu estado de interação.
3. Dar uma confirmação curta junto do local e um registo consultável.
4. Regressar ao jogo com foco e controlos coerentes.

Se falhar, manter o contexto e explicar a razão atual: recursos mudaram, local deixou de ser válido ou outra condição real. Não mostrar sucesso apenas porque a animação acabou.

## 9. Inventário de comandos e contratos de interação

| Comando observado | Decisão proposta | Verificação necessária |
| --- | --- | --- |
| **Fixar** | Conservar; nome acessível “Fixar analógico”; estado ligado/desligado explícito | Confirmar preferência persistida e geometria dos modos fixo/flutuante |
| **Correr** | Conservar acesso direto e alternativa manter/alternar quando viável | Distinguir intenção de correr de condições de velocidade do domínio |
| **Interagir** | Conservar posição; apresentar o verbo específico do alvo sem trocar a ação durante o gesto | Como escolhe alvo e desempata candidatos |
| **Espada** | Preservar ação de combate; usar “Atacar” apenas se corresponder ao comportamento real | É ataque, equipamento ou alternância de arma? |
| **Moeda** | Conservar ação económica independente | Largar, oferecer, investir ou outra semântica? |
| **Impulsos** | Manter disponível; redesenhar o controlo dentro da família comum | Instantâneo, modo, painel ou capacidade com recarga? |
| **Vigília** | Manter disponível; estado explícito se for um modo | Ação, postura, inspeção ou sistema de passagem de tempo? |
| **Pausa** | Acesso constante e discreto; indicar estado real do mundo | Pausa simulação? Há restrições por modo de jogo? |

### 9.1. Regras que não podem variar entre ecrãs

- A posição relativa das ações de combate, moeda e contexto é estável.
- O gesto iniciado pertence ao alvo e à ação selecionados naquele instante.
- Se o alvo ficar inválido, cancelar com motivo; nunca executar noutra entidade sem nova intenção.
- Abrir um menu bloqueia os comandos de jogo correspondentes e limpa estados de pressão ativos.
- Fechar uma ficha devolve o foco a quem a abriu, quando esse elemento ainda existe.
- Atalhos escritos correspondem ao mapa de comandos atual, incluindo remapeamentos.
- Uma ação indisponível deve poder ser compreendida sem ser executada.
- O modo tátil pode ser escolhido manualmente; deteção automática não deve fazê-lo desaparecer devido a um toque acidental no rato.

### 9.2. Estados de cada ação

Inventariar: disponível, focada, premida, ativa, indisponível, em execução e concluída. Estados de recarga só aparecem se a mecânica existir. “Ativa” não é o mesmo que “premida”: Vigília, se for um modo, precisa de continuar assinalada depois de largar o botão.

Uma ação indisponível não fica ilegível. Mostrar o motivo por toque/inspeção e acesso de teclado; evitar que `disabled` elimine a única forma de descobrir o requisito. A solução concreta depende do renderizador e do padrão acessível escolhido.

### 9.3. Multitoque e cancelamento

Validar andar + correr + interagir/atacar nas combinações realmente suportadas. O sistema de entrada associa cada ponteiro à sua intenção; um dedo não herda a ação de outro.

Pointer Events documenta captura e cancelamento de ponteiros [S22]. **Proposta:** libertar as intenções em `pointerup`, `pointercancel`, perda de captura, mudança de foco e ocultação da página; cancelar repetições pendentes e normalizar o analógico. Limitar `touch-action` à área onde o jogo precisa de controlar o gesto, preservando o comportamento dos menus e a ampliação.

## 10. Linguagem e microcopy

Usar português europeu consistente, frases curtas e termos que descrevam a ação. A prosa de ambientação pode existir em descrições opcionais; não deve obscurecer um erro ou um custo.

| Texto observado | Texto proposto | Condição |
| --- | --- | --- |
| “Fundar o Império aqui?” | “Fundar neste local” | Cabeçalho da ficha; decisão final tem confirmação |
| “INTERAGIR: Fundar” | “Fundar” ou “[comando atual] Inspecionar” | Depende de a ação executar ou abrir a ficha |
| “Pesqueiro: sem água ao alcance; aqui não se levanta.” | “Pesqueiro · Sem água ao alcance” | Preserva a razão sem dramatizar o bloqueio |
| “Poço de Minério: 1 de 2 com rocha com passagem ao alcance.” | Separar nome, contagem e condição, depois de validar a semântica | Não inferir o que a contagem representa |
| “Fixar” | “Fixar analógico” no nome acessível e nas definições | Rótulo visual curto pode manter “Fixar” |
| “Primavera · 16 dias” | “Primavera · 16 dias restantes” | Apenas se for uma contagem restante; se for duração total, explicar de outra forma |
| “Espada” | “Atacar” | Apenas se efetivamente executar um ataque |
| “Moeda” | “Largar moeda” / “Investir” / termo real | Só depois de confirmar o comportamento |

### Padrões de mensagem

- **Bloqueio:** ação + motivo específico + possibilidade de correção.
- **Aviso:** problema + localização conhecida + ação disponível.
- **Sucesso:** resultado confirmado + efeito relevante.
- **Estado vazio:** o que falta + como começar, se existir uma próxima ação.

Exemplos de formato, não afirmações sobre mecânicas existentes:

> “Construção indisponível · Falta uma passagem livre.”  
> “Muralha leste sob ataque · Ver local.”  
> “Armazém vazio · Nenhum recurso guardado.”

Não usar “erro desconhecido” se o domínio fornece uma causa. Não exibir nomes internos, códigos de estado ou frases de depuração ao jogador.

## 11. A UI completa: contratos por ecrã

Uma HUD nova rodeada por menus antigos continuaria a parecer uma intervenção parcial. O sistema deve ser aplicado por percurso de utilização, garantindo continuidade entre jogo, inspeção e gestão.

### 11.1. Menu principal

Uma paisagem do jogo funciona como presença visual. O nome Empire e o selo estabelecem a identidade. As ações prioritárias são Continuar, Novo jogo e Definições, conforme as funcionalidades reais. Continuar só surge como disponível quando existir um estado carregável.

Separar carregar, iniciar e apagar. Mostrar progresso de carregamento verdadeiro quando mensurável; caso contrário, usar uma indicação indeterminada honesta. Uma falha de leitura de save tem mensagem e opções de recuperação que existam no sistema.

Não transformar o menu principal num conjunto de cartões promocionais, estatísticas inventadas ou faixas de objetivos que o jogador ainda não compreende.

### 11.2. Pausa

Retomar é a ação dominante. Estado do reino, Controlos, Definições e restantes opções reais ficam organizados numa lista curta. Guardar e Sair seguem as regras existentes; se não houver gravação manual, não inventar um botão que apenas simula esse comportamento.

O cabeçalho indica “Jogo em pausa” somente quando a simulação está efetivamente parada. Se um modo mantiver o mundo ativo, indicar esse facto e reduzir a profundidade de navegação exigida durante perigo.

### 11.3. Estado do reino

Ecrã de leitura em superfície de linho, com tinta escura e cabeçalho comum. Usar grupos como Economia, Defesa, Território e Registos apenas quando existirem dados que sustentem cada grupo.

Cada linha deve responder a uma pergunta: saldo, problema, localização, tendência calculada ou próxima ação. Um valor sem unidade, intervalo ou significado é dívida de design.

**Proposta de composição:** resumo curto das exceções que exigem decisão; depois os dados completos por categoria. Cada problema selecionável conduz ao local ou à ficha correspondente, se o jogo permitir essa navegação. Não fabricar um índice de “saúde do reino” agregando números sem definição de gameplay.

### 11.4. Ficha de edifício

Estrutura comum: nome → estado → função → custo/consequência → condições → ações. Uma construção produtiva pode acrescentar produção e armazenamento quando esses sistemas existirem.

Mostrar razões concretas para inatividade: falta de recurso, acesso, capacidade ou trabalhador, conforme o domínio. “Parado” sem razão obriga o jogador a diagnosticar o sistema. Mostrar a unidade temporal dos rendimentos; não misturar por dia, por ciclo e total sem rótulo.

Se a escolha for melhorar um edifício, apresentar estado atual e resultado da melhoria numa comparação curta. O cálculo é do domínio, não do componente visual.

### 11.5. Mapa e território

O mapa deve respeitar a estrutura espacial real. Para uma apresentação lateral com faixas, estudar uma representação que conserve posição longitudinal, faixas e ligações. Não usar automaticamente um mapa top-down se ele criar relações espaciais que não existem.

Separar visitado, visto e desconhecido. Entradas subterrâneas apontam para um lugar com origem reconhecível. Uma rota entre superfície e subsolo é apresentada como ligação; não como um novo ponto aleatório sem proveniência.

O mapa partilha marcas de água, minério, edifício e perigo com a inspeção. Não existe um segundo dicionário de ícones para o mesmo mundo.

### 11.6. Armazéns e transferências

Se a transferência manual existir, mostrar origem, destino, quantidade e capacidade disponível. Tornar legível a diferença entre guardar, retirar e vender. As duas colunas pertencem ao mesmo componente, com direção explícita e ação reversível quando o sistema o permitir.

Se o armazenamento for automático, a interface mostra regras e estado, sem fingir que há uma operação manual. Um espaço vazio pode ser apresentado como utilizável; não precisa de uma recompensa fictícia para justificar a sua existência.

### 11.7. Definições e controlos

Organizar por tarefa: Imagem, Som, Interface, Controlos e Acessibilidade, ajustando aos sistemas disponíveis. “Interface” inclui escala e densidade; “Controlos” inclui posições e comportamento de toque. Evitar distribuir a mesma preferência por dois menus.

Cada opção deve mostrar valor atual e efeito. Permitir repor uma categoria sem apagar todas as preferências. Repor layout tátil não deve reiniciar preferências de áudio ou um save.

### 11.8. Confirmações, falhas e estados vazios

Adotar um componente comum, com título, consequência, ação e saída. Apagar progresso exige confirmação específica; uma ação rotineira reversível não precisa de um modal a cada utilização.

O padrão de modais do WAI-ARIA fornece a base para foco, contenção da navegação, Escape e retorno ao elemento de origem [S25]. Em renderização por canvas, criar comportamento equivalente e uma camada semântica apropriada; desenhar uma caixa não cria um diálogo acessível.

### Matriz de aplicação do sistema

| Ecrã | Superfície dominante | Assinatura partilhada | Informação prioritária |
| --- | --- | --- | --- |
| HUD | Campo escuro compacto | Divisórias de território, selos pequenos | Recurso, tempo e contexto |
| Fundação | Ficha de registo | Canto recortado, selo e rótulos comuns | Viabilidade, limitações e custo |
| Edifício | Ficha de registo | Mesmos estados, mesma ordem de leitura | Estado, benefício e condição |
| Pausa | Campo escuro / registo | Cabeçalho e botões comuns | Retomar e navegação |
| Estado do reino | Registo claro | Ícones e separadores comuns | Exceções e gestão |
| Mapa | Carta legível | Mesmas marcas de recursos e locais | Conhecimento espacial |
| Definições | Registo legível | Mesmo foco e estados dos controlos | Valor atual e mudança previsível |

## 12. Relação com biomas, estações e subsolos

O trabalho anterior do projeto procura lugares e ambientes com coerência. A UI deve tornar essa coerência perceptível, sem substituir a leitura do mundo por legendas permanentes.

### 12.1. Bioma como causa

Quando uma condição de terreno muda uma decisão, a ficha deve explicar a relação: recurso disponível, restrição de construção, condição de passagem ou efeito sazonal confirmado. Não acrescentar um bónus de bioma apenas para ter uma linha colorida.

Uma ficha que diz “sem água ao alcance” pode oferecer uma marca do alcance efetivamente usado pela regra. Não desenhar um raio idealizado se a regra depende de conectividade ou percurso. A geometria visível precisa de representar o teste real.

### 12.2. Estações como informação operacional

O relógio responde a “em que momento estamos?”. O detalhe da estação responde a “o que muda e quando?”. Um evento sazonal importante pode ganhar um aviso temporário; um texto extenso sobre todos os efeitos não fica permanente no topo.

Se a duração da fase for variável ou desconhecida pelo jogador, não mostrar uma contagem exata derivada de informação que não devia conhecer. Distinguir “restam”, “duração” e “dia da estação”.

### 12.3. Subsolos com origem

Ao entrar, mostrar um cabeçalho breve que preserve a identidade: nome do lugar e ligação à superfície, quando conhecidos. Manter a saída legível. A interface não cria sensação de masmorra através de uma barra épica quando o lugar é apenas um depósito vazio.

O relatório anterior estabelecia que uma entrada precisa de espaço utilizável e de razão espacial para existir. A UI pode ajudar a identificar uso e ligação, mas **não pode corrigir um espaço inválido apenas através de texto ou ícones**. O gerador continua responsável pela geometria e pela acessibilidade.

### 12.4. Conhecimento e incerteza

Nos dados de apresentação, distinguir conhecido, estimado, desconhecido e indisponível. “Ainda não explorado” não equivale a “não existe”. Um contador zero não deve representar ausência de informação.

## 13. Avisos, aprendizagem, som e movimento

### 13.1. Prioridades de aviso

| Prioridade | Exemplo de categoria | Apresentação proposta | Persistência |
| --- | --- | --- | --- |
| Crítica | Ameaça imediata a um objetivo conhecido | Direção, símbolo e frase curta | Mantém-se enquanto a condição crítica durar |
| Decisão | Ação disponível ou bloqueio relevante | Contexto ou faixa discreta | Até decisão ou mudança da condição |
| Informativa | Ganho, conclusão ou descoberta | Feedback breve associado ao resultado | Curta; histórico quando fizer sentido |
| Ambiente | Mudança de fase ou nome de local | Indicação subtil | Breve e sem roubar foco |

No gameplay, propor no máximo um aviso textual de topo por prioridade dominante, com agregação dos restantes. Não fazer uma fila longa de notificações impedir a chegada de um aviso crítico. Ao resolver a causa, atualizar ou retirar o aviso; o histórico conserva o resultado.

Não mostrar simultaneamente a mesma falha em modal, toast, painel e marcador. O contexto apresenta a causa principal; o detalhe acrescenta explicação.

### 13.2. Aprendizagem contextual

Ensinar uma ação quando ela se torna relevante. Uma dica explica objetivo e comando atual; não apresenta todos os botões no início. O jogador pode dispensar e recuperar a ajuda. A opção de manter rótulos visíveis existe para quem prefere referências constantes.

O primeiro contacto com moeda ensina a sua operação real. O primeiro local ensina inspeção. O primeiro bloqueio ensina a consultar requisitos. Não usar uma sequência de pop-ups que impede observar o que está a ser ensinado.

### 13.3. Som

Propor uma família curta: seleção, confirmação, impossibilidade e aviso. Materiais sugeridos: toque seco de instrumento, moeda discreta e marca de registo. Evitar sons longos a cada foco de menu.

Som suplementa informação visual. A mesma ação permanece compreensível com o áudio desligado. O volume de UI deve ser ajustável sem obrigar a desligar o ambiente.

### 13.4. Movimento

Valores iniciais de afinação: resposta de pressão imediata; transições curtas de cerca de 100–180 ms; confirmação discreta com limite de duração; nenhum elemento crítico espera pela animação para aceitar input. São propostas, não limiares universais demonstrados pelas fontes.

Não animar o aparecimento inicial da HUD de forma a atrasar o jogo. Não repetir pulsações em todas as ações disponíveis. Movimento reduzido elimina deslocações decorativas e flashes, mantendo mudança de estado.

## 14. Acessibilidade e conforto como parte do desenho

As fontes XAG e W3C são referências de conceção, não uma certificação desta proposta [S12–S18]. A implementação deverá ser verificada no contexto real do jogo.

| Tema | Especificação proposta | Como verificar |
| --- | --- | --- |
| Contraste | Texto corrente pelo menos 4,5:1; sinais funcionais pelo menos 3:1, respeitando contexto e exceções das referências | Cores reais em todos os estados e fundos [S17–S18] |
| Alto contraste | Modo de superfícies opacas, texturas reduzidas e pares reforçados | Verificar todos os componentes; a XAG 102 orienta 7:1 nesse modo [S13] |
| Cor | Símbolo e texto acompanham risco, validade e seleção | Ler a UI em escala de cinzentos e com simulações, depois testar com pessoas |
| Texto | Escala até 200% como objetivo, com reflow e sem perder ações | Frases longas, rótulos e valores extremos [S12] |
| Entrada | Remapear ações quando suportado; opções manter/alternar para pressões prolongadas | Testes com teclado, comando e toque [S14] |
| Motricidade | Alvos espaçados e layout ajustável | Utilização repetida, não apenas uma captura [S15–S16] |
| Foco | Visível, previsível e recuperado depois de fechar painéis | Percursos só com teclado/comando [S25] |
| Avisos acessíveis | Mensagens de estado semanticamente identificadas | Leitor de ecrã e ausência de anúncios excessivos [S26] |
| Movimento | Opção de redução, sem flashes decorativos recorrentes | Inspeção de todas as transições |
| Transparência | Opacidade ajustável e fundo estável para ler | Cenário claro, escuro, movimentado e com efeitos |

Uma camada DOM bem rotulada pode melhorar a acessibilidade de menus e mensagens, mas não torna automaticamente o gameplay espacial acessível a uma pessoa cega. Definir esse âmbito separadamente se o projeto o pretender. Não anunciar acessibilidade total apenas por existirem nomes ARIA nos botões.

## 15. Arquitetura técnica proposta

### 15.1. Primeiro descobrir a arquitetura atual

Inventariar renderizador, árvore de UI, fontes, input, escala, sistema de pausa, dados apresentados e componentes já reutilizados. Identificar qual é a fonte de verdade de cada recurso e requisito. Registar quais as melhorias anteriores já presentes, para as conservar.

Não migrar de tecnologia só para realizar este desenho. Se a UI atual for canvas, pode continuar a ser canvas com layout coerente. Se já existir DOM para menus, aproveitá-lo. Uma arquitetura híbrida é uma opção fundamentada pelo inventário, não uma obrigação deste plano.

### 15.2. Separar domínio, apresentação e execução

O domínio responde a perguntas como “pode fundar?”, “qual o custo?” e “que requisito falha?”. A apresentação escolhe o nível de detalhe. O sistema de input emite uma intenção; a simulação valida e devolve o resultado.

**Contratos propostos; nomes ilustrativos, não ficheiros confirmados:**

```ts
type RequirementView = {
  id: string;
  labelKey: string;
  state: 'met' | 'unmet' | 'unknown';
  reasonKey?: string;
  observed?: number;
  required?: number;
  unitKey?: string;
};

type ActionView = {
  id: string;
  labelKey: string;
  targetId: string;
  available: boolean;
  blockedReasonKey?: string;
  requirements: RequirementView[];
  costs: Array<{ resourceId: string; amount: number }>;
  consequenceKey: string;
};

type HudView = {
  worldRevision: number;
  inputMode: 'touch' | 'keyboardMouse' | 'gamepad';
  selectedTargetId?: string;
  actions: ActionView[];
  alerts: Array<{
    id: string;
    priority: 'critical' | 'decision' | 'info';
    textKey: string;
    knownLocationId?: string;
  }>;
};
```

`worldRevision` ajuda a identificar a origem de uma apresentação; não substitui a validação atual da ação. Os valores demonstrativos e o texto localizado nunca decidem se uma construção é válida.

### 15.3. Componentes mínimos

| Componente proposto | Responsabilidade |
| --- | --- |
| `ResourceReadout` | Valor, unidade, capacidade quando aplicável, custo e variação |
| `TimeReadout` | Dia, fase, estação e explicação temporal |
| `ContextPrompt` | Alvo e uma ação contextual curta |
| `InspectionPanel` | Condições, consequência e ação deliberada |
| `ActionControl` | Estados visuais, nome acessível e associação à intenção |
| `TouchMovement` | Analógico e preferências de Fixar/Correr |
| `NoticeRegion` | Priorização, agregação e duração dos avisos |
| `MenuShell` | Cabeçalho, navegação, retorno e linguagem comum |
| `RequirementRow` | Estado e razão de uma condição |
| `ConfirmationDialog` | Consequência, confirmar e cancelar |

Criar variantes por densidade e entrada. Evitar versões “mobile” e “desktop” com cópias independentes das regras e mensagens.

### 15.4. Uma geometria por componente

Cada componente recebe ou calcula um retângulo de layout. Fundo, texto, ícones, foco, animação e hitbox usam essa geometria. A transformação da câmara não modifica os controlos de ecrã.

Medir texto com a fonte final carregada. Uma mudança de escala ou idioma invalida a medição. Aplicar limites ao conteúdo e reflow; não posicionar linhas por constantes espalhadas no código.

Esta decisão também responde ao histórico de problemas de desencontro entre molduras e texto, sem assumir que ainda existem na build atual.

### 15.5. Nitidez e escala

Renderizar o mundo pixel art e a tipografia conforme necessidades distintas. Usar nearest-neighbor quando adequado aos sprites; a propriedade `imageSmoothingEnabled` controla suavização de imagens escaladas no canvas, não é uma correção universal para texto [S27].

Dimensionar a superfície de desenho segundo área CSS e DPR, com limites de desempenho explícitos. Evitar aplicar um `transform: scale()` a toda a HUD para a fazer caber num telefone. Testar posições fracionárias, zoom e mudanças de DPR.

Não aplicar efeitos de bloom, correção de cor do cenário ou filtros de píxeis à camada de leitura sem uma razão validada. A HUD não deve mudar de contraste porque o sol se pôs.

### 15.6. Navegador e área útil

Usar as margens seguras documentadas por `env(safe-area-inset-*)` [S19]. Definir uma política para `svh`/`dvh`: a primeira pode favorecer estabilidade, a segunda acompanha a dimensão dinâmica; ambas devem ser testadas com a interface do navegador [S21]. Não somar correções cegas de altura e safe-area que produzam margens duplicadas.

`VisualViewport` permite observar alterações da área visível, incluindo teclado e zoom [S20]. Os controlos não devem saltar de posição no meio de um gesto. Em caso de alteração estrutural, cancelar a intenção com segurança e refazer o layout num ponto controlado.

Não desativar zoom globalmente como solução para encaixe. O nome de local, os menus e as definições têm de continuar legíveis quando o utilizador amplia a interface.

### 15.7. Estado, desempenho e persistência

- Atualizar valores por alteração relevante; evitar reconstruir todos os painéis a cada frame.
- Cachear molduras e ícones quando isso beneficiar o renderizador existente.
- Evitar blur de fundo extenso sobre cenário animado em dispositivos limitados.
- Persistir preferências de UI separadamente do estado do mundo.
- Validar o layout guardado depois de rotação, alteração de escala e mudança de dispositivo; oferecer reposição de controlos.
- Preservar dados de jogo e formatos de save durante a migração de apresentação, salvo necessidade documentada.
- Medir p95 de frame time, tempo de abertura de fichas e alocações com o mesmo cenário, aparelho e build. Não afirmar um ganho sem baseline.

### 15.8. Ordem de camadas

Definir explicitamente mundo, marcas de seleção, HUD, inspeção, avisos e modal. Tooltip de terreno nunca cobre a ação que o jogador tenta premir. Um modal impede interação nas camadas inferiores; `pointer-events` sozinho não resolve foco, teclado ou simulação.

## 16. Produção de arte e biblioteca de componentes

### 16.1. Materiais a produzir

| Entrega | Conteúdo mínimo | Critério de qualidade |
| --- | --- | --- |
| Folha de identidade | Selo, três motivos, proporções e usos | Reconhecível a pequena escala |
| Paleta funcional | Pares aprovados por superfície e estado | Contraste medido, sem significados contraditórios |
| Tipografia | Títulos, rótulos, números e leitura longa | Diacríticos e ampliação verificados |
| Molduras | HUD, ficha, menu, aviso e confirmação | Poucas famílias que partilham construção |
| Ícones | Apenas conceitos do jogo e navegação necessária | Silhuetas distinguíveis e versões pequenas |
| Estados | Normal, foco, pressão, ativo, bloqueado e resultado | Diferenças legíveis sem depender só de cor |
| Som e movimento | Pequena biblioteca com regras de uso | Feedback breve, consistente e opcional |
| Exemplos reais | Fundação, combate, armazém, subsolo e definições | Provar reutilização em situações diferentes |

Bibliotecas de ícones podem servir no protótipo funcional. Na arte final, substituir os ícones identitários por uma família própria, mantendo os significados que os jogadores já aprenderam.

### 16.2. Critérios de direção artística

Evitar uma colagem de madeira, pergaminho envelhecido, correntes, runas, brasões e metal em cada painel. Selecionar os materiais que servem o universo do Empire e usá-los com disciplina.

O recorte assimétrico e as marcas de território têm prioridade sobre textura. Primeiro aprovar silhueta e hierarquia em escala de cinzentos; depois afinar cor e material. O resultado pode ser identificado mesmo quando o jogador ativa alto contraste ou reduz efeitos.

### 16.3. Pré-visualização conceptual desta proposta

A pré-visualização na conversa demonstra a relação entre HUD, inspeção e registo do reino. É um estudo de apresentação e navegação, com cenário esquemático e dados de demonstração identificados. Não é uma captura de uma build nova, nem prova de ergonomia no aparelho.

As funções de Impulsos, Vigília e Moeda permanecem sujeitas à auditoria descrita acima. O estudo não inventa o seu funcionamento. O desenho final de pixel art, emblema e ícones faz parte da produção de arte. O estudo usa fontes de substituição quando as famílias propostas não estão instaladas.

A verificação desta entrega incluiu integridade das referências, cálculo dos pares de contraste, sintaxe do script e execução da navegação/opções num modelo de DOM. A renderização num navegador automatizado não foi concluída porque não estava disponível o executável necessário. O layout final, o foco real, as fontes e a ergonomia continuam sujeitos à validação visual e aos testes em aparelhos definidos neste plano.

## 17. Plano de execução por etapas

Os intervalos seguintes são estimativas de esforço para uma equipa pequena com apoio de programação e arte. Não são um calendário prometido. O inventário da arquitetura e a disponibilidade de dispositivos podem alterar substancialmente o esforço.

| Etapa | Esforço indicativo | Trabalho | Saída necessária |
| --- | --- | --- | --- |
| **A — Baseline** | 1–2 dias de trabalho | Build atual, estados, dispositivos, contratos dos comandos e inventário de ecrãs | Diagnóstico reproduzível e lista do que já funciona |
| **B — Estrutura** | 2–3 dias | Wireframes de exploração, fundação e gestão em PC e telefone | Hierarquia e ações verificáveis sem depender de arte |
| **C — Direção visual** | 2–4 dias | Selo, componentes, paleta, fontes e estados | Folha do sistema e três ecrãs coerentes |
| **D — Percurso vertical** | 3–5 dias | Aproximar → inspecionar → confirmar → atualizar mundo/recursos | Fluxo de fundação integrado, com input seguro |
| **E — Restante UI** | 3–6 dias | Pausa, reino, edifícios, mapa, armazenamento e definições existentes | Mesma linguagem nos percursos principais |
| **F — Dispositivos e afinação** | 2–4 dias | Toque, escala, foco, navegador, desempenho e teste com jogadores | Evidência dos critérios de aceitação |

Total indicativo: **13–24 dias de trabalho**, antes de descobrir necessidades fora do âmbito, como reescrever sistemas de input ou acessibilidade integral do gameplay. Algumas atividades podem sobrepor-se numa equipa, mas não contar o mesmo trabalho como concluído duas vezes.

### 17.1. Backlog prioritário

| ID | Prioridade | Entrega | Dependência | Critério verificável |
| --- | --- | --- | --- | --- |
| HUD-01 | P0 | Capturas e estados de referência | Build identificada | Mesma seed/save e área útil registados |
| HUD-02 | P0 | Dicionário de ações e métricas | HUD-01 | Semântica de 6/33, 16 dias e 1 de 2 documentada |
| HUD-03 | P0 | Layout e hitboxes coerentes | HUD-01 | Texto, moldura e alvo usam a mesma geometria |
| HUD-04 | P0 | Contexto curto e inspeção voluntária | HUD-02/03 | Centro livre ao aproximar; detalhe acessível |
| HUD-05 | P0 | Entrada segura e controlos preservados | HUD-02/03 | Correr/Fixar funcionam; cancelamentos não deixam ações presas |
| UI-01 | P1 | Tokens, fontes e componentes | Etapa B | Estados coerentes em HUD, ficha e pausa |
| UI-02 | P1 | Fluxo de fundação completo | HUD-04/05, UI-01 | Custo e condições vêm do domínio; confirmação revalida |
| UI-03 | P1 | Pausa e Estado do reino | UI-01 | Percurso com foco e retorno previsíveis |
| UI-04 | P1 | Edifícios e armazenamento | UI-01/02 | Mesmas razões e valores em todas as vistas |
| UI-05 | P1 | Mapa e ligações subterrâneas | Dados espaciais existentes | Não revela locais desconhecidos nem relações inventadas |
| A11Y-01 | P1 | Escala, contraste e entrada | UI-01 | Conteúdo e ações preservados nos perfis suportados |
| QA-01 | P1 | Percursos em aparelhos reais | Etapa D | Sem regressão de input e leitura |
| ART-01 | P2 | Arte final de selo e ícones | Estrutura aprovada | Identidade reconhecível em tamanho real |
| POL-01 | P2 | Som, transições e aprendizagem | Fluxos estabilizados | Feedback discreto e modo de movimento reduzido |

### 17.2. Ordem sugerida de alterações no repositório

Preparar mudanças pequenas e reversíveis: contratos e medição; componentes básicos; HUD e contexto; input; fundação; restantes menus; afinação. Cada alteração deve apresentar capturas de estados relevantes e a verificação concreta que a suporta.

Evitar uma primeira alteração que substitui toda a UI e o input ao mesmo tempo. Manter a possibilidade de comparar apresentações enquanto o novo percurso não cumprir os critérios. A publicação deve corresponder a uma build identificada e testada, sem alegar que a validação de um protótipo valida o jogo.

## 18. Verificação e critérios de aceitação

### 18.1. Matriz de ambientes

Dimensões abaixo são cenários sintéticos em CSS para descoberta de problemas; confirmar valores reais no aparelho. Não deduzir viewport CSS da resolução física de uma captura.

| Cenário | Configuração inicial | Risco a verificar |
| --- | --- | --- |
| PC habitual | 1920 × 1080, teclado/rato | Relação de escala, leitura e espaço vazio |
| Portátil | 1366 × 768 | Painéis e requisitos longos |
| Ecrã ultralargo | 2560 × 1080 | Ancoragem à área jogável e deslocação excessiva do olhar |
| Alta densidade | 2560 × 1440 e DPR alternativo | Nitidez, tamanho físico e desempenho |
| Telefone horizontal | 844 × 390 e 932 × 430 | Polegares, safe-area e pouca altura |
| Telefone pequeno | 667 × 375 | Conflitos de texto e comandos |
| Telefone vertical | 390 × 844 | Menus, rotação e preservação da sessão |
| Tablet horizontal | 1024 × 768 | Híbrido toque/rato, escala e distribuição |
| Texto ampliado | 150% e 200% | Reflow, ação principal e mensagens completas |

Testar no navegador do telefone realmente usado, incluindo Safari/iOS e Chrome/Android quando fizerem parte do suporte do projeto. Um emulador desktop não reproduz integralmente barras móveis, teclado, gestos do sistema ou fadiga de toque.

### 18.2. Estados obrigatórios

Exploração normal; local válido; local inválido; recurso insuficiente; condição desconhecida; alvo alterado; inspeção aberta; perigo durante inspeção; mudança de estação; interior/subsolo; armazém vazio; nome longo; valores grandes; pausa; retoma; perda de foco; rotação; controlo desconectado; retorno à página.

Não é necessário inventar mecânicas para testar: escolher os equivalentes reais na build. Acesso a seed/save fixos torna os testes visuais comparáveis.

### 18.3. Testes automáticos com propósito

- **Contrato de domínio:** a mesma ação apresenta os mesmos requisitos na HUD e na ficha; executar revalida a condição real.
- **Seleção:** um gesto iniciado num alvo não é aplicado a outro após mudança de contexto.
- **Cancelamento:** terminar/cancelar um ponteiro, ocultar a página ou abrir um modal não deixa movimento, corrida ou repetição de moeda ativos.
- **Layout:** os retângulos de texto e controlo ficam dentro das áreas permitidas nos perfis suportados; alvos não se sobrepõem.
- **Foco:** abrir e fechar gestão preserva percurso de teclado/comando; o mundo não recebe input de um modal.
- **Preferências:** Fixar analógico, escala e comportamento de Correr sobrevivem a recarregamento e migração.
- **Regressão visual:** pequeno conjunto de estados determinísticos, com fontes carregadas e efeitos temporais controlados.

Evitar testes que apenas afirmam que uma constante de cor tem o valor definido no código. Os testes devem proteger comportamento e informação, não congelar detalhes de decoração.

### 18.4. Teste com jogadores

Uma primeira ronda com cerca de 5–8 participantes de experiências diferentes pode revelar problemas de compreensão; não é uma amostra para conclusões estatísticas fortes. Incluir pessoas que jogam no telefone e quem precisa de texto maior. Fazer observação sem explicar previamente onde clicar.

Tarefas: identificar moedas; explicar a contagem da estação; encontrar o custo de fundar; perceber que falta água para pesca; cancelar sem gastar; fixar analógico; correr; consultar Estado do reino; retomar; perceber uma ameaça conhecida.

Registar hesitações, comandos acidentais, interpretações erradas e sobreposição das mãos. Perguntar “o que esperavas que acontecesse?” depois da ação ajuda a distinguir um problema de arte de um problema de semântica.

### 18.5. Metas de aprovação

| Meta | Critério inicial |
| --- | --- |
| Entendimento imediato | Encontrar moedas e fase do dia sem abrir menus; investigar se a maioria demora mais de cerca de 2 segundos |
| Requisito | Explicar corretamente o bloqueio apresentado e a ação a que pertence |
| Sem perda de comandos | Correr, Fixar e restantes ações existentes mantêm acesso e comportamento necessários |
| Fundação segura | Nenhum gasto é executado por simples abertura da ficha ou troca involuntária de alvo |
| Leitura do mundo | Personagem e ameaça imediata legíveis em exploração/combate sem modal deliberado |
| Consistência | Mesmo conceito, mesmo símbolo, mesmo termo e mesma regra de estado |
| Navegação | Chegar ao Estado do reino em até duas ações de navegação desde o gameplay |
| Acessibilidade | Nenhum texto ou botão essencial desaparece nos perfis aprovados de escala |
| Desempenho | Sem regressão significativa previamente acordada face ao baseline do mesmo cenário/aparelho |
| Identidade | Participantes associam HUD, ficha e pausa ao mesmo jogo sem o logótipo |

As metas temporais e de ocupação são hipóteses de produto a validar. Se entrarem em conflito com compreensão ou acessibilidade, rever a composição e a própria meta.

## 19. Riscos concretos e decisões pendentes

| Risco | Sinal | Resposta prevista |
| --- | --- | --- |
| Arte medieval genérica | Só a cor e a fonte distinguem a interface | Aprovar os três motivos e a continuidade entre ecrãs |
| Minimalismo excessivo | Jogador não encontra ação ou requisito | Restaurar acesso direto e explicação contextual |
| Contexto instável | Verbo ou alvo muda enquanto o dedo está premido | Fixar intenção no início e cancelar quando necessário |
| Dados falsos na apresentação | Contagens ganham significado inventado | Validar contrato de cada métrica antes da microcopy |
| Desencontro com a build atual | Corrigir novamente algo já resolvido | Reproduzir a captura e identificar versão |
| Texto ilegível no telefone | Protótipo bonito, uso real difícil | Medir dimensão efetiva e testar em aparelho |
| Ocultação das ameaças | Ficha grande com mundo ainda ativo | Definir política de pausa/inspeção por modo de jogo |
| Bioma altera semântica visual | Aviso parece sucesso noutra região | Cores funcionais estáveis e redundância por símbolo/texto |
| Alcance desenhado incorretamente | Círculo visual não corresponde à conectividade | Renderizar a geometria real da regra |
| Regressão de preferências | Correr/Fixar ou posição personalizada desaparecem | Migração e validação das preferências |

Antes de implementar, resolver no código: significado de cada contagem; função exata de cada comando; regras de pausa; escolha de alvo; fonte dos requisitos; renderer; dispositivos suportados; estado das correções anteriores. São tarefas de auditoria técnica, não perguntas que bloqueiam a definição visual deste plano.

## 20. Primeiro pacote de trabalho recomendado

O primeiro incremento deve conter somente o suficiente para provar o sistema em uso real:

1. HUD persistente com recursos, tempo e acessos compactos.
2. Contexto de fundação curto, sem painel automático sobre a personagem.
3. Ficha de local que distingue fundação, potencial e requisitos.
4. Controlos redesenhados, preservando Correr, Fixar e todas as ações necessárias.
5. Pausa e Estado do reino com a mesma tipografia, cores, componentes e navegação.
6. Verificação em PC e telefone, com captura antes/depois do mesmo estado.

Só depois generalizar para todos os edifícios, mapa e subsolos. A identidade deve ser aprovada num percurso completo, não numa imagem estática isolada.

### Texto de passagem para implementação

> Implementar a direção Atlas do Império com base neste documento. Começar por auditar a build atual e os contratos de input e dados. Preservar Correr, Fixar analógico e restantes ações existentes. Não atribuir significado às contagens 6/33, 16 dias ou 1 de 2 antes de o confirmar. Substituir a inspeção central automática por contexto curto e ficha voluntária. Criar tokens, componentes e geometria comuns; revalidar ações no domínio; manter alvos e posições estáveis durante gestos. Entregar um percurso completo de fundação, pausa e Estado do reino, com capturas comparáveis e verificação em dispositivos reais. Tratar a pré-visualização conceptual como orientação de composição, não como implementação de gameplay ou arte final.

## 21. Fontes e rastreabilidade

Todas as referências abaixo foram consultadas durante esta pesquisa, em 7 de outubro de 2026. As datas nos títulos identificam o caso analisado; não indicam a versão atual completa dos jogos. Os URLs permitem verificar a evidência fora desta conversa.

### Jogos e decisões de design

| ID | Fonte primária | Evidência utilizada |
| --- | --- | --- |
| S01 | [Kingdom — Kingdom Two Crowns](https://kingdomthegame.com/kingdom-two-crowns/) | Enquadramento oficial de estratégia lateral, minimalismo, pixel art, moedas e coroa |
| S02 | [GrizzlyGames / Mythwright — Thronefall, descrição oficial na Steam](https://store.steampowered.com/app/2239150/Thronefall/) | Construção diurna, defesa noturna e economia/defesa |
| S03 | [Plausible Concept — Bad North](https://www.badnorth.com/) | Tática, forma das ilhas e posicionamento |
| S04 | [Wube — Friday Facts #238: The GUI update, Part II](https://factorio.com/blog/post/fff-238) | Legibilidade, ligação espacial entre informação e objeto e reconhecimento de ações |
| S05 | [Wube — Friday Facts #338: The (real) Character GUI](https://factorio.com/blog/post/fff-338) | Organização da interface de personagem por separadores |
| S06 | [Wube — Friday Facts #352: New website](https://factorio.com/blog/post/fff-352) | Coerência visual entre superfícies e reutilização da linguagem do jogo |
| S07 | [Xbox Wire — Accessibility Showcase, 13/10/2022](https://news.xbox.com/en-us/2022/10/13/xbox-accessibility-showcase-2022/) | Pentiment: inspiração artística, fontes, contraste, escala e Easy Read |
| S08 | [Eremite Games — Rainpunk Update, Part 2, 02/02/2023](https://eremitegames.com/rainpunk-update-2/) | Progressão visível e explicação aprofundada de cálculos |
| S09 | [Eremite Games — Time is Money Update, 26/05/2022](https://eremitegames.com/time-is-money-update/) | Requisitos, ícones, categorias, mensagens e correções de sobreposição |
| S10 | [Subset Games — Into the Breach, descrição oficial na Steam](https://store.steampowered.com/app/590380/Into_the_Breach/) | Antecipação explícita dos ataques no seu combate por turnos |
| S11 | [Firaxis / 2K — Civilization VII, notas de 25/03/2025](https://support.civilization.com/hc/en-us/articles/39719857984531-Civilization-VII-Patch-Notes-March-25-2025) | Ações visíveis, informação contextual, notificações, seleção e foco |

### Leitura, acessibilidade e interação

| ID | Fonte | Evidência utilizada |
| --- | --- | --- |
| S12 | [Microsoft — XAG 101: Text display](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/101) | Dimensão efetiva, legibilidade, configuração e escala de texto |
| S13 | [Microsoft — XAG 102: Contrast](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/102) | Contraste de elementos, fundos variáveis e modo reforçado |
| S14 | [Microsoft — XAG 107: Input](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/107) | Remapeamento por ação e alternativas de entrada |
| S15 | [W3C — WCAG 2.2, Target Size Minimum](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html) | Critério AA de 24 × 24 CSS px e respetivas exceções |
| S16 | [W3C — WCAG 2.2, Target Size Enhanced](https://www.w3.org/WAI/WCAG22/Understanding/target-size-enhanced.html) | Critério AAA de 44 × 44 CSS px e conforto de alvos |
| S17 | [W3C — Contrast Minimum](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html) | Contraste de texto e condições de medição |
| S18 | [W3C — Non-text Contrast](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html) | Sinais visuais funcionais e relação com fundos adjacentes |
| S25 | [W3C — WAI-ARIA, Dialog Modal Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/) | Foco, teclado, fecho e retorno de modais |
| S26 | [W3C — Status Messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html) | Mensagens semanticamente identificadas e risco de excesso de anúncios |

### Navegador, renderização e tipografia

| ID | Fonte | Evidência utilizada |
| --- | --- | --- |
| S19 | [MDN — env()](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Values/env) | Margens seguras e variáveis de ambiente |
| S20 | [MDN — VisualViewport](https://developer.mozilla.org/en-US/docs/Web/API/VisualViewport) | Diferença entre viewport de layout e área efetivamente visível |
| S21 | [MDN — CSS length](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Values/length) | Unidades de viewport pequenas, grandes e dinâmicas |
| S22 | [MDN — Pointer Events](https://developer.mozilla.org/en-US/docs/Web/API/Pointer_events) | Captura, cancelamento e gestão de ponteiros |
| S23 | [Braille Institute — Atkinson Hyperlegible](https://www.brailleinstitute.org/freefont/) | Família orientada à diferenciação e legibilidade de caracteres |
| S24 | [Google Fonts — Alegreya, licença OFL](https://github.com/google/fonts/blob/main/ofl/alegreya/OFL.txt) | Licença da família tipográfica proposta |
| S27 | [MDN — imageSmoothingEnabled](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/imageSmoothingEnabled) | Controlo de suavização de imagens escaladas no canvas |

### Evidência do projeto

- **P01:** captura enviada neste pedido; base do diagnóstico visual e da estimativa de ocupação.
- **P02:** `empire_planeamento_subsolos_armazens_dungeons.md`, de 5 de outubro de 2026; referência histórica de estrutura espacial e coerência dos lugares.
- **P03:** `relatorio_kingdom_vegetacao_biomas.md`; contexto do trabalho sobre ambientes, biomas e influências próximas.
- **P04:** histórico do trabalho de HUD; restrição de preservar Correr e Fixar analógico. Relatos de alterações anteriores não foram convertidos em afirmações sobre a build atual.

**Decisão proposta:** aprovar uma linguagem visual e um percurso completo de interação antes de expandir o redesign. O primeiro resultado a avaliar é o jogador conseguir ver o território, compreender o local e agir com confiança — reconhecendo o Empire em cada ecrã.
