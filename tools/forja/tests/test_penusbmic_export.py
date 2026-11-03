"""Provas de exportacao e ensaio: pixels/tempo iguais, nenhuma aprovacao inferida."""
import unittest

from PIL import Image

from tools.forja import ase, aseprite, contracts
from tools.forja.tests.helpers import framed, tempdir


def source():
    out = tempdir()
    frames = [framed(i) for i in range(3)]
    fx = [Image.new("RGBA", (64, 64)) for _ in frames]
    fx[1].putpixel((5, 5), (255, 255, 255, 255))
    sprite = aseprite.assemble((64, 64), {"body": frames, "fx": fx}, durations=[90, 65, 140],
                       tags=[("idle", 0, 0, "forward"), ("attack", 1, 2, "reverse")],
                       pivot=contracts.get("troop_64").pivot)
    ase.write(sprite, out / "original.aseprite")
    return out, sprite, frames


class ActionExportTest(unittest.TestCase):
    def test_trim_roundtrip_preserves_canvas_pivot_durations_and_reverse_order(self):
        from tools.forja import action_export
        out, sprite, frames = source()
        before = (out / "original.aseprite").read_bytes()
        manifest = action_export.export(out / "original.aseprite", out / "proof", "troop_64", ["fx"], trim=True)
        self.assertEqual(before, (out / "original.aseprite").read_bytes())
        self.assertEqual(manifest["actions"][1]["playback"], [2, 1])
        self.assertEqual(manifest["frames"][1]["duration_ms"], 65)
        self.assertEqual(manifest["frames"][1]["pivot"], list(contracts.get("troop_64").pivot))
        self.assertNotEqual(manifest["frames"][1]["actor_sha256"], manifest["frames"][1]["final_sha256"])
        self.assertTrue(action_export.verify(out / "proof" / "manifest.json")["ok"])
        self.assertFalse(manifest["release_ready"])

    def test_changed_png_or_metadata_invalidates_export(self):
        from tools.forja import action_export
        out, _, _ = source()
        manifest = action_export.export(out / "original.aseprite", out / "proof", "troop_64", ["fx"])
        file = out / "proof" / manifest["actions"][0]["actor"]["png"]
        with Image.open(file) as im:
            im = im.convert("RGBA")
        im.putpixel((0, 0), (1, 2, 3, 255))
        im.save(file)
        self.assertFalse(action_export.verify(out / "proof" / "manifest.json")["ok"])

    def test_pivot_change_native_size_and_unknown_fx_are_rejected(self):
        from tools.forja import action_export
        out, sprite, _ = source()
        for kind, layers in [("royal_80", ["fx"]), ("troop_64", ["missing"])]:
            with self.assertRaises(ValueError):
                action_export.export(out / "original.aseprite", out / "bad", kind, layers)
        sprite.slices[0].keys.append(ase.SliceKey(1, 0, 0, 64, 64, pivot=(20, 20)))
        ase.write(sprite, out / "moved.aseprite")
        with self.assertRaisesRegex(ValueError, "pivot"):
            action_export.export(out / "moved.aseprite", out / "bad", "troop_64", ["fx"])

    def test_plan_contains_sourced_method_without_redesigning_approved_cast(self):
        from tools.forja import prompts, study
        p = prompts.build("rei", "royal_80", mode="adapt_concept")
        self.assertIn("preserve_and_repair", p["expect"]["study"]["design_mode"])
        self.assertIn("study:Penusbmic", str(p["constraints"]))
        self.assertEqual(len(study.load()["proposals"]), 9)


class EvidenceTest(unittest.TestCase):
    def test_empty_review_is_pending_and_edited_bundle_is_blocked(self):
        from tools.forja import action_export, rehearsal_review
        out, _, _ = source()
        manifest = action_export.export(out / "original.aseprite", out / "proof", "troop_64", ["fx"])
        review = rehearsal_review.template(manifest)
        result = rehearsal_review.check(manifest, review)
        self.assertEqual(result["status"], "pending")
        self.assertFalse(result["ok"])
        review["manifest_sha256"] = "old"
        self.assertEqual(rehearsal_review.check(manifest, review)["status"], "blocked")

    def test_effect_window_protects_only_its_region_and_interval(self):
        from tools.forja import temporal
        frames = [Image.new("RGBA", (8, 8), (40, 40, 40, 255)) for _ in range(5)]
        frames[1].putpixel((2, 2), (42, 42, 42, 255))
        frames[3].putpixel((2, 2), (42, 42, 42, 255))
        windows = [{"from": 1, "to": 1, "box": [1, 1, 4, 4], "reason": "glitch"}]
        changed, report = temporal.stabilize(frames, 0.1, static=[[0, 0, 8, 8]], action_windows=windows)
        self.assertEqual(changed[1].getpixel((2, 2)), (42, 42, 42, 255))
        self.assertEqual(changed[3].getpixel((2, 2)), (40, 40, 40, 255))
        self.assertGreater(report["counts"]["expected"], 0)

    def test_sheet_offsets_effect_windows_to_each_tag(self):
        from tools.forja import sheet_audit, sheetforge
        frames = [Image.new("RGBA", (8, 8), (40, 40, 40, 255)) for _ in range(7)]
        frames[3].putpixel((2, 2), (42, 42, 42, 255))
        frames[5].putpixel((2, 2), (42, 42, 42, 255))
        opts = sheetforge.SheetOptions(deflicker=0.1, static=[[0, 0, 8, 8]], effect_windows=[
            {"from": 3, "to": 3, "box": [1, 1, 4, 4], "reason": "spark"}])
        out, _ = sheet_audit.correct(frames, [("idle", 0, 1, "forward"), ("attack", 2, 6, "forward")], opts, frozenset())
        self.assertEqual(out[3].getpixel((2, 2)), (42, 42, 42, 255))
        self.assertEqual(out[5].getpixel((2, 2)), (40, 40, 40, 255))

    def test_study_cannot_be_removed_from_an_executable_plan(self):
        from tools.forja import plan, study
        p = plan.make("openai", "troop archer")
        p.call()
        stripped = p.data["prompt"].replace(study.rules(p.data["mode"])[0]["text"], "")
        with self.assertRaisesRegex(ValueError, "texto do estudo"):
            p.call(stripped)


if __name__ == "__main__":
    unittest.main()
