"""Reproduz os desvios do fluxo: guia rejeitado, prompt trocado e reexportacao que esquece a origem."""
import json
import unittest
from unittest import mock

from tools.forja import cli, lineage, owner_rules, pipeline, plan, review_state
from tools.forja.equipment import image_sha
from tools.forja.tests.helpers import framed, tempdir
from tools.forja.tests import test_owner_rules as fixtures


class RulesFlowTest(unittest.TestCase):
    def test_all_backends_bind_consultation_to_the_selected_concept(self):
        from tools.forja import cast
        data = cast.load()
        entry = cast.character(data, "alquimista")
        contract = cast.authority(data, entry)
        for backend in ("openai", "gemini", "pixellab"):
            p = plan.make(backend, "alquimista", fidelity=contract, character=entry["id"])
            ctx = p.data["expect"]["owner_rules"]
            self.assertEqual(ctx["character"], entry["id"])
            self.assertEqual(ctx["authority_crop_sha256"], p.data["fidelity"]["crop_pixels_sha256"])
            if backend == "pixellab":
                self.assertFalse(p.ok)  # conceito grande nao se reduz em silencio para init_image nativa
                self.assertIn("init_image", " ".join(p.data["errors"]))
            else:
                self.assertTrue(p.ok, p.data["errors"])
                p.call()  # construcao local do pedido; nao envia nada

    def test_replaced_or_stale_prompt_is_refused_before_building_a_request(self):
        p = plan.make("openai", "troop archer")
        p.call()
        with self.assertRaisesRegex(ValueError, "regras do dono"):
            p.call("Make a knight.")
        marker_only = "FORJA_OWNER_RULES:" + p.data["expect"]["owner_rules"]["revision"]
        with self.assertRaisesRegex(ValueError, "texto das regras"):
            p.call(marker_only)
        p.data["expect"]["owner_rules"]["revision"] = "old"
        with self.assertRaisesRegex(ValueError, "consulta atual"):
            p.call()

    def test_rejected_native_cannot_be_a_density_guide_even_without_a_contract(self):
        d = tempdir()
        image = framed()
        image.save(d / "rejected.png")
        book = owner_rules.load()
        book["rejected_native_candidates"].append({"pixels_sha256": image_sha(image), "reason": "owner rejected"})
        with mock.patch.object(owner_rules, "load", return_value=book):
            p = plan.make("openai", "troop archer", references=[("style", str(d / "rejected.png"))])
        self.assertFalse(p.ok)
        self.assertIn("guia de entrega rejeitada", " ".join(p.data["errors"]))

    def test_consultation_survives_reexport_and_patch_without_rewriting_its_origin(self):
        d = tempdir()
        framed().save(d / "source.png")
        ctx = {**owner_rules.context(), "character": "test", "authority_crop_sha256": "reference"}
        def forge(source, name, **kw):
            opts = pipeline.Options(palette="none", noise=0, outline="keep", bg="keep", fit=False, **kw)
            return pipeline.forge(source, d / name, opts, name=name, report_html=False)
        first = forge(d / "source.png", "first", native_root=True, owner_rules=ctx)
        second = forge(first["files"]["png"], "second", lineage=first["lineage"], owner_rules={"revision": "new"})
        self.assertEqual(second["lineage"]["owner_rules"], ctx)
        patched = lineage.patch(second["lineage"], {"base_pixels_sha256": second["lineage"]["output_sha256"],
            "result_pixels_sha256": "patched"}, [[0, 0, 1, 1]])
        self.assertEqual(patched["owner_rules"], ctx)
        without = forge(d / "source.png", "without", native_root=True)
        later = forge(without["files"]["png"], "later", lineage=without["lineage"], owner_rules=ctx)
        self.assertIsNone(later["lineage"]["owner_rules"])

    def test_review_ready_requires_preserved_features_and_a_closed_chain(self):
        fx = fixtures.DeliveryGateTest()
        fx.setUp()
        ch = {**fx.ch, "pose": "idle", "pixel_pins": [], "critical_regions": [], "face_sheet": None}
        fx.forge["lineage"]["root"] = {"kind": "native_root_declared"}
        identity = {"status": "pass", "evidence": ["compared"]}
        with mock.patch.object(review_state, "identity", return_value=identity), \
                mock.patch.object(review_state, "preservation", return_value={"status": "pass"}):
            r = review_state.review(ch, fx.image, lint_result={"ok": True, "findings": []},
                                    forge=fx.forge, visual=fx.visual)
            self.assertTrue(r["ready_for_review"])
            self.assertFalse(r["release_ready"])  # o observador nao aprova o mestre pelo dono
            with mock.patch.object(review_state, "preservation", return_value={"status": "pending"}):
                r = review_state.review(ch, fx.image, lint_result={"ok": True, "findings": []},
                                        forge=fx.forge, visual=fx.visual)
                self.assertFalse(r["ready_for_review"])
            fx.forge["lineage"]["root"]["kind"] = "native_input"
            r = review_state.review(ch, fx.image, lint_result={"ok": True, "findings": []},
                                    forge=fx.forge, visual=fx.visual)
            self.assertFalse(r["ready_for_review"])

    def test_delivery_cli_returns_failure_and_keeps_missing_cast_visible(self):
        import contextlib
        import io
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            status = cli.main(["entrega", str(tempdir()), "--character", "alquimista"])
        self.assertEqual(status, 1)
        result = json.loads(out.getvalue())
        self.assertEqual(result["scope"], "selected_pilot")
        self.assertEqual([e["character"] for e in result["entries"]], ["alchemist_emperor"])
        self.assertEqual(result["release_ready"], 0)
