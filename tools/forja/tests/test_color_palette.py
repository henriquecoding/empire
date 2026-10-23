import unittest

from PIL import Image

from tools.forja import color, palette
from tools.forja.tests.helpers import sprite, tempdir


class ColorTest(unittest.TestCase):
    def test_oklab_round_trip(self):
        for rgb in ((0, 0, 0), (255, 255, 255), (89, 56, 107), (246, 216, 155), (12, 200, 90)):
            self.assertEqual(color.from_oklab(color.oklab(rgb)), rgb)

    def test_delta_orders_perceptual_differences(self):
        self.assertLess(color.delta((100, 100, 100), (102, 100, 100)), 0.02)
        self.assertGreater(color.delta((0, 0, 255), (255, 0, 255)), 0.1)

    def test_hex(self):
        self.assertEqual(color.parse_hex("#0f0"), (0, 255, 0))
        self.assertEqual(color.to_hex((89, 56, 107)), "#59386B")
        with self.assertRaises(ValueError):
            color.parse_hex("#12")


class PaletteTest(unittest.TestCase):
    def test_empire_palette_loads(self):
        pal = palette.load("empire")
        self.assertEqual(len(pal), 112)
        self.assertIn((0, 0, 0), pal)

    def test_nearest_and_two_nearest(self):
        pal = palette.Palette([(0, 0, 0), (255, 255, 255)])
        self.assertEqual(pal.nearest((30, 30, 30)), (0, 0, 0))
        i, j, t = pal.two_nearest((128, 128, 128))
        self.assertEqual({i, j}, {0, 1})
        self.assertTrue(0 < t < 1)

    def test_extract_is_deterministic_and_bounded(self):
        img = sprite(3)
        a, b = palette.extract(img, 4), palette.extract(img, 4)
        self.assertEqual(a.colors, b.colors)
        self.assertLessEqual(len(a), 4)

    def test_save_and_load_formats(self):
        pal = palette.Palette([(1, 2, 3), (200, 100, 50)], "t")
        d = tempdir()
        for name in ("p.gpl", "p.hex", "p.json", "p.png"):
            self.assertEqual(palette.load(palette.save(pal, d / name)).colors, pal.colors)

    def test_inline_and_merge(self):
        pal = palette.load("#808080,#818181,#FFFFFF")
        self.assertEqual(len(palette.merge_close(pal, 0.04)), 2)

    def test_ramp_goes_dark_to_light(self):
        ramp = palette.ramp((90, 140, 60), 5)
        lights = [color.oklab(c)[0] for c in ramp.colors]
        self.assertEqual(lights, sorted(lights))

    def test_from_image_ignores_transparent(self):
        img = Image.new("RGBA", (2, 1))
        img.putpixel((0, 0), (9, 9, 9, 255))
        self.assertEqual(palette.from_image(img).colors, [(9, 9, 9)])
