"""FORJA-04, incrementos 2 e 3: a protecao vale ate ao PNG final, e um orcamento de cores nunca e ignorado.

Os casos sao os do relatorio de 25/10 (§7): o pixel 105 protegido saia 100 depois da paleta; com paleta dada,
`colors=2` terminava com tres cores. Agora a garantia mede-se no fim (E(P), por posicao final) e, quando duas
garantias nao cabem juntas, o resultado diz o conflito em vez de declarar as duas cumpridas.
"""
import unittest

from PIL import Image, ImageDraw

from tools.forja import contracts, guard, pipeline, quantize
from tools.forja.imageops import count_colors, flat
from tools.forja.palette import Palette
from tools.forja.tests.helpers import tempdir

GREY, SUBTLE = (100, 100, 100, 255), (105, 105, 105, 255)


def face() -> Image.Image:
    img = Image.new("RGBA", (9, 9), GREY)
    img.putpixel((4, 4), SUBTLE)
    return img


def free(**kw) -> pipeline.Options:
    return pipeline.Options(**{"kind": "free", "cleanup": "character", "fit": False, "outline": "keep", **kw})


class ProtectionTest(unittest.TestCase):
    def test_protected_pixel_survives_the_palette_and_the_conflict_is_said(self):
        out, info = pipeline.finish(face(), free(protect=[(4, 4, 5, 5)]), contracts.get("free"),
                                    Palette([GREY[:3]]))
        self.assertEqual(out.getpixel((4, 4)), SUBTLE)
        self.assertEqual(info["protect"]["changed_final"], 0)
        self.assertEqual(info["protect"]["conflicts"], [[4, 4, "#696969"]])

    def test_without_protection_nothing_changes_in_behaviour(self):
        out, info = pipeline.finish(face(), free(), contracts.get("free"), Palette([GREY[:3]]))
        self.assertEqual(out.getpixel((4, 4)), GREY)
        self.assertNotIn("protect", info)

    def test_in_palette_protected_edge_pixel_is_not_normalised_to_black(self):
        img = Image.new("RGBA", (12, 12))
        ImageDraw.Draw(img).rectangle((2, 2, 9, 9), fill=(0, 0, 0, 255))
        ImageDraw.Draw(img).rectangle((3, 3, 8, 8), fill=(200, 60, 60, 255))
        img.putpixel((2, 5), (20, 20, 20, 255))
        pal = Palette([(0, 0, 0), (20, 20, 20), (200, 60, 60)])
        opts = free(kind="character_s1", protect=[(2, 5, 3, 6)])
        out, info = pipeline.finish(img, opts, contracts.get("character_s1"), pal)
        self.assertEqual(info["protect"], {**info["protect"], "changed_final": 0, "conflicts": []})
        x, y = guard.final_xy((2, 5), info)
        self.assertEqual(out.getpixel((x, y)), (20, 20, 20, 255))
        plain, _ = pipeline.finish(img, free(kind="character_s1"), contracts.get("character_s1"), pal)
        self.assertEqual(plain.getpixel((x, y)), (0, 0, 0, 255))

    def test_exact_through_cluster_upscale_and_canvas(self):
        img = Image.new("RGBA", (10, 12))
        ImageDraw.Draw(img).rectangle((1, 1, 8, 10), fill=(90, 120, 60, 255))
        img.putpixel((4, 5), (93, 121, 62, 255))
        c = contracts.get("character_s1")
        opts = free(kind="character_s1", fit=True, outline="auto", protect=[(4, 5, 5, 6)])
        out, info = pipeline.finish(img, opts, c, None)
        self.assertEqual(info["protect"]["changed_final"], 0)
        self.assertEqual(out.getpixel(guard.final_xy((4, 5), info)), (93, 121, 62, 255))

    def test_outline_does_not_enter_a_protected_empty_pixel(self):
        img = Image.new("RGBA", (10, 10))
        ImageDraw.Draw(img).rectangle((2, 2, 7, 7), fill=(200, 60, 60, 255))
        plain, info = pipeline.finish(img, free(kind="character_s1", outline="auto"), contracts.get("character_s1"),
                                      None)
        self.assertEqual(plain.getpixel(guard.final_xy((8, 4), info)), (0, 0, 0, 255))
        opts = free(kind="character_s1", outline="auto", protect=[(8, 4, 9, 5)])
        out, info = pipeline.finish(img, opts, contracts.get("character_s1"), None)
        self.assertEqual(out.getpixel(guard.final_xy((8, 4), info))[3], 0)
        self.assertEqual(info["protect"]["changed_final"], 0)

    def test_forge_reports_the_conflict_as_an_error(self):
        out = tempdir()
        src = out / "face.png"
        framed = Image.new("RGBA", (11, 11))
        framed.alpha_composite(face(), (1, 1))
        framed.resize((44, 44), Image.Resampling.NEAREST).save(src)
        res = pipeline.forge(src, out / "r", free(scale=4.0, palette="#646464", protect=[(4, 4, 5, 5)]),
                             report_html=False)
        rules = {f["rule"]: f["severity"] for f in res["lint"]["findings"]}
        self.assertEqual(rules.get("protect_conflict"), "error")
        self.assertFalse(res["lint"]["ok"])
        self.assertIn("color_coherence", res["verdicts"])


