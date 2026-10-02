# ADR 0044 — Três classes na primeira escolha

- **Estado:** substituída pela ADR 0052 (02/10/2026) na escolha inicial e no controlo de corpos de classe. A marca,
  a perfuração, o canto, a conversão e a promoção continuam — passam a servir o Imperador Arqueiro e o Bardo da Nia.
- **Contexto:** o dono pediu três escolhas iniciais com a jogabilidade já descrita no §08 e pesquisa na web. Existiam corpos assumíveis, mas não uma escolha de início nem as habilidades completas de Arqueiro e Bardo.

## Decisão

As três escolhas são Monarca, Arqueiro e Bardo. A seleção pausa o tempo, explica papéis, evolução e controlos, e exige confirmação. Arqueiro e Bardo recebem um corpo próprio junto do monarca. O rei permanece, conserva a gestão e pode voltar a ser assumido pelo Verbo 2. A seleção só aparece numa partida nova; saves anteriores continuam normalmente.

`Roster` guarda a escolha inicial. `HeroProgress` guarda feitos e fases de Arqueiro e Bardo por campanha; o Monarca conserva o `ClassSystem` existente. `ArcherFocus` guarda marcas por dono e prazo. `BardSong` guarda dono, autor, prazo e permanência da conversão, bem como as criaturas distintas já contadas para o feito. As regras são puras em `src/sim/`; `HeroWatch` liga-as aos verbos, combate e eventos já catalogados.

Marcas orientam todas as tropas do mesmo dono que conseguem atingir o alvo. A fase dois do Arqueiro aplica o dano de um único tiro aos inimigos da coluna à frente, com uma só precisão, cadência e consumo de munição. As classes jogáveis conservam recursos de combate ilimitados (Q-163).

Criaturas encantadas combatem inimigos da mesma faixa e acompanham o Bardo enquanto estiverem nela. Tropas não as alvejam. Podem defender a linha à frente da muralha e receber ataques da Podridão. Luzes próprias e roubo de galinhas não se aplicam a elas. Conversões permanentes são preservadas quando as criaturas da noite se dissolvem.

Maestro usa o mesmo gesto de cantar para promover uma tropa própria; o cursor distingue tropa de inimigo. A promoção lê os destinos do CSV, mantém a proporção de vida e deixa a unidade sem posto para ser redistribuída. Não gasta moedas nem cura por mudar o corpo. O intervalo é o do corpo do Bardo. Evolução de Arqueiro e Bardo é pelo Verbo 2 no núcleo, com feito e Semente Real.

## Dados e compatibilidade

`FieldWork.parts()` inclui progresso, foco e canto. Campos ausentes entram vazios; a escolha ausente num save antigo entra como Monarca e não abre a seleção. Não há mudança de esquema no Supabase: este estado pertence ao save do jogo. Dossiê e decisões aprovadas no painel foram consultados, sem alterar respostas do dono.

Os números de trabalho preexistentes permanecem em `_proposed`: duração da marca 10 s, raio da marca evoluída 96 px, feito do Arqueiro 30 abates marcados; encanto 30 s, limite de vida base 14, velocidade +10%; feito do Monarca 5 noites. As 15 conversões do Bardo e o custo de uma Semente são do §08. Destinos de promoção `archer → canopy_archer` e `spearman → mercenary` são uma nova proposta reversível em Q-183; usam os recursos e estatísticas existentes.

## Apresentação e investigação

Cartões com retratos do jogo, seleção visível, foco inicial, rolagem com foco e botão de confirmação fixo. Os valores das descrições são lidos do CSV. Inimigos marcados recebem um triângulo dourado; aliados temporários e permanentes recebem um sinal distinto. Bardo recebe um alaúde desenhado na apresentação, sem editar os assets protegidos.

A documentação oficial do Godot sobre foco e `ScrollContainer`, o princípio de entrada consistente das Game Accessibility Guidelines e a página oficial de Kingdom Two Crowns informaram a interface. Links e aplicação concreta em `docs/backlog/CLASSES-01.md`. Nenhuma dessas referências substitui a mecânica do dossiê.

## Verificação

Testes escritos antes da implementação para o arranque e testes de integração para combate, evolução, promoção e saves. Suite, portões, dados, vistoria e export Web são obrigatórios antes do merge. A escolha também é revista visualmente em desktop e tela compacta.
