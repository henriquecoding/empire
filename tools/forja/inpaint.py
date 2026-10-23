"""Editar uma regiao de um sprite com um gerador, sem tocar no resto (auditoria F04).

1. O sprite nativo e ampliado k vezes (k conhecido) sobre uma cor de chave que
   NAO existe no sprite nem na paleta (a mais longe de todas, escrita no relatorio),
   e vai com uma mascara cujo alfa 0 marca a caixa a mudar (convencao da OpenAI;
   internamente, 1 = editavel).
2. A resposta tem de vir no tamanho pedido: outro tamanho e erro, nao se estica.
   Volta a 1x pela grade CONHECIDA. Se a resposta traz alfa real, usa-se o alfa;
   senao, a chave.
3. Fora da caixa ficam os pixels originais, byte a byte. Dentro, cada celula que
   o gerador devolveu igual ao que recebeu fica com os bytes originais (um eco
   reconstroi o sprite exatamente, azul e transparencia incluidos); so as celulas
   mudadas sao levadas a paleta. E o conselho da propria OpenAI ("se uma regiao tem
   de ficar identica, compoe a edicao aprovada sobre o original"), feito sempre.
"""
from __future__ import annotations

import io
import itertools

from PIL import Image

from . import color, grid as gridmod, matte, prompts, quantize, resample
from .imageops import CLEAR, binarize, flat, png_bytes, upscale
from .palette import Palette, from_image

_EXTRA = tuple("#%02X%02X%02X" % c for c in itertools.product((0, 128, 255), repeat=3))


def key_for(colors: list[tuple[int, int, int]]) -> tuple[str, float]:
    """A cor de chave mais longe de todas as cores dadas, e essa distancia (OKLab)."""
    used = list(dict.fromkeys(colors))
    if not used:
        return matte.KEYS[0], 1.0
    candidates = list(dict.fromkeys(matte.KEYS + _EXTRA))
    best = max(candidates, key=lambda k: min(color.delta(color.parse_hex(k), c) for c in used))
    return best, round(min(color.delta(color.parse_hex(best), c) for c in used), 4)


def _check_box(native: Image.Image, box: tuple[int, int, int, int]) -> None:
    x0, y0, x1, y1 = box
    if not (0 <= x0 < x1 <= native.width and 0 <= y0 < y1 <= native.height):
        raise ValueError(f"caixa {tuple(box)} vazia ou fora do sprite {native.size}")


def _used(native: Image.Image, palette: Palette | None) -> list[tuple[int, int, int]]:
    return [p[:3] for p in flat(native.convert("RGBA")) if p[3]] + (list(palette.colors) if palette else [])


def prepare(native: Image.Image, box: tuple[int, int, int, int], key: str | None = None,
            target: str = "gpt-image", palette: Palette | None = None) -> tuple[bytes, bytes, int, str, str]:
    """(imagem, mascara, k, tamanho, chave) prontos para a edicao."""
    _check_box(native, box)
    key = key or key_for(_used(native, palette))[0]
    k = prompts.pick_scale(native.width, native.height, target)
    base = Image.new("RGBA", (native.width * k, native.height * k), key)
    base.alpha_composite(upscale(native.convert("RGBA"), k))
    mask = Image.new("RGBA", base.size, (0, 0, 0, 255))
    mask.paste(CLEAR, (box[0] * k, box[1] * k, box[2] * k, box[3] * k))
    return png_bytes(base), png_bytes(mask), k, f"{base.width}x{base.height}", key


def merge(native: Image.Image, result: Image.Image, k: int, box: tuple[int, int, int, int],
          palette: Palette | None = None, key: str | None = None) -> tuple[Image.Image, dict]:
    _check_box(native, box)
    native = native.convert("RGBA")
    want = (native.width * k, native.height * k)
    if result.size != want:
        raise ValueError(f"a edicao voltou com {result.size[0]}x{result.size[1]}, pedida {want[0]}x{want[1]}: "
                         "nao se estica nem se adivinha a grade")
    sampled = resample.resample(result.convert("RGBA"), gridmod.known(result.size, k), "dominant").image
    alpha_mode = any(p[3] < 255 for p in flat(sampled))
    if alpha_mode:
        fresh = binarize(sampled)
    else:
        fresh = matte.remove(sampled, key)[0] if key else sampled
    sent = Image.new("RGBA", native.size, key or (0, 0, 0, 0))
    sent.alpha_composite(native)
    src, raw, gen, echo = native.load(), sampled.load(), fresh.load(), sent.load()
    cells = [(x, y) for y in range(box[1], box[3]) for x in range(box[0], box[2])
             if raw[x, y] != echo[x, y] and not (gen[x, y][3] < 128 and src[x, y][3] == 0)]
    out = native.copy()
    if cells:
        pal = palette if palette is not None and len(palette) else from_image(native)
        patch = Image.new("RGBA", native.size, CLEAR)
        for x, y in cells:
            patch.putpixel((x, y), gen[x, y])
        patch = quantize.to_palette(patch, pal).load()
        for x, y in cells:
            out.putpixel((x, y), patch[x, y] if patch[x, y][3] >= 128 else CLEAR)
    changed = sum(1 for x, y in cells if out.getpixel((x, y)) != src[x, y])
    cleared = sum(1 for x, y in cells if gen[x, y][3] < 128 and src[x, y][3] >= 128)
    return out, {"scale": k, "box": list(box), "key": key, "matte": "alpha" if alpha_mode else "key",
                 "cells_returned_different": len(cells), "changed_pixels": changed, "became_transparent": cleared,
                 "outside_identical": _outside_equal(native, out, box),
                 "mask_convention": "openai: alfa 0 = editar (internamente 1 = editavel)"}


def _outside_equal(a: Image.Image, b: Image.Image, box: tuple[int, int, int, int]) -> bool:
    x = a.convert("RGBA").copy()
    y = b.convert("RGBA").copy()
    x.paste(CLEAR, box)
    y.paste(CLEAR, box)
    return x.tobytes() == y.tobytes()


def run(native: Image.Image, box: tuple[int, int, int, int], change: str, palette: Palette | None = None,
        references: list[bytes] | None = None, transport=None, model: str | None = None,
        folder=None, budget=None) -> tuple[Image.Image, dict]:
    """Com o gpt-image: pede a edicao (job duravel) e devolve o sprite com so a caixa mudada."""
    from .backends import openai_images
    image, mask, k, size, key = prepare(native, box, palette=palette)
    roles = ["edit_target"] + ["identity"] * len(references or [])
    answer = openai_images.edit(prompts.edit_prompt(change), [image] + (references or []), mask, size,
                                model=model, transport=transport, folder=folder, budget=budget, roles=roles)
    with Image.open(io.BytesIO(answer["images"][0])) as im:
        result = im.convert("RGBA")
    out, info = merge(native, result, k, box, palette, key)
    info["key_distance"] = key_for(_used(native, palette))[1]
    info["model"], info["job"] = answer["model"], answer["job"]["id"]
    return out, info
