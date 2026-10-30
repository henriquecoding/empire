"""FORJA-17: perdas na prancha, limites entre acoes e a previa que realmente se entrega."""
import json
import unittest
from pathlib import Path

from PIL import Image

from tools.forja import anim, cli, motion, pipeline, sheetforge
from tools.forja.equipment import image_sha
from tools.forja.tests.helpers import framed, tempdir


def poses():
    frames = [framed(4), framed(5), framed(6)]
    return frames


def board(frames, scale=1):
    sheet, _ = anim.strip(frames)
    return sheet.resize((sheet.width * scale, sheet.height * scale), Image.Resampling.NEAREST)


class TimelineIntegrityTest(unittest.TestCase):
    def test_animation_plan_assigns_keyposes_before_generation(self):
        from tools.forja import prompts
        r = prompts.build("troop archer", "troop_64", [("walk", 8), ("shoot", 5)])
        planned = r["expect"]["animation_plan"]
        self.assertEqual(planned["canvas"], [64, 64])
        self.assertEqual(planned["tags"][0]["keyframes"], {"contact": [0, 4]})
        self.assertEqual(planned["tags"][1]["keyframes"], {"release": [10]})
        self.assertIn("shoulder", r["prompt"])
        self.assertIn("occlusion", r["prompt"])
        self.assertIn("transition", r["prompt"])

    def test_keypose_plan_never_relabels_a_study_as_canonical(self):
        from tools.forja import prompts
        tag = prompts.build("king", "royal_80", [("attack", 4)])["expect"]["animation_plan"]["tags"][0]
        self.assertFalse(tag["canonical_count"])
        self.assertEqual(tag["keyframes"], {})

    def test_faithful_animation_does_not_order_every_frame_to_keep_the_static_pose(self):
        from tools.forja import prompts
        r = prompts.build("king", "royal_80", [("walk", 8)], mode="adapt_concept")
        self.assertNotIn("same view, pose and gesture", r["prompt"])
        self.assertIn("same camera", r["prompt"])
        self.assertIn("invariants", r["prompt"])
        self.assertEqual(r["implicit"], [])

    def test_invalid_export_writes_nothing(self):
        for durations in ([100], [100, 0, 100], [100, -1, 100], [100, 100, 65536]):
            out = tempdir() / "out"
            with self.subTest(durations=durations), self.assertRaises(ValueError):
                anim.export(poses(), out, "test", durations)
            self.assertFalse(out.exists())

    def test_frame_sizes_and_empty_sequences_fail_before_writing(self):
        for frames in ([], [framed(), Image.new("RGBA", (32, 32))]):
            with self.subTest(count=len(frames)), self.assertRaises(ValueError):
                anim.export(frames, tempdir() / "out", "test")

    def test_invalid_tag_ranges_and_orphan_frames_are_refused(self):
        for tags in ([("a", 0, 3, "forward")], [("a", 2, 1, "forward")],
                     [("a", 0, 1, "forward")], [("a", 0, 2, "unknown")]):
            with self.subTest(tags=tags), self.assertRaises(ValueError):
                anim.export(poses(), tempdir() / "out", "test", tags=tags)

    def test_direct_anim_refuses_a_short_or_long_tag_declaration(self):
        d = tempdir()
        files = []
        for i, f in enumerate(poses()):
            f.save(d / f"{i}.png")
            files.append(str(d / f"{i}.png"))
        for tags in ("walk:2", "walk:4"):
            with self.subTest(tags=tags), self.assertRaises(ValueError):
                cli.run(["anim", *files, "--tags", tags, "-o", str(d / "out")])

    def test_tag_and_hold_declarations_cannot_hide_invalid_counts(self):
        from tools.forja import review
        for text in ("walk:-1", "walk:0", "walk:2,walk:2"):
            with self.subTest(text=text), self.assertRaises(ValueError):
                sheetforge.parse_tags(text)
        for text in ("-1:100:pause", "1:-10:pause", "1:0:pause"):
            with self.subTest(text=text), self.assertRaises(ValueError):
                review.parse_holds([text])

    def test_transparent_hidden_rgb_does_not_invent_a_pose(self):
        from tools.forja import review
        a = framed()
        b = a.copy()
        b.putpixel((0, 0), (255, 0, 0, 0))
        r = review.motion([a, b], [("walk", 0, 1, "forward")])
        self.assertTrue(r["blocking"])
        self.assertEqual(anim.metrics([a, b])["distinct_rasters"], 1)


