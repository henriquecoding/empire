# Empire — animações V15

Continuação do design do Sombra e da bailarina aceito em 19/10/2026: manto pesado, capacete fechado simples, coroa pequena, roupa vinho/sálvia e atuação mais legível. O pacote reúne os oito personagens; Sombra, bailarina e floração foram atualizados nesta revisão. Os outros seis conservam os arquivos da V13.

## Ver e comparar

Extraia o ZIP e abra **ABRIR-PREVIA.html**. A página funciona sem internet, com imagens embutidas. Começa mostrando a nova dupla. Permite pausar, avançar quadros, alterar velocidade/direção, ver o tamanho real e mostrar os oito personagens.

**Novo jardim** sorteia outra configuração de plantas e horários. O GIF usa uma configuração fixa para que seja possível repetir a inspeção.

Em `previas/` estão:

- `SOMBRA-E-BAILARINA-V15.gif` e `.mp4`: os dois em movimento, ampliação inteira de 4×.
- `SOMBRA-JARDIM-V15.gif`: o ciclo completo de 12 segundos em 5×.
- `BAILARINA-DANCA-V15.gif`: a frase de dança em 6×.
- `EMPIRE-ACOES-V15.gif`: visão geral do elenco em 2×.

## Novas animações

| Personagem | Quadro individual | Ações |
|---|---|---|
| Sombra | 80×80 | idle, walk, hit, die, rise, sit, heal, stand |
| Bailarina | 64×64 | idle, walk, hit, die, rise, dance |

Há direções `right` e `left`. A esquerda espelha a direita, incluindo luz e roupa. Os pivôs também espelham: Sombra `[40,78]`/`[39,78]`; bailarina `[32,62]`/`[31,62]`. Os quadros completos devem ser preservados, sem recorte automático.

O Sombra tem poses próprias de levantar. A bailarina reutiliza a queda em sentido inverso para `rise`, identificado no JSON. Na queda do Sombra, a última pose fica mantida por dois tempos; isso é uma pausa, não um desenho novo.

Tempos diferentes de preparação, apoio e acomodação estão nos arquivos JSON e Aseprite. Não converter tudo para uma frequência única ao importar.

## O jardim agora é composto por plantas

São **28 plantas com inícios distintos**, três espécies e tamanhos de 7, 10 e 14 pixels de altura final. Cada uma usa oito estágios desenhados de crescimento e seis estágios próprios de murchamento. As três medidas são exportações das mesmas espécies, não novos desenhos independentes.

Cada planta tem posição inteira e raiz fixa durante o ciclo. Os desenhos passam de broto a caule, botão e pétalas abertas. O campo não usa rotação nem compressão vertical de uma imagem pronta. A saída usa os desenhos de pétalas e folhas cedendo; não toca o crescimento ao contrário.

A ordem de nascimento, espécie, tamanho e tempos são sorteados uma vez por ativação. Não há sorteio por quadro. O arquivo `source/jardim.cjs` contém esse relógio; o visualizador usa o mesmo código. A semente padrão é `20261019` e o esquema está em `efeitos/jardim-padrao.json`.

O corpo começa a sentar em 0 s; os primeiros brotos surgem depois de aproximadamente 1,3 s; o Sombra inicia o levantar em 8,2 s. As plantas murcham em tempos diferentes e o ciclo termina em 12 s. Esses tempos demonstram a composição visual e não redefinem alcance, duração, cura ou outras regras do jogo.

## Estrutura para edição

- `personagens/<id>/frames/`: PNG individual transparente na medida final.
- `personagens/<id>/acoes/`: faixa horizontal por ação/direção.
- `personagens/<id>/atlas.png` e `animacoes.json`: oito colunas, retângulos, pivôs, tempos e marcações.
- `personagens/<id>/<id>.aseprite`: timeline editável, com corpo em uma camada raster.
- `source-frames/`: poses de origem já adaptadas ao raster final para Sombra e bailarina, além de paletas e medidas de extração.
- `efeitos/plantas/`: variantes em PNG e Aseprite, com tags `grow` e `wither`.
- `efeitos/flores-back.png` e `flores-front.png`: ciclo padrão em camadas, quadros 160×40.
- `efeitos/flores.aseprite`: as duas camadas do campo.
- `efeitos/sombra-cura-composta.png` e `.aseprite`: 150 quadros 160×96, três camadas — flores atrás, corpo, flores à frente.
- `pesquisa/`: fundamentos, prompts e procedência desta revisão.

Na composição 160×96 o corpo continua sendo um sprite 80×80, no deslocamento `[40,16]`. O pivô da composição é `[80,94]`. O campo 160×40 fica em `[0,56]`, com pivô próprio `[80,38]`. Cada planta inteira pertence à frente ou ao fundo; os caules não são divididos por um corte horizontal.

## Godot

Copie a pasta `EMPIRE-ANIMACOES-V15` para a raiz do projeto. Use filtro **Nearest**, mipmaps desativados e posições inteiras.

`source/importar_godot.gd` é um EditorScript opcional que cria recursos `SpriteFrames` a partir dos atlases e JSONs. Ajuste os offsets pelos pivôs indicados. Ele não conecta as ações ao controlador do jogo.

`source/jardim.gd` é um Node2D opcional. Posicione-o no pivô dos pés do Sombra e chame `trigger()` **ao começar `sit`**. O próprio relógio aguarda o apoio do corpo antes de fazer os brotos aparecerem. `trigger(20261019)` reproduz o jardim padrão; sem argumento, uma nova semente é escolhida. As plantas usam sprites sem centralização, com `z_index` de frente/fundo e filtro Nearest.

O script demonstra o ciclo de 12 segundos. Para duração variável de habilidade, interrupção de cura ou persistência do jardim, o controlador precisa ligar e ajustar esses estados conforme a regra do jogo. Marcações de eventos nos JSONs são dados, não sinais já conectados.

Godot e Aseprite não estão disponíveis neste ambiente; os scripts não foram executados no motor nem os arquivos abertos no aplicativo Aseprite. O visualizador foi conferido por sintaxe, mas não pôde ser executado num navegador local. GIFs, vídeo e os arquivos binários foram produzidos e conferidos separadamente.

## Conferência e procedência

`python3 source/verify.py .`, executado na pasta do pacote, compara todos os pixels de PNGs, faixas, atlases e Aseprite, além de tempos, tags, espelhos e pivôs. Também reconstrói independentemente cada quadro da cura com as plantas e seus relógios, confere os estágios e verifica o alinhamento ao chão. O relatório está em `verificacao.json`.

`node source/exportar.cjs` reconstrói atlases e Aseprite dos personagens numa pasta `reexportado/`, a partir dos PNGs individuais. Esse leitor simples espera os PNGs originais de filtro zero; alterações exportadas por outros editores podem exigir outro decodificador.

As poses e os estágios das plantas foram criados com geração de imagens a partir do design aceito, depois separados, alinhados, adaptados às medidas finais e quantizados para as paletas do pacote. Não se afirma que a ferramenta gerou originalmente rasters 64/80 nem que todos os pixels foram desenhados manualmente. Os arquivos do corpo são rasters completos, não um rig de membros.

O aceite anterior foi do design. A aprovação artística desta animação continua sendo do autor do jogo. A conferência técnica não substitui essa avaliação nem um teste de gameplay.
