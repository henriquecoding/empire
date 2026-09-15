# 40 — Invariantes · As oito regras que nunca se quebram

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Cada uma existe porque violá-la custa uma reescrita, não uma correção. Cada uma tem um teste automático que a defende (§64). Se um agente propuser código que quebre qualquer uma delas, o CI trava o commit antes de tu leres uma linha.

| # | Invariante | Porquê | Guarda |
| --- | --- | --- | --- |
| I1 | src/sim/ é lógica pura. Nada lá dentro estende Node, chama get_tree(), toca em Engine, ou carrega cenas. | É o que torna a simulação testável em milissegundos e o save trivial. Também é o que permite correr uma noite inteira em headless para os testes de design. | test_sim_nao_toca_em_nos |
| I2 | Tudo o que é aleatório passa por um fluxo nomeado de RngService. Nunca randi() global. | Sem isto não há seed reproduzível, não há bugs reproduzíveis, e o save deixa de conseguir retomar uma noite a meio. | Lint de randi\\|randf\\|randomize |
| I3 | Toda a entidade tem band: Band.Kind desde a criação, e as colisões usam camadas separadas por faixa. | O §11 chama-lhe a decisão arquitetónica mais importante. Acrescentar isto no dia 200 é reescrever o jogo. | test_toda_entidade_tem_faixa |
| I4 | Números de balanceamento vivem em .tres, nunca em código. | Balancear passa a ser editar tabelas. E permite gerar os .tres de um CSV, que é o que resolve a base de dados de conteúdo (§44). | test_sem_literais_de_balanceamento |
| I5 | A simulação corre a passo fixo de 30 Hz, desacoplada do render. | Determinismo e desempenho com 300 unidades. O render interpola; a simulação não. | test_tick_fixo |
| I6 | Nunca load() nem ResourceLoader.load num ficheiro de save. Usa FileAccess.get_var(false), apenas tipos base, com validação campo a campo (ADR 0007). | Um .tres arbitrário pode conter script embutido. É execução remota de código disfarçada de save. | Lint + revisão obrigatória |
| I7 | A comunicação entre sistemas é por evento nomeado do catálogo do §46. Sistemas não se chamam uns aos outros diretamente. | É o que permite a um agente mexer num sistema sem partir os outros, e a ti perceberes o que aconteceu lendo um registo de eventos. | test_eventos_no_catalogo |
| I8 | O parallax move-se em pixels inteiros. Cada camada faz floor() antes de aplicar a posição. | Meio pixel de deslocamento destrói a grelha de autoria, que é a regra de ouro do §01. | test_parallax_inteiro |


> **A que se quebra primeiro**
>
> É sempre a I2. Um randf() solto para escolher uma variante de sprite parece inofensivo — e é, até ao dia em que precisas de reproduzir a noite 14 de um bug report e não consegues. Aleatoriedade puramente cosmética também vai a um fluxo: o fluxo visual, que existe exatamente para isso e nunca afeta a simulação.
