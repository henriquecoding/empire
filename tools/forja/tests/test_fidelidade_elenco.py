"""Auditoria de fidelidade de 29/10 (FORJA-15), P0-02 e P0-03, como regressao: os testes mudam a imagem ou a
evidencia e conferem que o resultado muda — nao so que o JSON diz o que se quer.

- T01 o bojo afinado e o gargalo alongado no mesmo envelope 13x20 divergem do molde;
- T02 a restricao partilhada tem consumidor: medida que nao cabe, par inexistente, dado invalido;
- T03 o verde trocado por ambar no mesmo molde (e o espelho declarado) passa;
- T04 a mao a flutuar falha o contacto; a mao sobre o vidro fica inconclusiva onde nao ha prova;
- T05/T06 a pupila mudada de lado e o sorriso torto trocado por uma linha nao ficam "preservados";
- T10 os pinos tirados do candidato protegem-no, mas nao preenchem a fidelidade ao conceito.
"""
import copy
import json
import unittest
from pathlib import Path

from tools.forja import cast, equipment, face, fidelity, geometry, production, prop_shape, props, review_state
from tools.forja.equipment import image_sha
from tools.forja.tests import fidelity_fixtures as ff

CONTRACTS = Path(__file__).resolve().parents[3] / "docs/art/concepts/2026-10-29-elenco/contracts"


def flask_check(drawn=ff.FLASK, mirror=False, hand=None, **kw) -> dict:
    img, regions = ff.scene(drawn, hand, mirror)
    man = ff.manifest(**kw)
    obs = ff.observe(img, regions)
    return {c["check"]: c for c in geometry.evaluate(man, obs) if c["check"] in ("prop_shape", "contact")}


class ObjectShapeTest(unittest.TestCase):
    def test_t01_a_thinner_body_and_longer_neck_in_the_same_envelope_diverge(self):
        img, regions = ff.scene(ff.THIN)
        self.assertEqual(prop_shape.measure(equipment.items(ff.manifest())[0], ff.observe(img, regions))["envelope"],
                         [13, 20])
        got = flask_check(ff.THIN)["prop_shape"]
        self.assertEqual(got["status"], "fail")
        self.assertIn("silhueta diverge", got["detail"])
        self.assertIn("neck", got["detail"])
        self.assertEqual(flask_check()["prop_shape"]["status"], "pass")

    def test_t03_the_liquid_color_and_a_declared_mirror_do_not_fail(self):
        amber, regions = ff.scene(glass=ff.LIQUID)
        man = ff.manifest()
        self.assertEqual(geometry.evaluate(man, ff.observe(amber, regions))[-2]["status"], "pass")
        spout = {"rows": ff.SPOUT}
        self.assertEqual(flask_check(ff.SPOUT, mirror=True, allowed=("orientation",), **spout)["prop_shape"]["status"],
                         "pass")
        self.assertEqual(flask_check(ff.SPOUT, mirror=True, **spout)["prop_shape"]["status"], "fail")  # nao declarado

    def test_a_proposed_model_never_gives_pass(self):
        self.assertEqual(flask_check(status="proposed")["prop_shape"]["status"], "inconclusive")

    def test_t04_a_floating_hand_fails_and_a_covering_hand_is_inconclusive(self):
        floating = {(x, y) for x in range(36, 39) for y in range(22, 26)}
        self.assertEqual(flask_check(hand=floating)["contact"]["status"], "fail")
        grip = {(x, y) for x in range(29, 34) for y in range(21, 26)}
        held = flask_check(hand=grip, occluded=True)
        self.assertEqual(held["contact"]["status"], "pass")
        self.assertEqual(held["prop_shape"]["status"], "pass")
        self.assertTrue(held["prop_shape"]["evidence"]["occluded_rows"])
        covered = {(x, y) for x in range(18, 36) for y in range(17, 30)}
        self.assertEqual(flask_check(hand=covered, occluded=True)["prop_shape"]["status"], "inconclusive")

    def test_without_observation_the_object_is_not_evaluated(self):
        man = ff.manifest()
        obs = {"regions": {}, "uncertain": set(), "anchors": {}}
        self.assertEqual(geometry.evaluate(man, obs)[-2]["status"], "not_evaluated")


