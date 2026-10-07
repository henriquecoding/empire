# 89 — Contratos de campanha · Sucessão, noite e modos de jogo sem contradições

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Esta secção reúne os pontos em que uma regra aparentemente local muda toda a campanha. As secções temáticas mantêm o detalhe; aqui ficam invariantes e fronteiras de implementação.

## Sucessão e continuidade

| Situação | Resultado canónico | O que não deve acontecer |
| --- | --- | --- |
| Herdeiro a treinar | Identidade neutra; custo e manutenção significativos | Já ser outro perfil fixo antes da escolha |
| Manutenção não paga | Herdeiro desaparece; exige novo investimento | Congelar treino para recuperar gratuitamente depois |
| Herdeiro pronto e troca voluntária | Escolha na Casa do Herdeiro; transferência de governo; reinício do ciclo | Segunda coroa ou troca livre fora da casa |
| Novo soberano | Bónus reduzidos recuperados depois de cinco noites | Reset de dívida, riqueza, perdas ou recursos |
| Coroa caída mas recuperável | Estado de queda, com as regras de recuperação | Declarar morte definitiva prematuramente |
| Morte definitiva com continuidade válida | Possibilidade de continuar pelo sucessor e sede de pé | Assumir uma tropa ou companheiro |
| Sem sucessor válido ou sede perdida | Derrota/legado conforme §16 | Recuar para um save anterior para anular a derrota legítima |
| Outro imperador perdido | Ritual válido ou indisponibilidade na campanha | Voltar a escolhê-lo nessa campanha sem satisfazer o ritual |


Custo exato para cumprir “a manutenção mais alta do jogo”, tratamento da companhia na transferência, resgate automático da coroa e perfil de Ganância são pendências próprias. A descrição do quarto imperador na Q-205 não decide essas linhas. O valor antigo de treino não deve ser apresentado como prova de que o novo sistema neutro está concluído.

## A noite tem orçamento e ensino

As primeiras noites devem dar espaço para apreciar a construção e aprender respostas. A Podridão continua autoritativa sobre a massa que gasta; emboscadas no escuro não são um segundo gerador gratuito. O local de invocação respeita o exterior da muralha mais afastada do lado ameaçado. Fissuras e pressão seguem a sede escolhida, não uma antiga origem fixa.

| Decisão | Regra desejada | Estado da baseline consultada |
| --- | --- | --- |
| Q-239 | Aplicar a rampa também às contribuições escritas de dia | Regra existe; aprovação recente incorporada nesta revisão |
| Q-240 | Introdução menos agressiva de espécies, sem infestar a abertura | O protótipo usa debut_step=3; esse ritmo foi contestado e não é declarado definitivo |
| Q-241 | Escuro gasta o orçamento da noite e só cria emboscada a partir da terceira | Regra existe; valores da pergunta aprovados |
| Q-242 | Rampa de sete noites na proposta apresentada, com medição do percurso real | CSV ainda conserva cinco; aplicação/validação por fazer |
| Q-243 | Primeira noite funda na doze; depois periodicidade indicada na proposta | Código atual não tem o novo limiar; implementação por fazer |


A tabela histórica de massa na §74 descreve os CSV atuais. Não é substituída à mão por uma curva que o executável ainda não usa. A próxima alteração deverá atualizar dados, simulação, tabelas, teste do início e condições de oferta em conjunto. Aprovar uma curva não obriga a aceitar uma composição esmagadora: a revisão deve medir quantidade, espécie, faixa atingível, tempo de chegada e meios defensivos obtidos.

Avaliar a abertura por seed, imperador, fundação precoce/tardia, trajetórias de economia/defesa e dispositivo. Mortalidade de um piloto que não melhora as muralhas não prova que todos os jogadores perdem, mas identifica cenários a estudar. A primeira noite não exige matar alguém para ensinar a lore; a §83 apresenta consequências reais.

## Solo, Coop e PvP

| Dimensão | Solo | Coop | PvP |
| --- | --- | --- | --- |
| Soberania | Um reino e uma coroa soberana | Um reino partilhado; papéis humanos próprios | Dois reinos soberanos separados |
| Fundação | Jogador | Só P1/criador; P2 pode sugerir | Cada fundador escolhe no seu lado |
| Economia e obras | Do reino | Partilhadas, com transações ordenadas | Separadas e isoladas |
| Caravana | Segue o jogador | Segue P1 antes de fundar | Uma em cada extremo, Oeste/Este |
| Conhecimento | Da campanha/reino | Partilhado conforme o contrato do modo | Privado por reino |
| Autoridade | Simulação local existente | Servidor dedicado futuro | Servidor dedicado futuro |
| Continuidade | Save local | Sessão e reconexão ao mesmo slot | Sessão, isolamento e reconexão |
| Objetivo | Campanha | Proteger e expandir em conjunto | Conquista/soberania total |


O suporte de mais de dois jogadores em Coop é direção futura, não limite técnico já validado. Captura de sede, prazo de graça, efeitos de desconexão, soberanias NPC relevantes e regra de despertar competitivo continuam na Q-236. A morte de um avatar não equivale automaticamente à conquista de todo o reino.

Duas intenções de gastar a última moeda têm uma ordenação e apenas uma pode ter efeito. Reenviar um comando produz o mesmo resultado identificável, sem nova cobrança. Reconexão recebe estado canónico e restaura jogador/reino, sem nova caravana ou prémio. Guardar só a seed não basta: o manifesto, alterações do mundo e estados sociais fazem parte da persistência.

Vercel distribui o site/export; Supabase observado serve administração, decisões e reportes. Nenhum dos dois é prova de que as partidas já tenham servidor de jogo. A tecnologia/hospedagem online permanece uma escolha pendente da arquitetura aceita, não uma integração instalada por esta revisão.

## Persistência e justiça

Não alterar uma sede antiga, repetir limpeza ou criar reservas na migração. Assinaturas inferidas devem declarar a sua proveniência. Não restaurar árvores ou loot já consumidos. Não descartar o último save válido se uma escrita falhar. Recuperar corrupção é diferente de desfazer derrota ou campanha terminada; as correções da auditoria estão identificadas no PR #92.

Mapas Solo/Coop favorecem descoberta; PvP compara oportunidades de alimento, água, materiais, mobilidade, defesa e risco nos dois extremos. As tolerâncias ainda precisam de aprovação e medição. Simetria visual não substitui essa comparação e diversidade visual não autoriza inícios desiguais.

Pendências da base recebida: Q-247 conserva aberta a possibilidade de a tocha na mão também proteger; atualmente é apenas iluminação. Q-248 conserva aberta outra compensação para árvores de saves antigos removidas por sobreposição com obras; a regra atual limpa o conflito sem reposição nem pagamento. Nenhuma das duas perguntas tem uma resposta remota nesta consulta.
