# 01 — Inventário · O que a arte já decidiu — e o que ainda não

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Medi as tuas duas cenas pixel a pixel, e agora medi também as cinco capturas das referências que deste — pelo mesmo processo. Há uma distinção que a v2 não fez e devia: algumas medições dizem-te como desenhas, e essas valem sempre; outras dizem-te o que está naquela imagem, e essas não valem nada enquanto o cenário não estiver terminado. As das referências pertencem à primeira categoria, e são a parte nova desta secção.

> **Correção — o erro que eu cometi**
>
> Li as tuas cenas como se fossem níveis autorados e construí uma secção inteira em cima disso: cheguei a escrever que "cada edifício está colocado com intenção e nenhum gerador teria feito aquilo". Está errado. São folhas de trabalho — arte em curso, com edifícios espalhados para ver como ficam juntos. Os números confirmam-no:
>
> A distinção que interessa: o design das personagens está praticamente fechado — silhuetas, proporções, escalas, rostos. É o cenário que está no início. Tudo o que eu li como layout era, na verdade, figuras acabadas espalhadas sobre um fundo por resolver.

Tudo o que abaixo dependia de posicionamento, extensão ou proporção de layout foi movido para a coluna "ainda em aberto". A §11 e a §21 foram reescritas em consequência.

## O que vale, e vai continuar a valer

Estas medições são propriedades de como desenhas e do desenho de personagem, que já está resolvido — não daquela composição em particular. Uma cena por acabar mede-as tão bem como uma acabada.

| Medição | Valor | O que decide |
| --- | --- | --- |
| Grelha de autoria | 1:1 nativo | Só 37% e 33% das sequências horizontais de cor têm comprimento par. Não é arte de 640×360 ampliada — é desenhada pixel a pixel a esta densidade. |
| Perda ao reduzir a 640×360 | 6,3% dos pixels | Contornos, caixilhos, telhas e ervas partem-se. A resolução interna é 1280 × 720, e esta é a decisão mais estruturante do projeto (§19). |
| Escala 1 — escudeiro | ≈ 34 px | Três escalas de personagem = hierarquia legível sem barra, nome ou seta. Medidas nos teus ficheiros de personagem, não na cena: Empire troop tem 24×47 px úteis e Knight Potato tem 35×64. |
| Escala 2 — aldeão/tropa | ≈ 46–52 px |  |
| Escala 3 — monarca/elite | ≈ 56–62 px |  |
| Contorno | Preto puro, 1 px | Em todo o objeto de jogo. É o que segura a leitura com 300 unidades no ecrã. |
| Vocabulário de material | Seis materiais | Estuque creme · vigas castanho-escuro · telha azul-petróleo escamada · pedra cinza-frio · madeira quente · relva verde-lima |
| Paleta de trabalho | 112 cores | 104 + 115 opacas nas duas cenas, 137 únicas combinadas. É a rampa atual, não a definitiva — ver §22. |
| Animação | 6 frames de idle | Confirmado nos dois ficheiros de personagem. Define o ritmo de 10 fps. |


## O que ainda está em aberto

Isto não se lê na arte atual. São decisões de design por tomar, e a §38 tem-nas na lista desta semana.

| Em aberto | O que eu tinha assumido | Como decidir |
| --- | --- | --- |
| Altura da linha do solo | y = 517, medido e tratado como constante de design | É onde calhou ficar naquela cena. Decide-a a partir do enquadramento de jogo (§11), não da imagem. |
| Altura do corte de terra | 203 px, "sempre visível" | A faixa branca é espaço por pintar, não um corte desenhado. A proporção é uma escolha de câmara. |
| Tamanho de região | 5120 px = 4 ecrãs, "a unidade natural" | 5120 é a largura da tela onde estavas a desenhar. O tamanho de região decide-se pelo tempo de travessia (§21). |
| Densidade de edifícios | 4446 px de "mundo construído" | É a extensão do que espalhaste, com vazios de 400 px pelo meio. A densidade decide-se por playtest. |
| Composição de segmento | Colocação intencional, "nenhum gerador faria aquilo" | Ainda não existe nenhum segmento autorado. §21 diz como se faz o primeiro. |
| Paleta definitiva | Paleta mestra fechada | É a rampa de duas cenas por acabar. §22 diz quando e como se fecha. |


## As três referências, medidas — não descritas

Deste-me três jogos e disseste que queres cenários assim. Não me limitei a olhar: passei as cinco capturas pelo mesmo processo que usei nas tuas cenas. O período da grelha de pixel de cada imagem sai por análise espectral do perfil de bordas — é invariante ao redimensionamento, por isso funciona mesmo em capturas da Steam já reescaladas e comprimidas. Dividindo a altura da imagem por esse período obtém-se a tela efetiva: a altura, em pixels de arte, a que o jogo foi realmente desenhado.

| Captura | Câmara | Imagem | Período | Tela efetiva | Detalhe de 1 px | Contorno 1 px |
| --- | --- | --- | --- | --- | --- | --- |
| Milki Delivery — estrada | Lateral | 1600×900 | 2,67 | 600 × 338 | 72,7% | 57,9% |
| Milki Delivery — floresta | Lateral | 1920×1080 | 2,67 | 720 × 405 | 72,3% | 44,2% |
| Eastward — floresta | Cima | 1280×720 | 2,20 | 582 × 327 | 79,5% | 38,9% |
| Eastward — aldeia (Octopia) | Cima | 1920×1080 | 3,00 | 640 × 360 | 72,8% | 51,6% |
| Chef RPG — mercado | Cima | 1920×1080 | 2,40 | 799 × 450 | 72,9% | 69,3% |
| Empire — as tuas cenas | Lateral | 1280×720 | 1,00 | 1280 × 720 | — | — |


