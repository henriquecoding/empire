# Playtest de A Última Carroça

**Estado:** protocolo preparado; nenhuma sessão humana realizada por esta alteração.
Usar 5–8 pessoas que conheçam Kingdom, uma sessão nova de 15 minutos por pessoa.
Não produzir arte final da abertura antes desse ensaio, conforme o relatório.

## Sessão

1. Anotar versão, dispositivo e idioma; começar novo jogo e escolher um monarca.
2. Deixar jogar sem explicar bandeira, moedas, ameaça ou tarefas. Observar tentativas
   e anotar confusão com segundo exato. A gravação de tela é opcional e combinada.
3. Na pausa, usar **Exportar dados da abertura** para baixar o JSON local.
4. Perguntar: «qual foi a primeira decisão tua?», «por que esse lugar?», «o que mudou
   antes da noite?», «o que vais fazer diferente?» e «como descreverias o jogo?».
5. Registrar separadamente quando a pessoa mencionou Kingdom e o motivo. Não tratar
   comentário ausente como prova automática de originalidade.

## Métricas e hipóteses

| Evento / campo | Fonte | Hipótese, ainda por medir |
|---|---|---|
| first_input | automático, primeiro movimento ou intenção | <10 s depois do perfil |
| first_landmark_inspected | interação com raízes/carga ou reconhecimento | <45 s |
| foundation_choice_committed | escolha do estandarte | <120 s |
| foundation_choice_id | estrada / bosque | nenhuma >75% sem intenção |
| foundation_reason_posttest | resposta humana | ≥80% explicam o custo espacial |
| first_worker_assignment | ordem contextual | <180 s |
| first_coin_spent | moeda sai da bolsa | 2–5 min; comparar também recrutamento real |
| rot_first_noticed | inspeção de raízes ou interação após contaminação | ≥85% antes da noite; confirmar verbalmente |
| pre_night_strategy | tarefa ativa ao crepúsculo | anotar também luz/muro na observação |
| night_one_survived | primeira alvorada | ≥90–95%; confirmar que monarca sobreviveu |
| night_one_loss_type | mantimentos / nenhuma | distribuição controlada |
| post_night_plan_changed | nova tarefa após alvorada | ≥40%; estratégia de muro/luz exige observação |
| underground_discovered | entrada real | <14–15 min |
| kingdom_similarity_timestamp | observador + resposta humana | mediana nunca / >10 min |

Os tempos do relógio diário e da sessão diferem antes de fincar a bandeira. O JSON
usa o segundo de sessão e guarda semente, escolha e eventos. Não contém nome, IP ou
envio remoto. Metas são hipóteses; não representam resultado aprovado ou já medido.

## Decisão depois das sessões

Comparar caminho observado, primeira escolha e razão relatada. Se ainda for «comprar
arco porque o jogo mandou», rever tarefas, consequências e legibilidade antes de arte.
Se ninguém usar renda alternativa/resgate, não concluir que há três estratégias só
porque três comandos existem. Rever textos, exposição do recurso e acessibilidade.
Guardar os resultados com a versão; afinar os parâmetros em `arrival.csv` e regenerar
recursos. O protocolo não autoriza contato ou envio de mensagens em nome do dono.
