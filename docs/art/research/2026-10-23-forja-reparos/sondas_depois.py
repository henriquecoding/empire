#!/usr/bin/env python3
"""As nove sondas da auditoria (F01-F09), refeitas contra a Forja reparada. Sem rede, sem chaves, sem gasto.

Mesmos cenarios de `../2026-10-23-pixellab/reproduce_forja_findings.py`, com a API
nova (o plano por gerador, os jobs duraveis, a revisao separada). O script da
auditoria continua no repositorio como registo do que se viu no commit 68ed1c8;
ele para no F02 porque o pedido que sondava agora e recusado localmente.

    python3 docs/art/research/2026-10-23-forja-reparos/sondas_depois.py --out observacoes-depois.json
"""
from __future__ import annotations

import argparse
import base64
import io
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from unittest import mock

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))
from tools.forja import cli, cmd_ai, contracts, godot, inpaint, jobs, pipeline, sheetforge  # noqa: E402
from tools.forja.backends import http, pixellab_api  # noqa: E402

ENV = {"PIXELLAB_API_KEY": "synthetic-test-token", "GEMINI_API_KEY": "synthetic-test-token"}


def png(image: Image.Image) -> bytes:
    buf = io.BytesIO()
    image.save(buf, "PNG")
    return buf.getvalue()


class Server:
    def __init__(self, *script):
        self.script, self.requests = list(script), []

    def __call__(self, req):
        self.requests.append(req)
        item = self.script.pop(0)
        if isinstance(item, BaseException):
            raise item
        return http.Response(item[0], json.dumps(item[1]).encode(), item[2] if len(item) > 2 else {})


def f01() -> dict:
    out = {}
    for name, answer in (("503", (503, {"error": "synthetic upstream failure"})), ("timeout", TimeoutError("lost"))):
        server = Server(answer, (200, {}))
        try:
            http.send(http.Request("POST", "https://example.invalid/generate", {}, b"{}"), server, sleep=lambda _: None)
        except http.ApiError as err:
            out[name] = {"post_attempts": len(server.requests), "outcome": err.outcome}
    with tempfile.TemporaryDirectory() as d, mock.patch.dict(os.environ, ENV):
        c = pixellab_api.call("x", 64, 64)
        job = jobs.create(c, d)
        first = Server(TimeoutError("accepted, answer lost"))
        try:
            jobs.execute(job, c, first, sleep=lambda _: None)
        except jobs.Ambiguous:
            pass
        again = Server()
        try:
            jobs.execute(jobs.load(job.path), c, again, sleep=lambda _: None)
        except jobs.Ambiguous:
            pass
        out["lost_response"] = {"state": job.state, "posts_first_run": len(first.requests),
                                "posts_after_reload": len(again.requests)}
    return out


def provider(backend: str, temp: Path) -> dict:
    ref = temp / "reference.png"
    Image.new("RGBA", (64, 64), "red").save(ref)
    argv = ["auto", "comic knight", "-o", str(temp / backend), "--backend", backend, "--attempts", "1"]
    argv += (["--kind", "royal_64", "--reference", str(ref)] if backend == "pixellab"
             else ["--kind", "character_s2", "--tags", "walk:8"])
    seen = []

    def capture(req):
        seen.append(req)
        raise http.SubmissionUnknown(backend, "sonda: parar antes de qualquer resposta")

    with mock.patch.dict(os.environ, ENV):
        args = cli.build_parser().parse_args(argv)
        plan = cmd_ai._plan(args).data
        cmd_ai.do_auto(args, transport=capture)
        refused = cmd_ai.do_auto(cli.build_parser().parse_args(
            ["auto", "x", "-o", str(temp / "bad"), "--backend", backend, "--kind", "character_s2",
             "--reference", str(ref)] + (["--tags", "walk:8"] if backend == "pixellab" else ["--model", "nope"])))
    body = json.loads(seen[0].body)
    if backend == "pixellab":
        return {"kind": "royal_64", "sent_size": body["image_size"], "reference_field": "init_image" in body,
                "reference_is_the_file": base64.b64decode(body["init_image"]["base64"]) == ref.read_bytes(),
                "reference_sha256_in_plan": plan["references"][0]["sha256"],
                "invalid_plan_errors": refused.get("errors"), "invalid_plan_network": refused.get("network")}
    images = [p for p in body["input"] if p["type"] == "image"]
    return {"plan_logical_canvas": plan["expect"]["cells"], "content_box": plan["expect"]["content"],
            "sent_format": body["response_format"], "estimated_output": plan["request"]["estimated_output"],
            "grid": plan["expect"]["grid"], "attachments_promised": [a["role"] for a in plan["attachments"]],
            "attached_images": len(images), "invalid_model_errors": refused.get("errors")}


