"""FORJA-04, incremento 5: area, conectividade e bloco sao tres medidas diferentes; zero no dither e desligado.

Relatorio de 25/10, §7 e §15.2: `min_cluster` (N4) apagou uma diagonal valida de oito pixels; a tira 1x4 e o
quadrado 2x2 tem a mesma area e nenhum aparece como mancha pequena; e `strength=0` no dither pintava metade da
imagem de branco.
"""
import unittest

from PIL import Image, ImageDraw

from tools.forja import cleanup, contracts, lint, quantize
from tools.forja.imageops import flat
from tools.forja.palette import Palette

BODY, ACCENT = (80, 80, 80, 255), (240, 220, 60, 255)


def diagonal() -> Image.Image:
    img = Image.new("RGBA", (16, 16), BODY)
    for i in range(4, 12):
        img.putpixel((i, i), ACCENT)
    return img


class MinClusterTest(unittest.TestCase):
    def test_eight_connected_diagonal_is_kept_by_default(self):
        img = diagonal()
        out, merged = cleanup.min_cluster(img, 2)
        self.assertEqual(merged, 0)
        self.assertEqual(out.tobytes(), img.tobytes())

    def test_four_connectivity_is_an_explicit_choice(self):
        out, merged = cleanup.min_cluster(diagonal(), 2, connectivity=4)
        self.assertEqual(merged, 8)

    def test_protected_pixels_are_not_merged(self):
        img = Image.new("RGBA", (8, 8), BODY)
        img.putpixel((3, 3), ACCENT)
        out, merged = cleanup.min_cluster(img, 2, protect=[(3, 3, 4, 4)])
        self.assertEqual((merged, out.getpixel((3, 3))), (0, ACCENT))


class FootprintTest(unittest.TestCase):
    def shapes(self):
        strip, square = Image.new("RGBA", (10, 10)), Image.new("RGBA", (10, 10))
        ImageDraw.Draw(strip).rectangle((3, 3, 6, 3), fill=ACCENT)
        ImageDraw.Draw(square).rectangle((3, 3, 4, 4), fill=ACCENT)
        return strip, square

    def test_same_area_different_geometry(self):
        strip, square = self.shapes()
        self.assertEqual(cleanup.small_islands(strip, 2), cleanup.small_islands(square, 2))
        a, b = cleanup.footprint(strip, 2), cleanup.footprint(square, 2)
        self.assertEqual((a["components"], a["below_area"], a["without_block"]), (1, 0, 1))
        self.assertEqual((b["components"], b["below_area"], b["without_block"]), (1, 0, 0))
        self.assertEqual(a["shapes"][0]["size"], [4, 1])
        self.assertEqual((a["uncovered_pixels"], b["uncovered_pixels"]), (4, 0))

    def test_lint_says_it_as_information_for_scenery(self):
        strip, square = self.shapes()
        c = contracts.get("prop")
        info = [f for f in lint.check(strip, c, frame=False)["findings"] if f["rule"] == "blocks"]
        self.assertEqual([f["severity"] for f in info], ["info"])
        self.assertFalse([f for f in lint.check(square, c, frame=False)["findings"] if f["rule"] == "blocks"])


class DitherStrengthTest(unittest.TestCase):
    def test_zero_strength_is_no_dither(self):
        dark = Image.new("RGBA", (16, 16), (20, 20, 20, 255))
        pal = Palette([(0, 0, 0), (255, 255, 255)])
        zero = quantize.to_palette(dark, pal, "bayer2", strength=0)
        self.assertEqual(zero.tobytes(), quantize.to_palette(dark, pal, "none").tobytes())

    def test_full_strength_is_the_classic_pattern_and_half_is_in_between(self):
        grey = Image.new("RGBA", (16, 16), (50, 50, 50, 255))
        pal = Palette([(0, 0, 0), (255, 255, 255)])
        white = lambda im: sum(p[:3] == (255, 255, 255) for p in flat(im))  # noqa: E731
        full, half = (quantize.to_palette(grey, pal, "bayer4", strength=s) for s in (1.0, 0.5))
        self.assertGreater(white(full), white(half))
        self.assertGreater(white(half), 0)


if __name__ == "__main__":
    unittest.main()
