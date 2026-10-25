"""O que a revisao precisa de ver: a imagem a 1x e ampliada, com as regioes observadas e as ancoras (FORJA-03).

Cada regiao e contornada com uma cor da legenda, celula a celula; cada ancora e uma cruz. A ampliacao e
inteira (Nearest): serve para diagnosticar; a leitura decide-se a 1x, que vai sempre ao lado.
"""
from __future__ import annotations

from PIL import Image, ImageDraw, ImageFont

from .imageops import on_background, upscale

TINTS = ((255, 72, 72), (72, 168, 255), (255, 210, 0), (90, 230, 130), (225, 90, 255), (255, 150, 30),
         (0, 225, 225), (255, 255, 255))
BG = (52, 58, 72)


def overlay(image: Image.Image, regions: dict, anchors: dict, k: int = 8) -> Image.Image:
    font = ImageFont.load_default()
    names = sorted(regions)
    big = on_background(upscale(image.convert("RGBA"), k), BG)
    legend_h = 14 * len(names) + 14 * bool(anchors) + 8
    out = Image.new("RGBA", (big.width, big.height + legend_h), (*BG, 255))
    out.alpha_composite(big)
    draw = ImageDraw.Draw(out)
    for i, name in enumerate(names):
        tint, region = TINTS[i % len(TINTS)], regions[name]
        for x, y in region:
            x0, y0, x1, y1 = x * k, y * k, x * k + k - 1, y * k + k - 1
            for (dx, dy), edge in (((0, -1), (x0, y0, x1, y0)), ((0, 1), (x0, y1, x1, y1)),
                                   ((-1, 0), (x0, y0, x0, y1)), ((1, 0), (x1, y0, x1, y1))):
                if (x + dx, y + dy) not in region:
                    draw.line(edge, fill=(*tint, 255), width=2)
        ly = big.height + 4 + 14 * i
        draw.rectangle((6, ly + 2, 16, ly + 11), fill=(*tint, 255))
        draw.text((22, ly), f"{name} ({len(region)} px)", fill=(235, 235, 235, 255), font=font)
    for name, (x, y) in anchors.items():
        cx, cy, r = x * k + k // 2, y * k + k // 2, max(3, k // 2)
        for width, fill in ((4, (0, 0, 0, 255)), (2, (255, 255, 255, 255))):
            draw.line((cx - r, cy, cx + r, cy), fill=fill, width=width)
            draw.line((cx, cy - r, cx, cy + r), fill=fill, width=width)
    if anchors:
        draw.text((6, big.height + 4 + 14 * len(names)), "+ ancoras: " + ", ".join(sorted(anchors)),
                  fill=(235, 235, 235, 255), font=font)
    return out


def strip(images: list[Image.Image], labels: list[str], k: int = 8, gap: int = 16) -> Image.Image:
    """Lado a lado, cada imagem a 1x por cima da ampliada, com a legenda: o antes e o depois."""
    font = ImageFont.load_default()
    tiles = []
    for img in images:
        img = img.convert("RGBA")
        tile = Image.new("RGBA", (img.width * k, img.height * (k + 1) + gap + 16), (*BG, 255))
        tile.alpha_composite(on_background(img, BG), (0, 16))
        tile.alpha_composite(on_background(upscale(img, k), BG), (0, img.height + gap + 16))
        tiles.append(tile)
    w = sum(t.width for t in tiles) + gap * (len(tiles) + 1)
    out = Image.new("RGBA", (w, max(t.height for t in tiles) + gap), (*BG, 255))
    draw = ImageDraw.Draw(out)
    x = gap
    for tile, label in zip(tiles, labels):
        out.alpha_composite(tile, (x, gap // 2))
        draw.text((x + images[0].width + 8, gap // 2 + 2), label, fill=(235, 235, 235, 255), font=font)
        x += tile.width + gap
    return out
