import unittest
from PIL import Image
from tools.forja import quality
from tools.forja.tests.helpers import framed


class QualityTest(unittest.TestCase):
    def test_frozen_walk_requires_review(self):
        frame = framed()
        res = quality.review([frame] * 8, [("walk", 0, 7, "forward")])
        self.assertIn("static_sequence", {f["rule"] for f in res["findings"]})
        self.assertFalse(res["ready"])

    def test_translation_is_not_new_articulation(self):
        frame = framed()
        shifted = Image.new("RGBA", frame.size)
        shifted.alpha_composite(frame, (1, -1))
        res = quality.review([frame, shifted], [("walk", 0, 1, "forward")])
        self.assertIn("rigid_translation", {f["rule"] for f in res["findings"]})

    def test_protected_face_is_measured_and_never_repainted(self):
        frame = framed()
        changed = frame.copy()
        changed.putpixel((32, 28), (255, 0, 0, 255))
        before = changed.tobytes()
        res = quality.review([changed], reference=frame, region=(24, 20, 40, 36))
        self.assertFalse(res["ready"])
        self.assertEqual(res["reference"]["regions"][0]["changed_pixels"], 1)
        self.assertEqual(changed.tobytes(), before)

    def test_transparent_rgb_does_not_count_as_identity_change(self):
        frame = framed()
        changed = frame.copy()
        changed.putpixel((0, 0), (255, 0, 0, 0))
        res = quality.review([changed], reference=frame, region=(0, 0, 4, 4))
        self.assertEqual(res["reference"]["regions"][0]["changed_pixels"], 0)

    def test_animation_metrics_do_not_bridge_unrelated_tags(self):
        frame = framed()
        changed = frame.copy()
        changed.putpixel((32, 28), (255, 0, 0, 255))
        tags = [("one", 0, 1, "forward"), ("two", 2, 3, "forward")]
        res = quality.review([frame, frame, changed, changed], tags)
        self.assertEqual([t["flicker_candidates"] for t in res["by_tag"]], [0, 0])

    def test_different_canvas_is_never_resized_for_comparison(self):
        with self.assertRaises(ValueError):
            quality.review([framed()], reference=Image.new("RGBA", (80, 80)))
