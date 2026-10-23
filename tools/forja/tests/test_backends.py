import base64
import io
import json
import os
import unittest
from unittest import mock

from PIL import Image

from tools.forja.backends import gemini_images, http, openai_images, pixellab_api


def png(color=(10, 20, 30, 255), size=(4, 4)) -> bytes:
    buf = io.BytesIO()
    Image.new("RGBA", size, color).save(buf, "PNG")
    return buf.getvalue()


class Fake:
    """Transporte falso: guarda os pedidos e devolve respostas preparadas (ou levanta a excecao dada)."""

    def __init__(self, *responses):
        self.responses = list(responses)
        self.requests = []

    def __call__(self, req):
        self.requests.append(req)
        item = self.responses.pop(0)
        if isinstance(item, BaseException):
            raise item
        status, body, *headers = item
        return http.Response(status, json.dumps(body).encode(), headers[0] if headers else {})


B64 = base64.b64encode(png()).decode()
ENV = {"OPENAI_API_KEY": "sk-test", "GEMINI_API_KEY": "g-test", "PIXELLAB_API_KEY": "p-test"}
NO_WAIT = {"sleep": lambda _: None}


@mock.patch.dict(os.environ, ENV)
class SendTest(unittest.TestCase):
    """F01: um POST cobrado sai uma vez; so as consultas se repetem, com espera e prazo."""

    def test_post_is_sent_once_on_503(self):
        fake = Fake((503, {"error": "busy"}), (200, {}))
        with self.assertRaises(http.SubmissionUnknown) as ctx:
            http.send(http.json_request("POST", "https://x/gen", {}, {}), fake, **NO_WAIT)
        self.assertEqual(len(fake.requests), 1)
        self.assertEqual(ctx.exception.outcome, "unknown")

    def test_post_timeout_is_ambiguous_not_retried(self):
        fake = Fake(TimeoutError("lost"), (200, {}))
        with self.assertRaises(http.SubmissionUnknown):
            http.send(http.json_request("POST", "https://x/gen", {}, {}), fake, **NO_WAIT)
        self.assertEqual(len(fake.requests), 1)

    def test_post_429_is_a_clear_rejection_with_its_wait(self):
        fake = Fake((429, {"error": "slow"}, {"Retry-After": "12"}))
        with self.assertRaises(http.ApiError) as ctx:
            http.send(http.json_request("POST", "https://x/gen", {}, {}), fake, **NO_WAIT)
        self.assertEqual((ctx.exception.outcome, ctx.exception.retry_after, len(fake.requests)), ("rejected", 12.0, 1))

    def test_get_retry_respects_retry_after(self):
        slept = []
        fake = Fake((503, {}, {"Retry-After": "7"}), (200, {"ok": 1}))
        log = []
        resp = http.send(http.json_request("GET", "https://x/job", None, {}), fake, sleep=slept.append, log=log)
        self.assertEqual((resp.status, slept), (200, [7.0]))
        self.assertEqual([e["status"] for e in log], [503, 200])
        self.assertNotIn("headers", log[0])

    def test_retry_after_http_date(self):
        from datetime import datetime, timezone
        now = datetime(2026, 10, 23, 12, 0, 0, tzinfo=timezone.utc)
        self.assertEqual(http.retry_after({"Retry-After": "Fri, 23 Oct 2026 12:00:30 GMT"}, now), 30.0)

    def test_get_stops_at_deadline(self):
        t = [0.0]

        def sleep(s):
            t[0] += s

        fake = Fake(*[(503, {})] * 50)
        with self.assertRaises(http.ApiError) as ctx:
            http.send(http.json_request("GET", "https://x/job", None, {}), fake, deadline=10, attempts=50,
                      sleep=sleep, clock=lambda: t[0], rand=lambda: 1.0)
        self.assertLessEqual(t[0], 10)
        self.assertEqual(ctx.exception.outcome, "failed")

    def test_get_client_error_is_not_retried(self):
        fake = Fake((404, {"error": "gone"}), (200, {}))
        with self.assertRaises(http.ApiError):
            http.send(http.json_request("GET", "https://x/job", None, {}), fake, **NO_WAIT)
        self.assertEqual(len(fake.requests), 1)


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
        self.assertEqual(res["revised_prompts"], ["r"])
        self.assertNotIn("sk-test", json.dumps(res["request"]) + json.dumps(res["job"]))
        self.assertEqual(res["job"]["cost"]["status"], "unknown")

    def test_edit_is_multipart_with_mask_and_roles(self):
        fake = Fake((200, {"data": [{"b64_json": B64}]}))
        res = openai_images.edit("fix the sword", [png(), png((1, 2, 3, 255))], png(), "1024x1024", transport=fake,
                                 roles=["edit_target", "identity"])
        req = fake.requests[0]
        self.assertTrue(req.headers["Content-Type"].startswith("multipart/form-data; boundary="))
        self.assertEqual(req.body.count(b'name="image[]"'), 2)
        self.assertIn(b'name="mask"', req.body)
        self.assertEqual([i["role"] for i in res["request"]["images"]], ["edit_target", "identity", "mask"])

    def test_size_and_model_rules(self):
        self.assertEqual(openai_images.check_size("1536x768", "gpt-image-2"), "1536x768")
        with self.assertRaises(ValueError):
            openai_images.check_size("1000x1000", "gpt-image-2")
        with self.assertRaises(ValueError):
            openai_images.check_size("1536x768", "gpt-image-1.5")
        with self.assertRaises(ValueError):
            openai_images.generate_call("x", "1024x1024", "pixflux")


