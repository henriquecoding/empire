# 25 — Onboarding · ADR 0066 · A Última Carroça: os primeiros quinze minutos

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

A chegada ensina território, pessoas e consequência. O monarca tem controlo depois da escolha do perfil; três cidadãos sem ofício acompanham a caravana móvel, sem construtor nem companhia pronta. Na fundação, o grupo passa a pertencer ao reino; recém-chegados continuam recrutáveis por moeda. Uma árvore amarga aparece no primeiro ecrã. A primeira decisão é onde criar raízes.

| Momento | Transformação | Escolha real |
| --- | --- | --- |
| Chegada | Carroça e cidadãos seguem o monarca; regiões interessantes orientam sem restringir | Comparar recursos, bioma, água, perigo e acesso; qualquer coordenada territorialmente válida pode ser escolhida |
| Fundação livre | Parado, sem outra interação prioritária: “Fundar o Império aqui?”. O Verbo 2 confirma sem moeda e a autoridade revalida | A sede nasce no local escolhido, dentro da janela da região de casa onde a noite e os recintos fazem sentido (Q-237); limpa flora e árvores sem loot e preserva entradas e segredos. Trabalho presente ergue o Acampamento |
| Reserva | A carroça ancora e abre: parte das oito moedas continua em provisões expostas | Contratar, formar um ofício ou reservar uma pessoa para resgate, coleta e reconhecimento |
| Trabalho | A mesma pessoa caminha e trabalha num único sítio; coleta produz moeda física limitada por dia | Trocar a tarefa interrompe a anterior. Ninguém constrói e coleta simultaneamente |
| Tarde | A Podridão escurece e suspende a coleta exposta antes da primeira criatura | Resgatar, levantar uma defesa ou preparar luz; inspecionar o perigo regista percepção, sem inferir que o jogador o viu |
| Noite 1 | A ameaça vem de oeste e alcança a zona das provisões | Luz e muralha protegem; recurso exposto pode perder-se. A sede não é o único objetivo |
| Amanhecer | Bandeira consolidada ou solo amargo persistente; construtores caminham para reparar a sede | Consolidar o Povoado exige primeira noite, rendimento e frentes defendidas além das moedas |
| Subsolo | Passagens e alçapão revelam salas delimitadas; o baú do jogador começa vazio | Guardar riqueza com risco de roubo; pagar ao construtor para escavar uma sala por estágio |
| Companhia | O posto aparece após a fundação; uma pessoa contratada transforma-se por sete moedas | Monarca e companhia evoluem vencendo batalhas próximos; nenhum novo corpo nasce de graça |


A escada Clareira → Acampamento → Povoado → Vila → Vila Fortificada → Fortaleza permanece. A casa do herdeiro abre na Fortaleza; a Capital continua posterior, quando houver uma rede a administrar (Q-222, Q-226). Os castelos antigos continuam Fortalezas (Q-225). O custo histórico de fundação permanece nos dados para compatibilidade; numa partida nova a confirmação territorial inicia o Acampamento gratuitamente. Estrada e Bosque são apenas formatos históricos de saves antigos.

> **Provas do protótipo, sem prometer tempos medidos**
>
> Medir first_input, first_landmark_inspected, foundation_choice_committed, first_worker_assignment, first_coin_spent, rot_first_noticed, pre_night_strategy, night_one_survived, night_one_loss_type e underground_discovered. Os registos ficam locais e podem ser exportados na pausa; não há envio externo. Metas e protocolo estão em docs/qa/ultima-carroca-playtest.md. A especificação completa e o estado de execução estão em docs/reports/EMPIRE-MASTER.md; a assinatura mínima não substitui o modelo climático futuro. Antes disso, os desenhos continuam provisórios.

> **Autoria e valores reversíveis**
>
> O relatório mestre fornecido tem preferência sobre respostas antigas incompatíveis. As regiões garantidas pelo gerador são oportunidades, não os únicos locais autorizados para fundar. Tempos de trabalho, coleta, defesa e escavação vivem em CSV. Q-230 a Q-233 foram aprovadas em 05/10; novos limiares de paragem e limpeza permanecem propostas identificadas. As três outras aberturas do relatório são alternativas mutuamente exclusivas, não fases adicionais desta partida.
