#!/usr/bin/env python3
"""As sondas da auditoria de 27/10 (B01-B16): o que a Forja faz em cada caso, sem rede, sem chaves, sem gasto.

Regista o comportamento observado; nao decide se e defeito (isso esta no README). Corre igual contra o codigo
antes e depois dos reparos, para o antes/depois sair do mesmo cenario:

    python3 docs/art/research/2026-10-27-forja-auditoria/sondas.py --root <checkout> --out observacoes-depois.json
"""
from __future__ import annotations

import argparse
import base64
import io
import json
import os
import random
import subprocess
import sys
import tempfile
from pathlib import Path
from unittest import mock

HERE = Path(__file__).resolve().parent
ENV = {"OPENAI_API_KEY": "synthetic-test-token", "GEMINI_API_KEY": "synthetic-test-token",
       "PIXELLAB_API_KEY": "synthetic-test-token"}


def png(image) -> bytes:
    buf = io.BytesIO()
    image.save(buf, "PNG")
    return buf.getvalue()


def probe(fn):
    """Uma sonda que rebenta regista o rebentamento: e uma observacao, nao um erro do script."""
    try:
        return fn()
    except Exception as err:  # noqa: BLE001
        return {"crash": f"{type(err).__name__}: {str(err)[:160]}"}


def b01_gemini():
    from PIL import Image
    from tools.forja.backends import gemini_images
    draft, final = png(Image.new("RGBA", (4, 4), (200, 10, 10, 255))), png(Image.new("RGBA", (4, 4), (10, 200, 10, 255)))
    enc = lambda d: base64.b64encode(d).decode()  # noqa: E731
    body = {"steps": [{"type": "thought", "summary": [{"type": "image", "data": enc(draft), "mime_type": "image/png"}]},
                      {"type": "model_output", "content": [{"type": "image", "data": enc(final), "mime_type": "image/png"}]}],
            "output_image": {"data": enc(final), "mime_type": "image/png"}}
    r = gemini_images.parse(body)
    return {"images": len(r.images), "first_is_final": r.images[:1] == [final]}


def _truth(seed, pal):
    from tools.forja import synth
    rnd = random.Random(seed)
    img = synth.sprite(seed, (24, 32))
    px = img.load()
    cols = sorted({px[x, y][:3] for y in range(img.height) for x in range(img.width) if px[x, y][3]} - {(0, 0, 0)})
    swap = {c: rnd.choice(pal.colors) for c in cols}
    for y in range(img.height):
        for x in range(img.width):
            if px[x, y][3] and px[x, y][:3] in swap:
                px[x, y] = (*swap[px[x, y][:3]], 255)
    return img


def _degrade(img, k, mode, rnd):
    from PIL import Image
    big = img.resize((img.width * k, img.height * k), Image.Resampling.NEAREST)
    out = Image.new("RGB", (big.width + 2 * k, big.height + 2 * k), (255, 0, 255))
    out.paste(big, (k, k), big)
    if mode.startswith("jpeg"):
        buf = io.BytesIO()
        out.save(buf, "JPEG", quality=int(mode[4:]))
        return Image.open(io.BytesIO(buf.getvalue())).convert("RGBA")
    sigma, px = float(mode[5:]), out.load()
    for y in range(out.height):
        for x in range(out.width):
            px[x, y] = tuple(max(0, min(255, round(v + rnd.gauss(0, sigma)))) for v in px[x, y])
    return out.convert("RGBA")


def b02_vote():
    from PIL import Image
    from tools.forja import grid as gridmod, palette as palmod, resample
    rnd = random.Random(1)
    cells = {}
    for base in [(128, 64, 200), (16, 32, 48), (100, 150, 90)]:
        wrong = 0
        for _ in range(50):
            im = Image.new("RGBA", (20, 20))
            im.putdata([tuple(max(0, min(255, round(v + rnd.gauss(0, 3)))) for v in
                              (base if rnd.random() < 0.6 else (40, 40, 40) if base[0] > 60 else (200, 200, 200)))
                        + (255,) for _ in range(400)])
            got = resample.resample(im, gridmod.known(im.size, 20)).image.getpixel((0, 0))[:3]
            wrong += sum(abs(a - b) for a, b in zip(got, base)) > 30
        cells[str(base)] = f"{wrong}/50"
    pal = palmod.load("empire")
    sprites = {}
    for mode in ("noise4", "noise6", "jpeg85", "jpeg75"):
        rnd, bad, total = random.Random(5), 0, 0
        for seed in range(6):
            truth = _truth(seed, pal)
            src = _degrade(truth, 12, mode, rnd)
            s = resample.resample(src, gridmod.known(src.size, 12)).image
            for y in range(truth.height):
                for x in range(truth.width):
                    t = truth.getpixel((x, y))
                    if t[3]:
                        total += 1
                        bad += max(abs(a - b) for a, b in zip(t[:3], s.getpixel((x + 1, y + 1))[:3])) > 6
        sprites[mode] = f"{bad}/{total}"
    near = sum(any(0 < v < 255 and min(v % 16, 16 - v % 16) <= 3 for v in c) for c in pal.colors)
    return {"boundary_cells_wrong": cells, "sprite_pixels_off_by_more_than_6": sprites,
            "palette_colors_near_a_bucket_edge": f"{near}/{len(pal)}"}


