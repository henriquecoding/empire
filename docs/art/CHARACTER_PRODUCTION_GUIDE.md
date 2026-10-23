# Personagens e animação — guia de produção do Empire

Consolidação de 19/10/2026. Este é o ponto de entrada para aplicar a pesquisa, continuar o elenco e evitar as falhas das revisões anteriores.

## Ordem de leitura e autoridade

1. [Referências do próprio projeto](REFERENCE_AUTHORITY.md): soldado, cozinheiro e elenco são a família visual.
2. [Decisões e estado atual](research/2026-10-19-character-animation/DECISOES-E-ESTADO.md): a aprovação mais recente do autor tem precedência sobre o entusiasmo do assistente e os textos históricos.
3. Este guia, [animação por poses](CHARACTER_ANIMATION_WORKFLOW.md), [floração individual](ORGANIC_FLOWER_ANIMATION.md) e [revisão](CHARACTER_REVIEW_CHECKLIST.md).
4. [Asset Bible](ASSET_BIBLE.md), [Animation Bible](ANIMATION_BIBLE.md) e [expressões](EXPRESSION_GUIDE.md): contratos de arquivos, slots e runtime.
5. [Fontes e aplicação](research/2026-10-19-character-animation/FONTES-E-APLICACAO.md), [arquivo completo anterior](research/2026-10-18-imperadores-escudeiros/README.md) e [evidências V13–V15](research/2026-10-19-character-animation/README.md).
6. [Estudo aplicado de pixel art](PIXEL_ART_STUDY_GUIDE.md) e [fluxo do Aseprite](ASEPRITE_WORKFLOW.md): pesquisa de Penusbmic, Watt e Pixel Pete, com trechos das aulas e exercícios de revisão. Complementa o método sem alterar as aprovações ou os contratos acima.

Este guia organiza o método de trabalho. Não altera o dossiê, balanceamento, nomes canônicos, paleta mestra ou contratos de runtime. A precedência continua sendo a de [AGENTS.md](../../AGENTS.md) e ADR 0079. Uma opção estética documentada precisa conservar seu estado: proposta, design aceito, animação revisada ou integração verificada.

## 1. Começar pela função e pela atuação

Para cada personagem escrever: papel, personalidade visível, gesto principal, três marcas de reconhecimento, material dominante e o que pode mudar. A pose parada já deve comunicar algo. Testar a silhueta preenchida com uma única cor e o personagem ao lado do soldado na mesma linha de chão.

Escolher uma massa dominante, uma secundária e um foco. Cabeça, mãos e acessório de ofício precisam de espaço; bordas douradas e microtextura não podem disputar todos os pontos da imagem. O desenho pertence ao elenco por proporção, agrupamentos de cor, linguagem facial e materiais, não por copiar adereços de outro personagem.

Afinidade entre uma dupla pode vir de dois sinais de família e de gestos complementares. No estudo aceito de Sombra/bailarina, tecido vinho/ameixa e bronze aproximam os dois; postura fechada/pesada e aberta/leve os diferenciam. Isso é a direção desta dupla, não um molde para todo o elenco.

## 2. Construir na escala útil

- Distinguir **tela**, **caixa opaca**, **altura útil**, **escala no mundo** e **ampliação de apresentação**. Um PNG 80×80 não prova desenho originalmente autorado nessa grade.
- Os estudos recentes usam 64×64 para pequenos e 80×80 para personagens maiores. A decisão por corpo deve confrontar a cena real; esses estudos não substituem silenciosamente as telas padrão propostas na Asset Bible.
- Medir cabeça, tronco e mãos na referência; não normalizar cada pose pela altura total. Um personagem sentado fica mais baixo sem encolher a cabeça.
- Trabalhar grandes massas, volumes, contorno, materiais, rosto e só então detalhes. A intenção de um pixel importa mais que a mera contagem de cores.
- Inspecionar a 1×, com ampliação inteira em Nearest e sobre fundos claros/escuros do jogo. Ampliação serve para diagnosticar; a decisão de leitura é na escala real.

Reduzir uma imagem grande, remover o fundo e quantizar uma paleta são operações de adaptação. Depois delas, rever clusters, diagonais, olhos, dedos, nariz, continuidade de barba/bigode e contorno. Não chamar essa adaptação de autoria manual nativa ou de acabamento concluído.

## 3. Luz, materiais e expressão

Usar a gramática e a paleta do projeto; qualquer nova rampa continua sendo uma proposta até aceita. Escolher a direção de luz antes dos frames. Tecido precisa de dobras grandes e pausas; metal de planos claros/escuros e poucos reflexos; couro de massas estáveis. Um brilho que troca de lugar sem mudança de orientação causa cintilação.

