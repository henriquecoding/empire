# Dossiê Empire v6 — camada de uso

O dossiê continua a ser o teu. **A camada de uso não lhe toca no conteúdo**:
as secções, as tabelas, os blocos de código e a Parte XIII saem byte a byte
como entraram do ficheiro de entrada. O que muda é o que se pode *fazer* com
o documento — e um punhado de defeitos que ninguém via porque não davam erro.

> As correções ao **texto** do dossiê são outra coisa, e fazem-se no próprio
> `docs/dossie.html`, com registo: `docs/dossie-v5.2-correcoes.md` (105 de
> português, 27 de conteúdo) e `docs/dossie-v6-correcoes.md` (8 ao dossiê,
> 10 às ferramentas). O construtor nunca corrige texto.

Construído com a disciplina do repositório **Recibo Certo**: o motor de
pesquisa é um porte directo de `src/lib/busca/`, o portão de telemóvel é um
porte de `scripts/verificar-movel.mjs`, a verificação de âncoras vem de
`ligacoes-internas.test.ts`, e a regra da proveniência vem do motor de
descoberta e do motor de dossiê de guia.

---

## 0 · A direção de arte — «a linha do solo»

O Empire tem uma estrutura que o define e que a §11 e a §53 repetem a cada
página: uma **linha de solo** e três faixas. O documento que a descreve
estava disposto como um artigo genérico — uma coluna de texto encostada à
esquerda, o terço direito vazio em qualquer ecrã acima de 1100px, e 85
secções sem nada que as ancorasse ao olho.

Agora tem a mesma anatomia que o jogo:

| | |
|---|---|
| **calha** | o número da secção, cravado na margem como um marco de estrada, fixo enquanto se lê |
| **medida** | a prosa, a 68 caracteres — onde se lê |
| **margem** | onde as tabelas, as figuras, o código e as grelhas **sangram** |

O que isso resolve, concretamente:

- **As tabelas deixaram de rolar.** A §34 tem nove colunas e rolava de lado
  num ecrã de 1400px, porque a coluna de texto tinha 590. Agora tem 1000.
- **O terço direito deixou de ser um vazio** e passou a ser a margem para
  onde as coisas largas vão.
- **As 85 secções distinguem-se ao folhear** — o número está grande, na
  margem, no mesmo sítio em todas.
- **O cabeçalho é uma composição.** O nome atravessa a página; por baixo,
  o que o documento é à esquerda e a **ficha técnica** à direita. As 14
  etiquetas eram um muro de crachás de CI em duas filas irregulares com
  três estilos; são a mesma informação, agora numa grelha de duas colunas
  com uma linha por facto.
- **As caixas têm identidade.** Eram 149 blocos cinzentos iguais: decisão é
  petróleo, risco é brasa, a candeia tem um halo de brasa.
- **O papel tem grão.** Dois por cento de ruído gerado em SVG, sem um único
  pedido de rede. Um dossiê sobre pixel art medido pixel a pixel não podia
  ser uma chapa de cor lisa.
- **O índice abre-se na secção onde se está** e mostra os seus sub-títulos,
  com o que se está a ler marcado. Há 174 sub-títulos; antes não se via
  nenhum.

### A noite é castanha — e o modo escuro não era

A §80 e a **ADR 0011** decidiram, a 13/09/2026, que a noite do Empire é
castanha e não azul, e a §80 publica a rampa: dez valores de `#14140F`
(silhueta) a `#F6D89B` (candeia), a família de trinta de «terra e madeira».

O modo escuro do documento estava pintado noutra coisa — superfícies a
`#1B1D13` e `#262A1D`, verde-azeitona. **O dossiê explicava uma decisão de
cor numa página que não a cumpria.** As superfícies passam a ser a rampa do
autor, e a brasa passa a ser a candeia (`#E8B87A`, o penúltimo valor). Não
há aqui uma cor nova: são as que a §80 escolheu.

O modo claro não foi tocado. É o do autor, medido pixel a pixel sobre
`Empire Concept.png`.

### O refino — o documento deixa de ser uma grelha de caixas

Havia **um** raio (3px) e **uma** forma de delimitar (um traço de um
pixel), aplicados a tudo: às 122 tabelas, às 149 caixas, aos cartões, aos
campos, às fichas, aos botões. Quando cada superfície tem a mesma aresta e
o mesmo peso, a página não tem hierarquia — tem uma grelha de arame.

Passou a haver uma escala de raio e uma de elevação, e cada superfície
escolhe o degrau que o seu papel justifica:

| nível | o que é | como se delimita |
|---|---|---|
| 0 | o papel | nada |
| 1 | o que se apoia — tabela, cartão, célula | degrau de fundo + sombra quente |
| 2 | o que interrompe — caixa de decisão | cor de fundo + raio de 20px + um ponto |
| 3 | o que flutua — pesquisa, dicas | sombra a sério |

E o pixel deixou de ser o esqueleto para passar a ser o sotaque: a
Silkscreen fica nos rótulos de dez pixéis, onde a rudeza é intencional, e
saiu de tudo o que é grande — o número da secção, que era um carimbo
ampliado com buracos entre algarismos («6 9», «7 0»), passou a ser um
numeral de margem na face de display.

As sombras são **quentes**: a tinta do documento é `#14140F`, não preto, e
uma sombra cinzenta por cima de estuque lê-se suja.

### Quatro bugs que estavam mesmo lá

1. **O painel de pesquisa passava por baixo dos números das secções.**
   `position:sticky` cria um contexto de empilhamento próprio — o
   `z-index:60` do painel não saía de dentro da coluna lateral. Quem se
   levanta é a coluna.
2. **«Rastreador · Fase 1» seguido de «Fase 1 · especificada em §06».** O
   contexto já dizia a fase, e a descrição repetia-a.
3. **A figura do ciclo do dia estava cortada e com rótulos sobrepostos.**
   Duas causas distintas: a frase «A Podridão nasce na borda do mapa ▸»
   começa na unidade 592 de um `viewBox` de 760 — vive FORA da janela que
   o desenho declara, e a calha recortava-a. E «85 s · última janela»
   sobrepõe-se a «30 s» em dezasseis unidades, na fonte para que a figura
   foi desenhada: é um defeito do desenho, não da substituição de fonte.
   A janela alarga-se para caber o desenho (nada nele muda), e os rótulos
   que se tocam são medidos e encolhidos o estritamente necessário —
   nunca abaixo de 80%.
4. **O portão media mal o texto dentro de SVG.** Num `<text>` o
   `font-size` está em unidades de utilizador, e o que chega ao olho é
   isso vezes a escala do `viewBox`. O portão reprovava rótulos legíveis
   e deixava passar rótulos minúsculos. Passa a medir o tamanho efectivo.

---

## 1 · O defeito que valia mais do que todos os outros juntos

O dossiê **não tinha `<meta name="viewport">`**.

Sem essa linha, qualquer telemóvel assume que a página foi desenhada para
980px e encolhe tudo até caber — o texto, as 122 tabelas, os blocos de
código, o gráfico. O documento era ilegível num telefone e não havia como
saber, porque não dá erro: dá uma página pequena.

Também não tinha `<!doctype html>`, o que punha o browser em **modo
quirks** — o modelo de caixa antigo, com regras de layout diferentes das
que a folha de estilo assume.

