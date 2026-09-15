# ADR 0017 — Conquistar dá uma dívida de trabalho, não edifícios

- Estado: aceite
- Data: 2026-09-14
- Secção do dossiê: §13, §14, §17, §78, §79, §81, §82

## Contexto
A §17 tem a melhor frase do dossiê: "o jogador só descobre no fim que a escolha estava a ser feita desde o primeiro
cerco." Neste momento é falsa — nada regista escolha nenhuma. Conquistar dava produção e arquitetura, de imediato e
sem custo de administração, o que também é o motor clássico do *snowball*.

## Decisão
Tomar ou assimilar um povo dá uma Colheita: `C = 6 + 2 × povos já detidos` dias (metade, arredondada para cima, por
assimilação) em que aquela gente trabalha a 140%, canta em modo menor, não dá tropas, e a aldeia dela fica fora das
tuas muralhas — A Podridão prefere-a a ti enquanto durar. Uma Colheita de cada vez; a segunda entra em fila. Se a
aldeia cair à noite, perde-se o povo, a decisão, a arquitetura e o diário de fortaleza, e esse diário reaparece no
capítulo seguinte que saiu (§77).
No fim, uma decisão com o Verbo 1 no núcleo deles: **soltar** (+25 de Favor, rota de 8 moedas/dia, tropa única a
1,5×, a canção deles junta-se ao coro para sempre) ou **ficar** (+80% de produção, tropa única de graça, a aldeia
cala-se, e o marco deles cria raiz — Amargueiro de 22 de massa por noite, que não se corta).

## Alternativas consideradas
Equilibrar as duas colunas para serem indiferentes: rejeitado de propósito. Estão equilibradas para que um jogador
que só olhe para os números escolha Ficar as seis vezes, porque é isso que tem de acontecer para o Ato IV funcionar.
Permitir Colheitas simultâneas: duas aldeias fora das muralhas ao mesmo tempo já é a punição por conquistar depressa
demais; três seriam uma noite impossível sem que o jogador percebesse porquê.

## Consequências
Três colunas novas em `peoples.csv` e dezasseis linhas em `economy.csv`. O mostrador é sonoro — o coro noturno tem
tantas vozes quantos povos soltaste — e por isso a §82 acrescenta a redundância visual: cada povo solto hasteia um
estandarte sobre o núcleo, seis mastros, zero números. Um povo perdido a meio da Colheita não conta para nenhum dos
dois contadores do epílogo (§79): é o único caso em que uma decisão do jogo não é uma decisão do jogador.
A Q-042 fica aberta: 16 dias na sexta Colheita pode ser longo demais, e mede-se em playtest.
