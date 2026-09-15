# 80 — Arte · revê a §11 e a §22 · O preto entra na paleta, e a noite deixa de ser azul

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Nick Cross, o diretor de arte da série, disse uma coisa que quase nenhum artista de televisão diz: recusou a teoria de cor impressionista que se ensina hoje e usou preto académico, à maneira da pintura antiga. Não é uma escolha estética — é o que permite que uma cena inteira se resolva com duas massas escuras, um céu de ocre e uma luz. É a alavanca 6, é a mais cara das sete em horas, e é a que resolve o diagnóstico da §11: "não é falta de resolução nem de talento, é falta de um plano no meio".

> **Decidido — ADR 0011, 13 de setembro de 2026**
>
> A noite é castanha. A Q-037 está fechada e a tabela de fases da §05 já foi corrigida. O que se segue é a razão, e fica escrita porque daqui a um ano ninguém se lembra dela.

> **As três imagens que enviaste já decidiram isto**
>
> Os dois cartazes que mandaste com este pedido são a mesma composição repetida: fundo de ocre queimado sem gradiente suave, duas massas de silhueta pretas sem detalhe nenhum, três figuras pequenas em contraluz, e uma fonte de luz quente ao centro. Zero azul. Zero névoa fria. É exatamente o oposto do que a §05 manda fazer à noite. Esta secção resolve a contradição do lado dos cartazes, e não do lado da tabela.

## 1 · Três valores de silhueta, e são para não desenhar

A tua paleta tem 112 cores, 23 delas neutras, e o mais escuro — #14140F — só é usado como contorno. Proposta: três valores dedicados a preencher, não a contornar.

| Plano (§11) | Valores permitidos | Contorno | Regra |
| --- | --- | --- | --- |
| Distância · y 300–420 | 1 | Nenhum | Uma massa chapada. Sem textura, sem gradiente, sem variação. #17130D. |
| Plano médio · y 420–517 | 2 | Nenhum | #241F17 e #2E251A. É a faixa que falta, e desenha-se em duas horas se forem só dois valores. |
| Plano de jogo · y 517–720 | toda a paleta | 2 px | Inalterado (§22). |
| Primeiro plano · y ≈ 640–720 | 2 | Nenhum | #100D09 e #14140F. Sobrepõe-se às tropas e não compete com elas. |


Cinco dos seis planos de parallax passam a ter um teto de valores. Isto não é uma restrição artística — é uma redução de horas: a §22 orçamenta 12 h para as seis camadas de parallax e o que as torna caras é a indecisão sobre quanto detalhe pôr. Com teto de valores, as três camadas de fundo desenham-se em 5 h e ficam melhores.

## 2 · A noite passa a castanha

A §05 mandava "Azul profundo" na noite. A tua paleta tem 30 cores de madeira e terra, 21 de estuque, 23 neutros — e 9 de azul-petróleo. A noite atual usa a família de que tens menos, o que obriga a inventar cor que não é tua, e produz o azul genérico de todos os jogos com ciclo dia-noite.

| Fase | v5.2 | Matiz · saturação · valor do tint | Amostra |
| --- | --- | --- | --- |
| Alvorada · 15 s | Âmbar rasante | 38° · 0,44 · 0,91 — mantém-se | #E8B87A |
| Manhã · 85 s | Neutra | 42° · 0,10 · 0,95 | #F2EADA |
| Meio-dia · 40 s | Alta, dura | 48° · 0,05 · 1,00 | #FFFBEF |
| Tarde · 85 s | Dourada | 36° · 0,41 · 0,91 | #E9C68A |
| Crepúsculo · 30 s | Vermelha baixa | 18° · 0,68 · 0,73 | #B9663A |
| Noite · 105 s | Azul profundo (v5.2) | 32° · 0,22 · 0,16 — castanho, com chão em 0,11 · ADR 0011 | #2A2117 |


