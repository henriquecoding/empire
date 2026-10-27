"""A solucao de 27/10 (FORJA-06): a corda com miolo, contorno e cor declarados (§4, §7.4), os conflitos de rampa que
deixam o material pendente (§5, §7.5) e o banding como suspeita (Pixel Fixer, TU Delft, 2025).

A fixture do arqueiro e REJEITADA: a prova e da intencao declarada (o miolo claro em x=56, o contorno em x=57), nao
de arte aprovada. O manifesto e o da prova de 24/10 (o mesmo arco, as mesmas partes).
"""
import json
import unittest
from pathlib import Path

from PIL import Image

from tools.forja import banding, cli, equipment, materials, palette as palmod, repair
from tools.forja.tests.helpers import tempdir

ROOT = Path(__file__).resolve().parents[3] / "docs/art/research"
FIXTURES = ROOT / "2026-10-27-forja-fidelidade/fixtures"
MANIFEST = ROOT / "2026-10-24-forja-armas/arqueiro/manifesto.json"
ARCHER = FIXTURES / "arqueiro-before-string.png"
LIGHT = (251, 236, 195, 255)
KING_PLAN = {"schema": "forja.cores/1", "lock": ["face", "hand_back", "hand_front", "sword_hilt"],
             "regions": {"blade": {"ramp": ["#A19D9E", "#F0F0F0"], "group": False}}}


def line(out: Path, *extra) -> list[str]:
    return ["line", str(ARCHER), "--manifest", str(MANIFEST), "--observation",
            str(FIXTURES / "arqueiro-equipment-observation.json"), "--item", "bow_main", "--kind", "royal_80",
            "-o", str(out), *extra]


def core() -> list[tuple[int, int]]:
    """O miolo do ensaio: x=56, y=22..69, sem a passagem tapada pelo antebraco."""
    image = Image.open(ARCHER).convert("RGBA")
    raw = json.loads((FIXTURES / "arqueiro-equipment-observation.json").read_text(encoding="utf-8"))
    occluder = equipment.observe(image, raw, FIXTURES)["regions"]["forearm_front"]
    return [(56, y) for y in range(22, 70) if (56, y) not in occluder]


class StringCoreTest(unittest.TestCase):
    """§4: miolo e contorno separados, a cor declarada em todo o miolo e nada decidido pela maioria."""

    def test_fill_keeps_the_30_light_pixels_and_fills_the_10_breaks(self):
        d = tempdir()
        res = cli.run(line(d, "--mode", "fill", "--core-box", "56,22,57,70", "--color", "#FBECC3"))
        before, after = Image.open(ARCHER).convert("RGBA"), Image.open(res["files"]["png"]).convert("RGBA")
        self.assertEqual((len(core()), sum(before.getpixel(p) == LIGHT for p in core())), (40, 30))
        self.assertTrue(all(after.getpixel(p) == LIGHT for p in core()))
        outline = [(57, y) for y in range(16, 76)]
        self.assertEqual([after.getpixel(p) for p in outline], [before.getpixel(p) for p in outline])
        self.assertEqual(res["compose"], {"ok": True, "outside_identical": True, "protected_identical": True,
                                          "changed_pixels": 10})
        self.assertEqual((res["paint"]["source"], res["paint"]["core_pixels"]), ("declared", 40))
        self.assertEqual(res["artistic_approval"], "pending")

    def test_without_a_declared_colour_the_mixed_string_is_inconclusive(self):
        d = tempdir()
        res = cli.run(line(d))
        self.assertFalse(res["ok"])
        self.assertEqual(res["status"], "inconclusive")
        self.assertIn("--color", res["why"])
        self.assertEqual(sorted(res["colors_in_core"]), ["#000000", "#D9B836", "#FBECC3"])  # contorno, pontas, miolo
        self.assertEqual(list(d.glob("*_line.png")), [])

    def test_a_colour_off_the_palette_or_a_core_over_the_hand_is_refused(self):
        d = tempdir()
        with self.assertRaisesRegex(ValueError, "paleta"):
            cli.run(line(d, "--mode", "fill", "--core-box", "56,22,57,70", "--color", "#FF00FF"))
        with self.assertRaisesRegex(ValueError, "protegid"):
            cli.run(line(d, "--mode", "fill", "--core-box", "56,40,63,56", "--color", "#FBECC3"))

    def test_reroute_paints_every_pixel_of_the_final_line(self):
        """O defeito de 27/10: a cor so ia para `new - line`, e um pixel preto que ja era da linha ficava preto."""
        img = Image.new("RGBA", (12, 20))
        string = frozenset((5, y) for y in range(2, 18))
        for p in string:
            img.putpixel(p, (229, 211, 149, 255))
        img.putpixel((5, 9), (0, 0, 0, 255))
        cand, zone, info = repair.straighten(img, string, (5, 2), (5, 17), colors=[(229, 211, 149)])
        self.assertTrue(all(cand.getpixel(p) == (229, 211, 149, 255) for p in string))
        self.assertEqual(info["repainted"], 1)
        with self.assertRaisesRegex(ValueError, "cor"):
            repair.straighten(img, string, (5, 2), (5, 17))

    def test_the_declared_family_keeps_its_highlights(self):
        """A prova de 24/10: as cores da corda vinham no seletor; as quatro claras continuam, como antes."""
        img = Image.new("RGBA", (12, 20))
        string = frozenset((5, y) for y in range(2, 18))
        for p in string:
            img.putpixel(p, (229, 211, 149, 255))
        img.putpixel((5, 9), (242, 222, 183, 255))
        cand, _, info = repair.straighten(img, string, (5, 2), (5, 17), colors=[(229, 211, 149), (242, 222, 183)])
        self.assertEqual(cand.getpixel((5, 9)), (242, 222, 183, 255))
        self.assertEqual(info["repainted"], 0)


