# 21 — Mundo · Geração procedural do território

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

O Kingdom usa "blocos de construção modulares dispostos aleatoriamente, com vegetação de solo colocada automaticamente e cotos estratégicos de torre e muro para evitar sobreposição". É o modelo certo para ti também.

> **Correção**
>
> A versão anterior desta secção dizia que a tua panorâmica "já é, na prática, o primeiro protótipo" do gerador e que "cada edifício está colocado com intenção". Não é e não está. É uma folha de assets com 24,5% da superfície pintada e vazios de até 400 px (§01). Ainda não existe nenhum segmento autorado — o primeiro está por fazer, e o resto desta secção é a proposta de como o fazer, não a descrição de algo que já lá está.

- **Região** — 4 a 6 ecrãs de largura — oito segmentos na fatia vertical, dez a doze quando uma região pedir cinco ou seis ecrãs, com ADR (Q-030). Não fixes isto pela largura da tela onde desenhaste — deriva-o do tempo de travessia: a pé (§12) atravessar uma região leva cerca de 40–60 s. É uma estimativa, e não uma lei: cada região é única e o número adapta-se a ela, e mede-se no greybox (Q-018, Q-082). A pé anda-se a 80 px/s (ADR 0021). Uma região = um povo = um império a conquistar.
- **Segmento** — 640 px (meio ecrã). Oito segmentos por região. Cada segmento é uma cena autorada à mão.
- **Linha do solo** — Constante em toda a região, no valor fixado na Fase 0 (§11). O terreno não sobe nem desce — é o que torna o mundo 1.5D e o movimento das tropas trivial (§20).
- **Corte de solo** — Gerado em paralelo com a superfície: cada segmento tem 0–2 cavidades e 0–1 passagem, dentro da altura fixada em §11.

| Tipo de segmento | Peso | Restrição |
| --- | --- | --- |
| base_inicial | — | Blueprint técnica da sede. O jogador escolhe a coordenada válida de fundação; não nasce um castelo ao centro (ADR 0066). |
| vazio | 30 | Terreno livre para o jogador construir. Nunca menos de 3 por região. |
| bosque / agua / rocha | 25 | Define a especialidade económica disponível. agua exige um vazio antes. |
| ruina | 12 | Traz uma passagem para o corte de solo. |
| acampamento_mercenario | 8 | Gerador atual: um a cada 4–7 segmentos. Contrato novo: mercenários móveis depois da fundação; migração pendente em RG-24. |
| fortaleza | 6 | Gerador atual: nunca duas adjacentes. Contrato novo: sociedades surgem de sementes depois da fundação, sem fortaleza organizada no dia 1; RG-24 pendente. |
| caotico | 4 | Só a partir da segunda região. |


> **Mundo natural e despertar social — ADR 0069**
>
> No contrato do relatório, dia 1 é natural: clima, biomas, fauna, ruínas e perigos. Depois da fundação e da primeira noite territorial, a alvorada seguinte ativa sementes de civilização por dia global. O gerador de sociedades prontas descrito abaixo ainda é a implementação antiga: RG-24 deve migrá-lo com determinismo, saves e níveis de simulação. A fundação livre Solo já funciona; clima e despertar social ainda não.

## O conflito que as referências levantam — e como se resolve

Há aqui uma contradição que este documento nunca tinha nomeado, e as três referências obrigam a nomeá-la agora.

> **Nomear o problema**
>
> O Eastward não usa tiles. A Pixpil decompõe cada edifício em camadas — telhado à parte das paredes —, remonta-as em 3D dentro do motor e pinta um bump map à mão para cada peça. Nada se repete: tudo é feito à medida daquele sítio. O Chef RPG é feito por um designer de arquitetura que desenha cada local aplicando princípios de desenho urbano. O Milki Delivery tem três pessoas e um jogo de duas a quatro horas — cada ecrã é uma ilustração.
>
> Os três são bonitos porque são autorados sítio a sítio. O teu jogo monta o território a partir de segmentos sorteados por uma seed. É o modelo certo para um kingdom-builder com rejogabilidade — mas é, literalmente, o oposto do que faz a beleza das tuas referências. Fingir que não há conflito é como se resolve mal.

A saída não é abandonar a geração. É subir a unidade autorada e separar quem autora o quê. Seis regras, e a primeira sozinha resolve metade do problema.

**1 · O parallax nunca é por segmento a mais importante** — As camadas de céu, distância e plano médio (§11) são geradas uma vez por região, como uma paisagem contínua, a partir da seed. Só o plano de jogo e o primeiro plano são montados segmento a segmento. O olho lê uma paisagem única; o jogo lê oito módulos. É este único truque que faz montagem procedural parecer composição.

