#!/usr/bin/env python3
"""Audit probes, not desired-behaviour tests: synthetic inputs, no network or keys.

Run from any directory. Prints observations against the checked-out Forja.
After repairs, observations should change; do not preserve bugs to pass a test.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))
from tools.forja import cmd_ai, contracts, godot, inpaint, pipeline, prompts, sheetforge
from tools.forja.backends import http, pixellab_api


class Captured(Exception):
    """Stop before a mocked request could advance the generation workflow."""


def provider_request(backend: str, temp: Path, reference: bool = False) -> dict:
    requests = []
    ref = temp / "reference.png"
    Image.new("RGBA", (64, 64), "red").save(ref)

    def capture(req):
        requests.append(json.loads(req.body))
        raise Captured()

    args = SimpleNamespace(subject="comic knight", kind="character_s2", tags="walk:8" if backend == "gemini"
                           else None, facing="right", reference=[str(ref)] if reference else [],
                           palette=None, backend=backend, model=None, attempts=1, out=str(temp / backend))
    with patch.object(http, "key", return_value="synthetic-test-token"):
        try:
            cmd_ai.do_auto(args, transport=capture)
        except Captured:
            pass
    body = requests[0]
    built = prompts.build(args.subject, args.kind, sheetforge.parse_tags(args.tags), args.facing,
                          reference, cmd_ai._palette(args, args.kind),
                          "gemini" if backend == "gemini" else "gpt-image")
    if backend == "pixellab":
        return {"compiled_size": built["expect"]["size"], "sent_size": body["image_size"],
                "native_parameters_available": built["pixellab"]["image_size"],
                "input_reference_count": len(args.reference),
                "reference_in_payload": "init_image" in body or "reference_images" in body,
                "request_sent_to_network": False}
    return {"compiled_size": built["expect"]["size"], "assumed_scale": built["expect"]["scale"],
            "sent_format": body["response_format"],
            "prompt_mentions_attached_palette": "attached palette swatch" in built["prompt"],
            "attached_images": sum(p["type"] == "image" for p in body["input"]),
            "request_sent_to_network": False}


def retry_post() -> dict:
    seen = []

    def unavailable(req):
        seen.append({"method": req.method, "headers": req.headers})
        return http.Response(503, b'{"error":"synthetic upstream failure"}', {})

    try:
        http.send(http.Request("POST", "https://example.invalid/generate", {}, b"{}"),
                  unavailable, sleep=lambda _: None)
    except http.ApiError:
        pass
    return {"post_attempts": len(seen), "provider_billing_observed": False,
            "idempotency_header_present": any("idempotency" in key.lower()
                                               for req in seen for key in req["headers"])}


def cleanup_details() -> dict:
    im = Image.new("RGBA", (16, 16))
    ImageDraw.Draw(im).rectangle((5, 5, 10, 10), fill="red")
    im.putpixel((7, 7), (0, 0, 0, 0))
    im.putpixel((1, 1), (255, 255, 0, 255))
    result, info = pipeline.finish(im, pipeline.Options(kind="free", noise=0, fit=False),
                                   contracts.get("free"), None)
    return {"noise_option": 0, "isolated_pixel_before_alpha": im.getpixel((1, 1))[3],
            "isolated_pixel_after_alpha": result.getpixel((1, 1))[3],
            "hole_before_alpha": im.getpixel((7, 7))[3], "hole_after_alpha": result.getpixel((7, 7))[3],
            "cleanup": info["despeckle"]}


def inpaint_blue() -> dict:
    native = Image.new("RGBA", (16, 16))
    ImageDraw.Draw(native).rectangle((4, 4, 11, 11), fill="#0000FF")

    def echo(_prompt, images, *_args, **_kw):
        return {"images": [images[0]], "model": "synthetic/echo"}

    with patch("tools.forja.backends.openai_images.edit", side_effect=echo), \
            patch.object(prompts, "pick_scale", return_value=2):
        result, info = inpaint.run(native, (4, 4, 12, 12), "leave unchanged")
    return {"provider_echoed_input": True, "fixture_scale_override": 2,
            "opaque_before": sum(a > 0 for a in native.getchannel("A").tobytes()),
            "opaque_after": sum(a > 0 for a in result.getchannel("A").tobytes()), **info}


def animation(temp: Path, shifted: bool) -> dict:
    im = Image.new("RGBA", (64, 32))
    draw = ImageDraw.Draw(im)
    for i in range(2):
        y = 14 - (4 if shifted and i else 0)
        draw.rectangle((i * 32 + 12, y, i * 32 + 19, y + 11), fill="red")
    big = im.resize((256, 128), Image.Resampling.NEAREST)
    source = temp / ("jump.png" if shifted else "duplicates.png")
    big.save(source)
    result = sheetforge.forge_sheet(source, temp / source.stem, pipeline.Options(kind="free", scale=4),
                                    sheetforge.SheetOptions(tags=[("jump" if shifted else "walk", 2)],
                                                           layout=(2, 1)))
    return {"source_vertical_displacement_native_px": -4 if shifted else 0, "ok": result["ok"],
            "found": result["found"], "source_boxes": [f["source_box"] for f in result["frames"]],
            "metrics": result["metrics"], "output_frame_count": len(result["frames"])}


def reverse_tag() -> dict:
    text = godot.sprite_frames("res://synthetic.png", [(0, 0, 4, 4), (4, 0, 4, 4), (8, 0, 4, 4)],
                               [100, 200, 300], [("reverse_example", 0, 2, "reverse")])
    order = [int(x) for x in re.findall(r'"texture": SubResource\("AtlasTexture_(\d+)"\)', text)]
    return {"input_direction": "reverse", "expected_indices": [2, 1, 0], "exported_indices": order,
            "godot_engine_executed": False}


def endless_job() -> dict:
    gets = 0

    def working(req):
        nonlocal gets
        if req.method == "POST":
            return http.Response(200, b'{"background_job_id":"synthetic-job"}', {})
        gets += 1
        if gets == 20:
            raise Captured()
        return http.Response(200, b'{"status":"processing"}', {})

    interrupted = False
    with patch.object(http, "key", return_value="synthetic-test-token"):
        try:
            pixellab_api.generate("synthetic", transport=working)
        except Captured:
            interrupted = True
    return {"get_attempts": gets, "stopped_by_audit_sentinel": interrupted,
            "elapsed_time_or_timeout_measured": False}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path)
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="forja-audit-") as folder:
        temp = Path(folder)
        observations = {"F01_post_retries": retry_post(), "F02_pixellab_request": provider_request("pixellab", temp, True),
                        "F03_gemini_request_and_guides": provider_request("gemini", temp),
                        "F04_inpaint_blue_collision": inpaint_blue(), "F05_cleanup_details": cleanup_details(),
                        "F06_jump_offsets": animation(temp, True), "F07_duplicate_motion": animation(temp, False),
                        "F08_godot_reverse": reverse_tag(), "F09_job_polling": endless_job()}
    result = {"scope": "local_synthetic_observations_no_network", "upstream_reviewed_commit":
              "68ed1c87461f5d39dd21fb664eef2930ddeaac81", "checkout_commit":
              subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
              "production_files_modified_by_probe": False, "observations": observations}
    text = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if args.out:
        args.out.write_text(text, encoding="utf-8")
    print(text, end="")


if __name__ == "__main__":
    main()
