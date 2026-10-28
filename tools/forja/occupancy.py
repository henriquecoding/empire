"""Tela, caixa util e vazio exterior sao medidas diferentes. Nenhuma contagem decide redesenhar pixels."""
from __future__ import annotations

from PIL import Image

from .imageops import opaque_bbox


def measure(image: Image.Image, canvas: tuple[int, int] | None = None) -> dict:
    box = opaque_bbox(image)
    alpha = image.convert('RGBA').getchannel('A').histogram()
    pixels = sum(alpha[128:])
    useful = [box[2] - box[0], box[3] - box[1]] if box else [0, 0]
    margins = (dict(left=box[0], top=box[1], right=image.width - box[2], bottom=image.height - box[3])
               if box else dict(left=image.width, top=image.height, right=0, bottom=0))
    return {'canvas': list(image.size), 'alpha_threshold': 128, 'opaque_bbox': list(box) if box else None,
            'useful_size': useful, 'clear_margins': margins, 'opaque_pixels': pixels,
            'empty_pixels_inside_bbox': useful[0] * useful[1] - pixels,
            'fits_canvas': all(v <= n for v, n in zip(useful, canvas)) if canvas else None,
            'target_canvas': list(canvas) if canvas else None,
            'note': 'vazio interior nao e margem removivel; a caixa util mede a extensao do desenho'}