def f04() -> dict:
    native = Image.new("RGBA", (16, 16))
    ImageDraw.Draw(native).rectangle((4, 4, 11, 11), fill="#0000FF")

    def echo(_prompt, images, *_a, **_kw):
        return {"images": [images[0]], "model": "synthetic/echo", "job": {"id": "local"}}

    with mock.patch("tools.forja.backends.openai_images.edit", side_effect=echo):
        result, info = inpaint.run(native, (4, 4, 12, 12), "leave unchanged")
    return {"opaque_before": sum(a > 0 for a in native.getchannel("A").tobytes()),
            "opaque_after": sum(a > 0 for a in result.getchannel("A").tobytes()),
            "byte_identical": result.tobytes() == native.tobytes(), "key_used": info["key"],
            "changed_pixels": info["changed_pixels"]}


def f05() -> dict:
    im = Image.new("RGBA", (16, 16))
    ImageDraw.Draw(im).rectangle((5, 5, 10, 10), fill="red")
    im.putpixel((7, 7), (0, 0, 0, 0))
    im.putpixel((1, 1), (255, 255, 0, 255))
    out = {}
    for kind in ("free", "royal_64", "fx", "prop"):
        c = contracts.get(kind)
        res, info = pipeline.finish(im, pipeline.Options(kind=kind, noise=0, fit=False, outline="keep"), c, None)
        k = c.cluster
        out[kind] = {"policy": info["cleanup"]["policy"], "isolated_pixel_alpha": res.getpixel((k, k))[3],
                     "hole_alpha": res.getpixel((7 * k, 7 * k))[3], "cluster": k}
    return out


def animation(temp: Path, shifted: bool) -> dict:
    im = Image.new("RGBA", (64, 32))
    draw = ImageDraw.Draw(im)
    for i in range(2):
        y = 14 - (4 if shifted and i else 0)
        draw.rectangle((i * 32 + 12, y, i * 32 + 19, y + 11), fill="red")
    source = temp / ("jump.png" if shifted else "duplicates.png")
    im.resize((256, 128), Image.Resampling.NEAREST).save(source)
    r = sheetforge.forge_sheet(source, temp / source.stem, pipeline.Options(kind="free", scale=4),
                               sheetforge.SheetOptions(tags=[("jump" if shifted else "walk", 2)], layout=(2, 1)))
    return {"ok": r["ok"], "contract_valid": r["review"]["contract_valid"],
            "needs_regeneration": r["review"]["needs_regeneration"], "artistic_approval": r["review"]["artistic_approval"],
            "feet": r["metrics"]["feet"], "distinct_rasters": r["metrics"]["distinct_rasters"],
            "alignment": r["metrics"]["alignment"],
            "blocking": [c["check"] for c in r["review"]["motion_checks"] if c["status"] == "fail"]}


def f08() -> dict:
    import re
    text = godot.sprite_frames("res://synthetic.png", [(0, 0, 4, 4), (4, 0, 4, 4), (8, 0, 4, 4)],
                               [100, 200, 300], [("reverse_example", 0, 2, "reverse")])
    seq = re.findall(r'"duration": ([\d.]+),\n"texture": SubResource\("AtlasTexture_(\d+)"\)', text)
    return {"expected_indices": [2, 1, 0], "exported_indices": [int(i) for _, i in seq],
            "duration_multipliers": [float(d) for d, _ in seq]}


def f09() -> dict:
    t = [0.0]

    def sleep(s):
        t[0] += s

    with mock.patch.dict(os.environ, ENV):
        c = pixellab_api.call("x", 64, 64)
        job = jobs.create(c)
        server = Server((200, {"background_job_id": "synthetic-job"}), *[(200, {"status": "processing"})] * 500)
        try:
            jobs.execute(job, c, server, poll=pixellab_api.poll_call, deadline=120, sleep=sleep, clock=lambda: t[0],
                         rand=lambda: 0.5)
        except jobs.Timeout:
            pass
        empty = jobs.create(c)
        try:
            jobs.execute(empty, c, Server((200, {"background_job_id": "j"}), (200, {"status": "completed"})),
                         poll=pixellab_api.poll_call, sleep=lambda _: None)
        except jobs.JobError:
            pass
    return {"get_attempts": len(server.requests) - 1, "state": job.state, "remote_id_kept": job.data["remote_id"],
            "fake_seconds_elapsed": round(t[0], 1), "deadline_s": 120, "empty_success_state": empty.state,
            "empty_success_error": empty.data["error"][:12]}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path)
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="forja-sondas-") as folder:
        temp = Path(folder)
        observations = {"F01_post_retries": f01(), "F02_pixellab_request": provider("pixellab", temp),
                        "F03_gemini_request_and_guides": provider("gemini", temp), "F04_inpaint_blue": f04(),
                        "F05_cleanup_details": f05(), "F06_jump_offsets": animation(temp, True),
                        "F07_duplicate_motion": animation(temp, False), "F08_godot_reverse": f08(),
                        "F09_job_polling": f09()}
    result = {"scope": "local_synthetic_observations_no_network", "audited_commit":
              "68ed1c87461f5d39dd21fb664eef2930ddeaac81", "checkout_commit": subprocess.check_output(
                  ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(), "observations": observations}
    text = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if args.out:
        args.out.write_text(text, encoding="utf-8")
    print(text, end="")


if __name__ == "__main__":
    main()
