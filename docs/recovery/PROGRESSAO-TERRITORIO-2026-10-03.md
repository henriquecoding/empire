# Progressão do território e recrutamento — 03/10/2026

## Diagnóstico da main

Auditado sobre `2b50e2f` (PR #78), após a implementação da ADR 0059.
A fundação e os estágios da sede funcionavam; faltava aplicar a progressão à composição
do mundo. `BuildView` desenhava todos os sítios vazios, incluindo silhuetas do último nível
de muralha. O destino da moeda aceitava sítios futuros. Tipos fora de `unlocks` abriam por
omissão. O pacote inicial contrariava o recrutamento pedido: trabalhadores próprios,
construtor gratuito e combatentes prontos fora de acampamentos.

## Pesquisa de Kingdom

**Fonte primária — atualização 2.0, developer blog #8.** A equipa descreve a revisão da
geração de muralhas, torres e fazendas, a redução de sobreposições, a distribuição dos
construtores e a posição de arqueiros nas frentes. Isso sustenta três critérios de projeto:
espaço legível, construção com função territorial e defesa que acompanha a expansão.

- [Publicação oficial no feed de Kingdom Two Crowns](https://store.steampowered.com/news/posts/?appids=701160&enddate=1729169450&feed=steam_community_announcements).

**Fonte primária — entrevista com Thomas van den Berg, cocriador de Kingdom.** O autor
discute descoberta e a dificuldade de tornar causa e efeito reconhecíveis pela apresentação.
Aplicação em Empire: não expor uma cidade fantasma inteira nem apresentar um convite que
rejeita moedas sem uma razão reconhecível; comunicar o próximo estágio na sede e os ofícios
nas ferramentas, antes de gastar.

- [Entrevista de 25/11/2015](https://wolfsgamingblog.com/2015/11/25/qa-with-thomas-van-den-berg-co-developer-of-kingdom/).

**Fonte secundária — documentação comunitária das regras de jogo.** As páginas Town center,
Archer, Tools and weapons, Building space, Farmer, Knight e Vagrant camp descrevem dois
vagabundos junto do ponto inicial, recrutamento antes do equipamento, ferramentas básicas
na fundação e serviços mais avançados dependentes de sede e espaço defendido. Usadas como
referência de funcionamento, não como especificação técnica ou promessa dos desenvolvedores.

- [Town center](https://kingdomthegame.fandom.com/wiki/Town_center)
- [Tools and weapons](https://kingdomthegame.fandom.com/wiki/Tools_and_weapons)
- [Building space](https://kingdomthegame.fandom.com/wiki/Building_space)
- [Vagrant camp](https://kingdomthegame.fandom.com/wiki/Vagrant_camp)

## Regra aplicada a Empire

| Sede | Convites coerentes | Território e apoio |
|---|---|---|
| Clareira | Marco para fundar; dois vagabundos próximos | Nenhum serviço pronto; demais pessoas em acampamentos |
| Acampamento | Bancas de arco e martelo; primeiro canteiro por flanco; primeira estacaria | Ferramentas exigem recrutado; canteiros adicionais exigem proteção; muralhas em sequência |
| Povoado | Casa de Treino, galinheiro, pesqueiro, torres e cidadãos | Serviços dentro da frente própria; torres podem preparar a próxima frente |
| Vila | Cozinha, celeiro, forja, reservas, montaria, herdeiro e santuário | Palicada para serviços maiores; alimento para cozinha; canteiro para celeiro; treino para forja |
| Vila Fortificada | Embaixada, serraria, gado, minério, farol e fosso | Treino para embaixada; madeira para serraria; apoio defensivo avançado acompanha a frente |
| Fortaleza | Fundição, altar consagrado e Bastião | Minério para fundição; santuário para altar; descobertas, conquistas, Lenho e unicidade continuam exigidos |

O estágio é necessário, mas não suficiente. A posição inteira deve caber no território,
o apoio deve estar de pé e a descoberta pode continuar a faltar. Uma muralha destruída não
apaga casas construídas: interrompe a disponibilidade de novas obras dependentes daquela
proteção. Comunidades e infraestrutura estrangeiras conservam o seu próprio contrato.

O primeiro ciclo é: fundar → recrutar → comprar arco → caçar → recrutar o segundo vagabundo
→ comprar martelo → construir renda e defesa → ampliar a sede → expandir cada flanco.
As 6 moedas iniciais e 8 da carroça continuam a financiar as escolhas; ferramentas e pessoas
são pagamentos separados. O martelo custa 3 como proposta de abertura e forma um único
construtor vivo; os seguintes exigem a Casa de Treino. Não se entrega o trabalhador pronto.

## Arqueiros e preservação

A folha temporária tinha corpo de 36 px em frames de 66×45, tornando a tropa pequena mesmo
com a escala de gameplay correta. A exportação agora deriva a base de `units.csv`: corpo de
64 px, base 64×64, canvas comum de todas as animações e pés fixos. Arco, projétil e poses de
morte podem ultrapassar a base sem serem cortados. O arqueiro jogável conserva o corpo de
72 px e o monarca continua maior. A fonte CC0 e os originais de Henrique não foram alterados.

Os sítios existentes mantêm ids e posições. Os três sítios suplementares são acrescentados
ao final; o save mantém unidades contratadas e obras pagas, em curso, de pé ou em ruína.
Moedas largadas em sítio ainda invisível ficam sem destino de construção, mesmo depois de
o convite abrir. O estado novo não respawna vagabundos ao carregar a partida.

## Verificação

O teste inicial foi executado antes da alteração e falhou pelo excesso de gente própria.
As verificações de conclusão e os resultados do CI ficam no PR desta tarefa. A suite cobre
visibilidade, cada flanco, largura completa, defesas válidas, produção de apoio, moeda sem
destino, reposição do primeiro construtor, save e escala do corpo. A abertura natural é
verificada com intenções de movimento e moedas, sem elevar saldo ou gerar servos de teste.

Os novos parâmetros são propostas de balanceamento, não resultados de telemetria de jogadores.
Vistoria automática mede coerência da simulação; não prova equilíbrio nem diversão de uma
campanha inteira. A Capital e a extensão futura da cadeia tecnológica continuam no roteiro.