"Detalhe de 1 px" = fração de sequências horizontais de cor com um só pixel de comprimento, na grelha do próprio jogo. "Contorno 1 px" = fração de sequências escuras com um só pixel. A estimativa de tamanho de paleta não é fiável a partir de JPEG e ficou de fora.

> **O número que muda tudo**
>
> As cinco referências vivem entre 327 e 450 pixels de altura de arte. Média: 376. Tu desenhas a 720.
>
> Isso são 1,9× a densidade linear de qualquer uma delas e 3,7× os pixels por ecrã. O Eastward — seis anos, equipa que chegou a oito, deferred lighting com bump maps pintados peça a peça — mede 640 × 360 na captura da aldeia e 582 × 327 na da floresta. As duas leituras batem certo: 640×360 é o valor que os jogadores relatam para a resolução base, e a diferença na segunda vem de a cena ser montada em 3D, onde os sprites não caem todos à mesma escala inteira. Em qualquer dos casos, menos de metade da tua grelha.
>
> E há uma segunda surpresa: o Milki Delivery, o único dos três que partilha a tua câmara lateral, não é pixel art — é desenhado à mão, na Unity. Mesmo assim mede um período de 2,67, porque o desenho é depois rasterizado a ~600×338. Aquilo que te parece "cenário lindo em pixel art" é, na verdade, ilustração grande apresentada em pouca resolução.

### O que os números querem dizer, em desenho

**O teu contorno pesa metade** — Em todas as cinco capturas, o contorno dominante tem 1 pixel na grelha delas — 39% a 69% das sequências escuras. Uma tropa tua de 47 px a 720 ocupa a mesma fração de ecrã que uma de 25 px a 376. Pões 1 px de contorno onde elas põem o equivalente a 2 dos teus. Em peso aparente, o teu contorno é metade do da referência — e é por isso que as tuas figuras, apesar de melhor desenhadas, não "assentam" como as delas.

Nas cinco, cerca de 73% do detalhe é de 1 px na grelha própria — o que na tua equivale a 2. Se pintares cenário com detalhe de 1 px, estás a desenhar ao dobro da densidade das tuas referências: a pagar o dobro das horas para obter um resultado mais ruidoso, não mais bonito. É o erro clássico de escolher resolução a mais — sobra espaço, e o espaço enche-se de ruído.

> **A lei da escala dupla — a decisão de arte mais importante deste documento**
>
> Tudo o que na referência é 1 px, na tua grelha é 2 px. Contorno de silhueta, folha de erva, telha, caixilho, junta de pedra, cluster mínimo. A tua resolução é o dobro da delas; a tua unidade de desenho de cenário também tem de ser.
>
> As personagens são a única exceção, e é de propósito. Elas ficam com detalhe de 1 px. Num ecrã onde o mundo é desenhado a passo de 2 px e as figuras a passo de 1 px, as figuras destacam-se sem contorno extra, sem barra de vida, sem seta — porque são literalmente o dobro da resolução de tudo o resto. É hierarquia visual feita com a grelha, e sai de graça.
>
> Isto não baixa a resolução do jogo nem toca numa linha da arte que já fizeste. Muda só a densidade a que pintas o mundo à volta dela. A §22 tem a especificação, o novo orçamento de horas, e o que fazer com o conflito de calendário que isto resolve.

## As camadas Aseprite já são um sistema de equipamento

Esta parte mantém-se inteira, e é a mais valiosa. Os teus ficheiros separam Body, Face, Shield, Sword, Equipments. As cenas confirmam a intenção: os aldeões são corpos-base creme com cabelo, barba e objeto na mão a mudar. Um corpo, dezenas de personagens. O pipeline exporta por camada, nunca achatado. §22 formaliza em cinco slots — e é isto que torna viável teres seis povos.

| Ficheiro | Tela | Sprite útil | Frames | Cores | Camadas |
| --- | --- | --- | --- | --- | --- |
| Empire troop | 192×192 | 24×47 | 6 | 32 | Knight · Body · Face · Shield · Sword · Equipments |
| Knight Potato | 128×128 | 35×64 | 6 | 41 | Background · Body · Face · Arms and Weapons |
| Archer Leek | — | — | — | — | Personagem do povo Horta (§04) |
| Healing Frog | — | — | — | — | A criatura verde do trono. É sistema, não adereço (§08) |


## A gramática visual — o que a arte realmente prova

**Contorno** — Preto de 1 px em tudo. Nenhum elemento de jogo flutua sem contorno.

Dois tons por material, sem gradientes. O dither fica reservado a efeitos, não a decoração.

Bocas largas com dentes, olhos afastados, narizes grandes. O humor está na cara, não em piadas de texto — e por isso atravessa idiomas de graça (§27).

As lojas identificam-se por ícone entalhado em madeira, nunca por texto. É UI diegética e localização grátis.

> **A regra de ouro, corrigida**
>
> Escrevi antes que "a arte manda" e que nenhuma decisão técnica pode obrigar a redesenhar a arte existente. A formulação certa é mais estreita e mais forte: é a grelha de autoria que manda. Nenhuma decisão técnica pode obrigar-te a desenhar a uma densidade diferente daquela a que desenhas bem. O layout, esse, ainda é todo teu para decidir — e é melhor assim, porque decidir layout com o jogo a correr dá sempre melhor resultado do que decidir numa tela em branco.
