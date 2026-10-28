"""Propor o patch 01 (limpeza) de um piloto: o fundo da prancha preso entre partes e a sombra do chao.

As regras so propoem; a lista de pixels gravada no patch foi conferida a olho numa ampliacao (fundo em magenta,
sombra em ciano), e os restos que as regras nao apanham entram por EXTRA, um a um, com o motivo.
Uso: python3 propor_limpeza.py <personagem>
"""
from __future__ import annotations

import json
import sys
from collections import deque
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[3]))
sys.path.insert(0, str(HERE))

import pilotos  # noqa: E402
from tools.forja import fidelity, pixel_patch  # noqa: E402
from tools.forja.equipment import image_sha  # noqa: E402

EXTRA = {"escudeiro": {(36, 42): "resto do fundo entre a perna e o escudo", (37, 42): "idem"},
         "arqueiro_tropa": {(44, 40): "resto do fundo dentro do arco", (15, 60): "resto do fundo entre as botas",
                            (28, 60): "idem"}}


def background(c) -> bool:
    r, g, b = c[:3]
    return 94 <= r <= 108 and abs(r - g) <= 7 and 0 <= g - b <= 6 and r >= g


def shadow(c) -> bool:
    r, g, b = c[:3]
    return 58 <= r <= 80 and 44 <= g <= 62 and 38 <= b <= 56 and r - g >= 6 and g >= b - 2


def groups(image, rule) -> list[list[tuple[int, int]]]:
    px, (w, h), seen, out = image.load(), image.size, set(), []
    for y in range(h):
        for x in range(w):
            if (x, y) in seen or not px[x, y][3] or not rule(px[x, y]):
                continue
            queue, comp = deque([(x, y)]), []
            seen.add((x, y))
            while queue:
                p = queue.popleft()
                comp.append(p)
                for n in ((p[0] + 1, p[1]), (p[0] - 1, p[1]), (p[0], p[1] + 1), (p[0], p[1] - 1)):
                    if 0 <= n[0] < w and 0 <= n[1] < h and n not in seen and px[n][3] and rule(px[n]):
                        seen.add(n)
                        queue.append(n)
            out.append(comp)
    return out


def propose(ident: str) -> dict:
    contract = fidelity.load(pilotos.CONTRACT)
    image, _ = pilotos.stages(contract, ident, upto="01")
    pockets = [c for c in groups(image, background) if len(c) >= 3]
    ground = [c for c in groups(image, shadow) if max(p[1] for p in c) >= image.height - 3]
    pixels = sorted({p for c in pockets + ground for p in c} | set(EXTRA.get(ident, {})))
    return {"schema": pixel_patch.SCHEMA, "base": {"pixels_sha256": image_sha(image), "canvas": list(image.size)},
            "mask": [[0, 0, image.width, image.height]], "author": "Claude (agente), conferido a olho",
            "date": "2026-10-28", "reason": "limpeza: fundo da prancha preso entre partes e sombra do chao; "
            f"{len(pockets)} bolsoes, {len(ground)} sombras, {len(EXTRA.get(ident, {}))} restos a mao",
            "extra": {f"{x},{y}": why for (x, y), why in EXTRA.get(ident, {}).items()},
            "operations": [{"op": "paint", "pixels": [[x, y, "transparent"] for x, y in pixels]}]}


if __name__ == "__main__":
    ident = sys.argv[1]
    patch = propose(ident)
    path = HERE / "patches" / ident / "01-limpeza.json"
    path.write_text(json.dumps(patch, indent=None, separators=(",", ":")) + "\n", encoding="utf-8")
    print(path, len(patch["operations"][0]["pixels"]))
