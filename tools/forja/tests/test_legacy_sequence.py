"""O portão novo também lê a prancha existente, sem reclassificar uma redução como desenho nativo."""
import unittest

from tools.forja import anim, fidelity, owner_rules, pipeline, sequence, sheetforge
from tools.forja.tests import test_sequence_review as review_fixtures
from tools.forja.tests.animation_fixtures import fixture, frames


class LegacySequenceTest(unittest.TestCase):
    complete = review_fixtures.SequenceReviewTest.complete

    def setUp(self):
        from tools.forja import sequence_review
        self.review = sequence_review
        self.root, master, _ = fixture()
        self.ch = fidelity.character(fidelity.load(self.root / "fidelity.json"), "test_squire")
        atlas, _ = anim.strip(frames(master))
        atlas.save(self.root / "atlas.png")
        context = owner_rules.context({"character": self.ch["id"],
                                      "crop_pixels_sha256": self.ch["_authority_crop_sha256"]})
        self.result = sheetforge.forge_sheet(self.root / "atlas.png", self.root / "sheet",
            pipeline.Options(kind="royal_64", scale=1, outline="keep", noise=0, cleanup="conservative",
                             native_root=True, owner_rules=context),
            sheetforge.SheetOptions(tags=[("walk", 8)], layout=(8, 1), align="preserve"))
        self.clip = sequence.load(self.result["files"]["forja_json"])

    def test_native_sheet_can_be_reviewed_by_frame_and_action(self):
        r = self.review.check(self.clip, self.ch, self.complete())
        self.assertTrue(r["ready_for_review"], r)
        self.assertFalse(r["release_ready"])

    def test_sheet_reduction_remains_blocked_after_a_reexport(self):
        self.clip.data["lineage"]["parent"] = {"diagnostic_only": True}
        r = self.review.check(self.clip, self.ch, self.complete())
        self.assertFalse(r["ready_for_review"])