@mock.patch.dict(os.environ, ENV)
class GeminiTest(unittest.TestCase):
    def test_interactions_payload_and_parse(self):
        fake = Fake((200, {"steps": [{"type": "model_output", "content": [{"type": "image", "mime_type": "image/png",
                                                                             "data": B64}]}]}))
        res = gemini_images.generate("a tree", [png()], "gemini-3.1-flash-image", aspect="16:9", size="2K",
                                     transport=fake)
        req = fake.requests[0]
        self.assertTrue(req.url.endswith("/v1beta/interactions"))
        self.assertEqual(req.headers["x-goog-api-key"], "g-test")
        body = json.loads(req.body)
        self.assertEqual(body["input"][1]["type"], "image")
        self.assertEqual(body["response_format"], {"type": "image", "aspect_ratio": "16:9", "image_size": "2K"})
        self.assertEqual(res["images"], [png()])

    def test_output_image_field(self):
        fake = Fake((200, {"output_image": {"data": B64}}))
        self.assertEqual(gemini_images.generate("a tree", transport=fake)["images"], [png()])

    def test_generate_content_parse(self):
        fake = Fake((200, {"candidates": [{"content": {"parts": [{"text": "ok"}, {"inlineData": {
            "mimeType": "image/png", "data": B64}}]}}]}))
        res = gemini_images.generate("a tree", api="generate_content", transport=fake)
        self.assertIn(":generateContent", fake.requests[0].url)
        self.assertEqual(len(res["images"]), 1)

    def test_capabilities_are_checked_locally(self):
        with self.assertRaisesRegex(ValueError, "proporcao"):
            gemini_images.call("x", [], "gemini-3-pro-image", "8:1", "1K")
        with self.assertRaisesRegex(ValueError, "resolucao"):
            gemini_images.call("x", [], "gemini-3.1-flash-lite-image", "1:1", "2K")
        with self.assertRaisesRegex(ValueError, "personagem"):
            gemini_images.call("x", [("identity", png())] * 5, "gemini-3.1-flash-image", "1:1", "1K")
        self.assertEqual(gemini_images.estimate("1:1", "1K"), (1024, 1024))


@mock.patch.dict(os.environ, ENV)
class PixelLabTest(unittest.TestCase):
    def test_sync_payload_and_cost(self):
        fake = Fake((200, {"image": {"type": "base64", "base64": B64}, "usage": {"type": "usd", "usd": 0.007}}))
        res = pixellab_api.generate("knight", 64, 64, outline="single color black outline", view="side",
                                    direction="east", no_background=True, transport=fake)
        body = json.loads(fake.requests[0].body)
        self.assertEqual(body["image_size"], {"width": 64, "height": 64})
        self.assertEqual(fake.requests[0].url, "https://api.pixellab.ai/v2/create-image-pixflux")
        self.assertEqual(res["images"], [png()])
        self.assertEqual(res["job"]["cost"], {"usd": 0.007, "status": "reported_by_provider"})

    def test_job_polling(self):
        fake = Fake((200, {"background_job_id": "j1"}), (200, {"status": "processing"}),
                    (200, {"status": "completed", "last_response": {"image": {"type": "base64", "base64": B64}}}))
        res = pixellab_api.generate("knight", 64, 64, model="pixen", transport=fake, **NO_WAIT)
        self.assertTrue(fake.requests[1].url.endswith("/background-jobs/j1"))
        self.assertEqual([r.method for r in fake.requests], ["POST", "GET", "GET"])
        self.assertEqual(len(res["images"]), 1)

    def test_limits_are_checked_before_any_request(self):
        self.assertIn("pixen: largura e altura multiplas de 4", pixellab_api.check("pixen", 30, 30))
        self.assertTrue(pixellab_api.check("pixflux", 401, 401))
        self.assertTrue(pixellab_api.check("bitforge", 256, 256))
        self.assertTrue(pixellab_api.check("pixen", 512, 512, no_background=True))
        self.assertIn("pixen nao aceita init_image", pixellab_api.check("pixen", 64, 64, init_image=png(size=(64, 64))))
        self.assertTrue(pixellab_api.check("pixflux", 64, 64, init_image=png(size=(32, 32))))
        self.assertEqual(pixellab_api.check("pixflux", 80, 80, init_image=png(size=(80, 80))), [])
        with self.assertRaises(ValueError):
            pixellab_api.payload("x", 32, 32, outline="thick")
        with self.assertRaises(ValueError):
            pixellab_api.call("x", 64, 64, "gpt-image-2")


class KeyTest(unittest.TestCase):
    def test_missing_key_message_names_the_variable(self):
        with mock.patch.dict(os.environ, {}, clear=True):
            with self.assertRaisesRegex(RuntimeError, "OPENAI_API_KEY"):
                http.key("OPENAI_API_KEY")
