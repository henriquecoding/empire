"""FORJA-04, incremento 4: a cintilacao diagnostica-se antes de se corrigir, e so se corrige onde se sabe.

Relatorio de 25/10, §7 e §14: o `blink` reabria um olho fechado de proposito e o `deflicker` igualava o segundo
quadro ao primeiro numa faixa de baixo contraste que andou uma coluna. Agora o piscar e a faixa sobrevivem, um ponto
de ruido numa regiao estatica declarada e identificado (e corrigido so ali), e o que nao se pode avaliar diz-se.
"""
import unittest

from PIL import Image, ImageDraw

from tools.forja import pipeline, quantize, sheetforge, temporal
from tools.forja.tests.helpers import tempdir
from tools.forja.tests.test_preserve import strip_sheet

BODY, BLACK = (80, 80, 80, 255), (0, 0, 0, 255)


def eye(open_: bool) -> Image.Image:
    img = Image.new("RGBA", (9, 9), BODY)
    if open_:
        img.putpixel((4, 4), BLACK)
    return img


def stripe(col: int) -> Image.Image:
    img = Image.new("RGBA", (16, 16), (100, 100, 100, 255))
    ImageDraw.Draw(img).line((col, 2, col, 13), fill=(110, 110, 110, 255))
    return img


def whole(img) -> list[tuple[int, int, int, int]]:
    return [(0, 0, img.width, img.height)]


class BlinkTest(unittest.TestCase):
    def test_an_intentional_blink_survives_by_default(self):
        frames = [eye(True), eye(False), eye(True)]
        out, count = quantize.blink(frames)
        self.assertEqual(count, 0)
        self.assertEqual(out[1].tobytes(), frames[1].tobytes())
        diag = temporal.diagnose(frames)
        self.assertEqual(diag["counts"]["inconclusive"], 1)
        self.assertEqual(diag["candidates"][0]["kind"], "blink")

    def test_a_declared_action_region_keeps_it_even_inside_a_static_region(self):
        frames = [eye(True), eye(False), eye(True)]
        out, rep = temporal.stabilize(frames, 0.05, static=whole(frames[0]), actions=[(3, 3, 6, 6)])
        self.assertEqual(out[1].tobytes(), frames[1].tobytes())
        self.assertEqual(rep["counts"]["expected"], 1)
        self.assertEqual(rep["changed"], [])


class MotionTest(unittest.TestCase):
    def test_low_contrast_stripe_moving_one_column_survives(self):
        frames = [stripe(5), stripe(6)]
        out, count = quantize.deflicker(frames, threshold=0.05)
        self.assertEqual(count, 0)
        self.assertEqual(out[1].tobytes(), frames[1].tobytes())

    def test_even_inside_a_static_region_motion_is_not_frozen(self):
        frames = [stripe(5), stripe(6)]
        out, rep = temporal.stabilize(frames, 0.05, static=whole(frames[0]))
        self.assertEqual(out[1].tobytes(), frames[1].tobytes())
        self.assertEqual(rep["counts"]["review"], 0)
        self.assertGreater(rep["counts"]["motion"], 0)


class NoiseTest(unittest.TestCase):
    def frames(self):
        base = Image.new("RGBA", (12, 12), (100, 100, 100, 255))
        noisy = base.copy()
        noisy.putpixel((7, 4), (104, 104, 104, 255))
        return [base, noisy, base.copy()]

    def test_speck_in_a_static_region_is_found_and_fixed_only_there(self):
        frames = self.frames()
        diag = temporal.diagnose(frames, 0.05, static=whole(frames[0]))
        self.assertEqual(diag["counts"]["review"], 1)
        out, rep = temporal.stabilize(frames, 0.05, static=whole(frames[0]))
        self.assertEqual(out[1].getpixel((7, 4)), (100, 100, 100, 255))
        self.assertEqual(rep["changed"], [[1, 7, 4]])

    def test_outside_any_static_region_nothing_changes_and_it_says_so(self):
        frames = self.frames()
        out, rep = temporal.stabilize(frames, 0.05, static=[(0, 0, 4, 4)])
        self.assertEqual(out[1].tobytes(), frames[1].tobytes())
        self.assertEqual(rep["counts"]["inconclusive"], 1)
        self.assertIn("nao avaliad", rep["note"])

    def test_threshold_zero_means_no_drift_correction(self):
        frames = self.frames()[:2]
        out, rep = temporal.stabilize(frames, 0.0, static=whole(frames[0]))
        self.assertEqual(rep["changed"], [])

    def test_a_tiny_uniform_drift_is_held_in_a_static_region(self):
        a = Image.new("RGBA", (2, 2), (100, 100, 100, 255))
        b = Image.new("RGBA", (2, 2), (101, 100, 100, 255))
        self.assertEqual(quantize.deflicker([a, b])[1], 0)
        out, rep = temporal.stabilize([a, b], 0.05, static=whole(a))
        self.assertEqual(len(rep["changed"]), 4)
        self.assertEqual(out[1].tobytes(), a.tobytes())


class SheetTest(unittest.TestCase):
    def figure(self, open_: bool) -> Image.Image:
        im = Image.new("RGBA", (10, 12))
        ImageDraw.Draw(im).rectangle((0, 0, 9, 11), fill=(200, 60, 60, 255))
        if open_:
            im.putpixel((4, 4), BLACK)
        return im

    def test_sheet_deflicker_without_static_region_changes_nothing_and_says_so(self):
        d = tempdir()
        strip_sheet([(self.figure(o), (11, 10)) for o in (True, False, True)]).save(d / "s.png")
        res = sheetforge.forge_sheet(d / "s.png", d / "out", pipeline.Options(kind="free", scale=4),
                                     sheetforge.SheetOptions(tags=[("blink", 3)], layout=(3, 1), deflicker=0.05))
        fix = res["fixes"]["deflicker"]
        self.assertEqual(fix["changed"], 0)
        self.assertGreaterEqual(fix["counts"]["inconclusive"], 1)
        self.assertIn("nenhuma regiao estatica", fix["note"])


if __name__ == "__main__":
    unittest.main()