class MaterialTest(unittest.TestCase):
    """§5: E(P) = 0 e o ok tecnico nao bastam; um pixel preso fora da rampa deixa o material pendente."""

    def king(self):
        image = Image.open(FIXTURES / "rei-before-colors.png").convert("RGBA")
        raw = json.loads((FIXTURES / "rei-colors-observation.json").read_text(encoding="utf-8"))
        return image, materials.regions_from(raw, equipment.observe(image, raw, FIXTURES))

    def test_locked_conflicts_keep_the_material_pending_with_the_proof_valid(self):
        image, regions = self.king()
        _, info = materials.apply(image, KING_PLAN, regions, palmod.load("empire"))
        self.assertTrue(info["ok"])
        self.assertEqual((info["changed_pixels"], info["locked"]), (26, {"pixels": 826, "changed": 0}))
        self.assertEqual((info["material"]["status"], info["material"]["conflicts"]), ("pending", 9))
        self.assertEqual(info["material"]["regions"], ["blade"])

    def test_the_cores_command_says_so_and_a_clean_plan_is_resolved(self):
        d = tempdir()
        (d / "plano.json").write_text(json.dumps(KING_PLAN))
        args = ["cores", str(FIXTURES / "rei-before-colors.png"), "--observation",
                str(FIXTURES / "rei-colors-observation.json"), "-o", str(d)]
        res = cli.run([*args, "--plan", str(d / "plano.json")])
        self.assertEqual(res["material"]["status"], "pending")
        self.assertEqual(json.loads(Path(res["files"]["json"]).read_text())["material"]["conflicts"], 9)
        cape = ["#222034", "#3D4059", "#3A2C32", "#5A3A3B"]
        (d / "limpo.json").write_text(json.dumps({**KING_PLAN, "lock": ["face"], "regions": {"cape": {"ramp": cape}}}))
        self.assertEqual(cli.run([*args, "--plan", str(d / "limpo.json")])["material"]["status"], "resolved")


def picture(*rows: str) -> Image.Image:
    colours = {"A": (200, 60, 60, 255), "B": (120, 40, 40, 255), "K": (0, 0, 0, 255), ".": (0, 0, 0, 0)}
    img = Image.new("RGBA", (len(rows[0]), len(rows)))
    img.putdata([colours[c] for row in rows for c in row])
    return img


class BandingTest(unittest.TestCase):
    """A definicao do Pixel Fixer: dois segmentos de cores diferentes, 2+ px, vizinhos pelo lado comprido e com as
    pontas alinhadas. Os contra-exemplos da figura 1 do poster nao contam."""

    def test_the_four_cases_of_the_definition(self):
        cases = {"banding": ((".AAA.", ".BBB."), 1), "degenerate": (("..A..", ".BBB."), 0),
                 "short_edge": (("AABB",), 0), "unaligned": (("AAA..", ".BBB."), 0),
                 "outline": ((".KKK.", ".BBB."), 0), "vertical": (("AB", "AB"), 1)}
        for name, (rows, pairs) in cases.items():
            self.assertEqual(banding.find(picture(*rows))["pairs"], pairs, name)

    def test_it_is_a_suspicion_with_places_never_a_fix(self):
        found = banding.find(picture(".AAA.", ".BBB.", "....."))
        self.assertEqual(found["status"], "review")
        self.assertEqual(found["examples"][0], {"axis": "horizontal", "at": [1, 0], "length": 3,
                                                "colors": ["#C83C3C", "#782828"]})
        self.assertEqual(banding.find(picture("A.", ".B"))["status"], "none")


if __name__ == "__main__":
    unittest.main()
