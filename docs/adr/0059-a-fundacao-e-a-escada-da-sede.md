# ADR 0059 — A fundação do reino e a escada da sede

- **Estado:** aceite (o dono, 03/10/2026: *«aplique esse relatório»*); os números novos são propostas (`_proposed`)
  e as escolhas que pedem medição estão nas Q-220 a Q-226.
- **Data:** 2026-10-03
- **Secção do dossiê:** §09, §10, §24, §25, §62
- **Plano-fonte:** `docs/recovery/PLANO-REINO-2026-10-03.md` (auditado sobre a `main` em `a27e45b`, merge do PR #76)
- **Substitui, por cláusula:** a frase do §10 *«o núcleo não é construído nem destruído»* e a linha `core` do
  `buildings.csv` como o castelo de pé desde o primeiro tick (`Greybox._nucleo`). O resto do §10 continua a valer.
  A Q-114 (evoluir o monarca pelo Verbo 1 no núcleo) continua, com a escolha do alvo explícita.

## Contexto

O dono pediu: *«o jogador estabelece um acampamento, começa com poucos recursos e os trabalhos essenciais, ganha
dinheiro, expande o território e fortalece progressivamente o reino, inspirado em Kingdom.»* O plano do reino de
03/10/2026 auditou a `main` e encontrou o contrário: o núcleo nascia castelo, nível 1, de pé e com 1000 de vida, e
todos os sítios de obra da região aceitavam moeda desde o primeiro minuto. Não havia uma escada da sede: o que crescia
eram as obras à volta de um castelo que já lá estava.

O plano propõe três eixos — a sede organiza, a exploração ensina, o território consolida-se —, uma escada de sete
estágios (Clareira, Acampamento, Povoado, Vila, Vila Fortificada, Fortaleza, Capital), um pacote fundador, dezasseis
decisões recomendadas (RG-D01 a RG-D16) e uma execução por lotes (A a E, RG-01 a RG-18). O dono respondeu *«aplique
esse relatório»*.

## Decisão

**O reino começa numa Clareira e a sede sobe por estágios. O estágio é o nível do núcleo, pago e levantado como um
degrau de muro (§55).**

O *«aplique esse relatório»* aprova o roteiro e as dezasseis recomendações do plano (§32.1). Aplica-se agora o Lote A
inteiro (RG-01 a RG-04) e o que do Lote B cabe nele sem medir (o acesso da torre alta, a reposição do pioneiro e o
painel da sede). O resto entra no backlog como o plano o escreveu (RG-05 a RG-18). Como na ADR 0037, o «aplique»
aprova o roteiro, não números que o plano manda testar: esses ficam em `_proposed`.

O que mudou:

1. **A sede é o núcleo com degraus** (`realm_stages.csv`, `SeatSite`). O nível 0 é a Clareira: sem vida, não trava
   ninguém, não se ataca e não conta como caída. Cada estágio é um degrau com preço, trabalho, vida, slots de contacto
   e largura. Pagar e levantar usa o `BuildSystem` de sempre: a moeda cai no marco, quem está presente levanta, e o
   estágio de antes continua a servir até o seguinte acabar.
2. **O que cada estágio abre** (coluna `unlocks`, `RealmLadder`). O `BuildSystem.can_climb` soma o estágio às guardas
   que já tinha (a estátua, a conquista, o Lenho). Uma obra que nenhum estágio lista abre com a fundação; o muro abre
   por nível. Nada deixa de existir: os sítios continuam publicados pela mesma ordem e com os mesmos ids (plano §3.8);
   só não aceitam moeda antes do estágio.
3. **O pacote fundador** (`rules.csv`, `FoundationWatch`): o monarca chega com a companhia, os dois trabalhadores sem
   ofício de antes e um construtor pioneiro; uma carroça de provisões com 8 moedas fica ao pé do marco e o monarca
   leva-a ao passar; a fundação custa 2 e ergue a banca do arco da região de graça, uma vez (a bancada fundadora).
   Sem Sementes nem Lenho; o baú da sala secreta continua vazio (ADR 0053).
4. **Subir não cura** (RG-D15): a sede passa ao estágio novo com a mesma proporção de vida. As outras obras continuam
   a acabar com a vida cheia.
5. **A lareira pede sede** (RG-D07): sem sede fundada não há lareira a acender nem a pagar. Fundada, continua paga ao
   crepúsculo como na Q-190; a fogueira do acampamento desenha-se em brasa baixa.
6. **O alvo da moeda no marco** (RG-04, plano §3.6 e §23.2): a moeda é da sede por omissão. Com o monarca a poder
   evoluir, o painel diz para onde vai a moeda e o Verbo 2 no marco troca o alvo. O marco tem a largura da Clareira em
   todos os estágios, para a volta do castelo grande continuar a ter gente por recrutar.
7. **Os saves de antes** (RG-D13): o castelo é a Fortaleza — a mesma vida (1000), largura (480) e slots de contacto (7)
   do núcleo de antes. A migração v8 passa o núcleo de pé a esse estágio com a vida que tinha e marca a sede como
   herdada; não cria pioneiro, carroça nem banca.
8. **O que se vê**: o Acampamento (tendas, fogueira em brasa e bancada), o Povoado (cabanas de troncos e o sino), a Vila
   (casas de reboco à volta do salão) e a Vila Fortificada (a vila entre palicadas, com guarita) pintam-se pelo
   `PixelPainter`, como as obras da ADR 0051; a Fortaleza é o castelo-árvore do dono. A Clareira mostra o convite do
   Acampamento, com o preço.

## Precedência, cláusula a cláusula

| Antes | Depois |
|---|---|
| O núcleo não é construído nem destruído (§10); nasce castelo de pé (`Greybox._nucleo`) | O núcleo é a sede: funda-se na Clareira e sobe por estágios; se cair depois de fundada, cai a partida |
| Todos os sítios de obra aceitam moeda desde o primeiro tick | Cada obra abre num estágio da sede (`unlocks`); a estátua, a conquista e o Lenho continuam a valer |
| Seis moedas no saco e dois trabalhadores (Q-110) | Seis no saco, oito na carroça, dois trabalhadores e um construtor pioneiro |
| A banca do arco paga-se (4, Q-165) | A fundação ergue a banca da região uma vez; as outras e a reconstrução pagam os 4 |
| A lareira acende-se paga ao crepúsculo (Q-190) | Igual, depois da fundação; antes dela não há lareira |
| A moeda no núcleo evolui o monarca sempre que ele pode (Q-114, ADR 0052) | A moeda é da sede por omissão; o Verbo 2 no marco escolhe o monarca |
| O castelo não se repara (custo 0) | A sede repara-se como as outras obras, pelo custo do degrau em que está (Q-224) |
| Save v7 | Save v8: o castelo é a Fortaleza, herdada |

As dezasseis recomendações do plano (§32.1), e onde ficaram:

| ID | Recomendação | Agora |
|---|---|---|
| RG-D01 | Fundação explícita | Aplicada |
| RG-D02 | F0 + seis estágios | F0 a F5 aplicados; a Capital (F6) entra com o RG-14 (Q-226) |
| RG-D03 | Fundação a 2 moedas | Aplicada (`_proposed`) |
| RG-D04 | 6 no saco + 8 em provisões | Aplicada (`_proposed`) |
| RG-D05 | Um construtor pioneiro | Aplicada (`_proposed`) |
| RG-D06 | Banca do arco integrada à fundação | Aplicada; a posição dela fica a da região (Q-221) |
| RG-D07 | Fogueira só ambiente; lareira paga | Aplicada |
| RG-D08 | Casas não limitam a população | Fica como está: nada a fazer |
| RG-D09 | Torre alta no Povoado | Aplicada |
| RG-D10 | O fecho dos acampamentos fica, com aviso | A regra fica; o aviso é o RG-10 |
| RG-D11 | Sem dias fixos por estágio | Aplicada: custo e trabalho |
| RG-D12 | A Capital não dá vitória | Aplicada (a Capital ainda não existe) |
| RG-D13 | Saves antigos preservados | Aplicada (v8) |
| RG-D14 | A reserva é o baú vulnerável | Fica para o QP-03 |
| RG-D15 | Subir não cura | Aplicada |
| RG-D16 | Um sítio fundador autorado | Aplicada: o núcleo da região |

## Execução por lotes

| Lote | Resultado | Tickets | Agora |
|---|---|---|---|
| 0 — Contrato | Plano-fonte, ADR, dossiê, perguntas e backlog | RG-00 | feito |
| A — Fundação | Contrato da sede, pacote e início, F1–F5, contexto do núcleo | RG-01 a RG-04 | feito |
| B — Povoado funcional | Empregos e reposição, economia de trajetória, defesa aérea, interface | RG-05 a RG-08 | parcial |
| C — Território | Frentes e refúgios, expansão e acampamentos, F4/F5, primeiro posto | RG-09 a RG-12 | por fazer (o RG-11 parcial) |
| D — Capital e rede | Rota física, F6, integração e ausência | RG-13 a RG-15 | por fazer |
| E — Apresentação | Arte por estágio e povo, migração, desempenho e mobile | RG-16 a RG-18 | parcial |

A ordem do plano é A → B → validação jogável → C → validação de expansão → D → acabamento (§29). A Capital não se
implementa porque F1 e F2 têm os testes verdes (§31.5).

## Alternativas consideradas

- **Um sistema de estágio separado do núcleo** (o `RealmProgression` do plano, §25.2). Rejeitado para o primeiro
  protótipo: o `BuildSlot` já tem degraus com preço, trabalho, vida e slots de contacto, e o `BuildSystem` já paga,
  ergue, danifica e repara. Um segundo sistema obrigava a duplicar tudo isso e a manter o estágio e o núcleo em acordo.
- **Esconder os sítios de obra até ao estágio.** Rejeitado: mudava os ids pela ordem de publicação e restaurava uma
  quinta sobre uma torre num save (plano §3.8, §27.2).
- **O castelo de antes como Acampamento nos saves antigos.** Rejeitado: *«saves atuais não devem virar
  acampamentos»* (plano §27.1).
- **A largura da sede como alvo da moeda.** Rejeitado: a Fortaleza tem 480 px, e os arqueiros por recrutar a 180 px
  do núcleo ficavam dentro dela — a moeda largada para os recrutar pagava a sede.

## Consequências

- Mais fácil: a primeira moeda tem um resultado que se vê; cada estágio diz o que abre; as obras, os ofícios e a sede
  competem pela mesma bolsa (plano §4.3).
- Mais difícil: os testes do mundo inteiro que medem uma mecânica depois da fundação erguem a sede primeiro
  (`tests/support/sede.gd`); os da abertura fundam com gestos. O piloto da vistoria leva a carroça, funda e sobe a sede.
- Proibido: conceder o pacote fundador outra vez ao carregar, na sucessão ou na troca de monarca; evoluir o monarca
  com uma moeda que era da sede; curar a sede por subir de estágio.
- Desfazer: no `Greybox._nucleo`, levantar a sede até à Fortaleza (`raise_to`) e tirar o `FoundationWatch.arrive`; o
  save v8 continua a abrir.
