"""A grade que se mede antes da que se estima, e a que a amostragem desmente.

O `grid.detect` estima o periodo pelas bordas. Duas coisas que ele nao ve, achadas
na forense das imagens publicas da documentacao do PixelLab
(docs/art/research/2026-10-26-pixellab-engenharia-reversa/):

- Uma ampliacao exata por vizinho mais proximo (blocos k x k de uma so cor) mede-se:
  a estimativa deu periodo 4 a um tileset ampliado 2x e devolvia metade da resolucao.
  Mede-se pelas fronteiras: as colunas (e as linhas) onde a imagem muda caem todas
  na mesma fase, a k umas das outras. O periodo e o maximo divisor comum das
  distancias entre elas, e a fase vem com ele. Conferir so blocos a partir do canto
  (a primeira versao) dava uma ampliacao 10x recortada 6 px ao lado como "exata 2x"
  (auditoria de 26/10, A01): numa prancha, todo o recorte esta fora de fase.
- Um sprite nativo com estrutura regular engana a autocorrelacao: um personagem de
  64x64 saiu com periodo 6,1 e 12x11 celulas. Amostrado nessa grade, a pureza das
  celulas cai (0,54); numa ampliacao verdadeira, com ruido e desfoque, fica acima de
  0,96 nas imagens falsas da prova. Abaixo de MIN_PURITY o periodo recusa-se e a
  imagem trata-se como nativa, com a razao escrita. O limiar e provisorio: esta
  calibrado nesses casos, nao num conjunto de imagens reais de geradores.
"""
from __future__ import annotations

from math import gcd

from PIL import Image, ImageChops

from . import grid
from .imageops import CLEAR, flat
from .resample import resample

MIN_PURITY = 0.8


def _changes(rgba: Image.Image) -> list[int]:
    """As colunas x (entre x-1 e x) em que a imagem muda em alguma linha."""
    w, h = rgba.size
    if w < 2:
        return []
    diff = ImageChops.difference(rgba.crop((0, 0, w - 1, h)), rgba.crop((1, 0, w, h)))
    seen = None
    for band in diff.split():
        seen = band if seen is None else ImageChops.lighter(seen, band)
    hit = seen.point(lambda v: 255 if v else 0).convert("F").resize((w - 1, 1), Image.Resampling.BOX)
    return [x + 1 for x, v in enumerate(flat(hit)) if v > 0]


def exact_grid(image: Image.Image) -> tuple[int, tuple[int, int]]:
    """(k, (fase x, fase y)) de uma ampliacao exata k x k, ou (1, (0, 0)) se nao o e.

    O vazio conta como uma cor so: a cor escondida num pixel transparente nao e desenho."""
    rgba = image.convert("RGBA")
    clean = Image.new("RGBA", rgba.size, CLEAR)
    clean.paste(rgba, (0, 0), rgba.getchannel("A").point(lambda a: 255 if a else 0))
    xs, ys = _changes(clean), _changes(clean.transpose(Image.Transpose.TRANSPOSE))
    if not xs and not ys:  # lisa (o vazio que o gerador devolveu): e ampliacao de qualquer k; fica o de antes
        w, h = rgba.size
        return next((k for k in range(16, 1, -1) if w % k == 0 and h % k == 0), 1), (0, 0)
    if len(xs) < 2 or len(ys) < 2:
        return 1, (0, 0)
    k = 0
    for cuts in (xs, ys):
        for a, b in zip(cuts, cuts[1:]):
            k = gcd(k, b - a)
    if k < 2:
        return 1, (0, 0)
    return k, (xs[0] % k, ys[0] % k)


def exact_scale(image: Image.Image) -> int:
    """O maior k em que a imagem e uma ampliacao exata k x k, em qualquer fase (1: nenhuma)."""
    return exact_grid(image)[0]


def _cuts(n: int, k: int, phase: int) -> list[int]:
    return sorted({0, n, *range(phase, n, k)})


def detect(image: Image.Image, scale: float | None = None, cells: tuple[int, int] | None = None) -> grid.Grid:
    """Como `grid.detect`; sem escala nem celulas dadas, mede primeiro e confere depois."""
    if scale or cells:
        return grid.detect(image, scale=scale, cells=cells)
    k, (ox, oy) = exact_grid(image)
    if k > 1:
        w, h = image.size
        phase = f", fase ({ox},{oy})" if ox or oy else ""
        return grid.Grid(_cuts(w, k, ox), _cuts(h, k, oy), (k, k), 1.0, False,
                         [f"ampliacao exata {k}x{phase}: medida, nao estimada"])
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
