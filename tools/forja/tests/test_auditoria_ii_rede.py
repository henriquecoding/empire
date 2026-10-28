"""A auditoria tecnica de 27/10, FORJA-08 (B01, B03, B04, B09-B12): a imagem paga certa, o teto entre processos, o registo no disco e
o servidor MCP que nao morre. Os testes da imagem estao em test_auditoria_ii.
"""
import base64
import io
import json
import os
import subprocess
import sys
import unittest
from pathlib import Path
from unittest import mock

from PIL import Image

from tools.forja import cli, durable, jobs, mcp_server
from tools.forja.backends import gemini_images
from tools.forja.tests.helpers import tempdir
from tools.forja.tests.test_backends import ENV, Fake, png

DRAFT, FINAL = png((200, 10, 10, 255)), png((10, 200, 10, 255))
ROOT = Path(__file__).resolve().parents[3]


def b64(data: bytes) -> str:
    return base64.b64encode(data).decode()


@mock.patch.dict(os.environ, ENV)
class GeminiThoughtTest(unittest.TestCase):
    """B01: as imagens de pensamento (rascunhos nao cobrados) nao sao a imagem paga."""

    def test_interactions_keep_only_the_final_image(self):
        body = {"steps": [{"type": "thought", "summary": [{"type": "image", "data": b64(DRAFT), "mime_type": "image/png"}]},
                          {"type": "model_output", "content": [{"type": "image", "data": b64(FINAL),
                                                                "mime_type": "image/png"}]}],
                "output_image": {"data": b64(FINAL), "mime_type": "image/png"}}
        r = gemini_images.parse(body)
        self.assertEqual(r.images, [FINAL])
        self.assertEqual(r.detail["thought_images_skipped"], 1)

    def test_generate_content_skips_thought_parts(self):
        body = {"candidates": [{"content": {"parts": [
            {"inlineData": {"mimeType": "image/png", "data": b64(DRAFT)}, "thought": True},
            {"text": "here"}, {"inlineData": {"mimeType": "image/png", "data": b64(FINAL)}}]}}]}
        self.assertEqual(gemini_images.parse(body).images, [FINAL])

    def test_the_job_stores_the_final_image_first(self):
        d = tempdir()
        body = {"steps": [{"type": "thought", "summary": [{"type": "image", "data": b64(DRAFT), "mime_type": "image/png"}]},
                          {"type": "model_output", "content": [{"type": "image", "data": b64(FINAL),
                                                                "mime_type": "image/png"}]}]}
        res = gemini_images.generate("knight", transport=Fake((200, body)), folder=d)
        self.assertEqual(res["images"], [FINAL])
        self.assertEqual(len(res["job"]["outputs"]), 1)


class BudgetTest(unittest.TestCase):
    """B03 e B09: o teto conta entre processos, e o registo fica no disco antes do POST."""

    def test_two_processes_on_one_folder_cannot_pass_the_cap(self):
        d = tempdir()
        first, second = jobs.Budget.open(d, 1), jobs.Budget.open(d, 1)  # dois processos, abertos antes de gastar
        first.reserve()
        with self.assertRaises(jobs.BudgetExceeded):
            second.reserve()
        self.assertEqual(json.loads((d / "budget.json").read_text())["calls"], 1)

    def test_settle_adds_to_what_another_process_wrote(self):
        d = tempdir()
        a, b = jobs.Budget.open(d, 5), jobs.Budget.open(d, 5)
        a.reserve()
        b.reserve()
        a.settle(0.25)
        b.settle(None)
        saved = json.loads((d / "budget.json").read_text())
        self.assertEqual((saved["calls"], saved["usd"], saved["unknown_cost_calls"]), (2, 0.25, 1))

    def test_records_are_synced_and_swapped_whole(self):
        d = tempdir()
        with mock.patch("tools.forja.durable.os.fsync", wraps=os.fsync) as sync:
            durable.write_text(d / "x.json", "{}\n")
        self.assertGreaterEqual(sync.call_count, 1)
        self.assertEqual([p.name for p in d.iterdir()], ["x.json"])

    def test_a_held_lock_times_out_as_an_os_error(self):
        d = tempdir()
        with durable.locked(d / "budget.json"):
            with self.assertRaises(OSError):
                with mock.patch("tools.forja.durable.time.sleep"), durable.locked(d / "budget.json", timeout=0.0):
                    pass


