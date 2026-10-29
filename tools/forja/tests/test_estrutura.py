"""Cenarios (FORJA-11): a revisao estrutural, os pares Wang, a bancada, a escala de uma referencia e a CLI."""
import colorsys
import csv
import json
import unittest
from pathlib import Path

from PIL import Image, ImageDraw

from tools.forja import cli, estrutura, mcp_server, montagem, regua, scene, tiles
from tools.forja.tests import scene_fixtures as fx
from tools.forja.tests.helpers import tempdir

ROOT = Path(__file__).resolve().parents[3]


def resolved(**over) -> dict:
    return scene.resolve(scene.load(fx.write(tempdir(), fx.contract(**over))))


def status(rep: dict, name: str) -> str:
    return next(c["status"] for c in rep["checks"] if c["check"] == name)


class EstruturaTest(unittest.TestCase):
    def setUp(self):
        self.res = resolved()

    def test_a_good_house_stands_on_the_ground_with_a_usable_door(self):
        rep = estrutura.review(fx.house(), self.res)
        for name in ("extent", "lattice", "base_contact", "opening:porta"):
            self.assertEqual(status(rep, name), "pass", name)
        self.assertEqual(rep["verdicts"]["structure"], "pass")
        self.assertEqual(rep["verdicts"]["artistic_approval"], "pending")
        self.assertEqual(rep["placement"]["anchor_local_px"], [64, 128])
        self.assertEqual(rep["placement"]["top_world_y"] % 2, 0)

    def test_floating_closed_and_short_doors_block(self):
        self.assertEqual(status(estrutura.review(fx.house(lift=4), self.res), "base_contact"), "fail")
        self.assertEqual(status(estrutura.review(fx.house(door=None), self.res), "opening:porta"), "fail")
        sunk = Image.new("RGBA", (128, 128))
        sunk.paste(fx.house(door=[52, 44, 76, 128]).resize((128, 64), Image.Resampling.NEAREST), (0, 64))
        self.assertEqual(status(estrutura.review(sunk, self.res), "opening:porta"), "fail")  # o ceu nao e vao
        short = fx.house()
        ImageDraw.Draw(short).rectangle([48, 44, 79, 79], fill=fx.WALL)
        rep = estrutura.review(short, self.res)
        self.assertEqual(status(rep, "opening:porta"), "fail")
        self.assertIn("structure", rep["blocking"])

    def test_a_gate_is_measured_as_a_public_door(self):
        gate = [{"id": "porta", "kind": "gate", "box_px": [40, 24, 88, 128]}]
        res = resolved(openings=gate)
        wide = fx.house(door=[40, 24, 88, 128])
        rep = estrutura.review(wide, res)
        need = next(c for c in rep["checks"] if c["check"] == "opening:porta")["evidence"]["required"]
        self.assertEqual(need, regua.metric(res["metrics"], "public_door_height")["px"][0])

    def test_a_lit_window_reads_brighter_than_the_wall(self):
        lit = fx.house()
        ImageDraw.Draw(lit).rectangle([16, 60, 39, 87], fill=(255, 240, 170, 255))
        window = {"id": "janela", "kind": "window", "box_px": [16, 60, 40, 88]}
        res = resolved(openings=[fx.contract()["openings"][0], {**window, "treatment": "lit"}])
        self.assertEqual(status(estrutura.review(lit, res), "opening:janela"), "pass")
        dark = resolved(openings=[fx.contract()["openings"][0], {**window, "treatment": "interior"}])
        self.assertEqual(status(estrutura.review(lit, dark), "opening:janela"), "fail")

    def test_the_extent_and_grid_are_checked_and_boxes_follow_the_anchor(self):
        wide = Image.new("RGBA", (132, 128))
        wide.paste(fx.house(), (2, 0))
        rep = estrutura.review(wide, self.res)
        self.assertEqual(status(rep, "extent"), "fail")
        self.assertEqual(status(rep, "opening:porta"), "pass")
        odd = Image.new("RGBA", (129, 128))
        odd.paste(fx.house(), (0, 0))
        self.assertEqual(status(estrutura.review(odd, self.res), "lattice"), "fail")

    def test_identity_signals_need_a_region_and_a_master_to_pass(self):
        rep = estrutura.review(fx.house(), self.res)
        self.assertEqual(status(rep, "chimney_join"), "inconclusive")
        self.assertEqual(status(rep, "roof_pitch"), "not_evaluated")
        same = estrutura.review(fx.house(), self.res, master=fx.house())  # igual a uma imagem nao a faz mestre
        self.assertEqual(status(same, "chimney_join"), "inconclusive")
        self.assertEqual(status(estrutura.review(fx.house(), self.res, master=fx.house(), master_state="approved"),
                                "chimney_join"), "pass")
        rgb = fx.house().convert("RGB")
        self.assertEqual(status(estrutura.review(rgb.convert("RGBA"), self.res, master=rgb, master_state="approved"),
                                "chimney_join"), "pass")
        moved = fx.house()
        ImageDraw.Draw(moved).rectangle([94, 0, 107, 7], fill=(0, 0, 0, 0))
        self.assertEqual(status(estrutura.review(moved, self.res, master=fx.house()), "chimney_join"), "fail")

    def test_states_change_only_inside_their_zones(self):
        damaged = fx.house()
        ImageDraw.Draw(damaged).rectangle([10, 10, 30, 20], fill=(0, 0, 0, 0))
        self.assertEqual(status(estrutura.review(fx.house(), self.res, states={"damaged": damaged}), "damaged"),
                         "pass")
        ImageDraw.Draw(damaged).rectangle([48, 100, 79, 127], fill=fx.WALL)
        rep = estrutura.review(fx.house(), self.res, states={"damaged": damaged})
        self.assertEqual(status(rep, "damaged"), "fail")
        self.assertEqual(rep["verdicts"]["states"], "fail")

    def test_a_strip_repeats_without_a_step_and_modules_join(self):
        res = resolved(asset="terrain_strip", extent_px=[64, 32], openings=[], signals=[], signal_regions={},
                       materials=["soil"], states=["done"], state_changes={})
        self.assertEqual(status(estrutura.review(fx.strip(), res), "repeat_x"), "pass")
        self.assertEqual(status(estrutura.review(fx.strip(rise=8), res), "repeat_x"), "fail")
        rep = estrutura.review(fx.strip(), res, neighbors={"right": fx.strip(),
                                                         "left": fx.strip(rise=8).transpose(Image.Transpose.FLIP_LEFT_RIGHT)})
        self.assertEqual(status(rep, "connector_right"), "pass")
        self.assertEqual(status(rep, "connector_left"), "fail")
        self.assertFalse(estrutura.joint(fx.strip(), fx.strip((64, 30)))["ok"])