O rosto é um pequeno sistema de marcas reconhecíveis. Guardar um recorte de referência e comparar nariz, olho, sobrancelha, boca, dentes e pelos faciais em todos os quadros. Não trocar expressividade por um sorriso genérico. No capacete fechado de Sombra, a expressão passa por inclinação da cabeça, ombros, mãos e pausas; desenhar olhos visíveis mudaria sua identidade aceita.

Cabeça e rosto não recebem squash/stretch segundo a Animation Bible. Um pixel isolado pode ter função em personagens; a proibição de ruído 1 px do cenário não deve ser aplicada indistintamente a olhos e detalhes do elenco.

## 4. Produzir uma prova pequena antes da série

| Etapa | Evidência para continuar |
|---|---|
| Brief | Referências identificadas, estado de aprovação e invariantes escritos |
| Corpo estático | Frente de leitura, perfil usado no jogo, linha de pés e comparação com o elenco a 1× |
| Poses-chave | Ação inteira entendida sem intermediários; apoio, peso e acessório permanecem legíveis |
| Transição crítica | Sentar/levantar, sacar/guardar ou mão que entrega objeto funciona sem salto |
| Ciclo curto | Timing, pés, volumes e início/fim revistos em movimento e quadro a quadro |
| Efeito composto | Personagem e efeito vistos juntos; frente/fundo, chão e ritmo conferidos |
| Elenco completo | Expandir depois da prova; corrigir famílias de erro antes de repetir em dezenas de quadros |

No caso de Sombra/bailarina, a prova de design foi aceita. A aceitação não se estende automaticamente à animação V15, aos demais personagens ou à integração Godot.

## 5. Usar geração de imagens como fonte controlada

Preservar referência, prompt integral, ferramenta realmente utilizada, quantidade pedida e quantidade recebida. Fixar câmera, direção, linha de chão, escala de cabeça, identidade e sequência exata. Pedir uma ação por folha sempre que a ação permitir.

Antes de extrair uma folha, contar e classificar as figuras reais. Houve pedidos de 24 poses que retornaram 20 ou 23. Não inventar um quadro ausente para cumprir o número nem interpretar duplicata como novo desenho. Uma pausa pode reutilizar raster desde que declarada.

Separar componentes opacos com inspeção: uma arma, mão ou mecha pode ser um componente desconectado que pertence ao mesmo personagem. Verificar bordas cortadas, figuras unidas, objetos extras e fundo residual. Fixar escala por uma medida estável, alinhar pelo apoio e quantizar sem destruir a expressão. Registrar o método e o que ainda exige redesenho.

A [Forja](FORJA.md) aplica este método como ferramenta: compila o pedido na grade final, conta as figuras, recupera a grade sem reduzir, aplica paleta, contorno e pivô, mede deriva e cintilação e grava a proveniência.

Os prompts da V15 estão [preservados](research/2026-10-19-character-animation/evidencias/v15/prompts.json). São receitas históricas, não prova de que o modelo cumpriu todos os requisitos. PixelLab foi pesquisado, mas não executado nessas entregas; não atribuir a ele os resultados de outra ferramenta.

## 6. Definir entrega, revisão e integração separadamente

Cada entrega precisa de PNGs individuais, timeline/atlas com retângulos, tempos, pivôs, direções, loops e eventos identificados; fonte editável; procedência; prova em movimento; relatório técnico; estado de revisão artística e de integração. Os nomes finais e slots são os da Asset Bible.

Contar separadamente entradas de timeline, rasters distintos, espelhos, pausas, sequências invertidas e desenhos de origem. Uma direção espelhada não é uma segunda direção desenhada. Um `.aseprite` gerado por código exige tanto conferência binária quanto abertura no aplicativo antes de ser declarado testado nele.

O importador deve preservar tempos por quadro e pivôs. A apresentação acompanha a simulação; não dispara cura, projétil, moeda ou promoção por conta própria. Não copiar o protótipo `jardim.gd` da entrega V15 diretamente para `src/`: ele precisa ser adaptado ao RngService, aos tipos e aos contratos do projeto.

Antes de promover material para produção, concluir a [checklist de revisão](CHARACTER_REVIEW_CHECKLIST.md). Registrar explicitamente o que foi visto na engine e o que foi apenas validado como arquivo.

## 7. Ficha reutilizável de personagem

Copiar para o ticket de produção e preencher com evidência, sem declarar aprovação por antecipação:

```text
Personagem / papel / versão:
Referências e decisão do autor:
Estado: proposta | design aceito | animação em revisão | integrada
Personalidade visível / gesto:
Três marcas que não podem variar:
Materiais / direção de luz / rampa de cor:
Tela / altura útil / escala em cena / pivot por direção:
Tags necessárias / poses-chave / transições entre tags:
Equipamento em cada estado / sockets / eventos existentes:
Fonte dos desenhos / ferramenta / prompt / correções manuais:
Entradas / rasters distintos / espelhos / pausas / inversões:
Prova 1× / prova em movimento / teste Godot:
Falhas abertas / aprovação do autor / próximo passo:
```
