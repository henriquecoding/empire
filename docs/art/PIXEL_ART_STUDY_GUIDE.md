# Pixel art do Empire — estudo aplicado e ordem de trabalho

Atualizado em 22/10/2026. Este é o ponto de entrada para aplicar o estudo de
Penusbmic, Watt, Pixel Pete e Aseprite a personagens, animação, materiais e
cenários. O [registro da pesquisa](research/2026-10-22-aseprite-penusbmic/README.md)
informa o que foi acessado e o alcance de cada leitura.

## Ler antes de produzir

1. Conferir [autoridade das referências](REFERENCE_AUTHORITY.md) e
   [decisões recentes](research/2026-10-19-character-animation/DECISOES-E-ESTADO.md).
2. Consultar as [notas do Penusbmic](research/2026-10-22-aseprite-penusbmic/PENUSBMIC-NOTAS.md)
   e a [leitura visual das prévias](research/2026-10-22-aseprite-penusbmic/LEITURA-VISUAL.md),
   e os [fundamentos complementares](research/2026-10-22-aseprite-penusbmic/WATT-E-PIXEL-PETE-NOTAS.md)
   pelo problema concreto, usando os links com tempo para rever a aula.
3. Preparar o arquivo com o [fluxo do Aseprite](ASEPRITE_WORKFLOW.md).
4. Aplicar o [guia de personagens](CHARACTER_PRODUCTION_GUIDE.md), o
   [fluxo de animação](CHARACTER_ANIMATION_WORKFLOW.md) e os contratos das
   [Asset](ASSET_BIBLE.md) e [Animation](ANIMATION_BIBLE.md) Bibles.
5. Usar os [exercícios e critérios de revisão](research/2026-10-22-aseprite-penusbmic/APLICACAO-E-EXERCICIOS.md)
   para produzir uma prova pequena antes de expandir o conjunto.

## O que passa a orientar a prática

O estudo organiza a execução; a aprovação artística continua pertencendo a
Henrique. Não altera mecânicas, cadência, paleta, dimensões canônicas nem o
estado de aprovação dos assets. O dossiê e as decisões posteriores mantêm sua
precedência. Um desenho bonito, um arquivo íntegro e uma integração funcional
são verificações diferentes.

| Problema encontrado | Primeira intervenção | Evidência que procurar |
| --- | --- | --- |
| Personagens difíceis de distinguir | Comparar silhueta, massas e acessório de ofício | Identidade reconhecível sem textura |
| Cenário rico, mas cansativo | Rever distribuição de contraste e intervalos | Personagem, entrada e caminho continuam claros |
| Cenário simplificado demais | Acrescentar estrutura e material nos pontos úteis | Madeira, pedra e função distinguíveis a 1× |
| Animação que parece uma imagem movida | Resolver apoio, articulações e transições | Corpo explica como chegou à próxima pose |
| Movimento sem peso | Separar movimento condutor e reação dos acessórios | Arma, tecido e bolsa não obedecem à mesma oscilação |
| Braço ou equipamento desaparece | Inspecionar partes ocultas e ordem das camadas | Ombro, cotovelo, mão e objeto mantêm continuidade |
| Cintilação de pixels | Comparar massas e luz entre exposições | Volume e material permanecem estáveis |
| Arte não encaixa no mapa | Compor com o elenco e a linha do solo desde o blockout | Escala, circulação e profundidade conferidas juntas |

Essas intervenções são a aplicação editorial deste estudo aos problemas do
projeto. Não são promessas de que os assets atuais já foram corrigidos.

## Construção de pixel art

**Forma → planos de luz → materiais → detalhes úteis → revisão nativa.**
Grupos de pixels precisam descrever um volume ou um sinal reconhecível. No
cenário, detalhes uniformemente espalhados competem com os atores. No rosto,
um pixel isolado pode ser indispensável. A distinção segue a categoria e a
função; não existe uma regra única de limpeza para todo o jogo.

Jaggies são interrupções indesejadas no ritmo de uma borda. Banding ocorre
quando faixas vizinhas reforçam o mesmo desenho da grade. Pillow shading
acompanha o contorno plano em vez dos volumes iluminados. Corrigir a estrutura
antes de acrescentar tons intermediários. Essas definições vêm do tutorial de
[cure](https://pixeljoint.com/forum/forum_posts.asp?TID=11299); não são técnicas
inventadas especificamente para o Empire.

Usar duplicação, seleção e transformação para trabalhar com eficiência. O
critério é o resultado revisto, não uma exigência de clicar manualmente em cada
pixel. Ferramentas não resolvem por si sós anatomia, perspectiva ou atuação.
[Derek Yu](https://derekyu.com/makegames/pixelart.html) complementa essa base.

## Escala e composição que o estudo deve respeitar

- A Asset Bible registra resolução interna 1280×720 e tile de 32 px; uma área
  de autoria 64×64 corresponde a 2×2 tiles. Não converter a grade do mundo em
  64 px porque um personagem usa uma tela dessa dimensão.
- Os estudos recentes de elenco usam 64×64 e 80×80. Tela, área opaca, altura do
  corpo e escala no mundo precisam ser anotadas separadamente. O guia de
  personagens já registra a reconciliação necessária com telas antigas propostas.
- Cabeça e rosto conservam a identidade; uma pose sentada perde altura sem
  encolher a cabeça. Animais pequenos não preenchem a mesma caixa útil dos grandes.
- Material rico significa estrutura convincente, desgaste selecionado e
  agrupamentos legíveis. Não significa ruído em todos os tiles nem fachadas vazias.
- Um exemplo top-down ensina relações de forma e luz; sua câmera e suas
  proporções não substituem o mundo 1.5D do Empire.

## Registro exigido numa continuação

Anotar referência e versão, estado de aprovação, regra do projeto aplicada,
técnica usada, alteração feita, prova a 1×, prova em movimento e falhas abertas.
Quando houver conflito entre uma aula e o jogo, registrar a adaptação. Não
atribuir ao professor uma regra que foi proposta para o Empire.

O estudo de outubro de 2026 fica versionado como conhecimento consultável.
Não constitui treinamento permanente do modelo nem substitui abrir esses
documentos nas próximas tarefas.
