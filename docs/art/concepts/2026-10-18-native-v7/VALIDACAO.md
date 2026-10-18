# Verificação da V7

- `source/build.py` e `source/verify.py`: PNGs indexados nas dimensões do manifesto, alfa binário, margens, linha de chão, recortes exatos, estados distintos e identidade persistente conferidos.
- Aseprite reabertos com o leitor do projeto: igualdade pixel a pixel com a composição dos PNGs.
- Pranchas revistas visualmente em cor, com os recortes faciais e amostras a 1×. Ajustados olhos/bocas, lâmina de Nia, marcas sobre a manga do escudeiro e visor de Sombra durante a revisão.
- Links Markdown locais e sintaxe JavaScript da galeria conferidos.
- Galeria em browser: não verificada. Playwright está disponível, mas o executável Chromium não está instalado. Não foi instalada uma nova dependência para esta revisão.
- `tools/check_claims.py`, `tools/check_dossie_vs_csv.py` e `tools/content_report.py --check`: aprovados.
- Godot indisponível neste ambiente; a suite integral e o comportamento do jogo não foram executados.

Os verificadores não avaliam beleza, personalidade, fluidez ou aprovação artística. A V7 contém conceitos estáticos, guardados fora dos assets do runtime.
