# ADR 0078 — O Atlas do Império e a ficha do sítio

- **Estado:** aceite como primeira entrega pedida pelo dono em 07/10/2026 («Implemente essas melhorias dos
  relatórios»).
- **Tarefas:** [UX-08](../backlog/UX-08.md) (HUD e UI) e [CV-01](../backlog/CV-01.md) (diagnóstico do cenário).
- **Fontes:** o plano mestre da HUD, [`docs/reports/HUD-UI-ATLAS.md`](../reports/HUD-UI-ATLAS.md), e o plano mestre
  de cenários, [`docs/reports/CENARIOS-GODOT.md`](../reports/CENARIOS-GODOT.md), ambos de 07/10/2026.
- **Estende:** ADR 0074 (HUD compacta com detalhe a pedido), ADR 0066 (a caravana escolhe onde o Império nasce) e
  ADR 0077 (o território decide o que se levanta).
- **Conserva:** a simulação, os preços, os gestos e a posição de cada controlo de toque, CORRER mantido (Q-193),
  FIXAR, a escala de UX-06, o save e os ficheiros de `art/` e `audio/` (regra 9).

## Contexto

A captura do dono mostrou o painel «Fundar o Império aqui?» no meio do ecrã, por cima do monarca, com uma linha por
consequência da clareira e por obra do território: ≈24 % da área de jogo só nesse painel (§3.1 do plano da HUD). O
painel misturava três perguntas — posso fundar aqui, o que este sítio permite, que condição falha a uma obra — com o
mesmo tamanho e a mesma urgência, e «Pesqueiro: sem água ao alcance; aqui não se levanta» lia-se como um bloqueio da
fundação, que não é. Os números «6 / 33», «16 dias» e «1 de 2» não diziam o que contavam. A HUD era castanha, a
pausa verde-ardósia e os botões de toque todos iguais: moeda, ataque e interagir pareciam a mesma coisa.

O plano de cenários pede quase tudo a arte (kits, máscaras, reconstrução de planos), que esta tarefa não pode tocar.
Do que é código, pede capturas reproduzíveis (CV-01), uma sobreposição que mostre o território que a simulação conhece
(CV-39, EX-07) e o contrato de que nada de jogo desliza com o parallax (§6.3, §40).

## Decisão

1. **Indicação curta e ficha voluntária (HUD-04, UI-02).** Parado num sítio de fundação, o contexto diz uma linha:
   «Fundar neste local · E: ver condições». O Interagir abre a `SiteSheet`: se aqui se funda, o que a fundação faz, o
   que a clareira leva e o que fica, e o que o território permite por obra. A ficha lê `FoundationGuide.sections()`,
   a mesma conta que a confirmação usa; não há uma segunda versão da frase. **Abrir não gasta nem funda.** Fundar é o
   Interagir outra vez, ou o botão «Fundar»: sai pela intenção `ASSUME` de sempre, e `FoundationChoice.claim()` volta
   a validar o sítio. Voltar, a pausa, `ui_cancel` ou o sítio deixar de valer fecham a ficha sem mudar nada; o foco
   seguro é o Voltar, porque o Espaço larga moedas e não deve fundar por hábito. Aberta,
   o mundo não recebe ordens (como o painel da viagem) e os controlos de toque soltam o que tinham premido; o relógio
   continua. No desktop a ficha encosta-se à direita e deixa o centro, onde a câmara põe o monarca; abaixo de 420
   unidades de altura sobe por cima do cabeçalho e o corpo rola.
2. **Tokens Atlas (UI-01).** `Atlas` guarda a paleta do §5.4 do plano (campo, campo elevado, texto, secundário,
   latão da moeda, perigo, cumprido, informação, linho e tinta) e duas cores derivadas e medidas: a linha (3,2:1 no
   campo) e a tinta suave (5,4:1 no linho). `HudStyle`, `GameHud`, `PauseTheme` e `TouchArt` leem-nas daí; o «Estado
   do reino» da pausa passa à folha de linho com tinta escura. Os motivos próprios que não precisam de arte: o
   **canto de registo** (um canto recortado em recta, os outros em esquadria) em todos os cartões, e as **linhas de
   território** (três traços) por baixo do título da ficha. O selo do horizonte e as fontes Alegreya e Atkinson
   Hyperlegible ficam por fazer (Q-253).
3. **Famílias de comandos no toque.** Moeda a latão, Interagir a azul de informação, ataque e habilidade com o aro
   duplo, e o resto (FIXAR, CORRER, impulsos, pausa) a secundário; ligado é verde de cumprido. Muda só o aro e o ícone:
   cada botão fica no sítio e com o gesto de antes (§9.1 do plano).
4. **O que cada número quer dizer (HUD-02).** Lido no código e dito no texto: o saldo é «moedas no saco / capacidade
   do saco» (`RealmReadout.purse()`), e o título passa a «Moedas / máx.»; a estação conta os dias que faltam com hoje
   incluído (`Seasons.left()`), «restam 16 dias», e o último diz «último dia»; «1 de 2» são os lugares (vagas) dessa
   obra com a fonte ao alcance, «Poço de minério · 1 de 2 lugares com rocha com passagem ao alcance». As linhas do
   território separam nome, contagem e condição e deixam de dizer «aqui não se levanta».
5. **Diagnóstico do cenário (CV-01, CV-39).** Com o inspetor aberto, `TerritoryOverlay` desenha no mundo as fontes do
   `TerritoryWatch` (água, árvores de pé, rocha das passagens) como barras no chão e cada sítio de obra com o alcance
   da regra e a resposta — verde cabe, vermelho não. O inspetor lista os planos de profundidade e o fator de cada um.
   `tools/captura_hud.gd` grava com cada PNG o manifesto da §30.1 (commit, motor, renderer, stretch, semente, dia,
   fase, posição do monarca) e ganha `--fundacao`, `--ficha` e `--inspetor`. `PlaneContract` lê as cenas sem as
   instanciar, e o teste guarda que os planos andam mais devagar quanto mais longe e que nenhuma camada de jogo vive
   dentro de um `Parallax2D`.

A primeira captura com a sobreposição achou o caso do §42.2 do plano: a água que o território conta para o pesqueiro
está debaixo do caminho, onde o cenário pinta mata e terra, e o lago só existe no panorama (Q-257).

## Limites

Nada disto é arte: o kit de terreno, a separação do panorama, a árvore monumental, as máscaras e os interiores do
plano de cenários continuam por produzir, e pedem quem possa tocar em `art/`. Não se trocou de fonte, não se desenhou
o selo, não se mexeu em `Band.GROUND_LINE` (o A/B 517 contra 460 é uma experiência por decidir) nem nos fatores de
parallax da cena, que divergem do `parallax_layers.csv` (Q-254). A ficha é a primeira; edifícios, armazéns e mapa
seguem a mesma ordem de leitura quando houver tarefa para eles. As capturas são de um ecrã virtual em OpenGL; não
certificam conforto num telemóvel real, que continua a pertencer à sessão de aparelhos do plano (§18).
