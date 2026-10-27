"""A solucao de 27/10 (FORJA-06): a autoridade das referencias (§7.1), o pedido contra o retorno nos dois caminhos
(§7.2), a edicao local presa ao mestre registado (§7.3) e o encerramento que nao chama aprovacao a uma evidencia de
ficheiro (§7.6). As fixtures sao os sprites REJEITADOS do pacote: passam no lint e continuam rejeitados.
"""
import io
import json
import unittest
from pathlib import Path
from unittest import mock

from PIL import Image, ImageDraw

from tools.forja import cli, equipment, inpaint, masks, palette as palmod, plan, refs, synth, verdicts
from tools.forja.tests.helpers import framed, tempdir
from tools.forja.tests.test_plan import drawn_sheet

FIXTURES = Path(__file__).resolve().parents[3] / "docs/art/research/2026-10-27-forja-fidelidade/fixtures"
CASES = {"rei": ((35, 21, 50, 35), (24, 63, 39, 78)), "arqueiro": ((38, 23, 49, 38), (54, 17, 68, 76)),
         "escudeiro": ((35, 29, 43, 40), (6, 49, 24, 61))}
OWNER = {"decided_by": "Henrique", "date": "2026-10-27"}


def fixture(name: str) -> Image.Image:
    return Image.open(FIXTURES / f"{name}.png").convert("RGBA")


def register(folder: Path, *entries) -> Path:
    """Um registo forja.refs/1 a partir de (id, imagem, estado, campos extra)."""
    for ident, image, _, _ in entries:
        image.save(folder / f"{ident}.png")
    rows = [{"id": i, "file": f"{i}.png", "pixels_sha256": equipment.image_sha(im), "state": s, **extra}
            for i, im, s, extra in entries]
    (folder / "refs.json").write_text(json.dumps({"schema": refs.SCHEMA, "entries": rows}), encoding="utf-8")
    return folder / "refs.json"


def echo(_prompt, images, *_a, **_kw):
    return {"images": [images[0]], "model": "synthetic/echo", "job": {"id": "local"}}


