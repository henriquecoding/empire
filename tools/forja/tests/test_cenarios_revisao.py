"""Cenarios (FORJA-09), a revisao do PR #131: a cena forjada fica onde a grade a pos, o fundo que cada gerador devolve,
a peca pousada pela sua ancora, os estados que faltam e o registo das referencias no pedido manual."""
import json
import unittest
from pathlib import Path

from PIL import Image, ImageDraw

from tools.forja import cli, estrutura, montagem, refs, scene, scene_plan, scene_prompt
from tools.forja.imageops import opaque_bbox
from tools.forja.tests import scene_fixtures as fx
from tools.forja.tests.helpers import tempdir

PLANE = {"openings": [], "signals": [], "signal_regions": {}, "materials": ["soil"], "states": ["done"],
         "state_changes": {}}


def resolved(**over) -> dict:
    return scene.resolve(scene.load(fx.write(tempdir(), fx.contract(**over))))


def leaning(size: int = 64) -> Image.Image:
    """Uma casa so na metade esquerda da grade pedida, com detalhe de uma celula; a porta nas celulas do contrato."""
    cells = Image.new("RGBA", (size, size))
    d = ImageDraw.Draw(cells)
    d.rectangle([5, 21, 40, size - 1], fill=fx.WALL)
    d.rectangle([3, 17, 42, 21], fill=fx.ROOF)
    d.rectangle([26, 22, 37, size - 1], fill=fx.DARK)
    return cells


class OriginTest(unittest.TestCase):
    def test_a_scene_forged_with_its_expect_stays_where_the_grid_put_it(self):
        out = tempdir()
        path = fx.write(out, fx.contract())
        req = cli.run(["cena", str(path), "-o", str(out / "pedido")])
        scale = json.loads(Path(req["files"]["expect"]).read_text(encoding="utf-8"))["scale"]
        leaning().resize((64 * scale, 64 * scale), Image.Resampling.NEAREST).save(out / "gerada.png")
        r = cli.run(["forge", str(out / "gerada.png"), "--expect", req["files"]["expect"], "-o", str(out / "f")])
        self.assertEqual((r["fit"]["mode"], r["fit"]["clipped_pixels"]), ("origin", 0))
        img = Image.open(r["files"]["png"]).convert("RGBA")
        self.assertEqual(opaque_bbox(img)[0], 4)  # 3 celulas menos o contorno acrescentado; centrada seria 22
        self.assertEqual(opaque_bbox(img)[3], 128)
        rep = estrutura.review(img, scene.resolve(scene.load(path)))
        self.assertEqual(next(c["status"] for c in rep["checks"] if c["check"] == "opening:porta"), "pass")

    def test_a_grid_other_than_the_requested_one_falls_back_to_the_anchor(self):
        out = tempdir()
        req = cli.run(["cena", str(fx.write(out, fx.contract())), "-o", str(out / "pedido")])
        coarse = leaning(32).resize((1920, 1920), Image.Resampling.NEAREST)
        coarse.save(out / "grossa.png")
        r = cli.run(["forge", str(out / "grossa.png"), "--expect", req["files"]["expect"], "-o", str(out / "f")])
        self.assertEqual(r["fit"]["mode"], "anchor")


class BackdropTest(unittest.TestCase):
    def test_only_alpha_generators_keep_transparency_and_edge_pieces_are_kept(self):
        house = resolved()
        strip = resolved(asset="terrain_strip", extent_px=[64, 32], **PLANE)
        self.assertEqual(scene_prompt.backdrop(house, "gpt-image"), "transparent")
        self.assertEqual(scene_prompt.backdrop(strip, "gpt-image"), "keep")
        key = scene_prompt.backdrop(house, "gemini")
        self.assertRegex(key, r"^#[0-9a-fA-F]{6}$")
        out = tempdir()
        g = scene_plan.make("gemini", fx.write(out, fx.contract()))
        self.assertEqual(g.data["expect"]["background"], key)
        self.assertIn(key.lower(), g.data["prompt"].lower())
        p = scene_plan.make("pixellab", fx.write(out, fx.contract(asset="terrain_strip", extent_px=[64, 32], **PLANE),
                                                  "faixa.json"))
        self.assertEqual(p.data["expect"]["background"], "keep")


