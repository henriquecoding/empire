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
Feito     Um endereço público que serve a última main: a página de entrada, o jogo em /jogar/ e o
          dossiê em /dossie/, construídos de raiz em cada push por tools/web/construir.sh (ADR 0024,
          que substitui a 0022). Cada PR tem a sua pré-visualização.
Fora      Releases com os binários de Linux e Windows — é outra decisão, para quando houver versões
          a nomear. Domínio próprio. Telemetria: o §32 é "medir sem espiar" e isto não mede nada.
Estado    feito — a produção segue a main: medido a 25/09/2026, o /versao.json de
          empire-phi-eight.vercel.app diz ramo main, ambiente production (tools/web/fumo.mjs)
Horas     2
```

---

Uma tarefa, uma sessão, um *merge* (§29). O campo **Fora** é o mais importante: é o que impede o agente — e a ti — de fazer três tarefas numa (§34). Se a tarefa depender de um valor marcado em `_proposed`, ou de uma pergunta aberta, diz-o em `docs/QUESTIONS.md` em vez de decidir.
