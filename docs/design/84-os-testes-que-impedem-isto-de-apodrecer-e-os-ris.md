# 84 — Garantias · novo · Os testes que impedem isto de apodrecer, e os riscos que traz

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

A §31 diz porque é que os testes existem neste projeto: sem eles não consegues rever o que a IA escreve, e ao fim de duas semanas deixas de tentar. Nove sistemas novos sem testes de design são nove sistemas que se desafinam sozinhos no mês oito e ninguém dá por isso. Catorze testes, seis riscos novos para a §37, e a lista dos campos de estado que o save passa a ter — porque a Q-036 obriga a que sejam todos tipos base.

## Os catorze testes de design

| # | O que garante | Falha quando | Secção |
| --- | --- | --- | --- |
| D-01 | A massa em campo limpo ao dia 20 é 400 | Alguém mexe nos coeficientes sem refazer a tabela da §74 | §74 |
| D-02 | O Lenho Amargo não tem preço de venda, e o rendimento sobe com a escala | Alguém lhe dá valor em moedas — e a exploração do vagabundo volta | §74 |
| D-03 | Um Amargueiro não se corta antes de aguentar uma noite | A regra 2 da §74 se perde numa refatoração | §74 |
| D-04 | A penalização por recusa nunca passa de 40 | O teto desaparece e um jogador principista fica com um jogo impossível | §75 |
| D-05 | Uma oferta por noite, mesmo com duas manchas a partir do dia 12 | A voz vira um sistema de menus | §75 |
| D-06 | A Dívida nunca desce, em nenhum caminho de código | Aparece uma forma de a limpar, e o epílogo deixa de significar nada | §75 · §79 |
| D-07 | Nunca há mais de nove nomeados vivos | O teto cede e o nome deixa de valer | §76 |
| D-08 | Um título volta com ordinal depois de três dias de luto | O sistema se esgota às nove horas de jogo | §76 |
| D-09 | Todos os capítulos colocados têm caminho alternativo | Um capítulo passa a bloquear a rota e parte a regra 5 | §77 |
| D-10 | Exatamente um capítulo tem law_enters_walls | Aparece o segundo, e a exceção do Forno Aceso deixa de ser especial | §77 |
| D-11 | Seis capítulos por campanha, e o Cerco é sempre um deles | O diário 12 fica inalcançável nalgumas sementes | §77 |
| D-12 | Os doze diários são alcançáveis em mil sementes seguidas | Uma combinação de capítulos deixa um ato sem fragmentos | §79 |
| D-13 | O epílogo é determinista e segue a precedência da §79 | Dois estados iguais dão dois finais | §79 |
| D-14 | O save dos sistemas novos só contém tipos base | Alguém guarda um Resource e reabre o buraco da Q-036 | §84 |


Cinco deles escrevem-se em vinte linhas e são os que apanham as regressões que doem:

```gdscript
# tests/design_unknown_test.gd
extends GdUnitTestSuite

func test_d01_massa_campo_limpo_dia_20() -> void:
    assert_float(Rot.mass(20, 0, 0, 0, 0)).is_equal_approx(400.0, 0.1)

func test_d02_lenho_nao_e_moeda() -> void:
    assert_bool(Lenho.sellable).is_false()
    assert_int(Amargueiro.yield_for(1, false)).is_equal(1)   # vagabundo
    assert_int(Amargueiro.yield_for(3, false)).is_equal(3)   # elite
    assert_int(Amargueiro.yield_for(1, true)).is_equal(5)    # nomeado

func test_d03_espera_uma_noite() -> void:
    var a := Amargueiro.root(&"vagrant", 1, false, 4)
    assert_bool(a.can_fell(4)).is_false()
    assert_bool(a.can_fell(5)).is_true()

func test_d04_recusa_tem_teto() -> void:
    var r := RotState.new()
    for i in 30: r.refuse()
    assert_float(r.refusal_penalty()).is_less_equal(40.0)

func test_d10_uma_so_lei_entra_em_casa() -> void:
    var n := ChapterDB.all().filter(func(c): return c.law_enters_walls).size()
    assert_int(n).is_equal(1)
```

