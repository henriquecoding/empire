# ADR 0022 — O jogo publica-se no GitHub Pages, e o portão é o `needs:`

- Estado: aceite
- Data: 2026-09-16
- Secção do dossiê: §19, §26, §32, §36

## Contexto
O `ci.yml` exporta Linux, Windows e Web em cada corrida verde e faz `upload-artifact` com os três. Isso resolve o
problema de *guardar* um build e não resolve nenhum dos outros: um artefacto de workflow expira em 7 dias, obriga
a ter conta no GitHub para o descarregar, obriga a descompactar, e no caso do Web obriga ainda a servir a pasta de
um servidor local. Ninguém a quem se queira mostrar o jogo faz esses quatro passos.

O §36 precisa de *wishlists*, página e trailer; o §32 quer medir sem espiar; o §26 quer o jogo experimentado em
Steam Deck e em teclado. Nenhuma dessas coisas começa sem **um sítio onde se carrega e se joga**.

O preset `Web` do `export_presets.cfg` já está preparado para isto: tem `thread_support` desligado de propósito,
não precisa dos cabeçalhos COOP/COEP, e por isso serve-se de qualquer servidor estático — o `ci.yml` diz-o com
todas as letras (*"o `python3 -m http.server` chega"*). O GitHub Pages é o servidor estático que este repositório
já tem, sem conta nova, sem fatura e sem segredo para guardar.

## Decisão
**O jogo publica-se no GitHub Pages a partir da `main`, e o portão é o `needs:` do próprio `ci.yml`.**

O job `publicar` tem `needs: [ci, export]` e `if: success() && github.ref == 'refs/heads/main'`. O job `ci` é o
que já existia para a protecção de ramo e só fica verde com os cinco portões verdes — por isso o `publicar` não
pode sequer **arrancar** sobre um commit que não passou. E não reconstrói nada: serve o artefacto `empire-web`
que o job do export produziu **nesta mesma corrida**, byte a byte.

As permissões (`pages: write`, `id-token: write`) ficam declaradas **no job** e não no workflow, contra a linha de
abertura do `ci.yml` (*"nenhum job deste workflow escreve no repositório"*) — a excepção é uma, e vê-se onde está.

**O Pages não se liga sozinho, e isso está medido.** O `GITHUB_TOKEN` de uma corrida sabe *publicar* no Pages e
não sabe *criá-lo*: com `enablement: true` no `configure-pages`, a corrida chumbou com *"Create Pages site failed:
Resource not accessible by integration"*. Ligar o Pages é um clique de quem tem `admin` no repositório, e uma vez
só — **Settings → Pages → Build and deployment → Source: GitHub Actions**.

Por isso o job **pergunta primeiro**, com um `gh api repos/.../pages`. Sem Pages ligado, avisa e salta os passos
seguintes em vez de chumbar: pintar a `main` de vermelho por causa de uma definição do repositório é dar o alarme
a quem não pode fazer nada com ele, e um `::warning::` que nomeia os dois cliques diz mais do que um `HttpError`.
Na primeira corrida depois de alguém ligar o interruptor, publica sozinho.

## Alternativas consideradas
**Um `pages.yml` separado, accionado por `workflow_run` depois do `ci`.** Foi a primeira decisão desta ADR, e foi
**escrita, empurrada, fundida na `main` — e não funcionou.** O `workflow_run` tem um arranque a frio que só se
descobre a tentar: o GitHub resolve a lista de subscritores a partir dos workflows **já registados**, e um
workflow cujos únicos gatilhos são `workflow_run` e `workflow_dispatch` nunca chega a ser registado pelo push que
o introduz. Medido: quinze minutos depois do merge e do `ci` verde na `main`, o `GET
/actions/workflows/pages.yml` devolvia **404**, o workflow não aparecia na lista, e nem o `workflow_dispatch` o
alcançava — não há botão para carregar num workflow que não existe. Rejeitada por não arrancar.

As três razões que na altura justificaram separá-lo não sobreviveram ao exame:

| Razão escrita então | O que se confirmou |
|---|---|
| *"cancelar um deploy a meio deixa o Pages a servir metade de um jogo"* | **Exagerado.** Um deploy do Pages é a troca atómica de um artefacto: cancelá-lo deixa a versão anterior servida, não meia. |
| *"o `ci.yml` corre em todos os ramos"* | Verdade, e resolve-se com uma linha: `if: github.ref == 'refs/heads/main'`. |
| *"o `ci.yml` abre a dizer que nenhum job escreve"* | Verdade, e a resposta certa não é outro ficheiro: é declarar a permissão **no job**, que é onde uma excepção se lê. |

**Reexportar o Web em vez de reusar o artefacto.** Era o que o `pages.yml` fazia, e custava outro `checkout`,
outro motor e outro 1,2 GB de *templates*. Dentro da mesma corrida o artefacto já existe e é exactamente o que os
portões viram — reexportar dava o mesmo jogo por mais dinheiro e com uma garantia mais fraca.

**Um GitHub Release com os três binários.** Resolve o download permanente e não resolve o que falta: continua a
não haver onde **carregar e jogar**. Não se exclui — é outra decisão, para quando houver versões a nomear.

**Publicar a cada push em vez de a cada `ci` verde.** Tira o portão de onde ele interessa: o único sítio onde um
erro fica visível para fora.

## Consequências
Passa a haver um endereço para dar a alguém, e ele mostra sempre a última `main` verde. O §36 e o §32 ganham a
coisa de que precisavam primeiro. Um chumbo na CI deixa de ser só um chumbo: passa a ser também *o que não foi
publicado*, e isso é uma segunda razão para o manter verde.

Três dependências novas, todas oficiais do GitHub e todas já vigiadas pelo `dependabot.yml` no ecossistema
`github-actions`, sem uma linha a mudar nesse ficheiro: `actions/configure-pages`, `actions/upload-pages-artifact`
e `actions/deploy-pages`. Nenhum segredo: o Pages usa o `GITHUB_TOKEN` da corrida.

O repositório é público, e por isso o Pages não custa nada e não expõe nada que já não estivesse exposto — o que
se serve é a pasta `build/web/` e mais nada. Se um dia passar a privado, o Pages privado exige plano pago e o
`deploy-pages` chumba com uma mensagem clara, sem publicar nada de errado.

**A lição, e é a que fica:** um deploy que depende de um gatilho que nunca disparou é indistinguível de não haver
deploy. Um `needs:` dentro da corrida que já existe não tem arranque a frio, não tem lista de subscritores e não
tem *token* cruzado — e é um portão mais forte, porque o job não arranca em vez de arrancar e desistir.

Reverter isto é apagar um job. Nada no jogo depende dele.
