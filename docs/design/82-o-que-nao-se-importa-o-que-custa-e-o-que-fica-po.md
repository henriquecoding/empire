# 82 — Disciplina · novo · O que não se importa, o que custa, e o que fica por decidir

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Uma influência mal gerida deixa de ser influência e passa a ser fan game. As seis coisas abaixo são boas na série e seriam más aqui, e cada uma tem uma razão que não é de gosto — é de formato, de duração ou de sistema.

## Seis coisas a não trazer

| O que | Porque é bom lá | Porque é mau aqui |
| --- | --- | --- |
| A revelação do purgatório | Cem minutos de investimento, cobrados uma vez, e recontextualizam tudo | Quarenta horas com permadeath e decay (§16). "Afinal nada aconteceu" apaga o jogo que o jogador acabou de jogar. |
| Os dois irmãos | Um contraste de temperamento carrega a série inteira | O Empire troca de personagem controlado com o Verbo 2 (§08). Um par fixo mata o sistema de classes e a colagem de povos. |
| A iconografia americana | É o vernáculo do país deles, com cem anos, posto fora de sítio | Não é o teu. Abóboras com cara ao lado de palafitas da Carrasqueira e de ferrarias bascas lê-se a empréstimo. §73. |
| Dez capítulos como espinha | A série é uma viagem: a estrutura episódica é o enredo | A espinha do Empire é o ciclo dia-noite. Os capítulos (§77) são conteúdo lateral, e assim que forem obrigatórios partem o loop. |
| O registo irónico moderno | O Wirt fala como um adolescente de 2014, e o atrito com o mundo é metade da piada | O Empire não tem protagonista falante nem texto de diálogo (§27). Sem onde assentar, a ironia vira anacronismo solto. |
| O epílogo que arruma toda a gente | Recompensa emocional depois de cem minutos de ameaça | Cinquenta horas de mortes permanentes. Arrumar toda a gente no fim desmente cada uma delas. |


## O problema que este trabalho criou, e a solução

> **Acessibilidade — apanhado a tempo**
>
> A §78 e a §81 põem o mostrador de moral inteiramente no som: o coro tem tantas vozes quantos povos soltaste. Para um jogador surdo, esse sistema não existe, e a §26 quer Steam Deck Verified e acessibilidade a sério. A Dívida da Candeia tem redundância visual — o brilho da candeia (§75) — mas o coro não tinha nenhuma.
>
> Proposta: cada povo solto hasteia o seu estandarte sobre o teu núcleo, um por povo, no mesmo sítio e na mesma ordem. Seis mastros. Zero números, zero UI, e o mostrador passa a ter as duas vias. Um povo ficado deixa o mastro vazio, o que é uma imagem melhor do que o estandarte cheio.

## O que custa, e onde entra

| Secção | Código | Arte | Som | Escrita | Total | Fase (§33) |
| --- | --- | --- | --- | --- | --- | --- |
| §80 · Preto na paleta, noite castanha | 2 | +2 | — | — | 4 | Fase 0 |
| §74 · Termo dos Amargueiros na massa | 1 | — | — | — | 1 | Fase 1 |
| §74 · Amargueiro e candeia, completos | 10 | 3 | — | — | 13 | Fase 2 |
| §75 · A Oferta e a Dívida | 12 | 4 | 2 | 2 | 20 | Fase 3 |
| §76 · O Nome | 7 | 2 | 1 | 1 | 11 | Fase 4 |
| §78 · A Colheita | 8 | 3 | — | — | 11 | Fase 5 |
| §77 · Dez capítulos | 30 | 50 | 20 | 6 | 106 | Fase 5 |
| §79 · Os doze diários e os três epílogos | 3 | — | — | 10 | 13 | Fase 6 |
| §81 · Som, tudo o resto | 6 | — | 38 | — | 44 | Fase 6 |
| §83 · Os primeiros vinte minutos | 3 | 4 | — | 1 | 8 | Fase 1 |
| §84 · Os catorze testes de design | 6 | — | — | — | 6 | Fase 1 |
| Total | 88 | 68 | 61 | 20 | 237 | — |