> **O D-12 é o único caro, e é o que salva a narrativa**
>
> Mil sementes, cada uma a correr só o gerador de mundo e a atribuição de diários — sem simulação, sem cenas. Corre em segundos e é a única maneira honesta de afirmar "uma partida vê sempre os doze". Uma combinação improvável de capítulos que deixe o Ato II sem fragmentos é o género de coisa que ninguém descobre em playtest e que um jogador descobre na semana de lançamento.

## Seis linhas novas para o registo de risco da §37

| Risco | Prob. | Impacto | Sinal de alarme | Mitigação |
| --- | --- | --- | --- | --- |
| A §77 come o calendário — 106 h num só item | Alta | Grande | Mais de três capítulos por acabar no fim da Fase 5 | Quatro é o mínimo viável. A Q-043 já prevê que só seis apareçam por campanha; com quatro, aparecem quatro e ninguém nota. |
| O Amargueiro vira economia em vez de dilema | Média | Grande | Telemetria: tropas a morrer fora do muro sem combate; amargueiro_decision com 90% em "cortar" | As três regras da §74 e os testes D-02 e D-03. Se o sinal aparecer na mesma, o rendimento por escala desce antes de qualquer outra coisa. |
| A Oferta degenera em "aceitar sempre" ou "recusar sempre" | Média | Grande | Mais de 85% das respostas na mesma direção, ao longo de uma campanha | O teto da recusa (§75) já impede o segundo caso. Para o primeiro, o preço das ofertas sobe com a Dívida e as caras só aparecem depois dos três. |
| A noite castanha esconde a mancha | Média | Médio | Playtesters a serem apanhados de surpresa pela Podridão em campo aberto | O teste das "duas frias" (§80) e a regra de que o violeta é a única cor fria saturada da noite. Se falhar, sobe-se o valor da mancha e não o do ambiente. |
| A cara na casca lê-se como bug | Baixa | Médio | Alguém pergunta "porque é que aquela árvore tem cara?" antes do minuto treze | O Amargueiro velho do minuto 0:00 (§83) existe precisamente para que a pergunta chegue depois da resposta. |
| A raiz portuguesa lê-se como folclore turístico | Média | Médio | Um habitante a explicar a tradição que representa | A regra 2 da §77: o habitante cumpre a lei e nunca a justifica. Uma linha de diálogo que comece por "aqui é costume" corta-se. |


## O estado novo, e porque é que ele passa na Q-036

A ADR 0007 fechou o save em FileAccess.store_var e get_var(false): só tipos base, nada de Resource, nada de caminhos que o motor possa carregar. Tudo o que estes nove sistemas guardam cabe nessa regra sem exceção, e cabe em cerca de dois quilobytes.

| Campo | Tipo base | O que é |
| --- | --- | --- |
| debt_lantern | int | 0–20. Nunca desce. |
| refusals_by_day | PackedInt32Array | Os últimos cinco dias. Janela deslizante. |
| amargueiro_x · _band · _tier · _day | 4 × PackedFloat32Array / PackedInt32Array | Arrays paralelos, um índice por árvore. Sem objetos. |
| amargueiro_title | PackedStringArray | Vazio quando anónimo. É o que põe a cara certa na casca. |
| titles_holder · titles_ordinal · titles_mourning | 3 × Dictionary de String → int | Quem tem, quantos já tiveram, até quando está de luto. |
| colheita_people · colheita_days · colheita_queue | String · int · PackedStringArray | Uma de cada vez, e a fila (§78). |
| peoples_released · peoples_kept | 2 × PackedStringArray | As seis decisões. É o epílogo. |
| chapters_placed · chapter_visits · journals_found | PackedStringArray · Dictionary · PackedStringArray | As visitas contam para a Casa Que Conta e para a Ponte. |


> **A única coisa desta parte que não tem rede**
>
> Todos os sistemas acima têm um teste, um teto, um sinal de alarme e um plano B. Um não tem: a escrita. Doze diários de setenta palavras, doze frases de oferta de oito, nove títulos e dez leis de capítulo. Se esse texto for morno, nenhum destes sistemas salva a Parte XIII — e não há teste automático que apanhe prosa morna. O único controlo possível é o espécime da §79: se um fragmento novo não aguentar a comparação com o diário 9, reescreve-se. É trabalho de uma tarde por ato, e é o que decide se isto foi uma boa ideia.
