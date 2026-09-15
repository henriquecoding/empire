# Regras de greybox

> **Nenhum cenário final se pinta antes de ter sido jogado em formas simples.** (§21 regra 5, §22)
>
> Um edifício em pixel art custa quatro horas; um retângulo de cor lisa com o tamanho certo custa dois minutos e
> responde à mesma pergunta — cabe no ecrã? lê-se à distância? percebe-se o que é? (§22)

*Nota de arrumação:* o relatório mestre punha este ficheiro em `docs/design/`. Essa pasta é **gerada do dossiê**
por `tools/split_dossie.py` e nunca se edita à mão (§69) — por isso vive aqui, ao lado da World Production Bible.

## 1 · O que entra na greybox

| Entra | Como |
|---|---|
| Personagens | **As reais, desde o primeiro dia.** O design está fechado (§01, §22): são elas que dão a escala de tudo o resto |
| Edifícios, muralhas, torres | Retângulos de cor lisa com a largura de `buildings.csv`/`walls.csv` e a altura prevista; contorno de 2 px |
| Terreno | Uma barra na linha do solo; o corte de solo em cor escura lisa |
| Cavidades e passagens | Retângulos recortados no corte de solo; passagens como escadas de 3 degraus |
| *Slots* de construção | Retângulo tracejado no chão, com a largura do edifício + 16 px de soleira |
| Céu e parallax | Três faixas de cor lisa (céu, distância, plano médio) — nada mais |
| A Podridão | Um retângulo roxo semitransparente que avança à velocidade do `rot.csv` |

## 2 · As cores do kit

Tiradas da paleta de trabalho (§22), para a greybox já falar a língua do jogo:

| Categoria | Cor | Hex |
|---|---|---|
| Céu | lavagem petróleo | `#DFEAEF` |
| Distância / plano médio | areias | `#C8D1C0` · `#BFB495` |
| Terreno e corte de solo | madeira e terra | `#6A4928` |
| Núcleo | azul-petróleo | `#2A6580` |
| Produção | verde | `#4C7719` |
| Conversão e ofícios | âmbar | `#AE4F16` |
| Defesas e muralhas | neutro escuro | `#3E3A2E` |
| Cavidade descoberta | neutro | `#75705E` |
| *Slot* de construção | contorno tracejado | `#14140F` |
| A Podridão | ameixa, 60% | `#59386B` |

## 3 · As treze perguntas

Uma greybox só passa quando todas têm resposta "sim" com o número ao lado. Regista-as no formulário da secção 5.

| # | Pergunta | Como se responde | Passa quando |
|---|---|---|---|
| 1 | A escala parece correta? | Personagens reais contra os blocos; porta ≥ 1,3× a altura de um aldeão | Um aldeão (46–52 px) cabe numa porta sem tocar no lintel |
| 2 | O personagem cabe visualmente? | Captura a 1× com as três escalas lado a lado | As três escalas distinguem-se sem UI (§01) |
| 3 | A câmara funciona? | Andar 3 segmentos, parar, voltar; câmara livre e regresso em 2 s (§24) | Sem tremer, sem subpíxel, limites da região respeitados |
| 4 | O jogador percebe a direção? | Pergunta a quem joga: "de onde vem o perigo? onde é casa?" | Aponta sem hesitar para o lado ameaçado e para o núcleo |
| 5 | O mundo tem espaço suficiente? | Medir os vazios | ≥ 240 px entre grupos; ≥ 3 segmentos `empty` por região |
| 6 | Os edifícios cabem? | Pôr o maior edifício do kit em cada *slot* | Todos cabem com soleira; nenhum invade outro *slot* |
| 7 | Há espaço de combate? | Seis Rastejantes contra o muro | 160 px livres à frente do muro; fila estável a 30–120 px |
| 8 | A Podridão lê-se? | Crepúsculo com o jogador no núcleo | A mancha vê-se do outro lado do ecrã antes de chegar (§51) |
| 9 | A faixa aérea funciona? | Uma voadora sobre os telhados | Lê-se "acima do alcance"; ≥ 30% de céu livre (§11) |
| 10 | A caverna funciona? | O monarca entra na cavidade | Cabe de pé, com teto desenhável (≥ 120 px; alvo 200) |
| 11 | Quanto demora a travessia? | Cronometrar a pé e a cavalo | Registar os segundos por segmento e por região — é a medida da Q-018 |
| 12 | Construir bloqueia passagem? | Construir em todos os *slots* | Nenhuma passagem entre faixas fica tapada; aliados atravessam-se (§07) |
| 13 | Lê-se tudo sem HUD? | Jogar um dia inteiro sem o *overlay* de depuração | O único HUD é o relógio da dívida, e só com dívida (§24) |

