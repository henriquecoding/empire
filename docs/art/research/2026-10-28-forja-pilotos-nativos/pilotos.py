"""Pilotos nativos de 28/10: os tres estaticos refeitos a partir da prancha de autoridade, na grade dela (FORJA-10).

Etapas, todas reproduziveis e cada uma com o hash dos pixels:
1. recuperar: o recorte de autoridade amostrado na grade que a propria prancha tem (periodo ~6 px, confianca
   0,94-0,96 nos tres recortes); nao e uma reducao nem uma grade escolhida para caber;
2. limpar (patches/<id>/01-*.json): o fundo preso entre partes e a sombra do chao, pixel a pixel;
3. tons (tools/forja/tones.py): o ruido do JPEG junta-se por limiar perceptual, sem teto de cores;
4. os patches seguintes (03-*, 04-*...): orcamento da tela e reparos autorizados, em forja.pixel_patch/1;
5. tela: forja forge a 1x no contrato do papel (pivo, caixa util, lint), com a paleta proposta destes pilotos.
Uso: python3 pilotos.py [--write]  (sem --write so confere; com --write grava candidatos/ e prova.json)
"""
from __future__ import annotations

import json
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(ROOT))

from PIL import Image  # noqa: E402

from tools.forja import aseprite, color, fidelity, gridcheck, occupancy, palette as palmod  # noqa: E402
from tools.forja import pipeline, pixel_patch, review_state, tones  # noqa: E402
from tools.forja.equipment import image_sha  # noqa: E402
from tools.forja.imageops import on_background, upscale  # noqa: E402

CONTRACT = HERE.parent / "2026-10-28-forja-escala-e-referencia" / "fidelidade.json"
CAST = ("rei", "escudeiro", "arqueiro_tropa")
PALETTE = HERE / "paleta-pilotos-proposta.gpl"


def recover(contract: dict, ch: dict) -> tuple[Image.Image, dict]:
    crop = fidelity.authority_crop(contract, ch).convert("RGBA")
    bg = color.to_hex(crop.getpixel((2, 2))[:3])
    grid = gridcheck.detect(crop)
    native, info = pipeline.snap(crop, pipeline.Options(palette="none", bg=bg), grid)
    g = info["grid"]
    return native, {"step": "recuperar", "grid_cells": g["cells"], "period_px": g["period"],
                    "confidence": g["confidence"], "background": bg, "size": list(native.size)}


def stages(contract: dict, ident: str, upto: str | None = None) -> tuple[Image.Image, list[dict]]:
    """A imagem depois de cada etapa ate `upto` (nome de patch, exclusivo), com o registo de cada uma; os tons
    vem logo a seguir ao patch 01 (a limpeza), para o fundo e a sombra nao entrarem nos tons."""
    ch = fidelity.character(contract, ident)
    image, rec = recover(contract, ch)
    log = [{**rec, "pixels_sha256": image_sha(image)}]
    for path in sorted((HERE / "patches" / ident).glob("*.json")):
        if upto and path.name >= upto:
            break
        image, rep = pixel_patch.apply(image, pixel_patch.load(path))
        log.append({"step": path.stem, "changed_pixels": rep["changed_pixels"], "changed_bbox": rep["changed_bbox"],
                    "reason": rep["reason"], "pixels_sha256": rep["result_pixels_sha256"]})
        if path.name.startswith("01-"):
            image, tr = tones.organize(image)
            log.append({"step": "02-tons", "input_colors": tr["input_colors"], "tones": len(tr["tones"]),
                        "pixels_sha256": image_sha(image)})
    return image, log


def _opaque(image: Image.Image) -> set[tuple[int, int, int, int]]:
    px = image.convert("RGBA").load()
    return {px[x, y] for y in range(image.height) for x in range(image.width) if px[x, y][3]}


def palette_of(images: list[Image.Image]) -> list[tuple[int, int, int]]:
    seen = {p[:3] for im in images for p in _opaque(im)}
    return sorted(seen, key=lambda c: (color.oklab(c)[0], c))


def write_palette(colors) -> None:
    lines = ["GIMP Palette", "Name: Empire pilotos 28-10 (proposta, nao aprovada)", "Columns: 16", "#",
             "# Tons tirados da prancha de autoridade (tools/forja/tones.py). Proposta para o dono: a paleta de",
             "# trabalho (art/palettes/empire_working.gpl) nao tem o vinho, o azul da capa nem a pele destes tres."]
    lines += [f"{r:3d} {g:3d} {b:3d}\t{color.to_hex((r, g, b))}" for r, g, b in colors]
    PALETTE.write_text("\n".join(lines) + "\n", encoding="utf-8")