class WangPairsTest(unittest.TestCase):
    def test_the_generated_set_has_64_and_64_good_joins(self):
        upper = Image.new("RGBA", (32, 32), fx.GRASS)
        sheet, _ = tiles.wang16(32, None, upper, cluster=2)
        joins = tiles.pairs(sheet, 32)
        self.assertEqual((joins["horizontal"]["pairs"], joins["vertical"]["pairs"]), (64, 64))
        self.assertTrue(joins["ok"])
        two, _ = tiles.wang16(32, Image.new("RGBA", (32, 32), fx.SOIL), upper, cluster=2)
        self.assertTrue(tiles.pairs(two, 32, tiles.upper_class(upper))["ok"])

    def test_a_broken_edge_is_found_even_when_the_mean_contrast_hides_it(self):
        sheet, _ = tiles.wang16(32, None, Image.new("RGBA", (32, 32), fx.GRASS), cluster=2)
        ImageDraw.Draw(sheet).rectangle([0 * 32 + 30, 3 * 32, 0 * 32 + 31, 3 * 32 + 31], fill=(0, 0, 0, 0))
        joins = tiles.pairs(sheet, 32)
        self.assertFalse(joins["ok"])
        self.assertTrue(any(b["a"] == 12 for b in joins["horizontal"]["bad"]))


    def test_a_cluster_broken_at_the_seam_is_found(self):
        sheet, _ = tiles.wang16(32, Image.new("RGBA", (32, 32), fx.SOIL), Image.new("RGBA", (32, 32), fx.GRASS),
                                cluster=2)
        self.assertTrue(tiles.junctions(sheet, 32)["ok"])
        for x in (3 * 32 + 31, 3 * 32):
            sheet.putpixel((x, 3 * 32 + 10), (255, 0, 0, 255))
        j = tiles.junctions(sheet, 32)
        self.assertFalse(j["ok"])
        self.assertTrue(any(s["a"] == 15 and s["b"] == 15 for s in j["seam"]))


