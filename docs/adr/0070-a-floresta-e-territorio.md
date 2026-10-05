# ADR 0070 — A floresta é território

- **Estado:** aceite como protótipo pedido pelo dono em 05/10/2026 («implemente também o que coloquei nesse relatório»).
- **Tarefa:** `docs/backlog/RG-26.md`.
- **Fonte:** relatório «Vegetação, mudanças ambientais e biomas em Kingdom e noutros jogos», em `docs/reports/VEGETACAO-BIOMAS.md`.
- **Corrige:** a verificação da fundação livre da ADR 0066 (PR #85), no mesmo pedido («verifique se foi bem implementado»).
- **Conserva:** fundação gratuita e sem madeira, reserva física, caça, estações da Q-172, escada da sede e saves antigos.

## Contexto

Até aqui a vegetação era só cenário gerado pela semente: não se cortava, não se lembrava e não
mudava nada no reino. O relatório recomenda começar com poucos ambientes claros, separar bioma,
cobertura, estação e intervenção, manter as alterações e explicar poucas relações de vizinhança
(origem, destino, alcance e acumulação). Propõe um protótipo por etapas, P0 a P5.

## Decisão

1. **Cada árvore é uma coisa do mundo** (`Woodland`): id estável, espécie, sítio e estado — de pé,
   marcada, abatida (fica o cepo) ou limpa (fundação ou obra, sem moeda). O save leva as árvores
   inteiras e a versão do gerador (`forest.csv.generator_version`); o que se corta não volta, nem
   com a primavera nem ao carregar.
2. **Primeiro o mapa, depois a floresta** (`ForestPlan`, `ForestWatch`). Passagens, provisões,
   acampamentos, estátuas, raízes, tocas, bases do Lume, bocas e o que já se ergueu ficam reservados.
   A densidade do bosque (`Woods`, o mesmo ruído do cenário) e a espécie do bioma enchem o resto,
   uma árvore no máximo por célula. A toca que vive de árvores nasce com o abrigo que a regra pede.
3. **Cinco espécies, cinco silhuetas** (`flora.csv`): carvalho, pinheiro, salgueiro, pinheiro da
   costa e árvore-das-raízes, ligadas aos biomas (os três exemplos do §9 do relatório: ribeira,
   costa baixa e charco). Num segmento de transição a espécie de cada célula sai de um dos dois
   biomas pelo peso da mistura nesse sítio; a densidade mínima mistura-se pelo mesmo peso.
4. **Abater como no Kingdom** (`ForestWork`). Depois de fundar e havendo construtor, uma moeda do
   monarca numa árvore marca-a; um construtor livre vai abatê-la de dia; o tronco dá moedas físicas
   e deixa o cepo. Uma obra tem prioridade sobre a árvore no mesmo sítio; quando o andaime se
   levanta, o chão dela limpa-se sem moeda, como a fundação (ADR 0066).
5. **Duas regras de influência, explícitas** (`Influence`):
   - *o bosque apoia a coleta* — origem: árvores `forage` de pé; destino: a coleta nas provisões;
     alcance: distância no mundo; condição: `grove_feeds_min`; efeito: +`grove_feeds_bonus` moeda
     por dia; acumulação: máximo `grove_feeds_cap`, nunca soma;
   - *a floresta abriga a caça* — origem: árvores `shelter`; destino: as tocas que saem de árvores
     (o veado); abaixo de `shelter_min` a toca adormece e não dá bicho.
   A distância é ao longo da faixa; um muro não corta a influência (escolha deste protótipo).
6. **Ler antes de decidir** (`ForestGuide`, `ForestView`). Ao pé de uma árvore o painel diz a
   espécie, o custo, o que o tronco dá e a quem ela serve, com quantas árvores cada destino tem e
   quantas precisa; se for a que faz a diferença, diz o que se perde. A vista marca os destinos com
   um losango e o chão entre os dois. Nas provisões, o painel diz o estado do bosque da coleta.
7. **A estação muda a aparência, não a existência.** A caducifólia fica ruiva no outono e despida
   no inverno; a perene não muda; as flores do campo são da primavera e do verão. O vento mexe só a
   copa, com fase estável por árvore. A flora comum à volta de um tronco abatido sai com ele: a
   clareira lê-se, e não só o objeto.

## Verificação da ADR 0066 (PR #85)

O deploy de produção serve o commit `64c7e73` e o teste de fumo passa. A verificação encontrou
dois defeitos reproduzidos com a mesma semente, corrigidos aqui:

- **A sede podia nascer fora da região de casa.** O validador aceitava todo o mundo gerado
  (`Frontier.walk_limits()`); fundar 2 500 px a leste da região punha os muros em terras de outro
  povo, deixava passagens e subsolo para trás e a noite, que nasce nas bordas da região, chegava
  pelo lado errado. A janela passa a ser o centro da região ± `foundation_window_px` (448, proposta
  em `arrival.csv`), que mantém o segundo recinto dentro das bordas. Alargá-la pede noite, Lume e
  subsolo relativos ao reino (RG-24).
- **A carroça ficava perdida.** Andava a 48 px/s atrás de um monarca mais rápido e, fundado o
  reino num sítio livre, ficava onde estava, com as moedas e o grupo a milhares de píxeis. Agora
  apressa-se (`caravan_catch_up_mult`) a partir de `caravan_catch_up_px` e, fundado o reino,
  ancora-se à sede como nas fundações antigas.

O que a ADR 0066 declara por fazer (Coop, PvP, servidor, clima completo e despertar social) continua
por fazer em RG-24/RG-25; não é defeito desta entrega.

## Dados e saves

`flora.csv` (espécies) e `forest.csv` (regras) são novos; todos os números estão em `_proposed`
(Q-238). Save v12: um save sem floresta fica marcado como de antes dela e planta-a no primeiro
passo, sem cobrir obras erguidas nem a clareira da sede, e sem tocar em moedas, pessoas ou obras.

## Fora desta decisão

Meteorologia e vento partilhado com água e som; recuperação da erva por células; plantação,
regeneração e árvores como recurso de construção; a floresta de fundo a recuar no horizonte;
mais regras de influência; arte final; medição de desempenho no equipamento-alvo (P5). Ficam em
RG-26 como lacunas, não como exceções permanentes.
