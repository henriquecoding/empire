"""O contrato de fidelidade e a revisao em quatro estados (FORJA-07; auditoria de 27/10, plano §1 e §5).

Usa o contrato real da prancha de 27/10 (docs/art/research/2026-10-27-forja-auditoria-fidelidade/fidelidade.json):
o arqueiro de tunica verde comprida e um conflito de referencia antes de gerar e fica bloqueado na identidade mesmo
com o runtime a passar; o modo fiel nao recebe as preferencias do compilador; um guia em revisao nao substitui o
conceito; a identidade e a aprovacao so passam pelo que uma pessoa registou, para esta imagem exata.
"""
import json
import shutil
import unittest

from PIL import Image

from tools.forja import cli, equipment, fidelity, plan, refs, review_state
from tools.forja.imageops import flat
from tools.forja.tests import audit_fixtures as fx
from tools.forja.tests.helpers import framed, tempdir
from tools.forja.tests.test_fidelidade import OWNER, register

CONTRACT = fx.AUDIT / "fidelidade.json"


def arch_plan(**kw) -> plan.Plan:
    return plan.make("openai", "imperial archer", "royal_80", fidelity=fidelity.load(CONTRACT), character="arqueiro",
                     **kw)


class ContractTest(unittest.TestCase):
    def test_the_real_contract_is_valid_and_points_at_the_board(self):
        data = fidelity.load(CONTRACT)
        self.assertEqual([c["id"] for c in data["characters"]], ["rei", "escudeiro", "arqueiro"])
        crop = fidelity.authority_crop(data, fidelity.character(data, "arqueiro"))
        self.assertEqual(crop.size, (362, 408))

    def test_a_changed_authority_or_a_crop_out_of_bounds_is_refused(self):
        d = tempdir()
        shutil.copytree(fx.AUDIT / "referencia", d / "referencia")
        shutil.copytree(fx.AUDIT / "fixtures", d / "fixtures")
        data = json.loads(CONTRACT.read_text(encoding="utf-8"))
        data["characters"][0]["authority_crop_xyxy"] = [55, 140, 1600, 618]
        (d / "f.json").write_text(json.dumps(data), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "fora da autoridade"):
            fidelity.load(d / "f.json")
        data["authority"]["sha256"] = "0" * 64
        (d / "f.json").write_text(json.dumps(data), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "o ficheiro mudou"):
            fidelity.load(d / "f.json")


class RequestTest(unittest.TestCase):
    """Plano §1: o pedido aponta para o recorte de autoridade e diz a origem de cada restricao."""

    def test_the_green_archer_is_a_reference_conflict_before_generating(self):
        p = arch_plan(references=[("concept", str(fx.AUDIT / "fixtures/arqueiro.png"))])
        self.assertFalse(p.ok)
        self.assertIn("reference_conflict", " ".join(p.data["errors"]))
        self.assertIn("candidato rejeitado", " ".join(p.data["errors"]))
        q = arch_plan(references=[("identity", str(fx.AUDIT / "fixtures/arqueiro.png"))])
        self.assertIn("candidato rejeitado", " ".join(q.data["errors"]))

    def test_the_faithful_request_carries_the_crop_and_no_compiler_preference(self):
        p = arch_plan()
        self.assertTrue(p.ok, p.data["errors"])
        self.assertEqual(p.data["mode"], "adapt_concept")
        self.assertEqual(p.data["attachments"][0]["prompt_role"], "concept")
        self.assertEqual(p.data["fidelity"]["crop"], [1115, 210, 1477, 618])
        text = p.data["prompt"]
        for implicit in ("two tones", "12-24", "strict side view"):
            self.assertNotIn(implicit, text)
        self.assertIn("NOT a long green tunic", text)
        self.assertEqual(p.data["implicit"], [])
        origins = {c["id"]: c["origin"] for c in p.data["constraints"]}
        self.assertEqual(origins["invariants"], "fidelity:arqueiro/estatica_superior_da_prancha")
        self.assertIn("max_colors null", origins["colors"])

    def test_the_stylized_request_says_its_preferences_are_the_compilers(self):
        d = tempdir()
        framed(5, (80, 80), (40, 78)).save(d / "ref.png")
        p = plan.make("openai", "comic king", "royal_80", references=[("identity", str(d / "ref.png"))])
        self.assertEqual(p.data["mode"], "stylized")
        self.assertIn("two tones", p.data["prompt"])
        self.assertEqual(sorted(p.data["implicit"]), ["camera", "colors", "shading"])

    def test_color_and_tone_counts_enter_only_as_decisions(self):
        p = arch_plan(decisions={"max_colors": 32, "tones": 3})
        self.assertIn("at most 32 colors", p.data["prompt"])
        self.assertIn("3 tones per material", p.data["prompt"])
        origins = {c["id"]: c["origin"] for c in p.data["constraints"]}
        self.assertEqual((origins["colors"].split("; ")[-1], origins["shading"]),
                         ("explicit_request", "explicit_request"))

    def test_a_guide_in_review_does_not_replace_the_concept(self):
        d = tempdir()
        guide = framed(6, (80, 80), (40, 78))
        reg = register(d, ("guia", guide, "adaptation_in_review", {}))
        alone = plan.make("openai", "comic king", "royal_80", references=[("identity", str(d / "guia.png"))],
                          register=refs.load(reg))
        self.assertIn("ao lado do conceito", " ".join(alone.data["errors"]))
        beside = arch_plan(references=[("identity", str(d / "guia.png"))], register=refs.load(reg))
        self.assertTrue(beside.ok, beside.data["errors"])
        self.assertEqual([a["prompt_role"] for a in beside.data["attachments"][:2]], ["identity_review", "concept"])

    def test_a_registered_concept_makes_the_request_faithful(self):
        d = tempdir()
        reg = refs.load(register(d, ("conceito", framed(7, (80, 80), (40, 78)), "concept", {})))
        p = plan.make("openai", "comic king", "royal_80", references=[("identity", str(d / "conceito.png"))],
                      register=reg)
        self.assertEqual(p.data["mode"], "adapt_concept")
        self.assertNotIn("two tones", p.data["prompt"])
        self.assertIn("sem contrato de fidelidade", " ".join(p.data["notes"]))

    def test_the_modes_ask_for_what_they_need(self):
        self.assertIn("recover_grid nao gera", " ".join(arch_plan(mode="recover_grid").data["errors"]))
        self.assertIn("mestre aprovado", " ".join(arch_plan(mode="edit_approved_master").data["errors"]))
        bare = plan.make("openai", "comic king", "royal_80", mode="adapt_concept")
        self.assertIn("pede --fidelity", " ".join(bare.data["errors"]))

    def test_the_prompt_command_writes_the_authority_crop_to_attach(self):
        d = tempdir()
        res = cli.run(["prompt", "imperial archer", "-o", str(d), "--kind", "royal_80", "--fidelity", str(CONTRACT),
                       "--character", "arqueiro"])
        self.assertEqual(res["mode"], "adapt_concept")
        self.assertEqual(res["attach"][0], str(d / "attach_concept_authority.png"))
        with Image.open(d / "attach_concept_authority.png") as im:
            self.assertEqual(im.size, (362, 408))
        self.assertIn("image 1: the authority CONCEPT ART", res["prompt"])


