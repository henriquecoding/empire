"""Tons por limiar (FORJA-10): o ruido de compressao junta-se, o material e o detalhe de um pixel ficam."""
import unittest

from PIL import Image

from tools.forja import palette as palmod, tones


def noisy() -> Image.Image:
    image = Image.new('RGBA', (12, 8))
    for y in range(8):
        for x in range(6):
            image.putpixel((x, y), (137 + (x + y) % 3, 30 + x % 2, 45 + y % 2, 255))  # vinho com ruido
        for x in range(6, 12):
            image.putpixel((x, y), (42 + y % 2, 57, 101 + x % 3, 255))  # azul com ruido
    image.putpixel((2, 2), (250, 248, 249, 255))  # um brilho de um pixel
    image.putpixel((9, 5), (3, 1, 2, 255))  # um pixel quase preto
    return image


class TonesTest(unittest.TestCase):
    def test_compression_noise_collapses_but_materials_and_a_lone_highlight_stay(self):
        out, rep = tones.organize(noisy())
        hexes = [t['hex'] for t in rep['tones']]
        self.assertEqual(len(hexes), 4)
        self.assertIn('#FAF8F9', hexes)
        self.assertIn('#000000', hexes)
        self.assertEqual(out.getpixel((2, 2)), (250, 248, 249, 255))
        self.assertEqual(len({out.getpixel((x, 0)) for x in range(6)}), 1)

    def test_project_color_only_replaces_an_indistinguishable_tone(self):
        pal = palmod.Palette([(138, 30, 46), (40, 120, 40)])
        _, rep = tones.organize(noisy(), palette=pal)
        origins = {t['hex']: t['origin'] for t in rep['tones']}
        self.assertEqual(origins.get('#8A1E2E'), 'project')
        self.assertEqual(sum(1 for o in origins.values() if o == 'proposed'), 2)

    def test_no_color_cap_is_imposed(self):
        image = Image.new('RGBA', (40, 1))
        for x in range(40):
            image.putpixel((x, 0), ((x * 61) % 256, (x * 37) % 256, (x * 97) % 256, 255))
        _, rep = tones.organize(image)
        self.assertGreater(len(rep['tones']), 24)


if __name__ == '__main__':
    unittest.main()
