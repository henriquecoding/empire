import io
import json
import unittest
from pathlib import Path

from PIL import Image

from tools.forja import cli, inpaint, mcp_server, pipeline, prompts, sheetforge, synth
from tools.forja.tests.helpers import framed, sprite, tempdir


def fake_file(d: Path, seed: int = 5, bg=(0, 0, 255)) -> Path:
    big, _, _ = synth.fake(sprite(seed, (24, 34)), 14.7, 1.3, 1.0, 7, bg, 3, seed)
    path = d / "fake.png"
    big.save(path)
    return path


class PipelineTest(unittest.TestCase):
    def test_forge_meets_character_contract(self):
        d = tempdir()
        res = pipeline.forge(fake_file(d), d / "out", pipeline.Options(kind="character_s1"), aseprite=True)
        self.assertTrue(res["lint"]["ok"], res["lint"]["findings"])
        with Image.open(res["files"]["png"]) as final:
            self.assertEqual(final.size, (64, 64))
        self.assertTrue(Path(res["files"]["report"]).read_text().startswith("<!doctype html>"))
        self.assertFalse(res["provenance"]["state"]["artistic_approval"])
        self.assertIn("aseprite", res["files"])

    def test_figure_too_big_is_refused_not_shrunk(self):
        d = tempdir()
        big, _, _ = synth.fake(sprite(5, (30, 62)), 12.0, 0.5, 0.6, 4, (0, 0, 255), 3, 5)
        big.save(d / "big.png")
        res = pipeline.forge(d / "big.png", d / "out", pipeline.Options(kind="character_s1"), report_html=False)
        rules = {f["rule"] for f in res["lint"]["findings"]}
        self.assertIn("clipped", rules)
        self.assertFalse(res["lint"]["ok"])
        self.assertIn("Draw the figure smaller", res["lint"]["prompt_feedback"])

    def test_sheet_counts_and_exports(self):
        d = tempdir()
        truths = [synth.sprite(40 + i, (24, 31)) for i in range(6)]
        synth.sheet(truths, 3, 8.1, bg=(0, 0, 255)).save(d / "sheet.png")
        res = sheetforge.forge_sheet(d / "sheet.png", d / "out", pipeline.Options(kind="character_s1"),
                                     sheetforge.SheetOptions(tags=[("idle", 6)], mirror=True,
                                                             godot_texture="res://idle.png"))
        self.assertEqual((res["requested"], res["found"]), (6, 6))
        for key in ("sheet", "json", "aseprite", "gif", "godot", "left_sheet", "report"):
            self.assertTrue(Path(res["files"][key]).exists(), key)
        self.assertEqual(res["metrics"]["max_drift"], 0)

    def test_sheet_reports_missing_frames_without_inventing(self):
        d = tempdir()
        truths = [synth.sprite(60 + i, (24, 31)) for i in range(5)]
        synth.sheet(truths, 3, 8.1, bg=(0, 0, 255)).save(d / "sheet.png")
        res = sheetforge.forge_sheet(d / "sheet.png", d / "out", pipeline.Options(kind="character_s1"),
                                     sheetforge.SheetOptions(tags=[("idle", 6)]))
        self.assertEqual((res["requested"], res["found"], res["ok"]), (6, 5, False))
        self.assertIn("exactly 6 separate poses", res["prompt_feedback"])


class PromptTest(unittest.TestCase):
    def test_build_respects_gpt_image_sizes(self):
        res = prompts.build("a squire with a wooden shield", "character_s1", [("walk", 8)])
        w, h = (int(v) for v in res["size"].split("x"))
        self.assertEqual((w % 16, h % 16), (0, 0))
        self.assertEqual(res["expect"]["layout"], [4, 2])
        self.assertEqual(res["expect"]["cells"], [256, 128])
        self.assertIn("contact poses on frames 1 and 5", res["prompt"])
        self.assertEqual(res["pixellab"]["outline"], "single color black outline")

    def test_scenery_cells_follow_cluster(self):
        res = prompts.build("stone well", "tile", target="gemini")
        self.assertEqual(res["expect"]["cells"], [16, 16])
        self.assertIn("chroma key", res["prompt"])

    def test_corrective(self):
        self.assertIn("Corrections", prompts.corrective("p", "No stray pixels."))


class InpaintTest(unittest.TestCase):
    def test_outside_box_is_identical(self):
        native = framed(3)
        image, mask, k, size, key = inpaint.prepare(native, (24, 20, 40, 32), "#0000FF")
        with Image.open(io.BytesIO(image)) as im:
            result = im.convert("RGBA")
        result.paste((200, 30, 30, 255), (24 * k, 20 * k, 40 * k, 32 * k))
        out, info = inpaint.merge(native, result, k, (24, 20, 40, 32), key="#0000FF")
        self.assertTrue(info["outside_identical"])
        self.assertGreater(info["changed_pixels"], 0)
        with Image.open(io.BytesIO(mask)) as im:
            alpha = im.getchannel("A")
        self.assertEqual(alpha.getpixel((24 * k, 20 * k)), 0)
        self.assertEqual(alpha.getpixel((0, 0)), 255)


class CliTest(unittest.TestCase):
    def test_kinds_and_prompt_files(self):
        self.assertIn("character_s2", cli.run(["kinds"])["kinds"])
        d = tempdir()
        res = cli.run(["prompt", "a fox", "-o", str(d), "--kind", "creature", "--tags", "idle"])
        for key in ("prompt", "expect", "layout", "palette"):
            self.assertTrue(Path(res["files"][key]).exists(), key)

    def test_forge_with_expect_scale(self):
        d = tempdir()
        exp = {"kind": "character_s1", "scale": 14.7, "layout": [1, 1], "background": "#0000FF"}
        (d / "expect.json").write_text(json.dumps(exp))
        res = cli.run(["forge", str(fake_file(d)), "-o", str(d / "o"), "--expect", str(d / "expect.json")])
        self.assertTrue(res["ok"], res["findings"])


class McpTest(unittest.TestCase):
    def talk(self, *messages):
        out = io.StringIO()
        mcp_server.serve(io.StringIO("\n".join(json.dumps(m) for m in messages) + "\n"), out)
        return [json.loads(line) for line in out.getvalue().splitlines()]

    def test_handshake_list_and_call(self):
        d = tempdir()
        path = fake_file(d)
        replies = self.talk(
            {"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2025-06-18"}},
            {"jsonrpc": "2.0", "method": "notifications/initialized"},
            {"jsonrpc": "2.0", "id": 2, "method": "tools/list"},
            {"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "forja_forge", "arguments": {
                "image": str(path), "out": str(d / "o"), "kind": "character_s1"}}},
            {"jsonrpc": "2.0", "id": 4, "method": "nope"})
        self.assertEqual(len(replies), 4)
        self.assertEqual(replies[0]["result"]["protocolVersion"], "2025-06-18")
        names = {t["name"] for t in replies[1]["result"]["tools"]}
        self.assertTrue({"forja_forge", "forja_sheet", "forja_prompt", "forja_lint", "forja_tileset"} <= names)
        forge = next(t for t in replies[1]["result"]["tools"] if t["name"] == "forja_forge")
        self.assertEqual(forge["inputSchema"]["required"], ["image", "out"])
        call = replies[2]["result"]
        self.assertFalse(call["isError"], call)
        self.assertEqual([c["type"] for c in call["content"]], ["text", "image"])
        self.assertEqual(replies[3]["error"]["code"], -32601)

    def test_bad_arguments_return_error_content(self):
        result = mcp_server.call("forja_forge", {"image": "missing.png"})
        self.assertTrue(result["isError"])