class ReviewTest(unittest.TestCase):
    """Plano §5: quatro estados; o tecnico nao preenche os outros."""

    def test_the_green_archer_stays_blocked_even_when_the_runtime_passes(self):
        archer = fx.rejected("arqueiro")
        own = ",".join(sorted({"#%02X%02X%02X" % p[:3] for p in flat(archer) if p[3] >= 128}))
        res = cli.run(["fidelity", str(CONTRACT), "--character", "arqueiro", "--candidate",
                       str(fx.AUDIT / "fixtures/arqueiro.png"), "--palette", own])
        summary = res["review"]["summary"]
        self.assertEqual(summary["runtime"], "pass")
        self.assertEqual(summary["identity_and_pose"], "blocked")
        self.assertFalse(res["deliverable"])
        self.assertFalse(res["ok"])

    def test_a_new_candidate_is_pending_where_no_one_has_looked(self):
        data = fidelity.load(CONTRACT)
        rev = review_state.review(fidelity.character(data, "rei"), framed(5, (80, 80), (40, 78)))
        self.assertEqual(rev["summary"], {"runtime": "pending", "declared_feature_preservation": "pending",
                                          "identity_and_pose": "pending", "native_master_approval": "pending"})
        self.assertFalse(rev["technical_pass_implies_identity_pass"])

    def test_only_a_complete_human_review_and_the_owner_close_it(self):
        d = tempdir()
        cand = framed(5, (80, 80), (40, 78))
        sha = equipment.image_sha(cand)
        ch = {"id": "rei", "pose": "p", "pixel_pins": [], "rejected_candidates": [],
              "critical_regions": [{"id": "face", "required": True, "target_box": [30, 10, 50, 30]}],
              "identity_reviews": [{"pixels_sha256": sha, "reviewed_by": "Henrique", "date": "2026-10-28",
                                    "status": "pass", "observations": {"face": "palpebra e sorriso como no conceito"}}]}
        forge = {"snap": {"loss": {"erased": []}}, "finish": {}, "signals": {"pins": []}}
        lint_ok = {"ok": True, "findings": []}
        rev = review_state.review(ch, cand, None, lint_ok, forge)
        self.assertEqual(rev["summary"]["identity_and_pose"], "pending")
        ch["identity_reviews"][0]["observations"].update({a: "como no conceito" for a in review_state.ASPECTS})
        reg = refs.load(register(d, ("rei", cand, "approved", OWNER)))
        rev = review_state.review(ch, cand, reg, lint_ok, forge)
        self.assertEqual(set(rev["summary"].values()), {"pass"})
        self.assertTrue(rev["deliverable"])
        moved = cand.copy()
        moved.putpixel((40, 40), (1, 2, 3, 255))
        self.assertFalse(review_state.review(ch, moved, reg, lint_ok, forge)["deliverable"])

    def test_the_sheet_puts_concept_and_candidate_side_by_side(self):
        d = tempdir()
        res = cli.run(["fidelity", str(CONTRACT), "--character", "rei", "--candidate",
                       str(fx.AUDIT / "fixtures/rei.png"), "--sheet", str(d / "lado.png"), "--crop-out", str(d)])
        with Image.open(res["sheet"]) as sheet:
            self.assertGreater(sheet.width, 320 + 80 + 320)
        self.assertEqual(res["review"]["summary"]["identity_and_pose"], "blocked")
        self.assertTrue(res["authority_crop"]["file"].endswith("rei-estatica_superior_da_prancha-autoridade.png"))


if __name__ == "__main__":
    unittest.main()
