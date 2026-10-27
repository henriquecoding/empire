"""Sinais declarados (FORJA-07; auditoria de 27/10, §16.3 e plano §4): um pixel preso com a cor e a origem, verificado
ate ao PNG final; dois pinos que disputam a mesma celula sao um conflito e nenhum ganha em silencio; uma regiao
critica com uma celula apagada fica perdida mesmo com a pureza alta; sem caixa ou sem cor, pendente.
"""
import json
import unittest

from PIL import Image

from tools.forja import cli, gridcheck, pipeline, signals
from tools.forja.equipment import image_sha
from tools.forja.tests import audit_fixtures as fx
from tools.forja.tests.helpers import tempdir

KNOWN = gridcheck.phased((fx.K * fx.N, fx.K * fx.N), fx.K, (0, 0), "fixture")
TOOTH = {"id": "dente", "role": "tooth", "color": "#FAF0D7", "source_xy": [135, 135], "status": "authorized",
         "source_annotation": "revisao-dente-01"}
LID = {"id": "palpebra", "role": "eyelid", "color": "#0A080C", "cell": [8, 8], "status": "authorized",
       "source_annotation": "revisao-palpebra-01"}


def forge(image: Image.Image, data: dict, **kw) -> dict:
    d = tempdir()
    image.save(d / "in.png")
    opts = pipeline.Options(kind="free", palette=kw.pop("palette", "none"), noise=0, cleanup="conservative",
                            outline="keep", fit="canvas" in kw, bg="#FF00FF", scale=16,
                            signals={"schema": signals.SCHEMA, **data}, **kw)
    return pipeline.forge(d / "in.png", d / "o", opts, name="in", report_html=False)


def by_id(state: dict) -> dict:
    return {p["id"]: p for p in state["pins"]} | {r["id"]: r for r in state["regions"]}


class PinTest(unittest.TestCase):
    def test_two_colors_for_one_cell_are_a_conflict_whatever_the_order(self):
        for order in ([TOOTH, LID], [LID, TOOTH]):
            got = signals.resolve(order, KNOWN)
            self.assertEqual([r["state"] for r in got], ["layout_conflict", "layout_conflict"])
            self.assertEqual(signals.apply(fx.base(), got)[1], 0)
        res = forge(fx.marked("dente"), {"pins": [TOOTH, LID]})
        state = res["signals"]
        self.assertEqual(state["status"], "blocked")
        self.assertEqual(by_id(state)["dente"]["conflicts_with"], [("palpebra", "revisao-palpebra-01")])

    def test_an_authorized_pin_survives_to_the_final_png(self):
        res = forge(fx.marked("dente"), {"pins": [TOOTH]})
        pin = by_id(res["signals"])["dente"]
        self.assertEqual((pin["state"], pin["cell"]), ("verified", [8, 8]))
        final = Image.open(res["files"]["png"]).convert("RGBA")
        self.assertEqual(final.getpixel(tuple(pin["target_pixel"])), fx.WHITE)
        self.assertEqual(res["signals"]["status"], "pass")

    def test_the_pin_holds_through_the_palette_and_says_the_conflict(self):
        res = forge(fx.marked("dente"), {"pins": [TOOTH]}, palette="empire")
        self.assertEqual(by_id(res["signals"])["dente"]["state"], "verified")
        self.assertIn("protect_conflict", [f["rule"] for f in res["lint"]["findings"]])

    def test_a_pin_the_finish_moves_out_of_the_canvas_is_lost_and_blocks(self):
        corner = {**TOOTH, "id": "canto", "source_xy": None, "cell": [0, 0]}
        res = forge(fx.marked("dente"), {"pins": [corner]}, canvas=(8, 8))
        self.assertTrue(res["finish"]["fit"]["clipped_pixels"])
        self.assertEqual(by_id(res["signals"])["canto"]["state"], "lost")
        self.assertEqual(res["signals"]["status"], "blocked")

    def test_unauthorized_colorless_or_unplaced_pins_stay_pending(self):
        pins = [{**TOOTH, "id": "a", "status": "illustrative_only_not_an_annotation_of_the_real_king"},
                {**TOOTH, "id": "b", "color": None, "required_palette_role": "face_dark"},
                {**TOOTH, "id": "c", "source_xy": None}]
        got = signals.resolve(pins, KNOWN)
        self.assertEqual([r["state"] for r in got], ["pending"] * 3)
        self.assertEqual(signals.state(got, [])["status"], "pending")
        self.assertEqual(signals.apply(fx.base(), got)[1], 0)


