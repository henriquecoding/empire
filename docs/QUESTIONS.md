# Perguntas em aberto

> O destino que o `AGENTS.md` manda usar quando a especificação não cobre um caso: **"escreve a pergunta aqui; não
> decidas tu."** Esta primeira leva saiu de transformar a prosa do dossiê em dados, testes e ficheiros que correm —
> é exatamente o tipo de contradição que *"uma tabela esconde e um gráfico apanha em cinco segundos"* (§06).
>
> Formato: o que diverge, onde, a proposta, o que bloqueia e quem decide. **Abertas** esperam por ti; **resolvidas
> na v5.2** estão aplicadas e documentadas, e podes revertê-las.

## Abertas — balanceamento e design

### Q-001 · Os arqueiros param o Aríete de lodo?
- **Onde:** §07 (tabela de tempo até matar) contra §31 (`test_arqueiros_nao_param_ariete`).
- **O que diverge:** o §07 diz que um arqueiro em campo demora **96,6 s** a matar um aríete — *"mais do que uma
  noite inteira"*. A noite dura **105 s** (§05). 96,6 < 105; com a precisão dos dados (0,34) dá 94,7 s. O teste do
  §31 exige > 105 e **falha com os números do próprio dossiê**.
- **Proposta:** manter a intenção (arqueiros não param aríetes) subindo a vida do aríete de 90 para **104**
  (26 golpes: 36,4 s em torre, 107 s em campo). Alternativa: medir o teste contra o tempo que o aríete demora a
  chegar ao muro, em vez da noite.
- **Bloqueia:** o teste está saltado com esta razão; volta quando decidires. F1-09.
- **Decide:** tu.

### Q-002 · Custo das muralhas: a tabela ou a fórmula?
- **Onde:** §06 (`base × 1,8^n`) contra §10 (tabela).
- **O que diverge:** a fórmula dá 6 · 10,8 · 19,4 · 35 · 63; a tabela diz 6 · 11 · 20 · **36** · **65**.
- **Proposta:** a tabela manda (é o que está nos CSV); a fórmula passa a descrição aproximada no dossiê.
- **Decide:** tu. Não bloqueia.

### Q-003 · Precisão em campo: 1/3 ou 0,34?
- **Onde:** §07 (tabela de TTK usa 1/3) contra §19/§44/F1-07 (`accuracy_open = 0.34`).
- **O que diverge:** 2% no TTK em campo. O teste tolera 3%.
- **Proposta:** fica 0,34 nos dados; a tabela do §07 passa a dizer "≈".

### Q-004 · Diplomata n2 com 60 de Favor: 45/45/10?
- **Onde:** §14.
- **O que diverge:** a regra ("cada 20 de Favor move 5 pontos de Captura para Dissolução") dá **45/50/5** com 60
  de Favor. O exemplo diz 45/45/10. O efeito do nível 2 do diplomata não está escrito.
- **Proposta:** o nível 2 move 5 pontos de Contrato para Captura? Não faz sentido. Mais simples: o exemplo está
  errado e fica **45/50/5**. Ou o nível 2 tem regra própria — escreve-a.
- **Bloqueia:** F6 (diplomacia). **Decide:** tu.

### Q-005 · Fuga: 30% ou 25% de vida?
- **Onde:** §07 (muro cai → fogem as tropas com vida < 30% e custo ≤ 4) contra §52 (FSM: FUGIR com vida < 25%).
- **Proposta:** são duas regras diferentes e ficam as duas — 30% quando o muro cai (`breach_flee_health`), 25% no
  resto (`flee_health`). Confirma.
- **Bloqueia:** F1-12.

### Q-006 · Quem atinge a faixa aérea? — **fechada pelo F1-07**
- **Onde:** §07 (Libélula: "só atacável por arqueiros e torres altas"; Alado: "obriga a torre alta") e §10.
- **O que divergia:** se os arqueiros atingem a faixa aérea, o Alado não obriga a nada.
- **Decisão — a proposta, tal como estava escrita:** o `targets_bands` diz o que a unidade **pode** apontar; a
  faixa dela própria chega sempre; qualquer outra só com um posto que lhe dê altura — o `hits_aerial` do
  `effect_params`, que hoje só a `high_tower` tem. Está em `src/sim/systems/posts.gd` e tem três testes.
- **É uma mudança de comportamento:** antes disto um arqueiro no chão abatia o Alado.

### Q-007 · Horta: "tropas baratíssimas" quanto?
- **Onde:** §04. Nenhum número. **Proposta:** −1 moeda no recrutamento de todas as tropas da Horta (mínimo 1).
  Fase 7.

### Q-008 · Forja e Fundição são o mesmo edifício?
- **Onde:** §09 e §22 (Forja, onde trabalha o ferreiro) contra §06 (Fundição, a casa de conversão do minério).
- **Proposta:** dois edifícios (oficina ≠ conversão), como está nos dados. Se for um só, a fatia vertical perde a
  forja sem minério.

### Q-009 · O estábulo das montarias é o estábulo das vacas?
- **Onde:** §06 (estábulo de vaca, 14) e §12 ("Cavalo de tração — Estábulo, 30 moedas").
- **Proposta:** dois edifícios (`cow_stable`, `mount_stable`); os 30 são o preço do cavalo.

### Q-010 · Paliçada de "gelo"?
- **Onde:** §10 ("Madeira reforçada / gelo"). Nenhum dos seis povos é de gelo. **Proposta:** retirar o gelo.

### Q-011 · As moedas de abate entram na curva?
- **Onde:** §25 (um Rastejante morto larga uma moeda) contra §06 (o modelo da curva não conta abates).
- **Proposta:** manter os abates baixos (1–6 moedas, nos dados) e incluí-los no modelo quando o `SimHarness` os medir.

### Q-012 · O peixe estraga?
- **Onde:** §06 (a Salga: "o peixe deixa de estragar"). Não há regra de estrago em lado nenhum.
  **Proposta:** o peixe perde 1 unidade por dia no pesqueiro se não for convertido.

### Q-013 · Que fortaleza é "do pântano"?
- **Onde:** §12 (a libélula-montaria vem da "Fortaleza do pântano"). Nenhum dos seis povos vive num pântano.
  **Proposta:** a Horta (várzea).

### Q-014 · Quanto custa um impulso real?
- **Onde:** §15 (o tirano paga "metade" pelos impulsos — logo têm custo — mas nenhum número).
  **Proposta:** 12 moedas (≈ o rendimento líquido do dia 1). Fase 6.

### Q-015 · Qual é a "tropa de elite"?
- **Onde:** §15 (Fastuoso: +1 tropa de elite grátis a cada 3 dias). **Proposta:** o Berserker de Raiz (escala 3).

### Q-016 · Quantas estátuas enterradas, e que mecânicas ensinam?
- **Onde:** §17 (só a do Ferreiro está escrita). **Proposta:** uma por mecânica dos primeiros 12 minutos (§25) que
  não se ensina por observação. Fase 3.

### Q-017 · Quantas criaturas tem a noite 1?
- **Onde:** §25 ("Noite 1: três Rastejantes") contra §05/§51 (massa do dia 1 = 86 → **10 Rastejantes**, e o tempo
  ativo dá para 19–33 invocações — ver `docs/content/ROT_BY_DAY.md`). E a precisão dos arqueiros **num muro** (postos
  do Caminho A) não está escrita: 0,34 ou 1,0?
- **Proposta:** a abertura é uma cena autorada (§25): o segmento `opening` limita a Podridão da primeira noite a 3
  Rastejantes. Postos de muro com precisão de torre (é o que o Caminho A vende).
- **Bloqueia:** `test_noite_1_e_sempre_ganha` (§31), F1-15. **Decide:** tu, com o `SimHarness`.

### Q-018 · Quanto demora a atravessar uma região?
- **Onde:** §21 ("40–60 s de ponta a ponta, o que a 26 px/s dá 1000–1560 px").
- **O que diverge:** 1560 px é pouco mais de um ecrã; uma região tem 4 a 6. A pé, uma região de 8 segmentos demora
  197 s.
- **Proposta:** ler "40–60 s **por ecrã**". Mede-se na greybox (pergunta 11 do GREYBOX_RULES).

### Q-028 · Que arquétipo jogável traz cada povo?
- **Onde:** §04 ("1 classe" por povo) e §13. **Proposta nos dados:** Enramados → arqueiro, Portuários → trepador,
  Fenda → monarca, Horta → bardo, Fornalha → cavaleiro enterrado, Sob-Raiz → cavaleiro selado. Fase 7.

### Q-029 · As "fogueiras" que abrandam A Podridão são o quê?
- **Onde:** §05 ("fogueiras, barris de fogo e terreno consagrado abrandam-na"). Só o barril e o altar têm dados.
  **Proposta:** fogueira = o *campfire* das rondas noturnas, edifício de 3 moedas com o abrandamento do barril.

### Q-030 · Uma região tem 8 segmentos ou 4 a 6 ecrãs?
- **Onde:** §21. Oito segmentos de 640 px são 4 ecrãs, não 6. **Proposta:** 8 na fatia vertical; 10–12 quando uma
  região precisar de 5–6 ecrãs, com ADR.

### Q-031 · O núcleo tem vida?
- **Onde:** §10 ("não é construído nem destruído"; "se cair, cai a partida"). **Proposta nos dados:** 1000 de vida,
  sem estados de ruína.

### Q-033 · A curva do §06 e os edifícios reais — **medida pelo F1-11**
- **Onde:** §06 (o simulador usa "fontes" abstratas: base = 3 + 2,6 × fontes) contra os edifícios de `buildings.csv`
  (2 a 5 por dia cada).
- **Proposta:** o `EconomySystem` (F1-10) calcula o rendimento a partir dos edifícios; o teste de design compara-o
  com o modelo de referência e o dia de asfixia tem de continuar entre 9 e 14. Se não bater, afina-se `economy.csv`.
- **O que o F1-11 mediu, e não decidiu:** o `EconomySystem.built_income()` soma os edifícios reais e o
  `sources()` conta-os. A região do *greybox* tem as **7 fontes** do perfil `balanced` — quatro canteiros,
  dois galinheiros e um pesqueiro — e rende **17 moedas no dia 1**. O simulador do §06, com as mesmas 7
  fontes, dá **21,2**. O abstrato é 25% mais generoso do que o concreto, e o `producao_test` fixa a
  diferença para que ela não mude em silêncio.
- **O que fica por decidir:** qual dos dois manda. Baixar `curve_income_per_source` de 2,6 para ≈2,0 fecha a
  diferença e move o dia da asfixia; subir os `yield_per_day` fecha-a do outro lado e mexe em seis edifícios.
  É balanceamento e é do F1-16 — nenhum número de `data/` foi mexido aqui.

### Q-034 · A roda do rei pausa o jogo? E porque é que o teclado vai de 1 a 5?
- **Onde:** §24 (impulso: "Tab → 1–5"; a roda tem 6 segmentos e há 6 impulsos) e §05 (a roda é o corpo do rei).
- **Proposta:** Tab + 1–6; a roda abranda o tempo a 50%, desligável.

### Q-035 · `treasury_changed` e os sinais do §30
- **Onde:** o `event_bus.gd` do §30 declara `treasury_changed`, `creature_requested`, `unit_band_changed`,
  `structure_built`, `structure_destroyed` e outras cargas; **nenhum destes está no catálogo fechado da §46**.