def b03_budget():
    from tools.forja import jobs
    from tools.forja.backends import http, openai_images
    d = tempfile.mkdtemp()
    posts = []

    def server(req):
        posts.append(req)
        return http.Response(200, json.dumps({"data": [{"b64_json": base64.b64encode(png(_blank())).decode()}]}).encode(), {})
    budgets = [jobs.Budget.open(d, 1), jobs.Budget.open(d, 1)]  # dois processos na mesma pasta, teto 1
    out = []
    with mock.patch.dict(os.environ, ENV):
        for b in budgets:
            call = openai_images.generate_call("knight", "1024x1024")
            out.append(probe(lambda: jobs.execute(jobs.create(call, d), call, server, budget=b) and "sent"))
    return {"posts_with_cap_1": len(posts), "results": out,
            "budget_json_calls": json.loads((Path(d) / "budget.json").read_text())["calls"]}


def _blank():
    from PIL import Image
    return Image.new("RGBA", (8, 8), (10, 20, 30, 255))


def b04_b11_b12_mcp():
    from tools.forja import mcp_server
    lines = ["[]", "42", '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":[1]}',
             '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"forja_nada"}}',
             '{"jsonrpc":"2.0","id":3,"method":"initialize","params":{"protocolVersion":"2025-06-18"}}',
             '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"forja_kinds","arguments":{}}}']
    seen = []
    for line in lines:
        out = io.StringIO()
        r = probe(lambda: mcp_server.serve(io.StringIO(line + "\n"), out))
        reply = json.loads(out.getvalue()) if out.getvalue() else None
        seen.append(r if isinstance(r, dict) else {"error": (reply or {}).get("error", {}).get("code"),
                                                   "isError": ((reply or {}).get("result") or {}).get("isError"),
                                                   "structured": "structuredContent" in ((reply or {}).get("result") or {})})
    tools = {t["name"]: t for t in mcp_server.tools()}
    return {"replies": dict(zip(["[]", "42", "params lista", "ferramenta desconhecida", "initialize", "kinds"], seen)),
            "generate_annotations": tools["forja_generate"].get("annotations")}


