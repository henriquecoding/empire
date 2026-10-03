# Assets em falta

> Quando uma tarefa precisa de um asset que ainda não existe, o agente cria um *placeholder* de cor lisa em
> `art/export/_placeholder/` e acrescenta uma linha aqui (AGENTS.md). Nunca desenha arte a sério, nunca toca em
> `art/source/`. O registo completo do que se vai produzir é `docs/art/ASSET_REGISTER.csv`; esta lista é só o que
> está **a ser usado em jogo como placeholder**.

| Placeholder | Tamanho | Usado em | Substitui-se por | Criado | Estado |
|---|---|---|---|---|---|
| `art/export/_placeholder/unit_scale2_placeholder.png` | 24 × 47 | `scenes/boot.tscn` | `enramados_villager_body` (ASSET_REGISTER) | 2026-09-11 | em uso |
| `art/export/_placeholder/contact_shadow_18.png` | 18 × 6 | `scenes/boot.tscn` | `shadow_18` | 2026-09-11 | em uso |
| procedural — `ActorArt`, coroa e pele própria | escala 3 | unidade `nia` (`src/actors/unit_art_batch.gd`) | a Imperatriz Nia: pequena, negra, coroa, machadinhas (ADR 0052; plano §16.5) — a registar | 2026-10-02 | em uso |
| procedural — `ActorArt`, coroa e arco | escala 4 | unidade `archer_emperor` | o Imperador Arqueiro: arco, aljava, coroa e a mão de tiro (plano §16.5) — a registar | 2026-10-02 | em uso |
| procedural — `ActorArt` + `BardArt.banner` | escala 2 | unidade `bard_banner` | o Bardo da Nia com a bandeira às costas (plano §16.3) — a registar | 2026-10-02 | em uso |
| `knight.png` emprestado (o escudeiro) | escala 1 | unidade `quiver_squire` | o escudeiro das flechas do Imperador Arqueiro: aljava e pagamento (plano §16.5) — a registar | 2026-10-02 | em uso |
| procedural — `GameArt`, formas lisas | 16 × 14 | caça `pheasant` (`src/world/game_art.gd`) | o faisão: corpo castanho, pescoço verde, barbela vermelha (ADR 0057) — a registar | 2026-10-03 | em uso |
| procedural — `GameArt`, formas lisas | 30 × 14 | caça `fox` | a raposa: laranja, ponta da cauda clara (ADR 0057) — a registar | 2026-10-03 | em uso |
| procedural — `GameArt`, formas lisas | 29 × 17 | caça `boar` | o javali: escuro, crina e presas (ADR 0057) — a registar | 2026-10-03 | em uso |
| procedural — `GameArt`, formas lisas | 28 × 41 | caça `white_stag` | o cervo branco: o veado em branco, hastes douradas (ADR 0057) — a registar | 2026-10-03 | em uso |
| procedural — `SeatSprites`, `PixelPainter` | 168 × 64 | sede `encampment` (`src/world/sprites_seat.gd`) | o Acampamento: duas tendas, a fogueira em brasa baixa e a bancada (ADR 0059) — a registar | 2026-10-03 | em uso |
| procedural — `SeatSprites`, `PixelPainter` | 248 × 80 | sede `hamlet` | o Povoado: duas cabanas de troncos, o sino e a lenha (ADR 0059) — a registar | 2026-10-03 | em uso |
| procedural — `SeatSprites`, `PixelPainter` | 328 × 120 | sede `village` | a Vila: casas de reboco à volta do salão (ADR 0059) — a registar | 2026-10-03 | em uso |
| procedural — `SeatSprites`, `PixelPainter` | 412 × 164 | sede `walled_village` | a Vila Fortificada: a vila entre palicadas, com a guarita (ADR 0059) — a registar | 2026-10-03 | em uso |
| procedural — `SeatSprites`, `PixelPainter` | 72 × 48 | carroça de provisões | a carroça da chegada com a bolsa (ADR 0059) — a registar | 2026-10-03 | em uso |

## Como se acrescenta

```text
| art/export/_placeholder/<nome>.png | L × A | <cena ou recurso> | <asset_id do ASSET_REGISTER> | AAAA-MM-DD | em uso |
```

Cor lisa da categoria (GREYBOX_RULES §2), contorno de 1 px preto, tamanho útil e pivot iguais aos do asset final.
