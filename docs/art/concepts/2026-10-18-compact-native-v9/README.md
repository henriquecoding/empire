# Empire — revisão dos rostos V9 · 18/10/2026

**Estado: rejeitada pelo autor.** Henrique considerou o resultado deformado e esclareceu que pediu personagens completos, não somente rostos. Os arquivos abaixo são preservados como histórico da tentativa; não constituem base aprovada nem entrega concluída. A correção de escopo está em [estudos completos V10](../2026-10-18-complete-character-studies-v10/README.md).

Esta tentativa revisou a construção facial dos sprites V8, a partir da captura e do `Empire Tileset.aseprite` criados por Henrique. O autor considerara V8 melhor, mas pedira aprofundamento sobretudo nos rostos, dentro da elaboração dos personagens inteiros. A restrição da intervenção a sete regiões faciais não atendeu ao pedido.

| Quadro real | Personagens |
| --- | --- |
| 64×64 | Nia, escudeiro, bardo, intendente, dançarina |
| 80×80 | Rei, arqueiro, Sombra |

Os sete rostos visíveis foram alterados por coordenadas inteiras na própria grade final. O elmo fechado do Sombra foi preservado. Barba e bigode do bardo continuam; o arqueiro permanece sem barba. O nariz usa a rampa da pele de cada personagem. A roupa vinho/sálvia/ouro do par Sombra–dançarina é mantida.

## O que mudou

- Rei: dois olhos individualizados, sobrancelhas espessas, ponte e ponta do nariz, dentes agrupados, cavidade da boca, lábio e queixo.
- Escudeiro: expressão sob a aba, olho distante abreviado, nariz com plano inferior e sorriso com lábio separado da mandíbula.
- Nia: pálpebras e direção do olhar, nariz com volume, canto do sorriso e área inferior do rosto.
- Bardo: olhos e nariz integrados à pele, bigode em dois grupos, boca de canto com dentes e cavidade; barba ruiva preservada.
- Arqueiro: remoção da boca em U que parecia um bigode, pálpebra, nariz comprido e sorriso oblíquo.
- Intendente: olhos cansados assimétricos, bolsas, nariz baixo, bigode separado da boca e do lábio.
- Dançarina: dois olhos, ponte nasal, ponta, sorriso curto e queixo.

## Arquivos

`png/` contém os oito PNGs exportados desta tentativa rejeitada, transparentes, com alfa 0/255. `aseprite/` contém os mesmos pixels nas mesmas dimensões: camada `corpo-v8` e camada `rostos-v9`, ambas editáveis, paleta embutida e pivô nos pés. `palette/` contém paletas GPL.

- `EMPIRE-PREVIA-COMPACTA-2X-V9.png`: corpos completos, ampliação inteira 2×.
- `EMPIRE-PREVIA-64-80-V9.png`: os mesmos sprites em 5×.
- `EMPIRE-ROSTOS-PIXELS-V9.png`: recortes dos próprios sprites em 6×.
- `EMPIRE-ROSTOS-COMPARACAO-V8-V9.png`: mesma região facial antes/depois em 6×.
- `EMPIRE-ATLAS-1X-V9.png` e `atlas.json`: sprites em escala real, retângulos e pivôs.
- `ESTUDO-DOS-ROSTOS.md`: observações da fonte do autor, alterações e fontes consultadas.
- `source/native-pixels.json`: grade literal do corpo V8 e alterações faciais por coordenada/cor/motivo.
- `source/faces.cjs`: registro dos grupos de pixels que constroem os rostos V9.
- `verification.json`: conferência técnica, sem atribuir aprovação artística.

## Construção e reprodução

O corpo V8 teve origem nos conceitos compactos gerados e numa adaptação de escala/paleta. Essa procedência permanece registrada; V9 não converte essa etapa anterior em desenho integral do zero. Nesta revisão, os rostos foram redesenhados na grade final; nenhum retrato grande foi reduzido para formar as novas feições. O PixelLab não foi executado.

Com Node.js, sem instalar dependências:

```sh
node source/render.cjs
```

O comando produz PNG, Aseprite, paletas, atlas e manifesto a partir da grade literal. Para reaplicar a edição facial registrada antes de renderizar:

```sh
node source/faces.cjs
node source/render.cjs
```

Verificação independente com Python 3, apenas biblioteca padrão:

```sh
python3 source/verify.py
```

Uma pose estática por personagem. A revisão está em `docs/art/concepts/`; não altera assets de produção, animações ou comportamento do jogo.
