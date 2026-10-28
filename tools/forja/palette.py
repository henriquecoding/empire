"""Paletas: ler e escrever (GPL, hex, JSON, PNG), procurar a cor mais proxima,
extrair uma paleta de uma imagem e fundir cores quase iguais.

A paleta do projeto e `art/palettes/empire_working.gpl` (Asset Bible §1). A
Forja nao a altera: le, compara e propoe.
"""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

from . import color
from .imageops import flat

ROOT = Path(__file__).resolve().parents[2]
EMPIRE_PALETTE = ROOT / "art" / "palettes" / "empire_working.gpl"


class Palette:
    def __init__(self, colors: list[tuple[int, int, int]], name: str = "",
                 names: list[str] | None = None):
        seen: dict[tuple[int, int, int], int] = {}
        for c in colors:
            seen.setdefault((c[0], c[1], c[2]), len(seen))
        self.colors = list(seen)
        self._set = frozenset(seen)
        self.name = name
        self.names = names if names and len(names) == len(self.colors) else [""] * len(self.colors)
        self._labs = [color.oklab(c) for c in self.colors]
        self._memo: dict[tuple[int, int, int], int] = {}

    def __len__(self) -> int:
        return len(self.colors)

    def __contains__(self, rgb: tuple[int, ...]) -> bool:
        return (rgb[0], rgb[1], rgb[2]) in self._set

    def index(self, rgb: tuple[int, ...]) -> int:
        """Indice da cor mais proxima em OKLab (memorizado)."""
        key = (rgb[0], rgb[1], rgb[2])
        hit = self._memo.get(key)
        if hit is None:
            lab = color.oklab(key)
            hit = min(range(len(self._labs)), key=lambda i: color.dist2(lab, self._labs[i]))
            self._memo[key] = hit
        return hit

    def nearest(self, rgb: tuple[int, ...]) -> tuple[int, int, int]:
        return self.colors[self.index(rgb)]

    def two_nearest(self, rgb: tuple[int, ...]) -> tuple[int, int, float]:
        """As duas cores mais proximas e onde o pixel cai entre elas (0..1)."""
        lab = color.oklab((rgb[0], rgb[1], rgb[2]))
        order = sorted(range(len(self._labs)), key=lambda i: color.dist2(lab, self._labs[i]))
        i = order[0]
        j = order[1] if len(order) > 1 else i
        p, q = self._labs[i], self._labs[j]
        seg = color.dist2(p, q)
        if seg == 0:
            return i, j, 0.0
        t = sum((lab[k] - p[k]) * (q[k] - p[k]) for k in range(3)) / seg
        return i, j, max(0.0, min(1.0, t))

    def hexes(self) -> list[str]:
        return [color.to_hex(c) for c in self.colors]

    def sorted_by_lightness(self) -> "Palette":
        order = sorted(range(len(self.colors)), key=lambda i: self._labs[i][0])
        return Palette([self.colors[i] for i in order], self.name, [self.names[i] for i in order])


def load(source: str | Path | None) -> Palette:
    """Le uma paleta: caminho .gpl/.hex/.txt/.json/.png, 'empire', ou hex separados por virgula."""
    if source in (None, "", "empire"):
        source = EMPIRE_PALETTE
    text = str(source)
    if not Path(text).is_file() and ("," in text or text.startswith("#")):  # um caminho pode ter virgulas (B14)
        return Palette([color.parse_hex(h) for h in text.replace(" ", "").split(",") if h], "inline")
    path = Path(text)
    suffix = path.suffix.lower()
    if suffix == ".gpl":
        return _load_gpl(path)
    if suffix == ".json":
        data = json.loads(path.read_text(encoding="utf-8"))
        items = data.get("colors", data) if isinstance(data, dict) else data
        return Palette([color.parse_hex(h) for h in items], path.stem)
    if suffix in (".png", ".gif", ".bmp"):
        with Image.open(path) as im:
            return from_image(im, path.stem)
    lines = [ln.split(";")[0].strip() for ln in path.read_text(encoding="utf-8").splitlines()]
    return Palette([color.parse_hex(ln) for ln in lines if ln], path.stem)


def _load_gpl(path: Path) -> Palette:
    colors, names, name = [], [], path.stem
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line.startswith("Name:"):
            name = line[5:].strip()
            continue
        if not line or line.startswith(("#", "GIMP", "Columns:")):
            continue
        parts = line.split(None, 3)
        if len(parts) >= 3 and all(p.isdigit() for p in parts[:3]):
            colors.append((int(parts[0]), int(parts[1]), int(parts[2])))
            names.append(parts[3].strip() if len(parts) > 3 else "")
    return Palette(colors, name, names)


def from_image(image: Image.Image, name: str = "") -> Palette:
    """As cores opacas de uma imagem, pela ordem em que aparecem (linha a linha)."""
    rgba = image.convert("RGBA")
    colors = [p[:3] for p in flat(rgba) if p[3] >= 128]
    return Palette(colors, name)


