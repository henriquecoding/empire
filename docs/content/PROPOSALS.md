# Valores propostos — para rever

_Gerado por tools/content_report.py a partir de data/source/ — nao editar a mao._

Cada linha é um valor que **não está no dossiê** e foi proposto ao criar a base de dados (decisão de 11/09/2026: propor e marcar, em vez de deixar vazio). A justificação está na coluna `_notes` do CSV. Para aceitar um valor, apaga o nome do campo da coluna `_proposed`; para o mudar, edita o número e mantém a marca até o playtest o confirmar.

| | balanceamento | apresentação/estrutura | total |
|---|---|---|---|
| Fases 0–2 (fatia vertical) | 185 | 89 | 274 |
| Fases 3–8 | 225 | 105 | 330 |
| Total | 410 | 194 | 604 |

**Por onde começar:** a primeira tabela abaixo — os números de balanceamento que a fatia vertical usa. O resto pode esperar pela fase respetiva.

## 1 · Fatia vertical — balanceamento — 185

| tabela | linha | campo | valor | fase | nota |
|---|---|---|---|---|---|
| units | `vagrant` | `job_affinity` | farm:1.0\|milking:1.0\|cart:0.8 | 1 | Sem ataque: intervalo, precisão e alcance ficam no valor por omissão e não são lidos. coin_capacity 2 herda a escala do Kingdom (camponês 2, §02). |
| units | `vagrant` | `coin_capacity` | 2 | 1 | Sem ataque: intervalo, precisão e alcance ficam no valor por omissão e não são lidos. coin_capacity 2 herda a escala do Kingdom (camponês 2, §02). |
| units | `archer` | `job_affinity` | hunt:1.0\|wall:1.0\|tower:1.0\|farm:0.3 | 1 | Faixa aérea só ao alcance em altura (torre alta, §10) — ver Q-006. coin_capacity 11 = arqueiro do Kingdom (§02). |
| units | `archer` | `coin_capacity` | 11 | 1 | Faixa aérea só ao alcance em altura (torre alta, §10) — ver Q-006. coin_capacity 11 = arqueiro do Kingdom (§02). |
| units | `spearman` | `job_affinity` | wall:1.0\|guard:0.8 | 1 | 'Segura a linha. Não persegue.' vira as tags holds_line e no_pursuit. |
| units | `spearman` | `coin_capacity` | 5 | 1 | 'Segura a linha. Não persegue.' vira as tags holds_line e no_pursuit. |
| units | `dragonfly` | `accuracy_open` | 1.0 | 2 | move_speed 152 = 80 × 1,9 (a libélula-montaria da §12). Sem sombra de contacto: não toca o chão (§22). |
| units | `dragonfly` | `targets_bands` | AERIAL\|SURFACE | 2 | move_speed 152 = 80 × 1,9 (a libélula-montaria da §12). Sem sombra de contacto: não toca o chão (§22). |
| units | `dragonfly` | `move_speed` | 152 | 2 | move_speed 152 = 80 × 1,9 (a libélula-montaria da §12). Sem sombra de contacto: não toca o chão (§22). |
| units | `dragonfly` | `job_affinity` | air_patrol:1.0 | 2 | move_speed 152 = 80 × 1,9 (a libélula-montaria da §12). Sem sombra de contacto: não toca o chão (§22). |
| units | `dragonfly` | `coin_capacity` | 0 | 2 | move_speed 152 = 80 × 1,9 (a libélula-montaria da §12). Sem sombra de contacto: não toca o chão (§22). |
| units | `root_berserker` | `scale_tier` | 3 | 2 | 'Avança sempre. Não recua nem com o muro caído.' → always_advance, no_retreat. Escala 3 por ser elite (§01). |
| units | `root_berserker` | `job_affinity` | wall:1.0 | 2 | 'Avança sempre. Não recua nem com o muro caído.' → always_advance, no_retreat. Escala 3 por ser elite (§01). |
| units | `root_berserker` | `coin_capacity` | 5 | 2 | 'Avança sempre. Não recua nem com o muro caído.' → always_advance, no_retreat. Escala 3 por ser elite (§01). |
| units | `monarch` | `max_health` | 60 | 1 | coin_capacity 33: menor valor que paga o Muro de pedra (20), não paga a Muralha de ferro (36) sem cavalo, e com o cavalo (66) paga o Bastião (65) — a lógica da §02 e da §12. |
| units | `monarch` | `damage` | 3 | 1 | coin_capacity 33: menor valor que paga o Muro de pedra (20), não paga a Muralha de ferro (36) sem cavalo, e com o cavalo (66) paga o Bastião (65) — a lógica da §02 e da §12. |
| units | `monarch` | `attack_interval` | 1.2 | 1 | coin_capacity 33: menor valor que paga o Muro de pedra (20), não paga a Muralha de ferro (36) sem cavalo, e com o cavalo (66) paga o Bastião (65) — a lógica da §02 e da §12. |
| units | `monarch` | `range_px` | 30 | 1 | coin_capacity 33: menor valor que paga o Muro de pedra (20), não paga a Muralha de ferro (36) sem cavalo, e com o cavalo (66) paga o Bastião (65) — a lógica da §02 e da §12. |
| units | `monarch` | `coin_capacity` | 33 | 1 | coin_capacity 33: menor valor que paga o Muro de pedra (20), não paga a Muralha de ferro (36) sem cavalo, e com o cavalo (66) paga o Bastião (65) — a lógica da §02 e da §12. |
| units | `squire` | `max_health` | 8 | 1 | coin_capacity 5 = escudeiro do Kingdom (§02). Na Fase 2 da classe cresce e torna-se tropa de combate (ClassData monarch). |
| units | `squire` | `coin_capacity` | 5 | 1 | coin_capacity 5 = escudeiro do Kingdom (§02). Na Fase 2 da classe cresce e torna-se tropa de combate (ClassData monarch). |
| units | `builder` | `max_health` | 12 | 1 | Os parâmetros da habilidade são os do nível 1 do §09 (+8% defesa das muralhas, +1 slot de armas). can_change_band: ofícios enviados passam entre faixas (§11). |
| units | `builder` | `job_affinity` | build:1.0\|repair:1.0 | 1 | Os parâmetros da habilidade são os do nível 1 do §09 (+8% defesa das muralhas, +1 slot de armas). can_change_band: ofícios enviados passam entre faixas (§11). |
| units | `builder` | `coin_capacity` | 2 | 1 | Os parâmetros da habilidade são os do nível 1 do §09 (+8% defesa das muralhas, +1 slot de armas). can_change_band: ofícios enviados passam entre faixas (§11). |
| units | `smith` | `max_health` | 12 | 2 | weapon_levels 1 vem da capacidade da Fundição (§06). Nível 2 recolhe armas largadas (§09). O bigode é dele (§04). |
| units | `smith` | `job_affinity` | forge:1.0 | 2 | weapon_levels 1 vem da capacidade da Fundição (§06). Nível 2 recolhe armas largadas (§09). O bigode é dele (§04). |
| units | `smith` | `coin_capacity` | 2 | 2 | weapon_levels 1 vem da capacidade da Fundição (§06). Nível 2 recolhe armas largadas (§09). O bigode é dele (§04). |
| units | `cook` | `max_health` | 12 | 2 | Prato de combate: buff forte de 20 s, permanente no nível 2 (§09). Os valores de vida/velocidade estão em crafts.csv. |
| units | `cook` | `job_affinity` | kitchen:1.0 | 2 | Prato de combate: buff forte de 20 s, permanente no nível 2 (§09). Os valores de vida/velocidade estão em crafts.csv. |
| units | `cook` | `coin_capacity` | 2 | 2 | Prato de combate: buff forte de 20 s, permanente no nível 2 (§09). Os valores de vida/velocidade estão em crafts.csv. |
| units | `canopy_archer` | `max_health` | 14 | 2 | É o arqueiro do §07 com a certeza da torre: 'a torre não dá dano — dá certeza' (§07). Custo 5 = arqueiro 3 + posição. |
| units | `canopy_archer` | `damage` | 4 | 2 | É o arqueiro do §07 com a certeza da torre: 'a torre não dá dano — dá certeza' (§07). Custo 5 = arqueiro 3 + posição. |
| units | `canopy_archer` | `attack_interval` | 1.4 | 2 | É o arqueiro do §07 com a certeza da torre: 'a torre não dá dano — dá certeza' (§07). Custo 5 = arqueiro 3 + posição. |
| units | `canopy_archer` | `range_px` | 200 | 2 | É o arqueiro do §07 com a certeza da torre: 'a torre não dá dano — dá certeza' (§07). Custo 5 = arqueiro 3 + posição. |
| units | `canopy_archer` | `recruit_cost` | 5 | 2 | É o arqueiro do §07 com a certeza da torre: 'a torre não dá dano — dá certeza' (§07). Custo 5 = arqueiro 3 + posição. |
| units | `canopy_archer` | `move_speed` | 80 | 2 | É o arqueiro do §07 com a certeza da torre: 'a torre não dá dano — dá certeza' (§07). Custo 5 = arqueiro 3 + posição. |
| units | `canopy_archer` | `coin_capacity` | 5 | 2 | É o arqueiro do §07 com a certeza da torre: 'a torre não dá dano — dá certeza' (§07). Custo 5 = arqueiro 3 + posição. |
| units | `canopy_archer` | `ability_params` | accuracy_in_canopy:1.0 | 2 | É o arqueiro do §07 com a certeza da torre: 'a torre não dá dano — dá certeza' (§07). Custo 5 = arqueiro 3 + posição. |
| creatures | `crawler` | `range_px` | 24 | 1 | coin_drop 1 é do dossiê (§25). A curva de asfixia do §06 não conta com moedas de abate — ver Q-011. |
| creatures | `crawler` | `accuracy` | 1.0 | 1 | coin_drop 1 é do dossiê (§25). A curva de asfixia do §06 não conta com moedas de abate — ver Q-011. |
| creatures | `crawler` | `scale_tier` | 1 | 1 | coin_drop 1 é do dossiê (§25). A curva de asfixia do §06 não conta com moedas de abate — ver Q-011. |
| creatures | `winged` | `range_px` | 24 | 1 | 'Obriga a torre alta' (§07, §10). Sem sombra de contacto: voa. |
| creatures | `winged` | `accuracy` | 1.0 | 1 | 'Obriga a torre alta' (§07, §10). Sem sombra de contacto: voa. |
| creatures | `winged` | `scale_tier` | 2 | 1 | 'Obriga a torre alta' (§07, §10). Sem sombra de contacto: voa. |
| creatures | `winged` | `coin_drop` | 1 | 1 | 'Obriga a torre alta' (§07, §10). Sem sombra de contacto: voa. |
| creatures | `brute` | `range_px` | 24 | 1 |  |
| creatures | `brute` | `accuracy` | 1.0 | 1 |  |
| creatures | `brute` | `scale_tier` | 3 | 1 |  |
| creatures | `brute` | `coin_drop` | 2 | 1 |  |
| buildings | `core` | `max_health` | 1000 | 1 | Não é construído nem destruído (§10): 1000 de vida mede quanto aguenta a partida, não um edifício. contact_slots 7 é o topo da escada do §10 — o Bastião —, a outra obra única por império: o núcleo é a maior do mapa (480 px) e a última. Sem a coluna nada o podia atacar (Q-076). Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `core` | `contact_slots` | 7 | 1 | Não é construído nem destruído (§10): 1000 de vida mede quanto aguenta a partida, não um edifício. contact_slots 7 é o topo da escada do §10 — o Bastião —, a outra obra única por império: o núcleo é a maior do mapa (480 px) e a última. Sem a coluna nada o podia atacar (Q-076). Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `training_house` | `max_health` | 80 | 1 | O custo 10 é o da reparação no minuto 8:30 (§25); assume-se igual para construção nova. Alvo prioritário dos reis inimigos a partir do dia 15 (§10, EconomyCurve). Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `forge` | `cost` | 12 | 2 | Forja (oficina do ferreiro) ≠ Fundição (casa de conversão do minério) — ver Q-008. Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `forge` | `max_health` | 96 | 2 | Forja (oficina do ferreiro) ≠ Fundição (casa de conversão do minério) — ver Q-008. Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `kitchen` | `cost` | 10 | 2 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `kitchen` | `max_health` | 80 | 2 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `farm` | `max_health` | 32 | 1 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `fishery` | `max_health` | 48 | 1 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `henhouse` | `max_health` | 64 | 1 | 'Galinhas roubáveis à noite' (§06). Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `granary` | `max_health` | 80 | 2 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `archer_tower` | `max_health` | 144 | 1 | 2 postos elevados, +40% alcance, precisão ≈100% — do dossiê. Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `high_tower` | `max_health` | 240 | 1 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `fire_barrel` | `max_health` | 20 | 1 | Exceção à regra de vida: 20, porque tem de rebentar. aoe_damage 20 mata dois Rastejantes (vida 10) e fere um Bruto. Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `fire_barrel` | `effect_params` | rot_slow:0.25\|aoe_damage:20\|aoe_radius:96 | 1 | Exceção à regra de vida: 20, porque tem de rebentar. aoe_damage 20 mata dois Rastejantes (vida 10) e fere um Bruto. Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| walls | `stakes` | `max_health_a` | 40 | 1 | Nível 1 é a base comum aos dois caminhos. Materiais de Horta e Fornalha propostos; os três primeiros são do §10. |
| walls | `stakes` | `guard_posts_b` | 1 | 1 | Nível 1 é a base comum aos dois caminhos. Materiais de Horta e Fornalha propostos; os três primeiros são do §10. |
| walls | `palisade` | `max_health_a` | 48 | 1 | O §10 diz 'Madeira reforçada / gelo'; nenhum dos seis povos é de gelo — Q-010. Caminho A = 50% da vida do B. |
| walls | `palisade` | `guard_posts_b` | 1 | 1 | O §10 diz 'Madeira reforçada / gelo'; nenhum dos seis povos é de gelo — Q-010. Caminho A = 50% da vida do B. |
| walls | `stone_wall` | `max_health_a` | 105 | 2 | 'Pedra / basalto / coral' (§10) repartidos por povo: a atribuição é proposta. |
| walls | `stone_wall` | `guard_posts_b` | 2 | 2 | 'Pedra / basalto / coral' (§10) repartidos por povo: a atribuição é proposta. |
| peoples | `enramados` | `economy_modifiers` | hunt_yield_mult:1.25 | 1 | O povo da fatia vertical (§33). 'Madeira e caça' vira +25% na caça; arquétipo arqueiro porque dispara de cima. v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `enramados` | `song_texture` | Voz sozinha e adufe — Beira Baixa, pandeiro quadrado | 1 | O povo da fatia vertical (§33). 'Madeira e caça' vira +25% na caça; arquétipo arqueiro porque dispara de cima. v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `enramados` | `colheita_song` | Meio tom abaixo, e o adufe fora de sítio | 1 | O povo da fatia vertical (§33). 'Madeira e caça' vira +25% na caça; arquétipo arqueiro porque dispara de cima. v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| classes | `monarch` | `evolve_condition` | nights_defended_in_person | 1 | O raio da aura reutiliza o raio de presença do rei (§07). A condição de feito é proposta — o §08 só dá a do Bardo. |
| classes | `monarch` | `evolve_condition_value` | 5 | 1 | O raio da aura reutiliza o raio de presença do rei (§07). A condição de feito é proposta — o §08 só dá a do Bardo. |
| classes | `archer` | `phase1_params` | targets:1\|duration:10 | 2 | Resolve o desperdício de flechas do Kingdom (§07). |
| classes | `archer` | `phase2_params` | pierce_column:1\|mark_radius:96 | 2 | Resolve o desperdício de flechas do Kingdom (§07). |
| classes | `archer` | `evolve_condition` | marked_kills | 2 | Resolve o desperdício de flechas do Kingdom (§07). |
| classes | `archer` | `evolve_condition_value` | 30 | 2 | Resolve o desperdício de flechas do Kingdom (§07). |
| crafts | `grain_granary` | `cost` | 1 | 2 | +10% de vida máxima enquanto a conversão corre; duration 0 = recalculada a cada fase (§49). |
| crafts | `grain_granary` | `magnitude` | 0.1 | 2 | +10% de vida máxima enquanto a conversão corre; duration 0 = recalculada a cada fase (§49). |
| crafts | `grain_granary` | `duration` | 0 | 2 | +10% de vida máxima enquanto a conversão corre; duration 0 = recalculada a cada fase (§49). |
| jobs | `wall` | `priority` | 1.0 | 1 | Só a noite é do dossiê; o resto sobe em rampa até ao crepúsculo. |
| jobs | `wall` | `dawn` | 0.5 | 1 | Só a noite é do dossiê; o resto sobe em rampa até ao crepúsculo. |
| jobs | `wall` | `morning` | 0.5 | 1 | Só a noite é do dossiê; o resto sobe em rampa até ao crepúsculo. |
| jobs | `wall` | `noon` | 0.5 | 1 | Só a noite é do dossiê; o resto sobe em rampa até ao crepúsculo. |
| jobs | `wall` | `afternoon` | 1.0 | 1 | Só a noite é do dossiê; o resto sobe em rampa até ao crepúsculo. |
| jobs | `wall` | `dusk` | 2.0 | 1 | Só a noite é do dossiê; o resto sobe em rampa até ao crepúsculo. |
| jobs | `tower` | `priority` | 1.2 | 1 | Prioridade acima do muro: 'a torre é o multiplicador' (§07). |
| jobs | `tower` | `dawn` | 0.5 | 1 | Prioridade acima do muro: 'a torre é o multiplicador' (§07). |
| jobs | `tower` | `morning` | 0.5 | 1 | Prioridade acima do muro: 'a torre é o multiplicador' (§07). |
| jobs | `tower` | `noon` | 0.5 | 1 | Prioridade acima do muro: 'a torre é o multiplicador' (§07). |
| jobs | `tower` | `afternoon` | 1.0 | 1 | Prioridade acima do muro: 'a torre é o multiplicador' (§07). |
| jobs | `tower` | `dusk` | 2.0 | 1 | Prioridade acima do muro: 'a torre é o multiplicador' (§07). |
| jobs | `farm` | `priority` | 1.0 | 1 | Crepúsculo a 0: é a recolha aos postos (§05). |
| jobs | `farm` | `dawn` | 1.0 | 1 | Crepúsculo a 0: é a recolha aos postos (§05). |
| jobs | `farm` | `morning` | 1.0 | 1 | Crepúsculo a 0: é a recolha aos postos (§05). |
| jobs | `farm` | `noon` | 1.0 | 1 | Crepúsculo a 0: é a recolha aos postos (§05). |
| jobs | `farm` | `afternoon` | 1.0 | 1 | Crepúsculo a 0: é a recolha aos postos (§05). |
| jobs | `farm` | `dusk` | 0.0 | 1 | Crepúsculo a 0: é a recolha aos postos (§05). |
| jobs | `hunt` | `priority` | 0.8 | 1 |  |
| jobs | `hunt` | `dawn` | 0.5 | 1 |  |
| jobs | `hunt` | `morning` | 1.0 | 1 |  |
| jobs | `hunt` | `noon` | 1.0 | 1 |  |
| jobs | `hunt` | `afternoon` | 0.8 | 1 |  |
| jobs | `hunt` | `dusk` | 0.0 | 1 |  |
| jobs | `hunt` | `night` | 0.0 | 1 |  |
| jobs | `build` | `priority` | 1.5 | 1 | A exceção do construtor evoluído é habilidade, não urgência. |
| jobs | `build` | `dawn` | 1.0 | 1 | A exceção do construtor evoluído é habilidade, não urgência. |
| jobs | `build` | `morning` | 1.0 | 1 | A exceção do construtor evoluído é habilidade, não urgência. |
| jobs | `build` | `noon` | 1.0 | 1 | A exceção do construtor evoluído é habilidade, não urgência. |
| jobs | `build` | `afternoon` | 1.0 | 1 | A exceção do construtor evoluído é habilidade, não urgência. |
| jobs | `build` | `dusk` | 0.5 | 1 | A exceção do construtor evoluído é habilidade, não urgência. |
| jobs | `repair` | `priority` | 1.5 | 1 |  |
| jobs | `repair` | `dawn` | 1.0 | 1 |  |
| jobs | `repair` | `morning` | 0.8 | 1 |  |
| jobs | `repair` | `noon` | 0.8 | 1 |  |
| jobs | `repair` | `afternoon` | 1.0 | 1 |  |
| jobs | `repair` | `dusk` | 1.5 | 1 |  |
| jobs | `repair` | `night` | 0.0 | 1 |  |
| jobs | `forge` | `priority` | 1.0 | 2 |  |
| jobs | `forge` | `dawn` | 1.0 | 2 |  |
| jobs | `forge` | `morning` | 1.0 | 2 |  |
| jobs | `forge` | `noon` | 1.0 | 2 |  |
| jobs | `forge` | `afternoon` | 1.0 | 2 |  |
| jobs | `forge` | `dusk` | 0.3 | 2 |  |
| jobs | `forge` | `night` | 0.0 | 2 |  |
| jobs | `kitchen` | `priority` | 1.0 | 2 |  |
| jobs | `kitchen` | `dawn` | 1.0 | 2 |  |
| jobs | `kitchen` | `morning` | 1.0 | 2 |  |
| jobs | `kitchen` | `noon` | 1.0 | 2 |  |
| jobs | `kitchen` | `afternoon` | 1.0 | 2 |  |
| jobs | `kitchen` | `dusk` | 0.5 | 2 |  |
| jobs | `kitchen` | `night` | 0.3 | 2 |  |
| jobs | `guard` | `priority` | 1.0 | 2 |  |
| jobs | `guard` | `dawn` | 0.3 | 2 |  |
| jobs | `guard` | `morning` | 0.3 | 2 |  |
| jobs | `guard` | `noon` | 0.3 | 2 |  |
| jobs | `guard` | `afternoon` | 0.5 | 2 |  |
| jobs | `guard` | `dusk` | 1.5 | 2 |  |
| jobs | `guard` | `night` | 2.0 | 2 |  |
| jobs | `air_patrol` | `priority` | 1.0 | 2 |  |
| jobs | `air_patrol` | `dawn` | 0.3 | 2 |  |
| jobs | `air_patrol` | `morning` | 0.3 | 2 |  |
| jobs | `air_patrol` | `noon` | 0.3 | 2 |  |
| jobs | `air_patrol` | `afternoon` | 0.5 | 2 |  |
| jobs | `air_patrol` | `dusk` | 2.0 | 2 |  |
| jobs | `air_patrol` | `night` | 3.0 | 2 |  |
| segments | `enramados_start_base_01` | `build_slots` | 2 | 1 | 'Um por região, ao centro. É o teu castelo-árvore.' |
| segments | `enramados_start_base_01` | `cavity_slots` | 1 | 1 | 'Um por região, ao centro. É o teu castelo-árvore.' |
| segments | `enramados_start_base_01` | `passages` | 1 | 1 | 'Um por região, ao centro. É o teu castelo-árvore.' |
| segments | `enramados_opening_00` | `build_slots` | 2 | 1 | Cena fixa, sempre igual, a mais afinada do jogo (§25). Substitui o start_base na primeira partida: 1 cavidade e 1 passagem do minuto 10:00. |
| segments | `enramados_empty_01` | `build_slots` | 3 | 1 | 'Nunca menos de 3 por região.' 2 a 3 edifícios por segmento (§21). |
| segments | `enramados_empty_02` | `build_slots` | 3 | 1 |  |
| segments | `enramados_empty_03` | `build_slots` | 3 | 1 |  |
| segments | `enramados_empty_03` | `cavity_slots` | 1 | 1 |  |
| segments | `enramados_forest_01` | `build_slots` | 2 | 1 | Define a especialidade económica disponível: corte de madeira e caça. |
| segments | `enramados_forest_01` | `cavity_slots` | 1 | 1 | Define a especialidade económica disponível: corte de madeira e caça. |
| segments | `enramados_ruin_01` | `build_slots` | 1 | 1 | 'Traz uma passagem para o corte de solo.' |
| segments | `enramados_ruin_01` | `cavity_slots` | 1 | 1 | 'Traz uma passagem para o corte de solo.' |
| segments | `enramados_fortress_01` | `build_slots` | 0 | 1 | 'Nunca duas adjacentes. Uma nas extremidades da região.' |
| segments | `enramados_fortress_01` | `cavity_slots` | 1 | 1 | 'Nunca duas adjacentes. Uma nas extremidades da região.' |
| segments | `enramados_edge_01` | `build_slots` | 0 | 1 | O tipo edge vem da lição do Chef RPG (§21), que pede um segmento dedicado; não está na tabela de pesos. |
| rot | `default` | `sacrifice_mass_per_animal` | 8 | 1 | Animal = 8 de massa (um Rastejante a menos); tropa = 14 (um Alado a menos). A largura inicial não está no dossiê. v6: a base, o termo do dia e o das fortalezas descem (60→40, 26→18, 40→30) e entram os Amargueiros e as recusas (§74). A tabela do §74 confere: campo limpo ao dia 20 = 400 (D-01). As tres paragens da luz e o dither de 2 px sao do §80 e o check_dossie_vs_csv confere-os contra o dossie — por isso o lantern_tint saiu de _proposed. A base do Amargueiro (32 px, a do barril de fogo) é onde a moeda cai nele e quem o corta tem de estar — o dossiê não a escreve (Q-086). O prato da oferta tem 'o tamanho de um slot de construção' e o dossiê não diz de qual: 96 px, o do canteiro (Q-090). |
| rot | `default` | `sacrifice_mass_per_troop` | 14 | 1 | Animal = 8 de massa (um Rastejante a menos); tropa = 14 (um Alado a menos). A largura inicial não está no dossiê. v6: a base, o termo do dia e o das fortalezas descem (60→40, 26→18, 40→30) e entram os Amargueiros e as recusas (§74). A tabela do §74 confere: campo limpo ao dia 20 = 400 (D-01). As tres paragens da luz e o dither de 2 px sao do §80 e o check_dossie_vs_csv confere-os contra o dossie — por isso o lantern_tint saiu de _proposed. A base do Amargueiro (32 px, a do barril de fogo) é onde a moeda cai nele e quem o corta tem de estar — o dossiê não a escreve (Q-086). O prato da oferta tem 'o tamanho de um slot de construção' e o dossiê não diz de qual: 96 px, o do canteiro (Q-090). |
| rot | `default` | `width_start` | 160 | 1 | Animal = 8 de massa (um Rastejante a menos); tropa = 14 (um Alado a menos). A largura inicial não está no dossiê. v6: a base, o termo do dia e o das fortalezas descem (60→40, 26→18, 40→30) e entram os Amargueiros e as recusas (§74). A tabela do §74 confere: campo limpo ao dia 20 = 400 (D-01). As tres paragens da luz e o dither de 2 px sao do §80 e o check_dossie_vs_csv confere-os contra o dossie — por isso o lantern_tint saiu de _proposed. A base do Amargueiro (32 px, a do barril de fogo) é onde a moeda cai nele e quem o corta tem de estar — o dossiê não a escreve (Q-086). O prato da oferta tem 'o tamanho de um slot de construção' e o dossiê não diz de qual: 96 px, o do canteiro (Q-090). |
| rot | `default` | `amargueiro_base_px` | 32 | 1 | Animal = 8 de massa (um Rastejante a menos); tropa = 14 (um Alado a menos). A largura inicial não está no dossiê. v6: a base, o termo do dia e o das fortalezas descem (60→40, 26→18, 40→30) e entram os Amargueiros e as recusas (§74). A tabela do §74 confere: campo limpo ao dia 20 = 400 (D-01). As tres paragens da luz e o dither de 2 px sao do §80 e o check_dossie_vs_csv confere-os contra o dossie — por isso o lantern_tint saiu de _proposed. A base do Amargueiro (32 px, a do barril de fogo) é onde a moeda cai nele e quem o corta tem de estar — o dossiê não a escreve (Q-086). O prato da oferta tem 'o tamanho de um slot de construção' e o dossiê não diz de qual: 96 px, o do canteiro (Q-090). |
| rot | `default` | `offer_plate_px` | 96 | 1 | Animal = 8 de massa (um Rastejante a menos); tropa = 14 (um Alado a menos). A largura inicial não está no dossiê. v6: a base, o termo do dia e o das fortalezas descem (60→40, 26→18, 40→30) e entram os Amargueiros e as recusas (§74). A tabela do §74 confere: campo limpo ao dia 20 = 400 (D-01). As tres paragens da luz e o dither de 2 px sao do §80 e o check_dossie_vs_csv confere-os contra o dossie — por isso o lantern_tint saiu de _proposed. A base do Amargueiro (32 px, a do barril de fogo) é onde a moeda cai nele e quem o corta tem de estar — o dossiê não a escreve (Q-086). O prato da oferta tem 'o tamanho de um slot de construção' e o dossiê não diz de qual: 96 px, o do canteiro (Q-090). |
| wildlife | `rabbit` | `max_health` | 4 | 1 | Vida 4 = um só acerto de arqueiro (dano 4). |
| wildlife | `rabbit` | `move_speed` | 40 | 1 | Vida 4 = um só acerto de arqueiro (dano 4). |
| wildlife | `deer` | `max_health` | 8 | 1 | Vida 8 = dois acertos de arqueiro, como no Kingdom (§02). |
| wildlife | `deer` | `move_speed` | 48 | 1 | Vida 8 = dois acertos de arqueiro, como no Kingdom (§02). |
| wildlife | `deer` | `coin_yield` | 3 | 1 | Vida 8 = dois acertos de arqueiro, como no Kingdom (§02). |
| wildlife | `boar` | `max_health` | 28 | 2 | Topo do intervalo da §06 (9). Carrega contra quem o caça: é o risco de 'sair das muralhas de dia'. |
| wildlife | `boar` | `move_speed` | 34 | 2 | Topo do intervalo da §06 (9). Carrega contra quem o caça: é o risco de 'sair das muralhas de dia'. |
| wildlife | `boar` | `coin_yield` | 9 | 2 | Topo do intervalo da §06 (9). Carrega contra quem o caça: é o risco de 'sair das muralhas de dia'. |
| wildlife | `boar` | `damage` | 6 | 2 | Topo do intervalo da §06 (9). Carrega contra quem o caça: é o risco de 'sair das muralhas de dia'. |
| parallax_layers | `closed_1` | `saturation_delta` | -0.052 | 0 | Valor invertido (o fundo escurece); saturação a 15% do delta aberto — '15%' é proposta. |
| parallax_layers | `closed_2` | `saturation_delta` | -0.042 | 0 | Valor invertido (o fundo escurece); saturação a 15% do delta aberto — '15%' é proposta. |
| parallax_layers | `closed_3` | `saturation_delta` | -0.03 | 0 | Valor invertido (o fundo escurece); saturação a 15% do delta aberto — '15%' é proposta. |
| parallax_layers | `closed_4` | `saturation_delta` | -0.015 | 0 | Valor invertido (o fundo escurece); saturação a 15% do delta aberto — '15%' é proposta. |
| camera | `default` | `lookahead_px` | 120 | 0 | Q-057: o dossiê dá UM número de câmara — os 2 s do regresso (§24). Os outros quatro são propostas. lookahead_px 120 é 3/16 da meia-tela (640), o que deixa ver cerca de dois terços do ecrã à frente de quem anda. lookahead_seconds 0,6 é alto de propósito: uma antecipação que salta ao primeiro passo para trás dá enjoo. follow_seconds 0,18 cola a câmara ao alvo e deixa a folga para a antecipação. free_speed_px_s 420 atravessa um segmento de 640 px em pouco mais de um segundo e meio. Todos se afinam no primeiro playtest — e nenhum é lido por nada da simulação. |
| camera | `default` | `lookahead_seconds` | 0.6 | 0 | Q-057: o dossiê dá UM número de câmara — os 2 s do regresso (§24). Os outros quatro são propostas. lookahead_px 120 é 3/16 da meia-tela (640), o que deixa ver cerca de dois terços do ecrã à frente de quem anda. lookahead_seconds 0,6 é alto de propósito: uma antecipação que salta ao primeiro passo para trás dá enjoo. follow_seconds 0,18 cola a câmara ao alvo e deixa a folga para a antecipação. free_speed_px_s 420 atravessa um segmento de 640 px em pouco mais de um segundo e meio. Todos se afinam no primeiro playtest — e nenhum é lido por nada da simulação. |
| camera | `default` | `follow_seconds` | 0.18 | 0 | Q-057: o dossiê dá UM número de câmara — os 2 s do regresso (§24). Os outros quatro são propostas. lookahead_px 120 é 3/16 da meia-tela (640), o que deixa ver cerca de dois terços do ecrã à frente de quem anda. lookahead_seconds 0,6 é alto de propósito: uma antecipação que salta ao primeiro passo para trás dá enjoo. follow_seconds 0,18 cola a câmara ao alvo e deixa a folga para a antecipação. free_speed_px_s 420 atravessa um segmento de 640 px em pouco mais de um segundo e meio. Todos se afinam no primeiro playtest — e nenhum é lido por nada da simulação. |
| camera | `default` | `free_speed_px_s` | 420 | 0 | Q-057: o dossiê dá UM número de câmara — os 2 s do regresso (§24). Os outros quatro são propostas. lookahead_px 120 é 3/16 da meia-tela (640), o que deixa ver cerca de dois terços do ecrã à frente de quem anda. lookahead_seconds 0,6 é alto de propósito: uma antecipação que salta ao primeiro passo para trás dá enjoo. follow_seconds 0,18 cola a câmara ao alvo e deixa a folga para a antecipação. free_speed_px_s 420 atravessa um segmento de 640 px em pouco mais de um segundo e meio. Todos se afinam no primeiro playtest — e nenhum é lido por nada da simulação. |

