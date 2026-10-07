# 86 — Consolidação · Decisões, precedência e conflitos resolvidos

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Esta parte fecha a distância entre o dossiê e o projeto que foi decidido. A fonte editável continua a ser docs/dossie.html; docs/design/ é gerado e não se edita à mão. Os relatórios e ADRs guardam pesquisa, motivação e migrações; as regras operacionais devem também aparecer na secção temática do dossiê.

## Precedência por cláusula

| Ordem | Fonte | Como se utiliza |
| --- | --- | --- |
| 1 | Instrução explícita mais recente do dono, com âmbito identificável | Substitui só a cláusula incompatível; não aprova todo o documento por proximidade |
| 2 | Dossiê consolidado e decisões aceites aqui referenciadas | Contrato funcional de desenvolvimento e revisão |
| 3 | ADRs, relatórios adotados e registo da pergunta | Justificação, histórico, exceções e detalhes; divergência descoberta volta a ser reconciliada |
| 4 | CSVs e catálogo de conteúdo | Valores que o executável utiliza; _proposed conserva a natureza provisória |
| 5 | Código, testes e publicação | Evidência do estado entregue, distinta da intenção de design |


A escolha “outra” lê-se pelo seu texto, não como rejeição automática. A escolha “aprovar” aplica-se à proposta apresentada, sem abranger pendências que a própria pergunta separava. “Adiar” não é autorização. Uma pergunta sem resposta não se fecha por inferência. A tabela consultada guarda a resposta mais recente, mas não um histórico completo de revisões da proposta: títulos e contexto são cruzados com o repositório; não se inventa um hash de proposta que o painel não forneceu.

## Conflitos que deixam de coexistir

| Tema | Formulação ultrapassada | Regra que passa a reger | Fonte e execução |
| --- | --- | --- | --- |
| Fundação | Castelo inicial, duas bandeiras ou duas moedas obrigatórias | Caravana móvel; qualquer coordenada válida; fundação gratuita | ADR 0066/0070; fluxo Solo existente |
| Fundadores | Dois trabalhadores, pioneiro e companhia pronta | Três cidadãos sem ofício; ferramentas e companhia pagas | Q-223, Documento Mestre, ADR 0066 |
| Bancas | Disponíveis antes do reino ou fora da proteção inicial | Nascem na fundação, dentro do primeiro traçado; exceção para conseguir formar o construtor | Q-221 atualizada, Q-231 |
| Biomas | Entrar numa região reinicia a partida | Mundo contínuo com identidades e ecossistemas; explorar não repõe recursos iniciais | Q-173/Q-221 |
| Personagens | Classes controláveis independentes | Só imperadores controláveis, três iniciais, outros descobertos | Q-195/Q-197 |
| Troca | Interagir junto de qualquer imperador vivo | Herdeiro preparado, escolha na sua casa, transferência e reinício do ciclo | Q-196/Q-202; UN-32 pendente |
| Casa do Herdeiro | Abre na Vila | Abre na Fortaleza, atual máximo da sede; expansão e apoio continuam necessários | Q-222/Q-233; realm_stages.csv |
| Quarto imperador | Conceito por escolher | Armadura completa, cura sentado, vegetação e escudeira dançante | Q-205; UN-33 pendente |
| Flechas | Doze por moeda ou munição gratuita ao trocar | Seis por moeda; escudeiro evoluído também dispara | Q-200; Q-246 mantém afinação aberta |
| Monarcas perdidos | Outro corpo vivo evita toda a derrota | Sucessor válido para continuar; ritual ou indisponibilidade durante a campanha | Q-196/Q-206 |
| Sociedades | Reinos completos desde o Dia Um | Natureza primeiro; sociedades emergem depois da fundação/noite/alvorada | ADR 0069; RG-24 pendente |
| Expansão | Só pagar o próximo nível | Estágio, território, população/apoio e feitos de maturidade | Q-227/Q-231/Q-233 |
| Pântano | Paul | Bruma como nome de trabalho; preservar migração de IDs | Q-175/ADR 0043 |
| Subsolo fundador | Preservar qualquer cavidade mesmo em conflito | Compatibilizar a cave da sede com o subsolo existente, preservando conteúdo protegido | Q-237; algoritmo/migração por completar |
| Curva noturna | Limite de estreia 3, depois 6, depois 9 tratado como aceite | O dono considerou esse crescimento agressivo; ritmo mais lento exige nova afinação | Q-240 atualizada; valor atual não é aprovação |
| Rampa e primeira funda | Rampa até 5 e primeira funda na noite 6 como destino final | Propostas de rampa 7 e primeira funda 12 receberam aprovação; implementar e medir no âmbito descrito | Q-242/Q-243; CSV atual ainda difere |
| Arte e clima | Escala técnica antiga decide todos os sprites; inverno universal | Base artística 64×64 e clima geralmente quente/agradável, com biomas dinâmicos | Q-235; meteorologia específica ainda por desenhar |
| Coop/PvP | Host-cliente autoritativo ou uma única regra de vitória | Servidor autoritativo, um reino em Coop, dois em PvP e conquista soberana | ADR 0067/0068; rede pendente |


A Q-178 antiga, que mantinha o rei em casa e enviava classes, foi superada quanto a quem o jogador controla pela unificação de monarcas. A possibilidade de delegar expedições, regressar a um refúgio conquistado e manter consequências no reino continua válida. A revisão não restaura classes só para satisfazer uma frase antiga.

## Respostas recentes com efeito parcial

Q-221 decide localização/tempo das bancas e continuidade entre biomas, mas não aprova novas moedas iniciais. Q-235 decide direção climática e base visual, mas não fecha probabilidades de chuva, duração de estações ou o despertar social. Q-237 exige resolver sobreposição subterrânea, mas não autoriza apagar masmorras descobertas ou tesouros sem compensação definida. Q-205 descreve o quarto monarca, mas não aprova automaticamente as restantes propostas que partilhavam essa pergunta.

Q-239 e Q-241 aprovam as regras apresentadas de rampa sobre pressão acumulada e custo/limiar das emboscadas. Q-242/Q-243 autorizam a proposta de curva no contexto indicado; continuam a exigir correspondência em dados/código e medição. Q-240 rejeita a agressividade do escalonamento; uma aprovação vizinha não anula essa objeção. O ajuste final deve satisfazer as três decisões em conjunto.

## Adiamentos e rastreabilidade

Q-081, Q-112, Q-147, Q-191, Q-194 e Q-245 permanecem adiadas na leitura do painel. Alterações posteriores autorizadas noutros pedidos são documentadas separadamente; não reescrevem retroativamente esses votos. As perguntas Q-234, Q-236, Q-244 e Q-246 conservam números ou contratos por fechar. A integração em prosa não marca respostas como aplicadas no Supabase.

A §91 apresenta o mapa editorial das decisões consultadas e liga cada pergunta aos temas correspondentes. O registo público contém apenas sínteses de design e referências. A evidência literal fica num ficheiro separado para o dono do projeto. O indicador remoto “aplicada” nunca substitui a verificação do comportamento nas plataformas.
