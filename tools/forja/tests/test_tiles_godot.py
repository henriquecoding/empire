import os
import json
import shutil
import subprocess
import unittest

from PIL import Image

from tools.forja import anim, godot, prova, scale, tiles
from tools.forja.imageops import flat
from tools.forja.tests.helpers import framed, tempdir


class TilesTest(unittest.TestCase):
    def test_corner_encoding_matches_pixellab(self):
        self.assertEqual(tiles.corners(0b1000), {"NW": 1, "NE": 0, "SW": 0, "SE": 0})
        self.assertEqual(tiles.corners(0b0001), {"NW": 0, "NE": 0, "SW": 0, "SE": 1})

    def test_wang_sheet_and_metadata(self):
        sheet, meta = tiles.wang16(16, Image.new("RGBA", (16, 16), (90, 60, 40, 255)),
                                   Image.new("RGBA", (16, 16), (80, 160, 60, 255)))
        self.assertEqual(sheet.size, (64, 64))
        self.assertEqual(meta[15]["corners"], {"NW": "upper", "NE": "upper", "SW": "upper", "SE": "upper"})
        self.assertEqual({p[:3] for p in flat(sheet.crop((48, 48, 64, 64)))}, {(80, 160, 60)})

    def test_tiles_join_without_seams(self):
        self.assertEqual(prova.tiles_case(None)["mismatched_pixels"], 0)

    def test_cluster_two_pixel_law(self):
        m = tiles.mask(6, 16, cluster=2)
        for y in range(0, 16, 2):
            for x in range(0, 16, 2):
                self.assertEqual(len({m[y][x], m[y][x + 1], m[y + 1][x], m[y + 1][x + 1]}), 1)

    def test_seams(self):
        flat_tile = Image.new("RGBA", (8, 8), (10, 10, 10, 255))
        self.assertTrue(tiles.seams(flat_tile)["seamless"])
        bad = flat_tile.copy()
        bad.paste((250, 250, 250, 255), (7, 0, 8, 8))
        self.assertFalse(tiles.seams(bad)["seamless"])


class ScaleTest(unittest.TestCase):
    def test_scale2x_and_rotsprite(self):
        img = framed(1)
        self.assertEqual(scale.scale2x(img).size, (128, 128))
        turned = scale.rotsprite(img, 90)
        self.assertEqual(turned.getchannel("A").getbbox() is not None, True)
        colors = {p[:3] for p in flat(img) if p[3]}
        self.assertTrue({p[:3] for p in flat(turned) if p[3]} <= colors)

    def test_downscale_inverts_upscale(self):
        img = framed(2)
        big = img.resize((256, 256), Image.Resampling.NEAREST)
        self.assertEqual(scale.downscale(big, 4).tobytes(), img.tobytes())


class GodotTest(unittest.TestCase):
    def test_tileset_text(self):
        text = godot.tileset("res://t.png", 32)
        self.assertIn("terrain_set_0/mode = 1", text)
        self.assertIn("1:0/0/terrains_peering_bit/bottom_right_corner = 1", text)
        self.assertEqual(text.count("/terrain_set = 0"), 16)

    def test_sprite_frames_text(self):
        _, rects = anim.strip([framed(i) for i in range(3)])
        text = godot.sprite_frames("res://a.png", rects, [100, 100, 200], [("idle", 0, 2, "forward")])
        self.assertIn('"name": &"idle"', text)
        self.assertIn('"duration": 2.0', text)

    @unittest.skipUnless(os.environ.get("GODOT") or shutil.which("godot"),
                         "sem o motor: GODOT ou godot no PATH (o CI da Forja nao instala o Godot)")
    def test_resources_load_in_godot(self):
        engine = os.environ.get("GODOT") or shutil.which("godot")
        d = tempdir()
        sheet, _ = tiles.wang16(16, Image.new("RGBA", (16, 16), (90, 60, 40, 255)),
                                Image.new("RGBA", (16, 16), (80, 160, 60, 255)))
        sheet.save(d / "wang.png")
        godot.write(d / "wang.tres", godot.tileset("res://wang.png", 16))
        frames = [framed(i) for i in range(3)]
        strip, rects = anim.strip(frames)
        strip.save(d / "hero.png")
        godot.write(d / "hero.tres", godot.sprite_frames("res://hero.png", rects, [100, 200, 300],
                                                       [("idle", 0, 2, "forward"), ("reverse", 0, 2, "reverse")]))
        (d / "check.gd").write_text(godot.CHECK_SCRIPT)
        (d / "project.godot").write_text('config_version=5\n\n[application]\nconfig/name="forja"\n')
        subprocess.run([engine, "--headless", "--path", str(d), "--import"], capture_output=True, timeout=180)
        for res in ("res://wang.tres", "res://hero.tres"):
            out = subprocess.run([engine, "--headless", "--path", str(d), "-s", "check.gd", "--", res],
                                 capture_output=True, text=True, timeout=120)
            self.assertIn("FORJA_OK", out.stdout, out.stdout + out.stderr)
            if res.endswith("hero.tres"):
                line = next(s for s in out.stdout.splitlines() if s.startswith("FORJA_ORDER reverse "))
                self.assertEqual(json.loads(line.removeprefix("FORJA_ORDER reverse ")), [[128, 3], [64, 2], [0, 1]])
