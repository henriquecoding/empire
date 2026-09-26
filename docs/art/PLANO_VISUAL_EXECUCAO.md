# Planejamento visual de 26/09 — o que foi executado e o que falta

Registo da execução do *Empire — planejamento de evolução visual e design* (revisão de 26/09/2026, base `de2d840`).
Diz o que cada lote tem hoje no código, como se prova, o que as medições mostraram e o que continua à espera de
arte ou de uma decisão do autor. Não é uma aprovação artística: essa só se dá a olhar o jogo em tamanho real e em
movimento (§8 do planejamento).

Regra 9 do `AGENTS.md`: nada em `art/` foi criado nem alterado. O que se fez é código de apresentação, ferramentas
de prova e documentação; a arte nova que o marco pede continua a ser do autor.

## Como reproduzir as provas

Com o Godot de `.godot-version` no `PATH` e um ecrã virtual (`xvfb-run -a`):

| Comando | O que produz | Onde |
|---|---|---|
| `make manifesto` | O motor, o renderer, a escala e o filtro declarados; chumba se o `project.godot` divergir do `.godot-version` | terminal (portão) |
| `make inventario-arte` | Confere que `docs/art/RUNTIME_ART.md` está em dia | terminal (portão) |
| `make marco` | As onze capturas do §8 (oeste, centro e leste de dia, ao crepúsculo e de noite; o rei no subsolo em cada passagem) | `build/revisao/marco/` |
| `make escala` | A mesma cena em 1280 × 720, 1920 × 1080 e 1280 × 800 com as três combinações da ADR 0001 | `build/revisao/escala/` |
| `make obras` | Oito quadros do centro com treino, cozinha, um canteiro e um muro a passar pelos oito pontos do `SiteStage` | `build/revisao/obras/` |

Cada imagem sai com a ficha do `tools/captura.gd` ao lado (`.json`): commit e se a árvore estava suja, motor,
renderer e *driver* que correram, janela, base, escala, fator, semente, dia, fase, posição e faixa do rei, centro
da câmara, comando, e `natural`/`preparado` com a lista do que foi preparado. Cada prancha junta as fichas num
`indice.json` e numa `folha.png`. A semente é fixa (`20260926`) e o jogo é novo: duas corridas no mesmo commit dão
a mesma região, a mesma gente e a mesma noite.

## Por lote

| Lote | Feito no código | Prova | Falta |
|---|---|---|---|
| 1 — Referência atual | `project.godot` declara 4.6; `tools/manifesto.py` + portão; ficha completa das capturas; `--semente` no jogo; `tools/revisao.py`; ADR 0001 com o estado real e as medições; legendas do site com proveniência; `docs/art/RUNTIME_ART.md` | `make manifesto`, `make marco`, `make escala`, `make inventario-arte`; `tests/captura_semente_test.gd` | Fechar a ADR 0001 (revisão visual em movimento e *spike* em hardware); voltar a tirar as imagens do site depois da revisão |
| 2 — Composição | Nada no código: é arte e autoria regional | Medições abaixo, `make marco` | A composição do centro, das laterais e do subsolo; separar a autoria regional do `Greybox` |
| 3 — Estados das obras | `SiteStage` (puro) e `SiteMarks`; `BuildingSkins`, `SettlementArt` e as obras procedurais usam-nos | `make obras`; `tests/site_stage_test.gd` | Arte própria por estado (hoje há um frame por export e os estados são desenhados por código) |
| 4 — Elenco e ações | `ActorAction`: prioridade morte → dano → medo → ataque → caminhada → trabalho → repouso; `OriginalArt.frame_at` por tag; recurso ao repouso quando a tag não existe | `tests/actor_action_test.gd` | As animações em si (só a tropa tem `idle`); o rei redesenhado; o arqueiro derivado |
| 5 — Interações e noite | `ConversionSystem.status`: o celeiro distingue modo escolhido de efeito ativo, no guia e num emblema na obra | `tests/conversion_test.gd`, `tests/celeiro_no_jogo_test.gd` | Impulsos, caça/entrega, noite (abaixo) |
| 6 — Revisão integrada | As ferramentas de prova (lote 1) | — | Vídeo, matriz de desempenho, imagens do site, publicação conferida |

## O que as medições mostraram

- **O renderer das capturas não é o do desktop.** Num ecrã virtual sem Vulkan o motor cai para
  `gl_compatibility`/`opengl3` (llvmpipe). É o mesmo renderer do jogo publicado no browser, e não o `mobile` do
  executável. As fichas passam a dizê-lo; uma captura de desktop tem de ser tirada numa máquina com Vulkan.
- **A semente das capturas era o relógio.** Sem `--semente`, nenhuma imagem do site se podia repetir.
- **Escala (ADR 0001).** Só 1080p separa as alternativas. O filtro suave a 1,5× passa de ~1340 para ~7300 cores
  únicas (franjas em cada contorno); o `nearest` fracionário mantém as cores mas alterna pixels de 1 e 2 px; a
  escala inteira em 1080p deixa 55,6% do ecrã sem imagem. No Deck há 10% de barras em qualquer combinação
  (aspecto `keep`). Números completos na ADR.
- **Castelo, treino e cozinha (§4.3).** Pelo alfa do `tree_castle.png`, os pixels opacos do castelo cobrem 17% da
  caixa da casa de treino e 13% da da cozinha. As casas desenham-se por cima (o núcleo é o primeiro slot), e por
  isso leem-se; o que fica por decidir é a composição, não a ordem de desenho.
- **Noite (§4.4).** Nas vistas oeste e leste da noite, fora da candeia, o rei fica uma silhueta quase do valor do
  fundo: coroa e rosto perdem-se, e o que se lê é a marca amarela aos pés e as moedas do preço por cima. É um
  achado para a revisão da luz, não uma decisão — a direção castanha (ADR 0011) e as regras da Candeia mantêm-se.
- **Subsolo.** O rei (90 px de corpo) cabe na galeria, com a cabeça rente às traves junto das passagens.

## Pendente, e porque não se fez aqui

- **Arte nova** (rei, arqueiro, ciclos de caminhada/trabalho/ataque, estados das obras, composição regional):
  regra 9 do `AGENTS.md`. O contrato de ações e o inventário dizem exatamente o que falta e onde entra.
- **Impulsos (§7).** A disponibilidade só aparece no inspetor de diagnóstico, com texto fixo, e a recusa de um
  impulso não ligado não se mostra ao jogador. Mostrá-la pede ou um sinal novo (o catálogo do §46 é fechado,
  regra 7) ou uma decisão de HUD — fica para decisão, não se inventou (Q-113).
- **Caça e entrega, treino com entrada e saída, travessia com percurso** (§7): dependem de ações desenhadas; o
  `ActorAction` já lê o estado de que precisam.
- **Revisão integrada** (vídeo, desempenho, publicação): exige o marco com arte.

Ligações: `docs/art/RUNTIME_ART.md` (gerado), `docs/adr/0001-escala-e-escada-de-resolucoes.md`,
`docs/backlog/ART-01.md`.
