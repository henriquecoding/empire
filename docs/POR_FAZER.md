# Por fazer — o que falta, e o que já se pode correr

> **Isto é uma fotografia, tirada a 15/09/2026, depois do núcleo jogável.** A fonte
> é `docs/backlog/`, um ficheiro por ticket, e é lá que o estado muda — não aqui.
> Todos os números desta página saem de comandos que estão escritos ao lado
> deles, para que se possa desconfiar e voltar a contar. É a mesma regra do
> `AGENTS.md`: *não escrevas à mão um número que a ferramenta conta.*

## Onde é que isto está

| | |
|---|---|
| Tickets | **53**, dos quais **32 feitos** e **21 por fazer** |
| Fase 0 | 14 de 16 — faltam dois, e nenhum dos dois é código |
| Fase 1 | 16 de 17 — o F1-01 ao F1-16, inteiros. Falta o F1-17 |
| Suite | 336 casos, 328 a passar, 8 saltados, 0 falhas, 0 *orphans* |
| `SimLoop` | **9 dos 11 passos** do §43 escritos; faltam o 9 (Dívida: XIII-04; Diplomacia: Fase 2) e o 10 (Fase 2) |
| Perguntas em aberto | 65 das 67 de `docs/QUESTIONS.md` — a Q-006 fechou com o F1-07, a Q-075 com o F1-16 |

```bash
# a contagem de cima, a partir da árvore
for f in docs/backlog/*.md; do [ "$(basename $f)" = README.md ] && continue
  grep -m1 '^Estado' "$f" | sed 's/^Estado *//'; done | sort | uniq -c
# as perguntas escritas
grep -c '^### Q-' docs/QUESTIONS.md
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

## Fase 1 — 1 por fazer

**O critério de saída da Fase 1 está medido e passa.** O §66 pede *"sobreviver 10
dias é possível e não é trivial"*, e as duas metades têm teste: a defesa do décimo
dia — um Bastião, a muralha de ferro no outro flanco, as duas torres e doze
arqueiros — aguenta dez noites inteiras com o castelo-árvore intacto; a receita do
§07 — estacaria, seis arqueiros, sem torre — cai ao terceiro dia, e os sete
degraus entre uma e outra caem todos.

| | O que é | Porque está parado |
|---|---|---|
| F1-17 | Arte da mancha: a Podridão e a candeia | **ART-02**: a paleta mestra e o LUT. Vê-se chegar do horizonte; a candeia tem três paragens e domina o ecrã. |

O instrumento dos dois critérios corre-se sem o motor aberto:

```bash
godot --headless --path . scenes/tests/night_test.tscn   # §07: dez noites, com torre e sem ela
godot --headless --path . scenes/tests/dez_dias.tscn     # §66: nove defesas, dez dias cada
```

E o que as duas tabelas ainda não dizem está escrito, não calado: a **Q-073** (o
§07 monta o microteste com seis arqueiros e a estacaria do §10 só tem um posto de
guarda — e o nível 1 é *"a base comum aos dois caminhos"*, por isso não é
afinável), a **Q-074** (os dez dias custam 9 a 11 s conforme o *runner*, e o §66
pede menos de 10) e a **Q-076** (o Alado atravessa a muralha, pousa no castelo e
não faz nada — é do F1-09). Os três testes correspondentes estão saltados com
essas razões em `tests/noite_do_07_test.gd` — **nenhum valor de `data/` foi
mexido** para os calar, que é o que o `AGENTS.md` manda.

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
  de muralha, quatro canteiros, dois galinheiros, um pesqueiro, duas casas de
  treino, duas torres de arqueiros, duas torres altas, duas passagens para o
  subsolo e nove pessoas por recrutar. As sete fontes de produção são as sete do
  perfil `balanced` do §06 — é isso que faz do dia da asfixia um número sobre
  este jogo.
- **As cinco acções de *input* que estavam declaradas e por ler estão ligadas.**
  Nenhuma delas muda estado directamente: cada uma enfileira uma **intenção**, e o
  início do tick seguinte consome-a, pela ordem em que chegou (§61).
  ```bash
  for a in verb_drop verb_assume king_wheel mark_target pause; do
    echo "$a: $(grep -rn "&\"$a\"" src/ --include='*.gd' | wc -l)"; done
  ```
- **Nove dos onze passos do `SimLoop`** estão escritos. Faltam dois, e cada um
  continua a ser uma linha com o ticket que a preenche: o 9 (a Dívida é a XIII-04,
  a diplomacia é Fase 2) e o 10 (IA do rei inimigo, Fase 2).

## O que falta e não é ticket nenhum

- **O mundo é um *greybox* montado em código, e não as nove cenas de segmento.**
  Elas não sobreviveram ao ZIP recuperado (Q-048). O `src/world/greybox.gd` põe a
  mesma região que o §21 descreve — seis ecrãs de 640 px, dois *slots* de
  construção e uma passagem por segmento, lidos do `segments.csv` — mas em código
  e não autorada. É a GB-01 que o substitui.
- **Não há um sprite.** Tudo o que se vê são rectângulos: `src/world/band_view.gd`
  desenha as tropas, as criaturas, as moedas, as obras e a mancha com `draw_rect`,
  uma faixa de cada vez.
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
- **Não há menu.** O jogo retoma o autosave mais recente, ou começa de novo se não
  houver nenhum, se o núcleo tiver caído, ou se se passar `--novo`. Escolher slot
  é o §18, e é a Fase 8.
- **Áudio:** 73 pistas escritas na bíblia, zero gravadas.
- **65 perguntas em aberto** em `docs/QUESTIONS.md`, de 67 escritas — a Q-006
  fechou com o F1-07 e a Q-075 com o F1-16. As treze mais recentes (Q-064 a
  Q-076) são as que encher o tick, medir a noite e afinar os dez dias obrigaram a
  fazer. As quatro que valem a pena ler primeiro: a **Q-076** (o Alado atravessa
  a muralha, pousa no castelo e não faz nada — e por isso os dias 4 a 6 do §07
  não custam nada a ninguém), a **Q-073** (o §07 monta o microteste com seis
  arqueiros e o muro do §10 só tem um posto de guarda), a Q-068 (o §25 diz três
  Rastejantes na noite 1 e a massa do §74 dá sete) e a Q-072 (o §06 dá três
  estados de risco ao rasto e o §49 só escreve dois).
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
| **O jogo** | `godot --path .` | A partida. Andas, largas moedas, recrutas, constróis, desces ao subsolo, e ao crepúsculo a mancha chega. Retoma o autosave da última alvorada. |
| **Uma partida do zero** | `godot --path . -- --novo` | O mesmo, ignorando o save. É o que se usa para repetir uma noite. |
| **A suite** | `make testes` | 335 casos. O `jogo_test.gd` e o `jogo_noite_test.gd` correm um dia e uma noite inteiros pelo `SimLoop`, em *headless*, com o mundo montado. |
| **A noite, medida** | `godot --headless --path . scenes/tests/night_test.tscn` | O cenário fechado do §07: dez noites, com torre e sem ela, e por noite as invocadas, os abates, as mortes e quantas chegaram a encostar ao muro. |
| **Os dez dias, medidos** | `godot --headless --path . scenes/tests/dez_dias.tscn` | O critério de saída da Fase 1 (§66): oito defesas, dez dias cada, e por cada uma se aguentou, em que dia caiu, e com que margem ficou o castelo-árvore. |
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
