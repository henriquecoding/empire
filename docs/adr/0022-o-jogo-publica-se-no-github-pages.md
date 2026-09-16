# ADR 0022 — O jogo publica-se no GitHub Pages, e só o que passou nos portões

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
**O jogo publica-se no GitHub Pages a partir da `main`, e publica-se o commit que passou nos portões.**

O `pages.yml` corre por `workflow_run` **a seguir** ao `ci`, e só quando ele acaba **verde** e **na main**. Faz
`checkout` do `head_sha` dessa corrida — e não da ponta da `main` —, exporta com o mesmo `make exportar-web` que
a CI já corre, e entrega a pasta ao Pages.

Fica **fora** do `ci.yml`, por três razões e não uma: o `ci.yml` tem `cancel-in-progress: true` e cancelar um
deploy a meio deixa o site a servir metade de um jogo; o `ci.yml` corre em todos os ramos e publicar um ramo de
trabalho é publicar trabalho por acabar; e o `ci.yml` abre a dizer *"nenhum job deste workflow escreve no
repositório"* — um deploy escreve, e a permissão fica visível num ficheiro só.

## Alternativas consideradas
**Um job no `ci.yml` com `if: github.ref == 'refs/heads/main'`.** Poupava um ficheiro e herdava as três
propriedades erradas acima. A do `cancel-in-progress` é a que decide: é a única que corrompe o que já está
publicado, e não apenas a corrida.

**Descarregar o artefacto `empire-web` da corrida do `ci` em vez de exportar outra vez.** Publicaria os *bytes*
exactos que os portões viram, e é mais rápido — mas obriga a um `download-artifact` com `run-id` e *token*
cruzado, e passa a depender da retenção de 7 dias do artefacto. Exportar de novo a partir do mesmo `head_sha` com
o mesmo alvo do `Makefile` dá o mesmo jogo por um caminho que se lê de uma vez. Rejeitada por custo de leitura,
não por correcção.

**Um GitHub Release com os três binários.** Resolve o download permanente e não resolve o que falta: continua a
não haver onde **carregar e jogar**. Não se exclui — é outra decisão, para quando houver versões a nomear.

**Publicar a cada push em vez de a cada `ci` verde.** Tira o portão de onde ele interessa: o único sítio onde um
erro fica visível para fora.

## Consequências
Passa a haver um endereço para dar a alguém, e ele mostra sempre a última `main` verde. O §36 e o §32 ganham a
coisa de que precisavam primeiro. Um chumbo na CI deixa de ser só um chumbo: passa a ser também *o que não foi
publicado*, e isso é uma segunda razão para o manter verde.

Três dependências novas, todas oficiais do GitHub e todas já vigiadas pelo `dependabot.yml` no ecossistema
`github-actions`: `actions/configure-pages`, `actions/upload-pages-artifact` e `actions/deploy-pages`.

O repositório passa a ter um ficheiro com `permissions: pages: write` e `id-token: write`. São as permissões
mínimas que o Pages exige e estão declaradas **no job** e não no workflow, para que a excepção se veja na
revisão. Nenhum segredo é preciso: o Pages usa o `GITHUB_TOKEN` da corrida.

O Pages liga-se sozinho: o `configure-pages` corre com `enablement: true`, e é a própria corrida que publica
que o activa na primeira vez. Não há interruptor para ninguém carregar. O repositório é público — o Pages não
custa nada e não expõe nada que já não estivesse exposto, porque o que se serve é a pasta `build/web/` e mais
nada. Se um dia o repositório passar a privado, o Pages privado exige um plano pago e o `deploy-pages` chumba com
uma mensagem clara, sem publicar nada de errado.

Reverter isto é apagar um ficheiro. Nada no jogo depende dele.
