# XIII-02 · §74 · O termo dos Amargueiros na massa

```text
Porque    Uma hora de código que transforma a curva de dificuldade de reta em consequência.
Spec      docs/design/74-a-podridao-ganha-uma-candeia-e-o-combustivel-es-.md
Depende   F1-08
Contrato  o "Feito" é o contrato; os números vêm de data/ e da Spec
Feito     O teste D-01 passa: 400 ao dia 20 em campo limpo, 466 com três árvores, 645 com cinco e três nomeadas
Fora      O Amargueiro como objeto no mundo — é o XIII-03.
Estado    feito
Horas     1
```

## Notas

- Os testes D-01 a D-03 já existem em tests/parte_xiii_rot_test.gd e passam sobre os dados.
- **Feito.** O D-01 media o modelo de referência; agora a mesma tabela sai do próprio `RotSystem` — as
  quatro linhas do dia 20 (400, 466, 576, 645) e a nota das três fortalezas (490) —, em
  `tests/rot_system_test.gd`. Mais três: as árvores só pesam na noite seguinte a serem contadas (a massa
  escreve-se ao crepúsculo), as recusas somam até ao teto e nunca mais, e o que o jogador escreveu de dia
  sobrevive ao save.
- O teto da contagem de recusas estava escrito no script (`RECUSAS_MAX := 5`). Passou a ler-se do
  `refusal_window_days` do `rot.csv`: uma recusa por noite, e por isso o teto da contagem é a janela.

---

Uma tarefa, uma sessão, um *merge* (§29). O campo **Fora** é o mais importante: é o que impede o agente — e a ti — de fazer três tarefas numa (§34). Se a tarefa depender de um valor marcado em `_proposed`, ou de uma pergunta aberta, diz-o em `docs/QUESTIONS.md` em vez de decidir.
