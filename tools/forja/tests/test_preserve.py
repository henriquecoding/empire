"""F04-F08: preservar a arte — edicao sem colisao de cor, pixels de proposito, deslocamentos, revisao e ordem."""
import io
import os
import re
import shutil
import subprocess
import unittest
from unittest import mock

from PIL import Image, ImageDraw

from tools.forja import anim, cleanup, contracts, godot, inpaint, pipeline, review, sheetforge
from tools.forja.imageops import CLEAR, flat, opaque_bbox
from tools.forja.tests.helpers import tempdir

BLUE, MAGENTA, GREEN = (0, 0, 255, 255), (255, 0, 255, 255), (0, 255, 0, 255)


def colorful() -> Image.Image:
    """Azul, magenta e verde legitimos (as chaves antigas), transparencia com cor escondida."""
    im = Image.new("RGBA", (16, 16), (255, 255, 255, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((2, 2, 7, 7), fill=BLUE)
    d.rectangle((8, 2, 13, 7), fill=MAGENTA)
    d.rectangle((2, 8, 13, 13), fill=GREEN)
    im.putpixel((15, 15), (0, 0, 0, 255))
    return im


def echo_of(native, box):
    image, mask, k, size, key = inpaint.prepare(native, box)
    with Image.open(io.BytesIO(image)) as im:
        return im.convert("RGBA"), k, key


class InpaintTest(unittest.TestCase):
    def test_echo_rebuilds_the_sprite_byte_for_byte(self):
        native = colorful()
        for box in ((4, 4, 12, 12), (0, 0, 16, 16), (12, 12, 16, 16)):
            result, k, key = echo_of(native, box)
            self.assertNotIn(key, ("#0000FF", "#FF00FF", "#00FF00"))
            out, info = inpaint.merge(native, result, k, box, key=key)
            self.assertEqual(out.tobytes(), native.tobytes(), box)
            self.assertEqual((info["changed_pixels"], info["outside_identical"]), (0, True))

    def test_run_with_an_echoing_provider_keeps_the_blue(self):
        native = colorful()

        def echo(_prompt, images, *_a, **_kw):
            return {"images": [images[0]], "model": "synthetic/echo", "job": {"id": "local"}}

        with mock.patch("tools.forja.backends.openai_images.edit", side_effect=echo):
            out, info = inpaint.run(native, (2, 2, 14, 14), "leave unchanged")
        self.assertEqual(out.tobytes(), native.tobytes())
        self.assertGreater(info["key_distance"], 0.1)

    def test_changes_stay_inside_and_old_key_colours_survive(self):
        native = colorful()
        box = (0, 0, 16, 16)
        result, k, key = echo_of(native, box)
        d = ImageDraw.Draw(result)
        d.rectangle((14 * k, 0, 16 * k - 1, 2 * k - 1), fill=BLUE)
        d.rectangle((2 * k, 2 * k, 3 * k - 1, 3 * k - 1), fill=key)
        out, info = inpaint.merge(native, result, k, box, key=key)
        self.assertEqual(out.getpixel((14, 0)), BLUE)
        self.assertEqual(out.getpixel((2, 2))[3], 0)
        self.assertEqual(info["became_transparent"], 1)
        self.assertEqual(info["changed_pixels"], 5)

    def test_bad_boxes_and_sizes_are_errors(self):
        native = colorful()
        with self.assertRaises(ValueError):
            inpaint.prepare(native, (4, 4, 4, 8))
        with self.assertRaises(ValueError):
            inpaint.prepare(native, (10, 10, 20, 12))
        result, k, key = echo_of(native, (4, 4, 8, 8))
        with self.assertRaisesRegex(ValueError, "nao se estica"):
            inpaint.merge(native, result.resize((result.width - k, result.height)), k, (4, 4, 8, 8), key=key)


def speck_and_hole() -> Image.Image:
    im = Image.new("RGBA", (16, 16))
    ImageDraw.Draw(im).rectangle((5, 5, 10, 10), fill="red")
    im.putpixel((7, 7), CLEAR)
    im.putpixel((1, 1), (255, 255, 0, 255))
    return im


class CleanupPolicyTest(unittest.TestCase):
    def test_free_kind_keeps_one_pixel_details(self):
        im = speck_and_hole()
        out, info = pipeline.finish(im, pipeline.Options(kind="free", noise=0, fit=False), contracts.get("free"), None)
        self.assertEqual((out.getpixel((1, 1))[3], out.getpixel((7, 7))[3]), (255, 0))
        self.assertEqual(info["cleanup"]["policy"], "conservative")

    def test_particles_and_holes_are_candidates_not_removals(self):
        for policy in ("fx", "character"):
            out, info = cleanup.clean(speck_and_hole(), policy)
            self.assertEqual(out.getpixel((1, 1))[3], 255, policy)
            self.assertEqual(out.getpixel((7, 7))[3], 0, policy)
            self.assertEqual(info["candidates"], [[1, 1]])

    def test_scenery_cleans_and_protection_holds(self):
        out, info = cleanup.clean(speck_and_hole(), cleanup.policy_for("prop"))
        self.assertEqual((out.getpixel((1, 1))[3], out.getpixel((7, 7))[3]), (0, 255))
        self.assertEqual(info["changed"]["orphans"], [[1, 1]])
        out, info = cleanup.clean(speck_and_hole(), "scenery", protect=[(0, 0, 3, 3)])
        self.assertEqual(out.getpixel((1, 1))[3], 255)
        self.assertEqual(info["protected_kept"], 1)

    def test_noise_only_where_asked(self):
        im = Image.new("RGBA", (5, 5), (100, 100, 100, 255))
        im.putpixel((2, 2), (103, 100, 100, 255))
        self.assertEqual(cleanup.clean(im, "character")[0].getpixel((2, 2))[:3], (100, 100, 100))
        self.assertEqual(cleanup.clean(im, "character", noise=0)[0].getpixel((2, 2))[:3], (103, 100, 100))

    def test_conservative_is_idempotent(self):
        im = speck_and_hole()
        once, _ = cleanup.clean(im, "conservative")
        twice, _ = cleanup.clean(once, "conservative")
        self.assertEqual(once.tobytes(), im.tobytes())
        self.assertEqual(twice.tobytes(), once.tobytes())


def strip_sheet(figures: list, cell: int = 32, scale: int = 4) -> Image.Image:
    """Cada figura (imagem, (x, y)) na sua celula, ampliada como um gerador ampliaria."""
    im = Image.new("RGBA", (cell * len(figures), cell))
    for i, (fig, (x, y)) in enumerate(figures):
        im.alpha_composite(fig, (i * cell + x, y))
    return im.resize((im.width * scale, im.height * scale), Image.Resampling.NEAREST)


def forge(figures, tag="anim", align="auto", holds=None, scale=4):
    d = tempdir()
    strip_sheet(figures, scale=scale).save(d / "sheet.png")
    return sheetforge.forge_sheet(d / "sheet.png", d / "out", pipeline.Options(kind="free", scale=scale),
                                  sheetforge.SheetOptions(tags=[(tag, len(figures))], layout=(len(figures), 1),
                                                          align=align, holds=holds))


def block(w, h, fill="red"):
    im = Image.new("RGBA", (w, h))
    ImageDraw.Draw(im).rectangle((0, 0, w - 1, h - 1), fill=fill)
    return im


def walker(legs: tuple[int, int]) -> Image.Image:
    im = Image.new("RGBA", (12, 16))
    d = ImageDraw.Draw(im)
    d.rectangle((3, 0, 8, 9), fill="red")
    for x in legs:
        d.rectangle((x, 10, x + 1, 15), fill="navy")
    return im


def frames_of(res) -> list[Image.Image]:
    sheet = Image.open(res["files"]["sheet"]).convert("RGBA")
    w, h = res["canvas"]
    return [sheet.crop((i * w, 0, (i + 1) * w, h)) for i in range(res["found"])]


class OffsetTest(unittest.TestCase):
    def test_jump_keeps_its_height(self):
        res = forge([(block(8, 12), (12, 14)), (block(8, 12), (12, 10))], "jump")
        feet = res["metrics"]["feet"]
        self.assertEqual(feet[0][1] - feet[1][1], 4)
        self.assertEqual(res["metrics"]["distinct_rasters"], 2)
        self.assertTrue(res["metrics"]["alignment"]["offsets_preserved"])
        self.assertTrue(res["ok"])

    def test_walk_keeps_the_torso_still(self):
        res = forge([(walker((3, 7)), (10, 12)), (walker((0, 10)), (10, 12))], "walk")
        torsos = [opaque_bbox(Image.composite(f, Image.new("RGBA", f.size), f.convert("L").point(
            lambda v: 255 if 60 < v < 90 else 0))) for f in frames_of(res)]
        self.assertEqual(torsos[0], torsos[1])
        support = next(c for c in res["review"]["motion_checks"] if c["check"] == "support")
        self.assertEqual(support["status"], "ok")

    def test_crouch_is_not_enlarged(self):
        res = forge([(block(8, 12), (12, 14)), (block(10, 8), (11, 18))], "crouch")
        self.assertEqual(res["metrics"]["heights"], [12, 8])
        self.assertEqual(res["metrics"]["feet"][0][1], res["metrics"]["feet"][1][1])

    def test_flower_grows_from_a_fixed_root(self):
        stages = []
        for i in range(4):
            im = Image.new("RGBA", (9, 12))
            d = ImageDraw.Draw(im)
            d.line((4, 11, 4, 11 - 2 * i), fill="green")
            if i >= 2:
                d.rectangle((4 - (i - 1), 11 - 2 * i - 2, 4 + (i - 1), 11 - 2 * i), fill="yellow")
            stages.append((im, (11, 18)))
        res = forge(stages, "grow")
        frames = frames_of(res)
        roots = {max(((x, y) for y in range(f.height) for x in range(f.width) if f.getpixel((x, y))[3]),
                     key=lambda p: p[1]) for f in frames}
        self.assertEqual(len(roots), 1)
        areas = [sum(p[3] > 0 for p in flat(f)) for f in frames]
        self.assertEqual(areas, sorted(set(areas)))
        self.assertFalse(res["review"]["needs_regeneration"])

    def test_feet_alignment_says_its_zero_drift_proves_nothing(self):
        res = forge([(block(8, 12), (12, 14)), (block(8, 12), (12, 10))], "jump", align="feet")
        self.assertEqual(res["metrics"]["max_drift"], 0)
        self.assertTrue(res["metrics"]["alignment"]["drift_imposed_by_alignment"])
        support = next(c for c in res["review"]["motion_checks"] if c["check"] == "support")
        self.assertEqual(support["status"], "n/a")


class ReviewTest(unittest.TestCase):
    def test_duplicated_walk_is_not_ok(self):
        res = forge([(block(8, 12), (12, 14))] * 2, "walk")
        self.assertFalse(res["ok"])
        self.assertTrue(res["review"]["contract_valid"])
        self.assertTrue(res["review"]["needs_regeneration"])
        self.assertEqual(res["review"]["artistic_approval"], "pendente")
        self.assertIn("static_tag", [c["check"] for c in res["review"]["motion_checks"]])

    def test_declared_hold_is_accepted_and_timed(self):
        a, b = (block(8, 12), (12, 14)), (block(8, 10), (12, 16))
        res = forge([a, b, b], "attack", holds=review.parse_holds(["2:300:antecipacao do golpe"]))
        checks = res["review"]["motion_checks"]
        self.assertNotIn("hidden_duplicate", [c["check"] for c in checks])
        self.assertEqual(next(c for c in checks if c["check"] == "hold")["status"], "ok")
        self.assertEqual(res["durations"][2], 300)
        self.assertTrue(res["ok"])
        with self.assertRaises(ValueError):
            review.parse_holds(["2:300"])

    def test_hidden_duplicate_is_flagged(self):
        a, b = (block(8, 12), (12, 14)), (block(8, 10), (12, 16))
        checks = forge([a, b, a, b], "walk")["review"]["motion_checks"]
        self.assertEqual(sum(c["check"] == "hidden_duplicate" for c in checks), 2)

    def test_missing_inbetween_and_lost_arm_are_flagged(self):
        body = block(6, 12)
        with_arm = Image.new("RGBA", (16, 16))
        with_arm.alpha_composite(body, (2, 2))
        with_arm.alpha_composite(block(4, 2, "blue"), (11, 6))
        without = Image.new("RGBA", (16, 16))
        without.alpha_composite(body, (2, 2))
        far = Image.new("RGBA", (16, 16))
        far.alpha_composite(block(3, 3), (13, 13))
        result = review.motion([with_arm, without, far], [("act", 0, 2, "forward")], loop=False)
        kinds = [(c["check"], c.get("frames")) for c in result["motion_checks"]]
        self.assertIn(("part_lost", [0, 1]), kinds)
        self.assertIn(("big_jump", [1, 2]), kinds)
        self.assertIn("order_and_limbs", [c["check"] for c in result["motion_checks"]])
        self.assertEqual(result["blocking"], [])


class GodotOrderTest(unittest.TestCase):
    def test_directions(self):
        self.assertEqual(godot.order(0, 2, "reverse"), [2, 1, 0])
        self.assertEqual(godot.order(0, 2, "pingpong"), [0, 1, 2, 1])
        self.assertEqual(godot.order(0, 2, "pingpong_reverse"), [2, 1, 0, 1])
        with self.assertRaises(ValueError):
            godot.order(0, 2, "random")

    def test_reverse_tag_order_and_time(self):
        text = godot.sprite_frames("res://s.png", [(0, 0, 4, 4), (4, 0, 4, 4), (8, 0, 4, 4)], [100, 200, 300],
                                   [("back", 0, 2, "reverse")])
        seq = re.findall(r'"duration": ([\d.]+),\n"texture": SubResource\("AtlasTexture_(\d+)"\)', text)
        self.assertEqual(seq, [("3.0", "2"), ("2.0", "1"), ("1.0", "0")])

    @unittest.skipUnless(os.environ.get("GODOT") or shutil.which("godot"), "sem o motor: GODOT ou godot no PATH")
    def test_reverse_loads_in_godot(self):
        engine = os.environ.get("GODOT") or shutil.which("godot")
        d = tempdir()
        frames = [block(4, 4, c) for c in ("red", "green", "blue")]
        strip, rects = anim.strip(frames)
        strip.save(d / "s.png")
        godot.write(d / "s.tres", godot.sprite_frames("res://s.png", rects, [100, 200, 300], [("back", 0, 2, "reverse")]))
        (d / "check.gd").write_text(godot.CHECK_SCRIPT)
        (d / "project.godot").write_text('config_version=5\n\n[application]\nconfig/name="forja"\n')
        subprocess.run([engine, "--headless", "--path", str(d), "--import"], capture_output=True, timeout=180)
        out = subprocess.run([engine, "--headless", "--path", str(d), "-s", "check.gd", "--", "res://s.tres"],
                             capture_output=True, text=True, timeout=120)
        line = next(x for x in out.stdout.splitlines() if x.startswith("FORJA_OK"))
        xs = [round(float(v)) for v in re.findall(r"\[(\d+(?:\.\d+)?),\s*\d", line.split("spriteframes", 1)[1])]
        self.assertEqual(xs[-3:], [rects[2][0], rects[1][0], rects[0][0]], line)
        self.assertIn("3", line)
