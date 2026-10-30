"""Mudanças no export ou na origem não herdam a revisão da sequência anterior."""
import copy
import json
import unittest

from tools.forja import aseprite, cli
from tools.forja.tests import test_sequence_review as fixtures


class SequenceIntegrityTest(unittest.TestCase):
    setUp = fixtures.SequenceReviewTest.setUp
    complete = fixtures.SequenceReviewTest.complete
    def test_export_pivot_and_aseprite_tags_must_match_the_reviewed_timeline(self):
        path = self.out / "animation.json"
        meta = json.loads(path.read_text())
        meta["meta"]["slices"][0]["keys"][0]["pivot"]["x"] -= 1
        path.write_text(json.dumps(meta))
        with self.assertRaisesRegex(ValueError, "pivot"):
            self.sequence.load(self.out / "animation.forja.json")

    def test_aseprite_direction_and_pivot_cannot_diverge_from_png_json(self):
        for tags, pivot in (([("walk", 0, 7, "reverse")], (32, 62)),
                            ([("walk", 0, 7, "forward")], (31, 62))):
            aseprite.from_frames(self.out / "animation.aseprite", self.clip.frames,
                durations=[100] * 8, tags=tags, pivot=pivot)
            with self.assertRaisesRegex(ValueError, "Aseprite"):
                self.sequence.load(self.out / "animation.forja.json")

    def test_lineage_and_hold_changes_invalidate_visual_review(self):
        doc = self.complete()
        for edit in (lambda d: d["lineage"].update(native_root_declared=True),
                     lambda d: d.update(holds=[{"frame": 0, "ms": 100, "reason": "test"}])):
            clip = copy.deepcopy(self.clip)
            edit(clip.data)
            self.assertNotEqual(clip.sha, self.clip.sha)
            self.assertFalse(self.review.check(clip, self.ch, doc)["ready_for_review"])

    def test_malformed_review_or_approval_fails_closed(self):
        for doc in ([], 2, "pass"):
            self.assertFalse(self.review.check(self.clip, self.ch, doc)["ready_for_review"])
        for entries in (None, "approved", [None], [{"sequence_sha256": self.clip.sha,
                "state": "approved", "decided_by": "Henrique", "date": " ", "evidence": " "}]):
            r = self.review.check(self.clip, self.ch, self.complete(),
                                  {"schema": self.review.APPROVALS, "entries": entries})
            self.assertFalse(r["release_ready"])

    def test_proof_contains_authority_all_native_frames_and_a_tag_player(self):
        path = self.root / "proof.html"
        r = cli.run(["animacao", str(self.clip.path), "--fidelity", str(self.root / "fidelity.json"),
            "--character", "test_squire", "--proof-out", str(path)])
        self.assertTrue(r["ok"])
        text = path.read_text()
        self.assertIn("Conceito de autoridade", text)
        self.assertIn("quadro 7", text)
        self.assertIn("onion", text)
        self.assertFalse(r["ready_for_review"])
