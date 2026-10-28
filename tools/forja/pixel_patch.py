"""`forja.pixel_patch/1`: editar pixels nativos por operacoes explicitas, numa mascara, sem regenerar (FORJA-10, P1).

Um refinamento de rosto, mao ou corda nao precisa de outra geracao global, que perde a identidade que tinha. O
patch diz a imagem base (o hash dos pixels e a tela), a mascara autorizada (caixas), o que fica protegido (caixas e
pinos com a cor que tem) e as operacoes, por ordem:

- `paint`: pixels [[x, y, cor], ...];
- `region`: uma caixa reescrita por linhas de caracteres e uma legenda (`keep` deixa o pixel como esta);
- `move`: um agrupamento (pixels opacos ou de certas cores numa caixa) deslocado por [dx, dy], com o destino
  validado e o lugar que vaga preenchido.

O executor recusa coordenadas fora da tela, outra imagem ou outra tela, alfa intermedio, cor fora da paleta (sem
`allow_new_colors`), editar fora da mascara ou num pixel protegido; nao ha blur, reamostragem nem limpeza de pixels
isolados. Fora da mascara o resultado e byte a byte a base, e isso e conferido depois de aplicar. A tela fica exata
por construcao; a arte ainda pode estar errada — o patch nao aprova nada, e a observacao anterior deixa de valer.
"""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

from . import color as colormod
from .equipment import image_sha
from .imageops import on_background, upscale

SCHEMA = "forja.pixel_patch/1"
OPS = ("paint", "region", "move")
CLEAR = (0, 0, 0, 0)


def load(path: str | Path) -> dict:
    try:
        data = json.loads(Path(path).read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"patch {path}: JSON invalido ({exc.msg}, linha {exc.lineno})") from exc
    if not isinstance(data, dict):
        raise ValueError(f"patch {path}: esperado um objeto JSON")
    return data


def rgba(value) -> tuple[int, int, int, int]:
    if value in ("transparent", "clear"):
        return CLEAR
    text = str(value).lstrip("#")
    if len(text) not in (6, 8):
        raise ValueError(f"cor {value!r}: use #RRGGBB, #RRGGBBAA ou transparent")
    r, g, b = colormod.parse_hex("#" + text[:6])
    a = int(text[6:], 16) if len(text) == 8 else 255
    if a not in (0, 255):
        raise ValueError(f"cor {value!r}: alfa intermedio ({a}); o sprite e opaco ou transparente")
    return (r, g, b, a) if a else CLEAR


def _box(b, size, what: str) -> set:
    if not (isinstance(b, list) and len(b) == 4 and all(type(v) is int for v in b)
            and 0 <= b[0] < b[2] <= size[0] and 0 <= b[1] < b[3] <= size[1]):
        raise ValueError(f"{what}: caixa {b} invalida ou fora da tela {list(size)}")
    return {(x, y) for y in range(b[1], b[3]) for x in range(b[0], b[2])}


class _Work:
    def __init__(self, base: Image.Image, patch: dict, palette):
        self.img, self.size, self.errors = base.copy(), base.size, []
        self.px = self.img.load()
        self.allowed = set().union(*[_box(b, self.size, "mascara") for b in patch.get("mask", [])])
        self.locked = set().union(*[_box(p.get("box"), self.size, f"protegida {p.get('id')}")
                                    for p in patch.get("protected", [])])
        for pin in patch.get("pins", []):
            x, y = pin.get("xy") or (-1, -1)
            if not (0 <= x < self.size[0] and 0 <= y < self.size[1]):
                raise ValueError(f"pino {pin.get('id')}: {pin.get('xy')} fora da tela")
            if self.px[x, y] != rgba(pin.get("rgba")):
                raise ValueError(f"pino {pin.get('id')}: a base tem {colormod.to_hex(self.px[x, y][:3])} em {[x, y]}, "
                                 f"nao {pin.get('rgba')}: o patch e de outra imagem ou o pino esta errado")
            self.locked.add((x, y))
        self.palette = None if palette is None or patch.get("allow_new_colors") else {tuple(c) for c in palette}
        self.changed: set = set()

    def put(self, x: int, y: int, value, op: str) -> None:
        if not (0 <= x < self.size[0] and 0 <= y < self.size[1]):
            self.errors.append(f"{op}: {[x, y]} fora da tela {list(self.size)}")
            return
        if (x, y) not in self.allowed:
            self.errors.append(f"{op}: {[x, y]} fora da mascara autorizada")
            return
        if (x, y) in self.locked:
            self.errors.append(f"{op}: {[x, y]} esta protegido")
            return
        if value[3] and self.palette is not None and value[:3] not in self.palette:
            self.errors.append(f"{op}: cor {colormod.to_hex(value[:3])} fora da paleta (allow_new_colors: false)")
            return
        if self.px[x, y] != value:
            self.px[x, y] = value
            self.changed.add((x, y))


def _paint(w: _Work, op: dict, n: str) -> None:
    for item in op.get("pixels", []):
        w.put(int(item[0]), int(item[1]), rgba(item[2]), n)


