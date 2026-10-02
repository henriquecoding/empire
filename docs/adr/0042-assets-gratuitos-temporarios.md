# ADR 0042 — assets gratuitos enquanto se testa a gameplay

**Estado:** aceite. **Data:** 30/09/2026. **Origem:** pedido explicito do dono
para aplicar os melhores gratuitos na main; nenhum pack pago. A arte definitiva
sera feita por Henrique.

## Decisao

Adicionar os PNGs necessarios de AnGav, LuizMelo, GrafxKid, Kenney e ansimuz em
`art/source/temporary`, com exports separados em `art/export/temporary`. Esta
autorizacao especifica permite acrescentar estes arquivos em `art/`; nao altera
as fontes, exports nem aprovacao dos originais protegidos pela regra 9 de AGENTS.

Os gratuitos com proibicao expressa de redistribuir os assets nao entram no
repositorio publico. As permissões dos packs usados e os creditos acompanham o
projeto em `art/export/temporary/CREDITS.txt`. O pack ansimuz inclui uma licenca
CC0; a pagina lista CC BY 4.0. O arquivo da licenca e os creditos ficam preservados.
O pack AnGav autoriza uso em projetos e adaptacao, proibindo revenda de assets.

Arqueiro e lanceiro deixam de usar o corpo de vagabundo como substituto. O corpo
do arqueiro jogavel usa uma escala inteira maior; ambos permanecem abaixo do rei.
Rei, cozinheiro, vagabundo e cavaleiro originais continuam a usar seus exports.

Rastejante, Alado, Bruto e Cavador recebem sprites distintos. Movimento, combate,
dano e morte sao lidos das colunas existentes, sem novos sistemas da simulacao.
O Ariete de lodo, o Devorador e o Zelador conservam a representacao atual: estes
packs nao fornecem equivalentes suficientes para suas formas e funcoes especiais.

O parallax usa as camadas transparentes middle/front, sem repetir o sol do fundo,
e reaproveita os planos e limites do mundo. O terreno mantem
a linha dos pes e as passagens. Props acrescentam leitura de funcao aos edificios
sem substituir andaimes, moedas, ruina, reparacao ou pontos de interacao.

## Contrato e substituicao futura

`export_temporary.py` preserva pivots entre as poses, mede os limites do repouso,
usa nearest com escalas inteiras e empacota as animacoes num atlas compartilhado.
Uma mascara com a mesma transparencia garante silhueta uniforme fora das luzes.
Os PNGs fonte nao entram no export; o manifesto e os creditos entram.

Novas texturas sao resolvidas pelo adaptador OriginalArt; a animacao usa o
contrato ActorAction. IDs da simulacao, CSVs, saves, dano, velocidade, custos,
municao e produtividade permanecem os mesmos. As lacunas nao viram mecanicas.

Para substituir a arte temporaria, alterar os perfis de apresentacao e remover
as chamadas de TemporaryScenery/CreatureSkins, mantendo os IDs de gameplay.
O inventario gerado registra a separacao entre originais e proxies temporarios.

## Validacao

Testes dos perfis, frames, escala e prioridade de animacao; suite gdUnit4,
portoes estaticos, exports reproduziveis e render de jogo/obras. A origem e o
estado temporario nao equivalem a aprovacao artistica.
