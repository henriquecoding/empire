# Direcao visual confirmada — 05/10/2026

A referencia mais recente esta em `references/2026-10-05/kingdom-panorama.png`.
O dono confirmou a direcao dos protagonistas e cenarios e disse expressamente:
«Essas criaturas da podridao que gerou agora eu gostei».

## Linguagem comum

- Materiais do reino: reboco marfim, carvalho quente, pedra clara e telhados azul-esverdeados.
- Protagonistas: formas expressivas e arredondadas, contorno escuro, equipamento legivel.
- Nia: pele castanha, cabelo preto encaracolado, capa vinho e dois machados.
- Podridao: casca torcida, raizes, musgo, sombras ameixa e olhos ambar. Silhuetas distinguem rastejante, alado, cavador, bruto, ariete, devorador e zelador.
- Paisagem: vale e lago ao fundo, vegetacao em planos e estrada clara. A luz continua a acompanhar as fases do dia.
- Arquitetura: a fundacao comeca numa lareira apagada; a arte cresce com os estagios reais do jogo.

## Fontes e integracao

As ilustracoes originais geradas e os retratos de referencia ficam em
`art/source/renewal/`. O ficheiro `prompts.json` resume os briefs de geracao da
sessao; `manifest.json` regista hashes de todas as fontes. Os desenhos anteriores
permanecem nos respetivos diretorios, sem serem substituidos no arquivo.

`python3 tools/export_renewal.py` recorta os frames, alinha os pes e produz texturas
com transparencia, atlas partilhado, mascara de impacto e emissao dos olhos.
`--check` regenera em diretorio temporario e compara os bytes. Atores usam detalhe
a um pixel; edificios e flora sao reduzidos numa grelha de dois pixels.

As referencias de quinta, porto e desfiladeiro orientam materiais e composicao.
Esta entrega concentra a renovacao no elenco principal, bestiario, floresta,
progressao da sede e edificios centrais. Unidades especializadas, veiculos e obras
secundarias ainda conservam partes do desenho procedural anterior; estao visiveis
no inventario gerado, nao marcadas como arte final concluida.
