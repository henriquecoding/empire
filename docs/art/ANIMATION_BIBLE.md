# Animation Bible — o mesmo ritmo para todas as personagens

> O dossiê fixa quatro animações (§22, §58): **`idle` 6 frames · `walk` 8 · `attack` 5 · `die` 7, a 10 fps**,
> e o *idle* de 6 frames que já desenhaste é a referência de ritmo. Este documento acrescenta o resto — os estados
> que o relatório mestre pede, os frames de ação, os pés, os *sockets* — para que nenhuma personagem ganhe um
> ritmo seu. Valores do dossiê marcados **(§)**; o resto é proposta, para o primeiro corpo animado confirmar.

## 1 · Regras que valem para tudo

| Regra | Especificação |
|---|---|
| Cadência | **10 fps** em todas as animações de personagem e criatura (§22). Um frame = 100 ms |
| Referência | O `idle` de 6 frames do `Empire troop` (650 ms por ciclo: 100/100/100/100/150/100 ms) é o metrónomo: um passo, um golpe, uma respiração medem-se contra ele |
| No sítio | **Todas as animações são no sítio.** A posição vem da simulação (`move_speed`), nunca da animação. Exceções: *knockback* de 3 px (§24) e a queda da morte — ambos só visuais |
| Pivot | O ponto de contacto dos pés (ASSET_BIBLE §1). Não muda entre frames nem entre tags |
| Sem subpíxel | Todos os deslocamentos de frame são inteiros; a câmara anda em píxeis inteiros; o parallax faz `floor()` (invariante I8) |
| Desfasamento | Cada unidade começa o `idle` num frame aleatório do fluxo `visual` — 300 aldeões não respiram em uníssono (§58) |
| Fora do ecrã | Continua a simular, pára de animar (§58) |
| Estado → tag | O `UnitView` escolhe a tag a partir de `UnitRec.state`; o estado de animação **nunca** é guardado (§45) |

### Travamento dos pés (*foot locking*)

O passo tem de acompanhar a velocidade atual em `data/source/units.csv`. O monarca usa 80 px/s (ADR 0021): num ciclo proposto de 0,8 s com dois passos, cada passo corresponde a 32 px. Isto é uma referência para desenhar o walk, não autorização para acelerar o idle. Os exports conservam as durações originais; fontes de um só frame ficam explicitamente estáticas.

### Antecipação sem adivinhar

A simulação decide o golpe (§50) e emite `attack_launched` com `hit` já resolvido; a apresentação nunca decide.
A apresentação reage a `attack_launched`. Um cooldown baixo não garante que haverá ataque: o alvo pode sair de alcance. Enquanto não existir um contrato de antecipação, não prometer que uma animação prévia terminará sempre num golpe. O hit reage ao dano sem esperar a fronteira da tag.

### *Squash & stretch*

Permitido em moedas (o *bounce* da moeda largada — a animação mais importante do jogo, §24), impactos, saltos de
criaturas e na mancha da Podridão. **Proibido na cabeça e no rosto das personagens**: o humor está na cara (§01) e
a cara não se deforma.

## 2 · Os estados

### Obrigatórios para todo o corpo-base (escalas 1–3)

| Tag | Frames | fps | Duração | Tipo | Antecipação | Ação | Recuperação | Pés | Som |
|---|---|---|---|---|---|---|---|---|---|
| `idle` original | **6** | variável | 0,65 s | loop | — | — | — | plantados | — |
| `walk` | **8 (§)** | 10 | 0,8 s | loop | — | contacto em 1 e 5 | — | ciclo, passo ≈ 10 px | `sfx_step` em 1 e 5 |
| `attack` | **5 (§)** | 10 | 0,5 s | uma vez | 1–2 | **3** | 4–5 | plantados | `sfx_attack_<arma>` no 3 |
| `die` | **7 (§)** | 10 | 0,7 s | uma vez, fica no 7 | — | 3 (queda) | — | — | `sfx_death` no 1 |
| `hit` | 2 | 10 | 0,2 s | uma vez | — | 1 | 2 | plantados | `sfx_hit` no 1 |
| `run` | 6 | 12 | 0,5 s | loop | — | contacto em 1 e 4 | — | ciclo | `sfx_step` em 1 e 4 |
| `work` | 6 | 10 | 0,6 s | loop | 1–2 | 3 | 4–6 | plantados | depende do posto |
| `carry` | 8 | 10 | 0,8 s | loop | — | contacto em 1 e 5 | — | ciclo | `sfx_step` |
| `flee` | 6 | 12 | 0,5 s | loop | — | — | — | ciclo | — |
| `interact` | 4 | 10 | 0,4 s | uma vez | 1 | 3 | 4 | plantados | `sfx_interact` no 3 |
| `celebrate` | 6 | 10 | 0,6 s | loop curto | — | 3 | — | salto de 2 px | — |
| `sleep` | 4 | 5 | 0,8 s | loop | — | — | — | deitado | — |

A última frame de `die` é o **corpo** que fica no mapa até ao amanhecer (§16) — desenha-a para se ler como
ressuscitável, não como mancha.

### Quando o papel o pede

