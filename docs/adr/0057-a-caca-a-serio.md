# ADR 0057 — A caça a sério: bichos vivos, variedade, moedas no chão e imperadores que caçam

- **Estado:** aceite, reversível (03/10/2026)
- **Contexto:** o dono pediu *«A caça e criaturas deve ser desenvolvida e trabalhada a sério, deve haver variedades e
  deve ser possível fazer farm com as moedas que caem; os imperadores também devem conseguir atacar e colher esse
  dinheiro»*, com pesquisa na web e implementação direta. O que havia: coelhos e veados parados à porta das tocas
  (Q-106, Q-150), só os arqueiros a caçar, a caça a ir para o saco deles (Q-111), e o javali no CSV sem tocas. O golpe
  de quem se conduz (ADR 0045) só procurava criaturas da Podridão: o imperador passava por um coelho e não lhe podia
  bater.

## A pesquisa

- **Kingdom: Two Crowns / New Lands / Eighties.** Os coelhos saem da erva e andam ao acaso; os veados levam dois
  tiros, valem três moedas e **fogem** do monarca e dos caçadores — correndo por eles, o jogador *empurra-os* para
  junto dos arqueiros. O javali tem toca própria, vale muito e é perigoso (atrai-se para o muro). As aves pousam nos
  arbustos e levantam quando o monarca se chega.
- **theHunter: Call of the Wild e devlogs de IA de presa.** Dois estados chegam para uma presa crível — pastar e
  fugir —, e o javali é a exceção ousada que carrega. O que separa a caça de «clicar num alvo» é a distância a que o
  bicho dá por nós.

## Decisão

1. **Os bichos andam (`Herd`).** Cada bicho pasta à volta da toca (até `roam_px`, a `graze_speed`), num vaivém sem
   sorteio (um seno com a fase da toca). Quem é teu, vivo e à superfície, a `notice_px`, fá-lo fugir para o lado
   contrário a `move_speed`, até `flee_px` da toca — aí fica **encurralado**, e é aí que o apanhas. O veado dá por ti
   de mais longe do que o coelho; o faisão foge cedo e depressa.
2. **O javali carrega.** Não foge: pasta sem medo de quem passa, e, **depois de ferido**, vai contra quem chega a
   `notice_px`, até `flee_px` da toca, e bate `damage` a cada `attack_interval` quando está a `reach_px` (a nota do
   CSV já dizia «carrega contra quem o caça»; assim não ataca quem trabalha nas obras ao pé da toca dele). O golpe tira vida a sério (`Herd.bite`, `unit_damaged`) e a morte passa
   pelo combate como qualquer outra. Ganha uma toca por região, na árvore do único chão livre a leste (entre o celeiro
   e o sino de vigia).
3. **Variedade.** Na floresta antiga de casa saem agora cinco bichos, cada um do sítio que faz sentido (Q-150): o
   coelho (arbusto, buraco, rocha), o **faisão** (arbusto; 1 acerto, 1 moeda), a **raposa** (buraco, rocha; 2 moedas),
   o veado (árvore, lago) e o javali (árvore). O **cervo branco** é o raro: cada vez que uma toca de veado dá um bicho,
   há `rare_chance` (8 %) de sair ele — 16 de vida, foge de mais longe, vale 12. O sorteio é o `RngService.scatter`
   com o número do bicho, fora do fluxo `economy`. Cada sítio fica para o bicho mais miúdo que dele sai, para o veado
   não perder as suas árvores.
4. **Os imperadores caçam (`RoyalHunt`).** O golpe de quem se conduz que não acha criatura vai ao bicho mais perto à
   frente, ao alcance da arma: a espada do Rei, as machadinhas da Nia, a flecha do Imperador Arqueiro (que já se gastou
   ao disparar, Q-200). O imperador que ninguém conduz bate, de dia, no bicho que lhe passe ao alcance, sem sair do
   sítio.
5. **As moedas caem (farm).** A caça de um imperador **cai no chão, moeda a moeda**, onde o bicho estava, e é de quem a
   pisar (`Gleaning`): o imperador apanha-a ao passar, e as tuas tropas guardam-na e entregam-ta (Q-111). A dos
   arqueiros continua a ir para o saco deles, como o dono decidiu na Q-111.

## O que não muda

- A **caça média do dia** continua a do `hunt_yield` (economy.csv): o período das tocas reparte-a pelas moedas de
  todos os bichos com toca. Com mais bichos, cada toca dá mais devagar; o cervo branco é um bónus por cima. Se a caça
  deve render mais agora que há mais caçadores, é a Q-213.
- A Q-106 (o Amargueiro mata a toca), a Q-120 (um bicho de cada vez, aos poucos) e o coelho do 1:10 do §25 — que agora
  cai no terreno do coelho, ao pé do castelo, e não à porta da toca.
- O save não muda de versão: a manada é uma chave nova do `hunting`, e um save antigo põe cada bicho à porta da toca.

## Leitura de «imperadores»

No código, imperador é um dos três monarcas da ADR 0052 (a tag `king`: o Rei, a Nia e o Imperador Arqueiro). Ainda não
há imperadores rivais nem encontrados no mundo (UN-16, UN-22). A regra vale para qualquer corpo com essa tag, conduzido
ou não, por isso os imperadores que chegarem com essas fases caçam e apanham pelas mesmas regras, sem código novo.

## Números novos (propostas, `_proposed` no wildlife.csv)

`graze_speed`, `roam_px`, `notice_px`, `flee_px`, `reach_px`, `attack_interval`, `rare_of`, `rare_chance`, as três
linhas novas (faisão, raposa, cervo branco) e a toca do javali. Nenhum número antigo mudou. Estão aplicados de forma reversível, e a aprovação deles é a Q-215.

## Consequências

- Mais fácil: caçar é um jogo — aproximar, encurralar, fugir do javali —, e o monarca tem uma fonte de moedas própria
  de dia, sem arqueiros.
- Mais difícil: o x de um bicho deixou de ser o da toca. A toca continua a ser o nome do bicho (`rabbits`, `wounds`);
  onde ele está é `herd.where(toca)`.
- O `HuntingSystem` chegou às 250 linhas: o saco do caçador passou para o `HuntBag`.
- Reverter: tirar o passo da manada e do `RoyalHunt` do `HuntWatch.tick`, pôr `burrows_per_region` do javali a 0 e
  apagar as três linhas novas do CSV.