Duzentas e trinta e sete horas, das quais 106 são um só item — os dez capítulos — que é cortável até quatro sem partir nada, porque a §77 já prevê que só seis apareçam por campanha. O caminho mínimo que dá a transformação inteira é §80 + §74 + §75 + §83 + §84: 52 horas, e é aí que está quase todo o efeito. As §83 e §84 entram nesse mínimo de propósito: sem a primeira, o jogador conhece o Amargueiro tarde demais para ele significar alguma coisa; sem a segunda, os números das outras três desafinam-se sozinhos até ao mês oito.

> **A ordem, e porque é que a §80 é primeiro**
>
> Só há uma dependência dura em toda a parte, e é de calendário e não de código: o teto de valores por camada tem de ser decidido antes de se desenhar cenário. Decidir agora custa 4 h. Decidir na Fase 5 custa redesenhar as camadas de fundo dos seis biomas. Tudo o resto pode entrar pela ordem que quiseres, e as §76, §77 e §81 podem cair inteiras sem que as outras deixem de funcionar.

> **Onde ficam os testes e os riscos**
>
> Os catorze testes de design, as seis linhas novas do registo de risco da §37 e a lista dos campos de estado que o save passa a ter estão na §84. Nenhum sistema desta parte entra no repositório sem o teste que o guarda.

## Uma decidida, nove por decidir

> **Q-037 · fechada**
>
> A noite é castanha — decidido a 13 de setembro de 2026, docs/adr/0011-noite-castanha.md. A tabela da §05 está corrigida e o clock.csv deixou de marcar night_tint_hsv e night_value_floor como proposta. Com esta fechada, nenhuma pergunta da Parte XIII bloqueia a Fase 0.

| # | A pergunta | Proposta | Bloqueia |
| --- | --- | --- | --- |
| Q-038 | A massa base desce de 60 para 40 e o termo do dia de 26 para 18. A Q-001 (o Aríete de lodo contra 105 s de noite) muda de resposta? | Recalcular o teste da §31 com os números novos antes de o desmarcar. | F1-09 |
| Q-039 | A lei do Forno Aceso (§77) faz nascer um Amargueiro dentro das muralhas, contra a regra da §74. Exceção ou erro? | Exceção deliberada, e a única. Se houver uma segunda, corta-se esta. | Fase 5 |
| Q-040 | A oferta "O que brilha, e nada mais" salta 105 s de jogo. Uma vez por campanha, ou com intervalo? | Uma vez por campanha. Saltar a noite duas vezes ensina a evitar o jogo. | Fase 3 |
| Q-041 | Nove nomeados é teto fixo ou cresce com o império? | Fixo. Cresce e deixa de significar nada. | Fase 4 |
| Q-042 | C = 6 + 2 × povos detidos põe a sexta Colheita em 16 dias. Longo demais? | Medir em playtest. Alternativa: 6 + 1,5 × n, arredondado. | Fase 5 |
| Q-043 | Seis capítulos por campanha de dez, ou os dez sempre? | Seis. Quatro por descobrir valem mais do que dez esgotados. | Fase 5 |
| Q-044 | O motivo sonoro da Podridão substitui um indicador visual de proximidade, ou coexistem? | Coexistem, mas o visual é a própria candeia e não um ícone. | §26 |
| Q-045 | A Dívida da Candeia fica escondida mesmo no modo de acessibilidade? | Fica. O brilho e os estandartes são a redundância; um número não é acessibilidade, é spoiler. | §26 |
| Q-046 | O Turno (terceiro epílogo, §79) entra na Fase 8 ou corta-se? | Entra. É um sinalizador no save e um termo na semente, e é o mais forte dos três. | Fase 8 |


> **A regra da Parte XII continua a valer**
>
> A §72 fechou a pré-produção e disse que o dossiê só muda por correção, por decisão que vira ADR, ou por número que um playtest desmentiu. Esta parte é do segundo tipo e tem de pagar o preço disso: cada secção daqui tem de virar ADR antes de virar código, e as dez perguntas acima entram no QUESTIONS.md com a proposta que já está nos CSV do anexo. Nada foi decidido em silêncio. A Q-037 fechou a 13 de setembro (ADR 0011): a noite é castanha, e com ela fora do caminho nenhuma pergunta desta parte bloqueia a Fase 0. As nove que sobram esperam pelas Fases 3 a 8, ou por um playtest.
