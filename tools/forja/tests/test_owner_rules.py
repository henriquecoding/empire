"""FORJA-16: regras consultadas e verificadas antes de apresentar uma entrega."""
import copy
import json
import unittest
from pathlib import Path

from PIL import Image

from tools.forja import cli, delivery_review, owner_rules
from tools.forja.equipment import image_sha
from tools.forja.tests.helpers import framed, tempdir


class OwnerRulesTest(unittest.TestCase):
    def test_rules_command_exposes_sources_and_required_reading(self):
        result = cli.run(["regras"])
        self.assertTrue(result["ok"])
        self.assertIn("hands_grip", {r["id"] for r in result["rules"]})
        self.assertIn("docs/art/OWNER_RULES.md", result["consultation"]["required_reading"])
        self.assertTrue(all(r["source"]["author"] == "Henrique" for r in result["rules"]))

    def test_prompt_and_plan_carry_rules_and_exact_character_authority(self):
        d = tempdir()
        for command in ("prompt", "plan"):
            r = cli.run([command, "alquimista", "--character", "alquimista",
                         "--palette", "none", "-o", str(d / command)])
            data = json.loads(Path(r["plan"]).read_text()) if command == "plan" else r
            self.assertIn("Pixel contact alone", data["prompt"])
            self.assertIn("round potion bulb", data["prompt"])
            ctx = data["expect"]["owner_rules"]
            self.assertEqual(ctx["character"], "alchemist_emperor")
            self.assertTrue(ctx["authority_crop_sha256"])
            self.assertEqual(ctx["revision"], owner_rules.context()["revision"])

    def test_mcp_exposes_rules_and_delivery_gate(self):
        from tools.forja import mcp_server
        names = {t["name"] for t in mcp_server.tools()}
        self.assertTrue({"forja_regras", "forja_entrega"} <= names)


class DeliveryGateTest(unittest.TestCase):
    def setUp(self):
        self.image = framed()
        self.ch = {"id": "test", "kind": "royal_64", "target_canvas": [64, 64],
                   "authority_crop_xyxy": [0, 0, 64, 64],
                   "_authority_crop_sha256": "reference"}
        self.ctx = {**owner_rules.context(), "character": "test", "authority_crop_sha256": "reference"}
        self.forge = {"owner_rules": self.ctx, "lineage": {"schema": "forja.lineage/1",
            "output_sha256": image_sha(self.image), "stages": [{"grid": {"origin": "exact"}}],
            "occurrences": []}}
        self.visual = {"owner_rules": delivery_review.template(self.ch, self.image),
                       "observer": {"author": "reviewer", "method": "visual", "date": "2026-10-30"}}
        doc = self.visual["owner_rules"]
        doc["views"] = {"native_1x": True, "integer_zoom": 4, "light_background": True,
                        "dark_background": True, "side_by_side": True}
        for check in doc["checks"]:
            check.update(status="pass", evidence="Observed in this exact image against the concept.",
                         candidate_box=[1, 1, 63, 63], authority_box=[1, 1, 63, 63])

    def check(self, **kw):
        return delivery_review.check(self.ch, kw.get("image", self.image),
                                     kw.get("forge", self.forge), kw.get("visual", self.visual))

    def test_unreviewed_dimensions_and_export_success_do_not_make_review_ready(self):
        self.assertFalse(self.check(visual=None)["ready_for_review"])
        self.assertEqual(self.check()["status"], "pass")
        self.assertFalse(self.check(forge=None)["ready_for_review"])

    def test_reduced_stage_stays_blocked_after_native_reexport_and_matching_flask(self):
        bad = copy.deepcopy(self.forge)
        bad["lineage"]["stages"] = [{"grid": {"origin": "deliberately_reduced"}},
                                    {"grid": {"origin": "native"}}]
        result = self.check(forge=bad)
        self.assertEqual(result["status"], "blocked")
        self.assertIn("reducao", " ".join(result["blocking"]))
        self.assertFalse(result["ready_for_review"])

    def test_stale_rules_changed_candidate_and_wrong_authority_are_rejected(self):
        for field, value in (("revision", "old"), ("image_sha256", "another"),
                             ("authority_crop_sha256", "wrong")):
            visual = copy.deepcopy(self.visual)
            visual["owner_rules"][field] = value
            self.assertEqual(self.check(visual=visual)["status"], "blocked", field)
        forged = copy.deepcopy(self.forge)
        forged["owner_rules"]["revision"] = "old"
        self.assertEqual(self.check(forge=forged)["status"], "blocked")

    def test_missing_or_failed_grip_or_face_review_cannot_pass_by_contact_alone(self):
        for key in ("hands_grip", "face", "contour", "equipment_shape"):
            visual = copy.deepcopy(self.visual)
            next(c for c in visual["owner_rules"]["checks"] if c["id"] == key)["status"] = "fail"
            self.assertEqual(self.check(visual=visual)["status"], "blocked", key)
        visual = copy.deepcopy(self.visual)
        visual["owner_rules"]["checks"] = [c for c in visual["owner_rules"]["checks"] if c["id"] != "face"]
        self.assertFalse(self.check(visual=visual)["ready_for_review"])

    def test_a_pass_requires_evidence_boxes_and_all_actual_views(self):
        visual = copy.deepcopy(self.visual)
        visual["owner_rules"]["checks"][0]["evidence"] = ""
        self.assertFalse(self.check(visual=visual)["ready_for_review"])
        visual = copy.deepcopy(self.visual)
        visual["owner_rules"]["checks"][0]["candidate_box"] = [0, 0, 65, 64]
        self.assertEqual(self.check(visual=visual)["status"], "blocked")
        visual = copy.deepcopy(self.visual)
        visual["owner_rules"]["views"]["native_1x"] = False
        self.assertFalse(self.check(visual=visual)["ready_for_review"])

    def test_delivery_command_fails_when_the_cast_is_missing_or_unreviewed(self):
        d = tempdir()
        r = cli.run(["entrega", str(d)])
        self.assertFalse(r["ok"])
        self.assertEqual(r["count"], 15)
        self.assertEqual(r["ready_for_review"], 0)

    def test_native_footprint_is_measured_without_an_arbitrary_fill_threshold(self):
        before = self.image.tobytes()
        result = self.check()
        self.assertEqual(result["measurements"]["canvas"], [64, 64])
        self.assertEqual(result["measurements"]["occupied_bbox"], list(self.image.getchannel("A").getbbox()))
        self.assertEqual(result["measurements"]["pixels_changed_by_review"], 0)
        self.assertEqual(self.image.tobytes(), before)

    def test_malformed_or_duplicated_review_evidence_does_not_pass(self):
        for field, value in (("views", [True]), ("checks", "pass")):
            visual = copy.deepcopy(self.visual)
            visual["owner_rules"][field] = value
            self.assertFalse(self.check(visual=visual)["ready_for_review"])
        visual = copy.deepcopy(self.visual)
        visual["owner_rules"]["checks"].append(visual["owner_rules"]["checks"][0])
        self.assertFalse(self.check(visual=visual)["ready_for_review"])
        self.assertEqual(self.check(visual={"owner_rules": ["pass"]})["status"], "blocked")
