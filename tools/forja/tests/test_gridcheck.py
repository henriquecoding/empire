"""A grade medida antes da estimada, e a recusa de um periodo que a amostragem desmente.

Os dois defeitos vieram da forense das imagens publicas do PixelLab (pesquisa de 26/10):
um tileset ampliado 2x saia com metade da resolucao, e um sprite nativo de 64x64 saia
com 12x11 celulas e `ok`. As imagens de terceiros nao entram no repositorio; os casos
aqui reproduzem os dois mecanismos.
"""
import random
import unittest
from unittest import mock

from PIL import Image

from tools.forja import grid, gridcheck, pipeline, synth
from tools.forja.tests.helpers import sprite


def detailed(size: int = 64, seed: int = 3) -> Image.Image:
    """Um sprite nativo com detalhe de um pixel em todo o lado (como um personagem de 64x64)."""
    rnd = random.Random(seed)
    tones = [(70, 40, 30), (150, 90, 50), (230, 190, 120), (40, 60, 120), (200, 60, 50), (240, 240, 230)]
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = im.load()
    for y in range(4, size - 4):
        for x in range(8, size - 8):
            px[x, y] = (*rnd.choice(tones), 255)
    return im


class ExactScaleTest(unittest.TestCase):
    def test_exact_upscales_are_measured(self):
        native = sprite(4)
        for k in (2, 3, 5):
            big = native.resize((native.width * k, native.height * k), Image.NEAREST)
            self.assertEqual(gridcheck.exact_scale(big), k)
            g = gridcheck.detect(big)
            self.assertEqual(g.size, native.size, k)
            self.assertIn(f"ampliacao exata {k}x", g.notes[0])

    def test_the_2x_that_the_estimate_missed_now_snaps_to_the_native_size(self):
        native = sprite(4)
        big = native.resize((native.width * 2, native.height * 2), Image.NEAREST)
        self.assertNotEqual(grid.detect(big).size, native.size)
        out, info = pipeline.snap(big, pipeline.Options(outline="keep", fit=False))
        self.assertEqual(info["grid"]["cells"], list(native.size))

    def test_native_and_noisy_images_are_not_exact(self):
        self.assertEqual(gridcheck.exact_scale(sprite(4)), 1)
        fake, _, _ = synth.fake(sprite(5), 8.0, 0.8, 0.7, 5, (255, 0, 255), 3, 5)
        self.assertEqual(gridcheck.exact_scale(fake), 1)


class PurityGuardTest(unittest.TestCase):
    def test_a_period_the_cells_contradict_is_refused(self):
        native = detailed()
        wrong = grid.known(native.size, 6.14)
        wrong.native = False
        with mock.patch.object(gridcheck.grid, "detect", return_value=wrong):
            g = gridcheck.detect(native)
        self.assertTrue(g.native)
        self.assertEqual(g.size, native.size)
        self.assertIn("recusado", g.notes[0])

    def test_a_real_upscale_keeps_the_estimated_grid(self):
        truth = sprite(5)
        fake, xs, ys = synth.fake(truth, 6.0, 0.5, 0.6, 4, (255, 0, 255), 3, 9)
        g = gridcheck.detect(fake)
        self.assertFalse(g.native)
        self.assertEqual(g.size, (len(xs) - 1, len(ys) - 1))

    def test_given_scale_or_cells_are_never_second_guessed(self):
        native = detailed()
        g = gridcheck.detect(native, scale=4)
        self.assertEqual(g.period, (4, 4))


if __name__ == "__main__":
    unittest.main()
