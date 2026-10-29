"""Auditoria de fidelidade de 29/10 (FORJA-15), P0-01, P1-01 e P1-02, como regressao com as imagens reais e mutadas.

- T07 a fonte arquivada da mercenaria: os quatro dentes apagados com pureza 0,970 ficam na cadeia, com os votos;
- T08 reexportar a base nativa depois da perda: zero perdas nesta etapa nao encerra a ocorrencia; um reparo provado
  nesta imagem libera so a sua;
- T09 a ampliacao inteira de um mestre volta igual (RGBA, posicao e sinais da ficha facial);
- T11 a edicao na mascara deixa o exterior e o pivo identicos e entra na cadeia;
- T12 o raster valido com a identidade pendente e um estudo; um hash rejeitado bloqueia;
- T13 o relatorio do lote tem os 15 do elenco, com os estados separados, sem omitir os que nao mudaram.
"""
import json
import shutil
import unittest

from PIL import Image

from tools.forja import cli, face, lineage, pipeline, pixel_patch, review_state
from tools.forja.equipment import image_sha
from tools.forja.imageops import opaque_bbox, upscale
from tools.forja.tests import fidelity_fixtures as ff
from tools.forja.tests.helpers import tempdir

SOURCE = ff.EVIDENCE / "casos/mercenary-source.png"
TEETH = [[38, 23], [39, 23], [38, 24], [39, 24]]
REGION = {"schema": "forja.signals/1", "pins": [],
          "regions": [{"id": "dentes", "required": True, "purpose": "dentes", "source_box": [745, 451, 784, 490]}]}
CH = {"id": "mercenary", "pose": "idle", "pixel_pins": [], "critical_regions": [], "face_sheet": None}


def forge(src, out, name, **kw) -> dict:
    opts = pipeline.Options(palette="none", noise=0, outline="keep", bg="keep", fit=False, **kw)
    return pipeline.forge(src, out, opts, name=name, report_html=False)


class InheritedLossTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.d = tempdir()
        cls.first = forge(SOURCE, cls.d / "a", "merc", signals=REGION)
        cls.second = forge(cls.d / "a/merc.png", cls.d / "b", "merc2", lineage=cls.first["lineage"])

    def test_t07_the_teeth_are_lost_with_high_purity_and_carried_with_their_votes(self):
        snap = self.first["snap"]
        self.assertEqual(snap["sample"]["purity"], 0.97)
        teeth = [o for o in self.first["lineage"]["occurrences"] if o["cell"] in TEETH]
        self.assertEqual(len(teeth), 4)
        self.assertTrue(all(o["critical"] and o["regions"] == ["dentes"] for o in teeth))
        for o in teeth:  # o voto nao mudou: a minoria clara nao virou dente sozinha; a evidencia mostra as duas
            self.assertLess(int(o["kept"][1:3], 16), 16)
            self.assertTrue(any(int(v["color"][1:3], 16) > 200 and v["cell_share"] > 0.2 for v in o["votes"]))
            self.assertIsNotNone(o["margin"])
            self.assertIsNotNone(o["grid_confidence"])
        self.assertEqual(self.first["delivery"]["release_ready"], False)

    def test_t08_reexporting_the_native_base_does_not_close_the_loss(self):
        second = self.second
        self.assertEqual(second["snap"]["loss"]["erased_cells"], 0)
        self.assertEqual(second["lineage"]["stages"][-1]["carried"], 5)
        self.assertIn("inherited_loss", [f["rule"] for f in second["lint"]["findings"]])
        final = Image.open(second["files"]["png"]).convert("RGBA")
        rev = review_state.review(CH, final, None, second["lint"], second)
        self.assertEqual(rev["release"]["status"], "blocked")
        self.assertEqual(len(rev["release"]["open_critical"]), 4)
        self.assertIn("inherited_losses", rev["blocked"])
        lone = forge(self.d / "a/merc.png", self.d / "c", "merc3")
        self.assertEqual(lone["lineage"]["root"]["kind"], "native_input")
        alone = review_state.review(CH, final, None, lone["lint"], lone)
        self.assertIn("base ja nativa", " ".join(alone["release"]["reasons"]))

    def test_t08_a_proven_repair_releases_only_its_occurrence(self):
        final = Image.open(self.second["files"]["png"]).convert("RGBA")
        teeth = [o for o in self.second["lineage"]["occurrences"] if o["cell"] in TEETH]
        patch = {"schema": pixel_patch.SCHEMA, "author": "teste", "date": "2026-10-29", "reason": "um dente",
                 "base": {"pixels_sha256": image_sha(final), "canvas": list(final.size)},
                 "mask": [[*teeth[0]["target_pixel"], teeth[0]["target_pixel"][0] + 1, teeth[0]["target_pixel"][1] + 1]],
                 "operations": [{"op": "paint", "pixels": [[*teeth[0]["target_pixel"], "#FFFFFF"]]}]}
        fixed, report = pixel_patch.apply(final, patch)
        lin = lineage.patch(self.second["lineage"], report, patch["mask"])
        self.assertEqual(lin["occurrences"][[o["id"] for o in lin["occurrences"]].index(teeth[0]["id"])]["touched_by"],
                         [3])
        res = [{"occurrence": teeth[0]["id"], "status": "repaired", "by": "teste", "date": "2026-10-29",
                "evidence": "dente branco de volta", "pixels_sha256": image_sha(fixed),
                "pixels": [[*teeth[0]["target_pixel"], "#FFFFFF"]]},
               {"occurrence": teeth[1]["id"], "status": "repaired", "by": "teste", "date": "2026-10-29",
                "evidence": "afirmado, sem pixel", "pixels_sha256": image_sha(fixed), "pixels": [[0, 0, "#FFFFFF"]]}]
        close = lineage.closure(lin, fixed, {}, res)
        self.assertEqual([o["id"] for o in close["resolved"]], [teeth[0]["id"]])
        self.assertEqual(len(close["open_critical"]), 3)
        self.assertTrue(close["open_critical"][0]["proof_refused"])
        self.assertEqual(lineage.closure(lin, final, {}, res)["status"], "blocked")  # outra imagem: nada prova

    def test_a_chain_that_does_not_link_is_refused(self):
        with self.assertRaisesRegex(ValueError, "a cadeia nao liga"):
            forge(SOURCE, self.d / "x", "x", lineage=self.first["lineage"])


class ExactAndLocalTest(unittest.TestCase):
    def test_t09_an_integer_upscale_of_a_master_comes_back_exact(self):
        d = tempdir()
        master = ff.face_image()
        upscale(master, 6).save(d / "big.png")
        res = forge(d / "big.png", d / "o", "big")
        with Image.open(res["files"]["png"]) as out:
            back = out.convert("RGBA")
        self.assertEqual(back.tobytes(), master.tobytes())
        self.assertEqual(res["snap"]["crop_origin"], [0, 0])
        self.assertEqual(res["snap"]["loss"]["erased_cells"], 0)
        self.assertEqual(face.check(ff.sheet(), back)["status"], "pass")

    def test_t11_a_local_edit_keeps_the_outside_and_the_pivot(self):
        base = ff.face_image(mouth="neutral")
        mask = [[5, 15, 14, 19]]
        rows = ["........." for _ in range(4)]
        crooked = ff.face_image()
        patch = {"schema": pixel_patch.SCHEMA, "author": "teste", "date": "2026-10-29", "reason": "sorriso torto",
                 "base": {"pixels_sha256": image_sha(base), "canvas": [24, 24]}, "mask": mask, "allow_new_colors": True,
                 "operations": [{"op": "region", "box": mask[0], "rows": rows, "legend": {".": "keep"}},
                                {"op": "paint", "pixels": [[x, y, "#%02X%02X%02X" % crooked.getpixel((x, y))[:3]]
                                                           for y in range(15, 19) for x in range(5, 14)]}]}
        fixed, report = pixel_patch.apply(base, patch)
        outside = [(x, y) for y in range(24) for x in range(24) if not (5 <= x < 14 and 15 <= y < 19)]
        self.assertTrue(all(fixed.getpixel(p) == base.getpixel(p) for p in outside))
        self.assertEqual(opaque_bbox(fixed), opaque_bbox(base))
        self.assertEqual(face.check(ff.sheet(), fixed)["status"], "pass")
        lin = lineage.patch(ff.chain(base), report, mask)
        self.assertEqual(lin["stages"][-1]["edited"], mask)
        self.assertEqual(lin["output_sha256"], image_sha(fixed))


