"""FORJA-04, incremento 3: cor por material, dentro da paleta autorizada, e agrupamento so com prova local.

Relatorio de 25/10, §12 e §11.5: cada regiao com rampa so recebe cores dessa rampa (contida na paleta mestra);
uma regiao sem rampa fica com a mestra; os pixels presos nao mudam; um fragmento so se funde quando esta na zona
editavel, nao toca o que esta preso, nao mexe no alfa, nao fecha uma separacao nem parte um traco, e a cor que o
absorve domina a vizinhanca. Na duvida fica, com as alternativas escritas.
"""
import unittest

from PIL import Image, ImageDraw

from tools.forja import materials
from tools.forja.imageops import flat
from tools.forja.palette import Palette

DARK, MID, LIGHT, NEAR = (43, 52, 33), (65, 110, 78), (137, 149, 67), (98, 115, 49)
BROWN, BLACK = (125, 68, 51), (0, 0, 0)
MASTER = Palette([BLACK, DARK, MID, LIGHT, NEAR, BROWN, (143, 166, 71)])


def field(size=(12, 12), fill=MID) -> Image.Image:
    return Image.new("RGBA", size, (*fill, 255))


def everything(img):
    return frozenset((x, y) for y in range(img.height) for x in range(img.width))


def plan(**regions) -> dict:
    return {"schema": "forja.cores/1", "palette": "inline", "lock": [], "regions": regions}


class PlanTest(unittest.TestCase):
    def test_ramp_must_live_in_the_master_palette(self):
        errors = materials.validate(plan(cloth={"ramp": ["#123456"]}), MASTER, {"cloth"})
        self.assertTrue(any("#123456" in e for e in errors))

    def test_unknown_region_and_schema(self):
        errors = materials.validate({"schema": "x", "regions": {"capa": {"ramp": ["#000000"]}}}, MASTER, {"cloth"})
        self.assertEqual(len(errors), 2)

    def test_a_global_budget_is_not_silently_ignored(self):
        errors = materials.validate({**plan(), "budget": 8}, MASTER, set())
        self.assertTrue(any("budget" in e for e in errors))


class RemapTest(unittest.TestCase):
    def test_near_tone_goes_to_the_ramp_and_locked_and_outside_stay(self):
        img = field()
        img.putpixel((3, 3), (*NEAR, 255))
        img.putpixel((8, 8), (*NEAR, 255))
        img.putpixel((10, 1), (*NEAR, 255))
        cloth = frozenset(p for p in everything(img) if p[0] < 10)
        out, rep = materials.remap(img, {"cloth": cloth}, {"cloth": Palette([DARK, MID, LIGHT])},
                                   locked=frozenset({(8, 8)}))
        self.assertIn(out.getpixel((3, 3))[:3], (MID, LIGHT))
        self.assertEqual(out.getpixel((8, 8))[:3], NEAR)
        self.assertEqual(out.getpixel((10, 1))[:3], NEAR)
        self.assertEqual(rep["cloth"]["changed"], 1)
        self.assertEqual(rep["cloth"]["locked_off_ramp"], [[8, 8, "#627331"]])


class RegroupTest(unittest.TestCase):
    def run_one(self, img, locked=frozenset(), ramp=(DARK, MID, LIGHT)):
        regions = {"cloth": {"pixels": everything(img), "material": "cloth", "trusted": True}}
        return materials.regroup(img, regions, {"cloth": Palette(list(ramp))}, {"cloth"}, locked)

    def test_lonely_light_speck_joins_its_mass(self):
        img = field()
        img.putpixel((5, 5), (*LIGHT, 255))
        out, rep = self.run_one(img)
        self.assertEqual(out.getpixel((5, 5))[:3], MID)
        self.assertEqual(rep["merged"][0]["from"], "#899543")
        self.assertEqual([p[3] for p in flat(out)], [p[3] for p in flat(img)])

    def test_outline_colour_is_structure_not_noise(self):
        img = field()
        img.putpixel((5, 5), (*BLACK, 255))
        out, rep = self.run_one(img, ramp=(BLACK, MID))
        self.assertEqual(out.getpixel((5, 5))[:3], BLACK)
        self.assertEqual(rep["kept"][0]["why"], "cor do contorno: e estrutura")

    def test_short_diagonal_is_left_for_stroke_review(self):
        img = field()
        img.putpixel((4, 4), (*LIGHT, 255))
        img.putpixel((5, 5), (*LIGHT, 255))
        out, rep = self.run_one(img)
        self.assertEqual(out.tobytes(), img.tobytes())
        self.assertEqual(rep["merged"], [])

    def test_speck_touching_locked_pixels_stays(self):
        img = field()
        img.putpixel((5, 5), (*LIGHT, 255))
        out, _ = self.run_one(img, locked=frozenset({(5, 5)}))
        self.assertEqual(out.getpixel((5, 5))[:3], LIGHT)

    def test_a_speck_that_separates_two_masses_is_not_filled(self):
        img = field(fill=DARK)
        ImageDraw.Draw(img).line((0, 5, 4, 5), fill=(*MID, 255))
        ImageDraw.Draw(img).line((6, 5, 11, 5), fill=(*MID, 255))
        img.putpixel((5, 5), (*LIGHT, 255))
        out, rep = self.run_one(img)
        self.assertEqual(out.getpixel((5, 5))[:3], LIGHT)
        self.assertIn("separa", rep["kept"][0]["why"])

    def test_ambiguous_junction_returns_alternatives(self):
        img = field(fill=DARK)
        ImageDraw.Draw(img).rectangle((7, 0, 11, 11), fill=(*MID, 255))
        ImageDraw.Draw(img).rectangle((6, 6, 11, 11), fill=(*MID, 255))
        img.putpixel((6, 5), (*LIGHT, 255))
        out, rep = self.run_one(img)
        self.assertEqual(out.getpixel((6, 5))[:3], LIGHT)
        self.assertEqual(set(rep["kept"][0]["alternatives"]), {"#2B3421", "#416E4E"})


class SeparationTest(unittest.TestCase):
    def test_lost_border_between_regions_is_reported(self):
        before = field()
        ImageDraw.Draw(before).rectangle((6, 0, 11, 11), fill=(*BROWN, 255))
        after = field()
        left = frozenset(p for p in everything(before) if p[0] < 6)
        right = frozenset(p for p in everything(before) if p[0] >= 6)
        lost = materials.separation(before, after, {"skin": left, "leather": right})
        self.assertEqual(lost[0]["pair"], ["leather", "skin"])
        self.assertEqual((lost[0]["distinct_before"], lost[0]["distinct_after"]), (12, 0))
        self.assertTrue(lost[0]["lost"])


if __name__ == "__main__":
    unittest.main()
