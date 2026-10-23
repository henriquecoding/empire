# Aplicação ao Empire — provas pequenas antes da série

Estas são propostas de exercícios de autoria e revisão. Não há novos sprites
produzidos nesta tarefa. As notas das aulas explicam a origem dos métodos; os
critérios abaixo foram adaptados aos problemas e contratos do Empire.

## 1. Ficha de entrada de uma peça

Antes de desenhar, preencher:

```text
Peça, função e versão:
Referência aceita e documento que registra a decisão:
Estado: estudo / design aceito / animação em revisão / integração verificada:
O que precisa melhorar e o que deve ser preservado:
Tela, caixa útil, altura do corpo e escala em cena:
Linha do chão, pivô e margem do gesto máximo:
Materiais, direção de luz e cores já disponíveis:
Tags, tempo, transição e evento existentes que a arte acompanha:
Técnica estudada e trecho da aula consultado:
Prova necessária para concluir a revisão:
```

Se falta decisão de design, registrar a questão no processo do projeto. Não
preencher essa lacuna com uma preferência do professor ou com uma aprovação
inventada pelo assistente. O estudo dá método para investigar; não transfere a
autoridade artística.

## 2. Rostos e identidade cômica

**Prova proposta:** uma comparação de cabeça e corpo com a referência aceita,
no mesmo chão, em repouso e numa pose de esforço. Usar recortes de igual escala.

Começar pela massa de cabeça, olhos, nariz, boca e pelos faciais que identificam
aquele personagem. Conferir a relação com ombros e mãos antes de ornamentar.
Desligar temporariamente detalhes internos para verificar se a forma principal
permanece reconhecível. Recolocar o rosto e comparar suas marcas em cada pose.

No rei e escudeiro, preservar as preferências registradas sem reaprovar uma
rodada posterior por inferência. Arqueiro e intendente precisam ser avaliados
pela anatomia e atuação, além da presença de arma ou bolsa. Nia continua
sujeita ao estado registrado; a aula não resolve sua aprovação.

**Rever:** sorriso genérico, olho que muda de lugar sem rotação explicável,
dentes virando textura, mão pequena demais para a ação e contorno interno que
divide o rosto. Mais cores não corrigem uma expressão indefinida.

## 3. Membros, equipamento e continuidade

**Prova proposta:** repouso → preparação → ação → recuperação → repouso,
primeiro sem VFX. Usar as poses já autorizadas e a cadência correspondente.

Marcar ombro, cotovelo, mão, quadril, joelho e apoio nas chaves, em camada de
trabalho. Entre duas poses, perguntar qual articulação moveu e qual parte
passou por trás de outra. Desenhar o intermediário que responde a essa mudança.
Evitar que um braço seja tratado apenas como um pixel de ligação entre arma e
tronco. Conferir a silhueta e as camadas separadamente.

Para arco e entrega de flechas, acompanhar o mesmo objeto até seu destino.
A mão que sustenta não troca com a outra por conveniência do frame. A corda,
a flecha e o acessório precisam seguir o gesto, sem definir projéteis ou
estoques na simulação.

Otimizar partes ocultas é possível. Mas primeiro confirmar que a oclusão existe
na direção, no ataque e no estado de equipamento em que a peça será usada.
Uma capa que esconde uma perna em repouso pode expô-la na caminhada.

**Rever:** arma atravessando o corpo, luva desconectada, pernas sem alternância,
apoio flutuante e retorno abrupto à primeira pose.

## 4. Peso e movimentos secundários

**Prova proposta:** comparar um ciclo com somente o movimento condutor e outra
versão com reações de tecido e equipamento. Conservar ambas para revisão.

Definir a ação principal pelo apoio e pela transferência de massa. Acrescentar
reações que correspondam ao material e ao gesto, preservando o ritmo existente.
Uma bolsa, uma peça metálica e um tecido leve não precisam atingir os extremos
ao mesmo tempo. Inspecionar também os instantes de repouso; nem toda parte
precisa mover continuamente.

No Sombra, conferir a relação entre peso do corpo, cabeça inclinada e manto. Na
bailarina, conferir transferência de apoio e continuidade de braços e saia.
Não converter a proibição de deformar rosto em uma proibição de atuar com a
postura. Também não deformar o rosto para obter uma oscilação mais perceptível.

**Rever:** ciclo inteiro deslocado como bloco, tecido que se move antes da
força que o impulsiona, objeto que perde peso no retorno e ponto de contato
que escorrega. A animação continua no lugar; o avanço pertence à simulação.

## 5. Sombra e floração individual

**Prova proposta:** um trecho completo com sentar, primeira planta, crescimento
de plantas individuais e levantar. Seguir o [guia de floração](../../ORGANIC_FLOWER_ANIMATION.md).

Separar as perguntas: o corpo está sentado de forma convincente? A planta
nasce de um ponto do solo? A flor passa por estados reconhecíveis? As plantas
começam em instantes diferentes? A composição deixa espaço para o personagem?
Primeiro revisar uma planta em crescimento; depois compor o campo.

