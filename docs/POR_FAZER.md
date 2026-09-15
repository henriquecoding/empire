# Por fazer — o que falta, e o que já se pode correr

> **Isto é uma fotografia, tirada a 15/09/2026 sobre o commit `baec82b`.** A fonte
> é `docs/backlog/`, um ficheiro por ticket, e é lá que o estado muda — não aqui.
> Todos os números desta página saem de comandos que estão escritos ao lado
> deles, para que se possa desconfiar e voltar a contar. É a mesma regra do
> `AGENTS.md`: *não escrevas à mão um número que a ferramenta conta.*

## Onde é que isto está

| | |
|---|---|
| Tickets | **53**, dos quais **20 feitos** e **33 por fazer** |
| Fase 0 | 14 de 16 — faltam dois, e nenhum dos dois é código |
| Fase 1 | 4 de 17 — F1-01, F1-02, F1-03 e F1-04 |
| Suite | 173 casos, 168 a passar, 5 saltados, 0 falhas, 0 *orphans* |
| CI | cinco *jobs* verdes na mesma corrida (#19, #20, #21) |
| Perguntas em aberto | 54, em `docs/QUESTIONS.md` |

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

## Fase 1 — 13 por fazer

**Desbloqueados agora** (as dependências estão todas feitas):

| | O que é | Depende de | Critério de aceitação (o "Feito" do ticket) |
|---|---|---|---|
| **F1-05** | JobBoard — o prompt 4 da §29 | F1-03 ✔ | Os quatro testes do prompt passam; a tropa vai ao posto certo e volta à alvorada |
| **F1-08** | RotSystem — o prompt 2 da §29 | F0-06 ✔ | Os seis testes do prompt passam e a mancha vê-se no horizonte ao crepúsculo |
| **F1-10** | Economia e a `curve.tres` — o prompt 3 da §29 | F1-01 ✔ | O dia da asfixia cai entre 9 e 14, e os três perfis batem com o alvo próprio |
| **F1-13** | `CanvasModulate` por faixa, animado pelo `GameClock` | F0-06 ✔ | As seis fases são distinguíveis sem HUD; a noite é castanha (ADR 0011) |

**À espera de outro ticket:**

| | O que é | Depende de | Critério de aceitação |
|---|---|---|---|
| F1-06 | Muro: cinco níveis, dois caminhos, slots de contacto | F1-05 | A tabela do §10 replicada em `.tres`; `test_muralhas_do_10` passa |
| F1-07 | Arqueiro: alcance, precisão 0,34 em campo e 1,0 em torre | F1-06 | O tempo até matar medido bate com a tabela do §07, em valor esperado |
| F1-09 | Criaturas: Rastejante, Alado, Bruto e a tabela de invocação | F1-08 | A noite 4 obriga a torre alta; o Alado só é atingido por quem chega à faixa aérea |
| F1-11 | Plantação, pesqueiro e galinheiro com os valores do §06 | F1-10 | *Payback* de 2 dias medido em jogo; `test_payback_do_06` continua a passar |
| F1-12 | Moral e fuga com o raio do rei | F1-05 | Com o rei em campo ninguém foge; fora do raio, foge ao limiar de vida dos dados |
| F1-14 | Save e load do estado de `src/sim/` com `save_version` | F1-10 | Fechar e reabrir no dia 7 preserva tudo, incluindo a sequência aleatória |
| F1-15 | Cenário de combate noturno para afinação | F1-09 | A noite 5 ganha-se com 1 a 2 mortes; corre em *headless* com delta fixo |
| F1-17 | Arte da mancha: a Podridão e a candeia | F1-08, **ART-02** | Vê-se chegar do horizonte; a candeia tem três paragens e domina o ecrã |
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

## O que falta e não é ticket nenhum

- **Não existe cena de jogo.** Há duas cenas no projeto: `scenes/boot.tscn` e
  `scenes/tests/bands.tscn`. Nenhuma põe um monarca, um vagabundo e uma moeda no
  mundo ao mesmo tempo — o minuto 0:20 do §25 acontece na simulação e é provado
  por teste, mas não há ecrã onde se veja.
- **Cinco ações de input estão declaradas e ninguém as lê:** `verb_drop`,
  `verb_assume`, `king_wheel`, `mark_target` e `pause` existem no `project.godot`
  com **zero** usos em `src/`. O `verb_drop` é o botão de largar a moeda.
  ```bash
  for a in verb_drop verb_assume king_wheel mark_target pause; do
    echo "$a: $(grep -rn "&\"$a\"" src/ --include='*.gd' | wc -l)"; done
  ```
- **Sete dos onze passos do `SimLoop`** estão escritos como linha vazia, cada um
  com o ticket que o preenche — 2, 3, 6, 7, 8, 9 e 10. Abrir
  `src/core/sim_loop.gd` mostra o esqueleto do jogo inteiro de uma vez.
- **As nove cenas de segmento** não sobreviveram ao ZIP recuperado. É a Q-048.
- **Áudio:** 73 pistas escritas na bíblia, zero gravadas.
- **54 perguntas em aberto** em `docs/QUESTIONS.md`, à espera de decisão — a mais
  recente é a Q-063, com os três números que o F1-04 teve de propor.
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
| **A suite** | `make testes` | 173 casos. O `minuto_0_20_test.gd` corre a sequência do §25 inteira pelo `SimLoop` e é a prova a sério do F1-04. |
| **As três faixas** | `godot --path . scenes/tests/bands.tscn` | A **única coisa interativa** que existe: setas movem o andarilho, a câmara segue, e as colunas provam a matriz do §53. |
| **A cena principal** | `godot --path .` | Céu, corte de solo, um *placeholder*, e o dia e a fase a avançarem em tempo real. Sem tropas nem moedas. |
| **Sem instalar o motor** | Artefacto `empire-linux-debug` de qualquer corrida verde do CI | O mesmo que a linha de cima, já exportado (Linux). |
| **O dossiê** | `make ferramentas` | Escreve `ferramentas/saida/dossie-empire.html`. Não precisa do motor. |
| **Tudo de uma vez** | `make tudo` | Portões estáticos + dados + suite. É o que o CI corre, menos o export e o dossiê. |
