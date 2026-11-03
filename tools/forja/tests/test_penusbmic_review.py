"""Evidencia incompleta, autoridade, efeitos e replay: nenhum sucesso implica aprovacao."""
import contextlib
import io
import json
import shutil
import subprocess
import unittest
from pathlib import Path

from tools.forja import action_export, proof_io, rehearsal, rehearsal_review
from tools.forja.tests.test_penusbmic_export import source


def observed():
    return {"status": "pass", "evidence": "Observacao sintetica do teste; nao e revisao artistica."}


def complete(manifest):
    manifest["authority"] = {"authority_crop_sha256": "synthetic", "face_states": [{
        "id": "neutral", "orientation": "right", "authorized_by": "fixture", "date": "2026-11-03",
        "reference_sha256": "synthetic", "instruction": "fixture", "invariants": ["nose", "beard"]}]}
    doc = rehearsal_review.template(manifest)
    doc["observer"] = {"author": "test", "method": "synthetic", "date": "2026-11-03"}
    doc["views"] = {k: 4 if k == "integer_zoom" else True for k in doc["views"]}
    for frame in doc["frames"]:
        for hand in frame["hands"]:
            hand.update(observed(), arm="connected", contact="empty_hand", visibility="visible",
                        orientation="palm down", trajectory="rest", box=[1, 1, 3, 3])
        frame["face"].update(observed(), state="neutral", orientation="right", box=[10, 10, 20, 20],
                             invariants_preserved=["nose", "beard"])
        frame["support"].update(observed(), phase="rest", contact="both", point=[32, 59],
                                leading_parts=["torso"], secondary_parts=[], occlusion="none")
        for key in ("body_without_vfx", "final_composition"):
            frame[key] = observed()
    for action in doc["actions"]:
        action["checks"] = {k: observed() for k in action["checks"]}
    doc["effect_windows"] = [{"from": 1, "to": 1, "box": [5, 5, 6, 6], "reason": "spark fixture"}]
    doc["effects_review"] = observed()
    doc["replay_review"] = observed()
    return doc


class ReviewTest(unittest.TestCase):
    def setUp(self):
        self.out, self.sprite, _ = source()
        self.m = action_export.export(self.out / "original.aseprite", self.out / "proof", "troop_64", ["fx"])
        self.actor, self.final, _, _ = action_export.prepare(self.sprite, "troop_64", ["fx"])
        self.doc = complete(self.m)

    def check(self, doc=None):
        return rehearsal_review.check(self.m, doc or self.doc, self.actor, self.final)

    def test_evidence_can_pass_but_never_grants_art_or_runtime_approval(self):
        result = self.check()
        self.assertTrue(result["ok"], result)
        self.assertFalse(result["release_ready"])
        self.assertEqual(result["owner_approval"], "not_granted")
        self.assertEqual(result["runtime_integration"], "not_evaluated")

    def test_hand_missing_arm_or_unknown_occluder_cannot_pass(self):
        self.doc["frames"][1]["hands"][0]["arm"] = "missing"
        self.assertEqual(self.check()["status"], "blocked")
        self.doc["frames"][1]["hands"][0]["arm"] = "occluded"
        self.assertEqual(self.check()["status"], "pending")

    def test_face_orientation_and_beard_require_their_own_evidence(self):
        self.doc["frames"][0]["face"]["orientation"] = "left"
        self.assertEqual(self.check()["status"], "pending")
        self.doc["frames"][0]["face"]["orientation"] = "right"
        self.doc["frames"][0]["face"]["invariants_preserved"] = ["nose"]
        self.assertEqual(self.check()["status"], "pending")

    def test_shared_prop_cannot_be_omitted_or_scaled_by_character(self):
        prop = {"id": "flask", "native_shared_dimensions": [8, 12]}
        self.m["authority"]["shared_props"] = [prop]
        self.assertEqual(self.check()["status"], "pending")
        for row in self.doc["frames"]:
            row["shared_props"] = [{"id": "flask", **observed(), "visibility": "visible", "dimensions": [8, 12]}]
        self.assertTrue(self.check()["ok"])
        self.doc["frames"][0]["shared_props"][0]["dimensions"] = [10, 15]
        self.assertEqual(self.check()["status"], "blocked")
        prop["native_shared_dimensions"] = None
        self.assertEqual(self.check()["status"], "pending")

    def test_effects_outside_declared_window_block_even_complete_review(self):
        self.doc["effect_windows"][0]["from"] = 2
        self.doc["effect_windows"][0]["to"] = 2
        self.assertEqual(self.check()["status"], "blocked")

    def test_omitted_action_and_stale_frame_are_blocking(self):
        self.doc["actions"].pop()
        self.doc["frames"][0]["duration_ms"] = 100
        self.assertEqual(self.check()["status"], "blocked")