def finish(ch: dict, image: Image.Image, out: Path) -> dict:
    src = out / f"{ch['id']}_pre.png"
    image.save(src)
    opts = pipeline.Options(kind=ch["kind"], scale=1, palette=str(PALETTE), bg=None, noise=0,
                            cleanup="conservative", outline="keep", useful_box=tuple(ch["target_useful_bbox"]))
    res = pipeline.forge(src, out / "forge", opts, name=ch["id"], report_html=False)
    final = Image.open(res["files"]["png"]).convert("RGBA")
    occ = occupancy.measure(final, tuple(ch["target_canvas"]))
    box = ch["target_useful_bbox"]
    bb = occ["opaque_bbox"]
    return {"image": final, "pixels_sha256": image_sha(final), "canvas": list(final.size), "occupancy": occ,
            "inside_useful_box": bool(bb) and box[0] <= bb[0] and box[1] <= bb[1] and bb[2] <= box[2]
            and bb[3] <= box[3], "pivot": (res["finish"].get("fit") or {}).get("pivot"),
            "clipped_pixels": (res["finish"].get("fit") or {}).get("clipped_pixels", 0),
            "colors": len(_opaque(final)), "lint_ok": res["lint"]["ok"],
            "lint_errors": [f["message"] for f in res["lint"]["findings"] if f["severity"] == "error"],
            "delivery": res["delivery"]}


def sheet(contract: dict, ch: dict, final: Image.Image, k: int = 6) -> Image.Image:
    concept = fidelity.authority_crop(contract, ch).convert("RGB")
    concept = concept.resize((round(concept.width * final.height * k / concept.height), final.height * k))
    panels = [concept] + [on_background(upscale(final, k), bg).convert("RGB") for bg in ((235, 230, 220), (34, 36, 44))]
    panels += [on_background(final, bg).convert("RGB") for bg in ((235, 230, 220), (34, 36, 44))]
    out = Image.new("RGB", (sum(p.width for p in panels) + 16 * (len(panels) + 1), final.height * k + 32), (60, 62, 70))
    x = 16
    for p in panels:
        out.paste(p, (x, 16))
        x += p.width + 16
    return out


def main(write: bool) -> dict:
    contract = fidelity.load(CONTRACT)
    result, pre = {"schema": "forja.pilotos/1", "authority_sha256": contract["authority"]["sha256"],
                   "characters": {}}, {}
    for ident in CAST:
        pre[ident] = stages(contract, ident)
    if write:
        write_palette(palette_of([im for im, _ in pre.values()]))
    with tempfile.TemporaryDirectory() as tmp:
        for ident in CAST:
            ch = fidelity.character(contract, ident)
            image, log = pre[ident]
            fin = finish(ch, image, Path(tmp))
            final = fin.pop("image")
            result["characters"][ident] = {"kind": ch["kind"], "role": ch["role"], "steps": log, **fin,
                                           "authoring": "recuperado da grade da prancha + patches nativos; nao gerado",
                                           "artistic_approval": "pending (Henrique)"}
            if write:
                cand = HERE / "candidatos"
                cand.mkdir(exist_ok=True)
                final.save(cand / f"{ident}.png")
                upscale(final, 8).save(cand / f"{ident}@8x.png")
                sheet(contract, ch, final).save(cand / f"{ident}_comparacao.png")
                review_state.sheet(contract, ch, final).save(cand / f"{ident}_fidelidade.png")
                pivot = tuple(fin["pivot"]) if fin["pivot"] else None
                aseprite.from_frames(cand / f"{ident}.aseprite", [final], pivot=pivot,
                                     palette=palmod.load(PALETTE).colors)
                result["characters"][ident]["aseprite"] = aseprite.verify(cand / f"{ident}.aseprite", [final])
    result["ok"] = all(c["lint_ok"] and c["inside_useful_box"] and not c["clipped_pixels"]
                       for c in result["characters"].values())
    if write:
        (HERE / "prova.json").write_text(json.dumps(result, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    return result


if __name__ == "__main__":
    r = main("--write" in sys.argv)
    print(json.dumps({"ok": r["ok"], **{k: {"sha": v["pixels_sha256"][:12], "bbox": v["occupancy"]["opaque_bbox"],
                                             "colors": v["colors"], "lint": v["lint_ok"]}
                                         for k, v in r["characters"].items()}}))
    sys.exit(0 if r["ok"] else 1)
