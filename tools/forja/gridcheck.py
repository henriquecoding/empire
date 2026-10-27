"""A grade que se mede antes da que se estima, e a que a amostragem desmente.

O `grid.detect` estima o periodo pelas bordas. Duas coisas que ele nao ve, achadas
na forense das imagens publicas da documentacao do PixelLab
(docs/art/research/2026-10-26-pixellab-engenharia-reversa/):

- Uma ampliacao exata por vizinho mais proximo (blocos k x k de uma so cor) mede-se, em
  vez de se estimar: a estimativa falha numa ampliacao 2x pequena (test_gridcheck). (A forense
  de 26/10 deu o tileset da documentacao como 2x, e a estimativa de periodo 4 como erro; nos
  pixels visiveis ele e 4x — o "2x" vinha da cor escondida debaixo do alfa 0. Auditoria, O1.)
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

A origem da grade vai escrita (FORJA-07; auditoria de 27/10, §3.4, §13 e §14): `exactly_measured` (ampliacao exata),
`estimated`, `operator_declared` (--scale/--cells: o operador sabe; nao e evidencia independente de autoria nativa),
`deliberately_reduced` (--reduce, ou uma grade dada mais grossa do que a ampliacao exata medida: adaptacao com perda,
nunca recuperacao fiel) e `unmeasured` (nada medido; tratada a 1x). `report` separa o que a grade prova (o periodo)
do que a amostragem prova (os valores dos pixels), diz se o recuperado cabe na tela e onde a imagem tem escala mais
fina: a grade que explica todos os pixels pode exceder o orcamento do jogo, e reduzir entao e desenho.
"""
from __future__ import annotations

from collections import Counter
from math import gcd

from PIL import Image, ImageChops

from . import grid
from .imageops import CLEAR, flat
from .resample import resample

MIN_PURITY = 0.8
ORIGINS = ("exactly_measured", "estimated", "operator_declared", "deliberately_reduced", "unmeasured")
LOSSY = ("JPEG", "MPO", "WEBP", "JPEG2000")


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


