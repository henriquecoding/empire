"""Cenarios (FORJA-12): os contraexemplos da auditoria de 28/10 (A1-A7) e o que ela pediu a volta deles — a largura
do vao, o apoio ligado a estrutura, a emenda pela cor, o estado que muda, a referencia que chega ao gerador, os estados
vazios, a altura com o limite exclusivo, o mestre pelo registo e o perfil de medidas dito como proposta."""
import json
import unittest

from PIL import Image, ImageDraw

from tools.forja import cli, estrutura, refs, regua, scene, scene_plan
from tools.forja.backends import gemini_images
from tools.forja.equipment import image_sha
from tools.forja.tests import scene_fixtures as fx
from tools.forja.tests.helpers import tempdir


def resolved(**over) -> dict:
    return scene.resolve(scene.load(fx.write(tempdir(), fx.contract(**over))))


def found(rep: dict, name: str) -> dict:
    return next(c for c in rep["checks"] if c["check"] == name)


class OpeningTest(unittest.TestCase):
    def test_a1_a_door_two_pixels_wide_is_refused_by_the_contract_and_the_review(self):
        narrow = [{"id": "porta", "kind": "door", "box_px": [62, 44, 64, 128]}]
        errors = scene.validate(fx.contract(openings=narrow), tempdir())["errors"]
        self.assertTrue(any("largura" in e for e in errors), errors)
        slit = fx.house(door=[62, 44, 64, 128])  # o contrato diz 32 px; a imagem so abriu uma fenda
        c = found(estrutura.review(slit, resolved()), "opening:porta")
        self.assertEqual(c["status"], "fail")
        self.assertIn("largura", c["detail"])
        self.assertEqual(c["evidence"]["clear_width"], 2)
        ok = found(estrutura.review(fx.house(), resolved()), "opening:porta")
        self.assertEqual((ok["status"], ok["evidence"]["clear_width"]), ("pass", 32))

    def test_a7_the_clear_height_counts_rows_and_the_minimum_is_exact(self):
        self.assertEqual(found(estrutura.review(fx.house(), resolved()), "opening:porta")["evidence"]["clear_height"],
                         84)
        need = regua.metric(regua.metrics(regua.ruler()), "door_clear_height")["px"][0]
        for rows, status in ((need, "pass"), (need - 2, "fail")):
            door = [48, 128 - rows, 80, 128]
            c = found(estrutura.review(fx.house(door=door), resolved(openings=[
                {"id": "porta", "kind": "door", "box_px": [48, 44, 80, 128]}])), "opening:porta")
            self.assertEqual((c["status"], c["evidence"]["clear_height"]), (status, rows))


class SupportTest(unittest.TestCase):
    def test_a2_a_loose_block_on_the_ground_does_not_hold_a_floating_house(self):
        hung = fx.house(lift=8)
        ImageDraw.Draw(hung).rectangle([20, 126, 21, 127], fill=fx.WALL)
        c = found(estrutura.review(hung, resolved()), "base_contact")
        self.assertEqual(c["status"], "fail")
        self.assertEqual((c["evidence"]["float_px"], c["evidence"]["loose_ground_fragments"]), (8, 1))

    def test_posts_joined_to_the_body_hold_it_up(self):
        stilts = fx.house(lift=8)
        d = ImageDraw.Draw(stilts)
        for x in (10, 114):
            d.rectangle([x, 100, x + 3, 127], fill=fx.WALL)
        c = found(estrutura.review(stilts, resolved()), "base_contact")
        self.assertEqual(c["status"], "pass", c["detail"])
        self.assertEqual(c["evidence"]["contact_columns"], 8)


class SeamTest(unittest.TestCase):
    def test_a3_two_opaque_strips_of_different_colour_do_not_join(self):
        light = Image.new("RGBA", (64, 32), (220, 220, 220, 255))
        dark = Image.new("RGBA", (64, 32), (20, 20, 20, 255))
        j = estrutura.joint(light, dark)
        self.assertFalse(j["ok"])
        self.assertEqual(j["criteria"], {"alpha": True, "colour": False})
        self.assertTrue(estrutura.joint(fx.strip(), fx.strip())["ok"])
        self.assertTrue(estrutura.joint(light, light)["ok"])


class StateTest(unittest.TestCase):
    def test_a4_a_state_identical_to_the_base_does_not_pass(self):
        rep = estrutura.review(fx.house(), resolved(), states={"damaged": fx.house()})
        self.assertEqual(found(rep, "damaged")["status"], "pass")  # nada mudou fora das zonas
        self.assertEqual(found(rep, "damaged:change")["status"], "fail")
        self.assertEqual(rep["verdicts"]["states"], "fail")
        broken = fx.house()
        ImageDraw.Draw(broken).rectangle([10, 10, 30, 20], fill=(0, 0, 0, 0))
        rep = estrutura.review(fx.house(), resolved(), states={"damaged": broken})
        self.assertEqual(found(rep, "damaged:change")["status"], "inconclusive")  # mudou; o significado ve-se a olho
        self.assertEqual(rep["verdicts"]["states"], "inconclusive")

    def test_a6_an_empty_state_list_is_refused_before_the_review(self):
        errors = scene.validate(fx.contract(states=[], state_changes={}), tempdir())["errors"]
        self.assertTrue(any("states" in e for e in errors), errors)
        with self.assertRaises(ValueError):
            resolved(states=[], state_changes={})

    def test_a_state_without_zones_is_warned(self):
        warns = scene.validate(fx.contract(states=["done", "damaged", "ruin"]), tempdir())["warnings"]
        self.assertTrue(any("ruin" in w and "zona" in w for w in warns), warns)


