"""Banding: faixas de cor paralelas com as pontas alinhadas, a suspeita que o diagnostico de cor nao via (FORJA-06).

Definicao do Pixel Fixer (Rares Bites, com Elmar Eisemann, Petr Kellnhofer e Mathijs Molenaar; TU Delft, 2025): ha
banding quando dois segmentos de cores diferentes, cada um com 2 ou mais pixels, sao vizinhos pelo lado comprido e
tem as pontas alinhadas. Um segmento de 1 px (degenerado), dois segmentos que so partilham o lado curto ou dois
desalinhados nao contam. Procura-se nas linhas (segmentos horizontais, um por cima do outro) e nas colunas.

O contorno e o vazio ficam de fora: sao estrutura, e o lint confere-os. O resultado e uma suspeita para rever a 1x,
com os sitios — nunca um defeito confirmado nem uma correcao (a tese corrige com o autor a escolher; aqui nao se
corrige nada). Uma faixa pode ser de proposito (um cinto, uma barra de cor): o papel declarado na observacao diz-o.
O limite (2 px, as duas pontas) e o da tese, por calibrar no Empire como o dos fragmentos (Q-281).
"""
from __future__ import annotations

from . import color
from .imageops import grid as to_grid

OUTLINE = (0, 0, 0)
SOURCE = "Bites, Eisemann, Kellnhofer, Molenaar: Pixel Fixer (TU Delft, 2025), banding entre segmentos alinhados"


def runs(line: list, outline=OUTLINE) -> list[tuple[int, int, tuple]]:
    """Os segmentos maximos de uma linha de pixels: (inicio, fim inclusivo, cor), sem vazio nem contorno."""
    out, start = [], 0
    for i in range(1, len(line) + 1):
        if i == len(line) or line[i] != line[start]:
            rgba = line[start]
            if rgba[3] >= 128 and rgba[:3] != outline:
                out.append((start, i - 1, rgba[:3]))
            start = i
    return out


def _pairs(lines: list[list], axis: str, min_len: int, outline) -> list[dict]:
    found = []
    previous = None
    for k, line in enumerate(lines):
        here = {(a, b): c for a, b, c in runs(line, outline) if b - a + 1 >= min_len}
        for (a, b), c in (previous or {}).items():
            other = here.get((a, b))
            if other is not None and other != c:
                at = [a, k - 1] if axis == "horizontal" else [k - 1, a]
                found.append({"axis": axis, "at": at, "length": b - a + 1,
                              "colors": [color.to_hex(c), color.to_hex(other)]})
        previous = here
    return found


def find(image, regions: dict | None = None, outline=OUTLINE, min_len: int = 2, examples: int = 24) -> dict:
    """Os pares de segmentos em banding, por eixo e por regiao (a do primeiro pixel do par)."""
    rows = to_grid(image.convert("RGBA"))
    cols = [list(col) for col in zip(*rows)]
    pairs = _pairs(rows, "horizontal", min_len, outline) + _pairs(cols, "vertical", min_len, outline)
    by_region = {}
    for name, spec in (regions or {}).items():
        pixels = spec["pixels"] if isinstance(spec, dict) else spec
        by_region[name] = sum(1 for p in pairs if tuple(p["at"]) in pixels)
    return {"pairs": len(pairs), "horizontal": sum(p["axis"] == "horizontal" for p in pairs),
            "vertical": sum(p["axis"] == "vertical" for p in pairs), "by_region": by_region,
            "examples": pairs[:examples], "status": "review" if pairs else "none",
            "rule": f"dois segmentos de cores diferentes com {min_len}+ px, vizinhos pelo lado comprido e com as duas "
                    "pontas alinhadas (sem contorno nem vazio)", "source": SOURCE,
            "note": "suspeita para rever a 1x: uma faixa pode ser de proposito; nada foi mudado"}
