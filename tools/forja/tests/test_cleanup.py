import unittest

from PIL import Image

from tools.forja import cleanup, matte, outline, quantize
from tools.forja.imageops import CLEAR, flat
from tools.forja.palette import Palette
from tools.forja.tests.helpers import sprite


def blank(size=(8, 8)):
    return Image.new("RGBA", size, CLEAR)


class MatteTest(unittest.TestCase):
    def test_key_background_goes_everywhere(self):
        img = Image.new("RGBA", (6, 6), (0, 0, 255, 255))
        img.putpixel((2, 2), (200, 50, 50, 255))
        out, info = matte.remove(img)
        self.assertEqual(info["mode"], "key")
        self.assertEqual(sum(1 for p in flat(out) if p[3]), 1)

    def test_flat_background_keeps_enclosed_holes(self):
        img = Image.new("RGBA", (7, 7), (200, 200, 200, 255))
        for x in range(1, 6):
            for y in range(1, 6):
                img.putpixel((x, y), (20, 20, 20, 255))
        img.putpixel((3, 3), (200, 200, 200, 255))
        out, info = matte.remove(img)
        self.assertEqual(info["mode"], "flat")
        self.assertEqual(out.getpixel((3, 3))[3], 255)
        self.assertEqual(out.getpixel((0, 0))[3], 0)

    def test_best_key_avoids_palette(self):
        self.assertNotEqual(matte.best_key([(255, 0, 255), (250, 10, 240)]), "#FF00FF")


class CleanupTest(unittest.TestCase):
    def test_orphan_and_hole(self):
        img = blank()
        img.putpixel((0, 0), (9, 9, 9, 255))
        for x in range(3, 6):
            for y in range(3, 6):
                img.putpixel((x, y), (100, 0, 0, 255))
        img.putpixel((4, 4), CLEAR)
        out, stats = cleanup.despeckle(img)
        self.assertEqual(stats["orphans"], 1)
        self.assertEqual(stats["holes"], 1)
        self.assertEqual(out.getpixel((4, 4))[:3], (100, 0, 0))

    def test_noise_is_smoothed_but_contrast_kept(self):
        img = Image.new("RGBA", (5, 5), (100, 100, 100, 255))
        img.putpixel((2, 2), (103, 100, 100, 255))
        img.putpixel((1, 1), (255, 255, 255, 255))
        out, stats = cleanup.despeckle(img)
        self.assertEqual(out.getpixel((2, 2))[:3], (100, 100, 100))
        self.assertEqual(out.getpixel((1, 1))[:3], (255, 255, 255))

    def test_min_cluster(self):
        img = Image.new("RGBA", (6, 6), (0, 100, 0, 255))
        img.putpixel((2, 2), (100, 0, 0, 255))
        out, merged = cleanup.min_cluster(img, 2)
        self.assertEqual(merged, 1)
        self.assertEqual(out.getpixel((2, 2))[:3], (0, 100, 0))

    def test_pixel_perfect_removes_l_corner(self):
        img = Image.new("RGBA", (5, 5), (200, 200, 200, 255))
        for x, y in ((0, 2), (1, 2), (1, 1), (2, 1), (3, 1)):
            img.putpixel((x, y), (0, 0, 0, 255))
        out, removed = cleanup.pixel_perfect(img)
        self.assertEqual(removed, 1)


class OutlineTest(unittest.TestCase):
    def test_add_measure_strip(self):
        img = blank((10, 10))
        img.paste((180, 40, 40, 255), (3, 3, 7, 7))
        lined = outline.add(img, (0, 0, 0), 1)
        m = outline.measure(lined)
        self.assertEqual(m["outline_share"], 1.0)
        self.assertEqual(m["thickness"], 1)
        stripped, found = outline.strip(lined)
        self.assertEqual(found, (0, 0, 0))
        self.assertEqual(stripped.tobytes(), img.tobytes())

    def test_selective_uses_darker_palette_color(self):
        img = blank((6, 6))
        img.paste((180, 40, 40, 255), (2, 2, 4, 4))
        pal = Palette([(180, 40, 40), (90, 20, 20), (250, 250, 250)])
        lined = outline.add(img, mode="selective", palette=pal)
        self.assertEqual(lined.getpixel((1, 2))[:3], (90, 20, 20))

    def test_normalize_near_black_edges(self):
        img = blank((6, 6))
        img.paste((20, 18, 24, 255), (1, 1, 5, 5))
        img.paste((180, 40, 40, 255), (2, 2, 4, 4))
        out, changed = outline.normalize(img)
        self.assertEqual(changed, 12)
        self.assertEqual(out.getpixel((1, 1))[:3], (0, 0, 0))


class QuantizeTest(unittest.TestCase):
    def test_bayer(self):
        m = quantize.bayer(4)
        self.assertEqual(sorted(round(v * 16 - 0.5) for row in m for v in row), list(range(16)))

    def test_to_palette_only_uses_palette(self):
        pal = Palette([(0, 0, 0), (255, 0, 0), (255, 255, 255)])
        out = quantize.to_palette(sprite(3), pal)
        self.assertTrue({p[:3] for p in flat(out) if p[3]} <= set(pal.colors))

    def test_dither_mixes_two_colors(self):
        pal = Palette([(0, 0, 0), (255, 255, 255)])
        img = Image.new("RGBA", (8, 8), (128, 128, 128, 255))
        out = quantize.to_palette(img, pal, "bayer4")
        self.assertEqual({p[:3] for p in flat(out)}, {(0, 0, 0), (255, 255, 255)})

    def test_deflicker_locks_tiny_changes_only_in_a_static_region(self):
        a = Image.new("RGBA", (2, 2), (100, 100, 100, 255))
        b = Image.new("RGBA", (2, 2), (101, 100, 100, 255))
        self.assertEqual(quantize.deflicker([a, b])[1], 0)
        out, fixed = quantize.deflicker([a, b], static=[(0, 0, 2, 2)])
        self.assertEqual(fixed, 4)
        self.assertEqual(out[1].tobytes(), a.tobytes())
