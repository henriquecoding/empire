"""FORJA-04: `forja cores`, o diagnostico e o agrupamento por regiao como comando (e ferramenta MCP).

Sem plano so diagnostica e mostra os candidatos; com plano aplica rampas e agrupamento so nas regioes editaveis
e prova o resto: zero pixels presos mudados (E(P)), zero fora da zona, o alfa igual e as fronteiras entre
materiais diferentes mantidas. A aprovacao continua do autor.
"""
import contextlib
import io
import json
import unittest

from PIL import Image, ImageDraw

from tools.forja import cli, equipment, mcp_server
from tools.forja.imageops import flat
from tools.forja.tests.helpers import tempdir

BLACK, SKIN = (0, 0, 0, 255), (224, 160, 96, 255)
DARK, MID, LIGHT, NEAR = (43, 52, 33, 255), (65, 110, 78, 255), (137, 149, 67, 255), (98, 115, 49, 255)
MASTER = "#000000,#2B3421,#416E4E,#899543,#627331,#E0A060"


def figure() -> Image.Image:
    img = Image.new("RGBA", (24, 24))
    d = ImageDraw.Draw(img)
    d.rectangle((2, 2, 21, 21), fill=MID, outline=BLACK)
    d.rectangle((3, 3, 20, 9), fill=SKIN)
    d.rectangle((3, 16, 20, 20), fill=DARK)
    img.putpixel((10, 6), BLACK)
    for x, y in ((6, 12), (12, 13), (17, 11)):
        img.putpixel((x, y), LIGHT)
    img.putpixel((9, 14), NEAR)
    return img


def observation(img) -> dict:
    greens = ["#2B3421", "#416E4E", "#899543", "#627331"]
    return equipment.observation(img, {
        "cloth": {"box": [3, 10, 21, 21], "colors": greens, "material": "cloth"},
        "face": {"box": [3, 3, 21, 10], "colors": ["#E0A060"], "material": "skin"},
        "eye": {"pixels": [[10, 6]], "role": "eye"}}, {}, "teste", "caixa e cores", "2026-10-26")


def plan(**over) -> dict:
    return {"schema": "forja.cores/1", "palette": MASTER, "lock": ["face", "eye"],
            "regions": {"cloth": {"ramp": ["#2B3421", "#416E4E", "#899543"], "group": True}}, **over}


def files(d, img, obs=None, pl=None):
    img.save(d / "f.png")
    if obs is not None:
        (d / "obs.json").write_text(json.dumps(obs), encoding="utf-8")
    if pl is not None:
        (d / "plan.json").write_text(json.dumps(pl), encoding="utf-8")


class CoresTest(unittest.TestCase):
    def test_diagnosis_only_draws_the_candidates(self):
        d = tempdir()
        files(d, figure())
        res = cli.run(["cores", str(d / "f.png"), "-o", str(d / "out")])
        self.assertEqual(res["status"], "needs_review")
        self.assertEqual(res["counts"]["review"], 5)
        self.assertTrue((d / "out" / "f_cores_candidatos.png").exists())

    def test_the_eye_is_expected_with_the_observation(self):
        d = tempdir()
        img = figure()
        files(d, img, observation(img))
        res = cli.run(["cores", str(d / "f.png"), "--observation", str(d / "obs.json"), "-o", str(d / "out")])
        self.assertEqual((res["counts"]["expected"], res["counts"]["review"]), (1, 4))

    def test_plan_groups_inside_the_cloth_and_proves_the_rest(self):
        d = tempdir()
        img = figure()
        files(d, img, observation(img), plan())
        res = cli.run(["cores", str(d / "f.png"), "--observation", str(d / "obs.json"), "--plan",
                       str(d / "plan.json"), "-o", str(d / "out")])
        self.assertTrue(res["ok"], res)
        self.assertEqual((res["locked"]["changed"], res["outside_zone_changed"]), (0, 0))
        self.assertTrue(res["alpha_identical"])
        out = Image.open(res["files"]["png"]).convert("RGBA")
        for x, y in ((6, 12), (12, 13), (17, 11), (9, 14)):
            self.assertEqual(out.getpixel((x, y)), MID, (x, y))
        self.assertEqual(out.getpixel((10, 6)), BLACK)
        self.assertEqual([p[3] for p in flat(out)], [p[3] for p in flat(img)])
        cloth = res["metrics"]["cloth"]
        self.assertGreater(cloth["singletons8"][0], cloth["singletons8"][1])
        for name in ("compare", "regions", "candidates_before", "candidates_after", "json"):
            self.assertTrue(res["files"][name])

    def test_ramp_outside_the_master_palette_is_refused(self):
        d = tempdir()
        img = figure()
        files(d, img, observation(img), plan(regions={"cloth": {"ramp": ["#123456"], "group": True}}))
        with contextlib.redirect_stdout(io.StringIO()) as said:
            code = cli.main(["cores", str(d / "f.png"), "--observation", str(d / "obs.json"), "--plan",
                             str(d / "plan.json"), "-o", str(d / "out")])
        self.assertEqual(code, 2)
        self.assertIn("#123456", said.getvalue())

    def test_mcp_lists_the_colour_tool(self):
        self.assertIn("forja_cores", {t["name"] for t in mcp_server.tools()})


if __name__ == "__main__":
    unittest.main()
