# Empire — pesquisa e laboratório de mecânicas do site

Data: 19/10/2026. Tarefa: PUB-06. Decisão: ADR 0085.
Âmbito: página de entrada PT/EN — uma secção nova onde se mexe nas regras do jogo e se vê o resultado.

## O pedido

> «Quero que faça uma densa pesquisa na web para implementar melhorias e funcionalidades interessantes no meu site,
> por exemplo, adicionar uma secção que a pessoa pode testar e ver todas as mecânicas que ela desejam, e por aí vai,
> quero que meu site seja criativo.» — o dono, 19/10/2026

## Conclusão

O que torna este site diferente das páginas do género não é mais uma imagem nem mais um efeito: é poder **mexer nas
regras**. O Empire tem o raro privilégio de ter as regras escritas — o dossiê, os CSV e os sistemas puros de
`src/sim/` — e por isso pode mostrá-las a funcionar, com as contas do próprio jogo, sem inventar nada. A página já
tinha um instrumento (a candeia); passa a ter uma bancada com quatro.

## O que a pesquisa diz

| Fonte | O que diz | O que se aplicou | Limite |
|---|---|---|---|
| Bret Victor, *Explorable Explanations* [1] (lida) | Documentos reativos: o leitor muda as premissas e vê a conclusão mudar; o autor tem de revelar o modelo, e quem lê «refuta mudando o modelo». A interatividade serve a explicação, não a substitui. | Cada instrumento tem uma frase que explica, os controlos, o resultado e a origem (o § e o CSV). O modelo está à vista no código e citado na página. | É um ensaio, não um estudo de conversão. |
| Nicky Case, *4 more design patterns* [2] e *Parable of the Polygons* [3] (via pesquisa) | Começar pelo raso e acabar na «caixa de areia», depois de as secções anteriores apresentarem as peças. | A candeia (raso) continua na secção da Podridão; o laboratório (fundo) vem depois dos povos, quando já se sabe o que é a noite, a moeda e o muro. | Padrão de desenho, sem medição. |
| Red Blob Games, *diagram structure* [4] (lida) | Controlos → entrada → algoritmo → saída → visualização; o algoritmo separado do desenho. | `laboratorio-contas.js` (o algoritmo, puro e testado) separado de `laboratorio.js` (controlos e desenho). | O autor não fala de testes; os testes são nossos. |
| W3C APG, *Tabs* e *Slider* [5, 6] (Tabs lida) | `tablist`/`tab`/`tabpanel`, setas, Home/End; ativação automática quando o painel não tem latência. Deslizadores nativos dão as teclas de graça. | Separadores com ativação automática (os painéis já estão na página); `input type=range` e `radio` nativos. | — |
| TanStack Charts e Semiotic, acessibilidade [7, 8] (via pesquisa) | Um gráfico precisa de uma camada de texto; a cor nunca é a única pista; o movimento reduzido não pode atrasar o valor. | O gráfico tem rótulo com o resultado, a legenda nomeia cada linha, o dia em foco dá os números por extenso, e há uma frase para o leitor de ecrã meio segundo depois do último movimento. | Recomendações de bibliotecas, não normas. |
| MDN, `History.replaceState` [9]; planeadores de builds com ligação permanente [10] (via pesquisa) | Mudar o endereço sem recarregar nem encher o histórico; uma ligação que guarda a configuração inteira é o modo de partilha dos planeadores das wikis de jogos. | `#laboratorio?f=noite&dia=12…`, escrito só depois de alguém mexer, e «Copiar a ligação». | O hash não versiona: um CSV mudado muda o resultado da mesma ligação — o que, aqui, é o que se quer. |
| Kingdom Two Crowns, página oficial [11] (lida) | Herói, slogan, texto, botões de loja, galeria e outros jogos. Nada se mexe. | A diferença que o Empire pode ter: deixar experimentar antes de jogar. | Uma página, não um estudo. |
| *Do demos help earn wishlists?* [12] (via pesquisa) | Num inquérito a 40 estúdios, cerca de 20% de quem joga uma demo põe o jogo na lista de desejos. | O laboratório acaba sempre num «Pôr à prova no jogo»: a demo é o fim do caminho, não um desvio. | Inquérito declarativo; não mede este site. |
| Chrome, *view transitions em 2025* [13] (via pesquisa) | As transições do mesmo documento entraram no Baseline no fim de 2025. | Consideradas e não usadas: trocar de separador não precisa de animação para se perceber, e cada animação é mais uma coisa a desligar com movimento reduzido. | — |

## O que se fez

**Um Laboratório com quatro instrumentos**, entre «Os povos» e «Como se joga», nas duas línguas e no menu.