- **Proposta:** a §46 manda (§39). O F0-07 escreve os 61 sinais da §46; o HUD do saco usa `coin_collected`.

## Abertas — técnicas

### Q-024 · A camada `Equipments` é o slot `head`?
- **Onde:** os teus ficheiros têm `Body · Face · Shield · Sword · Equipments`; a §58 tem `body · head · face ·
  weapon · shield · overlay`. **Proposta:** `Equipments` → `head`. Confirma ao separar o `Empire troop` (ART-01).

### Q-025 · Godot 4.6-stable, 4.6.3 ou 4.7?
- **Onde:** `.godot-version` (§69). Em setembro de 2026 existem 4.6.3-stable e 4.7.2-stable; o gdUnit4 6.2.1 suporta
  4.5–4.7.1. **Proposta:** ficar no 4.6 e subir para o **4.6.3** (só correções) com uma ADR no início da Fase 0;
  4.7 só com uma razão concreta.

### Q-036 · O I6 protege mesmo o save?
- **Onde:** §19 ("Usa `ResourceLoader.load` com `CACHE_MODE_IGNORE` e valida os tipos à mão"), §40 (I6) e §62.
- **O que diverge:** o `load()` do GDScript é um atalho para o `ResourceLoader.load`, e `CACHE_MODE_IGNORE` só decide
  se o recurso vem da *cache* — um `.tres` com *script* embutido executa-o na mesma. A regra, tal como está
  escrita, proíbe a função e recomenda a mesma função. É a única falha de segurança encontrada no dossiê.
- **Proposta:** o save grava-se com `FileAccess.store_var` e lê-se com `FileAccess.get_var(false)` (sem objetos —
  o valor por omissão), só com tipos base, validados campo a campo; nunca `ResourceLoader` num save. A ADR 0007 já
  diz isto desde a v5.2; falta mudares a frase do I6 no dossiê (§19, §40, §62).
- **Bloqueia:** F0-13 (`SaveService`) — o ticket já segue a proposta. **Decide:** tu, mas não há alternativa segura
  com `ResourceLoader`.

## Abertas — Parte XIII (§74 a §85)

> A §82 fecha com a regra: *"as dez perguntas acima entram no QUESTIONS.md com a proposta que já está nos CSV do
> anexo"*. É o que esta secção faz. A proposta de cada uma está na coluna `_proposed` da tabela indicada, e nenhuma
> delas bloqueia a Fase 0 — a única que bloqueava era a Q-037, fechada pela ADR 0011.

### Q-038 · A massa desce: a Q-001 muda de resposta?
- **Onde:** §74 (massa base de 60 para 40, termo do dia de 26 para 18) contra §07 e §31.
- **O que diverge:** a Q-001 media os arqueiros contra a noite com a massa antiga. Com 40 + 18 × dia a noite tem
  menos criaturas, e o Aríete de lodo chega mais tarde — o número que fazia o teste falhar pode ter mudado.
- **Proposta:** recalcular o teste da §31 com os números novos **antes** de o desmarcar. `docs/content/ROT_BY_DAY.md`
  já está gerado com a fórmula nova e serve de base à conta.
- **Bloqueia:** F1-09. **Decide:** tu.

### Q-039 · O Forno Aceso faz nascer um Amargueiro dentro das muralhas
- **Onde:** §77 (a lei do Forno Aceso: a brasa cria raiz ao sétimo dia, *"dentro das tuas muralhas inclusive"*)
  contra §74 (*"dentro das muralhas — não cria"*).
- **Proposta:** exceção deliberada, e a única. `chapters.csv` marca-a com `law_enters_walls`, e o teste D-10 falha
  se aparecer uma segunda. Se houver uma segunda, corta-se esta.
- **Bloqueia:** Fase 5. **Decide:** tu.

### Q-040 · "O que brilha, e nada mais" salta 105 s de jogo
- **Onde:** §75, quinta oferta.
- **Proposta:** uma vez por campanha. Saltar a noite duas vezes ensina a evitar o jogo em vez de o jogar.
  `offers.csv` traz `once_per_campaign = true` marcado em `_proposed`.
- **Bloqueia:** Fase 3. **Decide:** tu.

### Q-041 · Nove nomeados é teto fixo ou cresce com o império?
- **Onde:** §76, regra 1.
- **Proposta:** fixo. Cresce e deixa de significar nada — a escassez é o que faz o nome valer.
  `economy.csv` traz `named_cap = 9`; o teste D-07 guarda-o.
- **Bloqueia:** Fase 4. **Decide:** tu.

### Q-042 · A sexta Colheita em 16 dias é longa demais?
- **Onde:** §78 (`C = 6 + 2 × povos detidos`).
- **Proposta:** medir em playtest. Alternativa escrita: `6 + 1,5 × n`, arredondado para cima.
  `economy.csv` traz `colheita_base_days = 6` e `colheita_per_people = 2`, ambos marcados.
- **Bloqueia:** Fase 5. **Decide:** o playtest.

### Q-043 · Seis capítulos por campanha, ou os dez sempre?
- **Onde:** §77.
- **Proposta:** seis. Quatro por descobrir valem mais do que dez esgotados, e é o que dá os 126 mundos.
  O teste D-11 guarda o número e a presença d'O Cerco Que Não Acaba.
- **Bloqueia:** Fase 5. **Decide:** tu.

### Q-044 · O motivo sonoro da Podridão substitui o indicador visual?
- **Onde:** §81 contra §26.
- **Proposta:** coexistem, mas o visual é a própria candeia (§74) e não um ícone.
- **Bloqueia:** §26. **Decide:** tu.

### Q-045 · A Dívida fica escondida no modo de acessibilidade?
- **Onde:** §75 contra §26 e §82.
- **Proposta:** fica. O brilho da candeia e os estandartes dos povos soltos (§82) são a redundância;
  um número não é acessibilidade, é *spoiler*.
- **Bloqueia:** §26. **Decide:** tu.

### Q-046 · O Turno entra na Fase 8 ou corta-se?
- **Onde:** §79, terceiro epílogo.
- **Proposta:** entra. É um sinalizador no save e um termo na semente, e é o mais forte dos três.
  `rot.csv` guarda os limiares dos outros dois; O Turno é o ramo *"tudo o resto"* da precedência.
- **Bloqueia:** Fase 8. **Decide:** tu.

## Abertas — abertas pela recuperação da v6 (13/09/2026)

> `docs/recovery/v6-validation.json` regista seis perguntas novas (Q-047 a Q-052) mas não guardou o enunciado.
> O que segue foi reconstruído das duas únicas fontes que sobreviveram: o glossário das ferramentas
> (`ferramentas/src/03-paineis.js`, que cita a Q-047 pelo nome) e a lista `source_gaps` do próprio ficheiro.
> **Se tiveres o enunciado original, substitui — estas são a melhor reconstrução, não o registo.**

### Q-047 · Uma noite de pé, ou mais?
- **Onde:** §74, regra 2, e o glossário das ferramentas.
- **O que está em aberto:** o Amargueiro só se corta depois de aguentar uma noite inteira. Uma noite chega para
  fechar a exploração do vagabundo (paga-se +22 uma vez por árvore), mas não se sabe se o número devia subir com
  o dia, como sobe tudo o resto da §74.
- **Proposta:** fixo em 1 (`rot.csv`, `amargueiro_nights_standing`; `amargueiros.csv`,
  `nights_standing_required`). A conta da §74 — dez vagabundos são +220 na noite seguinte — já mata o império
  ao dia 6 com uma só noite. O teste D-03 guarda a regra.
- **Bloqueia:** Fase 2. **Decide:** tu.

### Q-048 · As nove cenas de segmento autoradas
- **Onde:** `source_gaps` da recuperação; §65 e §83.
- **O que falta:** as nove cenas de segmento escritas à mão não sobreviveram ao zip recuperado. A §83 exige que
  `seg_000` seja fixa e autorada, e agora com o Amargueiro velho e a candeia lá dentro desde o minuto 0:00.
- **Proposta:** refazer só a `seg_000` na Fase 1, com a lista de obrigatórios da §83, e deixar as outras oito
  para o greybox da Fase 2 — o gerador da §54 cobre-as até lá.
- **Bloqueia:** Fase 1. **Decide:** tu.

### Q-049 · O catálogo de tradução para além do título de arranque
- **Onde:** `source_gaps` da recuperação; §27 e §75.
- **O que falta:** `data/i18n/strings.csv` tem os nomes de conteúdo, mas a Parte XIII acrescenta 1 280 palavras
  novas (§75): doze frases de oferta, nove títulos, dez leis de capítulo e doze diários.
- **Proposta:** as chaves entram já (`OFFER_*`, `TITLE_*`, `CHAPTER_*`, `JOURNAL_*`), com o texto PT-PT do dossiê
  e o `en` por traduzir. A §27 passa a dizer *"precisa de mil e trezentas palavras"*.
- **Bloqueia:** Fase 3. **Decide:** tu.

### Q-050 · As tabelas de dados que faltavam
- **Onde:** `source_gaps` da recuperação (*"wildlife and remaining data tables"*).
- **O que diverge:** o zip recuperado trazia 17 tabelas e 154 recursos; este repositório tem 27 e 202. As dez que
  faltavam são as de fauna, segmentos, i18n e as quatro novas da Parte XIII.
