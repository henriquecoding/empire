# ADR 0106 — Luz facetada por pixel no Empire e na Forja

**Estado** — implementado em FORJA-20. Decisão de apresentação para o pedido de 07/11/2026.

O Pixel Art Lighter v3.5.23 de Red Hat Sprite (Moonfell RPG, MIT) estima relevo a partir de regiões de cor conexas,
distância à silhueta e planos de valor. A Forja porta esse núcleo para o processamento local com Pillow, com perfis de
personagem, objeto, arquitetura e terreno. Usa direções discretas, reúne contornos finos às faces vizinhas e exporta
uma máscara que atenua só a luz direta. O albedo é a arte de origem. O mapa técnico e a prévia saem em separado.

O runtime aplica os mapas nos oito atlas reais V15. Cada quadro é analisado na sua própria célula. Quando o manifesto
aponta para um espelho exato, espelham-se as posições e inverte-se a componente X da normal. Os mapas de runtime
ocupam `src/actors/lighting_maps/`, com prova de correspondência ao albedo e ao layout do manifesto.
O atlas RGB empacota X e Y em R e G (direita e cima) e a máscara em B=0…254. B=255 identifica o fundo e texturas
sem mapa. A componente Z é reconstruída no shader; a amostragem é nearest e sem mipmaps.

O shader usa as luzes que já vêm do `LightField` de cada faixa. A resposta normal × luz multiplica a receção direta
dentro das mesmas três paragens da ADR 0048. A silhueta distante continua a seguir a exposição do corpo; o flash do
dano desenha a partir do albedo. A hora do dia, o alcance das fontes e as regras de proteção continuam a vir dos
sistemas existentes. A altura aparente da luz é um parâmetro de apresentação. A correção dos mapas é revisão de arte.

Ver [Forja](../art/FORJA.md#luz-facetada-e-aseprite) para o fluxo de autoria e [NOTICE](../../NOTICE.md)
para a atribuição.
