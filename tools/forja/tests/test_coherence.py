"""FORJA-04, incremento 1: a cor organizada no espaco, ao lado (e nao dentro) do contrato raster.

As fixtures sao as do relatorio de 25/10 (§7): o mesmo histograma, os mesmos 2440 pixels opacos e tres cores,
uma vez com 16 pontos espalhados e outra com eles num bloco. O lint raster nao as distingue (e nao deve: as duas
cumprem a tela, a paleta e o contorno); o diagnostico de cor distingue-as sem apagar nada nem chamar defeito ao
que ninguem anotou.
"""
import unittest
from collections import Counter

from PIL import Image, ImageDraw

from tools.forja import clusters, contracts, lint, verdicts
from tools.forja.imageops import flat
from tools.forja.palette import Palette

BLACK, BODY, ACCENT = (0, 0, 0, 255), (80, 80, 80, 255), (240, 220, 60, 255)


def base() -> Image.Image:
    img = Image.new("RGBA", (80, 80))
    ImageDraw.Draw(img).rectangle((20, 18, 59, 78), fill=BODY, outline=BLACK, width=1)
    return img


def scatter() -> Image.Image:
    img = base()
    for y in (26, 38, 50, 62):
        for x in (25, 34, 43, 52):
            img.putpixel((x, y), ACCENT)
    return img


def cluster() -> Image.Image:
    img = base()
    ImageDraw.Draw(img).rectangle((36, 40, 39, 43), fill=ACCENT)
    return img


def plain(size=(16, 16), fill=BODY) -> Image.Image:
    return Image.new("RGBA", size, fill)


PAL = Palette([BLACK[:3], BODY[:3], ACCENT[:3]])


class SameHistogramTest(unittest.TestCase):
    def test_fixtures_share_the_histogram(self):
        self.assertEqual(Counter(flat(scatter())), Counter(flat(cluster())))

    def test_raster_contract_does_not_tell_them_apart(self):
        c = contracts.get("royal_80")
        a, b = lint.check(scatter(), c, PAL), lint.check(cluster(), c, PAL)
        for key in ("ok", "errors", "warnings", "prompt_feedback"):
            self.assertEqual(a[key], b[key], key)
        self.assertTrue(a["ok"])

    def test_the_spatial_diagnosis_does(self):
        a, b = clusters.diagnose(scatter()), clusters.diagnose(cluster())
        self.assertEqual((a["counts"]["review"], b["counts"]["review"]), (16, 0))
        self.assertEqual(a["figure"]["singletons8"], 16)
        self.assertEqual(b["figure"]["singletons8"], 0)
        self.assertAlmostEqual(a["figure"]["S8"], round(16 / 2440, 4))
        self.assertEqual((a["status"], b["status"]), ("needs_review", "pass"))

    def test_lint_carries_it_as_information_not_as_an_error(self):
        report = lint.check(scatter(), contracts.get("royal_80"), PAL)
        self.assertEqual(report["coherence"]["status"], "needs_review")
        info = [f for f in report["findings"] if f["rule"] == "fragments"]
        self.assertEqual([f["severity"] for f in info], ["info"])
        self.assertIsNone(info[0]["prompt_hint"])
        self.assertNotIn("fragments", {f["rule"] for f in lint.check(cluster(), contracts.get("royal_80"),
                                                                        PAL)["findings"]})

    def test_stats_match_the_research_package(self):
        self.assertEqual(clusters.stats(scatter()), {
            "size": [80, 80], "opaque": 2440, "colors": 3, "components4": 18, "components8": 18,
            "color_singletons4": 16, "color_singletons8": 16, "interior_color_singletons8": 16,
            "alpha_orphans8": 0})

    def test_diagnosis_never_changes_pixels(self):
        img = scatter()
        before = img.tobytes()
        clusters.diagnose(img)
        self.assertEqual(img.tobytes(), before)


