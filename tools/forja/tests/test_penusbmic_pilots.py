"""Pilotos limitam escopo, conservam escala e nao substituem desenhos escolhidos."""
import json
import unittest

from PIL import Image

from tools.forja import proof_io, study_pilots
from tools.forja.tests import scene_fixtures
from tools.forja.tests.helpers import framed, tempdir
from tools.forja.tests.test_penusbmic_review import observed


class PilotsTest(unittest.TestCase):
    def test_variations_reject_selected_cast_duplicate_and_wrong_canvas(self):
        out = tempdir()
        a, b = out / "a.png", out / "b.png"
        framed(0).save(a)
        framed(1).save(b)
        result = study_pilots.variations([a, b], "troop_64", out / "proof", "scout")
        self.assertTrue(result["ok"])
        path = out / "proof/manifest.json"
        doc = json.loads((out / "proof/review.template.json").read_text())
        self.assertEqual(study_pilots.review(path, doc)["status"], "pending")
        for images, character in (([a, a], None), ([a, b], "king")):
            with self.assertRaises(ValueError):
                study_pilots.variations(images, "troop_64", out / "bad", "scout", character=character)
        Image.new("RGBA", (80, 80)).save(b)
        with self.assertRaises(ValueError):
            study_pilots.variations([a, b], "troop_64", out / "bad", "scout")

    def test_scene_preserves_actor_scale_and_foreground_occlusion(self):
        out = tempdir()
        scene_fixtures.write(out, scene_fixtures.contract(), "contract.json")
        for name in ("masses", "background", "midground", "night"):
            Image.new("RGBA", (128, 128), (20, 30, 40, 255)).save(out / (name + ".png"))
        front = Image.new("RGBA", (128, 128))
        front.putpixel((40, 50), (255, 0, 0, 255))
        front.save(out / "foreground.png")
        front.save(out / "night-front.png")
        Image.new("RGBA", (64, 64), (0, 255, 0, 255)).save(out / "actor.png")
        spec = {"schema": "forja.scene_pilot/1", "contract": "contract.json",
                "planes": {n: n + ".png" for n in ("background", "midground", "foreground")},
                "masses": "masses.png", "night": "night.png", "night_foreground": "night-front.png",
                "actor": "actor.png", "actor_kind": "troop_64", "actor_at": [32, 32],
                "lower_access": [10, 100, 30, 128], "biome_groups": ["moss"], "procedural_regions": []}
        proof_io.save(out / "spec.json", spec)
        result = study_pilots.scene_pilot(out / "spec.json", out / "proof")
        self.assertTrue(result["ok"])
        for name in ("day-with-actor", "night-with-actor"):
            with Image.open(out / "proof" / (name + ".png")) as im:
                self.assertEqual(im.getpixel((40, 50)), (255, 0, 0, 255))
                self.assertEqual(im.getpixel((41, 50)), (0, 255, 0, 255))
        doc = json.loads((out / "proof/review.template.json").read_text())
        doc.update(observer={"author": "test", "method": "fixture", "date": "2026-11-03"},
                   views={"native_1x": True, "integer_zoom": 4})
        doc["checks"] = {k: observed() for k in doc["checks"]}
        self.assertEqual(study_pilots.review(out / "proof/manifest.json", doc)["status"], "pending")
        spec["actor_at"] = [100, 100]
        proof_io.save(out / "spec.json", spec)
        with self.assertRaises(ValueError):
            study_pilots.scene_pilot(out / "spec.json", out / "bad")


if __name__ == "__main__":
    unittest.main()