class ReplayTest(unittest.TestCase):
    @unittest.skipUnless(shutil.which("node"), "Node necessario para testar os controles do player")
    def test_player_uses_exact_duration_direction_and_native_canvas(self):
        out, _, _ = source()
        rehearsal.create(out / "original.aseprite", out / "proof", "troop_64", ["fx"])
        result = subprocess.run(["node", str(Path(__file__).with_name("rehearsal_player_test.cjs")),
                                 str(out / "proof/index.html")], capture_output=True, text=True, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_roundtrip_preview_and_identical_recipe(self):
        out, _, _ = source()
        for name in ("a", "b"):
            result = rehearsal.create(out / "original.aseprite", out / name, "troop_64", ["fx"], trim=True)
            self.assertTrue(result["ok"])
        a, b = out / "a/manifest.json", out / "b/manifest.json"
        self.assertTrue(rehearsal.compare(a, b)["ok"])
        m = json.loads(b.read_text())
        m["replay"]["events"][0]["camera"] = [1, 0]
        proof_io.seal(m, b.parent, list(m["files"]))
        self.assertFalse(rehearsal.compare(a, b)["ok"])
        self.assertIn('id="native"', (out / "a/index.html").read_text())
        self.assertIn("data:image/png;base64,", (out / "a/index.html").read_text())

    def test_resealed_frame_metadata_must_still_match_source(self):
        out, _, _ = source()
        m = action_export.export(out / "original.aseprite", out / "proof", "troop_64", ["fx"])
        m["frames"][0]["duration_ms"] = 100
        proof_io.seal(m, out / "proof", list(m["files"]))
        self.assertFalse(action_export.verify(out / "proof/manifest.json")["ok"])

    def test_invalid_recipe_and_omitted_action_are_rejected(self):
        out, _, _ = source()
        m = action_export.export(out / "original.aseprite", out / "proof", "troop_64")
        good = rehearsal.recipe(m)["recipe"]
        for bad in ({}, [], {**good, "steps": good["steps"][:1]},
                    {**good, "steps": [{**good["steps"][0], "camera": [0.5, 0]}]}):
            with self.assertRaises(ValueError):
                rehearsal.recipe(m, bad)

    def test_effect_cannot_hide_body_layer_and_paths_stay_in_bundle(self):
        out, _, _ = source()
        with self.assertRaisesRegex(ValueError, "anatomia"):
            action_export.export(out / "original.aseprite", out / "proof", "troop_64", ["body"])
        with self.assertRaises(ValueError):
            proof_io.resolve(out, "../outside.png")

    def test_cli_and_mcp_report_incomplete_review_without_approving_it(self):
        from tools.forja import cli, mcp_server
        out, _, _ = source()
        rehearsal.create(out / "original.aseprite", out / "proof", "troop_64", ["fx"])
        path, doc = str(out / "proof/manifest.json"), str(out / "proof/review.template.json")
        with contextlib.redirect_stdout(io.StringIO()) as captured:
            code = cli.main(["ensaio-rever", path, "--review", doc])
        self.assertNotEqual(code, 0)
        self.assertFalse(json.loads(captured.getvalue())["ok"])
        response = mcp_server.call("forja_ensaio-rever", {"manifest": path, "review": doc})
        self.assertFalse(response["isError"])
        self.assertFalse(json.loads(response["content"][0]["text"])["ok"])
        self.assertTrue(mcp_server.annotations("ensaio-rever")["readOnlyHint"])


if __name__ == "__main__":
    unittest.main()
