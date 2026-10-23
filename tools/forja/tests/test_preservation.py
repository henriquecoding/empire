"""Regressoes F04/F05/F06/F08 da auditoria publicada em 9ee6b4c."""
import io
import re
import unittest
from unittest import mock

from PIL import Image

from tools.forja import contracts, godot, inpaint, pipeline, sheetforge
from tools.forja.tests.helpers import tempdir


class PreservationTest(unittest.TestCase):
    def test_noop_edit_keeps_blue_magenta_green_and_transparency(self):
        for color in ("#0000ff", "#ff00ff", "#00ff00"):
            image = Image.new("RGBA", (16, 16))
            image.paste(color, (4, 4, 12, 12))
            def echo(prompt, images, mask, size, **kw):
                return {"images": [images[0]], "model": "echo"}
            with mock.patch("tools.forja.backends.openai_images.edit", side_effect=echo), \
                    mock.patch("tools.forja.prompts.pick_scale", return_value=2):
                out, info = inpaint.run(image, (2, 2, 14, 14), "leave unchanged")
            self.assertEqual(out.tobytes(), image.tobytes(), color)
            self.assertTrue(info["outside_identical"])

    def test_inpaint_rejects_wrong_canvas_and_empty_mask(self):
        image = Image.new("RGBA", (16, 16))
        with self.assertRaises(ValueError):
            inpaint.merge(image, image, 2, (1, 1, 4, 4))
        with self.assertRaises(ValueError):
            inpaint.prepare(image, (1, 1, 1, 4))

    def test_conservative_cleanup_keeps_orphans_and_holes_idempotently(self):
        image = Image.new("RGBA", (16, 16))
        image.paste("#008000", (6, 6, 12, 12))
        image.putpixel((8, 8), (0, 0, 0, 0))
        image.putpixel((1, 1), (255, 255, 0, 255))
        opts = pipeline.Options(kind="free", noise=0)
        once, _ = pipeline.finish(image, opts, contracts.get("free"), None)
        twice, _ = pipeline.finish(once, opts, contracts.get("free"), None)
        self.assertEqual(once.tobytes(), image.tobytes())
        self.assertEqual(twice.tobytes(), image.tobytes())

    def test_cleanup_can_be_requested_explicitly(self):
        image = Image.new("RGBA", (16, 16))
        image.putpixel((1, 1), (255, 255, 0, 255))
        opts = pipeline.Options(kind="free", remove_orphans=True)
        out, info = pipeline.finish(image, opts, contracts.get("free"), None)
        self.assertEqual(info["despeckle"]["orphans"], 1)
        self.assertIsNone(out.getbbox())

    def test_known_cells_preserve_a_four_pixel_jump_by_default(self):
        d = tempdir()
        image = Image.new("RGBA", (128, 64))
        image.paste("#008000", (25, 30, 40, 56))
        image.paste("#008000", (89, 26, 104, 52))
        image.save(d / "jump.png")
        result = sheetforge.forge_sheet(d / "jump.png", d / "out",
                                       pipeline.Options(kind="free", scale=1, noise=0, canvas=(64, 64)),
                                       sheetforge.SheetOptions(layout=(2, 1), tags=[("jump", 2)]))
        a, b = [Image.open(result["files"][f"cell_{i}"]).convert("RGBA") for i in range(2)]
        self.assertEqual(a.getbbox()[1] - b.getbbox()[1], 4)
        self.assertEqual(a.tobytes(), image.crop((0, 0, 64, 64)).tobytes())

    def test_godot_directions_preserve_order_and_duration(self):
        rects = [(i * 16, 0, 16, 16) for i in range(3)]
        for direction, order in {"reverse": [2, 1, 0], "pingpong": [0, 1, 2, 1],
                                 "pingpong_reverse": [2, 1, 0, 1]}.items():
            text = godot.sprite_frames("res://test.png", rects, [100, 200, 300], [("x", 0, 2, direction)])
            pairs = re.findall(r'"duration": ([\d.]+),\n"texture": SubResource\("AtlasTexture_(\d+)"\)', text)
            self.assertEqual([(float(t), int(i)) for t, i in pairs], [(float(i + 1), i) for i in order])

    def test_godot_rejects_unknown_direction(self):
        with self.assertRaises(ValueError):
            godot.sprite_frames("res://test.png", [(0, 0, 16, 16)], [100], [("x", 0, 0, "typo")])
