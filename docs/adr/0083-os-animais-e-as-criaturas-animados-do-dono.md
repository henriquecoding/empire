# ADR 0083 — Os animais e as criaturas animados do dono entram no jogo

- Estado: aceite
- Data: 2026-10-15
- Secção do dossiê: §06 (o galinheiro e o estábulo de vacas), §07 (as criaturas e o combate), §12 (as montarias),
  §22 (a pixel art e a escala), §25 (a caça), §75 (o Zelador), §80 (a luz)
- Complementa: ADR 0049 (o bestiário), ADR 0057 (a caça a sério), ADR 0075 (a direção visual), ADR 0081 (os cenários
  do dono); Q-218 e Q-219 (os bichos à escala do sprite de 64 px)
- Tarefa: [CV-03](../backlog/CV-03.md)

## Contexto

O dono, a 15/10/2026: *«Implemente isso no meu jogo»*, com dois pacotes de 14/10 e as prévias deles:

- **EMPIRE-ANIMAIS-ANIMADOS-64x64** — 12 espécies (cavalo, búfalo, vaca, cervo branco, javali, carneiro, cervo
  castanho, raposa, pavão, galo, galinha, coelho), seis ações cada (repouso, caminhar, correr, comer, a ação própria e
  deitar ou cair), 499 quadros de 64 × 64 com o pivô em (32, 60), uma escala por espécie e **as proporções entre as
  espécies guardadas** (a galinha 23 × 23, o cavalo 52 × 49).
- **EMPIRE-CRIATURAS-ANIMADAS-64x64** — as oito criaturas aprovadas (Cavador, Aríete de raízes, Saqueador de raízes,
  Rastejante, Alado de folhas, Bruto, Consumidora, Zelador), oito ações cada (repouso, andar, golpe, susto, morte,
  vinda e duas próprias), 252 quadros com o apoio em (32, 56) e uma paleta de 32 cores. Cada criatura enche o quadro:
  o porte entre elas não vem no pacote.

Os dois guias dizem o mesmo do que não trazem: IA, colisões, dano, velocidade e transições são do jogo; desenham para
a direita e espelham-se para a esquerda; filtro nearest e escala inteira. O catálogo de cenários de 08/10 que veio com
eles é o da ADR 0081, já no jogo.

Tal como nas ADR 0075 e 0081, este pedido autoriza a edição de `art/` para esta tarefa, sobrepondo-se à regra 9 do
`AGENTS.md`; as fontes ficam nos pacotes do dono e o que entra no repositório é o export verificado.

## Decisão

**Cada bicho e cada criatura que o jogo já tem passa a ser desenhado pela arte animada do dono, com as ações que a
simulação já sabe dizer. O que se faz, quando e onde, continua a ser a simulação a decidir.**

1. **Export (`tools/export_animated.py`).** Lê os dois ZIPs sem os extrair e confere cada ficheiro que usa com as
   somas do próprio pacote (`metadata/checksums.sha256`, `SHA256SUMS.txt`). Escreve em `art/export/animated/` a folha
   virada para a direita, byte a byte, a máscara branca dos mesmos quadros (o branco do golpe e a silhueta da noite)
   e, nas criaturas, o brilho: a cor mais clara da paleta delas — os olhos e os dentes —, a única coisa delas que se vê
   no escuro (ADR 0048). O `manifest.json` tem a forma que o `OriginalArt` lê (`size`, `foot`, `frame_origins`,
   `durations_ms`, `tags`), e as ações da categoria (`feed`, `special`, `down`) e os aliases do pacote (a fuga a 1,4×,
   o voo do Alado) são etiquetas também. `--check` confere o export contra o manifesto sem os ZIPs (portão
   `inventario-arte`). São 17 recursos, 0,5 MB.
2. **Quem é quem.** Criaturas: Rastejante → `crawler`, Alado → `winged`, Bruto → `brute`, Cavador → `burrower`, Aríete
   → `slime_ram`, Consumidora → `devourer`, Zelador → `tender`. Caça: coelho, raposa, cervo castanho (`deer`), cervo
   branco, javali e o pavão no lugar do faisão — o dono, a 15/10/2026: *«ainda há o faisão, e minha intenção era
   trocar ele pelo pavão que fiz»*. O id fica `pheasant`, que as tocas gravadas guardam; o nome que se vê passa a
   Pavão. Montaria: o cavalo de tração. Obras: a galinha e o galo à porta do galinheiro, duas vacas à porta do
   estábulo de vacas (§06: *«as galinhas cá fora»*, *«vacas vivas»*). O búfalo, o carneiro e o Saqueador não têm lugar
   no jogo e ficam nos pacotes (Q-263).