Ambos corrigidos. Tudo o resto abaixo só passou a fazer sentido depois destes.

## 2 · Pesquisa dentro do documento — `/` ou `Ctrl/⌘ K`

Um índice de 86 linhas responde a «onde está a secção sobre X». Não responde
a «onde é que se fala de asfixia», que é a pergunta que se faz a um documento
de 360 mil caracteres.

- **Perto de mil documentos indexados**, todos DERIVADOS do próprio ficheiro:
  as secções (com o corpo inteiro), os sub-títulos, as caixas de decisão e de
  risco, as 112 cores da paleta, as 48 mecânicas do rastreador, e o inventário
  do repositório — tickets, perguntas, ADRs e tabelas de dados.
  Uma secção nova entra no índice **por existir**, não por alguém se lembrar.
  Nenhum destes números está escrito aqui de propósito: contam-se na
  construção, e a tira de orientação no topo do dossiê mostra os do dia.
- **Ranking determinístico e explicável**: frase exacta, prefixo, subcadeia
  em fronteira de palavra, token exacto, prefixo de token e uma gralha a
  partir de cinco letras. Cada resultado diz *porquê* está ali («é o
  identificador», «o título responde», «no corpo do texto»).
- **Sem subsequência.** Em português quase tudo é subsequência de quase
  tudo, e um resultado inventado custa mais do que um resultado em falta.
  Há um estado «sem resultados» honesto, com limiar.
- **Melhor resposta** só quando ganha por margem clara (25%). Coroar sempre
  o primeiro seria anunciar uma certeza que não existe.
- **Identificadores endereçam**: `F1-08`, `Q-001`, `§07`, `clock.csv`
  devolvem a coisa, não o parágrafo que a cita.
- **Recentes** com três regras: o que parece identificador (NIF, IBAN,
  email, número comprido) nunca é guardado; o que é guardado expira em 30
  dias; há um botão para apagar, à vista.
- A consulta **não sai do dispositivo**. Não há pedido de rede nenhum.

A superfície é uma **região**, não um diálogo: sem véu, sem `aria-modal`,
sem foco preso. O documento continua legível e clicável por baixo.

## 3 · Navegação

- **Barra de contexto** fixa: em que Parte e em que secção estás, com
  anterior/seguinte.
- **Índice em grupos que dobram**, com contagem, filtro de texto e o grupo
  da secção corrente a abrir-se sozinho. O estado fica guardado.
- **Progresso de leitura**: uma secção fica marcada quando rolaste até ao
  fim dela (não quando passaste por cima num salto).
- **As 941 referências `§NN` passaram a ligações** com pré-visualização ao
  passar por cima — o título e a introdução da secção de destino, sem sair
  de onde estás.
- **Âncoras em todos os títulos**, com cópia de ligação.
- **Aterragem visível**: quem salta vê onde caiu, e tem um botão «Voltar».
- **Teclado**: `/` ou `⌘K` pesquisa · `J`/`K` secção seguinte/anterior ·
  `G G` topo · `G E` estado · `G I` inventário · `T` tema · `?` atalhos.
- **Telemóvel**: o índice deixou de ser uma grelha de 86 ligações no topo
  da página (era preciso passar o índice inteiro para chegar ao texto) e
  passou a ser uma folha inferior, chamada por um dock.

## 4 · Dois painéis novos

**`★ Estado` — onde é que isto está, medido.** Os números vêm de
`docs/recovery/v6-validation.json`, de `tickets.json`, de `QUESTIONS.md` e
da contagem dos CSV. Nenhum foi escrito à mão. E o painel dá o **mesmo
destaque ao que não foi verificado**: exportação, GPU, playtest, CI remoto,
push. «Gerado», «medido» e «aprovado» são três coisas diferentes, e nenhuma
frase usa a palavra «validado».

**`★ Inventário` — tudo o que o dossiê cita e não mostra.** Os tickets, as
perguntas, as ADRs e as tabelas de dados, com filtro, pesquisa e o estado
que o próprio ficheiro declara — incluindo as ressalvas («parcial — o CI
existe e nunca correu num runner remoto»), que é a informação que interessa.
Nada foi reescrito, e nenhum destes números foi escrito à mão: contam-se.

> Nota sobre as perguntas: um extractor que só lesse `### Q-NNN` deixava de
> fora as que vivem em linhas de tabela — as resolvidas e as que entraram em
> tabela na Parte XIII. O dossiê diria um número e o inventário diria outro,
> sem nada reprovar. Por isso as tabelas são lidas **pelo cabeçalho** (a
> coluna que se chama «A pergunta» é o título) e não por posição.

## 5 · Gráficos

**O gráfico da economia usava duas cores que são a mesma cor** para quem tem
deuteranopia: `--leaf` (a linha do líquido) e `--ember` (a marca da asfixia)
estão a ΔE 3,5 em OKLab, quando o mínimo utilizável é 6 e o alvo é 8. As duas
informações mais importantes do gráfico eram indistinguíveis para cerca de
uma pessoa em cada doze.

Os passos de gráfico saíram de procurar, dentro das **mesmas famílias de
matiz do dossiê**, a variante mais próxima do token que passa as seis
verificações (banda de luminosidade, chão de croma, separação sob protanopia
e deuteranopia simuladas, chão de visão normal, contraste ≥ 3:1). Desvio
total: ΔE 9,7. Continua a ser a paleta do Empire; deixou de ser a mesma linha.

Nesta passagem faltava uma: `--s-ref` no escuro (`#8E8875`, a linha do bruto)
estava a **ΔE 13,0 de visão normal** contra `#B37BB6`, o custo da noite —
abaixo do chão de 15, que é o único que o tracejado não desculpa. Passa a
`#7E7663`, mais fundo, o que também é o que uma linha de REFERÊNCIA deve ser
ao lado das que são dados. Com essa troca as quatro passam.

O gráfico já tinha leitura ponto a ponto, rótulo directo na ponta de cada
série e vista de tabela. O que faltava era maior do que tudo isso:

### O gráfico não mostrava o facto que lhe dá nome

A §06 chama-se «a curva, e o dia da asfixia» e escreve, com todas as letras,
que este «é o tipo de erro que uma tabela esconde e um gráfico apanha em
cinco segundos». Nos valores do próprio autor — 7 fontes, 0 rotas, 14 tropas,
28% — o cruzamento acontece a **5,7 px da base de um desenho de 250 px**.
Dois vírgula três por cento da altura. Os dias 1 a 19 vivem todos dentro dos
7% de baixo, empilhados numa linha que se vê como uma só.

Não é um defeito do desenho: é a escala. Três exponenciais (1,12 · 1,08 ·
1,22) num eixo linear que tem de chegar a 1 949 esmagam os primeiros vinte
dias contra o chão — e a asfixia acontece lá.

O eixo passa a ser **logarítmico à entrada**, com um comutador ao lado e a
escolha guardada. Em logarítmica as três curvas da §06 saem **direitas**, e a
inclinação de cada uma é o expoente que a §06 publica; o cruzamento passa a
ser o encontro de duas rectas, visível ao longo dos trinta dias, e a
distância entre elas ao dia 1 passa de meio pixel para vinte e três. A
transformação é simétrica — `sinal(v)·log₁₀(1+|v|)` — porque com poucas
fontes e muitas tropas o líquido é negativo e um `log` puro não tem resposta
para isso.

