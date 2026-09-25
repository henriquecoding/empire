# XIII-03 · §74 · O Amargueiro e a candeia, completos

```text
Porque    É o melhor rácio da parte inteira: 11 h de código e 3 de arte para a alavanca 2.
Spec      docs/design/74-a-podridao-ganha-uma-candeia-e-o-combustivel-es-.md
          docs/design/55-buildsystem-moeda-fisica-slots-pre-definidos.md
Depende   XIII-02, F1-06, ART-04
Contrato  o "Feito" é o contrato; os números vêm de data/ e da Spec
Feito     Os três destinos com o Verbo 1; a cara na casca; a candeia com raio e cor do rot.tres
Fora      A Oferta — é o XIII-04. O cante da alvorada — é o XIII-09.
Estado    parcial — falta a Semente Real e a arte (ART-04)
Horas     13 (10 + 3 arte)
```

## Notas

- Q-047: uma noite de pé, ou mais? A proposta é uma, fixa.
- O Lenho Amargo não tem preço (regra 1) — o D-02 chumba se alguém lhe der um.
- **O que está feito.** `src/sim/systems/amargueiro_system.gd`, em colunas como as tropas, e
  `tests/amargueiro_system_test.gd`. Na Alvorada quem morreu fora das muralhas cria raiz (no subsolo
  também; no ar cai; dentro das muralhas e sobre um Marco desaparece) e os mortos saem das colunas das
  tropas. A massa do crepúsculo conta as árvores de pé (`NightWatch`), e os Marcos entram como terreno
  consagrado no `rot.tick()`. **Cortar** pelo Verbo 1: as moedas pousadas na base pagam as 6 do
  `amargueiros.csv`, só depois de uma noite de pé (regra 2 — antes disso ficam no chão), e os 12 s
  andam com quem lá está; rende 1 · 2 · 3 Lenho pela escala, ou 5 se era nomeado (regra 3), e o Lenho é
  um inteiro, não uma moeda (regra 1). O pagamento anuncia-se com `coin_spent` e o Lenho com
  `material_produced`. Grava-se no save. **A cara na casca**, em *greybox*: `src/world/amargueiro_view.gd`,
  com o preço do corte por cima quando o rei está na base, pelo mesmo gesto do GB-05. **A candeia** já
  vinha do F1-17.
- **O que falta, e porquê** (Q-086): *consagrar* está escrito e testado mas não tem gesto — não há onde
  guardar uma Semente Real. O Lenho acumula-se e ainda não se gasta na muralha de nível 4. O tronco e a
  cara definitivos são do ART-04.

---

Uma tarefa, uma sessão, um *merge* (§29). O campo **Fora** é o mais importante: é o que impede o agente — e a ti — de fazer três tarefas numa (§34). Se a tarefa depender de um valor marcado em `_proposed`, ou de uma pergunta aberta, diz-o em `docs/QUESTIONS.md` em vez de decidir.
