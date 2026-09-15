# Por fazer — o que falta, e o que já se pode correr

> **Isto é uma fotografia, tirada a 15/09/2026, depois do núcleo jogável.** A fonte
> é `docs/backlog/`, um ficheiro por ticket, e é lá que o estado muda — não aqui.
> Todos os números desta página saem de comandos que estão escritos ao lado
> deles, para que se possa desconfiar e voltar a contar. É a mesma regra do
> `AGENTS.md`: *não escrevas à mão um número que a ferramenta conta.*

## Onde é que isto está

| | |
|---|---|
| Tickets | **53**, dos quais **23 feitos** e **30 por fazer** |
| Fase 0 | 14 de 16 — faltam dois, e nenhum dos dois é código |
| Fase 1 | 7 de 17 — F1-01, F1-02, F1-03, F1-04, **F1-05**, **F1-08** e **F1-10** |
| Suite | 255 casos, 250 a passar, 5 saltados, 0 falhas, 0 *orphans* |
| `SimLoop` | **9 dos 11 passos** do §43 escritos; faltam o 9 (F1-14) e o 10 (Fase 2) |
| Perguntas em aberto | 59, em `docs/QUESTIONS.md` |

```bash
# a contagem de cima, a partir da árvore
for f in docs/backlog/*.md; do [ "$(basename $f)" = README.md ] && continue
  grep -m1 '^Estado' "$f" | sed 's/^Estado *//'; done | sort | uniq -c
```

---

## Fase 0 — 2 por fazer, os dois bloqueados por coisas que não são código

| | O que falta | Porque está parado |
|---|---|---|
| **F0-09** | Decidir a escala e fechar a ADR 0001 | Exige teste **em 1080p e num Steam Deck**. É hardware, e nenhuma medição *headless* o substitui. A ADR 0001 continua proposta. |
| **F0-15** | Importar arte do Aseprite e fechar a ADR 0010 | Exige `tools/export_aseprite.sh` testado **com um ficheiro real**, e não há nenhum: zero `.aseprite` na árvore, sem Aseprite instalado e sem o Wizard. A ADR 0010 continua proposta. |

Estão registados como **bloqueados**, e não como adiados. A diferença importa: não
há aqui trabalho por fazer que alguém possa pegar — há uma máquina e um ficheiro
que faltam.

---

## Fase 1 — 10 por fazer

**Desbloqueados agora** (as dependências estão todas feitas):

| | O que é | Depende de | Critério de aceitação (o "Feito" do ticket) |
|---|---|---|---|
| **F1-06** | Muro: cinco níveis, dois caminhos, *slots* de contacto | F1-05 ✔ | A tabela do §10 replicada em `.tres`; `test_muralhas_do_10` passa |
| **F1-11** | Plantação, pesqueiro e galinheiro com os valores do §06 | F1-10 ✔ | *Payback* de 2 dias medido em jogo; `test_payback_do_06` continua a passar |
| **F1-12** | Moral e fuga com o raio do rei | F1-05 ✔ | Com o rei em campo ninguém foge; fora do raio, foge ao limiar de vida dos dados |
| **F1-13** | `CanvasModulate` **por faixa**, animado pelo `GameClock` | F0-06 ✔ | As seis fases são distinguíveis sem HUD; a noite é castanha (ADR 0011) |
| **F1-14** | Save e load do estado de `src/sim/` com `save_version` | F1-10 ✔ | Fechar e reabrir no dia 7 preserva tudo, incluindo a sequência aleatória |

Três deles já têm metade do caminho andado pelo núcleo jogável, e o ticket diz
exactamente qual metade: o **F1-06** tem a escada dos cinco níveis a pagar-se com
moeda e a travar criaturas, e falta-lhe a fila de contacto do §50; o **F1-07** tem
a ordem de resolução do §50 inteira, e falta-lhe a precisão 1,0 dentro de torre;
o **F1-13** tem o `CanvasModulate` global com as seis cores do `clock.tres`, e
falta-lhe ser **por faixa**.

**À espera de outro ticket:**

