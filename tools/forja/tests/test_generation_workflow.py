import json
import base64
import os
import unittest
from unittest import mock

from tools.forja import cli, cmd_ai, prompts, guides, pipeline
from PIL import Image
from tools.forja.backends import http, jobs
from tools.forja.tests.helpers import tempdir
from tools.forja.tests.test_native_animation import png64
from tools.forja.tests.test_backends import ENV, Fake, B64


class GenerationWorkflowTest(unittest.TestCase):
    def test_auto_dry_run_needs_no_key_and_uses_native_size(self):
        with mock.patch.dict(os.environ, {}, clear=True):
            result = cli.run(["auto", "a squire", "--kind", "royal_64", "--backend", "pixellab",
                              "--dry-run", "-o", str(tempdir())])
        self.assertEqual(result["plan"]["size"], "64x64")
        self.assertEqual(result["plan"]["max_submissions"], 3)

    def test_native_sheet_request_is_refused_before_any_call(self):
        args = cli.build_parser().parse_args(["auto", "a squire", "--kind", "royal_64", "--backend", "pixellab",
                                              "--tags", "walk", "-o", str(tempdir())])
        fake = Fake()
        with self.assertRaisesRegex(ValueError, "animate-native"):
            cmd_ai.do_auto(args, fake)
        self.assertFalse(fake.requests)

    def test_invalid_attempt_count_is_rejected_without_generation(self):
        args = cli.build_parser().parse_args(["auto", "a squire", "--attempts", "0", "-o", str(tempdir())])
        with self.assertRaises(ValueError):
            cmd_ai.do_auto(args, Fake())

    def test_gemini_plans_square_raster_with_explicit_integer_grid_padding(self):
        built = prompts.build("a squire", "character_s2", [("walk", 8)], target="gemini")
        exp = built["expect"]
        self.assertEqual(built["size"], "2048x2048")
        self.assertEqual(guides.template(exp).size, (2048, 2048))
        x0, y0, x1, y1 = exp["content_box"]
        self.assertEqual([x1 - x0, y1 - y0], [n * exp["scale"] for n in exp["cells"]])
        d = tempdir()
        Image.new("RGBA", (2048, 2048)).save(d / "raw.png")
        opts = pipeline.Options(source_box=tuple(exp["content_box"]), request_size=(2048, 2048))
        self.assertEqual(pipeline.input_image(d / "raw.png", opts).size, (x1 - x0, y1 - y0))
        Image.new("RGBA", (1024, 1024)).save(d / "wrong.png")
        with self.assertRaises(ValueError):
            pipeline.input_image(d / "wrong.png", opts)

    def test_existing_run_provenance_is_not_overwritten_by_dry_run(self):
        out = tempdir()
        for name in ("plan.json", "run.json"):
            (out / name).write_text('{"original":true}')
        with self.assertRaises(ValueError):
            cli.run(["auto", "changed", "--dry-run", "-o", str(out)])
        self.assertEqual((out / "plan.json").read_text(), '{"original":true}')

    @mock.patch.dict(os.environ, ENV)
    def test_native_auto_persists_one_submission_and_raw_image(self):
        out = tempdir()
        data = png64()
        fake = Fake((200, {"image": {"base64": base64.b64encode(data).decode()}}))
        args = cli.build_parser().parse_args(["auto", "a squire", "--kind", "royal_64", "--backend", "pixellab",
                                              "--attempts", "1", "--palette", "none", "-o", str(out)])
        result = cmd_ai.do_auto(args, fake)
        self.assertEqual(len(fake.requests), 1)
        self.assertEqual(json.loads(fake.requests[0].body)["image_size"], {"width": 64, "height": 64})
        self.assertEqual(result["attempts"][0]["status"], "reviewed")
        self.assertFalse(result["artistic_approval"])
        self.assertEqual((out / "raw/try1_01.png").read_bytes(), data)

    def test_polling_has_a_finite_request_budget(self):
        fake = Fake(*[(200, {"status": "processing"})] * 3)
        with self.assertRaisesRegex(http.ApiError, "job1"):
            jobs.poll_job("job1", {}, fake, max_polls=3)
        self.assertEqual(len(fake.requests), 3)

    @mock.patch.dict(os.environ, ENV)
    def test_checkpoint_precedes_first_poll(self):
        events = []
        fake = Fake((200, {"background_job_id": "job1"}),
                    (200, {"status": "completed", "last_response": {"image": {"base64": B64}}}))
        def transport(req):
            events.append(req.method)
            return fake(req)
        jobs.submit("create-image-pixflux", {}, {}, transport, on_job=lambda job: events.append(job))
        self.assertEqual(events, ["POST", "job1", "GET"])
