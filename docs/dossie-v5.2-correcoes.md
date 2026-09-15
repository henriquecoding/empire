# Dossiê Empire v5.2 — o que mudou desde a v5.1

> Revisão completa do texto do dossiê em **português europeu, com o Acordo Ortográfico de 1990**, feita sobre a v5.1.
> Cada linha abaixo é uma substituição exata: o texto da coluna **Antes** foi trocado pelo da coluna **Depois**,
> e nada mais. Os blocos de código "pronto a copiar" (`<pre>` e `<code>`) ficaram de fora de propósito — são ASCII sem acentos
> para poderem ser colados em ficheiros de código, e mudá-los partia a §69.

## Resumo

- **105 correções** em **92 blocos** de texto do HTML (parágrafos, células, títulos, listas, legendas) e numa cadeia da lista de mecânicas do rastreador.

| Tipo | Quantas | O quê |
|---|---:|---|
| AO90 | 69 | Grafia anterior ao Acordo Ortográfico (o resto do dossiê já seguia o AO90) |
| PT-BR | 9 | Formas do português do Brasil trocadas pelas de Portugal |
| concordância | 5 | Concordância (género, número, verbo) |
| sintaxe | 8 | Sintaxe (modo verbal, colocação do pronome, "se" em falta, relativo solto) |
| regência | 1 | Regência |
| crase | 1 | Crase |
| acentuação | 4 | Acentuação que muda a palavra |
| pontuação | 1 | Pontuação (separador decimal) |
| gralha | 2 | Gralhas |
| coerência | 5 | Coerência interna (números e remissões que não batiam com o próprio dossiê) |

As mais sérias, por ordem: "**Rouváveis**" → "Roubáveis" (§06); "**os dois riscos fatais são os mesmos risco**" → "o mesmo risco" (§37); 
"**Uma cavidade tem de caber um monarca**" → "Numa cavidade…" (§11); "**Só se podes entrar uma vez**" → "Só podes…" (§36); 
"**respondem a que jogo é este e vale a pena fazê-lo**" → "e se vale a pena" (§39); "**virgula flutuante**" → "vírgula" (§42); 
e as cinco correções de coerência, que não são de português mas estavam erradas: a §21 anunciava "cinco regras" e dava seis; 
a §37 falava de "outros nove riscos" numa tabela de doze; a §39 e a §65 remetiam para a §28 um critério de saída que está na §33; 
e a fase 5 do roadmap chamava-se "Próximo Fest" — tradução acidental do *Next Fest* da Steam, que a célula ao lado já nomeava bem.

## O que ficou como estava, e porquê

- **Termos ingleses de ofício** (*sprite, save, commit, tick, seed, parallax, playtest, build, backlog, devlog, wishlists, publisher*…): são jargão, não erros. Não se acrescentou itálico nem se traduziu nada.
- **"a personagem" / "o personagem"**: os dois géneros são aceites (em Portugal prefere-se o feminino, que é o que o dossiê usa quase sempre); os poucos masculinos ficaram.
- **"a §22" / "o §22"**: o símbolo lê-se "secção" ou "parágrafo"; as duas leituras são corretas e o dossiê usa as duas.
- **"não-diegético", "não-threaded"**: o hífen depois de "não" não é tratado de forma uniforme pelos vocabulários ortográficos; na dúvida, ficou.
- **Neologismos de desenvolvimento** (*jogável, testável, multijogador, rejogabilidade, autoritativo, autorado, versionado, tipado*): são formações regulares.
- **"facto", "contacto", "característica", "carácter"**: mantêm a consoante porque ela se pronuncia em Portugal — é assim no AO90.
- **Citações** (a tua lista original, as frases dos criadores do Kingdom e do Thronefall): ficaram literais, mesmo quando a grafia é discutível ("a tela é dividida ao meio").
- **Os blocos de código** (`<pre>`, `<code>`, o CSS e a lógica do script): intocados. Só mudou uma cadeia de texto visível do script — "super-tropa" na lista de mecânicas.

## Como se verificou

