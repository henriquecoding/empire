"""Pedidos reais compilados contra o recorte factual do OpenAPI público, sem rede nem créditos."""
import json
import unittest
from pathlib import Path
from unittest import mock

from tools.forja.backends import pixellab_animation as api
from tools.forja.tests.animation_fixtures import fixture, skeleton
from tools.forja.tests.test_backends import ENV


class AnimationApiContractTest(unittest.TestCase):
    def test_request_fields_required_and_enum_match_the_public_schema(self):
        spec = json.loads((Path(__file__).parent / "fixtures/pixellab-animation-openapi.json").read_text())
        self.assertEqual(spec["sha256"], api.SPEC_SHA256)
        root, master, _ = fixture()
        first = (root / "first.png").read_bytes()
        for model, name, frames, kw in (("text-v3", "AnimateWithTextV3Request", 8, {}),
                ("skeleton-v3", "AnimateWithSkeletonV3Request", 5,
                 {"description": "squire", "skeleton": skeleton(master)})):
            with mock.patch.dict("os.environ", ENV):
                body = json.loads(api.call(first, "walk", frames, model, **kw).request().body)
            schema = spec["schemas"][name]
            self.assertLessEqual(set(schema["required"]), set(body))
            self.assertLessEqual(set(body), set(schema["properties"]))
        self.assertEqual(set(api.JOINTS), set(spec["schemas"]["SkeletonLabel"]["enum"]))
        self.assertEqual(set(api.TEMPLATES), set(spec["schemas"]["AnimateWithSkeletonV3Request"]
                         ["properties"]["template_id"]["enum"]))

    def test_body_is_frozen_after_compilation(self):
        root, master, _ = fixture()
        poses = skeleton(master)
        call = api.call((root / "first.png").read_bytes(), "attack", 5, "skeleton-v3",
                        skeleton=poses, description="squire")
        poses["keypoints"][0][0]["x"] = 1
        with mock.patch.dict("os.environ", ENV):
            self.assertEqual(json.loads(call.request().body)["keypoints"][0][0]["x"], .4)
