# Empire — personagens completos 64×64 / 80×80 · V11

Oito sprites completos em PNG transparente, cada um com uma pose estática e fonte Aseprite correspondente. Os arquivos individuais têm as dimensões reais abaixo. As prévias usam os mesmos pixels, sem suavização.

| Dimensões do arquivo | Personagens |
| --- | --- |
| 64×64 | Escudeiro, Nia, Bardo, Intendente, Dançarina |
| 80×80 | Rei, Arqueiro, Sombra |

## Arquivos para usar

- `png/`: oito sprites individuais, corpo inteiro, transparência binária.
- `aseprite/`: oito fontes com camadas `arte-base` e `acabamento64-80`, paleta e pivô de apoio nos pés.
- `EMPIRE-ATLAS-1X-V11.png` e `atlas.json`: atlas sem ampliação e retângulos de cada sprite.
- `EMPIRE-CORPOS-COMPLETOS-1X-V11.png`: conferência do conjunto no tamanho real.
- `EMPIRE-CORPOS-COMPLETOS-3X-V11.png`: prévia ampliada exatamente 3×; não é o arquivo de importação.
- `palette/`: paletas GPL.

Os PNGs individuais são os arquivos para importação. As pranchas com nomes têm fundo de apresentação e não substituem os sprites transparentes. Uma pose por personagem; não estão incluídos ciclos de caminhada, ataque ou outras animações. Este pacote não modifica a cena ou o código do jogo.

## Procedência e limite

Este pacote adapta os quatro estudos completos gerados na V10 aos quadros finais. Faz isolamento por transparência, seleção discreta de cores, preservação de contornos e acabamento pontual na grade final. **Não foi desenhado integralmente do zero em 64×64/80×80 pelo gerador.** A dimensão exata do PNG e a edição na grade não mudam essa procedência.

A V9 foi rejeitada pelo autor e não foi usada como base. A V11 trabalha os oito corpos completos a partir dos estudos que retomaram os conceitos apreciados. Preserva o bardo barbudo, a Nia com duas machadinhas, o arqueiro sem barba, o elmo fechado do Sombra e o figurino vinho/sálvia/ouro do par Sombra–dançarina. O PixelLab não foi executado. A avaliação artística da V11 continua sendo do autor.

O requisito técnico de arquivos reais 64×64/80×80 está atendido. A exigência anterior de construção integral originalmente nessas grades não deve ser declarada cumprida por esta adaptação.

## Reprodução e conferência

`source/native-pixels.json` contém as grades literais completas, as paletas, as alterações pontuais e a identificação das imagens de origem. Não depende das imagens grandes para reproduzir os pixels exportados.

Com Node.js, sem instalar dependências:

```sh
node source/render.cjs
```

Com Python 3, apenas biblioteca padrão:

```sh
python3 source/verify.py
```

A conferência compara pixels de PNG, Aseprite e atlas; verifica dimensões, cores e alfa. Ela não substitui a avaliação artística nem significa aprovação para promover os assets ao jogo.
