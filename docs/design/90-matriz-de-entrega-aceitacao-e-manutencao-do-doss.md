# 90 — Execução e qualidade · Matriz de entrega, aceitação e manutenção do dossiê

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Base final reconciliada: main/f3efeac18b5732e68bad3154a0af340f9279d649 também inclui o PR #94 (Atlas, ficha do sítio e diagnóstico territorial). A ADR 0078 e Q-253–Q-257 desse trabalho mantêm identidade; a consolidação usa ADR 0079 e a proposta regional Q-258. Não se atribui esta implementação à revisão documental.

Atualização do mapa: o RG-28/ADR 0077 já implementa parte do território. A matriz A01–A12, os rascunhos AUD-CIV-01–18 e todos os critérios T01–T50 estão na §96. A ordem territorial pormenorizada complementa a sequência geral abaixo, sem declarar portos ou contratos entregues.

## Baseline e limites da verificação

A consulta inicial de 06/10 usou main/bafeb112aa6b9b7162d78fe3053da62c9d6c47ec. Na continuação de 07/10, o PR #92 já estava integrado: esta revisão foi reconciliada com main/ba743da3a616d27a7df581646e9e7356134c89c8, identificado pela Vercel como produção READY no deployment dpl_EJAScE19R3k3Tir47hhRgiQrCVRJ. Arte, HUD, tocha e correções desse PR fazem parte da base recebida, não são implementações desta alteração documental. Na verificação final, o ramo predefinido já é main. O PR #93/RG-28 avançou a baseline para 5b4b24a, com o primeiro protótipo territorial; ver §§92–96 para a comparação com o relatório.

Supabase forneceu as respostas atuais de empire_respostas. A leitura excluiu identificadores de contas administrativas. Não foram alteradas respostas, RLS, schema ou dados de partidas. A imagem anexada orientou a localização do painel; os números da imagem são um instante e não substituem a consulta atual ou o filtro do painel.

A auditoria mestre de 06/10 é uma fonte histórica de defeitos e limitações, não um teste repetido nesta revisão. O estado de cada correção deve ser validado no SHA que a entrega. Uma tabela de design atualizada não resolve, por si, um defeito de gravação ou combate.

## Mapa de execução

| Área | Contrato integrado | Evidência existente / trabalho restante |
| --- | --- | --- |
| Fundação livre | §§10, 25, 88 | ADR 0066/0070, RG-23; completar assinatura e clima em RG-24 |
| Sede, território e trabalhadores | §§09–10 | ADR 0060/0063–0065; progressão posterior, postos e rede em RG-09–RG-15 |
| Floresta e influência local | §§21, 87 | ADR 0070/0073, RG-26; mais afinidades/regeneração não estão concluídas |
| Cave, dungeons e reserva | §§11, 88 | ADR 0072, RG-27; Q-237/Q-244/Q-245 delimitam sobreposição e detalhes |
| Monarcas iniciais e combate | §08 | ADR 0052/0053, Q-198–Q-201; roster/encontros completos dependem de UN-16 |
| Sucessão escolhida | §§15–16, 89 | Q-196/Q-197/Q-202; UN-32 por fazer |
| Quarto imperador | §08 | Q-205; UN-33 por fazer |
| Diplomata universal | §§14, 88 | Q-203; UN-18–UN-21 por completar |
| Mundo social e clima | §§04, 21, 88 | ADR 0069; RG-24 por fazer |
| Abertura e noite | §§05, 25, 74, 89 | RG-06 e ADR 0071; reconciliar Q-240/Q-242/Q-243 sem mudar dados nesta revisão |
| Coop/PvP e autoridade | §§18, 89 | ADR 0067/0068; RG-25, UN-29–UN-31 e Q-236 |
| HUD/plataformas | §§24, 26 | Q-187/Q-188 e ADR 0074; hardware real continua gate próprio |
| Gravações/progressão/painel | §§62, 89 | Correções do PR #92 integradas na baseline publicada; critérios de integridade continuam aplicáveis |
| Afinidade regional nova | §87 | Q-258: proposta delimitada, sem multiplicadores aplicados |


## Ordem de implementação

