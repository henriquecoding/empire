# 00 — Visão canónica · A visão canónica e como usar este dossiê

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Integração de 07/10: o relatório territorial foi comparado na íntegra; §§92–96 completam as especificações e rastreiam A01–A12, AUD-CIV-01–18 e T01–T50. O RG-28 já entrou na main; o seu protótipo é a baseline desta leitura. Portos, contratos completos e remessas continuam desenvolvimentos pendentes.

Empire é um kingdom-builder 2D em pixel art, com exploração lateral, moeda física, pessoas que trabalham e combatem no mundo, uma ameaça noturna com memória e um império cuja identidade nasce do território e das escolhas do jogador. A partida começa antes do reino: um imperador, uma carroça e três cidadãos sem ofício atravessam a natureza; o jogador escolhe onde fundar e transforma esse lugar num acampamento, povoado e, muito mais tarde, numa rede territorial.

Esta revisão integra as decisões do painel, o Documento Mestre de 05/10, os relatórios de floresta e subsolo e as ADRs posteriores à v6. As regras foram atualizadas nas secções que as descrevem. A Parte XIV explica a integração de Civilization VII e Manor Lords, os contratos ainda por implementar e a rastreabilidade das respostas. O histórico mantém-se no Git e nas ADRs; não constitui uma segunda versão ativa do design.

## Os pilares atuais

| Pilar | Experiência pretendida | Consequência de design |
| --- | --- | --- |
| Presença | O jogador é um imperador no mundo | Governar, lutar, explorar e regressar competem pelo seu tempo; não há seleção direta de tropas ou ofícios |
| Território | O sítio onde se funda importa | Bioma, cobertura, água, recursos, vizinhança e acessos condicionam economia, defesa e expansão |
| Pessoas | O trabalho tem corpo, percurso e risco | Recrutar não cria profissão; dinheiro não substitui disponibilidade de trabalhadores |
| Transformação | Construir muda o que o lugar permite | Desmatar abre espaço e pode retirar abrigo ou rendimento; a consequência deve ser legível antes da ação |
| Continuidade | O reino e as pessoas têm história | Evolução, herdeiro, legado, alicerces e perdas persistem com regras próprias |
| Noite | A Podridão responde ao mundo | Pressão gradual, composição compreensível, luz e rotas importam; não há enxames fortes sem preparação |
| Escala | A complexidade cresce com a campanha | O começo ensina relações locais; sociedades, rotas e Capital acrescentam decisões quando há base para as sustentar |


## As referências e o que cada uma acrescenta

Kingdom sustenta a leitura lateral, os gestos simples, a moeda física e a gestão por presença. Civilization VII inspira o valor estratégico da posição, assentamentos com funções diferentes, progressão por fases e grupos políticos que podem crescer. Manor Lords inspira a coerência entre trabalho, recursos, ambiente e crescimento orgânico. A tradução concreta para Empire está na §87: não introduz automaticamente hexágonos, turnos, famílias, cadeias industriais, novas moedas ou quotas de felicidade.

## O contrato de leitura

- Decidido significa que a direção está autorizada por uma resposta ou pedido do dono identificado.
- Implementado exige correspondência no código e validação do comportamento; uma aprovação não basta.
- Publicado exige o commit efetivamente servido. Um ramo ou PR aberto não é produção.
- Proposto identifica uma hipótese de desenho ou um valor ainda em _proposed. Não se remove essa etiqueta por uma aprovação de outro assunto.
- Adiado preserva a escolha de não executar agora. Substituído conserva a proveniência, mas deixa de reger a cláusula em conflito.

O dossiê é a especificação integrada. Decisões explícitas posteriores prevalecem na cláusula afetada e obrigam à sua atualização; ADRs explicam a razão e a migração. CSVs descrevem os valores executados, incluindo os provisórios. Código descreve o que existe, não transforma uma divergência em regra desejada. A §86 resolve os conflitos conhecidos; a §91 conserva as respostas consultadas.

## O que existe e o que se está a construir

A revisão começou em bafeb112aa6b9b7162d78fe3053da62c9d6c47ec e foi reconciliada em 07/10 com main/ba743da3a616d27a7df581646e9e7356134c89c8, confirmado como produção READY na Vercel. Já existe jogo Solo com fundação livre, moeda e trabalho físico, monarcas, progressão da sede, floresta persistente e subsolo. A arte renovada, o HUD, a tocha na mão e as correções do PR #92 integram agora essa base publicada. A §90 identifica a versão e os limites da verificação.

O despertar social, a assinatura ambiental completa, a rede de povoações, a sucessão escolhida completa, o quarto imperador e os modos online conservam critérios de aceitação próprios. Não se apresentam como entregues por terem sido aprovados no painel.

As estimativas de horas, mercado e calendário das primeiras versões são históricas, não um compromisso atualizado. A ordem atual é: estabilizar e tornar coerente o ciclo Solo; validar a abertura e progressão; completar território e sociedades; validar sucessão e campanha; construir a rede online. O backlog continua a ser a unidade de execução e o dossiê o contrato de produto.
