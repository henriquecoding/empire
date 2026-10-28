"""Propor os patches 03 (orcamento da tela) dos pilotos: decisoes de desenho, nao reducoes.

Rei: o pivo royal_80 (40,78) fica no centro dos pes; na grade da prancha a capa vai 44 px para tras desse centro e
a tela da 40. O contorno de tras da capa entra ate x=4 (curva comprimida, borda clara e contorno mantidos, o miolo
encolhe, o braco e a espada nao mexem) e a ponta da barra em (3,65) sai. Margem esquerda 0, so do lado da capa.
Arqueiro de tropa: 64 linhas na grade da prancha para 61 uteis (y 2..62). Saem tres linhas inteiras fora do rosto
e das maos: a 3 (copa do capuz), a 30 (tronco creme) e a 52 (calcas). O arco e redesenhado no patch 04.
Uso: python3 propor_orcamento.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[3]))
sys.path.insert(0, str(HERE))

import pilotos  # noqa: E402
from tools.forja import color, fidelity, pixel_patch  # noqa: E402
from tools.forja.equipment import image_sha  # noqa: E402

DATE, WHO = "2026-10-28", "Claude (agente), conferido a olho a 1x e 7x"


def _cape(p) -> bool:
    return bool(p[3]) and (max(p[:3]) < 30 or (p[2] > p[0] + 10 and p[2] >= p[1]))


def tuck(image, limit: int = 4, rows=range(26, 72)) -> dict:
    px, w = image.load(), image.width
    starts = {y: next(x for x in range(w) if px[x, y][3]) for y in rows if any(px[x, y][3] for x in range(w))}
    low, top, edits = min(starts.values()), limit + 3, {}
    for y, x0 in starts.items():
        if x0 >= top:
            continue
        shift = limit + round((x0 - low) * (top - limit) / (top - low)) - x0
        run = x0
        while run < w and _cape(px[run, y]):
            run += 1
        seg = 3 if run - x0 >= 5 + shift else 2
        shift = min(shift, run - x0 - seg - 2)
        if shift <= 0:
            continue
        row = [px[x, y] for x in range(w)]
        new = [(0, 0, 0, 0)] * (x0 + shift) + row[x0:x0 + seg] + row[x0 + seg + shift:]
        edits.update({(x, y): new[x] for x in range(w) if new[x] != row[x]})
    edits[(3, 65)] = (0, 0, 0, 0)
    return edits


def _hex(p) -> str:
    return "transparent" if not p[3] else color.to_hex(p[:3])


def patch(image, ops, mask, reason) -> dict:
    return {"schema": pixel_patch.SCHEMA, "base": {"pixels_sha256": image_sha(image), "canvas": list(image.size)},
            "mask": mask, "author": WHO, "date": DATE, "reason": reason, "operations": ops}


def main() -> None:
    contract = fidelity.load(pilotos.CONTRACT)
    king, _ = pilotos.stages(contract, "rei", upto="03")
    edits = tuck(king)
    out = patch(king, [{"op": "paint", "pixels": [[x, y, _hex(v)] for (x, y), v in sorted(edits.items())]}],
                [[0, 26, 30, 72]], "orcamento royal_80: a capa entra 4 px atras (curva comprimida) para caber na tela "
                "com o pivo no centro dos pes; braco, espada e rosto intactos")
    (HERE / "patches/rei/03-capa.json").write_text(json.dumps(out, separators=(",", ":")) + "\n", encoding="utf-8")
    archer, _ = pilotos.stages(contract, "arqueiro_tropa", upto="03")
    w = archer.width
    rows = [3, 30, 52]
    ops = [{"op": "move", "box": [0, 0, w, r], "select": "all", "to": [0, 1]} for r in rows]
    out = patch(archer, ops, [[0, 0, w, 53]], "orcamento troop_64: tres linhas inteiras fora do rosto e das maos "
                "(3 copa do capuz, 30 tronco, 52 calcas) para 61 linhas uteis; pivo nos pes")
    (HERE / "patches/arqueiro_tropa/03-linhas.json").write_text(json.dumps(out, indent=1) + "\n", encoding="utf-8")
    print(len(edits), "pixels na capa; linhas", rows)


if __name__ == "__main__":
    main()