**A matemática não muda.** É a da §06, copiada linha a linha. A escala é uma
decisão de leitura, não de modelo, e está dita no ecrã por baixo do desenho.

### E o alvo da §06 passou a estar desenhado

A §06 publica um alvo — «entre o dia 9 e o dia 14» — e a §31 diz que o CI
falha fora dele. Era um número em prosa. Agora é uma **faixa vertical no
gráfico**: «está no alvo?» deixa de ser uma comparação de números e passa a
ser uma pergunta sobre posição — a linha tracejada cai dentro da faixa, ou
não cai. Não precisa de cor nenhuma para se responder, e é por isso que
sobrevive ao daltonismo, ao cinzento e à impressão.

### Quatro correções de desenho que a medição apanhou

| | |
|---|---|
| **a dica aterrava em cima dos cursores** | `tip()` põe a caixa acima do ponto, e o gráfico passava-lhe o TOPO do desenho: a caixa saía do gráfico e caía na grelha das quatro réguas. Ler um dia tapava os comandos com que se muda o dia. Agora vira-se para baixo quando não cabe, e o limite não é a janela — é o topo do próprio desenho |
| **o eixo linear tinha a última linha a flutuar** | `ceil(max/50)*50` com passos de 400 punha a grelha mais alta a 1 600 num desenho que ia a 1 949. Passa a haver marcas 1-2-5 com o topo NA marca |
| **os nomes das pontas colidiam** | quatro rótulos na mesma calha encontram-se sempre que duas séries acabam perto — e em logarítmica isso é a regra. Empurram-se para 13 px de intervalo, mantendo a ordem vertical, com uma perna a ligar cada um ao seu ponto |
| **as calhas eram estimadas a «7,25 px por caractere»** | verdade para a monoespaçada que o documento pede, falsa para a de reserva — e sem rede é sempre a de reserva. A 320px isso escrevia «asfixia · dia 11» por cima de «Custo». Agora `getComputedTextLength()` mede o texto real: as duas calhas ganham a largura exacta dos nomes que lá vão, e quando o rótulo da asfixia não cabe de nenhum dos lados **escreve-se menos** («dia 11», depois «d11») em vez de se encostar à borda |

### «O que mais mexe no dia da asfixia»

Porte do `SensibilidadeNegocio.tsx` do Descobrir — o bloco que ordena os
fatores pela amplitude entre o melhor e o pior caso e diz qual é o
pressuposto a confirmar primeiro. Quatro cursores sem comparação obrigam a
arrastar os quatro para descobrir qual é que interessa.

Com uma diferença que este dossiê permite e o Descobrir não: aqui as quatro
barras partilham **um eixo** — os trinta dias — porque medem todas a mesma
coisa. Não são quatro amplitudes para comparar de cabeça: são quatro
segmentos alinhados, com o alvo desenhado por trás, o troço de cada alcance
que cai dentro dele pintado por cima, e o dia actual marcado nos quatro. E
não custa uma conta: é a **mesma varredura** que pinta os carris das réguas,
lida outra vez.

**As figuras largas deixaram de encolher até ao ilegível.** O ciclo do dia
da §05 tem `viewBox="0 0 760 132"` e rótulos a 9,5px: num ecrã de 360 isso
são quatro pixéis. Nenhum portão tipográfico apanha isso, porque o
`font-size` continua a dizer 9,5 — a escala está no `viewBox`. Passam a
desenhar-se 1:1 dentro de uma calha que desliza com o dedo. **O desenho não
foi tocado.**

## 6 · Glossário

152 termos sublinhados a tracejado — A Podridão, faixa, asfixia, tick, seed,
greybox, Amargueiro, candeia, A Oferta, A Colheita, upkeep, TTK, ADR… Passar
por cima explica; carregar abre a secção que define. **Nenhuma definição foi
inventada**: cada uma é a leitura da secção que a define e leva o número
dessa secção. Onde o dossiê não define um termo, ele não está na lista.

---

## O portão — o que foi medido, e o resultado

```
node verificar-dossie.mjs saida/dossie-empire-v6.html
```

Percorre 360, 320 e 1280px, no claro e no escuro, com a folha do telemóvel
aberta, e reprova sete coisas que **nunca dão erro**:

| | Antes | Agora |
|---|---|---|
| âncoras internas mortas | — | **0** de 1 514 |
| rolagem lateral | 0 | **0** |
| caixas a transbordar (360px) | 30 | **0** |
| texto abaixo de 12px (360px) | **338** | **0** |
| alvos abaixo de 36px (toque) | 1 281 | **0** |
| erros de JavaScript | — | **0** |
| caixas que cortam o próprio conteúdo (360px) | **103** | **0** |
| caixas que rolam de lado sem o dizer | — | **0** |
| elementos HTML dentro de um `<svg>` | **2** | **0** |
| pesquisa: 9 perguntas reais + 1 de lixo | — | **todas certas** |
| sem JavaScript | — | **87 secções legíveis** |

E `verificar-novo.mjs` mede as camadas portadas — o plano, a saúde, o
recorte, as partes e, desde esta passagem, o **simulador**: 29 asserções que
tentam *usar* as coisas em vez de conferir que existem. Entre elas, as que
apanharam defeitos reais nesta passagem:

| | |
|---|---|
| a pega está DENTRO da faixa que a pinta, e a ≥ 30% de um passo da fronteira | apanhou o meio passo |
| a legenda lista exactamente as faixas que o mapa contém | apanhou «aguenta os 30 dias» |
| a dica nunca aterra por cima dos cursores, em quatro pontos do gráfico | apanhou o `tip()` |
| o rótulo da asfixia não sai do desenho, não pisa um nome de série e não atravessa a própria linha — a 320, 360 e 1280 | apanhou os dois cortes |
| o caminho rápido da varredura concorda com o modelo em 500 combinações | impede que os dois se separem |
| as quatro notas dizem coisas diferentes | impede o regresso das quatro etiquetas iguais |

Duas calibrações foram deliberadas e estão escritas no portão:

1. **Ligações em texto corrido não são alvos tácteis.** Há 941 referências
   `§NN` dentro de frases; obrigá-las a 36px partiria o entrelinhamento de
   todos os parágrafos. É o que a WCAG 2.5.8 isenta explicitamente.
2. **A régua dos 36px é de toque.** Com rato aplica-se o mínimo AA da
   WCAG, 24px. Medir as duas com a mesma régua produz 1 281 «defeitos» que
   ninguém corrige — e um portão que grita de mais deixa de ser lido.

### Três armadilhas que só a medição apanhou

1. **`$$` virou `$`.** `String.replace(alvo, texto)` interpreta `$$` dentro
   do texto de substituição. O JavaScript inserido tem um atalho chamado
   `$$`, e a inserção transformou-o em `$` — duas declarações no mesmo
   âmbito, `SyntaxError`, a camada inteira morta. O ficheiro tinha o
   tamanho certo e parecia bem.
2. **Uma linha de grelha com nome que deixa de existir não dá erro —
   fabrica pistas.** Ao colapsar a grelha para uma coluna no telemóvel, as
   regras de sangria (`grid-column: medida / -1`) continuavam a pedir uma
   linha chamada `medida`. O CSS Grid criou pistas implícitas para a
   satisfazer: a 360px a secção tinha três colunas e o texto ficava a 94
   pixéis de largura. Sem erro de consola, e a 1400px tudo certo.