class SubcellStrokeTest(unittest.TestCase):
    def test_a_stroke_thinner_than_the_cell_asks_for_a_native_redraw_not_a_forced_vote(self):
        from tools.forja.tests import audit_fixtures as fx
        d = tempdir()
        fx.marked("borda").save(d / "in.png")
        region = {"schema": "forja.signals/1", "pins": [],
                  "regions": [{"id": "palpebra", "required": True, "source_box": [128, 128, 144, 144]}]}
        res = forge(d / "in.png", d / "o", "in", scale=16, signals=region)
        self.assertIn("redraw_region", [f["rule"] for f in res["lint"]["findings"]])
        cand = Image.open(res["files"]["png"]).convert("RGBA")
        close = review_state.review(CH, cand, None, res["lint"], res)["release"]
        self.assertEqual(close["status"], "blocked")
        self.assertIn("redesenho nativo", close["open_critical"][0]["next_step"])
        self.assertEqual(res["snap"]["native_size"], [16, 16])  # nada reduzido para caber


class ClosureTest(unittest.TestCase):
    def test_t12_a_valid_raster_with_pending_identity_is_a_study(self):
        d = tempdir()
        upscale(ff.face_image(), 6).save(d / "big.png")
        res = forge(d / "big.png", d / "o", "big")
        self.assertEqual({k: res["delivery"][k] for k in ("raster_valid", "release_ready", "label")},
                         {"raster_valid": True, "release_ready": False, "label": "study"})
        self.assertNotIn("usable_sprite", res["delivery"])
        cand = Image.open(res["files"]["png"]).convert("RGBA")
        ch = {**CH, "face_sheet": ff.sheet()}
        rev = review_state.review(ch, cand, None, res["lint"], res)
        self.assertEqual((rev["label"], rev["deliverable"], rev["raster_valid"]), ("study", False, True))
        bad = {**ch, "rejected_candidates": [{"pixels_sha256": image_sha(cand), "decided_by": "Henrique",
                                              "date": "2026-10-29", "reasons": ["rosto generico"]}]}
        self.assertEqual(review_state.review(bad, cand, None, res["lint"], res)["label"], "blocked")

    def test_t13_the_batch_report_lists_the_whole_cast(self):
        d, old = tempdir(), tempdir()
        for who in ("alchemist_emperor", "alchemist_squire"):
            shutil.copy(ff.EVIDENCE / "casos" / who / "final.png", d / f"{who}.png")
        shutil.copy(d / "alchemist_emperor.png", old / "alchemist_emperor.png")
        Image.new("RGBA", (64, 64)).save(old / "alchemist_squire.png")
        rep = cli.run(["lote", str(d), "--previous", str(old), "-o", str(d / "lote.json")])
        self.assertEqual(rep["count"], 15)
        self.assertEqual(rep["labels"]["no_candidate"], 13)
        rows = {r["character"]: r for r in rep["entries"]}
        self.assertEqual(rows["alchemist_emperor"]["unchanged_from_previous"], True)
        self.assertEqual(rows["alchemist_squire"]["unchanged_from_previous"], False)
        self.assertEqual(set(rows["alchemist_emperor"]["summary"]), set(review_state.STATES))
        self.assertEqual(rows["alchemist_emperor"]["release"], "pending")
        self.assertEqual(rep["deliverable"], 0)
        self.assertEqual(json.loads((d / "lote.json").read_text(encoding="utf-8"))["count"], 15)


if __name__ == "__main__":
    unittest.main()
