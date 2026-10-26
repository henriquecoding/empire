"""Onde cada quadro fica na tela: o apoio, a origem na celula e o chao comum (auditoria F06).

Separado da extracao (`sheet.py`) porque e outra pergunta: nao "que figura e esta",
mas "onde ela esta em relacao as outras". Deslocamentos de apresentacao (salto,
agachar, flor a crescer) sao do desenho; nunca movem a simulacao.
"""
from __future__ import annotations

from statistics import median
from typing import TYPE_CHECKING

from PIL import Image

from .imageops import foot_point, place

if TYPE_CHECKING:
    from .sheet import Figure

ANCHORS = ("feet", "mass", "bottom", "center")
ALIGNS = ("preserve", "contact", "feet")


def frames(figures: list[Figure], canvas: tuple[int, int], pivot: tuple[int, int], anchor: str = "feet",
           align: str = "feet") -> tuple[list[Image.Image], list[dict]]:
    """As figuras na tela do contrato (auditoria F06).

    - preserve: cada figura fica onde estava na sua celula; uma so translacao para
      toda a prancha leva o chao comum (o pe mais baixo) e o centro mediano dos pes
      ao pivot. Um salto continua 4 px acima; uma passada nao abana o tronco.
    - contact: como preserve, e os quadros com o pe a 1 px do chao assentam nele.
    - feet: cada quadro alinhado pelo seu proprio apoio (o antigo); apaga deslocamentos
      de proposito e a deriva zero que dai sai nao prova nada.
    preserve/contact precisam da origem de cada figura (`Figure.origin`, da grelha pedida).
    """
    if anchor not in ANCHORS:
        raise ValueError(f"ancora desconhecida: {anchor}")
    if align not in ALIGNS:
        raise ValueError(f"alinhamento desconhecido: {align} (use {', '.join(ALIGNS)})")
    keep = align != "feet" and all(f.origin is not None for f in figures)
    points = [anchor_point(f.native, anchor) for f in figures]
    if keep:
        feet = [(f.origin[0] + p[0], f.origin[1] + p[1]) for f, p in zip(figures, points)]
        ground = max(p[1] for p in feet)
        rx = round(median(p[0] for p in feet))
        shift = (pivot[0] - rx, pivot[1] - ground)
    out, report = [], []
    for i, (f, point) in enumerate(zip(figures, points)):
        if keep:
            target = [f.origin[0] + shift[0], f.origin[1] + shift[1]]
            lift = ground - feet[i][1]
            if align == "contact" and 0 < lift <= 1:
                target[1] += lift
            frame, clipped = place(f.native, canvas, (0, 0), tuple(target))
            info = {"origin": list(f.origin), "lift": ground - feet[i][1] - (lift if align == "contact"
                                                                               and 0 < lift <= 1 else 0),
                    "offset": list(target)}
        else:
            frame, clipped = place(f.native, canvas, point, pivot)
            info = {"origin": None, "lift": 0, "offset": [pivot[0] - point[0], pivot[1] - point[1]]}
        out.append(frame)
        report.append({"frame": i, "source_box": list(f.box), "native_size": list(f.native.size),
                       "period": round(f.period, 3), "purity": round(f.purity, 3), "anchor": list(point),
                       "align": align if keep else "feet", **info, "clipped_pixels": clipped, "notes": f.notes})
    return out, report


def _mass_x(img: Image.Image) -> int:
    """O centro de massa horizontal: mais estavel que os pes quando as pernas mexem."""
    alpha = img.getchannel("A")
    xs = [x for y in range(img.height) for x in range(img.width) if alpha.getpixel((x, y)) >= 128]
    return round(sum(xs) / len(xs)) if xs else img.width // 2


def anchor_point(img: Image.Image, anchor: str) -> tuple[int, int]:
    if anchor == "feet":
        return foot_point(img) or (img.width // 2, img.height - 1)
    if anchor == "mass":
        return _mass_x(img), img.height - 1
    if anchor == "bottom":
        return img.width // 2, img.height - 1
    return img.width // 2, img.height // 2


def common_canvas(figures: list[Figure], anchor: str, align: str, margin: int = 2) -> tuple[tuple[int, int],
                                                                                        tuple[int, int]]:
    """Sem tela no contrato: a menor tela onde todas cabem, alinhadas como vao ficar."""
    images = [f.native for f in figures]
    points = [anchor_point(i, anchor) for i in images]
    if align == "feet":
        tops = [(-p[0], -p[1]) for p in points]
        ref = (0, 0)
    else:
        feet = [(f.origin[0] + p[0], f.origin[1] + p[1]) for f, p in zip(figures, points)]
        tops = [f.origin for f in figures]
        ref = (round(median(x for x, _ in feet)), max(y for _, y in feet))
    x0 = min(t[0] for t in tops)
    y0 = min(t[1] for t in tops)
    x1 = max(t[0] + i.width for t, i in zip(tops, images))
    y1 = max(t[1] + i.height for t, i in zip(tops, images))
    x1, y1 = max(x1, ref[0] + 1), max(y1, ref[1] + 1)
    return (x1 - x0 + 2 * margin, y1 - y0 + 2 * margin), (ref[0] - x0 + margin, ref[1] - y0 + margin)
