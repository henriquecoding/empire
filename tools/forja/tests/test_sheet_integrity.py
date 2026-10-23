"""Uma prancha incompleta nao pode mudar o significado dos quadros seguintes."""
import unittest

from PIL import Image

from tools.forja import grid, pipeline, sheet, sheetforge, synth
from tools.forja.tests.helpers import tempdir


class SheetIntegrityTest(unittest.TestCase):
    def test_explicit_native_grid_keeps_every_pixel(self):
        img = synth.sprite(15, (24, 32))
        g = grid.detect(img, scale=1)
        self.assertEqual(g.xs, list(range(25)))
        self.assertEqual(g.ys, list(range(33)))
        self.assertTrue(g.native)

    def test_native_cell_keeps_one_pixel_weapon(self):
        img = Image.new("RGBA", (32, 32))
        img.paste((80, 120, 40, 255), (10, 10, 20, 28))
        img.paste((10, 10, 10, 255), (22, 4, 23, 24))
        boxes, _, masks = sheet.find_cells(img, None, (1, 1))
        figures = sheet.extract(img, boxes, None, scale=1, masks=masks)
        expected = img.crop(img.getchannel("A").getbbox())
        self.assertEqual(figures[0].native.tobytes(), expected.tobytes())
        self.assertEqual(figures[0].native.size, expected.size)

    def test_empty_sheet_returns_actionable_failure(self):
        d = tempdir()
        Image.new("RGBA", (128, 64)).save(d / "empty.png")
        result = sheetforge.forge_sheet(d / "empty.png", d / "out", pipeline.Options(kind="royal_64"),
                                       sheetforge.SheetOptions(tags=[("walk", 2)], layout=(2, 1)))
        self.assertFalse(result["ok"])
        self.assertEqual(result["found"], 0)
        self.assertIn("empty", {f["rule"] for f in result["findings"]})
        self.assertNotIn("godot", result["files"])

    def test_gap_keeps_original_cell_and_never_relabels_walk_as_idle(self):
        d = tempdir()
        img = Image.new("RGBA", (256, 64))
        for i in (0, 2, 3):
            img.paste(synth.sprite(30 + i, (24, 32)), (64 * i + 20, 24))
        img.save(d / "gap.png")
        result = sheetforge.forge_sheet(d / "gap.png", d / "out", pipeline.Options(kind="royal_64", scale=1),
                                       sheetforge.SheetOptions(tags=[("idle", 2), ("walk", 2)], layout=(4, 1),
                                                               godot_texture="res://gap.png"))
        self.assertFalse(result["ok"])
        self.assertEqual(result["missing_cells"], [1])
        self.assertEqual([f["source_cell"] for f in result["frames"]], [0, 2, 3])
        self.assertNotIn("godot", result["files"])
        self.assertNotIn("aseprite", result["files"])

    def test_negative_frame_count_is_rejected(self):
        with self.assertRaises(ValueError):
            sheetforge.parse_tags("walk:-1")

    def test_clipped_sheet_is_reviewable_but_has_no_game_exports(self):
        d = tempdir()
        img = Image.new("RGBA", (128, 128))
        img.paste((80, 120, 40, 255), (10, 10, 110, 110))
        img.save(d / "large.png")
        result = sheetforge.forge_sheet(d / "large.png", d / "out", pipeline.Options(kind="royal_64", scale=1),
                                       sheetforge.SheetOptions(tags=[("idle", 1)], layout=(1, 1),
                                                               godot_texture="res://large.png"))
        self.assertFalse(result["ok"])
        self.assertFalse(result["export_complete"])
        self.assertIn("report", result["files"])
        self.assertNotIn("godot", result["files"])
        self.assertNotIn("aseprite", result["files"])

    def test_same_height_cannot_rescale_character_poses(self):
        with self.assertRaisesRegex(ValueError, "altura|height"):
            sheet.extract(Image.new("RGBA", (64, 64)), [], None, same_height=True)
