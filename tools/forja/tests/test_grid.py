import unittest

from PIL import Image

from tools.forja import grid, resample, synth
from tools.forja.tests.helpers import sprite


class GridTest(unittest.TestCase):
    def check(self, scale, jitter, blur, noise, seed=5):
        truth = sprite(seed)
        fake, xs, ys = synth.fake(truth, scale, jitter, blur, noise, (255, 0, 255), 3, seed)
        g = grid.detect(fake)
        self.assertEqual(g.size, (len(xs) - 1, len(ys) - 1), f"escala {scale}")
        self.assertLessEqual(max(abs(a - b) for a, b in zip(g.xs, xs)), max(2, int(scale * 0.2)))
        return g

    def test_integer_scale(self):
        self.assertAlmostEqual(self.check(16, 0, 0, 0).period[0], 16, delta=0.2)

    def test_fractional_jittered_blurred_noisy(self):
        self.check(15.6, 1.2, 0.9, 6)
        self.check(9.7, 0.8, 0.8, 8, seed=9)
        self.check(23.3, 2.0, 1.2, 8, seed=2)

    def test_native_art_stays_native(self):
        g = grid.detect(sprite(4))
        self.assertTrue(g.native)
        self.assertEqual(g.size, sprite(4).size)

    def test_known_grid(self):
        g = grid.known((64, 32), 8)
        self.assertEqual(g.size, (8, 4))

    def test_given_cells(self):
        truth = sprite(6)
        fake, xs, ys = synth.fake(truth, 12.0, 0, 0.5, 3, (0, 0, 255), 0, 1)
        g = grid.detect(fake, cells=(len(xs) - 1, len(ys) - 1))
        self.assertEqual(g.size, (len(xs) - 1, len(ys) - 1))

    def test_resample_recovers_flat_colors(self):
        truth = sprite(8)
        fake, _, _ = synth.fake(truth, 16, 0, 0, 0, (255, 0, 255), 0, 0)
        out = resample.resample(fake, grid.known(fake.size, 16)).image
        expected = Image.new("RGBA", truth.size, (255, 0, 255, 255))
        expected.alpha_composite(truth)
        self.assertEqual(out.tobytes(), expected.tobytes())

    def test_blockify_makes_two_pixel_clusters(self):
        img = resample.blockify(sprite(2, (16, 16)), 2)
        px = img.load()
        for y in range(0, 16, 2):
            for x in range(0, 16, 2):
                self.assertEqual(len({px[x, y], px[x + 1, y], px[x, y + 1], px[x + 1, y + 1]}), 1)
