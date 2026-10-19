# ADR 0085 — O site ganha um laboratório de mecânicas: as regras do jogo, para mexer

- Estado: aceite
- Data: 2026-10-19
- Secção do dossiê: §06, §07, §10, §25, §32, §36, §51, §74
- Complementa: ADR 0025 (o site lê o repositório), ADR 0056 (o site mostra o jogo de hoje), ADR 0080 (primeiro contacto)
- Tarefa: [PUB-06](../backlog/PUB-06.md)

## Contexto

O dono, a 19/10/2026: *«faça uma densa pesquisa na web para implementar melhorias e funcionalidades interessantes no
meu site, por exemplo, adicionar uma secção que a pessoa pode testar e ver todas as mecânicas que ela desejam, e por
aí vai, quero que meu site seja criativo»*.

A pesquisa está em `docs/reports/SITE-LABORATORIO-2026-10.md`. Diz, em resumo, três coisas:

- **As explicações exploráveis** (Bret Victor, Nicky Case, Red Blob Games) mostram o modelo e deixam o leitor mudar
  as premissas e ver a conclusão mudar. Exigem que o autor revele o modelo — e o Empire já o tem por escrito: o
  dossiê, os CSV e os sistemas puros de `src/sim/`.
- **Começa-se pelo raso e acaba-se na caixa de areia.** A página já tem o raso: a candeia, um instrumento só, na secção
  da Podridão. Falta o fundo: um sítio com vários instrumentos, depois de se perceber o jogo.
- **As páginas dos jogos do género** (Kingdom Two Crowns, Thronefall) mostram imagens, uma frase e um botão — e
  nenhuma deixa mexer nas regras. É a diferença que o Empire pode ter sem pedir nada a ninguém.

O risco é o do §07, dito ao contrário: um simulador que não faça as contas do jogo ensina um jogo que não existe. E o
da regra 10: metade dos números do Empire ainda está em `_proposed`.

## Decisão

**A página de entrada ganha um Laboratório, depois dos povos e antes de «Como se joga», com quatro instrumentos que
fazem as contas do jogo sobre os números dos CSV.**

1. **Quatro instrumentos, as quatro perguntas que o §07 diz que o jogador tem de saber responder antes da noite.**
   *Quem vem esta noite* (a massa da §74 termo a termo, a regra de escolha do §51 e o ritmo a que ela invoca — uma de
   cada vez, do crepúsculo à alvorada, e o que a massa paga além disso fica por vir —, com a arte animada do dono, ADR
   0083); *o dia da asfixia* (o simulador do §06, com os deslizadores que o próprio dossiê desenha); *quanto tempo até
   cair* (a tabela do tempo até matar do §07, por tropa e por posto); *a escada do muro* (os cinco níveis do §10, os
   dois caminhos, os slots de contacto e o Aríete).
2. **As contas são as do jogo, e testam-se contra o dossiê.** `tools/web/paginas/laboratorio-contas.js` tem uma
   função por cada função do GDScript de onde vem (`EconomySystem`, `RotProfile`, `RotSystem`, `RotPick`), com o nome
   dela ao lado, e nenhum número de balanceamento. `tests/web/laboratorio.test.mjs` confere-a contra o que o dossiê
   escreve: o `upkeep(14) = 3,0` e o `upkeep(25) = 13,5` do §29, o dia da asfixia de cada perfil do
   `economy_profiles.csv` (11, 15, 28…), a tabela do tempo até matar do §07, a noite 1 com três Rastejantes do §25, a
   tabela da §74 (220, 716, 782, 892, 961) e a escada 6 · 11 · 20 · 36 · 65; e as invocações que cabem numa noite
   contam-se tick a tick, como o `RotSystem.tick` as conta.
3. **O decidido por omissão; a proposta só a pedido, e a dizer que o é.** O `dados.mjs` chumba a construção se um
   campo de que uma conta depende estiver em `_proposed`. O crescimento da noite, os picos e as estreias (Q-151, Q-126,
   Q-240) entram só com «Juntar o que ainda é proposta», e a página diz quais são. A vida do caminho A e os postos do
   caminho B dizem «por decidir», como os monarcas (ADR 0056). Os impulsos reais ficam de fora: o preço de todos está
   em `_proposed`. A noite de dois lados (Q-179) diz-se e não se conta: o dia em que pode começar é decidido, a
   probabilidade (`rift_both_chance`) é proposta, e o instrumento conta um lado e di-lo. As réguas da noite acabam onde
   os dados acabam — os Amargueiros com nome no `named_cap`, as fortalezas uma por povo; os anónimos não têm teto no
   jogo, e a régua deles diz só até onde a régua vai.