| Tag | Quem | Frames | Ação | Evento / *socket* |
|---|---|---|---|---|
| `shoot` | arqueiros | 5 | 3 (solta) | projétil nasce no `socket_weapon` no frame 3 |
| `reload` | arqueiros | 3 | — | encadeia com `shoot` quando o intervalo > 0,8 s |
| `cast` | bardo, maestro | 6 | 4 | `socket_fx` (encantamento) no frame 4 |
| `block` | lanceiro, escudo | 3 | 2 | — |
| `charge` | berserker, javali | 4 loop | — | *screen shake* **não** (só muralha e aríete, §24) |
| `dig` | escavador, cavador | 6 | 3 e 6 | `fx_dust` no chão |
| `build` | construtor | 6 | 3 | `sfx_hammer` no 3 |
| `harvest` | plantação, semeador | 6 | 4 | — |
| `cook` | cozinheiro | 6 | 4 | `socket_fx` (vapor) |
| `smith` | ferreiro | 6 | 3 | `fx_sparks` no `socket_weapon` |
| `heal` | cavaleiro enterrado (sentado) | 8 loop | — | vegetação nasce à volta (§08) — é efeito, não frames |
| `ride` | cavaleiro selado, montarias | 8 loop | — | corpo + montaria no mesmo `body` |
| `climb` | trepador, lagarto | 6 loop | — | movimento vertical vem da simulação |

### *Sockets*

Pontos marcados em cada frame, exportados no JSON como uma camada `socket_*` de um píxel (não se desenha nada lá):

| Socket | Para quê |
|---|---|
| `socket_weapon` | Onde nascem projéteis e faíscas; ponta da arma no frame de ação |
| `socket_fx` | Buffs, encantamento, vapor, notas do bardo |
| `socket_head` | Onde pousa o `overlay` de marca, ferido, apodrecido |
| `socket_carry` | Onde vai a moeda ou o objeto transportado |

## 3 · Variantes por equipamento

- Cabeça, rosto, arma e escudo são camadas do mesmo ficheiro e **acompanham todos os frames** do corpo (ASSET_BIBLE §2).
- As 4 armas de uma família partilham a mesma coreografia; só muda o desenho. O nível lê-se pela silhueta da arma.
- O rosto muda de estado sem mudar de frame: `face_hurt` abaixo de 50% de vida (§07), `face_charmed`, `face_rotten`.
  O *flash* branco de 80 ms ao ser atingido é *shader*, não frame (§07).

## 4 · Criaturas, montarias, fauna, edifícios

| Tipo | Tags | Notas |
|---|---|---|
| Criaturas da Podridão | `spawn` (4, sai da mancha) · `idle` 6 · `walk` 8 · `attack` 5 · `die` 7 | a dissolução ao amanhecer é o *shader* `dissolve`, não frames (§51, §60) |
| Aríete de lodo | `walk` 8 · `attack` 6 (ação no 4) | o único golpe de criatura com *screen shake* (§24) |
| Consumidora | `walk` 8 · `attack` 6 · `grabbed` 6 | `grabbed`: quando o trepador sobe (§08) |
| Montarias | `idle` 6 · `walk` 8 · `run` 6 · `hurt` 2 | ferida recupera em 2 dias (§12) |
| Fauna | `idle` 4 · `run` 6 · `die` 4 | foge (`flees` nos dados) |
| Edifícios | tags = estados (`empty` · `scaffold` · `building` · `done` · `damaged` · `ruin`), `building` com 4 frames de progresso | um frame por estado, não cenas (§55) |
| Muralhas | `done` · `damaged` · `breached` por peça | `wall_breached` = tremor de ecrã, máx. 4 px (§55) |

## 5 · Quanto custa

O §22 estima **15 h** para *walk 8 · attack 5 · die 7* nos três corpos, porque o desenho já existe. Os estados
extra deste documento são para as fases em que o papel aparece — a fatia vertical precisa de `idle`, `walk`,
`attack`/`shoot`, `die`, `hit`, `work` e `build`. O resto entra com a classe ou o ofício que o usa.

## Parte XIII — três animações novas, e nenhuma delas é de personagem

> Fonte: §74, §75, §80. Ver [`VFX_REGISTER.csv`](VFX_REGISTER.csv) para os efeitos.

| Animação | Onde | Frames | fps | Nota |
|---|---|---|---|---|
| `root` | tronco de Amargueiro, por escala | 12 | 8 | O corpo levanta-se e vira árvore, na alvorada. A cara já lá está: é o slot `face` do morto. |
| `fell` | tronco de Amargueiro | 14 (em ciclo, 12 s) | 8 | O ciclo repete-se durante os 12 s do corte. O tempo é o preço, e é a única confirmação que o gesto tem. |
| `rise` · `sink` | alguidar de oferenda | 6 · 6 | 8 | Sobe com a frase; afunda-se ao fim de 20 s. Um afundamento é uma recusa, e não tem nada de dramático. |

**O Zelador** anda com o ciclo de caminhada da unidade genérica e uma pose `look` de quatro quadros — não tem
animação própria porque não ataca, não morre e nunca chega a tocar em nada.

**A candeia** é luz e não animação: quatro quadros de tremulação no *sprite* e o resto no *shader* (três paragens,
`dither` de 2 px). O brilho é controlado pela Dívida e não pela animação.