class PlaybackTest(unittest.TestCase):
    def test_nonlooping_gif_has_no_repeat_extension(self):
        p = tempdir() / "once.gif"
        anim.save_gif(poses(), [100, 120, 140], p, scale=1, loop=False)
        with Image.open(p) as im:
            self.assertNotIn("loop", im.info)
            self.assertEqual(im.n_frames, 3)

    def test_nonlooping_apng_plays_once_and_keeps_durations(self):
        p = tempdir() / "once.png"
        anim.save_apng(poses(), [100, 120, 140], p, scale=1, loop=False)
        with Image.open(p) as im:
            self.assertEqual(im.info["loop"], 1)
            durations = []
            for i in range(im.n_frames):
                im.seek(i)
                durations.append(im.info["duration"])
            self.assertEqual(durations, [100, 120, 140])

    def test_attack_preview_uses_one_play_in_both_formats(self):
        files = anim.export(poses(), tempdir(), "test", tags=[("attack", 0, 2, "forward")])
        with Image.open(files["gif"]) as im:
            self.assertNotIn("loop", im.info)
        with Image.open(files["apng"]) as im:
            self.assertEqual(im.info["loop"], 1)

    def test_direction_suffix_does_not_turn_an_attack_into_a_loop(self):
        files = anim.export(poses(), tempdir(), "test", tags=[("attack_left", 0, 2, "forward")])
        with Image.open(files["apng"]) as im:
            self.assertEqual(im.info["loop"], 1)

    def test_reverse_preview_matches_the_tag_and_its_times(self):
        files = anim.export(poses(), tempdir(), "test", [100, 120, 140], [("attack", 0, 2, "reverse")])
        with Image.open(files["apng"]) as im:
            self.assertEqual(im.convert("RGBA").resize((64, 64), Image.Resampling.NEAREST).tobytes(),
                             poses()[-1].tobytes())
            self.assertEqual(im.info["duration"], 140)


class LocalCorrectionTest(unittest.TestCase):
    def test_head_lock_preserves_a_declared_facial_action(self):
        from tools.forja import sheet_audit
        a = Image.new("RGBA", (8, 8), (80, 60, 50, 255))
        a.putpixel((4, 4), (0, 0, 0, 255))
        b = a.copy()
        b.putpixel((4, 4), (80, 60, 50, 255))
        fixed, _ = sheet_audit.correct([a, b], [("idle", 0, 1, "forward")],
            sheetforge.SheetOptions(lock=(0, 0, 8, 8), actions=[(4, 4, 5, 5)]), frozenset())
        self.assertEqual(fixed[1].tobytes(), b.tobytes())

    def test_lock_does_not_paste_a_head_over_a_changed_silhouette(self):
        a = framed()
        b = a.copy()
        b.putpixel((24, 20), (80, 30, 30, 255))
        b.putpixel((25, 21), (0, 0, 0, 0))
        fixed, report = motion.lock([a, b], (24, 20, 40, 32), search=0)
        self.assertEqual(fixed[1].tobytes(), b.tobytes())
        self.assertFalse(report[1]["locked"])
        self.assertIn("reason", report[1])

    def test_temporal_correction_does_not_cross_action_boundaries(self):
        from tools.forja import sheet_audit
        a = Image.new("RGBA", (4, 4), (100, 100, 100, 255))
        b = Image.new("RGBA", (4, 4), (101, 100, 100, 255))
        fixed, report = sheet_audit.correct([a, a.copy(), b, b.copy()],
            [("idle", 0, 1, "forward"), ("hit", 2, 3, "forward")],
            sheetforge.SheetOptions(deflicker=0.05, static=[(0, 0, 4, 4)]), frozenset())
        self.assertEqual([f.tobytes() for f in fixed], [a.tobytes(), a.tobytes(), b.tobytes(), b.tobytes()])
        self.assertEqual(report["deflicker"]["changed"], 0)