3. **Uma camada que vem depois anula as media queries de quem veio antes.**
   `.shell{grid-template-columns:248px 1fr}` tem a mesma especificidade que
   o `@media (max-width:960px)` do autor e vem depois na folha: a 360px o
   documento continuava a reservar 248 pixéis para uma coluna que já tinha
   sido movida para a folha inferior. 103 caixas a transbordar.

Nenhuma das três deu erro. Todas foram encontradas pelo portão.

### O que fica por verificar

- A medição correu **sem as fontes de ecrã** (o ambiente não tem rede para
  o Google Fonts), portanto foi feita sobre a pilha de reserva. As métricas
  reais com Fraunces e Source Serif 4 são ligeiramente diferentes.
- Não foi testado em Safari nem em Firefox. `color-mix()`, `dvh`,
  `ResizeObserver` e `backdrop-filter` são suportados nos três motores
  actuais, mas não foi verificado.
- Não houve teste com leitor de ecrã real. A semântica está lá (combobox
  com `aria-expanded`/`aria-activedescendant`, região sem foco preso,
  `role="img"` com descrição em cada figura, anúncio em `aria-live`), mas
  semântica correcta e experiência boa não são a mesma coisa.

---

## Como reconstruir

```
npm install --no-save playwright && npx playwright install chromium   # uma vez

node extrair-dados.mjs .. saida/dados.json
node construir.mjs ../docs/dossie.html saida/dados.json saida/dossie-empire-v6.html
node verificar-dossie.mjs saida/dossie-empire-v6.html
node verificar-novo.mjs  saida/dossie-empire-v6.html
```

A fonte é `../docs/dossie.html` — **o dossiê do repositório, e não uma cópia
aqui dentro**. Duas cópias divergem no primeiro dia em que alguém corrige uma
e não a outra, e ninguém dá por isso porque as duas continuam a abrir.

Para o artefacto publicado, o mesmo comando com `--artefacto` no fim: omite
`<!doctype>`, `<html>`, `<head>` e `<body>`, porque o serviço de publicação
fornece-os.

`construir.mjs` faz **cinco inserções cirúrgicas** e mais nada — a cabeça, os
estilos, a tira de orientação, os dados e o comportamento. Uma versão nova do
dossiê volta a passar por aqui e a camada reaplica-se. Não há uma cópia
editada à mão para manter em sincronia.

O `extrair-dados.mjs` aceita a raiz do repositório (`..` daqui) ou a pasta que
a contém, e lê sempre o registo de validação **mais recente** de
`docs/recovery/` — se houver um medido hoje, é esse que o painel de estado
mostra.

Ficheiros:

| | |
|---|---|
| `src/ux.css` | a camada de USO — cada correção medida, justificada |
| `src/design.css` | a camada de DESENHO — grelha, matéria, a noite castanha |
| `src/01-busca.js` | o motor de pesquisa (porte de `src/lib/busca/`) |
| `src/02-indice.js` | o índice derivado do DOM e do inventário |
| `src/03-paineis.js` | estado, inventário, gráficos, glossário, calhas |
| `src/04-plano.js` | **reconhecer a frase → o que se pode afirmar** (porte de `busca/reconhecer.ts` + `plano.ts`) |
| `src/05-recorte.js` | **levar o caso a alguém** (porte de `guias/dossie/`) |
| `src/06-saude.js` | **os fatores do plano, contados ao vivo** (porte de `insights.ts`) |
| `src/07-partes.js` | **as treze partes, que se abrem quando se quer** (porte da regra 11) |
| `src/08-interface.js` | desenha tudo o que está acima — vai em último |
| `saida/dados.json` | o inventário derivado das fontes (gerado; fora do repositório) |
| `extrair-dados.mjs` | o extractor — tickets, perguntas, ADRs, tabelas, validação |
| `construir.mjs` | as cinco inserções |
| `verificar-dossie.mjs` | o portão do documento |
| `verificar-novo.mjs` | o portão das três camadas novas |

Os ficheiros estão numerados pela ORDEM DE CARREGAMENTO, não por
importância: `07-interface.js` desenha o que os seis anteriores decidem, e
por isso tem de ser o último. A numeração é o contrato.

---

## 7 · As três camadas portadas do Recibo Certo

### A pesquisa deixou de listar e passou a responder

Escrever «o que o F0-00 bloqueia» dava dezassete resultados ordenados. A
resposta estava no ZIP, num campo, à espera de ser clicada.

O Recibo Certo separa isto em duas camadas, e é a separação que faz a
coisa funcionar. **`reconhecer`** extrai o que está escrito e mais nada —
se a pessoa escreveu «fase 1», sai «fase 1», não sai «tickets da fase 1»,
que era um palpite. **`plano`** decide o tom, em quatro estados:

| estado | o que a interface faz |
|---|---|
| `pronto` | afirma — «F0-00 bloqueia 4 tickets» |
| `clarificar` | faz **uma** pergunta, com a contagem de cada opção |
| `reconhecido` | mostra resultados sem coroar nenhum |
| `sem_caminho` | diz que não sabe |

Cada plano guarda os **códigos das regras** que o produziram, e é isso que
o botão «porquê isto?» lê. A explicação não é uma frase escrita à mão: é o
objeto a dizer como chegou ali. Quando alguém acrescentar uma regra, a
explicação acompanha sozinha.

E a regra que não se atravessa: **nenhuma resposta sem proveniência.**
`resposta()` exige o campo, portanto não há caminho no código para o
evitar — o portão verifica que construir uma sem ele rebenta.

### O recorte — levar o caso, não um link

Depois de ler, a única coisa que se podia mandar a um colaborador era o
ficheiro inteiro (575 KB, 86 secções) ou uma âncora, que do outro lado
abre sem nada à volta.

Cada secção e cada caixa de decisão ganhou um botão **Recortar** (243 no
documento). O que se junta compõe-se em Markdown, JSON ou CSV. As duas
regras vêm do motor original, palavra por palavra:

1. **Nada é reescrito.** O texto de um item é a string publicada. Sem
   resumos, sem paráfrases. É a diferença entre um recorte que se pode
   citar e um que se tem de ir confirmar.
2. **Nada é inventado por ausência.** Um recorte sem tickets não gera
   secção «tickets» vazia — gera recorte sem essa secção.

A fronteira é lista **branca**: um campo que ninguém autorizou fica de
fora. Com lista negra, cada campo novo passaria a seguir por omissão e o
erro descobria-se depois de já ter seguido.

E cada recorte leva uma **impressão** — `4ba54b5a85553f61` — calculada
sobre os dados e não sobre a apresentação, e sem o instante da composição.
Serve uma frase que sem ela é impossível dizer: «este recorte foi feito
sobre a versão de terça; o dossiê mudou.»

A bandeja vive em `sessionStorage`, nunca no endereço. Um URL é
partilhado, indexado e registado em servidores que não são nossos, e o que
a pessoa escolheu ler é dela.

### A saúde — o relatório que não envelhece

Uma lista de 42 tickets não responde a «isto anda?». O painel dá uma
palavra — **Travado** — e por baixo os sete fatores que a produziram, cada
um com a evidência ao lado.