def b05_outline():
    from PIL import Image
    from tools.forja import outline, pipeline
    body = Image.new("RGBA", (16, 24))
    body.paste((186, 52, 60, 255), (2, 2, 14, 22))
    spr = outline.add(body, (0, 0, 0), 1)
    for y in range(1, 23):
        spr.putpixel((1, y), (0, 0, 0, 0))
    for x in range(1, 15):
        spr.putpixel((x, 22), (0, 0, 0, 0))
    d = Path(tempfile.mkdtemp())
    spr.resize((96, 144), Image.Resampling.NEAREST).save(d / "p.png")
    res = pipeline.forge(d / "p.png", d / "o", pipeline.Options(kind="character_s1", palette="none", fit=False),
                         report_html=False)
    fin = Image.open(res["files"]["png"]).convert("RGBA")
    mark = lambda p: "." if p[3] < 128 else ("#" if p[:3] == (0, 0, 0) else "r")  # noqa: E731
    return {"middle_row": "".join(mark(fin.getpixel((x, fin.height // 2))) for x in range(fin.width)),
            "outline_findings": [f["rule"] for f in res["lint"]["findings"] if f["rule"].startswith("outline")]}


def b06_b07_open():
    from PIL import Image
    from tools.forja.imageops import open_rgba
    sys.path.insert(0, str(Path(__file__).resolve().parents[4] / "tools" / "forja" / "tests"))
    d = Path(tempfile.mkdtemp())
    ex = Image.Exif()
    ex[0x0112] = 6
    Image.new("RGB", (200, 100), (255, 0, 255)).save(d / "foto.png", exif=ex.tobytes())
    from helpers import linear_profile  # o perfil ICC de teste, escrito no repositorio de depois
    Image.new("RGB", (4, 4), (128, 128, 128)).save(d / "linear.png", icc_profile=linear_profile())
    return {"exif6_200x100_opened_as": list(open_rgba(d / "foto.png").size),
            "linear_gray128_reads_as": open_rgba(d / "linear.png").getpixel((0, 0))[0], "srgb_expected": 188}


def b08_hash():
    from PIL import Image
    from tools.forja import refs
    d = Path(tempfile.mkdtemp())
    a = Image.new("RGBA", (8, 8), (255, 0, 255, 0))
    a.putpixel((3, 3), (10, 200, 30, 255))
    a.save(d / "m.png")
    refs.add(d / "r.json", d / "m.png", "adaptation_in_review", "rei", by="sonda")
    b = Image.new("RGBA", (8, 8))
    b.putpixel((3, 3), (10, 200, 30, 255))
    b.save(d / "m.png")
    return probe(lambda: {"register_after_resave": "valid" if refs.load(d / "r.json") else "?"})


def b09_fsync():
    from tools.forja import jobs
    from tools.forja.backends import openai_images
    with mock.patch("os.fsync") as sync, mock.patch.dict(os.environ, ENV):
        jobs.create(openai_images.generate_call("knight"), tempfile.mkdtemp())
    return {"fsync_calls_writing_a_planned_job": sync.call_count}


def b10_windows_pipe(root: Path):
    """O servidor arrancado como no Windows: a codificacao do pipe e cp1252, o cliente manda UTF-8. Um ficheiro que
    existe numa pasta com acentos; "Á" e C3 81 em UTF-8, e 0x81 nao existe no cp1252."""
    from PIL import Image
    folder = Path(tempfile.mkdtemp()) / "cenários"
    folder.mkdir()
    Image.new("RGBA", (64, 64)).save(folder / "Árvore.png")
    msgs = [{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {
        "name": "forja_lint", "arguments": {"image": str(folder / "Árvore.png"), "kind": "royal_64"}}},
        {"jsonrpc": "2.0", "id": 2, "method": "ping"}]
    data = "".join(json.dumps(m, ensure_ascii=False) + "\n" for m in msgs).encode("utf-8")
    r = subprocess.run([sys.executable, "-m", "tools.forja", "mcp"], input=data, cwd=root, capture_output=True,
                       env={**os.environ, "PYTHONIOENCODING": "cp1252", "PYTHONUTF8": "0"}, timeout=60)
    replies = [json.loads(x) for x in r.stdout.decode("utf-8", "replace").splitlines() if x.strip()]
    first = next(((x.get("result") or {}).get("content", [{}])[0].get("text", "") for x in replies
                  if x.get("id") == 1), "")
    return {"jsonrpc_replies": sum("jsonrpc" in x for x in replies), "other_stdout": [x for x in replies
                                                                          if "jsonrpc" not in x][:1],
            "lint_ran_on_the_file": '"kind": "royal_64"' in first,
            "error": first[:120] if "Error" in first[:40] else None, "exit": r.returncode,
            "stderr_last": (r.stderr.decode("utf-8", "replace").strip().splitlines() or [""])[-1][:120]}


def b13_bomb(root: Path):
    code = ("import sys; from PIL import Image; Image.MAX_IMAGE_PIXELS = 1000; from tools.forja import cli; "
            "Image.new('1', (100, 100)).save(sys.argv[1]); sys.exit(cli.main(['lint', sys.argv[1], '--kind', 'royal_64']))")
    path = Path(tempfile.mkdtemp()) / "bomba.png"
    r = subprocess.run([sys.executable, "-c", code, str(path)], cwd=root, capture_output=True, text=True, timeout=60)
    return {"exit": r.returncode, "json": r.stdout.strip().startswith("{"), "traceback": "Traceback" in r.stderr}


def b14_palette_comma():
    from tools.forja import palette as palmod
    d = Path(tempfile.mkdtemp()) / "tons, quentes"
    palmod.save(palmod.Palette([(10, 20, 30)], "x"), d / "pal.gpl")
    return probe(lambda: {"loaded": palmod.load(d / "pal.gpl").hexes()})


def b15_ramp():
    from tools.forja import color, palette as palmod
    out = {}
    for base in ("#FFD000", "#2040FF", "#FF2020"):
        _, _, h = color.lch(color.parse_hex(base))
        r = palmod.ramp(color.parse_hex(base), 5)
        drift = [abs((color.lch(c)[2] - (h + palmod._hue_toward(h, 85.0) * 18 * ((i / 4 - 0.5) * 2)) + 180) % 360 - 180)
                 for i, c in enumerate(r.colors)]
        out[base] = {"ramp": r.hexes(), "max_hue_drift_deg": round(max(drift), 1)}
    return out


def b16_pixellab():
    from tools.forja.backends import pixellab_api
    live = json.loads((HERE.parent / "2026-10-26-pixellab-engenharia-reversa" / "contrato-2026-10-27.json").read_text())
    return {"adapter_spec_sha256": pixellab_api.SPEC_SHA256[:16], "spec_read_27_10": live["sha256"][:16],
            "diff": live["diff"], "conformance": live["forja_conformance"]["mismatches"]}


def o1_near_black():
    """O que fica aberto (Q-290): o preto ruidoso contra a paleta, com o L do OKLab e com o Lr de Ottosson, e quanto
    da escolha de cor mudaria se o Lr entrasse (amostra fixa do espaco sRGB). A Forja continua em OKLab."""
    import math
    from tools.forja import color, grid as gridmod, palette as palmod, resample
    k1, k2 = 0.206, 0.03
    k3 = (1 + k1) / (1 + k2)
    toe = lambda x: 0.5 * (k3 * x - k1 + math.sqrt((k3 * x - k1) ** 2 + 4 * k2 * k3 * x))  # noqa: E731
    pal = palmod.load("empire")
    labs = [color.oklab(c) for c in pal.colors]
    lr = [(toe(L), a, b) for L, a, b in labs]

    def pick(c, space):
        L, a, b = color.oklab(c)
        q = (toe(L), a, b) if space is lr else (L, a, b)
        return pal.colors[min(range(len(space)), key=lambda i: color.dist2(q, space[i]))]
    out = {}
    for mode in ("noise3", "noise4", "jpeg85"):
        rnd, black, ok_wrong, lr_wrong, rest_ok, rest_lr = random.Random(5), 0, 0, 0, 0, 0
        for seed in range(6):
            truth = _truth(seed, pal)
            src = _degrade(truth, 12, mode, rnd)
            s = resample.resample(src, gridmod.known(src.size, 12)).image
            for y in range(truth.height):
                for x in range(truth.width):
                    t = truth.getpixel((x, y))
                    if not t[3]:
                        continue
                    v = s.getpixel((x + 1, y + 1))[:3]
                    a, b = pick(v, labs) != t[:3], pick(v, lr) != t[:3]
                    if t[:3] == (0, 0, 0):
                        black, ok_wrong, lr_wrong = black + 1, ok_wrong + a, lr_wrong + b
                    else:
                        rest_ok, rest_lr = rest_ok + a, rest_lr + b
        out[mode] = {"black_px": black, "black_wrong_oklab": ok_wrong, "black_wrong_lr": lr_wrong,
                     "other_wrong_oklab": rest_ok, "other_wrong_lr": rest_lr}
    rnd = random.Random(3)
    sample = [(rnd.randrange(256), rnd.randrange(256), rnd.randrange(256)) for _ in range(20000)]
    moved = sum(pick(c, labs) != pick(c, lr) for c in sample)
    out["srgb_sample_that_would_change_palette_colour"] = f"{moved}/{len(sample)}"
    out["#020201"] = {"oklab": color.to_hex(pick((2, 2, 1), labs)), "lr": color.to_hex(pick((2, 2, 1), lr))}
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=str(HERE.parents[3]), help="o checkout a sondar (antes ou depois)")
    ap.add_argument("--out")
    a = ap.parse_args()
    root = Path(a.root).resolve()
    sys.path.insert(0, str(root))
    os.chdir(root)
    commit = subprocess.run(["git", "-C", str(root), "rev-parse", "--short", "HEAD"], capture_output=True,
                            text=True).stdout.strip()
    dirty = bool(subprocess.run(["git", "-C", str(root), "status", "--porcelain", "--", "tools/forja"],
                                capture_output=True, text=True).stdout.strip())
    result = {"commit": commit + ("+trabalho" if dirty else ""), "B01": probe(b01_gemini), "B02": probe(b02_vote),
              "B03": probe(b03_budget), "B04_B11_B12": probe(b04_b11_b12_mcp), "B05": probe(b05_outline),
              "B06_B07": probe(b06_b07_open), "B08": probe(b08_hash), "B09": probe(b09_fsync),
              "B10": probe(lambda: b10_windows_pipe(root)), "B13": probe(lambda: b13_bomb(root)),
              "B14": probe(b14_palette_comma), "B15": probe(b15_ramp), "B16": probe(b16_pixellab),
              "O1": probe(o1_near_black)}
    text = json.dumps(result, indent=1, ensure_ascii=False)
    if a.out:
        (HERE / a.out).write_text(text + "\n", encoding="utf-8")
    print(text)


if __name__ == "__main__":
    main()
