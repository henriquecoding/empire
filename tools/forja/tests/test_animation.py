import json
import unittest

from PIL import Image

from tools.forja import anim, aseprite, motion, sheet, synth
from tools.forja.imageops import flat
from tools.forja.tests.helpers import framed, tempdir


class SheetTest(unittest.TestCase):
    def test_finds_extracts_and_frames(self):
        truths = [synth.sprite(20 + i, (24, 30 + i % 3)) for i in range(6)]
        big = synth.sheet(truths, 3, 9.3, bg=(0, 0, 255))
        boxes, stray = sheet.find(big, (0, 0, 255))
        self.assertEqual(len(boxes), 6)
        figures = sheet.extract(big, boxes, (0, 0, 255))
        for f, t in zip(figures, truths):
            self.assertEqual(f.native.size, t.crop(t.getchannel("A").getbbox()).size)
        frames, report = sheet.frames(figures, (64, 64), (32, 56))
        self.assertTrue(all(r["clipped_pixels"] == 0 for r in report))
        self.assertEqual(anim.metrics(frames, (32, 56))["max_drift"], 0)

    def test_cells_separate_touching_figures(self):
        truths = [synth.sprite(70 + i, (24, 32)) for i in range(8)]
        big = synth.sheet(truths, 4, 8.0, gap=2, bg=(0, 0, 255))
        cells, _, masks = sheet.find_cells(big, (0, 0, 255), (4, 2))
        figures = sheet.extract(big, [c for c in cells if c], (0, 0, 255), masks=masks)
        self.assertEqual(len(figures), 8)
        for f, t in zip(figures, truths):
            self.assertEqual(f.native.size, t.crop(t.getchannel("A").getbbox()).size)

    def test_by_cells_merges_pieces(self):
        boxes = [(10, 10, 20, 40), (22, 15, 26, 20), (110, 10, 120, 40)]
        cells = sheet.by_cells(boxes, (200, 100), (2, 1))
        self.assertEqual(cells[0], (10, 10, 26, 40))


class AnimTest(unittest.TestCase):
    def test_export_and_json(self):
        frames = [framed(i) for i in range(4)]
        d = tempdir()
        files = anim.export(frames, d, "idle", [100] * 4, [("idle", 0, 3, "forward")], (32, 56))
        data = json.loads((d / "idle.json").read_text())
        self.assertEqual(len(data["frames"]), 4)
        self.assertEqual(data["meta"]["frameTags"][0]["name"], "idle")
        self.assertEqual(data["meta"]["slices"][0]["keys"][0]["pivot"], {"x": 32, "y": 56})
        with Image.open(files["gif"]) as gif:
            self.assertTrue(gif.is_animated)

    def test_mirror_moves_pivot(self):
        _, pivot = anim.mirror([framed(1, (80, 80), (40, 78))], (40, 78))
        self.assertEqual(pivot, (39, 78))

    def test_metrics_counts_duplicates_and_mirrors(self):
        f = framed(2)
        m = anim.metrics([f, f, f.transpose(Image.Transpose.FLIP_LEFT_RIGHT)])
        self.assertEqual(m["duplicates"], 1)
        self.assertEqual(m["mirror_pairs"], 1)


class AsepriteTest(unittest.TestCase):
    def test_round_trip_with_project_reader(self):
        frames = [framed(i) for i in range(3)]
        path = aseprite.from_frames(tempdir() / "t.aseprite", frames, durations=[100, 120, 140],
                                    tags=[("walk", 0, 2, "pingpong")], palette=[(0, 0, 0)], pivot=(32, 56))
        check = aseprite.verify(path, frames)
        self.assertTrue(check["pixel_equal"])
        self.assertEqual(check["durations"], [100, 120, 140])
        self.assertEqual(check["tags"]["walk"]["direction"], 2)
        self.assertFalse(check["opened_in_aseprite_app"])


class MotionTest(unittest.TestCase):
    def test_breathe_keeps_feet(self):
        f = framed(3)
        frames = motion.breathe(f, 40)
        self.assertEqual(len(frames), 6)
        for g in frames:
            self.assertEqual(g.crop((0, 40, 64, 64)).tobytes(), f.crop((0, 40, 64, 64)).tobytes())

    def test_lock_pastes_reference_head(self):
        ref = framed(4)
        moved = Image.new("RGBA", ref.size)
        moved.alpha_composite(ref, (1, 0))
        noisy = moved.copy()
        noisy.putpixel((33, 25), (255, 255, 255, 255))
        out, report = motion.lock([ref, noisy], (24, 20, 40, 32))
        self.assertEqual(report[1]["offset"], [1, 0])
        self.assertTrue(report[1]["locked"])

    def test_dissolve_and_flash(self):
        f = framed(5)
        steps = motion.dissolve(f, 4)
        self.assertEqual(steps[-1].getchannel("A").getbbox(), None)
        self.assertEqual({p[:3] for p in flat(motion.flash(f)) if p[3]}, {(255, 255, 255)})