Nada ali está escrito à mão: `1 de 42`, `20 de 42 abertas`, `51 de 86` são
contados do ZIP no instante em que a página abre. Um relatório de auditoria
envelhece no dia em que se publica; isto não.

E é honesto de uma maneira específica, que vem do `saudeFiscal`: um fator
que não se consegue avaliar diz **«por medir»** em vez de contar como bom.
É a distinção que impede o verde falso.

#### Três defeitos que a construção destas camadas apanhou

| | |
|---|---|
| o flutuante do recorte caía **por baixo** da barra inferior ao telemóvel — visível e impossível de carregar, porque quem apanhava o toque era o botão «Topo» |
| `overflow:hidden` faz o mínimo automático de um item de grelha cair para zero: a lista media 378 px, era comprimida para 161 e cortava dois grupos **em silêncio** |
| a bandeja anunciava-se por evento e a interface não o ouvia — sincronizar no sítio de cada clique funciona até ao dia em que alguém muda a bandeja sem clicar |

O primeiro e o terceiro só apareceram porque o portão novo tenta *usar* as
coisas em vez de verificar que existem.

---

## 8 · As réguas, e o recorte

### Os cursores eram `input[type=range]` crus

Quatro cursores com `accent-color:var(--petrol)` e mais nada: um traço do
sistema, uma bolinha, e um azul que nem sequer é deste documento. Arrastar
não dizia nada até se largar e ler o gráfico.

A `ReguaPreco` do Recibo Certo resolve isto de uma forma que se aplica aqui
sem mudar uma vírgula: **o carril deixa de ser uma barra e passa a ser um
mapa.** Cada faixa tem nome e cor, e a cor diz o que acontece se largares
ali. O `input` nativo continua lá, invisível por cima: dá setas, Home/End,
PageUp/PageDown, leitor de ecrã e arrasto por dedo. A acessibilidade não é
reimplementada — é herdada.

**E o mapa sai do próprio modelo.** Varre-se a amplitude de cada cursor com
os outros três fixos, e a faixa é o dia da asfixia que dá. Nenhuma cor é
escolhida à mão e nenhuma fronteira é desenhada: as duas saem da simulação
e mudam quando os outros cursores mudam.

Tudo isso está certo. O que estava errado era o resto.

#### O mapa era ilegível para uma pessoa em cada doze

As faixas usavam os quatro tokens de estado do documento. Passados pelo
mesmo validador que corrigiu as cores do gráfico:

| | par | ΔE simulado |
|---|---|---|
| claro | `--ok` × `--aviso` | **3,2** sob protanopia |
| escuro | `--ok` × `--grave` | **2,5** sob deuteranopia |

O mínimo utilizável é 6. As cores do GRÁFICO tinham sido corrigidas para
isto na passagem anterior; as das RÉGUAS — que são o mapa que se lê **a
arrastar** — não.

E a causa não se resolve trocando de vermelho. Vermelho–âmbar–verde–cinzento
é um mapa **divergente**: bom no meio, mau dos dois lados. Só que num carril
o lado já está codificado — **pela posição**. Vê-se onde a pega está. Gastar
matiz a repetir o que a geometria já diz é exactamente o que obriga a pôr
vermelho ao lado de verde, e vermelho ao lado de verde é o par que a visão
deficiente não separa.

Sobra a informação que a geometria não dá: **a que distância do alvo se
está**. Isso é uma grandeza, e uma grandeza pinta-se com uma rampa de um
matiz só, com a luminosidade a subir. Três degraus, ambos validados
(monotonia, ΔL ≥ 0,06 entre degraus, contraste do degrau mais pálido contra
a superfície, dispersão de matiz ≤ 40°):

```
claro   #94AA86 → #6E8C61 → #2F6B33      pálido a 2,23:1 · matiz 12°
escuro  #4A5340 → #68805A → #8FC27A      pálido a 2,03:1 · matiz  9°
```

O degrau mais forte de cada uma é o `--ok` que o documento já tem: o alvo
não ganha uma cor nova, ganha a cor que o documento já usa para «certo». E
porque a diferença é de **luminosidade**, a rampa sobrevive ao cinzento, à
impressão e às cores forçadas.

#### O carril pintava de âmbar o que a própria §06 chama certo

O alvo de design que a §06 publica é «entre o dia 9 e o dia 14», e a §31 diz
que o CI falha fora dele. O número grande já ficava verde lá dentro — mas o
carril por baixo dele dizia «a meio» em âmbar, porque as faixas eram
`cedo (<10) / meio (10–20) / tarde (>20)`, um vocabulário que não é o do
documento. Duas peças a dizer coisas diferentes sobre o mesmo dia.

As faixas passam a ser o alvo e a distância a ele. O número grande ganha um
**selo escrito** ao lado — «no alvo», «cedo demais», «tarde demais» — porque
a cor não vai sozinha, e passa a usar `--ok` em vez de `--s2`: a cor de
«certo», e não a cor da linha do líquido, que é uma identidade de série a
fazer de veredicto.

#### A faixa verde anunciava um estado que não existe

«Aguenta os 30 dias» estava na legenda, pintada de bom. Varridas as
**343 434 combinações** dos quatro cursores no modelo da §06: a asfixia
chega em todas, o mais tarde ao **dia 28** — exactamente como a §06 afirma
(«mesmo com tudo no máximo, a asfixia chega ao dia 28»). A legenda descrevia
um território vazio, e pintava-o de verde.

A correcção não é apagar a entrada: é a legenda deixar de ser escrita à mão.
Ela é agora **derivada** das faixas que os quatro mapas contêm. Se alguém
mexer nos expoentes e o território passar a existir, a legenda ganha-o
sozinha; enquanto não existir, não é anunciado. O portão confere que a
legenda e o mapa dizem o mesmo conjunto.

#### A faixa estava meio passo ao lado do valor que descreve

As faixas eram desenhadas de `pos(a)` a `pos(b + passo)` — a posição da PEGA
no primeiro valor, até à posição da pega no valor a seguir ao último. Um
valor discreto não ocupa isso: ocupa de `a − ½` a `b + ½`. Com o cursor das
fontes (17 valores) a diferença são 3% do carril, e o efeito é visível: a
pega no primeiro valor de uma faixa aparecia **em cima da fronteira**, com a
cor da faixa anterior por baixo dela.

É o mesmo pecado que a `ReguaPreco` corrigiu quando juntou as duas
geometrias numa só, à escala de meio passo em vez de meia pega. O portão
mede-o agora: a pega tem de estar dentro da faixa que a pinta, e a pelo
menos 30% de um passo da fronteira.

Pela mesma razão as divisórias deixaram de ser um `border-inline-end` DENTRO
da faixa — dois pixéis comidos ao território, com a cor a mudar dois pixéis
antes da fronteira — e passaram a ser marcas próprias, **centradas** na
fronteira, pela mesma função que posiciona a faixa.

#### Mexer num cursor era uma porta sem retorno

O `ReguaPreco` marca o preço recomendado com um alfinete e tem «Voltar ao
recomendado». Aqui o equivalente existe e é melhor definido: o valor que a
§06 **publica**. Cada carril leva um alfinete nele, e aparece um «Repor a
§06» — só enquanto houver o que repor.

#### A linha por baixo dizia a coisa errada, duas vezes

