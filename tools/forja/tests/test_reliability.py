"""Regressoes de contratos remotos e do transporte MCP, sem credenciais reais."""
import io
import json
import os
import unittest
from unittest import mock

from tools.forja import cli, mcp_server, prompts
from tools.forja.backends import http, pixellab_api
from tools.forja.tests.test_backends import B64, ENV, Fake, png


class TransportRegressionTest(unittest.TestCase):
    def test_nested_data_array_is_not_discarded(self):
        self.assertEqual(http.find_images({"data": [{"b64_json": B64}]}), [png()])

    def test_uncertain_post_failure_is_not_replayed(self):
        fake = Fake((502, {"error": "upstream"}), (200, {}))
        with self.assertRaises(http.ApiError):
            http.send(http.json_request("POST", "https://example.test", {}, {}), fake, sleep=lambda _: None)
        self.assertEqual(len(fake.requests), 1)

    def test_error_body_cannot_echo_secret(self):
        req = http.json_request("POST", "https://example.test", {}, {"Authorization": "Bearer private-test-key"})
        with self.assertRaises(http.ApiError) as caught:
            http.send(req, Fake((400, {"error": "Bearer private-test-key"})))
        self.assertNotIn("private-test-key", str(caught.exception))

    def test_native_prompt_uses_native_dimensions(self):
        result = prompts.build("a squire", "royal_64", target="pixellab")
        self.assertEqual(result["expect"]["scale"], 1)
        self.assertEqual(result["size"], "64x64")
        self.assertEqual(result["expect"]["background"], "transparent")

    def test_scenery_outline_is_one_logical_pixel_before_cluster_expansion(self):
        result = prompts.build("a house", "building", target="pixellab")
        self.assertIn("a 1-logical-pixel", result["prompt"])


@mock.patch.dict(os.environ, ENV)
class PixelLabRegressionTest(unittest.TestCase):
    def test_impossible_canvas_is_refused_before_transport(self):
        fake = Fake((200, {"image": {"base64": B64}}))
        with self.assertRaises(ValueError):
            pixellab_api.generate("x", 1024, 1024, transport=fake)
        self.assertFalse(fake.requests)

    def test_pixen_cannot_silently_discard_reference(self):
        with self.assertRaises(ValueError):
            pixellab_api.payload("x", 64, 64, "pixen", init_image=png())

    def test_empty_success_is_an_error(self):
        with self.assertRaises(http.ApiError):
            pixellab_api.generate("x", transport=Fake((200, {})))

    def test_invalid_parameter_types_are_rejected(self):
        for kw in ({"init_image_strength": 1.5}, {"text_guidance_scale": float("nan")},
                   {"seed": True}, {"no_background": "false"}):
            with self.subTest(kw=kw), self.assertRaises(ValueError):
                pixellab_api.payload("x", 64, 64, **kw)

    def test_failed_job_error_is_sanitized(self):
        fake = Fake((200, {"background_job_id": "job1"}),
                    (200, {"status": "failed", "last_response": {"detail": "p-test secret"}}))
        with self.assertRaises(http.ApiError) as caught:
            pixellab_api.generate("x", transport=fake)
        self.assertNotIn("p-test", str(caught.exception))


class McpRegressionTest(unittest.TestCase):
    def setUp(self):
        cli.build_parser()

    def test_list_files_response_does_not_crash_preview(self):
        with mock.patch.object(cli, "run", return_value={"ok": True, "files": ["missing.png"]}):
            result = mcp_server.call("forja_generate", {"prompt": "x", "out": "build/forja/test"})
        self.assertFalse(result["isError"])
        self.assertEqual(result["structuredContent"]["files"], ["missing.png"])

    def test_failed_verdict_is_a_tool_error(self):
        with mock.patch.object(cli, "run", return_value={"ok": False, "findings": ["clipped"]}):
            result = mcp_server.call("forja_lint", {"image": "x.png"})
        self.assertTrue(result["isError"])

    def test_unknown_argument_does_not_get_ignored(self):
        result = mcp_server.call("forja_kinds", {"typo": True})
        self.assertTrue(result["isError"])

    def test_invalid_message_does_not_kill_server(self):
        stream = io.StringIO('[]\n{"jsonrpc":"2.0","id":2,"method":"ping"}\n')
        out = io.StringIO()
        mcp_server.serve(stream, out)
        replies = [json.loads(line) for line in out.getvalue().splitlines()]
        self.assertEqual(replies[0]["error"]["code"], -32600)
        self.assertEqual(replies[1]["result"], {})

    def test_invalid_params_do_not_kill_server(self):
        for params in ([1], {"name": 3}, {"name": "forja_kinds", "arguments": [1]}):
            result = mcp_server.handle({"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": params})
            self.assertEqual(result["error"]["code"], -32602)

    def test_string_false_cannot_enable_a_boolean_option(self):
        with mock.patch.object(cli, "run") as run:
            result = mcp_server.call("forja_auto", {"subject": "x", "out": "x", "dry_run": "false"})
        self.assertTrue(result["isError"])
        run.assert_not_called()
