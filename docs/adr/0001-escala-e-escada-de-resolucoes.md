# ADR 0001 — Escala `fractional` por omissão, com interruptor para `integer`

- Estado: proposta — fecha no *spike* de duas horas da Fase 0 (§65) e na revisão visual do marco dos Enramados
- Data: 2026-09-11 · revista a 2026-09-26
- Secção do dossiê: §19, §38 (decisão 1), §67

## Contexto
A arte é desenhada a 1:1 em 1280 × 720 e perde 6,3% dos píxeis a 640 × 360 (§01). 1080p — o ecrã mais comum — é
1,5× e não é múltiplo inteiro. O Steam Deck (1280 × 800) é 1× com barras de 40 px.

## Decisão
`canvas_items` com escala `fractional` e filtro suave por omissão; nas Opções, "pixels nítidos" passa a `integer`
com barras. A largura visível do mundo fica limitada a 1,25× o rácio 16:9, para ecrãs ultralargos não verem A
Podridão chegar mais cedo.

## Alternativas consideradas
`integer` sempre: 1080p ficaria com barras enormes (escala 1×). Baixar a resolução interna para 640 × 360: destrói
a arte, que é o ativo mais difícil de refazer (§22).

## Consequências
A câmara e o enquadramento dependem disto; tomá-la depois custa uma reescrita (§19). **Para aceitar:** correr o
*spike* lado a lado em 1080p e no Deck, com `fractional` e `integer`, e guardar as capturas na PERFORMANCE_MATRIX.

## Estado em 26/09/2026 — o que corre não é o que a decisão acima diz

A frase original dizia que isto "já está no `project.godot`". Não está, e o que está é outra combinação. O que o
motor usa sai do `project.godot` mais os valores por omissão do Godot 4.6, e é o que `python3 tools/manifesto.py`
imprime:

| Ponto | Proposto acima | O que corre hoje |
|---|---|---|
| Modo de esticar | `canvas_items` | `canvas_items` (escrito) |
| Escala | `fractional` | `fractional` (omissão, não escrito) |
| Filtro das texturas | suave | `nearest` (`default_texture_filter=0`); o cenário dos Enramados força `nearest` por nó |
| Aspecto | limite de 1,25× em ultralargos | `keep` (omissão): barras em qualquer rácio que não seja 16:9 |
| Interruptor "pixels nítidos" | nas Opções | não existe |
| Renderer | — | `mobile` no desktop; o Web é sempre `gl_compatibility`; um ecrã virtual sem Vulkan cai para `gl_compatibility` |

A última linha pesa na comparação: as imagens do site e as do `make captura` são tiradas num ecrã virtual, e por
isso com o renderer de compatibilidade — o mesmo do jogo publicado no browser, e não o do executável de desktop.
A ficha de cada captura (`tools/captura.gd`) regista agora o renderer e o *driver* que correram, a semente e o
commit; as imagens deixam de depender de se saber de cor em que máquina foram tiradas.

### A comparação, medida

`xvfb-run -a make escala` fotografa a mesma cena (jogo novo, semente fixa, meio-dia do dia 1, rei no centro) nas três
resoluções que o planejamento pede, com as três combinações em causa. Commit `de2d840` com as alterações desta
revisão, Godot 4.6-stable, `gl_compatibility`/`opengl3` sobre llvmpipe, 26/09/2026:

| Resolução | Combinação | Fator | Imagem | Ecrã sem imagem | Um pixel da arte ocupa | Cores únicas |
|---|---|---:|---|---:|---|---:|
| 1280 × 720 | atual (`fractional` + `nearest`) | 1,0 | 1280 × 720 | 0% | 1 px | 1355 |
| 1280 × 720 | ADR (`fractional` + suave) | 1,0 | 1280 × 720 | 0% | 1 px | 1368 |
| 1280 × 720 | `integer` + `nearest` | 1,0 | 1280 × 720 | 0% | 1 px | 1355 |
| 1920 × 1080 | atual | 1,5 | 1920 × 1080 | 0% | 1 ou 2 px, alternados | 1337 |
| 1920 × 1080 | ADR | 1,5 | 1920 × 1080 | 0% | 1 ou 2 px, misturados | 7277 (5,4×) |
| 1920 × 1080 | `integer` | 1,0 | 1280 × 720 | 55,6% | 1 px | 1355 |
| 1280 × 800 | atual | 1,0 | 1280 × 720 | 10,0% | 1 px | 1354 |
| 1280 × 800 | ADR | 1,0 | 1280 × 720 | 10,0% | 1 px | 1368 |
| 1280 × 800 | `integer` | 1,0 | 1280 × 720 | 10,0% | 1 px | 1355 |

O que os números dizem, sem gosto nenhum:

- **Só 1080p separa as três.** A 720p e no Deck o fator é 1 e as três imagens são a mesma; no Deck as barras de
  40 px (10% do ecrã) existem em todas, porque o aspecto é `keep`.
- **O filtro suave inventa cores.** A 1,5× passa de ~1340 para ~7300 cores únicas: cada contorno de 1 px ganha
  uma franja. É exatamente o que a intenção do autor (nitidez) recusa, e é o argumento contra a decisão tal como
  está escrita.
- **O `nearest` fracionário não inventa cores, mas não tem pixels iguais.** A 1,5× metade das colunas e linhas da
  arte ocupa 1 px e a outra metade 2 px: olhos, dentes e diagonais podem mudar de forma com a câmara a andar.
- **A escala inteira em 1080p deixa 55,6% do ecrã sem imagem** (fator 1, 1280 × 720 ao centro).

### O que falta para fechar

Os números não fecham a ADR — a revisão visual fecha. Falta: olhar as imagens em `build/revisao/escala/` em tamanho
real, ver a mesma cena **em movimento** a 1,5× (a irregularidade de 1/2 px só se nota com a câmara a andar), e
correr o *spike* em hardware de 1080p e num Deck. Até lá o jogo fica como está (`canvas_items`, `fractional`,
`nearest`) e esta ADR continua proposta; o que a decisão escrita acima diz sobre o filtro suave não está em vigor e
os números medidos contrariam-no.
