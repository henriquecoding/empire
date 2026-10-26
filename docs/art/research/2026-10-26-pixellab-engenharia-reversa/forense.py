#!/usr/bin/env python3
"""Medir imagens publicas sem as redistribuir: escala, grade, cores, alfa e metadados.

Recebe uma pasta de imagens (descarregadas por GET publico, fora do
repositorio) e um ficheiro `fetch.log` com linhas "<estado> <caminho> <ficheiro>".
Grava so medidas, o URL e o SHA-256 de cada imagem. As medidas:

- `exact_scale`: o maior k (1 a 16) em que a imagem e uma ampliacao exata por
  vizinho mais proximo (todos os blocos k x k de uma so cor RGBA). k = 1 diz que
  nao ha blocos maiores que um pixel: arte nativa ou imagem que nao e pixel art.
- a grade que a Forja estima (tools/forja/grid) e a que ela aceita (tools/forja/gridcheck).
- cores opacas, pares de cores quase iguais (distancia OKLab < 0.02, o sinal de
  geracao em cor continua sem paleta indexada) e a classe do alfa (binario ou com
  meios-tons).
- metadados: os tipos de bloco PNG, as chaves de texto, e se ha C2PA (`caBX`) ou EXIF.

Nada aqui identifica o modelo que gerou a imagem: sao medidas para comparar com
hipoteses (ver DOSSIE.md). Imagens promocionais podem ter sido escolhidas e
retocadas; ecras de interface nao sao saidas de modelo. O papel de cada imagem
(saida de modelo, imagem do utilizador, ecra) vem de ROLES, escrito por quem leu
a pagina. `forja_grid_estimate` e o estimador sozinho; `forja_grid_checked`, a
grade com as salvaguardas de tools/forja/gridcheck.py.

    python3 -I forense.py --images /tmp/imgs --base https://www.pixellab.ai --output forense-imagens.json
"""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[3]))

from PIL import Image  # noqa: E402

from tools.forja import color, grid, gridcheck  # noqa: E402

NEAR = 0.02
MAX_PAIR_COLORS = 600
# Papel de cada imagem, atribuido por quem leu a pagina onde ela aparece (nao e um detector).
ROLES = {
    "model_output": ("final-mage", "fixed-head", "human-mage", "step1-result", "step5", "pirate",
                     "generate_", "resultsa2a", "views-and-directions", "sand-ocean-tileset"),
    "user_input": ("init-image", "start-init", "framerefa2a", "template-skeleton"),
}


def png_chunks(raw: bytes) -> dict:
    if not raw.startswith(b"\x89PNG\r\n\x1a\n"):
        return {}
    pos, types, keys = 8, [], []
    while pos + 8 <= len(raw):
        length, kind = struct.unpack(">I4s", raw[pos:pos + 8])
        kind = kind.decode("latin-1")
        types.append(kind)
        if kind in ("tEXt", "iTXt", "zTXt"):
            keys.append(raw[pos + 8:pos + 8 + min(length, 80)].split(b"\0", 1)[0].decode("latin-1"))
        pos += 12 + length
        if kind == "IEND":
            break
    return {"chunks": sorted(set(types)), "text_keys": keys, "c2pa": "caBX" in types,
            "exif": "eXIf" in types, "animated": "acTL" in types}


def exact_scale(im: Image.Image) -> int:
    w, h = im.size
    px = im.load()
    for k in range(16, 1, -1):
        if w % k or h % k:
            continue
        if all(px[x, y] == px[x - x % k, y - y % k] for y in range(h) for x in range(w)):
            return k
    return 1


def color_stats(im: Image.Image) -> dict:
    data = list(im.get_flattened_data() if hasattr(im, "get_flattened_data") else im.getdata())
    alpha = [a for *_, a in data]
    partial = sum(1 for a in alpha if 0 < a < 255)
    opaque = sorted({(r, g, b) for r, g, b, a in data if a == 255})
    stats = {"opaque_colors": len(opaque), "alpha_zero": alpha.count(0), "alpha_partial": partial,
             "alpha_class": "none" if min(alpha) == 255 else ("binary" if partial == 0 else "graded")}
    if len(opaque) <= MAX_PAIR_COLORS:
        labs = [color.oklab(c) for c in opaque]
        near = sum(1 for i in range(len(labs)) for j in range(i + 1, len(labs))
                   if color.dist2(labs[i], labs[j]) < NEAR * NEAR)
        stats["near_duplicate_pairs"] = near
        stats["colors_with_a_near_twin"] = len({i for i in range(len(labs)) for j in range(len(labs))
                                                 if i != j and color.dist2(labs[i], labs[j]) < NEAR * NEAR})
    else:
        stats["near_duplicate_pairs"] = None
    return stats