3. **A escala é sempre inteira.**
   - As criaturas à escala inteira que mais se aproxima do porte delas no `Bestiary` (Q-219): o Rastejante a 2×
     (90 × 58), o Cavador a 2×, o Alado, o Bruto, o Aríete e o Zelador a 3×, a Consumidora a 5× (275 × 245). O porte
     fica a menos de 20 % do da Q-219, e a ordem não se perde.
   - A caça e o cavalo a 2×, todos à mesma escala, para guardarem as proporções do pacote: o `sprite_scale` do coelho,
     da raposa, do javali e do faisão (agora o pavão) passa de 3 a 2 no `wildlife.csv` (a raposa a 3× ficava da altura
     do veado).
   - As galinhas e as vacas a 1:1, à escala da obra onde vivem: a 2×, a galinha ficava da altura do galinheiro.
4. **O que cada um faz no ecrã sai da simulação.**
   - Criaturas (`AnimatedBeasts`): o golpe acompanha o da simulação (`CombatFx.attack_frame`, como nas tropas); o
     susto toca desde que o golpe chega (`CombatFx.since_struck`); quem aparece a meio da noite levanta-se do chão
     (as que já estavam quando o jogo abriu, não); o Alado que apanha uma galinha (`Thieves`) agarra-a e foge com ela;
     quem entra numa luz que a aguenta recua (ADR 0034); o Aríete com uma obra por alvo investe. A morte é a animação
     `die` dela, pela pele do `LastSeen` que o `DeathBurst` já sabia desenhar e ninguém lhe dava.
   - Caça (`HuntPoses`): a velocidade que se vê — a fugir corre, a pastar anda, nas pontas do vaivém come e depois
     descansa; o javali ferido ameaça quando bate, e o atordoado pelo muro fica parado.
   - Cavalo: no estábulo está e pasta; montado anda, e corre com quem corre. Debaixo de quem o monta segue o x que se
     desenha dele e olha para onde ele olha.
   - Zelador da voz (`OfferView`): anda para o núcleo, pára no muro e, quando leva a tropa da noite, cuida dela.
   - Galinhas e vacas (`FarmAnimals`): passeiam à frente da obra — vão, comem, descansam e voltam; o galo canta e a
     galinha bate as asas na outra ponta. Cenário, como a `Fauna`: nada disto entra na simulação nem no save.
   - As ações sem nada na simulação que as chame (o bote, o rugido, o agarrar da Consumidora, o escavar, o deitar)
     ficam na folha à espera de quem as chame.
5. **A luz.** As criaturas levam a mesma tinta de antes (as tuas luzes revelam-nas; fora delas, o escuro) e o brilho
   por cima. A caça, o cavalo e os bichos da quinta levam a luz dos sprites das tropas (§80): perto de uma luz a cor
   deles, longe a silhueta quente.
6. **Recurso.** Sem o manifesto, cada desenhador volta ao que desenhava antes (o bestiário renovado, as formas lisas da
   caça e do cavalo). O manifesto entra no `include_filter` dos três presets de export.

## Alternativas consideradas

- **Escalar cada criatura para a caixa do `Bestiary` como a arte renovada fazia** (fator não inteiro): a 1,93× os
  pixeis da arte de 64 × 64 ficavam de larguras diferentes. Rejeitada a favor da escala inteira mais próxima.
- **O `sprite_scale` de antes (coelho, raposa e javali a 3×, veados a 2×)**: tinha sido escolhido para formas lisas de
  tamanhos sem relação; com a arte do dono, a raposa ficava da altura do veado e o javali acima do rei.
- **Tudo a 2×, as galinhas incluídas**: medido na captura, a galinha ficava da altura do galinheiro.
- **Instanciar as cenas `AnimatedSprite2D` dos pacotes**: o jogo desenha os corpos em lote, com a pose do golpe, a luz
  e a morte do `CombatFx`; um nó por bicho saía desse caminho. Os `SpriteFrames` ficam nos pacotes.
- **Subir o cavaleiro para a sela**: o pacote não tem pose de montar, e um corpo de pé em cima do cavalo lê-se pior do
  que o cavalo por trás dele. Fica como estava (Q-265).

## Consequências

- O `HuntView` e o `GameArt` deixam de desenhar o coelho, o veado, a raposa, o javali e o cervo branco; o `MountView`
  deixa as formas lisas do cavalo, o `RenewalBeasts` as sete criaturas e o `OfferView` o Zelador do bestiário. Ficam
  todos como recurso.
- A regra da Q-219 *«quem se levanta de um bicho nunca é mais pequeno do que ele»* passa a contar o corpo inteiro e não
  só a altura: a raposa tem as orelhas 4 px acima do Rastejante, que é mais largo e maior do que ela (Q-264).
- A Consumidora a 5× tem pixeis de 5 px contra o 1 px das tropas (o ASSET_BIBLE pede 1 px às personagens e uma tela de
  256 × 256 ao colosso).
- Reverter: apagar `art/export/animated/` (ou o manifesto) devolve os desenhos de antes sem tocar em código; o
  `sprite_scale` volta no CSV.
