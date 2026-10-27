"""A auditoria de 27/10 (B02, B05-B08, B13-B15): o que a Forja lia, votava e desenhava errado sem dizer.

Os testes de rede, teto e MCP estao em test_auditoria_ii_rede. Cenarios e antes/depois:
docs/art/research/2026-10-27-forja-auditoria/.
"""
import io
import json
import unittest
from contextlib import redirect_stdout
from unittest import mock

from PIL import Image, ImageCms

from tools.forja import cli, color, grid as gridmod, outline, palette as palmod, pipeline, refs, resample
from tools.forja.equipment import image_sha
from tools.forja.imageops import open_rgba
from tools.forja.tests.helpers import linear_profile, tempdir


def _cell(colors: list[tuple[tuple[int, int, int], int]], side: int = 20) -> Image.Image:
    """Uma celula `side` x `side` com as cores dadas por contagem, linha a linha (sem sorteio)."""
    pixels = [(*c, 255) for c, n in colors for _ in range(n)]
    im = Image.new("RGBA", (side, side))
    im.putdata(pixels[:side * side])
    return im


class VoteTest(unittest.TestCase):
    """B02: a cor maioritaria numa fronteira de balde (128 = 8 x 16) ja nao perde para a minoria."""

    def vote(self, im: Image.Image) -> tuple[int, int, int]:
        return resample.resample(im, gridmod.known(im.size, im.width)).image.getpixel((0, 0))[:3]

    def test_a_noisy_colour_on_a_bucket_edge_wins_its_cell(self):
        # 60% de um laranja ruidoso a cavalo de 128/64 em dois canais, 40% de um castanho limpo
        base = [((126, 62, 200), 60), ((129, 65, 201), 60), ((127, 66, 199), 60), ((130, 63, 200), 60)]
        im = _cell(base + [((40, 40, 40), 160)])
        got = self.vote(im)
        self.assertLess(max(abs(a - b) for a, b in zip(got, (128, 64, 200))), 4, got)

    def test_flat_and_two_colour_cells_keep_their_exact_colour(self):
        self.assertEqual(self.vote(_cell([((128, 64, 200), 400)])), (128, 64, 200))
        self.assertEqual(self.vote(_cell([((128, 64, 200), 240), ((40, 40, 40), 160)])), (128, 64, 200))