| | O que é | Depende de | Critério de aceitação |
|---|---|---|---|
| F1-07 | Arqueiro: alcance, precisão 0,34 em campo e 1,0 em torre | F1-06 | O tempo até matar medido bate com a tabela do §07, em valor esperado |
| F1-09 | Criaturas: Rastejante, Alado, Bruto e a tabela de invocação | F1-08 ✔ | A noite 4 obriga a torre alta; o Alado só é atingido por quem chega à faixa aérea |
| F1-15 | Cenário de combate noturno para afinação | F1-09 | A noite 5 ganha-se com 1 a 2 mortes; corre em *headless* com delta fixo |
| F1-17 | Arte da mancha: a Podridão e a candeia | F1-08 ✔, **ART-02** | Vê-se chegar do horizonte; a candeia tem três paragens e domina o ecrã |
| F1-16 | Afinar até sobreviver dez dias ser possível e não trivial | **tudo** | Medido no cenário do F1-15. É o último da fase, por construção. |

---

## Fora da Fase 1 — 18 por fazer

### Arte — 4

| | O que é |
|---|---|
| ART-01 | A primeira personagem real em cinco *slots* |
| ART-02 | A paleta mestra e o LUT — **bloqueia o F1-17** |
| ART-03 | As seis camadas de *parallax* com teto de valores |
| ART-04 | Rostos e expressões: o catálogo do §60 |

### Parte XIII — 10

Está toda em dados e em prosa, e nada dela em código.

| | O que é |
|---|---|
| XIII-01 | §80 · O preto na paleta e a noite castanha |
| XIII-02 | §74 · O termo dos Amargueiros na massa |
| XIII-03 | §74 · O Amargueiro e a candeia, completos |
| XIII-04 | §75 · A Oferta e a Dívida da Candeia |
| XIII-05 | §76 · O Nome |
| XIII-06 | §78 · A Colheita |
| XIII-07 | §77 · Os dez capítulos |
| XIII-08 | §79 · Os doze diários e os três epílogos |
| XIII-09 | §81 · Som: o cante, os motivos e a encomendação |
| XIII-10 | §83 · Os primeiros vinte minutos |

### Greybox — 3

| | O que é |
|---|---|
| GB-01 | Greybox do segmento zero |
| GB-02 | Greybox dos seis biomas |
| GB-03 | Regras de densidade medidas no greybox |

### Nomes — 1

| | O que é |
|---|---|
| NB-01 | A bíblia de nomes — **e escolher o nome do jogo** |

---

## O que já se joga, e não é ticket nenhum

- **Existe cena de jogo.** `scenes/game.tscn`. A `boot.tscn` continua a ser a cena
  principal (ADR 0005) — carrega o `Registry`, fixa o idioma e entrega. O que ela
  entrega é uma região de seis ecrãs com o castelo-árvore ao centro, quatro sítios
  de muralha, quatro canteiros, dois galinheiros, duas casas de treino, duas
  passagens para o subsolo e nove pessoas por recrutar.
- **As cinco acções de *input* que estavam declaradas e por ler estão ligadas.**
  Nenhuma delas muda estado directamente: cada uma enfileira uma **intenção**, e o
  início do tick seguinte consome-a, pela ordem em que chegou (§61).
  ```bash
  for a in verb_drop verb_assume king_wheel mark_target pause; do
    echo "$a: $(grep -rn "&\"$a\"" src/ --include='*.gd' | wc -l)"; done
  ```
- **Nove dos onze passos do `SimLoop`** estão escritos. Faltam dois, e cada um
  continua a ser uma linha com o ticket que a preenche: o 9 (dívida e diplomacia,
  F1-14) e o 10 (IA do rei inimigo, Fase 2).

## O que falta e não é ticket nenhum

- **O mundo é um *greybox* montado em código, e não as nove cenas de segmento.**
  Elas não sobreviveram ao ZIP recuperado (Q-048). O `src/world/greybox.gd` põe a
  mesma região que o §21 descreve — seis ecrãs de 640 px, dois *slots* de
  construção e uma passagem por segmento, lidos do `segments.csv` — mas em código
  e não autorada. É a GB-01 que o substitui.
- **Não há um sprite.** Tudo o que se vê são rectângulos: `src/world/world_view.gd`
  desenha as tropas, as criaturas, as moedas, as obras e a mancha com `draw_rect`.
  A composição por *slots* da §58 e o `UnitView` existem e estão testados, mas não
  há arte para lhes dar (ART-01, ART-02).
- **A roda do rei não existe.** Quatro dos seis segmentos do §24 não têm sistema
  nenhum por trás. A tecla `king_wheel` abre, por agora, o painel de estado do
  *greybox* — Q-067.
