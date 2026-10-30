"""Perdas por quadro só fecham com prova nos pixels atuais ou exceção expressa do dono."""
import unittest

from tools.forja import sequence_losses
from tools.forja.equipment import image_sha
from tools.forja.tests import test_sequence_review as fixtures


class AnimationLossTest(unittest.TestCase):
    setUp = fixtures.SequenceReviewTest.setUp

    def loss(self):
        self.clip.data["lineage"]["frames"][2]["losses"] = [{"target_pixel": [29, 40], "kind": "erased"}]
        return {"schema": sequence_losses.SCHEMA, "sequence_sha256": self.clip.sha, "resolutions": [{
            "chain_output_sha256": self.clip.data["lineage"]["output_sha256"], "frame": 2, "loss": 0,
            "status": "repaired", "by": "test", "date": "2026-10-30", "evidence": "synthetic only",
            "pixels_sha256": image_sha(self.clip.frames[2]), "pixels": [[29, 40, "#000000"]]}]}

    def test_unresolved_losses_remain_pending_and_exact_repair_closes_one(self):
        doc = self.loss()
        self.assertTrue(sequence_losses.check(self.clip)["pending"])
        self.assertEqual(sequence_losses.check(self.clip, doc)["pending"], [])
        doc["resolutions"][0]["pixels"] = [[29, 40, "#ffffff"]]
        self.assertTrue(sequence_losses.check(self.clip, doc)["pending"])

    def test_new_sequence_or_unattributed_exception_does_not_close_a_loss(self):
        doc = self.loss()
        doc["sequence_sha256"] = "other"
        self.assertTrue(sequence_losses.check(self.clip, doc)["blocked"])
        doc = self.loss()
        doc["resolutions"][0].update(status="excepted", authorized_by="assistant")
        self.assertTrue(sequence_losses.check(self.clip, doc)["pending"])
        doc["resolutions"][0]["authorized_by"] = "Henrique"
        self.assertEqual(sequence_losses.check(self.clip, doc)["pending"], [])

    def test_a_blanket_pass_cannot_resolve_a_frame_loss(self):
        doc = self.loss()
        doc["resolutions"][0].update(status="pass")
        self.assertTrue(sequence_losses.check(self.clip, doc)["pending"])
