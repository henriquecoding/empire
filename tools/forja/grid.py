"""Achar a grade escondida numa imagem "estilo pixel art".

O gerador desenha pixels logicos como blocos de ~N x N px, mas o N deriva, as
bordas vem suavizadas e ha ruido. Passos: (1) perfil de bordas por eixo, pelo
canal mais diferente; (2) periodo pela autocorrelacao dos dois eixos juntos,
com o pico alargado; (3) afinacao por pente de contraste (dentes menos meios:
multiplos e submultiplos perdem); (4) linhas por uma reta global refeita por
minimos quadrados com as bordas confirmadas, interpoladas nas zonas lisas.
"""
from __future__ import annotations

from dataclasses import dataclass, field

from PIL import Image, ImageChops

from .imageops import flat

NOISE_FLOOR = 10
NATIVE_STRENGTH = 0.12


@dataclass
class Grid:
    xs: list[int]
    ys: list[int]
    period: tuple[float, float]
    confidence: float
    native: bool = False
    notes: list[str] = field(default_factory=list)
    origin: str = "estimated"  # FORJA-07: gridcheck.ORIGINS; a dada pelo operador nao prova autoria nativa

    @property
    def size(self) -> tuple[int, int]:
        return len(self.xs) - 1, len(self.ys) - 1

    def as_dict(self) -> dict:
        return {"cells": list(self.size), "period": [round(p, 3) for p in self.period], "origin": self.origin,
                "confidence": round(self.confidence, 3), "native": self.native,
                "x0": self.xs[0], "y0": self.ys[0], "notes": self.notes}


def profiles(image: Image.Image, floor: int = NOISE_FLOOR) -> tuple[list[float], list[float]]:
    """Energia de borda por fronteira de coluna (indice x = entre x-1 e x) e de linha."""
    rgba = image.convert("RGBA")
    return _profile(rgba, floor), _profile(rgba.transpose(Image.Transpose.TRANSPOSE), floor)


def _profile(rgba: Image.Image, floor: int) -> list[float]:
    w, h = rgba.size
    if w < 3:
        return [0.0] * (w + 1)
    left, right = rgba.crop((0, 0, w - 1, h)), rgba.crop((1, 0, w, h))
    diff = None
    for a, b in zip(left.split(), right.split()):
        d = ImageChops.difference(a, b)
        diff = d if diff is None else ImageChops.lighter(diff, d)
    diff = diff.point(lambda v: 0 if v < floor else v).convert("F")
    return [0.0] + [float(v) for v in flat(diff.resize((w - 1, 1), Image.Resampling.BOX))] + [0.0]


def _smooth(e: list[float]) -> list[float]:
    n = len(e)
    return [0.25 * e[max(i - 1, 0)] + 0.5 * e[i] + 0.25 * e[min(i + 1, n - 1)] for i in range(n)]


def _comb(s: list[float], period: float, phase: float) -> float:
    n, total, count, pos = len(s), 0.0, 0, phase
    while pos < n - 0.5:
        total += s[int(pos + 0.5)]
        count += 1
        pos += period
    return total / count if count else 0.0


def _best_phase(s: list[float], period: float, step: float) -> tuple[float, float]:
    """(contraste, fase): dentes do pente menos os meios entre dentes."""
    best, phase, ph = -1e18, 0.0, 0.0
    while ph < period:
        sc = _comb(s, period, ph) - _comb(s, period, ph + period / 2)
        if sc > best:
            best, phase = sc, ph
        ph += step
    return best, phase


def autocorrelation(s: list[float], max_lag: int) -> list[float]:
    n = len(s)
    mean = sum(s) / n
    z = [v - mean for v in s]
    zero = sum(v * v for v in z) or 1.0
    return [1.0] + [sum(map(lambda a, b: a * b, z, z[lag:])) / zero * n / (n - lag)
                    for lag in range(1, max_lag + 1)]


def _first_peak(r: list[float], p_min: float, p_max: int) -> tuple[float, float] | None:
    lag = 1
    while lag < p_max and r[lag + 1] < r[lag]:
        lag += 1
    peaks = [k for k in range(max(lag, int(p_min)), p_max + 1) if r[k] >= r[k - 1] and r[k] >= r[k + 1]]
    top = max((r[k] for k in peaks), default=0.0)
    if top <= 0:  # sem picos, ou so negativos (recortes minusculos)
        return None
    k = next(k for k in peaks if r[k] >= 0.6 * top)
    a, b, c = r[k - 1], r[k], r[k + 1]
    bend = a - 2 * b + c
    return k + (0.5 * (a - c) / bend if bend < 0 else 0.0), max(0.0, b)


def estimate(*profiles_: list[float], p_min: float = 2.0) -> tuple[float, float]:
    """(periodo, forca) comum a um ou mais perfis (autocorrelacao media + pente de contraste)."""
    usable = [e for e in profiles_ if len(e) >= 8 and max(e) > 0]
    if not usable:
        return 1.0, 0.0
    smooth = [_smooth(e) for e in usable]
    p_max = int(min(len(e) for e in usable) / 6)
    if p_max < p_min + 1:
        return 1.0, 0.0
    rs = [autocorrelation(s, p_max + 2) for s in smooth]
    raw = [sum(vals) / len(vals) for vals in zip(*rs)]
    r = _widen(raw)
    peak = _first_peak(r, p_min, p_max)
    if peak is None:
        return 1.0, 0.0
    guess, strength = peak
    means = [sum(s) / len(s) or 1.0 for s in smooth]
    best_p, best = guess, -1e18
    reach = max(0.6, 0.08 * guess)
    p = max(p_min, guess - reach)
    while p <= guess + reach:
        step = 0.25 if p < 24 else 0.5
        sc = sum(_best_phase(s, p, step)[0] / m for s, m in zip(smooth, means))
        if sc > best:
            best_p, best = p, sc
        p = round(p + (0.02 if p < 24 else 0.05), 4)
    return best_p, strength


