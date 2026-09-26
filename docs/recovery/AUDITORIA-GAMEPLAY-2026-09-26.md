# Empire — auditoria de gameplay e plano de melhoria

**Data:** 26/09/2026 · **Árvore auditada:** `main` em `7b1f7c2` (PR #34), sem alterações locais ao código.
**Motor:** Godot `4.6.stable.official.89cea1439`, *headless*. **Pedido:** *"a gameplay ainda precisa melhorar muito, há
coisas faltando e coisas mal feitas — analise profundamente o repositório e faça uma densa pesquisa na web para
um relatório denso e completo, para eu melhorar o que já existe."*

Este documento **acrescenta** ao `ASTRA-RETOMADA-2026-09-25.md` (que continua a ser a fotografia de 25/09 e as
suas secções de seguimento 24–26). Não repete o diagnóstico visual de lá; foca-se no que o jogador **faz, decide e
sente**, e em defeitos de simulação que os testes atuais não apanham porque cada sistema passa sozinho.

---

## 0. Leitura de três minutos

**O estado, medido hoje.** A suíte tem **717 casos: 711 passam, 6 saltados, 0 falhas**. O circuito curto do
Kingdom existe e joga-se só com gestos (recrutar → caçar → pagar → ver construir → colher). Há reparação, Casa de
Treino, celeiro/cozinha, três impulsos reais, a escolha A/B da muralha, a Podridão com candeia, Amargueiros, quatro
ofertas, nomes e diário 1. **Mas o jogo ainda não é uma partida**: é uma região única que se defende até cair,
sem vitória, sem campanha, sem sucessão, sem som, e com a economia que o CI afina desligada da economia que corre.

**Oito defeitos reproduzidos hoje** com testes dirigidos (anexo A), nenhum apanhado pela suíte:

| # | Defeito | Consequência para quem joga |
|---|---|---|
| D1 | O **celeiro muda de modo sozinho** e come a própria venda assim que existe um cozinheiro | A decisão "moeda agora ou capacidade depois" é tomada pelo jogo, não por ti |
| D2 | **Retomar o autosave repete a alvorada**: produção a dobrar e a Colheita perde um dia | Carregar a partida muda o resultado; *save-scum* dá moedas |
| D3 | A **certeza da torre vai com o posto e não com o sítio**: 100% de precisão e 280 px de alcance a 500 px da torre | A regra-bandeira do §07 ("a torre dá certeza") é falsa em jogo |
| D4 | **Pagar o degrau seguinte de um muro tira-lhe a barreira** (e os postos) até a obra acabar | Melhorar o muro ao fim da tarde abre a porta à noite |
| D5 | **A moeda não tem destinatário**: cai 8 px ao lado do primeiro vagabundo e paga a Casa de Treino | O minuto 0:20 — o gesto que ensina o jogo — pode falhar sem explicação |
| D6 | **O rei morre e a partida continua sem ninguém para comandar** (sem sucessão, sem derrota) | *Soft-lock*: o jogador fica a ver o reino cair |
| D7 | **A economia do CI não é a do jogo**: o modelo dá 21,2→33,4 moedas/dia (dias 1–5); o jogo produz 17 fixas | O "dia da asfixia 9–14" é afinado sobre um número que o jogador nunca vê |
| D8 | **Com as regras inteiras (voz da Podridão ligada), nenhuma das 9 defesas do §66 aguenta 10 dias** | O teste verde do §66 desliga a voz; o critério "possível e não trivial" não se cumpre no jogo real |

**Os cinco problemas de design mais caros**, por ordem de valor:

1. **Não há objetivo depois do dia 3.** Capítulos planeados mas não visitáveis, conquista inexistente
   (`GameState.conquests` nunca recebe nada), epílogo calculado e nunca chamado, derrota = recomeçar do zero.
2. **Decisões dominadas.** A Colheita Forçada é **sempre prejuízo** (−6,4 moedas no melhor caso); o modo
   capacidade do celeiro troca ~8 moedas/dia por +1 de vida a cada arqueiro; o construtor custa 22 moedas por −8%
   de dano nos muros e não constrói mais depressa que ninguém.
3. **Economia sem sorvedouros e sem crescimento.** Manutenção, ganância e custo da noite só existem no modelo;
   os edifícios pagam-se em 2–2,7 dias e depois é só acumular. A produção não depende do trabalhador no posto.
4. **A noite é espera.** 135 s de 360 (37,5%) em que os verbos do jogador quase não mudam o resultado; não há
   aviso de *lado* nem de *composição* antes do crepúsculo; zero som.
5. **As faixas vertical e aérea não são jogo ainda.** O subsolo é um corredor com dois segredos; o Alado (dia 4)
   pousa e não faz nada (Q-077); o Cavador (dia 10) é a primeira ameaça subterrânea e nada a contraria.

**Recomendação.** Antes de mais conteúdo: fechar D1–D6 (uma semana de trabalho pequeno e bem testável), tornar
a economia do jogo a economia medida (D7), e dar ao dia 3–10 **um objetivo e uma decisão por dia** — a proposta
mínima está no §7 (P-A a P-O) e no roteiro do §8.

---

## 1. Âmbito, método e como ler este relatório

### 1.1 O que foi feito

- `git merge --ff-only origin/main` na branch de trabalho: a branch estava **55 commits atrás** da `main`. Toda a
  análise é sobre `7b1f7c2`.
- Leitura de `AGENTS.md`, `README.md`, `docs/POR_FAZER.md`, `docs/recovery/RETOMADA.md`,
  `ASTRA-RETOMADA-2026-09-25.md`, `docs/QUESTIONS.md` (104 perguntas escritas, até à Q-113; 2 fechadas), e das secções do dossiê que os
  sistemas citam (§06, §07, §10, §15, §16, §24, §25, §49, §55, §74, §75, §83).
- Leitura integral dos sistemas de simulação e de ligação: `sim_loop.gd`, `field_work.gd`, `verbs.gd`,
  `night_watch.gd`, `sim_save.gd`, `coin_system.gd`, `build_system.gd`, `build_slot.gd`, `economy_system.gd`,
  `conversion_system.gd`, `training_system.gd`, `crown_system.gd`, `hunting_system.gd`, `hunt_watch.gd`,
  `job_board.gd`, `posts.gd`, `recruit_system.gd`, `repair_work.gd`, `greybox.gd`, `wall_site.gd`, `game.gd`,
  `gameplay_guide.gd`, e partes de `combat_system.gd`, `offer_system.gd`, `harvest_system.gd`.
- Execução: import, **suíte inteira**, `vistoria` de 10 dias, `dez_dias` (§66), e **9 reproduções dirigidas**
  (anexo A) numa pasta temporária fora de `tests/` — não entram no commit para não mudar as contagens que o
  `check_claims` confere.
- Pesquisa na web: Kingdom (New Lands, Two Crowns), Thronefall, Dome Keeper, Against the Storm, Frostpunk, Into the
  Breach, o *AI Director* de Left 4 Dead, *value chains* e Machinations, *Beyond the HUD*, Game Accessibility
  Guidelines, requisitos do Steam Deck, método RITE e *Juice it or lose it* (fontes no anexo D).

### 1.2 Rótulos

| Rótulo | Significa |
|---|---|
| **Reproduzido** | Há um teste dirigido que mostra o comportamento, com o número que saiu (anexo A). |
| **Medido** | Saída de uma ferramenta do repositório corrida hoje (suíte, vistoria, `dez_dias`). |
| **No código** | Lido e seguido até à consequência; não reproduzido em partida. |
| **Estimativa** | Conta feita com os CSV e hipóteses escritas ao lado. |
| **Proposta** | Sugestão. Pelo `AGENTS.md` ("não inventes mecânicas"), cada proposta que muda regra precisa de uma decisão — pergunta em `docs/QUESTIONS.md` ou ADR — antes de código. O anexo C traz as perguntas em rascunho. |
| **Descartado** | Hipótese verificada e que não se confirmou. Fica escrita para ninguém a voltar a perseguir. |

### 1.3 Medições de hoje

| Verificação | Resultado |
|---|---|
| Import *headless* | OK |
| Suíte gdUnit4 | **717 casos · 711 passam · 6 saltados · 0 falhas · 0 *orphans*** (3 min 37 s) |
| Saltados (inalterados) | Q-078 candeia/farol · Q-073 ×2 noite do §07 · Q-074 dez dias em <10 s · Q-001 TTK · Q-101 recusar sempre |
| `vistoria --dias 10` (piloto) | **3 de 10 dias**, o núcleo cai ao dia 3; o rei morre na noite 2 (coluna `rei = -1` a partir do dia 3) |
| `dez_dias.tscn` (§66, com a voz) | **as 9 defesas caem** — a melhor (Bastião + ferro + torres + 12 arqueiros) cai ao **dia 10** |
| Erro espúrio na suíte | `registry_test.gd:44` formata `"%s" % nulos` com um *array* vazio → "not enough arguments for format string" (inofensivo, mas polui o registo) |

---

## 2. O que existe, de ponta a ponta — e o que só existe em dados

A pergunta útil não é "há ficheiro?", é "**o jogador consegue fazer isto e ver a consequência?**".

### 2.1 Jogável de ponta a ponta (gesto → simulação → save → ecrã)

| Frente | Como se joga hoje | Observação |
|---|---|---|
| Andar, câmara livre, interpolação | A/D, Q/Z, rato na margem | Sólido (GB-10…GB-12). |
| Moeda física (Verbo 1) | Espaço larga uma moeda do saco do rei; manter larga em contínuo | O preço aparece por cima do que está debaixo do rei (PriceTag). |
| Recrutar (0:20) | Moeda perto de quem não é de ninguém | Arqueiro custa 3, lanceiro 4, vagabundo 1. Ver D5. |
| Caça em vagas | Arqueiros teus caçam de dia; a caça vai para o saco deles e passa ao rei quando se cruzam | 3–9 coelhos/dia em três vagas (Q-106, Q-111). Coelhos estáticos (ver §5.6). |
| Obras e postos | Moedas no sítio → andaime → quem está em cima constrói | Qualquer tropa tua conta por igual (Q-064). |
| Produção (circuito 1) | Canteiro 2/dia, galinheiro 3/dia, pesqueiro 3/dia, moeda no chão por fase | Não depende do trabalhador (ver §5.3). |
| Reparação | Moedas numa obra tocada ou em ruína | Q-108. |
| Muralha, 5 níveis, caminho A/B | Verbo 2 junto ao muro antes do nível 2 | Ferro pede Fornalha **ou** 1 Lenho; Bastião, 3 Lenhos. Ver D4. |
| Torres e torre alta | Postos que dão precisão/alcance/altura | Ver D3. |
| Podridão, candeia, criaturas nas três faixas | Nasce ao crepúsculo, invoca por massa, recua à alvorada | Massa 58→220 do dia 1 ao 10. |
| Moral e fuga, raio do rei | Automático | Vigília desliga a fuga uma noite. |
| Casa de Treino → construtor | Moedas na casa; o trabalhador mais perto entra um dia | −8% de dano nos muros (Q-109). |
| Cozinha → cozinheiro; celeiro (circuito 2) | Grão vende a +50%; moeda no celeiro com cozinheiro troca para +10% vida | Ver D1 e §5.2. |
| Impulsos reais | Tab + 1–6; um por dia | 3 de 6 ligados (Q-110). Ver §5.1. |
| Ofertas da candeia | Prato ao crepúsculo | 4 de 12 (Q-099). |
| Nomes/feitos | Automático | 5 de 9 feitos; 1 de 9 bónus (Q-102). |
| Amargueiros e Lenho | Nascem dos mortos; serram-se com moedas | Único caminho para ferro e Bastião sem conquista. |
| Segredos e diário 1 | Estátua, câmara atrás da passagem, ruína | Descoberta passiva. |
| Pausa, opções, acessibilidade | Tremor, clarões, legendas, contraste, 3 modos de daltonismo, duração do dia 240–540 s | Bom ponto de partida (§26). |
| Derrota pelo núcleo | Ecrã "A coroa caiu" → novo jogo do zero | Sem *decay* (Q-088). |

### 2.2 Parcial — existe, mas falta a metade que faz dele uma decisão

| Frente | Falta |
|---|---|
| Faixa subterrânea | Um corredor com a câmara da Semente Real e as duas passagens. `cavity_slots` do `segments.csv` não é lido; nada se constrói nem se extrai lá em baixo. |
| Faixa aérea | O Alado atravessa, pousa e não faz nada (Q-077). A libélula (`dragonfly`) existe em dados e não aparece. |
| Colheita (§78) | O sistema inteiro existe; ninguém a começa (Q-103) porque não há conquista. |
| Capítulos (§77) | Seis sorteados com a semente e guardados no save; **nenhum se visita**. A bifurcação a +1800 px só mostra uma marca. |
| Epílogos (§79) | `NightWatch.epilogue()` calcula qual dos três finais; nada o chama. |
| Morte e sucessão (§15, §16) | Nem herdeiro, nem interregno, nem ressurreição, nem *decay*. Ver D6. |
| Guia/objetivo | Escada fixa: trabalhador → reparar → caçador → canteiro → muro → "explora". Depois do muro, "explora" não aponta para nada que dê recompensa proporcional. |

### 2.3 Só em dados (nenhum sistema lê)

Contagem por literal em `src/` (o construtor, por exemplo, funciona pelos `ability_params` e não pelo nome da
habilidade, e por isso aparece na lista sem estar partido):

- **16 edifícios fora do mundo**: forja, embaixada, casa do herdeiro, santuário das raízes, estábulo de montarias,
  estábulo de vacas, serração, mina, salgadeira, curral, serraria, fundição, barril de fogo, fosso de raízes, farol,
  altar consagrado.
- **39 de 64 *tags*** sem leitor — entre elas as que dariam decisões baratas: `stealable_at_night` (galinheiro),
  `attracts_burrowers` (mina), `priority_target` (Casa de Treino), `repairs_walls`, `opens_passages`,
  `plants_in_combat`, `climbable` (Devorador).
- **12 habilidades** sem leitor por nome (`dig_passage`, `repair_wall`, `plant_in_combat`, `siege_ram`,
  `shoot_from_canopy`…).
- Fauna: `move_speed`, `flees`, veado e javali — **nada** disto chega à caça.
- Economia: `upkeep_*`, `night_cost_*`, `trade_*`, `debt_*`, `heir_*`, `greed_*` — só o modelo as usa.

Isto não é um defeito: é o mapa do que falta. Serve para escolher **o que ligar primeiro** pelo critério "dá uma
decisão nova com a arte e os dados que já existem" (§7).

---

## 3. O ciclo do jogador, com números

### 3.1 O relógio (clock.csv, dia de 360 s)

| Alvorada | Manhã | Meio-dia | Tarde | Crepúsculo | Noite |
|---:|---:|---:|---:|---:|---:|
| 15 s | 85 s | 40 s | 85 s | 30 s | 105 s |

**225 s de luz e 135 s de ameaça.** A Podridão invoca a cada 4–7 s enquanto está ativa → 19 a 33 invocações no
máximo por noite (ROT_BY_DAY.md).

### 3.2 Preços e rendimentos (CSV v5.2)

| Coisa | Custo | Rende / faz | *Payback* |
|---|---:|---|---:|
| Vagabundo · arqueiro · lanceiro | 1 · 3 · 4 | trabalho · caça + defesa · linha | — |
| Canteiro | 4 | 2 moedas/dia | **2,0 dias** |
| Galinheiro | 8 | 3/dia | **2,7 dias** |
| Pesqueiro | 6 | 3/dia | **2,0 dias** |
| Celeiro | 10 | grão a +50% (4 canteiros: 8 → 12/dia) | 2,5 dias sobre os canteiros |
| Cozinha + cozinheiro | 10 + 10 | ativa o modo capacidade do celeiro | — |
| Casa de Treino + construtor | 10 + 12 | −8% dano nos muros (não soma) | — |
| Estacaria → paliçada → pedra → ferro → bastião | 6 → 11 → 20 → 36 (+1 Lenho) → 65 (+3 Lenhos) | vida e postos por caminho | — |
| Torre de arqueiros · torre alta | 18 · 30 | precisão 100% (+40% alcance) · atinge a faixa aérea | — |
| Impulso real | 12 | ver §5.1 | — |
| Serrar um Amargueiro | 6 | 1–3 Lenhos | — |

As sete fontes do greybox (4 canteiros, 2 galinheiros, 1 pesqueiro) custam **38 moedas** e dão **17 moedas/dia**.

### 3.3 O modelo que o CI afina contra a produção que corre — **reproduzido (D7)**

Sete fontes de pé desde o dia 1, rei parado no núcleo:

| Dia | `daily_income` (modelo do §06, o do teste da asfixia) | Produção real (moedas `production` que caíram) | `built_income` (terceiro número, com crescimento) |
|---:|---:|---:|---:|
| 1 | 21,2 | **17** | 17,0 |
| 2 | 23,7 | **17** | 19,0 |
| 3 | 26,6 | **17** | 21,3 |
| 4 | 29,8 | **17** | 23,9 |
| 5 | 33,4 | **17** | 26,7 |

Três números para a mesma pergunta. E os sorvedouros do modelo — `upkeep(14) = 3,0/dia`, `night_cost` de 6,1 a
13,5 do dia 1 ao 5, ganância 28% — **não existem na partida**. O teste mais importante do projeto segundo o §29
(asfixia entre os dias 9 e 14) mede uma economia que o jogador não joga. A Q-033 já nomeava a divergência; o que
este relatório acrescenta é o tamanho dela em moedas e a falta de crescimento em `EconomySystem.on_phase`
(`src/sim/systems/economy_system.gd:146` soma `yield_per_day / fases × impulso`, sem `income_growth`).

### 3.4 A pressão — massa da Podridão (piso, ROT_BY_DAY.md)

| Dia | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Massa | 58 | 76 | 94 | 112 | 130 | 148 | 166 | 184 | 202 | 220 |
| Mais cara | rastejante | ↑ | ↑ | alado | ↑ | ↑ | bruto | ↑ | ↑ | cavador |

Sobre isto somam-se +22 por Amargueiro de pé, +45 por nomeado e **até +40 por recusar ofertas** (8 × recusas das
últimas cinco noites).

### 3.5 O orçamento dos dez dias — **estimativa**

A defesa que o §66 usa para dizer "é possível" (a última linha do `dez_dias`) custa:

| Peça | Moedas | Outros |
|---|---:|---|
| Muro esquerdo até ao Bastião (6+11+20+36+65) | 138 | 1 Lenho (ferro) + 3 Lenhos (Bastião) |
| Muro direito até ao ferro (6+11+20+36) | 73 | 1 Lenho |
| Torre de arqueiros + torre alta | 48 | — |
| 12 arqueiros | 36 | — |
| **Total** | **≈ 295** | **5 Lenhos** (2–5 serras × 6 moedas, e Amargueiros só nascem de mortos teus) |

Receita máxima em dez dias, com hipóteses explícitas: 6 iniciais + caça 30–90 (3–9/dia) + produção líquida ≈ 115
(17/dia dos dias 2 a 10, menos as 38 das fontes) + saque noturno 50–150 (medido: 63 moedas de morte em 12 noites
com cinco soldados e torres, ≈ 5/noite nas primeiras; e só conta se alguém as apanhar fora do muro). **Cenário
médio ≈ 260; teto ≈ 360.** Sem recrutar trabalhadores, sem casas de ofício, sem reparar, sem impulsos.

Leitura: a defesa "possível" do §66 está **no limite superior do que a economia real produz**, e ainda assim cai ao
dia 10 com a voz ligada (D8). Não é prova de impossibilidade — é o motivo para existir um instrumento que jogue a
economia real (proposta P-E, teste no §8). Hoje ninguém mede isto.

### 3.6 A abertura, marco a marco (dossiê §25/§83 × jogo)

| Marco | O que o dossiê quer | O que acontece (medido/código) |
|---|---|---|
| 0:00 | Rei, 6 moedas, ruínas, vagabundo, Amargueiro velho | ✔ |
| 0:20 | Uma moeda recruta; chapéu | ✔, mas o vagabundo nasce **na borda** da Casa de Treino (−240 contra −360…−240) — D5 |
| 1:10 | Arqueiro caça coelho | ✔ (demonstração única, no save) |
| ~1:47 | — | 4 moedas de caça no saco do rei (histórico ASTRA §26) |
| ~2:00 | Canteiro pago e de pé | ✔ (ASTRA §26: 119 s) |
| 3:30 | Estacaria convidativa, custo 6 | Possível; compete com recrutar e com a caça que ainda falta |
| 3:45 (225 s) | Crepúsculo | A colheita do canteiro só cai aos 255 s (já à noite) |
| Noite 1 | "Ganha de certeza" | Massa 58 → 7 rastejantes (Q-068); sem muros o núcleo cai na noite 1; o piloto cai no dia 3 |
| 17:00–18:00 | Primeira oferta | ✔ (ADR 0023) |
| 20:00 | Alguém ganha nome | ✔ para 5 dos 9 feitos |

---

## 4. Defeitos confirmados

Cada entrada: **evidência → causa → consequência → correção → aceitação.** As reproduções estão no anexo A.

### D1 · O celeiro muda de modo sozinho e come a própria venda — **reproduzido**

- **Evidência:** celeiro e quatro canteiros de pé, um cozinheiro teu vivo **no núcleo** (a 1450 px do celeiro),
  rei parado, dia e meio sem nenhum gesto → **1 troca de modo, 1 moeda consumida, modo final = CAPACIDADE**.
- **Causa:** `ConversionSystem.on_phase` larga a venda **no x do celeiro** (`conversion_system.gd:97-108`);
  `ConversionSystem.absorb` trata **qualquer moeda pousada** a meia largura do celeiro como o gesto de trocar de
  modo (`:114-133`). Sem cozinheiro o `absorb` faz `continue`, por isso o defeito só aparece quando o jogador já
  investiu 20 moedas em cozinha e cozinheiro — o pior momento.
- **Consequência:** o jogador que escolheu vender perde a venda seguinte e passa a capacidade sem saber porquê.
  A próxima moeda que lá cair (a dele ou outra) volta a trocar. O Kingdom ensina exatamente o contrário: *"If they
  do something bad, it's usually in response to an action from the player"* (80.lv, anexo D).
- **Correção:** o modo só muda por uma moeda **do jogador**. Duas vias, por ordem de custo:
  1. a venda do celeiro cai **fora** do raio de troca (à porta, no lado do núcleo) — uma linha, sem save novo;
  2. a solução de fundo é D5/P-A (a moeda leva quem a largou e para quê).
- **Aceitação:** o teste do anexo A (§1) passa a dar **0 trocas** sem gesto; o `celeiro_no_jogo_test` continua a
  trocar com uma moeda largada pelo rei.

### D2 · Retomar o autosave repete a alvorada — **reproduzido**

- **Evidência:** quatro canteiros e dois galinheiros de pé; grava-se logo a seguir à alvorada do dia 2 (como o
  autosave). Dez ticks a seguir **sem** retomar: **0** moedas de produção, Colheita com `days_left = 3`. Dez ticks
  a seguir **depois de retomar**: **2** moedas de produção, `days_left = 2`.
- **Causa:** `SimLoop._montar()` põe `_fase = NENHUM` (`sim_loop.gd:197`); `resume()` não a repõe
  (`:84-90`). No primeiro `step()`, `_mudanca_de_fase()` devolve verdadeiro e corre **outra vez**: a passagem
  económica (`:164-165`), e em `NightWatch._virar` (`night_watch.gd:119-150`) `amargueiros.at_dawn`,
  `names.at_dawn`, **`harvest.at_dawn()` (que decrementa `days_left` sem olhar para o dia —
  `harvest_system.gd:79-87`)**, `voice.dawn()` e `rot.retreat()`. O autosave é escrito **depois** do tick da
  alvorada (`_no_amanhecer`, `sim_loop.gd:240-246`), por isso tudo isto já tinha corrido.
- **Consequência:** cada carregamento dá produção de graça, encurta a Colheita, e pode repetir efeitos de alvorada
  que ainda não têm teste de idempotência. O `save_world_test` só compara o estado **antes** de dar um passo.
- **Correção:** em `resume()`, depois do `ClockService.seek`, `_fase = int(ClockService.clock.current_phase())`.
  Complementar: `HarvestSystem.at_dawn(dia)` guarda o último dia contado (como o `CrownSystem` já faz com
  `used_day`), para ser idempotente por construção.
- **Aceitação:** o teste do anexo A (§2) dá a mesma produção e o mesmo `days_left` com e sem retomar; um novo
  caso no `save_world_test` dá **N passos depois de retomar** e compara com N passos sem retomar (determinismo
  do §42 estendido ao que vem depois do save).

### D3 · A certeza da torre vai com o posto, e não com o sítio — **reproduzido**

- **Evidência:** arqueiro teu atribuído à torre (fase NOITE), deslocado **500 px** para fora dela →
  `Posts.accuracy = 1,0` e `Posts.range_px = 280` (em campo aberto seriam 0,34 e 200).
- **Causa:** `Posts.of()` devolve a vaga pelo `job_id` e não verifica onde a tropa está (`posts.gd:17-37`). O
  `TargetPicker` e o `CombatSystem` usam isso diretamente (`target_picker.gd:126-137`, `combat_system.gd:137`).
- **Consequência:** um arqueiro a caminho da torre, a fugir, ou a seguir a cascata da alvorada dispara com a
  certeza da torre. O §07 — *"a torre não dá dano, dá certeza; é como se ensina posicionamento sem uma linha de
  tutorial"* — deixa de ensinar posicionamento.
- **Correção:** o posto só dá o bónus quando `|x − vaga.x| ≤ largura/2` da obra que o publica (a mesma regra de
  presença do `BuildSystem._presentes`). Guardar a largura no `JobSlot.grants()`.
- **Aceitação:** o teste do anexo A (§3) passa a dar 0,34/200 a 500 px e 1,0/280 em cima da torre;
  `noite_do_07_test` e `dez_dias` voltam a correr — **se os números mudarem, é informação para a Q-073, não para
  mexer em `data/`**.

### D4 · Pagar o degrau seguinte de um muro tira-lhe a barreira — **reproduzido**

- **Evidência:** estacaria de pé, trava quem vem de fora. Paga-se a paliçada (11 moedas) → estado `SCAFFOLD` →
  `BuildSystem.barrier()` **deixa de o ver**; a barreira seguinte passa a ser o **núcleo**.
- **Causa:** `absorb()` põe o muro em `SCAFFOLD` (`build_system.gd:96`); `barrier()` só considera obras
  `standing()` (`:175`), e `standing()` é `DONE` ou `DAMAGED` (`build_slot.gd:103`). O `JobBoard.publish()` troca
  os postos de guarda por **um** posto `build` enquanto dura a obra (`job_board.gd:63-65`) — os arqueiros descem.
  E um muro em obra não pode levar dano (`damage()` exige `standing`), por isso as criaturas passam **através**.
- **Consequência:** a melhor jogada do dia (subir o muro) é a pior se feita à tarde; o jogador não tem como saber.
  É um caso de "estado escondido que pune": o contrário da legibilidade que o §24 pede.
- **Correção (proposta, pede decisão):** distinguir **obra nova** de **degrau sobre obra de pé**. No degrau, o
  nível anterior continua a travar, a ter vida e postos até o novo acabar (é o que o jogador vê: o muro velho
  com andaime). Custo: um campo (`upgrading`) ou usar `level > 0` em `SCAFFOLD/BUILDING` como "de pé com obra".
- **Aceitação:** o teste do anexo A (§4) passa a encontrar o muro como barreira durante a obra; um teste novo
  mostra que os postos de guarda continuam publicados.

### D5 · A moeda não tem destinatário — **reproduzido**

- **Evidência:** rei 8 px à esquerda do primeiro vagabundo (−248 do núcleo), larga **uma** moeda → a **Casa de
  Treino fica com `paid = 1`**; o vagabundo **não** é recrutado.
- **Causa:** o passo 5 serve a mesma moeda pousada a **quatro** leitores pela ordem do tick
  (`sim_loop.gd:156-159`): obra → treino → celeiro → quem a foi buscar → quem a pisa. Nenhum sabe quem a largou nem
  para quê. O greybox põe o vagabundo do minuto 0:20 em −240 (`greybox.gd:71`) e a Casa de Treino em −300 ± 60
  (`:43`): **a borda de um é a borda do outro**.
- **Consequência:** o gesto que ensina o jogo pode falhar logo ao primeiro minuto. O `PriceTag` mostra o preço do
  que está debaixo do rei, mas a moeda não vai necessariamente para lá — a promessa visual e a regra divergem.
- **Correção imediata (nível):** afastar o vagabundo inicial do raio da Casa de Treino (ou o inverso). É autoria
  do segmento (§21), não balanceamento.
- **Correção de fundo (P-A):** resolver o **destino no momento do gesto** com a mesma função que o painel e o
  `PriceTag` usam, e gravá-lo na moeda (`target_id`, `origin`). O sistema de destino é o único que a pode
  absorver; moedas sem destino (produção, caça, saque) só podem ser **apanhadas**, nunca "pagar" nada.
- **Aceitação:** o teste do anexo A (§5) recruta o vagabundo; um teste de propriedade: "para qualquer x onde o
  painel diz *recrutar*, largar recruta; onde diz *construir X*, paga X".

### D6 · O rei morre e a partida continua sem comando — **reproduzido**

- **Evidência:** núcleo isolado (vida alta), rei com vida 0 → um dia depois: **rei fora de campo, núcleo de pé,
  `SimLoop.running() = true`, largar moeda não faz nada**. A vistoria mostra o mesmo em partida natural (rei
  morto na noite 2, núcleo cai no dia 3).
- **Causa:** o combate trata o monarca como qualquer tropa (`combat_system.gd:223-244`); na alvorada o corpo sai
  das colunas. `game.gd` só trata a queda do **núcleo** (`:144-150`). §15/§16 (herdeiro, interregno, derrota
  quando não há sucessor) não existem.
- **Consequência:** *soft-lock*: o jogador vê o reino cair sem poder agir, ou fica preso num mundo sem avatar.
- **Correção mínima (enquanto não há sucessão):** morte do rei = o mesmo ecrã de "A coroa caiu" que o núcleo.
  **Correção de design (proposta):** a do Kingdom — o saco é a vida (o rei perde moedas ao ser atingido e a coroa
  quando o saco está vazio) — ou a do §16 com herdeiro ao amanhecer. Ambas precisam de decisão (anexo C).
- **Aceitação:** um teste de jogo em que o rei morre acaba em ecrã de derrota ou em sucessão, nunca em mundo sem
  avatar.

### D7 · A economia do CI não é a do jogo — **reproduzido** (ver §3.3)

- **Correção:** decidir **qual é a verdade** (Q-033). Recomendação: a verdade é o jogo. O teste da asfixia passa a
  correr o `SimLoop` com o perfil `balanced` montado em obras reais (o greybox já tem as sete fontes do perfil) e
  com manutenção/ganância/custo da noite **aplicados na partida** (P-D). O modelo analítico fica como previsão, com
  tolerância declarada, e diverge ruidosamente quando os dois se afastam.
- **Aceitação:** um teste compara `daily_income` do modelo com a produção medida do `SimLoop` por dia, com margem
  escrita; o dia da asfixia é medido no jogo.

### D8 · Com a voz da Podridão, nenhuma defesa aguenta dez dias — **medido**

`scenes/tests/dez_dias.tscn` hoje (o instrumento recusa todas as ofertas, como um jogador que não quer pagar):

| esq | dir | torre | alta | arq | aguentou | mortes | muros |
|---:|---:|:---:|:---:|---:|:---:|---:|---:|
| 1 | 1 | não | não | 6 | caiu 2 | 0 | 2 |
| 2 | 2 | sim | não | 8 | caiu 8 | 9 | 2 |
| 3 | 3 | sim | sim | 10 | caiu 8 | 6 | 2 |
| 4 | 4 | sim | sim | 12 | caiu 8 | 8 | 2 |
| 5 | 4 | não | não | 12 | caiu 7 | 13 | 3 |
| 5 | 4 | sim | não | 12 | caiu 8 | 13 | 2 |
| 5 | 4 | não | sim | 12 | caiu 8 | 8 | 2 |
| 5 | 4 | sim | sim | 6 | caiu 10 | 3 | 3 |
| 5 | 4 | sim | sim | 12 | **caiu 10** | 8 | 3 |

A própria ferramenta imprime *"O §66 quer as duas: uma linha a aguentar e uma a cair"* — e hoje nenhuma aguenta.
O `dez_dias_test` verde desliga a voz (`campanha.voice = false`); o caso com a voz está saltado (Q-101, "cai ao
dia 9"). Leitura de design: **recusar a Podridão é uma sentença**, e uma escolha em que uma das opções perde
sempre não é uma escolha — é um imposto. A noite 10 também é um degrau: o núcleo está a 100% até ao dia 9 e cai
no 10, que é o dia do **Cavador** (primeira ameaça que entra por baixo) — ver §5.5.

- **Correção:** não mexer em `data/` para o teste passar (regra do `AGENTS.md`). Decidir a Q-101 com uma das três
  vias: (a) teto de recusas mais baixo; (b) recusar custa outra coisa que não massa (ex.: a candeia fica mais perto,
  mais cedo — pressão legível); (c) o instrumento ganha uma política de ofertas e o §66 passa a valer "para quem
  aceita alguma coisa". Recomendação: (b) ou (c), e medir as duas.

### Defeitos menores (no código)

| # | O quê | Onde | Correção |
|---|---|---|---|
| D9 | O `TrainingSystem._apanhar` pode apanhar mais do que falta (moedas de valor > 1) e o excesso perde-se | `training_system.gd:180-193` | Parar antes de passar `falta`, ou devolver o troco ao chão |
| D10 | `INTRO_SECONDS = 70` é fixo e não escala com o *slider* de duração do dia (240–540 s) | `hunt_watch.gd:6` | Exprimir como fração do dia ou ancorar à fase |
| D11 | Save só na alvorada: fechar o jogo perde até um dia (6 min) | `sim_loop.gd:240-246` | Gravar ao pausar/sair (P-L) |
| D12 | `registry_test.gd:44` formata um *array* vazio | teste | `"%s" % [nulos]` |
| D13 | Quem não tem posto segue o rei para todo o lado, incluindo para fora do muro ao crepúsculo | `recruit_system.gd:93-104` | P-C |

### Hipótese descartada

**"O saque das criaturas mortas junto a um muro paga-o sozinho e desliga a barreira a meio da noite."** Medido em
6 sementes × 2 noites, com cinco soldados teus, quatro muros e as torres: **63 moedas de morte, nenhuma dentro do
raio de um muro** (32 px), **0 degraus e 0 reparações iniciados sem gesto**. As criaturas morrem na fila (30–120 px),
fora do raio. Não perseguir — mas D5/P-A elimina a classe de problema de qualquer forma.

---

## 5. Problemas de design (não são bugs; são decisões que não funcionam)

### 5.1 Impulsos: um é sempre prejuízo

Conta com o `CrownSystem.yield_mult` (`crown_system.gd:77-88`) e o greybox com as sete fontes de pé (17/dia, das
quais 8 dos canteiros):

| Impulso | Custo | Ganho hoje | Custo amanhã | Saldo |
|---|---:|---:|---:|---:|
| **Colheita Forçada** (×1,8 hoje, canteiros parados amanhã) | 12 | +0,8 × 17 = +13,6 | −8 | **−6,4** (só canteiros: −13,6) |
| Chamada às Armas (vagabundos sem dono → lanceiros; produção 0 hoje) | 12 | 4 lanceiros ≈ 16 em preço | −17 hoje | −13, mas é botão de emergência: faz sentido |
| Vigília (ninguém foge esta noite; vida ×0,7 amanhã) | 12 | moral | vida | situacional, bom |

A Colheita Forçada **nunca compensa** — sem o crescimento diário que o modelo tem (D7), menos ainda. O §15 diz
*"nunca só vantagem"*; aqui é *"só desvantagem"*. Direção: o benefício tem de poder ganhar em algum estado do jogo
(ex.: antes de uma noite que se sabe difícil, ou quando há celeiro a +50%). Medir com um teste que percorra os
estados (P-M).

### 5.2 Circuito 2: capacidade é dominada por moeda

Com quatro canteiros: **modo moeda = 12 moedas/dia** (8 × 1,5). **Modo capacidade = 0 moedas** e +10% de vida
máxima às tropas (arqueiro 14 → 15). Doze arqueiros ganham 12 pontos de vida no total (o arredondamento dá +1 a cada um); as 8–12 moedas/dia que
se perdem compram 3–4 arqueiros novos por dia (≈ 42–56 de vida, e mais dano). A cozinha e o cozinheiro custam 20.
Só há decisão se a capacidade for **qualitativamente** diferente (ex.: cura ao amanhecer, ou valer por uma noite
concreta), não uma percentagem pequena permanente. Os outros quatro ofícios de conversão (`troop_speed`,
`combat_dish`, `wall_and_tower_cost −25%`, `weapon_level +1`) são mais interessantes — o `wall_and_tower_cost`
cria uma decisão real com a escada dos muros — mas nenhum está no mundo.

### 5.3 A produção não pede ninguém

`EconomySystem.on_phase` soma produção a todas as obras de pé com `yield_per_day > 0`, sem olhar para o posto
(`economy_system.gd:137-158`). O canteiro publica um posto `farm` (1 vaga) que **não muda nada**. Consequências:
o vagabundo recrutado não tem um destino que valha; a decisão "quantos trabalhadores" não existe; e o *payback* de
2 dias torna a produção uma formalidade — constrói-se tudo assim que se pode. No Kingdom, o camponês com foice é
quem faz a quinta render (e o que a Podridão/Greed leva à noite). Proposta P-B.

### 5.4 Economia sem sorvedouros → sem tensão depois do dia 4

Com fontes lineares e sorvedouros fixos (muros com teto), a *value chain* fica com **"dead-end resources"** —
*"when there's overabundance, people stop caring because there's no pull on earlier nodes"* (Lost Garden, anexo D).
O dossiê já tem os sorvedouros certos (manutenção por escalões a partir da 9.ª tropa, ganância, custo da noite,
dívida); estão todos no modelo e nenhum na partida. Ligar **um** — a manutenção paga ao amanhecer no núcleo, com
o gesto de sempre — dá a primeira decisão de "quanto exército consigo sustentar" (P-D).

### 5.5 A noite: longa, pouco legível, e o subsolo chega sem aviso

- **Aviso.** A candeia entra no ecrã antes da mancha (bom — é telegrafia). Mas o **lado** é sorteado no próprio
  crepúsculo (`night_watch.gd:136`) e a **composição** não se mostra. O jogador prepara às cegas. Thronefall mostra
  durante o dia quantos e quais inimigos virão por cada entrada; Into the Breach constrói o jogo sobre ameaças
  telegrafadas; Dome Keeper usa o **som** da onda para o jogador decidir quando voltar (anexo D).
- **Agência.** O rei tem 3 de dano. De noite os verbos são marcar alvo e largar moeda. Não há nada equivalente ao
  "largar moedas fora do muro como isca" do Kingdom, nem um uso noturno da candeia/oferta que seja escolha e não
  imposto.
- **Ritmo.** A massa cresce 18/dia sem respiração. O Kingdom dá **um dia sem ataque** depois de cada Lua de Sangue;
  o *AI Director* de Left 4 Dead alterna *build-up → peak → fade → relax* (anexo D). Sem relaxe, cada noite é igual à
  anterior um pouco pior, e o dia 10 é um degrau (o Cavador) em vez de um clímax preparado.
- **Subsolo.** O Cavador (dia 10) é a primeira criatura que usa a faixa de baixo; não há defesa subterrânea, nem
  posto, nem obra de cavidade. É a faixa que distingue Empire do Kingdom e hoje só existe como corredor.

### 5.6 A caça é um temporizador, não uma atividade

Coelhos são **pontos fixos** no chão (`HuntView` só lhes dá respiração); `move_speed`, `flees`, veado e javali não
são lidos; o abate ignora a precisão do arqueiro (`hunting_system.gd:199-210`). O arqueiro com posto (muro/torre)
não procura presas (`plan()` salta quem tem `job_id`) mas ainda caça o que lhe passar ao alcance — medido: com os
quatro muros de pé, três arqueiros caçam 4 em vez de 5 no dia 1, porque os muros do greybox calham perto das
clareiras. Resultado: a caça é previsível e não pede nada ao jogador. No Kingdom os arqueiros **saem para a
floresta de dia** e **voltam para trás das muralhas à noite** — a caça é o que põe gente em risco fora do muro.

### 5.7 Decisões boas que já existem (preservar)

- **Muralha A/B** (§10): paliçada A 48 vida/2 postos contra B 95/1; pedra 105/4 contra 210/2; ferro 225/6 contra
  450/2. É uma escolha real e irreversível — precisa só de se **ver** (silhueta e ocupação), como o ASTRA já pedia.
- **Lenho Amargo**: o ferro e o Bastião pedem madeira que só existe se alguém teu morreu e virou árvore. É uma
  ligação temática forte entre perda e progresso. Precisa de ser ensinada.
- **Caça entregue pela mão** (Q-111): o arqueiro traz a caça ao rei — é diegético e dá motivo para se cruzarem.

---

## 6. Pesquisa: o que outros jogos resolveram, e o que serve ao Empire

| Fonte | O que faz | O que o Empire tira disso | Liga a |
|---|---|---|---|
| **Kingdom** (80.lv, entrevista aos criadores) | *"Only one button to pay"*; aldeões com regras simples e previsíveis — *"if they do something bad, it's usually in response to an action from the player"* | A regra de ouro para D1 e D5: **nenhuma consequência sem gesto do jogador** | D1, D5, P-A |
| **Kingdom Two Crowns** (Wikipedia; guias da comunidade) | Recrutados ficam no acampamento até haver **ferramenta**; a ferramenta comprada numa loja dá o ofício ao aldeão mais perto; arqueiros caçam de dia e voltam ao muro à noite; *decay*: ao perder a coroa, o herdeiro herda o reino parcialmente destruído | Papéis físicos e visíveis; quem não tem papel **espera no centro**, não segue o rei; derrota que não apaga tudo | P-B, P-C, P-K, D6 |
| **Kingdom Two Crowns** (Game Developer, van den Berg/van Dyke) | *Decay design*: *"players keep a majority of what they built after inevitably losing their crown(s)"* | Fecha a Q-088 com um modelo testado no género | P-K |
| **Kingdom** (guias) | Lua de Sangue seguida de um dia e uma noite **sem ataque**; o Greed rouba moedas e depois a coroa | Ritmo com respiração; o saco como vida do rei | P-H, D6 |
| **Thronefall** (Game Developer; I.N.T.) | Sítios de construção **pré-definidos**; só fica a decisão de *quando* construir; ícones durante o dia com quantos inimigos vêm por cada entrada; *"address root problems, not symptoms"* | Empire já tem os sítios autorados (§21). Falta **o aviso da noite** e variantes de upgrade em vez de mais edifícios | P-F, P-N |
| **Dome Keeper** (Game Developer) | Minerar entre ondas; *"the battle giving a reason to go mining, but also being an immediate show floor for the fruits of your mining"*; o som da onda diz quando voltar | Modelo direto para a **faixa subterrânea**: expedição de dia, regresso antes do crepúsculo, som como relógio | P-I, P-O |
| **Against the Storm** (Game Developer) | A cidade como avatar; sessões curtas; a Rainha impaciente como relógio com ficção; *"rebuilding — bringing something forgotten and ruined back"* | Capítulos como "runs" curtas com modificadores; reconstruir ruínas como progressão | P-K |
| **Frostpunk** (PC Gamer; wiki) | Leis mutuamente exclusivas com custo moral; ameaça futura anunciada com antecedência | As ofertas da candeia como "livro de leis" noturno: escolhas com custo claro, não impostos | D8, P-F |
| **Into the Breach** (GDC 2019) | Ameaças telegrafadas transformam a luta em puzzle; telegrafar **acelerou** as batalhas | Mostrar o que a noite traz antes dela | P-F |
| **Left 4 Dead — AI Director** (Booth, 2009) | Estados *build-up → sustain peak → peak fade → relax* (30–45 s) | Uma curva de massa com respiração, não uma rampa | P-H |
| **Lost Garden — Value chains** (Cook, 2021) | Fontes/transformações/sorvedouros e âncoras; sintomas: *"X seems pointless"* | Diagnóstico de §5.3–5.4; sorvedouros do §06 na partida | P-D |
| **Machinations** (Dormans & Adams) | Simular a economia com *feedback loops* antes de afinar | Um instrumento "economia jogada" no CI | P-E |
| **Beyond the HUD** (Fagerholt & Lorentzon, 2009) | Interfaces diegéticas, espaciais, meta e não-diegéticas | Vocabulário para mover texto do painel para o mundo (§24) | P-F, P-N |
| **Game Accessibility Guidelines** | Básico: dificuldade ajustável, não usar só cor, legendas; *save anytime* | Gravar ao sair; modos de dificuldade como dados | P-L |
| **Steam Deck** (Steamworks) | Texto ≥ 9 px (recomendado 12 px) a 1280×800 | Validar o painel de contexto e os preços | §9 |
| **RITE** (Medlock et al., Microsoft, Age of Empires II) | Testar com poucos jogadores e corrigir entre sessões | Playtest barato e frequente da abertura | §9 |
| **Juice it or lose it** (Jonasson & Purho, 2012) | Respostas em cascata a cada gesto | A moeda já tem salto e sombra; falta o **som** e a resposta ao pagar/recrutar | P-O |

---

## 7. Propostas

Todas precisam de decisão antes de código (pergunta ou ADR — rascunhos no anexo C). Ordenadas por **valor para
quem joga ÷ custo**, e ligadas ao que já existe em dados.

### P-A · A moeda sabe para onde vai *(resolve D1, D5; prepara D3)*
- **Mecânica:** ao largar, o `Verbs` resolve o **destino** com a mesma função que alimenta o painel de contexto e o
  `PriceTag` (uma só fonte de verdade); a moeda leva `target_id` e `origin` (`player`, `production`, `hunt`,
  `death`). Só o sistema de destino a absorve; moedas sem destino só se apanham.
- **Código:** `CoinSystem` ganha duas colunas (save: `save_version` novo, §62); os `absorb()` filtram por destino;
  `GameplayGuide.context` e `PriceTag` passam a chamar a função partilhada.
- **Teste:** propriedade "o que o painel promete é o que a moeda faz" em todas as posições do greybox.

### P-B · O posto faz a obra render *(resolve §5.3)*
- **Mecânica:** um edifício de produção com posto rende a 100% com o trabalhador presente e a uma fração sem ele
  (a fração é um número novo → CSV `_proposed`). Galinheiro (`job_slots 0`) continua a render sozinho — é a
  diferença entre as fontes.
- **Efeito:** recrutar trabalhadores passa a ser uma decisão; o *payback* sobe; a Podridão que mata o
  trabalhador fora do muro custa produção (tensão espacial).

### P-C · Quem não tem papel espera no núcleo *(resolve D13; Kingdom)*
- **Mecânica:** recrutados sem posto vão para o núcleo (ou para a fogueira da ruína) e ficam lá; o rei **chama**
  com o Verbo 2 junto a eles (ou seguem-no só de dia). À noite ficam atrás do muro mais interior.
- **Efeito:** o rei deixa de arrastar uma fila para a morte; o núcleo lê-se como "casa".

### P-D · Um sorvedouro real: a manutenção ao amanhecer *(resolve §5.4, parte de D7)*
- **Mecânica (já no §06):** a partir da 9.ª tropa, `upkeep` por escalões; paga-se na alvorada **com moedas do saco
  do rei largadas no núcleo** (gesto de sempre). Não pagar → a tropa mais barata sem posto vai-se embora (o §07
  já tem fuga e moral para isto).
- **Efeito:** "quantos soldados consigo sustentar" passa a ser pergunta; o teste da asfixia passa a medir o jogo.

### P-E · O instrumento "economia jogada" *(fecha D7/D8 como medição)*
- Um piloto determinista (como o `Autopilot` da vistoria, mas **a jogar bem**): recruta, caça, constrói fontes,
  sobe muros pela ordem de uma política escrita, aceita/recusa ofertas por regra. Imprime moedas por origem, gasto
  por destino, e o dia em que caiu. É a versão Machinations do repositório, com o `SimLoop` real.
- **Aceitação:** o §66 passa a ser medido com este piloto e a voz ligada.

### P-F · A noite anuncia-se *(resolve §5.5 — aviso)*
- **Mecânica:** o lado da mancha sorteia-se **à tarde** (mesmo fluxo `rot`, só mais cedo) e mostra-se no mundo:
  a candeia acende-se ao longe desse lado; a composição lê-se pelo **som** e por silhuetas na borda (sem números).
- **Efeito:** a tarde passa a ser a fase de preparação — onde pôr os arqueiros, que muro subir (e não subir, D4).

### P-G · A noite pede gestos
- Opções já sugeridas pelos dados: **moeda como isca** fora do muro (as criaturas `rot` desviam-se para moedas
  pousadas, como o Greed); o **barril de fogo** (dados prontos: `aoe_damage 20`, `rot_slow 0,25`) como gasto
  noturno de uma só vez; o raio do rei na moral (já existe) tornado visível. Escolher **um**.

### P-H · Ritmo com respiração *(resolve o degrau do dia 10)*
- **Mecânica:** a cada N noites, uma noite de pico (massa × k) seguida de um dia sem ataque — em dados
  (`rot.csv`), com o anúncio de P-F. Os marcos de criatura nova (alado 4, bruto 7, cavador 10) caem nas noites de
  pico e **são anunciados na tarde anterior**.

### P-I · O subsolo como expedição *(a identidade vertical do Empire; Dome Keeper)*
- **Mecânica:** as `cavity_slots` do segmento viram sítios de obra subterrâneos: **mina** (dados prontos:
  `ore_pit`, `attracts_burrowers` — a própria tag é o custo), **escoras/túnel selado** (a oferta *O que enterraste*
  já pede `sealed_passage`), e o **Lenho** do Amargueiro de raiz. De dia desce-se a buscar; ao crepúsculo o som do
  Cavador diz para subir.
- **Efeito:** o dia ganha um segundo sítio para onde ir; o Cavador do dia 10 passa a ter resposta.

### P-J · O Alado ataca o que o dossiê já diz *(resolve Q-077)*
- **Mecânica:** o galinheiro tem `stealable_at_night` — o Alado **rouba galinhas** (produção do dia seguinte) em
  vez de pousar no castelo. A torre alta passa a proteger uma coisa concreta.

### P-K · Uma região acaba *(resolve "não há objetivo depois do dia 3")*
- **Mecânica mínima:** a bifurcação a +1800 px (já no greybox) abre, a partir do dia N, **a travessia para o
  capítulo seguinte** (já sorteado e guardado). Partir leva o rei e quem ele escolher; o que fica decai a 40%
  (§16) e pode ser retomado. Perder a coroa = herdeiro na região anterior com *decay*, não recomeço do zero.
- **Efeito:** cada região é uma "run" curta (Against the Storm) dentro de uma campanha que acumula (Kingdom Two
  Crowns). O `epilogue()` ganha quem o chame.

### P-L · Gravar quando o jogador sai *(D11; *save anytime*)*
- Gravar ao abrir a pausa e ao fechar a janela, com o mesmo formato; o autosave da alvorada fica como ponto de
  retorno. Pré-requisito: **D2 corrigido** (senão cada gravação fora da alvorada multiplica os efeitos de fase).

### P-M · Tornar as decisões não dominadas *(§5.1, §5.2)*
- Não afinar à mão: escrever primeiro o **teste de dominância** (para cada impulso/modo, existe um estado do jogo
  em que é a melhor opção?) e deixá-lo falhar. Depois a afinação vai para os CSV com `_proposed`.

### P-N · Upgrades com variante, não mais edifícios *(Thronefall)*
- A escolha A/B da muralha é o padrão certo. Estender a **torre** (alcance vs. cadência) e ao **canteiro** (mais
  moeda vs. imune ao rasto) antes de ligar edifícios novos — usa a arte e os sítios que já existem.

### P-O · Som mínimo com função *(Dome Keeper; Juice)*
- Seis sons que carregam informação, não ambiente: moeda a cair/pagar, recrutar, obra concluída, **crepúsculo
  (lado)**, brecha, alvorada. O `Captions` (legendas do §26) já existe e só precisa de eventos.

---

## 8. Roteiro

Cada etapa acaba com **evidência**, não com contagem de ficheiros. Seguir o ciclo do `AGENTS.md`: teste primeiro,
mínimo que o faz passar, `./run_tests.sh` e `make vistoria`.

### Etapa 1 — Integridade da simulação (pequena, alta confiança)

| Item | Teste que falha primeiro | Pronto quando |
|---|---|---|
| D2 retomar | "N passos depois de retomar = N passos sem retomar" (produção, Colheita, Amargueiros) | Verde, e o `save_world_test` ganha o caso |
| D1 celeiro | anexo A §1 sem gesto → 0 trocas | Verde; `celeiro_no_jogo_test` intacto |
| D5 nível 0:20 | anexo A §5 → vagabundo recrutado | Verde; `abertura_natural_test` intacto |
| D3 torre | anexo A §3 → 0,34/200 a 500 px | Verde; `dez_dias` re-medido e a diferença escrita na Q-073 |
| D4 muro em obra | anexo A §4 → o muro trava durante a obra; postos mantêm-se | Verde (depois de decidida a pergunta do anexo C) |
| D6 rei morto | Morte do rei → ecrã de derrota | Verde; vistoria já não mostra `rei = -1` com núcleo de pé |
| D9, D10, D12 | Casos unitários | Verde |

### Etapa 2 — A economia verdadeira

- P-E (piloto que joga bem) primeiro, **só a medir**. Publicar a tabela "moedas por origem × gasto por destino ×
  dia em que caiu" para 3 políticas.
- Decidir D7 (qual é a verdade) e ligar P-D (manutenção). Reescrever o teste da asfixia sobre o `SimLoop`.
- P-B (produção pede trabalhador) e P-M (teste de dominância) — afinar nos CSV.
- **Pronto quando:** o §66 é medido com a voz ligada e uma política declarada, e tem uma linha que aguenta e uma
  que cai; nenhuma opção da roda nem do celeiro é dominada no teste.

### Etapa 3 — A noite legível e com gestos

- P-F (aviso à tarde), P-H (ritmo), P-G (um gesto noturno), P-O (seis sons).
- **Pronto quando:** num playtest RITE (§9) o jogador diz, antes do crepúsculo, **de que lado** vem a noite e **o
  que** vai subir; e diz, depois, **porque** ganhou ou perdeu.

### Etapa 4 — As faixas

- P-I (subsolo como expedição) e P-J (Alado rouba galinhas).
- **Pronto quando:** o jogador desce por vontade própria antes do dia 5 e volta antes do crepúsculo; a torre alta é
  construída por causa das galinhas, não por causa de um número.

### Etapa 5 — Uma campanha mínima

- P-K (fim de região, travessia, *decay*), sucessão (D6 de design), e o `epilogue()` ligado.
- **Pronto quando:** uma partida de ~60–90 min tem começo, travessia e fim, e perder não apaga tudo.

**O que não fazer ainda:** montarias, comércio/diplomacia, mais povos, mais edifícios. Cada sistema novo exige
gesto, dados, save, teste e arte — e nenhum deles resolve "o que faço no dia 5?".

---

## 9. Como medir se melhorou

### 9.1 Playtest (RITE)

Cinco jogadores por ronda, **sem explicar nada**, abertura de 20 min; corrigir entre sessões o que três ou mais
tropeçarem (o método que a Microsoft usou no tutorial de Age of Empires II — anexo D). Perguntas depois de jogar:

1. De onde veio o dinheiro? (resposta certa: caça, produção, saque)
2. Porque é que a obra X parou/continuou?
3. Antes da noite: de que lado vinha e o que preparaste?
4. Porque é que perdeste/ganhaste a noite?
5. O que querias fazer amanhã?

Registar deslocações sem objetivo, esperas por tarefa, gestos que falharam (D5), e o momento em que o jogador
**deixa de ter uma pergunta**.

### 9.2 Métricas (já previstas no §32, "medir sem espiar")

| Métrica | Meta do dossiê | Hoje |
|---|---|---|
| Primeira moeda largada | < 40 s | cumprida no teste de gestos |
| Primeira muralha | < 4 min | possível; não medida com humano |
| Descoberta do subsolo | < 14 min | não medida |
| Noite 1 ganha | "de certeza" (§25) | **não** sem muros (Q-068) |
| Dias vividos por um jogador novo | — | medir; o piloto vive 3 |
| Moedas por origem/destino por dia | — | medir com P-E |

### 9.3 Hardware e legibilidade

Texto ≥ 9 px (idealmente 12 px) a 1280×800 para o Steam Deck; preços e painel de contexto em PT e EN; noite com
os três modos de daltonismo. O ASTRA §20.2 tem a lista de capturas mínimas — continua válida.

---

## 10. Riscos

| Risco | Mitigação |
|---|---|
| Corrigir D3 muda os números de `noite_do_07_test`/`dez_dias` | É informação: escrever na Q-073/Q-101, não mexer em `data/` |
| P-A muda o formato do save | `save_version` novo e migração que degrada (§62) |
| P-B/P-D tornam a abertura mais dura | Medir com P-E **antes** de afinar; a Q-068 já diz que a noite 1 é dura |
| Mais sistemas antes de fechar D1–D6 | Os defeitos contaminam qualquer medição de balanceamento feita por cima |
| O limite de 250 linhas no `SimLoop` (246 hoje) | Extrair o passo 5 (as absorções) para um coordenador pequeno, como o `FieldWork` fez |

---

## Anexo A — As reproduções

Correm com o gdUnit4 do repositório, numa pasta **fora de `tests/`** (não entram na contagem do CI):

```bash
mkdir -p tests_auditoria && # colar o ficheiro abaixo em tests_auditoria/auditoria_test.gd
godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a tests_auditoria -c \
  | grep AUDIT
```

Saída de hoje (`7b1f7c2`):

```text
AUDIT celeiro: trocas de modo sem gesto = 1 moedas comidas pela conversao = 1 modo final = 1
AUDIT retomar: producao nos 10 ticks a seguir ao save = 0 | depois de retomar = 2 | colheita days_left sem retomar = 3 depois de retomar = 2
AUDIT torre: a 500 px da torre precisao = 1.0 alcance = 280.0 (aberto 0.34 / 200)
AUDIT muro: antes trava = true | estado depois de pagar = 1 | trava = false | barreira seguinte = core
AUDIT 0:20: vagabundo em -240.0 casa de treino em -300.0 ± 60.0 | casa paga = 1 | vagabundo recrutado = false
AUDIT economia ( 7 fontes ):
    dia 1: modelo 21.2 | real 17 | built_income 17.0
    dia 2: modelo 23.7 | real 17 | built_income 19.0
    dia 3: modelo 26.6 | real 17 | built_income 21.3
    dia 4: modelo 29.8 | real 17 | built_income 23.9
    dia 5: modelo 33.4 | real 17 | built_income 26.7
   upkeep(14) = 3.0 night_cost(1..5) = 6.1 13.513540816
AUDIT caca dia 1, 3 arqueiros teus [cacado, com posto]: sem muros = [5, 0] | 4 muros nivel 1 = [4, 3]
AUDIT rei morto: rei em campo = false | nucleo de pe = true | a partida corre = true | largar criou moeda = false | dia = 2
AUDIT saque: moedas de morte = 63 | muros com moeda paga sem gesto = {  } | degraus iniciados sozinhos = 0 | reparacoes iniciadas sozinhas = 0
```

(Estado `1` = `SCAFFOLD`; modo `1` = `CAPACITY`.) Os testes **passam** porque afirmam o comportamento atual: ao
corrigir, inverte-se a asserção e move-se o caso para `tests/` com o nome do sistema.

```gdscript
extends GdUnitTestSuite

const STEP := 1.0 / 30.0
const SEMENTE := 20260926
const SLOT := 2

var _prod := 0
var _gasto_conv := 0
var _caca := 0
var _prod_x: Array[float] = []


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SaveService.delete_slot(SLOT)
	_prod = 0
	_gasto_conv = 0
	_caca = 0
	_prod_x = []
	EventBus.coin_dropped.connect(_caiu)
	EventBus.coin_spent.connect(_gastou)


func after_test() -> void:
	EventBus.coin_dropped.disconnect(_caiu)
	EventBus.coin_spent.disconnect(_gastou)
	SimLoop.stop()
	SimLoop.autosave_enabled = true
	SaveService.delete_slot(SLOT)


func _caiu(x: float, _f: int, quanto: int, origem: StringName) -> void:
	if origem == &"production":
		_prod += quanto
		_prod_x.append(x)
	elif origem == &"hunt":
		_caca += quanto


func _gastou(quanto: int, porque: StringName) -> void:
	if porque == &"conversion":
		_gasto_conv += quanto


func _novo() -> void:
	SimLoop.start(SEMENTE)
	Greybox.build()


func _obras(kind: StringName) -> Array[BuildSlot]:
	var saida: Array[BuildSlot] = []
	for o in SimLoop.builds.slots:
		if o.kind == kind:
			saida.append(o)
	return saida


func _de_pe(o: BuildSlot, nivel: int = 1) -> void:
	o.level = nivel
	o.state = BuildSlot.State.DONE
	o.health = o.max_health()


func _rei() -> int:
	return SimLoop.units.index_of(SimLoop.king_id)


func _dono() -> int:
	return SimLoop.units.owners[_rei()]


func _parar_rei_no_nucleo() -> void:
	SimLoop.units.set_target_x(SimLoop.king_id, SimLoop.core_x)


# 1 · O celeiro muda de modo e come a propria venda sem nenhum gesto do jogador.
func test_celeiro_troca_de_modo_sem_gesto() -> void:
	_novo()
	var celeiro := _obras(&"granary")[0]
	_de_pe(celeiro)
	for c in _obras(&"farm"):
		_de_pe(c)
	var cozinheiro := SimLoop.units.spawn(
		SimLoop.state, Registry.entry(&"units", &"cook"), _dono(), SimLoop.core_x
	)
	assert_int(cozinheiro).is_greater(0)
	var trocas := 0
	var modo := SimLoop.field.conversion.mode_of(celeiro)
	for _t in int(ClockService.clock.day_seconds() * 1.5 / STEP):
		_parar_rei_no_nucleo()
		SimLoop.step(STEP)
		var agora := SimLoop.field.conversion.mode_of(celeiro)
		if agora != modo:
			trocas += 1
			modo = agora
	prints("AUDIT celeiro: trocas de modo sem gesto =", trocas,
		"moedas comidas pela conversao =", _gasto_conv, "modo final =", modo)
	assert_int(trocas).is_greater(0)


# 2 · Retomar o autosave da alvorada repete a passagem de fase.
func test_retomar_repete_a_alvorada() -> void:
	_novo()
	for c in _obras(&"farm"):
		_de_pe(c)
	for c in _obras(&"henhouse"):
		_de_pe(c)
	while ClockService.clock.day < 2:
		_parar_rei_no_nucleo()
		SimLoop.step(STEP)
	var colheita := SimLoop.night.harvest
	colheita.people = "fenda"
	colheita.days_left = 3
	assert_bool(SaveService.save(SLOT, SimLoop.state, RngService.snapshot(), SimLoop.world())).is_true()
	_prod = 0
	for _t in 10:
		SimLoop.step(STEP)
	var sem_retomar := _prod
	var dias_sem := colheita.days_left
	SimLoop.stop()
	SimLoop.resume(SaveService.restore(SLOT), SaveService.restore_rng(SLOT))
	Greybox.region()
	SimLoop.load_world(SaveService.restore_world(SLOT))
	_prod = 0
	for _t in 10:
		SimLoop.step(STEP)
	prints("AUDIT retomar: producao nos 10 ticks a seguir ao save =", sem_retomar,
		"| depois de retomar =", _prod, "| colheita days_left sem retomar =", dias_sem,
		"depois de retomar =", SimLoop.night.harvest.days_left)
	assert_int(_prod).is_greater(sem_retomar)


# 3 · A certeza da torre vai com o posto, e nao com o sitio.
func test_torre_da_certeza_longe_dela() -> void:
	_novo()
	var torre := _obras(&"archer_tower")[0]
	_de_pe(torre)
	var i := SimLoop.units.index_of(7)
	SimLoop.units.owners[i] = _dono()
	SimLoop.jobs.refresh(SimLoop.builds, SimLoop.units, GameClock.Phase.NIGHT)
	var vaga := SimLoop.jobs.slot_of(SimLoop.units.job_ids[i])
	assert_object(vaga).is_not_null()
	SimLoop.units.xs[i] = torre.x + 500.0
	var dados := Registry.entry(&"units", &"archer") as UnitData
	var prec := Posts.accuracy(SimLoop.jobs, SimLoop.units, i, dados)
	var alc := Posts.range_px(SimLoop.jobs, SimLoop.units, i, dados)
	prints("AUDIT torre: a 500 px da torre precisao =", prec, "alcance =", alc, "(aberto 0.34 / 200)")
	assert_float(prec).is_equal(1.0)


# 4 · Pagar o degrau seguinte de um muro tira-lhe a barreira ate acabar.
func test_muro_em_obra_deixa_de_travar() -> void:
	_novo()
	var muro: BuildSlot = null
	for o in SimLoop.builds.slots:
		if o.two_paths() and o.x > SimLoop.core_x:
			muro = o
			break
	_de_pe(muro)
	var fora := muro.x + 300.0
	var antes := SimLoop.builds.barrier(fora, SimLoop.core_x, Band.Kind.SURFACE)
	for _k in muro.next_cost():
		SimLoop.drop_coin(muro.x, muro.band, 1, &"player")
	for _t in 60:
		SimLoop.step(STEP)
	var depois := SimLoop.builds.barrier(fora, SimLoop.core_x, Band.Kind.SURFACE)
	prints("AUDIT muro: antes trava =", antes == muro, "| estado depois de pagar =", muro.state,
		"| trava =", depois == muro, "| barreira seguinte =",
		depois.kind if depois != null else &"nenhuma")
	assert_bool(depois == muro).is_false()


# 5 · A moeda do minuto 0:20 cai no sitio da Casa de Treino e paga-a.
func test_moeda_do_vagabundo_vai_para_a_obra() -> void:
	_novo()
	var casa := _obras(&"training_house")[0]
	var vag := SimLoop.units.index_of(2)
	var x := SimLoop.units.xs[vag] - 8.0
	SimLoop.units.xs[_rei()] = x
	SimLoop.drop_coin(x, Band.Kind.SURFACE, 1, &"player")
	SimLoop.units.carried_coins[_rei()] -= 1
	for _t in 90:
		SimLoop.units.set_target_x(SimLoop.king_id, x)
		SimLoop.step(STEP)
	vag = SimLoop.units.index_of(2)
	prints("AUDIT 0:20: vagabundo em", SimLoop.units.xs[vag] - SimLoop.core_x,
		"casa de treino em", casa.x - SimLoop.core_x, "±", casa.width * 0.5,
		"| casa paga =", casa.paid,
		"| vagabundo recrutado =", SimLoop.units.owners[vag] != RecruitSystem.SEM_DONO)


# 6 · A economia que o CI afina e a que o jogo corre.
func test_modelo_contra_producao_real() -> void:
	_novo()
	var fontes := 0
	for kind in [&"farm", &"henhouse", &"fishery"]:
		for o in _obras(kind):
			_de_pe(o)
			fontes += 1
	var eco := SimLoop.economy
	prints("AUDIT economia (", fontes, "fontes ):")
	for dia in range(1, 6):
		var antes := _prod
		var d := ClockService.clock.day
		while ClockService.clock.day == d:
			_parar_rei_no_nucleo()
			SimLoop.step(STEP)
		prints("    dia %d: modelo %.1f | real %d | built_income %.1f" % [
			dia, eco.daily_income(fontes, dia), _prod - antes, eco.built_income(SimLoop.builds, dia)])
	prints("   upkeep(14) =", eco.upkeep(14), "night_cost(1..5) =", eco.night_cost(1), eco.night_cost(5))


# 7 · Arqueiros com posto num muro cacam menos?
var _cacado := 0


func _apanhou(quem: int, quanto: int) -> void:
	if quem in [6, 7, 8]:
		_cacado += quanto


func test_muro_canibaliza_a_caca() -> void:
	EventBus.coin_collected.connect(_apanhou)
	var sem := _caca_do_dia(false)
	var com := _caca_do_dia(true)
	EventBus.coin_collected.disconnect(_apanhou)
	prints("AUDIT caca dia 1, 3 arqueiros teus [cacado, com posto]: sem muros =", sem,
		"| 4 muros nivel 1 =", com)


func _caca_do_dia(muros: bool) -> Array:
	SimLoop.stop()
	_novo()
	_cacado = 0
	for id in [6, 7, 8]:
		SimLoop.units.owners[SimLoop.units.index_of(id)] = _dono()
	if muros:
		for o in SimLoop.builds.slots:
			if o.two_paths():
				_de_pe(o)
	while ClockService.clock.current_phase() < GameClock.Phase.DUSK:
		_parar_rei_no_nucleo()
		SimLoop.step(STEP)
	var postos := 0
	for id in [6, 7, 8]:
		if SimLoop.units.job_ids[SimLoop.units.index_of(id)] != UnitSystem.NENHUM:
			postos += 1
	return [_cacado, postos]


# 8 · O rei morre e a partida continua sem ninguem para comandar.
func test_rei_morto_sem_sucessao() -> void:
	_novo()
	SimLoop.builds.slots[0].health = 1000000  # isola a pergunta: o nucleo nao cai esta noite
	SimLoop.units.healths[_rei()] = 0
	for _t in int(ClockService.clock.day_seconds() * 1.1 / STEP):
		SimLoop.step(STEP)
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	var nucleo := SimLoop.builds.slots[0]
	var mandou := {&"x": SimLoop.core_x, &"band": Band.Kind.SURFACE, &"amount": 1, &"source": &"player"}
	SimLoop.intents.queue(IntentQueue.Kind.DROP_COIN, mandou)
	var moedas := SimLoop.coins.count()
	SimLoop.step(STEP)
	prints("AUDIT rei morto: rei em campo =", rei != UnitSystem.NENHUM,
		"| nucleo de pe =", nucleo.standing(), "| a partida corre =", SimLoop.running(),
		"| largar criou moeda =", SimLoop.coins.count() > moedas, "| dia =", ClockService.clock.day)


# 9 · (descartado) As moedas de quem morre junto a um muro pagam-no sem gesto?
var _mortes_x: Array[float] = []


func _caiu_morte(x: float, _f: int, _q: int, origem: StringName) -> void:
	if origem == &"death":
		_mortes_x.append(x)


func test_saque_da_noite_paga_obras_sozinho() -> void:
	EventBus.coin_dropped.connect(_caiu_morte)
	var pagos := {}
	var escadas := 0
	var tocadas := 0
	for semente in [1, 2, 3, 4, 5, 6]:
		SimLoop.stop()
		SimLoop.start(semente)
		Greybox.build()
		SimLoop.builds.slots[0].health = 1000000
		for id in [6, 7, 8, 9, 10]:
			SimLoop.units.owners[SimLoop.units.index_of(id)] = _dono()
		var muros: Array[BuildSlot] = []
		for o in SimLoop.builds.slots:
			if o.two_paths():
				_de_pe(o)
				muros.append(o)
		for t in _obras(&"archer_tower"):
			_de_pe(t)
		while ClockService.clock.day < 3:
			_parar_rei_no_nucleo()
			SimLoop.step(STEP)
			for m in muros:
				if m.paid > int(pagos.get(m.id, 0)):
					pagos[m.id] = m.paid
				if m.state == BuildSlot.State.SCAFFOLD and m.level >= 1:
					escadas += 1
					m.state = BuildSlot.State.DONE
				if m.mending:
					tocadas += 1
					m.mending = false
	EventBus.coin_dropped.disconnect(_caiu_morte)
	prints("AUDIT saque: moedas de morte =", _mortes_x.size(),
		"| muros com moeda paga sem gesto =", pagos,
		"| degraus iniciados sozinhos =", escadas, "| reparacoes iniciadas sozinhas =", tocadas)
```

---

## Anexo B — Comandos usados

```bash
git fetch origin && git merge --ff-only origin/main          # a branch estava 55 commits atrás
GODOT=<caminho do 4.6-stable> ./run_tests.sh -c               # 717 · 711 · 6 saltados · 0 falhas
$GODOT --headless --path . scenes/tests/vistoria.tscn -- --dias 10   # 3 de 10 dias
$GODOT --headless --path . scenes/tests/dez_dias.tscn                # as 9 defesas caem (voz ligada)
```

---

## Anexo C — Perguntas prontas para `docs/QUESTIONS.md` (rascunho; numerar ao colar)

**Q-a · Uma moeda serve quem?** — §02, §55, §61; `sim_loop.gd:156-159`. Hoje o destino é a ordem do tick; o painel
promete um destino e a moeda pode ir para outro (D5). *Proposta:* o destino resolve-se no gesto e vai na moeda
(P-A). *Decide:* tu.

**Q-b · Um muro a subir de nível continua a ser muro?** — §10, §55; `build_system.gd:96,175`. Hoje não trava, não
leva dano e perde os postos (D4). *Proposta:* o degrau anterior mantém-se de pé até o novo acabar. *Decide:* tu.

**Q-c · A torre dá certeza a quem está nela, ou a quem tem o posto?** — §07; `posts.gd:17-37`. Hoje é ao posto (D3).
*Proposta:* a quem está a meia largura dela. *Decide:* tu (é quase uma correção).

**Q-d · O que acontece quando o rei morre antes de haver sucessão?** — §15, §16; `game.gd:144-150`. Hoje o mundo
continua sem avatar (D6). *Opções:* derrota imediata; o saco como vida (Kingdom); interregno do §16 com herdeiro
provisório. *Decide:* tu.

**Q-e · Qual é a economia verdadeira: a do modelo ou a da partida?** — §06, §29, Q-033; `economy_system.gd:137-158`.
Três números para a mesma pergunta (D7). *Proposta:* a da partida, com o modelo como previsão com tolerância.
*Decide:* tu.

**Q-f · A produção pede o trabalhador?** — §06, §52; `economy_system.gd:137-158`. Hoje não (§5.3). *Proposta:* rende a
100% com o posto ocupado e a uma fração sem ele. *Decide:* tu (e a fração vai a `_proposed`).

**Q-g · Quando se sabe de que lado vem a noite?** — §05, §51; `night_watch.gd:136`. Hoje no crepúsculo, sem aviso de
composição. *Proposta:* à tarde, pela candeia e pelo som (P-F). *Decide:* tu.

**Q-h · A Colheita Forçada tem de poder compensar?** — §15; `impulses.csv`. Hoje dá −6,4 no melhor caso (§5.1).
*Decide:* tu (o §15 diz "nunca só vantagem"; hoje é só desvantagem).

**Q-i · Quem não tem posto segue o rei ou espera no núcleo?** — §25 ("segue-te"), §52; `recruit_system.gd:93-104`.
*Proposta:* segue de dia, recolhe ao núcleo ao crepúsculo (P-C). *Decide:* tu.

**Q-j · Como acaba uma região?** — §13, §16, §77, §79. Hoje não acaba. *Proposta:* travessia pela bifurcação para o
capítulo seguinte, com *decay* do que fica (P-K). *Decide:* tu e o calendário.

---

## Anexo D — Fontes

Jogos e entrevistas:

- [Kingdom Two Crowns — Wikipedia](https://en.wikipedia.org/wiki/Kingdom_Two_Crowns)
- [Kingdom Two Crowns and the practical intersection of pixel art and roguelike design — Game Developer](https://www.gamedeveloper.com/design/-i-kingdom-two-crowns-i-and-the-practical-intersection-of-pixel-art-and-roguelike-design)
- [How 2 guys created side-scrolling strategy Kingdom — 80.lv](https://80.lv/articles/kingdom-how-2-guys-created-a-side-scrolling-strategy)
- [How Kingdom: New Lands masters minimalist game design — Medium](https://omkarghawate.medium.com/how-kingdom-new-lands-masters-minimalist-game-design-5385ca17d72d)
- [Kingdom Two Crowns Walls Guide — Nerds & Scoundrels](https://www.nerdsandscoundrels.com/kingdom-two-crowns-walls/)
- [Kingdom Wiki — Tools and weapons](https://kingdomthegame.fandom.com/wiki/Tools_and_weapons) · [Villager](https://kingdomthegame.fandom.com/wiki/Villager) · [Blood Moon](https://kingdomthegame.fandom.com/wiki/Blood_Moon) · [Defending the Kingdom](https://kingdomthegame.fandom.com/wiki/Defending_the_Kingdom)
- [A Complete Guide to Kingdom: Two Crowns — Steam Community](https://steamcommunity.com/sharedfiles/filedetails/?id=1588497381)
- [Mastering minimalism and layering complexity with Thronefall — Game Developer](https://www.gamedeveloper.com/design/mastering-minimalism-and-layering-complexity-with-strategy-game-thronefall)
- [Paul Schnepf (Thronefall): "I want to take the headache out of strategy games" — I.N.T](https://int-magazine.com/interview/paul-schnepf-of-thronefall/)
- [Building a best-selling game with a tiny team — The Pragmatic Engineer](https://newsletter.pragmaticengineer.com/p/thronefall)
- [Thronefall hands-on preview — Checkpoint Gaming](https://checkpointgaming.net/features/2023/08/thronefall-hands-on-preview-a-small-game-packing-a-big-punch/)
- [How Dome Keeper focuses on systems that feed into one another — Game Developer](https://www.gamedeveloper.com/business/how-dome-keeper-focuses-on-systems-that-feed-into-one-another)
- [Dome Keeper — Shacknews interview](https://www.shacknews.com/article/130994/shacknews-e6-2022-dome-keeper-interview-on-resource-mining-and-survival)
- [How Against the Storm managed to mix city-building and roguelite play — Game Developer](https://www.gamedeveloper.com/business/how-against-the-storm-managed-to-mix-city-building-and-roguelite-play)
- [Frostpunk developers on hope, misery, and the book of laws — PC Gamer](https://www.pcgamer.com/frostpunk-developers-on-hope-misery-and-the-ultimately-terrifying-book-of-laws/)
- ['Into the Breach' Design Postmortem — GDC Vault](https://gdcvault.com/play/1026333/-Into-the-Breach-Design)
- [The AI Systems of Left 4 Dead — Michael Booth, Valve](https://www.readkong.com/page/the-ai-systems-of-left-4-dead-michael-booth-valve-9664541)

Economia, interface, acessibilidade e processo:

- [Value chains — Lost Garden (Daniel Cook)](https://lostgarden.com/2021/12/12/value-chains/)
- [The Designer's Notebook: Machinations — Game Developer](https://www.gamedeveloper.com/design/the-designer-s-notebook-machinations-a-new-way-to-design-game-mechanics)
- [Simulating Mechanics to Study Emergence in Games — Joris Dormans (AAAI)](https://cdn.aaai.org/ojs/12477/12477-52-16005-1-2-20201228.pdf)
- [Beyond the HUD — Fagerholt & Lorentzon (2009)](https://www.researchgate.net/publication/277202228_Beyond_the_HUD_-_User_Interfaces_for_Increased_Player_Immersion_in_FPS_Games)
- [Game Accessibility Guidelines — lista completa](https://gameaccessibilityguidelines.com/full-list/) · [Básico](https://gameaccessibilityguidelines.com/basic/)
- [Steam Deck and Steam Machine Compatibility Review — Steamworks](https://partner.steamgames.com/doc/steamhardware/compat)
- [Using the RITE method to improve products — Medlock et al.](https://www.jpattonassociates.com/wp-content/uploads/2015/04/rite_method.pdf)
- [Juice it or lose it — Jonasson & Purho (GDC Europe 2012)](https://www.youtube.com/watch?v=Fy0aCDmgnxg)