class AuthorityTest(unittest.TestCase):
    """§7.1: uma referencia em revisao, sem registo ou rejeitada nao e chamada aprovada pelo prompt."""

    def test_an_unrecorded_reference_is_not_called_approved(self):
        d = tempdir()
        framed(5, (80, 80), (40, 78)).save(d / "ref.png")
        p = plan.make("openai", "comic king", "royal_80", references=[("identity", str(d / "ref.png"))])
        self.assertNotIn("APPROVED", p.data["prompt"])
        self.assertIn("approval is NOT recorded", p.data["prompt"])
        self.assertEqual(p.data["references"][0]["state"], "unrecorded")
        self.assertEqual(p.data["authority"]["stage"], "recovery")

    def test_the_register_decides_the_words_and_a_rejected_file_never_goes(self):
        d = tempdir()
        reg = refs.load(register(d, ("mestre", framed(5, (80, 80), (40, 78)), "approved", OWNER),
                                 ("adaptacao", framed(6, (80, 80), (40, 78)), "adaptation_in_review", {}),
                                 ("conceito", framed(7, (80, 80), (40, 78)), "concept", {}),
                                 ("v2", framed(8, (80, 80), (40, 78)), "rejected", {**OWNER, "reason": "rosto"})))
        made = {name: plan.make("openai", "comic king", "royal_80", references=[("identity", str(d / f"{name}.png"))],
                                register=reg) for name in ("mestre", "adaptacao", "conceito", "v2")}
        self.assertIn("image 1: the APPROVED design", made["mestre"].data["prompt"])
        self.assertEqual(made["mestre"].data["authority"]["stage"], "from_master")
        self.assertIn("IN REVIEW and NOT approved", made["adaptacao"].data["prompt"])
        self.assertIn("CONCEPT ART", made["conceito"].data["prompt"])
        for name in ("adaptacao", "conceito"):
            self.assertNotIn("APPROVED", made[name].data["prompt"])
            self.assertEqual(made[name].data["authority"]["stage"], "recovery")
        self.assertEqual([a["role"] for a in made["conceito"].data["attachments"]], ["identity"])
        self.assertFalse(made["v2"].ok)
        self.assertIn("rejeitada", " ".join(made["v2"].data["errors"]))
        framed(9, (80, 80), (40, 78)).save(d / "solta.png")
        loose = plan.make("openai", "comic king", "royal_80", references=[("identity", str(d / "solta.png"))],
                          register=reg)
        self.assertIn("nao esta no registo", " ".join(loose.data["errors"]))

    def test_the_register_is_checked_and_an_approval_says_who_and_when(self):
        d = tempdir()
        img = framed(5, (80, 80), (40, 78))
        with self.assertRaisesRegex(ValueError, "decided_by"):
            refs.load(register(d, ("m", img, "approved", {})))
        reg = register(d, ("m", img, "adaptation_in_review", {}))
        img.transpose(Image.Transpose.FLIP_LEFT_RIGHT).save(d / "m.png")
        with self.assertRaisesRegex(ValueError, "mudou"):
            refs.load(reg)

    def test_refs_records_states_but_never_writes_an_approval(self):
        d = tempdir()
        framed(5, (80, 80), (40, 78)).save(d / "rei.png")
        reg = d / "refs.json"
        res = cli.run(["refs", str(reg), "--add", str(d / "rei.png"), "--state", "adaptation_in_review",
                       "--id", "rei-v3", "--by", "Claude"])
        self.assertTrue(res["ok"])
        self.assertEqual([e["state"] for e in res["entries"]], ["adaptation_in_review"])
        with self.assertRaisesRegex(ValueError, "dono"):
            cli.run(["refs", str(reg), "--add", str(d / "rei.png"), "--state", "approved", "--id", "rei-ok"])

    def test_prompt_names_the_state_of_what_will_be_attached(self):
        d = tempdir()
        base = ["prompt", "comic king", "--kind", "royal_80", "--reference"]
        review = cli.run([*base, "-o", str(d / "a"), "--reference-state", "adaptation_in_review"])
        self.assertIn("NOT approved", review["prompt"])
        self.assertNotIn("APPROVED", review["prompt"])
        self.assertIn("approval is NOT recorded", cli.run([*base, "-o", str(d / "b")])["prompt"])
        with self.assertRaisesRegex(ValueError, "registo"):
            cli.run([*base, "-o", str(d / "c"), "--reference-state", "approved"])
        reg = register(d, ("m", framed(5, (80, 80), (40, 78)), "approved", OWNER))
        ok = cli.run([*base, "-o", str(d / "e"), "--refs", str(reg), "--reference-file", str(d / "m.png")])
        self.assertIn("the APPROVED design", ok["prompt"])


