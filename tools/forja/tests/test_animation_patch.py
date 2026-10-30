"""Refinar um quadro sem regenerar o corpo nem apagar a origem ou a revisão pendente."""
import copy
import unittest

from tools.forja import cli, sequence
from tools.forja.equipment import image_sha
from tools.forja.tests import test_sequence_review as fixtures


class AnimationPatchTest(unittest.TestCase):
    setUp = fixtures.SequenceReviewTest.setUp
    complete = fixtures.SequenceReviewTest.complete

    def patch(self):
        return {"schema": "forja.animation_patch/1", "sequence_sha256": self.clip.sha,
            "frames": [{"frame": 2, "patch": {"schema": "forja.pixel_patch/1",
                "base": {"pixels_sha256": image_sha(self.clip.frames[2]), "canvas": [64, 64]},
                "author": "test", "date": "2026-10-30", "reason": "synthetic repair",
                "mask": [[29, 40, 30, 41]], "operations": [
                    {"op": "paint", "pixels": [[29, 40, "#ffffff"]]}]}}]}

    def test_patch_keeps_every_other_pixel_timing_and_ancestor(self):
        from tools.forja import animation_patch
        out = self.root / "patched"
        r = animation_patch.apply(self.clip, self.patch(), self.ch, out)
        changed = sequence.load(out / "animation.forja.json")
        self.assertNotEqual(changed.sha, self.clip.sha)
        for i, (a, b) in enumerate(zip(self.clip.frames, changed.frames)):
            self.assertEqual(a.tobytes() == b.tobytes(), i != 2)
        self.assertEqual(changed.data["durations"], self.clip.data["durations"])
        self.assertEqual(changed.data["lineage"]["parent"], self.clip.data["lineage"])
        self.assertTrue(r["patches"][0]["exterior_identical"])
        self.assertFalse(self.review.check(changed, self.ch, self.complete())["ready_for_review"])
        self.assertFalse(r["release_ready"])

    def test_wrong_sequence_duplicate_frame_or_forbidden_mask_writes_nothing(self):
        from tools.forja import animation_patch
        for edit in (lambda p: p.update(sequence_sha256="other"),
                     lambda p: p["frames"].append(p["frames"][0]),
                     lambda p: p["frames"][0]["patch"].update(mask=[[1, 1, 2, 2]])):
            p = copy.deepcopy(self.patch())
            edit(p)
            out = self.root / "refused"
            with self.assertRaises(ValueError):
                animation_patch.apply(self.clip, p, self.ch, out)
            self.assertFalse((out / "animation.forja.json").exists())

    def test_patch_cli_exposes_a_local_refinement(self):
        from tools.forja import mcp_server
        cli.build_parser()
        self.assertIn("anim-patch", cli.REGISTRY)
        self.assertFalse(next(t for t in mcp_server.tools() if t["name"] == "forja_anim-patch")
                         ["annotations"]["openWorldHint"])
