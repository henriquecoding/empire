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

### Q-006 · Quem atinge a faixa aérea?
- **Onde:** §07 (Libélula: "só atacável por arqueiros e torres altas"; Alado: "obriga a torre alta") e §10.
- **O que diverge:** se os arqueiros atingem a faixa aérea, o Alado não obriga a nada.
- **Proposta:** geometria — um arqueiro no chão não chega aos 200 px do topo com 200 px de alcance; em muro ou
  torre de arqueiros também não; **só a torre alta** (`hits_aerial`) e os arqueiros de copa. Os dados já dizem
  `targets_bands = SURFACE|AERIAL` no arqueiro; o alcance vertical decide.
- **Bloqueia:** F1-07, F1-09.

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

### Q-033 · A curva do §06 e os edifícios reais
- **Onde:** §06 (o simulador usa "fontes" abstratas: base = 3 + 2,6 × fontes) contra os edifícios de `buildings.csv`
  (2 a 5 por dia cada).
- **Proposta:** o `EconomySystem` (F1-10) calcula o rendimento a partir dos edifícios; o teste de design compara-o
  com o modelo de referência e o dia de asfixia tem de continuar entre 9 e 14. Se não bater, afina-se `economy.csv`.

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