## 2 · Fatia vertical — apresentação e estrutura — 89

| tabela | linha | campo | valor | fase | nota |
|---|---|---|---|---|---|
| units | `vagrant` | `tags` | worker | 1 | Sem ataque: intervalo, precisão e alcance ficam no valor por omissão e não são lidos. coin_capacity 2 herda a escala do Kingdom (camponês 2, §02). |
| units | `vagrant` | `head_pool` | bare\|hat_straw\|hair_black\|beard_red | 1 | Sem ataque: intervalo, precisão e alcance ficam no valor por omissão e não são lidos. coin_capacity 2 herda a escala do Kingdom (camponês 2, §02). |
| units | `archer` | `tags` | ranged\|hunter | 1 | Faixa aérea só ao alcance em altura (torre alta, §10) — ver Q-006. coin_capacity 11 = arqueiro do Kingdom (§02). |
| units | `archer` | `head_pool` | hood\|cap\|bare | 1 | Faixa aérea só ao alcance em altura (torre alta, §10) — ver Q-006. coin_capacity 11 = arqueiro do Kingdom (§02). |
| units | `spearman` | `tags` | melee\|holds_line\|no_pursuit | 1 | 'Segura a linha. Não persegue.' vira as tags holds_line e no_pursuit. |
| units | `spearman` | `head_pool` | helmet_round\|cap | 1 | 'Segura a linha. Não persegue.' vira as tags holds_line e no_pursuit. |
| units | `spearman` | `layer_slots` | body\|head\|face\|weapon\|shield\|overlay | 1 | 'Segura a linha. Não persegue.' vira as tags holds_line e no_pursuit. |
| units | `dragonfly` | `shadow_width` | 0 | 2 | move_speed 152 = 80 × 1,9 (a libélula-montaria da §12). Sem sombra de contacto: não toca o chão (§22). |
| units | `dragonfly` | `tags` | flyer | 2 | move_speed 152 = 80 × 1,9 (a libélula-montaria da §12). Sem sombra de contacto: não toca o chão (§22). |
| units | `root_berserker` | `shadow_width` | 22 | 2 | 'Avança sempre. Não recua nem com o muro caído.' → always_advance, no_retreat. Escala 3 por ser elite (§01). |
| units | `root_berserker` | `tags` | melee\|always_advance\|no_retreat\|elite | 2 | 'Avança sempre. Não recua nem com o muro caído.' → always_advance, no_retreat. Escala 3 por ser elite (§01). |
| units | `root_berserker` | `head_pool` | bare\|root_crown | 2 | 'Avança sempre. Não recua nem com o muro caído.' → always_advance, no_retreat. Escala 3 por ser elite (§01). |
| units | `monarch` | `tags` | king\|tank | 1 | coin_capacity 33: menor valor que paga o Muro de pedra (20), não paga a Muralha de ferro (36) sem cavalo, e com o cavalo (66) paga o Bastião (65) — a lógica da §02 e da §12. |
| units | `squire` | `shadow_width` | 14 | 1 | coin_capacity 5 = escudeiro do Kingdom (§02). Na Fase 2 da classe cresce e torna-se tropa de combate (ClassData monarch). |
| units | `squire` | `tags` | follows_king\|collects_coins | 1 | coin_capacity 5 = escudeiro do Kingdom (§02). Na Fase 2 da classe cresce e torna-se tropa de combate (ClassData monarch). |
| units | `builder` | `tags` | craft\|builder | 1 | Os parâmetros da habilidade são os do nível 1 do §09 (+8% defesa das muralhas, +1 slot de armas). can_change_band: ofícios enviados passam entre faixas (§11). |
| units | `builder` | `head_pool` | hat_builder | 1 | Os parâmetros da habilidade são os do nível 1 do §09 (+8% defesa das muralhas, +1 slot de armas). can_change_band: ofícios enviados passam entre faixas (§11). |
| units | `smith` | `tags` | craft\|smith | 2 | weapon_levels 1 vem da capacidade da Fundição (§06). Nível 2 recolhe armas largadas (§09). O bigode é dele (§04). |
| units | `smith` | `head_pool` | mustache_bald | 2 | weapon_levels 1 vem da capacidade da Fundição (§06). Nível 2 recolhe armas largadas (§09). O bigode é dele (§04). |
| units | `cook` | `tags` | craft\|cook | 2 | Prato de combate: buff forte de 20 s, permanente no nível 2 (§09). Os valores de vida/velocidade estão em crafts.csv. |
| units | `cook` | `head_pool` | hat_chef | 2 | Prato de combate: buff forte de 20 s, permanente no nível 2 (§09). Os valores de vida/velocidade estão em crafts.csv. |
| creatures | `crawler` | `shadow_width` | 16 | 1 | coin_drop 1 é do dossiê (§25). A curva de asfixia do §06 não conta com moedas de abate — ver Q-011. |
| creatures | `crawler` | `tags` | rot\|swarm | 1 | coin_drop 1 é do dossiê (§25). A curva de asfixia do §06 não conta com moedas de abate — ver Q-011. |
| creatures | `winged` | `shadow_width` | 0 | 1 | 'Obriga a torre alta' (§07, §10). Sem sombra de contacto: voa. |
| creatures | `winged` | `tags` | rot\|flyer | 1 | 'Obriga a torre alta' (§07, §10). Sem sombra de contacto: voa. |
| creatures | `brute` | `shadow_width` | 26 | 1 |  |
| creatures | `brute` | `tags` | rot\|heavy | 1 |  |
| buildings | `core` | `width_px` | 480 | 1 | Não é construído nem destruído (§10): 1000 de vida mede quanto aguenta a partida, não um edifício. contact_slots 7 é o topo da escada do §10 — o Bastião —, a outra obra única por império: o núcleo é a maior do mapa (480 px) e a última. Sem a coluna nada o podia atacar (Q-076). Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `core` | `shadow_width` | 480 | 1 | Não é construído nem destruído (§10): 1000 de vida mede quanto aguenta a partida, não um edifício. contact_slots 7 é o topo da escada do §10 — o Bastião —, a outra obra única por império: o núcleo é a maior do mapa (480 px) e a última. Sem a coluna nada o podia atacar (Q-076). Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `training_house` | `build_work` | 20 | 1 | O custo 10 é o da reparação no minuto 8:30 (§25); assume-se igual para construção nova. Alvo prioritário dos reis inimigos a partir do dia 15 (§10, EconomyCurve). Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `training_house` | `width_px` | 120 | 1 | O custo 10 é o da reparação no minuto 8:30 (§25); assume-se igual para construção nova. Alvo prioritário dos reis inimigos a partir do dia 15 (§10, EconomyCurve). Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `training_house` | `shadow_width` | 120 | 1 | O custo 10 é o da reparação no minuto 8:30 (§25); assume-se igual para construção nova. Alvo prioritário dos reis inimigos a partir do dia 15 (§10, EconomyCurve). Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `training_house` | `job_slots` | 1 | 1 | O custo 10 é o da reparação no minuto 8:30 (§25); assume-se igual para construção nova. Alvo prioritário dos reis inimigos a partir do dia 15 (§10, EconomyCurve). Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `forge` | `build_work` | 24 | 2 | Forja (oficina do ferreiro) ≠ Fundição (casa de conversão do minério) — ver Q-008. Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `forge` | `width_px` | 120 | 2 | Forja (oficina do ferreiro) ≠ Fundição (casa de conversão do minério) — ver Q-008. Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `forge` | `shadow_width` | 120 | 2 | Forja (oficina do ferreiro) ≠ Fundição (casa de conversão do minério) — ver Q-008. Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `forge` | `job_slots` | 1 | 2 | Forja (oficina do ferreiro) ≠ Fundição (casa de conversão do minério) — ver Q-008. Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `kitchen` | `build_work` | 20 | 2 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `kitchen` | `width_px` | 120 | 2 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `kitchen` | `shadow_width` | 120 | 2 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `kitchen` | `job_slots` | 1 | 2 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `farm` | `build_work` | 8 | 1 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `farm` | `width_px` | 96 | 1 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `farm` | `shadow_width` | 96 | 1 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `farm` | `job_slots` | 1 | 1 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `fishery` | `build_work` | 12 | 1 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `fishery` | `width_px` | 120 | 1 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `fishery` | `shadow_width` | 120 | 1 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `fishery` | `job_slots` | 1 | 1 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `henhouse` | `build_work` | 16 | 1 | 'Galinhas roubáveis à noite' (§06). Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `henhouse` | `width_px` | 96 | 1 | 'Galinhas roubáveis à noite' (§06). Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `henhouse` | `shadow_width` | 96 | 1 | 'Galinhas roubáveis à noite' (§06). Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `granary` | `build_work` | 20 | 2 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `granary` | `width_px` | 120 | 2 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `granary` | `shadow_width` | 120 | 2 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `archer_tower` | `build_work` | 36 | 1 | 2 postos elevados, +40% alcance, precisão ≈100% — do dossiê. Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `archer_tower` | `width_px` | 64 | 1 | 2 postos elevados, +40% alcance, precisão ≈100% — do dossiê. Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `archer_tower` | `shadow_width` | 64 | 1 | 2 postos elevados, +40% alcance, precisão ≈100% — do dossiê. Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `high_tower` | `build_work` | 60 | 1 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `high_tower` | `width_px` | 64 | 1 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `high_tower` | `shadow_width` | 64 | 1 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `high_tower` | `job_slots` | 2 | 1 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `fire_barrel` | `build_work` | 24 | 1 | Exceção à regra de vida: 20, porque tem de rebentar. aoe_damage 20 mata dois Rastejantes (vida 10) e fere um Bruto. Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `fire_barrel` | `width_px` | 32 | 1 | Exceção à regra de vida: 20, porque tem de rebentar. aoe_damage 20 mata dois Rastejantes (vida 10) e fere um Bruto. Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `fire_barrel` | `shadow_width` | 32 | 1 | Exceção à regra de vida: 20, porque tem de rebentar. aoe_damage 20 mata dois Rastejantes (vida 10) e fere um Bruto. Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| walls | `stakes` | `shadow_width` | 64 | 1 | Nível 1 é a base comum aos dois caminhos. Materiais de Horta e Fornalha propostos; os três primeiros são do §10. |
| walls | `stakes` | `material_by_people` | enramados:logs\|portuarios:stakes\|fenda:rock_shards\|horta:wattle\|fornalha:slag_chunks | 1 | Nível 1 é a base comum aos dois caminhos. Materiais de Horta e Fornalha propostos; os três primeiros são do §10. |
| walls | `palisade` | `shadow_width` | 64 | 1 | O §10 diz 'Madeira reforçada / gelo'; nenhum dos seis povos é de gelo — Q-010. Caminho A = 50% da vida do B. |
| walls | `stone_wall` | `shadow_width` | 64 | 2 | 'Pedra / basalto / coral' (§10) repartidos por povo: a atribuição é proposta. |
| walls | `stone_wall` | `material_by_people` | enramados:stone\|portuarios:coral\|fenda:stone\|horta:stone\|fornalha:basalt | 2 | 'Pedra / basalto / coral' (§10) repartidos por povo: a atribuição é proposta. |
| peoples | `enramados` | `playable_class` | archer | 1 | O povo da fatia vertical (§33). 'Madeira e caça' vira +25% na caça; arquétipo arqueiro porque dispara de cima. v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `enramados` | `starting_units` | monarch\|squire\|vagrant | 1 | O povo da fatia vertical (§33). 'Madeira e caça' vira +25% na caça; arquétipo arqueiro porque dispara de cima. v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| biomes | `ancient_forest` | `creature_table` | crawler\|winged\|brute\|burrower\|slime_ram\|devourer | 1 | A §07 tem uma tabela única: todos os biomas usam-na até haver criaturas por bioma. Fechado (§11). 'water' é o lago do castelo-árvore. |
| biomes | `ancient_forest` | `wildlife` | rabbit\|deer\|boar | 1 | A §07 tem uma tabela única: todos os biomas usam-na até haver criaturas por bioma. Fechado (§11). 'water' é o lago do castelo-árvore. |
| segments | `enramados_start_base_01` | `subject` | castle_tree | 1 | 'Um por região, ao centro. É o teu castelo-árvore.' |
| segments | `enramados_opening_00` | `subject` | castle_tree_ruin | 1 | Cena fixa, sempre igual, a mais afinada do jogo (§25). Substitui o start_base na primeira partida: 1 cavidade e 1 passagem do minuto 10:00. |
| segments | `enramados_empty_01` | `subject` | well | 1 | 'Nunca menos de 3 por região.' 2 a 3 edifícios por segmento (§21). |
| segments | `enramados_empty_02` | `subject` | broken_cart | 1 |  |
| segments | `enramados_empty_03` | `subject` | standing_stone | 1 |  |
| segments | `enramados_forest_01` | `subject` | fallen_giant | 1 | Define a especialidade económica disponível: corte de madeira e caça. |
| segments | `enramados_ruin_01` | `subject` | collapsed_arch | 1 | 'Traz uma passagem para o corte de solo.' |
| segments | `enramados_fortress_01` | `subject` | enemy_keep | 1 | 'Nunca duas adjacentes. Uma nas extremidades da região.' |
| segments | `enramados_edge_01` | `subject` | cliff | 1 | O tipo edge vem da lição do Chef RPG (§21), que pede um segmento dedicado; não está na tabela de pesos. |
| wildlife | `rabbit` | `per_segment_max` | 2 | 1 | Vida 4 = um só acerto de arqueiro (dano 4). |
| wildlife | `rabbit` | `shadow_width` | 10 | 1 | Vida 4 = um só acerto de arqueiro (dano 4). |
| wildlife | `deer` | `per_segment_max` | 1 | 1 | Vida 8 = dois acertos de arqueiro, como no Kingdom (§02). |
| wildlife | `deer` | `shadow_width` | 16 | 1 | Vida 8 = dois acertos de arqueiro, como no Kingdom (§02). |
| wildlife | `boar` | `per_segment_max` | 1 | 2 | Topo do intervalo da §06 (9). Carrega contra quem o caça: é o risco de 'sair das muralhas de dia'. |
| wildlife | `boar` | `shadow_width` | 24 | 2 | Topo do intervalo da §06 (9). Carrega contra quem o caça: é o risco de 'sair das muralhas de dia'. |