1. Integridade do ciclo existente: preservar e validar as correções de gravação/retoma, evolução real em batalha e consistência da floresta recebidas do PR #92; publicação com identidade verificável.
1. Abertura coerente: bancas e formação, curva inicial, local da ameaça, conflitos de subsolo e informação de consequências. Medir RG-06 com a sede atual.
1. Território legível: influência local consistente, escolhas de cobertura, alternativas sazonais e assinatura com proveniência. Só depois acrescentar uma afinidade nova medida.
1. Continuidade de campanha: herdeiro neutro e troca, roster, ritual, diplomata e perdas. Evitar multiplicar conteúdo antes de fechar os estados de transição.
1. Sociedades e escala: despertar, mercenários móveis, simulação distante, postos, rotas e Capital, com migração de mundos antigos.
1. Online: fechar regras competitivas, autoridade e transporte; testar dois clientes reais, reconexão e isolamento antes de anunciar o modo.

Esta ordem não transforma relatórios de pesquisa em implementação automática. Cada ticket deve citar a secção atual, a resposta/ADR, os parâmetros aprovados e os que ainda são hipótese.

## Matriz de aceitação do produto

| ID | Cenário | Resultado exigido |
| --- | --- | --- |
| DOC-01 | Regenerar docs/design/ | Mesmo conteúdo e índice; nenhuma edição manual divergente |
| DOC-02 | Reconciliar respostas consultadas | Cada ID consta do registo, sem duplicados; adiamentos e respostas parciais conservados |
| FUN-01 | Explorar dois biomas antes de fundar | Mesma caravana, riqueza e campanha; nenhuma profissão gratuita |
| FUN-02 | Confirmar duas vezes / carregar depois | Uma fundação, uma limpeza, sem duplicar pessoas, provisões ou prémios |
| FUN-03 | Fundar perto de conteúdo protegido | Apenas o footprint necessário é impeditivo; vizinhança preservada e explicada |
| TER-01 | Cortar a árvore que satisfaz um limiar | Preview e resultado concordam; destinatários corretos; cap respeitado |
| TER-02 | Gerar segmento depois de construir e repetir após load | Chão reservado idêntico; árvores não atravessam obras |
| ECO-01 | Inverno num bioma sazonal | Estratégia preparada viável com deslocações/trabalho reais |
| ECO-02 | Falta trabalhador, matéria ou percurso | Interrupção causal e explicada; não produção fantasma |
| SUB-01 | Qualquer entrada acessível | Chegada, folga, baía e margens utilizáveis; regresso possível |
| SUB-02 | Baú/tesouro visitado outra vez | Sem reposição, reroll ou dupla apropriação da riqueza |
| MON-01 | Trocar sem/com herdeiro pronto | Recusa justificada / transferência única e reinício do treino |
| MON-02 | Incumprir manutenção e recomeçar treino | Não recupera gratuitamente herdeiro anterior |
| MON-03 | Morte e ritual | Disponibilidade da campanha e desbloqueio persistente respeitam estados distintos |
| NOC-01 | Noites iniciais em trajetórias diversas | Espécies e pressão compatíveis com meios reais; registar curvas por seed/perfil |
| SOC-01 | Mundo novo antes do gatilho social | Sem sociedades organizadas ativas; ruínas e sobreviventes permitidos |
| SOC-02 | Perto, longe e reconexão | Reservas, perdas, estágio e relações mantêm causalidade |
| NET-01 | Dois jogadores gastam o último recurso | Uma transação aceite; rejeição explicada; sem saldo negativo |
| NET-02 | P2 tenta fundar Coop / outro reino tenta comandar | Autoridade valida e rejeita sem efeito colateral |
| NET-03 | Desligar/reconectar | Mesmo slot/reino, sem duplicação; sessão não depende do browser de P1 |
| UX-01 | Teclado, comando e toque | Mesmas ações e informação essencial, com alvos/foco/texto utilizáveis |
| SAV-01 | Escrita incompleta e retoma corrompida | Preservar save válido; recuperação não anula derrota legítima |


Os casos acima são critérios de aceitação, não uma declaração de que foram todos executados. A evidência da revisão documental, build e CI fica no PR desta entrega. Testes reais de jogo, hardware e rede exigem os ambientes correspondentes.

## Como impedir nova divergência

Ao receber uma resposta, registar fonte, âmbito e texto; comparar com a proposta identificável; atualizar a regra temática; apontar a substituição na ADR/pergunta; modificar dados e código apenas se a tarefa incluir implementação; regenerar as secções; verificar referências e valores; publicar pelo fluxo do repositório. Só depois de implementação verificada se considera atualizar “aplicada” no painel, preservando resposta entretanto editada.

Uma alteração documental pode ficar concluída enquanto um requisito de jogo continua por fazer. Por isso, o estado de documentação e o de implementação devem ser descritos separadamente. O histórico desta consolidação está na ADR 0079 e no registo da §91; as ADRs anteriores não são apagadas para fingir que as decisões sempre foram iguais.
