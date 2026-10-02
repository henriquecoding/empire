# ADR 0046 — O subsolo é um sítio, e acaba

- Estado: aceite
- Data: 2026-10-02
- Secção do dossiê: §11 (o mundo em duas camadas), §17 (segredos), §21 (geração do território), §24 (HUD), §53
- Complementa: ADR 0038 (o mundo contínuo), ADR 0039 (em baixo é só paisagem), ADR 0043 (Q-176, Q-182), ADR 0045
  (o painel do combate)

## Contexto
O dono, a 02/10/2026, com uma captura do porão da região com o painel do combate por cima: *«O subsolo não é infinito
acompanhando o piso de cima, é sempre algo delimitado, pode ser grande, mas nunca infinito, é gerado proceduralmente e
a primeira vez que é acessado naquela jogatina é algo distinto, o local onde aparece é aleatório, mas coerente com o
local, nos impérios é comum ter subsolos com locais de onde se pode armazenar coisas ou com uma sala secreta no
imperador. Esses botões não devem estar ali na frente atrapalhando, pois ao entrar no subsolo eles ficam por cima.»*

O que estava: o subsolo era uma faixa. A cave das raízes atravessava a região de ponta a ponta e o túnel de mina
seguia por baixo de todas as terras geradas; o rei, lá em baixo, andava até à borda do mundo. Com ele lá em baixo, a
terra ia-se toda. O painel do combate (ADR 0045) ficava ao fundo do ecrã, em cima do chão do subsolo.

A §11 já pedia outra coisa: *«a maior parte do corte é terra — paisagem pura, sem jogo»*; *«onde há caverna, dungeon
ou porão, a terra é recortada e o espaço passa a jogável»*. A pesquisa está em
`docs/recovery/PESQUISA-SUBSOLO-2026-10-02.md`.

## Decisão
**O subsolo é feito de sítios. Cada sítio é uma fila de salas entre duas paredes, num lugar que faz sentido, e as
salas só nascem na primeira descida.**

- **Os sítios** (`UndergroundSites`, puro). Cada um tem uma metade autorada — a chave, o tipo, a boca, o que tem de lá
  caber e o tecto que nunca passa — e uma metade gerada, as salas. A entrada fica na boca; crescem salas para os lados
  até cobrir o que tem de caber, mais 0 a `und_extra_rooms` sorteadas, de `und_room_min_px` a `und_room_max_px` cada
  (`rules.csv`, propostas). Nunca passam do tecto nem de 12 salas.
- **Onde** (`UnderWatch`):
  - **o porão de cada passagem** do império, entre os dois muros que ela tem de cada lado. É armazém, adega ou
    celeiro, e cresce até ao poço de minério e à câmara da Semente Real que lá estão, que dão o tipo à sala onde caem;
  - **a sala secreta debaixo do castelo**, com o alçapão num sítio sorteado do chão dele, a 70–190 px do meio, e as
    salas dentro da largura do castelo: a câmara, e salas de tesouro ou de fuga. O alçapão só se desenha depois de
    achado; até lá denuncia-o o sinal do Verbo 2 a quem passa por cima. Na primeira descida cai o tesouro do
    imperador, uma vez, com o prémio de uma masmorra sem guarda nem relíquia (`DungeonLoot`, Q-176);
  - **a masmorra de cada ruína** das terras (Q-173), presa ao segmento dela: a câmara do arco caído é a sala de
    entrada, as outras são cripta, desabamento, cisterna ou ossário.
- **A primeira descida.** O `Verbs.assume` que leva alguém ao subsolo chama o `UnderWatch.enter`: se o sítio da boca
  ainda não tem salas, ganha-as, pelo `RngService.scatter` com a chave do sítio. A mesma partida dá sempre o mesmo
  sítio; outra partida dá outro. As salas vão no save (`world.under`) e não mudam mais. Sem migração: um save antigo
  não tem salas, e elas nascem na descida seguinte.
- **As paredes.** No passo 5, antes do movimento, quem está lá em baixo dentro de um sítio não tem alvo para lá das
  paredes dele (`UndergroundSites.confine`). As criaturas não passam por aqui: quem cava continua a passar pela terra
  (§07: o Cavador *«passa pela faixa subterrânea»*; §51).
- **A terra.** A região e as terras têm por baixo terra maciça (`RootCellars`, `WildTunnel`); a `UnderArt` escava nela
  os sítios que já nasceram, com o recheio de cada tipo de sala (`UnderProps`) e uma parede de rocha em cada ponta.
- **Abrir só ali.** As janelas do `dither_reveal` ganham orla e força. Com o rei lá em baixo dentro de um sítio, a
  terra abre-se de parede a parede desse sítio, ao ritmo de sempre (0,45 s), e o resto continua paisagem. Sem sítio
  (um teste, uma ferramenta) vai-se toda, como antes. O poço de cada passagem abre conforme a terra por cima dele.
- **O painel do combate** passa ao canto de cima, à direita, por baixo do objetivo e acima do aviso e das legendas,
  com 66 px de alto. Não entra no corte de solo em nenhum tamanho de janela (`CombatBar.place`).

## Alternativas consideradas
- **Manter a faixa e só a cortar em troços.** Mais barato, mas o troço continuava a ser *«o piso de cima»* repetido:
  sem lugar, sem tipo e sem primeira vez.
- **Gerar tudo no início da partida.** Mais simples, mas não é o que o dono pede (*«a primeira vez que é acessado»*), e
  gerava salas que ninguém visita. O custo de gerar na descida é um sorteio de 37 números.
- **Um ecrã à parte para cada masmorra** (como a caverna do Kingdom). É a opção A da §11, rejeitada pelo dossiê: perde-se
  a superfície de vista.
- **Esconder o painel do combate no subsolo.** Rejeitado: é lá que estão os guardas das masmorras.

## Consequências
- O subsolo lê-se como lugares: o porão, a sala secreta, a masmorra. O que não é sítio é terra.
- Ir de um porão ao outro por baixo deixou de ser possível; sobe-se e desce-se noutra boca.
- A sala secreta dá um tesouro de 3 a 6 moedas (até 3 vezes) a quem a achar. É uma proposta, na Q-186.
- O armazém não guarda nada ainda. As outras possibilidades da pesquisa (o cofre, pisos, chave e porta, a saída do
  soberano) ficam para o dono.
- A arte são formas lisas em código (`UnderProps`, `UnderArt`), à espera de arte a sério, como o resto das terras
  (ADR 0038). Trocar é mudar esses dois ficheiros, e não o gerador.
- Como desfazer: tirar a linha do `field.under.confine` do `SimLoop.step` volta a deixar andar lá em baixo; tirar o
  `UnderWatch.enter` do `Verbs.assume` deixa os sítios por gerar, e a terra volta a ir-se toda.