> **A regra das duas exceções**
>
> Com a noite castanha, o ecrã noturno tem exatamente duas cores que não são terra, e cada uma delas quer dizer uma coisa: violeta (#59386B, o teu token --rot) é A Podridão e só A Podridão; âmbar (#F6D89B ao núcleo) é luz, seja a candeia dela ou uma fogueira tua. Um jogador aprende isto em duas noites sem que ninguém lho diga, e a partir daí lê o ecrã inteiro de relance. É a coisa que o azul profundo torna impossível, porque o azul é frio como o violeta e as duas coisas fundem-se.

## 3 · A luz é o assunto, e desenha-se com três paragens

A §22 põe "Luz quente pontual" no Bloco 4 com 3 h e sem especificação. Passa a ser o primeiro item do bloco, com regra:

- Três paragens, nunca um gradiente. Núcleo #F6D89B, meio #E8A94E, bordo #AE4F16, e depois dissolve para o ambiente com dither de 2 px — o mesmo shader de revelação que a §11 já pede para o corte de terra.
- Uma luz domina por ecrã. Se duas competem, o ecrã lê plano. Consequência de design, não só de arte: as tuas fogueiras têm de ser mais fracas do que a candeia à mesma distância. O que faz da candeia o centro de composição de todas as noites, que é precisamente onde a §36 quer o GIF de marketing.
- Nada tem contorno dentro do raio de luz. Perto da luz vê-se cor e volume; longe vê-se silhueta. Inverte-se a lógica de sprite habitual e é o que dá a sensação de pintura.

## 4 · A cara na casca

O Amargueiro (§74) é o sprite com maior retorno do jogo inteiro e custa três horas. Um tronco por escala — 3 troncos — mais a slot face das personagens que já tens desenhadas, encaixada na casca com uma máscara de casca por cima. Cada Amargueiro tem a cara de quem morreu ali, porque é literalmente o mesmo ficheiro. Não há sprite novo por unidade, não há variação a desenhar, e a variedade é automática e total.

## 5 · O teste de silhueta, no CI

A §31 já tem cultura de testes de design. Este cabe lá e corre sobre qualquer captura, como o guião de densidade da §01:

| Regra | Como se mede | Falha se |
| --- | --- | --- |
| Teto de valores por camada | Conta cores únicas no PNG exportado de cada camada de parallax | Distância > 1 · plano médio > 2 · primeiro plano > 2 |
| Leitura a 1 bit | Limiar de luminância a 0,42 sobre o ecrã composto | Não se identifica a cena. Manual, uma vez por ecrã acabado. |
| Rampa de densidade (§01) | Cores distintas em janela de 16×16 | Topo > 18 · base < 30. Mantém-se da §01. |
| Duas frias | Píxeis de matiz 200°–290° com saturação > 0,35, fora da mancha, à noite | > 0,5% do ecrã |


> **Porque é que o teste tem um limiar de saturação**
>
> Sem ele o teste chumbava a tua própria arquitetura: a telha azul-petróleo é uma das sete famílias da paleta (§22) e cai dentro de 200°–290°. Com o LUT da noite a levar a saturação para 0,22, os telhados descem abaixo de 0,35 e saem do teste sozinhos — continuam azuis à luz do dia e são cinzento-frio à noite. O que fica acima de 0,35 e frio, à noite, só pode ser uma coisa, e é essa a regra que o teste protege.

> **O que isto muda no calendário da §22**
>
> Parallax desce de 12 h para 5 h por causa do teto de valores. Luz e atmosfera sobe de 18 h para 24 h, e muda de ordem: a luz pontual passa a primeira e o LUT de hora do dia ganha mais duas horas para a rampa castanha. Amargueiro acrescenta 3 h ao Bloco 1. Saldo: +2 h no total da arte, com a §11 resolvida e a assinatura visual fechada. É o melhor negócio da Parte XIII e é o único item dela que eu faria mesmo que rejeitasses tudo o resto.