class SharedConstraintTest(unittest.TestCase):
    def contract(self, name: str) -> dict:
        return json.loads((CONTRACTS / f"{name}.json").read_text(encoding="utf-8"))

    def test_t02_the_99x3_mutation_of_the_audit_is_now_refused(self):
        data = self.contract("alchemist_squire")
        ch = data["characters"][0]
        self.assertEqual(production.validate(ch), [])
        bad = copy.deepcopy(data)
        bad["characters"][0]["shared_prop_constraints"][0]["native_shared_dimensions"] = [99, 3]
        self.assertIn("nao cabe na tela 64x64", " ".join(fidelity.validate(bad, CONTRACTS)))
        for wrong in ("13x20", [13], [0, 20]):
            mutated = copy.deepcopy(ch)
            mutated["shared_prop_constraints"][0]["native_shared_dimensions"] = wrong
            self.assertTrue(production.validate(mutated), wrong)
        mutated = copy.deepcopy(ch)
        mutated["shared_prop_constraints"][0].update(scale_with_character_canvas=True, scale="by_canvas")
        self.assertEqual(len(production.validate(mutated)), 2)

    def test_t02_the_pair_must_exist_and_declare_the_same_rule(self):
        emperor = self.contract("alchemist_emperor")["characters"][0]
        squire = self.contract("alchemist_squire")["characters"][0]
        self.assertEqual(props.pairs({"alchemist_emperor": emperor, "alchemist_squire": squire}), [])
        self.assertIn("fora do elenco", " ".join(props.pairs({"alchemist_squire": squire})))
        other = copy.deepcopy(emperor)
        other["shared_prop_constraints"][0]["native_shared_dimensions"] = [13, 20]
        self.assertIn("divergem", " ".join(props.pairs({"alchemist_emperor": other, "alchemist_squire": squire})))
        self.assertEqual(len(cast.load()["characters"]), 15)

    def test_the_v3_flasks_share_the_envelope_and_that_does_not_prove_the_mold(self):
        sides = []
        for who in ("alchemist_emperor", "alchemist_squire"):
            mask = json.loads((ff.EVIDENCE / "casos" / who / "flask-mask.json").read_text(encoding="utf-8"))
            item = equipment.items({"items": [{"id": "alchemy_standard_flask", "family": "flask", "slot": "weapon",
                                               "state": "held"}]})[0]
            obs = {"regions": {"alchemy_standard_flask.body": frozenset(map(tuple, mask["pixels"]))}}
            sides.append({"character": who, "measure": prop_shape.measure(item, obs), "shape": None})
        rule = self.contract("alchemist_squire")["characters"][0]["shared_prop_constraints"][0]
        res = props.pair(rule, *sides)
        self.assertEqual(res["envelopes"], {"alchemist_emperor": [13, 20], "alchemist_squire": [13, 20]})
        self.assertEqual(res["status"], "pending")
        self.assertIn("nao prova o mesmo molde", json.dumps(res, ensure_ascii=False))


class PairCommandTest(unittest.TestCase):
    def side(self, d: Path, who: str, drawn, hand) -> list[str]:
        img, regions = ff.scene(drawn, hand)
        img.save(d / f"{who}.png")
        man = ff.manifest()
        man["items"][0]["id"] = "alchemy_standard_flask"
        (d / f"{who}-man.json").write_text(json.dumps(man), encoding="utf-8")
        obs = equipment.observation(img, {(n if n == "hand_right" else f"alchemy_standard_flask.{n}"):
                                          {"pixels": sorted(map(list, c))} for n, c in regions.items()}, {},
                                    "teste", "fixture", "2026-10-29")
        (d / f"{who}-obs.json").write_text(json.dumps(obs), encoding="utf-8")
        return ["--side", who, str(d / f"{who}.png"), str(d / f"{who}-man.json"), str(d / f"{who}-obs.json")]

    def test_the_pair_measures_both_flasks_against_the_mold_and_the_grip(self):
        from tools.forja import cli
        from tools.forja.tests.helpers import tempdir
        d = tempdir()
        grip = {(x, y) for x in range(33, 36) for y in range(21, 25)}
        base = ["par", "--constraint", "alchemy_standard_flask"]
        same = cli.run(base + self.side(d, "alchemist_emperor", ff.FLASK, grip) +
                       self.side(d, "alchemist_squire", ff.FLASK, grip))
        self.assertEqual(same["status"], "pending")  # o molde bate; a medida nativa continua por fechar no mestre
        self.assertEqual([c["status"] for c in same["contacts"]], ["pass", "pass"])
        thin = cli.run(base + self.side(d, "alchemist_emperor", ff.FLASK, grip) +
                       self.side(d, "alchemist_squire", ff.THIN, grip))
        self.assertEqual(thin["status"], "blocked")
        self.assertFalse(thin["ok"])
        loose = {(x, y) for x in range(37, 40) for y in range(21, 25)}
        floating = cli.run(base + self.side(d, "alchemist_emperor", ff.FLASK, grip) +
                           self.side(d, "alchemist_squire", ff.FLASK, loose))
        self.assertEqual(floating["status"], "blocked")