A primeira versão punha o dia da asfixia, e as quatro réguas diziam «asfixia
ao dia 11» — porque o dia é um só. A segunda punha o alcance («alcança
1–21»), que já é próprio de cada cursor mas responde a uma pergunta que
ninguém faz: o alcance inclui territórios que não interessam a ninguém.

A pergunta que se faz antes de arrastar é «onde é que ponho ISTO?», e a
resposta é o intervalo que aterra no alvo:

| cursor | diz |
|---|---|
| Fontes de produção | dia 11 · alvo 6–9 fontes |
| Rotas de comércio | dia 11 · alvo até 1 rota |
| Tropas mantidas | dia 11 · alvo até 22 tropas |
| Ganância do rei | dia 11 · alvo 10–41 % |

É também a única coisa que a cor do carril não consegue dizer: o carril
mostra ONDE fica verde, a linha diz em que **números** — e é com números que
se edita `data/economy/curve.tres`.

O `aria-valuetext` leva o mapa inteiro, para quem navega às setas: «7 fontes
de produção — asfixia dia 11, no alvo».

#### E mais quatro coisas que a construção apanhou

| | |
|---|---|
| o comando media **22px** de altura e passava no portão por isenção de rótulo. Uma isenção é uma dispensa, não uma medida boa: passa a 36 |
| o cursor arrastado **pintava-se duas vezes** por movimento — a régua registava o seu próprio `input` e o simulador registava outro que mandava pintar as quatro — e varria a sua amplitude duas vezes para nada |
| a varredura **guardava a cache com os quatro valores**, o que invalidava os quatro mapas a cada movimento. O mapa do cursor `k` depende dos OUTROS três: passa a ser uma cache por cursor, e arrastar um deixa o dele intacto |
| a varredura **escrevia no `.value` do próprio input** para simular cada valor. Passa a haver um `modelo(v)` puro e um caminho rápido `diaDaAsfixia(v)` que não aloca as quatro séries — 151 chamadas por movimento. O portão confere que os dois concordam em 500 combinações, porque um expoente corrigido só num deles punha o mapa a descrever uma economia que o gráfico não desenha |

#### E o portão media três vezes o mesmo desenho

A §06 vive dentro de uma parte que entra **fechada**. Um SVG dentro de um
`<details>` fechado não tem caixa para medir, e o `ResizeObserver` não
dispara: o portão punha a janela a 320, a 360 e a 1280 e media, das três
vezes, o mesmo desenho de 800px — e dizia que estava tudo bem. Abre-se a
parte antes de medir. Só depois disso é que os cortes de rótulo a 320px
apareceram.

### O «Recortar» era uma barra vazia de 595px

Uma secção do dossiê é uma grelha de linhas nomeadas
(`[calha] 66px [medida] 595px [margem] 215px`), e um item de grelha é
esticado para a faixa onde cai. O `display:inline-flex` não o impede — quem
manda no tamanho de um item de grelha é a grelha. Daí a barra tracejada a
atravessar a coluna de leitura, por cima do primeiro parágrafo, em todas as
86 secções. `justify-self:end` devolveu-lhe os 100px do conteúdo.

E a funcionalidade ganhou quatro coisas:

| | |
|---|---|
| **`R`** | recorta a secção que estás a ler, sem ir buscar o rato |
| **Recortar as N secções** | no fim de cada parte — e o rótulo passa a «Tirar as N do recorte», porque um botão que alterna sem dizer para onde obriga a experimentar |
| **os itens da bandeja são destinos** | carregar leva lá e a folha sai da frente; rever o que se juntou deixou de obrigar a fechar, procurar e voltar |
| **sem ponteiro fino o botão vê-se sempre** | `@media (hover:none)` — um afordance que só aparece em hover não existe num telemóvel |

### Mais um corte que a medição apanhou — e o que ele escondia

O rótulo da asfixia no gráfico saía pela esquerda a 360px e chegava ao ecrã
como «fixia · dia 11». A regra antiga era «se a linha passou dos W−190,
escreve para a esquerda» — e a 360px o desenho inteiro tem menos de 190, por
isso a condição dava sempre verdadeiro.

A correcção de então — escolher o lado com mais espaço e grampear ao desenho
— resolveu o corte e deixou dois problemas por baixo dele, que só a medição
com o gráfico ABERTO trouxe à superfície (ver a última nota da §8):

1. **o limite era o fim do SVG, não o fim do desenho.** A calha da direita é
   onde vivem os nomes das pontas das séries, e em escala logarítmica a
   ponta mais alta — o custo da noite — fica exactamente à altura deste
   rótulo. Escrevia-se «asfixia · dia 11» por cima de «Custo»;
2. **grampear é a coisa errada a fazer quando não cabe.** A 320px o
   resultado era o rótulo atravessado por cima da própria linha que estava a
   nomear. Quando não cabe de nenhum dos lados, o que se faz é **escrever
   menos**: «dia 11», e depois «d11», que é o vocabulário do eixo x.

E a largura deixou de ser estimada a «7,25 px por caractere» — verdade para
a monoespaçada que o documento pede, falsa para a de reserva, e sem rede é
sempre a de reserva. `getComputedTextLength()` mede o texto real.
Verificado a 320, 360 e 1280, nos dois temas.

---

## 9 · A calha lateral, e as treze partes

### O que estava errado na calha

Estava **tudo em monoespaçada** — títulos, números e nomes de parte na
mesma face e quase no mesmo tamanho. Uma monoespaçada é boa para um
identificador (`F0-08`, `#4A781D`): alinha e não se confunde. Para
«Aleatoriedade com disciplina» faz o contrário — tira as formas que o
olho usa para reconhecer uma palavra sem a ler, que é exactamente o que
um índice serve para fazer.

Eram 41px por linha: **doze secções visíveis de 86**. E o item activo era
uma pastilha cheia, uma mancha de cor num sítio onde já competem 86
linhas.

| | antes | agora |
|---|---|---|
| face dos itens | monoespaçada | a de corpo (o número fica mono) |
| altura da linha | 41px | 28px (36px ao toque) |
| «estás aqui» | pastilha preenchida | calha + peso + tinta |
| separadores | um fio por grupo, 15 bandas | espaço, e fio só depois de uma lista aberta |
| o que se vê | 12 secções de 86 | as 13 partes inteiras, com contagem |

O cabeçalho de grupo mantém a face de pixéis do autor — é a identidade do
documento, e o que estava a mais eram os **itens**, não a sobrancelha.

### As treze partes

Cada parte passou a ser um `<details>`. Doze entram fechadas; a que o
endereço pede entra aberta.

**A forma troca; não se embrulha.** A primeira versão punha o cabeçalho do
autor — que já é um cartão completo, com régua, título e frase — dentro de
um SEGUNDO cartão de 202px. Dois títulos e duas bordas para a mesma coisa,
treze vezes seguidas. É exactamente o que o `SeccaoRevelavel` do Preço diz,
com todas as letras, para não se fazer.

    fechada  →  uma linha, com o nome e um resumo vivo
    aberta   →  o cabeçalho do autor, exactamente como sempre foi

Quando abre, a linha desaparece e o título do próprio cabeçalho ocupa-lhe o
lugar: leitura contínua, sem duplicação.

