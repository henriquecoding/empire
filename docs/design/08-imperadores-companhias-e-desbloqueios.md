# 08 — Monarcas · Imperadores, companhias e desbloqueios

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Só os imperadores são controláveis. Cada perfil reúne identidade, combate, autoridade soberana e companhia própria; tropas, ofícios, diplomatas e companheiros atuam sob IA. As antigas classes controláveis e a troca livre entre dois corpos vivos foram substituídas pelas Q-195–Q-202. Os identificadores técnicos de classe que ainda existem no código são mecanismos internos, não opções adicionais de personagem para o jogador.

## Escolha inicial e identidade

Uma campanha nova apresenta os três perfis iniciais completos. Confirmar a escolha inicia a partida. Explorar permite descobrir outros imperadores e desbloqueá-los para a campanha e para novos começos, conforme as regras de legado da §16. Desbloquear um perfil não concede outra coroa nem troca imediatamente quem governa.

| Imperador | Estilo e fragilidade | Companhia e economia | Evolução |
| --- | --- | --- | --- |
| Rei guerreiro defensivo | Corpo grande e lento, golpe curto; protege pela presença, mas pode morrer | Escudeiro pago protege com escudo e progride para combate | Defesa e companhia crescem por feitos de batalha |
| Imperatriz Nia | Rápida, de golpe curto e cadência alta; precisa de se expor para atacar | Bardo da bandeira recebe ordens pagas para encantar e incentivar; Nia não o substitui | Maestro amplia conversão e promoção conforme os dados aprovados |
| Imperador Arqueiro | Ataque distante, marca e sangramento exclusivo; depende de munição | Uma moeda compra seis flechas. Escudeiro evoluído também dispara e usa a aljava paga no protótipo | Marca em área e flecha perfurante; efeitos do escudeiro têm afinação própria |
| Quarto imperador, desbloqueável futuro | Grande, armadura completa, aparência obscura e passado triste; recupera vida sentado e faz nascer vegetação | Escudeira dança e aumenta a força dele e das tropas; evoluída abranda inimigos | Conceito decidido na Q-205; nome final, valores e implementação continuam em UN-33 |


Não há quarto perfil inicial incompleto. O antigo conceito do Cavaleiro Enterrado deve ser reconciliado com este quarto imperador em UN-33; esta revisão não autoriza criar uma personagem jogável redundante. O Cavaleiro Selado permanece conteúdo de tropa sob IA, com o vínculo à montaria descrito nos dados de conteúdo.

## A companhia é contratada, não oferecida

A caravana inicial tem três cidadãos sem ofício. Depois de fundar, o posto próximo da sede permite formar a companhia correspondente ao monarca por sete moedas; a formação usa uma pessoa disponível. Os fundadores já pertencem ao grupo e passam ao reino na fundação; recém-chegados são recrutados pelo gesto da moeda antes de receber ofício. Fontes: Q-223, ADR 0066 e arrival.csv.

Monarca e companhia evoluem juntos por feitos de batalha. O parâmetro de cinco vitórias conjuntas foi aprovado no contexto da Q-232 e está em dados; não se recupera a antiga evolução genérica de qualquer corpo jogável por uma moeda no marco. A condição conta mortes inimigas reais, com proximidade/faixa válidas e sem aliados; a correção desse caminho foi integrada pelo PR #92 na base publicada identificada na §90.

Cada perfil mantém vida, ferimentos, experiência, bolsa, flechas, recargas e vínculo de companhia. Trocar, viajar, gravar ou carregar não enche a aljava nem cura. O escudeiro Arqueiro só dispara na sua forma evoluída, com patrono vivo e condições de combate válidas. Os números de ataque e a discussão entre aljava partilhada ou reserva própria continuam na Q-246; a decisão de seis flechas por moeda não os aprova por associação.

## Troca de imperador: a sucessão é a chave

A escolha de outro imperador exige um herdeiro preparado. O jogador desloca-se à Casa do Herdeiro, escolhe um perfil desbloqueado e disponível segundo as regras da campanha, e transfere o governo numa única operação. O ciclo de preparação reinicia; a nova falta de sucessor é um risco real. Não basta encontrar um imperador vivo e premir Interagir. A §15 define preparação, incumprimento e recuperação dos bónus.

Um imperador perdido definitivamente naquela campanha fica indisponível nela, salvo ressurreição válida no prazo do ritual (§16). Os desbloqueios persistentes voltam a permitir escolhê-lo num novo começo conforme Q-195/Q-206. Solo conserva uma única coroa soberana, incluindo durante queda, roubo, troca e sucessão pendente. Coop/PvP têm topologia própria na §18.

## Controlos e funções

Ataque e habilidade são ações independentes: teclado/rato, comando e toque oferecem o mesmo conjunto de ações, com apresentação adaptada. Segurar ataque repete à cadência; segurar CORRER consome fôlego e soltar termina a corrida. Os tempos de fôlego de trinta e cinquenta segundos são decisões da Q-216, implementadas por dados; parado recupera mais depressa (Q-208). Nia ordena o serviço pago do Bardo; marcar não dispara uma flecha. A interface explica disponibilidade, custo e recuperação sem exigir conhecimento do código.

O companheiro do trono, como a mascote que segue alimentação, é conteúdo separado da companhia real e não substitui escudeiro ou Bardo. Trepador, montarias e variantes de povos mantêm-se como conteúdo faseado; nenhum deles reabre classes controláveis antigas.

Aceitação: começar com cada perfil; contratar a companhia; ficar sem moeda/munição; evoluir pela batalha; gravar e retomar; tentar trocar sem herdeiro; trocar com herdeiro; perder o perfil e verificar disponibilidade. O teste deve percorrer o fluxo completo, não apenas alterar diretamente um nível de personagem.
