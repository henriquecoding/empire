# Empire — personagens compactos V8 · 18/10/2026

Adaptação dos novos conceitos que Henrique apreciou nesta conversa. Mantida a versão do bardo com barba e bigode. Sombra e dançarina passam a compartilhar vinho, verde sálvia e ouro envelhecido: a dançarina conserva a roupa verde e a leveza; suas fitas e faixa passam a vinho. O forro verde da capa de Sombra repete a cor dela.

## Arquivos e dimensões

| Quadro | Personagens |
| --- | --- |
| 64×64 | Nia, escudeiro, bardo, intendente, dançarina |
| 80×80 | Rei, arqueiro, Sombra |

- `png/`: oito PNGs RGBA, fundo transparente e alfa apenas 0/255.
- `aseprite/`: oito arquivos com o mesmo quadro e os mesmos pixels do PNG. Camadas `corpo` e `acabamento-nativo`, paleta embutida e pivô dos pés.
- `palette/`: paletas GPL. Sombra e dançarina compartilham a mesma paleta de construção.
- `source/native-pixels.json`: grade editável literal, com uma entrada por pixel, paleta e correções identificadas por coordenadas inteiras.
- `EMPIRE-PREVIA-64-80-V8.png`: os próprios PNGs ampliados exatamente 5×, sem suavização.
- `EMPIRE-ROSTOS-PIXELS-V8.png`: recortes dos rostos dos mesmos PNGs, sem redesenhar retratos.
- `EMPIRE-ATLAS-1X-V8.png` e `atlas.json`: quadro de comparação/atlas em escala 1×, com retângulo e pivô de cada personagem.
- `verification.json`: dimensões, alfa, paleta e comparação independente dos pixels de PNG, Aseprite e atlas.

É uma pose estática por personagem. Não inclui ciclos de animação ou alteração dos assets do jogo.

## Como foi construído

As pranchas aprovadas são a referência de identidade. A harmonização do par e os recortes transparentes foram feitos com a ferramenta de imagens disponível nesta conversa. Não foi executado o PixelLab.

A inicialização dos rasters pequenos usa agrupamento perceptual de cores e votação por área na resolução final, mantendo as proporções compactas dos conceitos. Em seguida foram corrigidos olhos, pupilas, sorrisos, nariz e bigode diretamente nas grades pequenas. Essas alterações estão em `nativeEdits`, com coordenadas, cor e motivo, e na camada `acabamento-nativo`.

Os arquivos entregues têm resolução e fonte editável reais de 64×64 ou 80×80. Isso não significa que o modelo tenha desenhado diretamente um bitmap pequeno nem que a adaptação tenha sido desenhada do zero: a origem gerada e a etapa de reamostragem estão explicitadas no manifesto. O controle de integridade não substitui a avaliação visual do autor.

## Reprodução das fontes finais

Com Node.js, sem instalar dependências:

```sh
node source/render.cjs
```

O comando gera PNGs, arquivos Aseprite, paletas e manifesto a partir da grade literal; não usa imagens grandes nem redimensiona na etapa de reprodução. `finish.cjs` registra/reaplica o acabamento desta versão; não é necessário executá-lo para renderizar uma grade já editada.

Verificação independente com Python 3, apenas biblioteca padrão:

```sh
python3 source/verify.py
```

Referência do formato editável: [especificação oficial Aseprite](https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md).

## Estado de revisão

O autor apreciou os conceitos grandes e escolheu o bardo barbudo. Pediu a harmonização do par e os tamanhos finais de 64/80. A adaptação pequena desta entrega não recebeu aprovação automática por isso. Os PNGs e as fontes estão preparados para avaliação e continuidade; não foram promovidos a assets de produção.