class SheetEvidenceTest(unittest.TestCase):
    def test_declared_scale_preserves_the_measured_phase_of_each_crop(self):
        from tools.forja import cells, sheet
        original = poses()
        image = board(original, 8)
        boxes, masks, _ = cells.split(image, None, (3, 1))
        figures = sheet.extract(image, boxes, None, scale=8, masks=masks, exact=True)
        for truth, figure in zip(original, figures):
            crop = truth.crop(truth.getchannel("A").getbbox())
            self.assertEqual(figure.native.size, crop.size)
            self.assertEqual(figure.native.tobytes(), crop.tobytes())

    def forge(self, opts, sopts=None, frames=None):
        d = tempdir()
        board(frames or poses()).save(d / "source.png")
        return sheetforge.forge_sheet(d / "source.png", d / "out", opts,
            sopts or sheetforge.SheetOptions(tags=[("anim", 3)], layout=(3, 1)))

    def test_sheet_keeps_consultation_and_marks_deliberate_reduction(self):
        context = {"revision": "test", "character": "test"}
        r = self.forge(pipeline.Options(scale=2, reduce=True, owner_rules=context, noise=0, outline="keep"))
        self.assertEqual(r["lineage"]["owner_rules"], context)
        self.assertTrue(r["delivery"]["diagnostic_only"])
        self.assertFalse(r["delivery"]["release_ready"])
        self.assertTrue(all(f["snap"]["grid"]["origin"] == "deliberately_reduced" for f in r["frames"]))
        with Image.open(r["files"]["sheet"]) as im:
            self.assertEqual(r["lineage"]["output_sha256"], image_sha(im.convert("RGBA")))

    def test_a_foreign_parent_chain_cannot_be_silently_ignored(self):
        with self.assertRaisesRegex(ValueError, "cadeia"):
            self.forge(pipeline.Options(scale=1, lineage={"output_sha256": "other", "stages": []}))

    def test_sheet_reexport_preserves_reduction_and_the_original_consultation(self):
        from tools.forja import lineage
        d = tempdir()
        first = self.forge(pipeline.Options(scale=2, reduce=True, owner_rules={"revision": "original"}))
        parent = lineage.load(first["files"]["forja_json"])
        second = sheetforge.forge_sheet(first["files"]["sheet"], d, pipeline.Options(scale=1,
            lineage=parent, owner_rules={"revision": "new"}),
            sheetforge.SheetOptions(tags=[("anim", 3)], layout=(3, 1)))
        self.assertTrue(second["delivery"]["diagnostic_only"])
        self.assertEqual(second["lineage"]["owner_rules"], {"revision": "original"})

    def test_extra_poses_are_exposed_as_unassigned_diagnostics(self):
        r = self.forge(pipeline.Options(scale=1),
            sheetforge.SheetOptions(tags=[("walk", 2)], layout=(3, 1)))
        self.assertFalse(r["ok"])
        self.assertEqual(r["tags"][-1][0], "unassigned")
        self.assertEqual(len(r["durations"]), 3)

    def test_cells_reach_the_sampler_instead_of_being_ignored(self):
        r = self.forge(pipeline.Options(cells=(96, 32), reduce=True))
        self.assertTrue(all(f["period"] == 2 for f in r["frames"]))
        self.assertTrue(r["delivery"]["diagnostic_only"])

    def test_native_sheet_can_keep_authored_contours(self):
        d = tempdir()
        board(poses()).save(d / "source.png")
        r = cli.run(["sheet", str(d / "source.png"), "--layout", "3x1", "--tags", "anim:3",
            "--outline", "keep", "--scale", "1", "--palette", "none", "--native-root", "-o", str(d / "out")])
        data = json.loads(Path(r["files"]["forja_json"]).read_text())
        self.assertFalse(any(f["finish"].get("outline_added") for f in data["frames"]))
        self.assertTrue(data["lineage"]["native_root_declared"])