class ExpectationTest(unittest.TestCase):
    """§7.2: o tamanho e a grade que chegaram, contra os pedidos, no forge e no sheet manuais como no auto."""

    def test_manual_forge_flags_a_size_that_was_not_requested(self):
        d = tempdir()
        cli.run(["prompt", "comic knight", "-o", str(d / "p"), "--kind", "royal_64"])
        framed(5, (64, 64), (32, 62)).resize((512, 512), Image.Resampling.NEAREST).save(d / "g.png")
        out = cli.run(["forge", str(d / "g.png"), "--expect", str(d / "p" / "expect.json"), "-o", str(d / "o")])
        self.assertEqual([f["code"] for f in out["expectation"]["findings"]], ["size_mismatch"])
        self.assertFalse(out["ok"])
        self.assertEqual(json.loads(Path(out["files"]["json"]).read_text())["expectation"]["hard"], ["size_mismatch"])

    def test_a_native_request_is_native_only_when_the_size_says_so(self):
        d = tempdir()
        (d / "expect.json").write_text(json.dumps(plan.make("pixellab", "comic knight", "royal_64").data["expect"]))
        framed(5, (64, 64), (32, 62)).resize((128, 128), Image.Resampling.NEAREST).save(d / "g.png")
        out = cli.run(["forge", str(d / "g.png"), "--expect", str(d / "expect.json"), "-o", str(d / "o")])
        self.assertIn("native_size_mismatch", [f["code"] for f in out["expectation"]["findings"]])
        self.assertLessEqual(max(out["native_size"]), 64)

    def test_manual_sheet_marks_the_review_like_the_closed_loop(self):
        d = tempdir()
        exp = plan.make("openai", "comic knight", "royal_64", [("walk", 4)]).data["expect"]
        (d / "expect.json").write_text(json.dumps(exp))
        drawn_sheet(exp, 8, [synth.sprite(s, (24, 34)) for s in range(4)]).save(d / "g.png")
        out = cli.run(["sheet", str(d / "g.png"), "--expect", str(d / "expect.json"), "-o", str(d / "o")])
        self.assertEqual(out["expectation"]["hard"], ["size_mismatch"])
        self.assertFalse(out["review"]["contract_valid"])
        self.assertTrue(out["review"]["needs_regeneration"])
        self.assertFalse(out["ok"])


class LocalEditTest(unittest.TestCase):
    """§7.3: a edicao local parte do mestre registado; fora da mascara e no rosto ficam os bytes do mestre."""

    def test_an_adverse_answer_cannot_touch_the_face_of_the_three_fixtures(self):
        master = palmod.load("empire")
        for name, (face, zone) in CASES.items():
            native, protected = fixture(name), masks.box(face)
            source, _, k, _, key = inpaint.prepare(native, zone, palette=master)
            adverse = Image.open(io.BytesIO(source)).convert("RGBA")
            draw = ImageDraw.Draw(adverse)
            for x, y in [p for p in sorted(protected) if native.getpixel(p)[3]][:5] + [(zone[0], zone[3] - 1)]:
                draw.rectangle((x * k, y * k, (x + 1) * k - 1, (y + 1) * k - 1), fill=(217, 124, 43, 255))
            out, info = inpaint.merge(native, adverse, k, zone, master, key, protect=protected)
            self.assertTrue(info["outside_identical"] and info["protected_identical"], name)
            self.assertEqual(masks.digest(out, protected), masks.digest(native, protected), name)
            self.assertEqual(out.getpixel((zone[0], zone[3] - 1)), (217, 124, 43, 255), name)

    def test_a_wrong_size_stops_the_edit_and_does_not_redraw_the_character(self):
        calls = []

        def wrong(_prompt, images, *_a, **_kw):
            calls.append(1)
            with Image.open(io.BytesIO(images[0])) as im:
                bigger = im.convert("RGBA").resize((im.width + 16, im.height))
            buf = io.BytesIO()
            bigger.save(buf, "PNG")
            return {"images": [buf.getvalue()], "model": "synthetic/wrong", "job": {"id": "job-1"}}

        with mock.patch("tools.forja.backends.openai_images.edit", side_effect=wrong):
            out, info = inpaint.run(fixture("rei"), (24, 63, 39, 78), "repair the blade",
                                    protect=masks.box((35, 21, 50, 35)))
        self.assertIsNone(out)
        self.assertEqual((info["stopped"], info["job"], len(calls)), ("size_mismatch", "job-1", 1))
        self.assertIn("so a zona", info["next"])

    def test_the_edit_is_bound_to_a_registered_master(self):
        d = tempdir()
        reg = register(d, ("rei-v2", fixture("rei"), "rejected", {**OWNER, "reason": "fixture rejeitada"}))
        framed(5, (80, 80), (40, 78)).save(d / "outro.png")
        args = ["--box", "24,63,39,78", "--change", "x", "--refs", str(reg), "-o", str(d / "e.png")]
        with mock.patch("tools.forja.backends.openai_images.edit", side_effect=echo) as sent:
            with self.assertRaisesRegex(ValueError, "rejeitad"):
                cli.run(["inpaint", str(d / "rei-v2.png"), *args])
            with self.assertRaisesRegex(ValueError, "registo"):
                cli.run(["inpaint", str(d / "outro.png"), *args])
        self.assertEqual(sent.call_count, 0)

    def test_an_echo_on_a_master_in_review_says_what_is_still_missing(self):
        d = tempdir()
        native = fixture("arqueiro")
        reg = register(d, ("arq", native, "adaptation_in_review", {}))
        with mock.patch("tools.forja.backends.openai_images.edit", side_effect=echo):
            res = cli.run(["inpaint", str(d / "arq.png"), "--box", "54,17,68,76", "--protect", "38,23,49,38",
                           "--change", "repair the bow", "--refs", str(reg), "--palette", "empire",
                           "-o", str(d / "c.png")])
        self.assertEqual(res["master"]["state"], "adaptation_in_review")
        self.assertEqual(res["master"]["pixels_sha256"], equipment.image_sha(native))
        self.assertEqual(Image.open(d / "c.png").convert("RGBA").tobytes(), native.tobytes())
        self.assertFalse(res["delivery"]["deliverable"])
        self.assertIn("artistic_approval", res["delivery"]["missing"])


