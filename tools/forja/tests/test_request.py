"""FORJA-03: o pedido sem contradicoes, o zero explicito e os comandos de equipamento pela CLI e pelo MCP."""
import json
import unittest
from pathlib import Path
from unittest import mock

from PIL import Image

from tools.forja import cli, mcp_server, plan, review
from tools.forja.tests import equip_fixtures as F
from tools.forja.tests.helpers import framed, tempdir


class RequestTest(unittest.TestCase):
    def reference(self) -> str:
        path = tempdir() / "ref.png"
        framed(5, (80, 80), (40, 78)).save(path)
        return str(path)

    def test_explicit_zero_strength_stays_zero(self):
        ref = self.reference()
        for given, sent in ((None, 300), (0, 0), (500, 500)):
            p = plan.make("pixellab", "comic archer", "royal_80", references=[("identity", ref)],
                          init_strength=given)
            self.assertEqual(p.data["request"]["params"]["init_image_strength"], sent, given)

    def test_camera_contradiction_blocks_the_plan_before_any_network(self):
        p = plan.make("pixellab", "comic king in three-quarter profile with a short sword", "royal_80")
        self.assertFalse(p.ok)
        self.assertIn("perfil estrito", " ".join(p.data["errors"]))
        p = plan.make("openai", "archer facing left", "royal_80", facing="right")
        self.assertIn("--facing right", " ".join(p.data["errors"]))
        self.assertTrue(plan.make("openai", "archer facing left", "royal_80", facing="left").ok)

    def test_prompt_reports_the_conflict(self):
        res = cli.run(["prompt", "rei em perfil de tres quartos", "-o", str(tempdir()), "--kind", "royal_80"])
        self.assertFalse(res["ok"])
        self.assertTrue(res["conflicts"])

    def test_automatic_review_carries_separate_verdicts(self):
        v = review.verdict(True, None)["verdicts"]
        self.assertEqual(v["raster_contract"], "pass")
        self.assertEqual(v["equipment_geometry"], "not_evaluated")
        self.assertEqual(v["artistic_approval"], "pending")


class EquipCommandTest(unittest.TestCase):
    def files(self, img, obs, manifest) -> list[str]:
        d = tempdir()
        img.save(d / "x.png")
        (d / "obs.json").write_text(json.dumps(obs))
        (d / "manifest.json").write_text(json.dumps(manifest))
        return [str(d / "x.png"), "--manifest", str(d / "manifest.json"), "--observation", str(d / "obs.json"),
                "--kind", "royal_80", "-o", str(d / "out")]

    def test_equip_fails_the_forked_blade_and_writes_the_overlay(self):
        img = F.sword("forked")
        res = cli.run(["equip", *self.files(img, F.sword_observation(img), F.sword_manifest())])
        self.assertFalse(res["ok"])
        self.assertEqual(res["summary"]["raster_contract"], "pass")
        self.assertEqual(res["blocking"], ["equipment_geometry"])
        self.assertTrue(Path(res["files"]["preview"]).exists())
        self.assertEqual(json.loads(Path(res["files"]["json"]).read_text())["summary"]["artistic_approval"], "pending")

    def test_line_repairs_a_wide_string_and_proves_the_outside(self):
        img = F.bow("wide")
        res = cli.run(["line", *self.files(img, F.bow_observation(img), F.bow_manifest()), "--item", "bow"])
        self.assertTrue(res["ok"], res)
        self.assertEqual((res["before"]["equipment_geometry"], res["after"]["equipment_geometry"]), ("fail", "pass"))
        self.assertTrue(res["compose"]["outside_identical"] and res["compose"]["protected_identical"])
        again = json.loads(Path(res["files"]["observation"]).read_text())
        self.assertIn("reaplicados", again["observer"]["method"])

    def test_line_refuses_an_item_without_a_line(self):
        img = F.sword("reference")
        with self.assertRaisesRegex(ValueError, "linha"):
            cli.run(["line", *self.files(img, F.sword_observation(img), F.sword_manifest()), "--item", "sword"])

    def test_inpaint_takes_a_mask_a_method_and_protected_boxes(self):
        d = tempdir()
        img = F.bow("valid")
        img.save(d / "bow.png")
        zone = Image.new("RGBA", img.size)
        zone.paste((255, 255, 255, 255), (52, 18, 60, 62))
        zone.save(d / "zone.png")

        def echo(_prompt, images, *_a, **_kw):
            return {"images": [images[0]], "model": "synthetic/echo", "job": {"id": "local"}}

        base = ["inpaint", str(d / "bow.png"), "--mask", str(d / "zone.png"), "--change", "thin string",
                "-o", str(d / "out.png")]
        with mock.patch("tools.forja.backends.openai_images.edit", side_effect=echo) as paid:
            res = cli.run(base + ["--method", "add"])
            with self.assertRaisesRegex(ValueError, "protegidos"):
                cli.run(base + ["--protect", "50,30,62,50"])
        self.assertEqual(paid.call_count, 1, "a mascara recusada nao chega a pedir")
        self.assertTrue(res["ok"])
        self.assertEqual((res["method"], res["editable_box"], res["changed_pixels"]), ("add", [52, 18, 60, 62], 0))

    def test_mcp_lists_the_equipment_tools(self):
        names = {t["name"] for t in mcp_server.tools()}
        self.assertTrue({"forja_equip", "forja_line"} <= names)


if __name__ == "__main__":
    unittest.main()
