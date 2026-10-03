# ADR 0052 — Monarcas jogáveis, companhias e encontros imperiais

- **Estado:** aceite (direções do dono de 02/10/2026); as propostas marcadas **P** continuam por aprovar nas
  Q-196 a Q-205.
- **Data:** 2026-10-02
- **Secção do dossiê:** §08, §09, §13, §14, §15, §16, §18, §24, §99
- **Plano-fonte:** `docs/recovery/PLANO-MONARCAS-2026-10-02.md` (auditado sobre a `main` em `c255807`, merge do PR #69)
- **Substitui, por cláusula:** ADR 0044 (as três classes na primeira escolha), a Q-150 da ADR 0041 (a trela do rei),
  a Q-178 da ADR 0043 (só as classes viajam) e a premissa «o rei nunca sai» da ADR 0035. O resto destas ADRs
  continua a valer.

## Contexto

A ADR 0044 deu ao começo três escolhas — Monarca, Arqueiro e Bardo —, mas Arqueiro e Bardo eram um corpo a mais ao
lado de um rei que ficava com a coroa, as moedas, o escudeiro e a gestão. Quem joga escolhia uma classe e outro
personagem continuava a ser o responsável oculto pela gestão, pela derrota e pela sucessão. O código confirma a
divisão: `Assume.king()` compara com `SimLoop.king_id`, `CombatInput.queue_skill` chama sempre a Vigília para quem é
rei, `DawnWork` coroa sempre `units/monarch`, e `Roster.take` deixa assumir qualquer tropa de classe desbloqueada.

A 02/10/2026 o dono pediu a unificação e corrigiu-a a seguir: **só imperadores são controláveis**; a troca exige um
imperador desbloqueado e encontrado na campanha; tropas, ofícios, diplomatas e companheiros ficam sob IA; e o
escudeiro do Arqueiro dá flechas enquanto recebe moedas do próprio imperador — sem moedas, não há novo fornecimento.

## Decisão

**A escolha inicial é de monarca, não de classe.** Cada monarca reúne identidade, combate, autoridade da coroa e um
companheiro próprio. A autoridade pertence ao titular da coroa, não ao nome da classe de combate nem ao porte.

O que o dono decidiu (**D**):

1. Três monarcas: o **Rei guerreiro defensivo** (o primeiro definitivo, com o escudeiro pago), a **Imperatriz Nia**
   (pequena, negra, rápida, pouco dano por golpe e alta cadência, com um Bardo que leva a bandeira às costas e
   recebe moedas para encantar inimigos e incentivar aliados) e o **Imperador Arqueiro** (dispara flechas com
   chance de sangramento; o escudeiro fornece flechas mediante moedas pessoais dele).
2. **Só imperadores são controláveis.** Arqueiros, bardos, diplomatas, construtores, ferreiros, cozinheiros e
   combatentes funcionam por ordens e IA. Nenhuma tropa recebe controle direto.
3. **Troca só entre imperadores desbloqueados e encontrados** vivos e disponíveis na campanha. Desbloquear o
   arquétipo não cria nem teletransporta a pessoa.
4. **Flechas imperiais pagas:** o escudeiro do Arqueiro fornece flechas mediante moedas pessoais desse imperador;
   sem moedas, cessa o fornecimento; as flechas já carregadas continuam utilizáveis. Trocar de imperador, viajar ou
   carregar o save não repõe munição. A flecha normal infinita deixa de ser alternativa.
5. **Todos os monarcas exploram** até aos limites geográficos reais. Ficar em casa é uma estratégia, não uma regra.
6. **Morte definitiva sem sucessor válido encerra a campanha ativa.** Não há interregno automático de três dias.
   A queda com coroa recuperável (Q-167) não é morte definitiva.
7. **O Diplomata básico é contratável em qualquer império**, lidera incursões delegadas e nunca é corpo jogável.
8. **Escala comunica função** sem obrigar todo monarca a ser alto: Nia é pequena e continua reconhecível como
   imperatriz (exceção deliberada à Q-162 para ela).

As propostas (**P**) que preenchem o que o dono ainda não definiu — números de bancada, preços, transferência de
governo na troca, perfil do herdeiro, sangramento, reserva doméstica — estão nas Q-196 a Q-205 e nos `_proposed`
dos CSV. Nenhuma entra no painel como resposta do dono.

## Precedência, cláusula a cláusula

A matriz MU-01 a MU-28 do plano é o registo completo. As substituições que mudam o que estava escrito:

| Antes | Depois |
|---|---|
| Começar como Monarca, Arqueiro ou Bardo ao lado de um rei fixo (ADR 0044, §08) | Começar como um dos três monarcas, que possui a coroa e o seu companheiro |
| O rei anda até `king_leash_px` além da região (Q-150, ADR 0041) | Todos os monarcas exploram até às bordas reais; o resto da Q-150 (a caça dos sítios) fica |
| O rei nunca sai longe (Q-146, ADR 0035) | Sair é uma escolha de risco; a marcha delegada continua a existir |
| Só classes viajam; o rei fica (Q-178, ADR 0043) | Monarcas também viajam por destinos válidos; o resto da Q-178 (de dia, destino seguro) fica |
| «Só o rei gere» lido como o corpo do rei gordo (§08) | Só o titular da coroa gere; os três monarcas iniciais têm essa autoridade |
| Jogáveis com recursos de batalha ilimitados (Q-163) | O Arqueiro imperial gasta flechas pagas; a aljava das tropas e a banca do arco continuam |
| Escudeiro identificado pela tag `collects_coins` (ClassSystem) | Vínculo explícito entre o monarca e o companheiro |
| A habilidade de quem é rei é sempre a Vigília (ADR 0045) | A habilidade depende do perfil; os decretos continuam pela coroa |
| O sucessor nasce sempre de `units/monarch` | O sucessor tem identidade própria; o perfil do titular é a proposta da Q-202 |
| Sem herdeiro: interregno de três dias (§16) | Sem sucessor válido, a morte definitiva encerra a campanha ativa |
| Diplomata exige duas Sementes Reais para o acesso básico | Básico contratável em qualquer império; evolução continua a pedir progresso |
| Verbo 2 assume uma tropa de classe (Q-162, §08) | Não há troca com tropa; o Verbo 2 só troca com imperador elegível presente |
| Coop: cada jogador com uma classe (§18) | Coop: cada jogador com um imperador |

Não se revoga nenhuma ADR inteira: a ADR 0045 conserva o ataque manual, a 0046 o subsolo delimitado, a 0047 o toque.

## Execução por fases

O plano divide a execução em nove fases e 32 tickets locais, UN-00 a UN-31, agora em `docs/backlog/`:

| Fase | Resultado | Tickets |
|---|---|---|
| 0 — Contrato | Dossiê, decisões, esquemas e migração planejados | UN-00 |
| 1 — Fundamento | O rei existente sobre autoridade, perfil e vínculo; sem controlo de tropas | UN-01 a UN-08 |
| 2 — Nia | A imperatriz e o Bardo pago, completos | UN-09 a UN-12 |
| 3 — Arqueiro | Aljava paga, marca e sangramento | UN-13 a UN-15 |
| 4 — Encontros | Desbloqueio, pessoa encontrada e troca presencial | UN-16, UN-17 |
| 5 — Delegação | Diplomata universal, tesouro local e incursões | UN-18 a UN-21 |
| 6 — Conquista | Batalha física, governo inimigo e assimilação | UN-22, UN-23 |
| 7 — Conteúdo | Comitiva, ofícios, pontes, lore e primeiro ciclo | UN-24 a UN-28 |
| 8 — Multiplayer | Coop local, dois reinos e rede | UN-29 a UN-31 |

Cada fase entra por PR próprio. A condição de avançar está no plano (§21.1): nenhuma regra permite ao mesmo tempo
imperador e tropa controláveis; a troca não cura, não teletransporta, não duplica; saldo zero bloqueia a reposição.

## Alternativas consideradas

- **Mudar só o menu** (Nia como `bard_hero` com aparência nova). Rejeitada: o rei gordo continuava a gerir e a
  determinar a derrota às escondidas.
- **Manter o controlo de tropas em paralelo.** Rejeitada pela correção do dono.
- **Mudar só o controlo na troca e conservar o titular político.** Fica como alternativa aberta (Q-196); o padrão
  proposto é a transferência atómica do governo em solo.

## Consequências

- Mais fácil: uma pessoa é responsável por lutar, governar, pagar o companheiro e morrer; a derrota deixa de ter um
  rei escondido.
- Mais difícil: o combate, a coroa, a sucessão, a viagem e o save deixam de poder testar «é o `monarch`?» pelo nome
  — passam a perguntar pelo titular e pelo perfil.
- Proibido: oferecer «Assumir» numa tropa; criar flechas, cura ou moedas por trocar de corpo, viajar ou carregar.
- Reverter exige repor o Roster de classes, a trela do rei e o despacho único da Vigília, e migrar os saves de volta.

## Implementação — Fases 1 a 3 (03/10/2026)

O primeiro ciclo completo dos três monarcas (UN-01 a UN-15). Os números novos estão todos em `_proposed`.

- **Dados (UN-01, UN-09, UN-13).** `monarchs.csv` (`MonarchData`): corpo, classe das fases, habilidade, nome do ataque
  e companheiro com o serviço que vende. Unidades novas em `units.csv`: `nia`, `archer_emperor`, `bard_banner` e
  `quiver_squire`, com os números de bancada do plano. O `monarch` continua a ser o Rei, sem números mexidos.
- **Autoridade e vínculo (UN-02, UN-03).** `Monarchy` guarda o perfil, a geração e o vínculo patrono → companheiro
  por id; o `ClassSystem` deixa de achar o escudeiro pela tag `collects_coins` e só tem aura, noites e evolução com
  o Rei no trono. Gerir continua a ser do `SimLoop.king_id`: de quem tem a coroa, qualquer que seja o corpo.
- **Escolha (UN-04).** O escudeiro nasce ligado ao rei; `MonarchWatch.begin` passa os dois corpos ao perfil, sem
  nascer ninguém. A escolha mostra papel, companheiro, base, evolução e controlos de cada um.
- **Só imperadores (UN-05).** O `Roster` perdeu `take`, `back` e `begin`; o `Assume` perdeu a troca e a trela; a
  coroa caída não passa o controlo a nenhuma tropa; a viagem aceita o monarca — com o companheiro à mão — quando há
  destino seguro, sem roubar a marcha na bifurcação.
- **Migração (UN-06).** O save sobe à versão 7 (`SaveMigrationsV7`): conduz-se o rei, o perfil é o Rei, o escudeiro
  vivo passa a vínculo, os corpos de classe ficam no mundo sob IA com o que levavam.
- **Morte e sucessão (UN-07).** A coroa no chão, a morte de vez e a coroação valem para os três; o herdeiro nasce com
  o corpo do perfil de quem reinava (a opção mais simples da Q-202), herda o companheiro vivo, e o painel dá-lhe o
  nome de herdeiro com a geração. O companheiro morto fica perdido, sem substituto grátis.
- **Habilidade (UN-08).** O botão direito despacha pelo perfil: Vigília, canto pago ou marca.
- **Bardo pago (UN-10 a UN-12).** `RoyalSong`: o Bardo só canta vivo, à mão, pronto e pago — encantar, incentivar
  (passo, com o maior a valer) ou promover —, do orçamento dele e depois da bolsa da Nia, uma vez, no tick em que
  acontece. O convertido não rouba a coroa (`CrownDrop`). O feito da Nia é do Bardo dela, e não do Bardo de IA.
  Tetos (Q-199): dois encantados temporários na fase base; como Maestro, 48 de massa convertida viva.
- **Flechas e ferida (UN-13 a UN-15).** A aljava do Imperador Arqueiro é pessoal (`Supply.personal`): começa com as
  flechas iniciais, cada disparo gasta uma, a banca não a repõe, e só o escudeiro a enche por uma moeda da bolsa dele
  — o que não cabe fica em crédito. Sem flechas, um golpe de emergência fraco. `Bleeding`: sangramento com o
  sorteio do fluxo `combat`, uma ferida por alvo, no save, e a morte uma só pelo lote comum do combate.
- **Apresentação.** A Nia e o Arqueiro desenham-se pelo `ActorArt` (coroa, pele própria da Nia), o Bardo leva a
  bandeira às costas, o escudeiro das flechas empresta o sprite do escudeiro; tudo registado em
  `docs/ASSETS_TODO.md`. Nenhum ficheiro de `art/` ou `audio/` mudou.

Ficam para as fases seguintes: o roster de imperadores encontrados e a troca (UN-16, UN-17), o Diplomata universal
e as incursões (UN-18 a UN-21), a conquista física (UN-22, UN-23), o conteúdo (UN-24 a UN-28) e o multiplayer
(UN-29 a UN-31).
