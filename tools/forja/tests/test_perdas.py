"""A auditoria de 27/10, §12-§14, como regressao (FORJA-07): o que a amostragem apaga fica no relatorio mesmo com
pureza 1,0, a pureza e medida em todos os metodos, e a grade diz de onde veio e se o recuperado cabe na tela.
Os controlos de ampliacao exata continuam a recuperar os pixels conhecidos.
"""
import unittest

from PIL import Image, ImageFilter

from tools.forja import cli, gridcheck, loss, pipeline
from tools.forja.imageops import flat, opaque_bbox, upscale
from tools.forja.resample import resample
from tools.forja.tests import audit_fixtures as fx
from tools.forja.tests.helpers import tempdir

KNOWN = gridcheck.phased((fx.K * fx.N, fx.K * fx.N), fx.K, (0, 0), "fixture")


def forge(image: Image.Image, **kw) -> dict:
    d = tempdir()
    image.save(d / "in.png")
    opts = pipeline.Options(kind="free", palette="none", noise=0, cleanup="conservative", outline="keep", fit=False,
                            bg="#FF00FF", **kw)
    return pipeline.forge(d / "in.png", d / "o", opts, name="in", report_html=False)


class SamplerLossTest(unittest.TestCase):
    """§12: a marca some e a pureza fica alta; agora a perda fica escrita, celula a celula."""

    def observe(self, name: str, method: str = "dominant", inset: float = 0.18):
        image = fx.cases()[name]
        sampled = resample(image, KNOWN, method, inset=inset)
        return sampled, loss.observe(image, KNOWN, sampled.image, inset)

    def test_the_edge_stroke_is_reported_though_the_core_is_pure(self):
        sampled, lost = self.observe("borda")
        self.assertEqual(sampled.purity, 1.0)
        self.assertEqual(sampled.image.getpixel(fx.CELL), fx.SKIN)
        self.assertEqual([(e["cell"], e["kind"], e["color"]) for e in lost["erased"]],
                         [([8, 8], "outside_core", "#0A080C")])
        self.assertEqual(lost["erased"][0]["core_share"], 0.0)

    def test_a_minority_mark_in_the_core_is_reported(self):
        for name, color in (("centro_4", "#0A080C"), ("dente", "#FAF0D7")):
            _, lost = self.observe(name)
            self.assertEqual([(e["kind"], e["color"]) for e in lost["erased"]], [("minority", color)], name)

    def test_the_line_over_the_void_keeps_its_twelve_cells_in_the_data(self):
        sampled, lost = self.observe("fio_alfa")
        self.assertEqual(sampled.purity, 1.0)
        self.assertEqual(lost["by_kind"]["alpha_discarded"], 12)
        self.assertEqual(sorted(tuple(e["cell"]) for e in lost["erased"]), fx.LINE_CELLS)
        self.assertTrue(all(sampled.image.getpixel(c)[3] == 0 for c in fx.LINE_CELLS))

    def test_the_whole_cell_control_and_the_winning_mark_are_not_losses(self):
        for name in ("pixel_inteiro", "centro_6"):
            _, lost = self.observe(name)
            self.assertEqual(lost["erased_cells"], 0, name)
        _, lost = self.observe("centro_6")
        self.assertEqual(lost["absorbed_cells"], 1)

    def test_purity_is_measured_by_every_method(self):
        half = Image.new("RGBA", (16, 16), fx.SKIN)
        half.paste(fx.DARK, (0, 0, 8, 16))
        g = gridcheck.phased((16, 16), 16, (0, 0))
        for method in ("mode", "center", "median", "mean"):
            got = resample(half, g, method, inset=0.0)
            self.assertLess(got.purity, 0.75, method)
            self.assertEqual(got.as_dict()["method"], method)
            self.assertEqual(got.as_dict()["purity_basis"], "core")
        self.assertAlmostEqual(resample(half, g, "dominant", inset=0.18).core_share, 100 / 256, places=3)


class PipelineLossTest(unittest.TestCase):
    """§13: no pipeline real, com a escala declarada."""

    def test_the_forge_reports_the_erased_mark(self):
        res = forge(fx.marked("borda"), scale=16)
        rules = [f["rule"] for f in res["lint"]["findings"]]
        self.assertIn("erased", rules)
        self.assertNotIn("subgrid", rules)
        self.assertEqual(res["snap"]["sample"]["purity"], 1.0)
        self.assertEqual(res["snap"]["loss"]["erased_cells"], 1)

    def test_the_cells_that_went_transparent_stay_in_the_loss(self):
        res = forge(fx.line(), scale=16)
        erased = res["snap"]["loss"]["erased"]
        self.assertEqual(len(erased), 12)
        self.assertFalse(any(e["inside_crop"] for e in erased))
        self.assertIn("erased", [f["rule"] for f in res["lint"]["findings"]])

    def test_the_whole_cell_control_is_not_flagged(self):
        res = forge(fx.marked("pixel_inteiro"), scale=16)
        self.assertNotIn("erased", [f["rule"] for f in res["lint"]["findings"]])
        self.assertEqual(res["snap"]["grid"]["origin"], "operator_declared")
        self.assertIn("confirmada", " ".join(res["snap"]["grid"]["notes"]))


