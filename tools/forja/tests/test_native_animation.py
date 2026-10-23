import base64
import io
import os
import unittest
from unittest import mock

from PIL import Image

from tools.forja import cli
from tools.forja.backends import pixellab_api
from tools.forja.tests.helpers import framed, tempdir
from tools.forja.tests.test_backends import ENV, Fake


def png64() -> bytes:
    buf = io.BytesIO()
    framed().save(buf, "PNG")
    return buf.getvalue()


@mock.patch.dict(os.environ, ENV)
class NativeAnimationTest(unittest.TestCase):
    def test_odd_frame_count_does_not_submit(self):
        fake = Fake()
        with self.assertRaises(ValueError):
            pixellab_api.animate(png64(), "walk", 5, transport=fake)
        self.assertFalse(fake.requests)

    def test_frames_are_returned_without_raster_changes(self):
        data = png64()
        images = [{"type": "base64", "base64": base64.b64encode(data).decode()}] * 4
        fake = Fake((200, {"background_job_id": "native1"}),
                    (200, {"status": "completed", "last_response": {"images": images}}))
        result = pixellab_api.animate(data, "idle", 4, transport=fake)
        self.assertEqual(result["images"], [data] * 4)
        self.assertTrue(fake.requests[0].url.endswith("/animate-with-text-v3"))

    def test_wrong_dimensions_are_not_silently_resized(self):
        bad = io.BytesIO()
        Image.new("RGBA", (80, 80)).save(bad, "PNG")
        images = [{"base64": base64.b64encode(bad.getvalue()).decode()}] * 4
        with self.assertRaisesRegex(RuntimeError, "tela"):
            pixellab_api.animate(png64(), "idle", 4, transport=Fake((200, {"images": images})))

    def test_native_dry_run_preserves_source_and_needs_no_key(self):
        d = tempdir()
        source = d / "ref.png"
        source.write_bytes(png64())
        with mock.patch.dict(os.environ, {}, clear=True):
            result = cli.run(["animate-native", str(source), "--action", "walk", "--frames", "8",
                              "--dry-run", "-o", str(d / "out")])
        self.assertEqual(source.read_bytes(), png64())
        self.assertEqual(result["plan"]["frame_count"], 8)