## 3 · Fases 3 a 8 — 330

| tabela | linha | campo | valor | fase | nota |
|---|---|---|---|---|---|
| units | `mercenary` | `recruit_cost` | 18 | 6 | O §07 diz custo 'variável'. 18 = custo marginal da dívida por mercenário (§14); +25% na tarde vem da EconomyCurve. |
| units | `mercenary` | `tags` | melee\|mercenary | 6 | O §07 diz custo 'variável'. 18 = custo marginal da dívida por mercenário (§14); +25% na tarde vem da EconomyCurve. |
| units | `mercenary` | `job_affinity` | wall:1.0\|guard:1.0 | 6 | O §07 diz custo 'variável'. 18 = custo marginal da dívida por mercenário (§14); +25% na tarde vem da EconomyCurve. |
| units | `mercenary` | `coin_capacity` | 5 | 6 | O §07 diz custo 'variável'. 18 = custo marginal da dívida por mercenário (§14); +25% na tarde vem da EconomyCurve. |
| units | `mercenary` | `head_pool` | helmet_horned\|scarf | 6 | O §07 diz custo 'variável'. 18 = custo marginal da dívida por mercenário (§14); +25% na tarde vem da EconomyCurve. |
| units | `diplomat` | `max_health` | 12 | 6 | Não combate (§08). Resultados e probabilidades na EconomyCurve (§14). |
| units | `diplomat` | `tags` | craft\|diplomat\|non_combatant | 6 | Não combate (§08). Resultados e probabilidades na EconomyCurve (§14). |
| units | `diplomat` | `job_affinity` | embassy:1.0 | 6 | Não combate (§08). Resultados e probabilidades na EconomyCurve (§14). |
| units | `diplomat` | `coin_capacity` | 2 | 6 | Não combate (§08). Resultados e probabilidades na EconomyCurve (§14). |
| units | `diplomat` | `head_pool` | hat_feather | 6 | Não combate (§08). Resultados e probabilidades na EconomyCurve (§14). |
| units | `bard` | `max_health` | 12 | 6 | O §09 dá o custo (18) sem edifício; propõe-se a Casa de Treino. É também classe jogável (classes.csv). |
| units | `bard` | `tags` | craft\|bard\|charm | 6 | O §09 dá o custo (18) sem edifício; propõe-se a Casa de Treino. É também classe jogável (classes.csv). |
| units | `bard` | `job_affinity` | perform:1.0 | 6 | O §09 dá o custo (18) sem edifício; propõe-se a Casa de Treino. É também classe jogável (classes.csv). |
| units | `bard` | `coin_capacity` | 2 | 6 | O §09 dá o custo (18) sem edifício; propõe-se a Casa de Treino. É também classe jogável (classes.csv). |
| units | `bard` | `head_pool` | hat_bard | 6 | O §09 dá o custo (18) sem edifício; propõe-se a Casa de Treino. É também classe jogável (classes.csv). |
| units | `bard` | `trained_at` | training_house | 6 | O §09 dá o custo (18) sem edifício; propõe-se a Casa de Treino. É também classe jogável (classes.csv). |
| units | `bard` | `ability_params` | radius:120\|duration:30 | 6 | O §09 dá o custo (18) sem edifício; propõe-se a Casa de Treino. É também classe jogável (classes.csv). |
| units | `climber` | `max_health` | 16 | 6 | Proposta ancorada no arqueiro (vida 14–16) com dano de lanceiro reduzido; é mobilidade, não linha. |
| units | `climber` | `damage` | 5 | 6 | Proposta ancorada no arqueiro (vida 14–16) com dano de lanceiro reduzido; é mobilidade, não linha. |
| units | `climber` | `attack_interval` | 1.0 | 6 | Proposta ancorada no arqueiro (vida 14–16) com dano de lanceiro reduzido; é mobilidade, não linha. |
| units | `climber` | `range_px` | 26 | 6 | Proposta ancorada no arqueiro (vida 14–16) com dano de lanceiro reduzido; é mobilidade, não linha. |
| units | `climber` | `targets_bands` | SURFACE\|AERIAL | 6 | Proposta ancorada no arqueiro (vida 14–16) com dano de lanceiro reduzido; é mobilidade, não linha. |
| units | `climber` | `recruit_cost` | 6 | 6 | Proposta ancorada no arqueiro (vida 14–16) com dano de lanceiro reduzido; é mobilidade, não linha. |
| units | `climber` | `move_speed` | 92 | 6 | Proposta ancorada no arqueiro (vida 14–16) com dano de lanceiro reduzido; é mobilidade, não linha. |
| units | `climber` | `tags` | agile\|climbs | 6 | Proposta ancorada no arqueiro (vida 14–16) com dano de lanceiro reduzido; é mobilidade, não linha. |
| units | `climber` | `job_affinity` | hunt:0.8\|wall:0.6 | 6 | Proposta ancorada no arqueiro (vida 14–16) com dano de lanceiro reduzido; é mobilidade, não linha. |
| units | `climber` | `coin_capacity` | 5 | 6 | Proposta ancorada no arqueiro (vida 14–16) com dano de lanceiro reduzido; é mobilidade, não linha. |
| units | `buried_knight` | `max_health` | 50 | 6 | rot_slow 0,25 = o do barril de fogo (§10), para não criar um terceiro valor de abrandamento. |
| units | `buried_knight` | `damage` | 9 | 6 | rot_slow 0,25 = o do barril de fogo (§10), para não criar um terceiro valor de abrandamento. |
| units | `buried_knight` | `attack_interval` | 1.3 | 6 | rot_slow 0,25 = o do barril de fogo (§10), para não criar um terceiro valor de abrandamento. |
| units | `buried_knight` | `move_speed` | 68 | 6 | rot_slow 0,25 = o do barril de fogo (§10), para não criar um terceiro valor de abrandamento. |
| units | `buried_knight` | `ability_params` | heal_per_second:2\|rot_slow:0.25\|radius:160 | 6 | rot_slow 0,25 = o do barril de fogo (§10), para não criar um terceiro valor de abrandamento. |
| units | `buried_knight` | `coin_capacity` | 0 | 6 | rot_slow 0,25 = o do barril de fogo (§10), para não criar um terceiro valor de abrandamento. |
| units | `sealed_knight` | `max_health` | 45 | 6 | Montado o alcance é 60 px (lança); cego cai para corpo-a-corpo, 28 px = o do lanceiro (§07). |
| units | `sealed_knight` | `damage` | 10 | 6 | Montado o alcance é 60 px (lança); cego cai para corpo-a-corpo, 28 px = o do lanceiro (§07). |
| units | `sealed_knight` | `attack_interval` | 1.2 | 6 | Montado o alcance é 60 px (lança); cego cai para corpo-a-corpo, 28 px = o do lanceiro (§07). |
| units | `sealed_knight` | `range_px` | 60 | 6 | Montado o alcance é 60 px (lança); cego cai para corpo-a-corpo, 28 px = o do lanceiro (§07). |
| units | `sealed_knight` | `coin_capacity` | 0 | 6 | Montado o alcance é 60 px (lança); cego cai para corpo-a-corpo, 28 px = o do lanceiro (§07). |
| units | `barge` | `max_health` | 60 | 7 | Veículo sem ataque; a capacidade de 6 é do dossiê. |
| units | `barge` | `damage` | 0 | 7 | Veículo sem ataque; a capacidade de 6 é do dossiê. |
| units | `barge` | `attack_interval` | 1.0 | 7 | Veículo sem ataque; a capacidade de 6 é do dossiê. |
| units | `barge` | `range_px` | 0 | 7 | Veículo sem ataque; a capacidade de 6 é do dossiê. |
| units | `barge` | `recruit_cost` | 14 | 7 | Veículo sem ataque; a capacidade de 6 é do dossiê. |
| units | `barge` | `move_speed` | 135 | 7 | Veículo sem ataque; a capacidade de 6 é do dossiê. |
| units | `barge` | `coin_capacity` | 5 | 7 | Veículo sem ataque; a capacidade de 6 é do dossiê. |
| units | `barge` | `ability_params` | capacity:6 | 7 | Veículo sem ataque; a capacidade de 6 é do dossiê. |
| units | `counterweight_ram` | `max_health` | 80 | 7 | Espelho aliado do Aríete de lodo (§07: dano 26, 2,0 s) com menos vida. |
| units | `counterweight_ram` | `damage` | 26 | 7 | Espelho aliado do Aríete de lodo (§07: dano 26, 2,0 s) com menos vida. |
| units | `counterweight_ram` | `attack_interval` | 2.0 | 7 | Espelho aliado do Aríete de lodo (§07: dano 26, 2,0 s) com menos vida. |
| units | `counterweight_ram` | `range_px` | 30 | 7 | Espelho aliado do Aríete de lodo (§07: dano 26, 2,0 s) com menos vida. |
| units | `counterweight_ram` | `recruit_cost` | 20 | 7 | Espelho aliado do Aríete de lodo (§07: dano 26, 2,0 s) com menos vida. |
| units | `counterweight_ram` | `move_speed` | 49 | 7 | Espelho aliado do Aríete de lodo (§07: dano 26, 2,0 s) com menos vida. |
| units | `counterweight_ram` | `coin_capacity` | 5 | 7 | Espelho aliado do Aríete de lodo (§07: dano 26, 2,0 s) com menos vida. |
| units | `counterweight_ram` | `ability_params` |  | 7 | Espelho aliado do Aríete de lodo (§07: dano 26, 2,0 s) com menos vida. |
| units | `sower` | `max_health` | 12 | 7 | root_seconds 3 = fosso de raízes (§10), para reutilizar a mesma regra. |
| units | `sower` | `damage` | 0 | 7 | root_seconds 3 = fosso de raízes (§10), para reutilizar a mesma regra. |
| units | `sower` | `attack_interval` | 1.0 | 7 | root_seconds 3 = fosso de raízes (§10), para reutilizar a mesma regra. |
| units | `sower` | `range_px` | 0 | 7 | root_seconds 3 = fosso de raízes (§10), para reutilizar a mesma regra. |
| units | `sower` | `recruit_cost` | 2 | 7 | root_seconds 3 = fosso de raízes (§10), para reutilizar a mesma regra. |
| units | `sower` | `move_speed` | 80 | 7 | root_seconds 3 = fosso de raízes (§10), para reutilizar a mesma regra. |
| units | `sower` | `coin_capacity` | 5 | 7 | root_seconds 3 = fosso de raízes (§10), para reutilizar a mesma regra. |
| units | `sower` | `ability_params` | plant_cost:1\|root_seconds:3 | 7 | root_seconds 3 = fosso de raízes (§10), para reutilizar a mesma regra. |
| units | `war_smith` | `max_health` | 24 | 7 | 3 HP/s repõe uma Estacaria (40) em ~13 s: segura uma brecha, não a torna invulnerável. |
| units | `war_smith` | `damage` | 4 | 7 | 3 HP/s repõe uma Estacaria (40) em ~13 s: segura uma brecha, não a torna invulnerável. |
| units | `war_smith` | `attack_interval` | 1.2 | 7 | 3 HP/s repõe uma Estacaria (40) em ~13 s: segura uma brecha, não a torna invulnerável. |
| units | `war_smith` | `range_px` | 28 | 7 | 3 HP/s repõe uma Estacaria (40) em ~13 s: segura uma brecha, não a torna invulnerável. |
| units | `war_smith` | `recruit_cost` | 10 | 7 | 3 HP/s repõe uma Estacaria (40) em ~13 s: segura uma brecha, não a torna invulnerável. |
| units | `war_smith` | `move_speed` | 80 | 7 | 3 HP/s repõe uma Estacaria (40) em ~13 s: segura uma brecha, não a torna invulnerável. |
| units | `war_smith` | `coin_capacity` | 5 | 7 | 3 HP/s repõe uma Estacaria (40) em ~13 s: segura uma brecha, não a torna invulnerável. |
| units | `war_smith` | `ability_params` | hp_per_second:3 | 7 | 3 HP/s repõe uma Estacaria (40) em ~13 s: segura uma brecha, não a torna invulnerável. |
| units | `digger` | `max_health` | 18 | 7 | A única tropa que cria PassageRec novos (§53). |
| units | `digger` | `damage` | 3 | 7 | A única tropa que cria PassageRec novos (§53). |
| units | `digger` | `attack_interval` | 1.2 | 7 | A única tropa que cria PassageRec novos (§53). |
| units | `digger` | `range_px` | 26 | 7 | A única tropa que cria PassageRec novos (§53). |
| units | `digger` | `recruit_cost` | 8 | 7 | A única tropa que cria PassageRec novos (§53). |
| units | `digger` | `move_speed` | 80 | 7 | A única tropa que cria PassageRec novos (§53). |
| units | `digger` | `coin_capacity` | 5 | 7 | A única tropa que cria PassageRec novos (§53). |
| units | `digger` | `ability_params` | dig_seconds:20 | 7 | A única tropa que cria PassageRec novos (§53). |
| creatures | `burrower` | `range_px` | 24 | 3 | 'Passa pela faixa subterrânea' (§07) e o poço de minério 'atrai Cavadores' (§06). Sobe à superfície por passagem. |
| creatures | `burrower` | `accuracy` | 1.0 | 3 | 'Passa pela faixa subterrânea' (§07) e o poço de minério 'atrai Cavadores' (§06). Sobe à superfície por passagem. |
| creatures | `burrower` | `scale_tier` | 2 | 3 | 'Passa pela faixa subterrânea' (§07) e o poço de minério 'atrai Cavadores' (§06). Sobe à superfície por passagem. |
| creatures | `burrower` | `shadow_width` | 18 | 3 | 'Passa pela faixa subterrânea' (§07) e o poço de minério 'atrai Cavadores' (§06). Sobe à superfície por passagem. |
| creatures | `burrower` | `tags` | rot\|burrows\|attracted_by_mine | 3 | 'Passa pela faixa subterrânea' (§07) e o poço de minério 'atrai Cavadores' (§06). Sobe à superfície por passagem. |
| creatures | `burrower` | `coin_drop` | 2 | 3 | 'Passa pela faixa subterrânea' (§07) e o poço de minério 'atrai Cavadores' (§06). Sobe à superfície por passagem. |
| creatures | `slime_ram` | `range_px` | 24 | 6 | Só ataca muralha. O TTK do arqueiro em campo dá 96,6 s, menos do que a noite (105 s): o teste do §31 falha com estes números — Q-001. |
| creatures | `slime_ram` | `accuracy` | 1.0 | 6 | Só ataca muralha. O TTK do arqueiro em campo dá 96,6 s, menos do que a noite (105 s): o teste do §31 falha com estes números — Q-001. |
| creatures | `slime_ram` | `scale_tier` | 3 | 6 | Só ataca muralha. O TTK do arqueiro em campo dá 96,6 s, menos do que a noite (105 s): o teste do §31 falha com estes números — Q-001. |
| creatures | `slime_ram` | `shadow_width` | 40 | 6 | Só ataca muralha. O TTK do arqueiro em campo dá 96,6 s, menos do que a noite (105 s): o teste do §31 falha com estes números — Q-001. |
| creatures | `slime_ram` | `tags` | rot\|siege | 6 | Só ataca muralha. O TTK do arqueiro em campo dá 96,6 s, menos do que a noite (105 s): o teste do §31 falha com estes números — Q-001. |
| creatures | `slime_ram` | `coin_drop` | 3 | 6 | Só ataca muralha. O TTK do arqueiro em campo dá 96,6 s, menos do que a noite (105 s): o teste do §31 falha com estes números — Q-001. |
| creatures | `devourer` | `range_px` | 40 | 6 | Alvo do Trepador evoluído (§08): 'climbable' é a tag que a habilidade procura. |
| creatures | `devourer` | `accuracy` | 1.0 | 6 | Alvo do Trepador evoluído (§08): 'climbable' é a tag que a habilidade procura. |
| creatures | `devourer` | `scale_tier` | 3 | 6 | Alvo do Trepador evoluído (§08): 'climbable' é a tag que a habilidade procura. |
| creatures | `devourer` | `shadow_width` | 56 | 6 | Alvo do Trepador evoluído (§08): 'climbable' é a tag que a habilidade procura. |
| creatures | `devourer` | `tags` | rot\|colossal\|climbable | 6 | Alvo do Trepador evoluído (§08): 'climbable' é a tag que a habilidade procura. |
| creatures | `devourer` | `coin_drop` | 6 | 6 | Alvo do Trepador evoluído (§08): 'climbable' é a tag que a habilidade procura. |
| creatures | `tender` | `move_speed` | 22 | 3 | O Zelador: aparece com a Dívida da Candeia em 6, anda atrás da mancha, não ataca e olha para o teu núcleo. Se lá chegar, leva uma tropa nomeada (§76). Pode ser afastado, não morto — por isso não tem massa nem dia mínimo. |
| creatures | `tender` | `scale_tier` | 3 | 3 | O Zelador: aparece com a Dívida da Candeia em 6, anda atrás da mancha, não ataca e olha para o teu núcleo. Se lá chegar, leva uma tropa nomeada (§76). Pode ser afastado, não morto — por isso não tem massa nem dia mínimo. |
| creatures | `tender` | `shadow_width` | 24 | 3 | O Zelador: aparece com a Dívida da Candeia em 6, anda atrás da mancha, não ataca e olha para o teu núcleo. Se lá chegar, leva uma tropa nomeada (§76). Pode ser afastado, não morto — por isso não tem massa nem dia mínimo. |
| creatures | `tender` | `layer_slots` | body\|face\|overlay | 3 | O Zelador: aparece com a Dívida da Candeia em 6, anda atrás da mancha, não ataca e olha para o teu núcleo. Se lá chegar, leva uma tropa nomeada (§76). Pode ser afastado, não morto — por isso não tem massa nem dia mínimo. |
| buildings | `embassy` | `cost` | 20 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `embassy` | `max_health` | 160 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `embassy` | `build_work` | 40 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `embassy` | `width_px` | 120 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `embassy` | `shadow_width` | 120 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `embassy` | `job_slots` | 1 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `heir_house` | `cost` | 20 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `heir_house` | `max_health` | 160 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `heir_house` | `build_work` | 40 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `heir_house` | `width_px` | 120 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `heir_house` | `shadow_width` | 120 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `root_sanctuary` | `cost` | 25 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `root_sanctuary` | `max_health` | 200 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `root_sanctuary` | `build_work` | 50 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `root_sanctuary` | `width_px` | 120 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `root_sanctuary` | `shadow_width` | 120 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `mount_stable` | `cost` | 20 | 6 | Separado do estábulo de vaca (§06) até decisão — Q-009. As 30 moedas são o preço do cavalo (mounts.csv). Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `mount_stable` | `max_health` | 160 | 6 | Separado do estábulo de vaca (§06) até decisão — Q-009. As 30 moedas são o preço do cavalo (mounts.csv). Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `mount_stable` | `build_work` | 40 | 6 | Separado do estábulo de vaca (§06) até decisão — Q-009. As 30 moedas são o preço do cavalo (mounts.csv). Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `mount_stable` | `width_px` | 160 | 6 | Separado do estábulo de vaca (§06) até decisão — Q-009. As 30 moedas são o preço do cavalo (mounts.csv). Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `mount_stable` | `shadow_width` | 160 | 6 | Separado do estábulo de vaca (§06) até decisão — Q-009. As 30 moedas são o preço do cavalo (mounts.csv). Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `cow_stable` | `max_health` | 112 | 6 | 'Ordenha manual — exige uma tropa parada' → job_slots 1, do dossiê. Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `cow_stable` | `build_work` | 28 | 6 | 'Ordenha manual — exige uma tropa parada' → job_slots 1, do dossiê. Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `cow_stable` | `width_px` | 160 | 6 | 'Ordenha manual — exige uma tropa parada' → job_slots 1, do dossiê. Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `cow_stable` | `shadow_width` | 160 | 6 | 'Ordenha manual — exige uma tropa parada' → job_slots 1, do dossiê. Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `lumber_camp` | `max_health` | 56 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `lumber_camp` | `build_work` | 14 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `lumber_camp` | `width_px` | 120 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `lumber_camp` | `shadow_width` | 120 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `lumber_camp` | `job_slots` | 1 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `ore_pit` | `max_health` | 96 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `ore_pit` | `build_work` | 24 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `ore_pit` | `width_px` | 120 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `ore_pit` | `shadow_width` | 120 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `ore_pit` | `job_slots` | 1 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `saltery` | `max_health` | 72 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `saltery` | `build_work` | 18 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `saltery` | `width_px` | 120 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `saltery` | `shadow_width` | 120 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `pen` | `max_health` | 88 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `pen` | `build_work` | 22 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `pen` | `width_px` | 120 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `pen` | `shadow_width` | 120 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `sawmill` | `max_health` | 104 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `sawmill` | `build_work` | 26 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `sawmill` | `width_px` | 120 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `sawmill` | `shadow_width` | 120 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `smelter` | `max_health` | 144 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `smelter` | `build_work` | 36 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `smelter` | `width_px` | 120 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `smelter` | `shadow_width` | 120 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `root_moat` | `max_health` | 176 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `root_moat` | `build_work` | 44 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `root_moat` | `width_px` | 96 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `root_moat` | `shadow_width` | 96 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `lighthouse` | `max_health` | 320 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `lighthouse` | `build_work` | 80 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `lighthouse` | `width_px` | 64 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `lighthouse` | `shadow_width` | 64 | 6 | Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `consecrated_altar` | `max_health` | 440 | 6 | O raio não está no dossiê: 320 px = meio segmento (§21). Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `consecrated_altar` | `build_work` | 110 | 6 | O raio não está no dossiê: 320 px = meio segmento (§21). Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `consecrated_altar` | `width_px` | 96 | 6 | O raio não está no dossiê: 320 px = meio segmento (§21). Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `consecrated_altar` | `shadow_width` | 96 | 6 | O raio não está no dossiê: 320 px = meio segmento (§21). Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| buildings | `consecrated_altar` | `effect_params` | rot_slow:0.4\|radius:320 | 6 | O raio não está no dossiê: 320 px = meio segmento (§21). Regra proposta: max_health = 8 × custo; build_work = 2 s × custo; shadow_width = largura (§22: a sombra escala com a largura) |
| walls | `iron_wall` | `max_health_a` | 225 | 6 | Fornalha: escória. Os outros povos só depois de conquistarem a Fornalha (§10). |
| walls | `iron_wall` | `guard_posts_b` | 2 | 6 | Fornalha: escória. Os outros povos só depois de conquistarem a Fornalha (§10). |
| walls | `iron_wall` | `shadow_width` | 64 | 6 | Fornalha: escória. Os outros povos só depois de conquistarem a Fornalha (§10). |
| walls | `bastion` | `max_health_a` | 450 | 6 | Único por império (§10). A fórmula base × 1,8^n dá 63, não 65 — a tabela manda (Q-002). |
| walls | `bastion` | `guard_posts_b` | 3 | 6 | Único por império (§10). A fórmula base × 1,8^n dá 63, não 65 — a tabela manda (Q-002). |
| walls | `bastion` | `shadow_width` | 64 | 6 | Único por império (§10). A fórmula base × 1,8^n dá 63, não 65 — a tabela manda (Q-002). |
| peoples | `portuarios` | `economy_modifiers` | night_income:1\|trade_route_income_mult:1.25 | 7 | 'O único que ganha moeda de noite' é do dossiê; o +25% no comércio é proposta. Trepador: sobe a mastros. v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `portuarios` | `playable_class` | climber | 7 | 'O único que ganha moeda de noite' é do dossiê; o +25% no comércio é proposta. Trepador: sobe a mastros. v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `portuarios` | `starting_units` | monarch\|squire\|vagrant | 7 | 'O único que ganha moeda de noite' é do dossiê; o +25% no comércio é proposta. Trepador: sobe a mastros. v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `portuarios` | `starting_buildings` | core\|fishery | 7 | 'O único que ganha moeda de noite' é do dossiê; o +25% no comércio é proposta. Trepador: sobe a mastros. v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `portuarios` | `song_texture` | Duas vozes e cavaquinho, ritmo de vira — Minho, romaria | 7 | 'O único que ganha moeda de noite' é do dossiê; o +25% no comércio é proposta. Trepador: sobe a mastros. v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `portuarios` | `colheita_song` | Depressa demais | 7 | 'O único que ganha moeda de noite' é do dossiê; o +25% no comércio é proposta. Trepador: sobe a mastros. v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `fenda` | `landmark` | carved_gate | 7 | 'Defesa quase impenetrável mas economia pobre' (§13). v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `fenda` | `economy_modifiers` | ore_yield_mult:1.5 | 7 | 'Defesa quase impenetrável mas economia pobre' (§13). v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `fenda` | `playable_class` | monarch | 7 | 'Defesa quase impenetrável mas economia pobre' (§13). v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `fenda` | `starting_units` | monarch\|squire\|vagrant | 7 | 'Defesa quase impenetrável mas economia pobre' (§13). v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `fenda` | `song_texture` | Uma nota longa de gaita-de-foles — Trás-os-Montes, gaita mirandesa | 7 | 'Defesa quase impenetrável mas economia pobre' (§13). v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `fenda` | `colheita_song` | A nota não acaba nunca | 7 | 'Defesa quase impenetrável mas economia pobre' (§13). v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `horta` | `landmark` | silo | 7 | 'O dobro de rendimento por canteiro' = farm_yield_mult 2,0, do dossiê. 'Tropas baratíssimas' fica para a lista de preços por povo (Q-007). v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `horta` | `playable_class` | bard | 7 | 'O dobro de rendimento por canteiro' = farm_yield_mult 2,0, do dossiê. 'Tropas baratíssimas' fica para a lista de preços por povo (Q-007). v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `horta` | `starting_units` | monarch\|squire\|vagrant\|vagrant | 7 | 'O dobro de rendimento por canteiro' = farm_yield_mult 2,0, do dossiê. 'Tropas baratíssimas' fica para a lista de preços por povo (Q-007). v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `horta` | `starting_buildings` | core\|farm | 7 | 'O dobro de rendimento por canteiro' = farm_yield_mult 2,0, do dossiê. 'Tropas baratíssimas' fica para a lista de preços por povo (Q-007). v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `horta` | `song_texture` | Ponto, alto e coro, sem instrumentos — Alentejo, cante | 7 | 'O dobro de rendimento por canteiro' = farm_yield_mult 2,0, do dossiê. 'Tropas baratíssimas' fica para a lista de preços por povo (Q-007). v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `horta` | `colheita_song` | Falta-lhes o ponto: cantam só o coro | 7 | 'O dobro de rendimento por canteiro' = farm_yield_mult 2,0, do dossiê. 'Tropas baratíssimas' fica para a lista de preços por povo (Q-007). v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `fornalha` | `economy_modifiers` | weapon_level_bonus:1 | 7 | 'Fogo permanente nas muralhas' é o traço de defesa. Muralha de ferro sem conquista prévia (§10). v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `fornalha` | `playable_class` | buried_knight | 7 | 'Fogo permanente nas muralhas' é o traço de defesa. Muralha de ferro sem conquista prévia (§10). v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `fornalha` | `starting_units` | monarch\|squire\|vagrant | 7 | 'Fogo permanente nas muralhas' é o traço de defesa. Muralha de ferro sem conquista prévia (§10). v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `fornalha` | `starting_buildings` | core\|forge | 7 | 'Fogo permanente nas muralhas' é o traço de defesa. Muralha de ferro sem conquista prévia (§10). v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `fornalha` | `song_texture` | Bombo, ferrinhos e martelo na bigorna — percussão de trabalho | 7 | 'Fogo permanente nas muralhas' é o traço de defesa. Muralha de ferro sem conquista prévia (§10). v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `fornalha` | `colheita_song` | Certinho. Certinho demais. | 7 | 'Fogo permanente nas muralhas' é o traço de defesa. Muralha de ferro sem conquista prévia (§10). v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `sobraiz` | `landmark` | shaft | 7 | Sem muralhas — labirinto (§04, §10). Selado porque 'já não usava os olhos' (Sulco Cego, §17). v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `sobraiz` | `economy_modifiers` | secret_find_mult:2.0 | 7 | Sem muralhas — labirinto (§04, §10). Selado porque 'já não usava os olhos' (Sulco Cego, §17). v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `sobraiz` | `playable_class` | sealed_knight | 7 | Sem muralhas — labirinto (§04, §10). Selado porque 'já não usava os olhos' (Sulco Cego, §17). v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `sobraiz` | `starting_units` | monarch\|squire\|vagrant | 7 | Sem muralhas — labirinto (§04, §10). Selado porque 'já não usava os olhos' (Sulco Cego, §17). v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `sobraiz` | `song_texture` | Viola campaniça desafinada e uma voz que não chega à nota — Baixo Alentejo | 7 | Sem muralhas — labirinto (§04, §10). Selado porque 'já não usava os olhos' (Sulco Cego, §17). v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| peoples | `sobraiz` | `colheita_song` | Não cantam. Em Colheita, nunca cantaram. | 7 | Sem muralhas — labirinto (§04, §10). Selado porque 'já não usava os olhos' (Sulco Cego, §17). v6: a canção é a do §81; o marco cria raiz quando ficas com o povo (§78) — vira Amargueiro de 22 de massa e não se corta. |
| classes | `bard` | `phase1_params` | max_target_health:14\|duration:30\|speed_boost:0.1 | 6 | 'Fracos' = vida ≤ 14: Rastejante e Alado (§07). A condição 15 é do dossiê. |
| classes | `climber` | `phase2_params` | duration:20\|max_target_health_ratio:0.2 | 6 | 'Quase mortas' = 20% de vida (proposta); os 20 s são do dossiê. |
| classes | `climber` | `evolve_condition` | climbs | 6 | 'Quase mortas' = 20% de vida (proposta); os 20 s são do dossiê. |
| classes | `climber` | `evolve_condition_value` | 20 | 6 | 'Quase mortas' = 20% de vida (proposta); os 20 s são do dossiê. |
| classes | `buried_knight` | `unlock_seed_cost` | 2 | 6 | A segunda fase não está no dossiê — proposta: o bosque que cria dobra de raio. |
| classes | `buried_knight` | `phase2_ability` | sit_heal_grove | 6 | A segunda fase não está no dossiê — proposta: o bosque que cria dobra de raio. |
| classes | `buried_knight` | `phase2_params` | grove_radius_mult:2 | 6 | A segunda fase não está no dossiê — proposta: o bosque que cria dobra de raio. |
| classes | `buried_knight` | `evolve_condition` | sit_heals | 6 | A segunda fase não está no dossiê — proposta: o bosque que cria dobra de raio. |
| classes | `buried_knight` | `evolve_condition_value` | 10 | 6 | A segunda fase não está no dossiê — proposta: o bosque que cria dobra de raio. |
| classes | `sealed_knight` | `unlock_seed_cost` | 2 | 6 | Segunda fase proposta: a montaria recupera num dia e a cegueira pesa metade. |
| classes | `sealed_knight` | `phase2_ability` | mount_bond | 6 | Segunda fase proposta: a montaria recupera num dia e a cegueira pesa metade. |
| classes | `sealed_knight` | `phase2_params` | mount_heal_days:1\|blind_vignette_mult:0.5 | 6 | Segunda fase proposta: a montaria recupera num dia e a cegueira pesa metade. |
| classes | `sealed_knight` | `evolve_condition` | mounted_kills | 6 | Segunda fase proposta: a montaria recupera num dia e a cegueira pesa metade. |
| classes | `sealed_knight` | `evolve_condition_value` | 20 | 6 | Segunda fase proposta: a montaria recupera num dia e a cegueira pesa metade. |
| classes | `diplomat` | `unlock_seed_cost` | 2 | 6 | Números da fase 2 do dossiê; a condição de feito é proposta. |
| classes | `diplomat` | `evolve_condition` | missions_returned | 6 | Números da fase 2 do dossiê; a condição de feito é proposta. |
| classes | `diplomat` | `evolve_condition_value` | 3 | 6 | Números da fase 2 do dossiê; a condição de feito é proposta. |
| crafts | `fish_saltery` | `cost` | 1 | 6 | '+50%, e o peixe deixa de estragar' — o estrago não tem regra no dossiê (Q-012). |
| crafts | `fish_saltery` | `magnitude` | 0.1 | 6 | '+50%, e o peixe deixa de estragar' — o estrago não tem regra no dossiê (Q-012). |
| crafts | `fish_saltery` | `duration` | 0 | 6 | '+50%, e o peixe deixa de estragar' — o estrago não tem regra no dossiê (Q-012). |
| crafts | `animal_pen` | `cost` | 1 | 6 | coin_multiplier 1,0: no animal, 'moeda agora' é o rendimento passivo, não +50%. Prato = +30% de dano (proposta). |
| crafts | `animal_pen` | `magnitude` | 0.3 | 6 | coin_multiplier 1,0: no animal, 'moeda agora' é o rendimento passivo, não +50%. Prato = +30% de dano (proposta). |
| crafts | `wood_sawmill` | `cost` | 1 | 6 |  |
| crafts | `wood_sawmill` | `duration` | 0 | 6 |  |
| crafts | `ore_smelter` | `cost` | 1 | 6 |  |
| crafts | `ore_smelter` | `duration` | 0 | 6 |  |
| jobs | `embassy` | `priority` | 0.8 | 6 |  |
| jobs | `embassy` | `dawn` | 1.0 | 6 |  |
| jobs | `embassy` | `morning` | 1.0 | 6 |  |
| jobs | `embassy` | `noon` | 1.0 | 6 |  |
| jobs | `embassy` | `afternoon` | 1.0 | 6 |  |
| jobs | `embassy` | `dusk` | 0.0 | 6 |  |
| jobs | `embassy` | `night` | 0.0 | 6 |  |
| jobs | `milking` | `priority` | 0.9 | 6 |  |
| jobs | `milking` | `dawn` | 1.0 | 6 |  |
| jobs | `milking` | `morning` | 1.0 | 6 |  |
| jobs | `milking` | `noon` | 1.0 | 6 |  |
| jobs | `milking` | `afternoon` | 1.0 | 6 |  |
| jobs | `milking` | `dusk` | 0.0 | 6 |  |
| jobs | `milking` | `night` | 0.0 | 6 |  |
| jobs | `cart` | `priority` | 0.9 | 6 |  |
| jobs | `cart` | `dawn` | 1.0 | 6 |  |
| jobs | `cart` | `morning` | 1.0 | 6 |  |
| jobs | `cart` | `noon` | 1.0 | 6 |  |
| jobs | `cart` | `afternoon` | 0.8 | 6 |  |
| jobs | `cart` | `dusk` | 0.0 | 6 |  |
| jobs | `cart` | `night` | 0.0 | 6 |  |
| jobs | `perform` | `priority` | 0.6 | 6 |  |
| jobs | `perform` | `dawn` | 1.0 | 6 |  |
| jobs | `perform` | `morning` | 1.0 | 6 |  |
| jobs | `perform` | `noon` | 1.0 | 6 |  |
| jobs | `perform` | `afternoon` | 1.0 | 6 |  |
| jobs | `perform` | `dusk` | 0.5 | 6 |  |
| jobs | `perform` | `night` | 0.5 | 6 |  |
| biomes | `coast` | `creature_table` | crawler\|winged\|brute\|burrower\|slime_ram\|devourer | 7 | A §07 tem uma tabela única: todos os biomas usam-na até haver criaturas por bioma. |
| biomes | `coast` | `wildlife` | rabbit | 7 | A §07 tem uma tabela única: todos os biomas usam-na até haver criaturas por bioma. |
| biomes | `canyon` | `creature_table` | crawler\|winged\|brute\|burrower\|slime_ram\|devourer | 7 | A §07 tem uma tabela única: todos os biomas usam-na até haver criaturas por bioma. |
| biomes | `canyon` | `wildlife` | rabbit | 7 | A §07 tem uma tabela única: todos os biomas usam-na até haver criaturas por bioma. |
| biomes | `floodplain` | `creature_table` | crawler\|winged\|brute\|burrower\|slime_ram\|devourer | 7 | A §07 tem uma tabela única: todos os biomas usam-na até haver criaturas por bioma. |
| biomes | `floodplain` | `wildlife` | rabbit\|deer | 7 | A §07 tem uma tabela única: todos os biomas usam-na até haver criaturas por bioma. |
| biomes | `floodplain` | `resources` | fertile\|water | 7 | A §07 tem uma tabela única: todos os biomas usam-na até haver criaturas por bioma. |
| biomes | `volcanic` | `creature_table` | crawler\|winged\|brute\|burrower\|slime_ram\|devourer | 7 | A §07 tem uma tabela única: todos os biomas usam-na até haver criaturas por bioma. O §11 não classifica a Fornalha; proposto aberto. |
| biomes | `volcanic` | `atmosphere_preset` | open | 7 | A §07 tem uma tabela única: todos os biomas usam-na até haver criaturas por bioma. O §11 não classifica a Fornalha; proposto aberto. |
| biomes | `volcanic` | `parallax_preset` | open | 7 | A §07 tem uma tabela única: todos os biomas usam-na até haver criaturas por bioma. O §11 não classifica a Fornalha; proposto aberto. |
| biomes | `subterranean` | `creature_table` | crawler\|winged\|brute\|burrower\|slime_ram\|devourer | 7 | A §07 tem uma tabela única: todos os biomas usam-na até haver criaturas por bioma. |
| biomes | `subterranean` | `resources` | fungi | 7 | A §07 tem uma tabela única: todos os biomas usam-na até haver criaturas por bioma. |
| economy | `coin_pickup_px` | `coin_pickup_px` | 12 | 9 | Proposta: a apanha é por distância, não por colisão. A medir no F1-01. |
| economy | `coin_gravity_px_s2` | `coin_gravity_px_s2` | 700 | 9 | Proposta: o dossiê diz que a moeda é física e não diz com que física. 700 px/s² com o impulso abaixo dá um arco de 23 px em contínuo — cerca de 20 px a 30 Hz, que é o que se vê — e meio segundo de voo — alto o bastante para se ver por cima de uma tropa, curto o bastante para não se esperar por ele. Q-061; a medir no F1-01. |
| economy | `coin_drop_speed_px_s` | `coin_drop_speed_px_s` | 180 | 9 | Proposta: impulso vertical ao largar. Com a gravidade acima: ápice 23 px em contínuo, ~20 px medidos a 30 Hz, voo 0,51 s. Q-061. |
| economy | `coin_drop_spread_px_s` | `coin_drop_spread_px_s` | 40 | 9 | Proposta: dispersão horizontal máxima ao largar, em px/s. Sobre 0,51 s de voo dá ±20 px de espalhamento — mais do que o raio de apanha de 12, para que duas moedas largadas juntas não se apanhem como uma. Q-061. |
| economy | `coin_drop_repeat_s` | `coin_drop_repeat_s` | 0.12 | 9 | Proposta: o §24 manda largar em contínuo e não diz a que ritmo. 0,12 s dão pouco mais de oito moedas por segundo — depressa o bastante para encher uma obra sem martelar a tecla, devagar o bastante para se ver cada moeda a cair e para se parar a tempo. O Bastião de 65 sai em 8 s de tecla premida em vez de 65 toques. Ver Q-083. |
| economy | `recruit_notice_px` | `recruit_notice_px` | 120 | 9 | Proposta: «perto» não tem número no dossiê. 120 é o limite exterior da fila do §50 — a distância a que o jogo já diz que alguém pertence a um sítio. Ver Q-063. |
| economy | `follow_distance_px` | `follow_distance_px` | 30 | 9 | Proposta ancorada no queue_min_px do §50 (30): é a mesma pergunta — a que distância uma pessoa espera por outra. Ver Q-063. |
| economy | `follow_spacing_px` | `follow_spacing_px` | 18 | 9 | Proposta ancorada no queue_spacing_px do §50 (18), para o jogo ter UMA regra de espaçamento e não duas. Ver Q-063. |
| economy_profiles | `two_routes` | `expect_suffocation` | 14\|16 | 6 | O modelo dá o dia 15 (11 + 4). O intervalo ±1 é proposta. |
| mounts | `dragonfly_mount` | `obtain_ref` | horta | 6 | O §12 diz 'Fortaleza do pântano', mas nenhum dos seis povos vive num pântano — Q-013. Proposta: a Horta (várzea). |
| impulses | `forced_harvest` | `coin_cost` | 12 | 6 | coin_cost 12 ≈ o rendimento líquido do dia 1 no perfil equilibrado (12,3). O dossiê implica um custo ('os impulsos custam metade' para o tirano) sem o dar — Q-014. |
| impulses | `forced_harvest` | `icon` | sickle | 6 | coin_cost 12 ≈ o rendimento líquido do dia 1 no perfil equilibrado (12,3). O dossiê implica um custo ('os impulsos custam metade' para o tirano) sem o dar — Q-014. |
| impulses | `call_to_arms` | `coin_cost` | 12 | 6 | coin_cost 12 ≈ o rendimento líquido do dia 1 no perfil equilibrado (12,3). O dossiê implica um custo ('os impulsos custam metade' para o tirano) sem o dar — Q-014. |
| impulses | `call_to_arms` | `icon` | horn | 6 | coin_cost 12 ≈ o rendimento líquido do dia 1 no perfil equilibrado (12,3). O dossiê implica um custo ('os impulsos custam metade' para o tirano) sem o dar — Q-014. |
| impulses | `free_fair` | `coin_cost` | 12 | 6 | coin_cost 12 ≈ o rendimento líquido do dia 1 no perfil equilibrado (12,3). O dossiê implica um custo ('os impulsos custam metade' para o tirano) sem o dar — Q-014. Ganância +15 permanente. |
| impulses | `free_fair` | `icon` | scales | 6 | coin_cost 12 ≈ o rendimento líquido do dia 1 no perfil equilibrado (12,3). O dossiê implica um custo ('os impulsos custam metade' para o tirano) sem o dar — Q-014. Ganância +15 permanente. |
| impulses | `protected_route` | `coin_cost` | 12 | 6 | coin_cost 12 ≈ o rendimento líquido do dia 1 no perfil equilibrado (12,3). O dossiê implica um custo ('os impulsos custam metade' para o tirano) sem o dar — Q-014. Carroças imunes a assalto hoje. |
| impulses | `protected_route` | `icon` | shield_road | 6 | coin_cost 12 ≈ o rendimento líquido do dia 1 no perfil equilibrado (12,3). O dossiê implica um custo ('os impulsos custam metade' para o tirano) sem o dar — Q-014. Carroças imunes a assalto hoje. |
| impulses | `vigil` | `coin_cost` | 12 | 6 | coin_cost 12 ≈ o rendimento líquido do dia 1 no perfil equilibrado (12,3). O dossiê implica um custo ('os impulsos custam metade' para o tirano) sem o dar — Q-014. |
| impulses | `vigil` | `icon` | candle | 6 | coin_cost 12 ≈ o rendimento líquido do dia 1 no perfil equilibrado (12,3). O dossiê implica um custo ('os impulsos custam metade' para o tirano) sem o dar — Q-014. |
| impulses | `royal_pardon` | `coin_cost` | 12 | 6 | coin_cost 12 ≈ o rendimento líquido do dia 1 no perfil equilibrado (12,3). O dossiê implica um custo ('os impulsos custam metade' para o tirano) sem o dar — Q-014. |
| impulses | `royal_pardon` | `icon` | seal | 6 | coin_cost 12 ≈ o rendimento líquido do dia 1 no perfil equilibrado (12,3). O dossiê implica um custo ('os impulsos custam metade' para o tirano) sem o dar — Q-014. |
| greed_profiles | `austere` | `enemy_wall_bias` | 1.4 | 6 | 'Muralhas fortes, poucas elites. Ataca com Berserkers.' |
| greed_profiles | `austere` | `enemy_elite_bias` | 0.6 | 6 | 'Muralhas fortes, poucas elites. Ataca com Berserkers.' |
| greed_profiles | `lavish` | `enemy_elite_bias` | 1.4 | 6 | Fastuoso: +1 tropa de elite grátis a cada 3 dias. Qual é a tropa de elite — Q-015. |
| greed_profiles | `tyrant` | `enemy_wall_bias` | 0.5 | 6 | 'Muralhas fracas, tropas de elite. Cerco rápido com aríete.' O 0,45 do §20 (fortify) está na EconomyCurve. |
| greed_profiles | `tyrant` | `enemy_elite_bias` | 1.5 | 6 | 'Muralhas fracas, tropas de elite. Cerco rápido com aríete.' O 0,45 do §20 (fortify) está na EconomyCurve. |
| greed_profiles | `tyrant` | `enemy_attack_unit` | counterweight_ram | 6 | 'Muralhas fracas, tropas de elite. Cerco rápido com aríete.' O 0,45 do §20 (fortify) está na EconomyCurve. |
| secrets | `buried_statue` | `teaches` | weapons | 3 | Tutorial. 'A estátua do Ferreiro ensina o sistema de armas' — as outras estátuas são uma por mecânica (Q-016). |
| companions | `sniffer` | `rule_params` | radius:320 | 6 | O Healing Frog (§01) é o primeiro candidato: cura pouco, todos os dias (§08 'a cura vem do companheiro'). |
| companions | `sniffer` | `heal_per_day` | 2 | 6 | O Healing Frog (§01) é o primeiro candidato: cura pouco, todos os dias (§08 'a cura vem do companheiro'). |
| companions | `sniffer` | `growth_stages` | 3 | 6 | O Healing Frog (§01) é o primeiro candidato: cura pouco, todos os dias (§08 'a cura vem do companheiro'). |
| companions | `sniffer` | `food` | grain\|fish | 6 | O Healing Frog (§01) é o primeiro candidato: cura pouco, todos os dias (§08 'a cura vem do companheiro'). |
| companions | `herald` | `rule_params` | seconds_before_dusk:30 | 6 | 30 s antes do crepúsculo = a duração do próprio crepúsculo (§05). |
| companions | `herald` | `heal_per_day` | 2 | 6 | 30 s antes do crepúsculo = a duração do próprio crepúsculo (§05). |
| companions | `herald` | `growth_stages` | 3 | 6 | 30 s antes do crepúsculo = a duração do próprio crepúsculo (§05). |
| companions | `herald` | `food` | grain\|animal | 6 | 30 s antes do crepúsculo = a duração do próprio crepúsculo (§05). |
| companions | `magpie` | `rule_params` | radius:200 | 6 |  |
| companions | `magpie` | `heal_per_day` | 2 | 6 |  |
| companions | `magpie` | `growth_stages` | 3 | 6 |  |
| companions | `magpie` | `food` | fish\|animal | 6 |  |
| offers | `all_that_shines` | `once_per_campaign` | true | 3 | 'O que brilha, e nada mais.' A noite é saltada. Q-040: uma vez por campanha — saltar duas ensina a evitar o jogo. |
| offers | `keep_the_lantern` | `price_kind` | playable_class | 3 | 'Fica com a candeia por uma noite.' Preco: uma classe jogavel (§08) perdida para sempre. Efeito: controlas a mancha esta noite e mandas-la a um imperio rival. Ver Q-053: a §75 poe 'Uma classe jogavel, para sempre' na coluna Preco e a leitura como perda e a unica coerente. |
| titles | `the_one_who_stayed` | `ribbon_color` | #C9A227 | 4 | 'Aguentou' — 5 noites vivo em posto de cerco. +1 de vida máxima. |
| titles | `she_who_held_the_gate` | `ribbon_color` | #B9663A | 4 | 'Último na porta' — único sobrevivente de um portão atacado. Ignora a regra de fuga da §07. |
| titles | `the_one_who_broke_stone` | `ribbon_color` | #8A8F7A | 4 | 'Partiu o cerco' — golpe final num Aríete de lodo. +2 de dano contra siege. |
| titles | `the_counter` | `ribbon_color` | #59386B | 4 | 'Contou' — 10 Rastejantes abatidos. +10% de cadência. |
| titles | `the_one_who_brought_the_others` | `ribbon_color` | #6E8B3D | 4 | 'Trouxe os outros' — arrastou 3 corpos para dentro antes da alvorada (§74). Arrasta ao dobro. |
| titles | `she_who_spoke_with_her` | `ribbon_color` | #F6D89B | 4 | 'Falou com ela' — esteve dentro da mancha e saiu viva. Vê o raio da candeia como zona segura. |
| titles | `the_dry_one` | `ribbon_color` | #D8C9A3 | 4 | 'Não comeu' — 7 dias sem passar pela cozinha. Metade do consumo. |
| titles | `she_who_came_back` | `ribbon_color` | #7FA6A1 | 4 | 'Voltou' — ressuscitada no Santuário das Raízes (§16). Imune ao encantamento do Bardo inimigo. |
| titles | `the_one_with_the_same_spear` | `ribbon_color` | #A35A2A | 4 | 'Não largou' — manteve a mesma arma 10 dias. A arma sobe um nível. |
| chapters | `crossroad_souls` | `detour_seconds` | 25 | 5 | Deixa uma moeda no nicho e as almas apontam por onde vem a Podridão; tira uma e as leituras de estrada mentem três dias. É o único sem canção: o silêncio é a lei a funcionar. |
| chapters | `stopped_pilgrimage` | `detour_seconds` | 40 | 5 | Atravessar a pé custa o dobro; uma moeda no andor leva-te em 8 s, e as tropas andam ao passo dela um dia (−20%). O tema nunca cadencia. |
| chapters | `house_that_counts` | `detour_seconds` | 25 | 5 | À terceira passagem fica com um nome teu; dá-lhe um à primeira e diz-te a massa exata todas as noites. |
| chapters | `inverted_floodplain` | `detour_seconds` | 40 | 5 | As faixas trocam e a Podridão chega por cima: é o único sítio onde se vê a candeia de baixo. Vem da §17. |
| chapters | `blind_furrow` | `detour_seconds` | 40 | 5 | Não há luz: só o Cavaleiro Selado se orienta. Qualquer luz revela 60 px e acrescenta +30 à massa desta noite. Vem da §17, com o custo que lhe faltava. |
| chapters | `blind_furrow` | `folk_root` | vozes sem corpo | 5 | Não há luz: só o Cavaleiro Selado se orienta. Qualquer luz revela 60 px e acrescenta +30 à massa desta noite. Vem da §17, com o custo que lhe faltava. |
| chapters | `lit_oven` | `detour_seconds` | 25 | 5 | Cura por completo e sai com uma brasa: arde seis dias e ao sétimo cria raiz onde estiver, muralhas incluídas. É a única lei que entra em casa, e é de propósito (D-10). |
| chapters | `bone_market` | `detour_seconds` | 25 | 5 | Mercenários a metade, dívida ao dobro (§14); não se sai da praça com dívida por pagar. Sete vendedores; quem esvaziar a praça encontra a cadeira do Dono. |
| chapters | `spore_field` | `detour_seconds` | 40 | 5 | As tropas ganham 20% de dano e perdem 15% de vida por dia. Os chapéus dos cogumelos são telhados: a cidade Sob-Raiz está por baixo, intacta (§79). |
| chapters | `bridge_of_returners` | `detour_seconds` | 40 | 5 | Atravessar custa uma memória: uma região revelada volta a ficar escura. À sexta travessia dá-te um nome e muda o material de um segmento de muralha. |
| chapters | `endless_siege` | `detour_seconds` | 40 | 5 | Entras e ficas numa noite que não acaba: partes a muralha, ou abres o portão por dentro. São os dois epílogos em miniatura, e é por isso que carrega sempre o diário 12 (D-11). |
| chapters | `endless_siege` | `folk_root` | cerco sem fim | 5 | Entras e ficas numa noite que não acaba: partes a muralha, ou abres o portão por dentro. São os dois epílogos em miniatura, e é por isso que carrega sempre o diário 12 (D-11). |

