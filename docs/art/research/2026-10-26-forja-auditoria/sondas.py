#!/usr/bin/env python3
"""As sondas da auditoria de 26/10 (A01-A10): o que a Forja faz em cada caso, sem rede, sem chaves, sem gasto.

O script regista o comportamento observado; nao decide se e defeito (isso esta no README). Corre igual contra o
codigo antes e depois dos reparos, para o antes/depois sair do mesmo cenario:

    python3 docs/art/research/2026-10-26-forja-auditoria/sondas.py --out observacoes-depois.json
"""
from __future__ import annotations

import argparse
import base64
import io
import json
import os
import sys
import tempfile
from pathlib import Path
from unittest import mock

from PIL import Image

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))
from tools.forja import cli, cmd_ai, jobs, masks, mcp_server, plan, sheet, synth  # noqa: E402
from tools.forja.backends import http, pixellab_api  # noqa: E402

ENV = {"OPENAI_API_KEY": "synthetic-test-token", "GEMINI_API_KEY": "synthetic-test-token",
       "PIXELLAB_API_KEY": "synthetic-test-token"}
NO_WAIT = {"sleep": lambda _: None}


def png(image: Image.Image) -> bytes:
    buf = io.BytesIO()
    image.save(buf, "PNG")
    return buf.getvalue()


class Server:
    """Transporte falso: devolve as respostas dadas, por ordem, e guarda os pedidos."""

    def __init__(self, *answers):
        self.answers, self.requests = list(answers), []

    def __call__(self, req):
        self.requests.append(req)
        status, body = self.answers.pop(0)
        return http.Response(status, json.dumps(body).encode(), {})


def openai_answer(image: Image.Image) -> tuple:
    return 200, {"data": [{"b64_json": base64.b64encode(png(image)).decode()}]}


def gemini_answer(image: Image.Image) -> tuple:
    return 200, {"output_image": {"data": base64.b64encode(png(image)).decode(), "mime_type": "image/png"}}


def auto_args(*argv):
    return cli.build_parser().parse_args(["auto", *argv])


def guarded(fn):
    def run(tmp: Path) -> dict:
        try:
            return fn(tmp)
        except Exception as err:  # noqa: BLE001 — o que rebenta tambem e uma observacao
            return {"raised": f"{type(err).__name__}: {err}"[:300]}
    run.__doc__ = fn.__doc__
    return run


