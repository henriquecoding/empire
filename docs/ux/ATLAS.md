# Atlas do Império — tokens, fluxo da fundação e o que cada número quer dizer

Revisão de 07/10/2026. Implementação: [UX-08](../backlog/UX-08.md), [CV-01](../backlog/CV-01.md) e
[ADR 0078](../adr/0078-atlas-do-imperio-e-a-ficha-do-sitio.md). Fonte: o plano mestre da HUD,
[`docs/reports/HUD-UI-ATLAS.md`](../reports/HUD-UI-ATLAS.md). Estende [HUD-MOBILE.md](HUD-MOBILE.md) (UX-05, UX-06).

## Tokens

Vivem em `src/ui/atlas.gd`. `HudStyle`, `GameHud`, `PauseTheme` e `TouchArt` leem-nos daí: a HUD, a pausa, a ficha e
o toque deixam de ter paletas próprias. O contraste é o da WCAG 2.2 (luminância relativa sRGB) e mede-o
`tests/atlas_test.gd`, que é quem garante os mínimos; a tabela é o que o plano calculou.

| Token | Cor | Função | Contraste |
| --- | --- | --- | --- |
| `FIELD` | `#172A2B` | fundo da HUD e dos controlos | — |
| `RAISED` | `#233B3C` | subáreas e botões | — |
| `TEXT` | `#F1E9D8` | texto principal | 12,4:1 no campo |
| `SECONDARY` | `#BDC9C3` | explicação, navegação | 8,8:1 |
| `COIN` | `#DAB879` | moeda e ação económica, e só isso | 7,9:1 |
| `DANGER` | `#FFA28E` | perigo e falha | 7,7:1 |
| `VALID` | `#A5CCA5` | condição cumprida, controlo ligado | 8,4:1 |
| `INFO` | `#9CC8DE` | informação e o Interagir | 8,4:1 |
| `FOLIO` | `#E7DECB` | folha de leitura (ficha, Estado do reino) | — |
| `INK` | `#253839` | texto no linho | 9,2:1 no linho |
| `INK_SOFT` | `#4A5A57` | cabeçalhos e notas no linho (derivada) | 5,4:1 |
| `LINE` | `#5E7A74` | borda de um cartão no campo (derivada) | 3,2:1 |

O cartão da HUD é o campo a 95 %: por cima de um céu branco, o texto principal fica a 10,6:1 e o latão a 6,8:1.

**Motivos.** O *canto de registo* é um canto recortado em recta (cima à esquerda) e os outros em esquadria, em todos os
cartões (`Atlas.card()`). As *linhas de território* são três traços de comprimentos diferentes (`AtlasRule`), por
baixo do título da ficha. São decoração: não dizem faixa nenhuma. O *selo do horizonte* é arte e está por fazer
(Q-253).

## Famílias de comandos no toque

| Família | Botões | Aro |
| --- | --- | --- |
| Economia | Moeda | latão |
| Contexto | Interagir | informação; o aro de fora acende quando há o que fazer |
| Combate | ataque, habilidade (Vigília, Marcar, Encantar) | texto, com aro duplo |
| Navegação | alavanca, FIXAR, CORRER, Impulsos, pausa | secundário; ligado a verde |

Muda só a cor e a forma do aro. Nenhum botão mudou de sítio nem de gesto; CORRER continua mantido (Q-193).

## O fluxo da fundação

1. **Aproximar.** Parado num sítio válido, o contexto diz «Fundar neste local · E: ver condições». Uma linha, que
   não cobre o monarca.
2. **Inspecionar.** O Interagir abre a ficha (`SiteSheet`), em linho: o título e as linhas de território; «Pode
   fundar-se aqui: o chão da sede está livre.»; o que a fundação faz e que **não gasta moedas** (a lareira paga-se
   depois, no marco); o que a clareira leva e o que fica dentro do reino; o que o território permite, uma linha por
   obra. Tudo vem de `FoundationGuide.sections()`, a conta que a confirmação usa.
3. **Confirmar.** O Interagir outra vez, ou o botão «Fundar». Sai pela intenção `ASSUME`; `FoundationChoice.claim()`
   volta a validar o sítio. «Voltar», a pausa ou `ui_cancel` fecham sem mudar nada; o sítio deixar de valer também.
   O foco por omissão é «Voltar»: o Espaço (`ui_accept`) larga moedas neste jogo e não deve fundar por hábito.
   Enquanto a ficha está aberta, a linha curta do contexto esconde-se, para não dizer o mesmo duas vezes.
4. **Lugar.** No desktop a ficha encosta-se à direita e deixa o centro; abaixo de 420 unidades de altura ocupa o
   ecrã por cima do cabeçalho e o corpo rola. Aberta, o mundo não recebe ordens e o toque solta o que tinha premido.

## O que cada número quer dizer (HUD-02)

| Na captura | O que o código conta | O que o texto diz agora |
| --- | --- | --- |
| `6 / 33` | `RealmReadout.purse()`: moedas no saco de quem se conduz / capacidade desse saco | título «Moedas / máx.»; na pausa «Moedas: 6 (capacidade 33)» |
| `Primavera · 16 dias` | `Seasons.left(dia)`: os dias que faltam à estação, **hoje incluído** | «Primavera · restam 16 dias»; no último, «Primavera · último dia» |
| `1 de 2` | `FoundationGuide.territory_rows()`: dos lugares (vagas) dessa obra, quantos têm a fonte ao alcance se se fundar aqui | «Poço de minério · 1 de 2 lugares com rocha com passagem ao alcance» |

As linhas do território põem o nome primeiro e uma condição por linha. «Pesqueiro · sem água ao alcance» é uma
limitação do pesqueiro, e não da fundação.

## Provas

- `tests/site_sheet_test.gd` — a linha curta, as secções de uma fonte, o Interagir que abre sem enfileirar nada,
  abrir sem gastar nem fundar, confirmar pela intenção, voltar, o sítio que deixa de valer, o mundo bloqueado, e a
  ficha dentro do ecrã a 1280 × 720 (sem cobrir o centro) e a 844 × 390, em PT e EN.
- `tests/atlas_test.gd` — os pares de contraste, o cartão translúcido sobre o céu mais claro, a HUD e a pausa com os
  mesmos tokens, o canto de registo, e as famílias do toque.
- `tests/hud_copy_test.gd` — a estação e o último dia, o título do saldo e a linha da estação a caberem nos cartões,
  e as linhas do território.
- Capturas: `tools/captura_hud.tscn` com `--fundacao true` e `--ficha true`; cada PNG leva um JSON com o manifesto
  (commit, motor, renderer, stretch, semente, dia, fase, posição do monarca). São de um ecrã virtual em OpenGL:
  não certificam conforto nem leitura num telemóvel real, que pertencem à sessão de aparelhos do plano (§18).

```sh
godot --path . --audio-driver Dummy --resolution 1280x720 --rendering-method gl_compatibility \
  tools/captura_hud.tscn -- --novo --semente 20261007 --fundacao true --ficha true \
  --output build/hud/ficha.png
```