**E o resumo não é decoração.** Se a linha disser «11 secções», a pessoa tem
de abrir para saber se lhe interessa — a carga não desceu, passou a ser
treze decisões de «abro ou não abro?». Por isso a linha diz o intervalo e
os primeiros nomes:

> **PARTE VII · Sistemas**
> §48–§57 · GameClock — a fase do dia é um estado, não um temporizador,
> EconomySystem — três circuitos, uma passagem por fase, CombatSystem —
> legível antes de emocionante, RotSystem — uma entidade, não um spawner
> e mais 6

Muita gente já sabe aí que não é ali que quer estar — e não abre. É essa a
diferença entre esconder e resumir, e é o resumo que faz a densidade descer
de verdade.

**Recolher é acção secundária**, e fica no FIM do corpo, onde a pessoa
chega depois de ler — não no topo a competir com o conteúdo.

| | cartão (v1) | linha (v2) |
|---|---|---|
| altura fechada | 202px | 125–144px |
| treze fechadas | 2 424px | 1 538px |
| bordas por parte | 2 | 1 |
| o que se sabe sem abrir | «11 secções» | o intervalo e quatro nomes |

E há **uma só alavanca**: o grupo do índice e a parte no documento são a
mesma coisa. Fechar num sítio fecha no outro — dois mecanismos para uma
ideia é como não ter nenhum.

**A direcção importa.** O HTML sai com tudo aberto e é o JavaScript que
fecha. Quem não o tiver recebe o documento inteiro — a propriedade «sem
JavaScript lê-se de cima a baixo» continua verificada pelo portão. A
melhoria é o fecho, não a abertura.

#### Cinco defeitos que a medição apanhou nesta passagem

| | |
|---|---|
| o filtro das referências §NN recusa qualquer classe `x-*`, e eu envolvi o texto do autor em `x-parte-corpo` — **941 referências caíram para 174**, sem erro e com o portão a contar menos e a dizer que estava tudo bem |
| o índice tem 15 grupos e o documento 13 partes: casá-los por POSIÇÃO punha o grupo «I» a comandar a Parte II, e cada clique abria a parte errada |
| `dataset.parte` guardava «PARTE IV» inteiro, portanto nenhum grupo encontrava a sua parte |
| uma secção numa parte fechada mede zero, e zero passa em «lida quando o fundo passa os 140px» — fechar uma parte marcava as suas catorze secções como lidas |
| abrir uma parte faz o cabeçalho crescer 243px ACIMA do alvo, depois de o `scrollIntoView` já ter medido: o salto aterrava sempre 243px ao lado |

O último não se resolve a adivinhar um `setTimeout` — dá um número que
funciona nesta máquina e falha noutra. Resolve-se a **reconferir**: medir
de novo durante meio segundo e corrigir só quando o alvo saiu do sítio.

#### E uma coisa que ficou por corrigir, de propósito

A **§39 está fisicamente na Parte IV e o índice do autor lista-a na Parte
V**. Por isso a tira da Parte IV conta 12 e o índice conta 11. É uma
divergência do documento original, não da camada — e o conteúdo é do
autor, por isso fica registada aqui em vez de ser calada.

---

## 10 · O telemóvel, auditado a sério

Chegou uma captura de ecrã de um telefone: uma tabela da §01 com a terceira
coluna cortada a meio da palavra, sem forma de lá chegar. O portão dizia
«transbordos 0». Estava a dizer a verdade — e a medir a coisa errada.

### As 123 tabelas não podiam rolar, e ninguém sabia

A passagem anterior tinha posto `.tw{overflow-x:auto}` e uma etiqueta
«→ desliza». A camada de DESENHO, que entra depois, pôs
`.tw{overflow:hidden}` para arredondar os cantos do cartão — e o atalho
`overflow` escreve **os dois eixos**. As 123 tabelas perderam a rolagem no
mesmo instante, e a etiqueta, que se posiciona com `sticky; left:100%`,
ficou do lado de lá do corte.

Medido a 360px: **103 das 123 tabelas não cabem**, e as 123 tinham
`overflow-x: hidden`. Não havia rolagem — havia corte, sem aviso e sem saída.

E o portão não podia apanhar isto, porque a verificação 2 procura conteúdo
cortado **pela janela** e isenta as caixas que assumem a rolagem. Uma caixa
com `overflow:hidden` não faz nem uma coisa nem outra: corta dentro dos seus
próprios limites. Foi acrescentada a verificação que faltava, e é a que
teria apanhado isto no primeiro dia:

> **8 · caixas que cortam sozinhas** — qualquer caixa visível com
> `overflow-x:hidden` cujo conteúdo é maior do que ela. Isento o que corta
> de propósito e por uma linha (`ellipsis`, `line-clamp`) e as caixas de
> 1px que escondem texto para leitores de ecrã.
>
> **9 · caixas que rolam sem o dizer** — qualquer caixa que role de lado
> sem sombra de borda, sem pseudo-elemento e sem o atributo que a camada
> acende. Uma coluna cortada sem explicação lê-se como um defeito — foi
> exactamente assim que este chegou reportado.

### E rolar não chegava

O `.tw` era ao mesmo tempo o cartão (raio, sombra) e o scroller, e as duas
coisas querem `overflow` diferentes: uma tinha de ceder, e cedeu a que não
dava erro. Passam a ser dois elementos — `.tw` é o cartão, e `.x-rolo`,
dentro dele, é o scroller.

Mas a distribuição das tabelas diz que a rolagem só resolve metade:

| | tabelas | não cabem a 360px | caracteres por célula |
|---|---|---|---|
| 2 colunas | 5 | 1 | 65 |
| 3 colunas | 39 | 25 | 40 |
| 4 colunas | 49 | 48 | 29 |
| 5 colunas | 19 | 18 | 23 |
| 6 a 8 colunas | 11 | 11 | 7 a 13 |

Até cinco colunas com prosa são **fichas** — «nome · valor · o que isso
quer dizer» — e uma ficha lê-se de cima a baixo. Obrigar a deslizar para
ver a terceira coluna de cada linha é pedir seis gestos para ler cinco
factos. Essas **empilham**: cada linha passa a um bloco, a primeira célula
é o título dele, e as outras levam o nome da coluna por cima.

As restantes são **matrizes**, onde a comparação entre linhas É o conteúdo
e empilhar destruía-a. Essas **deslizam**, com sombra de borda dos dois
lados e a palavra «desliza →» no canto de cima à direita — que é onde se vê
a coluna cortada, e não no fundo do scroller, onde a primeira versão a pôs
e onde, numa tabela de 515px de altura, ninguém a via.

Três coisas que isto obrigou a decidir com cuidado:

1. **«Caber» não é «ler-se».** Uma tabela de três colunas de prosa cabe
   sempre em 328px — basta partir cada célula palavra a palavra. Era o que
   a §35 fazia: três colunas de 85px, uma palavra por linha, 232px de
   altura. A decisão passou a ter duas perguntas — «cabe ao mínimo?» e «e
   cabe de forma legível?», esta última contra a soma das larguras que as
   colunas *querem*, cada uma travada num tecto de 280px.
2. **Empilhar é um tratamento de ecrã estreito, não uma melhoria.** Acima
   de 560px nenhuma tabela empilha: uma tabela larga é uma tabela, e a que
   não couber na coluna de leitura desliza. Medido: a 1280px, 120 intactas,
   3 a deslizar, 0 empilhadas.
