# ADR 0063 — A moeda, as bancas e a cidade dentro dos muros

- **Estado:** aceite no âmbito dos pedidos do dono de 04/10/2026.
- **Data:** 2026-10-04
- **Tarefa:** `docs/backlog/RG-21.md`.
- **Substitui:** ADR 0060, ponto 6, quanto às bancas, aos recintos e ao primeiro
  canteiro; Q-064 quanto às mãos que constroem muralhas.

## Problema e pedido

O vagabundo procurava a moeda ao passo normal. O martelo ficava longe da chegada,
o arco fora do primeiro recinto e qualquer aliado podia construir uma muralha.
O dono pediu corrida pela moeda, contratação ao apanhá-la, formação do construtor
e só então pagamento e construção da muralha, com melhorias cada vez mais caras.

O pedido seguinte esclareceu a ordem: as duas bancas aparecem depois de fundar
a cidade. As construções ficam dentro dos muros; evoluir a sede oferece muros
mais distantes, e concluí-los publica construções adequadas ao estágio da sede.

## Decisão

1. O raio continua o `recruit_notice_px` existente, incluindo o seu limite. Moeda
   pousada, na mesma faixa, livre de obra e que caiba no saco é alvo. Empate pelo
   id; duas pessoas não duplicam a moeda.
2. A corrida aplica `recruit_run_mult` ao movimento sem alterar a velocidade base.
   O multiplicador 2 é proposta reversível no CSV, registada na Q-230. A escolha
   continua fatiada; perder a moeda cancela o alvo no tick seguinte. Contratação
   termina a corrida. Um movimento neutro sem alvo de moeda não é cancelado.
3. Martelo e arco ficam a 288 px a oeste e leste da sede, respeitando a largura
   final da Fortaleza e a folga de chão da Q-207. Ambos aparecem juntos após
   concluir a fundação, dentro do primeiro recinto planeado. Precisam existir
   antes de levantar os primeiros muros para não bloquear a formação do construtor.
   Não dão pessoas gratuitas: cada ferramenta transforma um recrutado existente.
4. Só um construtor vivo da mesma faixa e do dono permite destinar moeda a uma
   muralha. O posto só aceita construtores e o progresso exige presença física.
   Rei, companhia, arqueiro e trabalhador sem martelo não constroem muralhas.
   Perder o construtor pausa o andaime; outro pode retomá-lo.
5. Cada estágio da sede abre um recinto por lado: o Acampamento oferece os muros
   interiores, o Povoado os seguintes e a Vila os exteriores. Só o próximo muro
   depois da frente concluída se oferece. Evoluir a sede não constrói um muro.
6. Todo edifício urbano novo, inclusive canteiro, torre, fogueira e casa de
   cidadãos, exige área defendida. O edifício inteiro cabe atrás da borda interna
   de um muro próprio de pé; andaime sem defesa não reivindica território. O
   estágio, o nível de defesa e a produção de apoio do CSV continuam cumulativos.
   Bancas fundadoras são o arranque do recinto inicial; escoras do subsolo,
   árvores e territórios dos povos conservam suas regras próprias.
7. Casa de Treino e cozinha passam a 432 px da sede; canteiros interiores a
   576 px, exteriores a 1960 px e os últimos muros a 2080 px. Conservam-se a
   ordem e os ids dos slots. A expansão abre primeiro produção e torres; depois
   processamento e serviços conforme `realm_stages.csv` e `realm_sites.csv`.
8. A escada continua a de `walls.csv`: Estacaria, Paliçada, Pedra, Ferro e Bastião,
   uma etapa por pagamento, com custos existentes crescentes. Sede, conquistas,
   Lenho, caminhos e unicidade conservam os requisitos. O guia nomeia o próximo
   degrau e pede muralha antes do canteiro.

## Save e validação

Não há nova coluna autoritativa nem versão de save. Ao retomar, a autoria repõe
as posições e mantém pessoas, investimento, treinos e identidade dos slots.
Bancas vazias e sem investimento completam-se apenas numa sede já fundada;
ruínas não ressuscitam. Obras já pagas, construídas ou herdadas conservam-se
visíveis se uma defesa cair, evitando apagar investimento por dano.

Testes vermelhos reproduziram corrida ausente, banca distante, bancas prematuras,
expansão sem evolução e convites fora dos muros. A validação inclui raio, moeda
reservada, disputa, cancelamento, fluxo com gestos e dinheiro inicial, obra sem
rei, morte do construtor, save, ambos os lados, andaime exterior e cinco etapas.
Resultados da suite completa, portões, vistoria e exports ficam no PR.

Os preços das muralhas, população inicial, materiais e arte original permanecem.
Não há nova dependência. Esta decisão implementa o pedido para Empire; não afirma
que seus valores sejam os preços de uma edição de Kingdom.
