"""A auditoria de 26/10, aplicada a 27/10: as observacoes O3-O6 e as falhas A11 e A12 achadas ao aplica-las.

O1 (a forense) confere-se no verificar.py da pesquisa de 26/10 e O2 (as provas do arqueiro) no `make forja`.
Cenarios e antes/depois: docs/art/research/2026-10-26-forja-auditoria/.
"""
import unittest
from pathlib import Path
from unittest import mock

from PIL import Image

from tools.forja.tests.helpers import tempdir


class OpenItemsTest(unittest.TestCase):
    """O3-O6 da auditoria, aplicados a 27/10: o que estava aberto no relatorio."""

    def test_same_height_keeps_each_figure_on_its_own_grid(self):
        """O3: uma figura a 8x e outra (agachada, mais baixa) a 10x; nada se estica e o agachar nao cresce."""
        from tools.forja import sheet, synth
        tall, low = synth.sprite(1, (18, 30)), synth.sprite(2, (18, 20))
        board = Image.new("RGBA", (420, 300), (0, 0, 255, 255))
        board.alpha_composite(tall.resize((18 * 8, 30 * 8), Image.NEAREST), (20, 20))
        board.alpha_composite(low.resize((18 * 10, 20 * 10), Image.NEAREST), (220, 60))
        boxes, _, masks = sheet.find_masks(board, (0, 0, 255))
        crop = lambda im: im.crop(im.getchannel("A").getbbox())  # noqa: E731
        own = sheet.extract(board, boxes, (0, 0, 255), same_height=True, masks=masks)
        self.assertEqual([f.native.tobytes() for f in own], [crop(tall).tobytes(), crop(low).tobytes()])
        shared = sheet.extract(board, boxes, (0, 0, 255), masks=masks)
        self.assertTrue(any("escala propria" in " ".join(f.notes) for f in shared))

    def test_a_large_painting_without_a_grid_is_refused_at_once(self):
        """O4: sem grade e com mais do dobro da tela, recusa-se com a frase certa (era 225 s a 1920x1920)."""
        d = tempdir()
        paint = Image.new("RGBA", (300, 300))
        paint.putdata([(x % 256, (x * y) % 256, y % 256, 255) for y in range(300) for x in range(300)])
        from PIL import ImageFilter
        paint.filter(ImageFilter.GaussianBlur(8)).save(d / "pintura.png")
        from tools.forja import pipeline
        res = pipeline.forge(d / "pintura.png", d / "o", pipeline.Options(kind="royal_64"))
        self.assertEqual([f["rule"] for f in res["lint"]["findings"]], ["no_grid"])
        self.assertIn("crisp solid square block", res["lint"]["prompt_feedback"])
        self.assertEqual(Image.open(res["files"]["png"]).size, (64, 64))
        self.assertTrue(Path(res["files"]["report"]).exists())

    def test_a_cut_edge_is_a_margin_not_a_missing_outline(self):
        """O5: o lado cortado pela tela nao conta como contorno em falta; o `margin` diz o corte."""
        from tools.forja import contracts, lint
        img = Image.new("RGBA", (64, 64))
        img.paste((0, 0, 0, 255), (20, 30, 64, 64))
        img.paste((180, 60, 60, 255), (21, 31, 64, 64))
        report = lint.check(img, contracts.get("royal_64"))
        rules = {f["rule"] for f in report["findings"]}
        self.assertFalse(rules & {"outline", "outline_width"}, rules)
        self.assertIn("margin", rules)

    def test_forge_samples_the_image_once(self):
        """O6: a conferencia da grade ja amostrava pelo voto dominante; o `snap` repetia tudo."""
        from tools.forja import pipeline, resample, synth
        d = tempdir()
        fake, _, _ = synth.fake(synth.sprite(5), 8.0, 0.6, 0.6, 4, (0, 0, 255), 3, 5)
        fake.save(d / "f.png")
        real = resample.resample
        with mock.patch("tools.forja.resample.resample", side_effect=real) as spy, \
                mock.patch("tools.forja.gridcheck.resample", side_effect=real) as early:
            pipeline.forge(d / "f.png", d / "o", pipeline.Options(), report_html=False)
        self.assertEqual(spy.call_count + early.call_count, 1)

    def test_downscale_never_invents_a_colour(self):
        """O voto dominante fazia a media de tons do mesmo balde (aqui, 105, que nao estava no bloco)."""
        from tools.forja import scale
        block = Image.new("RGBA", (3, 3))
        tones = [(v, 100, 100, 255) for v in (96, 97, 98, 99, 108, 109, 110, 111, 111)]
        block.putdata(tones)
        self.assertEqual(scale.downscale(block, 3).getpixel((0, 0)), (111, 100, 100, 255))


if __name__ == "__main__":
    unittest.main()