def save(palette: Palette, path: str | Path, columns: int = 16) -> Path:
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    suffix = path.suffix.lower()
    if suffix == ".gpl":
        rows = ["GIMP Palette", f"Name: {palette.name or path.stem}", f"Columns: {columns}", "#"]
        for c, n in zip(palette.colors, palette.names):
            rows.append(f"{c[0]:3d} {c[1]:3d} {c[2]:3d}\t{n or color.to_hex(c)}")
        path.write_text("\n".join(rows) + "\n", encoding="utf-8")
    elif suffix == ".json":
        path.write_text(json.dumps({"name": palette.name, "colors": palette.hexes()}, indent=2) + "\n",
                        encoding="utf-8")
    elif suffix == ".png":
        swatch(palette, columns=columns, cell=1).save(path)
    else:
        path.write_text("\n".join(h.lstrip("#") for h in palette.hexes()) + "\n", encoding="utf-8")
    return path


def swatch(palette: Palette, columns: int = 16, cell: int = 16) -> Image.Image:
    rows = max(1, -(-len(palette) // columns))
    out = Image.new("RGBA", (columns * cell, rows * cell))
    for i, c in enumerate(palette.colors):
        x, y = (i % columns) * cell, (i // columns) * cell
        out.paste((*c, 255), (x, y, x + cell, y + cell))
    return out


def histogram(image: Image.Image) -> list[tuple[int, tuple[int, int, int]]]:
    """(contagem, cor) das cores opacas, da mais frequente para a menos."""
    rgba = image.convert("RGBA")
    found = rgba.getcolors(rgba.width * rgba.height) or []
    merged: dict[tuple[int, int, int], int] = {}
    for n, p in found:
        if p[3] >= 128:
            merged[p[:3]] = merged.get(p[:3], 0) + n
    return sorted(((n, c) for c, n in merged.items()), key=lambda t: (-t[0], t[1]))


def extract(image: Image.Image, k: int, iterations: int = 24) -> Palette:
    """K-means ponderado em OKLab, com sementes por ponto-mais-distante.

    Deterministico: nada de sorteio. A primeira semente e a cor mais frequente; cada
    seguinte e a que maximiza contagem x distancia^2 as sementes ja escolhidas — o
    k-means++ sem dado, para que a mesma imagem de sempre a mesma paleta.
    """
    hist = histogram(image)
    if not hist:
        return Palette([], "vazia")
    if len(hist) <= k:
        return Palette([c for _, c in hist], "extraida")
    labs = [color.oklab(c) for _, c in hist]
    weights = [n for n, _ in hist]
    centers = [labs[0]]
    nearest = [color.dist2(lab, centers[0]) for lab in labs]
    while len(centers) < k:
        pick = max(range(len(labs)), key=lambda i: weights[i] * nearest[i])
        if nearest[pick] == 0:
            break
        centers.append(labs[pick])
        nearest = [min(d, color.dist2(lab, labs[pick])) for d, lab in zip(nearest, labs)]
    for _ in range(iterations):
        sums = [[0.0, 0.0, 0.0, 0.0] for _ in centers]
        for lab, w in zip(labs, weights):
            j = min(range(len(centers)), key=lambda c: color.dist2(lab, centers[c]))
            acc = sums[j]
            acc[0] += lab[0] * w
            acc[1] += lab[1] * w
            acc[2] += lab[2] * w
            acc[3] += w
        moved = 0.0
        for j, acc in enumerate(sums):
            if acc[3]:
                new = (acc[0] / acc[3], acc[1] / acc[3], acc[2] / acc[3])
                moved = max(moved, color.dist2(new, centers[j]))
                centers[j] = new
        if moved < 1e-8:
            break
    return Palette([color.from_oklab(c) for c in centers], "extraida")


def merge_close(palette: Palette, threshold: float = 0.04) -> Palette:
    """Funde cores a menos de `threshold` em OKLab (a regra dos <4% da Asset Bible §1)."""
    kept: list[tuple[int, int, int]] = []
    for c in palette.colors:
        if all(color.delta(c, k) >= threshold for k in kept):
            kept.append(c)
    return Palette(kept, palette.name)


def ramp(base: tuple[int, int, int], steps: int = 5, hue_shift: float = 18.0,
         light_range: float = 0.42) -> Palette:
    """Uma rampa com desvio de matiz: claros para o quente, escuros para o frio.

    O desvio de matiz e a tecnica classica para rampas de pixel art nao parecerem
    "cinzento com tinta". O croma cai nas pontas para os extremos nao saturarem.
    """
    big_l, c, h = color.lch(base)
    out = []
    for i in range(steps):
        t = (i / (steps - 1) - 0.5) * 2 if steps > 1 else 0.0
        target = h + _hue_toward(h, 85.0) * hue_shift * t
        lum = max(0.05, min(0.97, big_l + t * light_range / 2))
        out.append(color.from_lch(lum, c * (1 - 0.35 * abs(t)), target % 360, gamut=True))
    return Palette(out, f"ramp {color.to_hex(base)}")


def _hue_toward(h: float, target: float) -> float:
    d = (target - h + 540) % 360 - 180
    return 1.0 if d >= 0 else -1.0