1. **Dicionário** — todas as palavras da prosa passaram pelo dicionário pt_PT do LibreOffice (grafia do AO90), via Hunspell.
2. **Leitura integral** — as 4 103 unidades de texto do dossiê (parágrafos, células, títulos, legendas, textos de SVG, atributos e as cadeias do rastreador) foram lidas uma a uma, secção a secção.
3. **Padrões** — procuras dirigidas a crase, "porquê/porque", "têm/tem", clíticos depois de "que/não/já", hífenes de prefixos, palavras repetidas, espaços antes de pontuação.
4. **Aplicação cirúrgica** — cada correção foi aplicada como substituição exata, e depois conferida bloco a bloco: mudaram exatamente os 92 blocos previstos (mais a cadeia do script), e nenhum outro. O `check_dossie_vs_csv.py` continua a dar 127 valores conferidos, 0 divergências.

## Parte 1 — As correções de português, uma a uma

| # | Onde | Antes | Depois | Tipo | Porquê | Contexto (v5.1) |
|---:|---|---|---|---|---|---|
| 1 | §00 | contra o quê rever | contra o que rever | acentuação | "que" átono antes de infinitivo não leva acento | …ejas. Uma revisão só existe se houver contra o quê rever. Até agora, a §19 dava definições de … |
| 2 | §00 | ordem exacta | ordem exata | AO90 | grafia do AO90 | … os campos, 61 eventos catalogados, a ordem exacta do tick, a disciplina de aleatoriedad… |
| 3 | §00 | Pára tudo | Para tudo | AO90 | o AO90 eliminou o acento de "para" (verbo parar) | Não há jogo. Pára tudo. |
| 4 | §00 | nunca se bloquearam | nunca se bloqueiam | sintaxe | tempo verbal: é uma regra geral (presente), como na §22 ("não se bloqueiam") | …ódigo são dias diferentes da semana e nunca se bloquearam. |
| 5 | §00 | as dezanove que faltavam | os dezanove que faltavam | concordância | refere-se a "ficheiros" (masculino), como diz a §68 | …tem antes do primeiro código e audita as dezanove que faltavam; a §69 dá o conteúdo de cada um, pron… |
| 6 | §01 | na lista de esta semana | na lista desta semana | sintaxe | contração obrigatória de + esta | … de design por tomar, e a §38 tem-nas na lista de esta semana. |
| 7 | §01 | tela efectiva | tela efetiva | AO90 | grafia do AO90 | …da imagem por esse período obtém-se a tela efectiva: a altura, em pixels de arte, a que o… |
| 8 | §01 | Tela efectiva | Tela efetiva | AO90 | grafia do AO90 | Tela efectiva |
| 9 | §01 | = fracção de sequências horizontais | = fração de sequências horizontais | AO90 | grafia do AO90 | "Detalhe de 1 px" = fracção de sequências horizontais de cor com um só pixel de comprimento… |
| 10 | §01 | = fracção de sequências escuras | = fração de sequências escuras | AO90 | grafia do AO90 | …elha do próprio jogo. "Contorno 1 px" = fracção de sequências escuras com um só pixel. A estimativa de tama… |
| 11 | §01 | mesma fracção de ecrã | mesma fração de ecrã | AO90 | grafia do AO90 | … Uma tropa tua de 47 px a 720 ocupa a mesma fracção de ecrã que uma de 25 px a 376. Pões 1 px de … |
| 12 | §01 | única excepção | única exceção | AO90 | grafia do AO90 | As personagens são a única excepção, e é de propósito. Elas ficam com det… |
| 13 | §04 | como codinome do jogo | como nome de código do jogo | PT-BR | "codinome" é brasileirismo; em PT-PT é "nome de código" | Uso Empire como codinome do jogo e A Podridão para a ameaça noturna. O… |
| 14 | §06 | meta-progresso | metaprogresso | AO90 | "meta-" só leva hífen antes de h ou de a | Nunca se perde. É o teu meta-progresso. |
| 15 | §06 | Rouváveis | Roubáveis | gralha | erro de digitação (roubar → roubável) | Rouváveis à noite |
| 16 | §06 | a rota pára até | a rota para até | AO90 | o AO90 eliminou o acento de "para" (verbo parar) | …correr o caminho. Se a carroça morre, a rota pára até a substituíres. |
| 17 | §07 | micro-teste | microteste | AO90 | "micro-" só leva hífen antes de h ou de o | … 5 e perdida sem torre no dia 8. Este micro-teste é a fundação de todo o balanceamento … |
| 18 | §08 | corpo-a-corpo | corpo a corpo | AO90 | locução sem hífen no AO90 | … morre, fica cego: o alcance cai para corpo-a-corpo e o jogador perde visão periférica no… |
| 19 | §11 | Uma cavidade tem de caber | Numa cavidade tem de caber | regência | é o monarca que cabe na cavidade, não o contrário | Uma cavidade tem de caber um monarca (58 px) de pé, com teto e … |
| 20 | §11 | fundo actual | fundo atual | AO90 | grafia do AO90 | A tua §22 descreve o teu fundo actual como "achatado". É exactamente isso: … |
| 21 | §11 | É exactamente isso | É exatamente isso | AO90 | grafia do AO90 | …e o teu fundo actual como "achatado". É exactamente isso: tens duas superfícies — céu e chão —… |
| 22 | §11 | "objectos sobre um fundo" | "objetos sobre um fundo" | AO90 | grafia do AO90 | … e tu não fazes, e é o que transforma "objectos sobre um fundo" numa paisagem. |
| 23 | §11 | excepto as voadoras | exceto as voadoras | AO90 | grafia do AO90 | …ueta contornada entra na faixa aérea, excepto as voadoras e a copa da árvore colossal do castel… |
| 24 | §11 | , que é justamente por isso que ela | , e é justamente por isso que ela | sintaxe | o relativo "que" não tem função na oração; é uma coordenada | …e a copa da árvore colossal do castelo, que é justamente por isso que ela vai ler-se como monumental. |
| 25 | §11 | A excepção medida | A exceção medida | AO90 | grafia do AO90 | A excepção medida: cenas fechadas invertem a regra |
| 26 | §13 | Se a muralha cai e o rei | Se a muralha cair e o rei | sintaxe | as duas condições coordenadas pedem o mesmo modo (futuro do conjuntivo) | Se a muralha cai e o rei inimigo estiver ausente, os defensore… |
| 27 | §14 | super-tropa | supertropa | AO90 | "super-" só leva hífen antes de h ou r | …aba com o acampamento e volta com uma super-tropa — a melhor unidade do jogo naquele bi… |
| 28 | §14 | Porquê isto é | Porque é que isto é | acentuação | "porquê" acentuado não introduz oração com verbo conjugado | Porquê isto é o teu melhor sorvedouro |
| 29 | §15 | zerada | a zero | PT-BR | "zerar" é brasileirismo; em PT-PT "a zero", como na célula ao lado | Dívida de mercenários zerada |
| 30 | §17 | lida em conjunto, explica-a | lida em conjunto, a explica | sintaxe | o relativo "que" atrai o pronome (próclise), mesmo com a intercalação | …dos descrevem uma decisão humana que, lida em conjunto, explica-a. |
| 31 | §17 | A ruptura | A rutura | AO90 | grafia do AO90 em Portugal | III — A ruptura |
| 32 | §21 | designer de arquitectura | designer de arquitetura | AO90 | grafia do AO90 | …uele sítio. O Chef RPG é feito por um designer de arquitectura que desenha cada local aplicando prin… |
| 33 | §21 | Cinco regras | Seis regras | coerência | a lista a seguir tem seis regras (1 a 6) | …autorada e separar quem autora o quê. Cinco regras, e a primeira sozinha resolve metade … |
| 34 | §21 | é exactamente | é exatamente | AO90 | grafia do AO90 | …nte interessantes não tem nenhuma — e é exactamente o que acontece quando se espalham edi… |
| 35 | §21 | e ainda distingues o povo | e ainda distinguires o povo | sintaxe | coordenada com "se cobrires" — o mesmo modo (futuro do conjuntivo) | …cobrires tudo abaixo da linha do solo e ainda distingues o povo, o kit está bom. Variedade de props n… |
| 36 | §21 | designer de arquitectura | designer de arquitetura | AO90 | grafia do AO90 | O autor do Chef RPG é designer de arquitectura. Aplica desenho urbano a cada local —… |
| 37 | §21 | directamente | diretamente | AO90 | grafia do AO90 | …atro ferramentas, e todas se traduzem directamente para 1.5D. |
| 38 | §21 | a correcção | a correção | AO90 | grafia do AO90 | A linha do solo é a rua. E aqui está a correcção que mais vai mudar as tuas cenas: os … |
| 39 | §22 | fonte arquitectónica | fonte arquitetónica | AO90 | grafia do AO90 | …ala dupla, a pilha de iluminação, e a fonte arquitectónica de cada povo. O plano de produção foi… |
| 40 | §22 | directamente | diretamente | AO90 | grafia do AO90 | …ncas diferentes, e que só uma delas é directamente tua. |
| 41 | §22 | tela efectiva | tela efetiva | AO90 | grafia do AO90 | 582–640 px de tela efectiva, menos de metade da tua. A beleza não… |
| 42 | §22 | arquitectura | arquitetura | AO90 | grafia do AO90 | Chef RPG — arquitectura |
| 43 | §22 | tela efectiva | tela efetiva | AO90 | grafia do AO90 | 799×450 de tela efectiva. Feito por um designer de arquitectur… |
| 44 | §22 | designer de arquitectura | designer de arquitetura | AO90 | grafia do AO90 | …99×450 de tela efectiva. Feito por um designer de arquitectura que desenha cada local com princípios… |
| 45 | §22 | Arquitectura primeiro | Arquitetura primeiro | AO90 | grafia do AO90 | Arquitectura primeiro (é grátis), composição a seguir (é a … |
| 46 | §22 | teu activo | teu ativo | AO90 | grafia do AO90 | …erde 6,3% dos pixels a reduzir, e é o teu activo mais valioso e o mais difícil de refa… |
| 47 | §22 | é directo | é direto | AO90 | grafia do AO90 | …e de desenho dentro dela. E o cálculo é directo: |
| 48 | §22 | A excepção deliberada | A exceção deliberada | AO90 | grafia do AO90 | A excepção deliberada. As figuras ficam ao dobro da resoluç… |
| 49 | §22 | como mediu a eles | como os mediu a eles | sintaxe | o pronome tónico "a eles" como complemento direto pede o clítico "os" (como em "mede-te a ti") | …e qualquer captura tua — mede-te a ti como mediu a eles. |
| 50 | §22 | optimista | otimista | AO90 | grafia do AO90 | …pixel por peça — não é uma estimativa optimista, é aritmética de área. Os valores da … |
| 51 | §22 | classe de objecto | classe de objeto | AO90 | grafia do AO90 | Um sprite de elipse por escala e por classe de objecto, mais o nó que o coloca |
| 52 | §22 | largura do objecto | largura do objeto | AO90 | grafia do AO90 | …ro quente — nunca preto. Escala com a largura do objecto, não com a altura. |
| 53 | §22 | "objectos pousados | "objetos pousados | AO90 | grafia do AO90 | … isolado do documento. É o que separa "objectos pousados numa imagem" de "objectos que estão a… |
| 54 | §22 | "objectos que estão ali" | "objetos que estão ali" | AO90 | grafia do AO90 | …ra "objectos pousados numa imagem" de "objectos que estão ali". As tuas cenas flutuam sobre branco; … |
| 55 | §22 | objectos-herói | objetos-herói | AO90 | grafia do AO90 | É o efeito Eastward a sério. Só para objectos-herói — núcleo, castelo, muralhas, forja. N… |
| 56 | §22 | resolve exactamente | resolve exatamente | AO90 | grafia do AO90 | …inquenta horas de edifícios novos — e resolve exactamente o sintoma que a §01 descreve: figuras… |
| 57 | §22 | As fracções acima | As frações acima | AO90 | grafia do AO90 | … move-se em pixels inteiros de mundo. As fracções acima são todas binárias exactas (1/32, 1/8… |
| 58 | §22 | binárias exactas | binárias exatas | AO90 | grafia do AO90 | …de mundo. As fracções acima são todas binárias exactas (1/32, 1/8, 1/4, 1/2, 3/2) precisamen… |
| 59 | §22 | fonte arquitectónica | fonte arquitetónica | AO90 | grafia do AO90 | Cada povo precisa de uma fonte arquitectónica, não de uma paleta |
| 60 | §22 | mistura arquitectura | mistura arquitetura | AO90 | grafia do AO90 | …rata e a mais subestimada. O Eastward mistura arquitectura japonesa Showa e Taishō com Hong Kong… |
| 61 | §22 | cruza arquitectura | cruza arquitetura | AO90 | grafia do AO90 | …hō com Hong Kong e Xangai; o Chef RPG cruza arquitectura asiática e ocidental com cyberpunk, e… |
| 62 | §22 | fonte arquitectónica | fonte arquitetónica | AO90 | grafia do AO90 | …s kits estão certos. É por isso que a fonte arquitectónica importa mais do que a paleta: a palet… |
| 63 | §22 | são a excepção | são a exceção | AO90 | grafia do AO90 | …uído a esta resolução. As personagens são a excepção e ficam a 1 px. |
| 64 | §22 | Sem excepções | Sem exceções | AO90 | grafia do AO90 | …tanha quente, multiplicativa, 45–55%. Sem excepções, nem para caixotes. |
| 65 | §22 | fonte arquitectónica | fonte arquitetónica | AO90 | grafia do AO90 | …e de um kit novo, e cada povo tem uma fonte arquitectónica real escrita no seu PeopleData.tres… |
| 66 | §25 | Meta-progresso | Metaprogresso | AO90 | "meta-" só leva hífen antes de h ou de a | Meta-progresso e narrativa |
| 67 | §26 | Nenhum caractere | Nenhum carácter | PT-BR | "caractere" é a forma do Brasil; em PT-PT é "carácter" | Nenhum caractere abaixo de 9 px de altura a 1280×800; … |
| 68 | §26 | altura de caractere | altura de carácter | PT-BR | "caractere" é a forma do Brasil; em PT-PT é "carácter" | …0: ou desenhas a tua fonte a 12 px de altura de caractere, ou tens duas fontes (uma decorativa … |
| 69 | §31 | É vinte linhas de código | São vinte linhas de código | concordância | "ser" concorda com o predicativo plural | …nha-o em segundos, sem tu leres nada. É vinte linhas de código que protegem a decisão mais important… |
| 70 | §33 | Próximo Fest | Next Fest | coerência | "Next Fest" é o nome do evento da Steam (a célula ao lado diz "Demo no Next Fest") | 5 · Próximo Fest |
| 71 | §33 | pára e diagnostica | para e diagnostica | AO90 | o AO90 eliminou o acento de "para" (verbo parar) | > 5 000 wishlists. Se não, pára e diagnostica. |
| 72 | §36 | Só se podes entrar uma vez | Só podes entrar uma vez | gralha | "só se podes" diz "só no caso de poderes"; o sentido é "só podes entrar uma vez" | Só se podes entrar uma vez. É o teu maior pico único. |
| 73 | §36 | um codinome | um nome de código | PT-BR | "codinome" é brasileirismo; em PT-PT é "nome de código" | Empire é um codinome, não um nome. É genérico demais para … |
| 74 | §37 | o devlog pára | o devlog para | AO90 | o AO90 eliminou o acento de "para" (verbo parar) | Duas semanas sem commit; o devlog pára |
| 75 | §37 | são os mesmos risco | são o mesmo risco | concordância | singular: os dois riscos são um só | Os dois riscos fatais são os mesmos risco |
| 76 | §37 | os outros nove riscos | os outros dez riscos | coerência | a tabela tem doze riscos; tirando os dois fatais, sobram dez | …rio jogo às sextas. Se não acontecer, os outros nove riscos não interessam. Todo o plano existe a… |
| 77 | §38 | Altura de caractere | Altura de carácter | PT-BR | "caractere" é a forma do Brasil; em PT-PT é "carácter" | Altura de caractere da fonte ≥ 12 px |
| 78 | §39 | e vale a pena fazê-lo | e se vale a pena fazê-lo | sintaxe | interrogativa indireta total pede "se" | …nteriores respondem a que jogo é este e vale a pena fazê-lo. As vinte e nove que se seguem respon… |
| 79 | §39 | contra o quê rever | contra o que rever | acentuação | "que" átono antes de infinitivo não leva acento | …ejas. Uma revisão só existe se houver contra o quê rever. Sem especificação, cada sessão de ag… |
| 80 | §39 | Sem excepções | Sem exceções | AO90 | grafia do AO90 | …m o nome daqui, o código está errado. Sem excepções — nomes divergentes são o que quebra … |
| 81 | §39 | §28 tem critérios de saída | §33 tem critérios de saída | coerência | os critérios de saída por fase estão na §33 (Roadmap), não na §28 | §28 tem critérios de saída, §34 tem 30 tickets |
| 82 | §39 | pára e pergunta | para e pergunta | AO90 | o AO90 eliminou o acento de "para" (verbo parar) | …es de algo que não está especificado, pára e pergunta em vez de decidir. A terceira é a que… |
| 83 | §40 | exactamente para isso | exatamente para isso | AO90 | grafia do AO90 | …m fluxo: o fluxo visual, que existe exactamente para isso e nunca afecta a simulação. |
| 84 | §40 | nunca afecta | nunca afeta | AO90 | grafia do AO90 | …, que existe exactamente para isso e nunca afecta a simulação. |
| 85 | §42 | Se o jogador salva a meio | Se o jogador grava a meio | PT-BR | "salvar" um ficheiro é uso do Brasil; em PT-PT grava-se ou guarda-se | Guardar a seed não chega. Se o jogador salva a meio da noite 9, retomar tem de continuar … |
| 86 | §42 | aleatória exactamente onde ia | aleatória exatamente onde ia | AO90 | grafia do AO90 | … retomar tem de continuar a sequência aleatória exactamente onde ia — logo o save guarda o estado de cada… |
| 87 | §42 | o resultado afecta | o resultado afeta | AO90 | grafia do AO90 | Nunca iterar um Dictionary quando o resultado afecta a simulação. Ordem de dicionário não … |
| 88 | §42 | Sem virgula flutuante | Sem vírgula flutuante | acentuação | o nome é "vírgula" (esdrúxula); "virgula" é forma do verbo virgular | Sem virgula flutuante acumulada |
| 89 | §43 | Entrega a apresentação | Entrega à apresentação | crase | entrega (os eventos) à camada de apresentação: a + a | Entrega a apresentação |
| 90 | §44 | kit de arquitectura | kit de arquitetura | AO90 | grafia do AO90 | kit de arquitectura, rampa de paleta, fonte arquitectónic… |
| 91 | §44 | fonte arquitectónica | fonte arquitetónica | AO90 | grafia do AO90 | kit de arquitectura, rampa de paleta, fonte arquitectónica, tropa única, modificadores |
| 92 | §46 | Meta-progresso | Metaprogresso | AO90 | "meta-" só leva hífen antes de h ou de a | Meta-progresso, save |
| 93 | §47 | 0.4 s | 0,4 s | pontuação | em português a vírgula é o separador decimal (como na §07 e na §50) | 0.4 s |
| 94 | §47 | é exactamente por isso | é exatamente por isso | AO90 | grafia do AO90 | … de um sistema é um chumbo. É rude, e é exactamente por isso que funciona quando o código não é es… |
| 95 | §50 | re-escolher | reescolher | AO90 | o prefixo "re-" nunca leva hífen (como reescrever, reeleger) | …ais próximo em faixa atingível. Nunca re-escolher se o alvo atual serve — é o que evita… |
| 96 | §52 | imperceptível | impercetível | AO90 | grafia do AO90 em Portugal | …cide cinco vezes por segundo, o que é imperceptível e corta a IA para um sexto do custo. … |
| 97 | §58 | pára de animar | para de animar | AO90 | o AO90 eliminou o acento de "para" (verbo parar) | …creenNotifier2D: continua a simular, pára de animar. A simulação nunca depende de estar v… |
| 98 | §61 | dado o mesmo seed | dada a mesma seed | concordância | o dossiê usa "a seed" no feminino em todo o lado ("a seed é visível") | …terminista apesar de haver um humano: dado o mesmo seed e a mesma sequência de intenções, a p… |
| 99 | §61 | repete-se exactamente | repete-se exatamente | AO90 | grafia do AO90 | …sma sequência de intenções, a partida repete-se exactamente. E é isso que torna possível gravar u… |
| 100 | §65 | Critério de saída do §28 | Critério de saída do §33 | coerência | o critério de saída da Fase 0 está na tabela do §33 (Roadmap), não no §28 | …minhos marcados §70 foram corrigidos. Critério de saída do §28: um sprite anda nas três faixas e o C… |
| 101 | §65 | mais as 19 da §68 | mais os 19 da §68 | concordância | refere-se a "ficheiros" (masculino) | Infraestrutura — 6, mais as 19 da §68 |
| 102 | §66 | Salvar a meio da noite 9 | Gravar a meio da noite 9 | PT-BR | "salvar" um ficheiro é uso do Brasil; em PT-PT grava-se ou guarda-se | Salvar a meio da noite 9 e retomar continua a mesma noite, com… |
| 103 | §66 | Salvar e carregar | Gravar e carregar | PT-BR | "salvar" um ficheiro é uso do Brasil; em PT-PT grava-se ou guarda-se | Salvar e carregar um estado vazio. Fazer isto cedo é o … |
| 104 | §70 | exactamente o que | exatamente o que | AO90 | grafia do AO90 | …NE. Dois nomes para o mesmo número — exactamente o que a regra do vocabulário do §28 existe … |
| 105 | ★ Rastreador (script) | super-tropa | supertropa | AO90 | "super-" só leva hífen antes de h ou r | lista das 48 mecânicas |


## Parte 2 — As alterações de conteúdo da v5.2

> Além do português, a v5.2 mexe no dossiê em 27 sítios, todos cirúrgicos: a versão, o índice, a caixa da §00,
> as linhas da §39 que diziam "em falta" para coisas que agora existem, as correções de código que a implementação
> exigiu (C-01 a C-05, na §47 e na §69), duas contradições internas que o próprio dossiê já resolvia (Q-020 e Q-021),
> as contagens de ficheiros e de secções, e a Parte XII nova. Nenhum texto de design foi reescrito.
> Nas colunas, `¦` separa células de tabela e `⏎` marca uma mudança de linha dentro de um bloco de código.

| # | Onde | Porquê | Antes | Depois |
|---|---|---|---|---|
| E01 | Cabeçalho | versão | Dossiê de produção · v5.1 · setembro 2026 · Rico | Dossiê de produção · v5.2 · setembro 2026 · Rico |
| E02 | Cabeçalho, etiquetas | contagem de secções e a Parte XII | 71 secções | 73 secções |
| E03 | Cabeçalho, etiquetas | nova etiqueta da v5.2 | *(nada)* | Etiqueta nova: "Repositório a correr" |
| E04 | Índice lateral | entrada da Parte XII | *(nada)* | Grupo "XII · A implementação", com as entradas 71 e 72 |
| E05 | §00 | caixa "O que a v5.2 acrescenta" | *(nada)* | Caixa nova, depois da da v5.1: *O que a v5.2 acrescenta — a Parte XII* |
| E06 | §34, F0-00 | contagem de ficheiros gerados (73 secções, o rastreador e o INDEX.md) | Push verde e docs/design/ com 72 ficheiros | Push verde e docs/design/ com 75 ficheiros |
| E07 | §39, tabela do que falta | estado atualizado: bíblia de arte | Existe, disperso ¦ §01 · §11 · §21 · §22 | Existe — arrumada na v5.2 ¦ §01 · §11 · §21 · §22, e docs/art/ (§71) |
| E08 | §39, tabela do que falta | estado atualizado: base de dados de conteúdo | Em falta ¦ Hoje os números vivem em prosa nas §06 a §10, e vão viver outra vez em .tres ¦ Alta — §44 diz como se resolve | Existe desde a v5.2 ¦ data/source/: 23 tabelas geradas para .tres e conferidas contra este dossiê pelo CI (§71) ¦ Feita — falta aprovares as propostas |
| E09 | §39, tabela do que falta | estado atualizado: bíblia de nomes | Em falta ¦ §17 tem segredos; os nomes dos povos são provisórios | Proposta na v5.2 ¦ docs/content/NAMING_BIBLE.md; o nome do jogo continua por escolher |
| E10 | §39, tabela do que falta | coerência: a Parte VI é "Dados"; as Fases 0 e 1 estão na Parte X | Resolvida na Parte VI | Fases 0 e 1 na Parte X; os tickets em docs/backlog/ (v5.2) |
| E11 | §42, tabela dos fluxos | Q-020: a tabela passa a dizer o que o código logo abaixo faz | world ¦ Geração de região, tipos de segmento, cavidades, passagens ¦ seed | world ¦ Geração de região, tipos de segmento, cavidades, passagens ¦ hash(str(seed) + "world") |
| E12 | §42, tabela dos fluxos | Q-020 | seed ^ 0x51ED | hash(str(seed) + "combat") |
| E13 | §42, tabela dos fluxos | Q-020 (0xR0T7 nem é hexadecimal) | seed ^ 0xR0T7 (constante nomeada) | hash(str(seed) + "rot") |
| E14 | §42, tabela dos fluxos | Q-020 | seed ^ 0xEC0N | hash(str(seed) + "economy") |
| E15 | §42, tabela dos fluxos | Q-020 | seed ^ 0x0A1A | hash(str(seed) + "ai") |
| E16 | §47, band.gd | C-01: o GDScript não aceita várias constantes numa linha | const L_AERIAL := 1, L_SURFACE := 2, L_UNDER := 4 ⏎ const L_TERRAIN := 8, L_BUILDING := 16, L_COIN := 32 | # v5.2: uma constante por linha — o GDScript não aceita várias numa só (C-01, §72) const L_AERIAL := 1 ⏎ const L_SURFACE := 2 ⏎ const L_UNDER := 4 ⏎ c… |
| E17 | §47, tabela de constantes | Q-021: a §69 criou o ClockData (ADR 0006) | DAY_SECONDS ¦ 360 ¦ §05 ¦ Sim → vai para EconomyCurve | DAY_SECONDS ¦ 360 ¦ §05 ¦ Sim → vai para ClockData (v5.2, ADR 0006) |
| E18 | §67, caixa "A peça que falta" | a base de dados existe | É a peça que mais depressa transforma tudo isto em código a correr. | É a peça que mais depressa transforma tudo isto em código a correr. Existe desde a v5.2: são 23 tabelas, e não sete, porque os campos desta parte pedi… |
| E19 | §69, .gitattributes | C-05: text forçado corrompia os PNG dos addons | addons/** -filter -diff -merge text ⏎ | # v5.2: 'text' forcado corrompia os PNG dos addons; '!' repoe o valor por omissao (C-05, §72) ⏎ addons/** !filter !diff !merge text=auto ⏎ |
| E20 | §69, ci.yml | C-03: o gdUnit4 6.x sai com 103 em --headless | run: godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests ⏎ | # v5.2: o gdUnit4 6.x sai com 103 em --headless sem esta opcao (C-03, §72) ⏎ run: godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd --i… |
| E21 | §69, ci.yml | C-04: o export falha sempre sem os templates do motor | O passo de export, sem templates | Dois passos novos (cache e instalação dos templates de Linux), e o export passa a verificar o `.pck` e a arrancar o executável — igual ao `ci.yml` do repositório |
| E22 | §69, run_tests.sh | C-03 | "$GODOT" --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests "$@" | # v5.2: o gdUnit4 6.x recusa --headless sem --ignoreHeadlessMode (sai com 103). C-03, §72 ⏎ "$GODOT" --headless --path . -s addons/gdUnit4/bin/GdUnitC… |
| E23 | §69, .gdlintrc | C-02: os padrões recusavam nomes privados usados pelo GameClock do §30 | function-name: '(_on_)?[a-z][a-z0-9]*(_[a-z0-9]+)*' ⏎ class-variable-name: '[a-z][a-z0-9]*(_[a-z0-9]+)*' | # v5.2: '_?' aceita privados (_init, _durations), que o GameClock do §30 usa (C-02, §72) ⏎ function-name: '(_on_)?_?[a-z][a-z0-9]*(_[a-z0-9]+)*' ⏎ cla… |
| E24 | §69, split do dossiê | contagem de ficheiros gerados | 72 ficheiros de docs/design/ | 75 ficheiros de docs/design/ |
| E25 | Parte XII (§71 e §72) | nova parte: índice do repositório e achados da implementação | *(nada — a parte é nova)* | A Parte XII inteira — §71 *O repositório que já existe, pasta a pasta* e §72 *O que a implementação encontrou no dossiê* — inserida antes do Rastreador |
| E26 | Rodapé | versão | Empire — Dossiê de produção v5.1. | Empire — Dossiê de produção v5.2. |
| E27 | Rodapé | contagem de secções (a v5.1 ainda dizia 68) | Sessenta e oito secções, num documento só. | Setenta e três secções, num documento só — e, desde a v5.2, um repositório que corre. |

Duas frases da própria Parte XII foram afinadas depois de inseridas ("as duas linhas por fazer", "o simulador do §06"); o texto do dossiê já é o final.

O diff completo, linha a linha, está em `docs/dossie-v5.1-para-v5.2.diff`.

---

Gerado a partir de `docs/dossie.html` v5.1 → v5.2. Para reverter uma correção, troca a coluna **Depois** pela **Antes** no bloco indicado.