O objetivo é crescimento individual e orgânico, como Henrique solicitou.
Rotacionar uma flor pronta até ficar vertical não atende a esse comportamento.
Repetir o mesmo frame com offsets também não comprova crescimento. A escala
de pétalas e folhas deve ser conferida com o personagem e a linha do solo.

Variação visual deve usar o mecanismo de aleatoriedade do projeto quando for
integrada. Não inserir temporizadores ou fontes de RNG arbitrárias em um
protótipo de runtime. A vegetação acompanha o estado autoritativo; não dispara
cura por conta própria.

**Rever:** nascimento fora do chão, todas as flores no mesmo instante, plantas
deitadas que giram, campo cobrindo a silhueta e desaparecimento sem transição
compatível. O design aceito de uma dupla não aprova automaticamente o efeito.

## 6. Animais e montarias em escala

**Prova proposta:** comparar portes sobre o mesmo chão e, para uma espécie,
um ciclo curto com apoio legível. Manter a mesma escala da cabeça entre poses.

Medir o corpo útil; não usar a altura total do arquivo como normalização.
Chifres, cristas, armas e caudas podem mudar a caixa opaca sem mudar o tamanho
do animal. A célula é um recipiente de autoria, não uma obrigação de preenchê-la.

Escolher referências de movimento da espécie antes de determinar os apoios.
As aulas de personagem não demonstram a biomecânica de todos os quadrúpedes;
não generalizar a corrida bípede para cavalo, javali ou ave. A prova de montaria
deve incluir a posição do cavaleiro, o gesto máximo e a sombra de contato.

**Rever:** pequenos tão grandes quanto bovinos, membros que deslizam sem
troca de apoio, cavaleiro flutuando e cabeça que cresce nos extremos.

## 7. Construção modular com material rico

**Prova proposta:** um encontro de fachada, telhado e solo, com porta, ator e
um estado adicional de construção. Usar módulos de autoria coerentes com o tile.

Desenhar a estrutura e o volume; depois vigas, apoios, arcos, beirais e material.
Uma viga suporta algo, um beiral projeta sombra e uma porta precisa ser lida
como acesso. Veios de madeira seguem o sentido da peça; pedra é organizada em
faces e blocos; telha comunica inclinação. Desgaste é escolhido por uso e
posição, não espalhado igualmente por toda a peça.

A preferência de Henrique por riqueza de materiais deve coexistir com a
leitura em tela pequena. Cortar ruído não implica remover todos os encaixes,
textura e sinais de função. Avaliar uma redução de detalhe pela perda ou ganho
de leitura, não apenas por um número menor de cores.

**Rever:** arquitetura sem apoio, porta menor que o corpo sem motivo, textura
que vira grade, todos os tijolos contornados e estados sem correspondência
com o progresso real. Um módulo 64×64 não redefine o tile de 32 px.

## 8. Cenário horizontal, portos, lagos e rios

**Prova proposta:** um trecho com margem ou porto, personagem, acesso à parte
inferior e passagem entre dois tratamentos de ambiente. Conferir de dia e à noite.

Começar pela circulação e pelo envelope vertical disponível. Compor marcos,
intervalos e grupos antes de preencher com vegetação. Diferenciar decoração,
chão caminhável e acesso funcional. A arte pode sugerir profundidade, mas não
inventar uma passagem que o jogo não possui.

No porto, conferir píer, apoio dos pilares e leitura da margem; no lago, a
relação entre solo, parte submersa e superfície; no rio, continuidade de bordas
e travessias existentes. A faixa inferior deve ser expressiva dentro do espaço
real, sem ampliar o mapa verticalmente para acomodar uma ilustração.

Separar planos por contraste, detalhe e relações de cor, usando os dados e
limites atuais. Uma composição de wallpaper não fornece colisões, regiões de
parallax nem limites de segmento. Testar as emendas no eixo horizontal antes
de multiplicar variantes.

**Rever:** fundo competindo com rosto e arma, todas as áreas igualmente densas,
ponte sem acesso, água cobrindo apoios, costura visível no loop e tratamento de
noite que contradiz a luz do jogo.

## 9. Checklist de saída

| Pergunta | Evidência |
| --- | --- |
| Referência e aprovação foram preservadas? | Documento e versão identificados |
| A função se entende na escala real? | Composição a 1× com elenco e chão |
| O volume sobrevive sem textura? | Versão de massas ou comparação simples |
| Há mãos, membros e equipamento coerentes? | Chaves e passagens vistas separadamente |
| O movimento tem apoio e continuidade? | Loop e entradas/saídas revistos |
| A luz é consistente? | Comparação entre quadros e direções |
| A peça cabe no mundo? | Prova com circulação e envelope do mapa |
| Fonte, export e metadados correspondem? | Conferência técnica documentada |
| Foi aberto no Aseprite e visto no Godot? | Estado de cada verificação registrado |
| Henrique aprovou a revisão artística? | Decisão explícita, sem inferência |

Automação pode encontrar retângulos inválidos, quadros vazios inesperados,
cores fora do contrato ou arquivos faltando. Ela não decide humor, beleza,
anatomia convincente nem aprovação artística. Relatar os dois tipos de revisão
separadamente.