- **Proposta:** o `_tables.csv` deste repositório manda, e a frase da §85 (*"os 154 recursos a partir das 17
  tabelas"*) passa a ser um número gerado e não escrito à mão.
- **Bloqueia:** nada — já aplicado. **Decide:** confirmar o número.

### Q-051 · Os sistemas de jogo e a cena de jogo
- **Onde:** `source_gaps` da recuperação (*"game systems and scene"*).
- **O que falta:** `src/sim/` tem os dados e as regras puras; os nove sistemas da Parte XIII (Amargueiro, Oferta,
  Dívida, Títulos, Capítulos, Colheita, Diários, Epílogos, Som) não têm implementação.
- **Proposta:** entram pela ordem de custo da §82 — §80, §74, §75, §83, §84 são o caminho mínimo de 52 h. Os
  catorze testes da §84 entram com cada sistema, não depois.
- **Bloqueia:** Fases 1 a 6. **Decide:** o calendário.

### Q-052 · CI remoto e exportação
- **Onde:** `source_gaps` da recuperação; §31 e §35.
- **O que falta:** ~~sem remoto nunca correu num runner limpo~~ — **corre.** A corrida **#19** pôs os cinco
  *jobs* verdes na mesma corrida (portões estáticos, dados e suite gdUnit4, export de Linux, camada do dossiê,
  e o `ci` que os junta), que era a condição para fechar esta pergunta. O que fica por fazer é o resto do
  enunciado: a **exportação só está testada para Linux**.
- **Proposta:** manter o `run_tests.sh` como contrato local e acrescentar os outros alvos de exportação quando
  houver máquina para os provar — exportar sem arrancar o binário não prova nada, e é o arranque que o job de
  Linux faz hoje.
- **Bloqueia:** Fase 2. **Decide:** tu — mas já não por falta de CI.

## Abertas — abertas ao implementar o anexo §85

### Q-053 · O preço da décima oferta
- **Onde:** §75, tabela das doze ofertas, linha *"Fica com a candeia por uma noite."*
- **O que diverge:** a coluna **Preço** diz *"Uma classe jogável, para sempre"* e a coluna **O que dá** diz
  *"Controlas a mancha esta noite e manda-la a um império rival"*. Lida como preço, a primeira só pode significar
  **perder** uma classe da §08 para sempre; lida como recompensa, seria a única linha da tabela com duas
  recompensas e preço nenhum.
- **Proposta:** é preço. `offers.csv` traz `price_kind = playable_class`, `price_amount = 1`, marcado em
  `_proposed`. A classe perdida escolhe-se largando a tropa dessa classe no prato, como todas as outras — continua
  a ser o Verbo 1. É o preço mais caro da tabela, e é por isso que só aparece ao dia 15 e vale +5 de Dívida.
- **Bloqueia:** Fase 3. **Decide:** tu.

### Q-054 · Dois capítulos ficaram sem raiz
- **Onde:** §77, caixa *"Cada lei tem uma raiz, e a raiz é verificável"*.
- **O que diverge:** a caixa lista oito raízes para dez capítulos. O Sulco Cego e O Cerco Que Não Acaba ficaram de
  fora, e a regra escrita é que **cada** capítulo sai de uma coisa que existiu.
- **Proposta:** `chapters.csv` propõe *"vozes sem corpo"* para O Sulco Cego e *"cerco sem fim"* para O Cerco,
  ambos marcados em `_proposed`. São descrições, não raízes verificáveis — falta-lhes a fonte.
- **Bloqueia:** Fase 5 (a escrita do habitante). **Decide:** tu.

### Q-055 · O desvio dos capítulos que não estão numa bifurcação nem numa travessia
- **Onde:** §77, regra 5 (*"25 s numa bifurcação e 40 s numa travessia"*).
- **O que diverge:** três das cinco colocações não são nenhuma das duas — beira da estrada, fortaleza e junto a
  acampamento de mercenários.
- **Proposta:** `chapters.csv` propõe 25 s para beira de estrada e acampamento (o desvio é curto) e 40 s para
  fortaleza (o desvio é uma região inteira). Marcado em `_proposed` nas dez linhas.
- **Bloqueia:** Fase 5. **Decide:** o playtest.

### Q-056 · O §46 dá a carga de cada sinal, mas não os tipos
- **Onde:** `docs/design/46-o-catalogo-completo.md` contra `src/core/event_bus.gd` (F0-07).
- **O que diverge:** a coluna *Carga* tipa sete parâmetros (`day: int`, `paused: bool`, `hit: bool`,
  `from, to: Phase`) e deixa os outros **cerca de quarenta** só com nome: `amount`, `source`, `ratio`,
  `tier`, `income`, `value`, `drops`, `segments`. Um sinal declarado exige o tipo escrito.
- **Proposta:** a regra que o F0-07 aplicou, para ser uma regra e não quarenta decisões avulsas —
  id de **dados** (existe numa linha de `data/source/*.csv`) é `StringName`; id de **instância**
  (sai do `next_id` do §45) é `int`; moeda, matéria e contagens são `int`; posição, massa, largura,
  rácio e duração são `float`; `drops` é `PackedStringArray` porque o CSV já os escreve `coins|corpse`.
- **Dois casos ficam por decidir, e estão implementados pelo mais simples:**
  `rot_summoned(creature_id)` leva o id de **dados** (é o que o §30 devolve em `pick.id`) enquanto
  `creature_died(creature_id)` leva o de **instância** — o mesmo nome de parâmetro para duas coisas;
  e `region_generated(segments)` ficou `int`, a contagem, porque a §46 não diz se é a lista ou quantos.
- **Bloqueia:** nada. Os tipos mudam sem quebrar ninguém enquanto não houver emissores — **e é agora
  que é barato**. **Decide:** tu, antes do F1-08 (o primeiro emissor de `rot_summoned`).

### Q-057 · O dossiê dá um número de câmara, e a câmara precisa de cinco
- **Onde:** `docs/design/24-controlos-hud-diegetico-e-feedback.md` contra `src/world/camera_rig.gd` (F0-08).
- **O que diverge:** a §24 escreve *"Reconhecimento; volta sozinha em 2 s"* para a câmara livre, e nomeia a
  antecipação ao dizer que a cegueira do Cavaleiro Selado a desliga. Não dá **nenhum** valor para a
  antecipação, para a suavização, nem para a velocidade da câmara livre. A §19 diz que "a câmara e o
  enquadramento dependem" da decisão de escala, que é o *spike* F0-09 e ainda não fechou.
- **Proposta:** os quatro valores entraram em `data/source/camera.csv` marcados em `_proposed`, porque a
  invariante I4 manda que o que se afina em *playtest* viva em `data/` e não num script:
  `lookahead_px` **120** (3/16 da meia-tela de 640 — deixa ver cerca de dois terços do ecrã à frente de quem
  anda), `lookahead_seconds` **0,6** (alto de propósito: uma antecipação que salta ao primeiro passo para trás
  dá enjoo), `follow_seconds` **0,18**, `free_speed_px_s` **420** (atravessa um segmento de 640 px em pouco
  mais de segundo e meio). O `free_return_seconds` é **2,0** e esse vem do dossiê.
- **Bloqueia:** nada — a câmara funciona e nenhum destes números é lido pela simulação. Mas o F0-09 pode
  mexer-lhes: se a escala mudar, a antecipação em píxeis muda com ela. **Decide:** o primeiro *playtest*,
  depois do F0-09.

### Q-058 · A célula das moedas contradiz-se dentro da própria tabela do §53
- **Onde:** `docs/design/53-faixas-colisao-e-a-matriz-que-tem-de-existir-no-.md`, as linhas `L_SURFACE` e `L_COIN`.
- **O que diverge:** `L_SURFACE` diz que colide com *"Terreno, edifícios, muralhas, **moedas**"*; duas linhas
  abaixo, `L_COIN` diz que colide com *"**Nada** — é apanha por proximidade"*, e justifica-o: *"colisão de moeda
  com 300 unidades é desperdício"*. As duas não podem ser verdade.
- **Proposta:** manda o `L_COIN`, porque traz a razão escrita e a razão é de desempenho. O `BandLayers` põe
  `coin_mask` a colidir só com o terreno da faixa onde a moeda foi largada — uma moeda tem de **assentar** no
  chão (§F1-01: largar, arco, queda, apanhar) — e nenhuma máscara de corpo inclui `L_COIN`. Há teste:
  `test_ninguem_apanha_moedas_por_colisao`.
- **Bloqueia:** nada hoje. **Decide:** o F1-01, que é quem primeiro larga uma moeda a sério.

### Q-059 · O `UnitSystem` do §30 é um `Node2D`; o do §41 e do §43 é simulação
- **Onde:** o §30 escreve `src/actors/unit_system.gd` com `class_name UnitSystem extends Node2D` e sprites lá
  dentro. O §41 põe os sistemas em `src/sim/systems/`, o §43 lista `UnitSystem — FSM` como o **passo 4 da
  simulação**, e o §52 descreve-o sem uma única referência a nós.
- **Proposta:** a especificação manda, pelo precedente da **Q-035** (*"a §46 manda (§39)"*): o §19 diz de si
  próprio que é o esboço e que a especificação está nas §39–§67. O `UnitSystem` é puro e vive em
  `src/sim/systems/`; o portão **G1** chumbaria de imediato um `Node2D` ali. A camada de apresentação é o
  `UnitView` (§58, F0-14), que é outra coisa e já existe. O próprio §30 fecha com a regra que isto aplica:
  *"os sistemas puros devolvem pedidos; só a camada de nós age"*.
- **Bloqueia:** nada. **Decide:** confirmação tua, ou uma ADR se preferires o contrário.

### Q-060 · `Array[UnitRec]` no §45 contra as colunas do F1-03
- **Onde:** o §45 declara `var units: Array[UnitRec] = []` e dá o `UnitRec` como classe; o título do **F1-03**
  é *"UnitSystem com arrays paralelos"*, e o §30 explica porquê: *"as unidades são linhas em arrays paralelos,
  não nós com script. É o que permite 300 unidades a 60 fps."*
- **O que diverge:** um `UnitRec` por unidade são 300 objetos `RefCounted` — exatamente o custo por unidade que
  o §63 orça para não existir.
- **Proposta:** as colunas são a verdade, e o `UnitRec` **não é criado**. O `UnitSystem` guarda `PackedArrays`
  com um campo por coluna, e o índice `i` é a mesma unidade em todas. O save leva as colunas, que já são tipos
  base e passam pelo canal da ADR 0007 sem conversão nenhuma — há teste. O `UnitRec` do §45 continua a ser a
  descrição do que uma unidade **é**; deixa de ser a descrição de como é guardada.
- **O que isto custa, e está escrito no código:** `remove()` troca com a última em vez de deslocar tudo, e por
  isso **muda a ordem das colunas**. Nada que afete a simulação pode iterar por índice e esperar estabilidade —
  itera-se por id crescente, que é o que a §42 já manda.
- **Bloqueia:** nada. **Decide:** tu, e antes do F1-14 (o save do estado a sério).

### Q-061 · O dossiê diz que a moeda é física e não diz com que física
- **Onde:** o §02 e o §61 fazem da moeda física o **Verbo 1** — *"tudo o que o jogador faz passa por ela"* — e
  o `economy.csv` traz **um** número para ela: `coin_pickup_px = 12`, já marcado em `_proposed` pelo F1-01.
  Um arco precisa de mais três, e nenhum está escrito em lado nenhum.
- **Proposta:** entraram em `data/source/economy.csv` marcados em `_proposed`, pela mesma regra do I4 que levou
  lá os da câmara (Q-057): `coin_gravity_px_s2` **700**, `coin_drop_speed_px_s` **180**,
  `coin_drop_spread_px_s` **40**. Dão um ápice de 23 px em contínuo — cerca de **20 px medidos a 30 Hz**, que é
  o que se vê — meio segundo de voo, e ±20 px de espalhamento, mais do que o raio de apanha de 12, para que
  duas moedas largadas juntas não se apanhem como uma só. Há teste a medir o ápice contra a fórmula, com a
  tolerância escrita como erro de discretização (`v0 · dt`) e não como um número a gosto.
- **Onde é que a moeda corre no tick:** o §43 tem onze passos e **nenhum é a moeda**. Corre no passo **5**, com
  o movimento, porque é movimento — e porque o passo 8 (BuildSystem) lê *"moedas largadas"* e portanto precisa
  delas já pousadas. Está escrito no `SimLoop` e no `CoinSystem`.
- **Bloqueia:** nada. **Decide:** o primeiro playtest — e o F1-06, que é quem constrói com a moeda a sério.

### Q-062 · Os portões mediam com um motor e o CI media com outro
- **Onde:** `ferramentas/verificar-dossie.mjs` e `ferramentas/verificar-novo.mjs`, em cada `goto`.
- **O que acontecia:** os dois abriam a página com `waitUntil: "load"` e uma espera fixa de 900 ms. O evento
  `load` **não** garante que as fontes da rede já foram aplicadas: com `display=swap` a página desenha-se com a
  de recurso e troca quando o ficheiro chega. Numa máquina fria isso acontece *a meio da medição*.
- **Como apareceu:** a corrida **#16** chumbou com duas falhas — «320px · "dia 11" fora do desenho» e
  «carregar num item leva à #s40 (desvio −4376px)» — que passavam em todo o lado.
- **O que a investigação encontrou, e é o mais importante:** neste ambiente as fontes **nunca** carregam. O
  Chromium do Playwright recusa o certificado do proxy (`net::ERR_CERT_AUTHORITY_INVALID`) e
  `document.fonts.size` é **0**. Ou seja: todas as corridas locais destes portões mediram uma página com
  tipos de letra de recurso, diferente da que o *runner* mede. Com o certificado ignorado à força, a medição
  local passou a dar **118 intactas · 5 a deslizar** — exactamente os números do *runner*, contra as 120 · 3
  de antes. Um portão de disposição cuja resposta depende de a rede ter chegado não é um portão.
- **A barreira entrou, e NÃO chegou.** Pôs-se `await página.evaluate(() => document.fonts.ready)` a seguir a
  cada `goto`, nos dois ficheiros. A corrida **#17** chumbou nas mesmas duas. A hipótese das fontes explicava
  a diferença de medição — e explica — mas **não** é a causa destas duas falhas. A barreira fica porque medir
  depois de as fontes assentarem é certo de qualquer maneira; não fica como correcção.
- **O que os números dizem agora:** o desvio mudou de **−4376 px** (#16) para **−4688 px** (#17). Não é uma
  diferença fixa de disposição: **varia entre corridas**. E as duas verificações que chumbam são as duas que
  medem depois de uma espera FIXA — `waitForTimeout(900)` a seguir ao clique, e a remedição a 320px. As
  vizinhas que esperam por uma condição («saltar para #s40 numa parte fechada: abriu=true, desvio 0px»)
  passam sempre, no mesmo ficheiro e na mesma corrida.
- **A causa, finalmente medida: era a VERSÃO DO MOTOR.** Os portões escolhiam o Chromium pela ordem errada —
  primeiro um caminho fixo (`chromium-1194`), e só se esse faltasse é que perguntavam ao Playwright. Nesta
  máquina o caminho fixo existe, no *runner* não: eu media com o **1194** e o CI media com o **1243**, em
  silêncio, durante três corridas. E a diferença não é cosmética. O salto do item da bandeja é **animado**, e
  no 1243 a animação demora quase o dobro:

  | motor | o salto assenta aos | o portão lia aos | resultado |
  |---|---|---|---|
  | 1194 (esta máquina) | **814 ms** | 900 ms fixos | passava, por 86 ms |
  | 1243 (o *runner*) | **1613 ms** | 900 ms fixos | lia a meio da animação |

- **Reproduzida.** Com o portão **antigo** e o motor do *runner*, a falha sai igual nesta máquina:
  `FALHA carregar num item leva à #s40 (desvio −4331px)` — e numa segunda corrida **−4639 px**. Varia aqui
  como varia lá (−4376, −4688), porque ler a meio de uma animação dá o sítio por onde a página ia passar. A
  série medida de 100 em 100 ms mostra-o inteiro:
  `113ms:−52409 · 213ms:−45372 · 313ms:−33967 · 413ms:−20681 · 514ms:−9275 · 614ms:−2236 · 714ms:0`.
  Os números do *runner* caem exactamente dentro desta curva.
- **Corrigido:** (1) pergunta-se ao Playwright PRIMEIRO qual é o Chromium, nos dois ficheiros — o caminho fixo
  passa a recurso e não a preferência, e esta máquina passa a medir com o motor do CI; (2) a verificação do
  item da bandeja espera até ESTABILIZAR — lê de 100 em 100 ms e só decide quando duas leituras seguidas
  coincidem, com tecto de 6 s e um piso de 400 ms (antes disso, duas leituras iguais são a página *parada* e
  não a página *assente*). O que se afirma não mudou; mudou quando se lê.
- **A segunda falha (o gráfico a 320px) era consequência da primeira — e eu tinha escrito aqui que não era.**
  A medição que me levou a isso foi feita nesta máquina: quando o gráfico se mede, a página já parou
  (`scrollY 38913 → 38913`). Só que esse «já parou» é do **1194**, onde a animação acaba aos 814 ms; no
  *runner*, onde acaba aos 1712 ms, o salto ainda ia a meio enquanto as verificações do simulador corriam, e o
  gráfico media-se sobre uma página em movimento. Corrigida a espera, a corrida **#19** passou as duas, e mais
  um número mudou de sítio com elas: os blocos de código a deslizar a 1280px passaram de **4** para **5**, que
  é o que esta máquina sempre mediu. Refutar uma hipótese com uma medição feita no ambiente errado é o mesmo
  erro das fontes, outra vez — e por isso fica escrito.
- **O que se fez em vez de adivinhar:** os portões passam a dizer com que números chumbam. Cada `FALHA` leva
  agora o detalhe — qual das quatro condições falhou e as caixas de cada rótulo — e cada corrida abre a
  declarar **que página mediu**: `motor: 153.0.8010.12 (…)` e `tipos de letra: 38 faces · loaded 10`. Uma
  destas duas linhas teria poupado as três corridas.
- **Fechada pela corrida #19:** os cinco *jobs* verdes, e as duas linhas que chumbavam a dizer
  `carregar num item leva à #s40 (desvio 0px, assente aos 1712ms)` e
  `320px · viewBox 246 · «dia 11» dentro do desenho`. Os 1712 ms do *runner* contra a espera fixa de 900 ms
  são a medida do que estava errado.
- **O que fica por decidir:** se o dossiê deve depender de uma CDN para a sua própria verificação. Continua a
  valer, e agora com mais provas: sem a CDN são **120 intactas · 3 a deslizar**, com ela **118 · 5**; uma face
  pode falhar sozinha (`IBM Plex Mono 500` deu `error` numa das medições) e só ela muda a contagem dos blocos
  de código; e os caracteres de desenho de caixa caem sempre para o tipo monoespaçado *da máquina*, que o
  *runner* tem e esta não. Embutir as fontes no ficheiro construído tornava o portão igual em qualquer máquina
  e sem rede. **Decide:** tu.

### Q-063 · O §25 descreve o minuto 0:20 em duas frases e não dá um número a nenhuma
- **Onde:** o §25 e o §83 dizem *"Largas uma moeda perto dele"* e *"O vagabundo segue-te"*, e o F1-04 tem de
  as pôr a funcionar. "Perto" não tem número, e "segue" não tem distância.
- **Proposta:** entraram em `data/source/economy.csv` marcados em `_proposed`, pela mesma regra que levou lá os
  da câmara (Q-057) e os da moeda (Q-061): `recruit_notice_px` **120**, `follow_distance_px` **30**,
  `follow_spacing_px` **18**. Os dois últimos estão ancorados na fila do §50 — `queue_min_px` 30 e
  `queue_spacing_px` 18 — **de propósito**: "a que distância uma pessoa espera por outra" já tem resposta neste
  jogo, e ter duas seria ter duas. Não se reutilizaram as chaves do §50 porque aquelas são de quem espera vez
  num muro; o dia em que uma mudar, a outra não tem de mudar com ela. O 120 é o limite exterior dessa mesma
  fila, que é a distância a que o jogo já diz que alguém pertence a um sítio.
- **Onde é que isto corre no tick:** procurar a moeda e andar atrás do rei **escrevem alvo**, e por isso são o
  passo **4** (*"estado, alvo, intenção de movimento"*). Apanhar e ser recrutado são consequência de ter
  **chegado**, e por isso são o passo **5**, a seguir ao movimento. O §43 não tem passo para a apanha, tal como
  não tinha para o arco (Q-061); está escrito no `SimLoop`, que é onde a ordem vive (ADR 0020).
- **O que a medição obrigou a mudar, e é a parte que interessa:** procurar moeda é uma varredura de unidades
  **contra** moedas, e o custo é o produto. Medido no pior caso do §63 — 300 por recrutar, 60 moedas no chão —
  a primeira versão dava **3871 µs só na procura**, e o tick completo **4372 µs** contra os **4000 µs** que o
  §63 dá à simulação **inteira**. Duas correcções, ambas indicadas pelo próprio dossiê:
  a procura passou a ser **fatiada** como a FSM (§52: *"é só a decisão que é fatiada"* — escolher para que
  moeda se anda é uma decisão), e a apanha deixou de varrer o chão todo por unidade, porque o passo 4 já
  escolheu a moeda e guarda-a no `target_ids` do §45, que estava na coluna à espera de quem o escrevesse.
  O tick ficou em **971 µs**. Se voltar a crescer, a alavanca é uma grelha por X (§53) e não o `AI_SLICE`.
- **O que fica por decidir:** (a) o §46 não tem sinal para *"deixou de ser de ninguém"* — o `unit_promoted` é
  do **JobSystem** no catálogo, e usá-lo aqui era inventar, por isso o recrutamento anuncia-se com
  `coin_spent(1, "recruit")`, que o §46 dá a *"Build, recrutamento"*; (b) um vagabundo por recrutar passa a
  ter o `set_target_x` **sobreposto** de seis em seis ticks por quem procura moeda — é o que se quer, mas é uma
  mudança de contrato para quem chamava esse método à mão. **Decide:** tu, e o primeiro playtest.

## Abertas — abertas ao encher o tick e a montar a cena de jogo

### Q-064 · O §55 dá estados à obra e não dá trabalho a nenhum deles
- **Onde:** a §55 escreve `EMPTY → SCAFFOLD → BUILDING(ratio) → DONE → DAMAGED(ratio) → RUIN` e diz que *"o
  progresso avança enquanto ele estiver presente"*. Não diz **quanto** avança, nem quanto tempo demora um muro.
  O `buildings.csv` tem `build_work` para os edifícios (regra proposta: 2 s × custo); o `walls.csv` não tem
  coluna nenhuma para isso.
- **Proposta, e é a mais reversível que há:** o muro herda a mesma regra proposta dos edifícios — `build_work =
  2 s × custo — lida do próprio canteiro em vez de repetida à mão (`Greybox._segundos_por_moeda()`). Uma
  estacaria de 6 moedas leva 12 s de construtor presente; um bastião de 65 leva 130.
- **E uma mão vale uma mão:** o progresso avança `delta × quantos estão em cima da obra`, **todos por igual**.
  O bónus do construtor é a habilidade do §09 (`builder_wall_bonus`, +8% de defesa) e não uma velocidade; dar-lhe
  aqui um multiplicador era inventar um número que o dossiê não escreve. Reparar uma obra `DAMAGED` com moeda
  também ficou de fora: é o posto `repair` do F1-05 mais a habilidade, e nenhum dos dois tem número.
- **Decide:** tu, e o primeiro *playtest* — é exactamente o tipo de número que o §67 diz que o greybox fecha.

### Q-065 · O §49 converte matéria em moeda por um ofício, e os ofícios são Fase 2
- **Onde:** o §49 tem três circuitos: produzir matéria, **convertê-la** por um ofício, e comércio. O circuito 2
  precisa do `CraftData` e do cozinheiro/ferreiro do §09, que são o F1-11 e a Fase 2. Sem ele a matéria acumula
  dentro do edifício e nunca sai — o que é o mesmo que não haver economia nenhuma no jogo.
- **Proposta:** enquanto não houver ofícios, a conversão é **1:1 e imediata**: um canteiro de
  `yield_per_day` 2 larga 2 moedas por dia, repartidas pelas seis fases (Q-027, fechada: *"o CSV guarda por dia
  e o sistema divide pelas fases"*). A moeda cai **por cima do edifício que a produziu**, que é a única parte
  em que o §49 não admite alternativa: *"nunca escreve um inventário do jogador. Não existe inventário."*
- **O que isto NÃO decide:** a taxa de conversão real dos ofícios. Quando o F1-11 entrar, a matéria passa a
  parar no `stock` e o ofício é que a tira de lá — e esta linha desaparece sem que mais nada mude.
- **Decide:** o F1-11.

### Q-066 · O Verbo 2 tem quatro usos no §24 e três deles não têm sistema
- **Onde:** o §24 dá ao Verbo 2 quatro contextos — *"trocar de classe, montar, entrar em passagem, subir em
  criatura"*. Classes são o §08, montarias o §12, e subir em criatura a habilidade do Trepador (§08): nenhum
  dos três existe. **Entrar em passagem** existe: a §11 dá as três faixas, o `units.csv` dá
  `can_change_band` ao monarca, e o `segments.csv` dá uma passagem por segmento.
- **Proposta:** o Verbo 2 faz **só** a passagem entre faixas, e a tolerância do gesto — a que distância da
  passagem a tecla ainda pega — é `SimFactory.PASSAGEM_PX` = **24 px**, ancorada na largura de uma tropa à
  escala 2 (§01). O dossiê não dá número nenhum a isto.
- **Decide:** tu. O §25 mede `underground_discovered` com alvo de 14 minutos (§32); se a mediana passar disso,
  o problema é a sinalização da passagem e não a tolerância.

### Q-067 · A roda do rei tem seis segmentos e quatro deles não têm sistema por trás
- **Onde:** o §24 chama à roda *"o único menu do jogo"* e dá-lhe seis segmentos: construir · recrutar ·
  ofícios · impulso · expedição · sucessão. Construir e recrutar **já são os dois verbos** e não precisam de
  menu; ofícios (§09), impulso (§15), expedição (§13) e sucessão (§15) não têm sistema nenhum.
- **Proposta:** a acção `king_wheel` (Tab) abre, por agora, o **painel de estado do greybox** — o que cada
  sistema está a pensar, para se poder testar uma mecânica sem ler o registo (§67, GB-03). Uma roda com quatro
  segmentos que não fazem nada é pior do que não haver roda: ensina um gesto que depois muda.
- **Decide:** a Fase 2, quando os quatro sistemas existirem. Até lá a tecla está ligada a alguma coisa em vez
  de estar declarada e por ler, que era o estado anterior.

### Q-068 · O §25 diz três Rastejantes na noite 1; a massa do §74 dá sete
- **Onde:** a tabela do §25 escreve *"Noite 1: três Rastejantes. Os arqueiros matam-nos do muro."* A massa do
  dia 1 é `40 + 18 × 1 = 58` (§74) e o Rastejante custa 8 (`creatures.csv`), o que dá **sete** — e é o que o
  `docs/content/ROT_BY_DAY.md`, gerado dos dados, escreve na linha do dia 1.
- **Não é um defeito do código:** o `RotSystem` gasta a massa como o §51 manda e o `ROT_BY_DAY` deriva dos
  mesmos números. A divergência é entre a **prosa do §25** e a **tabela do §74**, e as duas são do dossiê.
- **Porque é que importa:** o §25 diz que *"a noite 1 é ganha de certeza — está desenhada para isso"*. Sete
  Rastejantes contra um monarca sem muro não é isso.
- **E desde o F1-16 deixou de ser hipótese: é uma medição.** Com o núcleo já atacável (Q-076) o *greybox*
  corrido sem ninguém a jogar **perde na noite 1** — os sete Rastejantes chegam ao castelo-árvore e comem-no.
  Com as duas estacarias de dentro de pé aguenta a noite 1 com **376 de 1000** e perde na **noite 2**. Com a
  abertura do §25 inteira — muro **e** toda a gente recrutada — aguenta a noite 1 com **388** e perde na
  noite 2 na mesma. Só com as quatro muralhas e as quatro torres de pé é que o núcleo fica a **100%** ao
  quarto dia. Medido em `src/world/greybox.gd`, ao passo fixo, com a semente da suite.
- **Duas leituras, e a segunda é a Q-073:** ou a noite 1 tem criaturas a mais, ou a defesa tem postos a menos
  — nove tropas recrutadas num muro que publica **um** posto de guarda deixam oito a recolher ao núcleo, e
  isso não é uma defesa, é uma fila. As duas perguntas são a mesma medição vista de dois lados.
- **Decide:** tu, e é uma das duas — ou a prosa do §25 passa a sete, ou a `mass_base` do `rot.csv` desce. O
  `AGENTS.md` proíbe mexer no número para calar o teste, e por isso nada foi mexido.

### Q-069 · "CanvasModulate por faixa" pede a única coisa que o motor não faz
- **Onde:** o título do F1-13. O Godot aceita **um** `CanvasModulate` por canvas — é o que a documentação dele
  diz e é o que o nome quer dizer: ele modula *o canvas*. Três faixas no mesmo canvas não podem ter três.
- **Proposta:** um nó por faixa (`src/world/band_view.gd`) com o seu `modulate`. É a mesma multiplicação, e
  três nós irmãos podem tê-la diferente. A alternativa — três `CanvasLayer`, um por faixa — dava três
  `CanvasModulate` a sério, mas custava sincronizar a transformação da câmara à mão em cada um, porque um
  `CanvasLayer` não a herda. Isso é a pilha de parallax da §59 e é o ART-03; quando ela existir, este ficheiro
  passa a viver lá dentro sem que a conta mude.
- **E o segundo número que não existe:** o §80 dá `night_value_floor` 0,11 para o chão contra 0,16 do
  ambiente, e mais nada. Daí sai uma razão que vale em todas as fases; o subsolo leva-a duas vezes, porque não
  há número para ele e inventar um era escrever balanceamento em código (regra 3 do `AGENTS.md`).
- **Decide:** o ART-03, quando trouxer as seis camadas de parallax.

### Q-070 · Os dois caminhos da muralha são uma decisão, e não há onde a tomar
- **Onde:** o §10 escreve *"cada segmento oferece duas melhorias mutuamente exclusivas por nível. Nunca dá
  para ter as duas — **e essa é a decisão**"*. A **Guarnição** põe postos e deixa o muro frágil; a
  **Fortificação** põe vida e tira dano de saída. O `walls.csv` tem as quatro colunas para as duas.
- **O sistema está inteiro:** `BuildSlot.choose_path()` aceita a escolha até ao nível 1 — *"nunca dá para ter
  as duas"* também quer dizer que não se troca a meio — e a partir daí a vida e os postos saem do caminho
  escolhido. O que não existe é **onde carregar**: a roda do rei é a Q-067 e os dois verbos já estão tomados.
- **Proposta, por omissão:** `FORTIFICACAO`, que é a coluna que o §10 escreve como principal (é a coluna
  "Vida (B)" da tabela). Ninguém escolhe, e por isso escolhe-se a que o dossiê põe à frente.
- **Decide:** a Fase 2, com a roda. Até lá é uma linha no `greybox.gd` e muda-se num sítio.

### Q-071 · A fila do §50 mede-se do centro do muro, e um muro tem largura
- **Onde:** o §50 dá a fila como `wall.x + sign(...) * (30 + i * 18)`. O modelo dele não tem largura de muro;
  estes têm — a estacaria tem 64 px de silhueta. Trinta píxeis medidos do **centro** punham o primeiro da fila
  **dentro** dela, e quem tem *slot* de contacto ficava a 32 px de um alvo que alcança 24.
- **Proposta:** as distâncias medem-se da **face**. Quem tem *slot* fica na face (distância zero ao que vai
  bater); quem espera fica em `face + 30 + i × 18`, com o teto de 120 na mesma. O espaçamento do §50 mantém-se
  intacto — o que muda é de onde se conta, e é a única leitura que funciona com um muro que ocupa espaço.
- **Decide:** ninguém, se o greybox não desmentir. É geometria, não equilíbrio.

### Q-072 · O §06 diz que o pesqueiro é "imune ao rasto" e os dados só sabem dizer duas coisas
- **Onde:** a coluna *Risco* do §06 dá três estados diferentes — a plantação é *"destruída pelo rasto"*, o
  pesqueiro é *"imune ao rasto"*, e o galinheiro não diz nada. O §49 só escreve dois: *"a plantação no rasto é
  destruída; as outras só param"*. O `buildings.csv` tem uma bandeira, `destroyed_by_rot_trail`, e uma
  bandeira representa dois estados, não três.
- **O que está implementado:** os dois do §49. O pesqueiro não é arrasado (a bandeira está a `false`) mas
  **pára** enquanto o rasto o cobrir, como o galinheiro. A terceira leitura — produzir na mesma dentro do
  rasto — não está escrita em lado nenhum dos dados.
- **Proposta:** "imune" quer provavelmente dizer *fora do rasto*, e não *dentro dele a produzir*: o pesqueiro
  está na água e o rasto é de terra. Com geometria de água no segmento (GB-01) a frase resolve-se sozinha e
  sem coluna nova. Enquanto não houver água autorada, fica como está.
- **Decide:** o GB-01, ou uma terceira coluna em `buildings.csv` se o playtest a pedir.

### Q-073 · O §07 quer seis arqueiros num muro que só tem um posto
- **Onde:** o §07 fecha com a receita do microteste — *"monta um cenário fechado: um muro, **seis arqueiros**,
  uma noite de 105 s, vagas de Rastejantes crescentes. Ajusta até a noite ser ganha com **1–2 mortes no dia 5**
  e **perdida sem torre no dia 8**"*. O cenário existe (`tests/sim_harness.gd`, F1-15) e mede o contrário.
- **O que o instrumento lê**, com a estacaria de nível 1 e a semente do cenário:

  | Noite 5 | invoca | abate | mortes | ao muro | muro cai | núcleo |
  |---|---|---|---|---|---|---|
  | sem torre | 16 | 10 | **1** | 2 | **sim** | de pé |
  | com torre de arqueiros | 16 | 16 | **0** | 7 | não | de pé |

  E o dia 8 dá o mesmo desenho: sem torre o muro cai, com torre não. Sem torre o muro cai em **todas** as
  noites, a começar na 1 — e o §25 diz que a noite 1 *"é ganha de certeza"*.
- **Porque é que acontece, e não é um defeito do código:** a estacaria do §10 publica **um** posto de guarda
  (`guard_posts_b = 1`, `walls.csv`). Dos seis arqueiros, um sobe ao muro e os outros cinco ficam sem vaga, e
  quem não tem posto recolhe ao núcleo — a 500 px do muro, com 200 px de alcance. A noite inteira é decidida
  por **um** arqueiro. A torre de arqueiros dá mais dois postos, e é isso que a tabela de cima mede: *"a torre
  não dá dano — dá certeza"* (§07) está certo, e é a única coisa desta medição que está.
- **O que o F1-16 lhe acrescentou, e não fechou:** com o núcleo já atacável (Q-076) a segunda linha mudou de
  razão mas não de resposta — uma noite 8 **sozinha** continua a acabar com o castelo-árvore de pé, porque o
  muro cai tarde e o que resta da noite não chega para os 1000 de vida. Dez noites seguidas já chegam, e é
  isso que o `tests/dez_dias_test.gd` mede. A primeira linha está como estava.
- **Porque é que o F1-16 não a podia fechar, e não é falta de vontade:** a opção (b) é subir os postos de
  guarda, e no nível 1 não há onde. O §10 escreve *"o nível 1 é a base comum aos dois caminhos"*, e os postos
  do caminho A desse nível estão **na tabela do dossiê** — mexê-los é mexer no dossiê, não em `_proposed`. O
  `guard_posts_b` está proposto, mas pô-lo acima de A no nível 1 desfazia a base comum.
- **Decide:** tu, e é uma de três — (a) a receita do §07 passa a incluir a torre, e o "sem torre no dia 8"
  passa a ser a variante; (b) os postos de guarda do §10 sobem no nível 1, e aí é o dossiê que muda; (c) um
  arqueiro sem posto passa a disparar de onde está, e aí a §52 ganha uma regra que hoje não tem. O `AGENTS.md`
  proíbe mexer no número para calar o teste, e por isso nada foi mexido: os dois testes do §07 estão
  **saltados com esta razão** em `tests/noite_do_07_test.gd`.

### Q-074 · O §66 quer dez dias em dez segundos, e o tick fica no fio da navalha
- **Onde:** o §66 dá ao bloco *"Uma noite completa"* o critério *"corre em headless com delta fixo, **dez dias
  em menos de dez segundos**"*. Dez dias são 3600 s de jogo a 30 Hz — **108 000 ticks** —, o que dá um
  orçamento de **92 µs por tick**.
- **O que se mede:** o cenário fechado — duas obras, sete tropas, vagas de Rastejantes — corre os dez dias em
  **≈18 s** num *runner* headless. Medido por passo: **≈22 µs** com o mundo vazio, **≈99 µs** com as sete
  tropas e as duas obras, **≈275 µs** a meio da noite 10. O `EventBus` não é o custo (desligar a história
  muda 3%); o custo é o tick, e cresce com as obras e com as tropas antes de crescer com as criaturas.
- **Não colide com o §63:** o orçamento do §63 é de **4000 µs** por tick para a simulação inteira, e a 30 Hz
  isso é tempo real com folga — o `jogo_noite_test` mede-o e passa. O que o §66 pede é outra coisa: **360× mais
  depressa do que o tempo real**, que é o que faz de um cenário um instrumento de afinação em vez de uma
  partida acelerada.
- **Proposta:** medir antes de otimizar. Este número sai de um binário de editor em *debug*, com as
  verificações de tipo do GDScript e os `assert` ligados; a mesma medição sobre um *export* de release é o
  primeiro passo, e não custa nada senão correr o CI. Se a diferença não chegar, o §66 é que escolhe: ou o
  orçamento sobe, ou o tick emagrece — e aí é trabalho de simulação, com ticket próprio.
- **O que o F1-16 voltou a medir:** noutro *runner* headless, com o mesmo binário de editor, os mesmos dez
  dias custam **9,4 s numa corrida e 11,1 s na seguinte** — o orçamento do §66 passou a estar dentro da
  variação da máquina. Não é uma melhoria do tick: é a mesma medição noutro sítio, e é exactamente a razão
  para o teste continuar saltado. Um portão que responde à carga do *runner* e não ao código chumba a quem
  não mexeu em nada.
- **Bloqueia:** o teste está saltado com esta razão em `tests/noite_do_07_test.gd`. O que **não** está saltado
  é o que o F1-15 promete: os dez dias correm, em headless e ao passo fixo, e o relógio chega ao dia 11.
- **Decide:** tu. Não bloqueou o F1-16 — a afinação lê a tabela noite a noite, e essa é rápida.

### Q-075 · Uma criatura ataca de qualquer faixa que o `targets_bands` liste, de onde quer que esteja
- **Onde:** o F1-07 escreveu para as tropas a regra do alcance vertical (`Posts.reaches`, Q-006): a faixa
  própria alcança sempre, qualquer outra só com um posto que dê altura. Do lado das **criaturas** não havia
  regra nenhuma — o `TargetPicker._tropa_mais_proxima` olhava só para o `targets_bands` do `CreatureData`.
- **O que isso fazia:** o Cavador, que nasce na faixa subterrânea, atacava tropas da superfície **sem nunca
  subir**. O §07 diz que ele *"passa pela faixa subterrânea"* — passa, e passar é o que o torna uma ameaça,
  porque passa **por baixo do muro**. Atacar de lá não está escrito em lado nenhum, e tornava decorativo todo
  o `src/sim/systems/passages.gd` do F1-09: a passagem que o §25 manda abrir ao minuto 10:00 deixava de ter
  a factura que o mesmo §25 lhe põe ao minuto 12:00.
- **Decidido, e a decisão sai dos dados que já lá estavam:** `Passages.reaches(dados, sua_faixa, alvo)`. A
  faixa própria alcança sempre; outra faixa só se a criatura **não puder** mudar de faixa. O `can_change_band`
  do §44 separa exactamente as duas criaturas que o §07 descreve de maneiras diferentes:
  - o **Alado** (`can_change_band = false`) vive no ar e bate no chão de lá — *"ignora a camada de solo; só
    atacável por arqueiros e torres altas"* (§07). A resposta a ele é um posto que chegue lá acima, e é a
    torre alta.
  - o **Cavador** (`can_change_band = true`) tem de **subir** para bater, e sobe onde há passagem (§11, §51).
- **É uma mudança de comportamento**, e só toca no Cavador: o Rastejante, o Bruto, o Aríete e a Consumidora
  nascem e batem na superfície, e para eles a regra é a identidade.
- **Reversível, e o que a reverte:** se um dia o Cavador tiver de morder tornozelos de baixo para cima, o
  `return not dados.can_change_band` passa a `return true` e volta tudo ao que era. Nenhum número de `data/`
  foi mexido.

### Q-076 · O jogo não se podia perder: nada mordia o castelo-árvore — **fechada pelo F1-16**
- **Onde:** o §10 escreve a regra mais curta do dossiê — *"se o castelo-árvore cair, cai a partida"* — e ela
  estava implementada dos dois lados: o `BuildSystem.fallen()` sabia responder e o `src/world/game.gd` parava
  o relógio. O que não existia era o caminho pelo meio: **nada lhe tirava vida**.
- **A causa, e era de uma linha:** só o `WallData` tinha `contact_slots` (`walls.csv`, 2 a 7 pelos cinco
  degraus do §10). O `BuildingData` não tinha essa coluna, e por isso o `BuildSlot.contacts` de tudo o que não
  é muro ficava vazio e o `contact_slots()` devolvia **zero**. A `ContactQueue` do §50 reparte *N* atacantes
  por *N* slots; com zero slots não atribuía nenhum, o `target_slots` ficava em `NENHUM`, o `engaged()` dava
  falso, e o `CombatSystem._criaturas_batem()` saltava a criatura. **Só o muro podia ser atacado** — e era por
  isso que só o muro caía.
- **Decisão — a proposta, tal como estava escrita:** `contact_slots` passa a ser coluna do `buildings.csv`,
  como a que o `walls.csv` já tinha. Não inventa mecânica nenhuma, usa a fila do §50 que já existe, e uma obra
  com a coluna a zero comporta-se exactamente como antes — que é o caso de **todas** menos uma.
- **O número, e porque é que ele não decide nada:** o núcleo leva **7**, que é o topo da escada do §10 — o
  Bastião, a outra obra *única por império*; o núcleo é a maior do mapa (480 px) e a última. O dossiê não dá
  este número, e por isso ele está marcado em `_proposed` e a escolha é revertível. **E a varredura mostra que
  ela não muda o critério do §66**: com 2, 3, 4, 5 ou 7, as mesmas defesas aguentam e as mesmas caem. A única
  linha que se mexe é a muralha de ferro nos dois flancos, que a 2 slots aguenta com **5%** de núcleo — o fio
  da navalha que a escolha de 7 evita.
- **O que isto passou a medir** (`godot --headless --path . scenes/tests/dez_dias.tscn`, nove defesas, dez
  dias cada, com um Bastião só — o §10 escreve-o *"único por império"*):

  | esq | dir | torre | alta | arq | aguentou | núcleo |
  |---|---|---|---|---|---|---|
  | 1 | 1 | não | não | 6 | caiu no dia **3** | 0,00 |
  | 4 | 4 | sim | sim | 12 | caiu no dia 10 | 0,00 |
  | 5 | 4 | sim | não | 12 | caiu no dia 9 | 0,00 |
  | 5 | 4 | não | sim | 12 | caiu no dia 9 | 0,00 |
  | 5 | 4 | sim | sim | 6 | caiu no dia 9 | 0,00 |
  | 5 | 4 | sim | sim | 12 | **aguentou** | **1,00** |

  A primeira linha é a receita do §07 tal e qual. A última é a defesa do décimo dia, e é a única que aguenta:
  o §66 tem as duas metades que pede.
- **Onde:** `data/source/buildings.csv`, `src/sim/data/building_data.gd`, `src/world/greybox.gd`,
  `tests/support/closed_region.gd`. Os testes são o `tests/dez_dias_test.gd`, e nenhum deles está saltado.

### Q-077 · O Alado atravessa a muralha, pousa no castelo e não faz nada
- **Onde:** o §07 dá ao Alado a linha *"Dia 4 — obriga a torre alta"*, e o §10 vende a torre alta por 30
  moedas para *"atingir a camada aérea"*. Medido no cenário dos dez dias, os dias 4, 5 e 6 — que são os dele —
  **não custam nada a ninguém**.
- **A causa:** para uma criatura AÉREA nenhuma obra de superfície é barreira. O `BuildSystem.barrier()` filtra
  por faixa (`vaga.band != faixa`), e por isso o Alado nunca encontra muro nem núcleo no caminho: só olha para
  tropas, dentro dos seus 24 px de alcance. Atravessa a muralha, atravessa a região, pousa no castelo — e o
  castelo perde **0%**. Medido numa noite posta de propósito sem muro nenhum: os Alados do dia 5 chegam a
  **0 px** do núcleo.
- **O que a torre alta vale hoje, então:** os **dois postos** que publica, com precisão 1,0 — e não a altura.
  A varredura dos dez dias mostra-o: tirar a torre alta à defesa que aguenta faz cair a partida no dia 9, e
  faz cair pela mesma razão que tirar a torre de arqueiros faria. Não é a faixa aérea que ela está a defender.
- **Proposta:** ou a `barrier()` deixa de filtrar por faixa para quem voa — e aí um Alado bate no que estiver
  por baixo —, ou o `targets_bands` do §44 passa a valer também para obras, e a faixa da obra entra na conta
  como já entra a da tropa. A segunda usa uma coluna que já existe e não inventa regra nenhuma; a primeira é
  menos escrita e mais surpresa.
- **Bloqueia:** a linha *"obriga a torre alta"* do §07, e com ela metade do valor da torre de 30 moedas. Não
  bloqueia o F1-16: o critério do §66 mede-se e passa sem ela, e passaria com mais margem contra.
- **Não é a Q-075, e as duas encostam:** a Q-075 deu regra ao alcance vertical de uma criatura sobre as
  **tropas** — e para o Alado a resposta é que ele bate no chão de onde está, porque não pode mudar de
  faixa. Esta é sobre as **obras**, e o caminho é outro: quem filtra por faixa é o `BuildSystem.barrier()`,
  e ele não sabe nada de `targets_bands`.
- **Decide:** tu. É a segunda metade da Q-076, tal como ela estava escrita antes de o F1-16 a fechar, e é
  do F1-09 — o ticket do Alado e do Cavador.

### Q-078 · O farol ilumina 300 px e a candeia nunca passa dos 260
- **Onde:** o §80 escreve a regra de composição da noite inteira — *"uma luz domina por ecrã. Se duas
  competem, o ecrã lê plano. Consequência de design, não só de arte: as tuas fogueiras têm de ser **mais
  fracas do que a candeia à mesma distância**"*. E o §10 vende o farol por 40 moedas para *"iluminar 300 px"*.
  A candeia do §74 é `150 + 4 × dia`, **com teto em 260**. O farol é a única obra do jogo com `light_radius`,
  e ganha à candeia em qualquer dia.
- **Porque é que o raio decide isto:** com as mesmas três paragens, a luz de raio maior é mais forte a
  **qualquer** distância — o núcleo e o meio dela chegam onde a outra já é bordo. Duas luzes com paragens
  diferentes era outra conversa, e o §80 não dá paragens às fogueiras: dá **uma** regra de luz ao jogo todo.
- **Não bloqueia nada hoje, e é por isso que é uma pergunta e não um defeito:** o farol é de Fase 6, não está
  no *greybox*, e tem `blocks_summon` — *"A Podridão não invoca dentro da luz"* —, portanto a candeia e ele
  talvez nunca se encontrem no mesmo ecrã de propósito. O `tests/candeia_test.gd` tem o teste **saltado** com
  esta razão, e ele volta sozinho no dia em que a pergunta fechar.
- **Proposta:** a mais reversível é dar ao farol paragens próprias e mais fracas — uma coluna nova em
  `buildings.csv`, como o `light_radius` já é — em vez de lhe cortar o raio, que é um número do dossiê. A
  alternativa é escrever no §80 que o farol é a excepção: ele é *landmark* e não fogueira, e um marco que
  domina o seu ecrã é exactamente o que um farol faz.
- **Decide:** tu. A palavra que falta ao dossiê é se "fogueira" inclui o farol.

### Q-079 · O vocabulário de formas do *greybox*: uma por categoria, até haver arte
- **Onde:** §22 (*"a paleta muda com a hora do dia e com o LUT; a silhueta do telhado não muda nunca"*, e os
  seis kits de arquitetura), §80 §5 (a tabela do teste de silhueta), §25 (*"a silhueta é o convite"*), e
  `src/world/silhouette.gd`.
- **O que o dossiê não diz:** o dossiê decide que a **silhueta é a identidade** de uma obra, e decide de onde
  ela virá — do **kit de arquitetura do povo** (§22: stavkirke para os Enramados, basalto para a Fornalha, o
  negativo do desfiladeiro para a Fenda). O que ele não diz é que forma tem um canteiro **enquanto não há
  arte**, e até agora a resposta do repositório era "nenhuma": tudo era o mesmo rectângulo cinzento, e um
  canteiro, uma torre e o castelo-árvore só se distinguiam pela largura.
- **O que está escrito, e é reversível numa linha:** uma forma por **`category` de `buildings.csv`** — a
  coluna que já existe —, mais o muro (que vem de `walls.csv` e se reconhece por ter os dois caminhos do §10),
  mais uma por `tag` de `creatures.csv`, mais uma marca por `weapon_kind` de `units.csv`. Nada disto é um `if
  id == "archer_tower"`: sai todo de `data/`, e no dia em que aparecer a sexta obra de defesa ela ganha forma
  sozinha. As formas estão em `src/world/outline.gd`, em centésimos da caixa, e trocar uma é trocar uma linha
  de números.
- **As três coisas que escolhi e o dossiê não escreve** — e por isso estão aqui e não caladas:
  1. **As alturas.** O §01 fixa a escala das personagens (16 px = um degrau) e o §10 dá as **larguras** em
     `width_px`, mas nenhuma secção dá altura a um edifício. As do `Silhouette.DEGRAUS` estão em degraus —
     um canteiro dá pelo ombro, uma torre são cinco pessoas, a torre alta são oito — e a do castelo-árvore
     **não é uma escolha de escala**: sai da geometria das faixas, porque o §11 diz que a copa entra na faixa
     aérea e diz porquê.
  2. **A ruína.** O §55 dá seis estados a um sítio de obra e o dossiê descreve cinco. Uma ruína desenha-se com
     a mesma forma, rente ao chão: reconhece-se o que era, e vê-se que já não é.
  3. **A calha da barra de vida.** O §07 diz *"sem números no ecrã, nada de barras de vida flutuantes"*, e o
     `Gauge` é o contrário disso e sabe que é (GB-03, §67: o *greybox* existe para se **medir** uma noite).
     Com calha, 23 px de barra num castelo de 480 px passam a ler-se como 5% em vez de como um risco.
- **Proposta:** fica assim até ao **ART-01/ART-02**. Este vocabulário é o *fallback* neutro — um povo só, sem
  kit —, e a forma definitiva é por povo **e** por categoria, como o §22 manda. O `tests/outline_test.gd`
  guarda a única regra que tem de sobreviver à arte: **duas formas nunca desenham a mesma coisa**.
- **Decide:** tu. Não bloqueia nada, e nada na simulação muda com isto — é tudo apresentação (§45).

### Q-080 · A que luz se vê um corpo à noite
- **Onde:** §80 §1 (a tabela de tectos de valor, com *"inalterado"* na linha do plano de jogo), §80 §3
  (*"perto da luz vê-se cor e volume; longe vê-se silhueta"*), §22 degrau 3 (*"uma rampa 1D por hora do dia;
  todos os sprites amostram através dela"*), e `src/world/lighting.gd`.
- **O que estava errado, e mede-se:** o ambiente da fase vinha no `modulate` do nó da faixa, e um `modulate`
  multiplica **tudo** o que o nó desenha. Multiplicava três coisas que não são a mesma, e a terceira era um
  defeito a sério: **a candeia saía com luminância 26 contra um céu de 34** — a fonte de luz ficava mais escura
  do que o fundo, e o §80 diz o contrário em duas palavras, *"âmbar é luz"*. Ao lado disso, o chão era
  desenhado com `SOLO * plane()` e o `Color * float` do GDScript multiplica **quatro** componentes: o chão saía
  a 69% de opacidade sobre o cinzento por omissão do motor, e à noite dava (32,29,26) contra um céu de
  (36,34,30). Sem horizonte não há §11 nenhuma. Os dois estão corrigidos e têm teste.
- **O que não vem do dossiê, e por isso está aqui:** com o ambiente aplicado só onde ele manda, faltava
  responder *quanto* dele chega a um corpo. Escurecer a cor de cada um pelo ambiente deixava um vagabundo
  (0,93 0,85 0,61) a **luminância 31 contra um céu a 34** — a mesma mancha, e não se via. O que está escrito é
  a leitura literal do §80 §3: longe de qualquer luz o corpo é **uma silhueta**, um valor escuro só — o
  `#100D09` que o §80 §1 nomeia —, e perto da candeia é a cor dele. Mede 16 contra 34, e vê-se a **forma**,
  que é o que a §22 diz que identifica uma coisa.
- **As duas excepções que abri, e porquê:** o **chapéu** (§25, *"ele apanha-a e ganha um chapéu"*) e os
  **instrumentos** do `Gauge` não levam luz nenhuma. Um sinal de dono que se apaga à noite deixa de ser um
  sinal, e o *greybox* existe para se **medir** uma noite (§67, GB-03). Com isto, à noite vêem-se vultos
  escuros e os que têm um ponto dourado em cima são teus — que é a leitura do Kingdom.
- **Proposta:** fica assim até ao ART-02. A rampa 1D da §22 é o mecanismo certo e não existe enquanto não
  houver *sprites*; o que está escrito é a mesma decisão feita com `draw_rect`. O portão que a guarda é o
  `make silhueta`: a noite tem de abrir a gama que a paleta do §80 lhe dá, e a noite chapada de antes abria
  2,7× contra os 16,3× exigidos.
- **Decide:** tu. Nada na simulação muda — é tudo apresentação (§45).

### Q-081 · A derrota é de quem tem a cena aberta, e isso é deliberado
- **Onde:** §10 (*"se o castelo-árvore cair, cai a partida"*), §45 (o estado autoritativo),
  `src/world/game.gd`, `tools/vistoria.gd`.
- **O que a `make vistoria` mostrou:** quem pára a partida é a `game.gd` — um **nó** —, e por isso a regra só
  vale com a cena aberta. Uma ferramenta que chame `SimLoop.step()` a mão continua a correr dias sobre um
  castelo-árvore em ruína, e foi o que a vistoria fez: **sete dias**.
- **A correcção óbvia está errada, e experimentei-a.** Pôr o `step()` a parar sozinho quando o núcleo cai
  chumbou **três** instrumentos do próprio repositório, e pela mesma razão: eles existem para MEDIR uma
  derrota. O §66 varre nove defesas por dez dias e a coluna que interessa é *"em que dia caiu"*; o
  `jogo_noite_test` quer ver o amanhecer a seguir a uma noite que o *greybox* perde (Q-068). Um `step()` que
  pára tira-lhes o que eles vieram contar. **Quem joga tem cena; quem mede, não** — e a linha fica onde está.
- **O que mudou:** nada na simulação. A vistoria passou a perguntar pelo `builds.fallen()` e a dizer em que
  dia o castelo caiu, que era o que faltava — o instrumento é que estava a medir uma partida acabada.
- **O que continua por decidir:** o §46 **não tem sinal de derrota** e inventar um quebrava a regra 7 do
  `AGENTS.md`. O §16 (ressurreição até ao amanhecer) e o §15 (sucessão) não existem, e por isso a derrota é um
  fim seco: o relógio pára e é preciso reabrir o jogo.
- **Decide:** tu. A pergunta é se a derrota ganha sinal próprio na §46 quando o §15 e o §16 chegarem — e é aí
  que um `step()` que pára deixa de tirar nada a ninguém, porque passa a haver o que ouvir.

### Q-082 · O §21 dá dois tempos de travessia e eles não são o mesmo tempo
- **Onde:** §21 (*"Região — 4 a 6 ecrãs de largura... deriva-o do tempo de travessia: a pé (§12) uma região
  deve levar 40–60 s a atravessar de ponta a ponta, o que a 26 px/s dá 1000–1560 px por ecrã"*), §47
  (`SEGMENT_WIDTH 640`), §12, §19 e §44 (`move_speed = 26.0`), `data/source/units.csv`, `src/world/greybox.gd`.
- **A contradição, numa linha:** a primeira metade da frase diz que a **região** se atravessa em 40–60 s; a
  segunda faz a conta como se fossem 40–60 s **por ecrã**. Uma região de 1040–1560 px não são "4 a 6 ecrãs"
  de 640 px, nem "oito segmentos por região" — as duas metades não podem ser verdade ao mesmo tempo.
- **O que o jogo fazia:** nem uma nem outra. A região do *greybox* tem 3840 px (seis ecrãs de 640) e toda a
  `units.csv` andava aos 26 px/s que o §19 e a §44 escrevem como **valor por omissão do campo**. São **148 s**
  de ponta a ponta, num dia que dura 360 s (`clock.csv`) — quase metade de um dia a andar em linha reta, só de
  ida. Foi por aqui que a queixa do jogador entrou: *"o personagem está a mover-se extremamente lento"*.
- **O que foi decidido, e é reversível:** manda a primeira metade — a que a própria secção escreve como
  **ordem** (*"deriva-o do tempo de travessia"*). A pé são 80 px/s, 48 s de travessia, e a coluna inteira da
  `units.csv` sobe pelo mesmo factor para não perder as relações autoradas. A `creatures.csv` não se toca: a
  velocidade das criaturas está na tabela do §07 e é conferida contra o dossiê. Ver ADR 0021.
- **O que continua por decidir:** se o que se quis dizer foi mesmo 40–60 s **por ecrã**, então o número que
  está errado não é a velocidade — é a região, e ela tem de passar de seis segmentos para dois e meio, o que
  contradiz o §21 noutro sítio. Corrigir o dossiê fecha isto num dos dois sentidos; enquanto não for
  corrigido, o `tests/travessia_test.gd` é que guarda a leitura escolhida.
- **Decide:** tu. A pergunta é qual das duas metades da frase do §21 fica no dossiê.

### Q-083 · O §24 manda largar em contínuo e não diz a que ritmo
- **Onde:** §24 (mapa de comando: *"Largar em contínuo — A/✕ (manter) — Espaço (manter) — Pagar vários
  níveis de uma vez"*), §55, `src/ui/input_router.gd`, `data/source/economy.csv`.
- **O que faltava:** a linha estava no mapa de comando do §24 desde a v2 e **ninguém a lia**. O
  `input_router.gd` dizia-o no cabeçalho — *"manter para largar em contínuo espera pelo BuildSystem a aceitar
  pagamento por nível de uma vez"* — e isso era uma leitura a mais: o §55 quer a moeda física a cair uma a uma
  (*"uma obra existe quando uma moeda cai num BuildSlot"*), e o que o §24 pede não é um pagamento de uma vez, é
  **a mesma moeda a sair sozinha**. Pagar o Bastião de 65 moedas à tecla eram 65 toques.
- **O número que não está no dossiê:** o ritmo. Fica `coin_drop_repeat_s = 0,12` — pouco mais de oito moedas
  por segundo, o degrau mais caro do §10 (o Bastião, 65) em 8 s de tecla premida. O valor vem do PR #16, que
  chegou a esta mesma linha do §24 por outro caminho e o escreveu num `const` do router com a justificação
  certa (*"depressa o bastante para encher uma obra sem martelar a tecla, devagar o bastante para se ver cada
  moeda a cair"*); ao juntar os dois ficou o **número dele** e o **sítio deste** — `economy.csv`, pela regra 3
  do AGENTS.md, ao lado da gravidade e da dispersão do arco, que são a mesma classe de número.
- **O que isto NÃO faz, e é de propósito:** não paga vários níveis de uma vez. O §55 diz que uma obra a meio
  não aceita moeda, e por isso o contínuo enche o degrau seguinte, a obra arranca, e as moedas que saírem
  depois ficam no chão à espera do degrau a seguir — que é o que o Kingdom faz.
- **Decide:** tu, e é um número de playtest. Mais depressa e a moeda deixa de se ver a cair; mais devagar e a
  muralha de ferro volta a ser um exercício de dedo.

### Q-084 · O knockback do §24 é o único terço do impacto que mexe na simulação
- **Onde:** §24 (*"Impacto — flash branco de 80 ms, **3 px de knockback**, partícula de 4 px na direção do
  golpe"*), §45, §50, §61, `src/world/impact_view.gd`.
- **O que foi feito:** dois dos três. O flash e a partícula são apresentação e vivem no `ImpactView`; o
  `building_damaged` — o sinal que uma noite do *greybox* emite às centenas e que não se via em lado nenhum —
  acende a orla da obra que está a ser comida.
- **Porque é que o terceiro ficou de fora:** empurrar um corpo 3 px muda uma **posição**, e posições são a
  simulação (§45). Um empurrão dado da camada de apresentação tira um atacante da fila de contacto do §50 sem
  que o §50 dê por isso, e um empurrão que o *save* não conhece torna a partida irreproduzível pela mesma
  semente (§61, §42) — que é a propriedade que este repositório mais protege.
- **O que falta para o fazer:** um número em `data/` (3 px é do dossiê, mas falta dizer se é por golpe, se
  acumula, e se um Bruto empurra um vagabundo tanto como o contrário), e um sítio em `src/sim/` que o aplique
  no passo 6 do §43, a seguir à resolução do combate e antes do movimento.
- **Decide:** tu. A pergunta é se o empurrão é do atacante (massa) ou do golpe (dano), porque disso depende se
  ele vive no `CombatSystem` ou numa coluna nova.

### Q-085 · O §52 diz que quem luta não anda; o §24 diz que o comando "Mover" vale sempre
- **Onde:** §52 (a tabela de estados: `FIGHT | Inimigo em alcance | Alvo morre ou sai de alcance | Resolução de
  combate`), §24 (mapa de comando: *"Mover — Stick esquerdo / D-pad — A · D · ← → — **Sempre**"*), §08,
  `src/sim/systems/unit_system.gd`.
- **O que estava a acontecer:** o monarca tem `damage 3` e `range_px 30` (`units.csv`), e por isso o
  `target_picker` põe-no em FIGHT como põe qualquer tropa. Com o FIGHT a proibir movimento, uma criatura a
  30 px tirava o jogo das mãos de quem o joga **até ela morrer** — e numa noite com cinco delas à volta, isso
  era a partida inteira a ver-se a si própria.
- **A leitura que mudou:** a última coluna da tabela do §52 é o **custo por tick** de cada estado — GOTO custa
  "movimento em X", FIGHT custa "resolução de combate" — e não uma proibição. A proibição era uma
  interpretação do código, defensável para uma tropa (um lanceiro `holds_line` não deve sair da linha) e
  insustentável para o corpo que uma pessoa conduz.
- **O que foi decidido, e é reversível:** quem é conduzido por uma pessoa anda mesmo em FIGHT; quem a §52
  conduz continua a segurar a linha. Entra por parâmetro no `tick_movement()` e não por coluna, porque não é
  propriedade da unidade — é quem a está a conduzir agora, e isso vive no `SimLoop` (§45). Andar para fora do
  alcance desengata sozinho, e por isso fugir continua a custar o golpe que se deixa de dar.
- **Decide:** tu. A pergunta aberta é a da Fase 2: quando o Verbo 2 deixar assumir outros corpos (§24), o
  "conduzido" passa a ser mais do que o `king_id` — e aí talvez valha a pena ser coluna.

### Q-086 · A base do Amargueiro não tem largura
- **Onde:** §74 (*"largar moedas na base"*), §55 (a moeda cai *numa* obra quando cai dentro da meia largura
  dela), `data/source/rot.csv`.
- **O que falta:** o corte é um slot de destino no BuildSystem, e um slot precisa de largura — é ela que diz
  se uma moeda caiu na árvore ou ao lado, e quem está lá a serrar. O dossiê não a escreve.
- **O que foi feito, e é reversível:** `amargueiro_base_px = 32`, marcado em `_proposed` — a largura do barril
  de fogo, a obra mais estreita de `buildings.csv`. Um tronco é mais estreito do que uma casa e mais largo do
  que uma pessoa.
- **Decide:** o playtest — se largar seis moedas numa árvore obrigar a acertar, sobe.

### Q-087 · Consagrar pede uma Semente Real, e a Semente Real ainda não se larga
- **Onde:** §74 (*"Consagrar — largar 1 Semente Real na base"*), §15, §57 (CrownSystem), §61 (Verbo 1).
- **O que falta:** o Verbo 1 hoje larga moedas e só moedas. A Semente Real existe como número nos dados
  (`class_data.gd`, `economy_curve.gd`) e como sinal no catálogo (`seed_royal_gained`), mas não há inventário
  de sementes nem gesto para largar uma.
- **O que foi feito:** o destino está inteiro no `AmargueiroSystem.consecrate()` — vira Marco, sai da massa,
  protege 120 px de raízes novas, e a mancha abranda 40% sobre ele (testado pela `NightWatch`). O que não
  existe é quem o chame. Liga-se no dia em que a semente for uma coisa que sai da mão.
- **Bloqueia:** o "Feito" do XIII-03 fica parcial por isto. **Decide:** o calendário — é o CrownSystem da
  Fase 2, e não uma decisão de design.

### Q-088 · "Não é recolhida antes da alvorada" — não há gesto para recolher
- **Onde:** §74 (*"uma tropa que morre fora das muralhas e não é recolhida antes da alvorada cria raiz"*;
  *"reutiliza inteiro o gesto que a §16 já tem para o Santuário das Raízes"*), §16.
- **O que falta:** o gesto de arrastar um corpo para dentro é do Santuário das Raízes (§16), e o Santuário
  ainda não existe. Hoje um corpo fica onde caiu.
- **O que foi feito:** a regra de onde cria raiz está inteira — dentro das muralhas não cria, no subsolo cria,
  a voadora cai para a superfície, o Marco protege o raio dele. "Dentro" é haver, do lado do corpo, um muro de
  pé cuja face de fora está mais longe do núcleo do que ele (`AmargueiroRoots`): quem morre no posto do muro
  morreu em cima dele, e não fora. Recolher entra com o §16, e só muda o x do corpo antes da alvorada.
- **Decide:** o calendário.

### Q-089 · O vagabundo tem escala 2 no units.csv e a §74 dá-lhe escala 1
- **Onde:** §74, regra 3 (*"Escala 1 e vagabundo: 1 Lenho. Escala 2, tropa: 2"*), §22, `units.csv`
  (`vagrant,…,scale_tier 2`).
- **O que diverge:** a escala do §22 é a da figura, e um vagabundo tem o tamanho de qualquer tropa. A regra 3
  lê-se como "a carne barata rende pouco", e por isso junta o vagabundo à escala 1.
- **O que foi feito, e é reversível:** o vagabundo rende como escala 1 por exceção explícita
  (`AmargueiroRoots.VAGABUNDO`); todas as outras tropas rendem pela `scale_tier`. Uma linha a apagar, se a
  leitura for outra.
- **Decide:** tu.

## Resolvidas na v5.2 (reversíveis)

| # | O quê | Decisão | Onde |
|---|---|---|---|
| Q-019 | §30 escolhe criatura ao acaso; §51 manda "a mais cara que cabe" | **§51 manda** (`pick_rule`); o F1-08 corrige o código do §30 | `rot.csv`, ROT_BY_DAY |
| Q-020 | §42: sementes por XOR com constantes que não são hexadecimal (`0xR0T7`, `0xEC0N`); o código usa `hash(str(seed) + nome)` | o código manda; a tabela passa a dizer "derivada do nome do fluxo" | §42 |
| Q-021 | §47 manda `DAY_SECONDS` para a `EconomyCurve`; a §69 cria o `ClockData` | `ClockData` | ADR 0006 |
| Q-022 | ids em português nos exemplos (`enramados_arqueiro.tres`, `enramados_ferreiro_body`) contra a regra "código em inglês" | inglês | NAMING_BIBLE §5 |
| Q-023 | §22 "uma camada por slot" contra §58 "um ficheiro por slot" | fonte: um ficheiro por corpo com camadas; exportação: uma folha por camada com o nome da §58 | ASSET_BIBLE §2 |
| Q-026 | relatório mestre: `waves.csv`, `jobs.csv`, `GREYBOX_RULES` em `docs/design/` | `rot.csv` (§70); `jobs.csv` = postos; `docs/world/` | CONTENT_DATABASE §4 |
| Q-027 | §49 lê `yield_per_phase`; o §06 dá números por dia | o CSV guarda por dia; o sistema divide pelas fases | `building_data.gd` |
| Q-032 | sete correções aos ficheiros do dia zero (C-01 a C-07) | aplicadas | ADR 0009 |

## Resolvidas na Parte XIII (reversíveis)

| # | O quê | Decisão | Onde |
|---|---|---|---|
| Q-037 | A noite é azul profunda (§05) ou castanha (§80)? | **castanha** — 32° · 0,22 · 0,16, chão em 0,11 | ADR 0011, `clock.csv` |