4. **Uma experiência tem endereço.** O estado vai para `#laboratorio?f=noite&dia=12…` com `replaceState` — não enche
   o histórico, não muda nada no servidor, e só depois de alguém mexer. «Copiar a ligação» dá-a a quem a quiser ver.
5. **A regra da casa, toda.** Sem `<script>` nem `style=""` em linha: o modelo vai dentro do script do laboratório,
   a folha de cada criatura na folha gerada. Separadores do padrão da APG, deslizadores e escolhas nativos, uma frase para o
   leitor de ecrã meio segundo depois do último movimento, a cor nunca sozinha, movimento reduzido sem animação. Sem
   JavaScript, cada instrumento diz o caso por omissão numa frase, contada na construção com as mesmas contas.
6. **Trabalho a pedido (ADR 0080).** O script do laboratório — as contas, o modelo e o instrumento, num ficheiro —
   só se pede quando a secção chega a 800 px do ecrã, ou logo, se a ligação aponta para ela; não é caminho crítico.
   Das folhas animadas do dono serve-se só a linha do repouso, cortada na construção sem descodificar píxeis
   (`tools/web/bestas.mjs`): 1,6–3,5 KB por criatura em vez de 12–25 KB.
7. **Por onde se começa (o pedido do dono de 19/10: «refine também o design e a user experience»).** Quem chega não
   sabe o que experimentar, por isso os instrumentos da noite e da asfixia abrem com cenários de um toque, todos
   lidos dos dados: os perfis dos testes de design do §06 (`economy_profiles.csv` — «Com 2 rotas de comércio» dá os
   quatro dias que a conquista compra) e as noites que o dossiê conta (a primeira, a primeira que pode vir por
   dois lados, a estreia da criatura mais cara). O cenário em que o instrumento está fica marcado; «Repor» volta ao caso por omissão. Um
   perfil novo sem nome no site chumba a construção, como um trilho novo. A bancada chega-se por três sítios: o
   menu, o guia inicial («Mexer nas regras») e a candeia — o instrumento raso leva ao fundo. Num ecrã tátil,
   «Partilhar» abre a folha de partilha do sistema; no resto, copia a ligação.
8. **A abertura deixa de colar rótulos.** Cada fase da linha do dia é um contentor (CSS `@container`): o nome só
   aparece se couber. A 1180 px, «Meio-dia» era cortado e colava-se a «Tarde».
9. **A candeia passa a ter a rampa das primeiras noites** (Q-017, Q-068), como o `RotProfile.calendar_mass`: com o
   laboratório na mesma página, a noite 1 não podia ter 58 de massa numa e 24 na outra.

## Alternativas consideradas

**Correr o próprio jogo em miniatura (o `.wasm`) para cada instrumento.** Seria a regra exata por construção, mas são
~9 MB para responder a uma conta de uma linha, e o motor não arranca numa página que se lê.

**Uma biblioteca de gráficos ou de UI reativa.** Uma dependência nova (regra 8) para quatro instrumentos que o
browser desenha com SVG e com o CSS que o site já tem.

**Publicar as propostas como estão, porque o jogo já as usa.** É o que a regra 10 proíbe: o laboratório passava a
ser a primeira página a anunciar como regra o que o dono ainda não aprovou.

**Guardar a experiência em `localStorage`.** Ficava presa num browser; o endereço vai para onde a pessoa o levar.

## Consequências

- Um número mudado num CSV muda o laboratório na publicação seguinte; um campo de que ele depende passado para
  `_proposed`, ou uma regra de escolha nova no `rot.csv`, param a construção até alguém decidir o que mostrar.
- Uma mudança numa destas funções do GDScript tem de chegar à `laboratorio-contas.js`; o teste do laboratório apanha a
  divergência quando o dossiê e os CSV também mudam, e não antes — é o limite de copiar uma conta em vez de a correr.
- **Os tetos do portão sobem às claras**, como a ADR 0080 fez com as fotografias: o do caminho crítico de 660 para
  710 KB e o da página inteira de 1700 para 1750 KB. Medido no build final desta tarefa, sem compressão: 699 KB de
  caminho crítico (o HTML da página passa de 107 para ~130 KB e a folha de 50 para ~67 KB; em brotli, que é o que a
  Vercel serve, ≈ +4 KB e +2,6 KB) e 1697 KB de página inteira, com o script adiado (≈ 40 KB, com o modelo) e as
  folhas das criaturas. A folga — 11 e 53 KB — fica escrita para a próxima mudança não ter de reabrir esta decisão
  por uma frase; o que a passar volta a ser uma decisão.
- O portão do site ganha o grupo 20, e a conferência das duas línguas conta os cartões do laboratório.