class RegionTest(unittest.TestCase):
    def test_an_erased_cell_in_a_required_region_blocks_without_a_global_threshold(self):
        region = {"id": "boca", "required": True, "source_box": [120, 120, 152, 152], "purpose": "dente"}
        res = forge(fx.marked("dente"), {"regions": [region]})
        self.assertNotIn("subgrid", [f["rule"] for f in res["lint"]["findings"]])
        boca = by_id(res["signals"])["boca"]
        self.assertEqual((boca["state"], boca["erased_cells"], boca["erased"][0]["color"]), ("lost", 1, "#FAF0D7"))
        self.assertEqual(res["signals"]["status"], "blocked")

    def test_a_region_in_final_coordinates_sees_the_line_that_went_transparent(self):
        res = forge(fx.line(), {"regions": [{"id": "corda", "required": True, "target_box": [8, 0, 9, 12]}]})
        self.assertEqual(by_id(res["signals"])["corda"]["erased_cells"], 12)

    def test_the_control_region_has_no_loss_and_a_boxless_one_is_pending(self):
        res = forge(fx.marked("pixel_inteiro"), {"regions": [
            {"id": "olho", "required": True, "source_box": [128, 128, 144, 144]},
            {"id": "rosto", "required": True, "source_box": None}]})
        regions = by_id(res["signals"])
        self.assertEqual((regions["olho"]["state"], regions["rosto"]["state"]), ("no_loss_detected", "pending"))
        self.assertEqual(res["signals"]["status"], "pending")

    def test_nothing_declared_is_pending_not_pass(self):
        self.assertEqual(signals.state([], [])["status"], "pending")


class FileTest(unittest.TestCase):
    def test_the_signals_belong_to_one_image(self):
        d = tempdir()
        fx.marked("dente").save(d / "in.png")
        data = {"schema": signals.SCHEMA, "image_sha256": image_sha(fx.base()), "pins": [TOOTH]}
        (d / "s.json").write_text(json.dumps(data), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "noutra imagem"):
            cli.run(["forge", str(d / "in.png"), "-o", str(d / "o"), "--scale", "16", "--signals", str(d / "s.json")])
        data["image_sha256"] = image_sha(fx.marked("dente"))
        (d / "s.json").write_text(json.dumps(data), encoding="utf-8")
        res = cli.run(["forge", str(d / "in.png"), "-o", str(d / "o"), "--scale", "16", "--signals", str(d / "s.json"),
                       "--palette", "none", "--no-fit", "--bg", "#FF00FF"])
        self.assertEqual(res["signals"]["status"], "pass")

    def test_verify_rechecks_the_pins_after_composition(self):
        d = tempdir()
        master = Image.new("RGBA", (8, 8), (40, 40, 40, 255))
        master.putpixel((3, 3), fx.WHITE)
        master.save(d / "m.png")
        edited = master.copy()
        edited.putpixel((3, 3), (40, 40, 40, 255))
        edited.save(d / "c.png")
        pin = {"id": "brilho", "color": "#FAF0D7", "target_pixel": [3, 3], "status": "authorized"}
        (d / "s.json").write_text(json.dumps({"schema": signals.SCHEMA, "pins": [pin]}), encoding="utf-8")
        same = cli.run(["verify", str(d / "m.png"), "--master", str(d / "m.png"), "--signals", str(d / "s.json")])
        lost = cli.run(["verify", str(d / "c.png"), "--master", str(d / "m.png"), "--signals", str(d / "s.json")])
        self.assertEqual(same["signals"]["status"], "pass")
        self.assertEqual(lost["signals"]["status"], "blocked")
        self.assertFalse(lost["ok"])


if __name__ == "__main__":
    unittest.main()
