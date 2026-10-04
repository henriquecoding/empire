# ADR 0063 — A moeda, o martelo e a primeira muralha

- **Estado:** aceite no âmbito do pedido do dono de 04/10/2026.
- **Data:** 2026-10-04
- **Tarefa:** `docs/backlog/RG-21.md`.
- **Substitui:** ADR 0060, ponto 6, quanto ao momento e ao sítio da banca inicial;
  Q-064 quanto às mãos que constroem muralhas.

## Problema e pedido

O vagabundo procurava a moeda, mas andava à velocidade normal. A banca do martelo,
embora erguida pela fundação, estava 2080 px a oeste do núcleo, fora da chegada.
Qualquer aliado presente podia fazer uma muralha avançar; o quadro de postos também
mandava trabalhadores sem ferramenta para essa obra.

O dono pediu corrida pela moeda dentro de um raio, contratação ao apanhá-la,
banca de construção no começo, formação do construtor e só depois pagamento e
construção da primeira muralha. As melhorias devem ter etapas cada vez mais caras.

## Decisão

1. O raio continua o `recruit_notice_px` existente, incluindo o seu limite. Uma moeda
   pousada, na mesma faixa, livre de destino de obra e que caiba no saco é um alvo.
   Empate entre moedas resolve-se pelo id; duas pessoas não duplicam a mesma moeda.
2. A corrida aplica `recruit_run_mult` ao movimento, sem alterar `UnitSystem.speeds`.
   O multiplicador 2 é proposta reversível no CSV, registada na Q-230. A escolha
   continua fatiada; uma moeda desaparecida cancela o alvo no tick seguinte, sem
   esperar pela fatia de decisão. Contratação e perda do alvo terminam a corrida.
3. A banca do martelo fica a 112 px a oeste do núcleo, fora do raio de pagamento
   da sede. Está pronta desde a chegada. Conserva o mesmo slot/id, preço de martelo,
   formação à chegada do recrutado e limite do primeiro construtor da ADR 0060.
   Não dá um construtor gratuito, não cria população e não exige Casa de Treino.
4. Só a existência de um construtor vivo da mesma faixa e do dono permite destinar
   moedas a uma muralha. Sem ele, o guia explica a ferramenta em falta; o preço
   não convida a um pagamento que o jogo não aceite. Moedas livres anteriores não
   passam a pagar a muralha automaticamente quando aparece um construtor.
5. Paga a muralha, o posto de construção só aceita o construtor. O progresso exige
   presença física dele. Rei, companhia, arqueiro e trabalhador sem martelo não
   fazem a muralha avançar. Perder o construtor pausa o andaime; outro pode retomá-lo.
   As demais obras conservam a Q-064, fora do âmbito deste pedido.
6. A escada continua a de `walls.csv`: Estacaria, Paliçada, Pedra, Ferro e Bastião,
   uma etapa de cada vez, com os custos existentes crescentes. A sede, conquistas,
   Lenho, caminhos e unicidade continuam a fechar as melhorias correspondentes.
   O guia identifica o nome, nível e moedas do próximo degrau.

## Save e validação

Não há nova coluna autoritativa nem nova versão de save. A corrida deriva do alvo
reposto. A autoria coloca a banca junto do acampamento também ao retomar; pagos,
treinos e ruínas mantêm identidade. Um slot antigo ainda vazio e sem investimento
ganha a banca inicial; uma banca destruída não ressuscita ao carregar.

A banca gratuita é recriada na chegada de uma nova partida e fica fora da quota
de estruturas preservadas pelo decay. Assim não desloca uma construção investida
nem altera quais ruínas permanecem depois de uma derrota.

Testes vermelhos reproduziram o passo normal e a banca fora do começo. A validação
inclui moeda reservada, raio, disputa, cancelamento, fluxo só com gestos e dinheiro
inicial, construção sem rei, interrupção, save, cinco níveis e orçamento de tick.
Resultados finais da suite, portões, vistoria e exportação ficam no PR.

Não se alteram arte original, custos das muralhas, população inicial, materiais
nem tecnologia. Não há nova dependência. Esta decisão implementa o pedido para
Empire; não afirma que os seus valores sejam os preços de uma edição de Kingdom.
