"""Uma sequência revista é a lista exata de pixels, tempos, tags, pivô e autoridade; exportar não aprova."""
import copy
import json
import unittest

from PIL import Image

from tools.forja import fidelity
from tools.forja.tests.animation_fixtures import fixture, frames, response
from tools.forja.tests.test_backends import ENV, Fake
from unittest import mock


@mock.patch.dict("os.environ", ENV)
class SequenceReviewTest(unittest.TestCase):
    def setUp(self):
        env = mock.patch.dict("os.environ", ENV)
        env.start()
        self.addCleanup(env.stop)
        from tools.forja import animation_plan, animation_run, sequence, sequence_review
        self.sequence, self.review = sequence, sequence_review
        self.root, self.master, _ = fixture()
        self.contract = fidelity.load(self.root / "fidelity.json")
        self.ch = fidelity.character(self.contract, "test_squire")
        p = animation_plan.make(self.root / "first.png", self.contract, "test_squire", "walk", native_root=True)
        path = p.write(self.root / "plan")
        self.out = self.root / "out"
        self.result = animation_run.run(path, self.out, transport=Fake(
            (200, {"background_job_id": "J1"}), (200, response(frames(self.master)))), sleep=lambda _: None)
        self.clip = sequence.load(self.out / "animation.forja.json")

    def complete(self):
        doc = self.review.template(self.clip, self.ch)
        doc["observer"] = {"author": "test", "method": "synthetic fixture comparison", "date": "2026-10-30"}
        doc["views"] = {k: True for k in doc["views"]}
        doc["views"]["integer_zoom"] = 4
        for row in doc["frames"]:
            for check in row["checks"]:
                check.update(status="pass", evidence="synthetic fixture checked",
                             candidate_box=[0, 0, 64, 64], authority_box=[0, 0, 64, 64])
        for row in doc["tags"]:
            for check in row["checks"]:
                check.update(status="pass", evidence="synthetic timeline checked")
        for row in doc["findings"]:
            row.update(status="pass", evidence="synthetic finding inspected")
        return doc

    def test_template_is_pending_for_every_frame_and_action(self):
        doc = self.review.template(self.clip, self.ch)
        self.assertEqual(len(doc["frames"]), 8)
        self.assertTrue(all(c["status"] == "pending" for r in doc["frames"] for c in r["checks"]))
        result = self.review.check(self.clip, self.ch)
        self.assertFalse(result["ready_for_review"])
        self.assertFalse(result["release_ready"])

    def test_reviewed_sequence_is_not_automatically_approved_by_the_owner(self):
        result = self.review.check(self.clip, self.ch, self.complete())
        self.assertTrue(result["ready_for_review"], result)
        self.assertFalse(result["release_ready"])

    def test_each_frame_needs_its_own_evidence(self):
        for edit in (lambda d: d["frames"].pop(), lambda d: d["frames"].append(d["frames"][0]),
                     lambda d: d["frames"][2]["checks"][0].update(evidence=""),
                     lambda d: d["frames"][2]["checks"][0].update(status="fail"),
                     lambda d: d["frames"][2]["checks"][0].update(candidate_box=[0, 0, 80, 80])):
            doc = self.complete()
            edit(doc)
            self.assertFalse(self.review.check(self.clip, self.ch, doc)["ready_for_review"])

    def test_unchanged_pixels_do_not_hide_a_changed_timeline(self):
        doc = self.complete()
        for field, value in (("durations", [120] * 8), ("pivot", [31, 62]),
                             ("tags", [["walk", 0, 7, "reverse"]])):
            changed = copy.deepcopy(self.clip)
            changed.data[field] = value
            self.assertFalse(self.review.check(changed, self.ch, doc)["ready_for_review"])

    def test_pixel_change_invalidates_the_chain_and_old_visual_review(self):
        with Image.open(self.out / "animation.png") as im:
            changed = im.convert("RGBA")
        changed.putpixel((32, 30), (255, 0, 0, 255))
        changed.save(self.out / "animation.png")
        with self.assertRaisesRegex(ValueError, "cadeia|pixels"):
            self.sequence.load(self.out / "animation.forja.json")

    def test_current_authority_and_owner_rules_are_required(self):
        doc = self.complete()
        changed = {**self.ch, "_authority_crop_sha256": "different"}
        self.assertFalse(self.review.check(self.clip, changed, doc)["ready_for_review"])
        doc["owner_rules_revision"] = "old"
        self.assertFalse(self.review.check(self.clip, self.ch, doc)["ready_for_review"])
        changed = {**self.ch, "invariants": ["new owner decision"]}
        self.assertFalse(self.review.check(self.clip, changed, self.complete())["ready_for_review"])

    def test_source_and_inherited_reductions_cannot_be_laundered(self):
        doc = self.complete()
        altered = copy.deepcopy(self.clip)
        altered.data["lineage"]["parent"] = {"schema": "forja.animation_lineage/1", "diagnostic_only": True}
        altered.data["lineage"]["diagnostic_only"] = False
        self.assertFalse(self.review.check(altered, self.ch, doc)["ready_for_review"])

    def test_final_release_requires_owner_approval_of_this_sequence(self):
        approval = {"schema": "forja.animation_approvals/1", "entries": [{
            "sequence_sha256": self.clip.sha, "state": "approved", "decided_by": "Henrique",
            "date": "2026-10-30", "evidence": "synthetic test only"}]}
        self.assertTrue(self.review.check(self.clip, self.ch, self.complete(), approval)["release_ready"])
        approval["entries"][0]["sequence_sha256"] = "other"
        self.assertFalse(self.review.check(self.clip, self.ch, self.complete(), approval)["release_ready"])

    def test_owner_rejection_blocks_even_a_previously_complete_visual_review(self):
        approval = {"schema": "forja.animation_approvals/1", "entries": [{
            "sequence_sha256": self.clip.sha, "state": "rejected", "decided_by": "Henrique",
            "date": "2026-10-30", "evidence": "synthetic rejection"}]}
        self.assertFalse(self.review.check(self.clip, self.ch, self.complete(), approval)["ready_for_review"])

    def test_delivery_cli_fails_until_review_is_complete_and_does_not_grant_approval(self):
        from tools.forja import cli
        args = [str(self.out / "animation.forja.json"), "--fidelity", str(self.root / "fidelity.json"),
                "--character", "test_squire"]
        r = cli.run(["entrega-anim", *args])
        self.assertFalse(r["ok"])
        visual = self.root / "review.json"
        visual.write_text(json.dumps(self.complete()))
        r = cli.run(["entrega-anim", *args, "--review", str(visual)])
        self.assertTrue(r["ok"], r)
        self.assertFalse(r["release_ready"])
        r = cli.run(["entrega-anim", *args, "--review", str(visual), "--release"])
        self.assertFalse(r["ok"])