def _clean(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    clean = Image.new("RGBA", rgba.size, CLEAR)
    clean.paste(rgba, (0, 0), rgba.getchannel("A").point(lambda a: 255 if a else 0))
    return clean


def exact_grid(image: Image.Image) -> tuple[int, tuple[int, int]]:
    """(k, (fase x, fase y)) de uma ampliacao exata k x k, ou (1, (0, 0)) se nao o e.

    O vazio conta como uma cor so: a cor escondida num pixel transparente nao e desenho (o tileset da forense de
    26/10 e 4x no que se ve e so "2x" com as 508 cores escondidas debaixo do alfa 0)."""
    rgba = image.convert("RGBA")
    clean = _clean(rgba)
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
    return (k, (xs[0] % k, ys[0] % k)) if k > 1 else (1, (0, 0))


def exact_scale(image: Image.Image) -> int:
    """O maior k em que a imagem e uma ampliacao exata k x k, em qualquer fase (1: nenhuma)."""
    return exact_grid(image)[0]


def _cuts(n: int, k: int, phase: int) -> list[int]:
    return sorted({0, n, *range(phase, n, k)})


def phased(size: tuple[int, int], k: int, phase: tuple[int, int], note: str = "") -> grid.Grid:
    """A grade exata k x k com fase, conhecida (as celulas das pontas podem ser parciais)."""
    where = f", fase ({phase[0]},{phase[1]})" if any(phase) else ""
    return grid.Grid(_cuts(size[0], k, phase[0]), _cuts(size[1], k, phase[1]), (k, k), 1.0, False,
                     [f"ampliacao exata {k}x{where}{note}: medida, nao estimada"], "exactly_measured")


def declared(image: Image.Image, g: grid.Grid, reduce: bool = False) -> grid.Grid:
    """A grade que o operador deu, contra a ampliacao exata medida: confirmada, reduzida ou so declarada."""
    k, _ = exact_grid(image)
    period = max(g.period)
    if reduce:
        g.origin, note = "deliberately_reduced", "reducao declarada (--reduce): adaptacao com perda, nao recuperacao"
    elif k > 1 and period > 1.05 * k:
        g.origin = "deliberately_reduced"
        note = (f"a imagem e uma ampliacao exata {k}x ({image.width // k}x{image.height // k} celulas) e a grade dada "
                f"({period:.2f}) e mais grossa: reducao, nao recuperacao fiel")
    elif k > 1 and abs(period - k) <= 0.05 * k:
        g.origin, note = "operator_declared", f"dada e confirmada pela medicao (ampliacao exata {k}x)"
    else:
        note = "dada pelo operador e nao confirmada pela medicao: nao e evidencia de autoria nativa nesta grade"
    g.notes = g.notes + [note]
    return g


def measure(image: Image.Image, scale: float | None = None, cells: tuple[int, int] | None = None,
            reduce: bool = False) -> tuple[grid.Grid, object | None]:
    """A grade e, quando a conferencia ja a amostrou pelo voto dominante, essa amostragem (o `forge` nao a refaz)."""
    if reduce and not (scale or cells):
        raise ValueError("--reduce pede a grade da reducao: --scale ou --cells")
    if scale or cells:
        return declared(image, grid.detect(image, scale=scale, cells=cells), reduce), None
    k, phase = exact_grid(image)
    if k > 1:
        return phased(image.size, k, phase), None
    found = grid.detect(image)
    if found.native:
        return found, None
    sampled = resample(image, found)
    if sampled.purity >= MIN_PURITY:
        return found, sampled
    w, h = image.size
    return grid.Grid(list(range(w + 1)), list(range(h + 1)), (1.0, 1.0), 0.0, True, [
        f"periodo {found.period[0]:.2f} recusado: pureza das celulas {sampled.purity:.2f} < {MIN_PURITY}; nao se "
        "conseguiu medir a grade e a imagem fica a escala 1. Se a origem e uma ampliacao conhecida, de --scale; se a "
        "escolha e reduzir para caber, e adaptacao: --cells com --reduce (sai marcada como reducao)"],
        "unmeasured"), None


def detect(image: Image.Image, scale: float | None = None, cells: tuple[int, int] | None = None,
           reduce: bool = False) -> grid.Grid:
    """Como `grid.detect`; sem escala nem celulas dadas, mede primeiro e confere depois."""
    return measure(image, scale, cells, reduce)[0]


def mixed(image: Image.Image) -> dict | None:
    """Numa ampliacao exata k x k em que quase todas as fronteiras caem numa grade P mais grossa (P multiplo de k):
    P, e as zonas (caixas na imagem de entrada) que so a grade fina explica — o desenho com escalas misturadas."""
    clean = _clean(image)
    k, _ = exact_grid(clean)
    xs, ys = _changes(clean), _changes(clean.transpose(Image.Transpose.TRANSPOSE))
    gaps = Counter(b - a for cuts in (xs, ys) for a, b in zip(cuts, cuts[1:]))
    if k <= 1 or not gaps:
        return None
    top = max(gaps.items(), key=lambda t: (t[1], t[0]))[0]
    if top <= k or top % k:
        return None
    phase = tuple(Counter(c % top for c in cuts).most_common(1)[0][0] if cuts else 0 for cuts in (xs, ys))
    coarse = phased(clean.size, top, phase)
    fine = []
    for j in range(coarse.size[1]):
        for i in range(coarse.size[0]):
            box = (coarse.xs[i], coarse.ys[j], coarse.xs[i + 1], coarse.ys[j + 1])
            if len(clean.crop(box).getcolors((box[2] - box[0]) * (box[3] - box[1])) or [0, 0]) > 1:
                fine.append(box)
    return {"coarse_period": top, "fine_period": k, "coarse_cells": list(coarse.size), "fine_cells": len(fine),
            "zones": [list(b) for b in fine[:12]]}


def report(image: Image.Image, g: grid.Grid, native_size, canvas, fmt: str | None = None) -> dict:
    """A grade com as afirmacoes separadas: de onde veio, o que recuperou, se os valores dos pixels sao copia das
    celulas da entrada ou amostragem, se cabe na tela do contrato e, numa ampliacao exata, onde a escala e mais fina.
    Uma entrada com perdas (JPEG) pode dar uma grade exata (blocos alinhados com os da compressao) e cores que nao
    sao as originais: as duas afirmacoes ficam separadas (auditoria de 27/10, §14.2)."""
    exact = g.origin == "exactly_measured"
    values = "copied_from_input" if exact else ("native_pixels" if g.native else "sampled_not_proven_exact")
    lossy = (fmt or "").upper() in LOSSY
    fits = None if not canvas else all(n <= c for n, c in zip(native_size, canvas))
    out = {"origin": g.origin, "period": [round(v, 3) for v in g.period], "input_size": list(image.size),
           "recovered_cells": list(g.size), "native_size": list(native_size), "exact_upscale": exact,
           "pixel_values": values, "target_canvas": list(canvas) if canvas else None, "fits_target": fits,
           "mixed_scale": mixed(image) if exact else None,
           "evidence_of_native_authorship": exact, "input_format": fmt, "lossy_input": lossy,
           "original_colors": "not_provable_lossy_input" if lossy else ("input_cells" if exact else "sampled"),
           "note": "confidence e a forca da grade, nao a fidelidade ao personagem"}
    if g.origin == "deliberately_reduced":
        out["evidence_of_native_authorship"] = False
        out["note"] = "reducao deliberada: a saida nao prova recuperacao fiel"
    return out