class MontagemTest(unittest.TestCase):
    def test_the_bench_puts_the_base_on_the_walk_line_with_the_real_actors(self):
        res = resolved()
        b = montagem.bench(fx.house(), res)
        left, top = b["placement"]["asset_top_left"]
        self.assertEqual(top + 128, b["placement"]["anchor_world_y_edge"])
        self.assertEqual(left % 2, 0)
        self.assertEqual(b["day"].getpixel((left + 60, top + 127)), fx.DARK)
        self.assertEqual({a["actor"] for a in b["actors"]}, {res["ruler"]["tallest"]["id"],
                                                             res["ruler"]["shortest"]["id"]})
        self.assertEqual(b["night"].size, b["day"].size)

    def test_the_night_tint_is_read_from_the_clock(self):
        with open(ROOT / "data/source/clock.csv", encoding="utf-8") as f:
            row = next(csv.DictReader(f))
        hue, sat, val = (float(row[f"phase_tint_{k}"].split("|")[5]) for k in ("hue", "sat", "val"))
        rgb = colorsys.hsv_to_rgb(hue / 360, sat, max(val, float(row["night_vision"])))
        self.assertEqual(montagem.night_tint()["rgb"], tuple(round(c * 255) for c in rgb))

    def test_scale_from_landmarks_and_the_detail_verdict(self):
        cells = Image.new("RGBA", (40, 30), (0, 0, 0, 0))
        d = ImageDraw.Draw(cells)
        for i in range(0, 40, 2):
            d.rectangle([i, 10, i, 29], fill=(120 + 3 * i, 90, 60, 255))
        ref = cells.resize((400, 300), Image.Resampling.NEAREST)
        door = {"box": (100, 100, 140, 300), "target": (76, 86), "metric": "door_clear_height"}
        info = montagem.scale_reference(ref, [door], 2)
        self.assertTrue(info["consistent"])
        self.assertAlmostEqual(info["scale"], 81 / 200, places=3)
        self.assertAlmostEqual(info["reference_grid"]["period"], 10.0, delta=0.05)
        self.assertIn("mais grossa", info["detail"])
        squeezed = montagem.scale_reference(ref, [door], 2, footprint=64)["plan"]
        self.assertEqual(squeezed["compression"], round(64 / info["target_extent_px"][0], 3))
        self.assertIn("comprimir", squeezed["rule"])
        barrel = {"box": (0, 260, 20, 300), "target": (28, 36), "metric": "barrel_height"}
        clash = montagem.scale_reference(ref, [barrel, door], 2)
        self.assertFalse(clash["consistent"])
        self.assertIsNone(clash["common_range"])
        self.assertAlmostEqual(clash["scale"], 32 / 40, places=3)


class CliTest(unittest.TestCase):
    def test_cena_compiles_and_the_commands_reach_mcp(self):
        out = tempdir()
        path = fx.write(out, fx.contract())
        res = cli.run(["cena", str(path), "-o", str(out / "pedido")])
        self.assertTrue(res["ok"], res)
        expect = json.loads(Path(res["files"]["expect"]).read_text(encoding="utf-8"))
        self.assertEqual((expect["canvas_px"], expect["pivot_px"]), ([128, 128], [64, 127]))
        self.assertTrue(Path(res["files"]["ruler"]).is_file())
        bad = cli.run(["cena", str(fx.write(out, fx.contract(extent_px=None), "sem.json")), "-o", str(out / "x")])
        self.assertFalse(bad["ok"])
        fx.house().save(out / "casa.png")
        rev = cli.run(["estrutura", str(out / "casa.png"), "--scene", str(path)])
        self.assertEqual(rev["verdicts"]["structure"], "pass")
        self.assertFalse(rev["ok"])  # a casa sintetica nao tem contorno nem paleta: o raster bloqueia, a parte
        tools = {t["name"]: t for t in mcp_server.tools()}
        for name in ("forja_regua", "forja_cena", "forja_estrutura", "forja_montagem", "forja_escala"):
            self.assertIn(name, tools)
        self.assertTrue(tools["forja_regua"]["annotations"]["readOnlyHint"])

    def test_regua_reports_its_sources(self):
        res = cli.run(["regua"])
        self.assertEqual(res["world"]["sources"]["surface_y"], regua.data()["world"]["owner_manifest"])
        self.assertTrue(all(m["origin"] for m in res["metrics"]))


if __name__ == "__main__":
    unittest.main()