Uma coisa em que o olho pousa: o moinho, a ponte, a árvore partida, o poço. Tudo o resto é acompanhamento. Um segmento com quatro coisas igualmente interessantes não tem nenhuma — e é exatamente o que acontece quando se espalham edifícios numa folha para ver como ficam.

O teste do §22 mantém-se e agora tem um método: se cobrires tudo abaixo da linha do solo e ainda distinguires o povo, o kit está bom. Variedade de props não substitui variedade de remate. É onde 80% da identidade de um povo vive.

Cada prop repetível precisa de 4 variantes no mínimo e de uma regra de "não repetir a mesma variante dentro de 400 px". Espelhar é proibido em tudo o que tenha lado iluminado — a luz vem sempre do mesmo sítio e o olho apanha o espelhamento antes de perceber porquê.

Mantém-se inteira, e agora com mais razão: com a lei da escala dupla (§01), pintar um segmento com a composição errada custa-te meio dia em vez de um dia — mas continua a não consertar nada.

Um ecrã por império, acabado a 100% e fora do gerador. Serve de padrão de qualidade para os segmentos daquele povo, de material para a página da Steam, e de resposta à pergunta "quanto tempo demora uma cena acabada" (§22).

## A lição do Chef RPG: desenhar lugares, não fundos

O autor do Chef RPG é designer de arquitetura. Aplica desenho urbano a cada local — e é por isso que uma aldeia dele parece habitada e uma folha de assets não. São quatro ferramentas, e todas se traduzem diretamente para 1.5D.

| Ferramenta | O que é | Na tua vista lateral |
| --- | --- | --- |
| Marco | O elemento alto que se vê de longe e orienta. | Um por região, visível de três segmentos de distância, no plano médio ou a furar a faixa aérea. Para os Enramados é a árvore colossal; para os Portuários é o farol; para a Fornalha é a chaminé. |
| Limiar | A passagem de um sítio para outro, marcada. | A fronteira entre povos nunca é um fade: é um portão, uma ponte, uma falha na rocha, uma muralha em ruínas. Um segmento dedicado, com peso próprio. |
| Bordo | Onde o lugar acaba. | Uma região tem de terminar em alguma coisa — falésia, mar, muralha, desfiladeiro. Nunca em mais terreno igual que desaparece fora do ecrã. |
| Percurso | A rua. Os edifícios dirigem-se a ela. | A linha do solo é a rua. E aqui está a correção que mais vai mudar as tuas cenas: os teus edifícios assentam na linha do solo; têm de dar para ela. Entre a fachada e a linha por onde as tropas andam tem de haver 12–20 px de soleira: um degrau, um caixote, uma lanterna, ferramentas encostadas. É essa faixa de 16 px que faz um edifício parecer usado por alguém. |


> **Números de partida para a densidade — para o playtest desmentir**
>
> A §01 diz, e bem, que a densidade se decide a jogar. Mas começar de zero é pior do que começar de um número errado. Da tua própria panorâmica (4446 px de mundo construído, vazios de até 400 px) e da leitura das referências:

> **Porquê autorar segmentos em vez de gerar tudo**
>
> Com pixel art desenhada à mão, ruído procedural produz paisagens sem intenção. Segmentos autorados dão controlo de composição, reaproveitam os teus tilesets, e permitem slots de construção pré-definidos à maneira do Thronefall — forçar posições arriscadas em vez de deixar o jogador amontoar tudo no sítio seguro. Uma única seed reproduz tudo: guarda-a no save e mostra-a ao jogador.
>
> Não comeces por desenhar. Constrói um segmento de 640 px inteiramente com formas lisas de cor — retângulos para edifícios, uma barra para o chão, blocos para cavidades — e joga-o. Um segmento greybox leva vinte minutos a fazer e diz-te em cinco se a densidade está certa. Só depois de teres seis ou oito segmentos que se jogam bem é que vale a pena pintar algum: pintar um segmento com a composição errada custa-te um dia e não conserta nada.

Painel de 30/09/2026 — ADR 0043. Os oito povos têm kits, assuntos e obras locais próprios. O povo do pântano chama-se Bruma, nome de trabalho ajustável; os identificadores anteriores migram nos saves. Uma muralha própria além de um acampamento ou uma árvore vizinha abatida acaba com ele; no sítio pode erguer-se uma casa de cidadãos, até três à espera e mais caros (Q-170, Q-175). Os valores novos de balanceamento são propostas ajustáveis nas tabelas.