| Instrumento | Pergunta | Contas (GDScript de onde vêm) | Números |
|---|---|---|---|
| Quem vem esta noite | O que é que a Podridão manda hoje, e porquê? | `RotProfile.calendar_mass`, `rhythm`, `written_weight`, `debut_cap`; `RotSystem._massa_do_dia`; `RotPick.choose`/`take` | `rot.csv`, `creatures.csv`, `RECUSAS_MAX` do `rot_system.gd` |
| O dia da asfixia | Em que dia a noite me alcança? | `EconomySystem.daily_income`, `trade_income`, `upkeep`, `greed_cut`, `night_cost`, `suffocation_day`; `RulesFactory.impulse_cost_mult` (o perfil de ganância) | `economy.csv`, `greed_profiles.csv`, os deslizadores do simulador do §06 em `docs/dossie.html` |
| Quanto tempo até cair | Esta tropa segura esta criatura numa noite? | A tabela do §07: golpes inteiros × intervalo ÷ precisão; o posto da torre dá `tower_accuracy` | `units.csv`, `creatures.csv`, `economy.csv`, a noite do `clock.csv` |
| A escada do muro | O que compra cada degrau, e em que caminho? | Cada degrau paga-se inteiro (`WallSite`); o Aríete pela mesma conta do §07 | `walls.csv`, `realm_stages.csv`, `peoples.csv` |

**Criatividade com a matéria do jogo.** As criaturas que a noite traz são a arte animada do dono (ADR 0083), a
dobrar e com vizinho mais próximo, a respirar no quadro de repouso; o muro desenha-se em píxeis, fiada a fiada, com os
arqueiros do caminho A em cima, o contraforte do caminho B, os atacantes que cabem nos slots de contacto e o núcleo
atrás. O gráfico da asfixia mostra o alvo do §06 como uma faixa e o dia em foco como uma agulha.

**Honestidade com o que ainda não está decidido.** A construção chumba se um campo de que uma conta depende estiver
em `_proposed`. O crescimento da noite depois da noite 10, as noites fundas e calmas e as estreias (Q-151, Q-126,
Q-240) só entram com «Juntar o que ainda é proposta», e a página diz quais são. A vida do caminho A e os postos do
caminho B dizem «por decidir». Os impulsos reais ficaram de fora: o preço de todos está em `_proposed`.

**Design e experiência (o segundo pedido do dono: «refine também o design e a user experience»).** A página inteira
foi revista em 390, 1180 e 1440 px. Quatro mudanças, pela ordem do impacto:

- *Por onde começar.* A noite e a asfixia abrem com cenários de um toque, lidos dos dados — os perfis dos testes de
  design do §06 e as noites que o dossiê conta. O §06 escreve «põe as rotas a 2 e vê os quatro dias que a conquista
  te compra»: agora é um botão. O cenário ativo fica marcado e «Repor» volta ao caso por omissão.
- *Encontrar a bancada.* Além do menu, o guia inicial ganha «Mexer nas regras ↘» e a candeia acaba numa ponte para o
  laboratório — o raso a levar ao fundo, como na pesquisa.
- *Partilhar no telemóvel.* Num ecrã tátil, o botão abre a folha de partilha do sistema; no resto, copia a ligação.
- *Um defeito da abertura.* A 1180 px, a linha do dia cortava «Meio-dia» e colava-o a «Tarde». Cada fase passou a
  ser um contentor CSS, e o rótulo só aparece se couber.

**Trabalho a pedido.** O script do laboratório (as contas, o modelo e o desenho num ficheiro) só se pede quando a
secção se aproxima do ecrã, ou quando a ligação aponta para ela; e das folhas animadas do dono serve-se só a linha do
repouso, cortada na construção (`tools/web/bestas.mjs`): 1,6–3,5 KB por criatura em vez de 12–25 KB.

**Uma incoerência corrigida.** A candeia da secção da Podridão mostrava a massa como `40 + 18 × dia`, sem a rampa das
primeiras noites que o jogo aplica (Q-017, Q-068): a noite 1 dava 58 de massa, e no jogo são 24 — os três Rastejantes
do §25. Com o laboratório na mesma página, as duas tinham de dizer o mesmo.

## Como se verifica

- `node --test tests/web/laboratorio.test.mjs` — as contas contra o dossiê: `upkeep(14) = 3,0` e `upkeep(25) = 13,5`
  (§29); o dia da asfixia de cada perfil do `economy_profiles.csv` (11 por omissão, +4 com duas rotas, 28 com tudo no
  máximo, a ganância 80 três dias antes da 20); a tabela do tempo até matar do §07; a noite 1 com três Rastejantes
  (§25); a tabela da §74 com as propostas (220, 716; 286, 782; 396, 892; 465, 961); a escada 6 · 11 · 20 · 36 · 65; e
  que, em trinta noites, nunca sobra massa que ainda pague uma criatura.
