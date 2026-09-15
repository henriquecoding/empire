# Matriz de acessibilidade

> O §26 decide o que se faz e o que se declara na loja; esta matriz transforma cada regra num **teste que passa
> ou falha**, com o sítio onde se verifica. *"Jogável sem visão"* fica de fora, e a etiqueta da loja di-lo com
> honestidade (§26).

## 1 · Os testes

| # | Regra | Teste | Passa quando | Onde | Fase |
|---|---|---|---|---|---|
| A1 | Tamanho mínimo de texto | Medir a altura de carácter de cada fonte em cada ecrã a 1280 × 720 e 1280 × 800 | ≥ 12 px em todo o lado; **nada abaixo de 9 px** a 1280 × 800 (critério Verified) | captura + régua | 0 (decisão), 4 |
| A2 | Escala de texto | `OPT_TEXT_SIZE` no máximo em todos os ecrãs com texto | Nada cortado nem sobreposto | SCREEN_REGISTER | 5 |
| A3 | Contraste | `OPT_CONTRAST` no mínimo e no máximo; mancha contra o terreno ao crepúsculo | A mancha e as tropas distinguem-se do fundo nos dois extremos | cena C2 | 5 |
| A4 | Daltonismo | Filtros de protanopia, deuteranopia e tritanopia sobre o crepúsculo e a noite | **A Podridão distingue-se do terreno em protanopia** (§26) | captura filtrada | 5 |
| A5 | Sem informação só por cor | Rever o contrato do HUD (UI_UX_FLOWS §4) | Cada informação tem forma ou som além da cor (vida = rosto; muralha = silhueta; hora = luz **e** sol/lua) | revisão | 4 |
| A6 | Redução de movimento | Ligar a opção do sistema / do jogo | *Screen shake* desligado; transições instantâneas; sem raios pulsantes | jogo | 5 |
| A7 | Flashes | `OPT_FLASHES` desligado | Nenhum *flash* de corpo inteiro; o impacto fica só com partícula | jogo | 5 |
| A8 | Legendas de som | `OPT_CAPTIONS` ligado durante um dia inteiro | As 8 pistas do §26 aparecem, com o texto de `CAPTION_*` | AUDIO_CUE_SHEET | 5 |
| A9 | Só comando | Jogar do título à derrota sem tocar no teclado nem no rato | Todos os ecrãs, a roda do rei e as opções respondem | QA manual | 1+ |
| A10 | Só teclado | Idem, só teclado | Idem | QA manual | 1+ |
| A11 | Remapeamento completo | Remapear os dois verbos, a roda e a pausa para outras teclas/botões | O jogo inteiro joga-se com o novo mapa | `InputMap` | 5 |
| A12 | Glifos certos | Trocar de comando a meio do jogo | Os glifos mudam para o dispositivo ativo (§26) | QA manual | 4 |
| A13 | Ritmo próprio | `OPT_DAY_LENGTH` a 240 s e a 540 s | As 6 fases escalam na mesma proporção; o dia continua jogável | `clock.csv`: `day_seconds_min/max` | 5 |
| A14 | Pausa | Pausar em qualquer momento, incluindo roda aberta e noite | O tempo pára (`game_paused`) | jogo | 1 |
| A15 | Sem QTE | Rever mecânicas | Não há QTE — declara-se (§26) | revisão | — |
| A16 | Texto de entrada | Nome do save no Deck | Abre o teclado do Steamworks (§26) | Deck | 5 |

## 2 · Steam Deck Verified (§26)

| Categoria | Critério | Estado | Teste |
|---|---|---|---|
| Entrada | A configuração por omissão do comando dá acesso a todo o conteúdo | resolvido por design (dois verbos) | A9 |
| Entrada | Glifos correspondem ao dispositivo | a implementar | A12 |
| Entrada | Texto pela API do Steamworks ou teclado próprio navegável | só o nome do save | A16 |
| Ecrã | Corre a 1280 × 800 ou 1280 × 720 | nativo | PERFORMANCE_MATRIX |
| Ecrã | Nenhum carácter abaixo de 9 px a 1280 × 800; recomendado 12 | **o único risco real** | A1 |
| Continuidade | Sem avisos de incompatibilidade; sem *launcher* | sem *launcher* | QA manual |
| Desempenho | Jogável nas definições por omissão — 30 fps a 800p | alvo 60 | PERFORMANCE_MATRIX |
| Sistema | Sem incompatibilidades de Proton | Godot exporta Linux nativo — testar cedo | *export* do CI |

## 3 · O que se declara na loja (§26)

| Funcionalidade | Declaração | Teste que a prova |
|---|---|---|
| Remapeamento completo | sim | A11 |
| Legendas para pistas sonoras | sim | A8 |
| Modos para daltonismo | sim | A4 |
| Controlos de contraste | sim | A3 |
| Desligar *screen shake* e *flashes* | sim | A6, A7 |
| Jogável ao teu próprio ritmo | sim | A13 |
| Sem QTE | sim | A15 |
| Jogável sem visão | **não** | — |

## Parte XIII — os dois mostradores sem número

A Parte XIII acrescenta dois estados que o jogador tem de sentir sem os ler, e ambos falhariam a acessibilidade se
ficassem como foram desenhados. A §82 apanhou um a tempo; o outro já nascia com redundância.

| # | Regra | Teste | Passa quando | Onde | Fase |
|---|---|---|---|---|---|
| A13 | A Dívida da Candeia não vira número | Jogar até à Dívida 12 com todas as opções de acessibilidade ligadas | Nenhum número, barra, ícone ou linha de texto em nenhum modo. O brilho da candeia é o mostrador (Q-045) | jogo | 3 |
| A14 | O coro tem redundância visual | Soltar 3 povos e jogar com o som desligado | Três estandartes hasteados sobre o núcleo, na mesma ordem; três mastros vazios pelos que faltam (§82) | jogo | 5 |
| A15 | A noite castanha não esconde a mancha | Filtros de protanopia, deuteranopia e tritanopia sobre a noite do dia 12 | A mancha (violeta) distingue-se do ambiente (terra) nos três filtros — é a razão de o violeta ser a única cor fria saturada da noite | captura filtrada | 2 |
| A16 | A Oferta não exige leitura rápida | Medir o tempo de leitura das doze frases com `OPT_TEXT_SIZE` no máximo | As oito palavras lêem-se em menos de metade dos 20 s da janela; o resto do tempo é para decidir, não para ler | captura + cronómetro | 3 |

> **Porque é que a Dívida fica escondida mesmo no modo de acessibilidade**
>
> É a pergunta Q-045, e a resposta está escrita: um número não é acessibilidade, é *spoiler*. O que a
> acessibilidade exige é que o estado seja perceptível por mais do que um canal — e é: o brilho da candeia (visão)
> e o ambiente âmbar a partir dos 9 (visão, sem depender de cor) mais os estandartes da Colheita (visão) contra o
> coro (audição). Mostrar o número não acrescentaria um canal; substituiria a experiência inteira por um contador.
