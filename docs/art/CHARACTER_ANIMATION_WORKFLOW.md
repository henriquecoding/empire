# Animação de personagens — poses, continuidade e tempo

Aplicação da pesquisa de 18–19/10/2026. Entrada: [guia de produção](CHARACTER_PRODUCTION_GUIDE.md). Tags e cadência de produção: [Animation Bible](ANIMATION_BIBLE.md). [Fontes](research/2026-10-19-character-animation/FONTES-E-APLICACAO.md).

## Poses antes de interpolação

Definir intenção, apoio, linha de ação, orientação e acessório em cada chave. Desenhar o corpo inteiro coerente; só depois preencher a passagem entre as chaves. Translação de um braço, rotação de uma máscara ou deformação do corpo parado pode ajudar no blockout, mas não resolve mudança de apoio, torção, sobreposição e articulação que a ação exige.

Uma pose intermediária precisa responder **como** o corpo chegou ali. A perna que passa sob o quadril tem joelho e pé levantados; não é apenas a bota do contato deslocada. O cotovelo continua ligando ombro e mão mesmo quando fica parcialmente oculto. A capa reage ao corpo, sem substituir o movimento do corpo.

## Construção por ação

| Ação | Chaves a resolver | Falha a procurar |
|---|---|---|
| `idle` | apoio estável, respiração pequena e pausa | corpo inteiro oscilando mecanicamente; pés flutuando |
| `walk` | contato A, carga A, passagem A, subida A; repetir com B | perna rígida, mesma perna sempre à frente, cabeça encolhendo |
| ataque | antecipação, aceleração, contato/solta, continuação, recuperação | arma muda de mão; impacto sem preparação; retorno instantâneo |
| `hit` | recebe força, cede, estabiliza, retoma | confundir reação com ataque; rosto some |
| `die` | perde apoio, joelhos cedem, mão apoia, quadril chega, corpo acomoda | sprite reduzido inteiro ou corpo desaparece |
| sentar | joelhos/quadril flexionam, mão busca chão, apoio, descida, acomodação | tronco comprimido; assento inventado; pés mudam de chão |
| levantar | plantar pé, projetar massa, mão empurra, estender joelhos, acomodar tecido | só reverter sentar sem esforço de subida |
| dança | apoio, transferência, arco de braço/tronco, giro curto, oposição, pausa | braços alternados sem peso; rosto e saia trocam de identidade |

Essas são fases de revisão, não novas quantidades obrigatórias de quadros. A cadência e os eventos do jogo continuam seguindo a especificação existente.

## Timing e continuidade

Anotar duração de cada exposição em milissegundos. Pausas comunicam peso e intenção; não precisam de novos rasters. Uma ação rápida pode ter poucas exposições na passagem e mais tempo no apoio ou na recuperação. Comparar o resultado ao metrônomo do `Empire troop` antes de propor qualquer alteração de cadência canônica.

Os estudos V13/V15 têm tempos e contagens experimentais diferentes da Animation Bible. Preservá-los no arquivo e no diagnóstico; não usá-los para redefinir automaticamente `idle 6`, `attack 5`, `die 7` ou os eventos do jogo. Se uma mudança dessas for necessária à integração, registrar a divergência no ticket e seguir o processo de decisão do projeto.

Inspecionar começo/fim da ação e também as **emendas entre ações**: `idle → walk`, `idle → shoot`, `shoot → idle`, `sit → heal → stand`, `die → rise`. Uma animação pode funcionar sozinha e falhar ao entrar ou sair. Pontes não são quadros decorativos: conduzem objeto, mãos e apoio entre estados.

Na V13, o arqueiro precisou conduzir o arco da posição de repouso até o disparo; o intendente precisou de passagem para a entrega das flechas. Conferir a transferência real entre mãos e o objeto até o destino. No bardo, ambas as mãos precisam servir ao alaúde; um gesto gerado de levar a mão ao chapéu foi descartado.

## Volume, chão e pivô

- Comparar cabeça, mãos e tronco com recortes lado a lado e onion skin. Medidas fixas são referência de revisão, não uma razão para eliminar uma perspectiva intencional.
- Manter a origem da tela em todos os quadros. Não recortar cada PNG pela caixa opaca e recentralizar; isso cria saltos de cabeça, pés e arma.
- A animação é no lugar. Deslocamento no mundo vem da simulação; casar comprimento aparente do passo, ciclo e velocidade de movimento para reduzir deslizamento.
- O pivô é uma referência espacial fixa. A pose pode levantar um pé ou cair, mas não muda a linha de chão por normalização automática.
- Reservar margem para armas e gesto máximo antes de exportar. O arqueiro V13 precisou de espaço frontal e pivô deslocado.

Ao espelhar um raster de largura `W`, o índice de um pixel vira `W - 1 - x`. Um socket representado por índice de pixel segue a mesma regra. Coordenadas contínuas de borda ou offsets de nó podem ter outra convenção; documentar qual foi usada antes de aplicar a fórmula a todos os metadados.

Na V15, os pivôs discretos foram Sombra direita `[40,78]`, esquerda `[39,78]`; bailarina `[32,62]`/`[31,62]`. Não trocar esse ajuste de um pixel por arredondamento silencioso. A direção esquerda espelha também luz e roupa; isso deve aparecer como limitação de produção, especialmente onde a iluminação direcional exigir revisão.

## Secundários e atuação

Cabeça e mãos conduzem a ação. Capa, saia, cabelo e alforges acompanham com atraso e acomodação proporcionais ao material. Não acrescentar oscilação em todas as partes por medo de um instante parado. O manto pesado do Sombra pede menos agitação que a saia da bailarina.

Na bailarina, verificar quadril sobre a perna de apoio, sustentação do tornozelo, oposição do tronco e arco do braço. A referência da Royal Ballet School foi a descrição pública das aulas; o desenho é uma adaptação a uma personagem de dança popular/cortesã, não uma certificação de técnica de ballet.

No Sombra, o rosto permanece oculto. O gesto delicado próximo da planta, a cabeça inclinada e uma pausa podem comunicar mais que um grande balanço da capa. Essa reação foi proposta na direção aceita; a presença efetiva de cada gesto ainda deve ser conferida na animação entregue.

## Exportar sem perder a ação

Registrar, por tag: lista ordenada de quadros, duração por quadro, loop, direção, pivô, sockets e eventos. IDs de eventos são dados até serem ligados ao controlador existente. Não inventar sinais novos para justificar o atlas.

Se o `SpriteFrames` usar 10 fps como base, uma exposição de 160 ms tem duração relativa `1,6` à velocidade `1`. A fórmula geral documentada pelo Godot é `tempo = duração_relativa / (fps × velocidade)`. Não importar todos os quadros com a mesma duração por conveniência.

Distinguir três fatos no relatório: **arquivo decodificado e coerente**, **aberto no Aseprite**, **importado e visto em ação no Godot**. Um não comprova os outros. Usar Nearest e a política de importação do projeto, conferir camadas e alinhar o nó pelo pivô declarado.

## Contagem honesta

Publicar número de entradas, número de rasters distintos com e sem espelhos quando medido, origem de repetições e inversões. Não chamar `rise` invertido de uma nova subida desenhada. Na V15 o Sombra tem `stand` próprio; a bailarina ainda reutiliza a queda ao contrário. A última pose da queda do Sombra é mantida por dois tempos e não representa um desenho adicional.

O relatório [V15](research/2026-10-19-character-animation/evidencias/v15/verificacao.json) mede integridade e contagem. Ele declara que a animação não recebeu aprovação artística e não foi testada na engine. Esses estados precisam continuar explícitos em qualquer continuação.
