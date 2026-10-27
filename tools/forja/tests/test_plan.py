"""F02 e F03: cada gerador recebe o tamanho, as referencias e as guias que aceita; o que chega e medido."""
import base64
import hashlib
import io
import json
import os
import unittest
from pathlib import Path
from unittest import mock

from PIL import Image

from tools.forja import cli, cmd_ai, color, equipment, plan, refs, synth
from tools.forja.tests.helpers import framed, tempdir
from tools.forja.tests.test_backends import ENV, Fake

NO_WAIT = {"sleep": lambda _: None}


def png_of(image) -> bytes:
    buf = io.BytesIO()
    image.save(buf, "PNG")
    return buf.getvalue()


def answer(kind: str, image) -> tuple:
    data = base64.b64encode(png_of(image)).decode()
    if kind == "pixellab":
        return 200, {"image": {"type": "base64", "base64": data}, "usage": {"type": "usd", "usd": 0.007}}
    if kind == "gemini":
        return 200, {"output_image": {"data": data, "mime_type": "image/png"}}
    return 200, {"data": [{"b64_json": data}]}


def args(*argv):
    return cli.build_parser().parse_args(["auto", *argv])


def drawn_sheet(expect: dict, k: int, frames: list) -> Image.Image:
    """Uma prancha "gerada" que segue o plano (celulas e margens), ampliada k vezes."""
    lw, lh = expect["cells"]
    x0, y0, x1, y1 = expect["content"]
    cols, rows = expect["layout"]
    cw, ch = (x1 - x0) // cols, (y1 - y0) // rows
    bg = expect["background"]
    canvas = Image.new("RGBA", (lw, lh), (0, 0, 0, 0) if bg == "transparent" else (*color.parse_hex(bg), 255))
    for i, f in enumerate(frames):
        cx, cy = x0 + i % cols * cw, y0 + i // cols * ch
        canvas.alpha_composite(f, (cx + (cw - f.width) // 2, cy + ch - f.height - 2))
    return canvas.resize((lw * k, lh * k), Image.Resampling.NEAREST)


@mock.patch.dict(os.environ, ENV)
class PixelLabPlanTest(unittest.TestCase):
    def test_royal_sizes_are_native(self):
        for kind, side in (("royal_64", 64), ("royal_80", 80), ("character_s2", 96)):
            p = plan.make("pixellab", "comic knight", kind)
            self.assertEqual(p.data["errors"], [], kind)
            body = json.loads(p.call().request().body)
            self.assertEqual(body["image_size"], {"width": side, "height": side})
            self.assertEqual(p.data["expect"]["grid"], "native")
            self.assertEqual(p.data["authoring"], "generated_native")

    def test_auto_sends_native_size_and_the_reference_in_a_documented_field(self):
        d = tempdir()
        ref = d / "approved.png"
        framed(5, (64, 64), (32, 62)).save(ref)
        fake = Fake(answer("pixellab", framed(5, (64, 64), (32, 62))))
        res = cmd_ai.do_auto(args("comic knight", "-o", str(d / "run"), "--backend", "pixellab", "--kind", "royal_64",
                                  "--reference", str(ref), "--attempts", "1"), fake, **NO_WAIT)
        body = json.loads(fake.requests[0].body)
        self.assertEqual(body["image_size"], {"width": 64, "height": 64})
        self.assertEqual(base64.b64decode(body["init_image"]["base64"]), ref.read_bytes())
        self.assertIn("color_image", body)
        job = json.loads(Path(res["attempts"][0]["job"]).read_text())
        roles = {i["role"]: i["sha256"] for i in job["descriptor"]["images"]}
        self.assertEqual(roles["init_image"], hashlib.sha256(ref.read_bytes()).hexdigest())
        self.assertEqual(res["attempts"][0]["raster"]["matches"], True)
        self.assertEqual(job["cost"]["usd"], 0.007)
        self.assertEqual(res["review"]["artistic_approval"], "pendente")

    def test_invalid_requests_fail_without_any_transport_call(self):
        d = tempdir()
        fake = Fake()
        cases = [("--kind", "colossus", "--model", "bitforge"), ("--kind", "royal_64", "--tags", "walk:4"),
                 ("--kind", "royal_64", "--model", "gpt-image-2")]
        for extra in cases:
            res = cmd_ai.do_auto(args("x", "-o", str(d / extra[1]), "--backend", "pixellab", *extra), fake)
            self.assertFalse(res["ok"], extra)
            self.assertFalse(res["network"])
            self.assertTrue(res["errors"])
        ref = d / "wrong.png"
        framed(5, (96, 96), (48, 88)).save(ref)
        res = cmd_ai.do_auto(args("x", "-o", str(d / "w"), "--backend", "pixellab", "--kind", "royal_80",
                                  "--reference", str(ref)), fake)
        self.assertIn("init_image", " ".join(res["errors"]))
        self.assertEqual(fake.requests, [])


@mock.patch.dict(os.environ, ENV)
class GeminiPlanTest(unittest.TestCase):
    def test_sheet_payload_uses_a_supported_ratio_and_the_promised_guides(self):
        tags = [("walk", 8)]
        pal_plan = plan.make("gemini", "comic knight", "royal_64", tags, guides_mode="all",
                             palette=cmd_ai._palette(args("x", "-o", "y"), "royal_64"))
        d = pal_plan.data
        self.assertEqual(d["errors"], [])
        self.assertEqual(d["request"]["aspect_ratio"], "16:9")
        self.assertEqual(d["expect"]["content"], [0, 8, 256, 136])
        body = json.loads(pal_plan.call().request().body)
        self.assertEqual(body["response_format"]["aspect_ratio"], "16:9")
        self.assertEqual(body["response_format"]["image_size"], d["request"]["image_size"])
        sent = [hashlib.sha256(base64.b64decode(p["data"])).hexdigest() for p in body["input"] if p["type"] == "image"]
        self.assertEqual(sent, [a["sha256"] for a in d["attachments"]])
        self.assertEqual([a["role"] for a in d["attachments"]], ["palette", "layout"])
        self.assertIn("image 1: the palette swatch", d["prompt"])
        self.assertIn("image 2: the layout template", d["prompt"])
        self.assertIn("Margins:", d["prompt"])

    def test_unsupported_resolution_is_an_error_not_a_crash(self):
        p = plan.make("gemini", "comic knight", "royal_64", size="8K")
        self.assertIn("resolucao 8K", " ".join(p.data["errors"]))
        p = plan.make("gemini", "comic knight", "royal_64", model="gemini-3.1-flash-lite-image", size="2K")
        self.assertFalse(p.ok)

    def test_no_promise_without_attachment(self):
        p = plan.make("gemini", "comic knight", "royal_64", [("walk", 8)], guides_mode="none",
                      palette=cmd_ai._palette(args("x", "-o", "y"), "royal_64"))
        self.assertEqual(p.data["attachments"], [])
        self.assertNotIn("attached", p.data["prompt"].lower())
        self.assertEqual(json.loads(p.call().request().body)["input"][1:], [])

    def test_auto_measures_the_return_and_does_not_assume_the_grid(self):
        d = tempdir()
        a = args("comic knight", "-o", str(d / "run"), "--backend", "gemini", "--kind", "royal_64", "--tags", "walk:8",
                 "--attempts", "1")
        p = cmd_ai._plan(a)
        frames = [synth.sprite(seed, (24, 34)) for seed in range(8)]
        image = drawn_sheet(p.data["expect"], 7, frames)
        res = cmd_ai.do_auto(a, Fake(answer("gemini", image)), **NO_WAIT)
        raster = res["attempts"][0]["raster"]
        self.assertTrue(raster["requested_is_estimate"])
        self.assertEqual(raster["received"], [256 * 7, 144 * 7])
        self.assertEqual(raster["expected_period"], 7.0)
        self.assertLess(raster["period_deviation"], 0.05)
        forged = json.loads(Path(res["attempts"][0]["files"]["forja_json"]).read_text())
        self.assertEqual(forged["found"], 8)
        self.assertEqual(forged["region"], [0, 56, 1792, 952])
        self.assertTrue(forged["review"]["contract_valid"], forged["frames"][0]["lint_errors"])

    def test_grid_not_followed_is_reported(self):
        d = tempdir()
        a = args("comic knight", "-o", str(d / "run"), "--backend", "gemini", "--kind", "royal_64", "--attempts", "1")
        expect = {**cmd_ai._plan(a).data["expect"], "cells": [128, 128], "content": [0, 0, 128, 128]}
        image = drawn_sheet(expect, 4, [framed(2, (60, 60), (30, 58))])
        res = cmd_ai.do_auto(a, Fake(answer("gemini", image)), **NO_WAIT)
        self.assertEqual(res["attempts"][0]["raster"]["expected_period"], 8.0)
        codes = [f["code"] for f in res["attempts"][0]["findings"]]
        self.assertIn("grid_not_followed", codes)


@mock.patch.dict(os.environ, ENV)
class OpenAIPlanTest(unittest.TestCase):
    def test_references_and_palette_go_to_edits_with_roles(self):
        d = tempdir()
        ref = d / "approved.png"
        framed(5, (80, 80), (40, 78)).save(ref)
        entry = {"id": "rei", "file": ref.name, "pixels_sha256": equipment.image_sha(Image.open(ref)),
                 "state": "approved", "decided_by": "Henrique", "date": "2026-10-27"}  # FORJA-06: so o registo aprova
        (d / "refs.json").write_text(json.dumps({"schema": refs.SCHEMA, "entries": [entry]}))
        p = plan.make("openai", "comic king", "royal_80", [("walk", 8)], references=[("identity", str(ref))],
                      palette=cmd_ai._palette(args("x", "-o", "y"), "royal_80"), register=refs.load(d / "refs.json"))
        self.assertEqual(p.data["request"]["endpoint"], "images.edits")
        req = p.call().request()
        self.assertEqual(req.body.count(b'name="image[]"'), 2)
        self.assertIn("image 1: the APPROVED design", p.data["prompt"])
        self.assertIn("attached image 2 (the palette swatch", p.data["prompt"])
        self.assertTrue(p.data["expect"]["scale_exact"])
        self.assertEqual(p.data["expect"]["grid"], "requested")
