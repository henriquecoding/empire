"""Editar uma regiao de um sprite com um gerador, sem tocar no resto (auditoria F04).

1. O sprite nativo e ampliado k vezes (k conhecido) sobre uma cor de chave que
   NAO existe no sprite nem na paleta (a mais longe de todas, escrita no relatorio),
   e vai com uma mascara cujo alfa 0 marca a caixa a mudar (convencao da OpenAI;
   internamente, 1 = editavel).
   A zona pode ser uma caixa ou uma mascara qualquer (FORJA-03), na convencao do gerador.
2. A resposta tem de vir no tamanho pedido: outro tamanho e erro, nao se estica.
   Volta a 1x pela grade CONHECIDA. Se a resposta traz alfa real, usa-se o alfa;
   senao, a chave.
3. Fora da caixa ficam os pixels originais, byte a byte. Dentro, cada celula que
   o gerador devolveu igual ao que recebeu fica com os bytes originais (um eco
   reconstroi o sprite exatamente, azul e transparencia incluidos); so as celulas
   mudadas sao levadas a paleta. E o conselho da propria OpenAI ("se uma regiao tem
   de ficar identica, compoe a edicao aprovada sobre o original"), feito sempre.
4. A composicao declara o metodo (add, replace, remove), recusa mascaras que cobrem regioes
   protegidas e diz se o objeto antigo continua visivel (compose.py).
"""
from __future__ import annotations

import io
import itertools

from PIL import Image

from . import color, compose, grid as gridmod, masks, matte, prompts, quantize, resample
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


def editable(native: Image.Image, box=None, region=None) -> frozenset:
    """A zona a editar: a mascara dada ou a caixa."""
    if region is not None:
        region = frozenset(region)
        if not region or any(not (0 <= x < native.width and 0 <= y < native.height) for x, y in region):
            raise ValueError(f"mascara vazia ou fora do sprite {native.size}")
        return region
    if box is None:
        raise ValueError("diga a caixa ou a mascara a editar")
    _check_box(native, box)
    return masks.box(box)


def _used(native: Image.Image, palette: Palette | None) -> list[tuple[int, int, int]]:
    return [p[:3] for p in flat(native.convert("RGBA")) if p[3]] + (list(palette.colors) if palette else [])


def prepare(native: Image.Image, box: tuple[int, int, int, int] | None, key: str | None = None,
            target: str = "gpt-image", palette: Palette | None = None, region=None,
            convention: str = "openai") -> tuple[bytes, bytes, int, str, str]:
    """(imagem, mascara, k, tamanho, chave) prontos para a edicao."""
    zone = editable(native, box, region)
    key = key or key_for(_used(native, palette))[0]
    k = prompts.pick_scale(native.width, native.height, target)
    base = Image.new("RGBA", (native.width * k, native.height * k), key)
    base.alpha_composite(upscale(native.convert("RGBA"), k))
    mask = masks.to_png(native.size, zone, convention, k)
    return png_bytes(base), mask, k, f"{base.width}x{base.height}", key


def merge(native: Image.Image, result: Image.Image, k: int, box: tuple[int, int, int, int] | None,
          palette: Palette | None = None, key: str | None = None, region=None, method: str = "replace",
          protect=frozenset(), old=frozenset()) -> tuple[Image.Image, dict]:
    zone = editable(native, box, region)
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
    cells = [(x, y) for x, y in sorted(zone, key=lambda p: (p[1], p[0]))
             if raw[x, y] != echo[x, y] and not (gen[x, y][3] < 128 and src[x, y][3] == 0)]
    candidate = native.copy()
    if cells:
        pal = palette if palette is not None and len(palette) else from_image(native)
        patch = Image.new("RGBA", native.size, CLEAR)
        for x, y in cells:
            patch.putpixel((x, y), gen[x, y])
        patch = quantize.to_palette(patch, pal).load()
        for x, y in cells:
            candidate.putpixel((x, y), patch[x, y] if patch[x, y][3] >= 128 else CLEAR)
    out, info = compose.compose(native, candidate, zone, method, protect, old)
    final = out.load()
    cleared = sum(1 for x, y in cells if src[x, y][3] >= 128 and final[x, y][3] < 128)
    return out, {"scale": k, "box": list(box) if region is None else masks.bbox(zone), "key": key,
                 "matte": "alpha" if alpha_mode else "key", "cells_returned_different": len(cells),
                 "became_transparent": cleared, **info,
                 "mask_convention": "openai: alfa 0 = editar (internamente 1 = editavel)"}


def run(native: Image.Image, box: tuple[int, int, int, int] | None, change: str, palette: Palette | None = None,
        references: list[bytes] | None = None, transport=None, model: str | None = None,
        folder=None, budget=None, region=None, method: str = "replace", protect=frozenset(),
        old=frozenset()) -> tuple[Image.Image, dict]:
    """Com o gpt-image: pede a edicao (job duravel) e devolve o sprite com so a zona mudada."""
    from .backends import openai_images
    compose.refuse_protected(editable(native, box, region), protect)
    image, mask, k, size, key = prepare(native, box, palette=palette, region=region)
    roles = ["edit_target"] + ["identity"] * len(references or [])
    answer = openai_images.edit(prompts.edit_prompt(change), [image] + (references or []), mask, size,
                                model=model, transport=transport, folder=folder, budget=budget, roles=roles)
    with Image.open(io.BytesIO(answer["images"][0])) as im:
        result = im.convert("RGBA")
    out, info = merge(native, result, k, box, palette, key, region, method, protect, old)
    info["key_distance"] = key_for(_used(native, palette))[1]
    info["model"], info["job"] = answer["model"], answer["job"]["id"]
    return out, info
