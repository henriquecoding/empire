"""A auditoria de 26/10 (A02-A10): o que rebentava, o que se calava e o que chegava errado ao gerador.

A01 (a ampliacao exata fora de fase) esta em test_gridcheck. Cenarios e antes/depois:
docs/art/research/2026-10-26-forja-auditoria/.
"""
import io
import json
import os
import unittest
from pathlib import Path
from unittest import mock

from PIL import Image

from tools.forja import cli, cmd_ai, jobs, masks, mcp_server
from tools.forja.backends import http, pixellab_api
from tools.forja.tests.helpers import framed, tempdir
from tools.forja.tests.test_backends import B64, ENV, Fake
from tools.forja.tests.test_plan import answer, args

NO_WAIT = {"sleep": lambda _: None}


@mock.patch.dict(os.environ, ENV)
class EmptyAndStopTest(unittest.TestCase):
    """A02 e A03: uma imagem sem figura nao rebenta o ciclo pago, e o resultado diz o que foi forjado."""

    def test_an_empty_sheet_asks_for_another_generation(self):
        d = tempdir()
        Image.new("RGBA", (640, 320), (255, 0, 255, 255)).save(d / "vazia.png")
        res = cli.run(["sheet", str(d / "vazia.png"), "--kind", "royal_64", "--layout", "4x2", "--tags", "walk",
                       "-o", str(d / "out")])
        self.assertEqual(res["found"], 0)
        self.assertTrue(res["review"]["needs_regeneration"])
        self.assertIn("exactly 8 separate poses", res["prompt_feedback"])
        self.assertTrue(Path(res["files"]["forja_json"]).exists())

    def test_auto_survives_blank_generations_and_corrects_the_prompt(self):
        d = tempdir()
        a = args("comic knight", "-o", str(d / "run"), "--backend", "openai", "--kind", "royal_64", "--tags",
                 "walk:8", "--attempts", "2")
        w, h = cmd_ai._plan(a).data["expect"]["size"]
        blank = Image.new("RGBA", (w, h))
        fake = Fake(answer("openai", blank), answer("openai", blank))
        res = cmd_ai.do_auto(a, fake, **NO_WAIT)
        self.assertEqual(len(fake.requests), 2)
        self.assertEqual([x["review"]["needs_regeneration"] for x in res["attempts"]], [True, True])
        self.assertIn(b"no figure at all", fake.requests[1].body)
        self.assertTrue((d / "run" / "auto.json").exists())

    def test_a_stop_after_a_forged_attempt_still_reports_it(self):
        d = tempdir()
        a = args("comic knight", "-o", str(d / "run"), "--backend", "openai", "--kind", "royal_64", "--attempts",
                 "3", "--max-calls", "1")
        wrong = framed(2, (64, 64), (32, 62)).resize((1024, 1024), Image.NEAREST)
        res = cmd_ai.do_auto(a, Fake(answer("openai", wrong)), **NO_WAIT)
        self.assertFalse(res["ok"])
        self.assertEqual(Path(res["best"]).name, "try1")
        self.assertIsNotNone(res["review"])
        self.assertIn("teto", res["stopped"])
        self.assertIn("ainda pede outra geracao", res["next"])
        self.assertEqual([j["state"] for j in jobs.listing(d / "run")], ["completed"])

    def test_a_forja_error_keeps_the_paid_image_and_stops(self):
        d = tempdir()
        a = args("comic knight", "-o", str(d / "run"), "--backend", "openai", "--kind", "royal_64", "--attempts", "3")
        fine = framed(2, (64, 64), (32, 62)).resize((1920, 1920), Image.NEAREST)
        fake = Fake(answer("openai", fine), answer("openai", fine))
        with mock.patch("tools.forja.auto.forge_attempt", side_effect=RuntimeError("defeito da forja")):
            res = cmd_ai.do_auto(a, fake, **NO_WAIT)
        self.assertEqual(len(fake.requests), 1)
        self.assertIn("defeito da forja", res["attempts"][0]["error"])
        self.assertTrue(Path(res["attempts"][0]["image"]).exists())
        self.assertTrue((d / "run" / "auto.json").exists())


