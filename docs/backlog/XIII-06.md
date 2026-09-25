# XIII-06 · §78 · A Colheita

```text
Porque    Dá corpo à melhor frase do dossiê — a escolha estava a ser feita desde o primeiro cerco.
Spec      docs/design/78-a-colheita-e-as-duas-maneiras-de-acabar-com-um-p.md
Depende   F1-16
Contrato  o "Feito" é o contrato; os números vêm de data/ e da Spec
Feito     C = 6 + 2 × povos; a aldeia fica fora das muralhas; soltar ou ficar, com o Verbo 1 no núcleo deles
Fora      O coro por povo — é o XIII-09. Os estandartes — entram aqui, por acessibilidade.
Estado    parcial — falta a conquista que a começa e o gesto da decisão (Q-095)
Horas     11 (8 + 3 arte)
```

## Notas

- Q-042: a sexta Colheita em 16 dias mede-se em playtest.
- §82: cada povo solto hasteia um estandarte — é a redundância visual do coro.
- **O sistema** (`HarvestSystem`) está inteiro, com os campos da §84: C = 6 + 2 × povos já detidos (a primeira dura 6, a sexta 16), metade arredondada para cima por assimilação; uma Colheita de cada vez, e a seguinte em fila a 100%; 140% de produção enquanto dura; no fim, espera pela decisão — ninguém decide por ti; soltar dá uma voz ao coro, ficar dá +80% e um marco com raiz; se a aldeia cair, perde-se o povo sem escolha.
- **Já ligado:** cada alvorada é um dia de Colheita (`NightWatch`), o marco de cada povo que ficou pesa +22 de massa por noite como um Amargueiro que não se corta, e o save leva tudo. Um teste confere que o `keep_landmark_mass` e o `mass_per_amargueiro` são o mesmo número.
- **Por ligar (Q-095):** a conquista (§13) que chama `conquer()` ainda não existe, nem aldeias no greybox; o Verbo 1 no núcleo deles tem duas saídas e o dossiê não diz como se distingue soltar de ficar; os estandartes do §82 não têm cor por povo em `peoples.csv`.

---

Uma tarefa, uma sessão, um *merge* (§29). O campo **Fora** é o mais importante: é o que impede o agente — e a ti — de fazer três tarefas numa (§34). Se a tarefa depender de um valor marcado em `_proposed`, ou de uma pergunta aberta, diz-o em `docs/QUESTIONS.md` em vez de decidir.
