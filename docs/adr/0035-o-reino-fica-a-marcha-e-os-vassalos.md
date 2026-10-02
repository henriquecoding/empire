# ADR 0035 — O reino fica: a marcha conquista, e os povos conquistados são vassalos

- Estado: aceite (a confirmar pelo dono na Q-159)
- Data: 2026-09-29
- Secção do dossiê: §13, §16, §21, §79, §83
- Actualiza: a travessia da Q-135 (AUD-05)
- **Nota de precedência (ADR 0052, 02/10/2026):** a premissa «o rei nunca sai» foi substituída — todos os
  monarcas podem explorar e viajar, e sair é uma escolha de risco. A marcha delegada, a firmeza e os vassalos
  continuam a valer; a incursão nova passa a ser liderada por um Diplomata (UN-20).

## Contexto
A Q-135 (aprovada no painel de 29/09/2026) acabava a região com o rei a atravessar a bifurcação com a comitiva. No
mesmo painel o dono escreveu, na Q-146: *«o rei nunca sai para longe do reino, quem vai para longe do reino é as
classes jogáveis»*; na Q-103: *«ao conquistar um povo eles continuam funcionando como império, mas agora me geram um
tipo de imposto real […] O meu reino será sempre o que eu começo, os outros que assimilei podem inclusive ser
conquistados ou consumidos pelo meu inimigo, dependendo do modo de jogo»*; e na Q-154, sobre a comitiva: *«tem um
teto também […] a comitiva não deve limitar as bordas»*. As quatro não cabem juntas: se o rei nunca sai, a
travessia não pode levá-lo.

## Decisão
1. **O rei fica no reino dele**, que é sempre o primeiro da campanha. A região de casa já não se acaba.
2. **A bifurcação manda uma marcha** (`Realm`, `March`): o Verbo 2 lá, de dia e a partir do `crossing_day` (11), manda
   quem é teu e está perto do rei — até ao teto de cada papel, o do barco do New Lands (`march_party_caps`: 3
   construtores, 4 de longo alcance, 3 de corpo a corpo), com pelo menos `march_min_party` (3) — conquistar o povo
   seguinte do plano da campanha. Saem nessa noite (o reino fica desguarnecido, §13) e voltam na alvorada seguinte
   (`march_nights`, 1) à bifurcação.
3. **O povo conquistado passa a vassalo** (`VassalSystem`): funciona sem ti e paga tributo a cada alvorada — os
   *«4–6 moedas/dia para sempre»* do §13, `vassal_tribute`, largadas no núcleo — e dá, ao ser conquistado, Sementes
   Reais (`vassal_seeds`, 1 a 3). Saem o `people_assimilated`, o `trade_route_opened` e o `seed_royal_gained` da §46.
4. **Os vassalos podem cair**, conforme o modo de jogo (`vassals_can_fall`): cada vassalo tem firmeza
   (`vassal_strength`, 100), e cada noite a massa da Podridão gasta-lha (`vassal_erosion_per_mass`, 0,02 por ponto).
   A zero, o vassalo é consumido, deixa de pagar e sai o `trade_route_closed`.
5. **A campanha acaba quando todos os povos são vassalos** (`Realm.TODOS`), ou quando se apaga o Lume (Q-156). O
   epílogo da §79 conta os vassalos como povos que ficaram. O legado do fim de campanha fecha-se com
   `Legacy.end_campaign()`.
6. **O mapa deixa de acabar na comitiva** (Q-154): seis ecrãs de terras bravias para cada lado
   (`Greybox.BRAVIAS_ECRAS`), onde o rei anda e a câmara vai.

## Alternativas consideradas
- **Manter a travessia da Q-135 e ignorar a frase da Q-146.** Rejeitado: é a resposta mais recente e a mais
  específica, e diz o contrário.
- **O rei atravessa e o reino fica como vassalo dele.** Rejeitado: *«o meu reino será sempre o que eu começo»*.
- **A marcha como combate simulado noutra região.** Adiado: não há regiões com cena, e a Q-159 pergunta se a
  conquista deve poder falhar.

## Consequências
- As regiões seguintes conquistam-se de longe; a região de casa é onde se joga a campanha inteira. As classes
  jogáveis a ir para longe esperam por trocar de classe (§08).
- Hoje a marcha ganha sempre que leva três ou mais; o preço é a noite sem eles. Se deve poder falhar é a Q-159.
- O save ganha o reino (`realm`: a marcha e os vassalos), com migração na v2 (`SaveMigrations`).
- Os números da marcha e dos vassalos estão em `_proposed` no `economy.csv`, excepto os que o §13 dá: uma noite
  fora, 4–6 moedas por dia, 1 a 3 Sementes.
- `tests/marcha_test.gd` e `tests/fim_de_regiao_test.gd`.