def _widen(r: list[float]) -> list[float]:
    """Media movel de janela proporcional ao atraso: junta o pico partido em dois (23 e 28 para 26,7)."""
    out = []
    for k in range(len(r)):
        w = max(0, round(0.08 * k)) if k > 4 else 0
        lo, hi = max(1 if k else 0, k - w), min(len(r) - 1, k + w)
        out.append(sum(r[lo:hi + 1]) / (hi - lo + 1))
    return out


def _snap(e: list[float], pred: float, radius: int, strong: float) -> float | None:
    n = len(e) - 1
    lo, hi = max(1, int(pred) - radius), min(n - 1, int(pred) + radius + 1)
    if lo > hi:
        return None
    i = max(range(lo, hi + 1), key=lambda k: (e[k], -abs(k - pred)))
    return float(i) if e[i] >= strong else None


def _fit(points: list[tuple[int, float]]) -> tuple[float, float] | None:
    """Reta minima (fase, periodo) por (indice, posicao)."""
    if len(points) < 4:
        return None
    mk = sum(k for k, _ in points) / len(points)
    mp = sum(p for _, p in points) / len(points)
    var = sum((k - mk) ** 2 for k, _ in points)
    if not var:
        return None
    slope = sum((k - mk) * (p - mp) for k, p in points) / var
    return mp - slope * mk, slope


def walk(e: list[float], period: float, phase: float, window: float = 0.3) -> tuple[list[int], float]:
    """As linhas de corte: reta global + borda local + interpolacao nas zonas lisas."""
    n = len(e) - 1
    strong = 0.12 * (max(e) or 1.0)
    radius = max(1, int(round(window * period)))
    a, p = phase, period
    hits: dict[int, float] = {}
    for _ in range(4):
        k0, k1 = -int(a // p) - 1, int((n - a) // p) + 1
        hits = {}
        for k in range(k0, k1 + 1):
            if 0 < a + k * p < n:
                pos = _snap(e, a + k * p, radius, strong)
                if pos is not None:
                    hits[k] = pos
        fit = _fit(list(hits.items()))
        if fit is None or not 0.8 * period < fit[1] < 1.25 * period:
            break
        if abs(fit[1] - p) < 0.005 and abs(fit[0] - a) < 0.05:
            break
        a, p = fit
    k0, k1 = -int(a // p) - 1, int((n - a) // p) + 1
    confirmed = sorted(hits.items())
    lines = []
    for k in range(k0, k1 + 1):
        if k in hits:
            lines.append(hits[k])
            continue
        left = [kp for kp in confirmed if kp[0] < k]
        right = [kp for kp in confirmed if kp[0] > k]
        if left and right:
            (ka, pa), (kb, pb) = left[-1], right[0]
            lines.append(pa + (pb - pa) * (k - ka) / (kb - ka))
        else:
            lines.append(a + k * p)
    cuts = sorted({int(round(v)) for v in lines if 0 < v < n})
    if not cuts or cuts[0] >= 0.5 * p:
        cuts.insert(0, max(0, cuts[0] - int(round(p))) if cuts else 0)
    if n - cuts[-1] >= 0.5 * p:
        cuts.append(min(n, cuts[-1] + int(round(p))))
    total = sum(1 for k in range(k0, k1 + 1) if 0 < a + k * p < n)
    return cuts, len(hits) / max(1, total)


def known(size: tuple[int, int], scale: float, offset: tuple[float, float] = (0, 0)) -> Grid:
    """A grade de uma ampliacao que nos proprios fizemos: nada a medir."""
    def cuts(n: int, start: float) -> list[int]:
        out, pos = [], start
        while pos <= n + 1e-6:
            out.append(int(round(pos)))
            pos += scale
        return out
    return Grid(cuts(size[0], offset[0]), cuts(size[1], offset[1]), (scale, scale), 1.0,
                scale == 1, ["grade conhecida"], "operator_declared")


def detect(image: Image.Image, scale: float | None = None, cells: tuple[int, int] | None = None,
           floor: int = NOISE_FLOOR) -> Grid:
    """A grade de uma imagem. `scale` ou `cells` fixam o periodo; a fase e as linhas medem-se."""
    w, h = image.size
    ex, ey = profiles(image, floor)
    notes = []
    if cells or scale:
        px, py = (w / cells[0], h / cells[1]) if cells else (scale, scale)
        notes.append("celulas dadas" if cells else "escala dada")
        strength = 1.0
    else:
        p, strength = estimate(ex, ey)
        if strength < NATIVE_STRENGTH:
            return Grid(list(range(w + 1)), list(range(h + 1)), (1.0, 1.0), 0.0, True,
                        ["sem grade visivel: tratada como pixel art nativa (escala 1)"], "unmeasured")
        px = py = p
    (xs, cx), (ys, cy) = _axis(ex, px), _axis(ey, py)
    confidence = min(1.0, strength / 0.6) * (0.5 + 0.25 * (cx + cy))
    return Grid(xs, ys, (px, py), confidence, False, notes, "operator_declared" if cells or scale else "estimated")


def _axis(e: list[float], period: float) -> tuple[list[int], float]:
    s = _smooth(e)
    _, phase = _best_phase(s, period, 0.5)
    return walk(e, period, phase)
