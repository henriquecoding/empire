"""A prova da Forja: o que ela promete, medido contra uma verdade conhecida.

Corre sem rede, sem chave e sem motor, em segundos — e por isso e portao de CI
(`make forja`). Fabrica pixel art falsa com o synth (escala fracionaria, celulas
desiguais, desfoque, ruido, fundo de chave), passa-a pela forja e compara com
o sprite que a originou. Tambem prova a prancha, a ida e volta do .aseprite, a
costura dos tiles Wang e que o lint apanha os defeitos que diz apanhar.
"""
from __future__ import annotations

import random
from pathlib import Path

from PIL import Image

from . import aseprite, contracts, lint, pipeline, sheet, synth, tiles
from .imageops import flat, opaque_bbox
from .palette import from_image

SINGLE = ((16.0, 0.0, 0.0, 0), (15.6, 1.2, 0.9, 6), (12.3, 1.5, 1.0, 8), (8.0, 0.8, 0.7, 5),
          (21.7, 2.0, 1.2, 8), (5.5, 0.5, 0.6, 4), (31.0, 3.0, 1.5, 10))


def _diff(a: Image.Image, b: Image.Image) -> int:
    return sum(1 for p, q in zip(flat(a), flat(b)) if (p[3] >= 128) != (q[3] >= 128) or (p[3] >= 128 and p[:3] != q[:3]))