class ClosureTest(unittest.TestCase):
    """§7.6 e §9: not_evaluated nao fecha uma entrega; so a aprovacao registada pelo dono, desta imagem, fecha."""

    def test_nothing_evaluated_never_closes(self):
        c = verdicts.closure(verdicts.summary(verdicts.initial()), {"status": "pending"})
        self.assertFalse(c["deliverable"])
        self.assertTrue({"raster_contract", "artistic_approval"} <= set(c["missing"]))
        self.assertIn("nao e aprovacao", c["note"])

    def test_verify_rereads_the_candidate_against_the_master(self):
        d = tempdir()
        fixture("rei").save(d / "m.png")
        cand = fixture("rei")
        cand.putpixel((30, 70), (217, 124, 43, 255))
        cand.save(d / "c.png")
        tail = ["--master", str(d / "m.png"), "--box", "24,63,39,78", "--protect", "35,21,50,35", "--kind", "royal_80"]
        res = cli.run(["verify", str(d / "c.png"), *tail])
        self.assertTrue(res["ok"])
        self.assertEqual((res["preservation"]["outside_identical"], res["preservation"]["changed_inside"]), (True, 1))
        self.assertFalse(res["deliverable"])
        self.assertEqual(res["closure"]["conditions"]["review_recorded"]["status"], "pending")
        cand.putpixel((40, 25), (0, 0, 0, 255))
        cand.save(d / "b.png")
        bad = cli.run(["verify", str(d / "b.png"), *tail])
        self.assertFalse(bad["ok"] or bad["preservation"]["protected_identical"])

    def test_the_owner_approval_closes_only_that_exact_image(self):
        d = tempdir()
        fixture("rei").save(d / "m.png")
        cand = fixture("rei")
        cand.putpixel((30, 70), (217, 124, 43, 255))
        reg = register(d, ("rei-c", cand, "approved", OWNER))
        tail = ["--master", str(d / "m.png"), "--box", "24,63,39,78", "--kind", "royal_80", "--refs", str(reg)]
        self.assertTrue(cli.run(["verify", str(d / "rei-c.png"), *tail])["deliverable"])
        cores = d / "cores.json"
        cores.write_text(json.dumps({"material": {"status": "pending", "conflicts": 9, "regions": ["blade"]}}))
        self.assertFalse(cli.run(["verify", str(d / "rei-c.png"), *tail, "--cores", str(cores)])["deliverable"])
        cand.putpixel((31, 70), (217, 124, 43, 255))
        cand.save(d / "c2.png")
        again = cli.run(["verify", str(d / "c2.png"), *tail])
        self.assertFalse(again["deliverable"])
        self.assertEqual(again["approval"]["status"], "pending")


if __name__ == "__main__":
    unittest.main()