def frames(im: Image.Image) -> list[Image.Image]:
    out = []
    for i in range(getattr(im, "n_frames", 1)):
        im.seek(i)
        out.append(im.convert("RGBA").copy())
    return out


def measure(path: Path) -> dict:
    raw = path.read_bytes()
    with Image.open(path) as im:
        fmt, mode, size = im.format, im.mode, im.size
        seq = frames(im)
    first = seq[0]
    scale = exact_scale(first)
    native = first.resize((first.width // scale, first.height // scale), Image.NEAREST) if scale > 1 else first
    estimate, checked = grid.detect(first), gridcheck.detect(first)
    distinct = len({hashlib.sha256(f.tobytes()).hexdigest() for f in seq})
    return {
        "sha256": hashlib.sha256(raw).hexdigest(), "bytes": len(raw), "format": fmt, "mode": mode,
        "size": list(size), "frames": len(seq), "distinct_frames": distinct,
        "exact_scale": scale, "logical_size": list(native.size),
        "forja_grid_estimate": {"cells": list(estimate.size), "period": [round(p, 2) for p in estimate.period],
                                "native": estimate.native, "confidence": round(estimate.confidence, 3)},
        "forja_grid_checked": {"cells": list(checked.size), "native": checked.native, "notes": checked.notes},
        "logical": color_stats(native), "metadata": png_chunks(raw),
    }


def role(url: str) -> str:
    name = url.rsplit("/", 1)[-1]
    return next((r for r, keys in ROLES.items() if any(k in name for k in keys)), "ui_screenshot")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--images", type=Path, required=True)
    parser.add_argument("--base", default="https://www.pixellab.ai")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    rows = []
    for line in (args.images / "fetch.log").read_text().splitlines():
        status, url_path, name = line.split()
        if status != "200":
            continue
        m = measure(args.images / name)
        rows.append({"url": args.base + url_path, "role": role(url_path), **m})
    art = [r for r in rows if r["role"] == "model_output"]
    summary = {
        "images": len(rows), "model_outputs": len(art), "roles": {k: sum(r["role"] == k for r in rows)
                                                                for k in (*ROLES, "ui_screenshot")},
        "exact_upscale_gt1": sum(r["exact_scale"] > 1 for r in art),
        "scales": sorted({r["exact_scale"] for r in art}),
        "with_c2pa": sum(r["metadata"].get("c2pa", False) for r in rows),
        "with_exif": sum(r["metadata"].get("exif", False) for r in rows),
        "with_text_chunks": sum(bool(r["metadata"].get("text_keys")) for r in rows),
        "art_alpha_classes": {c: sum(r["logical"]["alpha_class"] == c for r in art) for c in ("none", "binary", "graded")},
        "art_with_near_duplicate_colors": sum((r["logical"].get("near_duplicate_pairs") or 0) > 0 for r in art),
        "art_opaque_colors_range": [min(r["logical"]["opaque_colors"] for r in art),
                                    max(r["logical"]["opaque_colors"] for r in art)] if art else None,
        "estimate_wrong_on_outputs": sum(r["forja_grid_estimate"]["cells"] != r["logical_size"] for r in art),
        "checked_wrong_on_outputs": sum(r["forja_grid_checked"]["cells"] != r["logical_size"] for r in art),
    }
    report = {"near_threshold_oklab": NEAR, "summary": summary, "images": rows,
              "limits": ["Imagens de documentacao: escolhidas pelo fornecedor, modelo e versao desconhecidos.",
                         "Uma ampliacao exata ou nativa diz como o ficheiro foi gravado, nao como foi gerado."]}
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary))


if __name__ == "__main__":
    main()