class GridOriginTest(unittest.TestCase):
    """§13-§14: a origem da grade, o orcamento contra a tela e as afirmacoes separadas."""

    def test_the_grid_that_explains_every_pixel_can_exceed_the_budget(self):
        res = forge(fx.marked("centro_4"), canvas=(16, 16))
        rep = res["snap"]["grid_report"]
        self.assertEqual((rep["origin"], rep["period"], rep["native_size"]), ("exactly_measured", [2, 2], [128, 128]))
        self.assertFalse(rep["fits_target"])
        self.assertEqual(rep["mixed_scale"]["coarse_period"], 16)
        self.assertEqual(rep["mixed_scale"]["coarse_cells"], [16, 16])
        self.assertEqual(rep["mixed_scale"]["zones"], [[128, 128, 144, 144]])
        self.assertIn("grid_budget", [f["rule"] for f in res["lint"]["findings"]])

    def test_a_coarser_declared_grid_is_a_reduction_not_a_recovery(self):
        res = forge(fx.marked("centro_4"), scale=16)
        self.assertEqual(res["snap"]["grid"]["origin"], "deliberately_reduced")
        self.assertFalse(res["snap"]["grid_report"]["evidence_of_native_authorship"])
        self.assertIn("grid_reduced", [f["rule"] for f in res["lint"]["findings"]])
        said = forge(fx.marked("pixel_inteiro"), scale=16, reduce=True)
        self.assertEqual(said["snap"]["grid"]["origin"], "deliberately_reduced")

    def test_reduce_needs_the_grid_of_the_reduction(self):
        d = tempdir()
        fx.marked("borda").save(d / "in.png")
        with self.assertRaisesRegex(ValueError, "--scale ou --cells"):
            cli.run(["forge", str(d / "in.png"), "-o", str(d / "o"), "--reduce"])

    def test_a_refused_estimate_says_it_could_not_measure(self):
        native = fx.rejected("rei")
        g, _ = gridcheck.measure(native.resize((1254, 1254), Image.Resampling.BILINEAR))
        self.assertEqual(g.origin, "unmeasured")
        self.assertIn("--scale", g.notes[0])
        self.assertIn("--reduce", g.notes[0])

    def test_a_jpeg_recovers_grid_and_shape_but_does_not_claim_the_original_colors(self):
        native = fx.rejected("escudeiro")
        target = native.crop(opaque_bbox(native))
        solid = Image.new("RGBA", (native.width * 8, native.height * 8), (255, 0, 255, 255))
        solid.alpha_composite(upscale(native, 8))
        d = tempdir()
        solid.convert("RGB").save(d / "in.jpg", format="JPEG", quality=75, subsampling=0)
        opts = pipeline.Options(kind="free", palette="none", noise=0, cleanup="conservative", outline="keep",
                                fit=False, bg="#FF00FF")
        res = pipeline.forge(d / "in.jpg", d / "o", opts, name="in", report_html=False)
        rep = res["snap"]["grid_report"]
        self.assertAlmostEqual(rep["period"][0], 8, delta=0.1)
        self.assertEqual(rep["native_size"], list(target.size))
        self.assertEqual((rep["input_format"], rep["lossy_input"], rep["original_colors"]),
                         ("JPEG", True, "not_provable_lossy_input"))
        got = Image.open(res["files"]["png"]).convert("RGBA")
        self.assertEqual([p[3] >= 128 for p in flat(got)], [p[3] >= 128 for p in flat(target)])
        self.assertNotEqual(got.tobytes(), target.tobytes())


class RecoveryControlTest(unittest.TestCase):
    """§14.1: os controlos PNG inteiros continuam exatos (o caminho que funciona nao se perde)."""

    def test_the_png_controls_recover_the_known_pixels(self):
        for name in ("rei", "escudeiro", "arqueiro"):
            native = fx.rejected(name)
            target = native.crop(opaque_bbox(native))
            nn8 = upscale(native, 8)
            for case, image in (("8x", nn8), ("13x", upscale(native, 13)), ("fase", nn8.crop((3, 5, *nn8.size))),
                                ("blur", nn8.filter(ImageFilter.GaussianBlur(0.35)))):
                opts = pipeline.Options(kind="free", palette="none", noise=0, cleanup="conservative", outline="keep",
                                        fit=False)
                g, s = gridcheck.measure(image)
                got, info = pipeline.snap(image, opts, g, s)
                self.assertEqual(got.tobytes(), target.tobytes(), (name, case))
                self.assertEqual(info["loss"]["erased_cells"], 0, (name, case))
                if case != "blur":
                    self.assertEqual(g.origin, "exactly_measured", (name, case))


if __name__ == "__main__":
    unittest.main()