## 4 · A decisão que só a greybox toma

**`GROUND_LINE`** (§11, §47, §67). Monta a mesma greybox com a linha do solo a **500, 517 e 540** e joga as três.
Escolhe pelo enquadramento — céu para o parallax respirar, corte de solo para a caverna ter composição — e não
pela imagem onde calhou ficar. Escreve a ADR 0011 com as três capturas e, a partir daí, **não se mexe**: meia dúzia
de sistemas dependem dele.

As outras decisões da Fase 0 que se tomam aqui ao lado — escala `fractional`/`integer` no Deck, tamanho de fonte —
estão no QA (PERFORMANCE_MATRIX e ACCESSIBILITY_MATRIX) e na ADR 0001.

## 5 · Formulário de aprovação

Copia para `docs/world/greybox/<segment_id>.md` e preenche.

```text
Segmento:            enramados_empty_01
Data / build:        ____-__-__ / <commit>
Assunto (1 linha):   o poço
Perguntas 1–13:      [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ]
Travessia a pé:      ___ s     a cavalo: ___ s
Densidade:           ___ edifícios · ___ props · maior vazio ___ px
Veredito:            pintar  |  iterar  |  cortar
O que mudou desde a última volta:
```

## 6 · O que vem a seguir

- `tools/greybox_gen.gd` (previsto na árvore da §41): gerar a cena greybox a partir da linha de `segments.csv` —
  ticket GB-02.
- Os oito segmentos da fatia vertical estão em `SEGMENT_REGISTER.csv`, com `greybox_status = todo`.

## Parte XIII — o que o greybox de um capítulo tem de mostrar

Um capítulo prova-se em greybox antes de levar um píxel pintado, e o que se prova são três coisas — as únicas que
não se corrigem depois de a arte estar feita:

1. **O desvio existe e custa o que está escrito.** Marca o caminho alternativo em caixas e mede-o. Se o desvio não
   existir, o capítulo bloqueia a rota e parte a regra 5 da §77.
2. **A lei lê-se em noventa segundos, sem ninguém a explicar.** Põe alguém a jogar e não digas nada. Se tiver de
   perguntar o que se passa, a lei está a precisar de duas frases e são dois capítulos.
3. **O habitante está onde se dá por ele sem ser preciso procurá-lo.**

### O `seg_000`, revisto

A §25 reserva o `seg_000` como cena fixa e escrita à mão, e essa decisão fica. A §83 acrescenta-lhe obrigatórios,
e todos entram já no greybox porque decidem enquadramento:

- **Um Amargueiro velho fora do muro, à esquerda**, com a cara virada para a muralha. Existe para que a pergunta
  "porque é que aquela árvore tem cara?" chegue **depois** da resposta e não antes (risco R-17).
- **A candeia visível ao longe desde o minuto 0:00.** Ao minuto zero é cenário estranho; ao minuto treze é uma
  ameaça com nome.
- **Um vagabundo com `head_pool` fixo**, para que a cara do minuto 0:20 seja sempre a mesma — é a mesma cara que
  pode acabar na casca.