@mock.patch.dict(os.environ, ENV)
class BudgetResumeTest(unittest.TestCase):
    """A04: o custo de um job retomado por `forja jobs --resume` entra no teto da pasta."""

    def setUp(self):
        self.enterContext(mock.patch.dict(os.environ, ENV))
        self.d = tempdir()
        self.budget = jobs.Budget.open(self.d, 3, 1.0)
        call = pixellab_api.call("knight", 64, 64)
        self.job = jobs.create(call, self.d)
        with self.assertRaises(jobs.Timeout):
            jobs.execute(self.job, call, Fake((200, {"background_job_id": "J1"}),
                                              (200, {"status": "processing", "last_response": {}})),
                         poll=pixellab_api.poll_call, budget=self.budget, max_polls=1, **NO_WAIT)

    def resume(self, *answers) -> dict:
        with mock.patch.object(http, "urllib_transport", Fake(*answers)):
            return cli.run(["jobs", str(self.d), "--resume", self.job.id, "--deadline", "30"])

    def saved(self) -> dict:
        return json.loads((self.d / "budget.json").read_text())

    def test_the_resumed_cost_is_added(self):
        done = {"status": "completed", "last_response": {"image": {"type": "base64", "base64": B64},
                                                         "usage": {"type": "usd", "usd": 0.25}}}
        self.assertEqual(self.resume((200, done))["job"]["state"], "completed")
        self.assertEqual((self.saved()["calls"], self.saved()["usd"]), (1, 0.25))

    def test_a_failed_job_closes_as_unknown_cost(self):
        res = self.resume((200, {"status": "failed", "last_response": {"error": "gpu"}}))
        self.assertFalse(res["ok"])
        self.assertEqual(self.saved()["unknown_cost_calls"], 1)


@mock.patch.dict(os.environ, ENV)
class CorrectiveTest(unittest.TestCase):
    """A05: o que o gerador le no prompt corretivo e ingles e diz a medida."""

    def test_the_grid_hint_reaches_the_generator_in_english(self):
        d = tempdir()
        a = args("comic knight", "-o", str(d / "run"), "--backend", "gemini", "--kind", "royal_64", "--attempts", "2")
        exp = cmd_ai._plan(a).data["expect"]
        from tools.forja import color, synth
        canvas = Image.new("RGBA", (128, 128), (*color.parse_hex(exp["background"]), 255))
        canvas.alpha_composite(synth.sprite(3, (40, 100)), (44, 20))
        image = canvas.resize((512, 512), Image.NEAREST)
        fake = Fake(answer("gemini", image), answer("gemini", image))
        cmd_ai.do_auto(a, fake, **NO_WAIT)
        text = json.loads(fake.requests[1].body)["input"][0]["text"].split("(follow strictly):")[1]
        self.assertNotIn("grade detetada", text)
        self.assertIn("Use exactly 64x64 logical pixels for the whole image", text)
        self.assertIn("about 8x8 image pixels, not 4x4", text)
        self.assertIn("at most 62 pixels tall", text)
        self.assertNotIn("1-62", text)

    def test_a_size_mismatch_says_the_size(self):
        d = tempdir()
        a = args("comic knight", "-o", str(d / "run"), "--backend", "openai", "--kind", "royal_64", "--attempts", "2")
        wrong = framed(2, (64, 64), (32, 62)).resize((1024, 1024), Image.NEAREST)
        fake = Fake(answer("openai", wrong), answer("openai", wrong))
        cmd_ai.do_auto(a, fake, **NO_WAIT)
        self.assertIn(b"The image must be exactly 1920x1920 pixels.", fake.requests[1].body)


def two_cells(spear: range, k: int = 7) -> tuple[Image.Image, Image.Image, Image.Image]:
    """Duas figuras em celulas de 40x40 logicos e uma lanca de 2 px da figura 0 pelas colunas `spear`."""
    from tools.forja import synth
    canvas = Image.new("RGBA", (80, 40), (0, 0, 255, 255))
    a, b = synth.sprite(1, (16, 30)), synth.sprite(2, (16, 30))
    canvas.alpha_composite(a, (12, 8))
    canvas.alpha_composite(b, (52, 8))
    for x in spear:
        canvas.putpixel((x, 20), (0, 0, 0, 255))
        canvas.putpixel((x, 21), (160, 160, 170, 255))
    first = Image.new("RGBA", canvas.size)
    first.alpha_composite(a, (12, 8))
    for x in spear:
        first.putpixel((x, 20), (0, 0, 0, 255))
        first.putpixel((x, 21), (160, 160, 170, 255))
    crop = lambda im: im.crop(im.getchannel("A").getbbox())  # noqa: E731
    return canvas.resize((80 * k, 40 * k), Image.NEAREST), crop(first), crop(b)


