import base64
import io
import json
import os
import unittest
from unittest import mock

from PIL import Image

from tools.forja.backends import gemini_images, http, openai_images, pixellab_api


def png(color=(10, 20, 30, 255)) -> bytes:
    buf = io.BytesIO()
    Image.new("RGBA", (4, 4), color).save(buf, "PNG")
    return buf.getvalue()


class Fake:
    """Transporte falso: guarda os pedidos e devolve respostas preparadas."""

    def __init__(self, *responses):
        self.responses = list(responses)
        self.requests = []

    def __call__(self, req):
        self.requests.append(req)
        status, body = self.responses.pop(0)
        return http.Response(status, json.dumps(body).encode(), {})


B64 = base64.b64encode(png()).decode()
ENV = {"OPENAI_API_KEY": "sk-test", "GEMINI_API_KEY": "g-test", "PIXELLAB_API_KEY": "p-test"}


@mock.patch.dict(os.environ, ENV)
class OpenAITest(unittest.TestCase):
    def test_generate_request_and_parse(self):
        fake = Fake((200, {"data": [{"b64_json": B64, "revised_prompt": "r"}]}))
        res = openai_images.generate("a knight", "1024x1024", "gpt-image-2", background="transparent", transport=fake)
        req = fake.requests[0]
        self.assertEqual(req.url, "https://api.openai.com/v1/images/generations")
        self.assertEqual(req.headers["Authorization"], "Bearer sk-test")
        body = json.loads(req.body)
        self.assertEqual((body["model"], body["background"], body["output_format"]), ("gpt-image-2", "transparent", "png"))
        self.assertEqual(res["images"], [png()])
        self.assertNotIn("sk-test", json.dumps(res["request"]))

    def test_edit_is_multipart_with_mask(self):
        fake = Fake((200, {"data": [{"b64_json": B64}]}))
        openai_images.edit("fix the sword", [png(), png()], png(), "1024x1024", transport=fake)
        req = fake.requests[0]
        self.assertTrue(req.headers["Content-Type"].startswith("multipart/form-data; boundary="))
        self.assertEqual(req.body.count(b'name="image[]"'), 2)
        self.assertIn(b'name="mask"', req.body)

    def test_size_rules(self):
        self.assertEqual(openai_images.check_size("1536x768", "gpt-image-2"), "1536x768")
        with self.assertRaises(ValueError):
            openai_images.check_size("1000x1000", "gpt-image-2")
        with self.assertRaises(ValueError):
            openai_images.check_size("1536x768", "gpt-image-1.5")

    def test_retry_then_error(self):
        slept = []
        fake = Fake((429, {"error": "slow"}), (200, {"data": [{"b64_json": B64}]}))
        req = http.json_request("POST", "https://x", {}, {})
        self.assertEqual(http.send(req, fake, sleep=slept.append).status, 200)
        self.assertEqual(len(slept), 1)
        with self.assertRaises(http.ApiError):
            http.send(req, Fake((400, {"error": "bad"})), sleep=slept.append)


@mock.patch.dict(os.environ, ENV)
class GeminiTest(unittest.TestCase):
    def test_interactions_payload_and_parse(self):
        fake = Fake((200, {"steps": [{"type": "model_output", "content": [{"type": "image", "mime_type": "image/png", "data": B64}]}]}))
        res = gemini_images.generate("a tree", [png()], "gemini-3.1-flash-image", transport=fake)
        req = fake.requests[0]
        self.assertTrue(req.url.endswith("/v1beta/interactions"))
        self.assertEqual(req.headers["x-goog-api-key"], "g-test")
        body = json.loads(req.body)
        self.assertEqual(body["input"][1]["type"], "image")
        self.assertEqual(res["images"], [png()])

    def test_generate_content_parse(self):
        fake = Fake((200, {"candidates": [{"content": {"parts": [{"text": "ok"}, {"inlineData": {"mimeType": "image/png", "data": B64}}]}}]}))
        res = gemini_images.generate("a tree", api="generate_content", transport=fake)
        self.assertIn(":generateContent", fake.requests[0].url)
        self.assertEqual(len(res["images"]), 1)


@mock.patch.dict(os.environ, ENV)
class PixelLabTest(unittest.TestCase):
    def test_sync_payload(self):
        fake = Fake((200, {"image": {"type": "base64", "base64": B64}}))
        res = pixellab_api.generate("knight", 64, 64, outline="single color black outline", view="side",
                                    direction="east", no_background=True, transport=fake)
        body = json.loads(fake.requests[0].body)
        self.assertEqual(body["image_size"], {"width": 64, "height": 64})
        self.assertEqual(fake.requests[0].url, "https://api.pixellab.ai/v2/create-image-pixflux")
        self.assertEqual(res["images"], [png()])

    def test_job_polling(self):
        fake = Fake((200, {"background_job_id": "j1"}), (200, {"status": "processing"}),
                    (200, {"status": "completed", "last_response": {"image": {"type": "base64", "base64": B64}}}))
        res = pixellab_api.generate("knight", 64, 64, model="pixen", transport=fake)
        self.assertTrue(fake.requests[1].url.endswith("/background-jobs/j1"))
        self.assertEqual(len(res["images"]), 1)

    def test_rejects_unknown_enum(self):
        with self.assertRaises(ValueError):
            pixellab_api.payload("x", 32, 32, outline="thick")


class KeyTest(unittest.TestCase):
    def test_missing_key_message_names_the_variable(self):
        with mock.patch.dict(os.environ, {}, clear=True):
            with self.assertRaisesRegex(RuntimeError, "OPENAI_API_KEY"):
                http.key("OPENAI_API_KEY")