def framed(seed: int, canvas=(64, 64), pivot=(32, 62)) -> Image.Image:
    s = synth.sprite(seed, (24, 34))
    s = s.crop(s.getchannel("A").getbbox())
    out = Image.new("RGBA", canvas)
    out.alpha_composite(s, (pivot[0] - s.width // 2, pivot[1] - s.height + 1))
    return out


@guarded
def a01_exact_scale_phase(tmp: Path) -> dict:
    """Prancha ampliada 10x por vizinho mais proximo, a grelha do plano: que periodo sai de cada figura?"""
    p = plan.make("openai", "comic knight", "royal_64", [("walk", 8)])
    exp = p.data["expect"]
    lw, lh = exp["cells"]
    cols, rows = exp["layout"]
    canvas = Image.new("RGBA", (lw, lh))
    for i in range(8):
        f = framed(i).crop((8, 8, 56, 63))
        cx, cy = i % cols * (lw // cols), i // cols * (lh // rows)
        canvas.alpha_composite(f, (cx + 8, cy + 6))
    k = exp["scale"]
    big = canvas.resize((lw * k, lh * k), Image.NEAREST)
    big.save(tmp / "a01.png")
    (tmp / "a01.json").write_text(json.dumps(exp))
    with mock.patch("sys.stdout", io.StringIO()):
        code = cli.main(["sheet", str(tmp / "a01.png"), "--expect", str(tmp / "a01.json"), "-o", str(tmp / "a01")])
    res = json.loads(next((tmp / "a01").glob("*.forja.json")).read_text())
    offset = big.crop((6, 6, big.width, big.height))
    with mock.patch("sys.stdout", io.StringIO()):
        cli.main(["snap", str(tmp / "a01.png"), "-o", str(tmp / "a01_full.png")])
    offset.save(tmp / "a01_offset.png")
    snap = cli.run(["snap", str(tmp / "a01_offset.png"), "-o", str(tmp / "a01_snap.png")])
    return {"requested_scale": k, "sheet_exit": code, "periods": sorted({f["period"] for f in res["frames"]}),
            "native_sizes": [f["native_size"] for f in res["frames"]][:2],
            "contract_valid": res["review"]["contract_valid"],
            "snap_offset_6px": {"period": snap["grid"]["period"], "cells": snap["grid"]["cells"],
                                "notes": snap["grid"]["notes"]}}


@guarded
def a02_empty_sheet(tmp: Path) -> dict:
    """Uma prancha sem figuras (o gerador devolveu so o fundo): sheet e auto."""
    Image.new("RGBA", (640, 320), (255, 0, 255, 255)).save(tmp / "a02.png")
    out = {}
    try:
        res = cli.run(["sheet", str(tmp / "a02.png"), "--kind", "royal_64", "--layout", "4x2", "--tags", "walk",
                       "-o", str(tmp / "a02")])
        out["sheet"] = {"found": res["found"], "needs_regeneration": res["review"]["needs_regeneration"],
                        "prompt_feedback": res["prompt_feedback"][:160]}
    except Exception as err:  # noqa: BLE001
        out["sheet"] = {"raised": f"{type(err).__name__}: {err}"[:200]}
    a = auto_args("comic knight", "-o", str(tmp / "a02auto"), "--backend", "openai", "--kind", "royal_64",
                  "--tags", "walk:8", "--attempts", "2")
    w, h = cmd_ai._plan(a).data["expect"]["size"]
    blank = Image.new("RGBA", (w, h))
    server = Server(openai_answer(blank), openai_answer(blank))
    try:
        res = cmd_ai.do_auto(a, server, **NO_WAIT)
        out["auto"] = {"posts": len(server.requests), "states": [x["state"] for x in res["attempts"]],
                       "needs_regeneration": [(x.get("review") or {}).get("needs_regeneration") for x in res["attempts"]]}
    except Exception as err:  # noqa: BLE001
        out["auto"] = {"raised": f"{type(err).__name__}: {err}"[:200], "posts": len(server.requests)}
    out["auto"]["auto_json_written"] = (tmp / "a02auto" / "auto.json").exists()
    return out


@guarded
def a03_auto_stops_on_budget(tmp: Path) -> dict:
    """1a tentativa forjada e a pedir outra (tamanho errado); a 2a bate no teto de 1 chamada."""
    a = auto_args("comic knight", "-o", str(tmp / "a03"), "--backend", "openai", "--kind", "royal_64",
                  "--attempts", "3", "--max-calls", "1")
    wrong = framed(2).resize((1024, 1024), Image.NEAREST)
    res = cmd_ai.do_auto(a, Server(openai_answer(wrong)), **NO_WAIT)
    states = [j["state"] for j in jobs.listing(tmp / "a03")]
    return {"ok": res["ok"], "best": Path(res["best"]).name if res["best"] else None, "next": res["next"],
            "attempts": [{"state": x["state"], "forged": bool(x.get("review"))} for x in res["attempts"]],
            "job_states": sorted(states)}


@guarded
def a04_resumed_cost(tmp: Path) -> dict:
    """Um job PixelLab que esgota o prazo e e retomado por `forja jobs --resume`: o custo chega ao budget.json?"""
    budget = jobs.Budget.open(tmp, 3, 1.0)
    call = pixellab_api.call("knight", 64, 64)
    job = jobs.create(call, tmp)
    try:
        jobs.execute(job, call, Server((200, {"background_job_id": "J1"}),
                                       (200, {"status": "processing", "last_response": {}})),
                     poll=pixellab_api.poll_call, budget=budget, max_polls=1, **NO_WAIT)
    except jobs.Timeout:
        pass
    done = (200, {"status": "completed", "last_response": {
        "image": {"type": "base64", "base64": base64.b64encode(png(framed(1))).decode()},
        "usage": {"type": "usd", "usd": 0.25}}})
    with mock.patch.object(http, "urllib_transport", Server(done)):
        res = cli.run(["jobs", str(tmp), "--resume", job.id, "--deadline", "30"])
    return {"resumed_state": res["job"]["state"] if "job" in res else res.get("state"),
            "job_cost": jobs.load(job.path).data["cost"],
            "budget_json": json.loads((tmp / "budget.json").read_text())}


@guarded
def a05_corrective_language(tmp: Path) -> dict:
    """O texto das correcoes que o gerador recebe quando a grade nao foi seguida e a figura nao cabe."""
    a = auto_args("comic knight", "-o", str(tmp / "a05"), "--backend", "gemini", "--kind", "royal_64",
                  "--attempts", "2")
    exp = cmd_ai._plan(a).data["expect"]
    canvas = Image.new("RGBA", (128, 128), (*bytes.fromhex(exp["background"].lstrip("#")), 255))
    canvas.alpha_composite(synth.sprite(3, (40, 100)), (44, 20))
    image = canvas.resize((512, 512), Image.NEAREST)
    server = Server(gemini_answer(image), gemini_answer(image))
    cmd_ai.do_auto(a, server, **NO_WAIT)
    text = json.loads(server.requests[-1].body)["input"][0]["text"]
    return {"posts": len(server.requests),
            "corrections": text.split("(follow strictly):")[-1].strip() if len(server.requests) > 1 else None}


@guarded
def a06_mcp_repeatable(tmp: Path) -> dict:
    """Duas caixas --protect pelo servidor MCP, como a ajuda diz (repetivel)."""
    truth = synth.sprite(5)
    fake, _, _ = synth.fake(truth, 8.0, 0.6, 0.6, 4, (0, 0, 255), 3, 5)
    fake.save(tmp / "a06.png")
    schema = {t["name"]: t for t in mcp_server.tools()}["forja_forge"]["inputSchema"]["properties"]["protect"]
    two = mcp_server.call("forja_forge", {"image": str(tmp / "a06.png"), "out": str(tmp / "a06"),
                                          "protect": ["1,1,3,3", "5,5,7,7"]})
    return {"schema_type": schema["type"], "two_boxes_error": two["isError"],
            "message": two["content"][0]["text"][:120] if two["isError"] else None}


@guarded
def a07_mask_without_alpha(tmp: Path) -> dict:
    """Uma mascara branca sobre preto, sem canal alfa (a convencao do PixelLab), de 9 pixels."""
    m = Image.new("L", (16, 16), 0)
    m.paste(255, (2, 2, 5, 5))
    m.save(tmp / "a07.png")
    picked = masks.select(Image.new("RGBA", (16, 16), (200, 50, 50, 255)), {"mask": "a07.png"}, tmp)
    return {"marked": 9, "selected": len(picked)}


@guarded
def a08_cell_crossing(tmp: Path) -> dict:
    """Prancha de 2 celulas; a lanca da figura 0 entra 6 pixels logicos na celula 1."""
    canvas = Image.new("RGBA", (80, 40), (0, 0, 255, 255))
    canvas.alpha_composite(synth.sprite(1, (16, 30)), (12, 8))
    canvas.alpha_composite(synth.sprite(2, (16, 30)), (52, 8))
    for x in range(26, 46):
        canvas.putpixel((x, 20), (0, 0, 0, 255))
        canvas.putpixel((x, 21), (160, 160, 170, 255))
    canvas.resize((560, 280), Image.NEAREST).save(tmp / "a08.png")
    res = cli.run(["sheet", str(tmp / "a08.png"), "--layout", "2x1", "--tags", "anim:2", "--bg", "#0000FF",
                   "-o", str(tmp / "a08")])
    full = json.loads(Path(res["files"]["forja_json"]).read_text())
    return {"native_sizes": [f["native_size"] for f in full["frames"]], "contract_valid": res["review"]["contract_valid"],
            "lint_errors": [f["lint_errors"] for f in full["frames"]],
            "cell_crossing": [f.get("cell_crossing") for f in full["frames"]]}


@guarded
def a09_cli_contract(tmp: Path) -> dict:
    """Um ficheiro que nao e imagem: o resultado sai em JSON com o codigo 2, como o guia diz?"""
    (tmp / "a09.png").write_text("nao sou png")
    out = io.StringIO()
    with mock.patch("sys.stdout", out):
        try:
            code = cli.main(["lint", str(tmp / "a09.png")])
        except Exception as err:  # noqa: BLE001
            return {"raised": type(err).__name__, "json": False}
    return {"exit": code, "json": out.getvalue().strip().startswith("{")}


@guarded
def a10_height_hint(tmp: Path) -> dict:
    """A frase de altura que o lint de royal_64 manda ao gerador, quando a figura nao cabe."""
    tall = Image.new("RGBA", (64, 64))
    tall.paste((120, 40, 40, 255), (20, 0, 44, 64))
    from tools.forja import contracts, lint
    rep = lint.check(tall, contracts.get("royal_64"))
    return {"height_hints": [f["prompt_hint"] for f in rep["findings"] if f["rule"] == "height"]}


def mixed_board() -> tuple[Image.Image, list[Image.Image]]:
    """Uma figura a 8x e outra, mais baixa (agachada), a 10x, sobre fundo de chave opaco."""
    tall, low = synth.sprite(1, (18, 30)), synth.sprite(2, (18, 20))
    board = Image.new("RGBA", (420, 300), (0, 0, 255, 255))
    board.alpha_composite(tall.resize((18 * 8, 30 * 8), Image.NEAREST), (20, 20))
    board.alpha_composite(low.resize((18 * 10, 20 * 10), Image.NEAREST), (220, 60))
    return board, [tall, low]


@guarded
def o3_same_height(tmp: Path) -> dict:
    """--same-height numa prancha com pixels de 8 e de 10: que tamanho nativo sai de cada figura?"""
    board, truths = mixed_board()
    boxes, _, masks = sheet.find_masks(board, (0, 0, 255))
    figures = sheet.extract(board, boxes, (0, 0, 255), same_height=True, masks=masks)
    return {"native_sizes": [list(f.native.size) for f in figures],
            "truth_sizes": [list(t.crop(t.getchannel("A").getbbox()).size) for t in truths]}


@guarded
def o4_no_grid(tmp: Path) -> dict:
    """Uma pintura lisa de 400x400, sem grade, como royal_64: quanto tempo, e o que se pede ao gerador?"""
    import time
    from PIL import ImageFilter
    from tools.forja import pipeline
    paint = Image.new("RGBA", (400, 400))
    paint.putdata([(x % 256, (x * y) % 256, y % 256, 255) for y in range(400) for x in range(400)])
    paint.filter(ImageFilter.GaussianBlur(8)).save(tmp / "o4.png")
    t0 = time.monotonic()
    res = pipeline.forge(tmp / "o4.png", tmp / "o4", pipeline.Options(kind="royal_64"), report_html=False)
    return {"seconds": round(time.monotonic() - t0, 1), "errors": sorted(f["rule"] for f in res["lint"]["findings"]
                                                                          if f["severity"] == "error"),
            "prompt_feedback": res["lint"]["prompt_feedback"][:200]}


@guarded
def o5_clipped_hints(tmp: Path) -> dict:
    """Um retangulo com contorno cortado pela tela: que achados e que frases para o gerador?"""
    from tools.forja import contracts, lint
    img = Image.new("RGBA", (64, 64))
    img.paste((0, 0, 0, 255), (20, 30, 64, 64))
    img.paste((180, 60, 60, 255), (21, 31, 64, 64))
    rep = lint.check(img, contracts.get("royal_64"))
    return {"rules": sorted(f["rule"] for f in rep["findings"]), "prompt_feedback": rep["prompt_feedback"]}


@guarded
def o6_samplings(tmp: Path) -> dict:
    """Quantas vezes o `forge` amostra a imagem inteira (a conferencia da grade e o recorte)?"""
    from tools.forja import pipeline, resample
    fake, _, _ = synth.fake(synth.sprite(5), 8.0, 0.6, 0.6, 4, (0, 0, 255), 3, 5)
    fake.save(tmp / "o6.png")
    real, calls = resample.resample, []
    spy = lambda *a, **k: calls.append(1) or real(*a, **k)  # noqa: E731
    with mock.patch("tools.forja.resample.resample", spy), mock.patch("tools.forja.gridcheck.resample", spy):
        pipeline.forge(tmp / "o6.png", tmp / "o6", pipeline.Options(), report_html=False)
    return {"samplings": len(calls)}


@guarded
def a11_mask_edge(tmp: Path) -> dict:
    """A figura a 8x da prancha mista, sem --same-height: o periodo dela, medido no recorte com a mascara."""
    board, _ = mixed_board()
    boxes, _, masks = sheet.find_masks(board, (0, 0, 255))
    return {"periods": [f.period for f in sheet.extract(board, boxes, (0, 0, 255), masks=masks, same_height=True)]}


@guarded
def a12_downscale(tmp: Path) -> dict:
    """`forja scale --down 3` de um bloco de nove tons do mesmo balde (96-111): a cor que sai estava no bloco?"""
    from tools.forja import scale
    block = Image.new("RGBA", (3, 3))
    tones = [(v, 100, 100, 255) for v in (96, 97, 98, 99, 108, 109, 110, 111, 111)]
    block.putdata(tones)
    out = scale.downscale(block, 3).getpixel((0, 0))
    return {"out": list(out), "was_in_block": out in tones}


PROBES = {"A01": a01_exact_scale_phase, "A02": a02_empty_sheet, "A03": a03_auto_stops_on_budget,
          "A04": a04_resumed_cost, "A05": a05_corrective_language, "A06": a06_mcp_repeatable,
          "A07": a07_mask_without_alpha, "A08": a08_cell_crossing, "A09": a09_cli_contract, "A10": a10_height_hint,
          "O3": o3_same_height, "O4": o4_no_grid, "O5": o5_clipped_hints, "O6": o6_samplings,
          "A11": a11_mask_edge, "A12": a12_downscale}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", help="JSON de saida (por omissao, so imprime)")
    args = parser.parse_args()
    found = {}
    with mock.patch.dict(os.environ, ENV):
        for name, probe in PROBES.items():
            with tempfile.TemporaryDirectory(prefix=f"forja-{name}-") as tmp:
                found[name] = {"question": probe.__doc__, "observed": probe(Path(tmp))}
    text = json.dumps(found, indent=1, ensure_ascii=False) + "\n"
    if args.out:
        Path(args.out).write_text(text, encoding="utf-8")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