- `node tools/web/verificar_site.mjs`, grupo 20 — os separadores pelo teclado, a noite 1, a §74 com as propostas, a
  asfixia por omissão, a ligação que restaura um instrumento (em inglês, a 390 px), a partilha e o caso sem
  JavaScript; os grupos 1–5 passam o laboratório a 320, 360, 768 e 1440 px nos dois temas, com o axe; o 14 conta os
  cartões do laboratório nas duas línguas; o 18 confere a candeia com a rampa.

## O peso, medido

No build final desta tarefa (1440 px, DPR 1, bytes sem compressão, como o portão conta):

| | Antes | Depois | Em brotli |
|---|---|---|---|
| HTML da página de entrada | 107 KB | ≈ 130 KB | 16,4 → ≈ 20 KB |
| Folha de estilo | 50 KB | ≈ 67 KB | 9,4 → ≈ 12 KB |
| Caminho crítico | ≈ 658 KB | 699 KB (teto 660 → 710) | — |
| Página inteira, rolada até ao fim | — | 1697 KB (teto 1700 → 1750) | — |
| Script do laboratório (adiado) | — | ≈ 40 KB | — |
| Folhas das criaturas | 12–25 KB cada | 1,6–3,5 KB cada | — |

Os tetos sobem na ADR 0085, às claras e com a folga escrita. O que o laboratório acrescenta ao primeiro ecrã são os
seus rótulos e estilos; o trabalho dele — contas, modelo e desenho — só chega quando a secção se aproxima.

## O que fica de fora, e porquê

- **Os impulsos reais e a roda do rei.** O preço de todos é proposta; um instrumento sem preço não responde a nada.
- **Correr o jogo em miniatura** (o `.wasm`) para cada conta: ~9 MB para responder a uma linha de aritmética.
- **Um vídeo ou GIF automático da noite.** O §36 pede GIFs para o devlog, não para a página; e a página já mostra o
  jogo a mexer na abertura.
- **Analytics para medir o uso do laboratório.** O §32 é «medir sem espiar»; a medida certa é a do protocolo do §32 —
  cinco sessões observadas.

## Próximos passos sugeridos

1. Observar cinco pessoas a usar o laboratório (§32): que instrumento abrem primeiro, onde ficam presas, e se a frase
   de cada um basta sem tutorial.
2. Quando o dono aprovar as propostas da noite (Q-151, Q-126, Q-240), o interruptor deixa de ser preciso para elas:
   retirá-las do `_proposed` faz o laboratório usá-las por omissão na publicação seguinte.
3. Um quinto instrumento quando o preço dos impulsos sair de `_proposed` (Q-014): o decreto, o dia e a ganância.

## Referências

1. Bret Victor, *Explorable Explanations* (2011): https://worrydream.com/ExplorableExplanations/
2. Nicky Case, *Explorable Explanations: 4 More Design Patterns*: https://blog.ncase.me/explorable-explanations-4-more-design-patterns/
3. *Parable of the Polygons* (Vi Hart e Nicky Case): https://en.wikipedia.org/wiki/Parable_of_the_Polygons
4. Amit Patel (Red Blob Games), *Diagram structure*: https://www.redblobgames.com/making-of/diagram-structure/
5. W3C WAI-ARIA APG, *Tabs Pattern*: https://www.w3.org/WAI/ARIA/apg/patterns/tabs/
6. W3C WAI-ARIA APG, *Slider Pattern*: https://www.w3.org/WAI/ARIA/apg/patterns/slider/
7. TanStack Charts, *Accessibility*: https://tanstack.com/charts/latest/docs/guides/accessibility
8. Semiotic, *Accessibility overview*: https://semiotic.nteract.io/accessibility/overview/
9. MDN, *History: replaceState()*: https://developer.mozilla.org/en-US/docs/Web/API/History/replaceState
10. Exemplo de planeador com ligação permanente: https://wikily.gg/far-far-west/build-planner
11. Kingdom Two Crowns, página oficial: https://kingdomthegame.com/kingdom-two-crowns/
12. How To Market A Game, *Do demos help earn wishlists?* (junho de 2024): https://howtomarketagame.com/2024/06/24/do-demos-help-earn-wishlists-steam-next-fest-june-2024/
13. Chrome for Developers, *What's new in view transitions (2025 update)*: https://developer.chrome.com/blog/view-transitions-in-2025