def single(out: Path | None) -> list[dict]:
    cases = []
    for i, (scale, jitter, blur, noise) in enumerate(SINGLE):
        truth = synth.sprite(100 + i, (24, 32))
        fake, xs, ys = synth.fake(truth, scale, jitter, blur, noise, (0, 0, 255), 3, 7 + i)
        opts = pipeline.Options(palette=",".join("#%02X%02X%02X" % c for c in from_image(truth).colors),
                                outline="keep", fit=False)
        native, info = pipeline.snap(fake, opts)
        final, _ = pipeline.finish(native, opts, contracts.get("free"), pipeline.palette_for(opts, contracts.get("free")))
        ref = truth.crop(opaque_bbox(truth))
        same = final.size == ref.size
        wrong = _diff(final, ref) if same else None
        solid = sum(1 for p in flat(ref) if p[3] >= 128)
        ok = same and wrong <= max(2, solid // 100) and tuple(info["grid"]["cells"]) == (len(xs) - 1, len(ys) - 1)
        if out:
            fake.save(out / f"single_{i}_fake.png")
            final.save(out / f"single_{i}_forja.png")
        cases.append({"case": f"single scale={scale} jitter={jitter} blur={blur} noise={noise}", "ok": ok,
                      "cells": info["grid"]["cells"], "true_cells": [len(xs) - 1, len(ys) - 1],
                      "wrong_pixels": wrong, "opaque_pixels": solid})
    return cases


def sheet_case(out: Path | None) -> dict:
    truths = [synth.sprite(200 + i, (24, 30 + i % 3)) for i in range(6)]
    big = synth.sheet(truths, 3, 9.3, bg=(0, 0, 255))
    boxes, _ = sheet.find(big, (0, 0, 255))
    figures = sheet.extract(big, boxes, (0, 0, 255))
    sizes = [list(f.native.size) for f in figures]
    want = [list(t.crop(opaque_bbox(t)).size) for t in truths]
    if out:
        big.save(out / "sheet_fake.png")
    return {"case": "sheet 6 figuras", "ok": len(figures) == 6 and sizes == want, "found": len(figures),
            "sizes": sizes, "expected_sizes": want}


def aseprite_case(out: Path) -> dict:
    frames = []
    for i in range(4):
        f = Image.new("RGBA", (64, 64))
        f.alpha_composite(synth.sprite(300 + i, (24, 32)), (20, 24))
        frames.append(f)
    path = aseprite.from_frames(out / "prova.aseprite", frames, durations=[100, 100, 150, 200],
                                tags=[("idle", 0, 3, "forward")], pivot=(32, 56))
    check = aseprite.verify(path, frames)
    return {"case": "aseprite ida e volta", "ok": check["pixel_equal"] and check["durations"] == [100, 100, 150, 200]
            and "idle" in check["tags"], **check}


def tiles_case(out: Path | None, size: int = 16) -> dict:
    """O mapa montado com os 16 tiles e igual ao campo avaliado de uma vez: sem costura."""
    cols, rows, seed = 6, 4, 5
    corners = [[(i * 7 + j * 13 + seed) % 3 == 0 for i in range(cols + 1)] for j in range(rows + 1)]
    mismatched = 0
    for j in range(rows):
        for i in range(cols):
            index = corners[j][i] << 3 | corners[j][i + 1] << 2 | corners[j + 1][i] << 1 | corners[j + 1][i + 1]
            m = tiles.mask(index, size, 0.35, seed)
            for y in range(size):
                for x in range(size):
                    gx, gy = i + (x + 0.5) / size, j + (y + 0.5) / size
                    ci, cj = int(gx), int(gy)
                    u, v = gx - ci, gy - cj
                    f = (corners[cj][ci] * (1 - u) * (1 - v) + corners[cj][ci + 1] * u * (1 - v)
                         + corners[cj + 1][ci] * (1 - u) * v + corners[cj + 1][ci + 1] * u * v)
                    truth = f + 0.35 * tiles.noise(i * size + x, j * size + y, size, 4, seed) > 0.5
                    mismatched += m[y][x] != truth
    return {"case": "tiles Wang sem costura", "ok": mismatched == 0, "mismatched_pixels": mismatched}


def lint_case() -> dict:
    good = Image.new("RGBA", (64, 64))
    good.alpha_composite(synth.sprite(400, (24, 34)), (20, 56 - 33))
    pal = from_image(good)
    clean = lint.check(good, contracts.get("character_s1"), pal)
    bad = good.copy()
    bad.putpixel((2, 2), (255, 255, 255, 255))
    bad.putpixel((40, 40), (1, 2, 3, 200))
    dirty = lint.check(bad, contracts.get("character_s1"), pal)
    rules = {f["rule"] for f in dirty["findings"]}
    return {"case": "lint", "ok": clean["ok"] and {"orphans", "alpha", "palette"} <= rules,
            "clean_findings": [f["rule"] for f in clean["findings"]], "dirty_rules": sorted(rules)}


def run(out: Path | None = None) -> dict:
    work = out or Path("build/forja-prova")
    work.mkdir(parents=True, exist_ok=True)
    cases = single(out) + [sheet_case(out), aseprite_case(work), tiles_case(out), lint_case()]
    return {"ok": all(c["ok"] for c in cases), "passed": sum(c["ok"] for c in cases), "total": len(cases),
            "cases": cases}


def bench(count: int, seed: int = 42) -> dict:
    """Bancada pesada (nao e portao): sprites, escalas 3-40 px, celulas desiguais ate 12%,
    desfoque, ruido e tres chaves, sorteados de forma fixa. Mede quantos voltam certos."""
    rnd = random.Random(seed)
    failures = []
    for case in range(count):
        w = rnd.choice([16, 20, 24, 32, 40, 48])
        h = int(w * rnd.uniform(1.0, 1.6))
        scale = min(rnd.uniform(3.0, 40.0), 1600 / max(w, h))
        jitter, blur = rnd.uniform(0, 0.12) * scale, rnd.uniform(0, 0.12) * scale if rnd.random() < 0.8 else 0
        noise, bg = rnd.randint(0, 12), rnd.choice([(255, 0, 255), (0, 255, 0), (0, 0, 255)])
        truth = synth.sprite(1000 + case, (w, h))
        fake, _, _ = synth.fake(truth, scale, jitter, blur, noise, bg, 3, case)
        opts = pipeline.Options(palette=",".join("#%02X%02X%02X" % c for c in from_image(truth).colors),
                                outline="keep", fit=False)
        native, info = pipeline.snap(fake, opts)
        final, _ = pipeline.finish(native, opts, contracts.get("free"), pipeline.palette_for(opts, contracts.get("free")))
        ref = truth.crop(opaque_bbox(truth))
        solid = sum(1 for p in flat(ref) if p[3] >= 128)
        wrong = _diff(final, ref) if final.size == ref.size else None
        if wrong is None or wrong > max(2, solid // 100):
            failures.append({"case": case, "scale": round(scale, 2), "jitter": round(jitter, 2), "blur": round(blur, 2),
                             "noise": noise, "size": list(final.size), "expected": list(ref.size), "wrong": wrong})
    return {"ok": True, "cases": count, "exact_or_within_1pct": count - len(failures), "failures": failures}
