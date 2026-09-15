# 76 — Identidade · novo · Ninguém tem nome até merecer um

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Na taberna do quarto capítulo não há um único nome próprio. Há o Taberneiro, o Açougueiro, o Padeiro, a Parteira, o Alfaiate, o Salteador, o Fabricante de Brinquedos. Quando o Wirt se recusa a dizer o que é, a taberna não o deixa em paz — atribui-lhe um papel à força, porque um sítio assim não sabe lidar com quem não tem função. É a alavanca 3, é a mais barata das sete, e resolve um problema que todos os kingdom-builders têm: a sopa de unidades indistinguíveis.

> **O problema que isto resolve, dito sem rodeios**
>
> A §04 promete: "Não são unidade tipo 3 — são razões para doer quando morrem, e a tua morte é permanente." A frase está escrita desde a v3 e nada no dossiê a implementa. Cinquenta lanceiros iguais a morrer não doem. O que dói é aquele lanceiro. E a diferença entre um e outro não é arte nem IA — é um nome e uma linha de história, que custam uma tabela CSV.

## Como se ganha um nome

Nunca por sobrevivência sozinha, e nunca por escolha do jogador. Ganha-se por feito registado: uma condição que o sistema já observa para outra coisa qualquer. Na alvorada, se uma tropa viva cumpriu uma condição na noite anterior, o império nomeia-a.

| Feito | Condição | Título | Ganha |
| --- | --- | --- | --- |
| Aguentou | 5 noites vivo em posto de cerco | O Que Ficou | +1 vida máxima |
| Último na porta | Único sobrevivente de um portão atacado | A Que Ficou na Porta | Não foge (ignora a regra da §07) |
| Partiu o cerco | Golpe final num Aríete de lodo | O Que Partiu a Pedra | +2 dano contra siege |
| Contou | 10 Rastejantes abatidos | O Contador | +10% cadência |
| Trouxe os outros | Arrastou 3 corpos para dentro antes da alvorada | O Que Trouxe os Outros | Arrasta ao dobro da velocidade |
| Falou com ela | Estava dentro da mancha e saiu vivo | A Que Falou com Ela | Vê o raio da candeia como zona segura: não entra em pânico |
| Não comeu | 7 dias sem passar pela cozinha | O Seco | Metade do consumo de comida |
| Voltou | Ressuscitado no Santuário das Raízes (§16) | A Que Voltou | Imune a encantamento do Bardo inimigo |
| Não largou | Manteve a mesma arma 10 dias | O Da Mesma Lança | A arma sobe um nível |


## As quatro regras

**Nove, no máximo** — O império segura nove nomes ao mesmo tempo. Cumprido um décimo feito, a tropa fica à espera: na alvorada seguinte para um passo à frente das outras e não é nomeada. Fica assim até abrir vaga — e um jogador atento percebe que aquela figura parada é uma promessa por pagar. Nove cabe num ecrã sem menu, e a escassez é o que faz o nome valer.

Uma fita no slot overlay que já existe na composição por slots (§58). Uma cor por tipo de feito. Zero sprites novos de corpo.

Um título é único enquanto o dono estiver vivo. Morto o dono, o título fica de luto três dias e depois pode ser ganho outra vez — mas por O Segundo Que Ficou, e depois pelo Terceiro. O ordinal é a memória do império, custa um inteiro no estado, e é o que impede o sistema de se esgotar às nove horas de jogo.

Um Amargueiro nomeado vale 45 de massa em vez de 22 (§74), rende 5 Lenho em vez de 1, 2 ou 3, e serrá-lo tira 1 ponto de moral ao império durante 2 dias. Ter nomes é ficar mais forte e mais frágil ao mesmo tempo.

## A encomendação

Em boa parte do país houve, e nalguns sítios ainda há, o costume da encomendação das almas: na Quaresma, um grupo sai de noite e vai pelos caminhos a chamar em voz alta pelos mortos, para que não fiquem esquecidos. Não é uma cerimónia bonita — é uma obrigação, e faz-se no escuro.

É a cerimónia de nomeação do Empire, e é o momento em que os quinze segundos da Alvorada deixam de ser tempo morto. Na alvorada, se houve nomeação ou se houve Amargueiro, o império canta. Duas vozes, sem instrumentos, oito segundos (§81). Nomeia quem sobreviveu; chama quem criou raiz. A mesma melodia para as duas coisas — e é essa a decisão de design: o jogo não distingue celebração de luto, porque a série também não.

> **Custo**
>
> titles.csv com nove linhas, um ouvinte de feitos pendurado nos sinais que o CombatSystem e o UnitSystem já emitem (§50, §52), um campo title_id no estado da unidade, um sprite de fita por cor e um stinger de oito segundos. 7 h de código, 2 h de arte, 1 h de som. É a secção com o maior retorno emocional por hora de toda a Parte XIII, e nenhuma outra secção depende dela para existir — se o calendário apertar, esta entra na Fase 4 sem partir nada.
