# XIII-05 · §76 · O Nome

```text
Porque    A secção com o maior retorno emocional por hora da parte inteira, e nenhuma outra depende dela.
Spec      docs/design/76-ninguem-tem-nome-ate-merecer-um.md
Depende   F1-12
Contrato  o "Feito" é o contrato; os números vêm de data/ e da Spec
Feito     Nove nomes no máximo; o título ganha-se na alvorada; o luto de três dias devolve-o com ordinal
Fora      A encomendação cantada — é o XIII-09.
Estado    feito — 5 dos 9 feitos com o que observar (Q-094)
Horas     11 (7 + 2 arte + 1 som + 1 escrita)
```

## Notas

- D-07 e D-08 já correm sobre os dados. Q-041: o teto é fixo.
- **Os sistemas.** `FeatLedger` regista os feitos — quem abateu o quê (o último golpe numa criatura, lido dos acontecimentos que o CombatSystem já devolve), noites em posto de cerco (muro e torre), quem esteve dentro da mancha, dias com a mesma arma. `TitleSystem` dá os nomes, com os campos da §84: `titles_holder`, `titles_ordinal`, `titles_mourning`.
- **O título ganha-se na alvorada**, nunca por escolha: a `NightWatch` corre-o a seguir aos Amargueiros. Quem espera primeiro; depois por id (§42).
- **Nove no máximo**, e a décima fica à espera — com nove títulos únicos, o teto e a unicidade coincidem: quem cumpre um feito cujo título tem dono fica "um passo à frente" até ele abrir.
- **Morto o dono, três dias de luto, e volta com ordinal** — o segundo que o ganha é O Segundo Que Ficou. Morrer, criar raiz ou ser levado pela Oferta ou pelo Zelador são o mesmo para o título.
- **Os nomes chegam onde a Parte XIII os pede:** um nomeado morto lá fora é um Amargueiro nomeado (+45 de massa, 5 Lenho), porque os nomes se leem antes de os corpos se levantarem; a Oferta e o Zelador leem os nomes verdadeiros.
- **A fita** (§58, slot overlay) na cor de `titles.csv`; quem espera por vaga tem só o contorno. O monarca e os vagabundos por recrutar não ganham nome.
- Das nove bonificações só a vida máxima se aplica hoje; quatro dos nove feitos dependem de portões, arrastar corpos, cozinha e ressurreição (Q-094). A encomendação cantada é o XIII-09.

---

Uma tarefa, uma sessão, um *merge* (§29). O campo **Fora** é o mais importante: é o que impede o agente — e a ti — de fazer três tarefas numa (§34). Se a tarefa depender de um valor marcado em `_proposed`, ou de uma pergunta aberta, diz-o em `docs/QUESTIONS.md` em vez de decidir.
