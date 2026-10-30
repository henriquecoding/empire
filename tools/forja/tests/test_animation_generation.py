"""Plano -> um POST -> polling retomável -> PNGs nativos -> sequência fiel aos metadados."""
import json
import io
import os
import unittest
from unittest import mock

from PIL import Image

from tools.forja import cli, fidelity, jobs, mcp_server
from tools.forja.imageops import png_bytes
from tools.forja.tests.animation_fixtures import fixture, frames, response, skeleton
from tools.forja.tests.test_backends import ENV, Fake


@mock.patch.dict(os.environ, ENV)
class AnimationGenerationTest(unittest.TestCase):
    def setUp(self):
        from tools.forja import animation_plan, animation_run
        self.planner, self.runner = animation_plan, animation_run
        self.root, self.master, self.ch = fixture()
        self.fidelity = fidelity.load(self.root / "fidelity.json")

    def plan(self, **kw):
        p = self.planner.make(self.root / "first.png", self.fidelity, self.ch["id"], "walk",
                              native_root=True, **kw)
        self.assertTrue(p.ok, p.data["errors"])
        return p.write(self.root / "plan")

    def run_clip(self, clip=None, **kw):
        fake = Fake((200, {"background_job_id": "J1"}), (200, response(clip or frames(self.master))))
        path = self.plan(**kw)
        result = self.runner.run(path, self.root / "out", transport=fake, sleep=lambda _: None)
        return result, fake, path

    def test_plan_is_offline_and_has_no_fabricated_native_approval(self):
        path = self.plan()
        p = self.planner.load(path)
        self.assertEqual(p.data["canvas"], [64, 64])
        self.assertEqual(p.data["reference"]["state"], "unrecorded")
        self.assertEqual(p.data["owner_rules"]["character"], self.ch["id"])
        self.assertFalse(p.data["release_ready"])
        self.assertNotIn("base64", json.dumps(p.data))

    def test_source_must_be_native_and_its_origin_explicit(self):
        p = self.planner.make(self.root / "first.png", self.fidelity, self.ch["id"], "walk")
        self.assertFalse(p.ok)
        self.master.resize((128, 128)).save(self.root / "big.png")
        p = self.planner.make(self.root / "big.png", self.fidelity, self.ch["id"], "walk", native_root=True)
        self.assertFalse(p.ok)
        self.assertIn("tela", " ".join(p.data["errors"]))

    def test_optional_end_pose_requires_its_own_native_origin(self):
        kw = {"last_path": self.root / "first.png", "native_root": True}
        p = self.planner.make(self.root / "first.png", self.fidelity, self.ch["id"], "walk", **kw)
        self.assertFalse(p.ok)
        p = self.planner.make(self.root / "first.png", self.fidelity, self.ch["id"], "walk",
                              last_native_root=True, **kw)
        self.assertTrue(p.ok, p.data["errors"])
        self.assertTrue(self.planner.load(p.write(self.root / "end-plan")).ok)

    def test_stale_rules_reference_and_tampered_parameters_fail_before_network(self):
        path = self.plan()
        d = json.loads(path.read_text())
        d["request"]["params"]["action"] = "different"
        path.write_text(json.dumps(d))
        fake = Fake()
        with self.assertRaises(ValueError):
            self.runner.run(path, self.root / "out", transport=fake)
        self.assertEqual(fake.requests, [])

    def test_native_frame_order_pixels_count_and_timing_are_preserved(self):
        clip = frames(self.master)
        result, fake, path = self.run_clip(clip)
        self.assertEqual([r.method for r in fake.requests], ["POST", "GET"])
        self.assertEqual(result["received_frames"], 8)
        self.assertFalse(result["ready_for_review"])
        data = json.loads((self.root / "out" / "animation.forja.json").read_text())
        self.assertEqual(data["durations"], [100] * 8)
        self.assertEqual(data["tags"], [["walk", 0, 7, "forward"]])
        for i, expected in enumerate(clip):
            with Image.open(self.root / "out" / f"frame_{i:03d}.png") as got:
                self.assertEqual(got.convert("RGBA").tobytes(), expected.tobytes())
        self.assertEqual(data["lineage"]["owner_rules"], self.planner.load(path).data["owner_rules"])

    def test_completed_command_is_idempotent_and_never_pays_twice(self):
        result, fake, path = self.run_clip()
        second = self.runner.run(path, self.root / "out", transport=Fake())
        self.assertEqual(second["job"], result["job"])
        self.assertEqual(len(fake.requests), 2)
        self.assertEqual(jobs.Budget.saved(self.root / "out").calls, 1)

    def test_timeout_resumes_by_get_and_preserves_the_budget(self):
        path = self.plan()
        fake = Fake((200, {"background_job_id": "J1"}), (200, {"status": "processing"}))
        first = self.runner.run(path, self.root / "out", transport=fake, max_polls=1, sleep=lambda _: None)
        self.assertFalse(first["ok"])
        again = Fake((200, response(frames(self.master))))
        second = self.runner.run(path, self.root / "out", transport=again, sleep=lambda _: None)
        self.assertTrue(second["ok"])
        self.assertEqual([r.method for r in again.requests], ["GET"])
        self.assertEqual(jobs.Budget.saved(self.root / "out").calls, 1)

    def test_generic_jobs_resume_keeps_the_animation_parser(self):
        out = self.root / "out"
        r = self.runner.run(self.plan(), out, transport=Fake(
            (200, {"background_job_id": "J1"}), (200, {"status": "processing"})),
            max_polls=1, sleep=lambda _: None)
        job = jobs.load(r["job"])
        data = response(frames(self.master))
        data["last_response"]["preview"] = response([self.master])["last_response"]["images"][0]
        fake = Fake((200, data))
        from tools.forja.backends import http
        send = http.send
        with mock.patch("tools.forja.backends.http.send", side_effect=lambda request, _transport, service, **kw:
                        send(request, fake, service, **kw)):
            r = cli.run(["jobs", str(out), "--resume", job.id])
        self.assertTrue(r["ok"], r)
        self.assertEqual(len(r["job"]["outputs"]), 8)
        self.assertEqual([r.method for r in fake.requests], ["GET"])

    def test_ambiguous_submission_is_not_repeated_even_with_a_larger_budget(self):
        path = self.plan()
        first = self.runner.run(path, self.root / "out", transport=Fake(TimeoutError("lost")), max_calls=2)
        self.assertFalse(first["ok"])
        again = Fake()
        result = self.runner.run(path, self.root / "out", transport=again, max_calls=2)
        self.assertFalse(result["ok"])
        self.assertEqual(again.requests, [])

    def test_wrong_count_or_dimensions_are_diagnostic_without_dropping_frames(self):
        for clip in (frames(self.master, 9), [Image.new("RGBA", (80, 80))] * 8):
            out = self.root / f"bad-{len(clip)}"
            path = self.plan()
            fake = Fake((200, {"background_job_id": "J1"}), (200, response(clip)))
            r = self.runner.run(path, out, transport=fake, sleep=lambda _: None)
            self.assertFalse(r["ok"])
            self.assertFalse((out / "animation.forja.json").exists())
            job = jobs.load(r["job"])
            self.assertEqual(len(job.data["outputs"]), len(clip))
            self.assertTrue(all(o.get("file") for o in job.data["outputs"]))

    def test_odd_canonical_count_uses_skeleton_and_keeps_all_five_frames(self):
        p = self.planner.make(self.root / "first.png", self.fidelity, self.ch["id"], "attack",
            model="skeleton-v3", skeleton=skeleton(self.master), native_root=True, description="squire")
        self.assertTrue(p.ok, p.data["errors"])
        path = p.write(self.root / "attack-plan")
        fake = Fake((200, {"background_job_id": "J1"}), (200, response(frames(self.master, 5))))
        r = self.runner.run(path, self.root / "attack", transport=fake, sleep=lambda _: None)
        self.assertEqual(r["received_frames"], 5)

    def test_non_png_output_is_retained_as_diagnostic_without_conversion(self):
        from tools.forja.backends import http
        buf = io.BytesIO()
        self.master.convert("RGB").save(buf, "JPEG")
        raw = {"type": "base64", "format": "jpeg", "base64": http.b64(buf.getvalue())}
        fake = Fake((200, {"background_job_id": "J1"}),
                    (200, {"status": "completed", "last_response": {"images": [raw] * 8}}))
        r = self.runner.run(self.plan(), self.root / "jpeg", transport=fake, sleep=lambda _: None)
        self.assertFalse(r["ok"])
        self.assertEqual(len(jobs.load(r["job"]).data["outputs"]), 8)
        self.assertFalse((self.root / "jpeg" / "animation.forja.json").exists())

    def test_cli_and_mcp_expose_plan_generation_and_sequence_gate(self):
        r = cli.run(["anim-plan", str(self.root / "first.png"), "--character", self.ch["id"],
            "--fidelity", str(self.root / "fidelity.json"), "--tag", "walk", "--native-root",
            "-o", str(self.root / "cli-plan")])
        self.assertTrue(r["ok"])
        schemas = {t["name"]: t for t in mcp_server.tools()}
        self.assertTrue(schemas["forja_animar"]["annotations"]["openWorldHint"])
        self.assertFalse(schemas["forja_anim-plan"]["annotations"]["openWorldHint"])
        self.assertIn("forja_entrega-anim", schemas)
