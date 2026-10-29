"""Fixtures da auditoria de fidelidade de 29/10 (FORJA-15): um frasco 13x20 com partes e um rosto nativo com marcos.

Nao sao o frasco nem o rosto aprovados de nenhum personagem: isolam a medida. O frasco e o envelope comum dos dois
alquimistas da entrega v3 (13x20) com um molde arbitrario; a mutacao T01 afina o bojo e alonga o gargalo sem mudar o
envelope. O rosto tem o olhar para a esquerda, um sorriso torto e dois dentes separados.
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

from tools.forja import equipment, face

EVIDENCE = Path(__file__).resolve().parents[3] / "docs/art/research/2026-10-29-forja-fidelidade-elenco/evidencias"
LEGEND = {"C": "cork", "L": "lip", "N": "neck", "B": "body"}
FLASK = ["....CCCC.....", "...CCCCCC....", "...LLLLLL....", "....NNNN.....", "....NNNN.....", "....NNNN.....",
         "...BBBBBB....", "..BBBBBBBB...", ".BBBBBBBBBB..", ".BBBBBBBBBBB.", "BBBBBBBBBBBBB", "BBBBBBBBBBBBB",
         "BBBBBBBBBBBBB", "BBBBBBBBBBBBB", "BBBBBBBBBBBBB", ".BBBBBBBBBBB.", ".BBBBBBBBBBB.", "..BBBBBBBBB..",
         "...BBBBBBB...", "....BBBBB...."]
THIN = ["....CCCC.....", "...CCCCCC....", "...LLLLLL....", "....NNNN.....", "....NNNN.....", "....NNNN.....",
        "....NNNN.....", "....NNNN.....", "...BBBBBB....", "..BBBBBBBB...", "BBBBBBBBBBBBB", "..BBBBBBBBB..",
        "..BBBBBBBBB..", "..BBBBBBBBB..", "..BBBBBBBBB..", "..BBBBBBBBB..", "..BBBBBBBBB..", "...BBBBBBB...",
        "....BBBBB....", ".....BBB....."]
GLASS, LIQUID, CORK, HAND = (40, 160, 70, 255), (210, 130, 30, 255), (110, 70, 40, 255), (230, 170, 120, 255)


def model(status: str = "approved", rows=None) -> dict:
    return {"schema": "forja.prop_model/1", "id": "flask_test", "size": [13, 20], "rows": rows or FLASK,
            "legend": LEGEND, "status": status, "approved_by": "teste" if status == "approved" else None,
            "date": "2026-10-29", "authored_from": {"authority_sha256": "0" * 64, "box": [0, 0, 10, 10],
                                                    "note": "fixture: nao e o frasco do conceito"}}


def parts(rows, at=(20, 10), mirror: bool = False) -> dict[str, set]:
    out: dict[str, set] = {}
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in LEGEND:
                out.setdefault(LEGEND[ch], set()).add((at[0] + (len(row) - 1 - x if mirror else x), at[1] + y))
    return out


def scene(rows=FLASK, hand=None, mirror=False, glass=GLASS) -> tuple[Image.Image, dict[str, set]]:
    """A imagem 64x64 com o frasco (e a mao por cima, se houver) e as regioes visiveis de cada parte."""
    regions = parts(rows, mirror=mirror)
    img = Image.new("RGBA", (64, 64))
    for name, cells in regions.items():
        for p in cells:
            img.putpixel(p, CORK if name == "cork" else glass)
    hand = set(hand or ())
    for p in hand:
        img.putpixel(p, HAND)
    seen = {k: v - hand for k, v in regions.items()}
    if hand:
        seen["hand_right"] = hand
    return img, seen


SPOUT = [r[2:] + ".." if i < 6 else r for i, r in enumerate(FLASK)]  # o gargalo fora do centro: o espelho ve-se


def manifest(contacts=True, occluded=False, allowed=("liquid_color",), with_model=True, status="approved",
             rows=None) -> dict:
    occ = ["hand_right"] if occluded else []
    item = {"id": "flask", "family": "flask", "slot": "weapon", "state": "offered",
            "parts": {"body": {"occluders": occ}}, "allowed_variations": list(allowed),
            "contacts": [{"part": "body", "body": "hand_right"}] if contacts else []}
    if with_model:
        item["model"] = model(status, rows)
    return {"schema": equipment.SCHEMA, "items": [item]}


def observe(img: Image.Image, regions: dict[str, set]) -> dict:
    """A observacao ja resolvida (o que equipment.observe devolve): as regioes visiveis de cada parte e da mao."""
    return {"regions": {(n if n == "hand_right" else f"flask.{n}"): frozenset(c) for n, c in regions.items()},
            "uncertain": set(), "anchors": {}, "observer": {"author": "teste"},
            "image_sha256": equipment.image_sha(img)}


S, D, W, M, N = (225, 170, 120, 255), (20, 14, 16, 255), (250, 245, 230, 255), (150, 40, 50, 255), (190, 120, 80, 255)


def face_image(pupil: str = "left", mouth: str = "crooked") -> Image.Image:
    """Um rosto 24x24: olho 4x2 com a pupila num lado, sobrancelha por cima, nariz de 4 px, boca e dois dentes."""
    img = Image.new("RGBA", (24, 24), S)
    for x in range(5, 9):
        img.putpixel((x, 4), D)
        for y in (6, 7):
            img.putpixel((x, y), W)
    px = 5 if pupil == "left" else 8
    for y in (6, 7):
        img.putpixel((px, y), D)
    for x in range(12, 16):
        img.putpixel((x, 11), N)
    line = [(6, 16), (7, 16), (8, 17), (9, 17), (10, 18), (11, 18), (12, 18)] if mouth == "crooked" else \
        [(x, 18) for x in range(6, 13)]
    for p in line:
        img.putpixel(p, M)
    for p in ((8, 19), (10, 19)):
        img.putpixel(p, W)
    return img


def sheet(status: str = "registered") -> dict:
    marks = [("eye_left", "eye", [5, 6, 9, 8], ["#FAF5E6"]),
             ("pupil_left", "pupil", [5, 6, 9, 8], ["#140E10"]), ("brow_left", "brow", [4, 3, 10, 5], ["#140E10"]),
             ("nose", "nose", [11, 10, 17, 13], ["#BE7850"]), ("mouth", "mouth", [5, 15, 14, 19], ["#962832"]),
             ("teeth", "teeth", [6, 19, 13, 21], ["#FAF5E6"])]
    out = {"schema": face.SCHEMA, "status": status, "intent": "olhar de lado, sorriso torto, dentes separados",
           "landmarks": [{"id": i, "feature": f, "intent": f"{f} do conceito", "authority_box": None,
                          "target_box": b, "colors": c} for i, f, b, c in marks],
           "relations": [{"id": "gaze", "type": "offset", "a": "pupil_left", "within": "eye_left", "expect": "left"},
                         {"id": "smile", "type": "asymmetry", "a": "mouth", "expect": "left_higher", "min": 2},
                         {"id": "brow_over_eye", "type": "above", "a": "brow_left", "b": "eye_left"},
                         {"id": "teeth_apart", "type": "pieces", "a": "teeth", "min": 2},
                         {"id": "big_nose", "type": "extent", "a": "nose", "axis": "x", "min": 4}]}
    return out


def chain(img: Image.Image, occurrences=(), root: str = "generated") -> dict:
    """Uma cadeia de uma etapa que deu esta imagem, com as ocorrencias dadas (forja.lineage/1)."""
    sha = equipment.image_sha(img)
    return {"schema": "forja.lineage/1", "root": {"kind": root, "input_sha256": "f" * 64},
            "stages": [{"n": 1, "stage": "forge", "input_sha256": "f" * 64, "output_sha256": sha, "carried": 0}],
            "occurrences": list(occurrences), "output_sha256": sha}
