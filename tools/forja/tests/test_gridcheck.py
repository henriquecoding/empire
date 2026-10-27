"""A grade medida antes da estimada, e a recusa de um periodo que a amostragem desmente.

Os dois defeitos vieram da forense das imagens publicas do PixelLab (pesquisa de 26/10): uma
ampliacao exata pequena sai com metade da resolucao pela estimativa, e um sprite nativo de 64x64
saia com 12x11 celulas e `ok`. (O tileset que a forense deu como 2x e 4x no que se ve; a errata
esta no dossie.) As imagens de terceiros nao entram no repositorio; os casos aqui reproduzem os
mecanismos, e os da auditoria de 26/10 (A01: a fase) tambem.
"""
import random
import unittest
from unittest import mock

from PIL import Image

from tools.forja import grid, gridcheck, pipeline, sheet, synth
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

    def test_an_upscale_cut_out_of_phase_keeps_its_scale(self):
        """A01: recortada 6 px ao lado, uma ampliacao 10x saia "exata 2x" (o 6 e par) e a figura 5x maior."""
        native = sprite(4)
        big = native.resize((native.width * 10, native.height * 10), Image.NEAREST)
        for dx, dy in ((6, 6), (3, 7), (5, 0), (9, 1)):
            crop = big.crop((dx, dy, big.width, big.height))
            self.assertEqual(gridcheck.exact_grid(crop), (10, ((10 - dx) % 10, (10 - dy) % 10)), (dx, dy))
            out, info = pipeline.snap(crop, pipeline.Options(outline="keep", fit=False))
            ref = native.crop(native.getchannel("A").getbbox())
            self.assertEqual(out.tobytes(), ref.tobytes(), (dx, dy))
            self.assertIn("fase", info["grid"]["notes"][0])

    def test_a_flat_image_keeps_the_old_answer(self):
        """Lisa, e ampliacao de qualquer k: fica o maior ate 16 que divide os lados (o vazio sai rapido)."""
        self.assertEqual(gridcheck.exact_grid(Image.new("RGBA", (64, 48))), (16, (0, 0)))
        self.assertEqual(gridcheck.exact_grid(Image.new("RGBA", (63, 47), (9, 9, 9, 255))), (1, (0, 0)))

    def test_hidden_colour_under_transparency_is_not_drawing(self):
        native = sprite(4)
        big = native.resize((native.width * 4, native.height * 4), Image.NEAREST)
        px = big.load()
        px[1, 1] = (255, 0, 0, 0)
        self.assertEqual(gridcheck.exact_scale(big), 4)

    def test_an_exact_sheet_keeps_every_frame_at_its_size(self):
        frames = [sprite(s, (18, 30)) for s in range(4)]
        sheet_img = Image.new("RGBA", (4 * 40, 40))
        for i, f in enumerate(frames):
            sheet_img.alpha_composite(f, (i * 40 + 11, 5))
        big = sheet_img.resize((sheet_img.width * 10, sheet_img.height * 10), Image.NEAREST)
        boxes, _, masks = sheet.find_cells(big, None, (4, 1))
        figures = sheet.extract(big, boxes, None, masks=masks)
        self.assertEqual([f.period for f in figures], [10.0] * 4)
        self.assertEqual([f.native.size for f in figures], [f.crop(f.getchannel("A").getbbox()).size for f in frames])


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