- **A derrota acaba a partida e não a recomeça.** O §16 dá ressurreição até ao
  amanhecer, o §15 dá sucessão, e nenhum dos dois existe: quando o núcleo cai, o
  relógio pára e é preciso reabrir o jogo. O §46 também não tem sinal de derrota,
  e inventar um quebrava a regra 7 do `AGENTS.md` — o que há é o mundo a dizê-lo,
  com o núcleo em ruína.
- **Áudio:** 73 pistas escritas na bíblia, zero gravadas.
- **59 perguntas em aberto** em `docs/QUESTIONS.md` — as cinco mais recentes
  (Q-064 a Q-068) são as que encher o tick obrigou a fazer, e a Q-068 é a única
  que é uma contradição do dossiê consigo próprio: o §25 diz três Rastejantes na
  noite 1 e a massa do §74 dá sete.
- **A prosa dos doze diários** é primeira versão, e não há teste que apanhe prosa
  morna (§84): o único controlo é o espécime do diário 9.

A tabela *"O que NÃO foi verificado"* do `docs/recovery/RETOMADA.md` é a versão
canónica disto, e é a que se mantém a par.

---

## Apêndice — o que já se pode correr

Precisa de **Godot 4.6-stable** (fixado em `.godot-version`). Num *checkout*
frio, `make importar` primeiro — sem isso o motor não consegue abrir uma cena.

| O quê | Como | O que se vê |
|---|---|---|
| **O jogo** | `godot --path .` | A partida. Andas, largas moedas, recrutas, constróis, desces ao subsolo, e ao crepúsculo a mancha chega. |
| **A suite** | `make testes` | 255 casos. O `jogo_test.gd` e o `jogo_noite_test.gd` correm um dia e uma noite inteiros pelo `SimLoop`, em *headless*, com o mundo montado. |
| **Uma fotografia** | `make captura` | Escreve `build/empire.png`. Com `AVANCAR=` salta para qualquer ponto do dia sem esperar pelo relógio. |
| **As três faixas** | `godot --path . scenes/tests/bands.tscn` | A cena de prova do §53: as colunas e a matriz de colisão, medidas e não afirmadas. |
| **O dossiê** | `make ferramentas` | Escreve `ferramentas/saida/dossie-empire.html`. Não precisa do motor. |
| **Tudo de uma vez** | `make tudo` | Portões estáticos + dados + suite. É o que o CI corre, menos os exports e o dossiê. |

### Sem instalar o motor

Cada corrida verde do CI deixa três artefactos, e nenhum deles precisa do Godot:

| Artefacto | Como se corre |
|---|---|
| `empire-linux-debug` | `chmod +x empire.x86_64 && ./empire.x86_64` |
| `empire-windows-debug` | duplo clique no `empire.exe` (o `.pck` tem de ficar ao lado) |
| `empire-web` | `python3 -m http.server` dentro da pasta, e abrir `http://localhost:8000` |

O *preset* de Web tem `thread_support` desligado de propósito: não precisa dos
cabeçalhos COOP/COEP e por isso serve-se de qualquer servidor estático. Localmente
os três saem de `make exportar-tudo`.

### Os comandos, no teclado

| Tecla | O quê | Onde está escrito |
|---|---|---|
| **A** · **D** · ← → | Andar | §24, o mapa de comando |
| **Espaço** | Verbo 1 — largar uma moeda do teu saco | §02, §61 |
| **E** | Verbo 2 — entrar numa passagem e mudar de faixa | §11, §24 (Q-066) |
| **Botão direito** | Marcar alvo para os teus | §24, §50 |
| **Tab** | Painel de estado de cada sistema | Q-067 |
| **Esc** | Pausa | §24 |
| **Q** · **Z** | Câmara livre; volta sozinha em 2 s | §24 |

O ciclo é o do Kingdom, e está todo lá: largas uma moeda ao lado de quem não é de
ninguém e ele passa a ser teu (§25, minuto 0:20); largas moedas em cima de um
sítio de obra e ela levanta-se **enquanto alguém estiver em cima dela** (§55);
quem é teu e não tem posto anda atrás de ti, e quem tem vai para o posto quando a
fase muda (§52); os canteiros de pé largam moeda uma vez por fase (§49); ao
crepúsculo a mancha nasce na borda e gasta massa a invocar (§51); um muro de pé
trava quem vem, e quem morre larga o que transportava (§50). E **perde-se**: o
§10 diz que se o castelo-árvore cair, cai a partida, e é o que acontece — o
relógio pára e a entrada deixa de responder.