class BudgetTest(unittest.TestCase):
    def scatter(self):
        img = Image.new("RGBA", (80, 80))
        ImageDraw.Draw(img).rectangle((20, 18, 59, 78), fill=(80, 80, 80, 255), outline=(0, 0, 0, 255))
        for y in (26, 38, 50, 62):
            for x in (25, 34, 43, 52):
                img.putpixel((x, y), (240, 220, 60, 255))
        return img

    def test_colors_with_a_palette_is_applied_as_a_subset(self):
        pal = Palette([(0, 0, 0), (80, 80, 80), (240, 220, 60)])
        opts = pipeline.Options(kind="royal_80", colors=2, fit=False, outline="keep")
        out, info = pipeline.finish(self.scatter(), opts, contracts.get("royal_80"), pal)
        self.assertEqual(count_colors(out), 2)
        budget = info["palette"]["budget"]
        self.assertEqual((budget["requested"], budget["applied"], budget["output_colors"]), (2, True, 2))
        self.assertIn("#000000", budget["chosen"])
        self.assertTrue(all(p[:3] in pal for p in flat(out) if p[3]))

    def test_budget_smaller_than_the_protected_colors_is_a_conflict(self):
        img = Image.new("RGBA", (6, 2), (10, 10, 10, 255))
        img.putpixel((1, 0), (200, 0, 0, 255))
        img.putpixel((3, 0), (0, 200, 0, 255))
        pal = Palette([(10, 10, 10), (200, 0, 0), (0, 200, 0)])
        out, info = pipeline.finish(img, free(colors=2, protect=[(0, 0, 6, 1)]), contracts.get("free"), pal)
        budget = info["palette"]["budget"]
        self.assertFalse(budget["applied"])
        self.assertIn("protegid", budget["conflict"])
        self.assertEqual(out.tobytes(), img.tobytes())

    def test_extracted_budget_keeps_the_protected_colour_inside_the_count(self):
        img = Image.new("RGBA", (8, 8), (40, 90, 160, 255))
        ImageDraw.Draw(img).rectangle((0, 0, 3, 7), fill=(200, 160, 60, 255))
        img.putpixel((6, 6), (43, 92, 158, 255))
        out, info = pipeline.finish(img, free(colors=2, protect=[(6, 6, 7, 7)]), contracts.get("free"), None)
        self.assertEqual(out.getpixel((6, 6)), (43, 92, 158, 255))
        self.assertLessEqual(count_colors(out), 2)
        self.assertTrue(info["palette"]["budget"]["applied"])

    def test_subset_helper_is_deterministic_and_inside_the_palette(self):
        pal = Palette([(0, 0, 0), (80, 80, 80), (240, 220, 60), (250, 250, 250)])
        a = quantize.subset(self.scatter(), pal, 2, required=[(0, 0, 0)])
        b = quantize.subset(self.scatter(), pal, 2, required=[(0, 0, 0)])
        self.assertEqual(a.colors, b.colors)
        self.assertTrue(set(a.colors) <= set(pal.colors))


if __name__ == "__main__":
    unittest.main()
