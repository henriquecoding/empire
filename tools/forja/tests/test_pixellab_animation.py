"""A API recebe referência nativa e poses explícitas; nenhum quadro é inventado para fechar contagens."""
import copy
import json
import os
import unittest
from unittest import mock

from PIL import Image

from tools.forja.imageops import png_bytes
from tools.forja.tests.animation_fixtures import fixture, frames, response, skeleton
from tools.forja.tests.test_backends import ENV, Fake


class AnimationBackendTest(unittest.TestCase):
    def setUp(self):
        from tools.forja.backends import pixellab_animation
        self.api = pixellab_animation
        self.root, self.master, _ = fixture()
        self.png = png_bytes(self.master)

    def test_text_payload_and_descriptor_keep_the_native_image(self):
        with mock.patch.dict(os.environ, ENV):
            call = self.api.call(self.png, "walk", 8, seed=42)
            body = json.loads(call.request().body)
        self.assertEqual(body["frame_count"], 8)
        self.assertEqual(body["seed"], 42)
        self.assertFalse(body["enhance_prompt"])
        self.assertEqual(body["first_frame"]["base64"], self.api.http.b64(self.png))
        self.assertNotIn("base64", json.dumps(call.descriptor))
        self.assertNotIn("p-test", json.dumps(call.descriptor))

    def test_odd_count_and_pixel_budget_are_refused_before_a_post(self):
        for n in (0, 3, 5, 7, 17, True):
            with self.subTest(n=n), self.assertRaises(ValueError):
                self.api.call(self.png, "attack", n)
        with self.assertRaises(ValueError):
            self.api.call(png_bytes(Image.new("RGBA", (256, 256))), "walk", 16)
        with self.assertRaises(ValueError):
            self.api.call(png_bytes(Image.new("RGBA", (257, 64))), "walk", 8)

    def test_end_pose_and_options_are_validated(self):
        for kw in ({"last_frame": png_bytes(Image.new("RGBA", (80, 80)))}, {"seed": -1},
                   {"drift_threshold": float("nan")}, {"seed": True}):
            with self.subTest(kw=list(kw)), self.assertRaises(ValueError):
                self.api.call(self.png, "walk", 8, **kw)
        for text in ("", "x" * 1001):
            with self.assertRaises(ValueError):
                self.api.call(self.png, text, 8)

    def test_skeleton_supports_the_five_frame_attack_without_resampling(self):
        pose = skeleton(self.master)
        with mock.patch.dict(os.environ, ENV):
            call = self.api.call(self.png, "attack", 5, model="skeleton-v3", skeleton=pose,
                                 description="a squire with sword", direction="east")
            body = json.loads(call.request().body)
        self.assertEqual(len(body["keypoints"]), 5)
        self.assertEqual(len(body["first_frame_keypoints"]), 18)
        self.assertEqual(body["keypoints"], pose["keypoints"])
        self.assertEqual(body["view"], "side")

    def test_missing_duplicate_nonfinite_and_unknown_joints_are_refused(self):
        original = skeleton(self.master)
        cases = []
        for edit in (lambda p: p["keypoints"][0].pop(),
                     lambda p: p["keypoints"][0].append(p["keypoints"][0][0]),
                     lambda p: p["keypoints"][0][0].update(x=float("nan")),
                     lambda p: p["keypoints"][0][0].update(x=1.1),
                     lambda p: p["keypoints"][0][0].update(label="HAND"),
                     lambda p: p["keypoints"][0][0].update(z_index=0.5),
                     lambda p: p["keypoints"][0][0].update(depth=256)):
            pose = copy.deepcopy(original)
            edit(pose)
            cases.append(pose)
        for pose in cases:
            with self.subTest(pose=pose["keypoints"][0][0]), self.assertRaises(ValueError):
                self.api.call(self.png, "attack", 5, model="skeleton-v3", skeleton=pose,
                              description="squire")

    def test_skeleton_is_bound_to_the_exact_reference(self):
        pose = skeleton(self.master)
        pose["first_frame_pixels_sha256"] = "other"
        with self.assertRaisesRegex(ValueError, "referencia"):
            self.api.call(self.png, "attack", 5, model="skeleton-v3", skeleton=pose, description="squire")

    def test_poll_reads_only_the_ordered_images_not_the_reference_or_preview(self):
        clip = frames(self.master)
        data = response(clip)
        data["last_response"]["preview"] = response([self.master])["last_response"]["images"][0]
        parsed = self.api.parse_job(data)
        self.assertEqual(parsed.images, [png_bytes(f) for f in clip])
        self.assertEqual(parsed.usage_usd, 0.12)
        self.assertEqual(self.api.parse_job({"status": "processing"}) .state, "processing")

    def test_repeated_frames_remain_in_the_provider_order(self):
        clip = [self.master, self.master, frames(self.master)[0]]
        parsed = self.api.parse_job(response(clip))
        self.assertEqual(len(parsed.images), 3)
        self.assertEqual(parsed.images[0], parsed.images[1])


if __name__ == "__main__":
    unittest.main()
