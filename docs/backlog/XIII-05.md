# XIII-05 · §76 · O Nome

```text
Porque    A secção com o maior retorno emocional por hora da parte inteira, e nenhuma outra depende dela.
Spec      docs/design/76-ninguem-tem-nome-ate-merecer-um.md
Depende   F1-12
Contrato  o "Feito" é o contrato; os números vêm de data/ e da Spec
Feito     Nove nomes no máximo; o título ganha-se na alvorada; o luto de três dias devolve-o com ordinal
Fora      A encomendação cantada — é o XIII-09.
Estado    feito
Horas     11 (7 + 2 arte + 1 som + 1 escrita)
```

## Notas

- D-07 e D-08 já correm sobre os dados. Q-041: o teto é fixo.
- **Feito.** `NameSystem` (puro): os feitos contam-se no combate e na alvorada; na alvorada quem cumpriu
  um feito é nomeado, por id crescente, até ao `named_cap`; o décimo fica à espera e dá um passo à
  frente (uma seta, no *greybox*). Morto o dono, o título fica de luto `title_mourning_days` e volta com
  ordinal. Quem cai com nome pesa 45 como Amargueiro e rende 5 Lenho (§74). O Zelador leva um nomeado.
  A fita da cor do título vê-se (`NameView`). Testes: `tests/name_system_test.gd`, e o Zelador em
  `tests/oferta_jogo_test.gd`.
- **O que fica** (Q-088): quatro dos nove feitos observam-se hoje; só o +1 de vida tem efeito; a
  encomendação é do XIII-09; a fita definitiva e o *stinger* são arte e som.

---

Uma tarefa, uma sessão, um *merge* (§29). O campo **Fora** é o mais importante: é o que impede o agente — e a ti — de fazer três tarefas numa (§34). Se a tarefa depender de um valor marcado em `_proposed`, ou de uma pergunta aberta, diz-o em `docs/QUESTIONS.md` em vez de decidir.
