# Playtest de A Última Carroça

**Estado:** protocolo preparado; nenhuma sessão humana realizada por esta alteração.
Usar 5–8 pessoas que conheçam Kingdom, uma sessão nova de cerca de 30 minutos por pessoa, acompanhando exploração, fundação e a primeira noite.
Não produzir arte final da abertura antes desse ensaio, conforme o relatório.

## Sessão

1. Anotar versão, dispositivo e idioma; começar novo jogo e escolher um monarca.
2. Deixar jogar sem explicar fundação, moedas, ameaça ou tarefas. Observar tentativas
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
| foundation_choice_committed | confirmação de coordenada válida | 16–20 min típicos; sem prazo obrigatório |
| foundation_choice_id | coordenada livre + assinatura | comparar vantagens e limitações, sem duas opções fixas |
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

Os tempos do relógio diário e da sessão diferem antes de confirmar a fundação. O JSON
usa o segundo de sessão e guarda semente, posição, assinatura e eventos. Não contém nome, IP ou
envio remoto. Metas são hipóteses; não representam resultado aprovado ou já medido.

## Decisão depois das sessões

Comparar caminho observado, primeira escolha e razão relatada. Se ainda for «comprar
arco porque o jogo mandou», rever tarefas, consequências e legibilidade antes de arte.
Se ninguém usar renda alternativa/resgate, não concluir que há três estratégias só
porque três comandos existem. Rever textos, exposição do recurso e acessibilidade.
Guardar os resultados com a versão; afinar os parâmetros em `arrival.csv` e regenerar
recursos. O protocolo não autoriza contato ou envio de mensagens em nome do dono.

## Validação histórica da ADR 0065

A revisão `2c29b50026eb97795c28d35ccf3b58a4bf1e18ee` passou todos os jobs da
[CI 37206947318](https://github.com/henriquecoding/empire/actions/runs/37206947318):
suíte completa, dados, portões estáticos, camada de uso do dossiê, site, silhueta
noturna e exportações Linux/Windows/Web. As contagens reais e a duração estão em
`docs/recovery/validation.json`, no campo `last_cart_verification`.

O fluxo no navegador confirmou movimento por teclado, fundação gratuita no bosque,
contratação de habitante, renda por coleta, resgate com retorno físico das provisões,
pagamento das sete moedas e chegada do mesmo habitante ao posto de companheiro.
O JSON baixado pela pausa registra esses eventos, sem erros de JavaScript. A captura
gráfica usa OpenGL com Mesa
llvmpipe. A vistoria terminou com derrota do piloto no quarto dia, sem quebra de
invariantes; isso não demonstra equilíbrio nem sobrevivência durante oito dias.

Essas verificações demonstram funcionamento técnico. Compreensão da decisão,
motivo da fundação e semelhança percebida com Kingdom aguardam as sessões acima.

## Migração de 05/10 — ADR 0066

A caravana segue; a fundação é livre e gratuita, parado e sem interação prioritária. O grupo fundador sem ofício passa ao reino. Verificar flora removida dentro do footprint e conservada fora, entradas protegidas, reload sem limpeza adicional e o guia nos quatro dispositivos. A assinatura mínima não prova clima, arquitetura adaptada nem consequências ambientais completas. O mundo social dormente, Coop/PvP e rede continuam por fazer. Os resultados históricos acima não validam automaticamente esta revisão.
