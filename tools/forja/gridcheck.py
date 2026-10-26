"""A grade que se mede antes da que se estima, e a que a amostragem desmente.

O `grid.detect` estima o periodo pelas bordas. Duas coisas que ele nao ve, achadas
na forense das imagens publicas da documentacao do PixelLab
(docs/art/research/2026-10-26-pixellab-engenharia-reversa/):

- Uma ampliacao exata por vizinho mais proximo (blocos k x k de uma so cor) mede-se:
  a estimativa deu periodo 4 a um tileset ampliado 2x e devolvia metade da resolucao.
- Um sprite nativo com estrutura regular engana a autocorrelacao: um personagem de
  64x64 saiu com periodo 6,1 e 12x11 celulas. Amostrado nessa grade, a pureza das
  celulas cai (0,54); numa ampliacao verdadeira, com ruido e desfoque, fica acima de
  0,96 nas imagens falsas da prova. Abaixo de MIN_PURITY o periodo recusa-se e a
  imagem trata-se como nativa, com a razao escrita. O limiar e provisorio: esta
  calibrado nesses casos, nao num conjunto de imagens reais de geradores.
"""
from __future__ import annotations

from PIL import Image

from . import grid
from .resample import resample

MIN_PURITY = 0.8
MAX_EXACT = 16


def exact_scale(image: Image.Image) -> int:
    """O maior k em que a imagem e uma ampliacao exata k x k (1: nenhuma)."""
    rgba = image.convert("RGBA")
    w, h = rgba.size
    raw = rgba.tobytes()
    for k in range(MAX_EXACT, 1, -1):
        if w % k or h % k:
            continue
        if rgba.resize((w // k, h // k), Image.NEAREST).resize((w, h), Image.NEAREST).tobytes() == raw:
            return k
    return 1


def detect(image: Image.Image, scale: float | None = None, cells: tuple[int, int] | None = None) -> grid.Grid:
    """Como `grid.detect`; sem escala nem celulas dadas, mede primeiro e confere depois."""
    if scale or cells:
        return grid.detect(image, scale=scale, cells=cells)
    k = exact_scale(image)
    if k > 1:
        exact = grid.known(image.size, k)
        exact.native, exact.notes = False, [f"ampliacao exata {k}x: medida, nao estimada"]
        return exact
    found = grid.detect(image)
    if found.native:
        return found
    purity = resample(image, found).purity
    if purity >= MIN_PURITY:
        return found
    w, h = image.size
    return grid.Grid(list(range(w + 1)), list(range(h + 1)), (1.0, 1.0), 0.0, True, [
        f"periodo {found.period[0]:.2f} recusado: pureza das celulas {purity:.2f} < {MIN_PURITY}; tratada "
        "como pixel art nativa (escala 1). Se for uma ampliacao, de --scale ou --cells"])