class AnchorTest(unittest.TestCase):
    def test_each_asset_rests_on_its_declared_ground(self):
        strip = resolved(asset="terrain_strip", extent_px=[64, 32], **PLANE)
        far = resolved(asset="plane_far", extent_px=[256, 64], **PLANE)
        front = resolved(asset="foreground", extent_px=[128, 32], **PLANE)
        surface = strip["lattice"]["anchors"]["surface_y"]["edge"]
        s = scene.place(strip, (64, 32))
        self.assertEqual(s["asset_top_left"][1], surface)  # o labio no chao, a terra para baixo
        self.assertEqual([c[0] for c in s["copies"]], list(range(0, 1280, 64)))
        f = scene.place(far, (256, 64))
        self.assertEqual(f["asset_top_left"][1] + 64, far["lattice"]["anchors"]["horizon_y"]["edge"])
        b = scene.place(front, (128, 32))
        self.assertEqual(b["asset_top_left"][1] + 32, front["world"]["viewport"][1])
        house = scene.place(resolved(), (128, 128))
        self.assertEqual(house["copies"], [house["asset_top_left"]])
        self.assertEqual(house["asset_top_left"], [640 - 64, surface - 128])

    def test_the_bench_tiles_a_strip_under_the_feet(self):
        strip = resolved(asset="terrain_strip", extent_px=[64, 32], **PLANE)
        b = montagem.bench(fx.strip(), strip)
        top = b["placement"]["asset_top_left"][1]
        self.assertEqual(b["day"].getpixel((10, top + 9)), fx.GRASS)
        self.assertEqual(b["day"].getpixel((1270, top + 20)), fx.SOIL)
        self.assertEqual(estrutura.review(fx.strip(), strip)["placement"]["top_world_y"], top)


class StatesTest(unittest.TestCase):
    def test_a_declared_variant_without_an_image_is_not_evaluated(self):
        res = resolved(conditions=["night"])
        rep = estrutura.review(fx.house(), res)
        self.assertEqual({c["check"]: c["status"] for c in rep["checks"] if c["axis"] == "states"},
                         {"damaged": "not_evaluated", "night": "not_evaluated"})
        rep = estrutura.review(fx.house(), res, states={"damaged": fx.house()})
        self.assertEqual(rep["verdicts"]["states"], "not_evaluated")
        rep = estrutura.review(fx.house(), res, states={"damaged": fx.house(), "night": fx.house()})
        self.assertEqual(rep["verdicts"]["states"], "pass")


class ManualRefsTest(unittest.TestCase):
    def test_the_manual_request_refuses_a_rejected_reference(self):
        out = tempdir()
        fx.house().save(out / "ref.png")
        path = fx.write(out, fx.contract(references=[{"role": "asset_concept", "file": "ref.png"}]))
        ok = cli.run(["cena", str(path), "-o", str(out / "a")])
        self.assertTrue(ok["ok"], ok)
        self.assertIn(str(out / "ref.png"), ok["attach"])
        reg = refs.add(out / "registo.json", out / "ref.png", "rejected", "casa_v1", by="dono", date="2026-10-28")
        bad = cli.run(["cena", str(path), "--refs", reg["path"], "-o", str(out / "b")])
        self.assertFalse(bad["ok"])
        self.assertTrue(any("rejeitada" in e for e in bad["errors"]))
        self.assertNotIn(str(out / "ref.png"), bad["attach"])
        self.assertEqual([r["state"] for r in bad["references"]], ["rejected"])


if __name__ == "__main__":
    unittest.main()
