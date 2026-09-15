# XIII-01 · §80 · O preto na paleta e a noite castanha

```text
Porque    É a única dependência dura de calendário da parte inteira: o teto de valores tem de ser decidido antes de se desenhar cenário.
Spec      docs/design/80-o-preto-entra-na-paleta-e-a-noite-deixa-de-ser-a.md
Depende   ART-02
Contrato  o "Feito" é o contrato; os números vêm de data/ e da Spec
Feito     Os tints das seis fases vêm do clock.tres; o teste das duas frias corre no CI
Fora      A candeia — é o XIII-03.
Estado    feito
Horas     4 (2 código + 2 arte)
```

## Notas

- ADR 0011. A Q-037 está fechada; a tabela da §05 já foi corrigida.
- **As duas metades do contrato, e onde estão.** Os tints: `src/world/band_light.gd`, lidos do
  `clock.tres` — as seis fases, com a noite em 32° · 0,22 · 0,16 e o chão em 0,11, e a passagem
  entre fases feita de MEIO a MEIO. O teste das duas frias: `tools/check_silhueta.py`, no job
  `silhueta` do CI, sobre uma fotografia do meio da noite. Corre-se à mão com `make silhueta`.
- **Nenhum dos quatro limiares está escrito no script.** Os 200°–290°, a saturação de 0,35 e os
  0,5% do ecrã são lidos da própria linha *Duas frias* da tabela da §80 §5, em `docs/design/`.
  Mudar o dossiê muda o portão; e se a linha desaparecer, o portão chumba a dizê-lo em vez de
  medir uma regra que já não existe.
- **O que do §80 §5 este ticket NÃO fecha**, e porquê — a tabela tem quatro linhas e só uma
  se automatiza hoje: *teto de valores por camada* precisa dos PNG das camadas de parallax
  (ART-03); *rampa de densidade* é sobre a arte e o greybox de cores chapadas chumbava por
  construção (GB-03); *leitura a 1 bit* o próprio §80 escreve como "manual, uma vez por ecrã
  acabado". A metade dela que se mede está noutro sítio: o `tests/outline_test.gd` guarda que
  duas formas nunca desenham a mesma coisa, que é o que nenhum limiar separa depois.
- **O portão foi provado a chumbar, e não só a passar** — um portão que não sabe falhar não guarda
  nada. Sobre a captura real: a noite da v5.2 (a mesma imagem com o matiz rodado para o azul
  profundo) dá **0,757%** e chumba; violeta **fora** da mancha chumba; violeta **dentro** dela
  passa, que é a excepção que o §80 escreve; e uma captura de uma cor só — o `xvfb` que não
  arrancou — chumba a dizê-lo, em vez de passar por não ter um único píxel frio.
- Os três valores de silhueta do §80 §1 continuam por entrar na paleta: são ART-02.

---

Uma tarefa, uma sessão, um *merge* (§29). O campo **Fora** é o mais importante: é o que impede o agente — e a ti — de fazer três tarefas numa (§34). Se a tarefa depender de um valor marcado em `_proposed`, ou de uma pergunta aberta, diz-o em `docs/QUESTIONS.md` em vez de decidir.
