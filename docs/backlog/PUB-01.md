# PUB-01 · O jogo passa a jogar-se no browser

```text
Porque    A CI exporta o Web em cada corrida verde e o resultado é um artefacto que expira em 7
          dias, exige conta no GitHub, exige descompactar e exige servir a pasta. Ninguém a quem
          se queira mostrar o jogo faz esses quatro passos. O §36 e o §32 não começam sem um sítio
          onde se carrega e se joga.
Spec      docs/design/36-wishlists-pagina-demo-e-trailer.md
          docs/design/32-medir-sem-espiar.md
          docs/design/19-arquitetura-godot-4-6.md
Depende   F0-04
Contrato  o "Feito" é o contrato; os números vêm de data/ e da Spec
Feito     Um endereço público que serve a última main verde. O job `publicar` do ci.yml tem
          needs: [ci, export] — não arranca sobre um commit que não passou — e serve o artefacto
          empire-web dessa mesma corrida, byte a byte.
Falta     LIGAR O PAGES, e é um clique de quem tem admin: Settings > Pages > Build and deployment
          > Source: GitHub Actions. O GITHUB_TOKEN de uma corrida sabe publicar e não sabe criar o
          site (medido: "Resource not accessible by integration"), e a API do Pages está fora do
          alcance do agente. Até esse clique o job avisa e salta, e a main fica verde.
Fora      Releases com os binários de Linux e Windows — é outra decisão, para quando houver versões
          a nomear. Domínio próprio. Telemetria: o §32 é "medir sem espiar" e isto não mede nada.
Estado    por fazer
Horas     2
```

---

Uma tarefa, uma sessão, um *merge* (§29). O campo **Fora** é o mais importante: é o que impede o agente — e a ti — de fazer três tarefas numa (§34). Se a tarefa depender de um valor marcado em `_proposed`, ou de uma pergunta aberta, diz-o em `docs/QUESTIONS.md` em vez de decidir.