class RolesTest(unittest.TestCase):
    def test_a_one_pixel_eye_is_expected_when_the_role_is_declared(self):
        img = plain()
        img.putpixel((5, 5), BLACK)
        found = clusters.diagnose(img)
        self.assertEqual(found["candidates"][0]["status"], "review")
        eye = {"eye": {"pixels": frozenset({(5, 5)}), "role": "eye", "trusted": True}}
        found = clusters.diagnose(img, eye)
        self.assertEqual(found["candidates"][0]["status"], "expected")
        self.assertEqual(found["status"], "pass")

    def test_protected_highlight_is_protected(self):
        img = plain()
        img.putpixel((9, 4), ACCENT)
        found = clusters.diagnose(img, protected=frozenset({(9, 4)}))
        self.assertEqual(found["candidates"][0]["status"], "protected")

    def test_untrusted_region_is_inconclusive(self):
        img = plain()
        img.putpixel((7, 7), ACCENT)
        cloth = {"cloth": {"pixels": frozenset((x, y) for x in range(16) for y in range(16)),
                           "material": "cloth", "trusted": False}}
        found = clusters.diagnose(img, cloth)
        self.assertEqual(found["candidates"][0]["status"], "inconclusive")
        self.assertEqual(found["status"], "inconclusive")

    def test_unknown_accent_role_is_refused(self):
        with self.assertRaises(ValueError):
            clusters.diagnose(plain(), {"x": {"pixels": frozenset({(1, 1)}), "role": "decoracao", "trusted": True}})


class StrokesTest(unittest.TestCase):
    def test_an_eight_pixel_diagonal_is_not_a_fragment(self):
        img = plain()
        for i in range(4, 12):
            img.putpixel((i, i), ACCENT)
        st = clusters.stats(img)
        self.assertEqual((st["color_singletons4"], st["color_singletons8"]), (8, 0))
        self.assertEqual(clusters.diagnose(img)["candidates"], [])

    def test_a_short_diagonal_goes_to_stroke_analysis(self):
        img = plain()
        img.putpixel((4, 4), ACCENT)
        img.putpixel((5, 5), ACCENT)
        cand = clusters.diagnose(img)["candidates"][0]
        self.assertEqual((cand["size"], cand["n4_pieces"], cand["status"]), (2, 2, "inconclusive"))

    def test_descriptors(self):
        img = plain()
        img.putpixel((8, 8), (90, 90, 90, 255))
        cand = clusters.diagnose(img)["candidates"][0]
        self.assertTrue(cand["interior"])
        self.assertEqual(cand["edge_distance"], 8)
        self.assertEqual(cand["dominant"], "#505050")
        self.assertLess(cand["dominant_delta"], 0.05)


class RegionMetricsTest(unittest.TestCase):
    def test_empty_region_is_not_applicable_and_not_zero(self):
        found = clusters.diagnose(plain(), {"face": {"pixels": frozenset(), "trusted": True}})
        self.assertEqual(found["regions"]["face"]["S8"], "n/a")
        self.assertEqual(found["regions"]["face"]["F"], "n/a")

    def test_region_components_are_local(self):
        img = plain()
        img.putpixel((2, 2), ACCENT)
        left = {"left": {"pixels": frozenset((x, y) for x in range(8) for y in range(16)), "trusted": True}}
        found = clusters.diagnose(img, left)
        self.assertEqual(found["regions"]["left"]["area"], 128)
        self.assertEqual(found["regions"]["left"]["singletons8"], 1)
        self.assertEqual(found["regions"]["left"]["U"], 1)

    def test_empty_image_is_not_evaluated(self):
        self.assertEqual(clusters.diagnose(Image.new("RGBA", (4, 4)))["status"], "not_evaluated")

    def test_what_is_not_measured_is_said(self):
        self.assertIn("banding", " ".join(clusters.diagnose(cluster())["not_measured"]))


class AxisTest(unittest.TestCase):
    def test_color_coherence_is_its_own_axis(self):
        self.assertIn("color_coherence", verdicts.AXES)
        v = verdicts.initial()
        self.assertEqual(v["color_coherence"]["status"], "not_evaluated")
        v = verdicts.for_review(True, None, coherence=clusters.diagnose(scatter()))
        self.assertEqual(v["raster_contract"]["status"], "pass")
        self.assertEqual(v["color_coherence"]["status"], "needs_review")
        self.assertEqual(verdicts.blocking(v), [])

    def test_fx_has_its_own_policy(self):
        report = lint.check(scatter(), contracts.get("fx"))
        self.assertEqual(report["coherence"]["status"], "not_evaluated")


if __name__ == "__main__":
    unittest.main()
