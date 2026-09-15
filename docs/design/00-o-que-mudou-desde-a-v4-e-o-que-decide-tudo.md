# 00 — Veredito · O que mudou desde a v4, e o que decide tudo

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

A v3 respondeu a consegues acabá-lo?. A v4 respondeu a como é que os cenários ficam bonitos?, medindo as três referências que deste — Milki Delivery, Eastward e Chef RPG — e reescrevendo a §01, a §11, a §21 e a §22 em consequência. Esta versão acrescenta a peça que faltava ao projeto inteiro: a especificação técnica, §39 a §67, agora dentro deste documento e não ao lado dele.

> **O achado da v4, que se mantém**
>
> As cinco capturas das tuas referências foram desenhadas entre 327 e 450 pixels de altura de arte. Tu desenhas a 720. Nenhuma delas é bonita por causa da resolução — e uma delas nem sequer é pixel art. A §01 tem os números; a §22 tem o que fazer com eles.

> **O que a v5 acrescenta, e porquê**
>
> O teu plano é que a IA escreva quase todo o código e tu revejas. Uma revisão só existe se houver contra o que rever. Até agora, a §19 dava definições de projeto, uma estrutura de pastas e um exemplo de Resource — um esboço de arquitetura. Cada sessão de agente reinventava nomes de campos, ordem de execução e contratos de módulo, e tu passavas o tempo a arbitrar decisões que já tinhas tomado, sem te lembrares de quando.
>
> As secções §39 a §67 fecham isso: doze recursos de definição com todos os campos, 61 eventos catalogados, a ordem exata do tick, a disciplina de aleatoriedade, o esquema do save, os orçamentos de desempenho, cinco portões de CI, e a Fase 0 e a Fase 1 listadas ao nível do ficheiro, com horas e critérios de aceitação. O CLAUDE.md do repositório aponta para elas.

## As três correções materiais

**Motor** — Godot 4.6, não 4.5. Saiu em janeiro de 2026 com docks móveis, previews de recursos em tempo real, @export por drag-and-drop e suporte para profilers de tracing (Tracy, Perfetto). Nada disto muda a arquitetura — muda a velocidade a que a IA e tu trabalham.

A §06 foi reescrita de raiz. A tua economia tem três circuitos — produção, conversão e comércio — onde o Kingdom só tem um. O comércio faltava por completo no documento e é o que dá razão económica para manteres vivo o que conquistas. Os números do Kingdom ficam só como referência de escala.

As referências foram medidas, não descritas (§01). Daí sai a lei da escala dupla: no cenário, tudo o que na referência é 1 px é 2 px na tua grelha. Corta o cenário de 109 h para ≈ 70 h, e as horas libertadas vão para luz — que é onde está o retorno. A §22 tem a pilha completa.

## O tamanho real do que planeaste

Recontei a tua lista: são 48 mecânicas, não 42 como dizia a v2. O Kingdom: Two Crowns, feito por um estúdio com publisher e anos de iteração, tem cerca de 15. Isto continua a não ser um problema — é uma decisão de sequenciamento. O que mudou é que agora tens esse sequenciamento escrito ao nível do ticket (§34) e as 48 rastreáveis no fim do documento.

| Camada | O que é | Fase | Se falhar |
| --- | --- | --- | --- |
| 1 — O motor | Ciclo dia/noite, moeda física, controlo indireto, muros, ondas noturnas | 0–2 | Não há jogo. Para tudo. |
| 2 — Identidade | Classes com duas fases, ofícios, segunda camada, montarias, conquista, ganância | 3–5 | Tens um clone de Kingdom. Vendável, esquecível. |
| 3 — Profundidade | Sucessão, dívida, conversão, lore, biomas caóticos, multijogador | 6–8 | Tens o jogo. Cortas sem dor. |


> **O achado desta revisão**
>
> O cenário é o caminho crítico, não o código nem as personagens. A IA escreve o código e tu revê-lo; as figuras já estão desenhadas. O que falta é o mundo à volta delas — ≈ 70 das ≈ 176 horas de arte da fatia vertical depois da revisão da v4 (§22). Ao ritmo de um sábado por semana são sete meses, e o roadmap dava-lhe três. A solução não é trabalhar mais: é começar o cenário da Fase 2 durante a Fase 1, estreitar a fatia, e pôr a luz antes dos edifícios. Arte e código são dias diferentes da semana e nunca se bloqueiam.

> **O único risco que mata o projeto**
>
> Não é técnico. É construíres a Camada 2 antes de a Camada 1 estar divertida. O teste é brutal e simples: se o ciclo de 10 dias com uma classe, um bioma e uma fortaleza não te fizer querer jogar mais um dia, nenhuma quantidade de bardos e diplomatas salva. A Fase 2 existe exatamente para responder a isso antes de gastares dois anos. §33 e §37.

> **O compromisso, atualizado**
>
> 28 a 40 meses para a versão completa, com jogo jogável ao fim de 7 meses e demo pública ao fim de 14. §35 põe-lhe um preço: entre 2 700 € e 16 000 € em custos diretos, conforme o cenário. O custo real é o teu tempo, e esse está contabilizado.

> **O que a v5.1 acrescenta — a Parte XI**
>
> Três secções no fim, e um punhado de correções ao longo do documento. A §68 responde a que ficheiros existem antes do primeiro código e audita os dezanove que faltavam; a §69 dá o conteúdo de cada um, pronto a copiar, incluindo o script que transforma este dossiê nos ficheiros de docs/design/ que o contrato do agente manda ler; a §70 resolve seis contradições que as dez partes anteriores deixaram abertas — o relógio, a faixa, a câmara, o arranque. Nenhuma delas é grave enquanto ninguém escreve código; todas se tornam duas implementações do mesmo conceito no dia em que alguém escreve.

> **O que a v5.2 acrescenta — a Parte XII**
>
> Nenhuma teoria nova. Duas secções no fim e o português revisto de ponta a ponta. A §71 é o índice do repositório que já existe: abre no Godot 4.6, passa os testes, exporta um executável, e tem os números deste dossiê em 23 tabelas que o CI confere contra o texto. A §72 lista o que a implementação encontrou de errado aqui dentro — sete ficheiros do dia zero que não corriam como estavam escritos, já corrigidos na §47 e na §69, e as contradições entre secções, que passaram para docs/QUESTIONS.md em vez de serem decididas em silêncio. As 105 correções de português estão, uma a uma, em docs/dossie-v5.2-correcoes.md.
