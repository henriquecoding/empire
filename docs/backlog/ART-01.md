# ART-01 · A primeira personagem real em cinco slots

```text
Porque    Sem uma personagem real na greybox, o critério de saída da pré-produção não se pode provar.
Spec      docs/design/58-composicao-por-slots.md
          docs/design/22-pipeline-de-pixel-art-e-a-paleta-mestra.md
Depende   F0-14, F0-15
Contrato  o "Feito" é o contrato; os números vêm de data/ e da Spec
Feito     Um vagabundo com os cinco slots, na paleta, a andar na greybox
Fora      As outras 21 unidades. Uma personagem chega para provar o circuito.
Estado    por fazer
Horas     8
```

## Notas

- Q-024: a camada Equipments dos teus ficheiros é o slot head? Fechar aqui.
- 26/09: o contrato de ações (`src/actors/actor_action.gd`) já liga `walk`, `work`, `attack`, `hit`, `flee`
  e `die` ao estado da simulação; uma tag nova no manifesto entra no jogo sem código. O que falta desenhar
  está em `docs/art/RUNTIME_ART.md`; o registo da execução em `docs/art/PLANO_VISUAL_EXECUCAO.md`.

---

Uma tarefa, uma sessão, um *merge* (§29). O campo **Fora** é o mais importante: é o que impede o agente — e a ti — de fazer três tarefas numa (§34). Se a tarefa depender de um valor marcado em `_proposed`, ou de uma pergunta aberta, diz-o em `docs/QUESTIONS.md` em vez de decidir.