class OutlineGapTest(unittest.TestCase):
    """B05: um contorno que ja cobria metade da borda nao fica com 2 px nessa metade."""

    def test_a_partial_outline_is_closed_not_doubled(self):
        body = Image.new("RGBA", (16, 24))
        body.paste((186, 52, 60, 255), (2, 2, 14, 22))
        spr = outline.add(body, (0, 0, 0), 1)
        for y in range(1, 23):
            spr.putpixel((1, y), (0, 0, 0, 0))
        for x in range(1, 15):
            spr.putpixel((x, 22), (0, 0, 0, 0))
        d = tempdir()
        spr.resize((96, 144), Image.Resampling.NEAREST).save(d / "p.png")
        res = pipeline.forge(d / "p.png", d / "o", pipeline.Options(kind="character_s1", palette="none", fit=False),
                             report_html=False)
        with Image.open(res["files"]["png"]) as im:
            fin = im.convert("RGBA")
        mark = lambda p: "." if p[3] < 128 else ("#" if p[:3] == (0, 0, 0) else "r")  # noqa: E731
        row = "".join(mark(fin.getpixel((x, fin.height // 2))) for x in range(fin.width))
        col = "".join(mark(fin.getpixel((fin.width // 2, y))) for y in range(fin.height))
        self.assertEqual((row.count("#"), col.count("#")), (2, 2), (row, col))


class OpenTest(unittest.TestCase):
    """B06 e B07: a imagem le-se como se ve — a orientacao EXIF aplicada, as cores em sRGB."""

    def test_exif_orientation_is_applied_and_recorded(self):
        d = tempdir()
        lying = Image.new("RGB", (200, 100), (255, 0, 255))
        ex = Image.Exif()
        ex[0x0112] = 6
        lying.save(d / "foto.png", exif=ex.tobytes())
        img = open_rgba(d / "foto.png")
        self.assertEqual(img.size, (100, 200))
        self.assertEqual(img.info["forja_source"], {"exif_orientation": 6})

    def test_a_non_srgb_profile_is_converted_and_srgb_is_left_exact(self):
        d = tempdir()
        Image.new("RGB", (4, 4), (128, 128, 128)).save(d / "linear.png", icc_profile=linear_profile())
        img = open_rgba(d / "linear.png")
        self.assertLessEqual(abs(img.getpixel((0, 0))[0] - 188), 1)
        self.assertIn("Linear RGB", img.info["forja_source"]["icc"])
        srgb = ImageCms.ImageCmsProfile(ImageCms.createProfile("sRGB")).tobytes()
        Image.new("RGB", (4, 4), (128, 64, 31)).save(d / "srgb.png", icc_profile=srgb)
        self.assertEqual(open_rgba(d / "srgb.png").getpixel((0, 0)), (128, 64, 31, 255))

    def test_the_forge_reports_what_the_opening_did(self):
        d = tempdir()
        big = Image.new("RGB", (120, 120), (255, 0, 255))
        big.paste((186, 52, 60), (40, 30, 80, 90))
        big.save(d / "g.png", icc_profile=linear_profile())
        res = pipeline.forge(d / "g.png", d / "o", pipeline.Options(kind="free"), report_html=False)
        self.assertIn("icc", res["provenance"]["input"]["opened"])


class HashTest(unittest.TestCase):
    """B08: a cor escondida debaixo do alfa 0 nao muda o hash dos pixels, nem tira um mestre do registo."""

    def test_a_resave_that_zeroes_hidden_colour_keeps_the_register(self):
        d = tempdir()
        a = Image.new("RGBA", (8, 8), (255, 0, 255, 0))
        a.putpixel((3, 3), (10, 200, 30, 255))
        a.save(d / "mestre.png")
        refs.add(d / "refs.json", d / "mestre.png", "adaptation_in_review", "rei-v3", by="Claude")
        b = Image.new("RGBA", (8, 8))
        b.putpixel((3, 3), (10, 200, 30, 255))
        b.save(d / "mestre.png")
        self.assertEqual(image_sha(a), image_sha(b))
        self.assertEqual(refs.load(d / "refs.json")["entries"][0]["id"], "rei-v3")

    def test_a_visible_change_still_changes_the_hash(self):
        a = Image.new("RGBA", (8, 8))
        b = a.copy()
        b.putpixel((0, 0), (0, 0, 0, 255))
        self.assertNotEqual(image_sha(a), image_sha(b))


class RampTest(unittest.TestCase):
    """B15: uma rampa fora do gamut sRGB baixa o croma; a luminosidade e o matiz ficam."""

    def test_a_saturated_ramp_keeps_its_hues(self):
        for base in ("#FFD000", "#2040FF", "#FF2020"):
            big_l, _, h = color.lch(color.parse_hex(base))
            ramp = palmod.ramp(color.parse_hex(base), 5)
            for i, c in enumerate(ramp.colors):
                t = (i / 4 - 0.5) * 2
                want = (h + palmod._hue_toward(h, 85.0) * 18 * t) % 360
                got = color.lch(c)[2]
                self.assertLess(abs((got - want + 180) % 360 - 180), 1.5, (base, i, ramp.hexes()))
            lights = [color.lch(c)[0] for c in ramp.colors]  # os dois claros podem ficar ambos no teto 0.97
            self.assertTrue(all(b > a - 0.002 for a, b in zip(lights, lights[1:])), (base, lights))


class SurfaceTest(unittest.TestCase):
    """B13 e B14: o pedido invalido responde em JSON; um caminho com virgula e um caminho."""

    def test_a_decompression_bomb_is_a_json_refusal(self):
        d = tempdir()
        Image.new("1", (100, 100)).save(d / "bomba.png")
        buf = io.StringIO()
        with mock.patch.object(Image, "MAX_IMAGE_PIXELS", 1000), redirect_stdout(buf):
            code = cli.main(["lint", str(d / "bomba.png"), "--kind", "royal_64"])
        self.assertEqual(code, 2)
        self.assertFalse(json.loads(buf.getvalue())["ok"])

    def test_a_palette_path_with_a_comma(self):
        d = tempdir() / "tons, quentes"
        palmod.save(palmod.Palette([(10, 20, 30), (200, 100, 50)], "x"), d / "pal.gpl")
        self.assertEqual(palmod.load(d / "pal.gpl").hexes(), ["#0A141E", "#C86432"])
        self.assertEqual(palmod.load("#0A141E,#C86432").hexes(), ["#0A141E", "#C86432"])


if __name__ == "__main__":
    unittest.main()