class FaceSheetTest(unittest.TestCase):
    def review(self, image, sheet=None, pins=()) -> dict:
        ch = {"id": "x", "pose": "p", "face_sheet": sheet, "pixel_pins": list(pins), "critical_regions": []}
        return review_state.review(ch, image, None, {"ok": True, "findings": []})

    def test_the_drawn_expression_passes_its_sheet(self):
        got = face.check(ff.sheet(), ff.face_image())
        self.assertEqual(got["status"], "pass", got)
        self.assertEqual(face.validate(ff.sheet(), [24, 24]), [])

    def test_t05_a_moved_pupil_flags_the_acting(self):
        got = face.check(ff.sheet(), ff.face_image(pupil="right"))
        self.assertEqual(got["status"], "blocked")
        self.assertIn("gaze", got["blocked"][0])
        self.assertEqual(self.review(ff.face_image(pupil="right"), ff.sheet())["summary"][
            "declared_feature_preservation"], "blocked")

    def test_t06_a_neutral_line_is_not_the_crooked_smile(self):
        rev = self.review(ff.face_image(mouth="neutral"), ff.sheet())
        self.assertNotEqual(rev["summary"]["declared_feature_preservation"], "pass")
        self.assertIn("smile", " ".join(rev["states"]["declared_feature_preservation"]["evidence"]))

    def test_t10_candidate_pins_protect_but_do_not_fill_fidelity(self):
        simple = ff.face_image(mouth="neutral")
        px = simple.load()
        pins = [{"id": f"p{x}", "target_pixel": [x, 18], "color": "#962832", "status": "authorized",
                 "source_annotation": "tirado do candidato"} for x in range(6, 13)]
        rev = self.review(simple, None, pins)
        kept = rev["states"]["declared_feature_preservation"]
        self.assertEqual(kept["candidate_protection"]["status"], "pass")
        self.assertEqual(kept["status"], "pending")
        self.assertTrue(all(px[x, 18][:3] == (150, 40, 50) for x in range(6, 13)))
        self.assertEqual(self.review(simple, ff.sheet(), pins)["summary"]["declared_feature_preservation"], "blocked")

    def test_an_authority_pin_needs_a_point_in_the_concept(self):
        data = json.loads((CONTRACTS / "mercenary.json").read_text(encoding="utf-8"))
        data["characters"][0]["pixel_pins"] = [{"id": "dente", "color": "#FFFFFF", "target_pixel": [30, 20],
                                                "status": "authorized", "source_kind": "authority"}]
        self.assertIn("authority_xy", " ".join(fidelity.validate(data, CONTRACTS)))
        self.assertEqual(image_sha(ff.face_image()), image_sha(ff.face_image()))

    def test_a_bad_sheet_is_refused_by_the_contract(self):
        sheet = ff.sheet()
        sheet["relations"].append({"id": "x", "type": "asymmetry", "a": "nope", "expect": "sideways"})
        sheet["landmarks"][0]["feature"] = "ear"
        self.assertEqual(len(face.validate(sheet, [24, 24])), 2)


if __name__ == "__main__":
    unittest.main()
