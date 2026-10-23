import re
import unittest
from pathlib import Path

from PIL import Image

from tools.forja import contracts, lint, prova
from tools.forja.palette import from_image
from tools.forja.tests.helpers import framed

ROOT = Path(__file__).resolve().parents[3]


class ContractsTest(unittest.TestCase):
    def test_scales_match_asset_bible(self):
        text = (ROOT / "docs/art/ASSET_BIBLE.md").read_text(encoding="utf-8")
        rows = re.findall(r"\|\s*(1|2|3|Colosso)\s*\|[^|]*\|\s*([^|]+?)\s*\|\s*(\d+) × (\d+)\s*\|\s*\((\d+), (\d+)\)", text)
        kinds = {"1": "character_s1", "2": "character_s2", "3": "character_s3", "Colosso": "colossus"}
        self.assertEqual(len(rows), 4)
        for scale, height, w, h, px, py in rows:
            c = contracts.get(kinds[scale])
            self.assertEqual(c.canvas, (int(w), int(h)))
            self.assertEqual(c.pivot, (int(px), int(py)))
            numbers = [int(n) for n in re.findall(r"\d+", height)]
            self.assertEqual(c.useful_height[1], numbers[-1])

    def test_tags_match_animation_bible(self):
        text = (ROOT / "docs/art/ANIMATION_BIBLE.md").read_text(encoding="utf-8")
        found = 0
        for name, frames, fps in re.findall(r"^\| `(\w+)` \| \**(\d+)[^|]*\| (\d+) \|", text, re.M):
            tag = contracts.tag(name)
            self.assertIsNotNone(tag, name)
            self.assertEqual((tag["frames"], tag["fps"]), (int(frames), int(fps)), name)
            found += 1
        self.assertGreaterEqual(found, 12)

    def test_palette_path_exists(self):
        self.assertTrue((ROOT / contracts.load_data()["palette"]).exists())


class LintTest(unittest.TestCase):
    def test_clean_sprite_passes(self):
        img = framed(9)
        self.assertTrue(lint.check(img, contracts.get("character_s1"), from_image(img))["ok"])

    def test_defects_are_reported_with_fixes_and_hints(self):
        report = prova.lint_case()
        self.assertTrue(report["ok"], report)

    def test_canvas_pivot_and_cluster(self):
        img = framed(9, (60, 60), (30, 50))
        rules = {f["rule"] for f in lint.check(img, contracts.get("character_s1"))["findings"]}
        self.assertIn("canvas", rules)
        self.assertIn("pivot", rules)
        scenery = Image.new("RGBA", (16, 16), (40, 40, 40, 255))
        scenery.putpixel((5, 5), (200, 0, 0, 255))
        rules = {f["rule"] for f in lint.check(scenery, contracts.get("prop"), frame=False)["findings"]}
        self.assertIn("cluster", rules)

    def test_feedback_is_english_for_the_generator(self):
        img = framed(9)
        img.putpixel((1, 1), (255, 255, 255, 255))
        report = lint.check(img, contracts.get("character_s1"), from_image(img))
        self.assertIn("No stray isolated pixels", report["prompt_feedback"])
