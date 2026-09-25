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
- **O termo já estava escrito, e só o modelo o provava.** `RotSystem._massa_do_dia()` somava os Amargueiros desde o F1-08, mas o D-01 corre contra `tests/support/reference_model.gd` — nenhum teste punha uma árvore no sistema real. Agora `tests/rot_system_test.gd` corre a tabela inteira da §74 (as quatro linhas nos dias 5, 10 e 20) sobre o `RotSystem`, e confere cada célula contra o modelo.
- **A massa escreve-se ao crepúsculo.** Uma árvore que nasce com a mancha já no campo só pesa na noite seguinte — é o "alimenta a noite seguinte" da §74, com teste.
- **O save guarda o que o jogador escreveu de dia**: fortalezas, Amargueiros e nomeados atravessam o `to_dict`/`from_dict` e a massa lida é a mesma.
- Provado a chumbar: sem o termo das árvores, os testes novos falham.
- Quem escreve `amargueiros` e `named_amargueiros` no `RotSystem` é o AmargueiroSystem do XIII-03. Até lá ficam a zero, e a massa é a do campo limpo.

---

Uma tarefa, uma sessão, um *merge* (§29). O campo **Fora** é o mais importante: é o que impede o agente — e a ti — de fazer três tarefas numa (§34). Se a tarefa depender de um valor marcado em `_proposed`, ou de uma pergunta aberta, diz-o em `docs/QUESTIONS.md` em vez de decidir.