class TransportTest(unittest.TestCase):
    def setUp(self):
        self.dir = tempdir()

    def plan(self, backend: str, role: str, size: tuple[int, int], model: str | None = None):
        fx.house().resize(size, Image.Resampling.NEAREST).save(self.dir / f"{role}.png")
        path = fx.write(self.dir, fx.contract(references=[{"role": role, "file": f"{role}.png"}]), f"{role}.json")
        return scene_plan.make(backend, path, model=model)

    def test_a5_a_reference_the_model_cannot_receive_is_refused(self):
        p = self.plan("pixellab", "composition", (64, 64))
        self.assertFalse(p.ok)
        self.assertTrue(any("composition" in e and "nao chega" in e for e in p.data["errors"]), p.data["errors"])
        self.assertEqual(p.data["references"][0]["sent"], None)

    def test_the_concept_goes_as_init_image_only_at_the_request_size(self):
        p = self.plan("pixellab", "asset_concept", (64, 64))
        self.assertTrue(p.ok, p.data["errors"])
        self.assertIn("init_image", [a["prompt_role"] for a in p.data["attachments"]])
        self.assertEqual(p.data["references"][0]["sent"], "init_image")
        big = self.plan("pixellab", "asset_concept", (128, 128))
        self.assertFalse(big.ok)
        self.assertTrue(any("init_image" in e for e in big.data["errors"]))
        style = self.plan("pixellab", "style_master", (64, 64), model="bitforge")
        self.assertEqual(style.data["references"][0]["sent"], "style_image")
        self.assertFalse(self.plan("pixellab", "style_master", (64, 64)).ok)  # o pixflux nao tem style_image

    def test_registered_and_sent_are_separate_fields(self):
        p = self.plan("openai", "composition", (64, 64))
        self.assertTrue(p.ok, p.data["errors"])
        ref = p.data["references"][0]
        self.assertEqual((ref["state"], ref["sent"]), (refs.UNRECORDED, "composition"))


class AuthorityTest(unittest.TestCase):
    def test_equal_to_a_master_passes_only_when_the_register_approves_it(self):
        out = tempdir()
        fx.house().save(out / "mestre.png")
        path = fx.write(out, fx.contract())
        fx.house().save(out / "casa.png")
        loose = cli.run(["estrutura", str(out / "casa.png"), "--scene", str(path), "--master", str(out / "mestre.png")])
        self.assertEqual(found(loose, "chimney_join")["status"], "inconclusive")
        row = {"id": "casa_mestre", "file": "mestre.png", "pixels_sha256": image_sha(fx.house()), "state": "approved",
               "decided_by": "dono", "date": "2026-10-28"}  # approved escreve-o o dono, a mao
        (out / "registo.json").write_text(json.dumps({"schema": refs.SCHEMA, "entries": [row]}), encoding="utf-8")
        ok = cli.run(["estrutura", str(out / "casa.png"), "--scene", str(path), "--master", str(out / "mestre.png"),
                      "--refs", str(out / "registo.json")])
        self.assertEqual(found(ok, "chimney_join")["status"], "pass")
        self.assertEqual(found(ok, "chimney_join")["evidence"]["master_state"], "approved")


class GeminiPixelsTest(unittest.TestCase):
    def test_the_published_table_replaces_the_area_estimate(self):
        self.assertEqual(gemini_images.estimate("8:1", "1K", "gemini-3.1-flash-image"), (3072, 384))
        self.assertEqual(gemini_images.estimate("21:9", "2K", "gemini-nano-banana-2.1"), (3168, 1344))
        self.assertEqual(gemini_images.estimate("16:9", "1K", "gemini-2.5-flash-image"), (1344, 768))
        self.assertIsNone(gemini_images.published("gemini-3.1-flash-lite-image", "1:1", "1K"))
        self.assertIn("image-generation.md.txt", gemini_images.capabilities("gemini-3.1-flash-image")["pixel_table"])
        p = scene_plan.make("gemini", fx.write(tempdir(), fx.contract(extent_px=[512, 128])))
        self.assertTrue(p.data["request"]["output_size_known"])
        self.assertIn(tuple(p.data["request"]["estimated_output"]),
                      [tuple(v) for t in gemini_images.PIXELS["tables"].values() for row in t.values()
                       for v in row.values()])


class ProfileTest(unittest.TestCase):
    def test_the_measures_say_they_are_a_proposal(self):
        for m in regua.metrics(regua.ruler()):
            self.assertEqual((m["status"], m["decision"]), ("proposal", "Q-295"), m["id"])
        rep = estrutura.review(fx.house(), resolved())
        self.assertEqual(found(rep, "opening:porta")["evidence"]["rule_status"], "proposal")
        self.assertEqual(rep["profile"]["status"], "proposal")


if __name__ == "__main__":
    unittest.main()
