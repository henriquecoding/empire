# 39 — Contrato · A especificação técnica começa aqui

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

As trinta e nove secções anteriores respondem a que jogo é este e se vale a pena fazê-lo. As vinte e nove que se seguem respondem a que ficheiros existem, que campos têm, por que ordem correm e como se sabe que estão certos. São públicos diferentes: a primeira metade é para ti; esta é para ti e para os agentes que escrevem o código.

> **Porque é que isto é a peça que faltava**
>
> O teu plano é que a IA escreva quase todo o código e tu revejas. Uma revisão só existe se houver contra o que rever. Sem especificação, cada sessão de agente reinventa nomes de campos, ordem de execução e contratos de módulo, e tu passas o tempo a arbitrar decisões que já tinhas tomado — sem te lembrares de quando.
>
> A §19 tem definições de projeto, estrutura de pastas, um exemplo de Resource e uma lista de truques de desempenho. É um esboço de arquitetura. Esta parte é a especificação: todos os recursos, todos os eventos, a ordem do tick, a disciplina de aleatoriedade, o esquema do save e os critérios de aceitação.

## Autoridade

| Assunto | Manda | Regra de conflito |
| --- | --- | --- |
| Design, números de balanceamento, intenção | §00 a §38 | Se uma secção de §39 a §67 contradiz um número das secções anteriores, é ela que está errada. Corrige-a. |
| Nomes de classes, campos, sinais, ficheiros | §39 a §67 | Se o código não bate certo com o nome daqui, o código está errado. Sem exceções — nomes divergentes são o que quebra a geração assistida. |
| Ordem de execução e contratos de módulo | §39 a §67 | Alterações exigem subida de versão do documento e uma linha no registo de alterações. |
| Arte, densidade, paleta, camadas | §01, §11, §22 | Aqui só entram as consequências técnicas (nomenclatura de exportação, uniforms de shader, ordem de camadas). |


## O que ainda falta ao projeto, depois desta parte

Para não ficares com a ideia de que isto fecha tudo. O mapa honesto do que existe e do que não:

| Documento | Estado | Onde vive | Prioridade |
| --- | --- | --- | --- |
| GDD — design, sistemas, progressão, UX | Existe e está bom | §04 a §27 | — |
| Bíblia de arte | Existe — arrumada na v5.2 | §01 · §11 · §21 · §22, e docs/art/ (§71) | Baixa — o artista és tu e escreveste-a |
| Especificação técnica | §39 a §67 | Esta parte | Era a que faltava |
| Base de dados de conteúdo — as tabelas como fonte única | Existe desde a v5.2 | data/source/: 23 tabelas geradas para .tres e conferidas contra este dossiê pelo CI (§71) | Feita — falta aprovares as propostas |
| Bíblia de nomes e lore | Proposta na v5.2 | docs/content/NAMING_BIBLE.md; o nome do jogo continua por escolher | Média — bloqueia o §36 |
| Especificação da fatia vertical | Parcial | §33 tem critérios de saída, §34 tem 30 tickets | Fases 0 e 1 na Parte X; os tickets em docs/backlog/ (v5.2) |


> **Como um agente deve usar esta parte**
>
> O CLAUDE.md do repositório aponta para aqui e diz três coisas: (1) nunca inventes um nome que as §39 a §67 já definem; (2) nunca acrescentes um sinal que não esteja no catálogo da §46; (3) se precisares de algo que não está especificado, para e pergunta em vez de decidir. A terceira é a que poupa mais tempo.