def _region(w: _Work, op: dict, n: str) -> None:
    _box(op.get("box"), w.size, n)
    x0, y0, x1, y1 = op["box"]
    rows, legend = op.get("rows", []), op.get("legend", {})
    if len(rows) != y1 - y0 or any(len(r) != x1 - x0 for r in rows):
        raise ValueError(f"{n}: {len(rows)} linhas para a caixa {op['box']} ({x1 - x0}x{y1 - y0})")
    colors = {k: None if v == "keep" else rgba(v) for k, v in legend.items()}
    for dy, row in enumerate(rows):
        for dx, ch in enumerate(row):
            if ch not in colors:
                raise ValueError(f"{n}: caractere {ch!r} sem legenda")
            if colors[ch] is not None:
                w.put(x0 + dx, y0 + dy, colors[ch], n)


def _move(w: _Work, op: dict, n: str) -> None:
    area = _box(op.get("box"), w.size, n)
    dx, dy = op.get("to") or (0, 0)
    pick = op.get("select", "opaque")
    wanted = None if pick == "opaque" else {rgba(c) for c in pick}
    moving = {p: w.px[p] for p in area if w.px[p][3] and (wanted is None or w.px[p] in wanted)}
    if not moving:
        raise ValueError(f"{n}: nada selecionado na caixa {op['box']}")
    fill = rgba(op.get("fill", "transparent"))
    for (x, y) in moving:
        if (x + dx, y + dy) not in moving:
            w.put(x, y, fill, n)
    for (x, y), value in moving.items():
        w.put(x + dx, y + dy, value, n)


def apply(base: Image.Image, patch: dict, palette=None) -> tuple[Image.Image, dict]:
    """O patch aplicado, ou ValueError com todas as recusas (nada se grava)."""
    base = base.convert("RGBA")
    alpha = base.getchannel("A")
    errors = [] if patch.get("schema") == SCHEMA else [f"schema: esperado {SCHEMA}"]
    if any(alpha.histogram()[1:255]):
        errors.append("a base tem alfa intermedio: passe-a pelo forja forge antes de a editar ao pixel")
    clean = Image.new("RGBA", base.size, CLEAR)
    clean.paste(base, (0, 0), alpha.point(lambda a: 255 if a else 0))
    base = clean  # a cor escondida no transparente nao conta (como no image_sha)
    sha = image_sha(base)
    if (patch.get("base") or {}).get("pixels_sha256") != sha:
        errors.append(f"o patch e de outra imagem (base {str((patch.get('base') or {}).get('pixels_sha256'))[:12]}..., "
                      f"esta {sha[:12]}...)")
    if (patch.get("base") or {}).get("canvas") != list(base.size):
        errors.append(f"tela {(patch.get('base') or {}).get('canvas')} e nao {list(base.size)}")
    errors += [f"patch sem {k}" for k in ("author", "date", "reason") if not patch.get(k)]
    if not patch.get("mask"):
        errors.append("patch sem mascara autorizada")
    if errors:
        raise ValueError("; ".join(errors))
    w = _Work(base, patch, palette)
    for i, op in enumerate(patch.get("operations", []), 1):
        n = f"op {i} ({op.get('op')})"
        if op.get("op") not in OPS:
            raise ValueError(f"{n}: use {', '.join(OPS)}")
        {"paint": _paint, "region": _region, "move": _move}[op["op"]](w, op, n)
    if w.errors:
        raise ValueError("; ".join(w.errors[:12]) + (f" (+{len(w.errors) - 12})" if len(w.errors) > 12 else ""))
    src, out = base.load(), w.px
    outside = [(x, y) for y in range(base.height) for x in range(base.width)
               if (x, y) not in w.allowed and src[x, y] != out[x, y]]
    touched = [p for p in w.locked if src[p] != out[p]]
    if outside or touched:
        raise ValueError(f"exterior alterado em {len(outside)} pixels e protegidos em {len(touched)}: patch recusado")
    before = {src[x, y] for y in range(base.height) for x in range(base.width) if src[x, y][3]}
    added = sorted({colormod.to_hex(out[p][:3]) for p in w.changed if out[p][3] and out[p] not in before})
    xs, ys = [p[0] for p in w.changed], [p[1] for p in w.changed]
    return w.img, {"schema": SCHEMA, "base_pixels_sha256": sha, "result_pixels_sha256": image_sha(w.img),
                   "canvas": list(base.size), "changed_pixels": len(w.changed),
                   "changed_bbox": [min(xs), min(ys), max(xs) + 1, max(ys) + 1] if w.changed else None,
                   "exterior_identical": True, "protected_identical": True, "new_colors": added,
                   "resampled": False, "blurred": False, "singletons_removed_automatically": False,
                   "author": patch["author"], "date": patch["date"], "reason": patch["reason"]}


def diff(before: Image.Image, after: Image.Image, scale: int = 8) -> Image.Image:
    """Antes, depois e o que mudou (magenta sobre o depois esbatido), ampliados por um inteiro."""
    a, b = (on_background(upscale(i, scale), (128, 128, 128)).convert("RGB") for i in (before, after))
    marked = b.point(lambda v: 64 + v // 2)
    pa, pb = before.convert("RGBA").load(), after.convert("RGBA").load()
    for y in range(before.height):
        for x in range(before.width):
            if pa[x, y] != pb[x, y]:
                marked.paste((255, 0, 255), (x * scale, y * scale, (x + 1) * scale, (y + 1) * scale))
    out = Image.new("RGB", (a.width * 3 + 32, a.height), (24, 30, 36))
    for i, im in enumerate((a, b, marked)):
        out.paste(im, (i * (a.width + 16), 0))
    return out