class CellCrossingTest(unittest.TestCase):
    """A08: o que passa a fronteira da celula volta a figura dona; o que fica dividido diz-se."""

    def forge(self, image: Image.Image) -> dict:
        d = tempdir()
        image.save(d / "p.png")
        res = cli.run(["sheet", str(d / "p.png"), "--layout", "2x1", "--tags", "anim:2", "--bg", "#0000FF",
                       "-o", str(d / "o")])
        return json.loads(Path(res["files"]["forja_json"]).read_text())

    def test_a_spear_tip_goes_back_to_its_owner(self):
        image, first, second = two_cells(range(26, 46))
        from tools.forja import cells, sheet
        boxes, masks, crossed = cells.split(image, (0, 0, 255), (2, 1))
        self.assertEqual([c["action"] for c in crossed], ["reassigned"])
        figures = sheet.extract(image, boxes, (0, 0, 255), masks=masks, exact=True)
        self.assertEqual(figures[0].native.tobytes(), first.tobytes())
        self.assertEqual(figures[1].native.tobytes(), second.tobytes())
        full = self.forge(image)
        self.assertEqual(full["frames"][0]["cell_crossing"][0]["from"], [1])
        self.assertNotIn("cell_crossing", full["frames"][1])
        self.assertIn("inside its own cell", full["prompt_feedback"])

    def test_figures_that_touch_are_cut_at_the_line_and_reported(self):
        image, _, _ = two_cells(range(26, 54))  # a lanca toca a figura 1: uma mancha dividida pelas duas celulas
        full = self.forge(image)
        self.assertEqual([f["cell_crossing"][0]["action"] for f in full["frames"]], ["split", "split"])
        self.assertTrue(all(f["lint_warnings"] for f in full["frames"]))

    def test_figures_inside_their_cells_report_nothing(self):
        image, _, _ = two_cells(range(26, 34))
        full = self.forge(image)
        self.assertFalse(any("cell_crossing" in f for f in full["frames"]))


class SurfaceTest(unittest.TestCase):
    """A06, A07 e A09: o que o agente passa e o que recebe, pelo MCP e pela linha de comandos."""

    def test_mcp_repeats_a_box_for_each_item(self):
        prop = {t["name"]: t for t in mcp_server.tools()}["forja_sheet"]["inputSchema"]["properties"]["static"]
        self.assertEqual(prop["type"], "array")
        argv = mcp_server._argv("forge", {"image": "x.png", "out": "o", "protect": ["1,1,3,3", "5,5,7,7"]})
        self.assertEqual(argv[-4:], ["--protect", "1,1,3,3", "--protect", "5,5,7,7"])
        self.assertEqual(mcp_server._argv("forge", {"image": "x.png", "out": "o", "protect": "1,1,3,3"})[-2:],
                         ["--protect", "1,1,3,3"])

    def test_mcp_forge_with_two_protected_boxes(self):
        d = tempdir()
        from tools.forja.tests.test_pipeline_cli import fake_file
        res = mcp_server.call("forja_forge", {"image": str(fake_file(d)), "out": str(d / "o"),
                                              "protect": ["1,1,3,3", "5,5,7,7"]})
        self.assertFalse(res["isError"], res["content"][0]["text"][:300])
        forged = json.loads(next((d / "o").glob("*.json")).read_text())
        self.assertEqual(forged["finish"]["protect"]["boxes"], [[1, 1, 3, 3], [5, 5, 7, 7]])

    def test_a_mask_without_alpha_marks_its_white_pixels(self):
        d = tempdir()
        white = Image.new("L", (16, 16), 0)
        white.paste(255, (2, 2, 5, 5))
        white.save(d / "l.png")
        white.convert("RGBA").save(d / "opaque.png")
        cut = Image.new("RGBA", (16, 16))
        cut.paste((0, 0, 0, 255), (2, 2, 5, 5))
        cut.save(d / "alpha.png")
        sprite = Image.new("RGBA", (16, 16), (200, 50, 50, 255))
        want = masks.box((2, 2, 5, 5))
        for name in ("l.png", "opaque.png", "alpha.png"):
            self.assertEqual(masks.select(sprite, {"mask": name}, d), want, name)

    def test_a_file_that_is_not_an_image_is_a_json_error(self):
        d = tempdir()
        (d / "x.png").write_text("nao sou png")
        out = io.StringIO()
        with mock.patch("sys.stdout", out):
            code = cli.main(["lint", str(d / "x.png")])
        self.assertEqual(code, 2)
        self.assertFalse(json.loads(out.getvalue())["ok"])


if __name__ == "__main__":
    unittest.main()