class McpTest(unittest.TestCase):
    """B04, B10, B11, B12: nada do que chega derruba o servidor; cada ferramenta diz o que faz antes de ser chamada."""

    def serve(self, *lines, raw: bool = False) -> list[dict]:
        out = io.StringIO()
        data = "".join(line + "\n" for line in lines)
        mcp_server.serve(io.BytesIO(data.encode("utf-8")) if raw else io.StringIO(data), out)
        return [json.loads(x) for x in out.getvalue().splitlines()]

    def test_non_objects_and_batches_are_errors_and_the_server_lives(self):
        got = self.serve("[]", '[{"jsonrpc":"2.0","id":1,"method":"ping"}]', "42", '"x"', "{nope",
                         '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":[1]}',
                         '{"jsonrpc":"2.0","id":3,"method":"ping"}')
        self.assertEqual([g.get("error", {}).get("code") for g in got], [-32600, -32600, -32600, -32600, -32700,
                                                                          -32602, None])
        self.assertEqual(got[-1], {"jsonrpc": "2.0", "id": 3, "result": {}})

    def test_an_unknown_tool_is_a_protocol_error(self):
        got = self.serve('{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"forja_nada"}}')
        self.assertEqual(got[0]["error"]["code"], -32602)

    def test_a_cp1252_pipe_still_reads_utf8(self):
        """O servidor como arranca no Windows: o pipe na pagina de codigo da consola, o cliente em UTF-8. O "A" de
        "Arvore" com acento e C3 81, e 0x81 nao existe no cp1252: antes, o servidor morria a ler."""
        folder = tempdir() / "cenários"
        folder.mkdir()
        Image.new("RGBA", (64, 64)).save(folder / "Árvore.png")
        msgs = [{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {
            "name": "forja_lint", "arguments": {"image": str(folder / "Árvore.png"), "kind": "royal_64"}}},
            {"jsonrpc": "2.0", "id": 2, "method": "ping"}]
        data = "".join(json.dumps(m, ensure_ascii=False) + "\n" for m in msgs).encode("utf-8")
        r = subprocess.run([sys.executable, "-m", "tools.forja", "mcp"], input=data, capture_output=True, timeout=120,
                           cwd=ROOT, env={**os.environ, "PYTHONIOENCODING": "cp1252", "PYTHONUTF8": "0"})
        replies = [json.loads(x) for x in r.stdout.decode("utf-8").split("\n") if x.strip()]
        self.assertEqual([x["id"] for x in replies], [1, 2])
        self.assertEqual(json.loads(replies[0]["result"]["content"][0]["text"])["kind"], "royal_64")

    def test_the_preview_stays_in_content_without_structured_content(self):
        call = '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"forja_kinds","arguments":{}}}'
        got = self.serve('{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25"}}', call)
        self.assertEqual(got[0]["result"]["protocolVersion"], "2025-11-25")
        self.assertNotIn("structuredContent", got[1]["result"])
        self.assertTrue(json.loads(got[1]["result"]["content"][0]["text"])["ok"])

    def test_paid_tools_are_marked_open_world_and_not_idempotent(self):
        tools = {t["name"]: t for t in mcp_server.tools()}
        self.assertEqual(tools["forja_generate"]["annotations"],
                         {"readOnlyHint": False, "destructiveHint": False, "idempotentHint": False,
                          "openWorldHint": True})
        self.assertTrue(tools["forja_lint"]["annotations"]["readOnlyHint"])
        self.assertTrue(all(t["title"] for t in tools.values()))

    def test_a_call_without_the_cli_registry_built(self):
        with mock.patch.dict(cli.REGISTRY, clear=True):
            self.assertFalse(mcp_server.call("forja_kinds", {})["isError"])


if __name__ == "__main__":
    unittest.main()
