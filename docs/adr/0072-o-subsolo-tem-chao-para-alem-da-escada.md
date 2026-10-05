# ADR 0072 — O subsolo tem chão para além da escada

- **Estado:** aceite como protótipo pedido pelo dono em 05/10/2026 («implemente esse relatório»).
- **Tarefa:** `docs/backlog/RG-27.md`.
- **Fonte:** relatório «Armazéns, subsolos, masmorras e cavernas», em `docs/reports/SUBSOLO-ARMAZENS-DUNGEONS.md`.
- **Estende:** ADR 0046 (o subsolo é um sítio, e acaba) e Q-186; a cave real e o cofre da ADR 0065 e da Q-220.
- **Conserva:** o passo de escavação de 96 px, o teto de 12 salas, a geração na primeira descida pela semente e pela
  chave do sítio, os layouts e cofres gravados, os guardiões que não se evaporam ao amanhecer e a transferência única
  do cofre estrangeiro.

## Contexto

O dono viu subsolos que eram só a escada. O relatório encontrou quatro caminhos para isso no código: a largura
mínima de uma sala encolhia até caber no tecto; as salas extra podiam sair zero; a cave real no estágio zero tinha
96 px (`cellar_step_px`), menos do que a sala mais estreita; e a escavação acrescentava o que sobrava, mesmo 20 px.
Faltava uma condição final — «a entrada leva a uma zona utilizável» — e as entradas publicavam-se antes de a confirmar.
Pedia também que nenhuma cave ou masmorra aparecesse só porque saiu num sorteio.

## Decisão

1. **O contrato de área útil** (`UnderFit`). Um sítio tem a chegada (`arrival_px`), a folga de circulação
   (`clear_px`), as margens (`margin_px`) e uma **baía**: um intervalo livre, contíguo e alcançável de pelo menos
   `bay_px`, fora da chegada e do que lá está (o poço de minério, a câmara da Semente Real). Mede-se a união do que
   está ocupado e procura-se um intervalo inteiro; a soma de bocados não conta. Vazio é válido; escada sem chão não.
2. **Gerar e depois cumprir** (`UnderLayout`). O gerador antigo corre igual; se no fim não há baía, o sítio
   alonga-se pelo lado onde o envelope mais curto cabe — uma conta, não tentativas às cegas. Um bocado mais curto do
   que meia sala alarga a sala da ponta em vez de criar uma sala de 20 px; com 12 salas, também.
3. **Reservar antes de publicar** (`UnderReserve`). Cada sítio por gerar reserva o envelope mínimo que lhe cabe, por
   ordem de chegada e sem tocar nos gerados; cada um fica depois com o que sobra dos outros. Nenhum sítio cresce para
   o chão prometido a outro, nem pela escavação. Um sítio **opcional** sem chão fica sem entrada: a ruína continua a
   ser ruína, sem boca. Um sítio **obrigatório** (os porões das passagens e a reserva real) publica-se sempre, e o
   porquê fica registado em vez de a sala encolher em silêncio.
4. **A cave real tem largura habitável inicial** (`cellar_base_px`), separada do passo de escavação: a chegada de um
   lado da boca e a baía do outro, e cada estágio acrescenta um passo. A escavação fecha-se no estágio que já não
   cabe sem tocar noutro sítio (`BuildSystem.cellar_room`) — não se cobra por um aumento que não existe.
5. **O baú não é a subida.** O baú fica na baía, a `chest_px` da ponta dela que dá para a chegada, longe do alcance
   da boca: o Verbo 2 na boca sobe, no baú tira. O ladrão vai ao baú e não à boca.
6. **A causa antes do sorteio.** Cada sítio tem uma família com uma âncora que se vê: o porão (a passagem), a reserva
   real (a sede), a ruína (o arco caído) e a **caverna** (a falha de rocha de um limiar, `rock_fault`). A ruína escolhe
   a função que teve — cripta, depósito ou cisterna — e só leva salas dessa função. A reserva real já não traz arcas
   nem frestas que não respondem. A caverna não tem escada nem abóbada aparelhada, e não guarda tesouro.
7. **Um tecto de entradas opcionais por povo** (`optional_max`, `optional_spacing_px`): ruínas e cavernas de um povo
   não passam de `min(optional_max, comprimento elegível / optional_spacing_px)`. Decide-se uma vez, quando o
   segmento nasce, e grava-se. Um tecto e não uma quota: pode sair zero, e uma candidata recusada não é trocada por
   outra masmorra.
8. **A função da sala não se apaga.** O que está numa sala entra nas features dela (`FEATS`) e o tipo fica; a arte
   desenha a feature ao meio e o recheio ao lado, se couber.
9. **A recompensa é uma intenção.** Sorteia-se quando o segmento nasce, como antes, mas fica por pôr; materializa-se
   uma vez, no meio da baía, na primeira descida, e marca-se onde ficou. Descer outra vez ou carregar não a repete.
10. **O ladrão leva o que lhe cabe** (`thief_carry`) e leva-o consigo: o valor entra na carga dele e cai onde ele
    morrer. Só se perde se ele sair vivo. O total conserva-se: baú + o que os ladrões levam.
11. **Os celeiros dividem a reserva.** Um celeiro cheio passa o resto ao seguinte, por ordem de id; nada se deita fora.
12. **Diagnóstico.** O inspetor (TAB) diz o sítio mais perto do rei: chave, família, porque não serve, baía, versão e
    quantos ficaram sem entrada (§17.5 do relatório).

## Dados e saves

`underground.csv` é novo; todos os números são valores de ensaio do relatório, em `_proposed` (Q-244). Cada sítio
gerado guarda a versão do gerador (`generator_version`), o baú e se foi reparado. Um sítio de um save antigo
(versão 1) repara-se uma vez ao carregar: o tipo das salas que a feature apagou volta pelo sorteio guardado na sala,
e o chão que falta estende-se dentro do que é dele, sem mexer na boca nem no que lá estava; a marca de versão impede a
segunda vez. As recompensas de um save antigo já estavam na boca e ficam lá — nada se repete nem reaparece. O formato
do save não muda de versão: as chaves novas têm valor por omissão.

## Fora desta decisão

O transporte de uma categoria por trabalhadores (SUB-16), a recuperação de um depósito vazio (SUB-19), a preparação e
a fuga do ladrão (SUB-17, parte), encontros por papel (SUB-18), a fauna das cavernas, portas e chaves, a associação de
cada unidade a um `site_id` em vez da coordenada, e os ensaios no Web e com pessoas (SUB-21, SUB-22). Ficam em RG-27
como lacunas, não como exceções permanentes.