3. **`display:block` tira a uma tabela a semântica de tabela.** Empilhada,
   uma `<tr>` deixa de ser uma linha na árvore de acessibilidade e uma
   `<td>` deixa de ter cabeçalho. Devolve-se por `role`, e só enquanto está
   empilhada; o `<thead>` fica escondido à moda dos leitores de ecrã, não
   removido; e o rótulo de coluna que aparece em cada célula é um elemento
   `aria-hidden`, e não um `::before` — conteúdo gerado por CSS é anunciado
   por alguns leitores, e ali repetiria o cabeçalho que a tabela ainda tem.

Resultado, a 360px: **77 fichas empilhadas, 43 matrizes a deslizar, 3
intactas, 0 a cortar**. Células de prosa abaixo de 150px: **0**, contra 362.

### O mesmo atalho, outra vez, nos 52 blocos de código

Os blocos de código ganharam a sombra clássica de quatro camadas com
`background-attachment: local` — que aparece só do lado para onde ainda há
conteúdo e não custa uma linha de JavaScript. Não apareceu: a camada de
desenho escreve `pre{background:var(--sunk)}`, e o atalho `background`
apaga também o `background-image`. Passou a `background-color`, com a razão
escrita ao lado.

**Três defeitos, um padrão.** `overflow` no `.tw`, `background` no `pre`, e
antes disso o `.shell{grid-template-columns}` do achado A-3: um atalho de
uma camada posterior apaga o que a anterior tinha nomeado, sem erro e sem
aviso. É a lição que a camada de desenho tem escrita à cabeça e que voltou
a acontecer duas vezes.

### A régua tipográfica também empurrava para baixo

A regra do piso era uma lista de selectores com `font-size:12px!important`.
Para os que estavam a 9 ou 10 fez o que devia. Mas **dezanove dos
selectores da lista já estavam acima de 12** — e o `!important` desceu-os.
Medido a 360px, com a regra desligada:

| | natural | com a régua |
|---|---|---|
| `td` (4 002 células) | 16px | 12px |
| `.trk-h` | 16,5px | 12px |
| `.mark` | até 18px | 12px |
| `label` | até 15px | 12px |

O caso do `label` é o que se via melhor: o nome de cada uma das 48
mecânicas do rastreador descia de 15 para 12, enquanto a etiqueta da fase
ao lado subia de 10 para 12. **A hierarquia ao contrário** — o metadado a
pesar mais do que o conteúdo.

Não há em CSS forma de dizer «pelo menos 12, senão o que era» sem saber o
que era. Por isso a lista passou a ser medida: ficam nela os selectores
cujas instâncias estão todas abaixo de 12, e saem os que já estavam acima.
Os que tinham instâncias dos dois lados voltaram pelo contexto de cada um
(`.sim-ctl label`, `.cell h6`), com o portão a dizer quais eram — 111
sítios na primeira volta, e o portão a nomear cada um.

E uma tabela que desliza compacta-se agora **de propósito** (13px, mais
colunas por gesto) e não por efeito colateral de uma régua que apanhava
`td` no meio do caminho.

### O glossário estava a apagar palavras dos desenhos

Um elemento HTML inserido dentro de um `<svg>` fora de um
`<foreignObject>` fica na árvore e **não é pintado**. O glossário e o
ligador das §NN entravam nos desenhos:

| | no `textContent` | no ecrã |
|---|---|---|
| §05 | «A Podridão nasce na borda do mapa ▸» | «nasce na borda do mapa ▸» |
| §41 | «Autoloads: EventBus · GameClock · …» | «Autoloads:  · GameClock · …» |

Medido: a largura pintada da figura da §05 era 144px e passou a 210. É a
mesma figura que uma passagem anterior tinha corrigido por outra razão — o
recorte da calha — e que continuava a chegar ao ecrã sem duas palavras.

Os dois varrimentos passam a recusar qualquer nó dentro de um `<svg>`, e o
portão ganhou a verificação: **nenhum elemento HTML dentro de um desenho**.

### E a lista de invólucros, pela terceira vez

O prefixo `x-` significa duas coisas: «isto é da camada, não mexer» e «isto
é um invólucro que embrulha prosa do autor». Cada vez que um invólucro novo
apareceu, os dois varrimentos passaram a saltar tudo o que estava lá dentro:

| invólucro novo | referências §NN | termos de glossário |
|---|---|---|
| `x-parte-corpo` | 941 → 174 | — |
| `x-rolo` | 940 → 531 | 150 → 84 |

Nas duas vezes sem erro, e com o portão a imprimir o número novo como se
fosse normal. A lista passou a viver num sítio só (`X.INVOLUCROS`, em
`01-busca.js`), lida pelos dois varrimentos — e o portão passou a ter um
chão para as duas contagens, para não haver uma quarta vez.

### E um espaço que o `display:flex` comeu

O alvo tátil do rótulo de cada mecânica é dado por `display:flex`. Só que
isso transforma o texto e a referência «§NN» em dois **itens** de flex, e o
espaço em branco entre itens de flex desaparece: as 48 linhas do rastreador
liam-se «Inspirado em Kingdom§02». Um `gap` devolve-o, e um `wrap` deixa a
referência descer quando a frase é longa, em vez de a atirar para a margem
direita.

### O portão, agora

```
360px · light    rolagem 0 · transbordos 0 · corta-sozinha 0 · rola-sem-dizer 0 · texto<12px 0 · alvos<36px 0
360px · dark     rolagem 0 · transbordos 0 · corta-sozinha 0 · rola-sem-dizer 0 · texto<12px 0 · alvos<36px 0
320px · light    rolagem 0 · transbordos 0 · corta-sozinha 0 · rola-sem-dizer 0 · texto<12px 0 · alvos<36px 0
320px · dark     rolagem 0 · transbordos 0 · corta-sozinha 0 · rola-sem-dizer 0 · texto<12px 0 · alvos<36px 0
1280px · light   rolagem 0 · transbordos 0 · corta-sozinha 0 · rola-sem-dizer 0 · texto<12px 0 · alvos<24px 0
1280px · dark    rolagem 0 · transbordos 0 · corta-sozinha 0 · rola-sem-dizer 0 · texto<12px 0 · alvos<24px 0
```

Mais doze asserções de comportamento em `verificar-novo.mjs`, sobre o que as
tabelas fazem e não sobre as classes que têm.

### O que continua por verificar

- A medição correu **sem as fontes de ecrã** (o ambiente não tem rede para
  o Google Fonts). As larguras mínimas das tabelas — que decidem quem
  empilha e quem desliza — são feitas de métricas de fonte, e com Fraunces
  e Source Serif 4 serão ligeiramente diferentes. A decisão é remedida
  quando `document.fonts.ready` resolve, por isso corrige-se sozinha; o
  que não foi verificado é se alguma tabela troca de tratamento.
- Não foi testado em Safari nem em Firefox. `background-attachment:local`,
  `clip-path`, `min-content` e `color-mix()` são suportados nos três
  motores actuais, mas não foi verificado.
- Não houve teste com leitor de ecrã real numa tabela empilhada. Os `role`
  estão lá e o `<thead>` continua na árvore, mas semântica correcta e
  experiência boa não são a mesma coisa.
