"""Editar uma regiao de um sprite com um gerador, sem tocar no resto.

1. O sprite nativo e ampliado k vezes (k conhecido) e vai com uma mascara cujo
   alfa 0 marca a caixa a mudar.
2. A resposta volta a 1x pela grade CONHECIDA — nao ha nada a detetar.
3. Fora da caixa ficam os pixels originais, byte a byte; dentro, os novos,
   levados a paleta. E o conselho da propria OpenAI ("se uma regiao tem de ficar
   identica, compoe a edicao aprovada sobre o original"), feito sempre.
"""
from __future__ import annotations

import io

from PIL import Image

from . import grid as gridmod, matte, prompts, quantize, resample
from .imageops import CLEAR, flat, upscale
from .palette import Palette, from_image


def _png(image: Image.Image) -> bytes:
    buf = io.BytesIO()
    image.save(buf, "PNG")
    return buf.getvalue()


def prepare(native: Image.Image, box: tuple[int, int, int, int], key: str | None = None,
            target: str = "gpt-image") -> tuple[bytes, bytes, int, str]:
    """(imagem, mascara, k, tamanho) prontos para a edicao."""
    _validate_box(native, box)
    k = prompts.pick_scale(native.width, native.height, target)
    big = upscale(native, k)
    if key:
        base = Image.new("RGBA", big.size, key)
        base.alpha_composite(big)
        big = base
    mask = Image.new("RGBA", big.size, (0, 0, 0, 255))
    mask.paste(CLEAR, (box[0] * k, box[1] * k, box[2] * k, box[3] * k))
    return _png(big), _png(mask), k, f"{big.width}x{big.height}"


def merge(native: Image.Image, result: Image.Image, k: int, box: tuple[int, int, int, int],
          palette: Palette | None = None, key: str | None = None) -> tuple[Image.Image, dict]:
    _validate_box(native, box)
    if result.size != (native.width * k, native.height * k):
        raise ValueError("edicao devolvida fora da tela pedida; nao redimensionar")
    g = gridmod.known(result.size, k)
    fresh = resample.resample(result, g, "dominant").image
    fresh, _ = matte.remove(fresh, key) if key else (fresh, None)
    pal = palette if palette is not None and len(palette) else from_image(native)
    fresh = quantize.to_palette(fresh, pal)
    out = native.convert("RGBA").copy()
    region = fresh.crop(box)
    out.paste(CLEAR, box)
    out.alpha_composite(region, (box[0], box[1]))
    changed = sum(1 for a, b in zip(flat(native.convert("RGBA").crop(box)), flat(out.crop(box))) if a != b)
    return out, {"scale": k, "box": list(box), "changed_pixels": changed,
                 "outside_identical": _outside_equal(native, out, box)}


def _validate_box(native: Image.Image, box: tuple[int, int, int, int]) -> None:
    if not (0 <= box[0] < box[2] <= native.width and 0 <= box[1] < box[3] <= native.height):
        raise ValueError("mascara deve ser uma caixa nao vazia dentro da tela")


def _outside_equal(a: Image.Image, b: Image.Image, box: tuple[int, int, int, int]) -> bool:
    x = a.convert("RGBA").copy()
    y = b.convert("RGBA").copy()
    x.paste(CLEAR, box)
    y.paste(CLEAR, box)
    return x.tobytes() == y.tobytes()


def run(native: Image.Image, box: tuple[int, int, int, int], change: str, palette: Palette | None = None,
        references: list[bytes] | None = None, transport=None, model: str | None = None) -> tuple[Image.Image, dict]:
    """Com o gpt-image: pede a edicao e devolve o sprite com so a caixa mudada."""
    from .backends import openai_images
    key = None
    image, mask, k, size = prepare(native, box, key)
    answer = openai_images.edit(prompts.edit_prompt(change), [image] + (references or []), mask, size,
                                model=model, transport=transport, background="transparent")
    if not answer["images"]:
        raise RuntimeError("o gerador nao devolveu imagem")
    with Image.open(io.BytesIO(answer["images"][0])) as im:
        result = im.convert("RGBA")
    out, info = merge(native, result, k, box, palette, key)
    info["model"] = answer["model"]
    return out, info
